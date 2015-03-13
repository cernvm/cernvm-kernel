###############################################################################
# Build system for the CernVM kernel.
#
# Builds a vanilla kernel with aufs patches and
#   - OpenAFS
#   - VirtualBox Guest Additions
#   - VMware tools
# 
# Requires (incomplete): make, gcc, gcc-c++, tar, xz, gzip, unzip, 7pzip
#
###############################################################################

TOP = $(shell pwd)
include params.mk

all: $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz

$(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz: \
  $(BUILD)/linux-built \
  $(BUILD)/awskernel-built \
  $(BUILD)/firmware-built \
  $(BUILD)/headers-built \
  $(BUILD)/depmod-built \
  | $(DIST)
	mkdir $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)
	cp $(KERN_DIR)/arch/x86/boot/bzImage.xz $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/vmlinuz-$(CVM_KERNEL_VERSION).xz
	cp $(KERN_DIR)/arch/x86/boot/bzImage.gzip $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/vmlinuz-$(CVM_KERNEL_VERSION).gzip
	cp -av $(BUILD)/modules-$(LINUX_VERSION) $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/modules-$(LINUX_VERSION)
	cp -av $(BUILD)/headers-$(LINUX_VERSION) $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/headers-$(LINUX_VERSION)
	cp -av $(BUILD)/firmware-$(LINUX_VERSION) $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/firmware-$(LINUX_VERSION)
	cd $(DIST) && tar cfvz cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz cernvm-kernel-$(CVM_KERNEL_VERSION)
	rm -rf $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)
	

$(BUILD):
	mkdir -p $(BUILD)

$(SRC):
	mkdir -p $(SRC)

$(DIST):
	mkdir -p $(DIST)


$(BUILD)/afs-built: \
  $(BUILD)/openafs-$(AFS_VERSION)/src/libafs/MODLOAD-$(CVM_KERNEL_VERSION)-SP/openafs.ko \
  $(BUILD)/modules-built
	mkdir -p $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs
	cp $(BUILD)/openafs-$(AFS_VERSION)/src/libafs/MODLOAD-$(CVM_KERNEL_VERSION)-SP/openafs.ko \
	  $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs/openafs-$(AFS_VERSION).ko
	ln -s openafs-$(AFS_VERSION).ko $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs/openafs/openafs.ko
	touch $(BUILD)/afs-built

$(BUILD)/afs-unpacked: $(SRC)/$(AFS_TARBALL) | $(BUILD)
	cd $(BUILD) && tar xvfj $(SRC)/$(AFS_TARBALL)
	touch $(BUILD)/afs-unpacked

$(BUILD)/aufs-cloned: | $(BUILD)
	if [ -d $(SRC)/aufs ]; then \
	  cd $(SRC)/aufs && git pull; \
	else \
	  git clone -b $(AUFS_BRANCH) $(AUFS_GIT) $(SRC)/aufs; \
	fi
	touch $(BUILD)/aufs-cloned

$(BUILD)/awskernel-built: $(KERN_DIR)/arch/x86/boot/bzImage.gzip
	touch $(BUILD)/awskernel-built

