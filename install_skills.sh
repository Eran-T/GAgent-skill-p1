#!/usr/bin/env bash

# ==============================================================================
# 🤖 Gagent-Skills Installation Script
# This script automates deploying custom agent skills locally or globally.
# ==============================================================================

set -euo pipefail

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Brand Header ---
echo -e "${BLUE}"
echo "    ╔═══════════════════════════════════════════════════════════╗"
echo "    ║                                                           ║"
echo "    ║   🧭   GAGENT-SKILLS CUSTOMIZATION INSTALLER   🧭         ║"
echo "    ║                                                           ║"
echo "    ╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# --- Help Usage ---
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --local           Install skills to the current directory (workspace-scoped)"
    echo "  --global          Install skills to ~/.gemini/config/skills (global-scoped)"
    echo "  --help, -h        Display this help menu"
    echo ""
    echo "If no options are supplied, the installer will run interactively."
    exit 1
}

# --- Variables ---
INSTALL_MODE=""
WORKSPACE_DIR="$(pwd)"
GLOBAL_DIR="$HOME/.gemini/config"
SOURCE_SKILLS_DIR="./skills"
SOURCE_AGENTS_FILE="./AGENTS.md"

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local)
            INSTALL_MODE="local"
            shift
            ;;
        --global)
            INSTALL_MODE="global"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# --- Interactive Prompts ---
if [[ -z "$INSTALL_MODE" ]]; then
    echo -e "Where would you like to install the customization skills?"
    echo -e "  ${GREEN}1)${NC} Local Workspace (Installs .agents/ to the current folder)"
    echo -e "  ${GREEN}2)${NC} Global Scope (Installs to ~/.gemini/config/skills/)"
    echo -ne "\nEnter selection [1-2]: "
    read -r choice

    case "$choice" in
        1) INSTALL_MODE="local" ;;
        2) INSTALL_MODE="global" ;;
        *) echo -e "${RED}Invalid selection. Exiting.${NC}"; exit 1 ;;
    esac
fi

# --- Executing Local Workspace Installation ---
if [[ "$INSTALL_MODE" == "local" ]]; then
    echo -e "\n${BLUE}⏳ Running Local Workspace Scope Installation...${NC}"
    
    TARGET_AGENTS_DIR="$WORKSPACE_DIR/.agents"
    TARGET_SKILLS_DIR="$TARGET_AGENTS_DIR/skills"

    # Verify source directory exists
    if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
        echo -e "${RED}Error: Source skills directory '$SOURCE_SKILLS_DIR' not found! Run from the package directory.${NC}"
        exit 1
    fi

    # Create target directories
    mkdir -p "$TARGET_SKILLS_DIR"

    # Backup existing if they exist
    if [[ -f "$TARGET_AGENTS_DIR/AGENTS.md" ]]; then
        echo -e "${YELLOW}⚠️  Existing local AGENTS.md detected. Backing up to AGENTS.md.bak...${NC}"
        mv "$TARGET_AGENTS_DIR/AGENTS.md" "$TARGET_AGENTS_DIR/AGENTS.md.bak"
    fi

    # Copy files
    echo -e "Copying workspace directives and skills..."
    cp -r "$SOURCE_SKILLS_DIR/"* "$TARGET_SKILLS_DIR/"
    if [[ -f "$SOURCE_AGENTS_FILE" ]]; then
        cp "$SOURCE_AGENTS_FILE" "$TARGET_AGENTS_DIR/"
    fi

    echo -e "${GREEN}✅ Local installation complete!${NC}"
    echo -e "Placed customization skills inside: ${BLUE}$TARGET_AGENTS_DIR${NC}"
    echo -e "Any AI agent running in this directory will now automatically load these skills."

# --- Executing Global Scope Installation ---
elif [[ "$INSTALL_MODE" == "global" ]]; then
    echo -e "\n${BLUE}⏳ Running Global User Scope Installation...${NC}"
    
    TARGET_GLOBAL_SKILLS_DIR="$GLOBAL_DIR/skills"

    # Verify source directory exists
    if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
        echo -e "${RED}Error: Source skills directory '$SOURCE_SKILLS_DIR' not found! Run from the package directory.${NC}"
        exit 1
    fi

    # Create target directories
    mkdir -p "$TARGET_GLOBAL_SKILLS_DIR"

    # Copy files
    echo -e "Copying skills to global config..."
    cp -r "$SOURCE_SKILLS_DIR/"* "$TARGET_GLOBAL_SKILLS_DIR/"

    echo -e "${GREEN}✅ Global installation complete!${NC}"
    echo -e "Placed global skills inside: ${BLUE}$TARGET_GLOBAL_SKILLS_DIR${NC}"
    echo -e "Your coding assistant will now load these skills across all of your local workspaces."
fi

echo -e "\n${GREEN}🎉 Done! Have a wonderful hacking session! 🚀${NC}\n"
