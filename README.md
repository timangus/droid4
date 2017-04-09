# Various hacks for the Motorola Droid 4 (XT894)
## factory-flash
A simple script that will restore to factory state given the relevant firmware zip file.
## root
A script to root a factory flashed device.
## altpart-safestrap
This is an alternative SafeStrap (derived from https://github.com/stargo/android_packages_apps_Safestrap/releases) that
makes use of the unused `/webtop` partition and repurposes it as the `/system` parition. This alleviates the issue where
the original `/system` is not large enough to contain more modern ROMs and `gapps`.
