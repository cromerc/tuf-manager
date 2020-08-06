# server doesn't need gschema, only gui or cli
if build_gui or build_cli
    gnome = import('gnome')
    gschemas = files(
        'org.tuf.manager.gschema.xml'
    )
    gnome.compile_schemas(
        build_by_default: true,
        depend_files: gschemas
    )
    install_data('org.tuf.manager.gschema.xml', install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas'))
endif
