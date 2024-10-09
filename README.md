<img align="right" src="https://raw.githubusercontent.com/jiganomegsdfdf/ubuntu-xiaomi-nabu/master/ubnt.png" width="425" alt="Ubuntu 23.04 Running On A Xiaoxin Pad Pro 12.6">

# Ubuntu for Xiaoxin Pad Pro 12.6
This repo contians scripts for automatic building of ubuntu rootfs and kernel for Xiaoxin Pad Pro 12.6

# Where do i get needed files?
Actually, just go to the "Actions" tab, find one of latest builds and download file named **rootfs_(Desktop Environment you want)_(Kernel version you want)** 
<br>for update download file named **xiaomi-nabu-debs_(Kernel version you want)**

# Update info
<!-- - ~~ Unpack .zip you downloaded ~~
- ~~  Run dpkg -i *-xiaomi-nabu.deb ~~ 
- ~~ P.S. if you are moving to another kernel version make that after installing .deb's ~~ 
 ~~  <br>**First method**: just replace your old kernel version with the new kernel version in /boot/grub/grub.cfg ~~ 
  ~~  <br>**Second method**: grub-install and grub-mkconfig -o /boot/grub/grub.cfg ~~  -->

# Install info
- Unpack .zip you downloaded
- Unpack extracted .7z (there you take rootfs.img)
- rootfs.img must be copy to the partition named "userdata"
- flash rootfs/boot/boot.img to the partition named "boot_b"
- erase to the partition named "dtbo_b"
- If you want to modify cmdline, please follow the following command to execute it in a Linux environment
```shell
# Make Android Boot Image
git clone https://android.googlesource.com/platform/system/tools/mkbootimg tools --depth=1
mkdir out
cp rootdir/boot/vmlinuz-* out/kernel
cp rootdir/boot/initrd.img-* out/ramdisk
cp rootdir/usr/lib/linux-*/qcom/sm8250-lenovo-q706f.dtb out/dtb
tools/mkbootimg.py --header_version 2 --os_version 11.0.0 --os_patch_level 2024-05 --kernel out/kernel --ramdisk out/ramdisk --dtb out/dtb --pagesize 0x00001000 --base 0x00000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --second_offset 0x00000000 --tags_offset 0x00000100 --dtb_offset 0x0000000001f00000 --board "" --cmdline "root=PARTLABEL=userdata rw rootwait audit=0 splash plymouth.ignore-serial-consoles slot_suffix=_b" -o lenovo-q706f-boot.img
cp lenovo-q706f-boot.img rootdir/boot/boot.img
```