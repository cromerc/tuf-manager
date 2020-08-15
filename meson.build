project(
    'tuf-manager',
    [
        'c',
        'vala'
    ],
    version: '1.2.0',
    license: 'BSD-3',
    default_options:
    [
        'b_ndebug=if-release',
        'c_std=c18',
        'warning_level=2'
    ]
)
add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

always_authenticated = get_option('always-authenticated')
build_cli = get_option('build-cli')
build_gui = get_option('build-gui')
build_tray = get_option('build-tray')

subdir('po')
subdir('data')
subdir('src')
subdir('docs')
subdir('script')
subdir('contrib')
