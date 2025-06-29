#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Modular App Store (Glass)         ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
main_menu() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}Available Modules:${GLASS_RESET}"
  echo -e "  1. Quantum Secure Vault"
  echo -e "  2. Celestial Monitor"
  echo -e "  3. LilithAI"
  echo -e "  4. Gaming Mode"
  echo -e "  0. Return to Dashboard"
  echo ""
  read -p "Enter module number to install (demo) or 0 to return: " choice
  case $choice in
    1|2|3|4)
      echo -e "${GLASS_CYAN}Installing module... (demo)${GLASS_RESET}"
      sleep 1
      echo -e "${GLASS_CYAN}Module installed!${GLASS_RESET}"
      read -p "Press Enter to continue...";;
    0)
      return 0;;
    *)
      echo -e "${GLASS_DARK}Invalid choice. Try again.${GLASS_RESET}"
      read -p "Press Enter to continue...";;
  esac
  main_menu
}
main_menu 