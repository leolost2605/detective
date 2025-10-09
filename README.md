<div align="center">
  <img alt="An icon representing an open book and a magnifying glass" src="data/128.svg" />
  <h1>Detective</h1>
  <h3>Quickly search through apps and files</h3>
  <a href="https://elementary.io"><img src="https://ellie-commons.github.io/community-badge.svg" alt="Made for elementary OS"></a>
<span align="center"> <img class="center" src="https://github.com/leolost2605/detective/blob/main/data/screenshots/Search%20fi.png" alt="Search results showing various apps below a search field"><span>
</div>
<br/>

## Installation

You can download and install Detective here:

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg?new)](https://appcenter.elementary.io/io.github.leolost2605.detective/) 


## Building, Testing, and Installation

Run `flatpak-builder` to configure the build environment, download dependencies, build, and install

    flatpak-builder build io.github.leolost2605.detective.yml --user --install --force-clean --install-deps-from=appcenter

execute with `io.github.leolost2605.detective`

    flatpak run io.github.leolost2605.detective

## What to expect

Nothing fancy.
This is more of a sideproject for me where I want to try the power of GTK's ListModels, Expressions, Sorters and Filters.
If something useful comes from it, great, if not experience was gained :)

## Credits

Many things here (especially the plugins like Calculations) were inspired and taken from synapse and the elementary applications menu. Huge credit to them <3

Icon taken from [Wikimedia](https://commons.wikimedia.org/wiki/File:Book_%28Search%29.svg) by [Wikmoz](https://commons.wikimedia.org/wiki/User:Wikmoz) <3
