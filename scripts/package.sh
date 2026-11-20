#!/bin/bash
# Production package for Russian shared hosting: builds for the real domain, drops the git-based admin (useless there), adds .htaccess, zips.
# Usage: [HTTPS=1] scripts/package.sh [domain] [index]   e.g. scripts/package.sh revers22.ru        (noindex, for review)
#   HTTPS=1 (after the SSL certificate is issued) turns on the http -> https redirect in .htaccess
#                                                    scripts/package.sh revers22.ru 1      (open to Yandex/Google)
set -euo pipefail
cd "$(dirname "$0")/.."
DOMAIN="${1:-revers22.ru}"; IDX="${2:-0}"
SITE_URL="https://$DOMAIN" BASE="" INDEX="$IDX" node build.mjs
OUT="../hosting-package/$DOMAIN"; rm -rf "$OUT"; mkdir -p "$OUT"
cp -R dist/. "$OUT/"
rm -rf "$OUT/admin" "$OUT/admin-decap" "$OUT/admin-sveltia"
cat > "$OUT/.htaccess" <<'H'
Options -Indexes
AddDefaultCharset UTF-8
ErrorDocument 404 /404.html
__HTTPS__
<IfModule mod_deflate.c>
AddOutputFilterByType DEFLATE text/html text/css application/javascript application/json image/svg+xml
</IfModule>
<IfModule mod_expires.c>
ExpiresActive On
ExpiresByType image/webp "access plus 1 year"
ExpiresByType font/woff2 "access plus 1 year"
ExpiresByType text/css "access plus 1 week"
ExpiresByType application/javascript "access plus 1 week"
ExpiresByType text/html "access plus 10 minutes"
</IfModule>
H
if [ "${HTTPS:-0}" = 1 ]; then R="RewriteEngine On\nRewriteCond %{HTTP_HOST} ^www\\. [NC,OR]\nRewriteCond %{HTTPS} off\nRewriteRule ^(.*)\$ https://$DOMAIN/\$1 [R=301,L]"; else R='# http -> https redirect is off; rebuild with HTTPS=1 after the SSL certificate is issued'; fi
python3 -c "import sys;p=sys.argv[1];s=open(p).read().replace('__HTTPS__',sys.argv[2].replace('\\\\n','\\n'));open(p,'w').write(s)" "$OUT/.htaccess" "$R"
(cd "$(dirname "$OUT")" && rm -f "$DOMAIN.zip" && zip -qr "$DOMAIN.zip" "$DOMAIN")
echo "package: $OUT ($(find "$OUT" -type f | wc -l | tr -d ' ') files), zip: $(du -h "$OUT.zip" | cut -f1)  index=$IDX"
