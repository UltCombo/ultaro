# Ultaro

Ultaro is a minimalistic, secure, performant, beautiful desktop environment with power users in mind.

Based on [GNOME](https://www.gnome.org/gnome-3/), Ultaro draws inspiration from the best parts of MacOS and Windows with further UX enhancements.

## Install

The Ultaro setup is meant to be run after a clean [Manjaro Linux](https://manjaro.org/get-manjaro/) GNOME installation.

Download or clone the repository then run the `setup` executable. For instance, from the terminal:

```sh
git clone --depth 1 https://github.com/UltCombo/ultaro.git
./ultaro/setup
```

## Guiding principles

### Performance, security and freshness

Ultaro is a set of modifications and customizations on top of Manjaro Linux. Manjaro Linux, being based on Arch Linux, is an always up-to-date distribution with the latest kernels and packages. This is invaluable to performance and security. It also provides an excellent package manager with hooks support, which greatly facilitates customizing software while keeping it up-to-date.

### User experience

Ultaro prevents distractions as much as possible.

Maximizing an application window automatically hides the top bar, dock and window title bar. This allows the user to focus in what really matters: the current application.

The dock and top bar can be revealed by pushing the cursor towards the edge of screen, similarly to other implementations such as MacOS but with notable UX improvements:

- It implements the concept of "pressure", the user has to push the cursor further than the edge of the screen to reveal the off-screen elements. This prevents accidental triggers by hovering elements near edge of the screen, while keeping the off-screen elements easily accessible by a single quick swipe with the pointing device.

- Application windows can be maximized taking the whole viewport. This an improvement over other implementations such as MacOS that reserve a small hover area to reveal off-screen elements: that simply does not work as good as the pressure concept and just wastes screen real estate.

The application switcher (`Alt`+`Tab`) also works similarly to the MacOS implementation, grouping windows by application and allowing to quit selected applications by pressing `Q`. Displaying just applications instead of all application windows allows reaching the desired target faster. As a further UX enhancement, the application switcher allows selecting a specific window from the selected application with `Alt`+`` ` `` as well as closing windows by pressing `W` without leaving the switcher interface.

The screenshot tool also improves upon the MacOS implementation, providing more features and better usability. It provides similar capture options such as full desktop (`Print`), current screen (`Ctrl`+`Print`) and GUI/selection (`Shift`+`Print`). The GUI capture provides extra features such as adjusting the selection and drawing on it.

As a rule of thumb, unnecessary elements should be removed to prevent distractions and preserve user focus. Such unnecessary elements include:

- Window control buttons: minimize is useless, maximize/restore can be achieved with `Super`+`↑`/`Super`+`↓` respectively, closing windows can be achieved with `Ctrl`+`W`, `Ctrl`+`Shift`+`W` (in tabbed applications) or `Alt`+`F4`, or `Ctrl`+`Q` to quit application.

- Close buttons in tabs: it is much easier and faster to close tabs with `Ctrl`+`W` or, in the worst scenario (off-hand away from keyboard to grab coffee mug or phone), with a mouse middle-click or touchpad three-finger-click anywhere in the tab title, which is much easier than clicking a very small close button. This removes the visual clutter of the unnecessary close button and leaves more room for the tab title text.

- Window title bar: they rarely hold any useful information, usually it can be inferred from the window content or from tab titles in tabbed applications. As previously noted, title bars are a waste of screen real estate and are automatically hidden for maximized windows.

- Dock and top bar: these are automatically hidden to maximize usable area and prevent distractions. Most important resources should be quickly accessible via shortcuts, for example the Emoji Selector can be triggered with `Super`+`E` even when the top bar is hidden. The dock is useful to quickly launch the most important apps, but not much besides that: it is more efficient to switch between applications with the application switcher (`Alt`+`Tab`) and launch other apps from Activities Overview search (`Super` key, similar to MacOS Spotlight Search).

### Privacy

Ultaro avoids any unnecessary interactions with third-party services. Several companies provide software and services with the sole purpose of unsolicitedly gathering your information to be used against you. Therefore, no software from Google or Mozilla is included in this distribution.

Ultaro provides Vivaldi as the default web browser. It is basically an improved Google Chrome with more features and customization, without the Google brand behind it.

Ultaro promotes installing as few native applications and packages as possible without negatively affecting user experience. Every package is seen as a possible point of failure: they have full access to disk and network, thus a single compromised registry or maintainer may result in stolen private documents and credentials.

As such, web applications should be preferred over native applications. Web applications are always up-to-date and run inside a secure sandboxed environment with strict permissions management. Web applications are also cross-platform: being more accessible means people on different platforms can collaborate using the same tools. The [Web platform](https://en.wikipedia.org/wiki/Web_platform) is thus the ultimate applications delivery platform.

## Misc

### What is the motivation behind Ultaro?

I've used MacOS for 3 years and Windows for over a decade. As a power user, I always felt that these desktop environments never suited my needs completely. Although MacOS generally provides excellent UX, the lack of customization became a killer after a couple years bearing its limitations and shortcomings.

I've been developing, experiencing and evolving my desktop environment for over 6 months before open-sourcing it as Ultaro. My goal is to provide a desktop environment that is simple and pleasant for power users to use.

### Why the Mega Man wallpapers?

Mega Man is a super hero: he takes the best parts of its enemies and adapts to handle every situation.

Mega Man is the perfect analogy for Ultaro.
