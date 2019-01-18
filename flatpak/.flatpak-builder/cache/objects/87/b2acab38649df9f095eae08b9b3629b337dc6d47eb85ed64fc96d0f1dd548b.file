/*
 * libosso.vapi
 *
 * Copyright (C) 2007 Instituto Nokia de Tecnologia
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *     Marcelo Lira dos Santos <setanta@gmail.com>
 *
 *
 * ChangeLog:
 *
 * 2009-02-16: Jukka-Pekka Iivonen <jukka-pekka.iivonen@nokia.com>
 *
 *           * Context.rpc_async_run: changed the async_cb type to RpcAsync?.
 *             Context.rpc_async_run_with_defaults: same here
 *
 *
 * 2009-02-10: Jukka-Pekka Iivonen <jukka-pekka.iivonen@nokia.com>
 *
 *           * Converted 'pointer' to 'void*'.
 *
 *           * Changed the name of Osso.Error to Osso.Status.
 *
 *           * Changed the type of 4th argument of Context.Context ().
 *
 *           * Made all fields of HWState public.
 *
 *           * Removed all argfill functions.
 *
 *
 * Initial code based on r78 from
 *
 *     http://code.google.com/p/setanta-labs/source/browse/trunk/vala/osso/libosso.vala
 */

[CCode (cheader_filename = "libosso.h")]
namespace Osso {

	[CCode (ref_function = "osso_initialize", unref_function = "osso_deinitialize", cname = "osso_context_t", cprefix = "osso_", cheader_filename = "libosso.h")]
	public class Context {
		[CCode (cname = "osso_initialize")]
		public Context (string application, string version, bool activation, GLib.MainContext? context);

		/* RPC */
		public Status rpc_run (string service, string object_path, string iface, string method, out Rpc retval, int argument_type, ...);
		public Status rpc_run_system (string service, string object_path, string iface, string method, out Rpc retval, int argument_type, ...);
		public Status rpc_run_with_defaults (string application, string method, out Rpc retval, int argument_type, ...);
		public Status rpc_async_run (string service, string object_path, string iface, string method, RpcAsync? async_callback, void* data, int argument_type, ...);
		public Status rpc_async_run_with_defaults (string application, string method, RpcAsync? async_callback, void* data,int argument_type, ...);
		[CCode (cname = "osso_rpc_set_cb_f")]
		public Status set_rpc_callback (string service, string object_path, string iface, RpcCallback cb, void* data);
		[CCode (cname = "osso_rpc_set_default_cb_f")]
		public Status set_rpc_default_callback (RpcCallback cb, void* data);
		[CCode (cname = "osso_rpc_unset_cb_f")]
		public Status unset_rpc_callback (string service, string object_path, string iface, RpcCallback cb, void* data);
		[CCode (cname = "osso_rpc_unset_default_cb_f")]
		public Status unset_rpc_default_callback (RpcCallback cb, void* data);
		[CCode (cname = "osso_rpc_get_timeout")]
		public Status get_rpc_timeout (ref int timeout);
		[CCode (cname = "osso_rpc_set_timeout")]
		public Status set_rpc_timeout (int timeout);

		/* Application */
		public Status application_top (string application, string arguments);
		[CCode (cname = "osso_application_set_top_callback")]
		public Status set_application_top_callback (ApplicationTopCallback cb, void* data);
		[CCode (cname = "osso_application_unset_top_callback")]
		public Status unset_application_top_callback (ApplicationTopCallback cb, void* data);
		[CCode (cname = "osso_application_set_autosave_callback")]
		public Status set_application_autosave_callback (ApplicationAutosaveCallback cb, void* data);
		[CCode (cname = "osso_application_unset_autosave_callback")]
		public Status unset_application_autosave_callback (ApplicationAutosaveCallback cb, void* data);
		public Status application_userdata_changed ();
		public Status application_autosave_force ();
		[CCode (cname = "osso_application_name_get")]
		public string get_application_name ();
		[CCode (cname = "osso_application_version_get")]
		public string get_application_version ();

		public Status statusbar_send_event (string name, int argument1, int argument2, string argument3, out Rpc retval);

		/* Time Notification */
		[CCode (cname = "osso_time_set_notification_cb")]
		public Status set_time_notification_callback (TimeCallback cb, void* data);
		//[CCode (cname = "osso_time_set")]
		//public Status set_time (time_t new_time);

		/* Locale */
		[CCode (cname = "osso_locale_change_set_notification_cb")]
		public Status set_locale_change_notification_callback (LocaleChangeCallback cb, void* data);
		[CCode (cname = "osso_locale_set")]
		public Status set_locale (string new_locale);

		/* System Note */
		public Status system_note_dialog (string message, SystemNoteType type, out Rpc retval);
		public Status system_note_infoprint (string text, out Rpc retval);

		/* State Saving */
		[CCode (cname = "osso_state_write")]
		public Status state_write (ref State state);
		[CCode (cname = "osso_state_read")]
		public Status state_read (ref State state);

		/* Plugin */
		[CCode (cname = "osso_cp_plugin_execute")]
		public Status plugin_execute (string filename, void* data, bool user_activated);
		[CCode (cname = "osso_cp_plugin_execute")]
		public Status plugin_save (string filename, void* data);

