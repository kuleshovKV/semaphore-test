#!/bin/bash

# 🎰 AUTO-UPDATE NAMESERVERS IN REG.RU

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="https://api.reg.ru/api/regru2/domain/"
DELAY=0.5

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

usage() {
    echo "Usage: $0 <login> <password> <nameservers_csv_file>"
    echo "Example: $0 mylogin mypassword NAMESERVERS_BULK_target1.csv"
    exit 1
}

if [ $# -lt 3 ]; then
    usage
fi

LOGIN=$1
PASSWORD=$2
CSV_FILE=$3

if [ ! -f "$CSV_FILE" ]; then
    print_error "CSV file not found: $CSV_FILE"
    exit 1
fi

print_success "Login: $LOGIN"
print_success "CSV File: $CSV_FILE"
echo ""

total=0
success=0

tail -n +2 "$CSV_FILE" | while IFS=',' read -r domain ns1 ns2; do
    domain=$(echo "$domain" | xargs)
    ns1=$(echo "$ns1" | xargs)
    ns2=$(echo "$ns2" | xargs)
    
    if [ -z "$domain" ]; then
        continue
    fi
    
    ((total++))
    
    print_info "Updating $domain..."
    
    response=$(curl -s -X POST "$API_URL/nop.json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$LOGIN" \
        -d "password=$PASSWORD" \
        -d "domain=$domain" \
        -d "ns0=$ns1" \
        -d "ns1=$ns2" \
        -d "input_format=json" \
        -d "output_format=json" \
        2>/dev/null)
    
    if echo "$response" | grep -q '"status":"success"'; then
        print_success "Updated $domain"
        ((success++))
    else
        print_error "Failed to update $domain"
    fi
    
    sleep "$DELAY"
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Summary: Total=$total Success=$success"
echo "═══════════════════════════════════════════════════════════"
