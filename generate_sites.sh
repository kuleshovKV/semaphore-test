#!/bin/bash
set -e

GEN_DIR="/var/www/casino_generator"
WORK_ROOT="/var/www"

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

pick_variant() {
  local key="$1"
  local max="$2"
  local sum=0
  local i char

  for (( i=0; i<${#key}; i++ )); do
    char=$(printf '%d' "'${key:$i:1}")
    sum=$((sum + char))
  done

  echo $(( sum % max ))
}

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
  local page_bonuses="${10}"
  local extra_block_html="${11}"
  local date_published="${12}"
  local date_modified="${13}"
  local section_1="${14}"
  local section_2="${15}"
  local section_3="${16}"

  sed \
    -e "s|BRAND_NAME|${brand_name}|g" \
    -e "s|BRAND_SLUG|${brand_slug}|g" \
    -e "s|DOMAIN|${domain}|g" \
    -e "s|PATH_SUFFIX|${path_suffix}|g" \
    -e "s|PAGE_TITLE_FULL|${page_title_full}|g" \
    -e "s|PAGE_INTRO|${page_intro}|g" \
    -e "s|PAGE_BONUSES|${page_bonuses}|g" \
    -e "s|EXTRA_BLOCK_HTML|${extra_block_html}|g" \
    -e "s|REF_LINK|${ref_link}|g" \
    -e "s|DATE_PUBLISHED|${date_published}|g" \
    -e "s|DATE_MODIFIED|${date_modified}|g" \
    -e "s|SECTION_1_BLOCK|${section_1}|g" \
    -e "s|SECTION_2_BLOCK|${section_2}|g" \
    -e "s|SECTION_3_BLOCK|${section_3}|g" \
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

    VARIANT_INDEX=$(pick_variant "$BRAND_SLUG" 3)
    SECTION_VARIANT=$(pick_variant "${BRAND_SLUG}_section" 3)
    DATE_OFFSET=$(pick_variant "${BRAND_SLUG}_date" 7)

    # Даты (сегодня ± N дней)
    TODAY=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    DATE_PUBLISHED=$(date -u -d "${DATE_OFFSET} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "2025-01-01T00:00:00Z")
    DATE_MODIFIED="$TODAY"

    case "$VARIANT_INDEX" in
      0)
        OFFICIAL_INTRO="${BRAND_NAME} — это лицензированное онлайн-казино с упором на быстрый вывод средств и регулярные турниры для активных игроков."
        BONUSES_INTRO="В ${BRAND_NAME} доступен приветственный пакет, еженедельный кэшбэк и специальные акции для хайроллеров."
        WITHDRAWAL_INTRO="Вывод средств в ${BRAND_NAME} происходит без скрытых комиссий, при условии прохождения стандартной верификации."
        REGISTER_INTRO="Регистрация в ${BRAND_NAME} занимает меньше минуты: заполните короткую форму, подтвердите контакты и получите доступ к бонусам."
        REVIEWS_INTRO="Игроки ${BRAND_NAME} чаще всего отмечают быстрые выплаты и удобный интерфейс сайта, подходящий как для новичков, так и для опытных пользователей."
        EXTRA_BLOCK_HTML="<h2>Рабочее зеркало ${BRAND_NAME}</h2><p>При временных блокировках основного домена используйте рабочее зеркало ${BRAND_NAME}. Оно полностью копирует функционал сайта и позволяет сохранять доступ к аккаунту и бонусам.</p>"
        ;;
      1)
        OFFICIAL_INTRO="${BRAND_NAME} — современное казино онлайн с большим выбором слотов, лайв-дилеров и удобной мобильной версией."
        BONUSES_INTRO="${BRAND_NAME} предлагает продуманную бонусную систему: фриспины, бонусы на депозиты и постоянные акции для лояльных игроков."
        WITHDRAWAL_INTRO="Выплаты в ${BRAND_NAME} обрабатываются автоматически, большинство заявок закрываются в течение 5–15 минут."
        REGISTER_INTRO="Создать аккаунт в ${BRAND_NAME} можно через email или телефон, а также с быстрой авторизацией через популярные сервисы."
        REVIEWS_INTRO="В отзывах о ${BRAND_NAME} часто упоминают удобную мобильную версию и стабильную работу сайта даже при высокой нагрузке."
        EXTRA_BLOCK_HTML="<h2>Мобильная версия ${BRAND_NAME}</h2><p>${BRAND_NAME} доступно на смартфонах и планшетах без установки отдельного приложения. Адаптивный интерфейс позволяет комфортно играть и управлять аккаунтом с любого устройства.</p>"
        ;;
      2)
        OFFICIAL_INTRO="${BRAND_NAME} — международная платформа для азартных игр с лицензией Curacao и поддержкой популярных платёжных систем."
        BONUSES_INTRO="В ${BRAND_NAME} можно получать бонусы за депозиты, участвовать в сезонных турнирах и активировать промокоды с повышенным кэшбэком."
        WITHDRAWAL_INTRO="Финансовые операции в ${BRAND_NAME} защищены шифрованием, а лимиты и сроки вывода прозрачно указаны в личном кабинете."
        REGISTER_INTRO="После регистрации в ${BRAND_NAME} вам станут доступны персональные акции, VIP-программа и участие в закрытых турнирах."
        REVIEWS_INTRO="Отзывы о ${BRAND_NAME} подчёркивают разнообразие провайдеров, наличие живых дилеров и регулярные турниры с крупными призовыми фондами."
        EXTRA_BLOCK_HTML="<h2>Турниры и джекпоты ${BRAND_NAME}</h2><p>В ${BRAND_NAME} регулярно проходят турниры с призовыми фондами и разыгрываются прогрессивные джекпоты. Детали участия и актуальные события отображаются в лобби казино.</p>"
        ;;
    esac

    # Вариативность структуры блоков (разный порядок)
    case "$SECTION_VARIANT" in
      0)
        SECTION_1="<h2>Официальный сайт ${BRAND_NAME}</h2><p><strong>${BRAND_NAME}</strong> — это современное онлайн-казино с международной лицензией Curacao, доступом к тысячам слотов и быстрыми выплатами на популярные платёжные системы.</p><table><tr><th>Параметр</th><th>Описание</th></tr><tr><td>Лицензия</td><td>Curacao eGaming, номер 365/JAZ</td></tr><tr><td>Игровые автоматы</td><td>7200+ слотов, live-дилеры, crash-игры, Megaways и настольные игры</td></tr><tr><td>Минимальный депозит</td><td>от 100 ₽ или 5 EUR, в зависимости от способа оплаты</td></tr><tr><td>Скорость вывода</td><td>в среднем 5–30 минут после подтверждения заявки</td></tr></table>"
        SECTION_2="<h2>Бонусы и акции ${BRAND_NAME}</h2><p>${BONUSES_INTRO}</p>"
        SECTION_3="$EXTRA_BLOCK_HTML"
        ;;
      1)
        SECTION_1="<h2>Бонусы и акции ${BRAND_NAME}</h2><p>${BONUSES_INTRO}</p>"
        SECTION_2="<h2>Официальный сайт ${BRAND_NAME}</h2><p><strong>${BRAND_NAME}</strong> — это современное онлайн-казино с международной лицензией Curacao, доступом к тысячам слотов и быстрыми выплатами на популярные платёжные системы.</p><table><tr><th>Параметр</th><th>Описание</th></tr><tr><td>Лицензия</td><td>Curacao eGaming, номер 365/JAZ</td></tr><tr><td>Игровые автоматы</td><td>7200+ слотов, live-дилеры, crash-игры, Megaways и настольные игры</td></tr><tr><td>Минимальный депозит</td><td>от 100 ₽ или 5 EUR, в зависимости от способа оплаты</td></tr><tr><td>Скорость вывода</td><td>в среднем 5–30 минут после подтверждения заявки</td></tr></table>"
        SECTION_3="$EXTRA_BLOCK_HTML"
        ;;
      2)
        SECTION_1="$EXTRA_BLOCK_HTML"
        SECTION_2="<h2>Официальный сайт ${BRAND_NAME}</h2><p><strong>${BRAND_NAME}</strong> — это современное онлайн-казино с международной лицензией Curacao, доступом к тысячам слотов и быстрыми выплатами на популярные платёжные системы.</p><table><tr><th>Параметр</th><th>Описание</th></tr><tr><td>Лицензия</td><td>Curacao eGaming, номер 365/JAZ</td></tr><tr><td>Игровые автоматы</td><td>7200+ слотов, live-дилеры, crash-игры, Megaways и настольные игры</td></tr><tr><td>Минимальный депозит</td><td>от 100 ₽ или 5 EUR, в зависимости от способа оплаты</td></tr><tr><td>Скорость вывода</td><td>в среднем 5–30 минут после подтверждения заявки</td></tr></table>"
        SECTION_3="<h2>Бонусы и акции ${BRAND_NAME}</h2><p>${BONUSES_INTRO}</p>"
        ;;
    esac

    SITE_DIR="${DOMAIN_DIR}/${BRAND_SLUG}"
    mkdir -p "${SITE_DIR}"/{register,bonus,reviews,withdrawal}

    render_page "$TEMPLATE" "${SITE_DIR}/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "" \
      "${BRAND_NAME} — официальный сайт онлайн казино" \
      "$OFFICIAL_INTRO" \
      "$REF_LINK" \
      "$BONUSES_INTRO" \
      "" \
      "$DATE_PUBLISHED" \
      "$DATE_MODIFIED" \
      "$SECTION_1" \
      "$SECTION_2" \
      "$SECTION_3"

    render_page "$TEMPLATE" "${SITE_DIR}/register/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "register/" \
      "Регистрация в ${BRAND_NAME}" \
      "$REGISTER_INTRO" \
      "$REF_LINK" \
      "$BONUSES_INTRO" \
      "" \
      "$DATE_PUBLISHED" \
      "$DATE_MODIFIED" \
      "$SECTION_1" \
      "$SECTION_2" \
      "$SECTION_3"

    render_page "$TEMPLATE" "${SITE_DIR}/bonus/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "bonus/" \
      "Бонусы и акции ${BRAND_NAME}" \
      "$BONUSES_INTRO" \
      "$REF_LINK" \
      "$BONUSES_INTRO" \
      "" \
      "$DATE_PUBLISHED" \
      "$DATE_MODIFIED" \
      "$SECTION_1" \
      "$SECTION_2" \
      "$SECTION_3"

    render_page "$TEMPLATE" "${SITE_DIR}/reviews/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "reviews/" \
      "Отзывы игроков о ${BRAND_NAME}" \
      "$REVIEWS_INTRO" \
      "$REF_LINK" \
      "$BONUSES_INTRO" \
      "" \
      "$DATE_PUBLISHED" \
      "$DATE_MODIFIED" \
      "$SECTION_1" \
      "$SECTION_2" \
      "$SECTION_3"

    render_page "$TEMPLATE" "${SITE_DIR}/withdrawal/index.html" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "withdrawal/" \
      "Вывод средств в ${BRAND_NAME}" \
      "$WITHDRAWAL_INTRO" \
      "$REF_LINK" \
      "$BONUSES_INTRO" \
      "" \
      "$DATE_PUBLISHED" \
      "$DATE_MODIFIED" \
      "$SECTION_1" \
      "$SECTION_2" \
      "$SECTION_3"

    cat > "${SITE_DIR}/robots.txt" << ROB
