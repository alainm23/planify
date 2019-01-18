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

public interface Maya.Backend : GLib.Object {
    public abstract string get_name (); // A backend should never change his name
    public abstract string get_uid ();
    public abstract Gee.Collection<PlacementWidget> get_new_calendar_widget (E.Source? to_edit = null);
    public abstract void add_new_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets);
    public abstract void modify_calendar (string name, string color, bool set_default, Gee.Collection<PlacementWidget> widgets, E.Source source);
}
