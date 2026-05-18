# Ultaro

_The OS should be a thin layer between me and getting my work done._

* **Minimal**: less things to break or get in the way
* **Secure**: always up-to-date rolling release
* **Stable**: avoid breaking changes whenever possible
* **Efficient**: lightweight and fast
* **Beautiful**: consistent look and feel
* **Power user friendly**: scripted hotkeys and automation

## Install

The Ultaro setup is meant to be run after a clean [Manjaro Linux](https://manjaro.org).

Download or clone the repository then run the `setup` executable. For instance, from the terminal:

```sh
git clone --depth 1 https://github.com/UltCombo/ultaro.git
./ultaro/setup
```

The setup script is mostly [idempotent](https://en.wikipedia.org/wiki/Idempotence), meaning it can be run again to update Ultaro or in case of unexpected failures.

Please note Ultaro is in the process of gradually migrating away from the GNOME desktop environment in favor of a simpler, stable i3wm setup.

GNOME is an excellent community project. However, it had many breaking changes (extension APIs, X11 removal) over the years. This goes agaisnt our goals: users shouldn't spend their precious time fixing broken stuff, so we are moving away from it.

## Features

- Vivaldi
  - Privacy - block ad and trackers
  - uBlock Origin - no allow list, block cookie notices
  - Tab Management
    - Organization: workspaces, tab stacks
    - Mark unread tabs
    - Close Duplicate or inactive tabs
  - Speed dial and history search
  - Browser Launcher - Open links in private window by default
    - Prevent leaking cross-site info
    - Don't pollute history - keep it tidy for autocomplete
    - Fight tab hoarding - private tabs are ephemeral
  - DuckDuckGo as default search engine
    - No Ads (disabled via query parameters)
    - Not affected by "SEO optimizations" targeted at Google
    - Duck.ai
    - Custom theme
    - Bangs (ex. !yt to search YouTube)
- Volume controls
  - Boost audio output over 100%
  - Global hotkey to mute mic
- Screenshot
  - Capture whole screen or area
  - Automatically copy to clipboard
- Terminal
  - Quick toggle (Super+`)
  - fish
    - History autocomplete based on directory
    - Autocomplete and syntax highlight (commands, paths)
    - Abbreviations
- Notifications
  - Auto dismiss on timeout
    - Do not auto dismiss if idle
    - Do not auto dismiss urgent notifications
  - Persistent history
  - Custom notifications
  - Do Not Disturb hotkey
- Locking controls
  - Locking sets display on standby (turn off, turn on on input)
  - Closing laptop lid does not lock
