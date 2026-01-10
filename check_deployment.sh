#!/bin/bash

# Deployment Health Check Script
set -e

WEB_ROOT="/var/www"
CACHE_FILE="${WEB_ROOT}/.deployment_cache"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAINS_COUNT=0
BRANDS_COUNT=0
MISSING_FILES=0
ORPHAN_DIRS=0

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          SEO DEPLOYMENT HEALTH CHECK                      ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# 1. Check cache
echo -e "${BLUE}[CHECK 1/8]${NC} Проверка кэша развёртывания..."
if [ -f "$CACHE_FILE" ]; then
    echo -e "${GREEN}✓${NC} Файл кэша найден: $CACHE_FILE"
    echo
    cat "$CACHE_FILE" | sed 's/^/  /'
    echo
    CACHE_DOMAINS=$(grep "^DOMAINS=" "$CACHE_FILE" | cut -d'=' -f2)
    CACHE_BRANDS=$(grep "^BRANDS=" "$CACHE_FILE" | cut -d'=' -f2)
    CACHE_HASH=$(grep "^HASH=" "$CACHE_FILE" | cut -d'=' -f2)
    EXPECTED_SITES=$(grep "^TOTAL_SITES=" "$CACHE_FILE" | cut -d'=' -f2)
else
    echo -e "${YELLOW}⚠️ ${NC} Кэш не найден"
    CACHE_DOMAINS=0
    CACHE_BRANDS=0
fi

echo

# 2. Check web root
echo -e "${BLUE}[CHECK 2/8]${NC} Проверка корневой директории..."
if [ -d "$WEB_ROOT" ]; then
    echo -e "${GREEN}✓${NC} Директория $WEB_ROOT существует"
    SIZE=$(du -sh "$WEB_ROOT" 2>/dev/null | cut -f1)
    echo "  Размер: $SIZE"
else
    echo -e "${RED}✗${NC} Директория $WEB_ROOT НЕ существует"
fi

echo

# 3. Count
echo -e "${BLUE}[CHECK 3/8]${NC} Подсчёт доменов и брендов..."
DOMAINS_COUNT=$(find "$WEB_ROOT" -maxdepth 1 -type d -name "casino*.ru" 2>/dev/null | wc -l)
echo "  Найдено доменов: $DOMAINS_COUNT"

echo

# 4. Files
echo -e "${BLUE}[CHECK 4/8]${NC} Проверка целостности файлов..."
ACTUAL_FILES=$(find "$WEB_ROOT" -maxdepth 4 -name "index.html" 2>/dev/null | wc -l)
echo "  Найдено index.html: $ACTUAL_FILES"

echo

# 5. Orphans
echo -e "${BLUE}[CHECK 5/8]${NC} Проверка orphan директорий..."
ORPHANS=$(find "$WEB_ROOT" -maxdepth 3 -type d -name "casino*.ru" ! -exec test -f "{}/index.html" \; -print 2>/dev/null | wc -l)
if [ "$ORPHANS" -gt 0 ]; then
    ORPHAN_DIRS=$ORPHANS
    echo -e "  ${YELLOW}⚠️ ${NC} Найдено orphan директорий: $ORPHAN_DIRS"
else
    echo -e "  ${GREEN}✓${NC} Orphan директорий не найдено"
fi

echo

# 6. Permissions
echo -e "${BLUE}[CHECK 6/8]${NC} Проверка прав доступа..."
WRONG_PERMS=$(find "$WEB_ROOT" -type d ! -perm 755 2>/dev/null | wc -l)
if [ "$WRONG_PERMS" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} Все директории имеют правильные права (755)"
else
    echo -e "  ${YELLOW}⚠️ ${NC} Директорий с неправильными правами: $WRONG_PERMS"
fi

echo

# 7. Disk
echo -e "${BLUE}[CHECK 7/8]${NC} Проверка использования диска..."
PERCENT=$(df "$WEB_ROOT" | tail -1 | awk '{print $5}')
PERCENT_NUM=${PERCENT%\%}
echo "  Процент: $PERCENT"

if [ "$PERCENT_NUM" -lt 80 ]; then
    echo -e "  ${GREEN}✓${NC} Место достаточно"
else
    echo -e "  ${RED}✗${NC} Заканчивается место!"
fi

echo

# 8. Summary
echo -e "${BLUE}[CHECK 8/8]${NC} Формирование отчёта..."
echo

HEALTH_SCORE=100
[ "$MISSING_FILES" -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 20))
[ "$ORPHAN_DIRS" -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 15))
[ "$WRONG_PERMS" -gt 0 ] && HEALTH_SCORE=$((HEALTH_SCORE - 10))
[ "$PERCENT_NUM" -gt 80 ] && HEALTH_SCORE=$((HEALTH_SCORE - 25))

if [ "$HEALTH_SCORE" -ge 90 ]; then
    STATUS_COLOR=$GREEN
    STATUS="✅ HEALTHY"
elif [ "$HEALTH_SCORE" -ge 70 ]; then
    STATUS_COLOR=$YELLOW
    STATUS="⚠️ WARNING"
else
    STATUS_COLOR=$RED
    STATUS="❌ CRITICAL"
fi

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    ИТОГОВЫЙ ОТЧЁТ                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "Статус здоровья:     ${STATUS_COLOR}${STATUS}${NC}"
echo -e "Оценка здоровья:     ${STATUS_COLOR}${HEALTH_SCORE}/100${NC}"
echo

if [ -f "$CACHE_FILE" ]; then
    DEPLOY_TIME=$(grep "^DEPLOYMENT_TIME=" "$CACHE_FILE" | cut -d'=' -f2)
    echo "  Последнее обновление: $DEPLOY_TIME"
fi

echo
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
