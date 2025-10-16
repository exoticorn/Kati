release: release-linux

export-web:
    mkdir -p export/web
    godot --export-release Web export/web/index.html
    brotli -f export/web/index.wasm
    brotli -f export/web/index.pck

deploy-web: export-web
    rsync -rP export/web/. exoticorn.de:/var/www/html/kati/.

release-linux:
    rm -rf export/kati-linux
    mkdir -p export/kati-linux
    godot --export-release Linux export/kati-linux/Kati.x86_64
    cp README.md LICENSE.txt export/kati-linux
    cd export && tar czf kati-linux.tgz kati-linux
    
