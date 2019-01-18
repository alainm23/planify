/* libpanelapplet-2.0.vala
 *
 * Copyright (C) 2007  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 */

[CCode (cheader_filename = "panel-applet.h")]
[Version (deprecated = true)]
namespace Panel {
	public class Applet : Gtk.EventBox {
		[CCode (has_construct_function = false)]
		public Applet ();
		public AppletFlags get_flags ();
		public bool get_locked_down ();
		public AppletOrient get_orient ();
		public string get_preferences_key ();
		public uint get_size ();
		public void request_focus (uint32 timestamp);
		public void set_flags (AppletFlags flags);
		public static int factory_main (string iid, GLib.Type applet_type, AppletFactoryCallback callback);
		public void set_background_widget (Gtk.Widget widget);
		public void setup_menu (string xml, [CCode (array_length = false)] BonoboUI.Verb[] verb_list, void* data);
		public signal void change_background (AppletBackgroundType type, Gdk.Color? color, Gdk.Pixmap? pixmap);
		public signal void change_orient (uint orient);
		public signal void change_size (int size);
		public signal void move_focus_out_of_applet (Gtk.DirectionType direction);
	}

	[CCode (cprefix = "PANEL_")]
	public enum AppletBackgroundType {
		NO_BACKGROUND,
		COLOR_BACKGROUND,
		PIXMAP_BACKGROUND
	}

	[CCode (cprefix = "PANEL_APPLET_")]
	public enum AppletFlags {
		FLAGS_NONE,
		EXPAND_MAJOR,
		EXPAND_MINOR,
		HAS_HANDLE
	}

	[CCode (cprefix = "PANEL_APPLET_ORIENT_")]
	public enum AppletOrient {
		UP,
		DOWN,
		LEFT,
		RIGHT
	}

	public delegate bool AppletFactoryCallback (Applet applet, string iid);
}

