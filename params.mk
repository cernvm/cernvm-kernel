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

LINUX_VERSION = 4.14.6
LINUX_TARBALL = linux-$(LINUX_VERSION).tar.xz
LINUX_URL = https://www.kernel.org/pub/linux/kernel/v4.x/$(LINUX_TARBALL)

AFS_VERSION = 1.6.17
AFS_TARBALL = openafs-$(AFS_VERSION)-src.tar.bz2
AFS_URL = http://www.openafs.org/dl/openafs/$(AFS_VERSION)/$(AFS_TARBALL)

AUFS_BRANCH = aufs4.1
AUFS_GIT = https://github.com/cernvm/aufs4-standalone.git

ENA_BRANCH = master
ENA_GIT = https://github.com/cernvm/amzn-drivers.git

VBOX_VERSION = 4.3.28
VBOX_ISO = VBoxGuestAdditions_$(VBOX_VERSION).iso
VBOX_URL = http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/$(VBOX_ISO)

VBOX51_VERSION = 5.1.8
VBOX51_ISO = VBoxGuestAdditions_$(VBOX51_VERSION).iso
VBOX51_URL = https://ecsft.cern.ch/dist/cernvm/$(VBOX51_ISO)

VMTOOLS_VERSION = 10.0.0-3000743
VMTOOLS_TARBALL = open-vm-tools-$(VMTOOLS_VERSION).tar.gz
VMTOOLS_URL = https://ecsft.cern.ch/dist/cernvm/$(VMTOOLS_TARBALL)
