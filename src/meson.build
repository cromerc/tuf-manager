glib_dep = dependency('glib-2.0')
gtk_dep = dependency('gtk+-3.0', version: '>=3.14.0')
posix_dep = meson.get_compiler('vala').find_library('posix', required: true)
m_dep = meson.get_compiler('c').find_library('m', required: true)

gio_unix_dep = dependency('gio-unix-2.0')
if not always_authenticated
    polkit_gobject_dep = dependency('polkit-gobject-1')
endif

if build_gui
    gobject_dep = dependency('gobject-2.0')
    gmodule_dep = dependency('gmodule-2.0') # gmodule-export-2.0 is needed to connect the handlers from glade ui

    if build_tray
        appindicator_dep = dependency('appindicator3-0.1')
        libnotify_dep = dependency('libnotify')
    endif
endif

server_dependencies = [
    glib_dep,
    gio_unix_dep,
    gtk_dep,
    m_dep,
    posix_dep
]

# if not always authenticated then polkit will be used for authentication
if not always_authenticated
    server_dependencies += [polkit_gobject_dep]
endif

if build_cli
    cli_dependencies = [
        glib_dep,
        gtk_dep,
        m_dep
    ]
endif

if build_gui
    gui_dependencies = [
        glib_dep,
        gobject_dep,
        gtk_dep,
        gmodule_dep # gmodule-export-2.0 is needed to connect the handlers from glade ui
    ]

    if build_tray
        tray_dependencies = [
            appindicator_dep,
            gtk_dep,
            libnotify_dep,
            posix_dep
        ]
    endif
endif

config_data = configuration_data()
config_data.set('VERSION', meson.project_version())
config_data.set('GETTEXT_PACKAGE', meson.project_name())

config_data_file = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: config_data
)

if build_cli
    config_data = configuration_data()
    config_data.set('APP', 'CLI')
    cli_main_file = configure_file(
        input: 'main.vala.in',
        output: 'cli-main.vala',
        configuration: config_data
    )
endif

if build_gui
    config_data = configuration_data()
    config_data.set('APP', 'GUI')
    gui_main_file = configure_file(
        input: 'main.vala.in',
        output: 'gui-main.vala',
        configuration: config_data
    )
endif

error_vala_sources = files(
    'error.vala'
)

# The sources containing a main function definition are separated to prevent
# conflict errors when building valadoc. valadoc doesn't like multiple entry
# points even if they are in different namespaces.
server_vala_sources_main = files(
    'server-main.vala'
)

if build_tray
    tray_vala_sources_main = files(
        'tray-main.vala'
    )
endif

server_vala_sources = files(
    'server.vala',
    'server-interface.vala'
)

if build_cli
    cli_vala_sources = files(
        'cli.vala',
        'server-interface.vala',
        'common.vala'
    )
endif

if build_gui
    gui_vala_sources = files(
        'gui.vala',
        'gui-window.vala',
        'server-interface.vala',
        'common.vala'
    )

    if build_tray
        tray_vala_sources = files(
            'tray.vala',
            'tray-icon.vala',
            'server-interface.vala',
            'common.vala'
        )
    endif
endif

server_sources = server_vala_sources
server_sources += server_vala_sources_main
server_sources += error_vala_sources
server_sources += config_data_file

if build_cli
    cli_sources = cli_vala_sources
    cli_sources += cli_main_file
    cli_sources += error_vala_sources
    cli_sources += config_data_file
endif

if build_gui
    gui_sources = gui_vala_sources
    gui_sources += gui_main_file
    gui_sources += error_vala_sources
    gui_sources += [tuf_manager_gresource]
    gui_sources += config_data_file

    if build_tray
        tray_sources = tray_vala_sources
        tray_sources += tray_vala_sources_main
        tray_sources += error_vala_sources
        tray_sources += config_data_file
    endif
endif

server_vala_args = []
if always_authenticated
    server_vala_args += ['--define=ALWAYS_AUTHENTICATED']
endif

if build_cli
    cli_vala_args = []
    if always_authenticated
        cli_vala_args += ['--define=ALWAYS_AUTHENTICATED']
    endif
endif

if build_gui
    gui_vala_args = ['--gresources='+join_paths(meson.source_root(), 'data/ui/tuf.manager.gresource.xml')]
endif

server_exe = executable(
    'tuf-server',
    server_sources,
    dependencies: server_dependencies,
    vala_args: server_vala_args,
    install: true,
    install_dir: join_paths(get_option('libexecdir'), meson.project_name())
)

if build_cli
    cli_exe = executable(
        'tuf-cli',
        cli_sources,
        vala_args: cli_vala_args,
        dependencies: cli_dependencies,
        install: true
    )
endif

if build_gui
    gui_exe = executable(
        'tuf-gui',
        gui_sources,
        dependencies: gui_dependencies,
        vala_args: gui_vala_args,
        install: true
    )

    if build_tray
        tray_exe = executable(
            'tuf-tray',
            tray_sources,
            dependencies: tray_dependencies,
            install: true
        )
    endif
endif
