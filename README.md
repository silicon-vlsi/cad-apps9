# cad-apps9
Scripts, modulefiles, etc .. for the Advanced VLSI Lab CAD 

# Rocky 9 installation

## VNC Server

```bash
dnf install tigervnc-server

# /etc/tigervnc/vncserver.users
:1=username

# ~/.config/tigervnc/config
# Check /usr/share/xsessions/ for installed desktops eg. gnome, xfce
session=xfce
geometry=1920x1080

# ~/.config/tigervnc/passwd
vncpasswd

#open port in firewall
firewall-cmd --permanent --add-port=5901/tcp
firewall-cmd --reload

# startup
systemctl enable --now vncserver@:1.service

# For status/restart
# systemctl status/restart vncserver@:1.service

```

## QUOTAS

```bash
## /etc/fstab
/dev/mapper/rl-home_nfs1 /home/nfs1  xfs defaults,uquota,pquota  0 0
/dev/mapper/rl-home_nfs2 /home/nfs2  xfs defaults,uquota,pquota  0 0

umount /home/nfs1
umount /home/nfs2

mount -a

## Set default quotas but it doesn't apply to existing users
sudo xfs_quota -x -c 'limit -u bsoft=4g bhard=5g -d' /home/nfs1
sudo xfs_quota -x -c 'limit -u bsoft=4g bhard=5g -d' /home/nfs2

## Dry run Script to find users with zero limit
xfs_quota -x -c 'report -ubN' /home/nfs1 \
 | awk '$1!="root" && $3==0 && $4==0 {sub(/^#/,"",$1); print $1}' \
 | while read u; do echo "$u"; done

## Script to set explicit limit for those users
xfs_quota -x -c 'report -ubN' /home/nfs1 \
 | awk '$1!="root" && $3==0 && $4==0 {sub(/^#/,"",$1); print $1}' \
 | while read u; do
     xfs_quota -x -c "limit -u bsoft=4g bhard=5g $u" /home/nfs1
   done
## Do the same for other mounts eg. /home/nfs2

```
