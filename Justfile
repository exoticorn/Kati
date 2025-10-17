release: release-linux release-win release-mac deploy-web

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
    
release-win:
    rm -rf export/kati-windows
    mkdir -p export/kati-windows
    godot --export-release "Windows Desktop" export/kati-windows/Kati.exe
    cp README.md LICENSE.txt export/kati-windows
    cd export && zip -r -9 kati-windows.zip kati-windows

release-mac:
    mkdir -p export
    godot --export-release macOS export/kati-macos.zip
    zip export/kati-macos.zip README.md LICENSE.txt
