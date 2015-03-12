
TOP = $(shell pwd)
include params.mk

all: $(BUILD)/linux-built \
	$(BUILD)/modules-built \
	$(BUILD)/firmware-built \
	$(BUILD)/headers-built \
	$(BUILD)/vbox-unpacked \
	$(BUILD)/vbox-built \
	$(BUILD)/afs-built \
	$(BUILD)/depmod-built

$(BUILD):
	mkdir -p $(BUILD)

$(SRC):
	mkdir -p $(SRC)


$(BUILD)/afs-built: $(BUILD)/openafs-$(AFS_VERSION)/src/libafs/MODLOAD-$(CVM_KERNEL_VERSION)-SP/openafs.ko
	mkdir -p $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs
	cp $(BUILD)/openafs-$(AFS_VERSION)/src/libafs/MODLOAD-$(CVM_KERNEL_VERSION)-SP/openafs.ko \
	  $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs/openafs-$(AFS_VERSION).ko
	ln -s openafs-$(AFS_VERSION).ko $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs/openafs.ko
	touch $(BUILD)/afs-built

$(BUILD)/afs-unpacked: $(SRC)/$(AFS_TARBALL) | $(BUILD)
	cd $(BUILD) && tar xvfj $(SRC)/$(AFS_TARBALL)
	touch $(BUILD)/afs-unpacked

$(BUILD)/aufs-cloned: | $(BUILD)
	git clone -b $(AUFS_BRANCH) $(AUFS_GIT) $(SRC)/aufs
	touch $(BUILD)/aufs-cloned

$(BUILD)/aufs-patched: $(BUILD)/aufs-cloned $(BUILD)/linux-unpacked
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-kbuild.patch
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-base.patch
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-mmap.patch
	cp $(SRC)/aufs/include/uapi/linux/aufs_type.h $(KERN_DIR)/include/uapi/linux/
	cp $(SRC)/aufs/Documentation/ABI/testing/* $(KERN_DIR)/Documentation/ABI/testing/
	cp -r $(SRC)/aufs/Documentation/filesystems/aufs $(KERN_DIR)/Documentation/filesystems/
	cp -r $(SRC)/aufs/fs/aufs $(KERN_DIR)/fs/
	touch $(BUILD)/aufs-patched

$(KERN_DIR)/.config.xz: kconfig-cernvm $(BUILD)/aufs-patched
	cp kconfig-cernvm $(KERN_DIR)/.config.xz

$(KERN_DIR)/arch/x86/boot/bzImage.xz: $(KERN_DIR)/.config.xz
	cp $(KERN_DIR)/.config.xz $(KERN_DIR)/.config
	$(MAKE) -C $(KERN_DIR) olddefconfig
	$(MAKE) -C $(KERN_DIR) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv $(KERN_DIR)/arch/x86/boot/bzImage $(KERN_DIR)/arch/x86/boot/bzImage.xz

$(BUILD)/depmod-built: $(BUILD)/vbox-built $(BUILD)/afs-built
	depmod -a -b $(BUILD)/modules-$(LINUX_VERSION) $(CVM_KERNEL_VERSION)
	touch $(BUILD)/depmod-built

$(BUILD)/linux-built: $(KERN_DIR)/arch/x86/boot/bzImage.xz
	touch $(BUILD)/linux-built

$(BUILD)/linux-unpacked: $(SRC)/$(LINUX_TARBALL) | $(BUILD)
	cd $(BUILD) && tar xvfJ $(SRC)/$(LINUX_TARBALL)
	touch $(BUILD)/linux-unpacked

$(BUILD)/firmware-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_FW_PATH=$(BUILD)/firmware-$(LINUX_VERSION) firmware_install
	touch $(BUILD)/firmware-built

$(BUILD)/headers-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_HDR_PATH=$(BUILD)/headers-$(LINUX_VERSION) headers_install
	touch $(BUILD)/headers-built

$(BUILD)/modules-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_MOD_PATH=$(BUILD)/modules-$(LINUX_VERSION) modules_install
	rm -f $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	rm -f $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	ln -s build $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/source
	ln -s /usr/src/kernels/$(CVM_KERNEL_VERSION) $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/build
	touch $(BUILD)/modules-built

$(BUILD)/openafs-$(AFS_VERSION)/Makefile: $(BUILD)/afs-unpacked $(BUILD)/linux-built
	cd $(BUILD)/openafs-$(AFS_VERSION) && ./configure --with-linux-kernel-packaging --with-linux-kernel-headers=$(KERN_DIR)

$(BUILD)/openafs-$(AFS_VERSION)/src/libafs/MODLOAD-$(CVM_KERNEL_VERSION)-SP/openafs.ko: $(BUILD)/openafs-$(AFS_VERSION)/Makefile
	$(MAKE) -C $(BUILD)/openafs-$(AFS_VERSION)

$(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko: $(BUILD)/vbox-unpacked $(BUILD)/linux-built
	$(MAKE) -C $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest KERN_DIR=$(KERN_DIR)

$(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko: $(BUILD)/vbox-unpacked $(BUILD)/linux-built
	$(MAKE) -C $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf KERN_DIR=$(KERN_DIR)

$(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko: $(BUILD)/vbox-unpacked $(BUILD)/linux-built
	$(MAKE) -C $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo KERN_DIR=$(KERN_DIR)

$(BUILD)/vbox-built: \
  $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko \
  $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko \
  $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko \
  $(BUILD)/modules-built
	mkdir -p $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/misc
	cp $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxguest/vboxguest.ko \
	  $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxsf/vboxsf.ko \
	  $(BUILD)/vbox-$(VBOX_VERSION)/src/vboxguest-$(VBOX_VERSION)/vboxvideo/vboxvideo.ko \
	  $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/misc/
	touch $(BUILD)/vbox-built 

$(BUILD)/vbox-unpacked: $(SRC)/$(VBOX_ISO) | $(BUILD)
	mkdir -p $(BUILD)/vbox-$(VBOX_VERSION)
	cp $(SRC)/$(VBOX_ISO) $(BUILD)/vbox-$(VBOX_VERSION)
	cd $(BUILD)/vbox-$(VBOX_VERSION) && 7z x $(VBOX_ISO)
	rm -f $(BUILD)/vbox-$(VBOX_VERSION)/$(VBOX_ISO)
	chmod +x $(BUILD)/vbox-$(VBOX_VERSION)/VBoxLinuxAdditions.run
	cd $(BUILD)/vbox-$(VBOX_VERSION) && ./VBoxLinuxAdditions.run --tar xvf
	rm -f $(BUILD)/vbox-$(VBOX_VERSION)/VBoxLinuxAdditions.run
	cd $(BUILD)/vbox-$(VBOX_VERSION) && tar xvfj VBoxGuestAdditions-amd64.tar.bz2
	rm -f $(BUILD)/vbox-$(VBOX_VERSION)/VBoxGuestAdditions-amd64.tar.bz2		
	touch $(BUILD)/vbox-unpacked

$(SRC)/$(AFS_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(AFS_TARBALL) $(AFS_URL)

$(SRC)/$(LINUX_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(LINUX_TARBALL) $(LINUX_URL)

$(SRC)/$(VBOX_ISO): | $(SRC)
	curl -L -o $(SRC)/$(VBOX_ISO) $(VBOX_URL)


clean:
	rm -rf $(BUILD)*

