###############################################################################
# Build system for the CernVM kernel.
#
# Builds a vanilla kernel with guest virtualization support
#
# Amazon EC2 only supports gzip'd kernel, thus build both xz and gzip images.
#
# Requires (incomplete): make, gcc, gcc-c++, tar, xz, gzip, unzip, p7zip,
#                        p7zip-plugins, patch, bzip2, autoconf, automake,
#                        libtool, bc, bison, byacc, flex, glib2-devel,
#                        glibc-static
#
###############################################################################

TOP = $(shell pwd)
include params.mk

# No more guest modules
CVM_GUEST_MODULES =

all: $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz

help:
	@$(MAKE) --print-data-base --question no-such-target 2>&1 | \
	  grep -v -e '^no-such-target' -e '^Makefile' |      \
	  awk '/^[^.%][-A-Za-z0-9_]*:/                       \
	  { print substr($$1, 1, length($$1)-1) }' |    \
	  sort

$(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz: \
  $(BUILD)/linux-built \
  $(BUILD)/awskernel-built \
  $(BUILD)/modules-built \
  $(BUILD)/headers-built \
  $(BUILD)/depmod-built \
  | $(DIST)
	mkdir $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)
	cp $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).xz \
	  $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/vmlinuz-$(CVM_KERNEL_VERSION).xz
	cp $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).gzip \
	  $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/vmlinuz-$(CVM_KERNEL_VERSION).gzip
	cp -av $(BUILD)/modules-$(LINUX_VERSION) $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/modules-$(LINUX_VERSION)
	cp -av $(BUILD)/headers-$(LINUX_VERSION) $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)/headers-$(LINUX_VERSION)
	cd $(DIST) && tar cfvz cernvm-kernel-$(CVM_KERNEL_VERSION).tar.gz cernvm-kernel-$(CVM_KERNEL_VERSION)
	rm -rf $(DIST)/cernvm-kernel-$(CVM_KERNEL_VERSION)


$(BUILD):
	mkdir -p $(BUILD)

$(SRC):
	mkdir -p $(SRC)

$(DIST):
	mkdir -p $(DIST)


$(BUILD)/awskernel-built: $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).gzip
	touch $(BUILD)/awskernel-built

$(BUILD)/linux-patched: $(BUILD)/linux-unpacked
	touch $(BUILD)/linux-patched

$(KERN_DIR)/.config.gzip: kconfig-cernvm.$(CVM_KERNEL_ARCH) $(BUILD)/linux-unpacked
	sed -e 's/CONFIG_KERNEL_XZ=y//' kconfig-cernvm.$(CVM_KERNEL_ARCH) > $(KERN_DIR)/.config.gzip.tmp
	echo CONFIG_KERNEL_GZIP=y >> $(KERN_DIR)/.config.gzip.tmp
	mv $(KERN_DIR)/.config.gzip.tmp $(KERN_DIR)/.config.gzip

$(KERN_DIR)/.config.xz: kconfig-cernvm.$(CVM_KERNEL_ARCH) $(BUILD)/linux-unpacked
	cp kconfig-cernvm.$(CVM_KERNEL_ARCH) $(KERN_DIR)/.config.xz

$(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).gzip: $(KERN_DIR)/.config.gzip $(BUILD)/linux-built
	cp $(KERN_DIR)/.config.gzip $(KERN_DIR)/.config
	$(MAKE) -C $(KERN_DIR) olddefconfig
	$(MAKE) -C $(KERN_DIR) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE) \
	  $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).gzip

$(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).xz: $(KERN_DIR)/.config.xz $(BUILD)/linux-patched
	cp $(KERN_DIR)/.config.xz $(KERN_DIR)/.config
	$(MAKE) -C $(KERN_DIR) olddefconfig
	$(MAKE) -C $(KERN_DIR) LOCALVERSION=$(CVM_KERNEL_LOCALVERSION)
	mv $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE) \
	  $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).xz

$(BUILD)/depmod-built: $(BUILD)/modules-built $(CVM_GUEST_MODULES)
	/sbin/depmod -a -b $(BUILD)/modules-$(LINUX_VERSION) $(CVM_KERNEL_VERSION)
	touch $(BUILD)/depmod-built

$(BUILD)/headers-built: $(BUILD)/linux-built
	$(MAKE) -C $(KERN_DIR) INSTALL_HDR_PATH=$(BUILD)/headers-$(LINUX_VERSION) headers_install
	touch $(BUILD)/headers-built

$(BUILD)/linux-built: $(KERN_DIR)/arch/$(KERN_ARCH_FAMILY)/boot/$(KERN_IMAGE).xz
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

$(KERN_DIR)/build: $(BUILD)/linux-unpacked
	ln -sf . $(KERN_DIR)/build

$(SRC)/$(LINUX_TARBALL): | $(SRC)
	curl -L -o $(SRC)/$(LINUX_TARBALL) $(LINUX_URL)

clean:
	rm -rf $(BUILD)*

