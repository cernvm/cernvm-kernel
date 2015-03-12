
TOP = $(shell pwd)
include params.mk

all: build/linux-built \
	build/modules-built \
	build/firmware-built \
	build/headers-built \
	build/vbox-unpacked \
	build/vbox-built

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

build/linux-built: build/linux-$(LINUX_VERSION)/arch/x86/boot/bzImage.xz
	touch build/linux-built

build/linux-unpacked: src/$(LINUX_TARBALL) | build
	cd build && tar xvfJ ../src/$(LINUX_TARBALL)
	touch build/linux-unpacked

build/firmware-built: build/linux-built
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_FW_PATH=$(TOP)/build/firmware-$(LINUX_VERSION) firmware_install
	touch build/firmware-built

build/headers-built: build/linux-built
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_HDR_PATH=$(TOP)/build/headers-$(LINUX_VERSION) headers_install
	touch build/headers-built

build/modules-built: build/linux-built
	$(MAKE) -C build/linux-$(LINUX_VERSION) INSTALL_MOD_PATH=$(TOP)/build/modules-$(LINUX_VERSION) modules_install
	rm -f build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	rm -f build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	ln -s build build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	ln -s /usr/src/kernels/$(CVM_KERNEL_VERSION) build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	touch build/modules-built

build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko: build/vbox-unpacked build/linux-built
	$(MAKE) -C build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest KERN_DIR=$(TOP)/build/linux-$(LINUX_VERSION)

build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko: build/vbox-unpacked build/linux-built
	$(MAKE) -C build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf KERN_DIR=$(TOP)/build/linux-$(LINUX_VERSION)

build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko: build/vbox-unpacked build/linux-built
	$(MAKE) -C build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo KERN_DIR=$(TOP)/build/linux-$(LINUX_VERSION)

build/vbox-built: \
  build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko \
  build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko \
  build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko \
  build/modules-built
	mkdir -p build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/misc
	cp build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko \
	  build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko \
	  build/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko \
	  build/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/misc/
	touch build/vbox-built 

build/vbox-unpacked: src/$(VBOX_ISO) | build
	mkdir -p build/vbox-$(VBOX_VERSION)
	cp src/$(VBOX_ISO) build/vbox-$(VBOX_VERSION)
	cd build/vbox-$(VBOX_VERSION) && 7z x $(VBOX_ISO)
	rm -f build/vbox-$(VBOX_VERSION)/$(VBOX_ISO)
	chmod +x build/vbox-$(VBOX_VERSION)/VBoxLinuxAdditions.run
	cd build/vbox-$(VBOX_VERSION) && ./VBoxLinuxAdditions.run --tar xvf
	rm -f build/vbox-$(VBOX_VERSION)/VBoxLinuxAdditions.run
	cd build/vbox-$(VBOX_VERSION) && tar xvfj VBoxGuestAdditions-amd64.tar.bz2
	rm -f build/vbox-$(VBOX_VERSION)/VBoxGuestAdditions-amd64.tar.bz2		
	touch build/vbox-unpacked

src/$(LINUX_TARBALL): | src
	curl -o src/$(LINUX_TARBALL) $(LINUX_URL)

src/$(VBOX_ISO): | src
	curl -L -o src/$(VBOX_ISO) $(VBOX_URL)


clean:
	rm -rf build/*

