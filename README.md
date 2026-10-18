# MacDown for Apple silicon

A port of [MacDown](https://github.com/MacDownApp/macdown) for Apple silicon (arm64), maintained by Guglielmo Pasa. It builds on the arm64 port by [wltb](https://github.com/wltb/macdown-arm64); the upstream project targets x86, which Apple is phasing out.

MacDown is an open source Markdown editor for macOS, released under the MIT License. The author was inspired by [Chen Luo](https://twitter.com/chenluois)’s [Mou](http://mouapp.com).

## What this fork adds

* **Preview on WKWebView**, with stylesheets embedded in the page so every style applies.
* **New document styles**: GitHub Moderne (readable tables, wide tables scroll horizontally), Lecture (sepia, serif), Nuit (dark) and Académique (serif, booktabs tables).
* **Sticky headings**: chapter and section titles and table headers stay at the top while scrolling (Preferences › Rendering).
* **Live style preview** in Preferences › Rendering, updated as you hover the style menu or pick a code theme; all preference panes share one size.
* **Quick Look**: press space on a `.md` file in Finder for a preview rendered with your MacDown style.
* Signed with a Developer ID, notarized, and updated through Sparkle from this repository.

## Install

[Download the latest release](https://github.com/gpasa/macdown-arm64/releases/latest), unzip, and drag MacDown to the Applications folder. Requires macOS 26 on Apple silicon. Later versions install from within the app (MacDown › Check for Updates).

For x86 builds, visit the [original project site](http://macdown.uranusjr.com/).

## Screenshot

![screenshot](assets/screenshot.png)

## License

MacDown is released under the terms of MIT License. You may find the content of the license [here](http://opensource.org/licenses/MIT), or inside the `LICENSE` directory.

You may find full text of licenses about third-party components in the `LICENSE` directory, or the **About MacDown** panel in the application.

The following editor themes and CSS files are extracted from [Mou](http://mouapp.com), courtesy of Chen Luo:

* Mou Fresh Air
* Mou Fresh Air+
* Mou Night
* Mou Night+
* Mou Paper
* Mou Paper+
* Tomorrow
* Tomorrow Blue
* Tomorrow+
* Writer
* Writer+
* Clearness
* Clearness Dark
* GitHub
* GitHub2

## Development

### Requirements

If you wish to build MacDown yourself, you will need the following components/tools:

* macOS 26 SDK (Xcode 26 or later)
* Git
* [Bundler](http://bundler.io)

> Note: Old versions of CocoaPods are not supported. Please use Bundler to execute CocoaPods, or make sure your CocoaPods is later than shown in `Gemfile.lock`.

> Note: The Command Line Tools (CLT) should be unnecessary. If you failed to compile without it, please install CLT with
>
>     xcode-select --install
>
> and report back.

### Environment Setup

After cloning the repository, run the following commands inside the repository root (directory containing this `README.md` file):

    git submodule update --init
    bundle install
    bundle exec pod install
    make -C Dependency/peg-markdown-highlight

and open `MacDown.xcworkspace` in Xcode. The first command initialises the dependency submodule(s) used in MacDown; the second one installs dependencies managed by CocoaPods.

Refer to the official guides of Git and CocoaPods if you need more instructions. If you run into build issues later on, try running the following commands to update dependencies:

    git submodule update
    bundle exec pod install

### Translation

Please help translation on [Transifex](https://www.transifex.com/macdown/macdown/).

![Transifex translation percentage](https://www.transifex.com/projects/p/macdown/resource/macdownxliff/chart/image_png/)

## Discussion

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MacDownApp/macdown)

Join our [Gitter channel](https://gitter.im/MacDownApp/macdown) if you have any problems with MacDown. Any suggestions are welcomed, too!

You can also [file an issue directly](https://github.com/MacDownApp/macdown/issues/new) on GitHub if you prefer so. But please, **search first to make sure no-one has reported the same issue already** before opening one yourself. MacDown does not update in your computer immediately when we make changes, so something you experienced might be known, or even fixed in the development version.

MacDown depends a lot on other open source projects, such as [Hoedown](https://github.com/hoedown/hoedown) for Markdown-to-HTML rendering, [Prism](http://prismjs.com) for syntax highlighting (in code blocks), and [PEG Markdown Highlight](https://github.com/ali-rantakari/peg-markdown-highlight) for editor highlighting. If you find problems when using those particular features, you can also consider reporting them directly to upstream projects as well as to MacDown’s issue tracker. I will do what I can if you report it here, but sometimes it can be more beneficial to interact with them directly.

## Tipping

If you find MacDown suitable for your needs, please consider [giving me a tip through PayPal](http://macdown.uranusjr.com/faq/#donation). Or, if you prefer to buy me a drink *personally* instead, just [send me a tweet](https://twitter.com/uranusjr) when you visit [Taipei, Taiwan](http://en.wikipedia.org/wiki/Taipei), where I live. I look forward to meeting you!

