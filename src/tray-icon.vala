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
        public class TrayIcon {
            private AppIndicator.Indicator indicator;
            private Notify.Notification notification;
            private Gtk.IconTheme icon_theme;

            public TrayIcon (TUFManagerApp parent) {
                icon_theme = Gtk.IconTheme.get_default ();
                icon_theme.changed.connect (on_icon_theme_changed);

                indicator = new AppIndicator.Indicator (_ ("TUF Manager"), "tuf-manager", AppIndicator.IndicatorCategory.APPLICATION_STATUS);

                var menu = new Gtk.Menu ();
                var item = new Gtk.MenuItem.with_label (_ ("TUF Manager"));
                item.activate.connect (execute_manager);
                menu.append (item);
                item = new Gtk.MenuItem.with_mnemonic (_ ("_Quit"));
                item.activate.connect (parent.release);
                menu.append (item);
                menu.show_all ();

                indicator.set_menu (menu);

                indicator.set_icon_full ("tuf-manager", "tuf-manager");
                indicator.set_title (_ ("TUF Manager"));
                set_icon_visible (true);

                Timeout.add (200, () => {
                    indicator.set_status (AppIndicator.IndicatorStatus.ACTIVE);
                    return false;
                });

                Notify.init (_ ("TUF Manager"));

                //show_notification ("test");
                //update_notification ("test2");
            }

            private void execute_manager () {
                try {
                    Process.spawn_command_line_async ("tuf-gui");
                }
                catch (SpawnError e) {
                    stderr.printf (_ ("Error: %s\n"), e.message);
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

            private void show_notification (string info) {
                try {
                    close_notification ();
                    notification = new Notify.Notification (_ ("TUF Manager"), info, "tuf-manager");
                    notification.set_timeout (Notify.EXPIRES_DEFAULT);
                    notification.add_action ("default", _ ("Details"), execute_manager);
                    notification.show ();
                }
                catch (Error e) {
                    stderr.printf (_ ("Error: %s\n"), e.message);
                }
            }

            private void update_notification (string info) {
                try {
                    if (notification != null) {
                        if (notification.get_closed_reason () == -1 && notification.body != info) {
                            notification.update (_ ("TUF Manager"), info, "tuf-manager");
                            notification.show ();
                        }
                    }
                    else {
                        show_notification (info);
                    }
                }
                catch (Error e) {
                    stderr.printf (_ ("Error: %s\n"), e.message);
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
                    stderr.printf (_ ("Error: %s\n"), e.message);
                }
            }

            private void on_icon_theme_changed () {
                icon_theme = Gtk.IconTheme.get_default ();
                indicator.set_icon_full ("tuf-manager", "tuf-manager");
            }
        }
    }
}
