#!/bin/bash

INITRD_IMG_OUTPUT_PATH="/home/gah0/rootfs-master"
ROOTFS_NAME="myinitrd.img"


sudo apt-get install libncurses5-dev
cd /busybox
echo "开始编译busybox"
sudo make user_defconfig
sudo make
sudo make install
if[ $? -eq 0];then
	echo "成功编译"
	cp ./_install/\* ..
	cd ..
	rm -r /busybox_1.31.0



mkdir dev etc lib proc bin sbin sys

echo dir:'pwd'

cat > etc/init.d/rcS << EOF
echo "======================="
echo "|  Shortsight System  |"
echo "======================="
EOF
chmod +x ./etc/init.d/rcS

cat > etc/profile << EOF
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/usr/lib
PS1='[\u@\h \W]# '
EOF

cat > etc/fstab << EOF
proc /proc proc defaults 0 0
none /tmp ramfs default 0 0
mdev /dev ramfs default 0 0
sysfs /sys sysfs default 0 0
EOF

cat > etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
tty2::askfirst:-/bin/sh
::ctrlaltdel:/bin/unmount -a -r
EOF

cd dev
sudo cp /dev/console ./dev/ -a
sudo cp /dev/null ./dev/ -a
sudo cp /dev/zero ./dev/ -a
sudo cp /dev/*tty* ./dev/ -a
sudo cp /dev/ram* ./dev/ -a

dd if=/dev/zero of=${INITRD_IMG_OUTPUT_PATH}/${ROOTFS_NAME}E bs=1024 count=8192
mkfs.ext2 -F ${ROOTFS_NAME} 
sudo mkdir /mnt/initrd
sudo mount -t ext2 -o loop ${ROOTFS_NAME} /mnt/initrd
sudo cp rootfs/* /mnt/initrd/ -a
sudo rm build_rootfs.sh 
sudo rm my_rootfs.sh
sudo rm README.md
sudo umount /mnt/initrd

echo "写入镜像成功"

sudo cp $ROOTFS_NAME /boot/
if[ $? -eq 0];then
	echo "成功复制镜像到/boot"

echo "修改grub文件"
sudo sed -i 's/#GRUB_HEDDEN_TIMEOUT=0//' /boot/grub.cfg
sudo cat > /boot/grub.cfg << EOF
menuentry "FARSIGHT busybox"{
	insmod part_msdos
	insmod ext2

	set root='(hd0,msdos1)'
	linux /boot/initframlinuz-3.13.0-32-generic rw root=/dev/ram0 rootfs_size=8M
	initrd /boot/myinitrd.img
}
EOF

echo "成功，你自己去重启看看有没有选项吧！"
