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
	 * The server namespace contains anything releated to working as a dbus daemon
	 * and handling root related tasks
	 */
	namespace Server {
		/**
		 * The global instance of the server running as a dbus daemon
		 */
		TUFServer tuf_server;
		/**
		 * The loop of the dbus daemon running in the background
		 */
		MainLoop? loop = null;

		/**
		 * Register the bus after the name has been aquired
		 *
		 * @param conn The connection to register with
		 */
		private void on_bus_acquired (DBusConnection conn) {
			try {
				tuf_server = new TUFManager.Server.TUFServer ();
			}
			catch (Error e) {
				stderr.printf ("Error: %s\n", e.message);
			}
			try {
				conn.register_object ("/org/tuf/manager/server", tuf_server);
			}
			catch (IOError e) {
				stderr.printf ("Could not register service\n");
				if (loop != null) {
					loop.quit ();
				}
			}
		}

		/**
		* The TUF Server is a dbus service that runs in the background and uses
		* root priveleges via polkit to make system changes
		*/
		[DBus (name = "org.tuf.manager.server")]
		public class TUFServer : Object {
			private Mutex locked;
			private Mutex authorization;
			private GenericSet<string> authorized_senders;
			private MainContext context;
			public signal void procedure_finished ();

			/**
			 * The server class initialization
			 *
			 * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
			 */
			public TUFServer () throws Error {
				locked = Mutex ();
				authorization = Mutex ();
				authorized_senders = new GenericSet<string> (str_hash, str_equal);
				context = MainContext.ref_thread_default ();
			}

			/**
			 * Get authorization to run root tasks via polkit
			 *
			 * @param sender The bus that sent the request
			 * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
			 */
			private async bool get_authorization (BusName sender) throws Error {
#if ALWAYS_AUTHENTICATED
				return true;
#else
				bool authorized = false;
				authorization.lock ();
				bool fast_authorized = authorized_senders.contains (sender);
				authorization.unlock ();
				if (fast_authorized) {
					var idle = new IdleSource ();
					idle.set_priority (Priority.DEFAULT);
					idle.set_callback (() => {
						return false;
					});
					idle.attach (context);
					return true;
				}
				try {
					Polkit.Authority authority = yield Polkit.Authority.get_async ();
					Polkit.Subject subject = new Polkit.SystemBusName (sender);
					var result = yield authority.check_authorization (
						subject,
						"org.tuf.manager.save",
						null,
						Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION);
					authorized = result.get_is_authorized ();
				}
				catch (Error e) {
					stderr.printf ("Error: %s\n", e.message);
				}
				/*if (!authorized) {
					stderr.printf ("%s\n", _ ("Authentication failed!"));
				}
				else {
					stderr.printf ("%s\n", _ ("Authentication passed!"));
				}*/
				return authorized;
#endif
			}

			/**
			 * Get the version of the currently running server
			 *
			 * @return Returns a string containing the version
			 * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
			 */
			public string get_server_version () throws Error {
				return VERSION;
			}

			/**
			 * Get the current fan mode
			 *
			 * @return Returns the current fan mode
			 * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
			 * @throws TUFError Thrown if there is a problem reading a value from the stream
			 */
			public int get_fan_mode () throws Error, TUFError {
				var stream = FileStream.open (THERMAL_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				var line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				var mode = int.parse (line);
				if (mode < 0 || mode > 2) {
					throw new TUFError.INVALID_VALUE (_ ("File contains invalid value!"));
				}

				return mode;
			}

			/**
			 * Set a new fan mode
			 *
			 *  * 1 - normal mode
			 *  * 2 - boost mode
			 *  * 3 - silent mode
			 *
			 * @param mode The new mode to set
			 * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
			 * @throws TUFError Thrown if there is a problem writing a value to the stream
			 */
			public void set_fan_mode (int mode, BusName sender) throws Error, TUFError {
				get_authorization.begin (sender, (obj, res) => {
					bool authorized = false;
					try {
						authorized = get_authorization.end (res);
					}
					catch (TUFError e) {
						stderr.printf ("Error: %s\n", e.message);
					}
					catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}

					if (authorized) {
						try {
							set_fan_mode_authorized (mode, sender);
						}
						catch (TUFError e) {
							stderr.printf ("Error: %s\n", e.message);
						}
						catch (Error e) {
							stderr.printf ("Error: %s\n", e.message);
						}
					}
					else {
						// Not authorized, so let's end this
						procedure_finished ();
					}
				});
			}

			private void set_fan_mode_authorized (int mode, BusName sender) throws Error, TUFError {
				locked.lock ();
				var stream = FileStream.open (THERMAL_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				if (mode < 0 || mode > 2) {
					locked.unlock ();
					throw new TUFError.INVALID_VALUE (_ ("Invalid value!"));
				}

				stream.puts (mode.to_string ());
				locked.unlock ();
				procedure_finished ();
			}

			public Gdk.RGBA get_keyboard_color () throws Error, TUFError {
				string color = "#";

				// Get red
				var stream = FileStream.open (RED_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				var line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				color += line;

				// Get green
				stream = FileStream.open (GREEN_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				color += line;

				// Get blue
				stream = FileStream.open (BLUE_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				color += line;

				var rgba = Gdk.RGBA ();
				rgba.parse (color);

				return rgba;
			}

			public void set_keyboard_color (Gdk.RGBA color, BusName sender) throws Error, TUFError {
				get_authorization.begin (sender, (obj, res) => {
					bool authorized = false;
					try {
						authorized = get_authorization.end (res);
					}
					catch (TUFError e) {
						stderr.printf ("Error: %s\n", e.message);
					}
					catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}

					if (authorized) {
						try {
							set_keyboard_color_authorized (color, sender);
						}
						catch (TUFError e) {
							stderr.printf ("Error: %s\n", e.message);
						}
						catch (Error e) {
							stderr.printf ("Error: %s\n", e.message);
						}
					}
					else {
						// Not authorized, so let's end this
						procedure_finished ();
					}
				});
			}

			private void set_keyboard_color_authorized (Gdk.RGBA color, BusName sender) throws Error, TUFError {
				locked.lock ();

				var red = "%02x".printf ((uint) (Math.round (color.red * 255))).up ();
				var green = "%02x".printf ((uint) (Math.round (color.green * 255))).up ();
				var blue = "%02x".printf ((uint) (Math.round (color.blue * 255))).up ();
				var keyboard_set = "1";
				var keyboard_flags = "2a";

				var stream = FileStream.open (RED_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (red);

				stream = FileStream.open (GREEN_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (green);

				stream = FileStream.open (BLUE_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (blue);

				stream = FileStream.open (KEYBOARD_FLAGS_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_flags);

				stream = FileStream.open (KEYBOARD_SET_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_set);

				locked.unlock ();
				procedure_finished ();
			}

			public int get_keyboard_mode () throws Error, TUFError {
				var stream = FileStream.open (KEYBOARD_MODE_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				var line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				var mode = int.parse (line);
				if (mode < 0 || mode > 3) {
					throw new TUFError.INVALID_VALUE (_ ("File contains invalid value!"));
				}

				return mode;
			}

			public void set_keyboard_mode (int mode, BusName sender) throws Error, TUFError {
				get_authorization.begin (sender, (obj, res) => {
					bool authorized = false;
					try {
						authorized = get_authorization.end (res);
					}
					catch (TUFError e) {
						stderr.printf ("Error: %s\n", e.message);
					}
					catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}

					if (authorized) {
						try {
							set_keyboard_mode_authorized (mode, sender);
						}
						catch (TUFError e) {
							stderr.printf ("Error: %s\n", e.message);
						}
						catch (Error e) {
							stderr.printf ("Error: %s\n", e.message);
						}
					}
					else {
						// Not authorized, so let's end this
						procedure_finished ();
					}
				});
			}

			private void set_keyboard_mode_authorized (int mode, BusName sender) throws Error, TUFError {
				locked.lock ();
				var keyboard_set = "1";
				var keyboard_flags = "2a";

				var stream = FileStream.open (KEYBOARD_MODE_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				if (mode < 0 || mode > 3) {
					locked.unlock ();
					throw new TUFError.INVALID_VALUE (_ ("Invalid value!"));
				}
				stream.puts (mode.to_string ());

				stream = FileStream.open (KEYBOARD_FLAGS_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_flags);

				stream = FileStream.open (KEYBOARD_SET_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_set);

				locked.unlock ();
				procedure_finished ();
			}

			public int get_keyboard_speed () throws Error, TUFError {
				var stream = FileStream.open (KEYBOARD_SPEED_PATH, "r");
				if (stream == null) {
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				var line = stream.read_line ();
				if (line == null) {
					throw new TUFError.INVALID_VALUE (_ ("File is empty!"));
				}

				var mode = int.parse (line);
				if (mode < 0 || mode > 2) {
					throw new TUFError.INVALID_VALUE (_ ("File contains invalid value!"));
				}

				return mode;
			}

			public void set_keyboard_speed (int speed, BusName sender) throws Error, TUFError {
				get_authorization.begin (sender, (obj, res) => {
					bool authorized = false;
					try {
						authorized = get_authorization.end (res);
					}
					catch (TUFError e) {
						stderr.printf ("Error: %s\n", e.message);
					}
					catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}

					if (authorized) {
						try {
							set_keyboard_speed_authorized (speed, sender);
						}
						catch (TUFError e) {
							stderr.printf ("Error: %s\n", e.message);
						}
						catch (Error e) {
							stderr.printf ("Error: %s\n", e.message);
						}
					}
					else {
						// Not authorized, so let's end this
						procedure_finished ();
					}
				});
			}

			private void set_keyboard_speed_authorized (int speed, BusName sender) throws Error, TUFError {
				locked.lock ();
				var keyboard_set = "1";
				var keyboard_flags = "2a";

				var stream = FileStream.open (KEYBOARD_SPEED_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}

				if (speed < 0 || speed > 2) {
					locked.unlock ();
					throw new TUFError.INVALID_VALUE (_ ("Invalid value!"));
				}
				stream.puts (speed.to_string ());

				stream = FileStream.open (KEYBOARD_FLAGS_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_flags);

				stream = FileStream.open (KEYBOARD_SET_PATH, "w");
				if (stream == null) {
					locked.unlock ();
					throw new TUFError.STREAM (_ ("Failed to open stream!"));
				}
				stream.puts (keyboard_set);

				locked.unlock ();
				procedure_finished ();
			}
		}
	}
}
