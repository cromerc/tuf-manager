# only gui or cli need gschema
if build_gui or build_cli
    glib_compile_schemas = find_program('glib-compile-schemas')
    meson.add_install_script('compile_schemas.sh')
endif
