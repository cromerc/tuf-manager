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
     * The TUF Server interface that is running in the background
     */
    private TUFServerInterface tuf_server;

    /**
     * The bus name to send to the server to identify itself
     */
    private BusName bus_name;

    /**
     * Connect to the TUF Server daemon via dbus
     *
     * @throws TUFError Thrown when the server and the client versions don't match
     */
    private void connect_tuf_server () throws TUFError {
        bus_name = new BusName ("org.tuf.manager");

        try {
            tuf_server = Bus.get_proxy_sync (BusType.SYSTEM, "org.tuf.manager.server", "/org/tuf/manager/server");
        }
        catch (IOError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }

        string? server_version = get_server_version ();
        if (server_version == null) {
            return;
        }

        if (server_version != VERSION) {
            throw new TUFError.UNMATCHED_VERSIONS (_ ("The server and client versions do not match!"));
        }
    }

    /**
     * Get the server version from the running daemon
     *
     * @return Returns a string containing the server version or null on failure
     */
    private string? get_server_version () {
        try {
            return tuf_server.get_server_version ();
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        return null;
    }

    /**
     * Get the mode the fan is in
     *
     * @return Returns the fan mode or -3 on error
     */
    private int get_fan_mode () {
        try {
            return tuf_server.get_fan_mode ();
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        return -3;
    }

    /**
     * Set the fan mode
     *
     * @param mode The new mode to set
     */
    private void set_fan_mode (int mode) {
        try {
            tuf_server.set_fan_mode (mode, bus_name);
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
    }

    /**
     * Get the current keyboard color
     *
     * @return Returns an RGBA struct containing the keyboard color or an initialized RGBA struct on error
     */
    private Gdk.RGBA get_keyboard_color () {
        try {
            return tuf_server.get_keyboard_color ();
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        return Gdk.RGBA ();
    }

    /**
     * Set a new keyboard color
     *
     * @param color An RGBA struct containing the new color to set
     */
    private void set_keyboard_color (Gdk.RGBA color) {
        try {
            tuf_server.set_keyboard_color (color, bus_name);
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
    }

    /**
     * Get the current lighting mode of the keyboard
     *
     * @return Returns the current keyboard lighting mode or -3 on error
     */
    private int get_keyboard_mode () {
        try {
            return tuf_server.get_keyboard_mode ();
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        return -3;
    }

    /**
     * Set the keyboard lighting mode
     *
     * @param mode The new mode to set for the keyboard lighting
     */
    private void set_keyboard_mode (int mode) {
        try {
            tuf_server.set_keyboard_mode (mode, bus_name);
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
    }

    /**
     * Get the current keyboard lighting speed
     *
     * @return Returns the current speed or -3 on error
     */
    private int get_keyboard_speed () {
        try {
            return tuf_server.get_keyboard_speed ();
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        return -3;
    }

    /**
     * Set a new keyboard lighting speed
     *
     * @param speed The new speed to set
     */
    private void set_keyboard_speed (int speed) {
        try {
            tuf_server.set_keyboard_speed (speed, bus_name);
        }
        catch (TUFError e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
        catch (Error e) {
            stderr.printf (_ ("Error: %s\n"), e.message);
        }
    }
}
