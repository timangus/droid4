#!/bin/bash

DIR=$(realpath ${BASH_SOURCE%/*})
. ${DIR}/utils.sh

FILE=$1

if [ ! -e ${FILE} ]
then
  echo "${FILE} doesn't exist"
  exit 1
fi

MD5=($(md5sum $1))
BASE_FILE=$(basename ${FILE})
FILE_DIR=$(dirname `realpath ${FILE}`)
PATCH_FILE=altpart-patch-${BASE_FILE}

BUILD_DIR="/tmp/altpart-patch"

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

# Extract from ROM zip
echo "=== Extracting from ROM zip ===================================================="
unzip -d ${BUILD_DIR} ${FILE} \
  system/addon.d/50-cm.sh \
  system/etc/kexec/ramdisk.img || exit $?

echo "=== Patching 50-cm.sh =========================================================="
# Patch 50-cm.sh so our patched ramdisk.img gets restored after an upgrade
patch -d ${BUILD_DIR} -p0 -F3 <<< \
"--- system/addon.d/50-cm.sh	2017-03-01 12:00:00.000000000 +0000
+++ system/addon.d/50-cm.sh	2017-03-01 12:00:00.000000000 +0000
@@ -10,6 +10,7 @@
 list_files() {
 cat <<EOF
 etc/hosts
+etc/kexec/ramdisk.img
 EOF
 }" || exit $?

ROM_RAMDISK="${BUILD_DIR}/system/etc/kexec/ramdisk.img"

echo "=== Splitting ramdisk.img ======================================================"
# Split the ramdisk.img into its two constituent gzipped images (in the case of
# CM12+)
splitRamdiskImage ${ROM_RAMDISK} ${BUILD_DIR}

echo "=== Extracting ramdisk.img ====================================================="
unpackRamdiskImage \
  ${BUILD_DIR}/ramdisk.img.2.cpio.gz \
  ${BUILD_DIR}/ramdisk || exit $?

echo "=== Patching fixboot.sh ========================================================"
# Patch fixboot.sh so that we can boot our new partition layout
patch -d ${BUILD_DIR} -p0 -F3 <<< \
"--- ramdisk/sbin/fixboot.sh	2017-03-01 12:00:00.000000000 +0000
+++ ramdisk/sbin/fixboot.sh	2017-03-01 12:00:00.000000000 +0000
@@ -10,7 +10,12 @@
 
 SLOT_LOC=\$(/sbin/bbx cat /ss/safestrap/active_slot)
 
-if [ \"\$SLOT_LOC\" != \"stock\" ]; then
+if [ \"\$SLOT_LOC\" = \"altpart\" ]; then
+/sbin/bbx mv /dev/block/system /dev/block/systemorig
+/sbin/bbx ln -s /dev/block/webtop /dev/block/system
+
+/sbin/bbx umount /ss
+elif [ \"\$SLOT_LOC\" != \"stock\" ]; then
 # setup loopbacks
 /sbin/bbx losetup /dev/block/loop-system /ss/safestrap/\$SLOT_LOC/system.img
 /sbin/bbx losetup /dev/block/loop-userdata /ss/safestrap/\$SLOT_LOC/userdata.img" || \
   exit $?

echo "=== Repacking ramdisk.img ======================================================"
packRamdiskImage \
  ${BUILD_DIR}/ramdisk \
  ${BUILD_DIR}/ramdisk-patched.img.2.cpio.gz || exit $?

cat ${BUILD_DIR}/ramdisk.img.1.cpio.gz \
  ${BUILD_DIR}/ramdisk-patched.img.2.cpio.gz > \
  ${ROM_RAMDISK}

echo "=== Creating installer ========================================================="
mkdir -p ${BUILD_DIR}/META-INF/com/google/android

echo -en \
"ui_print(\"=== ROM patch for alternative partition layout ======\");
ui_print(\"\");
ui_print(\"  * ${BASE_FILE}\");
ui_print(\"  * ${MD5}\");

ui_print(\"Mounting /system...\");
mount(\"ext3\", \"EMMC\", \"/dev/block/system\", \"/system\");
ui_print(\" Replacing /system/addon.d/50-cm.sh\");
ui_print(\" Replacing /system/etc/kexec/ramdisk.img\");
package_extract_dir(\"system\", \"/system\");
ui_print(\"Unmounting /system...\");
unmount(\"/system\");\n" > \
  ${BUILD_DIR}/META-INF/com/google/android/updater-script

cp ${DIR}/update-binary ${BUILD_DIR}/META-INF/com/google/android/

echo "=== Creating patch zip ========================================================="
pushd ${BUILD_DIR}
zip -r9 _${PATCH_FILE} system/ META-INF/

echo "=== Signing patch zip =========================================================="
java -jar ${DIR}/signapk/signapk.jar ${DIR}/signapk/key.x509.pem \
  ${DIR}/signapk/key.pk8 _${PATCH_FILE} ${FILE_DIR}/${PATCH_FILE} || exit $?

echo "=== Cleaning up ================================================================"
popd
rm -rf ${BUILD_DIR}

echo "Done!"
