/*
 * Copyright 2020 Chris Cromer
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The TUF Manager namespace
 */
namespace TUFManager {
    /**
     * The tray namespace handles everything related to the system tray
     */
    namespace Tray {
        private TUFManagerApp parent;
        private Thread<void>? thread = null;
        private bool poll = true;
        public class TrayIcon {
            private AppIndicator.Indicator indicator;
            private Notify.Notification notification;
            private Gtk.IconTheme icon_theme;

            /**
             * The settings object from gschema/dconf
             */
            private Settings settings;

            public TrayIcon () {
                Process.signal (ProcessSignal.INT, on_exit);
                Process.signal (ProcessSignal.TERM, on_exit);

                settings = new Settings ("org.tuf.manager");
                try {
                    connect_tuf_server ();
                }
                catch (TUFError e) {
                    warning (e.message);
                }

                icon_theme = Gtk.IconTheme.get_default ();
                icon_theme.changed.connect (on_icon_theme_changed);

                indicator = new AppIndicator.Indicator (_ ("TUF Manager"), "tuf-manager", AppIndicator.IndicatorCategory.APPLICATION_STATUS);

                indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);
                var menu = new Gtk.Menu ();
                var item = new Gtk.MenuItem.with_mnemonic (_ ("_TUF Manager"));
                item.activate.connect (execute_manager);
                menu.append (item);

                // Submenu fan
                item = new Gtk.MenuItem.with_mnemonic (_ ("_Fan"));
                menu.append (item);
                var submenu = new Gtk.Menu ();
                item.set_submenu (submenu);

                // Fan modes
                var subitem = new Gtk.MenuItem.with_mnemonic (_ ("_Balanced"));
                subitem.activate.connect (set_fan_balanced);
                submenu.append (subitem);

                subitem = new Gtk.MenuItem.with_mnemonic (_ ("_Turbo"));
                subitem.activate.connect (set_fan_turbo);
                submenu.append (subitem);

                subitem = new Gtk.MenuItem.with_mnemonic (_ ("_Silent"));
                subitem.activate.connect (set_fan_silent);
                submenu.append (subitem);

                // Quit
                item = new Gtk.MenuItem.with_mnemonic (_ ("_Quit"));
                item.activate.connect (quit);
                menu.append (item);

                menu.show_all ();

                indicator.set_menu (menu);

                indicator.set_icon_full ("tuf-manager", "tuf-manager");
                indicator.set_title (_ ("TUF Manager"));
                set_icon_visible (true);

                Timeout.add_seconds (30, () => {
                    indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);
                    show_notification ("TUF Manager started");
                    close_notification ();
                    return false;
                });

                Notify.init (_ ("TUF Manager"));

                restore ();
                thread = new Thread<void> ("poll_fan", this.poll_fan);
            }

            private void quit () {
                on_exit (ProcessSignal.TERM);
            }

            private static void on_exit (int signum) {
                poll = false;
                if (thread != null) {
                    thread.join ();
                }
                parent.release () ;
            }

            private void poll_fan () {
                int ret;
                Posix.pollfd[] fan_fd = {};
                fan_fd += Posix.pollfd ();
                fan_fd[0].fd = Posix.open (THERMAL_PATH, Posix.O_RDONLY);
                fan_fd[0].events = Posix.POLLERR | Posix.POLLPRI;
                Posix.read (fan_fd[0].fd, null, 1);
                string content = "";
                while (poll) {
                    ret = Posix.poll (fan_fd, 1000);
                    if (ret > 0) {
                        Posix.read (fan_fd[0].fd, content, 1);
                        Posix.lseek (fan_fd[0].fd, Posix.SEEK_SET, 0);

                        int mode = int.parse (content);
                        if (mode == 0) {
                            show_notification (_ ("Fan set to balanced"));
                        }
                        else if (mode == 1) {
                            show_notification (_ ("Fan set to turbo"));
                        }
                        else if (mode == 2) {
                            show_notification (_ ("Fan set to silent"));
                        }
                    }
                }
            }

            private void execute_manager () {
                try {
                    Process.spawn_command_line_async ("tuf-gui");
                }
                catch (SpawnError e) {
                    warning (e.message);
                }
            }

            private void set_fan_balanced () {
                set_fan_mode (0);
                //show_notification (_ ("Fan set to balanced"));
                settings.set_int ("fan-mode", 0);
            }

            private void set_fan_turbo () {
                set_fan_mode (1);
                //show_notification (_ ("Fan set to turbo"));
                settings.set_int ("fan-mode", 1);
            }

            private void set_fan_silent () {
                set_fan_mode (2);
                //show_notification (_ ("Fan set to silenced"));
                settings.set_int ("fan-mode", 2);
            }

            private void restore () {
                var mode = settings.get_int ("fan-mode");
                if (mode >= 0 && mode <= 2) {
                    if (get_fan_mode () != mode) {
                        set_fan_mode (mode);
                    }
                }

                mode = settings.get_int ("keyboard-mode");
                if (mode >= 0 && mode <= 3) {
                    if (get_keyboard_mode () != mode) {
                        set_keyboard_mode (mode);
                    }
                }

                var speed = settings.get_int ("keyboard-speed");
                if (speed >= 0 && speed <= 2) {
                    if (get_keyboard_speed () != speed) {
                        set_keyboard_speed (speed);
                    }
                }

                var color = settings.get_string ("keyboard-color");
                var rgba = Gdk.RGBA ();
                rgba.parse (color);
                if (!get_keyboard_color ().equal (rgba)) {
                    set_keyboard_color (rgba);
                }
            }

            private void set_icon_visible (bool visible) {
                if (visible) {
                    indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);
                }
                else {
                    indicator.set_status (AppIndicator.IndicatorStatus.PASSIVE);
                }
            }

            private void show_notification (string message) {
                try {
                    close_notification ();
                    notification = new Notify.Notification (_ ("TUF Manager"), message, "tuf-manager");
                    notification.set_timeout (Notify.EXPIRES_DEFAULT);
                    notification.add_action ("default", _ ("Details"), close_notification);
                    notification.show ();
                }
                catch (Error e) {
                    warning (e.message);
                }
            }

            private void close_notification () {
                try {
                    if (notification != null && notification.get_closed_reason () == -1) {
                        notification.close ();
                        notification = null;
                    }
                }
                catch (Error e) {
                    warning (e.message);
                }
            }

            private void on_icon_theme_changed () {
                icon_theme = Gtk.IconTheme.get_default ();
                indicator.set_icon_full ("tuf-manager", "tuf-manager");
            }
        }
    }
}
