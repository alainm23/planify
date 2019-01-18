// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Maya Developers (https://launchpad.net/maya)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

// This is needed in order to have good placement for widgets
public class Maya.PlacementWidget : GLib.Object {

    ~PlacementWidget () {
        widget.destroy ();
    }

    public Gtk.Widget widget;
    public int row = 0;
    public int column = 0;
    public string ref_name;
    public bool needed = false; // Only usefull for Gtk.Entry and his derivates
}

namespace Maya.DefaultPlacementWidgets {
    public Gee.LinkedList<Maya.PlacementWidget> get_user (int row, bool needed = true, string entry_text = "", string? ph_text = null) {
        var collection = new Gee.LinkedList<Maya.PlacementWidget> ();
        var user_label = new PlacementWidget ();
        user_label.widget = new Gtk.Label (_("User:"));
        ((Gtk.Misc) user_label.widget).xalign = 1.0f;
        user_label.row = row;
        user_label.column = 0;
        user_label.ref_name = "user_label";
        collection.add (user_label);

        var user_entry = new PlacementWidget ();
        user_entry.widget = new Gtk.Entry ();
        ((Gtk.Entry)user_entry.widget).placeholder_text = ph_text?? _("user.name");
        user_entry.row = row;
        user_entry.column = 1;
        user_entry.ref_name = "user_entry";
        user_entry.needed = needed;
        ((Gtk.Entry)user_entry.widget).text = entry_text;
        collection.add (user_entry);
        return collection;
    }

    public Gee.LinkedList<Maya.PlacementWidget> get_email (int row, bool needed = true, string entry_text = "", string? ph_text = null) {
        var collection = new Gee.LinkedList<Maya.PlacementWidget> ();
        var user_label = new PlacementWidget ();
        user_label.widget = new Gtk.Label (_("Email:"));
        ((Gtk.Misc) user_label.widget).xalign = 1.0f;
        user_label.row = row;
        user_label.column = 0;
        user_label.ref_name = "email_label";
        collection.add (user_label);

        var user_entry = new PlacementWidget ();
        user_entry.widget = new Gtk.Entry ();
        ((Gtk.Entry)user_entry.widget).placeholder_text = ph_text?? _("john@doe.com");
        user_entry.row = row;
        user_entry.column = 1;
        user_entry.ref_name = "email_entry";
        user_entry.needed = needed;
        ((Gtk.Entry)user_entry.widget).text = entry_text;
        collection.add (user_entry);
        return collection;
    }

    public Maya.PlacementWidget get_keep_copy (int row, bool default_value = false) {
        var keep_check = new PlacementWidget ();
        keep_check.widget = new Gtk.CheckButton.with_label (_("Keep a copy locally"));
        ((Gtk.CheckButton)keep_check.widget).active = default_value;
        keep_check.row = row;
        keep_check.column = 1;
        keep_check.ref_name = "keep_copy";
        return keep_check;
    }
}
