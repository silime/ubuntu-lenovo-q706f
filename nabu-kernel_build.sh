git clone https://github.com/silime/linux.git --branch sm8250/6.11-release --depth 1 linux
cd linux
curl https://raw.githubusercontent.com/silime/ArchLinux-Packages/refs/heads/main/linux-sm8250/config -o .config
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
_kernel_version="$(make kernelrelease -s)"
mkdir ../linux-lenovo-q706f/boot
cp arch/arm64/boot/Image.gz ../linux-lenovo-q706f/boot/vmlinuz-$_kernel_version
cp arch/arm64/boot/dts/qcom/sm8250-lenovo-q706f.dtb ../linux-lenovo-q706f/boot/dtb-$_kernel_version
sed -i "s/Version:.*/Version: ${_kernel_version}/" ../linux-lenovo-q706f/DEBIAN/control
rm -rf ../linux-lenovo-q706f/lib
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=../linux-lenovo-q706f modules_install
rm ../linux-lenovo-q706f/lib/modules/**/build
cd ..
rm -rf linux

dpkg-deb --build --root-owner-group linux-lenovo-q706f
dpkg-deb --build --root-owner-group firmware-lenovo-q706f
dpkg-deb --build --root-owner-group alsa-lenovo-q706f
