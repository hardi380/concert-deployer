#!/usr/bin/env bash
# ==============================================================================
# Script: run-local.sh
# Description: Executes IBM Concert Ansible Playbook from your local workstation
#              against the currently active OpenShift context (via 'oc').
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "===================================================================="
echo "  IBM Concert Deployer - Local Execution Runner"
echo "===================================================================="

# Check if oc is available and logged in
if ! command -v oc &> /dev/null; then
  echo "Error: 'oc' CLI is not found in PATH. Please install OpenShift CLI." >&2
  exit 1
fi

CURRENT_USER=$(oc whoami 2>/dev/null || true)
if [ -z "${CURRENT_USER}" ]; then
  echo "Error: Not logged into OpenShift cluster. Please run 'oc login' first." >&2
  exit 1
fi

echo "Connected to OpenShift as: ${CURRENT_USER}"
echo "Current Server: $(oc whoami --show-server)"

# Check for IBM Entitlement Key
if [ -z "${IBM_ENTITLEMENT_KEY:-}" ]; then
  echo ""
  echo "IBM_ENTITLEMENT_KEY environment variable is not set."
  read -r -s -p "Enter your IBM Entitlement Key: " IBM_ENTITLEMENT_KEY
  echo ""
  export IBM_ENTITLEMENT_KEY
fi

# Ensure Python requirements and collections are installed
cd "${PROJECT_ROOT}"

if [ ! -d "collections" ]; then
  echo "Installing Ansible collections..."
  ansible-galaxy collection install -r requirements.yml
fi

echo "===================================================================="
echo "Starting Ansible deployment..."
echo "===================================================================="
ansible-playbook -i inventory/localhost.yml playbooks/install_concert.yml "$@"
