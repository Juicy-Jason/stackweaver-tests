#!/bin/sh
# Outputs the latest Debian amd64 netinst ISO URL and filename as JSON
# for Terraform external data source. Fetches the cdimage directory listing
# and parses for debian-MAJOR.MINOR.PATCH-amd64-netinst.iso (e.g. 13.x, 14.x).
# The "current" URL always points at the latest stable, so any major is fine.
# Requires: curl or wget, grep. The Terraform runner needs network access to cdimage.debian.org.
set -e
BASE="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd"
HTML=$(curl -sL "$BASE/" 2>/dev/null) || HTML=$(wget -qO- "$BASE/" 2>/dev/null) || { printf '{"iso_url":"","iso_filename":""}\n'; exit 1; }
FN=$(echo "$HTML" | grep -oE 'debian-[0-9]+\.[0-9]+\.[0-9]+-amd64-netinst\.iso' | head -1)
if [ -z "$FN" ]; then
  printf '{"iso_url":"","iso_filename":""}\n'
  exit 1
fi
printf '{"iso_url":"%s/%s","iso_filename":"%s"}\n' "$BASE" "$FN" "$FN"
