#!/bin/bash


INITRD_IMG_OUTPUT_PATH="/home/gah0/rootfs-master"
ROOTFS_NAME="myinitrd.img"
CURRENT_DIR=$(cd $(dirname $0); pwd)
CURRENT_BACK_DIR=$CURRENT_DIR/..
CURRENT_ROOTFS_DIR=$CURRENT_DIR/rootfs

platform=`uname -m`

install(){
	ldconfig -p | grep libncurses5-dev
	if [ "$?" == 0 ] ;
		echo "已安装libncurses5-dev"
	else
		echo "未安装"
		if [ $platform='x86_64' ]
		then
        	echo 64
        	sudo apt-get install ncurses
        	if test "dpkg -l | grep libncurses5" = "1"
				echo "安装成功"
			else
				echo "安装失败"
			fi
		else
        	sudo dpkg -i libncurses5-dev_5.7+20100626-0ubuntu1_i386.deb
			if test "dpkg -l | grep libncurses5" = "1"
				echo "安装成功"
			else
				echo "安装失败"
			fi
		fi
	fi
}

mke(){
	if [ -d $CURRENT_DIR/busybox ]
		cd /busybox
		echo "开始编译busybox"
		sudo make user_defconfig

	if [ $? -eq 0 ]; then
		sudo make

	if [ $? -eq 0 ]; then
		sudo make install

	if[ $? -eq 0];then
		echo "成功编译"
		cp ./_install/* ..
		cd ..
		rm -R /busybox
}

mkrootfs(){
	mkdir $CURRENT_DIR/rootfs
	if test "/$CURRENT_DIR/rootfs"="1"
		cd rootfs
		mkdir dev etc lib proc bin sbin sys

cat > $CURRENT_DIR/rootfs/etc/init.d/rcS << EOF
echo "***********************"
echo "    Busybox System    *"
echo "***********************"
EOF
chmod +x ./etc/init.d/rcS

cat > $CURRENT_DIR/rootfs/etc/profile << EOF
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/usr/lib
PS1='[(busybox)\u@\h \W]# '
EOF

cat > $CURRENT_DIR/rootfs/etc/fstab << EOF
proc /proc proc defaults 0 0
none /tmp ramfs default 0 0
mdev /dev ramfs default 0 0
sysfs /sys sysfs default 0 0
EOF

cat > $CURRENT_DIR/rootfs/etc/inittab << EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
tty2::askfirst:-/bin/sh
::ctrlaltdel:/bin/unmount -a -r
EOF

cd $CURRENT_DIR/dev
sudo cp /dev/console $CURRENT_ROOTFS_DIR/dev/ -a
sudo cp /dev/null $CCURRENT_ROOTFS_DIR/dev/ -a
sudo cp /dev/zero $CURRENT_ROOTFS_DIR/dev/ -a
sudo cp /dev/*tty* $CURRENT_ROOTFS_DIR/dev/ -a
sudo cp /dev/ram* $CURRENT_ROOTFS_DIR/dev/ -a
}

mkeimg(){
cd $CURRENT_DIR
cd ..
dd if=/dev/zero of=$CURRENT_BACK_DIR bs=1024 count=8192
mkfs.ext2 -F ${ROOTFS_NAME} 
sudo mkdir /mnt/initrd
sudo mount -t ext2 -o loop ${ROOTFS_NAME} /mnt/initrd
sudo cp $CURRENT_DIR/rootfs/* /mnt/initrd/ -a
sudo umount /mnt/initrd

if [ $? -eq 0 ]; then
	echo "写入镜像成功"

sudo cp $ROOTFS_NAME /boot/
if[ $? -eq 0];then
	echo "成功复制镜像到/boot"

echo "修改grub文件"
sudo sed -i 's/#GRUB_HEDDEN_TIMEOUT=0//' /boot/grub.cfg
sudo cat > /boot/grub.cfg << EOF
menuentry "Busybox-1.23.0"{
	insmod part_msdos
	insmod ext2

	set root='(hd0,msdos1)'
	linux /boot/initframlinuz-3.13.0-32-generic rw root=/dev/ram0 rootfs_size=8M
	initrd /boot/myinitrd.img
}
EOF

sudo update-grub
if[ $? -eq 0];then
	echo "成功，你自己去重启看看有没有选项吧！"
}