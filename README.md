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
