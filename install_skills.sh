#!/usr/bin/env bash

# ==============================================================================
# 🤖 Gagent-Skills Installation Script
# This script automates deploying custom agent skills locally or globally.
#
# Skills are installed using the vendor-neutral `.agents/` convention, which is
# discovered by modern agentic coding tools (OpenCode, Claude Code-compatible
# loaders, Antigravity, etc.):
#   - Local  (workspace):   ./.agents/skills/<name>/SKILL.md
#   - Global (user home):   ~/.agents/skills/<name>/SKILL.md
# ==============================================================================

set -euo pipefail

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Resolve script location (so it can be run from anywhere) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo "  --local           Install skills to the current directory (./.agents/)"
    echo "  --global          Install skills to your home (~/.agents/)"
    echo "  --help, -h        Display this help menu"
    echo ""
    echo "If no options are supplied, the installer will run interactively."
    exit 1
}

# --- Variables ---
INSTALL_MODE=""
WORKSPACE_DIR="$(pwd)"
SOURCE_SKILLS_DIR="$SCRIPT_DIR/skills"
SOURCE_AGENTS_FILE="$SCRIPT_DIR/AGENTS.md"

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
    echo -e "  ${GREEN}2)${NC} Global Scope (Installs to ~/.agents/)"
    echo -ne "\nEnter selection [1-2]: "
    read -r choice

    case "$choice" in
        1) INSTALL_MODE="local" ;;
        2) INSTALL_MODE="global" ;;
        *) echo -e "${RED}Invalid selection. Exiting.${NC}"; exit 1 ;;
    esac
fi

# --- Resolve target base directory from install mode ---
if [[ "$INSTALL_MODE" == "local" ]]; then
    TARGET_AGENTS_DIR="$WORKSPACE_DIR/.agents"
    echo -e "\n${BLUE}⏳ Running Local Workspace Scope Installation...${NC}"
else
    TARGET_AGENTS_DIR="$HOME/.agents"
    echo -e "\n${BLUE}⏳ Running Global User Scope Installation...${NC}"
fi

TARGET_SKILLS_DIR="$TARGET_AGENTS_DIR/skills"

# --- Verify source directory exists ---
if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
    echo -e "${RED}Error: Source skills directory '$SOURCE_SKILLS_DIR' not found!${NC}"
    exit 1
fi

# --- Create target directories ---
mkdir -p "$TARGET_SKILLS_DIR"

# --- Back up any existing skills before overwriting (idempotent safety) ---
if [[ -n "$(ls -A "$TARGET_SKILLS_DIR" 2>/dev/null)" ]]; then
    BACKUP_DIR="$TARGET_SKILLS_DIR.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}⚠️  Existing skills detected. Backing up to $BACKUP_DIR...${NC}"
    cp -r "$TARGET_SKILLS_DIR" "$BACKUP_DIR"
fi

# --- Copy skills ---
echo -e "Copying skills..."
cp -r "$SOURCE_SKILLS_DIR/"* "$TARGET_SKILLS_DIR/"

# --- Copy AGENTS.md routing directives (both scopes) ---
if [[ -f "$SOURCE_AGENTS_FILE" ]]; then
    if [[ -f "$TARGET_AGENTS_DIR/AGENTS.md" ]]; then
        echo -e "${YELLOW}⚠️  Existing AGENTS.md detected. Backing up to AGENTS.md.bak...${NC}"
        mv "$TARGET_AGENTS_DIR/AGENTS.md" "$TARGET_AGENTS_DIR/AGENTS.md.bak"
    fi
    cp "$SOURCE_AGENTS_FILE" "$TARGET_AGENTS_DIR/"
fi

echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "Placed customization skills inside: ${BLUE}$TARGET_SKILLS_DIR${NC}"
if [[ "$INSTALL_MODE" == "local" ]]; then
    echo -e "Any AI agent running in this directory will now automatically load these skills."
else
    echo -e "Your coding assistant will now load these skills across all of your local workspaces."
fi

echo -e "\n${GREEN}🎉 Done! Have a wonderful hacking session! 🚀${NC}\n"
