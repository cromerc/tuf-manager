#!/bin/sh -eu

echo "Compiling gsettings schemas..."
glib-compile-schemas "${MESON_INSTALL_DESTDIR_PREFIX}/share/glib-2.0/schemas"