User-agent: *
Disallow: /admin
Allow: /
Sitemap: https://${domain}/${BRAND_SLUG}/sitemap.xml
ROB

    cat > "${SITE_DIR}/sitemap.xml" << MAP
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://${domain}/${BRAND_SLUG}/</loc><lastmod>${DATE_MODIFIED}</lastmod></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/register/</loc><lastmod>${DATE_MODIFIED}</lastmod></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/bonus/</loc><lastmod>${DATE_MODIFIED}</lastmod></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/reviews/</loc><lastmod>${DATE_MODIFIED}</lastmod></url>
  <url><loc>https://${domain}/${BRAND_SLUG}/withdrawal/</loc><lastmod>${DATE_MODIFIED}</lastmod></url>
</urlset>
MAP

    cat > "${SITE_DIR}/privacy/index.html" << PRIV
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Политика конфиденциальности | ${BRAND_NAME}</title>
</head>
<body>
  <h1>Политика конфиденциальности ${BRAND_NAME}</h1>
  <p>${BRAND_NAME} уважает приватность своих пользователей и обязуется защищать персональные данные в соответствии с GDPR и локальным законодательством.</p>
  <h2>Сбор данных</h2>
  <p>При регистрации мы собираем: ФИО, адрес электронной почты, номер телефона, паспортные данные для верификации.</p>
  <h2>Использование данных</h2>
  <p>Данные используются для: верификации личности, обработки платежей, связи с игроком, предотвращения мошенничества.</p>
  <h2>Защита данных</h2>
  <p>Все данные зашифрованы и хранятся на защищённых серверах. Доступ имеют только авторизованные сотрудники.</p>
