#!/bin/bash

# SEO Sites Deployment Script (IDEMPOTENT)
# Fixes circular creation by implementing state tracking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www"
CACHE_FILE="${WEB_ROOT}/.deployment_cache"
LOG_FILE="/var/log/seo_deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠️ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Check requirements
check_requirements() {
    log "Проверка зависимостей..."
    
    command -v ansible >/dev/null 2>&1 || error "ansible не установлен"
    command -v ansible-playbook >/dev/null 2>&1 || error "ansible-playbook не установлен"
    
    [ -f "$SCRIPT_DIR/domains.csv" ] || error "Файл domains.csv не найден"
    [ -f "$SCRIPT_DIR/brands.csv" ] || error "Файл brands.csv не найден"
    [ -f "$SCRIPT_DIR/ref_links.conf" ] || error "Файл ref_links.conf не найден"
    [ -f "$SCRIPT_DIR/playbook_seo_sites_fixed.yml" ] || error "Playbook не найден"
    
    success "Все зависимости доступны"
}

# Calculate hash of input files
calculate_hash() {
    local domains_hash=$(sha256sum "$SCRIPT_DIR/domains.csv" | cut -d' ' -f1)
    local brands_hash=$(sha256sum "$SCRIPT_DIR/brands.csv" | cut -d' ' -f1)
    local refs_hash=$(sha256sum "$SCRIPT_DIR/ref_links.conf" | cut -d' ' -f1)
    
    echo "${domains_hash:0:8}${brands_hash:0:8}${refs_hash:0:8}"
}

# Check if deployment is needed
check_deployment_needed() {
    local current_hash=$(calculate_hash)
    
    if [ -f "$CACHE_FILE" ]; then
        local cached_hash=$(grep "^HASH=" "$CACHE_FILE" 2>/dev/null | cut -d'=' -f2)
        
        if [ "$current_hash" == "$cached_hash" ]; then
            warn "Развёртывание не требуется (конфиги не изменились)"
            cat "$CACHE_FILE"
            return 1
        else
            log "Конфиги изменены, требуется переразвёртывание"
            return 0
        fi
    else
        log "Первое развёртывание, кэш не найден"
        return 0
    fi
}

# Backup existing cache
backup_cache() {
    if [ -f "$CACHE_FILE" ]; then
        cp "$CACHE_FILE" "${CACHE_FILE}.bak.$(date +%s)"
        success "Старый кэш сохранён"
    fi
}

# Run ansible playbook
run_playbook() {
    log "Запуск Ansible playbook..."
    log "Playbook: playbook_seo_sites_fixed.yml"
    log "Веб-корень: $WEB_ROOT"
    
    ansible-playbook \
        -i "localhost," \
        -c local \
        "$SCRIPT_DIR/playbook_seo_sites_fixed.yml" \
        -v 2>&1 | tee -a "$LOG_FILE"
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        success "Playbook выполнен успешно"
        return 0
    else
        error "Playbook завершился с ошибкой (код: $exit_code)"
    fi
}

# Verify deployment
verify_deployment() {
    log "Проверка развёртывания..."
    
    local domains_count=$(wc -l < "$SCRIPT_DIR/domains.csv")
    local brands_count=$(wc -l < "$SCRIPT_DIR/brands.csv")
    local expected_dirs=$((domains_count * brands_count))
    
    local actual_dirs=$(find "$WEB_ROOT" -maxdepth 2 -type d -name "casino*.ru" | wc -l)
    
    if [ "$actual_dirs" -ge "$expected_dirs" ]; then
        success "Проверка пройдена! Создано директорий: $actual_dirs из $expected_dirs"
        return 0
    else
        warn "Проверка не пройдена. Создано: $actual_dirs, ожидается: $expected_dirs"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     SEO Sites Deployment Script (IDEMPOTENT v2)            ║${NC}"
    echo -e "${BLUE}║     Fix for circular site creation                         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log "Инициализация развёртывания..."
    
    # Phase 1: Check
    check_requirements
    
    # Phase 2: Decide
    if ! check_deployment_needed; then
        log "Скипуем развёртывание (ничего не изменилось)"
        exit 0
    fi
    
    # Phase 3: Backup
    backup_cache
    
    # Phase 4: Deploy
    run_playbook
    
    # Phase 5: Verify
    verify_deployment
    
    # Done
    echo
    success "═══════════════════════════════════════════════════════"
    success "Развёртывание завершено успешно!"
    success "═══════════════════════════════════════════════════════"
    
    log "Подробный лог: $LOG_FILE"
    log "Кэш файл: $CACHE_FILE"
}

# Run main function
main "$@"
