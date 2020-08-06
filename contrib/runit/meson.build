runit = get_option('runit')

runit_config_data = configuration_data()
runit_config_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name()))

runit_config_data_file = configure_file(
    input: 'run.in',
    output: 'run',
    configuration: runit_config_data
)

if runit
    install_data(
        runit_config_data_file,
        install_dir: join_paths(get_option('sysconfdir'), 'runit', 'sv', 'tufmanager')
    )
endif
