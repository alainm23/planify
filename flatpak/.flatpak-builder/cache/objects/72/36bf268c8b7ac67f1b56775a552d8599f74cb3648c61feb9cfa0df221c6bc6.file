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

public class Maya.LocalBackend : GLib.Object, Maya.Backend {
    E.SourceRegistry registry;

    public string get_name () {
        return _("On this computer");
    }

    public string get_uid () {
        return "local-stub";
    }

    public Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null) {
        return new Gee.LinkedList<PlacementWidget> ();
    }

    public void add_new_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets) {
        try {
            var new_source = new E.Source (null, null);
            new_source.display_name = name;
            new_source.parent = get_uid ();
            E.SourceCalendar cal = (E.SourceCalendar)new_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            cal.color = color;
            cal.backend_name = "local";
            add_source.begin (new_source, set_default);
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    public async void add_source (E.Source new_source, bool set_default) {
        try {
            if (registry == null) {
                registry = yield new E.SourceRegistry (null);
            }

            registry.commit_source_sync (new_source);
            if (set_default) {
                yield set_source_default (new_source);
            }
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    public async void set_source_default (E.Source source) {
        try {
            if (registry == null) {
                registry = yield new E.SourceRegistry (null);
            }

            registry.default_calendar = source;
            yield source.write (null);
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    public void modify_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets, E.Source source) {
        source.display_name = name;
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        cal.color = color;
        source.write.begin (null);
        if (set_default) {
            set_source_default.begin (source);
        }
    }
}
