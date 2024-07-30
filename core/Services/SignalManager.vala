/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Services.SignalManager : GLib.Object {
    static GLib.Once<Services.SignalManager> _instance;
    public static unowned Services.SignalManager instance () {
        return _instance.once (() => {
            return new Services.SignalManager ();
        });
    }

    private Gee.HashMap<GLib.Object, Gee.ArrayList<ulong>> signal_map = new Gee.HashMap<GLib.Object, Gee.ArrayList<ulong>> ();

    public ulong connect_signal (GLib.Object obj, ulong signal_id) {
        add_signal_id (obj, signal_id);
        return signal_id;
    }

    private void add_signal_id (GLib.Object obj, ulong signal_id) {
        if (signal_map.has_key (obj)) {
            signal_map[obj].add(signal_id);
        } else {
            Gee.ArrayList<ulong> signal_list = new Gee.ArrayList<ulong>();
            signal_list.add(signal_id);
            signal_map.set(obj, signal_list);
        }
    }

    public void disconnect_signals (GLib.Object obj) {
        if (signal_map.has_key (obj)) {
            foreach (ulong signal_id in signal_map[obj]) {
                print ("signal_id: %s\n".printf (signal_id.to_string ()));
                obj.disconnect (signal_id);
            }
        }
    }

    public void disconnect_all_signals () {
        foreach (GLib.Object obj_key in signal_map.keys) {
            disconnect_signals (obj_key);
        }

        signal_map.clear ();
    }
}