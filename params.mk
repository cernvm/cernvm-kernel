CVM_KERNEL_ARCH = $(shell uname -m)
CVM_KERNEL_RELEASE = $(shell cat release)
CVM_KERNEL_LOCALVERSION = -$(CVM_KERNEL_RELEASE).cernvm.$(CVM_KERNEL_ARCH)
CVM_KERNEL_VERSION = $(LINUX_VERSION)$(CVM_KERNEL_LOCALVERSION)

ifeq ($(CVM_KERNEL_ARCH),ppc64le)
  KERN_ARCH_FAMILY = powerpc
  KERN_IMAGE = zImage
endif
ifeq ($(CVM_KERNEL_ARCH),x86_64)
  KERN_ARCH_FAMILY = x86
  KERN_IMAGE = bzImage
endif
ifeq ($(CVM_KERNEL_ARCH),i686)
  KERN_ARCH_FAMILY = x86
  KERN_IMAGE = bzImage
endif
ifeq ($(CVM_KERNEL_ARCH),aarch64)
  KERN_ARCH_FAMILY = arm64
  KERN_IMAGE = Image
endif

DIST = $(TOP)/dist
BUILD = $(TOP)/build-$(CVM_KERNEL_VERSION)
SRC = $(TOP)/src-$(CVM_KERNEL_VERSION)
KERN_DIR = $(BUILD)/linux-$(LINUX_VERSION)

LINUX_VERSION = 4.14.157
LINUX_TARBALL = linux-$(LINUX_VERSION).tar.xz
LINUX_URL = https://www.kernel.org/pub/linux/kernel/v4.x/$(LINUX_TARBALL)

AUFS_BRANCH = aufs4.14
AUFS_GIT = https://github.com/cernvm/aufs4-standalone.git

VBOX_VERSION = 5.2.6
VBOX_ISO = VBoxGuestAdditions_$(VBOX_VERSION).iso
VBOX_URL = http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/$(VBOX_ISO)
