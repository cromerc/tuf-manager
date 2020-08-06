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
         * The GUI application class
         */
        public class TUFManagerApp : Gtk.Application {
            /**
             * The main application window
             */
            private MainWindow window;

            /**
             * Initialize the application and set it's id
             */
            public TUFManagerApp () {
                application_id = "cl.cromer.tuf.manager";
            }

            /**
             * Run when the application is activated, we call and show the window here
             */
            public override void activate () {
                window = new MainWindow (this);
                window.icon = new Gtk.Image.from_resource ("/cl/cromer/tuf-manager/pixdata/tuf-manager.png").get_pixbuf ();
                window.show_all ();
                window.initialize ();
            }

            /**
             * Run when the application starts, we set the language here
             */
            public override void startup () {
                Intl.textdomain (GETTEXT_PACKAGE);
                Intl.setlocale (LocaleCategory.ALL, "");
                base.startup ();
            }
        }
    }
}
