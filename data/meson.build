if build_gui
    i18n.merge_file(
        input: 'tuf-manager.desktop.in',
        output: 'tuf-manager.desktop',
        po_dir: join_paths(meson.source_root(), 'po'),
        type: 'desktop',
        install: true,
        install_dir: join_paths(get_option('datadir'), 'applications')
    )
    
    if build_tray
        i18n.merge_file(
            input: 'tuf-tray.desktop.in',
            output: 'tuf-tray.desktop',
            po_dir: join_paths(meson.source_root(), 'po'),
            type: 'desktop',
            install: true,
            install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
        )
    endif
endif

subdir('dbus')
subdir('polkit')
subdir('ui')
subdir('icons')
subdir('gschema')
