#!/bin/bash

################################################################################
# 🎰 CASINO DEPLOYMENT QUICK START SCRIPT
# Interactive startup for Ansible playbook
# Version: 1.0
# Date: 2026-01-12
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🎰 CASINO DEPLOYMENT QUICK START 🎰               ║${NC}"
    echo -e "${BLUE}║     Ansible Automation for Cloudflare Integration     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_requirements() {
    print_header
    echo "PHASE 1: Checking Requirements..."
    echo ""
    
    if command -v ansible &> /dev/null; then
        ansible_version=$(ansible --version | head -n 1)
        print_success "Ansible found: $ansible_version"
    else
        print_error "Ansible is not installed!"
        exit 1
    fi
    
    if [ -f "inventory.ini" ]; then
        print_success "inventory.ini found"
    else
        print_error "inventory.ini not found!"
        exit 1
    fi
    
    if [ -f "casino-deployment-full.yml" ]; then
        print_success "Playbook found"
    else
        print_error "Playbook not found!"
        exit 1
    fi
    
    echo ""
}

check_credentials() {
    print_header
    echo "PHASE 2: Checking Cloudflare Credentials..."
    echo ""
    
    cf_email=$(grep "cf_email=" inventory.ini | cut -d'=' -f2 | xargs)
    cf_api_key=$(grep "cf_api_key=" inventory.ini | cut -d'=' -f2 | xargs)
    
    if [ "$cf_email" = "your_email@cloudflare.com" ] || [ -z "$cf_email" ]; then
        print_error "Cloudflare email not configured!"
        exit 1
    fi
    
    if [ "$cf_api_key" = "your_global_api_key_here" ] || [ -z "$cf_api_key" ]; then
        print_error "Cloudflare API Key not configured!"
        exit 1
    fi
    
    print_success "Cloudflare email: $cf_email"
    print_success "Cloudflare API Key configured"
    
    echo ""
    print_info "Testing Cloudflare API connection..."
    
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user" \
        -H "X-Auth-Email: $cf_email" \
        -H "X-Auth-Key: $cf_api_key" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"success":true'; then
        print_success "Cloudflare API connection successful!"
    else
        print_error "Cloudflare API connection failed!"
        exit 1
    fi
    
    echo ""
}

check_ssh() {
    print_header
    echo "PHASE 3: Checking SSH Connection..."
    echo ""
    
    hosts=$(grep "ansible_host=" inventory.ini | grep -v "^\[" | grep -v "^#")
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        host_ip=$(echo "$line" | grep -o "ansible_host=[^ ]*" | cut -d'=' -f2)
        host_user=$(echo "$line" | grep -o "ansible_user=[^ ]*" | cut -d'=' -f2)
        
        if [ -z "$host_user" ]; then
            host_user="root"
        fi
        
        print_info "Testing SSH to $host_user@$host_ip..."
        
        if ssh -o ConnectTimeout=5 "$host_user@$host_ip" "echo OK" &> /dev/null; then
            print_success "SSH connection successful"
        else
            print_error "SSH connection failed to $host_user@$host_ip!"
            exit 1
        fi
    done <<< "$hosts"
    
    echo ""
}

show_menu() {
    print_header
    echo "PHASE 4: Select Deployment Mode..."
    echo ""
    echo "  1) DRY RUN (check mode)"
    echo "  2) TEST RUN (first server only)"
    echo "  3) FULL DEPLOYMENT (all servers)"
    echo "  4) CANCEL"
    echo ""
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1) ansible-playbook -i inventory.ini casino-deployment-full.yml --check -v ;;
        2) 
            first_host=$(grep "^[a-z]" inventory.ini | head -n 1 | cut -d' ' -f1)
            ansible-playbook -i inventory.ini casino-deployment-full.yml -l "$first_host" -v
            ;;
        3) ansible-playbook -i inventory.ini casino-deployment-full.yml -v ;;
        4) exit 0 ;;
        *) show_menu ;;
    esac
}

main() {
    check_requirements
    check_credentials
    check_ssh
    show_menu
}

main
