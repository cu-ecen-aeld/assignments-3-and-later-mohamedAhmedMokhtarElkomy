#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
CURRDIR=~/dev/embedded_linux_course
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v6.6.8
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-
C_LIB=arm64_libc

if [ $# -lt 1 ]; then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

pushd .
mkdir -p ${OUTDIR}
cd "$OUTDIR"

if [ ! -d "linux-stable" ]; then
        #Clone only if the repository does not exist.
		echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
		git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e linux-stable/arch/${ARCH}/boot/Image ]; then
        cd linux-stable
        echo "Checking out version ${KERNEL_VERSION}"
        git checkout ${KERNEL_VERSION}
        # TODO: Add your kernel build steps here
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper # It goes silence in case of already cleaned direc.
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig  # default configuration for arm64 
        make j=10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all # This is the steps where the Image gets generated, j=10 uses multithreading to build!
        make j=10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules # Generate the modules
        make j=10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs # Generate device tree
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/dev ${OUTDIR}/rootfs/home ${OUTDIR}/rootfs/bin  \
         ${OUTDIR}/rootfs/sbin ${OUTDIR}/rootfs/etc ${OUTDIR}/rootfs/lib  \
         ${OUTDIR}/rootfs/lib64 ${OUTDIR}/rootfs/usr ${OUTDIR}/rootfs/tmp \
         ${OUTDIR}/rootfs/proc ${OUTDIR}/rootfs/sys ${OUTDIR}/rootfs/var  \
         ${OUTDIR}/rootfs/var/log ${OUTDIR}/rootfs/usr/bin ${OUTDIR}/rootfs/usr/sbin \
         ${OUTDIR}/rootfs/usr/lib ${OUTDIR}/rootfs/home/conf

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION} 
else
    cd busybox
fi

# TODO:  Configure busybox
# TODO: Make and install busybox
make distclean  # It goes silence in case of already cleaned direc.
make defconfig  # default configuration for arm64 
make j=10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE   # builds the busybox executable!
make j=10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=${OUTDIR}/rootfs install # Adds all the program bin to the rootfs/bin as hard links

# echo "Library dependencies"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

popd
# TODO: Add library dependencies to rootfs
cp -a ${C_LIB}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp -a ${C_LIB}/lib64/ld-2.31.so ${OUTDIR}/rootfs/lib64

cp -a ${C_LIB}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64
cp -a ${C_LIB}/lib64/libc-2.31.so ${OUTDIR}/rootfs/lib64

cp -a ${C_LIB}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp -a ${C_LIB}/lib64/libresolv-2.31.so ${OUTDIR}/rootfs/lib64

cp -a ${C_LIB}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp -a ${C_LIB}/lib64/libm-2.31.so ${OUTDIR}/rootfs/lib64

# TODO: Clean and build the writer utility
if [ ! -e writer ]; then # if the writer app does not exist!
    make CROSS_COMPILE=${CROSS_COMPILE} all
else
    make clean
    make CROSS_COMPILE=${CROSS_COMPILE} all
fi

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp finder.sh ${OUTDIR}/rootfs/home
cp conf/assignment.txt ${OUTDIR}/rootfs/home/conf
cp conf/username.txt ${OUTDIR}/rootfs/home/conf
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Make device nodes
if [ ! -e ${OUTDIR}/rootfs/dev/console ]; then  # if the file does not exist!
    sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1 # character devices creation
fi
if [ ! -e ${OUTDIR}/rootfs/dev/null ]; then
    sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
fi

# TODO: Chown the root directory
# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio 
gzip -f ${OUTDIR}/initramfs.cpio