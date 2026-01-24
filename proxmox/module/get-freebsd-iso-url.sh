#!/bin/sh
# Outputs FreeBSD amd64 ISO URL, filename, and SHA256 from the official CHECKSUM file.
# Used by Terraform external data source. Rigid URL scheme:
#   https://download.freebsd.org/releases/ISO-IMAGES/VERSION/FreeBSD-VERSION-RELEASE-amd64-TYPE.iso
#   https://download.freebsd.org/releases/ISO-IMAGES/VERSION/CHECKSUM.SHA256-FreeBSD-VERSION-RELEASE-amd64
#
# Args: version (e.g. 15.0), image_type (e.g. bootonly, disc1, dvd1).
# Requires: curl or wget, grep, sed. Network access to download.freebsd.org.
set -e
V="${1:-15.0}"
T="${2:-bootonly}"
FN="FreeBSD-${V}-RELEASE-amd64-${T}.iso"
BASE="https://download.freebsd.org/releases/ISO-IMAGES/${V}"
URL="${BASE}/${FN}"
CHECKSUM_URL="${BASE}/CHECKSUM.SHA256-FreeBSD-${V}-RELEASE-amd64"

BODY=$(curl -sL "$CHECKSUM_URL" 2>/dev/null) || BODY=$(wget -qO- "$CHECKSUM_URL" 2>/dev/null) || true
if [ -z "$BODY" ]; then
  printf '{"error":"could not fetch CHECKSUM from %s"}\n' "$CHECKSUM_URL" >&2
  exit 1
fi
# Format: "SHA256 (FreeBSD-15.0-RELEASE-amd64-bootonly.iso) = 78b40ce..."
SHA=$(echo "$BODY" | grep -F "($FN)" | head -1 | sed -n 's/.*= \([0-9a-f]\{64\}\).*/\1/p')
if [ -z "$SHA" ]; then
  printf '{"error":"no SHA256 line for %s in CHECKSUM"}\n' "$FN" >&2
  exit 1
fi
printf '{"iso_url":"%s","iso_filename":"%s","sha256":"%s"}\n' "$URL" "$FN" "$SHA"
