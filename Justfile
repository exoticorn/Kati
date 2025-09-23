export-web:
    godot --export-release Web export/web/index.html
    brotli -f export/web/index.wasm
    brotli -f export/web/index.pck

deploy-web: export-web
    rsync -rP export/web/. exoticorn.de:/var/www/html/kati/.
