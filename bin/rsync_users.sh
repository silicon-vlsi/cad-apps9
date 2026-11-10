#!/usr/bin/bash
# migrate-homes.sh — copy home directories from the old server, one user at a time,
# preserving numeric UID/GID, permissions, ACLs and xattrs, then relabel for SELinux.
#
# Run on srv01 as root:   sudo -i ; ./migrate-homes.sh
# Dry run (no changes):   DRYRUN=1 ./migrate-homes.sh
# Final pass (mirror):    DELETE=1 ./migrate-homes.sh   (removes files deleted on the source)

SRC_HOST="root@192.168.11.237"        # or youruser@oldhost and set RSYNC_PATH below
SRC_BASE="/home"               # where homes live on the old server
RSYNC_PATH=""                  # e.g. "sudo rsync" when not connecting as root
LOG="/var/log/migrate-homes-$(date +%F_%H%M%S).log"

# One entry per line:  login  target-volume (nfs1 or nfs2)
USERS_DONE="
mvlab1  nfs2
mvlab2  nfs2
mvlab3  nfs2
mvlab4  nfs2
mvlab5  nfs2
mvlab6  nfs2
sic2s1  nfs2
sic2s2  nfs2
sic2s3  nfs2
sic2s4  nfs2
sic2s5  nfs2
vlab1  nfs2
vlab10  nfs2
vlab11  nfs2
vlab12  nfs2
vlab13  nfs2
vlab14  nfs2
vlab15  nfs2
vlab16  nfs2
vlab17  nfs2
vlab18  nfs2
vlab19  nfs2
vlab2  nfs2
vlab20  nfs2
vlab21  nfs2
vlab22  nfs2
vlab23  nfs2
vlab24  nfs2
vlab25  nfs2
vlab26  nfs2
vlab27  nfs2
vlab28  nfs2
vlab29  nfs2
vlab3  nfs2
vlab30  nfs2
vlab31  nfs2
vlab32  nfs2
vlab33  nfs2
vlab34  nfs2
vlab35  nfs2
vlab36  nfs2
vlab37  nfs2
vlab38  nfs2
vlab39  nfs2
vlab4  nfs2
vlab40  nfs2
vlab41  nfs2
vlab42  nfs2
vlab43  nfs2
vlab44  nfs2
vlab45  nfs2
vlab46  nfs2
vlab47  nfs2
vlab48  nfs2
vlab49  nfs2
vlab5  nfs2
vlab50  nfs2
vlab6  nfs2
vlab7  nfs2
vlab8  nfs2
vlab9  nfs2
"

USERS="
"

# ---------------------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo -i)"; exit 1; }

opts=(-aHAXS --numeric-ids --filter='-x security.selinux' --info=stats1)
[ -n "$DRYRUN" ]     && opts+=(-n)
[ -n "$DELETE" ]     && opts+=(--delete)
[ -n "$RSYNC_PATH" ] && opts+=(--rsync-path="$RSYNC_PATH")

log() { echo "$(date '+%F %T')  $*" | tee -a "$LOG"; }

ok=(); failed=()
log "Start: source $SRC_HOST:$SRC_BASE  dryrun=${DRYRUN:-0} delete=${DELETE:-0}"

while read -r user vol; do
    [ -z "$user" ] && continue
    case $vol in nfs1|nfs2) ;; *) log "SKIP $user: bad volume '$vol'"; failed+=("$user"); continue ;; esac

    dest="/home/$vol/$user"
    log "---- $user -> $dest"

    if ! id "$user" >/dev/null 2>&1; then
        log "FAIL $user: not found in IPA (id lookup failed)"
        failed+=("$user"); continue
    fi

    [ -n "$DRYRUN" ] || mkdir -p "$dest"

    rsync "${opts[@]}" "$SRC_HOST:$SRC_BASE/$vol/$user/" "$dest/" >>"$LOG" 2>&1
    rc=$?
    if [ $rc -ne 0 ] && [ $rc -ne 24 ]; then       # 24 = some source files vanished, harmless
        log "FAIL $user: rsync exit $rc"
        failed+=("$user"); continue
    fi
    [ $rc -eq 24 ] && log "WARN $user: some files vanished during transfer"

    if [ -z "$DRYRUN" ]; then
        restorecon -R "$dest" >>"$LOG" 2>&1 || log "WARN $user: restorecon reported errors"
        log "OK   $user  owner=$(stat -c '%u:%g' "$dest") context=$(stat -c '%C' "$dest")"
    else
        log "OK   $user (dry run)"
    fi
    ok+=("$user")
done <<< "$USERS"

log "Done: ${#ok[@]} ok, ${#failed[@]} failed${failed:+: ${failed[*]}}"
echo "Log: $LOG"
[ ${#failed[@]} -eq 0 ]
