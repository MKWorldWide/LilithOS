#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Celestial Monitor (Glass)         ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
show_stats() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}System Stats (Demo):${GLASS_RESET}"
  echo -e "  CPU Usage: 12%"
  echo -e "  RAM Usage: 3.2 GB / 8 GB"
  echo -e "  Disk Usage: 45%"
  echo -e "  Network: 120 Mbps"
  echo -e "  Temperature: 48°C"
  echo ""
  read -p "Press Enter to return to dashboard..."
}
show_stats 