$(BUILD)/linux-patched: $(BUILD)/aufs-cloned $(BUILD)/linux-unpacked
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-kbuild.patch
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-base.patch
	cd $(KERN_DIR) && patch -p1 < $(SRC)/aufs/aufs3-mmap.patch
	cp $(SRC)/aufs/include/uapi/linux/aufs_type.h $(KERN_DIR)/include/uapi/linux/
	cp $(SRC)/aufs/Documentation/ABI/testing/* $(KERN_DIR)/Documentation/ABI/testing/
	cp -r $(SRC)/aufs/Documentation/filesystems/aufs $(KERN_DIR)/Documentation/filesystems/
	cp -r $(SRC)/aufs/fs/aufs $(KERN_DIR)/fs/
	touch $(BUILD)/linux-patched

$(KERN_DIR)/.config.gzip: kconfig-cernvm $(BUILD)/linux-unpacked
	sed -e 's/CONFIG_KERNEL_XZ=y//' kconfig-cernvm > $(KERN_DIR)/.config.gzip.tmp
	echo CONFIG_KERNEL_GZIP=y >> $(KERN_DIR)/.config.gzip.tmp
	mv $(KERN_DIR)/.config.gzip.tmp $(KERN_DIR)/.config.gzip

$(KERN_DIR)/.config.xz: kconfig-cernvm $(BUILD)/linux-unpacked
	cp kconfig-cernvm $(KERN_DIR)/.config.xz

$(KERN_DIR)/arch/x86/boot/bzImage.gzip: $(KERN_DIR)/.config.gzip $(BUILD)/linux-built
	cp $(KERN_DIR)/.config.gzip $(KERN_DIR)/.config
	$(MAKE) -C $(KERN_DIR) olddefconfig
	$(MAKE) -C $(KERN_DIR) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv $(KERN_DIR)/arch/x86/boot/bzImage $(KERN_DIR)/arch/x86/boot/bzImage.gzip

$(KERN_DIR)/arch/x86/boot/bzImage.xz: $(KERN_DIR)/.config.xz $(BUILD)/linux-patched
	cp $(KERN_DIR)/.config.xz $(KERN_DIR)/.config
	$(MAKE) -C $(KERN_DIR) olddefconfig
	$(MAKE) -C $(KERN_DIR) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv $(KERN_DIR)/arch/x86/boot/bzImage $(KERN_DIR)/arch/x86/boot/bzImage.xz

$(BUILD)/depmod-built: $(BUILD)/vbox-built $(BUILD)/afs-built $(BUILD)/vmtools-built
	depmod -a -b $(BUILD)/modules-$(LINUX_VERSION) $(CVM_KERNEL_VERSION)
	touch $(BUILD)/depmod-built

$(BUILD)/firmware-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_FW_PATH=$(BUILD)/firmware-$(LINUX_VERSION) firmware_install
	touch $(BUILD)/firmware-built

$(BUILD)/headers-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_HDR_PATH=$(BUILD)/headers-$(LINUX_VERSION) headers_install
	touch $(BUILD)/headers-built

$(BUILD)/linux-built: $(KERN_DIR)/arch/x86/boot/bzImage.xz
	touch $(BUILD)/linux-built

$(BUILD)/linux-unpacked: $(SRC)/$(LINUX_TARBALL) | $(BUILD)
	cd $(BUILD) && tar xvfJ $(SRC)/$(LINUX_TARBALL)
	touch $(BUILD)/linux-unpacked

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

$(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/configure: $(BUILD)/vmtools-unpacked
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && autoreconf -i

$(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/Makefile: $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/configure $(BUILD)/linux-built
	ln -sf . $(KERN_DIR)/build
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && \
	  ./configure --disable-multimon --disable-docs --disable-tests \
	    --without-gtk2 --without-gtkmm --without-x --without-pam --without-procps --without-dnet --without-icu \
	    --with-kernel-release=$(CVM_KERNEL_VERSION) --with-linuxdir=$(KERN_DIR)

$(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/modules/linux/vmhgfs/vmhgfs.ko: $(BUILD)/vmtools-patched
	$(MAKE) -C $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/modules

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

$(BUILD)/vmtools-built: \
  $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/modules/linux/vmhgfs/vmhgfs.ko \
  $(BUILD)/modules-built
	mkdir -p $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs
	cp $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/modules/linux/vmhgfs/vmhgfs.ko \
	  $(BUILD)/modules-$(LINUX_VERSION)/lib/modules/$(CVM_KERNEL_VERSION)/kernel/fs
	touch $(BUILD)/vmtools-built

$(BUILD)/vmtools-patched: $(BUILD)/vmtools-unpacked $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/Makefile
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0001-Remove-unused-DEPRECATED-macro.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0002-Conditionally-define-g_info-macro.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0003-Add-kuid_t-kgid_t-compatibility-layer.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0004-Use-new-link-helpers.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0005-Update-hgfs-file-operations-for-newer-kernels.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0006-Fix-vmxnet-module-on-kernels-3.16.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0007-Fix-vmhgfs-module-on-kernels-3.16.patch
	cd $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION) && patch -p2 < $(TOP)/patches/0008-Fix-segfault-in-vmhgfs.patch
	sed -i -e 's/^MODULES = .*/MODULES = vmhgfs/' $(BUILD)/open-vm-tools-$(VMTOOLS_VERSION)/modules/Makefile
	touch $(BUILD)/vmtools-patched

$(BUILD)/vmtools-unpacked: $(SRC)/$(VMTOOLS_TARBALL) | $(BUILD)
	cd $(BUILD) && tar xvfz  $(SRC)/$(VMTOOLS_TARBALL)
	touch $(BUILD)/vmtools-unpacked

$(SRC)/$(AFS_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(AFS_TARBALL) $(AFS_URL)

$(SRC)/$(LINUX_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(LINUX_TARBALL) $(LINUX_URL)

$(SRC)/$(VBOX_ISO): | $(SRC)
	curl -L -o $(SRC)/$(VBOX_ISO) $(VBOX_URL)

$(SRC)/$(VMTOOLS_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(VMTOOLS_TARBALL) $(VMTOOLS_URL)

clean:
	rm -rf $(BUILD)*

