#!/bin/bash

CHROOT=/chroot/rhel5

##################################################
# Get SL 5.7 files

SL_RPM_BASE=http://rcfzilla.unl.edu/scientific-linux/57/x86_64/SL

# Make a temporary directory
TEMP_RPM_DIR=`mktemp -d`
cd $TEMP_RPM_DIR

wget $SL_RPM_BASE/sl-release-5.7-1.x86_64.rpm
wget $SL_RPM_BASE/yum-conf-57-1.SL.noarch.rpm
wget $SL_RPM_BASE/yum-conf-epel-5-1.noarch.rpm

##################################################
# Make the chroot destination and initialize the RPM database

mkdir -p $CHROOT/var/lib/rpm
rpm --root $CHROOT --initdb

# Install the release and repo RPMs into chroot
rpm --root $CHROOT -ivh --nodeps *.rpm

# Install yum and dependencies into chroot
yum --installroot=$CHROOT install -y yum yum-fastestmirror yum-priorities

##################################################
# Bind mounts

# Make DNS work
touch $CHROOT/etc/resolv.conf
mount --bind /etc/resolv.conf $CHROOT/etc/resolv.conf

# And nscd
mkdir -p $CHROOT/var/run/nscd
mount --bind /var/run/nscd $CHROOT/var/run/nscd

# If you don't use nscd/LDAP, uncomment the following:
mount --bind /etc/passwd $CHROOT/etc/passwd
mount --bind /etc/group  $CHROOT/etc/group

# And bind other system directories
mount --bind /tmp     $CHROOT/tmp
mount --bind /var/tmp $CHROOT/var/tmp
mount --bind /home    $CHROOT/home
mount --bind /proc    $CHROOT/proc
mount --bind /dev     $CHROOT/dev
mount --bind /sys     $CHROOT/sys

# Note we remounted /home above.  Add any additional mounts
# needed for your site!

##################################################
# Convert chroot RPM database to native format

RPMDBFILES="Packages Pubkeys"

# Dump files
cd $CHROOT/var/lib/rpm/
for i in $RPMDBFILES ; do
  /usr/lib/rpm/rpmdb_dump $i > $i.dmp
done

# LCMAPS 
cat > $CHROOT/etc/lcmaps.db << EOF
path = lcmaps

gumsclient = "lcmaps_gums_client.mod"
             "-resourcetype ce"
             "-actiontype execute-now"
             "-capath /etc/grid-security/certificates"
# Nebraska-only: comment out these three lines, as we don't need hostcerts.
# We have a special GUMS server.  You need these lines!
#             "-cert   /etc/grid-security/hostcert.pem"
#             "-key    /etc/grid-security/hostkey.pem"
#             "--cert-owner root"
             "--endpoint https://red-auth.unl.edu:8443/gums/services/GUMSXACMLAuthorizationServicePort"

verifyproxy = "lcmaps_verify_proxy.mod"
          "--allow-limited-proxy"
          " -certdir /etc/grid-security/certificates"

tracking = "lcmaps_process_tracking.mod"
condor_updates = "lcmaps_condor_update.mod"

glexec:

verifyproxy -> gumsclient
gumsclient -> condor_updates
condor_updates -> tracking
EOF

# CVMFS
cat > $CHROOT/etc/cvmfs/default.local << EOF
CVMFS_REPOSITORIES=cms,atlas
CVMFS_HTTP_PROXY="http://red-squid1.unl.edu:3128;DIRECT"
EOF

cat > $CHROOT/etc/security/limits.d/cvmfs.conf << EOF
cvmfs soft nofile 32768
cvmfs hard nofile 32768
EOF

cat >> $CHROOT/etc/auto.master << EOF
# CVMFS additions
/cvmfs /etc/auto.cvmfs
EOF

cat > $CHROOT/etc/fuse.conf << EOF
user_allow_other
EOF

##################################################
# Switch to environment and finish installation
chroot $CHROOT <<'EOF'

RPMDBFILES="Packages Pubkeys"

# Recover BDB environment
cd /var/lib/rpm
/usr/lib/rpm/rpmdb_recover
rm log.0000000001

# Load RPM data
for i in $RPMDBFILES ; do
  /usr/lib/rpm/rpmdb_load -f $i.dmp $i.new
  mv $i.new $i
  rm $i.dmp
done

# Rebuild RPM database
rpm --rebuilddb

##################################################
# Install base group and other RPMs
yum groupinstall -y Base --exclude=openssh-clients

# Bootstrap the OSG repos and set the priorities.
cd /tmp
wget http://repo.grid.iu.edu/osg-release-latest.rpm
yum install -y osg-release-latest.rpm
sed -i /etc/yum.repos.d/osg* -e 's|priority=98|priority=49|'

# Install the OSG client.
yum --enablerepo=osg-testing install -y osg-wn-client

##################################################
# Install WLCG RPMs.
# See https://twiki.cern.ch/twiki/bin/view/LCG/SL5DependencyRPM

curl http://grid-deployment.web.cern.ch/grid-deployment/download/HEP/repo/HEP_OSlibs.repo > /etc/yum.repos.d/HEP_OSlibs.repo
yum install -y HEP_OSlibs_SL5

##################################################
# glexec support (note we setup lcmaps.db previously)
yum install -y --enablerepo=osg-testing glexec
yum install -y --enablerepo=osg-development lcmaps-plugins-condor-update lcmaps-plugins-process-tracking

##################################################
# CVMFS support
# For demo purposes only; don't download a GPG key through HTTP as below!!!!
# Note: cvmfs user and fuse group must be pre-existing.
# Note: cvmfs user must be in fuse group.
# cd /etc/yum.repos.d/
# wget http://cvmrepo.web.cern.ch/cvmrepo/yum/cernvm.repo
# cd /etc/pki/rpm-gpg/
# wget http://cvmrepo.web.cern.ch/cvmrepo/yum/RPM-GPG-KEY-CernVM
# yum -y install cvmfs cvmfs-init-scripts cvmfs-keys

service autofs restart
service cvmfs restartclean

EOF

