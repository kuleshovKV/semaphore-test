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
  local table_html="${12}"

  sed \
    -e "s|BRAND_NAME|${brand_name}|g" \
    -e "s|BRAND_SLUG|${brand_slug}|g" \
    -e "s|DOMAIN|${domain}|g" \
    -e "s|PATH_SUFFIX|${path_suffix}|g" \
    -e "s|PAGE_TITLE_FULL|${page_title_full}|g" \
    -e "s|PAGE_INTRO|${page_intro}|g" \
    -e "s|PAGE_BONUSES|${page_bonuses}|g" \
    -e "s|EXTRA_BLOCK_HTML|${extra_block_html}|g" \
    -e "s|TABLE_HTML|${table_html}|g" \
    -e "s|REF_LINK|${ref_link}|g" \
    "$tpl" > "$out"
}
