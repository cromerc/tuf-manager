if not always_authenticated
    i18n.merge_file(
        input: 'org.tuf.manager.policy.in',
        output: 'org.tuf.manager.policy',
        po_dir: join_paths(meson.source_root(), 'po'),
        type: 'xml',
        install: true,
        install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
    )
endif
