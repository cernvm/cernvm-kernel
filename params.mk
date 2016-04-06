CVM_KERNEL_ARCH = $(shell uname -m)
CVM_KERNEL_RELEASE = $(shell cat release)
CVM_KERNEL_LOCALVERSION = -$(CVM_KERNEL_RELEASE).cernvm.$(CVM_KERNEL_ARCH)
CVM_KERNEL_VERSION = $(LINUX_VERSION)$(CVM_KERNEL_LOCALVERSION)

ifeq ($(CVM_KERNEL_ARCH),ppc64le)
  KERN_ARCH_FAMILY = powerpc
  KERN_IMAGE = zImage
else
  KERN_ARCH_FAMILY = x86
  KERN_IMAGE = bzImage
endif

DIST = $(TOP)/dist
BUILD = $(TOP)/build-$(CVM_KERNEL_VERSION)
SRC = $(TOP)/src-$(CVM_KERNEL_VERSION)
KERN_DIR = $(BUILD)/linux-$(LINUX_VERSION)

LINUX_VERSION = 4.1.21
LINUX_TARBALL = linux-$(LINUX_VERSION).tar.xz
LINUX_URL = https://www.kernel.org/pub/linux/kernel/v4.x/$(LINUX_TARBALL)

AFS_VERSION = 1.6.11.1
AFS_TARBALL = openafs-$(AFS_VERSION)-src.tar.bz2
AFS_URL = http://www.openafs.org/dl/openafs/$(AFS_VERSION)/$(AFS_TARBALL)

AUFS_BRANCH = aufs4.1
AUFS_GIT = https://github.com/cernvm/aufs4-standalone.git

VBOX_VERSION = 4.3.28
VBOX_ISO = VBoxGuestAdditions_$(VBOX_VERSION).iso
VBOX_URL = http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/$(VBOX_ISO)

VMTOOLS_VERSION = 10.0.0-3000743
VMTOOLS_TARBALL = open-vm-tools-$(VMTOOLS_VERSION).tar.gz
VMTOOLS_URL = https://ecsft.cern.ch/dist/cernvm/$(VMTOOLS_TARBALL)
