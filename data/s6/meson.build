s6_config_data = configuration_data()
s6_config_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name()))

s6_config_data_file = configure_file(
    input: 'run.in',
    output: 'run',
    configuration: s6_config_data
)

s6 = find_program ('s6-init', required: false)

if s6.found()
    install_data(
        [s6_config_data_file, 'type', 'dependencies'],
        install_dir: join_paths(get_option('sysconfdir'), 's6', 'sv', 'tufmanager')
    )
endif
