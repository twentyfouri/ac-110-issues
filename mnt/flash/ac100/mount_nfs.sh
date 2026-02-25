#!/bin/sh

mkdir /tmp/nfs
chmod 777 /tmp/nfs/
mount -t nfs -o nolock 192.168.8.195:/home/ubuntu/sdk_v2.5.5 /tmp/nfs/

mkdir /tmp/nfs2
chmod 777 /tmp/nfs2/
mount -t nfs -o nolock 192.168.8.132:/home/ubuntu/sdk_v2.5.5 /tmp/nfs2/

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib
