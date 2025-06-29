#!/bin/bash
# Quantum Secure Vault CLI
# ------------------------
# 📋 Quantum Documentation:
#   Command-line interface for managing the Quantum Secure Vault.
#   Supports storing, retrieving, listing, and deleting secrets.
#
# 🧩 Feature Context:
#   - Used by users and system scripts to securely manage secrets.
#   - Integrates with the secure-vault module loader.
#
# 🧷 Dependency Listings:
#   - openssl, bash
#
# 💡 Usage Examples:
#   ./vault.sh store mysecret "superpassword"
#   ./vault.sh get mysecret
#   ./vault.sh list
#   ./vault.sh delete mysecret
#
# ⚡ Performance Considerations:
#   - Fast for small secrets, slower for large files.
#
# 🔒 Security Implications:
#   - Secrets are encrypted with AES-256.
#   - Access is logged.
#
# 📜 Changelog Entries:
#   - 2024-06-29: Initial CLI created.

VAULT_DIR="${QUANTUM_VAULT_DIR:-$PWD/store}"
VAULT_LOG="$VAULT_DIR/vault.log"

mkdir -p "$VAULT_DIR"

log_access() {
    echo "[$(date)] $1" >> "$VAULT_LOG"
}

store_secret() {
    local name="$1"
    local value="$2"
    local file="$VAULT_DIR/$name.enc"
    echo -n "$value" | openssl enc -aes-256-cbc -salt -out "$file" -pass pass:$(whoami)
    log_access "STORE $name by $(whoami)"
    echo "Secret stored: $name"
}

get_secret() {
    local name="$1"
    local file="$VAULT_DIR/$name.enc"
    if [ ! -f "$file" ]; then
        echo "Secret not found: $name"; return 1;
    fi
    openssl enc -d -aes-256-cbc -in "$file" -pass pass:$(whoami)
    log_access "GET $name by $(whoami)"
}

list_secrets() {
    ls "$VAULT_DIR" | grep ".enc$" | sed 's/\.enc$//'
    log_access "LIST by $(whoami)"
}

delete_secret() {
    local name="$1"
    local file="$VAULT_DIR/$name.enc"
    rm -f "$file"
    log_access "DELETE $name by $(whoami)"
    echo "Secret deleted: $name"
}

case "$1" in
    store)
        store_secret "$2" "$3";;
    get)
        get_secret "$2";;
    list)
        list_secrets;;
    delete)
        delete_secret "$2";;
    *)
        echo "Usage: $0 {store|get|list|delete} [name] [value]";;
esac 