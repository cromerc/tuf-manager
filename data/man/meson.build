man_pages = files()
if build_cli
    man_pages += files('tuf-cli.1')
endif
if build_gui
    man_pages += files('tuf-gui.1')
endif
if build_tray
    man_pages += files('tuf-tray.1')
endif

if build_cli or build_gui or build_tray
    install_man(man_pages)
endif

