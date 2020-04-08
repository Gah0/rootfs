#!/bin/bash

INITRD_IMG_OUTPUT_PATH="/home/gah0/rootfs"
ROOTFS_NAME="myinitrd.img"

mkdir dev etc lib proc bin sbin sys

echo dir:'pwd'

cat > etc/init.d/rcS << EOF
echo "======================="
echo "| Gah0 busybox System |"
echo "======================="
mkdir -p /proc
mkdir -p /tmp
mkdir -p /sys
mkdir -p /mnt
/bin/mount -a

mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotpulg
mdev -s
EOF

chmod +x ./etc/init.d/rcS
cat > etc/fstab << EOF
proc /proc proc defaults 0 0
tmpfs /tmp tmpfs default 0 0
sysfs /sys sysfs default 0 0
tmpfs /dev tmpfs default 0 0
EOF

cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/unmount -a -r
EOF

cd dev
mknod console c 5 1
mknod mknod null c 1 3
sudo cp /dev/zero ./dev/ -a
sudo cp /dev/*tty* ./dev/ -a

dd if=/dev/zero of=$INITRD_IMG_OUTPUT_PATH/$ROOTFS_NAME bs=1024 count=8192
mkfs.ext2 -F $ROOTFS_NAME 
sudo mkdir /mnt/initrd
sudo mount -t ext2 -o loop myinitrd.img /mnt/initrd
sudo cp rootfs/* /mnt/initrd/ -a
sudo umount /mnt/initrd

echo "写入镜像成功"
sudo cp $ROOTFS_NAME /boot/


echo "修改grub文件"
sed -i '/^\#GRUB_HEDDEN_TIMEOUT=0/d' /boot/grub.cfg
sudo cat > /boot/grub.cfg << EOF
menuentry "Fuck busybox"{
	insmod part_msdos
	insmod ext2
	insmod gzio
	set root='(hd0,msdos1)'
	linux /boot/initframlinuz-5.3.0-45-generic  rw root=UUID=4046321b-7e46-4a61-90aa-3740ddd1be5b
	initrd /boot/myinitrd.img
}
EOF

echo "successfully build rootfs"
