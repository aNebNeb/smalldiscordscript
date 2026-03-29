#!/bin/bash

APP_DIR="$HOME/.local/share/discordo"
TOKEN_FILE="$APP_DIR/token.txt"
DISCORDO_BIN="$APP_DIR/discordo"
DISCORDO_ZIP="$APP_DIR/discordo.zip"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}    Discordo Launcher${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

mkdir -p "$APP_DIR"

if [[ -f "$DISCORDO_BIN" ]]; then
    echo -e "${GREEN}✓ discordo already installed${NC}"
else
    echo -e "${YELLOW}Downloading discordo...${NC}"
    curl -# -L -o "$DISCORDO_ZIP" "https://nightly.link/ayn2op/discordo/workflows/ci/main/discordo_macOS_ARM64.zip"
    cd "$APP_DIR"
    unzip -q "$DISCORDO_ZIP"
    rm -f "$DISCORDO_ZIP"
    chmod +x "$DISCORDO_BIN"
    echo -e "${GREEN}✓ discordo installed${NC}"
fi
echo ""

test_token() {
    local token="$1"
    local response
    response=$(curl -s -X GET https://discord.com/api/v9/users/@me \
        -H "Authorization: $token")
    
    if echo "$response" | grep -q '"id"'; then
        return 0
    else
        return 1
    fi
}

if [[ -f "$TOKEN_FILE" ]]; then
    token=$(cat "$TOKEN_FILE")
    if test_token "$token"; then
        echo -e "${GREEN}✓ Logging in...${NC}"
        cd "$APP_DIR"
        DISCORDO_TOKEN="$token" ./discordo
        exit 0
    else
        echo -e "${YELLOW}⚠ Token expired, please log in${NC}"
        rm -f "$TOKEN_FILE"
    fi
fi

echo -e "${YELLOW}First time setup - log in to Discord:${NC}"
echo ""
read -p "Email: " email
read -s -p "Password: " password
echo ""
read -p "2FA code (press Enter if none)(not tested with 2fa): " mfa
echo ""

echo -e "${YELLOW}Authenticating...${NC}"
if [[ -n "$mfa" ]]; then
    response=$(curl -s -X POST https://discord.com/api/v9/auth/login \
        -H "content-type: application/json" \
        -d "{\"login\":\"$email\",\"password\":\"$password\",\"code\":\"$mfa\"}")
else
    response=$(curl -s -X POST https://discord.com/api/v9/auth/login \
        -H "content-type: application/json" \
        -d "{\"login\":\"$email\",\"password\":\"$password\"}")
fi

token=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$token" ]] || [[ "$token" == "null" ]]; then
    echo -e "${RED}Login failed${NC}"
    echo "$response"
    exit 1
fi

echo "$token" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
echo -e "${GREEN}✓ Login successful!${NC}"
echo ""

echo -e "${GREEN}Launching discordo...${NC}"
cd "$APP_DIR"
DISCORDO_TOKEN="$token" ./discordo