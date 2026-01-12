#!/bin/bash

################################################################################
# 🎰 FAST GIT PUSH - Casino Deployment Project
# One-click push to GitHub/GitLab
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🎰 FAST GIT PUSH - CASINO DEPLOYMENT 🎰           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# STEP 1: CHECK IF GIT INITIALIZED
# ============================================================================

if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Git not initialized. Initializing now...${NC}"
    git init
    echo -e "${GREEN}✅ Git initialized${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Git repository found${NC}"
    echo ""
fi

# ============================================================================
# STEP 2: CHECK REMOTE
# ============================================================================

remote=$(git remote get-url origin 2>/dev/null)

if [ -z "$remote" ]; then
    echo -e "${YELLOW}ℹ️  No remote repository configured${NC}"
    echo ""
    echo "Enter your repository URL:"
    echo "Example: https://github.com/YOUR_USERNAME/casino-deployment.git"
    read -p "Repository URL: " repo_url
    
    if [ -z "$repo_url" ]; then
        echo -e "${RED}❌ No URL provided${NC}"
        exit 1
    fi
    
    git remote add origin "$repo_url"
    echo -e "${GREEN}✅ Remote added: $repo_url${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Remote found: $remote${NC}"
    echo ""
fi

# ============================================================================
# STEP 3: CHECK FILES
# ============================================================================

echo "Files to be pushed:"
echo ""

files=(
    "casino-deployment-full.yml"
    "QUICK_START.sh"
    "auto-update-regru-ns.sh"
    "HOW_TO_RUN_PLAYBOOK.md"
    "SEMAPHORE_SETUP_GUIDE.md"
    "GIT_PUSH_INSTRUCTIONS.md"
    "README.md"
    "PUSH_TO_GIT.sh"
    ".gitignore"
)

missing=0
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file (MISSING)${NC}"
        missing=$((missing+1))
    fi
done

echo ""

if [ $missing -gt 0 ]; then
    echo -e "${RED}❌ $missing files missing!${NC}"
    exit 1
fi

# ============================================================================
# STEP 4: GIT ADD & COMMIT
# ============================================================================

echo -e "${BLUE}Adding files to git...${NC}"
git add -A

echo ""
echo "Files to be committed:"
git diff --cached --name-only | sed 's/^/  ✅ /'
echo ""

read -p "Commit message (or Enter for default): " commit_msg

if [ -z "$commit_msg" ]; then
    commit_msg="🎰 Casino Deployment - Ansible playbook and scripts"
fi

echo ""
echo -e "${BLUE}Committing...${NC}"
git commit -m "$commit_msg"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Commit failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Files committed${NC}"
echo ""

# ============================================================================
# STEP 5: GIT PUSH
# ============================================================================

branch=$(git rev-parse --abbrev-ref HEAD)

echo -e "${BLUE}Pushing to remote...${NC}"
echo "Branch: $branch"
echo ""

git push -u origin "$branch"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ PUSH SUCCESSFUL!${NC}"
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 ✅ SUCCESS! ✅                          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Repository: $remote"
    echo "Branch: $branch"
    echo ""
    echo "Your files are now on GitHub/GitLab!"
    echo ""
    echo "Share this URL with your team:"
    echo -e "${YELLOW}  $remote${NC}"
    echo ""
    echo "They can clone with:"
    echo -e "${YELLOW}  git clone $remote${NC}"
    echo ""
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi
