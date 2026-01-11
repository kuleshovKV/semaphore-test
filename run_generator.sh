#!/bin/bash

# 🎰 Casino Sites Generator - One-Command Launch
# Usage: ./run_generator.sh [action]
# Actions: gen, deploy, check, logs

set -e

ROOT_DIR="/root"
cd "$ROOT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

case "${1:-gen}" in
    gen)
        log_info "🎰 Starting Casino Sites Generation..."
        log_info "Reading config files..."
        
        if [ ! -f "domains.csv" ]; then
            log_error "domains.csv not found"
            exit 1
        fi
        if [ ! -f "brands.csv" ]; then
            log_error "brands.csv not found"
            exit 1
        fi
        if [ ! -f "ref_links.conf" ]; then
            log_error "ref_links.conf not found"
            exit 1
        fi
        
        log_info "Domains: $(wc -l < domains.csv) entries"
        log_info "Brands: $(wc -l < brands.csv) entries"
        log_info "Ref links: $(wc -l < ref_links.conf) entries"
        
        log_info "Running playbook..."
        ansible-playbook \
            -i "localhost," \
            -c local \
            casino_sites_generator_v2_with_refs.yml
        
        log_success "Generation completed!"
        
        # Show stats
        SITE_COUNT=$(find output -maxdepth 1 -type d -not -name output | wc -l)
        HTML_COUNT=$(find output -name index.html | wc -l)
        SIZE=$(du -sh output | cut -f1)
        
        log_info "📊 Results:"
        log_info "   Sites: $SITE_COUNT"
        log_info "   Pages: $HTML_COUNT"
        log_info "   Size: $SIZE"
        ;;
        
    deploy)
        log_info "🚀 Deploying to production..."
        
        if [ ! -d "output" ]; then
            log_error "output/ directory not found. Run 'gen' first."
            exit 1
        fi
        
        log_info "Creating archive..."
        tar -czf /tmp/output_sites.tar.gz output/
        
        log_info "Deploying..."
        ansible-playbook semaphore_deploy.yml \
            -i "prod1.example.com," \
            -e "source_archive=/tmp/output_sites.tar.gz"
        
        log_success "Deployment completed!"
        ;;
        
    check)
        log_info "📊 Checking generated sites..."
        
        if [ ! -d "output" ]; then
            log_error "output/ directory not found"
            exit 1
        fi
        
        SITES=$(find output -maxdepth 1 -type d -not -name output)
        
        for site in $SITES; do
            SITE_NAME=$(basename "$site")
            INDEX="$site/index.html"
            ROBOTS="$site/robots.txt"
            SITEMAP="$site/sitemap.xml"
            
            if [ -f "$INDEX" ] && [ -f "$ROBOTS" ] && [ -f "$SITEMAP" ]; then
                log_success "$SITE_NAME"
            else
                log_warn "$SITE_NAME (missing files)"
            fi
        done
        ;;
        
    logs)
        log_info "📝 Generation logs..."
        if [ -d "logs" ]; then
            ls -lh logs/
        else
            log_warn "No logs directory found"
        fi
        ;;
        
    git)
        log_info "🔄 Git status..."
        git status
        ;;
        
    *)
        echo "Usage: $0 [action]"
        echo ""
        echo "Actions:"
        echo "  gen     - Generate casino sites (default)"
        echo "  deploy  - Deploy to production"
        echo "  check   - Check generated sites"
        echo "  logs    - Show generation logs"
        echo "  git     - Show git status"
        echo ""
        echo "Example:"
        echo "  $0 gen"
        echo "  $0 deploy"
        exit 1
        ;;
esac
