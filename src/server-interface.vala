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
     * This interface defines the dbus daemon provided by the server
     */
    [DBus (name = "org.tuf.manager.server")]
    public interface TUFServerInterface : Object {
        /**
         * This signal is emited when a procedure finishes
         */
        public signal void procedure_finished ();

        /**
         * Get the version of the currently running server
         *
         * @return Returns a string containing the version
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         */
        public abstract string get_server_version () throws Error;

        /**
         * Get the current fan mode
         *
         * @return Returns the current fan mode
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem reading a value from the stream
         */
        public abstract int get_fan_mode () throws Error, TUFError;

        /**
         * Set a new fan mode
         *
         *  * 0 - balanced mode
         *  * 1 - turbo mode
         *  * 2 - silent mode
         *
         * @param mode The new mode to set
         * @param sender The bus that sent the request
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract void set_fan_mode (int mode, BusName sender) throws Error, TUFError;

        /**
         * Get the current keyboard color
         *
         * @return Returns an RGBA struct containing the color
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract Gdk.RGBA get_keyboard_color ()  throws Error, TUFError;

        /**
         * Set the keyboard color
         *
         * @param color The new RGBA color to set
         * @param sender The bus that sent the request
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract void set_keyboard_color (Gdk.RGBA color, BusName sender) throws Error, TUFError;

        /**
         * Get the current keyboard mode
         *
         * @return Returns the mode
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract int get_keyboard_mode () throws Error, TUFError;

        /**
         * Set a new keyboard mode
         *
         *  * 0 - static
         *  * 1 - breathing
         *  * 2 - color cycle
         *  * 3 - strobing
         *
         * @param mode The new mode to set
         * @param sender The bus that sent the request
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract void set_keyboard_mode (int mode, BusName sender) throws Error, TUFError;

        /**
         * Get the current keyboard lighting speed
         *
         * @return The current speed
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract int get_keyboard_speed () throws Error, TUFError;

        /**
         * Set a new keyboard speed
         *
         *  * 0 - slow
         *  * 1 - medium
         *  * 2 - fast
         *
         * @param speed The new speed to set
         * @param sender The bus that sent the request
         * @throws Error Thrown if there is a problem connecting to a dbus session or an IO error
         * @throws TUFError Thrown if there is a problem writing a value to the stream
         */
        public abstract void set_keyboard_speed (int speed, BusName sender) throws Error, TUFError;
    }
}
