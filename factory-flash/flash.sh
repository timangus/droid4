#!/bin/bash

DIR="${BASH_SOURCE%/*}"

USER=$(whoami)

FIRMWARE_DIR="${DIR}/VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml"

if [ ! -e ${FIRMWARE_DIR} ]
then
  echo "${FIRMWARE_DIR} doesn't exist, please extract VRZ_XT894_9.8.2O-72_VZW-18-8_CFC.xml.zip ee0c8151934b5893f58e58daea90e1b3 there"
  exit 1
fi

if [ "$USER" != "root" ];
then
  echo "Must be root."
  exit 1
fi

echo "Ensure device is in bootloader mode then press a key..."
read

cd ${FIRMWARE_DIR}
fastboot flash cdt.bin cdt.bin_patch
fastboot reboot-bootloader
fastboot flash emstorage emstorage.img 
fastboot reboot-bootloader
fastboot flash mbm allow-mbmloader-flashing-mbm.bin 
fastboot reboot-bootloader
fastboot flash mbmloader mbmloader.bin 
fastboot flash mbm mbm.bin 
fastboot oem fb_mode_set
fastboot reboot-bootloader
fastboot flash cdt.bin cdt.bin 
fastboot reboot-bootloader
fastboot erase cache
fastboot erase userdata
fastboot flash logo.bin logo.bin 
fastboot flash ebr ebr 
fastboot flash mbr mbr 
fastboot flash devtree device_tree.bin 
fastboot flash boot boot.img 
fastboot flash system system.img 
fastboot flash recovery recovery.img 
fastboot flash cdrom cdrom 
fastboot flash preinstall preinstall.img 
fastboot flash radio radio.img 
fastboot oem fb_mode_clear
fastboot reboot
