#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Gaming Mode (Glass)               ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
show_status() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}Controller Status (Demo):${GLASS_RESET}"
  echo -e "  Joy-Con: Connected"
  echo -e "  Xbox Controller: Not Connected"
  echo -e "  PlayStation Controller: Not Connected"
  echo -e "  Low-Latency Mode: Enabled"
  echo ""
  read -p "Press Enter to return to dashboard..."
}
show_status 