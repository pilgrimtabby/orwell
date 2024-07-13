# Orwell
Block and unblock websites to maximize productivity. MacOS only, but would probably work on Linux with a few tweaks.

I wrote this program for personal use and there might be bugs; feel free to add an issue or pull request.

# Usage

Use flag `-a` to add one or more URLs to the blacklist. This blacklist can be enabled/disabled.

- Usage: `orwell -a <URL> <URL>` ...
- Example: `orwell -a www.google.com` adds google.com to the blacklist.

Use flag `-x` to specify one or more URLs to block always, even when the blacklist isn't enforced. This list is called the permanent blacklist.

- Usage: `orwell -x <URL> <URL>` ...
- Example: `orwell -x www.google.com` adds google.com to the permanent blacklist.

Use flag `-d` to delete one or more URLs from all blacklists.

- Usage: `orwell -d <URL> <URL>` ...
- Example: `orwell -d www.google.com` deletes google.com from either or both blacklists if it is present.

Use flag `-e` to empty the blacklist or the permament blacklist.

- Usage: `orwell -e blacklist` to empty the blacklist
- `orwell -e p-blacklist` to empty the permanent blacklist

Use flag `-t` to toggle blacklist status (enforced or not enforced).

Use flag `-s` to show blacklist status (enforced or not enforced).

Use flag `-l` to list all sites on both blacklists.

Use flag `-h` to show the help message.

### Why does Orwell ask for my password?

Orwell needs your password to flush the DNS cache and edit `/etc/hosts` (see [Warning](#warning) below). This program doesn't gather or store any information or data.

# Installation

Simply download the source code and move `orwell` to wherever you want it, like `/usr/local/bin`. You may need to run `chmod +x orwell` to make it executable.

# Warning

Orwell modifies your `/etc/hosts` file and flushes the DNS cache. This should be generally harmless, but things could rarely go wrong, so you've been warned.

To uninstall Orwell, just delete it. You may also want to delete its configuration files, which are stored in `~/.config/orwell`. All modifications made to `/etc/hosts` are preceded with a comment that says "Orwell config", so if you want/need to delete those modifications, you can open `/etc/hosts` and do so using `sudo nano` or another text editor program.
