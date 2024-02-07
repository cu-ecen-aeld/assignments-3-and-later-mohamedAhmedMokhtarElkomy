# !/bin/sh
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
# OUTDIR=~/Downloads/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v6.6.8
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
# CROSS_COMPILE=aarch64-linux-gnu-
CROSS_COMPILE=aarch64-linux-gnu-
TOOLCHAIN_SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
install ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 sbin sys tmp usr var
mkdir -p usr/bin/ usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
export PATH=~/Downloads/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin:$PATH
make -j ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a /usr/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a /usr/bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
cp ${TOOLCHAIN_SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/ld-linux-aarch64.so.1
cp ${TOOLCHAIN_SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/libm.so.6
cp ${TOOLCHAIN_SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/libresolv.so.2
cp ${TOOLCHAIN_SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/libc.so.6


# TODO: Make device nodes
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
# cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/usr/bin
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/usr/bin
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
mkdir ${OUTDIR}/rootfs/home/conf
cp ${FINDER_APP_DIR}/conf/* ${OUTDIR}/rootfs/home/conf/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/

# install ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home
# install ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home
# install -d ${OUTDIR}/rootfs/home/conf
# install -m 644 -t ${OUTDIR}/rootfs/home/conf ${FINDER_APP_DIR}/conf/assignment.txt ${FINDER_APP_DIR}/conf/username.txt
# install ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home
# install ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

