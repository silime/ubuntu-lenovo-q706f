#!/bin/sh

if [ "$(id -u)" -ne 0 ]
then
  echo "rootfs can only be built as root"
  exit
fi

VERSION="24.04"

truncate -s 6G rootfs.img
mkfs.ext4 rootfs.img
mkdir rootdir
mount -o loop rootfs.img rootdir

wget https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.1-base-arm64.tar.gz
tar xzvf ubuntu-base-24.04.1-base-arm64.tar.gz -C rootdir
#rm ubuntu-base-$VERSION-base-arm64.tar.gz

mount --bind /dev rootdir/dev
mount --bind /dev/pts rootdir/dev/pts
mount --bind /proc rootdir/proc
mount --bind /sys rootdir/sys

echo "nameserver 8.8.8.8" | tee rootdir/etc/resolv.conf
echo "lenovo-q706f" | tee rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 lenovo-q706f" | tee rootdir/etc/hosts

if uname -m | grep -q aarch64
then
  echo "cancel qemu install for arm64"
else
  wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static
  install -m755 qemu-aarch64-static rootdir/

  echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
  #ldconfig.real abi=linux type=dynamic
  echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
fi


#chroot installation
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH
export DEBIAN_FRONTEND=noninteractive

chroot rootdir apt update
chroot rootdir apt upgrade -y

#u-boot-tools breaks grub installation
chroot rootdir apt install -y bash-completion sudo ssh nano u-boot-tools- $1

#chroot rootdir gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts-only-mounted true



#Device specific
# chroot rootdir apt install -y rmtfs protection-domain-mapper tqftpserv

#Remove check for "*-laptop"
# sed -i '/ConditionKernelVersion/d' rootdir/lib/systemd/system/pd-mapper.service

cp /home/runner/work/ubuntu-lenovo-q706f/ubuntu-lenovo-q706f/lenovo-q706f-debs/*.deb rootdir/tmp/
mv $(realpath rootdir/tmp/linux-image-*.deb) rootdir/tmp/linux-image.deb
chroot rootdir apt install -y /tmp/firmware-lenovo-q706f.deb
chroot rootdir dpkg -i /tmp/linux-image.deb
chroot rootdir dpkg -i /tmp/alsa-lenovo-q706f.deb
rm rootdir/tmp/*-lenovo-q706f.deb


#EFI
chroot rootdir apt install -y grub-efi-arm64 pulseaudio

sed --in-place 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' rootdir/etc/default/grub
sed --in-place 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' rootdir/etc/default/grub

#this done on device for now
#grub-install
#grub-mkconfig -o /boot/grub/grub.cfg

#create fstab!
# echo "PARTLABEL=linux / ext4 errors=remount-ro,x-systemd.growfs 0 1
# PARTLABEL=esp /boot/efi vfat umask=0077 0 1" | tee rootdir/etc/fstab

mkdir rootdir/var/lib/gdm
touch rootdir/var/lib/gdm/run-initial-setup
chroot rootdir rm -r /home/ubuntu
chroot rootdir apt clean

# Make Android Boot Image
git clone https://android.googlesource.com/platform/system/tools/mkbootimg tools --depth=1
mkdir out
cp rootdir/boot/vmlinuz-* out/kernel
cp rootdir/boot/initrd.img-* out/ramdisk
cp rootdir/usr/lib/linux-*/qcom/sm8250-lenovo-q706f.dtb out/dtb
tools/mkbootimg.py --header_version 2 --os_version 11.0.0 --os_patch_level 2024-05 --kernel out/kernel --ramdisk out/ramdisk --dtb out/dtb --pagesize 0x00001000 --base 0x00000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --second_offset 0x00000000 --tags_offset 0x00000100 --dtb_offset 0x0000000001f00000 --board "" --cmdline "root=PARTLABEL=userdata rw rootwait audit=0 splash plymouth.ignore-serial-consoles slot_suffix=_b" -o lenovo-q706f-boot.img
cp lenovo-q706f-boot.img rootdir/boot/boot.img

if uname -m | grep -q aarch64
then
  echo "cancel qemu install for arm64"
else
  #Remove qemu emu
  echo -1 | tee /proc/sys/fs/binfmt_misc/aarch64
  echo -1 | tee /proc/sys/fs/binfmt_misc/aarch64ld
  rm rootdir/qemu-aarch64-static
  rm qemu-aarch64-static
fi

umount rootdir/sys
umount rootdir/proc
umount rootdir/dev/pts
umount rootdir/dev
umount rootdir

rm -d rootdir

echo 'cmdline for legacy boot: "root=PARTLABEL=userdata"'

7zz a rootfs.7z rootfs.img
