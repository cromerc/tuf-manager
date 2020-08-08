systemd_config_data = configuration_data()
systemd_config_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name()))

systemd_config_data_file = configure_file(
    input: 'tufmanager.service.in',
    output: 'tufmanager.service',
    configuration: systemd_config_data
)

systemd = find_program ('systemd', required: false)

if systemd.found()
    message ('systemd was found')
    install_data(
        systemd_config_data_file,
        install_dir: join_paths(get_option('prefix'), 'lib', 'systemd', 'system')
    )
endif
