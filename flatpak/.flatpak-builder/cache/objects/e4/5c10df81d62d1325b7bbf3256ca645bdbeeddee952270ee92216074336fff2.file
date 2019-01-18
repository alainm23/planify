/* dbus-glib-1.vala
 *
 * Copyright (C) 2007-2010  Jürg Billeter
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
 *  Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 */

[CCode (cheader_filename = "dbus/dbus-glib-lowlevel.h,dbus/dbus-glib.h", gir_namespace = "DBusGLib", gir_version = "1.0")]
namespace DBus {
	public const string SERVICE_DBUS;
	public const string PATH_DBUS;
	public const string INTERFACE_DBUS;

	public const string INTERFACE_INTROSPECTABLE;
	public const string INTERFACE_PROPERTIES;
	public const string INTERFACE_PEER;

	[CCode (cname = "dbus_g_thread_init")]
	public static void thread_init ();

	[CCode (cprefix = "DBUS_BUS_")]
	public enum BusType {
		SESSION,
		SYSTEM,
		STARTER
	}

	[CCode (lower_case_cprefix = "dbus_bus_")]
	namespace RawBus {
		public static RawConnection get (BusType type, ref RawError error);
	}

	[CCode (ref_function = "dbus_connection_ref", unref_function = "dbus_connection_unref", cname = "DBusConnection", cprefix = "dbus_connection_")]
	public class RawConnection {
		[CCode (cname = "dbus_connection_setup_with_g_main")]
		public void setup_with_main (GLib.MainContext? context = null);
		[CCode (cname = "dbus_connection_get_g_connection")]
		public unowned Connection get_g_connection ();
		[CCode (cname = "dbus_connection_register_g_object")]
		public void register_object (string at_path, GLib.Object object);

		public bool send (RawMessage message, uint32? client_serial);
		public RawMessage send_with_reply_and_block (RawMessage message, int timeout_milliseconds, ref RawError error);

		public bool add_filter (RawHandleMessageFunction function, RawFreeFunction? free_data_function = null);
		public void remove_filter (RawHandleMessageFunction function);

		[CCode (cname = "dbus_bus_add_match")]
		public void add_match (string rule, ref RawError error);
		[CCode (cname = "dbus_bus_remove_match")]
		public void remove_match (string rule, ref RawError error);
		[CCode (cname = "dbus_bus_get_unique_name")]
		public unowned string get_unique_name();
		[CCode (cname = "dbus_bus_request_name")]
		public int request_name(string name, uint flags, ref RawError error);
		[CCode (cname="dbus_bus_release_name")]
		public int release_name(string name, ref RawError error);
	}

	[CCode (cname = "DBusError", cprefix = "dbus_error_", destroy_function = "dbus_error_free")]
	public struct RawError {
		public string name;
		public string message;

		public RawError ();
		public bool has_name (string name);
		public bool is_set ();
	}

	[CCode (cname = "DBusFreeFunction", has_target = false)]
	public delegate void* RawFreeFunction (void* memory);
	[CCode (cname = "DBusHandleMessageFunction", instance_pos = -1)]
	public delegate RawHandlerResult RawHandleMessageFunction(RawConnection connection, RawMessage message);

	[CCode (cname = "DBusHandlerResult", cprefix = "DBUS_HANDLER_RESULT_")]
	public enum RawHandlerResult {
		HANDLED,
		NOT_YET_HANDLED,
		NEED_MEMORY
	}

	[CCode (cname = "DBusMessageIter", cprefix = "dbus_message_iter_")]
	public struct RawMessageIter {
		public bool has_next ();
		public bool next ();
		public string get_signature ();
		public int get_arg_type ();
		public int get_element_type ();
		public void recurse (RawMessageIter sub);
		public void get_basic (void* value);
		public bool open_container (RawType arg_type, string? signature, RawMessageIter sub);
		public bool close_container (RawMessageIter sub);
		public bool append_basic (RawType arg_type, void* value);

		[CCode (cname = "dbus_message_type_from_string")]
		public static int type_from_string (string type);
		[CCode (cname = "dbus_message_type_to_string")]
		public static string type_to_string (int type);
	}

