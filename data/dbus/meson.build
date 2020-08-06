dbus_config_data = configuration_data()
dbus_config_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name()))

dbus_config_data_file = configure_file(
    input: 'org.tuf.manager.server.service.in',
    output: 'org.tuf.manager.server.service',
    configuration: dbus_config_data
)

install_data(
    ['org.tuf.manager.server.conf'],
    install_dir: join_paths(get_option('datadir'), 'dbus-1', 'system.d')
)
install_data(
    dbus_config_data_file,
    install_dir: join_paths(get_option('datadir'), 'dbus-1', 'system-services')
)
