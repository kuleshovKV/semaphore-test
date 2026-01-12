#!/bin/bash
set -e

GEN_DIR="/var/www/casino_generator"   # сюда git клонирует репозиторий
WORK_ROOT="/var/www"                  # корень доменов

DOMAINS_FILE="$GEN_DIR/domains.csv"
SUBDOMAINS_FILE="$GEN_DIR/subdomains.csv"
REFS_FILE="$GEN_DIR/ref_links.conf"
TEMPLATE="$GEN_DIR/templates/index.html.tpl"

declare -A REFS

while IFS='=' read -r key value; do
  [[ -z "$key" ]] && continue
  [[ "$key" =~ ^# ]] && continue
  REFS["$key"]="$value"
done < "$REFS_FILE"

DEFAULT_REF="${REFS[default]}"

render_page() {
  local tpl="$1"
  local out="$2"
  local brand_name="$3"
  local brand_slug="$4"
  local domain="$5"
  local path_suffix="$6"
  local page_title_full="$7"
  local page_intro="$8"
  local ref_link="$9"

  sed \
    -e "s|BRAND_NAME|${brand_name}|g" \
    -e "s|BRAND_SLUG|${brand_slug}|g" \
    -e "s|DOMAIN|${domain}|g" \
    -e "s|PATH_SUFFIX|${path_suffix}|g" \
    -e "s|PAGE_TITLE_FULL|${page_title_full}|g" \
    -e "s|PAGE_INTRO|${page_intro}|g" \
    -e "s|REF_LINK|${ref_link}|g" \
    "$tpl" > "$out"
}

while IFS= read -r domain; do
  [[ -z "$domain" ]] && continue
  [[ "$domain" =~ ^# ]] && continue

  DOMAIN_DIR="${WORK_ROOT}/${domain}"
  mkdir -p "${DOMAIN_DIR}"

  while IFS= read -r brand; do
    [[ -z "$brand" ]] && continue
    [[ "$brand" =~ ^# ]] && continue

    BRAND_SLUG="${brand}"
    BRAND_CAP="$(printf '%s' "$brand" | sed 's/^./\U&/')"
    BRAND_NAME="${BRAND_CAP} Casino"

    REF_LINK="${REFS[$brand]}"
    [[ -z "$REF_LINK" ]] && REF_LINK="$DEFAULT_REF"

    SITE_DIR="${DOMAIN_DIR}/${BRAND_SLUG}"
    mkdir -p "${SITE_DIR}"/{register,bonus,reviews,withdrawal}

    render_page "$TEMPLATE" "${SITE_DIR}/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "" \
      "${BRAND_NAME} — официальный сайт онлайн казино" \
      "${BRAND_NAME} — это лицензированное онлайн-казино с бонусами, быстрыми выплатами и широким выбором слотов и live-игр." \
      "$REF_LINK"

    render_page "$TEMPLATE" "${SITE_DIR}/register/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "register/" \
      "Регистрация в ${BRAND_NAME}" \
      "Регистрация в ${BRAND_NAME} занимает меньше минуты. Создайте аккаунт, подтвердите контакты и получите приветственный бонус на первый депозит." \
      "$REF_LINK"

    render_page "$TEMPLATE" "${SITE_DIR}/bonus/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "bonus/" \
      "Бонусы и акции ${BRAND_NAME}" \
      "На странице бонусов ${BRAND_NAME} собраны приветственные предложения, фриспины, кэшбэк и эксклюзивные промокоды для активных игроков." \
      "$REF_LINK"

    render_page "$TEMPLATE" "${SITE_DIR}/reviews/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "reviews/" \
      "Отзывы игроков о ${BRAND_NAME}" \
      "Игроки отмечают быстрый вывод средств, разнообразие слотов и работу службы поддержки в ${BRAND_NAME}. Ознакомьтесь с реальными мнениями перед началом игры." \
      "$REF_LINK"

    render_page "$TEMPLATE" "${SITE_DIR}/withdrawal/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "withdrawal/" \
      "Вывод средств в ${BRAND_NAME}" \
      "Подробная информация о лимитах, сроках и доступных методах вывода выигрышей в ${BRAND_NAME}. Следуйте правилам KYC для ускорения обработки заявок." \
      "$REF_LINK"

    cat > "${SITE_DIR}/robots.txt" << ROB
User-agent: *
Disallow: /admin
Allow: /
Sitemap: https://${domain}/${BRAND_SLUG}/sitemap.xml
ROB

    cat > "${SITE_DIR}/sitemap.xml" << MAP
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://${domain}/${BRAND_SLUG}/</loc></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/register/</loc></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/bonus/</loc></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/reviews/</loc></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/withdrawal/</loc></url>
</urlset>
MAP

    echo "✅ Generated: ${BRAND_SLUG}.${domain}"

  done < "$SUBDOMAINS_FILE"
done < "$DOMAINS_FILE"
