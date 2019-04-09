# Various hacks for the Motorola Droid 4 (XT894)
## factory-flash
A simple script that will restore to factory state given the relevant firmware zip file.
## root
A script to root a factory flashed device.
## altpart-safestrap
This is an alternative [SafeStrap](https://github.com/stargo/android_packages_apps_Safestrap/releases) that makes use of the unused `/webtop` partition and repurposes it as the `/system` parition. This alleviates the issue where the original `/system` is not large enough to contain a more modern ROM with a gapps package.

After installing the replacement recovery you will find an extra option on the slot selection UI; *Webtop -> System*. Selecting this will use `/webtop` as the `/system` partition when installing. Please note that all the other partitions *stay the same* and are not altered from their stock configuration. This is a key point because it means that the new slot is not a slot in the usual sense in that except for `/system`, all other partitions are *shared* with the stock slot. In order words, attempting to use the stock slot and the *Webtop -> System* slot at the same time is highly unlikely to work and should be avoided.

In order for a ROM to boot from the `/webtop` partition, it must first be patched so that it recognises the new slot configuration. A script is provided [patch-rom.sh](https://github.com/timangus/droid4/blob/master/altpart-safestrap/patch-rom.sh) which when invoked with a zip file such as [lineage-14.1-20170405-UNOFFICIAL-maserati.zip](http://droid.cs.fau.de/lineage-14.1/lineage-14.1-20170405-UNOFFICIAL-maserati.zip), will produce an *altpart-patch* file in the same directory. This much be flashed immediately after the main ROM zip, or the ROM **will not boot**.

Many thanks to Mentor.37 for the [*unused partitions*](http://www.internauta37.altervista.org/en/xt894-and-xt912-safestrap-375-unused-partitions-preinstall-webtop) recovery that served as a great reference as to how to make use of the webtop partition.

Please note this recovery should be considered **highly experimental** and may brick your phone and/or eat your dog etc.. Having said that I've been using it for the past few days and it seems to be working fine. All the scripts have been developed on Linux to run on Linux, but there is no intrinsic reason why they shouldn't work fine under cygwin/git bash/Ubuntu for windows etc., but I have not tested any of this. Patches welcome :).

Finally, contained in this repository are a build of the modified SafeStrap and a patch for the latest Lineage ROM mentioned above. I'm not 100% on the intricacies of the legal position over distribution of these so if anybody thinks it's an issue let me know and I'll take them down. Don't see why though, really. In any case, the scripts can be used to rebuild the recovery and the patch as required.

#### [Safestrap-maserati-v3.75-altpart.apk](https://github.com/timangus/droid4/blob/master/binaries/Safestrap-maserati-v3.75-altpart.apk)
#### [Safestrap-maserati-v3.75-altpart.tar.gz](https://github.com/timangus/droid4/blob/master/binaries/Safestrap-maserati-v3.75-altpart.tar.gz)
#### [altpart-patch-lineage-14.1-20170405-UNOFFICIAL-maserati.zip](https://github.com/timangus/droid4/blob/master/binaries/altpart-patch-lineage-14.1-20170405-UNOFFICIAL-maserati.zip)
