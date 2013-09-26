cernvm-kernel
=============

Contains build configuration for the µCernVM Linux kernel and busybox.

## µCernVM Linux Kernel

The CernVM Kernel is a virtualization friendly Linux kernel.
It is intended to be used by a CernVM guest OS.
In contrast to an (S)LC kernel, it is lightweight and provides the newest
features wrt virtualization and memory management techniques.

Features:
  * Based on 3.6 vanilla
  * (Paravirtualized) device drivers for
     KVM, Xen, VMware, VirtualBox, and HyperV
  * Boots an SL6 OS and possibly other distributions
  * Provides the following options
    - X32 ABI support
    - Kernel SamePage Merging (KSM)
    - Transparent Huge Pages (THP)
    - zRam, zCache, cleancache, frontswap
    - (All) cgroup controllers
    - Aufs3 (patched from aufs upstream)
    - ext2-4, XFS, Btrfs (module), NTFS (module), Fuse (module)
    - NFS 3, 4, 4.1
    - LVM / device mapper

Kernel, Ramdisk, and modules are 10MB--20MB in size, compared to >100MB of SL6.
After boot, it occupies ~25MB less memory than the SL6 kernel.

## Busybox used in µCernVM

The busybox configuration is not primarily optimized for size
but it is meant to provide a sufficiently comfortable environment to debug µCernVM

## Build Products

Kernel and busybox are built on
[Electric Commander](https://ecsft.cern.ch/dist/cernvm).
