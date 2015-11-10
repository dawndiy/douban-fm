#!/bin/bash

./build-click-package.sh douban-fm ubuntu-sdk-15.04 vivid
adb push douban-fm.ubuntu-dawndiy_0.2.1_armhf.click /home/phablet
adb shell 'pkcon install-local douban-fm.ubuntu-dawndiy_0.2.1_armhf.click --allow-untrusted'

