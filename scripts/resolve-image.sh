#!/usr/bin/env bash
#
# Print the upstream Armbian CB1 minimal image file name for a given version,
# preferring Debian releases over Ubuntu ones. Point releases do not always
# ship every distribution, so the distro branch is resolved dynamically.
#
# Usage: resolve-image.sh <armbian-version>

set -euo pipefail

ARCHIVE_URL="${ARCHIVE_URL:-https://dl.armbian.com/bigtreetech-cb1/archive}"

version="${1:?usage: resolve-image.sh <armbian-version>}"
listing="$(curl --silent --fail --location "$ARCHIVE_URL/")"

for distro in trixie forky resolute noble; do
    candidate="$(printf '%s\n' "$listing" \
        | grep --only-matching --extended-regexp \
            "Armbian_${version}_Bigtreetech-cb1_${distro}_current_[0-9.]+_minimal\.img\.xz" \
        | sort --version-sort --unique | tail --lines=1)" || true
    if [ -n "$candidate" ]; then
        printf '%s\n' "$candidate"
        exit 0
    fi
done

echo "no minimal image for Armbian $version found at $ARCHIVE_URL" >&2
exit 1
