/* gtkmozembed.vala
 *
 * Copyright (C) 2007  Alberto Ruiz
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
 * 	Alberto Ruiz <aruiz@gnome.org>
 */

[CCode (cprefix = "Gtk", lower_case_cprefix = "gtk_")]
namespace Gtk {
	[CCode (cprefix = "GTK_MOZ_EMBED_FLAG_", cheader_filename = "gtkembedmoz/gtkmozembed.h")]
	public enum MozEmbedProgressFlags {
		START,
  		REDIRECTING,
		TRANSFERRING,
		NEGOTIATING,
		STOP,
		IS_REQUEST,
		IS_DOCUMENT,
		IS_NETWORK,
		IS_WINDOW,
		RESTORING,
	}
	[CCode (cprefix = "GTK_MOZ_EMBED_STATUS_", cheader_filename = "gtkembedmoz/gtkmozembed.h")]
	public enum MozEmbedStatusFlags
	{
		FAILED_DNS,
		FAILED_CONNECT,
		FAILED_TIMEOUT,
		FAILED_USERCANCELED,
	}
	[CCode (cprefix = "GTK_MOZ_EMBED_FLAG_", cheader_filename = "gtkembedmoz/gtkmozembed.h")]
	public enum MozEmbedReloadFlags
	{
		RELOADNORMAL,
		RELOADBYPASSCACHE,
		RELOADBYPASSPROXY,
		RELOADBYPASSPROXYANDCACHE,
		RELOADCHARSETCHANGE,
	}
	[CCode (cprefix = "GTK_MOZ_EMBED_FLAG_", cheader_filename = "gtkembedmoz/gtkmozembed.h")]
	public enum MozEmbedChromeFlags
	{
		DEFAULTCHROME,
		WINDOWBORDERSON,
		WINDOWCLOSEON,
		WINDOWRESIZEON,
		MENUBARON,
		TOOLBARON,
		LOCATIONBARON,
		STATUSBARON,
		PERSONALTOOLBARON,
		SCROLLBARSON,
		TITLEBARON,
		EXTRACHROMEON,
		ALLCHROME,
		WINDOWRAISED,
		WINDOWLOWERED,
		CENTERSCREEN,
		DEPENDENT,
		MODAL,
		OPENASDIALOG,
		OPENASCHROME,
	}
	[CCode (cheader_filename = "gtkembedmoz/gtkmozembed.h")]
	public class MozEmbed : Gtk.Bin {
		public MozEmbed ();
		public void load_url (string url);

		public void stop_load ();
		public unowned bool can_go_back ();
		public unowned bool can_go_forward ();
		public void go_back ();
		public void go_forward ();

		public void render_data (string data, uint32 len, string base_uri, string mime_type);
		public void open_stream (string base_uri, string mime_type);
		public void append_data (string data, uint32 len);

		public void close_stream ();
		public unowned string get_link_message ();
		public unowned string get_js_status ();
		public unowned string get_title ();
		public unowned string get_location ();

		public void reload (MozEmbedReloadFlags flags);
		public void set_chrome_mask (MozEmbedChromeFlags flags);
		public MozEmbedChromeFlags get_chrome_mask ();

		public static void push_startup ();
		public static void pop_startup ();
		public static void set_comp_path (string aPath);
		public static void set_profile_path (string aDir, string aName);

		public signal void js_status ();
		public signal void location ();
		public signal void link_message ();
		public signal void title ();
		public signal void progress (int cur, int max);
		public signal void net_state (int flags, uint status);
		public signal void net_start ();
		public signal void net_stop ();
		public signal void new_window (out MozEmbed retval, MozEmbedChromeFlags chromemask);
		public signal void visibility (bool visibility);
		public signal void destroy_browser ();
		public signal bool open_uri (string uri);
	}
}

