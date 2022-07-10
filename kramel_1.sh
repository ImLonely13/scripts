#!/usr/bin/bash
# Written by: cyberknight777
# YAKB v1.0
# Copyright (c) 2022-2023 Cyber Knight <cyberknight755@gmail.com>
#
#			GNU GENERAL PUBLIC LICENSE
#			 Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

# Some Placeholders: [!] [*] [✓] [✗]

# A function to send message(s) via Telegram's BOT api.
tg() {
    curl -sX POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage \
        -d chat_id="-1001754559150" \
        -d parse_mode=Markdown \
        -d disable_web_page_preview=true \
        -d text="$1"
}

tgs() {
    MD5=$(md5sum "$1" | cut -d' ' -f1)
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TG_TOKEN}"/sendDocument \
        -F "chat_id=-1001754559150" \
        -F "parse_mode=Markdown" \
        -F "caption=$2 | *MD5*: \`$MD5\`"
}

# Some configuration about device
export CODENAME=$CODENAME
export DEVICE="$DEVICE"
export CONFIG=$CONFIG

# User and Host name
export BUILDER=ItsProf
export HOST=github.com

# Kernel repository URL.
REPO_URL="https://github.com/ImLonely13/android_kernel_xiaomi_mt6768"
export REPO_URL

# Commit hash of HEAD.
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH

# Number of jobs to run.
PROCS=$(nproc --all)

# Necessary variables to be exported.
export STATUS=STABLE


    echo -e "\n\e[1;93m|| Cloning toolchains ||\e[0m"
    git clone https://github.com/ImLonely13/android_kernel_xiaomi_mt6768 --depth=1 -b x1.0 $(pwd)/android_kernel_xiaomi_mt6768-stable
    git clone https://github.com/cyberknight777/gcc-arm64 --depth=1 -b master android_kernel_xiaomi_mt6768-stable/gcc64
    git clone https://github.com/cyberknight777/gcc-arm --depth=1 -b master android_kernel_xiaomi_mt6768-stable/gcc32
    git clone https://github.com/ImLonely13/AnyKernel3 -b merlin android_kernel_xiaomi_mt6768-stable/anykernel_1

    cd android_kernel_xiaomi_mt6768-stable
    KBUILD_COMPILER_STRING=$(gcc64/bin/aarch64-elf-gcc --version | head -n 1)
    export KBUILD_COMPILER_STRING
    export PATH=$(pwd)/gcc32/bin:$(pwd)/gcc64/bin:/usr/bin/:${PATH}
    MAKE+=(
        CC=aarch64-elf-gcc
        LD=aarch64-elf-ld.lld
        CROSS_COMPILE=aarch64-elf-
        CROSS_COMPILE_ARM32=arm-eabi-
        AR=llvm-ar
        NM=llvm-nm
        OBJDUMP=llvm-objdump
        OBJCOPY=llvm-objcopy
        OBJSIZE=llvm-objsize
        STRIP=llvm-strip
        HOSTAR=llvm-ar
        HOSTCC=gcc
        HOSTCXX=aarch64-elf-g++
	CONFIG_DEBUG_SECTION_MISMATCH=y
        CONFIG_SECTION_MISMATCH_WARN_ONLY=y
    )

    export KBUILD_BUILD_VERSION=$GITHUB_RUN_NUMBER
    export KBUILD_BUILD_HOST=$HOST
    export KBUILD_BUILD_USER=$BUILDER
    export kver=$KBUILD_BUILD_VERSION
    export VERSION=$VERSION
    export DATE2=$(date +"%m%d")
    export zipn=[$DATE2][$STATUS][$CODENAME]LynxesKernel-$VERSION


tg "
*⚒ CI Number $KBUILD_BUILD_VERSION Build Triggered*

*Date*: \`$(date)\`
*Builder*: \`${BUILDER}\`
*Device*: \`${DEVICE} [${CODENAME}]\`
*Kernel Version*: \`$(make kernelversion 2>/dev/null)\`
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Linker*: \`$(gcc64/bin/aarch64-elf-ld.lld -v | head -n1 | sed 's/(compatible with [^)]*)//' |
            head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Last Commit*: [${COMMIT_HASH}](${REPO_URL}/commit/${COMMIT_HASH})
"

    echo -e "\n\e[1;93m|| Building kernel ||\e[0m"
    BUILD_START=$(date +"%s")
     make -j$(nproc) O=out ARCH=arm64 ${CONFIG}
     make -j$(nproc) ARCH=arm64 O=out \
     "${MAKE[@]}" 2>&1 | tee log.txt
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    if ! [ -a out/arch/arm64/boot/Image.gz ]; then
            tgs "log.txt" "*Build failed*"
            exit 1
    fi

    echo -e "\n\e[1;93m|| Zipping into a flashable zip ||\e[0m"
    mv out/arch/arm64/boot/Image.gz anykernel_1/
    cd anykernel_1 || exit 1
    zip -r9 "$zipn".zip . -x ".git*" -x "README.md" -x "LICENSE" -x "*.zip"
    tgs "${zipn}.zip" "*#${kver} ${KBUILD_COMPILER_STRING}*"
