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

pick_page_variant() {
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

    # 5 основных вариантов (было 3)
    VARIANT_INDEX=$(pick_variant "$BRAND_SLUG" 5)

    case "$VARIANT_INDEX" in
      0)
        OFFICIAL_INTRO="${BRAND_NAME} — это лицензированное онлайн-казино с упором на быстрый вывод средств и регулярные турниры для активных игроков."
        BONUSES_INTRO="В ${BRAND_NAME} доступен приветственный пакет, еженедельный кэшбэк и специальные акции для хайроллеров."
        WITHDRAWAL_INTRO="Вывод средств в ${BRAND_NAME} происходит без скрытых комиссий, при условии прохождения стандартной верификации."
        REGISTER_INTRO="Регистрация в ${BRAND_NAME} занимает меньше минуты: заполните короткую форму, подтвердите контакты и получите доступ к бонусам."
        REVIEWS_INTRO="Игроки ${BRAND_NAME} чаще всего отмечают быстрые выплаты и удобный интерфейс сайта, подходящий как для новичков, так и для опытных пользователей."
        EXTRA_BLOCK_HTML="<h2>Рабочее зеркало ${BRAND_NAME}</h2><p>При временных блокировках основного домена используйте рабочее зеркало ${BRAND_NAME}. Оно полностью копирует функционал сайта и позволяет сохранять доступ к аккаунту и бонусам.</p>"
        TABLE_VARIANT=0
        ;;
      1)
        OFFICIAL_INTRO="${BRAND_NAME} — современное казино онлайн с большим выбором слотов, лайв-дилеров и удобной мобильной версией."
        BONUSES_INTRO="${BRAND_NAME} предлагает продуманную бонусную систему: фриспины, бонусы на депозиты и постоянные акции для лояльных игроков."
        WITHDRAWAL_INTRO="Выплаты в ${BRAND_NAME} обрабатываются автоматически, большинство заявок закрываются в течение 5–15 минут."
        REGISTER_INTRO="Создать аккаунт в ${BRAND_NAME} можно через email или телефон, а также с быстрой авторизацией через популярные сервисы."
        REVIEWS_INTRO="В отзывах о ${BRAND_NAME} часто упоминают удобную мобильную версию и стабильную работу сайта даже при высокой нагрузке."
        EXTRA_BLOCK_HTML="<h2>Мобильная версия ${BRAND_NAME}</h2><p>${BRAND_NAME} доступно на смартфонах и планшетах без установки отдельного приложения. Адаптивный интерфейс позволяет комфортно играть и управлять аккаунтом с любого устройства.</p>"
        TABLE_VARIANT=1
        ;;
      2)
        OFFICIAL_INTRO="${BRAND_NAME} — международная платформа для азартных игр с лицензией Curacao и поддержкой популярных платёжных систем."
        BONUSES_INTRO="В ${BRAND_NAME} можно получать бонусы за депозиты, участвовать в сезонных турнирах и активировать промокоды с повышенным кэшбэком."
        WITHDRAWAL_INTRO="Финансовые операции в ${BRAND_NAME} защищены шифрованием, а лимиты и сроки вывода прозрачно указаны в личном кабинете."
        REGISTER_INTRO="После регистрации в ${BRAND_NAME} вам станут доступны персональные акции, VIP-программа и участие в закрытых турнирах."
        REVIEWS_INTRO="Отзывы о ${BRAND_NAME} подчёркивают разнообразие провайдеров, наличие живых дилеров и регулярные турниры с крупными призовыми фондами."
        EXTRA_BLOCK_HTML="<h2>Турниры и джекпоты ${BRAND_NAME}</h2><p>В ${BRAND_NAME} регулярно проходят турниры с призовыми фондами и разыгрываются прогрессивные джекпоты. Детали участия и актуальные события отображаются в лобби казино.</p>"
        TABLE_VARIANT=2
        ;;
      3)
        OFFICIAL_INTRO="${BRAND_NAME} — надёжная площадка с проверенной репутацией, стабильностью и оперативной поддержкой для игроков со всего мира."
        BONUSES_INTRO="Система бонусов ${BRAND_NAME} разработана для максимальной выгоды: стартовые бонусы, кэшбэк и ежемесячные акции с призами."
        WITHDRAWAL_INTRO="В ${BRAND_NAME} вывод денег происходит быстро благодаря множеству платёжных методов и оптимизированной процедуре верификации."
        REGISTER_INTRO="Регистрация в ${BRAND_NAME} простая и безопасная: несколько кликов, и вы готовы начать играть с полным набором привилегий."
        REVIEWS_INTRO="Игроки ценят ${BRAND_NAME} за справедливые условия, прозрачную работу и внимательное отношение к каждому клиенту."
        EXTRA_BLOCK_HTML="<h2>Партнёрская программа ${BRAND_NAME}</h2><p>${BRAND_NAME} предлагает привлекательную программу для партнёров с комиссией от каждого игрока и поддержкой маркетинговых материалов.</p>"
        TABLE_VARIANT=0
        ;;
      4)
        OFFICIAL_INTRO="${BRAND_NAME} совмещает высокое качество игровых предложений с заботой о безопасности и комфорте каждого пользователя."
        BONUSES_INTRO="${BRAND_NAME} регулярно запускает эксклюзивные акции с повышенными коэффициентами отката и специальными предложениями для постоянных клиентов."
        WITHDRAWAL_INTRO="Процесс вывода в ${BRAND_NAME} полностью автоматизирован, что гарантирует минимальные сроки обработки запросов."
        REGISTER_INTRO="В ${BRAND_NAME} вас ждёт простая регистрация, моментальная активация аккаунта и доступ к эксклюзивным предложениям для новичков."
        REVIEWS_INTRO="Большинство отзывов о ${BRAND_NAME} отмечают высокий уровень сервиса, разнообразие игр и справедливую политику бонусов."
        EXTRA_BLOCK_HTML="<h2>Живой чат поддержки ${BRAND_NAME}</h2><p>Команда ${BRAND_NAME} работает 24/7 и всегда готова помочь с вопросами игры, платежами и техническими проблемами через живой чат.</p>"
        TABLE_VARIANT=1
        ;;
    esac

    # 5 вариантов для каждого типа страницы
    BONUS_PAGE_VARIANT=$(pick_page_variant "${BRAND_SLUG}_bonus" 5)
    WITHDRAW_PAGE_VARIANT=$(pick_page_variant "${BRAND_SLUG}_withdraw" 5)
    REGISTER_PAGE_VARIANT=$(pick_page_variant "${BRAND_SLUG}_register" 5)
    REVIEWS_PAGE_VARIANT=$(pick_page_variant "${BRAND_SLUG}_reviews" 5)

    case "$BONUS_PAGE_VARIANT" in
      0)
        BONUSES_INTRO_PAGE="$BONUSES_INTRO"
        ;;
      1)
        BONUSES_INTRO_PAGE="В ${BRAND_NAME} новый игрок может собрать приветственный пакет из бонусов на первые депозиты и фриспинов на популярные слоты."
        ;;
      2)
        BONUSES_INTRO_PAGE="${BRAND_NAME} регулярно запускает временные акции с увеличенными бонусами, промокодами и розыгрышами среди активных игроков."
        ;;
      3)
        BONUSES_INTRO_PAGE="Бонусная политика ${BRAND_NAME} включает не только приветственные предложения, но и регулярные вознаграждения за активность и лояльность."
        ;;
      4)
        BONUSES_INTRO_PAGE="${BRAND_NAME} даёт игрокам возможность увеличить свой банкролл через стартовые бонусы и постоянные расчеты кэшбэка без жёстких ограничений."
        ;;
    esac

    case "$WITHDRAW_PAGE_VARIANT" in
      0)
        WITHDRAWAL_INTRO_PAGE="$WITHDRAWAL_INTRO"
        ;;
      1)
        WITHDRAWAL_INTRO_PAGE="Средства из ${BRAND_NAME} можно вывести на банковские карты, электронные кошельки и другую популярную платёжную инфраструктуру без лишних задержек."
        ;;
      2)
        WITHDRAWAL_INTRO_PAGE="Перед первым выводом в ${BRAND_NAME} потребуется пройти верификацию, после чего повторные заявки обычно обрабатываются значительно быстрее."
        ;;
      3)
        WITHDRAWAL_INTRO_PAGE="Система вывода ${BRAND_NAME} поддерживает множество платёжных методов и гарантирует безопасную транспортировку ваших выигрышей."
        ;;
      4)
        WITHDRAWAL_INTRO_PAGE="${BRAND_NAME} не устанавливает минимальных лимитов на вывод, что позволяет игрокам забирать даже небольшие суммы без потерь."
        ;;
    esac

    case "$REGISTER_PAGE_VARIANT" in
      0)
        REGISTER_INTRO_PAGE="$REGISTER_INTRO"
        ;;
      1)
        REGISTER_INTRO_PAGE="Анкета в ${BRAND_NAME} максимально упрощена: укажите базовые данные, выберите валюту счёта и сразу переходите к пополнению и игре."
        ;;
      2)
        REGISTER_INTRO_PAGE="${BRAND_NAME} позволяет создать аккаунт с привязкой к телефону или email, что упрощает восстановление доступа и работу с бонусами."
        ;;
      3)
        REGISTER_INTRO_PAGE="Процесс регистрации в ${BRAND_NAME} занимает менее 30 секунд, и сразу после этого вы получаете доступ к полному каталогу игр и бонусам."
        ;;
      4)
        REGISTER_INTRO_PAGE="Новичкам в ${BRAND_NAME} предложен упрощённый режим регистрации с возможностью быстрого пополнения счёта и получения приветственного бонуса."
        ;;
    esac

    case "$REVIEWS_PAGE_VARIANT" in
      0)
        REVIEWS_INTRO_PAGE="$REVIEWS_INTRO"
        ;;
      1)
        REVIEWS_INTRO_PAGE="Часть игроков отмечает в отзывах ${BRAND_NAME} за стабильную работу сайта, быстрое открытие игр и понятные условия бонусных предложений."
        ;;
      2)
        REVIEWS_INTRO_PAGE="Среди отзывов о ${BRAND_NAME} часто встречаются комментарии о разнообразии провайдеров слотов и регулярных акциях для активных клиентов."
        ;;
      3)
        REVIEWS_INTRO_PAGE="Отзывы игроков о ${BRAND_NAME} подчёркивают надёжность платформы, простоту вывода средств и качество технической поддержки."
        ;;
      4)
        REVIEWS_INTRO_PAGE="${BRAND_NAME} получает положительные оценки за честную политику, прозрачность условий и справедливый расчёт выигрышей по всем видам игр."
        ;;
    esac

    # Вариативные таблицы
    case "$TABLE_VARIANT" in
      0)
        TABLE_HTML="<table><tr><th>Параметр</th><th>Описание</th></tr><tr><td>Лицензия</td><td>Curacao eGaming, номер 365/JAZ</td></tr><tr><td>Игровые автоматы</td><td>7200+ слотов, live-дилеры, crash-игры, Megaways и настольные игры</td></tr><tr><td>Минимальный депозит</td><td>от 100 ₽ или 5 EUR, в зависимости от способа оплаты</td></tr><tr><td>Скорость вывода</td><td>в среднем 5–30 минут после подтверждения заявки</td></tr></table>"
        ;;
      1)
        TABLE_HTML="<table><tr><th>Особенность</th><th>Подробнее</th></tr><tr><td>Провайдеры игр</td><td>Микроигры, Pragmatic Play, NetEnt, Evolution Gaming, Red Tiger и 80+ других разработчиков</td></tr><tr><td>Методы пополнения</td><td>Банковские карты, e-wallets (Skrill, Neteller), криптовалюты, мобильные платежи</td></tr><tr><td>Процесс регистрации</td><td>1 минута, простая анкета, моментальное подтверждение и доступ к бонусам</td></tr><tr><td>Поддержка игроков</td><td>Live chat 24/7, email, телефон, соцсети</td></tr></table>"
        ;;
      2)
        TABLE_HTML="<table><tr><th>Показатель</th><th>Значение</th></tr><tr><td>Лицензионный статус</td><td>Регулируемое казино с лицензией Curacao № 365/JAZ</td></tr><tr><td>Всего игр</td><td>Более 7500 слотов и настольных игр на выбор</td></tr><tr><td>Сертификация RTP</td><td>Все игры проходят независимую сертификацию на честность</td></tr><tr><td>Минимальная ставка</td><td>От 0.01 до 100+ в зависимости от игры</td></tr></table>"
        ;;
    esac

    SITE_DIR="${DOMAIN_DIR}/${BRAND_SLUG}"
    mkdir -p "${SITE_DIR}"/{register,bonus,reviews,withdrawal}

    # Финальный рендер с таблицей
    for page_type in index register bonus reviews withdrawal; do
      case "$page_type" in
        index)
          TITLE="${BRAND_NAME} — официальный сайт онлайн казино"
          INTRO="$OFFICIAL_INTRO"
          BONUS_TEXT="$BONUSES_INTRO"
          EXTRA="$EXTRA_BLOCK_HTML"
          PATH=""
          OUT="${SITE_DIR}/index.html"
          ;;
        register)
          TITLE="Регистрация в ${BRAND_NAME}"
          INTRO="$REGISTER_INTRO_PAGE"
          BONUS_TEXT="$BONUSES_INTRO"
          EXTRA=""
          PATH="register/"
          OUT="${SITE_DIR}/register/index.html"
          ;;
        bonus)
          TITLE="Бонусы и акции ${BRAND_NAME}"
          INTRO="$BONUSES_INTRO_PAGE"
          BONUS_TEXT="$BONUSES_INTRO"
          EXTRA=""
          PATH="bonus/"
          OUT="${SITE_DIR}/bonus/index.html"
          ;;
        reviews)
          TITLE="Отзывы игроков о ${BRAND_NAME}"
          INTRO="$REVIEWS_INTRO_PAGE"
          BONUS_TEXT="$BONUSES_INTRO"
          EXTRA=""
          PATH="reviews/"
          OUT="${SITE_DIR}/reviews/index.html"
          ;;
        withdrawal)
          TITLE="Вывод средств в ${BRAND_NAME}"
          INTRO="$WITHDRAWAL_INTRO_PAGE"
          BONUS_TEXT="$BONUSES_INTRO"
          EXTRA=""
          PATH="withdrawal/"
          OUT="${SITE_DIR}/withdrawal/index.html"
          ;;
      esac

      render_page "$TEMPLATE" "$OUT" "$BRAND_NAME" "$BRAND_SLUG" "$domain" "$PATH" "$TITLE" "$INTRO" "$REF_LINK" "$BONUS_TEXT" "$EXTRA"
    done

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

    FAV_TEXT="${BRAND_CAP:0:1}"
    convert -size 64x64 xc:"#0b1020" -gravity center -fill "#ffb34d" -pointsize 42 -annotate 0 "$FAV_TEXT" "${SITE_DIR}/favicon-64.png"
    convert "${SITE_DIR}/favicon-64.png" -resize 32x32 "${SITE_DIR}/favicon-32x32.png"
    convert "${SITE_DIR}/favicon-64.png" -resize 16x16 "${SITE_DIR}/favicon-16x16.png"
    convert "${SITE_DIR}/favicon-16x16.png" "${SITE_DIR}/favicon-32x32.png" -colors 256 "${SITE_DIR}/favicon.ico"

    echo "✅ Generated: ${BRAND_SLUG}.${domain}"

  done < "$SUBDOMAINS_FILE"
done < "$DOMAINS_FILE"
