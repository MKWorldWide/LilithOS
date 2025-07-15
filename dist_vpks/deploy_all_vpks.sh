#!/bin/bash
# ============================================================================
# deploy_all_vpks.sh - Quantum-Documented Deployment Script for LilithOS PS Vita VPKs
#
# This script deploys all VPKs in dist_vpks/ to a PS Vita device via FTP (VitaShell).
# - User supplies Vita IP address
# - Uses curl to upload each .vpk to ux0:/VPK/
#
# Usage:
#   ./deploy_all_vpks.sh <VITA_IP>
#
# Dependencies: curl, VitaShell FTP server running on Vita
# Security: FTP is plaintext; use only on trusted networks
# ============================================================================
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <VITA_IP>"
  exit 1
fi
VITA_IP="$1"
VITA_FTP="ftp://$VITA_IP:1337/ux0:/VPK/"

DIST_DIR="$(pwd)"

for vpk in "$DIST_DIR"/*.vpk; do
  echo "[INFO] Uploading $vpk to $VITA_FTP..."
  curl -T "$vpk" "$VITA_FTP"
  echo "[SUCCESS] Uploaded $vpk"
done

echo "[COMPLETE] All VPKs deployed to PS Vita at $VITA_IP. Install via VitaShell."
