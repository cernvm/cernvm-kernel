LINUX_VERSION = 3.18.18
LINUX_TARBALL = linux-$(LINUX_VERSION).tar.xz
LINUX_URL = https://www.kernel.org/pub/linux/kernel/v3.x/$(LINUX_TARBALL)

AFS_VERSION = 1.6.11
AFS_TARBALL = openafs-$(AFS_VERSION)-src.tar.bz2
AFS_URL = http://www.openafs.org/dl/openafs/$(AFS_VERSION)/$(AFS_TARBALL)

AUFS_BRANCH = aufs3.18.1+
AUFS_GIT = git://git.code.sf.net/p/aufs/aufs3-standalone

VBOX_VERSION = 4.3.28
VBOX_ISO = VBoxGuestAdditions_$(VBOX_VERSION).iso
VBOX_URL = http://download.virtualbox.org/virtualbox/$(VBOX_VERSION)/$(VBOX_ISO)

VMTOOLS_VERSION = 9.4.6-1770165
VMTOOLS_TARBALL = open-vm-tools-$(VMTOOLS_VERSION).tar.gz
VMTOOLS_URL = https://ecsft.cern.ch/dist/cernvm/$(VMTOOLS_TARBALL)

CVM_KERNEL_ARCH = x86_64
CVM_KERNEL_RELEASE = $(shell cat release)
CVM_KERNEL_LOCALVERSION = -$(CVM_KERNEL_RELEASE).cernvm.$(CVM_KERNEL_ARCH)
CVM_KERNEL_VERSION = $(LINUX_VERSION)$(CVM_KERNEL_LOCALVERSION)

DIST = $(TOP)/dist
BUILD = $(TOP)/build-$(CVM_KERNEL_VERSION)
SRC = $(TOP)/src-$(CVM_KERNEL_VERSION)
KERN_DIR = $(BUILD)/linux-$(LINUX_VERSION)