	[CCode (ref_function = "dbus_message_ref", unref_function = "dbus_message_unref", cname = "DBusMessage", cprefix = "dbus_message_")]
	public class RawMessage {
		[CCode (cname = "dbus_message_new_method_call")]
		public RawMessage.call (string bus_name, string path, string interface, string method);
		[CCode (sentinel = "DBUS_TYPE_INVALID")]
		public bool append_args (RawType first_arg_type, ...);
		[CCode (cname = "dbus_message_iter_init")]
		public bool iter_init (RawMessageIter iter);
		[CCode (cname = "dbus_message_iter_init_append")]
		public bool iter_init_append (RawMessageIter iter);

		public RawMessageType get_type ();
		public bool   set_path (string object_path);
		public unowned string get_path ();
		public bool   has_path (string object_path);
		public bool   set_interface (string iface);
		public unowned string get_interface ();
		public bool   has_interface (string iface);
		public bool   set_member (string member);
		public unowned string get_member ();
		public bool   has_member (string member);
		public bool   set_error_name (string name);
		public unowned string get_error_name ();
		public bool   set_destination (string destination);
		public unowned string get_destination ();
		public bool   set_sender (string sender);
		public unowned string get_sender ();
		public unowned string get_signature ();
		public void   set_no_reply (bool no_reply);
		public bool   get_no_reply ();
		public bool   is_method_call (string iface, string method);
		public bool   is_signal (string iface, string signal_name);
		public bool   is_error (string error_name);
		public bool   has_destination (string bus_name);
		public bool   has_sender (string unique_bus_name);
		public bool   has_signature (string signature);
		public uint32 get_serial ();
		public void   set_serial (uint32 serial);
		public bool   set_reply_serial (uint32 reply_serial);
		public uint32 get_reply_serial ();
		public void   set_auto_start (bool auto_start);
		public bool   get_auto_start ();
		public bool   get_path_decomposed (out char[] path );
	}

	[CCode (cname = "int", cprefix = "DBUS_MESSAGE_TYPE_")]
	public enum RawMessageType {
		INVALID,
		METHOD_CALL,
		METHOD_RETURN,
		ERROR,
		SIGNAL
	}

	[CCode (cname = "int", cprefix = "DBUS_TYPE_")]
	public enum RawType {
		INVALID,
		BYTE,
		BOOLEAN,
		INT16,
		UINT16,
		INT32,
		UINT32,
		INT64,
		UINT64,
		DOUBLE,
		STRING,
		OBJECT_PATH,
		SIGNATURE,
		ARRAY,
		VARIANT,
		STRUCT,
		DICT_ENTRY,
	}

	[DBus (name = "org.freedesktop.DBus.Error")]
	[CCode (cname = "DBusGError", lower_case_csuffix = "gerror", cprefix = "DBUS_GERROR_")]
	public errordomain Error {
		FAILED,
		NO_MEMORY,
		SERVICE_UNKNOWN,
		NAME_HAS_NO_OWNER,
		NO_REPLY,
		[DBus (name = "IOError")]
		IO_ERROR,
		BAD_ADDRESS,
		NOT_SUPPORTED,
		LIMITS_EXCEEDED,
		ACCESS_DENIED,
		AUTH_FAILED,
		NO_SERVER,
		TIMEOUT,
		NO_NETWORK,
		ADDRESS_IN_USE,
		DISCONNECTED,
		INVALID_ARGS,
		FILE_NOT_FOUND,
		FILE_EXISTS,
		UNKNOWN_METHOD,
		TIMED_OUT,
		MATCH_RULE_NOT_FOUND,
		MATCH_RULE_INVALID,
		[DBus (name = "Spawn.ExecFailed")]
		SPAWN_EXEC_FAILED,
		[DBus (name = "Spawn.ForkFailed")]
		SPAWN_FORK_FAILED,
		[DBus (name = "Spawn.ChildExited")]
		SPAWN_CHILD_EXITED,
		[DBus (name = "Spawn.ChildSignaled")]
		SPAWN_CHILD_SIGNALED,
		[DBus (name = "Spawn.Failed")]
		SPAWN_FAILED,
		UNIX_PROCESS_ID_UNKNOWN,
		INVALID_SIGNATURE,
		INVALID_FILE_CONTENT,
		[DBus (name = "SELinuxSecurityContextUnknown")]
		SELINUX_SECURITY_CONTEXT_UNKNOWN,
		REMOTE_EXCEPTION
	}

