#!/bin/bash

# 🔍 Configuration Checker for Casino Sites Generator

echo "╔════════════════════════════════════════════════════════╗"
echo "║  🔍 CASINO SITES GENERATOR - CONFIG CHECK             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_file() {
    if [ -f "$1" ]; then
        SIZE=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null)
        echo -e "${GREEN}✅${NC} $1 ($(numfmt --to=iec-i --suffix=B $SIZE 2>/dev/null || echo $SIZE bytes))"
        return 0
    else
        echo -e "${RED}❌${NC} $1 (NOT FOUND)"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $1/ (exists)"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} $1/ (will be created)"
        return 1
    fi
}

echo "📋 Configuration Files:"
check_file "domains.csv"
check_file "brands.csv"
check_file "ref_links.conf"

echo ""
echo "🎯 Playbooks:"
check_file "casino_sites_generator_v2_with_refs.yml"
check_file "semaphore_deploy.yml"

echo ""
echo "🔧 Scripts:"
check_file "index.html.tpl_FULL.sh"
check_file "batch_generator.py"

echo ""
echo "📁 Directories:"
check_dir "templates"
check_dir "output"
check_dir "logs"

echo ""
echo "🔗 Git Configuration:"
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${GREEN}✅${NC} Git repository initialized"
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${GREEN}   Current branch: $BRANCH${NC}"
else
    echo -e "${YELLOW}⚠️${NC} Git repository not initialized"
    echo "   Run: git init && git config user.email 'admin@local' && git config user.name 'Bot'"
fi

echo ""
echo "📊 File Contents:"

if [ -f "domains.csv" ]; then
    echo "Domains ($(wc -l < domains.csv) entries):"
    sed 's/^/   /' domains.csv
fi

if [ -f "brands.csv" ]; then
    echo ""
    echo "Brands ($(wc -l < brands.csv) entries):"
    sed 's/^/   /' brands.csv
fi

if [ -f "ref_links.conf" ]; then
    echo ""
    echo "Ref Links ($(wc -l < ref_links.conf) entries):"
    sed 's/^/   /' ref_links.conf
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ All checks completed                              ║"
echo "╚════════════════════════════════════════════════════════╝"
