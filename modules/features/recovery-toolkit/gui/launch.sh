#!/bin/bash
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Recovery Toolkit (Glass)          ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}
main_menu() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}1.${GLASS_RESET} Emergency Recovery (demo)"
  echo -e "${GLASS_CYAN}2.${GLASS_RESET} System Repair (demo)"
  echo -e "${GLASS_CYAN}3.${GLASS_RESET} Diagnostic Mode (demo)"
  echo -e "${GLASS_CYAN}4.${GLASS_RESET} Safe Mode (demo)"
  echo -e "${GLASS_CYAN}0.${GLASS_RESET} Return to Dashboard"
  echo ""
  read -p "Select option [0-4]: " choice
  case $choice in
    1|2|3|4)
      echo -e "${GLASS_CYAN}Selected option (demo): $choice${GLASS_RESET}"
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