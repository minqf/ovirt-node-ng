#
# Platform repositories
#
url --url=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=updates --mirrorlist=http://mirrorlist.centos.org/?repo=updates&release=$releasever&arch=$basearch
repo --name=extra --mirrorlist=http://mirrorlist.centos.org/?repo=extras&release=$releasever&arch=$basearch

lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
network
auth --enableshadow --passalgo=sha512
selinux --permissive
rootpw --lock
user --name=node --lock
firstboot --reconfig

clearpart --all --initlabel
bootloader --timeout=1
part / --size=3072 --fstype=ext4 --fsoptions=discard

poweroff


#
# Packages
#
%packages --excludedocs --ignoremissing
#
# Additional packages for EFI support
# https://www.brianlane.com/creating-live-isos-with-livemedia-creator.html
# http://lorax.readthedocs.org/en/latest/livemedia-creator.html#kickstarts
dracut-config-generic
-dracut-config-rescue
grub2-efi
memtest86+
syslinux
%end


#
# Add custom post scripts after the base post.
#
%post --erroronfail

# setup systemd to boot to the right runlevel
echo "Setting default runlevel to multiuser text mode"
ln -fvs /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

echo "Cleaning old yum repodata."
yum clean all
%end


#
# Adds the latest cockpit bits
#
%post --erroronfail
set -x
mkdir -p /etc/yum.repos.d
curl -L -o /etc/yum.repos.d/cockpit-preview-epel-7.repo "https://copr.fedoraproject.org/coprs/g/cockpit/cockpit-preview/repo/epel-7/msuchy-cockpit-preview-epel-7.repo"
yum install --nogpgcheck -y cockpit
%end


#
# Adding upstream oVirt vdsm
#
%post --erroronfail
set -x

repo_ovirt="plain.resources.ovirt.org/pub/yum-repo"
# 1. Install oVirt release file with repositories
yum install -y http://${repo_ovirt}/ovirt-release36.rpm
yum install -y http://${repo_ovirt}/ovirt-release36-snapshot.rpm


# 2. Install oVirt Node release
yum install -y ovirt-release36-host-node

# 3. Add the placeholder for subsequent updates
yum install -y ovirt-node-ng-image-update-placeholder

# HACKS
# FIXME https://bugzilla.redhat.com/show_bug.cgi?id=1309912
yum install -y vdsm-cli

# Disable all repositories
# FIXME should this be here or in imgbased post-processing?
sed -i "s/^enabled=.*/enabled=0/" /etc/yum.repos.d/*

yum clean all

imgbase --debug --experimental image-build --postprocess
%end
