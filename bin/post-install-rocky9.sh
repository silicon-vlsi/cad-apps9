#!/bin/sh
#
if [ $# -ne 1 ]
then
  echo " "
  echo "Usage: post-install-rocky9.sh <option>"
  echo " "
  echo "DESCRIPTION:  Options are "
  echo "  all:       runs the entire scripts"
  echo "  addhosts:  Adds hostnames to /etc/hosts"
  echo "  mkmnt:     Makes all the mount points /CAD etc"
  echo "  fstab:     appends the NFS mounts to /etc/fstab"
  echo "  pkgmin:    Minimal packages to get the CAD system running"
  echo "  link:      Creates the soft links silicon.csh and cron.daily.silicon"
  echo "  nis:       Sets up the NIS server"
  echo "  localsim:  sets up /home/local/simulation"
  echo "  localdoc:  creates /home/local/docs"
  echo " "
  exit 1
fi

if [ $1 == "pkgmin" ] || [ $1 == "all" ]
then
  echo "CHECKING AND INSTALLING PACKAGES:"
#pckarr=( \
#  epel-release environment-modules tree tigervnc-server subversion git \
#  numpy python-matplotlib tcl tk ypbind rpcbind \
#  glibc glibc.i686 elfutils-libelf ksh mesa-libGL \ 
#  mesa-libGLU motif libXp libpng libjpeg-turbo \
#  expat glibc-devel gdb xorg-x11-fonts-misc \
#  xorg-x11-fonts-ISO8859-1-75dpi redhat-lsb \
#  libXScrnSaver libXaw apr apr-util compat-db47 \
#  xorg-x11-server-Xvfb mesa-dri-drivers openssl-devel \ 
#  cronie-anacron iverilog gtkwave \
#  gcc gcc-c++ \
#)

## Python pkgs are propbably loaded via pip in ROcky. Not finding these pkgs
#numpy python-matplotlib 
## NIS is deprecates Rocky 9 .. not available any more :-(
#ypserv ypbind 

pckarr=( \
  epel-release environment-modules tree tigervnc-server subversion git \
  tcl tk rpcbind nfs-utils \
)

for i in  ${pckarr[*]}
 do
  isinstalled=$(rpm -q $i)
  #echo Package  $i 
  if [ !  "$isinstalled" == "package $i is not installed" ];
   then
    echo "--installed** $i"
  else
    echo "**NOT INSTALLED** INSTALLLING $i"
    dnf install -y $i	# Installs without asking
  fi
 done

fi
if [ $1 == "addhosts" ] || [ $1 == "all" ]
then
  echo "#################################"
  echo "# CHECKING /etc/hosts #"
  echo "#################################"
  # CHeck if the current host is in /etc/hosts
  thishost=`hostname`
  if grep -q $thishost /etc/hosts ; then
    echo "This host exists in /etc/hosts"
  else
    echo "This host **DOES NOT** exists in /etc/hosts adding ..."
    ethdev=`nmcli connection show --active | grep ethernet | awk '{print $1}'`
    ipaddr=`nmcli -g ipv4.addresses connection show $ethdev`
    echo "$ipaddr $thishost" >> /etc/hosts
  fi
  # Check if servers are on /etc/hosts
  echo "Checking if servers are in /etc/hosts"
  if grep -q srv02.vlsi.silicon.ac.in /etc/hosts ; then
    echo "/etc/hosts seems to populated with the following:"
    cat /etc/hosts
  else
    echo "ADDING hostnames in /etc/hosts"
    cat >> /etc/hosts <<EOF
192.168.11.221  srv01.vlsi.silicon.ac.in srv01
192.168.11.229  srv02.vlsi.silicon.ac.in srv02 srv02.silicon.ac.in cdslicserv mgclicsrv.vlsi.silicon.ac.in mgclicserv
192.168.11.237  srv03.vlsi.silicon.ac.in srv03
EOF
  fi
fi


## NOTE: Rocky9 does not create user 'nfsnobody' by default. 'nobody' is used instead.
if [ $1 == "mkmnt" ] || [ $1 == "all" ]
then
  echo "#################################"
  echo "# CHECKING MOUNTS /CAD /PDK /home/nfs1 /home/nfs2 #"
  echo "#################################"
  if [ ! -d /CAD ] ; then
    mkdir /CAD
    chown nfsnobody:nfsnobody /CAD
  else
    echo "Directory /CAD exists.. Checking permissions"
    perm=`ls -ald /CAD | awk '{print $3$4}'`
    if [ $perm == "nobodynobody" ] ; then
      echo "Permision looks fine .. check below.."
      ls -ald /CAD
    else
      chown nobody:nobody /CAD
    fi
  fi
  if [ ! -d /PDK ] ; then
    mkdir /PDK
    chown nobody:nobody /PDK
  else
    echo "Directory /PDK exists.. Checking permissions"
    perm=`ls -ald /PDK | awk '{print $3$4}'`
    if [ $perm == "nobodynobody" ] ; then
      echo "Permision looks fine .. check below.."
      ls -ald /PDK
    else
      chown nobody:nobody /PDK
    fi
  fi
  if [ ! -d /home/nfs1 ] ; then
    mkdir /home/nfs1
    chown nobody:nobody /home/nfs1
  else
    echo "Directory /home/nfs1 exists.. Checking permissions"
    perm=`ls -ald /home/nfs1 | awk '{print $3$4}'`
    if [ $perm == "nobodynobody" ] ; then
      echo "Permision looks fine .. check below.."
      ls -ald /home/nfs1
    else
      chown nobody:nobody /home/nfs1
    fi
  fi
  if [ ! -d /home/nfs2 ] ; then
    mkdir /home/nfs2
    chown nobody:nobody /home/nfs2
  else
    echo "Directory /home/nfs2 exists.. Checking permissions"
    perm=`ls -ald /home/nfs2 | awk '{print $3$4}'`
    if [ $perm == "nobodynobody" ] ; then
      echo "Permision looks fine .. check below.."
      ls -ald /home/nfs2
    else
      chown nobody:nobody /home/nfs2
    fi
  fi
fi


if [ $1 == "fstab" ] || [ $1 == "all" ]
then
  echo "#################################"
  echo "# ADDING MOUNT POINTS TO /etc/fstab #"
  echo "#################################"
  if grep -q "srv01:/home/nfs1" /etc/fstab ; then
    echo "/etc/fstab looks fine .. check"
  else
    cat >> /etc/fstab <<EOF
# NFS mounts from srv01.vlsi.silicon.ac.in
srv01:/home/nfs1  /home/nfs1      nfs     noatime,rsize=32768,wsize=32768
srv01:/home/nfs2  /home/nfs2      nfs     noatime,rsize=32768,wsize=32768
srv01:/CAD        /CAD            nfs     noatime,rsize=32768,wsize=32768
srv01:/PDK        /PDK            nfs     noatime,rsize=32768,wsize=32768
EOF
  fi 
mount -a
systemctl daemon-reload
fi


