/*/
*- Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.ShortcutEntry : Gtk.TreeView {
    private Gtk.CellRendererAccel cell_edit;
    public signal void shortcut_changed (string new_shortcut);

    public ShortcutEntry (string accel) {
        var shortcut = new Shortcut.parse (accel);

        cell_edit = new Gtk.CellRendererAccel ();
        cell_edit.editable = true;
        insert_column_with_attributes (-1, null, cell_edit, "text", 0);
        headers_visible = false;
        get_column (0).expand = true;

        cell_edit.accel_edited.connect ((path, key, mods) => {
            var new_shortcut = new Shortcut (key, mods);
            change_shortcut (path, new_shortcut);
            shortcut_changed (new_shortcut.to_gsettings ());
        });

        Gtk.TreeIter iter;
        var store = new Gtk.ListStore (1, typeof (string));
        store.append (out iter);
        store.set (iter, 0, shortcut.to_readable ());

        model = store;
    }

    private void change_shortcut (string path, Shortcut ? shortcut) {
        Gtk.TreeIter iter;

        model.get_iter (out iter, new Gtk.TreePath.from_string (path));
        var ls = (model as Gtk.ListStore);
        if (ls != null) {
            ls.set (iter, 0, shortcut.to_readable ());
        }
    }

    public void activate () {
        // cell_edit.activate ();
    }
}

class Shortcut : GLib.Object {
    public Gdk.ModifierType modifiers;
    public uint accel_key;

    string SEPARATOR = " · ";

    public Shortcut (uint key = 0, Gdk.ModifierType mod = (Gdk.ModifierType) 0) {
        accel_key = key;
        modifiers = mod;
    }

    public Shortcut.parse (string ? str) {
        if (str == null) {
            accel_key = 0;
            modifiers = (Gdk.ModifierType) 0;
            return;
        }

        Gtk.accelerator_parse (str, out accel_key, out modifiers);
    }

    public string to_gsettings () {
        if (!valid ())
            return "";
        return Gtk.accelerator_name (accel_key, modifiers);
    }

    public string to_readable () {
        if (!valid ())
            return _ ("Disabled");

        string tmp = "";

        if ((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0)
            tmp += "⇧" + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.SUPER_MASK) > 0)
            tmp += "⌘" + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0)
            tmp += _ ("Ctrl") + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.MOD1_MASK) > 0)
            tmp += "⎇" + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.MOD2_MASK) > 0)
            tmp += "Mod2" + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.MOD3_MASK) > 0)
            tmp += "Mod3" + SEPARATOR;
        if ((modifiers & Gdk.ModifierType.MOD4_MASK) > 0)
            tmp += "Mod4" + SEPARATOR;

        switch (accel_key) {
        case Gdk.Key.Tab :
            tmp += "↹";
            break;
        case Gdk.Key.Up :
            tmp += "↑";
            break;
        case Gdk.Key.Down :
            tmp += "↓";
            break;
        case Gdk.Key.Left :
            tmp += "←";
            break;
        case Gdk.Key.Right :
            tmp += "→";
            break;
        default :
            tmp += Gtk.accelerator_get_label (accel_key, 0);
            break;
        }

        return tmp;
    }

    public bool valid () {
        if (accel_key == 0 || (modifiers == (Gdk.ModifierType) 0 && accel_key != Gdk.Key.Print))
            return false;

        if (modifiers == Gdk.ModifierType.SHIFT_MASK) {
            if ((accel_key >= Gdk.Key.a                    && accel_key <= Gdk.Key.z)
                || (accel_key >= Gdk.Key.A                    && accel_key <= Gdk.Key.Z)
                || (accel_key >= Gdk.Key.@0                   && accel_key <= Gdk.Key.@9)
                || (accel_key >= Gdk.Key.kana_fullstop        && accel_key <= Gdk.Key.semivoicedsound)
                || (accel_key >= Gdk.Key.Arabic_comma         && accel_key <= Gdk.Key.Arabic_sukun)
                || (accel_key >= Gdk.Key.Serbian_dje          && accel_key <= Gdk.Key.Cyrillic_HARDSIGN)
                || (accel_key >= Gdk.Key.Greek_ALPHAaccent    && accel_key <= Gdk.Key.Greek_omega)
                || (accel_key >= Gdk.Key.hebrew_doublelowline && accel_key <= Gdk.Key.hebrew_taf)
                || (accel_key >= Gdk.Key.Thai_kokai           && accel_key <= Gdk.Key.Thai_lekkao)
                || (accel_key >= Gdk.Key.Hangul               && accel_key <= Gdk.Key.Hangul_Special)
                || (accel_key >= Gdk.Key.Hangul_Kiyeog        && accel_key <= Gdk.Key.Hangul_J_YeorinHieuh)
                || (accel_key == Gdk.Key.Home)
                || (accel_key == Gdk.Key.Left)
                || (accel_key == Gdk.Key.Up)
                || (accel_key == Gdk.Key.Right)
                || (accel_key == Gdk.Key.Down)
                || (accel_key == Gdk.Key.Page_Up)
                || (accel_key == Gdk.Key.Page_Down)
                || (accel_key == Gdk.Key.End)
                || (accel_key == Gdk.Key.Tab)
                || (accel_key == Gdk.Key.KP_Enter)
                || (accel_key == Gdk.Key.Return)) {
                return false;
            }
        }

        return true;
    }
}
