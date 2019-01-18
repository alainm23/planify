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

public Maya.Backend get_backend (Module module) {
    debug ("Activating Google Backend");
    var b = new Maya.GoogleBackend ();
    b.ref ();
    return b;
}

public static Maya.Backend backend;

public class Maya.GoogleBackend : GLib.Object, Maya.Backend {
    public GoogleBackend () {
        backend = this;
    }

    public string get_name () {
        return _("Google");
    }

    public string get_uid () {
        return "google-stub";
    }

    public Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null) {
        var collection = new Gee.LinkedList<PlacementWidget> ();

        bool keep_copy = false;
        if (to_edit != null) {
            E.SourceOffline source_offline = (E.SourceOffline)to_edit.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            keep_copy = source_offline.stay_synchronized;
        }
        collection.add (Maya.DefaultPlacementWidgets.get_keep_copy (3, keep_copy));

        string user = "";
        if (to_edit != null) {
            E.SourceAuthentication auth = (E.SourceAuthentication)to_edit.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            user = auth.user;
        }

        collection.add_all (Maya.DefaultPlacementWidgets.get_user (4, true, user, _("user.name or user.name@gmail.com")));

        return collection;
    }

    public void add_new_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets) {
        try {
            var new_source = new E.Source (null, null);
            new_source.display_name = name;
            new_source.parent = get_uid ();
            E.SourceCalendar cal = (E.SourceCalendar)new_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            cal.backend_name = "caldav";
            E.SourceWebdav webdav = (E.SourceWebdav)new_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            E.SourceOffline offline = (E.SourceOffline)new_source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            E.SourceAuthentication auth = (E.SourceAuthentication)new_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "user_entry":
                        string decoded_user = ((Gtk.Entry)widget.widget).text;
                        if (!decoded_user.contains ("@") && !decoded_user.contains ("%40")) {
                            decoded_user = "%s@gmail.com".printf (decoded_user);
                        }

                        auth.user = decoded_user;
                        var soup_uri = new Soup.URI (null);
                        soup_uri.set_host ("www.google.com");
                        soup_uri.set_scheme ("https");
                        soup_uri.set_user (decoded_user);
                        soup_uri.set_path ("/calendar/dav/%s/events".printf (decoded_user));
                        webdav.soup_uri = soup_uri;
                        break;
                    case "keep_copy":
                        offline.set_stay_synchronized (((Gtk.CheckButton)widget.widget).active);
                        break;
                }
            }

            var calmodel = Maya.Model.CalendarModel.get_default ();
            var registry = calmodel.registry;
            var list = new List<E.Source> ();
            list.append (new_source);
            registry.create_sources_sync (list);
            calmodel.add_source (new_source);
            if (set_default) {
                registry.default_calendar = new_source;
            }

        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    public void modify_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets, E.Source source) {
        try {
            source.display_name = name;
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            E.SourceWebdav webdav = (E.SourceWebdav)source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            E.SourceOffline offline = (E.SourceOffline)source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            E.SourceAuthentication auth = (E.SourceAuthentication)source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            foreach (var widget in widgets) {
                switch (widget.ref_name) {
                    case "user_entry":
                        string decoded_user = ((Gtk.Entry)widget.widget).text;
                        if (!decoded_user.contains ("@") && !decoded_user.contains ("%40")) {
                            decoded_user = "%s@gmail.com".printf (decoded_user);
                        }

                        auth.user = decoded_user;
                        var soup_uri = new Soup.URI (null);
                        soup_uri.set_host ("www.google.com");
                        soup_uri.set_scheme ("https");
                        soup_uri.set_user (decoded_user);
                        soup_uri.set_path ("/calendar/dav/%s/events".printf (decoded_user));
                        webdav.soup_uri = soup_uri;
                        break;
                    case "keep_copy":
                        offline.set_stay_synchronized (((Gtk.CheckButton)widget.widget).active);
                        break;
                }
            }

            source.write.begin (null);
            if (set_default) {
                var registry = new E.SourceRegistry.sync (null);
                registry.default_calendar = source;
            }

        } catch (GLib.Error error) {
            critical (error.message);
        }
    }
}
