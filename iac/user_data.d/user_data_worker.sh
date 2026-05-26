#!/bin/bash
set -euxo pipefail

apt-get update -y
apt-get install -y git make parted

DEVICE=/dev/xvdf
PARTITION=${DEVICE}1
MOUNT_POINT=/mnt/data
LINK_PATH=/home/ubuntu/data

while [ ! -b "$DEVICE" ]; do
  echo "Waiting for $DEVICE to be attached..."
  sleep 2
done

if ! lsblk -f | grep -q "${PARTITION}"; then
  parted -s $DEVICE mklabel gpt
  parted -s -a opt $DEVICE mkpart primary ext4 0% 100%
  mkfs.ext4 $PARTITION
fi

mkdir -p $MOUNT_POINT

if ! mount | grep -q "$MOUNT_POINT"; then
  mount $PARTITION $MOUNT_POINT
fi

chown -R ubuntu:ubuntu $MOUNT_POINT

UUID=$(blkid -s UUID -o value $PARTITION)
grep -q "$UUID" /etc/fstab || echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >>/etc/fstab

if [ ! -L "$LINK_PATH" ]; then
  ln -s $MOUNT_POINT $LINK_PATH
  chown -h ubuntu:ubuntu $LINK_PATH
fi
