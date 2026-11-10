#!/usr/bin/env bash
# claude-gen on 11/05/2026
# /usr/local/sbin/ipa-newuser  -v nfs1|nfs2  <login> <first> <last>
klist -s || { echo "No Kerberos ticket: run kinit admin first"; exit 1; }

set -euo pipefail	#fails on any error

vol=""

usage() { echo "usage: $0 -v nfs1|nfs2 login first last"; exit 1; }
while getopts "v:" opt; do
  case $opt in
    v) vol=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 3 ] || usage
case $vol in 
  nfs1|nfs2) ;;
  *) echo "error: -v must be nfs1 or nfs2"; usage ;;
esac

base=/home/$vol
[ -d "$base" ] || { echo "error: $base does not exist"; exit 1; }

ipa user-add "$1" --first="$2" --last="$3" --shell=/usr/bin/csh \
		  --homedir="$base/$1" --password
#invalidates SSSD's cached entry for that login.
sss_cache -u "$1"
uid=$(id -u "$1"); gid=$(id -g "$1")
##Creates directory and sets the permission to 750
install -d -m 700 -o "$uid" -g "$gid" "$base/$1"
cp -a /etc/skel/. "$base/$1"/
chown -R "$uid:$gid" "$base/$1"
#resets SELinux labels
restorecon -R "$base/$1"
echo "Created $1 (uid $uid) with home $base/$1"

