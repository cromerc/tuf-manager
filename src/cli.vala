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
	 * The CLI namespace handles all command line related usage
	 */
	namespace CLI {
		public class TUFManagerApp : Application {
#if ALWAYS_AUTHENTICATED
#else
			/**
			 * The subprocess that will contain our tty polkit agent
			 */
			Subprocess? pkttyagent = null;
#endif

			private enum FanMode {
				BALANCED,
				TURBO,
				SILENT
			}

			private enum KeyboardMode {
				STATIC,
				BREATHING,
				COLOR_CYCLE,
				STROBING
			}

			private enum KeyboardSpeed {
				SLOW,
				MEDIUM,
				FAST
			}

			private bool invalid = false;

			private bool help = false;
			private bool info = false;
			private bool version = false;

			private bool fan = false;
			private FanMode? fan_mode = null;

			private bool lighting = false;
			private KeyboardMode? keyboard_mode = null;

			private bool speed = false;
			private KeyboardSpeed? keyboard_speed = null;

			private bool color = false;
			private Gdk.RGBA? rgba = null;

			public TUFManagerApp () {
				Object (application_id: "cl.cromer.tuf.manager", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
				set_inactivity_timeout (1000);
			}

			public override void activate () {
				this.hold ();
				this.release ();
			}

			private int _command_line (ApplicationCommandLine command_line) {
				try {
					connect_dbus ();
				}
				catch (TUFError e) {
					command_line.printerr (_ ("Error: ") + e.message + "\n");
				}

				string[] args = command_line.get_arguments ();

				if (args.length == 1) {
					help = true;
				}
				else if (args.length > 1) {
					switch (args[1]) {
						case "version":
							version = true;
							check_second_argument (args);
							break;
						case "help":
							help = true;
							check_second_argument (args);
							break;
						case "info":
							info = true;
							check_second_argument (args);
							break;
						case "fan":
							fan = true;
							break;
						case "lighting":
							lighting = true;
							break;
						case "speed":
							speed = true;
							break;
						case "color":
							color = true;
							break;
						default:
							invalid = true;
							break;
					}

					if (args.length > 2) {
						if (fan) {
							switch (args[2]) {
								case "balanced":
									fan_mode = FanMode.BALANCED;
									break;
								case "turbo":
									fan_mode = FanMode.TURBO;
									break;
								case "silent":
									fan_mode = FanMode.SILENT;
									break;
								default:
									invalid = true;
									break;
							}
						}

						if (lighting) {
							switch (args[2]) {
								case "static":
									keyboard_mode = KeyboardMode.STATIC;
									break;
								case "breath":
									keyboard_mode = KeyboardMode.BREATHING;
									break;
								case "cycle":
									keyboard_mode = KeyboardMode.COLOR_CYCLE;
									break;
								case "strobe":
									keyboard_mode = KeyboardMode.STROBING;
									break;
								default:
									invalid = true;
									break;
							}
						}

						if (speed) {
							switch (args[2]) {
								case "slow":
									keyboard_speed = KeyboardSpeed.SLOW;
									break;
								case "medium":
									keyboard_speed = KeyboardSpeed.MEDIUM;
									break;
								case "fast":
									keyboard_speed = KeyboardSpeed.FAST;
									break;
								default:
									invalid = true;
									break;
							}
						}

						if (color) {
							try {
								// Make sure it's a valid hex color
								Regex regex = new Regex ("^#[0-9A-F]{6}$");

								if (!regex.match (args[2].up ())) {
									invalid = true;
								}
							}
							catch (RegexError e) {
								command_line.printerr (_ ("Error: ") + e.message + "\n");
							}
							finally {
								rgba = Gdk.RGBA ();
								rgba.parse (args[2]);
							}
						}
					}

					if (fan && fan_mode == null) {
						invalid = true;
					}

					if (lighting && keyboard_mode == null) {
						invalid = true;
					}

					if (speed && keyboard_speed == null) {
						invalid = true;
					}

					if (color && rgba == null) {
						invalid = true;
					}
				}

				if (invalid) {
					command_line.printerr (_ ("Invalid arguments!\n\n"));
					print_usage (command_line);
					release_cli ();
					return 1;
				}
				else if (version) {
					command_line.print (_ ("Version: ") + VERSION + "\n");
					release_cli ();
					return 0;
				}
				else if (help) {
					print_usage (command_line);
					release_cli ();
					return 0;
				}
				else if (info) {
					command_line.print (_ ("Client version: ") + VERSION + "\n");
					command_line.print (_ ("Server version: ") + get_server_version () + "\n");
					var current_setting = get_fan_mode ();
					switch (current_setting) {
						case 0:
							command_line.print (_ ("Current fan mode: Balanced\n"));
							break;
						case 1:
							command_line.print (_ ("Current fan mode: Turbo\n"));
							break;
						case 2:
							command_line.print (_ ("Current fan mode: Silent\n"));
							break;
						default:
							command_line.printerr (_ ("Error: Could not get current fan mode!\n"));
							break;
					}
					current_setting = get_keyboard_mode ();
					switch (current_setting) {
						case 0:
							command_line.print (_ ("Current keyboard lighting: Static\n"));
							break;
						case 1:
							command_line.print (_ ("Current keyboard lighting: Breathing\n"));
							break;
						case 2:
							command_line.print (_ ("Current keyboard lighting: Color Cycle\n"));
							break;
						case 3:
							command_line.print (_ ("Current keyboard lighting: Strobing\n"));
							break;
						default:
							command_line.printerr (_ ("Error: Could not get current keyboard mode!\n"));
							break;
					}
					current_setting = get_keyboard_speed ();
					switch (current_setting) {
						case 0:
							command_line.print (_ ("Current keyboard speed: Slow\n"));
							break;
						case 1:
							command_line.print (_ ("Current keyboard speed: Medium\n"));
							break;
						case 2:
							command_line.print (_ ("Current keyboard speed: Fast\n"));
							break;
						default:
							command_line.printerr (_ ("Error: Could not get current fan mode!\n"));
							break;
					}
					var current_color = get_keyboard_color ();
					var color_hex = "#%02x%02x%02x".printf (
						(uint) (Math.round (current_color.red * 255)),
						(uint) (Math.round (current_color.green * 255)),
						(uint) (Math.round (current_color.blue * 255))
					).up ();
					command_line.print (_ ("Current keyboard color: " + color_hex + "\n"));
					release_cli ();
					return 0;
				}
				else if (fan) {
#if ALWAYS_AUTHENTICATED
					int mode = fan_mode;
					tuf_server.procedure_finished.connect (release_cli);
					set_fan_mode (mode);
#else
					try {
						pkttyagent = new Subprocess.newv ({"pkttyagent"}, SubprocessFlags.NONE);
						Timeout.add (200, () => {
							int mode = fan_mode;
							tuf_server.procedure_finished.connect (release_cli);
							set_fan_mode (mode);
							return false;
						});
					}
					catch (Error e) {
						command_line.printerr (_ ("Error: ") + e.message + "\n");
					}
#endif

					return 0;
				}
				else if (lighting) {
#if ALWAYS_AUTHENTICATED
					int mode = keyboard_mode;
					tuf_server.procedure_finished.connect (release_cli);
					set_keyboard_mode (mode);
#else
					try {
						pkttyagent = new Subprocess.newv ({"pkttyagent"}, SubprocessFlags.NONE);

						Timeout.add (200, () => {
							int mode = keyboard_mode;
							tuf_server.procedure_finished.connect (release_cli);
							set_keyboard_mode (mode);
							return false;
						});
					}
					catch (Error e) {
						command_line.printerr (_ ("Error: ") + e.message + "\n");
					}
#endif
					return 0;
				}
				else if (speed) {
#if ALWAYS_AUTHENTICATED
					int set_speed = keyboard_speed;
					tuf_server.procedure_finished.connect (release_cli);
					set_keyboard_speed (set_speed);
#else
										try {
											pkttyagent = new Subprocess.newv ({"pkttyagent"}, SubprocessFlags.NONE);

											Timeout.add (200, () => {
												int set_speed = keyboard_speed;
												tuf_server.procedure_finished.connect (release_cli);
												set_keyboard_speed (set_speed);
												return false;
											});
										}
										catch (Error e) {
											command_line.printerr (_ ("Error: ") + e.message + "\n");
										}
					#endif
										return 0;
				}
				else if (color) {
#if ALWAYS_AUTHENTICATED
					tuf_server.procedure_finished.connect (release_cli);
					set_keyboard_color (rgba);
#else
					try {
						pkttyagent = new Subprocess.newv ({"pkttyagent"}, SubprocessFlags.NONE);

						Timeout.add (200, () => {
							tuf_server.procedure_finished.connect (release_cli);
							set_keyboard_color (rgba);
							return false;
						});
					}
					catch (Error e) {
						command_line.printerr (_ ("Error: ") + e.message + "\n");
					}
#endif
					return 0;
				}
				return 0;
			}

			private void check_second_argument (string[] args) {
				if (args.length > 2) {
					invalid = true;
				}
			}

			private void print_usage (ApplicationCommandLine command_line) {
				command_line.print ("Usage: tuf-cli COMMAND [SUBCOMMAND] ...\n\n");
				command_line.print ("  version                                    Print the version of tuf-cli\n");
				command_line.print ("  help                                       Show this help screen\n");
				command_line.print ("  fan [balanced, turbo, silent]              Set the fan mode\n");
				command_line.print ("  lighting [static, breath, cycle, stobe]    Set the keyboard lighting\n");
				command_line.print ("  speed [slow, medium, fast]                 Set the keyboard lighting speed\n");
				command_line.print ("  color [\"#XXXXXX\"]                          Set the keyboard color\n");
				command_line.print ("  info                                       Show the current config\n\n");
				command_line.print ("Examples:\n");
				command_line.print ("  Silence fan: tuf-cli fan silent\n");
				command_line.print ("  Change RGB color: tuf-cli color \"#FF0000\"\n");
			}

			/**
			 * This method releases the command line program from it's loop
			 */
			public void release_cli () {
#if ALWAYS_AUTHENTICATED
#else
				if (pkttyagent != null) {
					pkttyagent.force_exit ();
				}
#endif
				this.release ();
			}

			public override int command_line (ApplicationCommandLine command_line) {
				// keep the application running until we are done with this commandline
				this.hold ();
				int res = _command_line (command_line);
				return res;
			}
		}
	}
}
