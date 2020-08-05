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
		private static bool foreground = false;

		private const OptionEntry[] options = {
			{ "foreground", 'f', 0, OptionArg.NONE, ref foreground, N_ ("Run the daemon in the foreground"), null },
			{ null }
		};

		private static void on_exit (int signum) {
			if (loop != null) {
				loop.quit ();
			}
		}

		/**
		 * The entry point to the server launches a system dbus daemon
		 *
		 * @param args Arguments passed from the command line
		 * @return Returns 0 on success
		 */
		public static int main (string[] args) {
			Intl.setlocale (LocaleCategory.ALL, "");
			Intl.bindtextdomain (GETTEXT_PACKAGE, "/usr/share/locale");
			Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (GETTEXT_PACKAGE);

			try {
				var opt_context = new OptionContext ("");
				opt_context.set_translation_domain (GETTEXT_PACKAGE);
				opt_context.set_help_enabled (true);
				opt_context.add_main_entries (options, null);
				opt_context.parse (ref args);
			}
			catch (OptionError e) {
				print (_ ("Error: %s\n"), e.message);
				print (_ ("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
				return 1;
			}

			if (!foreground) {
				var pid = Posix.fork ();
				if (pid < 0) {
					Posix.exit (Posix.EXIT_FAILURE);
				}
				else if (pid > 0) {
					Posix.exit (Posix.EXIT_SUCCESS);
				}

				Posix.umask (0);

				var sid = Posix.setsid ();
				if (sid < 0) {
					Posix.exit (Posix.EXIT_FAILURE);
				}

				if (Posix.chdir ("/") < 0) {
					Posix.exit (Posix.EXIT_FAILURE);
				}
			}

			Process.signal (ProcessSignal.INT, on_exit);
			Process.signal (ProcessSignal.TERM, on_exit);

			Bus.own_name (BusType.SYSTEM,
				"org.tuf.manager.server",
				BusNameOwnerFlags.NONE,
				on_bus_acquired,
				() => {},
				() => {
					stderr.printf (_ ("Could not acquire bus name\n"));
				});

			loop = new MainLoop ();
			loop.run ();

			return 0;
		}
	}
}
