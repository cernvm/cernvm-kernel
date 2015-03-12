
TOP = $(shell pwd)
include params.mk

all: build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz \
	build/modules-built \
	build/firmware-built \
	build/headers-built

src:
	mkdir -p src

build:
	mkdir -p build


build/aufs-cloned: | build
	git clone -b $(AUFS_BRANCH) $(AUFS_GIT) build/aufs
	touch build/aufs-cloned

build/aufs-patched: build/aufs-cloned build/linux-unpacked
	cd build/linux-$(LINUX_VERSION) && patch -p1 < ../aufs/aufs3-kbuild.patch
	cd build/linux-$(LINUX_VERSION) && patch -p1 < ../aufs/aufs3-base.patch
	cd build/linux-$(LINUX_VERSION) && patch -p1 < ../aufs/aufs3-mmap.patch
	cp build/aufs/include/uapi/linux/aufs_type.h build/linux-$(LINUX_VERSION)/include/uapi/linux/
	cp build/aufs/Documentation/ABI/testing/* build/linux-$(LINUX_VERSION)/Documentation/ABI/testing/
	cp -r build/aufs/Documentation/filesystems/aufs build/linux-$(LINUX_VERSION)/Documentation/filesystems/
	cp -r build/aufs/fs/aufs build/linux-$(LINUX_VERSION)/fs/
	touch build/aufs-patched

build/linux-$(LINUX_VERSION)/.config.xz: kconfig-cernvm build/aufs-patched
	cp kconfig-cernvm build/linux-$(LINUX_VERSION)/.config.xz

build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz: build/linux-$(LINUX_VERSION)/.config.xz
	cp build/linux-$(LINUX_VERSION)/.config.xz build/linux-$(LINUX_VERSION)/.config
	$(MAKE) -C build/linux-$(LINUX_VERSION) olddefconfig
	$(MAKE) -C build/linux-$(LINUX_VERSION) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz	

build/linux-unpacked: src/$(LINUX_TARBALL) | build
	cd build && tar xvfJ ../src/$(LINUX_TARBALL)
	touch build/linux-unpacked

build/modules-built: build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_MOD_PATH=$(TOP)/build/modules-$(LINUX_VERSION) modules_install
	rm -f build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	rm -f build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	ln -s build build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	ln -s /usr/src/kernels/$(CVM_KERNEL_VERSION) build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	touch build/modules-built

build/firmware-built: build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_FW_PATH=$(TOP)/build/firmware-$(LINUX_VERSION) firmware_install
	touch build/firmware-built

build/headers-built: build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_HDR_PATH=$(TOP)/build/headers-$(LINUX_VERSION) headers_install
	touch build/headers-built

src/$(LINUX_TARBALL): | src
	curl -o src/$(LINUX_TARBALL) $(LINUX_URL)


clean:
	rm -rf build/*

