#!/bin/bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored header
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   Valyu MCP Setup Assistant    ${NC}"
echo -e "${BLUE}================================${NC}\n"

# Detect OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    OS="Windows"
    VENV_ACTIVATE=".venv\\Scripts\\activate"
    CONFIG_PATH="%APPDATA%\\Claude\\claude_desktop_config.json"
else
    OS="Unix"
    VENV_ACTIVATE=".venv/bin"
    CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
fi

echo -e "${YELLOW}Detected OS: $OS${NC}\n"

# Create and activate virtual environment
echo -e "${BLUE}Creating virtual environment...${NC}"
python -m venv .venv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create virtual environment. Please ensure Python is installed.${NC}"
    exit 1
fi

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
if [[ "$OS" == "Windows" ]]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi

# Install dependencies
echo -e "\n${BLUE}Installing dependencies...${NC}"
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies. Please check requirements.txt${NC}"
    exit 1
fi

# Get API key from user
echo -e "\n${YELLOW}Please enter your Valyu API key:${NC}"
read -p "> " VALYU_API_KEY

# Create .env file
echo -e "\n${BLUE}Creating .env file...${NC}"
echo "VALYU_API_KEY=$VALYU_API_KEY" > .env

# Get absolute path of current directory
CURRENT_DIR=$(pwd)

# Instructions for Claude config
echo -e "\n${GREEN}Setup complete! 🎉${NC}"
echo -e "\n${YELLOW}Final steps:${NC}"
echo -e "1. Open your Claude Desktop config file at:"
echo -e "   ${BLUE}$CONFIG_PATH${NC}"
echo -e "\n   If the config file doesn't exist, please:"
echo -e "   1. Open Claude Desktop"
echo -e "   2. Go to Settings"
echo -e "   3. Enable Developer Mode in the Developer tab"
echo -e "   4. The config file will be generated automatically"
echo -e "\n2. Add the following to your config file under 'mcpServers':"
echo -e "${BLUE}"
cat << EOF
{
  "mcpServers": {
    "valyu-mcp": {
      "command": "$CURRENT_DIR/$VENV_ACTIVATE/python",
      "args": ["-u", "$CURRENT_DIR/valyu-mcp.py"],
      "env": {
        "VALYU_API_KEY": "$VALYU_API_KEY"
      }
    }
  }
}
EOF
echo -e "${NC}"

echo -e "\n${GREEN}Once completed, you're all set! The Valyu MCP server is ready to use. Restart Claude Desktop to use the new tool.${NC}" 