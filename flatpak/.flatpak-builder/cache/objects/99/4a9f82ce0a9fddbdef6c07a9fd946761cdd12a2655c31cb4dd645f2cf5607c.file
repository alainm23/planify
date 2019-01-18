// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.LocationPanel : Gtk.Grid {
    private EventDialog parent_dialog;

    private Gtk.SearchEntry location_entry;
    private Gtk.EntryCompletion location_completion;
    private Gtk.ListStore location_store;
    private GtkChamplain.Embed champlain_embed;
    private Maya.Marker point;
     // Only set the geo property if map_selected is true, this is a smart behavior!
    private bool map_selected = false;
    private GLib.Cancellable search_cancellable;
    private GLib.Cancellable find_cancellable;

    public string location {
        get { return location_entry.get_text (); }
        set { location_entry.set_text (value); }
    }

    public LocationPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        margin_start = 12;
        margin_end = 12;
        set_row_spacing (6);
        set_column_spacing (12);
        set_sensitive (parent_dialog.can_edit);

        location_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        var location_label = Maya.View.EventDialog.make_label (_("Location:"));
        location_entry = new Gtk.SearchEntry ();
        location_entry.placeholder_text = _("John Smith OR Example St.");
        location_entry.hexpand = true;
        location_entry.activate.connect (() => {compute_location.begin (location_entry.text);});
        attach (location_label, 0, 0, 1, 1);
        attach (location_entry, 0, 1, 1, 1);

        location_completion = new Gtk.EntryCompletion ();
        location_completion.set_minimum_key_length (3);
        location_entry.set_completion (location_completion);

        location_completion.set_match_func ((completion, key, iter) => {
            Value val1, val2;
            Gtk.ListStore model = (Gtk.ListStore)completion.get_model ();
            model.get_value (iter, 0, out val1);
            model.get_value (iter, 1, out val2);

            if (val1.get_string ().casefold (-1).contains (key) || val2.get_string ().casefold (-1).contains (key)) {
                return true;
            }

            return false;
        });
        location_completion.set_model (location_store);
        location_completion.set_text_column (0);
        location_completion.set_text_column (1);
        location_completion.match_selected.connect ((model, iter) => suggestion_selected (model, iter));

        champlain_embed = new GtkChamplain.Embed ();
        var view = champlain_embed.champlain_view;
        var marker_layer = new Champlain.MarkerLayer.full (Champlain.SelectionMode.SINGLE);
        view.add_layer (marker_layer);

        load_contact.begin ();

        var frame = new Gtk.Frame (null);
        frame.add (champlain_embed);

        attach (frame, 0, 2, 1, 1);

        // Load the location
        point = new Maya.Marker ();
        point.draggable = parent_dialog.can_edit;
        point.drag_finish.connect (() => {
            map_selected = true;
            find_location.begin (point.latitude, point.longitude);
        });

        if (parent_dialog.ecal != null) {
            unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            unowned string location = comp.get_location ();

            if (location != null) {
                location_entry.text = location.dup ();
            }

            iCal.GeoType? geo;
            parent_dialog.ecal.get_geo (out geo);
            bool need_relocation = true;
            if (geo != null) {
                if (geo.latitude >= Champlain.MIN_LATITUDE && geo.longitude >= Champlain.MIN_LONGITUDE &&
                    geo.latitude <= Champlain.MAX_LATITUDE && geo.longitude <= Champlain.MAX_LONGITUDE) {
                    need_relocation = false;
                    point.latitude = geo.latitude;
                    point.longitude = geo.longitude;
                    if (geo.latitude == 0 && geo.longitude == 0)
                        need_relocation = true;
                }
            }

            if (need_relocation == true) {
                if (location != null && location != "") {
                    compute_location.begin (location_entry.text);
                } else {
                    // Use geoclue to find approximate location
                    discover_location.begin ();
                }
            }
        }

        view.zoom_level = 10;
        view.goto_animation_duration = 500;
        view.center_on (point.latitude, point.longitude);
        marker_layer.add_marker (point);

        destroy.connect (() => {
            if (search_cancellable != null)
                search_cancellable.cancel ();
            if (find_cancellable != null) {
                find_cancellable.cancel ();
            }
        });
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        // Save the location
        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        string location = location_entry.text;

        comp.set_location (location);
        if (map_selected == true) {
            // First, clear the geo
            int count = comp.count_properties (iCal.PropertyKind.GEO);

            for (int i = 0; i < count; i++) {
                unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.GEO);
                comp.remove_property (remove_prop);
            }

            // Add the comment
            var property = new iCal.Property (iCal.PropertyKind.GEO);
            iCal.GeoType geo = {0, 0};
            geo.latitude = (float)point.latitude;
            geo.longitude = (float)point.longitude;
            property.set_geo (geo);
            comp.add_property (property);
        }
    }

    private async void compute_location (string loc) {
        if (search_cancellable != null)
            search_cancellable.cancel ();
        search_cancellable = new GLib.Cancellable ();
        var forward = new Geocode.Forward.for_string (loc);
        try {
            forward.set_answer_count (1);
            var places = yield forward.search_async (search_cancellable);
            foreach (var place in places) {
                point.latitude = place.location.latitude;
                point.longitude = place.location.longitude;
                Idle.add (() => {
                    if (search_cancellable.is_cancelled () == false)
                        champlain_embed.champlain_view.go_to (point.latitude, point.longitude);
                    return false;
                });
            }

            if (loc == location_entry.text)
                map_selected = true;

            location_entry.has_focus = true;
        } catch (Error error) {
            debug (error.message);
        }
    }

    private async void find_location (double latitude, double longitude) {
        if (find_cancellable != null) {
            find_cancellable.cancel ();
        }

        find_cancellable = new GLib.Cancellable ();
        Geocode.Location location = new Geocode.Location (latitude, longitude);
        var reverse = new Geocode.Reverse.for_location (location);

        try {
            var address = yield reverse.resolve_async (find_cancellable);
            var builder = new StringBuilder ();
            if (address.street != null) {
                builder.append (address.street);
                add_address_line (builder, address.town);
                add_address_line (builder, address.county);
                add_address_line (builder, address.postal_code);
                add_address_line (builder, address.country);
            } else {
                builder.append (address.name);
                add_address_line (builder, address.country);
            }

            location_entry.text = builder.str;
        } catch (Error error) {
            debug (error.message);
        }
    }

    private async void discover_location () {
        if (search_cancellable != null)
            search_cancellable.cancel ();
        search_cancellable = new GLib.Cancellable ();
        try {
            var simple = yield new GClue.Simple ("io.elementary.calendar", GClue.AccuracyLevel.CITY, null);

            point.latitude = simple.location.latitude;
            point.longitude = simple.location.longitude;
            Idle.add (() => {
                if (search_cancellable.is_cancelled () == false)
                    champlain_embed.champlain_view.go_to (point.latitude, point.longitude);
                return false;
            });

        } catch (Error e) {
            warning ("Failed to connect to GeoClue2 service: %s", e.message);
            // Fallback to timezone location
            compute_location.begin (E.Util.get_system_timezone_location ());
            return;
        }
    }

    private void add_address_line (StringBuilder sb, string? text) {
        if (text != null) {
             sb.append (", ");
             sb.append (text);
        }
    }

    /**
     * Filter all contacts with address information and
     * add them to the location store.
     */
    private async void add_contacts_store (Gee.Map<string, Folks.Individual> contacts) {
        Gtk.TreeIter contact;
        var map_iterator = contacts.map_iterator ();
        while (map_iterator.next ()) {
            foreach (var address in map_iterator.get_value ().postal_addresses) {
                location_store.append (out contact);
                location_store.set (contact, 0, map_iterator.get_value ().full_name, 1, address.value.street);
            }
        }
    }

    /**
     * Load the backend and call add_contacts_store with all
     * contacts.
     */
    private async void load_contact () {
        var aggregator = Folks.IndividualAggregator.dup ();

        if (aggregator.is_prepared) {
            add_contacts_store.begin (aggregator.individuals);
        } else {
            aggregator.notify["is-quiescent"].connect (() => {
                add_contacts_store.begin (aggregator.individuals);
            });

            aggregator.prepare.begin ();
        }
    }

    private bool suggestion_selected (Gtk.TreeModel model, Gtk.TreeIter iter) {
        Value address;
        model.get_value (iter, 1, out address);
        location_entry.set_text (address.get_string ());
        compute_location.begin (address.get_string ());
        return true;
    }
}

public class Maya.Marker : Champlain.Marker {
    public Marker () {
        try {
            weak Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
            var pixbuf = icon_theme.load_icon ("location-marker", 32, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            Clutter.Image image = new Clutter.Image ();
            image.set_data (pixbuf.get_pixels (),
                          pixbuf.has_alpha ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                          pixbuf.width,
                          pixbuf.height,
                          pixbuf.rowstride);
            content = image;
            set_size (pixbuf.width, pixbuf.height);
            translation_x = -pixbuf.width/2;
            translation_y = -pixbuf.height;
        } catch (Error e) {
            critical (e.message);
        }
    }
}
