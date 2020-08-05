# TUF Manager

## License
[3-Clause BSD License](LICENSE)

## Build requirements
To build TUF Manager the following is needed:

- vala
- valadoc
- glib
- gtk3
- dbus
- polkit
- polkit-gobject
- gmodule-export

## Build options

- valadocs

Build TUF Manager's vala documentation.
- valadocs-deps

Build external valadocs that TUF Manager utilizes and calls.
- always-authenticated

Authentication is not required to use the TUF Server that runs in the background as a daemon, if this is set to false polkit is used for authentication. Setting this to false is more secure, but also makes things like auto restore of settings on login impossible to do without a password.

## Usage
There are 2 programs and 1 daemon supplied by TUF Manager.

- tuf-cli

This allows controlling the TUF laptop functions via command line interface.
- tuf-gui

This supplies a graphical interface to control the TUF laptop.
- tuf-server

This is the daemon that runs in the background and handles all requests from both tuf-cli and tuf-gui.

## Future plans

- Manpage
- Config options for both tuf-gui and tuf-cli
- Status bar icon that allows control of the notebook
- Notifications of fan mode change via status bar
- Restore last known settings on login via status bar icon
- Service scripts for various init systems instead of relying on dbus activation
