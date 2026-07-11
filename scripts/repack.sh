#!/usr/bin/env bash
#
# Repack a stock Armbian BigTreeTech CB1 image into a per-board Sovobian image:
#   1. compile the board overlay (.dts -> .dtbo);
#   2. drop it into overlay-user/ on the boot filesystem inside the image;
#   3. point fdtfile at the eMMC-enabled CB1 dtb and register the overlay
#      in armbianEnv.txt.
#
# The base OS is untouched: kernel upgrades via apt keep working because the
# overlay lives in overlay-user/, which kernel packages never overwrite.
#
# Requires: Linux, root (losetup/mount), dtc.
#
# Usage: repack.sh <base.img> <overlay.dts> <output.img>

set -euo pipefail
shopt -s nullglob

FDTFILE="sun50i-h616-bigtreetech-cb1-emmc.dtb"

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <base.img> <overlay.dts> <output.img>" >&2
    exit 1
fi

if [ "$(id --user)" -ne 0 ]; then
    echo "$0 must run as root (losetup/mount)" >&2
    exit 1
fi

base_img="$1"
overlay_dts="$2"
output_img="$3"
overlay_name="$(basename "$overlay_dts" .dts)"

workdir="$(mktemp --directory)"
mnt="$workdir/mnt"
loopdev=""

cleanup() {
    if mountpoint --quiet "$mnt" 2> /dev/null; then
        umount "$mnt"
    fi
    if [ -n "$loopdev" ]; then
        losetup --detach "$loopdev"
    fi
    rm --recursive --force "$workdir"
}
trap cleanup EXIT

dtc -I dts -O dtb -o "$workdir/$overlay_name.dtbo" "$overlay_dts"

cp "$base_img" "$output_img"

loopdev="$(losetup --find --show --partscan "$output_img")"
mkdir "$mnt"

# Locate armbianEnv.txt: on a separate boot partition it sits at the
# partition root, on a single-partition image it lives under /boot.
bootdir=""
for part in "$loopdev"p*; do
    mount "$part" "$mnt"
    if [ -f "$mnt/armbianEnv.txt" ]; then
        bootdir="$mnt"
        break
    elif [ -f "$mnt/boot/armbianEnv.txt" ]; then
        bootdir="$mnt/boot"
        break
    fi
    umount "$mnt"
done

if [ -z "$bootdir" ]; then
    echo "armbianEnv.txt not found in any partition of $base_img" >&2
    exit 1
fi

env_file="$bootdir/armbianEnv.txt"

mkdir --parents "$bootdir/overlay-user"
cp "$workdir/$overlay_name.dtbo" "$bootdir/overlay-user/"

if grep --quiet '^fdtfile=' "$env_file"; then
    sed --in-place "s|^fdtfile=.*|fdtfile=$FDTFILE|" "$env_file"
else
    echo "fdtfile=$FDTFILE" >> "$env_file"
fi

if grep --quiet '^user_overlays=' "$env_file"; then
    sed --in-place "s|^user_overlays=.*|user_overlays=$overlay_name|" "$env_file"
else
    echo "user_overlays=$overlay_name" >> "$env_file"
fi

sync
echo "repacked: $output_img (overlay=$overlay_name, fdtfile=$FDTFILE)"
