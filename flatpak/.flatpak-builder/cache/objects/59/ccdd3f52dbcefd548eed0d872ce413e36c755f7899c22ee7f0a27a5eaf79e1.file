/* gobject-2.0.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 * Copyright (C) 2007  Mathias Hasselmann
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
 *	Raffaele Sandrini <rasa@gmx.ch>
 *	Mathias Hasselmann <mathias.hasselmann@gmx.de>
 */

[CCode (cheader_filename = "glib.h", cprefix = "G", gir_namespace = "GObject", gir_version = "2.0", lower_case_cprefix = "g_")]
namespace GLib {
	namespace Signal {
		public static ulong add_emission_hook (uint signal_id, GLib.Quark detail, GLib.SignalEmissionHook hook_func, GLib.DestroyNotify? data_destroy);
		public static void chain_from_overridden ([CCode (array_length = false)] GLib.Value[] instance_and_params, out GLib.Value return_value);
		[Version (since = "2.18")]
		public static void chain_from_overridden_handler (void* instance, ...);
		public static ulong connect (void* instance, string detailed_signal, GLib.Callback handler, void* data);
		public static ulong connect_after (void* instance, string detailed_signal, GLib.Callback handler, void* data);
		public static ulong connect_closure (void* instance, string detailed_signal, GLib.Closure closure, bool after);
		public static ulong connect_closure_by_id (void* instance, uint signal_id, GLib.Quark detail, GLib.Closure closure, bool after);
		public static ulong connect_data (void* instance, string detailed_signal, GLib.Callback handler, void* data, GLib.ClosureNotify destroy_data, GLib.ConnectFlags flags);
		public static ulong connect_object (void* instance, string detailed_signal, GLib.Callback handler, GLib.Object gobject, GLib.ConnectFlags flags);
		public static ulong connect_swapped (void* instance, string detailed_signal, GLib.Callback handler, void* data);
		public static void emit (void* instance, uint signal_id, GLib.Quark detail, ...);
		public static void emit_by_name (void* instance, string detailed_signal, ...);
		public static unowned GLib.SignalInvocationHint? get_invocation_hint (void* instance);
		public static bool has_handler_pending (void* instance, uint signal_id, GLib.Quark detail, bool may_be_blocked);
		public static uint[] list_ids (GLib.Type itype);
		public static uint lookup (string name, GLib.Type itype);
		public static unowned string name (uint signal_id);
		public static void override_class_closure (uint signal_id, GLib.Type instance_type, GLib.Closure class_closure);
		[Version (since = "2.18")]
		public static void override_class_handler (string signal_name, GLib.Type instance_type, GLib.Callback class_handler);
		public static bool parse_name (string detailed_signal, GLib.Type itype, out uint signal_id, out GLib.Quark detail, bool force_detail_quark);
		public static void query (uint signal_id, out GLib.SignalQuery query);
		public static void remove_emission_hook (uint signal_id, ulong hook_id);
		public static void stop_emission (void* instance, uint signal_id, GLib.Quark detail);
		public static void stop_emission_by_name (void* instance, string detailed_signal);
	}
	namespace SignalHandler {
		public static void block (void* instance, ulong handler_id);
		[CCode (cname = "g_signal_handlers_block_by_func")]
		public static uint block_by_func (void* instance, void* func, void* data);
		[CCode (cname = "g_signal_handlers_block_matched")]
		public static uint block_matched (void* instance, GLib.SignalMatchType mask, uint signal_id, GLib.Quark detail, GLib.Closure? closure, void* func, void* data);
		public static void disconnect (void* instance, ulong handler_id);
		[CCode (cname = "g_signal_handlers_disconnect_by_func")]
		public static uint disconnect_by_func (void* instance, void* func, void* data);
		[CCode (cname = "g_signal_handlers_disconnect_matched")]
		public static uint disconnect_matched (void* instance, GLib.SignalMatchType mask, uint signal_id, GLib.Quark detail, GLib.Closure? closure, void* func, void* data);
		public static ulong find (void* instance, GLib.SignalMatchType mask, uint signal_id, GLib.Quark detail, GLib.Closure? closure, void* func, void* data);
		public static bool is_connected (void* instance, ulong handler_id);
		public static void unblock (void* instance, ulong handler_id);
		[CCode (cname = "g_signal_handlers_unblock_by_func")]
		public static uint unblock_by_func (void* instance, void* func, void* data);
		[CCode (cname = "g_signal_handlers_unblock_matched")]
		public static uint unblock_matched (void* instance, GLib.SignalMatchType mask, uint signal_id, GLib.Quark detail, GLib.Closure? closure, void* func, void* data);
	}
	[CCode (type_id = "G_TYPE_BINDING")]
	[Version (since = "2.26")]
	public class Binding : GLib.Object {
		public GLib.BindingFlags get_flags ();
		public unowned GLib.Object get_source ();
		public unowned string get_source_property ();
		public unowned GLib.Object get_target ();
		public unowned string get_target_property ();
		[DestroysInstance]
		[Version (since = "2.38")]
		public void unbind ();
		public GLib.BindingFlags flags { get; construct; }
		public GLib.Object source { get; construct; }
		public string source_property { get; construct; }
		public GLib.Object target { get; construct; }
		public string target_property { get; construct; }
	}
	[CCode (ref_function = "g_closure_ref", type_id = "G_TYPE_CLOSURE", unref_function = "g_closure_unref")]
	[Compact]
	public class Closure {
		[CCode (cname = "sizeof(GClosure)")]
		public static size_t SIZE;
		[CCode (cname = "g_closure_new_object")]
		public Closure (ulong sizeof_closure, GLib.Object object);
		public void add_finalize_notifier (void* notify_data, GLib.ClosureNotify notify_func);
		public void add_invalidate_notifier (void* notify_data, GLib.ClosureNotify notify_func);
		public void add_marshal_guards (void* pre_marshal_data, GLib.ClosureNotify pre_marshal_notify, void* post_marshal_data, GLib.ClosureNotify post_marshal_notify);
		public void invalidate ();
		public void invoke (out GLib.Value return_value, [CCode (array_length_cname = "n_param_values", array_length_pos = 1.5, array_length_type = "guint")] GLib.Value[] param_values, void* invocation_hint);
		[CCode (has_construct_function = false)]
		public Closure.object (uint sizeof_closure, GLib.Object object);
		public unowned GLib.Closure @ref ();
		public void remove_finalize_notifier (void* notify_data, GLib.ClosureNotify notify_func);
		public void remove_invalidate_notifier (void* notify_data, GLib.ClosureNotify notify_func);
		public void set_marshal (GLib.ClosureMarshal marshal);
		public void set_meta_marshal (void* marshal_data, GLib.ClosureMarshal meta_marshal);
		[CCode (has_construct_function = false)]
		public Closure.simple (uint sizeof_closure, void* data);
		public void sink ();
		public void unref ();
	}
	[CCode (lower_case_csuffix = "enum")]
	public class EnumClass : GLib.TypeClass {
		public int maximum;
		public int minimum;
		public uint n_values;
		[CCode (array_length_cname = "n_values")]
		public weak GLib.EnumValue[] values;
		public unowned GLib.EnumValue? get_value (int value);
		public unowned GLib.EnumValue? get_value_by_name (string name);
		public unowned GLib.EnumValue? get_value_by_nick (string name);
	}
	[CCode (lower_case_csuffix = "flags")]
	public class FlagsClass : GLib.TypeClass {
		public uint mask;
		public uint n_values;
		[CCode (array_length_cname = "n_values")]
		public weak GLib.FlagsValue[] values;
		public unowned GLib.FlagsValue? get_first_value (uint value);
		public unowned GLib.FlagsValue? get_value_by_name (string name);
		public unowned GLib.FlagsValue? get_value_by_nick (string name);
	}
	[CCode (ref_sink_function = "g_object_ref_sink", type_id = "G_TYPE_INITIALLY_UNOWNED")]
	public class InitiallyUnowned : GLib.Object {
		[CCode (has_construct_function = false)]
		protected InitiallyUnowned ();
	}
	[CCode (cheader_filename = "glib-object.h", get_value_function = "g_value_get_object", marshaller_type_name = "OBJECT", param_spec_function = "g_param_spec_object", ref_function = "g_object_ref", set_value_function = "g_value_set_object", take_value_function = "g_value_take_object", unref_function = "g_object_unref")]
	public class Object {
		public uint ref_count;
		[CCode (construct_function = "g_object_new", has_new_function = false)]
		public Object (...);
		public void add_toggle_ref (GLib.ToggleNotify notify);
		public void add_weak_pointer (void** data);
		[CCode (cname = "g_object_bind_property_with_closures")]
		[Version (since = "2.26")]
		public unowned GLib.Binding bind_property (string source_property, GLib.Object target, string target_property, GLib.BindingFlags flags = GLib.BindingFlags.DEFAULT, [CCode (type = "GClosure*")] owned GLib.BindingTransformFunc? transform_to = null, [CCode (type = "GClosure*")] owned GLib.BindingTransformFunc? transform_from = null);
		public unowned GLib.Object connect (string signal_spec, ...);
		public virtual void constructed ();
		[CCode (cname = "g_signal_handler_disconnect")]
		public void disconnect (ulong handler_id);
		[CCode (cname = "g_object_run_dispose")]
		public virtual void dispose ();
		[CCode (simple_generics = true)]
		[Version (since = "2.34")]
		public T dup_data<T> (string key, GLib.DuplicateFunc<T> dup_func);
		[CCode (simple_generics = true)]
		[Version (since = "2.34")]
		public T dup_qdata<T> (GLib.Quark quark, GLib.DuplicateFunc<T> dup_func);
		public void force_floating ();
		public void freeze_notify ();
		public void @get (string first_property_name, ...);
		[CCode (cname = "G_OBJECT_GET_CLASS")]
		public unowned GLib.ObjectClass get_class ();
		[CCode (simple_generics = true)]
		public unowned T get_data<T> (string key);
		public void get_property (string property_name, ref GLib.Value value);
		[CCode (simple_generics = true)]
		public unowned T get_qdata<T> (GLib.Quark quark);
		[CCode (cname = "G_TYPE_FROM_INSTANCE")]
		public GLib.Type get_type ();
		[Version (since = "2.54")]
		public void getv ([CCode (array_length_cname = "n_properties", array_length_pos = 0.5, array_length_type = "guint")] string[] names, [CCode (array_length_cname = "n_properties", array_length_pos = 0.5, array_length_type = "guint")] GLib.Value[] values);
		public static unowned GLib.ParamSpec? interface_find_property (GLib.TypeInterface g_iface, string property_name);
		public static void interface_install_property (GLib.TypeInterface g_iface, GLib.ParamSpec pspec);
		[CCode (array_length_pos = 1.1, array_length_type = "guint")]
#if VALA_0_26
		public static (unowned GLib.ParamSpec)[] interface_list_properties (GLib.TypeInterface g_iface);
#else
		public static unowned GLib.ParamSpec[] interface_list_properties (GLib.TypeInterface g_iface);
#endif
		public bool is_floating ();
		public static GLib.Object @new (GLib.Type type, ...);
		public static GLib.Object new_valist (GLib.Type type, string? firstprop, va_list var_args);
		[Version (deprecated = true, deprecated_since = "2.54")]
		public static GLib.Object newv (GLib.Type type, [CCode (array_length_pos = 1.9, array_length_type = "guint")] GLib.Parameter[] parameters);
		[Version (since = "2.54")]
		public static GLib.Object new_with_properties (GLib.Type object_type, [CCode (array_length_cname = "n_properties", array_length_pos = 1.5, array_length_type = "guint")] string[] names, [CCode (array_length_cname = "n_properties", array_length_pos = 1.5, array_length_type = "guint")] GLib.Value[] values);

