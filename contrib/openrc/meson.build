openrc_config_data = configuration_data()
openrc_config_data.set('SBINDIR', join_paths(get_option('prefix'), get_option('sbindir')))
openrc_config_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name()))

openrc_config_data_file = configure_file(
    input: 'tufmanager.in',
    output: 'tufmanager',
    configuration: openrc_config_data
)

if openrc
    install_data(
        openrc_config_data_file,
        install_dir: join_paths(get_option('sysconfdir'), 'init.d')
    )

    permissions = find_program('chmod')
    meson.add_install_script('permission.sh', join_paths(get_option('sysconfdir'), 'init.d'))
endif
