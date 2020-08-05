docs_enabled = get_option('valadocs')
if docs_enabled
	valadoc = find_program('valadoc', required: docs_enabled)
	vala_doc_sources = server_vala_sources
	if build_cli
		vala_doc_sources += cli_vala_sources
	endif
	if build_gui
		vala_doc_sources += gui_vala_sources
	endif
	vala_doc_sources += error_vala_sources
	vala_doc_sources += config_data_file
	valadocs_deps = get_option('valadocs-deps')
	docs_deps = [
		'--pkg=polkit-gobject-1',
		'--pkg=posix',
		'--pkg=gtk+-3.0'
	]
	if valadocs_deps
		docs_deps += ['--deps']
	endif
	custom_target(
		'valadoc',
		input: vala_doc_sources,
		output: 'valadoc',
		command: [ valadoc,
			docs_deps,
			'--doclet=html',
			'--internal',
			'--private',
			'--force',
			'--package-name=@0@'.format(meson.project_name()),
			'--package-version=@0@'.format(meson.project_version()),
			'--vapidir=@0@'.format(join_paths(meson.source_root(), 'vapi')),
			'--directory=@OUTDIR@/valadoc',
			vala_doc_sources
		],
		build_by_default: true,
		install: true,
		install_dir: join_paths(get_option('datadir'), 'doc', meson.project_name())
	)
endif

install_data('../LICENSE', install_dir: join_paths(get_option('datadir'), 'doc', meson.project_name()))
install_data('../README.md', install_dir: join_paths(get_option('datadir'), 'doc', meson.project_name()))
