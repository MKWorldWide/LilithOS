#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Quantum Portal (Glass)            ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
show_status() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}Remote Access Status (Demo):${GLASS_RESET}"
  echo -e "  SSH: Enabled (port 2222)"
  echo -e "  Web Dashboard: Enabled (https://localhost:8443)"
  echo -e "  2FA: Enabled"
  echo -e "  Sessions: 0 active"
  echo ""
  read -p "Press Enter to return to dashboard..."
}
show_status 