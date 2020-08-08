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
     * The GUI namespace contains a GTK based interface to interact with the TUF laptop
     */
    namespace GUI {
        /**
         * The main window to show to the user
         */
        [GtkTemplate (ui = "/cl/cromer/tuf-manager/tuf.manager.window.ui")]
        public class MainWindow : Gtk.ApplicationWindow {
            /**
             * This is used to make sure that the sysfs files are not written to until everything is initialized
             */
            private bool initialized = false;

            /**
             * The settings object from gschema/dconf
             */
            private Settings settings;

            /**
             * The fan mode combo box
             */
            [GtkChild]
            private Gtk.ComboBoxText fan_mode;

            /**
             * They keyboard mode combo box
             */
            [GtkChild]
            private Gtk.ComboBoxText keyboard_mode;

            /**
             * The keyboard speed combox box
             */
            [GtkChild]
            private Gtk.ComboBoxText keyboard_speed;

            /**
             * The color chooser widget
             */
            [GtkChild]
            private Gtk.ColorChooserWidget keyboard_color;

            /**
             * The restore switch
             */
            [GtkChild]
            private Gtk.Switch restore_settings;

            /**
             * The notifications switch
             */
            [GtkChild]
            private Gtk.Switch notifications;

            /**
             * Create the main window
             * @param application The application used to make the GLib object
             */
            public MainWindow (Gtk.Application application) {
                Object (application: application);
            }

            /**
             * This is called after the window is created to initialize it's interface
             */
            public void initialize () {
                settings = new Settings ("org.tuf.manager");
                try {
                    connect_tuf_server ();
                }
                catch (TUFError e) {
                    warning (e.message);
                    if (e.code == TUFError.UNMATCHED_VERSIONS) {
                        Gtk.MessageDialog msg;
                        msg = new Gtk.MessageDialog (this,
                            Gtk.DialogFlags.MODAL,
                            Gtk.MessageType.ERROR,
                            Gtk.ButtonsType.CLOSE,
                            _ ("The current running tuf-server version doesn't match the GUI version!"));
                        msg.response.connect ((response_id) => {
                            msg.destroy ();
                            this.close ();
                        });
                        msg.show ();
                    }
                }
                finally {
                    print (_ ("Client version: ") + VERSION + "\n");
                    print (_ ("Server version: ") + get_server_version () + "\n");

                    if (settings.get_boolean ("notifications")) {
                        notifications.set_active (true);
                    }

                    if (settings.get_boolean ("restore")) {
                        restore_settings.set_active (true);
                        restore ();
                    }
                    else {
                        // Get the fan speed
                        var mode = get_fan_mode ();
                        if (mode >= 0) {
                            fan_mode.set_active (mode);
                            print (_ ("Current fan mode: ") + fan_mode.get_active_text () + "\n");
                        }
                        else {
                            warning (_ ("Could not get current fan mode!"));
                        }

                        // Get the keyboard mode
                        mode = get_keyboard_mode ();
                        if (mode >= 0) {
                            keyboard_mode.set_active (mode);
                            if (mode == 2) {
                                keyboard_color.sensitive = false;
                            }
                            if (mode == 0 || mode == 3) {
                                keyboard_speed.sensitive = false;
                            }
                            print (_ ("Current keyboard mode: ") + keyboard_mode.get_active_text () + "\n");
                        }
                        else {
                            warning (_ ("Could not get current keyboard mode!"));
                        }

                        // Get the keyboard speed
                        var speed = get_keyboard_speed ();
                        if (speed >= 0) {
                            keyboard_speed.set_active (mode);
                            print (_ ("Current keyboard speed: ") + keyboard_speed.get_active_text () + "\n");
                        }
                        else {
                            warning (_ ("Could not get current keyboard speed!"));
                        }

                        // Get the keyboard color
                        var color = get_keyboard_color ();
                        keyboard_color.set_rgba (color);
                        print (_ ("Current keyboard color: ") + color.to_string () + "\n");
                    }

                    initialized = true;
                }
            }

            /**
             * Used to restore the previous config from donf
             * TODO: Move this to a status bar app and/or user daemon
             */
            private void restore () {
                var mode = settings.get_int ("fan-mode");
                if (mode >= 0 && mode <= 2) {
                    if (get_fan_mode () != mode) {
                        set_fan_mode (mode);
                    }
                    fan_mode.set_active (mode);
                }
                print (_ ("Current fan mode: ") + fan_mode.get_active_text () + "\n");

                mode = settings.get_int ("keyboard-mode");
                if (mode >= 0 && mode <= 3) {
                    if (get_keyboard_mode () != mode) {
                        set_keyboard_mode (mode);
                    }
                    keyboard_mode.set_active (mode);
                    if (mode == 2) {
                        keyboard_color.sensitive = false;
                    }
                    if (mode == 0 || mode == 3) {
                        keyboard_speed.sensitive = false;
                    }
                }
                print (_ ("Current keyboard mode: ") + keyboard_mode.get_active_text () + "\n");

                var speed = settings.get_int ("keyboard-speed");
                if (speed >= 0 && speed <= 2) {
                    if (get_keyboard_speed () != speed) {
                        set_keyboard_speed (speed);
                    }
                    keyboard_speed.set_active (speed);
                }
                print (_ ("Current keyboard speed: ") + keyboard_speed.get_active_text () + "\n");

                var color = settings.get_string ("keyboard-color");
                var rgba = Gdk.RGBA ();
                rgba.parse (color);
                if (!get_keyboard_color ().equal (rgba)) {
                    set_keyboard_color (rgba);
                }
                keyboard_color.set_rgba (rgba);
                print (_ ("Current keyboard color: ") + color.to_string () + "\n");
            }

            /**
             * Called when the user changes the fan mode
             *
             * @param combo_box The combo box that changed
             */
            [GtkCallback]
            public void on_fan_mode_changed (Gtk.ComboBox combo_box) {
                if (initialized) {
                    int mode = combo_box.get_active ();
                    set_fan_mode (mode);

                    settings.set_int ("fan-mode", mode);
                }
            }

            /**
             * Called when the user changes the keyboard lighting mode
             *
             * @param combo_box The combo box that changed
             */
            [GtkCallback]
            public void on_keyboard_mode_changed (Gtk.ComboBox combo_box) {
                if (initialized) {
                    int mode = combo_box.get_active ();
                    if (mode == 2) {
                        keyboard_color.sensitive = false;
                    }
                    else {
                        keyboard_color.sensitive = true;
                    }
                    if (mode == 1 || mode == 2) {
                        keyboard_speed.sensitive = true;
                    }
                    else {
                        keyboard_speed.sensitive = false;
                    }
                    set_keyboard_mode (mode);

                    settings.set_int ("keyboard-mode", mode);
                }
            }

            /**
             * Called when the user changes the keyboard lighting speed
             *
             * @param combo_box The combo box that changed
             */
            [GtkCallback]
            public void on_speed_changed (Gtk.ComboBox combo_box) {
                if (initialized) {
                    int speed = combo_box.get_active ();
                    set_keyboard_speed (speed);

                    settings.set_int ("keyboard-speed", speed);
                }
            }

            /**
             * Called when the user clicks the set color button
             *
             * @param button The button that was clicked
             */
            [GtkCallback]
            public void on_set_color_clicked (Gtk.Button button) {
                if (initialized) {
                    Gdk.RGBA rgba = keyboard_color.get_rgba ();

                    set_keyboard_color (rgba);
                    settings.set_string ("keyboard-color", rgba.to_string ());
                }
            }

            /**
             * Called when the user clicks the restore settings switch
             *
             * @param gtk_switch The switch that was clicked
             * @param switched The new state of the switch
             */
            [GtkCallback]
            public bool on_restore_settings_state_set (Gtk.Switch gtk_switch, bool switched) {
                if (switched) {
                    settings.set_boolean ("restore", true);
                }
                else {
                    settings.set_boolean ("restore", false);
                }
                return false;
            }

            /**
             * Called when the user clicks the notifications switch
             *
             * @param gtk_switch The switch that was clicked
             * @param switched The new state of the switch
             */
            [GtkCallback]
            public bool on_notifications_state_set (Gtk.Switch gtk_switch, bool switched) {
                if (switched) {
                    settings.set_boolean ("notifications", true);
                }
                else {
                    settings.set_boolean ("notifications", false);
                }
                return false;
            }
        }
    }
}
