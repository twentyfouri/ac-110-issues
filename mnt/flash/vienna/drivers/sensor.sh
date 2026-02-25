#!/bin/sh
insmod vpl_vic.ko gdwSignalWaitTime=4000 > /dev/null 2>&1;
#insmod GC2053.ko
insmod GC2053_24MHz.ko