	public struct Bus {
		[CCode (cname = "dbus_g_bus_get")]
		public static Connection get (BusType type) throws Error;
	}

	[Compact]
	[CCode (ref_function = "dbus_g_connection_ref", unref_function = "dbus_g_connection_unref", cname = "DBusGConnection")]
	public class Connection {
		[CCode (cname = "dbus_g_connection_open")]
		public Connection (string address) throws Error;
		[CCode (cname = "dbus_g_proxy_new_for_name")]
		public Object get_object (string name, string path, string? interface_ = null);
		[CCode (cname="dbus_g_proxy_new_for_name_owner")]
		public Object get_object_for_name_owner (string name, string path, string? interface_ = null) throws Error;
		[CCode (cname = "dbus_g_proxy_new_from_type")]
		public GLib.Object get_object_from_type (string name, string path, string interface_, GLib.Type type);
		[CCode (cname = "dbus_g_connection_register_g_object")]
		public void register_object (string at_path, GLib.Object object);
		[CCode (cname = "dbus_g_connection_unregister_g_object")]
		public void unregister_object (GLib.Object object);
		[CCode (cname = "dbus_g_connection_lookup_g_object")]
		public unowned GLib.Object lookup_object (string at_path);
		[CCode (cname = "dbus_g_connection_get_connection")]
		public unowned RawConnection get_connection ();
	}

	[CCode (cname = "DBusGProxy", lower_case_csuffix = "g_proxy")]
	public class Object : GLib.Object {
		public bool call (string method, out GLib.Error error, GLib.Type first_arg_type, ...);
		public unowned ProxyCall begin_call (string method, ProxyCallNotify notify, GLib.DestroyNotify destroy, GLib.Type first_arg_type, ...);
		public bool end_call (ProxyCall call, out GLib.Error error, GLib.Type first_arg_type, ...);
		public void cancel_call (ProxyCall call);
		public unowned string get_path ();
		public unowned string get_bus_name ();
		public unowned string get_interface ();
		public GLib.HashTable<string,GLib.Value?> get_all (string interface_name) throws DBus.Error;

		public signal void destroy ();
	}

	[CCode (cname = "char", const_cname = "const char", copy_function = "g_strdup", free_function = "g_free", cheader_filename = "stdlib.h,string.h,glib.h", type_id = "DBUS_TYPE_G_OBJECT_PATH", marshaller_type_name = "BOXED", get_value_function = "g_value_get_boxed", set_value_function = "g_value_set_boxed", type_signature = "o")]
	public class ObjectPath : string {
		[CCode (cname = "g_strdup")]
		public ObjectPath (string path);
	}

	[CCode (cname = "char", const_cname = "const char", copy_function = "g_strdup", free_function = "g_free", cheader_filename = "stdlib.h,string.h,glib.h", type_id = "G_TYPE_STRING", marshaller_type_name = "STRING", get_value_function = "g_value_get_string", set_value_function = "g_value_set_string")]
	public class BusName : string {
		[CCode (cname = "g_strdup")]
		public BusName (string bus_name);
	}

	[CCode (cname = "DBusGProxyCallNotify")]
	public delegate void ProxyCallNotify (Object obj, ProxyCall call_id);

	[CCode (cname = "DBusGProxyCall")]
	public class ProxyCall {
	}

	[CCode (cname = "DBusGMethodInvocation")]
	public class MethodInvocation {
	}

	[Flags]
	[CCode (cname = "uint")]
	public enum NameFlag {
		ALLOW_REPLACEMENT,
		REPLACE_EXISTING,
		DO_NOT_QUEUE
	}

	[CCode (cname = "int")]
	public enum RequestNameReply {
		PRIMARY_OWNER,
		IN_QUEUE,
		EXISTS,
		ALREADY_OWNER
	}
}
