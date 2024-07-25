# Orwell

Block and unblock websites at the DNS level to maximize productivity.

Compatible with Linux (tested on Ubuntu 20.04 LTS) and MacOS (tested on MacOS Ventura).

I wrote this program for personal use and there might be bugs; feel free to add an issue or pull request.

# Usage

There are two blacklists, the togglable one (accessed using `-a` and `-t`) and the permanent one (accessed using `-x`). The permanent one is always active; the toggleable one can be enabled and disabled with the `-t` flag. This is useful if you want to allow some sites sometimes while always blocking others.

Orwell operates on the DNS level (see [Warning](#warning)), so it can't block individual pages on a website. For instance, you can't block individual groups on Facebook; you have to either block Facebook entirely or leave it unblocked.

## Options

Use flag `-a` to add URL(s) to the toggleable blacklist (use `-t` to enable/disable).

- Usage: `orwell.sh -a <URL> <URL>` ...
- Example: `orwell.sh -a www.google.com` adds google.com to the blacklist.

Use flag `-x` to add URL(s) to the permanent blacklist.

- Usage: `orwell.sh -x <URL> <URL>` ...
- Example: `orwell.sh -x www.google.com` adds google.com to the permanent blacklist.

Use flag `-d` to delete URL(s) from both blacklists.

- Usage: `orwell.sh -d <URL> <URL>` ...
- Example: `orwell.sh -d www.google.com` deletes google.com from any blacklist where it is present.

Use flag `-e` to empty either or both blacklists.

- Usage: `orwell.sh -e blacklist` to empty the toggleable blacklist
- `orwell.sh -e p-blacklist` to empty the permanent blacklist
- `orwell.sh -e all` to empty both blacklists

Use flag `-l` to output the contents of either or both blacklists.

- Usage: `orwell.sh -l` or `orwell.sh -l all` to output both blacklists' contents
- `orwell.sh -l blacklist` to output the contents of the toggleable blacklist
- `orwell.sh -l p-blacklist` to output the contents of the permanent blacklist

Use flag `-t` to toggle toggleable blacklist status (enforced or not enforced).

Use flag `-s` to show toggleable blacklist status (enforced or not enforced).

Use flag `-v` to display current version number.

Use flag `-h` to show the help message.

## Examples

Let's say you're easily distracted while working. You can block your favorite news and social media sites:

    orwell.sh -a nytimes.com msnbc.com foxnews.com wsj.com reddit.com instagram.com

Maybe you're trying to shake an online shopping habit. You can keep certain sites blocked always:

    orwell.sh -x amazon.com ebay.com etsy.com temu.com

When you open your laptop to get something done, you can block your favorite sites by toggling the first blacklist:

    orwell.sh -t

(You might have to restart your browser and/or wait a few minutes.)

Later, you can re-enable them:

    orwell.sh -t

If you can't remember what sites are blocked, you can print them to the console:

    orwell.sh -l

And so on. Use it however you want.

### Why does Orwell ask for my password?

Orwell uses your password to flush the DNS cache and edit `/etc/hosts` (see [Warning](#warning) below). This program doesn't gather or store any of your information or data.

# Installation

Download the source code and move `orwell.sh` somewhere safe, like `/usr/local/bin`. You may need to run `chmod +x orwell.sh` to make the program executable.

# Warning

Orwell works by modifying your `/etc/hosts` file and flushing the DNS cache. This should be generally harmless, but there is a small chance something could go wrong.

Orwell stores a backup of your `/etc/hosts` file in `~/.config/orwell/backup_file`. If you need to, you can use this file to restore `/etc/hosts` to its original state.

To uninstall Orwell, just delete it. You may also want to delete its configuration files, which are stored in `~/.config/orwell`. All modifications made to `/etc/hosts` are preceded with a comment that says "Orwell config", so if you want/need to delete those modifications, you can open `/etc/hosts` using `sudo nano` or another text editor program.
