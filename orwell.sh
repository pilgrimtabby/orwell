#!/usr/bin/env bash

# Copyright (c) 2024 pilgrim_tabby
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# Orwell is a simple command line tool that automates modifying the /etc/hosts file
# and flushing the DNS cache to allow easy website blocking. It supports two blacklists,
# a permanent (always-on) option and a toggleable option, to allow for greater
# flexibility and customization.
# See https://github.com/pilgrimtabby/orwell for the source code.


################
#              #
# Main methods #
#              #
################

# Parse user flags
main() {
    [[ "$1" == "" ]] && help && exit

    # Make sure user doesn't pass any arguments that aren't flags
    # Non-dashed options and a single dash only aren't caught by getopts
    if [[ "$1" != -* ]] || [[ "$1" == "-" ]]; then
        echo "$0: illegal option -- $1"
        echo "Use a valid flag prefixed with '-'."
        echo "Type orwell -h for a list of commands."
        exit
    fi

    make_config

    optspec="a:x:d:e:ltsvh"
    while getopts "$optspec" optchar
    do
        case "${optchar}" in
            a)
                add "${@:2}"
                ;;
            x)
                permanent_add "${@:2}"
                ;;
            d)
                delete "${@:2}"
                ;;
            e)
                empty "${@:2}"
                ;;
            l)
                list "${@:2}"
                ;;
            t)
                toggle "${@:2}"
                ;;
            s)
                show_status "${@:2}"
                ;;
            v)
                echo "$ORWELL_VERSION"
                ;;
            h)
                help
                ;;
            *)
                echo "Type orwell -h for a list of commands."
                ;;
        esac
    done
}


# Create and populate the config folder if any files are missing
make_config() {
    CONFIG_DIR=~/.config/orwell
    # Store original copy of /etc/hosts for emergencies.
    BACKUP_FILE=$CONFIG_DIR"/backup_file"
    BLACKLIST=$CONFIG_DIR"/blacklist"
    PERM_BLACKLIST=$CONFIG_DIR"/perm_blacklist"
    # Store 0 (toggleable blacklist not enforced) or 1 (enforced)
    STATUS_FILE=$CONFIG_DIR"/status"

    [[ ! -d ~/.config ]] && mkdir ~/.config
    [[ ! -d $CONFIG_DIR ]] && mkdir $CONFIG_DIR
    [[ ! -f $BACKUP_FILE ]] && cp /etc/hosts $BACKUP_FILE
    [[ ! -f $BLACKLIST ]] && touch $BLACKLIST
    [[ ! -f $PERM_BLACKLIST ]] && touch $PERM_BLACKLIST
    [[ ! -f $STATUS_FILE ]] && echo 0 > $STATUS_FILE
}


