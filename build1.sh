echo -e "\nStarting compilation...\n"
# ENV

git clone --depth=1 https://github.com/kdrag0n/proton-clang clang/proton
git clone --depth=1 https://github.com/HafizZiq/arm-linux-androideabi-4.9 gcc/arm-linux-androideabi-4.9
git clone --depth=1 https://github.com/HafizZiq/aarch64-linux-android-4.9 gcc/aarch64-linux-android-4.9

transfer() {
if [ $# -eq 0 ]; then
 echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1;
fi;
tmpfile=$( mktemp -t transferXXX );
if tty -s; then
 basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g');
 curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile;
else
 curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ;
fi;
cat $tmpfile;
rm -f $tmpfile; \
}

CONFIG=vendor/sixteen_defconfig
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
export KBUILD_BUILD_USER="hafizziq"
export KBUILD_BUILD_HOST="ubuntu"
export KBUILD_BUILD_TIMESTAMP="$(TZ=Asia/Kuala_Lumpur date)"
export PATH="${PWD}/clang/proton/bin:$PATH"
export LD_LIBRARY_PATH="${PWD}/clang/proton/lib:$LD_LIBRARY_PATH"
export KBUILD_COMPILER_STRING="$(${PWD}/clang/proton/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export CROSS_COMPILE=${PWD}/gcc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=${PWD}/gcc/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export out=out

# let's clean the output first before building
if [ -d $out ]; then
 echo -e "Cleaning out leftovers...\n"
 rm -rf $out
fi;

mkdir -p $out

# Functions
clang_build () {
    make -j$(nproc --all) O=$out \
                          ARCH=arm64 \
                          CC="clang" \
                          AR="llvm-ar" \
                          NM="llvm-nm" \
                          LD="ld.lld" \
                          AS="llvm-as" \
                          OBJCOPY="llvm-objcopy" \
                          OBJDUMP="llvm-objdump" \
                          CLANG_TRIPLE=aarch64-linux-gnu- \
                          CROSS_COMPILE=$CROSS_COMPILE \
                          CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32
}

# Build kernel
make O=$out ARCH=arm64 $CONFIG > /dev/null
echo -e "${bold}Compiling with CLANG${normal}\n$KBUILD_COMPILER_STRING"
clang_build
if [ -f "$out/arch/arm64/boot/Image.gz" ] && [ -f "$out/arch/arm64/boot/dtbo.img" ] && [ -f "$out/arch/arm64/boot/dts/qcom/trinket.dtb" ]; then
 echo -e "\nKernel compiled succesfully! Zipping up...\n"
 ZIPNAME="PerawanX☭•Q•Ginklow-$(date '+%Y%m%d-%H%M').zip"
 if [ ! -d AnyKernel3 ]; then
  git clone -q https://github.com/HafizZiq/AnyKernel3 --depth=1 -b perawanx
 fi;
 cp -f $out/arch/arm64/boot/Image.gz AnyKernel3
 cp -f $out/arch/arm64/boot/dtbo.img AnyKernel3
 cp -f $out/arch/arm64/boot/dts/qcom/trinket.dtb AnyKernel3/dtb
 cd AnyKernel3
 zip -r9 "${PWD}/$ZIPNAME" *
 cd ..
 rm -rf AnyKernel3
 echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
 echo "Zip: $ZIPNAME"
 rm -rf $out
 transfer $ZIPNAME
else
 echo -e "\nCompilation failed!"
fi;
exit 0
