# Orwell

Block and unblock websites to maximize productivity. Compatible with MacOS only, but would probably work on Linux with a few tweaks.

I wrote this program for personal use and there might be bugs; feel free to add an issue or pull request.

# Usage

There are two blacklists, the togglable one (accessed using `-a` and `-t`) and the permanent one (accessed using `-x`). The permanent one is always active; the toggleable one can be enabled and disabled with the `-t` flag. This is useful if you want to allow some sites sometimes while always blocking others.

Orwell operates on the DNS level (see [Warning](#warning)), so it can't block individual pages on a website. For instance, you can't block individual groups on Facebook; you have to either block Facebook entirely or leave it unblocked.

## Options

Use flag `-a` to add URL(s) to the toggleable blacklist (use `-t` to enable/disable).

- Usage: `orwell -a <URL> <URL>` ...
- Example: `orwell -a www.google.com` adds google.com to the blacklist.

Use flag `-x` to add URL(s) to the permanent blacklist.

- Usage: `orwell -x <URL> <URL>` ...
- Example: `orwell -x www.google.com` adds google.com to the permanent blacklist.

Use flag `-d` to delete URL(s) from both blacklists.

- Usage: `orwell -d <URL> <URL>` ...
- Example: `orwell -d www.google.com` deletes google.com from any blacklist where it is present.

Use flag `-e` to empty either of the blacklists.

- Usage: `orwell -e blacklist` to empty the toggleable blacklist
- `orwell -e p-blacklist` to empty the permanent blacklist

Use flag `-t` to toggle toggleable blacklist status (enforced or not enforced).

Use flag `-s` to show toggleable blacklist status (enforced or not enforced).

Use flag `-l` to list all sites on both blacklists.

Use flag `-h` to show the help message.

## Examples

My friend Timmy is easily distracted while working, so he decides to block his favorite news and social media sites:

    orwell -a nytimes.com msnbc.com foxnews.com wsj.com reddit.com instagram.com

He's also trying to shake a bad online shopping habit, so he keeps certain sites blocked all the time:

    orwell -x amazon.com ebay.com etsy.com temu.com

When he opens his laptop to clock into work, he blocks his favorite sites by toggling the first blacklist:

    orwell -t

(He probably has to restart his internet browser for this to work.)

After he clocks out, he re-enables them so he can doomscroll while he eats dinner:

    orwell -t

He can't remember what sites he's blocked, so he prints them to the console:

    orwell -l

And so on. Use it however you want.

### Why does Orwell ask for my password?

Orwell uses your password to flush the DNS cache and edit `/etc/hosts` (see [Warning](#warning) below). This program doesn't gather or store any of your information or data.

# Installation

Download the source code and move `orwell` somewhere safe, like `/usr/local/bin`. You may need to run `chmod +x orwell` to make the program executable.

# Warning

Orwell works by modifying your `/etc/hosts` file and flushing the DNS cache. This should be generally harmless, but there is a small chance something could go wrong.

Orwell stores a backup of your `/etc/hosts` file in `~/.config/orwell/backup_file`. If you need to, you can use this file to restore `/etc/hosts` to its original state.

To uninstall Orwell, just delete it. You may also want to delete its configuration files, which are stored in `~/.config/orwell`. All modifications made to `/etc/hosts` are preceded with a comment that says "Orwell config", so if you want/need to delete those modifications, you can open `/etc/hosts` using `sudo nano` or another text editor program.