</body>
</html>
PRIV

    cat > "${SITE_DIR}/terms/index.html" << TERMS
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Условия использования | ${BRAND_NAME}</title>
</head>
<body>
  <h1>Условия использования ${BRAND_NAME}</h1>
  <p>Используя ${BRAND_NAME}, вы соглашаетесь с нижеследующими условиями.</p>
  <h2>Возраст</h2>
  <p>Только лица старше 18 лет могут создавать аккаунты и играть в ${BRAND_NAME}.</p>
  <h2>Ответственная игра</h2>
  <p>Мы поддерживаем ответственную игру. Если вы испытываете проблемы с контролем ставок, свяжитесь с нашей поддержкой.</p>
  <h2>Запреты</h2>
  <p>Запрещены: использование ботов, автоклики, множественные аккаунты, мошенничество, манипуляция системой.</p>
</body>
</html>
TERMS

    cat > "${SITE_DIR}/responsible-gaming/index.html" << RG
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ответственная игра | ${BRAND_NAME}</title>
</head>
<body>
  <h1>Ответственная игра</h1>
  <p>${BRAND_NAME} поддерживает принципы ответственной игры и помогает игрокам контролировать свои расходы.</p>
  <h2>Инструменты самоограничения</h2>
  <ul>
    <li>Установка лимитов на ставки (суточные, недельные, месячные)</li>
    <li>Период охлаждения (временное блокирование аккаунта)</li>
    <li>Полное самоисключение на длительный период</li>
  </ul>
  <h2>Ресурсы помощи</h2>
  <p><a href="https://www.gambleaware.co.uk">GambleAware</a> — бесплатная консультация и поддержка.</p>
</body>
</html>
RG

    FAV_TEXT="${BRAND_CAP:0:1}"
    convert -size 64x64 xc:"#0b1020" -gravity center -fill "#ffb34d" -pointsize 42 -annotate 0 "$FAV_TEXT" "${SITE_DIR}/favicon-64.png"
    convert "${SITE_DIR}/favicon-64.png" -resize 32x32 "${SITE_DIR}/favicon-32x32.png"
    convert "${SITE_DIR}/favicon-64.png" -resize 16x16 "${SITE_DIR}/favicon-16x16.png"
    convert "${SITE_DIR}/favicon-16x16.png" "${SITE_DIR}/favicon-32x32.png" -colors 256 "${SITE_DIR}/favicon.ico"

    echo "✅ Generated: ${BRAND_SLUG}.${domain}"

  done < "$SUBDOMAINS_FILE"
done < "$DOMAINS_FILE"