# Add a URL to the toggleable blacklist
add() {
    url_added="false"

    for url in "$@"
    do
        # Save original url so we can print it to the console
        orig_url="$url"
        # http references prevent this from working, so remove them here
        [[ "$url" == https://* ]] && url="${url:8}"
        [[ "$url" == http://* ]] && url="${url:7}"
        # Standardize urls by making sure they all start with www.
        # That way we can add both the www. and non-www. versions later
        [[ "$url" != www.* ]] && url="www.$url"

        url_line_no=$(find_url_line $url $BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            echo "Warning: $orig_url is already in blacklist."
            continue
        fi

        # It doesn't strike me as desirable to allow the URL to be on both
        # blacklists, so we catch any duplicates here
        url_line_no=$(find_url_line $url $PERM_BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            echo "Warning: $orig_url is already in permanent blacklist."
            echo "Please remove it from that blacklist first."
            continue
        fi

        # The password isn't required to modify the blacklist, but we don't
        # want the user to modify the blacklist if they don't have the password
        # since this would lead to the blacklist's current state not matching
        # what is happening in /etc/hosts.
        if [[ $(get_permission) == "false" ]]; then
            echo "Error: -a: password required to add URLs"
            exit
        fi

        # Add www. and non-www. url to blacklist
        echo -e "127.0.0.1\t$url" >> $BLACKLIST
        echo -e "127.0.0.1\t${url:4}" >> $BLACKLIST
        echo "$orig_url added to blacklist!"
        url_added="true"
    done

    if [[ $url_added == "true" ]]; then
        status_val=`cat $STATUS_FILE`
        if [[ "$status_val" == 1 ]]; then
            block
            echo "Updated blacklist is IN FORCE."
            echo "You may need to restart your internet browser to see changes."
        fi
    fi
}


# Add a URL to the permanent blacklist
# See add() for detailed documentation, since the two functions are similar
permanent_add() {
    url_added="false"

    for url in "$@"
    do
        orig_url="$url"
        [[ "$url" == https://* ]] && url="${url:8}"
        [[ "$url" == http://* ]] && url="${url:7}"
        [[ "$url" != www.* ]] && url="www.$url"

        url_line_no=$(find_url_line $url $BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            echo "Warning: $orig_url is already in toggleable blacklist."
            echo "Please remove it from that blacklist first."
            continue
        fi

        url_line_no=$(find_url_line $url $PERM_BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            echo "Warning: $orig_url is already in permanent blacklist."
            continue
        fi

        # The password isn't required to modify the blacklist, but we don't
        # want the user to modify the blacklist if they don't have the password
        # since this would lead to the blacklist's current state not matching
        # what is happening in /etc/hosts.
        if [[ $(get_permission) == "false" ]]; then
            echo "Error: -x: password required to add URLs"
            exit
        fi

        echo -e "127.0.0.1\t$url" >> $PERM_BLACKLIST
        echo -e "127.0.0.1\t${url:4}" >> $PERM_BLACKLIST
        echo "$orig_url added to permanent blacklist!"
        url_added="true"
    done

    # Call unblock if toggleable blacklist isn't being enforced so that the
    # permanent blacklist will still be updated.
    if [[ $url_added == "true" ]]; then
        status_val=`cat $STATUS_FILE`
        if [[ "$status_val" == 0 ]]; then
            unblock
        else
            block
        fi
        echo "Updated permanent blacklist is IN FORCE."
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    fi
}


# Delete a URL from a blacklist if it is found
delete() {
    blacklist_len=`wc -c < $BLACKLIST | tr -d " "`
    p_blacklist_len=`wc -c < $PERM_BLACKLIST | tr -d " "`
    os=`uname`  # Get operating system for sed commands

    for url in "$@"
    do
        deleted_url="false"
        # Save original url so we can print it to the console
        orig_url="$url"
        [[ "$url" == https://* ]] && url="${url:8}"
        [[ "$url" == http://* ]] && url="${url:7}"
        [[ "$url" != www.* ]] && url="www.$url"

        url_line_no=$(find_url_line $url $BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            # The password isn't required to modify the blacklist, but we don't
            # want the user to modify the blacklist if they don't have the password
            # since this would lead to the blacklist's current state not matching
            # what is happening in /etc/hosts.
            if [[ $(get_permission) == "false" ]]; then
                echo "Error: -d: password required to delete URLs"
                exit
            fi

            # MacOS doesn't use the GNU sed, so it needs an extra blank param
            # after `-i`. Passing this to GNU sed breaks the command, though.
            if [[ $os == "Darwin" ]]; then
                sed -i "" "${url_line_no},$(( $url_line_no + 1 ))d" $BLACKLIST
            else  # Linux
                sed -i "${url_line_no},$(( $url_line_no + 1 ))d" $BLACKLIST
            fi
            echo "$orig_url removed from blacklist!"
            deleted_url="true"
        fi

        url_line_no=$(find_url_line $url $PERM_BLACKLIST)
        if [[ $url_line_no -ge 0 ]]; then
            # The password isn't required to modify the blacklist, but we don't
            # want the user to modify the blacklist if they don't have the password
            # since this would lead to the blacklist's current state not matching
            # what is happening in /etc/hosts.
            if [[ $(get_permission) == "false" ]]; then
                echo "Error: -d: password required to delete URLs"
                exit
            fi

            # MacOS doesn't use the GNU sed, so it needs an extra blank param
            # after `-i`. Passing this to GNU sed breaks the command, though.
            if [[ $os == "Darwin" ]]; then
                sed -i "" "${url_line_no},$(( $url_line_no + 1 ))d" $PERM_BLACKLIST
            else  # Linux
                sed -i "${url_line_no},$(( $url_line_no + 1 ))d" $PERM_BLACKLIST
            fi
            echo "$orig_url removed from permanent blacklist!"
            deleted_url="true"
        fi

        [[ $deleted_url == "false" ]] && echo "Warning: $orig_url not found."
    done

    blacklist_len_new=`wc -c < $BLACKLIST | tr -d " "`
    p_blacklist_len_new=`wc -c < $PERM_BLACKLIST | tr -d " "`
    blacklist_diff=$(( $blacklist_len_new - $blacklist_len ))
    p_blacklist_diff=$(( $p_blacklist_len_new - $p_blacklist_len ))
    status_val=`cat $STATUS_FILE`

    if [[ $status_val == 1 && $blacklist_diff != 0 ]]; then
        # Only need to do anything if the toggleable blacklist is currently
        # active, since next time it's turned on it'll update anyway
        block
        echo "Updated blacklist is IN FORCE."
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    elif [[ $p_blacklist_diff != 0 ]]; then
        # Regardless of toggleable blacklist status, make sure p_blacklist is
        # up-to-date
        [[ $status_val == 0 ]] && unblock
        [[ $status_val == 1 ]] && block
        echo "Updated permanent blacklist is IN FORCE."
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    fi
}


# Delete all entries on a blacklist
empty() {
    # The password isn't required to modify the blacklist, but we don't
    # want the user to modify the blacklist if they don't have the password
    # since this would lead to the blacklist's current state not matching
    # what is happening in /etc/hosts.
    if [[ $(get_permission) == "false" ]]; then
        echo "Error: -e: password required to delete URLs"
        exit
    fi

    if [[ $# -gt 1 ]]; then
        echo "Error: -e: please specify exactly one argument."
        echo "Options: 'blacklist', 'p-blacklist', 'all'"
        exit
    fi

    if [[ "$1" == "blacklist" ]]; then
        > $BLACKLIST
        status_val=`cat $STATUS_FILE`
        if [[ "$status_val" == 1 ]]; then
            block
        fi
        echo "Blacklist has been emptied!"

    # Call unblock if toggleable blacklist isn't being enforced so that the
    # permanent blacklist will still be updated.
    elif [[ "$1" == "p-blacklist" ]]; then
        > $PERM_BLACKLIST
        status_val=`cat $STATUS_FILE`
        if [[ "$status_val" == 0 ]]; then
            unblock
        else
            block
        fi
        echo "Permanent blacklist has been emptied!"
        
    elif [[ "$1" == "all" ]]; then
        "$0" -e blacklist
        "$0" -e p-blacklist

    else
        echo "Error: -e: valid arguments are 'blacklist', 'p-blacklist', 'all'"
    fi
}


# Toggle the enforced status of the toggleable blackist
toggle() {
    if [[ $(get_permission) == "false" ]]; then
        echo "Error: -t: password required to toggle blacklist status"
        exit
    fi

    if [[ $# -ge 1 ]]; then
        echo "Error: -t: this option does not take arguments"
        exit
    fi

    status_val=`cat $STATUS_FILE`
    if [[ "$status_val" == 0 ]]; then
        block
        echo "Blacklist is now IN FORCE!"
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    else
        unblock
        echo "Blacklist is NO LONGER ENFORCED."
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    fi
}


# Print the toggled status of the toggleable blacklist
show_status() {
    if [[ $# -ge 1 ]]; then
        echo "Error: -s: this option does not take arguments"
        exit
    fi

    status_val=`cat $STATUS_FILE`
    if [[ "$status_val" == 0 ]]; then
        echo "Toggleable blacklist is NOT ENFORCED."
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    else
        echo "Toggleable blacklist is ENFORCED!"
        echo "You may need to restart your internet browser or wait a few minutes to see changes."
    fi
}


# Output all URLs on a given blacklist. By default, prints contents of both
# (but only prints variants w/out www. for simplicity)
list() {
    if [[ $# -gt 1 ]]; then
        echo "Error: -l: please specify exactly one or zero arguments."
        echo "Options: 'blacklist', 'p-blacklist', 'all' (default)"
        exit
    fi

    if [[ "$1" == "blacklist" ]]; then
        echo "Toggleable blacklist:"

        blacklist_len=`wc -c < $BLACKLIST | tr -d " "`
        if [[ $blacklist_len == 0 ]]; then
            echo "    Empty"
        else
            while IFS= read -r line; do
                # Trim the first 10 chars to avoid printing the DNS info and tab
                [[ "$line" != *www.* ]] && echo "    ${line:10}"
            done < $BLACKLIST | sort
        fi

    elif [[ "$1" == "p-blacklist" ]]; then
        echo "Permanent blacklist:"

        p_blacklist_len=`wc -c < $PERM_BLACKLIST | tr -d " "`
        if [[ $p_blacklist_len == 0 ]]; then
            echo "    Empty"
        else
            while IFS= read -r line; do
                # Trim the first 10 chars to avoid printing the DNS info and tab
                [[ "$line" != *www.* ]] && echo "    ${line:10}"
            done < $PERM_BLACKLIST | sort
        fi
    
    elif [[ "$1" == "all" || $# == 0 ]]; then
        "$0" -l blacklist && echo
        "$0" -l p-blacklist

    else
        echo "Error: -l: valid arguments are 'blacklist', 'p-blacklist', 'all' (default)"
    fi
}


# Help menu
help() {
    echo "DESCRIPTION"
    echo "  Thanks for using Orwell! (c) 2024 pilgrim_tabby."
    echo "  Source code: https://github.com/pilgrimtabby/orwell"
    echo
    echo "  Easily block and unblock websites on MacOS."
    echo "  There are two blacklists, the togglable one (accessed using -a and -t)"
    echo "  and the permanent one (accessed using -x). The permanent one is always"
    echo "  active; the toggleable one can be enabled and disabled. Useful if you"
    echo "  want to allow some sites sometimes while always blocking others."
    echo
    echo "NOTE"
    echo "  Since Orwell operates on the DNS level, it cannot block only certain"
    echo "  pages on websites -- it blocks the whole website or not at all."
    echo
    echo "WARNING"
    echo "  Orwell modifies /etc/hosts and flushes the DNS cache."
    echo "  Use at your own risk."
    echo
    echo "OPTIONS"
    echo "  -a  Add URL(s) to the toggleable blacklist (use -t to enable/disable)."
    echo "      Usage:    orwell -a <URL> <URL> ..."
    echo "      Example:  orwell -a www.google.com"
    echo
    echo "  -x  Add URL(s) to the permanent blacklist."
    echo "      This list is always enforced, even if the toggleable blacklist is off."
    echo "      Usage:    orwell -x <URL> <URL> ..."
    echo "      Example:  orwell -x www.google.com"
    echo
    echo "  -d  Delete URL(s) from either or both blacklists."
    echo "      Usage:    orwell -d <URL> <URL> ..."
    echo "      Example:  orwell -d www.google.com"
    echo
    echo "  -e  Empty either or both blacklists."
    echo "      Usage:  orwell -e blacklist    (empty toggleable blacklist)"
    echo "              orwell -e p-blacklist  (empty permanent blacklist)"
    echo "              orwell -e all          (empty both blacklists)"
    echo
    echo "  -l  Output contents of either or both blacklists."
    echo "      Usage:  orwell -l | orwell -l all  (output both blacklists)"
    echo "              orwell -l blacklist        (output toggleable blacklist)"
    echo "              orwell -l p-blacklist      (output permanent blacklist)"
    echo
    echo "  -t  Toggle toggleable blacklist status (enforced vs. not enforced)."
    echo
    echo "  -s  Show toggleable blacklist status (enforced vs. not enforced)."
    echo
    echo "  -v  Show version number."
    echo 
    echo "  -h  Show this help message."
}


##################
#                #
# Helper methods #
#                #
##################


# Ask for / extend sudo authentication credentials
#
# Returns:
#   "true" if user enters correct password, "false" otherwise.
get_permission() {
    sudo -v &> /dev/null && echo "true" || echo "false"
}


# Find the line containing a given value in a given file.
#
# Line number starts at 1, since that is the convention used
# by sed, and this function is designed to work with sed.
#
# Args:
#   $1 (str): The value to search for.
#   $2 (str): Path the the file to search.
#
# Returns:
#   int: The line number, or -1 if the value isn't found.
find_url_line() {
    line_no=1
    while IFS= read -r line; do
        [[ "${line:10}" == "$1" ]] && echo $line_no && return
        ((line_no++))
    done < $2
    echo -1
}


# Flush the DNS cache.
# Doing this increases the chances of websites being blocked/unblocked
# properly without needing to restart the web browser.
flush_DNS() {
    os=`uname`  # Get operating system
    if [[ $os == "Darwin" ]]; then
        # Check system version. Versions after Big Sur (v. 11) don't need the
        # second-to-last command in this function.
        sys_version_full=`sw_vers -productVersion`
        sys_version_plain=${sys_version_full:0:2}
        [[ $sys_version_plain == *.* ]] && sys_version_plain=9

        [[ $sys_version_plain > 10 ]] && sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder
    else  # Linux
        # There are various methods for flushing the DNS cache that are distro-
        # dependent. We use all three here so we can be sure one method works,
        # and ignore the command-not-found and service-not-found errors.
        sudo resolvectl flush-caches &> /dev/null
        sudo killall -HUP dnsmasq &> /dev/null
        sudo systemctl restart nscd.service &> /dev/null
    fi
}


# Enforce the toggleable blacklist.
# A tmp file is used because echoing directly into /etc/hosts is difficult,
# even with sudo. sudo cp is much easier and straightforward to implement.
# This method is the only one that should be used to modify the status file
# except for unblock.
block() {
    tmp_file=$CONFIG_DIR"/tmp"
    awk "/# Orwell config/{exit}1" /etc/hosts > $tmp_file

    # This comment is informational, but it also gives us something to search
    # for for the `awk` command above and in unblock(). 
    echo "# Orwell config -- do not alter anything beyond this point" >> $tmp_file
    while IFS= read -r line; do
        echo "$line"
    done < $BLACKLIST >> $tmp_file
    while IFS= read -r line; do
        echo "$line"
    done < $PERM_BLACKLIST >> $tmp_file

    sudo cp $tmp_file /etc/hosts
    rm $tmp_file

    flush_DNS
    echo 1 > $STATUS_FILE
}


# Stop enforcing the toggleable blacklist.
# See block() for more details, since the methods are similar.
# This method is the only one that should be used to modify the status file
# except for block().
unblock() {
    tmp_file=$CONFIG_DIR"/tmp"
    awk "/# Orwell config/{exit}1" /etc/hosts > $tmp_file

    echo "# Orwell config -- do not alter anything beyond this point" >> $tmp_file
    while IFS= read -r line; do
        echo "$line"
    done < $PERM_BLACKLIST >> $tmp_file  # Put the perm. blacklist in, since it's always on
    
    sudo cp $tmp_file /etc/hosts
    rm $tmp_file

    flush_DNS
    echo 0 > $STATUS_FILE
}


##########
#        #
# Script #
#        #
##########

ORWELL_VERSION="v0.1.0"

main $@
