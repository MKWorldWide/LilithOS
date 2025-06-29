#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      LilithAI Assistant (Glass)        ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
main_menu() {
  print_header
  echo ""
  read -p "Ask LilithAI (demo): " query
  echo -e "${GLASS_CYAN}LilithAI:${GLASS_RESET} (demo) You asked: '$query'"
  echo -e "${GLASS_CYAN}Response:${GLASS_RESET} (demo) This is a simulated AI response."
  read -p "Press Enter to return to dashboard..."
}
main_menu 