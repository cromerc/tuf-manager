if build_gui
	gnome = import('gnome')
	tuf_manager_gresource = gnome.compile_resources(
		'tuf_manager_gresource',
		'tuf.manager.gresource.xml',
		source_dir: '.',
		c_name: 'resource_tuf_manager',
		export: true,
		install_header: true
	)
endif
