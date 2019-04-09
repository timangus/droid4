#!/bin/bash
#
# Script to create Safestrap-maserati-v3.75-altpart.tar.gz from the apk file
# to provide bootable SafeStrap recovery for droid4-kexecboot
#

APK=$1

if [ "${APK}" == "" ] || [ ! -e ${APK} ]; then
   echo "usage: $0 Safestrap-file.apk"
   exit 1
fi

if ! TMPDIR=$(mktemp -d); then
    echo "could not make tmp dir"
    exit 1
fi

if ! mkdir ${TMPDIR}/files; then
    echo "could not create directory for files"
    exit 1
fi

echo "unzipping ${APK}.."
if ! unzip -q -d ${TMPDIR}/files ${APK}; then
    echo "could not unzip apk"
    exit 1
fi

echo "unzipping install-files.zip.."
if ! unzip -q -d ${TMPDIR}/files ${TMPDIR}/files/assets/install-files.zip; then
    echo "could not unzip install-files.zip"
    exit 1
fi

if ! mkdir -p ${TMPDIR}/boot/safestrap; then
    echo "could not mkdir safestrap directory"
    exit 1
fi

echo "moving files to ${TMPDIR}/boot/safestrap.."
if ! mv ${TMPDIR}/files/install-files/etc/safestrap/* ${TMPDIR}/boot/safestrap/; then
    echo "could not move install-files"
    exit 1
fi

echo "removing unpacked files.."
if ! rm -rf ${TMPDIR}/files; then
    echo "could not remove unpacked files"
    exit 1
fi

echo "creating kexecboot boot.cfg file.."
if ! cat > ${TMPDIR}/boot/boot.cfg <<EOF
LABEL=SafeStrap recovery
PRIORITY=1
DTB=/boot/safestrap/kexec/devtree
KERNEL=/boot/safestrap/kexec/kernel
INITRD=/boot/safestrap/ramdisk-recovery.img
CMDLINE="androidboot.safestrap=recovery"
EOF
then
    echo "could not create boot.cfg"
    exit 1
fi

echo "files for recovery copied and configured:"
find ${TMPDIR}/

TGZ=$(basename -s .apk ${APK}).tar.gz
echo "creating ${TGZ} file.."
if ! tar zcf ${TGZ}  -C ${TMPDIR} .; then
    echo "could not create ${TGZ}"
    exit 1
fi

echo "all done"

echo "sha256 for original apk file ${APK}:"
sha256sum ${APK}

echo "sha256 for new tar.gz file ${TGZ}:"
sha256sum ${TGZ}