		[CCode (cname = "g_object_notify")]
		public void notify_property (string property_name);
		public unowned GLib.Object @ref ();
		public unowned GLib.Object ref_sink ();
		[CCode (simple_generics = true)]
		[Version (since = "2.34")]
		public bool replace_data<G,T> (string key, G oldval, owned T newval, out GLib.DestroyNotify? old_destroy);
		[CCode (simple_generics = true)]
		[Version (since = "2.34")]
		public bool replace_qdata<G,T> (GLib.Quark quark, G oldval, owned T newval, out GLib.DestroyNotify? old_destroy);
		public void remove_toggle_ref (GLib.ToggleNotify notify);
		public void remove_weak_pointer (void** data);
		public void @set (string first_property_name, ...);
		[CCode (cname = "g_object_set_data_full", simple_generics = true)]
		public void set_data<T> (string key, owned T data);
		public void set_data_full (string key, void* data, GLib.DestroyNotify? destroy);
		public void set_property (string property_name, GLib.Value value);
		[CCode (cname = "g_object_set_qdata_full", simple_generics = true)]
		public void set_qdata<T> (GLib.Quark quark, owned T data);
		public void set_qdata_full (GLib.Quark quark, void* data, GLib.DestroyNotify? destroy);
		public void set_valist (string first_property_name, va_list var_args);
		[Version (since = "2.54")]
		public void setv ([CCode (array_length_cname = "n_properties", array_length_pos = 0.5, array_length_type = "guint")] string[] names, [CCode (array_length_cname = "n_properties", array_length_pos = 0.5, array_length_type = "guint")] GLib.Value[] values);
		[CCode (simple_generics = true)]
		public T steal_data<T> (string key);
		[CCode (simple_generics = true)]
		public T steal_qdata<T> (GLib.Quark quark);
		public void thaw_notify ();
		public void unref ();
		public void watch_closure (GLib.Closure closure);
		public void weak_ref (GLib.WeakNotify notify);
		public void weak_unref (GLib.WeakNotify notify);
		public signal void notify (GLib.ParamSpec pspec);
	}
	[CCode (lower_case_csuffix = "object_class")]
	public class ObjectClass : GLib.TypeClass {
		public unowned GLib.ParamSpec? find_property (string property_name);
		[CCode (cname = "G_OBJECT_CLASS_NAME")]
		public unowned string get_name ();
		[CCode (cname = "G_OBJECT_CLASS_TYPE")]
		public GLib.Type get_type ();
		public void install_properties ([CCode (array_length_pos = 0.9, array_length_type = "guint")] GLib.ParamSpec[] pspecs);
		public void install_property (uint property_id, GLib.ParamSpec pspec);
		[CCode (array_length_type = "guint")]
#if VALA_0_26
		public (unowned GLib.ParamSpec)[] list_properties ();
#else
		public unowned GLib.ParamSpec[] list_properties ();
#endif
		public void override_property (uint property_id, string name);
	}
	[CCode (get_value_function = "g_value_get_param", param_spec_function = "g_param_spec_param", ref_function = "g_param_spec_ref", set_value_function = "g_value_set_param", take_value_function = "g_value_take_param", type_id = "G_TYPE_PARAM", unref_function = "g_param_spec_unref")]
	public class ParamSpec {
		public GLib.ParamFlags flags;
		public string name;
		public GLib.Type owner_type;
		public GLib.Type value_type;
		[NoWrapper]
		public virtual void finalize ();
		public unowned string get_blurb ();
		[Version (since = "2.38")]
		public unowned GLib.Value? get_default_value ();
		public unowned string get_name ();
		[Version (since = "2.46")]
		public GLib.Quark get_name_quark ();
		public unowned string get_nick ();
		public void* get_qdata (GLib.Quark quark);
		public unowned GLib.ParamSpec get_redirect_target ();
		[CCode (cname = "g_param_spec_internal")]
		public ParamSpec.@internal (GLib.Type param_type, string name, string nick, string blurb, GLib.ParamFlags flags);
		public unowned GLib.ParamSpec @ref ();
		public unowned GLib.ParamSpec ref_sink ();
		public void set_qdata (GLib.Quark quark, void* data);
		public void set_qdata_full (GLib.Quark quark, void* data, GLib.DestroyNotify destroy);
		[CCode (cname = "g_param_value_set_default")]
		public void set_value_default (ref GLib.Value value);
		public void sink ();
		public void* steal_qdata (GLib.Quark quark);
		public void unref ();
		[CCode (cname = "g_param_value_convert")]
		public bool value_convert (GLib.Value src_value, ref GLib.Value dest_value, bool strict_validation);
		[CCode (cname = "g_param_value_defaults")]
		public bool value_defaults (GLib.Value value);
		[CCode (cname = "g_param_value_validate")]
		public bool value_validate (GLib.Value value);
		[CCode (cname = "g_param_values_cmp")]
		public int values_cmp (GLib.Value value1, GLib.Value value2);
	}
	[CCode (type_id = "G_TYPE_PARAM_BOOLEAN")]
	public class ParamSpecBoolean : GLib.ParamSpec {
		public bool default_value;
		[CCode (cname = "g_param_spec_boolean")]
		public ParamSpecBoolean (string name, string nick, string blurb, bool defaultvalue, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_BOXED")]
	public class ParamSpecBoxed : GLib.ParamSpec {
		[CCode (cname = "g_param_spec_boxed")]
		public ParamSpecBoxed (string name, string nick, string blurb, GLib.Type boxed_type, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_CHAR")]
	public class ParamSpecChar : GLib.ParamSpec {
		public int8 default_value;
		public int8 maximum;
		public int8 minimum;
		[CCode (cname = "g_param_spec_char")]
		public ParamSpecChar (string name, string nick, string blurb, int8 minimum, int8 maximum, int8 default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_DOUBLE")]
	public class ParamSpecDouble : GLib.ParamSpec {
		public double default_value;
		public double maximum;
		public double minimum;
		[CCode (cname = "g_param_spec_double")]
		public ParamSpecDouble (string name, string nick, string blurb, double minimum, double maximum, double default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_ENUM")]
	public class ParamSpecEnum : GLib.ParamSpec {
		public int default_value;
		public weak GLib.EnumClass enum_class;
		[CCode (cname = "g_param_spec_enum")]
		public ParamSpecEnum (string name, string nick, string blurb, GLib.Type enum_type, int default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_FLAGS")]
	public class ParamSpecFlags : GLib.ParamSpec {
		public uint default_value;
		public weak GLib.FlagsClass flags_class;
		[CCode (cname = "g_param_spec_flags")]
		public ParamSpecFlags (string name, string nick, string blurb, GLib.Type flags_type, uint default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_FLOAT")]
	public class ParamSpecFloat : GLib.ParamSpec {
		public float default_value;
		public float maximum;
		public float minimum;
		[CCode (cname = "g_param_spec_float")]
		public ParamSpecFloat (string name, string nick, string blurb, float minimum, float maximum, float default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_GTYPE")]
	public class ParamSpecGType : GLib.ParamSpec {
		public GLib.Type is_a_type;
		[CCode (cname = "g_param_spec_gtype")]
		public ParamSpecGType (string name, string nick, string blurb, GLib.Type is_a_type, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_INT")]
	public class ParamSpecInt : GLib.ParamSpec {
		public int default_value;
		public int maximum;
		public int minimum;
		[CCode (cname = "g_param_spec_int")]
		public ParamSpecInt (string name, string nick, string blurb, int minimum, int maximum, int default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_INT64")]
	public class ParamSpecInt64 : GLib.ParamSpec {
		public int64 default_value;
		public int64 maximum;
		public int64 minimum;
		[CCode (cname = "g_param_spec_int64")]
		public ParamSpecInt64 (string name, string nick, string blurb, int64 minimum, int64 maximum, int64 default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_LONG")]
	public class ParamSpecLong : GLib.ParamSpec {
		public long default_value;
		public long maximum;
		public long minimum;
		[CCode (cname = "g_param_spec_long")]
		public ParamSpecLong (string name, string nick, string blurb, long minimum, long maximum, long default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_OBJECT")]
	public class ParamSpecObject : GLib.ParamSpec {
		[CCode (cname = "g_param_spec_object")]
		public ParamSpecObject (string name, string nick, string blurb, GLib.Type object_type, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_PARAM")]
	public class ParamSpecParam : GLib.ParamSpec {
		[CCode (cname = "g_param_spec_param")]
		public ParamSpecParam (string name, string nick, string blurb, GLib.Type param_type, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_POINTER")]
	public class ParamSpecPointer : GLib.ParamSpec {
		[CCode (cname = "g_param_spec_pointer")]
		public ParamSpecPointer (string name, string nick, string blurb, GLib.ParamFlags flags);
	}
	[Compact]
	public class ParamSpecPool {
		public ParamSpecPool (bool type_prefixing = false);
		public void insert (GLib.ParamSpec pspec, GLib.Type owner_type);
		[CCode (array_length_pos = 1.1, array_length_type = "guint")]
#if VALA_0_26
		public (unowned GLib.ParamSpec)[] list (GLib.Type owner_type);
#else
		public unowned GLib.ParamSpec[] list (GLib.Type owner_type);
#endif
		public GLib.List<weak GLib.ParamSpec> list_owned (GLib.Type owner_type);
		public unowned GLib.ParamSpec lookup (string param_name, GLib.Type owner_type, bool walk_ancestors);
		public void remove (GLib.ParamSpec pspec);
	}
	[CCode (type_id = "G_TYPE_PARAM_STRING")]
	public class ParamSpecString : GLib.ParamSpec {
		public string cset_first;
		public string cset_nth;
		public string default_value;
		public uint ensure_non_null;
		public uint null_fold_if_empty;
		public char substitutor;
		[CCode (cname = "g_param_spec_string")]
		public ParamSpecString (string name, string nick, string blurb, string default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_UCHAR")]
	public class ParamSpecUChar : GLib.ParamSpec {
		public uint8 default_value;
		public uint8 maximum;
		public uint8 minimum;
		[CCode (cname = "g_param_spec_uchar")]
		public ParamSpecUChar (string name, string nick, string blurb, uint8 minimum, uint8 maximum, uint8 default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_UINT")]
	public class ParamSpecUInt : GLib.ParamSpec {
		public uint default_value;
		public uint maximum;
		public uint minimum;
		[CCode (cname = "g_param_spec_uint")]
		public ParamSpecUInt (string name, string nick, string blurb, uint minimum, uint maximum, uint default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_UINT64")]
	public class ParamSpecUInt64 : GLib.ParamSpec {
		public uint64 default_value;
		public uint64 maximum;
		public uint64 minimum;
		[CCode (cname = "g_param_spec_uint64")]
		public ParamSpecUInt64 (string name, string nick, string blurb, uint64 minimum, uint64 maximum, uint64 default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_ULONG")]
	public class ParamSpecULong : GLib.ParamSpec {
		public ulong default_value;
		public ulong maximum;
		public ulong minimum;
		[CCode (cname = "g_param_spec_ulong")]
		public ParamSpecULong (string name, string nick, string blurb, ulong minimum, ulong maximum, ulong default_value, GLib.ParamFlags flags);
	}
	[CCode (type_id = "G_TYPE_PARAM_UNICHAR")]
	public class ParamSpecUnichar : GLib.ParamSpec {
		public unichar default_value;
		[CCode (cname = "g_param_spec_unichar")]
		public ParamSpecUnichar (string name, string nick, string blurb, unichar default_value, GLib.ParamFlags flags);
	}
	[Version (since = "2.26")]
	[CCode (type_id = "G_TYPE_PARAM_VARIANT")]
	public class ParamSpecVariant : GLib.ParamSpec {
		public GLib.Variant? default_value;
		public GLib.VariantType type;
		[CCode (cname = "g_param_spec_variant")]
		public ParamSpecVariant (string name, string nick, string blurb, GLib.VariantType type, GLib.Variant? default_value, GLib.ParamFlags flags);
	}
	[CCode (free_function = "g_type_class_unref", lower_case_csuffix = "type_class")]
	[Compact]
	public class TypeClass {
		[Version (deprecated = true, deprecated_since = "2.58")]
		public void add_private (size_t private_size);
		[Version (since = "2.38")]
		public void adjust_private_offset (ref int private_size_or_offset);
		[Version (since = "2.38")]
		public int get_instance_private_offset ();
		[CCode (cname = "G_TYPE_FROM_CLASS")]
		public GLib.Type get_type ();
		[CCode (cname = "g_type_interface_peek")]
		public unowned GLib.TypeInterface? peek (GLib.Type iface_type);
		public unowned GLib.TypeClass? peek_parent ();
	}
	[CCode (lower_case_csuffix = "type_instance")]
	[Compact]
	public class TypeInstance {
	}
	[CCode (free_function = "g_type_default_interface_unref", lower_case_csuffix = "type_interface")]
	[Compact]
	public class TypeInterface {
		public void add_prerequisite ();
		public unowned GLib.TypePlugin get_plugin (GLib.Type interface_type);
		[CCode (cname = "G_TYPE_FROM_INTERFACE")]
		public GLib.Type get_type ();
		public unowned GLib.TypeInterface? peek_parent ();
	}
	[CCode (cheader_filename = "glib-object.h", lower_case_csuffix = "type_module", type_id = "g_type_module_get_type ()")]
	public abstract class TypeModule : GLib.Object, GLib.TypePlugin {
		[CCode (has_construct_function = false)]
		protected TypeModule ();
		public void add_interface (GLib.Type instance_type, GLib.Type interface_type, GLib.InterfaceInfo interface_info);
		[NoWrapper]
		public virtual bool load ();
		[Version (since = "2.6")]
		public GLib.Type register_enum (string name, GLib.EnumValue const_static_values);
		[Version (since = "2.6")]
		public GLib.Type register_flags (string name, GLib.FlagsValue const_static_values);
		public GLib.Type register_type (GLib.Type parent_type, string type_name, GLib.TypeInfo type_info, GLib.TypeFlags flags);
		public void set_name (string name);
		[NoWrapper]
		public virtual void unload ();
		public void unuse ();
		public bool use ();
	}
	[CCode (copy_function = "g_value_array_copy", free_function = "g_value_array_free", type_id = "G_TYPE_VALUE_ARRAY")]
	[Compact]
	[Version (deprecated = true, deprecated_since = "2.32")]
	public class ValueArray {
		public uint n_values;
		[CCode (array_length_cname = "n_values", array_length_type = "guint")]
		public GLib.Value[] values;
		public ValueArray (uint n_prealloced);
		public void append (GLib.Value value);
		public GLib.ValueArray copy ();
		public unowned GLib.Value? get_nth (uint index_);
		public void insert (uint index_, GLib.Value value);
		public void prepend (GLib.Value value);
		public void remove (uint index_);
		public void sort (GLib.CompareFunc<GLib.Value?> compare_func);
		public void sort_with_data (GLib.CompareDataFunc<GLib.Value?> compare_func);
	}
	[CCode (cheader_filename = "glib-object.h", lower_case_csuffix = "type_plugin", type_id = "g_type_plugin_get_type ()")]
	public interface TypePlugin {
		public void complete_interface_info (GLib.Type instance_type, GLib.Type interface_type, GLib.InterfaceInfo info);
		public void complete_type_info (GLib.Type g_type, GLib.TypeInfo info, GLib.TypeValueTable value_table);
		public void unuse ();
		public void use ();
	}
	[CCode (has_type_id = false)]
	public struct EnumValue {
		public int value;
		public weak string value_name;
		public weak string value_nick;
	}
	[CCode (has_type_id = false)]
	public struct FlagsValue {
		public uint value;
		public weak string value_name;
		public weak string value_nick;
	}
	[CCode (has_type_id = false)]
	public struct InterfaceInfo {
		public GLib.InterfaceInitFunc interface_init;
		public GLib.InterfaceFinalizeFunc interface_finalize;
		public void* interface_data;
	}
	[CCode (has_copy_function = false, has_destroy_function = false)]
	public struct ObjectConstructParam {
		public ParamSpec pspec;
		public GLib.Value value;
	}
	[CCode (has_copy_function = false, has_destroy_function = false)]
	[Version (deprecated = true, deprecated_since = "2.54")]
	public struct Parameter {
		public weak string name;
		public GLib.Value value;
	}
	public struct SignalInvocationHint {
		public uint signal_id;
		public GLib.Quark detail;
		public GLib.SignalFlags run_type;
	}
	public struct SignalQuery {
		public uint signal_id;
		public weak string signal_name;
		public GLib.Type itype;
		public GLib.SignalFlags signal_flags;
		public GLib.Type return_type;
		public uint n_params;
		[CCode (array_length_cname = "n_params", array_length_type = "guint")]
		public weak GLib.Type[] param_types;
	}
	[CCode (get_value_function = "g_value_get_gtype", marshaller_type_name = "GTYPE", set_value_function = "g_value_set_gtype", type_id = "G_TYPE_GTYPE")]
	[GIR (fullname = "GType")]
	public struct Type : ulong {
		public const GLib.Type BOOLEAN;
		public const GLib.Type BOXED;
		public const GLib.Type CHAR;
		public const GLib.Type DOUBLE;
		public const GLib.Type ENUM;
		public const GLib.Type FLAGS;
		public const GLib.Type FLOAT;
		public const GLib.Type INT;
		public const GLib.Type INT64;
		public const GLib.Type INTERFACE;
		public const GLib.Type INVALID;
		public const GLib.Type LONG;
		public const GLib.Type NONE;
		public const GLib.Type OBJECT;
		public const GLib.Type PARAM;
		public const GLib.Type POINTER;
		public const GLib.Type STRING;
		public const GLib.Type UCHAR;
		public const GLib.Type UINT;
		public const GLib.Type UINT64;
		public const GLib.Type ULONG;
		public const GLib.Type VARIANT;
		public void add_class_private (size_t private_size);
		[CCode (array_length_type = "guint")]
		public GLib.Type[] children ();
		public unowned GLib.TypeClass? class_peek ();
		public unowned GLib.TypeClass? class_peek_parent ();
		public unowned GLib.TypeClass? class_peek_static ();
		public unowned GLib.TypeClass? default_interface_peek ();
		public GLib.TypeInterface default_interface_ref ();
		public GLib.TypeClass class_ref ();
		public uint depth ();
		[Version (since = "2.34")]
		public void ensure ();
		[CCode (cname = "g_enum_to_string")]
		[Version (since = "2.54")]
		public string enum_to_string (int @value);
		[CCode (cname = "g_flags_to_string")]
		[Version (since = "2.54")]
		public string flags_to_string (uint @value);
		[CCode (cname = "G_TYPE_FROM_INSTANCE")]
		public static GLib.Type from_instance (void* instance);
		public static GLib.Type from_name (string name);
		[Version (since = "2.44")]
		public int get_instance_count ();
		public void* get_qdata (GLib.Quark quark);
		[Version (since = "2.36")]
		public static uint get_type_registration_serial ();
		[CCode (array_length_type = "guint")]
		public GLib.Type[] interface_prerequisites ();
		[CCode (array_length_type = "guint")]
		public GLib.Type[] interfaces ();
		public GLib.Type next_base (GLib.Type root_type);
		public bool is_a (GLib.Type is_a_type);
		[CCode (cname = "G_TYPE_IS_ABSTRACT")]
		public bool is_abstract ();
		[CCode (cname = "G_TYPE_IS_CLASSED")]
		public bool is_classed ();
		[CCode (cname = "G_TYPE_IS_DEEP_DERIVABLE")]
		public bool is_deep_derivable ();
		[CCode (cname = "G_TYPE_IS_DERIVABLE")]
		public bool is_derivable ();
		[CCode (cname = "G_TYPE_IS_DERIVED")]
		public bool is_derived ();
		[CCode (cname = "G_TYPE_IS_ENUM")]
		public bool is_enum ();
		[CCode (cname = "G_TYPE_IS_FLAGS")]
		public bool is_flags ();
		[CCode (cname = "G_TYPE_IS_FUNDAMENTAL")]
		public bool is_fundamental ();
		[CCode (cname = "G_TYPE_IS_INSTANTIATABLE")]
		public bool is_instantiatable ();
		[CCode (cname = "G_TYPE_IS_INTERFACE")]
		public bool is_interface ();
		[CCode (cname = "G_TYPE_IS_OBJECT")]
		public bool is_object ();
		[CCode (cname = "G_TYPE_IS_VALUE_TYPE")]
		public bool is_value_type ();
		public unowned string name ();
		public GLib.Type parent ();
		public GLib.Quark qname ();
		public void query (out GLib.TypeQuery query);
		public void set_qdata (GLib.Quark quark, void* data);
	}
	[CCode (has_type_id = false)]
	public struct TypeInfo {
		public uint16 class_size;
		public GLib.BaseInitFunc base_init;
		public GLib.BaseFinalizeFunc base_finalize;
		public GLib.ClassInitFunc class_init;
		public GLib.ClassFinalizeFunc class_finalize;
		public void* class_data;
		public uint16 instance_size;
		public uint16 n_preallocs;
		public GLib.InstanceInitFunc instance_init;
		unowned GLib.TypeValueTable value_table;
	}
	public struct TypeQuery {
		public GLib.Type type;
		public weak string type_name;
		public uint class_size;
		public uint instance_size;
	}
	[CCode (has_type_id = false)]
	public struct TypeValueTable {
	}
	[CCode (copy_function = "g_value_copy", destroy_function = "g_value_unset", get_value_function = "g_value_get_boxed", marshaller_type_name = "BOXED", set_value_function = "g_value_set_boxed", take_value_function = "g_value_take_boxed", type_id = "G_TYPE_VALUE", type_signature = "v")]
	public struct Value {
		public Value (GLib.Type g_type);
		public void copy (ref GLib.Value dest_value);
		public void* dup_boxed ();
		public GLib.ParamSpec dup_param ();
		public GLib.Object dup_object ();
		public string dup_string ();
		[Version (since = "2.26")]
		public GLib.Variant? dup_variant ();
		public bool fits_pointer ();
		public bool get_boolean ();
		public void* get_boxed ();
		[Version (deprecated = true, deprecated_since = "2.32")]
		public char get_char ();
		public double get_double ();
		public int get_enum ();
		public uint get_flags ();
		public float get_float ();
		[Version (since = "2.12")]
		public GLib.Type get_gtype ();
		public int get_int ();
		public int64 get_int64 ();
		public long get_long ();
		public unowned GLib.Object get_object ();
		public unowned GLib.ParamSpec get_param ();
		public void* get_pointer ();
		[Version (since = "2.32")]
		public int8 get_schar ();
		public unowned string get_string ();
		public uchar get_uchar ();
		public uint get_uint ();
		public uint64 get_uint64 ();
		public ulong get_ulong ();
		[Version (since = "2.26")]
		public GLib.Variant? get_variant ();
		[CCode (cname = "G_VALUE_HOLDS")]
		public bool holds (GLib.Type type);
		public unowned GLib.Value? init (GLib.Type g_type);
		[Version (since = "2.42")]
		public void init_from_instance (void* instance);
		public void param_take_ownership (out GLib.ParamSpec param);
		public void* peek_pointer ();
		public static void register_transform_func (GLib.Type src_type, GLib.Type dest_type, GLib.ValueTransform transform_func);
		public unowned GLib.Value? reset ();
		public void set_boolean (bool v_boolean);
		public void set_boxed (void* v_boxed);
		[Version (deprecated = true, deprecated_since = "2.32")]
		public void set_char (char v_char);
		public void set_double (double v_double);
		public void set_enum (int v_enum);
		public void set_flags (uint v_flags);
		public void set_float (float v_float);
		[Version (since = "2.12")]
		public void set_gtype (GLib.Type v_gtype);
		public void set_instance (void* instance);
		public void set_int (int v_int);
		public void set_int64 (int64 v_int64);
		public void set_long (long v_long);
		public void set_object (GLib.Object? v_object);
		public void set_param (GLib.ParamSpec? param);
		public void set_pointer (void* v_pointer);
		[Version (since = "2.32")]
		public void set_schar (int8 v_char);
		public void set_static_string (string? v_string);
		public void set_string (string? v_string);
		public void set_uchar (uchar v_uchar);
		public void set_uint (uint v_uint);
		public void set_uint64 (uint64 v_uint64);
		public void set_ulong (ulong v_ulong);
		[Version (since = "2.26")]
		public void set_variant (GLib.Variant? variant);
		[CCode (cname = "g_strdup_value_contents")]
		public string strdup_contents ();
		public void take_boxed (owned void* v_boxed);
		public void take_object (owned GLib.Object? v_object);
		public void take_param (owned GLib.ParamSpec? param);
		public void take_string (owned string? v_string);
		[Version (since = "2.26")]
		public void take_variant (owned GLib.Variant? variant);
		public bool transform (ref GLib.Value dest_value);
		[CCode (cname = "G_VALUE_TYPE")]
		public GLib.Type type ();
		public static bool type_compatible (GLib.Type src_type, GLib.Type dest_type);
		[CCode (cname = "G_VALUE_TYPE_NAME")]
		public unowned string type_name ();
		public static bool type_transformable (GLib.Type src_type, GLib.Type dest_type);
		public void unset ();
	}
	[CCode (destroy_function = "g_weak_ref_clear", lvalue_access = false)]
	[Version (since = "2.32")]
	public struct WeakRef {
		public WeakRef (GLib.Object? object);
		public GLib.Object? @get ();
		public void @set (GLib.Object? object);
	}
	[CCode (cprefix = "G_BINDING_")]
	[Flags]
	[Version (since = "2.26")]
	public enum BindingFlags {
		DEFAULT,
		BIDIRECTIONAL,
		SYNC_CREATE,
		INVERT_BOOLEAN
	}
	[CCode (cprefix = "G_CONNECT_", has_type_id = false)]
	[Flags]
	public enum ConnectFlags {
		AFTER,
		SWAPPED
	}
	[CCode (cprefix = "G_PARAM_", has_type_id = false)]
	[Flags]
	public enum ParamFlags {
		READABLE,
		WRITABLE,
		CONSTRUCT,
		CONSTRUCT_ONLY,
		LAX_VALIDATION,
		STATIC_NAME,
		STATIC_NICK,
		STATIC_BLURB,
		READWRITE,
		STATIC_STRINGS,
		USER_SHIFT,
		[Version (since = "2.42")]
		EXPLICIT_NOTIFY,
		[Version (since = "2.26")]
		DEPRECATED,
		MASK
	}
	[CCode (cprefix = "G_SIGNAL_", has_type_id = false)]
	[Flags]
	public enum SignalFlags {
		RUN_FIRST,
		RUN_LAST,
		RUN_CLEANUP,
		NO_RECURSE,
		DETAILED,
		ACTION,
		NO_HOOKS,
		MUST_COLLECT,
		DEPRECATED,
		[CCode (cname = "G_SIGNAL_FLAGS_MASK")]
		MASK
	}
	[CCode (cprefix = "G_SIGNAL_MATCH_", has_type_id = false)]
	public enum SignalMatchType {
		ID,
		DETAIL,
		CLOSURE,
		FUNC,
		DATA,
		UNBLOCKED,
		MASK
	}
	[CCode (cprefix = "G_TYPE_DEBUG_", has_type_id = false)]
	[Flags]
	[Version (deprecated = true, deprecated_since = "2.36")]
	public enum TypeDebugFlags {
		NONE,
		OBJECTS,
		SIGNALS,
		INSTANCE_COUNT,
		MASK
	}
	[CCode (cprefix = "G_TYPE_FLAG_", has_type_id = false)]
	[Flags]
	public enum TypeFlags {
		ABSTRACT,
		VALUE_ABSTRACT
	}
	[CCode (cprefix = "G_TYPE_FLAG_", has_type_id = false)]
	[Flags]
	public enum TypeFundamentalFlags {
		CLASSED,
		INSTANTIATABLE,
		DERIVABLE,
		DEEP_DERIVABLE
	}
	[CCode (has_target = false)]
	public delegate void BaseInitFunc (GLib.TypeClass g_class);
	[CCode (has_target = false)]
	public delegate void BaseFinalizeFunc (GLib.TypeClass g_class);
	[Version (since = "2.26")]
	public delegate bool BindingTransformFunc (GLib.Binding binding, GLib.Value source_value, ref GLib.Value target_value);
	[CCode (has_target = false)]
	public delegate void* BoxedCopyFunc (void* boxed);
	[CCode (has_target = false)]
	public delegate void BoxedFreeFunc (void* boxed);
	[CCode (has_target = false)]
	public delegate void Callback ();
	[CCode (has_target = false)]
	public delegate void ClassInitFunc (GLib.TypeClass g_class, void* class_data);
	[CCode (has_target = false)]
	public delegate void ClassFinalizeFunc (GLib.TypeClass g_class, void* class_data);
	[CCode (has_target = false, instance_pos = 0)]
	public delegate void ClosureMarshal (GLib.Closure closure, out GLib.Value return_value, [CCode (array_length_pos = 2.9, array_length_type = "guint")] GLib.Value[] param_values, void* invocation_hint, void* marshal_data);
	[CCode (has_target = false)]
	public delegate void ClosureNotify (void* data, GLib.Closure closure);
	[CCode (has_target = false)]
	public delegate void InstanceInitFunc (GLib.TypeInstance instance, GLib.TypeClass g_class);
	[CCode (has_target = false)]
	public delegate void InterfaceInitFunc (GLib.TypeInterface g_iface, void* iface_data);
	[CCode (has_target = false)]
	public delegate void InterfaceFinalizeFunc (GLib.TypeInterface g_iface, void* iface_data);
	[CCode (cname = "GCallback", has_target = false)]
	public delegate GLib.Object ObjectConstructorFunc (GLib.Type type, [CCode (array_length_pos = 1.9, array_length_type = "guint")] GLib.ObjectConstructParam[] construct_properties);
	[CCode (has_target = false)]
	public delegate void ObjectGetPropertyFunc (GLib.Object object, uint property_id, ref GLib.Value value, GLib.ParamSpec pspec);
	[CCode (has_target = false)]
	public delegate void ObjectFinalizeFunc (GLib.Object object);
	[CCode (has_target = false)]
	public delegate void ObjectSetPropertyFunc (GLib.Object object, uint property_id, GLib.Value value, GLib.ParamSpec pspec);
	public delegate bool SignalEmissionHook (GLib.SignalInvocationHint ihint, [CCode (array_length_pos = 1.9, array_length_type = "guint")] GLib.Value[] param_values);
	[CCode (instance_pos = 0)]
	public delegate void ToggleNotify (GLib.Object object, bool is_last_ref);
	[CCode (has_target = false)]
	public delegate void TypeClassCacheFunc (void* cache_data, GLib.TypeClass g_class);
	[CCode (has_target = false)]
	public delegate void ValueTransform (GLib.Value src_value, ref GLib.Value dest_value);
	[CCode (instance_pos = 0)]
	public delegate void WeakNotify (GLib.Object object);
	public static void source_set_closure (GLib.Source source, GLib.Closure closure);
	public static void source_set_dummy_callback (GLib.Source source);
}
