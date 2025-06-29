#!/bin/bash
# Glass UI - Quantum Secure Vault
GLASS_CYAN='\033[1;36m'
GLASS_DARK='\033[1;30m'
GLASS_RESET='\033[0m'
VAULT_SH="$(dirname "$0")/../vault.sh"

print_header() {
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_CYAN}      Quantum Secure Vault (Glass)      ${GLASS_RESET}"
  echo -e "${GLASS_CYAN}========================================${GLASS_RESET}"
  echo -e "${GLASS_DARK}         [Dark Glass Theme Enabled]      ${GLASS_RESET}"
}

main_menu() {
  print_header
  echo ""
  echo -e "${GLASS_CYAN}1.${GLASS_RESET} Store Secret"
  echo -e "${GLASS_CYAN}2.${GLASS_RESET} Retrieve Secret"
  echo -e "${GLASS_CYAN}3.${GLASS_RESET} List Secrets"
  echo -e "${GLASS_CYAN}0.${GLASS_RESET} Return to Dashboard"
  echo ""
  read -p "Enter choice [0-3]: " choice
  case $choice in
    1)
      read -p "Secret name: " name
      read -s -p "Secret value: " value; echo
      bash "$VAULT_SH" store "$name" "$value"
      read -p "Press Enter to continue...";;
    2)
      read -p "Secret name: " name
      bash "$VAULT_SH" get "$name"
      read -p "Press Enter to continue...";;
    3)
      bash "$VAULT_SH" list
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