		/* Device State */
		public Status display_state_on ();
		public Status display_blanking_pause ();

		[CCode (cname = "osso_hw_set_event_cb")]
		public Status set_hw_event_callback (void* state, HWCallback cb, void* data);
		[CCode (cname = "osso_hw_unset_event_cb")]
		public Status unset_hw_event_callback (ref HWState state, void* data);
		[CCode (cname = "osso_hw_set_display_event_cb")]
		public Status set_hw_display_event_callback (DisplayEventCallback cb, void* data);

		/* Mime */
		[CCode (cname = "osso_mime_set_cb")]
		public Status set_mime_callback (MimeCallback cb, void* data);
		[CCode (cname = "osso_mime_unset_cb")]
		public Status unset_mime_callback ();
		[CCode (cname = "osso_mime_unset_cb_full")]
		public Status unset_mime_callback_full (MimeCallback cb, void* data);

		/* DBus */
		public void* get_dbus_connection ();
		public void* get_sys_dbus_connection ();
	}

	/* Callbacks */
	[CCode (cname = "osso_rpc_cb_f", has_target = false)]
	public delegate int RpcCallback (string iface, string method, GLib.Array arguments, void* data, out Rpc rpc);
	[CCode (cname = "osso_rpc_async_f", has_target = false)]
	public delegate int RpcAsync (string iface, string method, out Rpc rpc, void* data);

	[CCode (cname = "osso_application_top_cb_f", has_target = false)]
	public delegate void ApplicationTopCallback (string arguments, void* data);
	[CCode (cname = "osso_application_autosave_cb_f", has_target = false)]
	public delegate void ApplicationAutosaveCallback (void* data);
	[CCode (cname = "osso_time_cb_f", has_target = false)]
	public delegate void TimeCallback (void* data);
	[CCode (cname = "osso_locale_change_cb_f", has_target = false)]
	public delegate void LocaleChangeCallback (string new_locale, void* data);
	[CCode (cname = "osso_display_event_cb_f", has_target = false)]
	public delegate void DisplayEventCallback (DisplayState state, void* data);

	[CCode (cname = "osso_hw_cb_f*", has_target = false)]
	public delegate void HWCallback (ref HWState state, void* data);

	[CCode (cname = "osso_mime_cb_f", has_target = false)]
	public delegate void MimeCallback (void* data, string[] args);

	/* Structs */
	[CCode (cname = "osso_state_t")]
	public struct State {
		public uint32 state_size;
		public void* state_data;
	}

	[CCode (cname = "osso_hw_state_t")]
	public struct HWState {
		public bool shutdown_ind;
		public bool save_unsaved_data_ind;
		public bool memory_low_ind;
		public bool system_inactivity_ind;
		public DevMode sig_device_mode_ind;
	}

	[CCode (destroy_function = "osso_rpc_free_val", cname = "osso_rpc_t")]
	public struct Rpc {
		public int type;
		[CCode (cname = "value.u")]
		private uint32 u;
		[CCode (cname = "value.i")]
		private int32 i;
		[CCode (cname = "value.b")]
		private bool b;
		[CCode (cname = "value.d")]
		private double d;
		[CCode (cname = "value.s")]
		private string s;
		public uint32 to_uint32 () requires (type == 'u') {
			return u;
		}
		public int32 to_int32 () requires (type == 'i') {
			return i;
		}
		public bool to_bool () requires (type == 'b') {
			return b;
		}
		public double to_double () requires (type == 'd') {
			return d;
		}
		public unowned string to_string () requires (type == 's') {
			return s;
		}
	}

	/* Enums */
	[CCode (cname = "osso_return_t", cprefix = "OSSO_")]
	public enum Status {
		OK,
		ERROR,
		INVALID,
		RPC_ERROR,
		ERROR_NAME,
		ERROR_NO_STATE,
		ERROR_STATE_SIZE
	}

	[CCode (cname = "osso_system_note_type_t", cprefix = "OSSO_GN_")]
	public enum SystemNoteType {
		WARNING,
		ERROR,
		NOTICE,
		WAIT
	}

	[CCode (cname = "osso_devmode_t", cprefix = "OSSO_DEVMODE_")]
	public enum DevMode {
		NORMAL,
		FLIGHT,
		OFFLINE,
		INVALID
	}

	[CCode (cname = "osso_display_state_t", cprefix = "OSSO_DISPLAY_")]
	public enum DisplayState {
		ON,
		OFF,
		DIMMED
	}

	[CCode (cprefix = "GDK_", has_type_id = false, cheader_filename = "gdk/gdkkeysyms.h")]
	public enum KeySym {
		Up,
		Down,
		Left,
		Right,
		[CCode (cname = "GDK_Return")]
		Select,
		[CCode (cname = "GDK_F6")]
		FullScreen,
		[CCode (cname = "GDK_F7")]
		ZoomIn,
		[CCode (cname = "GDK_F8")]
		ZoomOut,
		[CCode (cname = "GDK_Escape")]
		Close,
		[CCode (cname = "GDK_F4")]
		OpenMenu,
		[CCode (cname = "GDK_F5")]
		ShowHome,
		[CCode (cname = "GDK_Execute")]
		Power
	}
}

