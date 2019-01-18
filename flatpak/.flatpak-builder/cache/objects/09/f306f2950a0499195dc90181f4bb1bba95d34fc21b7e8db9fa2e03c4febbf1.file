/* glib-2.0.vala
 *
 * Copyright (C) 2006-2014  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 * Copyright (C) 2007  Mathias Hasselmann
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
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 *	Raffaele Sandrini <rasa@gmx.ch>
 *	Mathias Hasselmann <mathias.hasselmann@gmx.de>
 */

[SimpleType]
[GIR (name = "gboolean")]
[CCode (cname = "gboolean", cheader_filename = "glib.h", type_id = "G_TYPE_BOOLEAN", marshaller_type_name = "BOOLEAN", get_value_function = "g_value_get_boolean", set_value_function = "g_value_set_boolean", default_value = "FALSE", type_signature = "b")]
[BooleanType]
public struct bool {
	public string to_string () {
		if (this) {
			return "true";
		} else {
			return "false";
		}
	}

	public static bool parse (string str) {
		if (str == "true") {
			return true;
		} else {
			return false;
		}
	}
	public static bool try_parse (string str, out bool result = null) {
		if (str == "true") {
			result = true;
			return true;
		} else if (str == "false") {
			result = false;
			return true;
		} else {
			result = false;
			return false;
		}
	}
}

[SimpleType]
[GIR (name = "gint8")]
[CCode (cname = "gchar", cprefix = "g_ascii_", cheader_filename = "glib.h", type_id = "G_TYPE_CHAR", marshaller_type_name = "CHAR", get_value_function = "g_value_get_schar", set_value_function = "g_value_set_schar", default_value = "\'\\0\'", type_signature = "y")]
[IntegerType (rank = 2, min = 0, max = 127)]
public struct char {
	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%c");
	public bool isalnum ();
	public bool isalpha ();
	public bool iscntrl ();
	public bool isdigit ();
	public bool isgraph ();
	public bool islower ();
	public bool isprint ();
	public bool ispunct ();
	public bool isspace ();
	public bool isupper ();
	public bool isxdigit ();
	public int digit_value ();
	public int xdigit_value ();
	public char tolower ();
	public char toupper ();

	[CCode (cname = "MIN")]
	public static char min (char a, char b);
	[CCode (cname = "MAX")]
	public static char max (char a, char b);
	[CCode (cname = "CLAMP")]
	public char clamp (char low, char high);
}

[SimpleType]
[GIR (name = "guint8")]
[CCode (cname = "guchar", cheader_filename = "glib.h", type_id = "G_TYPE_UCHAR", marshaller_type_name = "UCHAR", get_value_function = "g_value_get_uchar", set_value_function = "g_value_set_uchar", default_value = "\'\\0\'", type_signature = "y")]
[IntegerType (rank = 3, min = 0, max = 255)]
public struct uchar {
	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hhu");

	[CCode (cname = "MIN")]
	public static uchar min (uchar a, uchar b);
	[CCode (cname = "MAX")]
	public static uchar max (uchar a, uchar b);
	[CCode (cname = "CLAMP")]
	public uchar clamp (uchar low, uchar high);
}

[SimpleType]
[GIR (name = "gint")]
[CCode (cname = "gint", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", default_value_on_error = "-1", type_signature = "i")]
[IntegerType (rank = 6)]
public struct int {
	[CCode (cname = "G_MININT")]
	public const int MIN;
	[CCode (cname = "G_MAXINT")]
	public const int MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%i");

	[CCode (cname = "MIN")]
	public static int min (int a, int b);
	[CCode (cname = "MAX")]
	public static int max (int a, int b);
	[CCode (cname = "CLAMP")]
	public int clamp (int low, int high);

	[CCode (cname = "GINT_TO_POINTER")]
	public void* to_pointer ();
	[CCode (cname = "GPOINTER_TO_INT")]
	public static int from_pointer (void* p);

	[CCode (cname = "abs", cheader_filename = "stdlib.h")]
	public int abs ();

	[CCode (cname = "GINT_TO_BE")]
	public int to_big_endian ();
	[CCode (cname = "GINT_TO_LE")]
	public int to_little_endian ();

	[CCode (cname = "GINT_FROM_BE")]
	public static int from_big_endian (int val);
	[CCode (cname = "GINT_FROM_LE")]
	public static int from_little_endian (int val);

	[CCode (cname = "atoi", cheader_filename = "stdlib.h")]
	public static int parse (string str);
}

[SimpleType]
[GIR (name = "guint")]
[CCode (cname = "guint", cheader_filename = "glib.h", type_id = "G_TYPE_UINT", marshaller_type_name = "UINT", get_value_function = "g_value_get_uint", set_value_function = "g_value_set_uint", default_value = "0U", type_signature = "u")]
[IntegerType (rank = 7)]
public struct uint {
	[CCode (cname = "0")]
	public const uint MIN;
	[CCode (cname = "G_MAXUINT")]
	public const uint MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%u");

	[CCode (cname = "MIN")]
	public static uint min (uint a, uint b);
	[CCode (cname = "MAX")]
	public static uint max (uint a, uint b);
	[CCode (cname = "CLAMP")]
	public uint clamp (uint low, uint high);

	[CCode (cname = "GUINT_TO_POINTER")]
	public void* to_pointer ();
	[CCode (cname = "GPOINTER_TO_UINT")]
	public static uint from_pointer (void* p);

	[CCode (cname = "GUINT_TO_BE")]
	public uint to_big_endian ();
	[CCode (cname = "GUINT_TO_LE")]
	public uint to_little_endian ();

	[CCode (cname = "GUINT_FROM_BE")]
	public static uint from_big_endian (uint val);
	[CCode (cname = "GUINT_FROM_LE")]
	public static uint from_little_endian (uint val);
}

[SimpleType]
[GIR (name = "gshort")]
[CCode (cname = "gshort", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", default_value_on_error = "-1", type_signature = "n")]
[IntegerType (rank = 4, min = -32768, max = 32767)]
public struct short {
	[CCode (cname = "G_MINSHORT")]
	public const short MIN;
	[CCode (cname = "G_MAXSHORT")]
	public const short MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hi");

	[CCode (cname = "MIN")]
	public static short min (short a, short b);
	[CCode (cname = "MAX")]
	public static short max (short a, short b);
	[CCode (cname = "CLAMP")]
	public short clamp (short low, short high);
	[CCode (cname = "abs", cheader_filename = "stdlib.h")]
	public short abs ();
}

[SimpleType]
[GIR (name = "gushort")]
[CCode (cname = "gushort", cheader_filename = "glib.h", type_id = "G_TYPE_UINT", marshaller_type_name = "UINT", get_value_function = "g_value_get_uint", set_value_function = "g_value_set_uint", default_value = "0U", type_signature = "q")]
[IntegerType (rank = 5, min = 0, max = 65535)]
public struct ushort {
	[CCode (cname = "0U")]
	public const ushort MIN;
	[CCode (cname = "G_MAXUSHORT")]
	public const ushort MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hu");

	[CCode (cname = "MIN")]
	public static ushort min (ushort a, ushort b);
	[CCode (cname = "MAX")]
	public static ushort max (ushort a, ushort b);
	[CCode (cname = "CLAMP")]
	public ushort clamp (ushort low, ushort high);
}

[SimpleType]
[GIR (name = "glong")]
[CCode (cname = "glong", cheader_filename = "glib.h", type_id = "G_TYPE_LONG", marshaller_type_name = "LONG", get_value_function = "g_value_get_long", set_value_function = "g_value_set_long", default_value = "0L", default_value_on_error = "-1L")]
[IntegerType (rank = 8)]
public struct long {
	[CCode (cname = "G_MINLONG")]
	public const long MIN;
	[CCode (cname = "G_MAXLONG")]
	public const long MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%li");

	[CCode (cname = "MIN")]
	public static long min (long a, long b);
	[CCode (cname = "MAX")]
	public static long max (long a, long b);
	[CCode (cname = "CLAMP")]
	public long clamp (long low, long high);
	[CCode (cname = "labs", cheader_filename = "stdlib.h")]
	public long abs ();

	[CCode (cname = "GLONG_TO_BE")]
	public long to_big_endian ();
	[CCode (cname = "GLONG_TO_LE")]
	public long to_little_endian ();

	[CCode (cname = "GLONG_FROM_BE")]
	public static long from_big_endian (long val);
	[CCode (cname = "GLONG_FROM_LE")]
	public static long from_little_endian (long val);

	[CCode (cname = "strtol", cheader_filename = "stdlib.h")]
	static long strtol (string nptr, out char* endptr, uint _base);

	public static long parse (string str) {
		return strtol (str, null, 0);
	}

	public static bool try_parse (string str, out long result = null, out unowned string unparsed = null) {
		char* endptr;
		result = strtol (str, out endptr, 0);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}
}

[SimpleType]
[GIR (name = "gulong")]
[CCode (cname = "gulong", cheader_filename = "glib.h", type_id = "G_TYPE_ULONG", marshaller_type_name = "ULONG", get_value_function = "g_value_get_ulong", set_value_function = "g_value_set_ulong", default_value = "0UL")]
[IntegerType (rank = 9)]
public struct ulong {
	[CCode (cname = "0UL")]
	public const ulong MIN;
	[CCode (cname = "G_MAXULONG")]
	public const ulong MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%lu");

	[CCode (cname = "MIN")]
	public static ulong min (ulong a, ulong b);
	[CCode (cname = "MAX")]
	public static ulong max (ulong a, ulong b);
	[CCode (cname = "CLAMP")]
	public ulong clamp (ulong low, ulong high);

	[CCode (cname = "GULONG_TO_BE")]
	public ulong to_big_endian ();
	[CCode (cname = "GULONG_TO_LE")]
	public ulong to_little_endian ();

	[CCode (cname = "GULONG_FROM_BE")]
	public static ulong from_big_endian (ulong val);
	[CCode (cname = "GULONG_FROM_LE")]
	public static ulong from_little_endian (ulong val);

	[CCode (cname = "strtoul", cheader_filename = "stdlib.h")]
	static ulong strtoul (string nptr, out char* endptr, uint _base);

	public static ulong parse (string str) {
		return strtoul (str, null, 0);
	}

	public static bool try_parse (string str, out ulong result = null, out unowned string unparsed = null) {
		char* endptr;
		result = strtoul (str, out endptr, 0);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}
}

[SimpleType]
[GIR (name = "gulong")]
[CCode (cname = "gsize", cheader_filename = "glib.h", type_id = "G_TYPE_ULONG", marshaller_type_name = "ULONG", get_value_function = "g_value_get_ulong", set_value_function = "g_value_set_ulong", default_value = "0UL")]
[IntegerType (rank = 9)]
public struct size_t {
	[CCode (cname = "0UL")]
	public const ulong MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXSIZE")]
	public const ulong MAX;

	[Version (since = "2.6")]
	[CCode (cname = "G_GSIZE_FORMAT")]
	public const string FORMAT;
	[Version (since = "2.6")]
	[CCode (cname = "G_GSIZE_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "GSIZE_TO_POINTER")]
	public void* to_pointer ();
	[CCode (cname = "GPOINTER_TO_SIZE")]
	public static size_t from_pointer (void* p);

	[CCode (cname = "MIN")]
	public static size_t min (size_t a, size_t b);
	[CCode (cname = "MAX")]
	public static size_t max (size_t a, size_t b);
	[CCode (cname = "CLAMP")]
	public size_t clamp (size_t low, size_t high);
}

[SimpleType]
[GIR (name = "glong")]
[CCode (cname = "gssize", cheader_filename = "glib.h", type_id = "G_TYPE_LONG", marshaller_type_name = "LONG", get_value_function = "g_value_get_long", set_value_function = "g_value_set_long", default_value = "0L", default_value_on_error = "-1L")]
[IntegerType (rank = 8)]
public struct ssize_t {
	[Version (since = "2.14")]
	[CCode (cname = "G_MINSSIZE")]
	public const long MIN;
	[Version (since = "2.14")]
	[CCode (cname = "G_MAXSSIZE")]
	public const long MAX;

	[Version (since = "2.6")]
	[CCode (cname = "G_GSSIZE_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GSIZE_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "MIN")]
	public static ssize_t min (ssize_t a, ssize_t b);
	[CCode (cname = "MAX")]
	public static ssize_t max (ssize_t a, ssize_t b);
	[CCode (cname = "CLAMP")]
	public ssize_t clamp (ssize_t low, ssize_t high);
}

[SimpleType]
[GIR (name = "gulong")]
[CCode (cname = "guintptr", cheader_filename = "glib.h", type_id = "G_TYPE_ULONG", marshaller_type_name = "ULONG", get_value_function = "g_value_get_ulong", set_value_function = "g_value_set_ulong", default_value = "0UL")]
[IntegerType (rank = 9)]
public struct uintptr {
	[CCode (cname = "0UL")]
	public const ulong MIN;
	[CCode (cname = "G_MAXSIZE")]
	public const ulong MAX;

	[CCode (cname = "G_GUINTPTR_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINTPTR_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "GSIZE_TO_POINTER")]
	public void* to_pointer ();
	[CCode (cname = "GPOINTER_TO_SIZE")]
	public static uintptr from_pointer (void* p);

	[CCode (cname = "MIN")]
	public static uintptr min (uintptr a, uintptr b);
	[CCode (cname = "MAX")]
	public static uintptr max (uintptr a, uintptr b);
	[CCode (cname = "CLAMP")]
	public uintptr clamp (uintptr low, uintptr high);
}

[SimpleType]
[GIR (name = "glong")]
[CCode (cname = "gintptr", cheader_filename = "glib.h", type_id = "G_TYPE_LONG", marshaller_type_name = "LONG", get_value_function = "g_value_get_long", set_value_function = "g_value_set_long", default_value = "0L")]
[IntegerType (rank = 8)]
public struct intptr {
	[CCode (cname = "G_MINSSIZE")]
	public const long MIN;
	[CCode (cname = "G_MAXSSIZE")]
	public const long MAX;

	[CCode (cname = "G_GINTPTR_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINTPTR_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "MIN")]
	public static intptr min (intptr a, intptr b);
	[CCode (cname = "MAX")]
	public static intptr max (intptr a, intptr b);
	[CCode (cname = "CLAMP")]
	public intptr clamp (intptr low, intptr high);
}

[SimpleType]
[GIR (name = "gint8")]
[CCode (cname = "gint8", cheader_filename = "glib.h", type_id = "G_TYPE_CHAR", marshaller_type_name = "CHAR", get_value_function = "g_value_get_char", set_value_function = "g_value_set_char", default_value = "0", default_value_on_error = "-1", type_signature = "y")]
[IntegerType (rank = 1, min = -128, max = 127)]
public struct int8 {
	[Version (since = "2.4")]
	[CCode (cname = "G_MININT8")]
	public const int8 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXINT8")]
	public const int8 MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hhi");

	[CCode (cname = "MIN")]
	public static int8 min (int8 a, int8 b);
	[CCode (cname = "MAX")]
	public static int8 max (int8 a, int8 b);
	[CCode (cname = "CLAMP")]
	public int8 clamp (int8 low, int8 high);
}

[SimpleType]
[GIR (name = "guint8")]
[CCode (cname = "guint8", cheader_filename = "glib.h", type_id = "G_TYPE_UCHAR", marshaller_type_name = "UCHAR", get_value_function = "g_value_get_uchar", set_value_function = "g_value_set_uchar", default_value = "0U", type_signature = "y")]
[IntegerType (rank = 3, min = 0, max = 255)]
public struct uint8 {
	[CCode (cname = "0U")]
	public const uint8 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXUINT8")]
	public const uint8 MAX;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hhu");

	[CCode (cname = "MIN")]
	public static uint8 min (uint8 a, uint8 b);
	[CCode (cname = "MAX")]
	public static uint8 max (uint8 a, uint8 b);
	[CCode (cname = "CLAMP")]
	public uint8 clamp (uint8 low, uint8 high);
}

[SimpleType]
[GIR (name = "gint16")]
[CCode (cname = "gint16", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", default_value_on_error = "-1", type_signature = "n")]
[IntegerType (rank = 4, min = -32768, max = 32767)]
public struct int16 {
	[Version (since = "2.4")]
	[CCode (cname = "G_MININT16")]
	public const int16 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXINT16")]
	public const int16 MAX;

	[CCode (cname = "G_GINT16_FORMAT")]
	public const string FORMAT;
	[Version (since = "2.4")]
	[CCode (cname = "G_GINT16_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "MIN")]
	public static int16 min (int16 a, int16 b);
	[CCode (cname = "MAX")]
	public static int16 max (int16 a, int16 b);
	[CCode (cname = "CLAMP")]
	public int16 clamp (int16 low, int16 high);

	[CCode (cname = "GINT16_TO_BE")]
	public int16 to_big_endian ();
	[CCode (cname = "GINT16_TO_LE")]
	public int16 to_little_endian ();

	[CCode (cname = "GINT16_FROM_BE")]
	public static int16 from_big_endian (int16 val);
	[CCode (cname = "GINT16_FROM_LE")]
	public static int16 from_little_endian (int16 val);
}

[SimpleType]
[GIR (name = "guint16")]
[CCode (cname = "guint16", cheader_filename = "glib.h", type_id = "G_TYPE_UINT", marshaller_type_name = "UINT", get_value_function = "g_value_get_uint", set_value_function = "g_value_set_uint", default_value = "0U", type_signature = "q")]
[IntegerType (rank = 5, min = 0, max = 65535)]
public struct uint16 {
	[CCode (cname = "0U")]
	public const uint16 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXUINT16")]
	public const uint16 MAX;

	[CCode (cname = "G_GUINT16_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINT16_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%hu");

	[CCode (cname = "MIN")]
	public static uint16 min (uint16 a, uint16 b);
	[CCode (cname = "MAX")]
	public static uint16 max (uint16 a, uint16 b);
	[CCode (cname = "CLAMP")]
	public uint16 clamp (uint16 low, uint16 high);

	[CCode (cname = "GUINT16_TO_BE")]
	public uint16 to_big_endian ();
	[CCode (cname = "GUINT16_TO_LE")]
	public uint16 to_little_endian ();

	[CCode (cname = "GUINT16_FROM_BE")]
	public static uint16 from_big_endian (uint16 val);
	[CCode (cname = "GUINT16_FROM_LE")]
	public static uint16 from_little_endian (uint16 val);

	[CCode (cname = "g_htons")]
	public static uint16 to_network (uint16 val);
	[CCode (cname = "g_ntohs")]
	public static uint16 from_network (uint16 val);

	[CCode (cname = "GUINT16_SWAP_BE_PDP")]
	public uint16 swap_big_endian_pdp ();
	[CCode (cname = "GUINT16_SWAP_LE_BE")]
	public uint16 swap_little_endian_big_endian ();
	[CCode (cname = "GUINT16_SWAP_LE_PDP")]
	public uint16 swap_little_endian_pdp ();
}

[SimpleType]
[GIR (name = "gint32")]
[CCode (cname = "gint32", cheader_filename = "glib.h", type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0", default_value_on_error = "-1", type_signature = "i")]
[IntegerType (rank = 6)]
public struct int32 {
	[Version (since = "2.4")]
	[CCode (cname = "G_MININT32")]
	public const int32 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXINT32")]
	public const int32 MAX;

	[CCode (cname = "G_GINT32_FORMAT")]
	public const string FORMAT;
	[Version (since = "2.4")]
	[CCode (cname = "G_GINT32_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%i");

	[CCode (cname = "MIN")]
	public static int32 min (int32 a, int32 b);
	[CCode (cname = "MAX")]
	public static int32 max (int32 a, int32 b);
	[CCode (cname = "CLAMP")]
	public int32 clamp (int32 low, int32 high);

	[CCode (cname = "GINT32_TO_BE")]
	public int32 to_big_endian ();
	[CCode (cname = "GINT32_TO_LE")]
	public int32 to_little_endian ();

	[CCode (cname = "GINT32_FROM_BE")]
	public static int32 from_big_endian (int32 val);
	[CCode (cname = "GINT32_FROM_LE")]
	public static int32 from_little_endian (int32 val);
}

[SimpleType]
[GIR (name = "guint32")]
[CCode (cname = "guint32", cheader_filename = "glib.h", type_id = "G_TYPE_UINT", marshaller_type_name = "UINT", get_value_function = "g_value_get_uint", set_value_function = "g_value_set_uint", default_value = "0U", type_signature = "u")]
[IntegerType (rank = 7)]
public struct uint32 {
	[CCode (cname = "0U")]
	public const uint32 MIN;
	[Version (since = "2.4")]
	[CCode (cname = "G_MAXUINT32")]
	public const uint32 MAX;

	[CCode (cname = "G_GUINT32_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINT32_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%u");

	[CCode (cname = "MIN")]
	public static uint32 min (uint32 a, uint32 b);
	[CCode (cname = "MAX")]
	public static uint32 max (uint32 a, uint32 b);
	[CCode (cname = "CLAMP")]
	public uint32 clamp (uint32 low, uint32 high);

	[CCode (cname = "GUINT32_TO_BE")]
	public uint32 to_big_endian ();
	[CCode (cname = "GUINT32_TO_LE")]
	public uint32 to_little_endian ();

	[CCode (cname = "GUINT32_FROM_BE")]
	public static uint32 from_big_endian (uint32 val);
	[CCode (cname = "GUINT32_FROM_LE")]
	public static uint32 from_little_endian (uint32 val);

	[CCode (cname = "g_htonl")]
	public static uint32 to_network (uint32 val);
	[CCode (cname = "g_ntohl")]
	public static uint32 from_network (uint32 val);

	[CCode (cname = "GUINT32_SWAP_BE_PDP")]
	public uint32 swap_big_endian_pdp ();
	[CCode (cname = "GUINT32_SWAP_LE_BE")]
	public uint32 swap_little_endian_big_endian ();
	[CCode (cname = "GUINT32_SWAP_LE_PDP")]
	public uint32 swap_little_endian_pdp ();
}

[SimpleType]
[GIR (name = "gint64")]
[CCode (cname = "gint64", cheader_filename = "glib.h", type_id = "G_TYPE_INT64", marshaller_type_name = "INT64", get_value_function = "g_value_get_int64", set_value_function = "g_value_set_int64", default_value = "0LL", default_value_on_error = "-1LL", type_signature = "x")]
[IntegerType (rank = 10)]
public struct int64 {
	[CCode (cname = "G_MININT64")]
	public const int64 MIN;
	[CCode (cname = "G_MAXINT64")]
	public const int64 MAX;

	[CCode (cname = "G_GINT64_FORMAT")]
	public const string FORMAT;
	[Version (since = "2.4")]
	[CCode (cname = "G_GINT64_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "MIN")]
	public static int64 min (int64 a, int64 b);
	[CCode (cname = "MAX")]
	public static int64 max (int64 a, int64 b);
	[CCode (cname = "CLAMP")]
	public int64 clamp (int64 low, int64 high);
	[CCode (cname = "llabs", cheader_filename = "stdlib.h")]
	public int64 abs ();

	[CCode (cname = "GINT64_TO_BE")]
	public int64 to_big_endian ();
	[CCode (cname = "GINT64_TO_LE")]
	public int64 to_little_endian ();

	[CCode (cname = "GINT64_FROM_BE")]
	public static int64 from_big_endian (int64 val);
	[CCode (cname = "GINT64_FROM_LE")]
	public static int64 from_little_endian (int64 val);

	[CCode (cname = "GUINT64_SWAP_LE_BE")]
	public uint64 swap_little_endian_big_endian ();

	[CCode (cname = "g_ascii_strtoll")]
	static int64 ascii_strtoll (string nptr, out char* endptr, uint _base);

	[Version (since = "2.12")]
	public static int64 parse (string str) {
		return ascii_strtoll (str, null, 0);
	}

	[Version (since = "2.12")]
	public static bool try_parse (string str, out int64 result = null, out unowned string unparsed = null) {
		char* endptr;
		result = ascii_strtoll (str, out endptr, 0);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}

	[CCode (cname = "g_ascii_string_to_signed")]
	[Version (since = "2.54")]
	public static bool from_string (string str, [CCode (pos = 5.1)] out int64 out_num = null, uint @base = 10U, int64 min = int64.MIN, int64 max = int64.MAX) throws GLib.NumberParserError;
}

[SimpleType]
[GIR (name = "guint64")]
[CCode (cname = "guint64", cheader_filename = "glib.h", type_id = "G_TYPE_UINT64", marshaller_type_name = "UINT64", get_value_function = "g_value_get_uint64", set_value_function = "g_value_set_uint64", default_value = "0ULL", type_signature = "t")]
[IntegerType (rank = 11)]
public struct uint64 {
	[CCode (cname = "0ULL")]
	public const uint64 MIN;
	[CCode (cname = "G_MAXUINT64")]
	public const uint64 MAX;

	[CCode (cname = "G_GUINT64_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINT64_MODIFIER")]
	public const string FORMAT_MODIFIER;

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%" + FORMAT);

	[CCode (cname = "MIN")]
	public static uint64 min (uint64 a, uint64 b);
	[CCode (cname = "MAX")]
	public static uint64 max (uint64 a, uint64 b);
	[CCode (cname = "CLAMP")]
	public uint64 clamp (uint64 low, uint64 high);

	[CCode (cname = "GUINT64_TO_BE")]
	public uint64 to_big_endian ();
	[CCode (cname = "GUINT64_TO_LE")]
	public uint64 to_little_endian ();

	[CCode (cname = "GUINT64_FROM_BE")]
	public static uint64 from_big_endian (uint64 val);
	[CCode (cname = "GUINT64_FROM_LE")]
	public static uint64 from_little_endian (uint64 val);

	[CCode (cname = "g_ascii_strtoull")]
	static uint64 ascii_strtoull (string nptr, out char* endptr, uint _base);

	public static uint64 parse (string str) {
		return ascii_strtoull (str, null, 0);
	}

	public static bool try_parse (string str, out uint64 result = null, out unowned string unparsed = null) {
		char* endptr;
		result = ascii_strtoull (str, out endptr, 0);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}

	[CCode (cname = "g_ascii_string_to_unsigned")]
	[Version (since = "2.54")]
	public static bool from_string (string str, [CCode (pos = 5.1)] out uint64 out_num = null, uint @base = 10U, uint64 min = uint64.MIN, uint64 max = uint64.MAX) throws GLib.NumberParserError;
}

[SimpleType]
[GIR (name = "gfloat")]
[CCode (cname = "gfloat", cheader_filename = "glib.h,float.h,math.h", type_id = "G_TYPE_FLOAT", marshaller_type_name = "FLOAT", get_value_function = "g_value_get_float", set_value_function = "g_value_set_float", default_value = "0.0F", default_value_on_error = "-1.0F")]
[FloatingType (rank = 1)]
public struct float {
	[CCode (cname = "FLT_ROUNDS")]
	public const int ROUNDS;
	[CCode (cname = "FLT_RADIX")]
	public const int RADIX;
	[CCode (cname = "FLT_MANT_DIG")]
	public const int MANT_DIG;
	[CCode (cname = "FLT_DIG")]
	public const int DIG;

	[CCode (cname = "FLT_MIN_EXP")]
	public const int MIN_EXP;
	[CCode (cname = "FLT_MAX_EXP")]
	public const int MAX_EXP;

	[CCode (cname = "FLT_MIN_10_EXP")]
	public const int MIN_10_EXP;
	[CCode (cname = "FLT_MAX_10_EXP")]
	public const int MAX_10_EXP;

	[CCode (cname = "FLT_EPSILON")]
	public const float EPSILON;
	[CCode (cname = "FLT_MIN")]
	public const float MIN;
	[CCode (cname = "FLT_MAX")]
	public const float MAX;

	[CCode (cname = "NAN")]
	public const float NAN;
	[CCode (cname = "INFINITY")]
	public const float INFINITY;

	[CCode (cname = "isnan")]
	public bool is_nan ();
	[CCode (cname = "isfinite")]
	public bool is_finite ();
	[CCode (cname = "isnormal")]
	public bool is_normal ();
	[CCode (cname = "isinf")]
	public int is_infinity ();

	[CCode (cname = "g_strdup_printf", instance_pos = -1)]
	public string to_string (string format = "%g");

	[CCode (cname = "MIN")]
	public static float min (float a, float b);
	[CCode (cname = "MAX")]
	public static float max (float a, float b);
	[CCode (cname = "CLAMP")]
	public float clamp (float low, float high);
	[CCode (cname = "fabsf")]
	public float abs ();

	[CCode (cname = "strtof", cheader_filename = "stdlib.h")]
	static float strtof (string nptr, out char* endptr);

	public static float parse (string str) {
		return strtof (str, null);
	}

	public static bool try_parse (string str, out float result = null, out unowned string unparsed = null) {
		char* endptr;
		result = strtof (str, out endptr);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}
}

[SimpleType]
[GIR (name = "gdouble")]
[CCode (cname = "gdouble", cheader_filename = "glib.h,float.h,math.h", type_id = "G_TYPE_DOUBLE", marshaller_type_name = "DOUBLE", get_value_function = "g_value_get_double", set_value_function = "g_value_set_double", default_value = "0.0", default_value_on_error = "-1.0", type_signature = "d")]
[FloatingType (rank = 2)]
public struct double {
	[CCode (cname = "DBL_MANT_DIG")]
	public const int MANT_DIG;
	[CCode (cname = "DBL_DIG")]
	public const int DIG;

	[CCode (cname = "DBL_MIN_EXP")]
	public const int MIN_EXP;
	[CCode (cname = "DBL_MAX_EXP")]
	public const int MAX_EXP;

	[CCode (cname = "DBL_MIN_10_EXP")]
	public const int MIN_10_EXP;
	[CCode (cname = "DBL_MAX_10_EXP")]
	public const int MAX_10_EXP;

	[CCode (cname = "DBL_EPSILON")]
	public const double EPSILON;
	[CCode (cname = "DBL_MIN")]
	public const double MIN;
	[CCode (cname = "DBL_MAX")]
	public const double MAX;

	[CCode (cname = "((double) NAN)")]
	public const double NAN;
	[CCode (cname = "((double) INFINITY)")]
	public const double INFINITY;

	[CCode (cname = "isnan")]
	public bool is_nan ();
	[CCode (cname = "isfinite")]
	public bool is_finite ();
	[CCode (cname = "isnormal")]
	public bool is_normal ();
	[CCode (cname = "isinf")]
	public int is_infinity ();

	[CCode (cname = "MIN")]
	public static double min (double a, double b);
	[CCode (cname = "MAX")]
	public static double max (double a, double b);
	[CCode (cname = "CLAMP")]
	public double clamp (double low, double high);
	[CCode (cname = "fabs")]
	public double abs ();

	[CCode (cname = "G_ASCII_DTOSTR_BUF_SIZE")]
	public const int DTOSTR_BUF_SIZE;
	[CCode (cname = "g_ascii_dtostr", instance_pos = -1)]
	public unowned string to_str (char[] buffer);
	[CCode (cname = "g_ascii_formatd", instance_pos = -1)]
	public unowned string format (char[] buffer, string format = "%g");

	public string to_string () {
		return this.to_str(new char[DTOSTR_BUF_SIZE]);
	}

	[CCode (cname = "g_ascii_strtod")]
	static double ascii_strtod (string nptr, out char* endptr);

	public static double parse (string str) {
		return ascii_strtod (str, null);
	}

	public static bool try_parse (string str, out double result = null, out unowned string unparsed = null) {
		char* endptr;
		result = ascii_strtod (str, out endptr);
		if (endptr == (char*) str + str.length) {
			unparsed = "";
			return true;
		} else {
			unparsed = (string) endptr;
			return false;
		}
	}
}

[GIR (name = "glong")]
[CCode (cheader_filename = "time.h", has_type_id = false, default_value = "0")]
[IntegerType (rank = 8)]
public struct time_t {
	[CCode (cname = "time")]
	public time_t (out time_t result = null);
}

[SimpleType]
[CCode (cheader_filename="stdarg.h", cprefix="va_", has_type_id = false, destroy_function = "va_end", lvalue_access = false)]
public struct va_list {
	[CCode (cname = "va_start")]
	public va_list ();
	[CCode (cname = "va_copy")]
	public va_list.copy (va_list src);
	[CCode (generic_type_pos = 1.1, simple_generics = true)]
	public unowned G arg<G> ();
}

[SimpleType]
[GIR (name = "gunichar")]
[CCode (cname = "gunichar", cprefix = "g_unichar_", cheader_filename = "glib.h", type_id = "G_TYPE_UINT", marshaller_type_name = "UINT", get_value_function = "g_value_get_uint", set_value_function = "g_value_set_uint", default_value = "0U", type_signature = "u")]
[IntegerType (rank = 7)]
public struct unichar {
	public bool validate ();
	public bool isalnum ();
	public bool isalpha ();
	public bool iscntrl ();
	public bool isdigit ();
	public bool isgraph ();
	public bool islower ();
	[Version (since = "2.14")]
	public bool ismark ();
	public bool isprint ();
	public bool ispunct ();
	public bool isspace ();
	public bool isupper ();
	public bool isxdigit ();
	public bool istitle ();
	public bool isdefined ();
	public bool iswide ();
	[Version (since = "2.12")]
	public bool iswide_cjk ();
	[Version (since = "2.14")]
	public bool iszerowidth ();
	public unichar toupper ();
	public unichar tolower ();
	public unichar totitle ();
	public int digit_value ();
	public int xdigit_value ();
	public GLib.UnicodeType type ();
	public GLib.UnicodeBreakType break_type ();
	[Version (since = "2.14")]
	public GLib.UnicodeScript get_script();

	public int to_utf8 (string? outbuf);

	public string to_string () {
		string str = (string) new char[7];
		this.to_utf8 (str);
		return str;
	}

	[Version (since = "2.30")]
	public bool compose (unichar b, out unichar ch);
	[Version (since = "2.30")]
	public bool decompose (out unichar a, out unichar b);
	[Version (since = "2.30")]
	public size_t fully_decompose (bool compat, unichar[] result);

	[CCode (cname = "MIN")]
	public static unichar min (unichar a, unichar b);
	[CCode (cname = "MAX")]
	public static unichar max (unichar a, unichar b);
	[CCode (cname = "CLAMP")]
	public unichar clamp (unichar low, unichar high);

	[CCode (cname = "G_UNICHAR_MAX_DECOMPOSITION_LENGTH")]
	public const int MAX_DECOMPOSITION_LENGTH;

	[CCode (cname = "G_GUINT32_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINT32_MODIFIER")]
	public const string FORMAT_MODIFIER;
}

[SimpleType]
[GIR (name = "guint16")]
[CCode (cname = "gunichar2", cheader_filename = "glib.h", default_value = "0U", type_signature = "q", has_type_id = false)]
[IntegerType (rank = 5)]
public struct unichar2 {
	[CCode (cname = "G_GUINT16_FORMAT")]
	public const string FORMAT;
	[CCode (cname = "G_GINT16_MODIFIER")]
	public const string FORMAT_MODIFIER;
}

[Compact]
[Immutable]
[GIR (name = "utf8")]
[CCode (cname = "gchar", const_cname = "const gchar", copy_function = "g_strdup", free_function = "g_free", cheader_filename = "stdlib.h,string.h,glib.h", type_id = "G_TYPE_STRING", marshaller_type_name = "STRING", param_spec_function = "g_param_spec_string", get_value_function = "g_value_get_string", set_value_function = "g_value_set_string", take_value_function = "g_value_take_string", type_signature = "s")]
public class string {
	[Version (replacement = "string.index_of")]
	[CCode (cname = "strstr")]
	public unowned string? str (string needle);
	[Version (replacement = "string.last_index_of")]
	[CCode (cname = "g_strrstr")]
	public unowned string? rstr (string needle);
	[CCode (cname = "g_strrstr_len")]
	public unowned string? rstr_len (ssize_t haystack_len, string needle);

	[CCode (cname = "strstr")]
	static char* strstr (char* haystack, char* needle);
	[CCode (cname = "g_strrstr")]
	static char* strrstr (char* haystack, char* needle);
	[CCode (cname = "g_utf8_strchr")]
	static char* utf8_strchr (char* str, ssize_t len, unichar c);
	[CCode (cname = "g_utf8_strrchr")]
	static char* utf8_strrchr (char* str, ssize_t len, unichar c);

	public int index_of (string needle, int start_index = 0) {
		char* result = strstr ((char*) this + start_index, (char*) needle);

		if (result != null) {
			return (int) (result - (char*) this);
		} else {
			return -1;
		}
	}

	public int last_index_of (string needle, int start_index = 0) {
		char* result = strrstr ((char*) this + start_index, (char*) needle);

		if (result != null) {
			return (int) (result - (char*) this);
		} else {
			return -1;
		}
	}

	public int index_of_char (unichar c, int start_index = 0) {
		char* result = utf8_strchr ((char*) this + start_index, -1, c);

		if (result != null) {
			return (int) (result - (char*) this);
		} else {
			return -1;
		}
	}

	public int last_index_of_char (unichar c, int start_index = 0) {
		char* result = utf8_strrchr ((char*) this + start_index, -1, c);

		if (result != null) {
			return (int) (result - (char*) this);
		} else {
			return -1;
		}
	}

	[Version (since = "2.2")]
	[CCode (cname = "g_str_has_prefix")]
	public bool has_prefix (string prefix);
	[Version (since = "2.2")]
	[CCode (cname = "g_str_has_suffix")]
	public bool has_suffix (string suffix);
	[CCode (cname = "g_strdup_printf"), PrintfFormat]
	public string printf (...);
	[CCode (cname = "g_strdup_vprintf")]
	public string vprintf (va_list args);
	[CCode (cname = "sscanf", cheader_filename = "stdio.h"), ScanfFormat]
	public int scanf (string format, ...);
	[CCode (cname = "g_strconcat")]
	public string concat (string string2, ...);
	[CCode (cname = "g_strescape")]
	public string escape (string? exceptions = null);
	[CCode (cname = "g_strcompress")]
	public string compress ();
	[CCode (cname = "g_strsplit", array_length = false, array_null_terminated = true)]
	public string[] split (string delimiter, int max_tokens = 0);
	[Version (since = "2.4")]
	[CCode (cname = "g_strsplit_set", array_length = false, array_null_terminated = true)]
	public string[] split_set (string delimiters, int max_tokens = 0);
	[CCode (cname = "g_stpcpy")]
	private static void* copy_to_buffer (void* dest, string src);
	[CCode (cname = "_vala_g_strjoinv")]
	public static string joinv (string? separator, string?[]? str_array) {
		if (separator == null) {
			separator = "";
		}
		if (str_array != null && (str_array.length > 0 || (str_array.length == -1 && str_array[0] != null))) {
			int i;
			size_t len = 1;
			for (i = 0 ; (str_array.length != -1 && i < str_array.length) || (str_array.length == -1 && str_array[i] != null) ; i++) {
				len += (str_array[i] != null) ? ((!) str_array[i]).length : 0;
			}
			if (i == 0) {
				return "";
			}
			str_array.length = i;
			len += ((!) separator).length * (i - 1);

			string* res = GLib.malloc (len);
			void* ptr = string.copy_to_buffer ((void*) res, (!) str_array[0]);
			for (i = 1 ; i < str_array.length ; i++) {
				ptr = string.copy_to_buffer (ptr, (!) separator);
				ptr = string.copy_to_buffer (ptr, (str_array[i] != null) ? ((!) str_array[i]) : "");
			}

			return (owned) res;
		} else {
			return "";
		}
	}
	[CCode (cname = "g_strjoin")]
	public static string join (string separator, ...);
	[CCode (cname = "g_strnfill")]
	public static string nfill (size_t length, char fill_char);

	public char get (long index) {
		return ((char*) this)[index];
	}

	// checks whether valid string character starts at specified index
	// embedded NULs are not supported by the string class
	public bool valid_char (int index) {
		uint8 c = ((uint8*) this)[index];
		if (c == 0x00 || (c >= 0x80 && c < 0xc2) || c >= 0xf5) {
			return false;
		} else {
			return true;
		}
	}

	[CCode (cname = "g_utf8_next_char")]
	public unowned string next_char ();
	[CCode (cname = "g_utf8_next_char")]
	static char* utf8_next_char (char* str);
	public bool get_next_char (ref int index, out unichar c) {
		c = utf8_get_char ((char*) this + index);
		if (c != 0) {
			index = (int) (utf8_next_char ((char*) this + index) - (char*) this);
			return true;
		} else {
			return false;
		}
	}
	[CCode (cname = "g_utf8_get_char")]
	static unichar utf8_get_char (char* str);
	public unichar get_char (long index = 0) {
		return utf8_get_char ((char*) this + index);
	}
	[CCode (cname = "g_utf8_get_char_validated")]
	public unichar get_char_validated (ssize_t max_len = -1);

	[Version (replacement = "string.index_of_nth_char")]
	[CCode (cname = "g_utf8_offset_to_pointer")]
	public unowned string utf8_offset (long offset);
	public unowned string offset (long offset) {
		return (string) ((char*) this + offset);
	}
	[Version (replacement = "string.char_count")]
	public long pointer_to_offset (string pos) {
		return (long) ((char*) pos - (char*) this);
	}

	[CCode (cname = "g_utf8_offset_to_pointer")]
	char* utf8_offset_to_pointer (long offset);

	public int index_of_nth_char (long c) {
		return (int) (this.utf8_offset_to_pointer (c) - (char*) this);
	}

	[CCode (cname = "g_utf8_prev_char")]
	public unowned string prev_char ();
	[CCode (cname = "g_utf8_prev_char")]
	static char* utf8_prev_char (char* str);
	public bool get_prev_char (ref int index, out unichar c) {
		if (0 < index) {
			index = (int) (utf8_prev_char ((char*) this + index) - (char*) this);
			c = utf8_get_char ((char*) this + index);
			return true;
		} else {
			c = 0;
			return false;
		}
	}

	[Version (replacement = "string.length")]
	[CCode (cname = "strlen")]
	public long len ();
	[Version (replacement = "string.index_of_char")]
	[CCode (cname = "g_utf8_strchr")]
	public unowned string chr (ssize_t len, unichar c);
	[Version (replacement = "string.last_index_of_char")]
	[CCode (cname = "g_utf8_strrchr")]
	public unowned string rchr (ssize_t len, unichar c);
	[Version (since = "2.2")]
	[CCode (cname = "g_utf8_strreverse")]
	public string reverse (ssize_t len = -1);
	[CCode (cname = "g_utf8_validate")]
	public bool validate (ssize_t max_len = -1, out char* end = null);
	[Version (since = "2.52")]
	[CCode (cname = "g_utf8_make_valid")]
	public string make_valid (ssize_t len = -1);
	[CCode (cname = "g_utf8_normalize")]
	public string normalize (ssize_t len = -1, GLib.NormalizeMode mode = GLib.NormalizeMode.DEFAULT);

	[CCode (cname = "g_utf8_strup")]
	public string up (ssize_t len = -1);
	[CCode (cname = "g_utf8_strdown")]
	public string down (ssize_t len = -1);
	[CCode (cname = "g_utf8_casefold")]
	public string casefold (ssize_t len = -1);
	[CCode (cname = "g_utf8_collate")]
	public int collate (string str2);
	[CCode (cname = "g_utf8_collate_key")]
	public string collate_key (ssize_t len = -1);
	[Version (since = "2.8")]
	[CCode (cname = "g_utf8_collate_key_for_filename")]
	public string collate_key_for_filename (ssize_t len = -1);

	[CCode (cname = "g_locale_to_utf8")]
	public string locale_to_utf8 (ssize_t len, out size_t bytes_read, out size_t bytes_written, out GLib.Error error = null);

	[CCode (cname = "g_strchomp")]
	public unowned string _chomp();
	public string chomp () {
		string result = this.dup ();
		result._chomp ();
		return result;
	}

	[CCode (cname = "g_strchug")]
	public unowned string _chug();
	public string chug () {
		string result = this.dup ();
		result._chug ();
		return result;
	}

	[CCode (cname = "g_strstrip")]
	public unowned string _strip ();
	public string strip () {
		string result = this.dup ();
		result._strip ();
		return result;
	}

	[CCode (cname = "g_strdelimit")]
	public unowned string _delimit (string delimiters, char new_delimiter);
	public string delimit (string delimiters, char new_delimiter) {
		string result = this.dup ();
		result._delimit (delimiters, new_delimiter);
		return result;
	}

	[CCode (cname = "g_str_hash")]
	public uint hash ();

	[Version (since = "2.40")]
	[CCode (cname = "g_str_is_ascii")]
	public bool is_ascii ();
	[Version (since = "2.40")]
	[CCode (instance_pos = "1.5", cname = "g_str_match_string")]
	public bool match_string (string search_term, bool accept_alternates);
	[Version (since = "2.40")]
	[CCode (cname = "g_str_to_ascii")]
	public string to_ascii (string? from_locale = null);
	[Version (replacement = "int.parse")]
	[CCode (cname = "atoi")]
	public int to_int ();
	[Version (replacement = "long.parse")]
	[CCode (cname = "strtol")]
	public long to_long (out unowned string endptr = null, int _base = 0);
	[Version (replacement = "double.parse")]
	[CCode (cname = "g_ascii_strtod")]
	public double to_double (out unowned string endptr = null);
	[Version (replacement = "ulong.parse")]
	[CCode (cname = "strtoul")]
	public ulong to_ulong (out unowned string endptr = null, int _base = 0);
	[Version (replacement = "int64.parse")]
	[CCode (cname = "g_ascii_strtoll")]
	public int64 to_int64 (out unowned string endptr = null, int _base = 0);
	[Version (replacement = "uint64.parse", since = "2.2")]
	[CCode (cname = "g_ascii_strtoull")]
	public uint64 to_uint64 (out unowned string endptr = null, int _base = 0);
	[CCode (cname = "g_str_tokenize_and_fold", array_length = false, array_null_terminated = true)]
	[Version (since = "2.40")]
	public string[] tokenize_and_fold (string transit_locale, [CCode (array_length = false, array_null_terminated = true)] out string[] ascii_alternates);

	[Version (replacement = "bool.parse")]
	public bool to_bool () {
		if (this == "true") {
			return true;
		} else {
			return false;
		}
	}

	[Version (replacement = "string.length")]
	[CCode (cname = "strlen")]
	public size_t size ();

	[CCode (cname = "g_ascii_strcasecmp")]
	public int ascii_casecmp (string s2);
	[CCode (cname = "g_ascii_strncasecmp")]
	public int ascii_ncasecmp (string s2, size_t n);
	[CCode (cname = "g_ascii_strup")]
	public string ascii_up (ssize_t len = -1);
	[CCode (cname = "g_ascii_strdown")]
	public string ascii_down (ssize_t len = -1);

	[CCode (cname = "g_utf8_skip")]
	public static char skip[256];

	/* modifies string in place */
	[CCode (cname = "g_strcanon")]
	public void canon (string valid_chars, char substitutor);

	[CCode (cname = "g_strdup")]
	public string dup ();
	[Version (replacement = "string.substring")]
	[CCode (cname = "g_strndup")]
	public string ndup (size_t n);

	[CCode (cname = "memchr")]
	static char* memchr (char* s, int c, size_t n);

	// strnlen is not available on all systems
	static long strnlen (char* str, long maxlen) {
		char* end = memchr (str, 0, maxlen);
		if (end == null) {
			return maxlen;
		} else {
			return (long) (end - str);
		}
	}

	[CCode (cname = "g_strndup")]
	static string strndup (char* str, size_t n);

	public string substring (long offset, long len = -1) {
		long string_length;
		if (offset >= 0 && len >= 0) {
			// avoid scanning whole string
			string_length = strnlen ((char*) this, offset + len);
		} else {
			string_length = this.length;
		}

		if (offset < 0) {
			offset = string_length + offset;
			GLib.return_val_if_fail (offset >= 0, null);
		} else {
			GLib.return_val_if_fail (offset <= string_length, null);
		}
		if (len < 0) {
			len = string_length - offset;
		}
		GLib.return_val_if_fail (offset + len <= string_length, null);
		return strndup ((char*) this + offset, len);
	}

	public string slice (long start, long end) {
		long string_length = this.length;
		if (start < 0) {
			start = string_length + start;
		}
		if (end < 0) {
			end = string_length + end;
		}
		GLib.return_val_if_fail (start >= 0 && start <= string_length, null);
		GLib.return_val_if_fail (end >= 0 && end <= string_length, null);
		GLib.return_val_if_fail (start <= end, null);
		return strndup ((char*) this + start, end - start);
	}

	public string splice (long start, long end, string? str = null) {
		long string_length = this.length;
		if (start < 0) {
			start = string_length + start;
		}
		if (end < 0) {
			end = string_length + end;
		}
		GLib.return_val_if_fail (start >= 0 && start <= string_length, null);
		GLib.return_val_if_fail (end >= 0 && end <= string_length, null);
		GLib.return_val_if_fail (start <= end, null);

		size_t str_size;
		if (str == null) {
			str_size = 0;
		} else {
			str_size = ((!)(str)).length;
		}

		string* result = GLib.malloc0 (string_length - (end - start) + str_size + 1);

		char* dest = (char*) result;

		GLib.Memory.copy (dest, this, start);
		dest += start;

		GLib.Memory.copy (dest, str, str_size);
		dest += str_size;

		GLib.Memory.copy (dest, (char*) this + end, string_length - end);

		return (owned) result;
	}

	public bool contains (string needle) {
		return strstr ((char*) this, (char*) needle) != null;
	}

	public string replace (string old, string replacement) {
		if (*((char*) this) == '\0' || *((char*) old) == '\0' || old == replacement)
			return this;

		try {
			var regex = new GLib.Regex (GLib.Regex.escape_string (old));
			return regex.replace_literal (this, -1, 0, replacement);
		} catch (GLib.RegexError e) {
			GLib.assert_not_reached ();
		}
	}

	[CCode (cname = "g_utf8_strlen")]
	public int char_count (ssize_t max = -1);

	public int length {
		[CCode (cname = "strlen")]
		get;
	}

	public uint8[] data {
		get {
			unowned uint8[] res = (uint8[]) this;
			res.length = (int) this.length;
			return res;
		}
	}

	public char[] to_utf8 () {
		var string_length = this.length;
		char[] result = new char[string_length + 1];
		result.length--;
		GLib.Memory.copy (result, this, string_length);
		return result;
	}

	public unowned string to_string () {
		return this;
	}

	[CCode (cname = "g_utf8_to_utf16")]
	public string16 to_utf16 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;
	[CCode (cname = "g_utf8_to_ucs4")]
	public string32 to_utf32 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;
	[CCode (cname = "g_utf8_to_ucs4_fast")]
	public string32 to_utf32_fast (long len = -1, out long items_written = null);

}

[Compact]
[Immutable]
[GIR (name = "gunichar")]
[CCode (cname = "gunichar", const_cname = "const gunichar", free_function = "g_free", cheader_filename = "glib.h")]
public class string32 {
	[CCode (cname = "g_ucs4_to_utf16")]
	public string16 to_utf16 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;
	[CCode (cname = "g_ucs4_to_utf8")]
	public string to_utf8 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;

	public string? to_string () {
		try {
			return this.to_utf8 ();
		} catch (GLib.ConvertError e) {
			return null;
		}
	}
}

[Compact]
[Immutable]
[GIR (name = "guint16")]
[CCode (cname = "gunichar2", const_cname = "const gunichar2", free_function = "g_free", cheader_filename = "glib.h")]
public class string16 {
	[CCode (cname = "g_utf16_to_ucs4")]
	public string32 to_utf32 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;
	[CCode (cname = "g_utf16_to_utf8")]
	public string to_utf8 (long len = -1, out long items_read = null, out long items_written = null) throws GLib.ConvertError;

	public string? to_string () {
		try {
			return this.to_utf8 ();
		} catch (GLib.ConvertError e) {
			return null;
		}
	}
}

[CCode (cprefix = "G", lower_case_cprefix = "g_", cheader_filename = "glib.h", gir_namespace = "GLib", gir_version = "2.0")]
namespace GLib {
	[CCode (lower_case_cprefix = "", cheader_filename = "math.h")]
	namespace Math {
		[CCode (cname = "G_E")]
		public const double E;

		[CCode (cname = "G_PI")]
		public const double PI;

		[CCode (cname = "G_LN2")]
		public const double LN2;

		[CCode (cname = "G_LN10")]
		public const double LN10;

		[CCode (cname = "G_PI_2")]
		public const double PI_2;

		[CCode (cname = "G_PI_4")]
		public const double PI_4;

		[CCode (cname = "G_SQRT2")]
		public const double SQRT2;

		[CCode (cname = "G_LOG_2_BASE_10")]
		public const double LOG_2_BASE_10;

		/* generated from <bits/mathcalls.h> of glibc */
		public static double acos (double x);
		public static float acosf (float x);
		public static double asin (double x);
		public static float asinf (float x);
		public static double atan (double x);
		public static float atanf (float x);
		public static double atan2 (double y, double x);
		public static float atan2f (float y, float x);
		public static double cos (double x);
		public static float cosf (float x);
		public static double sin (double x);
		public static float sinf (float x);
		public static double tan (double x);
		public static float tanf (float x);
		public static double cosh (double x);
		public static float coshf (float x);
		public static double sinh (double x);
		public static float sinhf (float x);
		public static double tanh (double x);
		public static float tanhf (float x);
		public static void sincos (double x, out double sinx, out double cosx);
		public static void sincosf (float x, out float sinx, out float cosx);
		public static double acosh (double x);
		public static float acoshf (float x);
		public static double asinh (double x);
		public static float asinhf (float x);
		public static double atanh (double x);
		public static float atanhf (float x);
		public static double exp (double x);
		public static float expf (float x);
		public static double frexp (double x, out int exponent);
		public static float frexpf (float x, out int exponent);
		public static double ldexp (double x, int exponent);
		public static float ldexpf (float x, int exponent);
		public static double log (double x);
		public static float logf (float x);
		public static double log10 (double x);
		public static float log10f (float x);
		public static double modf (double x, out double iptr);
		public static float modff (float x, out float iptr);
		[CCode (feature_test_macro = "_GNU_SOURCE")]
		public static double exp10 (double x);
		[CCode (feature_test_macro = "_GNU_SOURCE")]
		public static float exp10f (float x);
		[CCode (feature_test_macro = "_GNU_SOURCE")]
		public static double pow10 (double x);
		[CCode (feature_test_macro = "_GNU_SOURCE")]
		public static float pow10f (float x);
		public static double expm1 (double x);
		public static float expm1f (float x);
		public static double log1p (double x);
		public static float log1pf (float x);
		public static double logb (double x);
		public static float logbf (float x);
		public static double exp2 (double x);
		public static float exp2f (float x);
		public static double log2 (double x);
		public static float log2f (float x);
		public static double pow (double x, double y);
		public static float powf (float x, float y);
		public static double sqrt (double x);
		public static float sqrtf (float x);
		public static double hypot (double x, double y);
		public static float hypotf (float x, float y);
		public static double cbrt (double x);
		public static float cbrtf (float x);
		public static double ceil (double x);
		public static float ceilf (float x);
		public static double fabs (double x);
		public static float fabsf (float x);
		public static double floor (double x);
		public static float floorf (float x);
		public static double fmod (double x, double y);
		public static float fmodf (float x, float y);
		public static int isinf (double value);
		public static int isinff (float value);
		public static int finite (double value);
		public static int finitef (float value);
		public static double drem (double x, double y);
		public static float dremf (float x, float y);
		public static double significand (double x);
		public static float significandf (float x);
		public static double copysign (double x, double y);
		public static float copysignf (float x, float y);
		public static double nan (string tagb);
		public static float nanf (string tagb);
		public static int isnan (double value);
		public static int isnanf (float value);
		public static double j0 (double x0);
		public static float j0f (float x0);
		public static double j1 (double x0);
		public static float j1f (float x0);
		public static double jn (int x0, double x1);
		public static float jnf (int x0, float x1);
		public static double y0 (double x0);
		public static float y0f (float x0);
		public static double y1 (double x0);
		public static float y1f (float x0);
		public static double yn (int x0, double x1);
		public static float ynf (int x0, float x1);
		public static double erf (double x0);
		public static float erff (float x0);
		public static double erfc (double x0);
		public static float erfcf (float x0);
		public static double lgamma (double x0);
		public static float lgammaf (float x0);
		public static double tgamma (double x0);
		public static float tgammaf (float x0);
		public static double gamma (double x0);
		public static float gammaf (float x0);
		public static double lgamma_r (double x0, out int signgamp);
		public static float lgamma_rf (float x0, out int signgamp);
		public static double rint (double x);
		public static float rintf (float x);
		public static double nextafter (double x, double y);
		public static float nextafterf (float x, float y);
		public static double nexttoward (double x, double y);
		public static float nexttowardf (float x, double y);
		public static double remainder (double x, double y);
		public static float remainderf (float x, float y);
		public static double scalbn (double x, int n);
		public static float scalbnf (float x, int n);
		public static int ilogb (double x);
		public static int ilogbf (float x);
		public static double scalbln (double x, long n);
		public static float scalblnf (float x, long n);
		public static double nearbyint (double x);
		public static float nearbyintf (float x);
		public static double round (double x);
		public static float roundf (float x);
		public static double trunc (double x);
		public static float truncf (float x);
		public static double remquo (double x, double y, out int quo);
		public static float remquof (float x, float y, out int quo);
		public static long lrint (double x);
		public static long lrintf (float x);
		public static int64 llrint (double x);
		public static int64 llrintf (float x);
		public static long lround (double x);
		public static long lroundf (float x);
		public static int64 llround (double x);
		public static int64 llroundf (float x);
		public static double fdim (double x, double y);
		public static float fdimf (float x, float y);
		public static double fmax (double x, double y);
		public static float fmaxf (float x, float y);
		public static double fmin (double x, double y);
		public static float fminf (float x, float y);
		public static double fma (double x, double y, double z);
		public static float fmaf (float x, float y, float z);
		public static double scalb (double x, double n);
		public static float scalbf (float x, float n);
	}

	/* Byte order */
	[CCode (cprefix = "G_", cname = "int", has_type_id = false)]
	public enum ByteOrder {
		[CCode (cname = "G_BYTE_ORDER")]
		HOST,
		LITTLE_ENDIAN,
		BIG_ENDIAN,
		PDP_ENDIAN
	}

	public const ByteOrder BYTE_ORDER;

	/* Atomic Operations */

	[Version (since = "2.4")]
	namespace AtomicInt {
		public static int get ([CCode (type = "volatile gint *")] ref int atomic);
		public static void set ([CCode (type = "volatile gint *")] ref int atomic, int newval);
		[Version (since = "2.30")]
		public static int add ([CCode (type = "volatile gint *")] ref int atomic, int val);
		[Version (deprecated_since = "2.30", replacement = "add")]
		public static int exchange_and_add ([CCode (type = "volatile gint *")] ref int atomic, int val);
		public static bool compare_and_exchange ([CCode (type = "volatile gint *")] ref int atomic, int oldval, int newval);
		public static void inc ([CCode (type = "volatile gint *")] ref int atomic);
		public static bool dec_and_test ([CCode (type = "volatile gint *")] ref int atomic);
	}

	[Version (since = "2.4")]
	namespace AtomicPointer {
		public static void* get ([CCode (type = "volatile gpointer *")] void** atomic);
		public static void set ([CCode (type = "volatile gpointer *")] void** atomic, void* newval);
		public static bool compare_and_exchange ([CCode (type = "volatile gpointer *")] void** atomic, void* oldval, void* newval);
	}

	/* The Main Event Loop */

	[Compact]
	[CCode (ref_function = "g_main_loop_ref", unref_function = "g_main_loop_unref")]
	public class MainLoop {
		public MainLoop (MainContext? context = null, bool is_running = false);
		public void run ();
		public void quit ();
		public bool is_running ();
		public unowned MainContext get_context ();
	}

	namespace Priority {
		public const int HIGH;
		public const int DEFAULT;
		public const int HIGH_IDLE;
		public const int DEFAULT_IDLE;
		public const int LOW;
	}

	[Compact]
	[CCode (ref_function = "g_main_context_ref", unref_function = "g_main_context_unref")]
	public class MainContext {
		public MainContext ();
		public static unowned MainContext @default ();
		public bool iteration (bool may_block);
		public bool pending ();
		public unowned Source find_source_by_id (uint source_id);
		public unowned Source find_source_by_user_data (void* user_data);
		public unowned Source find_source_by_funcs_user_data (SourceFuncs funcs, void* user_data);
		public void wakeup ();
		public bool acquire ();
		public void release ();
		[Version (since = "2.10")]
		public bool is_owner ();
		public bool wait (Cond cond, Mutex mutex);
		public bool prepare (out int priority);
		public int query (int max_priority, out int timeout_, PollFD[] fds);
		public bool check (int max_priority, PollFD[] fds);
		public void dispatch ();
		public void set_poll_func (PollFunc func);
		public PollFunc get_poll_func ();
		public void add_poll (ref PollFD fd, int priority);
		public void remove_poll (ref PollFD fd);
		public int depth ();
		[Version (since = "2.12")]
		[CCode (cname = "g_main_current_source")]
		public static unowned Source current_source ();
		[Version (since = "2.22")]
		public static unowned MainContext? get_thread_default ();
		[Version (since = "2.32")]
		public static MainContext ref_thread_default ();
		[Version (since = "2.22")]
		public void push_thread_default ();
		[Version (since = "2.22")]
		public void pop_thread_default ();
		[Version (since = "2.28")]
		[CCode (cname = "g_main_context_invoke_full")]
		public void invoke (owned SourceFunc function, [CCode (pos = 0.1)] int priority = Priority.DEFAULT);
		[Version (since = "2.28")]
		public void invoke_full (int priority, owned SourceFunc function);
	}

	[CCode (has_target = false)]
	public delegate int PollFunc (PollFD[] ufds, int timeout_);

	[CCode (cname = "GSource")]
	public class TimeoutSource : Source {
		public TimeoutSource (uint interval);
		[Version (since = "2.14")]
		public TimeoutSource.seconds (uint interval);
	}

	namespace Timeout {
		[CCode (cname = "g_timeout_add_full")]
		public static uint add (uint interval, owned SourceFunc function, [CCode (pos = 0.1)] int priority = Priority.DEFAULT);
		public static uint add_full (int priority, uint interval, owned SourceFunc function);
		[Version (since = "2.14")]
		[CCode (cname = "g_timeout_add_seconds_full")]
		public static uint add_seconds (uint interval, owned SourceFunc function, [CCode (pos = 0.1)] int priority = Priority.DEFAULT);
		[Version (since = "2.14")]
		public static uint add_seconds_full (int priority, uint interval, owned SourceFunc function);
	}

	[CCode (cname = "GSource")]
	public class IdleSource : Source {
		public IdleSource ();
	}

	namespace Idle {
		[CCode (cname = "g_idle_add_full")]
		public static uint add (owned SourceFunc function, [CCode (pos = 0.1)] int priority = Priority.DEFAULT_IDLE);
		public static uint add_full (int priority, owned SourceFunc function);
		public static bool remove_by_data (void* data);
	}

	[CCode (type_id = "G_TYPE_INT", marshaller_type_name = "INT", get_value_function = "g_value_get_int", set_value_function = "g_value_set_int", default_value = "0")]
	[IntegerType (rank = 6)]
	public struct Pid : int {
		[CCode (cname = "G_PID_FORMAT")]
		[Version (since = "2.50")]
		public const string FORMAT;
	}

	public delegate void ChildWatchFunc (Pid pid, int status);

	[CCode (cname = "GSource")]
	public class ChildWatchSource : Source {
		public ChildWatchSource (Pid pid);
	}

	namespace ChildWatch {
		[Version (since = "2.4")]
		[CCode (cname = "g_child_watch_add_full")]
		public static uint add (Pid pid, owned ChildWatchFunc function, [CCode (pos = 0.1)] int priority = Priority.DEFAULT_IDLE);
		[Version (since = "2.4")]
		public static uint add_full (int priority, Pid pid, owned ChildWatchFunc function);
	}

	public struct PollFD {
		public int fd;
		public IOCondition events;
		public IOCondition revents;
	}

	[Compact]
	[CCode (ref_function = "g_source_ref", unref_function = "g_source_unref")]
	public abstract class Source {
		protected Source ();
		[Version (since = "2.12")]
		public void set_funcs (SourceFuncs funcs);
		public uint attach (MainContext? context = null);
		public void destroy ();
		[Version (since = "2.12")]
		public bool is_destroyed ();
		public void set_priority (int priority);
		public int get_priority ();
		public void set_can_recurse (bool can_recurse);
		public bool get_can_recurse ();
		public uint get_id ();
		[Version (since = "2.26")]
		public unowned string? get_name ();
		[Version (since = "2.26")]
		public void set_name (string? name);
		[Version (since = "2.26")]
		public static void set_name_by_id (uint tag, string? name);
		public unowned MainContext get_context ();
		public void set_callback (owned SourceFunc func);
		public void set_callback_indirect (void* callback_data, SourceCallbackFuncs callback_funcs);
		[Version (since = "2.36")]
		public void* add_unix_fd (int fd, IOCondition events);
		[Version (since = "2.36")]
		public void remove_unix_fd (void* tag);
		[Version (since = "2.36")]
		public void modify_unix_fd (void* tag, IOCondition new_events);
		[Version (since = "2.36")]
		public IOCondition query_unix_fd (void* tag);
		public void add_poll (ref PollFD fd);
		public void remove_poll (ref PollFD fd);
		[Version (since = "2.28")]
		public void add_child_source (Source child_source);
		[Version (since = "2.28")]
		public void remove_child_source (Source child_source);
		[Version (since = "2.28")]
		public int64 get_time ();
		[Version (deprecated_since = "2.28", replacement = "get_time")]
		public void get_current_time (out TimeVal timeval);
		[Version (since = "2.36")]
		public void set_ready_time (int64 ready_time);
		public int64 get_ready_time ();
		public static bool remove (uint id);
		public static bool remove_by_funcs_user_data (void* user_data);
		public static bool remove_by_user_data (void* user_data);
		[Version (since = "2.32")]
		[CCode (cname = "G_SOURCE_CONTINUE")]
		public const bool CONTINUE;
		[Version (since = "2.32")]
		[CCode (cname = "G_SOURCE_REMOVE")]
		public const bool REMOVE;

		protected abstract bool prepare (out int timeout_);
		protected abstract bool check ();
		protected abstract bool dispatch (SourceFunc _callback);
	}

	[CCode (has_target = false)]
	public delegate void SourceDummyMarshal ();

	[CCode (has_target = false)]
	public delegate bool SourcePrepareFunc (Source source, out int timeout_);
	[CCode (has_target = false)]
	public delegate bool SourceCheckFunc (Source source);
	[CCode (has_target = false)]
	public delegate bool SourceDispatchFunc (Source source, SourceFunc _callback);
	[CCode (has_target = false)]
	public delegate void SourceFinalizeFunc (Source source);

	public struct SourceFuncs {
		public SourcePrepareFunc prepare;
		public SourceCheckFunc check;
		public SourceDispatchFunc dispatch;
		public SourceFinalizeFunc finalize;
	}

	[CCode (has_target = false)]
	public delegate void SourceCallbackRefFunc (void* cb_data);
	[CCode (has_target = false)]
	public delegate void SourceCallbackUnrefFunc (void* cb_data);
	[CCode (has_target = false)]
	public delegate void SourceCallbackGetFunc (void* cb_data, Source source, SourceFunc func);

	[Compact]
	public class SourceCallbackFuncs {
		public SourceCallbackRefFunc @ref;
		public SourceCallbackUnrefFunc unref;
		public SourceCallbackGetFunc @get;
	}

	public delegate bool SourceFunc ();

	public errordomain ThreadError {
		AGAIN;
		public static GLib.Quark quark ();
	}

	/* Thread support */

	[CCode (scope = "async")]
	public delegate G ThreadFunc<G> ();
	public delegate void Func<G> (G data);

	[Version (since = "2.36")]
	public uint get_num_processors ();

	[CCode (has_type_id = false)]
	public enum ThreadPriority {
		LOW,
		NORMAL,
		HIGH,
		URGENT
	}

	[Compact]
	[Version (since = "2.32")]
	[CCode (ref_function = "g_thread_ref", unref_function = "g_thread_unref")]
	public class Thread<T> {
		[Version (since = "2.32")]
		public Thread (string? name, owned ThreadFunc<T> func);
		[Version (since = "2.32")]
		[CCode (cname = "g_thread_try_new")]
		public Thread.try (string? name, owned ThreadFunc<T> func) throws GLib.Error;
		public static bool supported ();
		[Version (deprecated_since = "2.32", replacement = "new Thread<T> ()")]
		[CCode (simple_generics = true)]
		public static unowned Thread<T> create<T> (owned ThreadFunc<T> func, bool joinable) throws ThreadError;
		[Version (deprecated_since = "2.32", replacement = "new Thread<T> ()")]
		[CCode (simple_generics = true)]
		public static unowned Thread<T> create_full<T> (owned ThreadFunc<T> func, ulong stack_size, bool joinable, bool bound, ThreadPriority priority) throws ThreadError;
		[CCode (simple_generics = true)]
		public static unowned Thread<T> self<T> ();
		[DestroysInstance]
		public T join ();
		[Version (deprecated_since = "2.32")]
		public void set_priority (ThreadPriority priority);
		public static void yield ();
		public static void exit (T retval);
		[Version (deprecated_since = "2.32", since = "2.10")]
		public static void @foreach (Func<Thread> thread_func);

		[CCode (cname = "g_usleep")]
		public static void usleep (ulong microseconds);
	}

	[Version (since = "2.32")]
	[CCode (destroy_function = "g_mutex_clear", lvalue_access = false)]
	public struct Mutex {
		public Mutex ();
		public void @lock ();
		public bool trylock ();
		public void unlock ();
	}

	[Version (since = "2.44")]
	[CCode (destroy_function = "g_mutex_locker_free")]
	public struct MutexLocker {
		public MutexLocker (Mutex mutex);
		public void free ();
	}

	[Version (since = "2.32")]
	[CCode (destroy_function = "g_rec_mutex_clear")]
	public struct RecMutex {
		public RecMutex ();
		public void lock ();
		public bool trylock ();
		public void unlock ();
	}

	[Version (since = "2.32")]
	[CCode (destroy_function = "g_rw_lock_clear")]
	public struct RWLock {
		public RWLock ();
		public void writer_lock ();
		public bool writer_trylock ();
		public void writer_unlock ();
		public void reader_lock ();
		public bool reader_trylock ();
		public void reader_unlock ();
	}

	[Version (deprecated_since = "2.32", replacement = "Mutex")]
	[CCode (destroy_function = "g_static_mutex_free", default_value = "G_STATIC_MUTEX_INIT")]
	public struct StaticMutex {
		public StaticMutex ();
		public void lock ();
		public bool trylock ();
		public void unlock ();
		public void lock_full ();
	}

	[Version (deprecated_since = "2.32", replacement = "RecMutex")]
	[CCode (destroy_function = "g_static_rec_mutex_free", default_value = "G_STATIC_REC_MUTEX_INIT")]
	public struct StaticRecMutex {
		public StaticRecMutex ();
		public void lock ();
		public bool trylock ();
		public void unlock ();
		public void lock_full ();
	}

	[Version (deprecated_since = "2.32", replacement = "RWLock")]
	[CCode (destroy_function = "g_static_rw_lock_free", default_value = "G_STATIC_RW_LOCK_INIT")]
	public struct StaticRWLock {
		public StaticRWLock ();
		public void reader_lock ();
		public bool reader_trylock ();
		public void reader_unlock ();
		public void writer_lock ();
		public bool writer_trylock ();
		public void writer_unlock ();
	}

	[Compact]
	[CCode (ref_function = "", unref_function = "")]
	public class Private {
		public Private (DestroyNotify? destroy_func = null);
		public void* get ();
		public void set (void* data);
		public void replace (void* data);
	}

	[CCode (destroy_function = "g_static_private_free", default_value = "G_STATIC_PRIVATE_INIT")]
	[Version (deprecated_since = "2.32")]
	public struct StaticPrivate {
		public StaticPrivate ();
		public void* get ();
		public void set (void* data, DestroyNotify? destroy_func);
	}

	[Version (since = "2.32")]
	[CCode (destroy_function = "g_cond_clear", lvalue_access = false)]
	public struct Cond {
		public Cond ();
		public void @signal ();
		public void broadcast ();
		public void wait (Mutex mutex);
		[Version (deprecated_since = "2.32", replacement = "wait_until")]
		public bool timed_wait (Mutex mutex, TimeVal abs_time);
		[Version (since = "2.32")]
		public bool wait_until (Mutex mutex, int64 end_time);
	}

	[CCode (cname = "GThreadFunc")]
	public delegate G OnceFunc<G> ();

	[Version (since = "2.4")]
	[CCode (default_value = "G_ONCE_INIT")]
	public struct Once<G> {
		[CCode (cname = "g_once")]
		public unowned G once (OnceFunc<G> function);
		[Version (since = "2.14")]
		public static bool init_enter ([CCode (ctype="volatile gsize *")] size_t *value);
		[Version (since = "2.14")]
		public static void init_leave ([CCode (ctype="volatile gsize *")] size_t *value, size_t set_value);
		public OnceStatus status;
	}

	[CCode (cprefix = "G_ONCE_STATUS_", has_type_id = false)]
	public enum OnceStatus {
		NOTCALLED,
		PROGRESS,
		READY
	}

	/* Thread Pools */

	[CCode (cname = "GFunc")]
	public delegate void ThreadPoolFunc<G> (owned G data);

	[Compact]
	[CCode (free_function = "g_thread_pool_free")]
	public class ThreadPool<T> {
		[Version (deprecated_since = "vala-0.18", replacement = "ThreadPool.with_owned_data")]
		public ThreadPool (Func<T> func, int max_threads, bool exclusive) throws ThreadError;
		[CCode (cname = "g_thread_pool_new")]
		public ThreadPool.with_owned_data (ThreadPoolFunc<T> func, int max_threads, bool exclusive) throws ThreadError;
		[Version (deprecated_since = "vala-0.18", replacement = "add")]
		public void push (T data) throws ThreadError;
		[CCode (cname = "g_thread_pool_push")]
		public void add (owned T data) throws ThreadError;
		public void set_max_threads (int max_threads) throws ThreadError;
		public int get_max_threads ();
		public uint get_num_threads ();
		[Version (since = "2.46")]
		public bool move_to_front (T data);
		public uint unprocessed ();
		[CCode (cname = "g_thread_pool_free")]
		void _free (bool immediate, bool wait);
		[CCode (cname = "vala__g_thread_pool_free_wrapper")]
		public static void free (owned ThreadPool? pool, bool immediate, bool wait) {
			ThreadPool* ptr = (owned) pool;
			if (ptr != null) {
				((ThreadPool)ptr)._free (immediate, wait);
			}
		}
		public static void set_max_unused_threads (int max_threads);
		public static int get_max_unused_threads ();
		public static uint get_num_unused_threads ();
		public static void stop_unused_threads ();
		[Version (since = "2.10")]
		public void set_sort_function (CompareDataFunc<T> func);
		[Version (since = "2.10")]
		public static void set_max_idle_time (uint interval);
		[Version (since = "2.10")]
		public static uint get_max_idle_time ();
	}

	/* Asynchronous Queues */

	[Compact]
	[CCode (ref_function = "g_async_queue_ref", unref_function = "g_async_queue_unref")]
	public class AsyncQueue<G> {
		[Version (since = "2.16")]
		[CCode (cname = "g_async_queue_new_full", simple_generics = true)]
		public AsyncQueue ();
		public void push (owned G data);
		[Version (since = "2.10")]
		public void push_sorted (owned G data, CompareDataFunc<G> func);
		public G pop ();
		public G? try_pop ();
		public G? timed_pop (ref TimeVal end_time);
		public int length ();
		[Version (since = "2.10")]
		public void sort (CompareDataFunc<G> func);
		public void @lock ();
		public void unlock ();
		public void ref_unlocked ();
		public void unref_and_unlock ();
		[Version (since = "2.46")]
		public void push_front (owned G data);
		[Version (since = "2.46")]
		public void push_front_unlocked (owned G data);
		public void push_unlocked (owned G data);
		[Version (since = "2.10")]
		public void push_sorted_unlocked (owned G data, CompareDataFunc<G> func);
		public G pop_unlocked ();
		[Version (since = "2.46")]
		public bool remove (G data);
		[Version (since = "2.46")]
		public bool remove_unlocked (G data);
		public G? try_pop_unlocked ();
		public G? timed_pop_unlocked (ref TimeVal end_time);
		public G? timeout_pop (uint64 timeout);
		public G? timeout_pop_unlocked (uint64 timeout);
		public int length_unlocked ();
		public void sort_unlocked (CompareDataFunc<G> func);
	}

	/* Memory Allocation */

	public static void* malloc (size_t n_bytes);
	public static void* malloc0 (size_t n_bytes);
	public static void* realloc (void* mem, size_t n_bytes);

	public static void* try_malloc (size_t n_bytes);
	[Version (since = "2.8")]
	public static void* try_malloc0 (size_t n_bytes);
	public static void* try_realloc (void* mem, size_t n_bytes);

	public static void free (void* mem);

	public class MemVTable {
	}

	[CCode (cname = "glib_mem_profiler_table")]
	public static MemVTable mem_profiler_table;

	public static void mem_set_vtable (MemVTable vtable);
	public static void mem_profile ();

	[CCode (cheader_filename = "string.h")]
	namespace Memory {
		[CCode (cname = "memcmp")]
		public static int cmp (void* s1, void* s2, size_t n);
		[CCode (cname = "memcpy")]
		public static void* copy (void* dest, void* src, size_t n);
		[CCode (cname = "memset")]
		public static void* set (void* dest, int src, size_t n);
		[CCode (cname = "g_memmove")]
		public static void* move (void* dest, void* src, size_t n);
		[CCode (cname = "g_memdup")]
		public static void* dup (void* mem, uint n);
	}

	[Version (since = "2.10")]
	namespace Slice {
		public static void* alloc (size_t block_size);
		public static void* alloc0 (size_t block_size);
		[Version (since = "2.14")]
		public static void* copy (size_t block_size, void* mem_block);
		[CCode (cname = "g_slice_free1")]
		public static void free (size_t block_size, void* mem_block);
		public static void free_chain_with_offset (size_t block_size, void *mem_chain, size_t next_offset);
		public static int64 get_config (SliceConfig ckey);
		[CCode (array_length_cname = "n_values", array_length_type = "guint")]
		public static int64[] get_config_state (SliceConfig ckey, int64 address);
		public static void set_config (SliceConfig ckey, int64 value);
	}

	[CCode (cprefix = "G_SLICE_CONFIG_", has_type_id = false)]
	public enum SliceConfig {
		ALWAYS_MALLOC,
		BYPASS_MAGAZINES,
		WORKING_SET_MSECS,
		COLOR_INCREMENT,
		CHUNK_SIZES,
		CONTENTION_COUNTER
	}

	/* IO Channels */

	[Compact]
	[CCode (ref_function = "g_io_channel_ref", unref_function = "g_io_channel_unref")]
	public class IOChannel {
		[CCode (cname = "g_io_channel_unix_new")]
		public IOChannel.unix_new (int fd);
		public int unix_get_fd ();
		[CCode (cname = "g_io_channel_win32_new_fd")]
		public IOChannel.win32_new_fd (int fd);
		[CCode (cname = "g_io_channel_win32_new_socket")]
		public IOChannel.win32_socket (int socket);
		[CCode (cname = "g_io_channel_win32_new_messages")]
		public IOChannel.win32_messages (size_t hwnd);
		public void init ();
		public IOChannel.file (string filename, string mode) throws FileError;
		public IOStatus read_chars (char[] buf, out size_t bytes_read) throws ConvertError, IOChannelError;
		public IOStatus read_unichar (out unichar thechar) throws ConvertError, IOChannelError;
		public IOStatus read_line (out string str_return, out size_t length, out size_t terminator_pos) throws ConvertError, IOChannelError;
		public IOStatus read_line_string (StringBuilder buffer, out size_t terminator_pos) throws ConvertError, IOChannelError;
		public IOStatus read_to_end (out string str_return, out size_t length) throws ConvertError, IOChannelError;
		public IOStatus write_chars (char[] buf, out size_t bytes_written) throws ConvertError, IOChannelError;
		public IOStatus write_unichar (unichar thechar) throws ConvertError, IOChannelError;
		public IOStatus flush () throws IOChannelError;
		public IOStatus seek_position (int64 offset, SeekType type) throws IOChannelError;
		public IOStatus shutdown (bool flush) throws IOChannelError;
		[CCode (cname = "g_io_create_watch")]
		public IOSource create_watch (IOCondition condition);
		[CCode (cname = "g_io_add_watch")]
		public uint add_watch (IOCondition condition, IOFunc func);
		[CCode (cname = "g_io_add_watch_full")]
		public uint add_watch_full (int priority, IOCondition condition, owned IOFunc func);
		public size_t get_buffer_size ();
		public void set_buffer_size (size_t size);
		public IOCondition get_buffer_condition ();
		public IOFlags get_flags ();
		public IOStatus set_flags (IOFlags flags) throws IOChannelError;
		public unowned string get_line_term (out int length);
		public void set_line_term (string line_term, int length);
		public bool get_buffered ();
		public void set_buffered (bool buffered);
		public unowned string get_encoding ();
		public IOStatus set_encoding (string? encoding) throws IOChannelError;
		public bool get_close_on_unref ();
		public void set_close_on_unref (bool do_close);
	}

	[Compact]
	[CCode (cname = "GSource")]
	public class IOSource : Source {
		[CCode (cname = "g_io_create_watch")]
		public IOSource (IOChannel channel, IOCondition condition);
		[CCode (cname = "g_source_set_callback")]
		public void set_callback ([CCode (type = "GSourceFunc")] owned IOFunc func);
	}

	[CCode (cprefix = "G_SEEK_", has_type_id = false)]
	public enum SeekType {
		CUR,
		SET,
		END
	}

	[CCode (has_type_id = false)]
	public enum IOStatus {
		ERROR,
		NORMAL,
		EOF,
		AGAIN
	}

	public errordomain IOChannelError {
		FBIG,
		INVAL,
		IO,
		ISDIR,
		NOSPC,
		NXIO,
		OVERFLOW,
		PIPE,
		FAILED;
		public static GLib.Quark quark ();
	}

	[Flags]
	[CCode (cprefix = "G_IO_")]
	public enum IOCondition {
		IN,
		OUT,
		PRI,
		ERR,
		HUP,
		NVAL
	}

	public delegate bool IOFunc (IOChannel source, IOCondition condition);

	[CCode (cprefix = "G_IO_FLAG_", has_type_id = false)]
	[Flags]
	public enum IOFlags {
		APPEND,
		NONBLOCK,
		IS_READABLE,
		IS_WRITABLE,
		IS_WRITEABLE,
		IS_SEEKABLE,
		MASK,
		GET_MASK,
		SET_MASK
	}

	/* Error Reporting */

	[Compact]
	[ErrorBase]
	[CCode (copy_function = "g_error_copy", free_function = "g_error_free")]
	public class Error {
		[PrintfFormat]
		public Error (Quark domain, int code, string format, ...);
		public Error.literal (Quark domain, int code, string message);
		[PrintfFormat]
		public Error.valist (Quark domain, int code, string format, va_list args);
		public Error copy ();
		public bool matches (Quark domain, int code);
		[CCode (cname = "g_prefix_error")]
		public static void prefix (out Error? dest, string format, ...);
		[CCode (cname = "g_propagate_error")]
		public static void propagate (out Error? dest, owned Error src);
		[CCode (cname = "g_propagate_prefixed_error")]
		public static void propagate_prefixed (out Error? dest, owned Error src, string format, ...);
		[CCode (cname = "g_set_error")]
		public static void @set (out Error? dest, Quark domain, int code, string format, ...);
		[CCode (cname = "g_set_error_literal")]
		public static void set_literal (out Error? dest, Quark domain, int code, string message);

		public Quark domain;
		public int code;
		public string message;
	}

	/* Message Output and Debugging Functions */

	[PrintfFormat]
	public static void print (string format, ...);
	public static void set_print_handler (PrintFunc func);
	[CCode (has_target = false)]
	public delegate void PrintFunc (string text);
	[PrintfFormat]
	public static void printerr (string format, ...);
	public static void set_printerr_handler (PrintFunc func);

	public static void return_if_fail (bool expr);
	[CCode (sentinel = "")]
	public static void return_val_if_fail (bool expr, ...);
	[NoReturn]
	public static void return_if_reached ();
	[NoReturn]
	[CCode (sentinel = "")]
	public static void return_val_if_reached (...);
	[Version (since = "2.16")]
	public static void warn_if_fail (bool expr);
	[Version (since = "2.16")]
	public static void warn_if_reached ();

	[Assert]
	public static void assert (bool expr);
	[Assert]
	[Version (since = "2.46")]
	public static void assert_cmpmem (uint8[] m1, uint8[] m2);
	[Assert]
	public static void assert_error (Error? error, Quark error_domain, int error_code);
	[Assert]
	[Version (since = "2.38")]
	public static void assert_false (bool expr);
	[Assert]
	[Version (since = "2.38")]
	public static void assert_true (bool expr);
	[Assert]
	[Version (since = "2.38")]
	public static void assert_null (void* expr);
	[Assert]
	public static void assert_no_error (Error? error);
	[Assert]
	[Version (since = "2.40")]
	public static void assert_nonnull (void* expr);
	[NoReturn]
	public static void assert_not_reached ();

	public static void on_error_query (string? prg_name = null);
	public static void on_error_stack_trace (string? prg_name = null);
	[CCode (cname = "G_BREAKPOINT")]
	public static void breakpoint ();

	/* Message Logging */

	[CCode (cprefix = "G_LOG_", has_type_id = false)]
	[Flags]
	public enum LogLevelFlags {
		/* log flags */
		FLAG_RECURSION,
		FLAG_FATAL,

		/* GLib log levels */
		LEVEL_ERROR,
		LEVEL_CRITICAL,
		LEVEL_WARNING,
		LEVEL_MESSAGE,
		LEVEL_INFO,
		LEVEL_DEBUG,

		LEVEL_MASK
	}

	[CCode (cprefix = "G_LOG_WRITER_", has_type_id = false)]
	[Version (since = "2.50")]
	public enum LogWriterOutput {
		HANDLED,
		UNHANDLED
	}

	[CCode (has_type_id = false, simple_generics = true)]
	[Version (since = "2.50")]
	public struct LogField<T> {
		public unowned string key;
		public unowned T @value;
		public ssize_t length;
	}

	public void logv (string? log_domain, LogLevelFlags log_level, string format, va_list args);
	[Diagnostics]
	[PrintfFormat]
	public void log (string? log_domain, LogLevelFlags log_level, string format, ...);

	[Version (since = "2.50")]
	public void log_structured (string? log_domain, LogLevelFlags log_levels, ...);
	[Version (since = "2.50")]
	public void log_structured_array (LogLevelFlags log_levels, LogField[] fields);

	[Version (since = "2.50")]
	public void log_variant (string? log_domain, LogLevelFlags log_levels, GLib.Variant fields);

	[Diagnostics]
	[PrintfFormat]
	public void message (string format, ...);
	[Diagnostics]
	[PrintfFormat]
	public void warning (string format, ...);
	[Diagnostics]
	[PrintfFormat]
	public void critical (string format, ...);
	[Diagnostics]
	[PrintfFormat]
	[NoReturn]
	public void error (string format, ...);
	[Diagnostics]
	[PrintfFormat]
	[Version (since = "2.6")]
	public void debug (string format, ...);
	[Diagnostics]
	[PrintfFormat]
	[Version (since = "2.40")]
	public void info (string format, ...);
	[CCode (cname = "G_DEBUG_HERE")]
	[Version (since = "2.50")]
	public void debug_here ();

	public delegate void LogFunc (string? log_domain, LogLevelFlags log_levels, string message);
	[Version (since = "2.50")]
	public delegate LogWriterOutput LogWriterFunc (LogLevelFlags log_level, LogField[] fields);

	namespace Log {
		public static uint set_handler (string? log_domain, LogLevelFlags log_levels, LogFunc log_func);
		[Version (since = "2.46")]
		public static void set_handler_full (string? log_domain, LogLevelFlags log_levels, owned LogFunc log_func);
		[Version (since = "2.6")]
		public static void set_default_handler (LogFunc log_func);
		[CCode (delegate_target = false)]
		public static GLib.LogFunc default_handler;
		public static LogLevelFlags set_fatal_mask (string log_domain, LogLevelFlags log_levels);
		public static LogLevelFlags set_always_fatal (LogLevelFlags log_levels);
		public static void remove_handler (string? log_domain, uint handler_id);

		public const string FILE;
		public const int LINE;
		public const string METHOD;

		[Version (since = "2.50")]
		public static void set_writer_func (owned LogWriterFunc func);
		[Version (since = "2.50")]
		public static bool writer_supports_color (int output_fd);
		[Version (since = "2.50")]
		public static bool writer_is_journald (int output_fd);
		[Version (since = "2.50")]
		public static string writer_format_fields (LogLevelFlags log_levels, LogField[] fields, bool use_color);
		[Version (since = "2.50")]
		public static LogWriterOutput writer_journald (LogLevelFlags log_levels, LogField[] fields, void* user_data);
		[Version (since = "2.50")]
		public static LogWriterOutput writer_standard_streams (LogLevelFlags log_levels, LogField[] fields, void* user_data);
		[Version (since = "2.50")]
		public static LogWriterOutput writer_default (LogLevelFlags log_levels, LogField[] fields, void* user_data);
	}

	[CCode (has_type_id = false)]
	public struct DebugKey {
		unowned string key;
		uint value;
	}

	public uint parse_debug_string (string? debug_string, DebugKey[] keys);

	/* String Utility Functions */

	public string strdup (string str);
	[CCode (array_length = false, array_null_terminated = true)]
	public string[] strdupv ([CCode (array_length = false, array_null_terminated = true)] string[] str_array);

	public void strfreev (string** str_array);
	[Version (since = "2.6")]
	public uint strv_length ([CCode (array_length = false, array_null_terminated = true)] string[] str_array);
	[Version (since = "2.44")]
	public bool strv_contains ([CCode (array_length = false, array_null_terminated = true)] string[] str_array, string str);

	[CCode (cname = "errno", cheader_filename = "errno.h")]
	public int errno;
	public unowned string strerror (int errnum);

	/* Character Set Conversions */

	public static string convert (string str, ssize_t len, string to_codeset, string from_codeset, out size_t bytes_read = null, out size_t bytes_written = null) throws ConvertError;
	public static string convert_with_fallback (string str, ssize_t len, string to_codeset, string from_codeset, string? fallback = null, out size_t bytes_read = null, out size_t bytes_written = null) throws ConvertError;
	public static string convert_with_iconv (string str, ssize_t len, IConv converter, out size_t bytes_read = null, out size_t bytes_written = null) throws ConvertError;
	public static bool get_charset (out unowned string charset);
	public static bool get_filename_charsets ([CCode (array_length = false, array_null_terminated = true)] out unowned string[] charsets);

	[SimpleType]
	public struct IConv {
		public static IConv open (string to_codeset, string from_codeset);
		[CCode (cname = "g_iconv")]
		public size_t iconv ([CCode (array_length = false)] ref char[] inbuf, ref size_t inbytes_left, [CCode (array_length = false)] ref char[] outbuf, ref size_t outbytes_left);
		public int close ();
	}

	namespace Filename {
		public static string to_utf8 (string opsysstring, ssize_t len, out size_t bytes_read, out size_t bytes_written) throws ConvertError;
		public static string from_utf8 (string utf8string, ssize_t len, out size_t bytes_read, out size_t bytes_written) throws ConvertError;
		public static string from_uri (string uri, out string hostname = null) throws ConvertError;
		public static string to_uri (string filename, string? hostname = null) throws ConvertError;
		[Version (since = "2.6")]
		public static string display_name (string filename);
		[Version (since = "2.6")]
		public static string display_basename (string filename);
	}

	public errordomain ConvertError {
		NO_CONVERSION,
		ILLEGAL_SEQUENCE,
		FAILED,
		PARTIAL_INPUT,
		BAD_URI,
		NOT_ABSOLUTE_PATH;
		public static GLib.Quark quark ();
	}

	/* Base64 Encoding */

	[Version (since = "2.12")]
	namespace Base64 {
		public static size_t encode_step (uchar[] _in, bool break_lines, char* _out, ref int state, ref int save);
		public static size_t encode_close (bool break_lines, char* _out, ref int state, ref int save);
		public static string encode (uchar[] data);
		public static size_t decode_step (char[] _in, uchar* _out, ref int state, ref uint save);
		[CCode (array_length_type = "size_t")]
		public static uchar[] decode (string text);
	}

	/* Data Checksums */

	[Version (since = "2.16")]
	[CCode (cprefix = "G_CHECKSUM_", has_type_id = false)]
	public enum ChecksumType {
		MD5,
		SHA1,
		SHA256,
		[Version (since = "2.52")]
		SHA384,
		[Version (since = "2.36")]
		SHA512;

		public ssize_t get_length ();
	}

	[Compact]
	[Version (since = "2.16")]
	[CCode (free_function = "g_checksum_free")]
	public class Checksum {
		public Checksum (ChecksumType checksum_type);
		public Checksum copy ();
		public void update ([CCode (array_length = false)] uchar[] data, size_t length);
		public unowned string get_string ();
		public void get_digest ([CCode (array_length = false)] uint8[] buffer, ref size_t digest_len);
		[CCode (cname = "g_compute_checksum_for_data")]
		public static string compute_for_data (ChecksumType checksum_type, uchar[] data);
		[CCode (cname = "g_compute_checksum_for_string")]
		public static string compute_for_string (ChecksumType checksum_type, string str, size_t length = -1);
		[Version (since = "2.34")]
		[CCode (cname = "g_compute_checksum_for_bytes")]
		public static string compute_for_bytes (ChecksumType checksum_type, Bytes data);
	}

	/* Secure HMAC Digests */

	[Compact]
	[Version (since = "2.30")]
	[CCode (ref_function = "g_hmac_ref", unref_function = "g_hmac_unref")]
	public class Hmac {
		public Hmac (ChecksumType digest_type, [CCode (array_length_type = "gsize")] uint8[] key);
		public Hmac copy ();
		public void update ([CCode (array_length_type = "gssize")] uint8[] data);
		public unowned string get_string ();
		public void get_digest ([CCode (array_length = false)] uint8[] buffer, ref size_t digest_len);
		[Version (since = "2.30")]
		[CCode (cname = "g_compute_hmac_for_data")]
		public static string compute_for_data (ChecksumType checksum_type, uint8[] key, uint8[] data);
		[Version (since = "2.30")]
		[CCode (cname = "g_compute_hmac_for_string")]
		public static string compute_for_string (ChecksumType checksum_type, uint8[] key, string str, size_t length = -1);
		[Version (since = "2.50")]
		[CCode (cname = "g_compute_hmac_for_bytes")]
		public static string compute_hmac_for_bytes (ChecksumType checksum_type, Bytes key, Bytes data);
	}

	/* Date and Time Functions */

	[CCode (has_type_id = false)]
	public struct TimeVal {
		public long tv_sec;
		public long tv_usec;

		[CCode (cname = "g_get_current_time")]
		public TimeVal ();
		[CCode (cname = "g_get_current_time")]
		public void get_current_time ();
		public void add (long microseconds);
		[Version (since = "2.12")]
		[CCode (instance_pos = -1)]
		public bool from_iso8601 (string iso_date);
		[Version (since = "2.12")]
		public string to_iso8601 ();
	}

	[Version (since = "2.28")]
	public static int64 get_monotonic_time ();
	[Version (since = "2.28")]
	public static int64 get_real_time ();

	public struct DateDay : uchar {
		[CCode (cname = "G_DATE_BAD_DAY")]
		public static DateDay BAD_DAY;

		[CCode (cname = "g_date_valid_day")]
		public bool valid ();
	}

	[CCode (cprefix = "G_DATE_", has_type_id = false)]
	public enum DateMonth {
		BAD_MONTH,
		JANUARY,
		FEBRUARY,
		MARCH,
		APRIL,
		MAY,
		JUNE,
		JULY,
		AUGUST,
		SEPTEMBER,
		OCTOBER,
		NOVEMBER,
		DECEMBER;

		[CCode (cname = "g_date_get_days_in_month")]
		public uchar get_days_in_month (DateYear year);
		[CCode (cname = "g_date_valid_month")]
		public bool valid ();
	}

	public struct DateYear : ushort {
		[CCode (cname = "G_DATE_BAD_YEAR")]
		public static DateDay BAD_YEAR;

		[CCode (cname = "g_date_is_leap_year")]
		public bool is_leap_year ();
		[CCode (cname = "g_date_get_monday_weeks_in_year")]
		public uchar get_monday_weeks_in_year ();
		[CCode (cname = "g_date_get_sunday_weeks_in_year")]
		public uchar get_sunday_weeks_in_year ();
		[CCode (cname = "g_date_valid_year")]
		public bool valid ();
	}

	[CCode (cprefix = "G_DATE_", has_type_id = false)]
	public enum DateWeekday {
		BAD_WEEKDAY,
		MONDAY,
		TUESDAY,
		WEDNESDAY,
		THURSDAY,
		FRIDAY,
		SATURDAY,
		SUNDAY;

		[CCode (cname = "g_date_valid_weekday")]
		public bool valid ();
	}

	[CCode (cprefix = "G_DATE_", has_type_id = false)]
	public enum DateDMY {
		DAY,
		MONTH,
		YEAR
	}

	[CCode (type_id = "G_TYPE_DATE")]
	public struct Date {
		public void clear (uint n_dates = 1);
		[Version (since = "2.56")]
		public Date copy ();
		public void set_day (DateDay day);
		public void set_month (DateMonth month);
		public void set_year (DateYear year);
		public void set_dmy (DateDay day, int month, DateYear y);
		public void set_julian (uint julian_day);
		[Version (since = "2.10")]
		public void set_time_t (time_t timet);
		[Version (since = "2.10")]
		public void set_time_val (TimeVal timeval);
		public void set_parse (string str);
		public void add_days (uint n_days);
		public void subtract_days (uint n_days);
		public void add_months (uint n_months);
		public void subtract_months (uint n_months);
		public void add_years (uint n_years);
		public void subtract_years (uint n_years);
		public int days_between (Date date2);
		public int compare (Date rhs);
		public void clamp (Date min_date, Date max_date);
		public void order (Date date2);
		public DateDay get_day ();
		public DateMonth get_month ();
		public DateYear get_year ();
		public uint get_julian ();
		public DateWeekday get_weekday ();
		public uint get_day_of_year ();
		public bool is_first_of_month ();
		public bool is_last_of_month ();
		public uint get_monday_week_of_year ();
		public uint get_sunday_week_of_year ();
		[Version (since = "2.6")]
		public uint get_iso8601_week_of_year ();
		[CCode (instance_pos = -1)]
		public size_t strftime (char[] s, string format);
		[CCode (cname = "g_date_to_struct_tm")]
		public void to_time (out Time tm);
		public bool valid ();
		public static uchar get_days_in_month (DateMonth month, DateYear year);
		public static bool valid_day (DateDay day);
		public static bool valid_dmy (DateDay day, DateMonth month, DateYear year);
		public static bool valid_julian (uint julian_date);
		public static bool valid_weekday (DateWeekday weekday);
	}

	[CCode (cname = "struct tm", cheader_filename = "time.h", has_type_id = false)]
	public struct Time {
		[CCode (cname = "tm_sec")]
		public int second;
		[CCode (cname = "tm_min")]
		public int minute;
		[CCode (cname = "tm_hour")]
		public int hour;
		[CCode (cname = "tm_mday")]
		public int day;
		[CCode (cname = "tm_mon")]
		public int month;
		[CCode (cname = "tm_year")]
		public int year;
		[CCode (cname = "tm_wday")]
		public int weekday;
		[CCode (cname = "tm_yday")]
		public int day_of_year;
		[CCode (cname = "tm_isdst")]
		public int isdst;

		[CCode (cname = "gmtime_r", feature_test_macro = "_XOPEN_SOURCE")]
		static void gmtime_r (ref time_t time, out Time result);
		[CCode (cname = "localtime_r", feature_test_macro = "_XOPEN_SOURCE")]
		static void localtime_r (ref time_t time, out Time result);

		public static Time gm (time_t time) {
			Time result;
			gmtime_r (ref time, out result);
			return result;
		}
		public static Time local (time_t time) {
			Time result;
			localtime_r (ref time, out result);
			return result;
		}

		public string to_string () {
			return "%04d-%02d-%02d %02d:%02d:%02d".printf (year + 1900, month + 1, day, hour, minute, second);
		}

		public string format (string format) {
			var buffer = new char[64];
			this.strftime (buffer, format);
			return (string) buffer;
		}

		[CCode (cname = "mktime")]
		public time_t mktime ();

		[CCode (cname = "strftime", instance_pos = -1)]
		public size_t strftime (char[] s, string format);
		[CCode (cname = "strptime", instance_pos = -1, feature_test_macro = "_XOPEN_SOURCE")]
		public unowned string? strptime (string buf, string format);
	}

	[SimpleType]
	[Version (since = "2.26")]
	[CCode (cheader_filename = "glib.h", type_id = "G_TYPE_INT64", marshaller_type_name = "INT64", get_value_function = "g_value_get_int64", set_value_function = "g_value_set_int64", default_value = "0LL", type_signature = "x")]
	[IntegerType (rank = 10)]
	public struct TimeSpan : int64 {
		public const TimeSpan DAY;
		public const TimeSpan HOUR;
		public const TimeSpan MINUTE;
		public const TimeSpan SECOND;
		public const TimeSpan MILLISECOND;
	}

	[Compact]
	[Version (since = "2.26")]
	[CCode (ref_function = "g_date_time_ref", unref_function = "g_date_time_unref", type_id = "G_TYPE_DATE_TIME")]
	public class DateTime {
		public DateTime.now (TimeZone tz = new TimeZone.local ());
		public DateTime.now_local ();
		public DateTime.now_utc ();
		[Version (since = "2.56")]
		public DateTime.from_iso8601 (string text, TimeZone default_tz);
		public DateTime.from_unix_local (int64 t);
		public DateTime.from_unix_utc (int64 t);
		public DateTime.from_timeval_local (TimeVal tv);
		public DateTime.from_timeval_utc (TimeVal tv);
		public DateTime (TimeZone tz, int year, int month, int day, int hour, int minute, double seconds);
		public DateTime.local (int year, int month, int day, int hour, int minute, double seconds);
		public DateTime.utc (int year, int month, int day, int hour, int minute, double seconds);
		public DateTime add (TimeSpan timespan);
		public DateTime add_years (int years);
		public DateTime add_months (int months);
		public DateTime add_weeks (int weeks);
		public DateTime add_days (int days);
		public DateTime add_hours (int hours);
		public DateTime add_minutes (int minutes);
		public DateTime add_seconds (double seconds);
		public DateTime add_full (int years, int months, int days, int hours = 0, int minutes = 0, double seconds = 0);
		public int compare (DateTime dt);
		public TimeSpan difference (DateTime begin);
		public uint hash ();
		public bool equal (DateTime dt);
		public void get_ymd (out int year, out int month, out int day);
		public int get_year ();
		public int get_month ();
		public int get_day_of_month ();
		public int get_week_numbering_year ();
		public int get_week_of_year ();
		public int get_day_of_week ();
		public int get_day_of_year ();
		public int get_hour ();
		public int get_minute ();
		public int get_second ();
		public int get_microsecond ();
		public double get_seconds ();
		public int64 to_unix ();
		public bool to_timeval (out TimeVal tv);
		public TimeSpan get_utc_offset ();
		public unowned string get_timezone_abbreviation ();
		public bool is_daylight_savings ();
		public DateTime to_timezone (TimeZone tz);
		public DateTime to_local ();
		public DateTime to_utc ();
		public string format (string format);
		public string to_string () {
			return this.format ("%FT%H:%M:%S%z");
		}
	}

	public enum TimeType {
		STANDARD,
		DAYLIGHT,
		UNIVERSAL
	}

	[Compact]
	[Version (since = "2.26")]
	[CCode (ref_function = "g_time_zone_ref", unref_function = "g_time_zone_unref")]
	public class TimeZone {
		public TimeZone (string identifier);
		public TimeZone.utc ();
		public TimeZone.local ();
		public int find_interval (TimeType type, int64 time);
		public int adjust_time (TimeType type, ref int64 time);
		public unowned string get_abbreviation (int interval);
		public int32 get_offset (int interval);
		public bool is_dst (int interval);
	}

	/* Random Numbers */

	[Compact]
	[CCode (copy_function = "g_rand_copy", free_function = "g_rand_free")]
	public class Rand {
		public Rand.with_seed (uint32 seed);
		[Version (since = "2.4")]
		public Rand.with_seed_array ([CCode (array_length = false)] uint32[] seed, uint seed_length);
		public Rand ();
		public void set_seed (uint32 seed);
		[Version (since = "2.4")]
		public void set_seed_array ([CCode (array_length = false)] uint32[] seed, uint seed_length);
		public bool boolean ();
		[CCode (cname = "g_rand_int")]
		public uint32 next_int ();
		public int32 int_range (int32 begin, int32 end);
		[CCode (cname = "g_rand_double")]
		public double next_double ();
		public double double_range (double begin, double end);
	}

	namespace Random {
		public static void set_seed (uint32 seed);
		public static bool boolean ();
		[CCode (cname = "g_random_int")]
		public static uint32 next_int ();
		public static int32 int_range (int32 begin, int32 end);
		[CCode (cname = "g_random_double")]
		public static double next_double ();
		public static double double_range (double begin, double end);
	}

	namespace Uuid {
		[Version (since = "2.52")]
		public static bool string_is_valid (string str);
		[Version (since = "2.52")]
		public static string string_random ();
	}

	/* Miscellaneous Utility Functions */

	namespace Environment {
		[Version (since = "2.2")]
		[CCode (cname = "g_get_application_name")]
		public static unowned string? get_application_name ();
		[Version (since = "2.2")]
		[CCode (cname = "g_set_application_name")]
		public static void set_application_name (string application_name);
		[CCode (cname = "g_get_prgname")]
		public static unowned string get_prgname ();
		[CCode (cname = "g_set_prgname")]
		public static void set_prgname (string application_name);
		[CCode (cname = "g_getenv")]
		public static unowned string? get_variable (string variable);
		[Version (since = "2.4")]
		[CCode (cname = "g_setenv")]
		public static bool set_variable (string variable, string value, bool overwrite);
		[Version (since = "2.4")]
		[CCode (cname = "g_unsetenv")]
		public static void unset_variable (string variable);
		[Version (since = "2.8")]
		[CCode (cname = "g_listenv", array_length = false, array_null_terminated = true)]
		public static string[] list_variables ();
		[CCode (cname = "g_get_user_name")]
		public static unowned string get_user_name ();
		[CCode (cname = "g_get_real_name")]
		public static unowned string get_real_name ();
		[Version (since = "2.6")]
		[CCode (cname = "g_get_user_cache_dir")]
		public static unowned string get_user_cache_dir ();
		[Version (since = "2.6")]
		[CCode (cname = "g_get_user_data_dir")]
		public static unowned string get_user_data_dir ();
		[Version (since = "2.6")]
		[CCode (cname = "g_get_user_config_dir")]
		public static unowned string get_user_config_dir ();
		[CCode (cname = "g_get_user_runtime_dir")]
		public static unowned string get_user_runtime_dir ();
		[Version (since = "2.14")]
		[CCode (cname = "g_get_user_special_dir")]
		public static unowned string get_user_special_dir (UserDirectory directory);
		[Version (since = "2.6")]
		[CCode (cname = "g_get_system_data_dirs", array_length = false, array_null_terminated = true)]
		public static unowned string[] get_system_data_dirs ();
		[Version (since = "2.6")]
		[CCode (cname = "g_get_system_config_dirs", array_length = false, array_null_terminated = true)]
		public static unowned string[] get_system_config_dirs ();
		[Version (since = "2.8")]
		[CCode (cname = "g_get_host_name")]
		public static unowned string get_host_name ();
		[CCode (cname = "g_get_home_dir")]
		public static unowned string get_home_dir ();
		[CCode (cname = "g_get_tmp_dir")]
		public static unowned string get_tmp_dir ();
		[CCode (cname = "g_get_current_dir")]
		public static string get_current_dir ();
		[CCode (cname = "g_find_program_in_path")]
		public static string? find_program_in_path (string program);
		[Version (deprecated_since = "2.32")]
		[CCode (cname = "g_atexit")]
		public static void atexit (VoidFunc func);
		[Version (since = "2.8")]
		[CCode (cname = "g_chdir")]
		public static int set_current_dir (string path);
	}

	namespace Environ {
		[Version (since = "2.28")]
		[CCode (cname = "g_get_environ", array_length = false, array_null_terminated = true)]
		public static string[] get ();
		[Version (since = "2.32")]
		[CCode (cname = "g_environ_getenv")]
		public static unowned string? get_variable ([CCode (array_length = false, array_null_terminated = true)] string[]? envp, string variable);
		[Version (since = "2.32")]
		[CCode (cname = "g_environ_setenv", array_length = false, array_null_terminated = true)]
		public static string[] set_variable ([CCode (array_length = false, array_null_terminated = true)] owned string[]? envp, string variable, string value, bool overwrite = true);
		[Version (since = "2.32")]
		[CCode (cname = "g_environ_unsetenv", array_length = false, array_null_terminated = true)]
		public static string[] unset_variable ([CCode (array_length = false, array_null_terminated = true)] owned string[]? envp, string variable);
	}

	[Version (since = "2.14")]
	[CCode (has_type_id = false)]
	public enum UserDirectory {
		DESKTOP,
		DOCUMENTS,
		DOWNLOAD,
		MUSIC,
		PICTURES,
		PUBLIC_SHARE,
		TEMPLATES,
		VIDEOS,
		[CCode (cname = "G_USER_N_DIRECTORIES")]
		N_DIRECTORIES
	}

	namespace Hostname {
		public static bool is_non_ascii (string hostname);
		public static bool is_ascii_encoded (string hostname);
		public static bool is_ip_address (string hostname);
		public static string to_ascii (string hostname);
		public static string to_unicode (string hostname);
	}

	namespace Path {
		public static bool is_absolute (string file_name);
		public static unowned string skip_root (string file_name);
		public static string get_basename (string file_name);
		public static string get_dirname (string file_name);
		[CCode (cname = "g_build_filename")]
		public static string build_filename (string first_element, ...);
		[Version (since = "2.56")]
		[CCode (cname = "g_build_filename_valist")]
		public static string build_filename_valist (string first_element, va_list args);
		[CCode (cname = "g_build_path")]
		public static string build_path (string separator, string first_element, ...);

		[CCode (cname = "G_DIR_SEPARATOR")]
		public const char DIR_SEPARATOR;
		[CCode (cname = "G_DIR_SEPARATOR_S")]
		public const string DIR_SEPARATOR_S;
		[Version (since = "2.6")]
		[CCode (cname = "G_IS_DIR_SEPARATOR")]
		public static bool is_dir_separator (unichar c);
		[CCode (cname = "G_SEARCHPATH_SEPARATOR")]
		public const char SEARCHPATH_SEPARATOR;
		[CCode (cname = "G_SEARCHPATH_SEPARATOR_S")]
		public const string SEARCHPATH_SEPARATOR_S;
	}

	namespace Bit {
		public static int nth_lsf (ulong mask, int nth_bit);
		public static int nth_msf (ulong mask, int nth_bit);
		public static uint storage (ulong number);
	}

	namespace SpacedPrimes {
		public static uint closest (uint num);
	}

	[CCode (has_target = false)]
	public delegate void FreeFunc (void* data);
	[CCode (has_target = false)]
	public delegate void VoidFunc ();

	[Version (deprecated_since = "2.30", replacement = "format_size", since = "2.16")]
	public string format_size_for_display (int64 size);

	[Version (since = "2.30")]
	[CCode (cname = "g_format_size_full")]
	public string format_size (uint64 size, FormatSizeFlags flags = FormatSizeFlags.DEFAULT);

	[Version (since = "2.30")]
	[CCode (cprefix = "G_FORMAT_SIZE_", has_type_id = false)]
	[Flags]
	public enum FormatSizeFlags {
		DEFAULT,
		LONG_FORMAT,
		IEC_UNITS
	}

	/* Lexical Scanner */
	[CCode (has_target = false)]
	public delegate void ScannerMsgFunc (Scanner scanner, string message, bool error);

	[Compact]
	[CCode (free_function = "g_scanner_destroy")]
	public class Scanner {
		public unowned string input_name;
		public TokenType token;
		public TokenValue value;
		public uint line;
		public uint position;
		public TokenType next_token;
		public TokenValue next_value;
		public uint next_line;
		public uint next_position;
		public ScannerMsgFunc msg_handler;
		public ScannerConfig? config;
		public Scanner (ScannerConfig? config_templ);
		public void input_file (int input_fd);
		public void sync_file_offset ();
		public void input_text (string text, uint text_len);
		public TokenType peek_next_token ();
		public TokenType get_next_token ();
		public bool eof ();
		public int cur_line ();
		public int cur_position ();
		public TokenType cur_token ();
		public TokenValue cur_value ();
		public uint set_scope (uint scope_id);
		public void scope_add_symbol (uint scope_id, string symbol, void* value);
		public void scope_foreach_symbol (uint scope_id, HFunc<string, void*> func);
		public void* scope_lookup_symbol (uint scope_id, string symbol);
		public void scope_remove_symbol (uint scope_id, string symbol);
		public void* lookup_symbol (string symbol);
		[PrintfFormat]
		public void warn (string format, ...);
		[PrintfFormat]
		public void error (string format, ...);
		public void unexp_token (TokenType expected_token, string? identifier_spec, string? symbol_spec, string? symbol_name, string? message, bool is_error);
	}

	public struct ScannerConfig {
		public string* cset_skip_characters;
		public string* cset_identifier_first;
		public string* cset_identifier_nth;
		public string* cpair_comment_single;
		public bool case_sensitive;
		public bool skip_comment_multi;
		public bool skip_comment_single;
		public bool scan_comment_multi;
		public bool scan_identifier;
		public bool scan_identifier_1char;
		public bool scan_identifier_NULL;
		public bool scan_symbols;
		public bool scan_binary;
		public bool scan_octal;
		public bool scan_float;
		public bool scan_hex;
		public bool scan_hex_dollar;
		public bool scan_string_sq;
		public bool scan_string_dq;
		public bool numbers_2_int;
		public bool int_2_float;
		public bool identifier_2_string;
		public bool char_2_token;
		public bool symbol_2_token;
		public bool scope_0_fallback;
		public bool store_int64;
	}

	[CCode (lower_case_cprefix="G_CSET_")]
	namespace CharacterSet {
		public const string A_2_Z;
		public const string a_2_z;
		public const string DIGITS;
		public const string LATINC;
		public const string LATINS;
	}

	[CCode (cprefix = "G_TOKEN_", has_type_id = false)]
	public enum TokenType {
		EOF,
		LEFT_PAREN,
		RIGHT_PAREN,
		LEFT_CURLY,
		RIGHT_CURLY,
		LEFT_BRACE,
		RIGHT_BRACE,
		EQUAL_SIGN,
		COMMA,
		NONE,
		ERROR,
		CHAR,
		BINARY,
		OCTAL,
		INT,
		HEX,
		FLOAT,
		STRING,
		SYMBOL,
		IDENTIFIER,
		IDENTIFIER_NULL,
		COMMENT_SINGLE,
		COMMENT_MULTI,
		LAST
	}

	[SimpleType]
	public struct TokenValue {
		[CCode (cname="v_symbol")]
		public void* symbol;
		[CCode (cname="v_identifier")]
		public unowned string identifier;
		[CCode (cname="v_binary")]
		public ulong binary;
		[CCode (cname="v_octal")]
		public ulong octal;
		[CCode (cname="v_int")]
		public ulong int;
		[CCode (cname="v_int64")]
		public ulong int64;
		[CCode (cname="v_float")]
		public double float;
		[CCode (cname="v_hex")]
		public ulong hex;
		[CCode (cname="v_string")]
		public unowned string string;
		[CCode (cname="v_comment")]
		public unowned string comment;
		[CCode (cname="v_char")]
		public uchar char;
		[CCode (cname="v_error")]
		public uint error;
	}

	[CCode (cprefix = "G_ERR_", has_type_id = false)]
	public enum ErrorType {
		UNKNOWN,
		UNEXP_EOF,
		UNEXP_EOF_IN_STRING,
		UNEXP_EOF_IN_COMMENT,
		NON_DIGIT_IN_CONST,
		DIGIT_RADIX,
		FLOAT_RADIX,
		FLOAT_MALFORMED
	}

	/* Automatic String Completion */

	[Version (deprecated_since = "2.26")]
	[Compact]
	[CCode (free_function = "g_completion_free")]
	public class Completion {
		public Completion (CompletionFunc? func = null);
		public List<void*> items;
		public CompletionFunc func;
		public string prefix;
		public List<void*> cache;
		public CompletionStrncmpFunc strncmp_func;
		public void add_items (List<void*> items);
		public void remove_items (List<void*> items);
		public void clear_items ();
		public unowned List<void*> complete (string prefix, out string? new_prefix = null);
		[Version (since = "2.4")]
		public unowned List<void*> complete_utf8 (string prefix, out string? new_prefix = null);
	}

	[CCode (has_target = false)]
	public delegate string CompletionFunc (void* item);
	[CCode (has_target = false)]
	public delegate int CompletionStrncmpFunc (string s1, string s2, size_t n);

	/* Timers */

	[Compact]
	[CCode (free_function = "g_timer_destroy")]
	public class Timer {
		public Timer ();
		public void start ();
		public void stop ();
		[Version (since = "2.4")]
		public void @continue ();
		public double elapsed (out ulong microseconds = null);
		public void reset ();
	}

	/* Spawning Processes */

	public errordomain SpawnError {
		FORK,
		READ,
		CHDIR,
		ACCES,
		PERM,
		TOO_BIG,
		NOEXEC,
		NAMETOOLONG,
		NOENT,
		NOMEM,
		NOTDIR,
		LOOP,
		TXTBUSY,
		IO,
		NFILE,
		MFILE,
		INVAL,
		ISDIR,
		LIBBAD,
		FAILED;
		public static GLib.Quark quark ();
	}

	[CCode (cprefix = "G_SPAWN_", has_type_id = false)]
	[Flags]
	public enum SpawnFlags {
		LEAVE_DESCRIPTORS_OPEN,
		DO_NOT_REAP_CHILD,
		SEARCH_PATH,
		STDOUT_TO_DEV_NULL,
		STDERR_TO_DEV_NULL,
		CHILD_INHERITS_STDIN,
		FILE_AND_ARGV_ZERO,
		SEARCH_PATH_FROM_ENVP
	}

	public delegate void SpawnChildSetupFunc ();
	[CCode (has_target = false, cheader_filename = "signal.h")]
	public delegate void SignalHandlerFunc (int signum);

	public unowned string strsignal (int signum);

	[CCode (lower_case_cprefix = "g_")]
	namespace Process {
		public static bool spawn_async_with_pipes (string? working_directory, [CCode (array_length = false, array_null_terminated = true)] string[] argv, [CCode (array_length = false, array_null_terminated = true)] string[]? envp, SpawnFlags _flags, SpawnChildSetupFunc? child_setup, out Pid child_pid, out int standard_input = null, out int standard_output = null, out int standard_error = null) throws SpawnError;
		public static bool spawn_async (string? working_directory, [CCode (array_length = false, array_null_terminated = true)] string[] argv, [CCode (array_length = false, array_null_terminated = true)] string[]? envp, SpawnFlags _flags, SpawnChildSetupFunc? child_setup, out Pid child_pid) throws SpawnError;
		public static bool spawn_sync (string? working_directory, [CCode (array_length = false, array_null_terminated = true)] string[] argv, [CCode (array_length = false, array_null_terminated = true)] string[]? envp, SpawnFlags _flags, SpawnChildSetupFunc? child_setup, out string standard_output = null, out string standard_error = null, out int exit_status = null) throws SpawnError;
		public static bool spawn_command_line_async (string command_line) throws SpawnError;
		public static bool spawn_command_line_sync (string command_line, out string standard_output = null, out string standard_error = null, out int exit_status = null) throws SpawnError;
		[CCode (cname = "g_spawn_close_pid")]
		public static void close_pid (Pid pid);
		[Version (since = "2.34")]
		[CCode (cname = "g_spawn_check_exit_status")]
		public static bool check_exit_status (int exit_status) throws GLib.Error;

		/* these macros are required to examine the exit status of a process */
		[CCode (cname = "WIFEXITED", cheader_filename = "sys/wait.h")]
		public static bool if_exited (int status);
		[CCode (cname = "WEXITSTATUS", cheader_filename = "sys/wait.h")]
		public static int exit_status (int status);
		[CCode (cname = "WIFSIGNALED", cheader_filename = "sys/wait.h")]
		public static bool if_signaled (int status);
		[CCode (cname = "WTERMSIG", cheader_filename = "sys/wait.h")]
		public static ProcessSignal term_sig (int status);
		[CCode (cname = "WCOREDUMP", cheader_filename = "sys/wait.h")]
		public static bool core_dump (int status);
		[CCode (cname = "WIFSTOPPED", cheader_filename = "sys/wait.h")]
		public static bool if_stopped (int status);
		[CCode (cname = "WSTOPSIG", cheader_filename = "sys/wait.h")]
		public static ProcessSignal stop_sig (int status);
		[CCode (cname = "WIFCONTINUED", cheader_filename = "sys/wait.h")]
		public static bool if_continued (int status);

		[NoReturn]
		[CCode (cname = "abort", cheader_filename = "stdlib.h")]
		public void abort ();
		[NoReturn]
		[CCode (cname = "exit", cheader_filename = "stdlib.h")]
		public void exit (int status);
		[CCode (cname = "raise", cheader_filename = "signal.h")]
		public int raise (ProcessSignal sig);
		[CCode (cname = "signal", cheader_filename = "signal.h")]
		public SignalHandlerFunc @signal (ProcessSignal signum, SignalHandlerFunc handler);
	}

	[CCode (cname = "int", has_type_id = false, cheader_filename = "signal.h", cprefix = "SIG")]
	public enum ProcessSignal {
		HUP,
		INT,
		QUIT,
		ILL,
		TRAP,
		ABRT,
		BUS,
		FPE,
		KILL,
		SEGV,
		PIPE,
		ALRM,
		TERM,
		USR1,
		USR2,
		CHLD,
		CONT,
		STOP,
		TSTP,
		TTIN,
		TTOU
	}


	/* File Utilities */

	public errordomain FileError {
		EXIST,
		ISDIR,
		ACCES,
		NAMETOOLONG,
		NOENT,
		NOTDIR,
		NXIO,
		NODEV,
		ROFS,
		TXTBSY,
		FAULT,
		LOOP,
		NOSPC,
		NOMEM,
		MFILE,
		NFILE,
		BADF,
		INVAL,
		PIPE,
		AGAIN,
		INTR,
		IO,
		PERM,
		NOSYS,
		FAILED;
		public static GLib.Quark quark ();
	}

	[CCode (has_type_id = false)]
	[Flags]
	public enum FileTest {
		IS_REGULAR,
		IS_SYMLINK,
		IS_DIR,
		IS_EXECUTABLE,
		EXISTS
	}

	[CCode (cname = "int", cprefix = "SEEK_", has_type_id = false)]
	public enum FileSeek {
		SET,
		CUR,
		END
	}

	[Compact]
	[CCode (cname = "FILE", free_function = "fclose", cheader_filename = "stdio.h")]
	public class FileStream {
		[CCode (cname = "EOF", cheader_filename = "stdio.h")]
		public const int EOF;

		[Version (since = "2.6")]
		[CCode (cname = "g_fopen", cheader_filename = "glib/gstdio.h")]
		public static FileStream? open (string path, string mode);
		[CCode (cname = "fdopen")]
		public static FileStream? fdopen (int fildes, string mode);
		[CCode (cname = "fprintf")]
		[PrintfFormat ()]
		public void printf (string format, ...);
		[CCode (cname = "vfprintf")]
		public void vprintf (string format, va_list args);
		[CCode (cname = "fputc", instance_pos = -1)]
		public void putc (char c);
		[CCode (cname = "fputs", instance_pos = -1)]
		public void puts (string s);
		[CCode (cname = "fgetc")]
		public int getc ();
		[CCode (cname = "ungetc", instance_pos = -1)]
		public int ungetc (int c);
		[CCode (cname = "fgets", instance_pos = -1)]
		public unowned string? gets (char[] s);
		[CCode (cname = "feof")]
		public bool eof ();
		[CCode (cname = "fscanf"), ScanfFormat]
		public int scanf (string format, ...);
		[CCode (cname = "fflush")]
		public int flush ();
		[CCode (cname = "fseek")]
		public int seek (long offset, FileSeek whence);
		[CCode (cname = "ftell")]
		public long tell ();
		[CCode (cname = "rewind")]
		public void rewind ();
		[CCode (cname = "fileno")]
		public int fileno ();
		[CCode (cname = "ferror")]
		public int error ();
		[CCode (cname = "clearerr")]
		public void clearerr ();
		[CCode (cname = "fread", instance_pos = -1)]
		public size_t read ([CCode (array_length_pos = 2.1)] uint8[] buf, size_t size = 1);
		[CCode (cname = "fwrite", instance_pos = -1)]
		public size_t write ([CCode (array_length_pos = 2.1)] uint8[] buf, size_t size = 1);

		public string? read_line () {
			int c;
			StringBuilder? ret = null;
			while ((c = getc ()) != EOF) {
				if (ret == null) {
					ret = new StringBuilder ();
				}
				if (c == '\n') {
					break;
				}
				((!)(ret)).append_c ((char) c);
			}
			if (ret == null) {
				return null;
			} else {
				return ((!)(ret)).str;
			}
		}
	}

	[CCode (cname = "struct utimbuf", cheader_filename = "sys/types.h,utime.h")]
	public struct UTimBuf {
		time_t actime;       /* access time */
		time_t modtime;      /* modification time */
	}

	[CCode (lower_case_cprefix = "g_file_", cheader_filename = "glib/gstdio.h")]
	namespace FileUtils {
		public static bool get_contents (string filename, out string contents, out size_t length = null) throws FileError;
		[Version (since = "2.8")]
		public static bool set_contents (string filename, string contents, ssize_t length = -1) throws FileError;
		[CCode (cname = "g_file_get_contents")]
		public static bool get_data (string filename, [CCode (type = "gchar**", array_length_type = "size_t")] out uint8[] contents) throws FileError;
		[CCode (cname = "g_file_set_contents")]
		public static bool set_data (string filename, [CCode (type = "const char*", array_length_type = "size_t")] uint8[] contents) throws FileError;
		public static bool test (string filename, FileTest test);
		public static int open_tmp (string tmpl, out string name_used) throws FileError;
		[Version (since = "2.4")]
		public static string read_link (string filename) throws FileError;
		public static int error_from_errno (int err_no);

		[CCode (cname = "g_mkstemp")]
		public static int mkstemp (string tmpl);
		[Version (since = "2.6")]
		[CCode (cname = "g_rename")]
		public static int rename (string oldfilename, string newfilename);
		[Version (since = "2.6")]
		[CCode (cname = "g_remove")]
		public static int remove (string filename);
		[CCode (cname = "g_unlink")]
		public static int unlink (string filename);
		[Version (since = "2.8")]
		[CCode (cname = "g_chmod")]
		public static int chmod (string filename, int mode);
		[Version (since = "2.18")]
		[CCode (cname = "g_utime")]
		public static int utime (string filename, UTimBuf? times = null);

		[CCode (cname = "symlink", cheader_filename = "unistd.h")]
		public static int symlink (string oldpath, string newpath);

		[CCode (cname = "close", cheader_filename = "unistd.h")]
		public static int close (int fd);

		[Version (since = "2.36")]
		[CCode (cname = "g_close")]
		public static bool close_checked (int fd) throws FileError;
	}

	[CCode (cname = "struct stat", cheader_filename = "sys/stat.h,glib/gstdio.h")]
	public struct Stat {
		public time_t st_atime;
		public time_t st_mtime;
		public time_t st_ctime;
		[CCode (cname = "g_stat", instance_pos = -1)]
		public Stat (string filename);
		[Version (since = "2.6")]
		[CCode (cname = "g_lstat", instance_pos = -1)]
		public Stat.l (string filename);
	}

	[Compact]
	[CCode (free_function = "g_dir_close")]
	public class Dir {
		public static Dir open (string filename, uint _flags = 0) throws FileError;
		public unowned string? read_name ();
		public void rewind ();
	}

	[CCode (cheader_filename = "glib/gstdio.h")]
	namespace DirUtils {
		[Version (since = "2.6")]
		[CCode (cname = "g_mkdir")]
		public static int create (string pathname, int mode);
		[Version (since = "2.8")]
		[CCode (cname = "g_mkdir_with_parents")]
		public static int create_with_parents (string pathname, int mode);
		[Version (since = "2.30")]
		[CCode (cname = "mkdtemp")]
		public static string mkdtemp (owned string template);
		[Version (since = "2.30")]
		[CCode (cname = "g_dir_make_tmp")]
		public static string make_tmp (string tmpl) throws FileError;
		[Version (since = "2.6")]
		[CCode (cname = "g_rmdir")]
		public static int remove (string filename);
	}

	[Compact]
	[Version (since = "2.22")]
	[CCode (ref_function = "g_mapped_file_ref", unref_function = "g_mapped_file_unref")]
	public class MappedFile {
		public MappedFile (string filename, bool writable) throws FileError;
		public size_t get_length ();
		public unowned char* get_contents ();
		[Version (since = "2.34")]
		public Bytes get_bytes ();
	}

	[CCode (cname = "stdin", cheader_filename = "stdio.h")]
	public static FileStream stdin;

	[CCode (cname = "stdout", cheader_filename = "stdio.h")]
	public static FileStream stdout;

	[CCode (cname = "stderr", cheader_filename = "stdio.h")]
	public static FileStream stderr;

	/* URI Functions */

	namespace Uri {
		public const string RESERVED_CHARS_ALLOWED_IN_PATH;
		public const string RESERVED_CHARS_ALLOWED_IN_PATH_ELEMENT;
		public const string RESERVED_CHARS_ALLOWED_IN_USERINFO;
		public const string RESERVED_CHARS_GENERIC_DELIMITERS;
		public const string RESERVED_CHARS_SUBCOMPONENT_DELIMITERS;

		[Version (since = "2.16")]
		public static string? parse_scheme (string uri);
		[Version (since = "2.16")]
		public static string escape_string (string unescaped, string? reserved_chars_allowed = null, bool allow_utf8 = true);
		[Version (since = "2.16")]
		public static string? unescape_string (string escaped_string, string? illegal_characters = null);
		[Version (since = "2.16")]
		public static string? unescape_segment (string? escaped_string, string? escaped_string_end, string? illegal_characters = null);
		[Version (since = "2.6")]
		[CCode (array_length = false, array_null_terminated = true)]
		public static string[] list_extract_uris (string uri_list);
	}

	/* Shell-related Utilities */

	public errordomain ShellError {
		BAD_QUOTING,
		EMPTY_STRING,
		FAILED;
		public static GLib.Quark quark ();
	}

	namespace Shell {
		public static bool parse_argv (string command_line, [CCode (array_length_pos = 1.9)] out string[] argvp) throws ShellError;
		public static string quote (string unquoted_string);
		public static string unquote (string quoted_string) throws ShellError;
	}

	/* Commandline option parser */

	public errordomain OptionError {
		UNKNOWN_OPTION,
		BAD_VALUE,
		FAILED;
		public static GLib.Quark quark ();
	}

	[Compact]
	[Version (since = "2.6")]
	[CCode (free_function = "g_option_context_free")]
	public class OptionContext {
		public OptionContext (string? parameter_string = null);
		[Version (since = "2.12")]
		public void set_summary (string summary);
		[Version (since = "2.12")]
		public unowned string get_summary ();
		[Version (since = "2.12")]
		public void set_description (string description);
		[Version (since = "2.12")]
		public unowned string get_description ();
		[Version (since = "2.12")]
		public void set_translate_func (TranslateFunc func, DestroyNotify? destroy_notify);
		[Version (since = "2.12")]
		public void set_translation_domain (string domain);
		public bool parse ([CCode (array_length_pos = 0.9)] ref unowned string[] argv) throws OptionError;
		[Version (since = "2.40")]
		public bool parse_strv ([CCode (array_length = false, array_null_terminated = true)] ref string[] argv) throws OptionError;
		public void set_help_enabled (bool help_enabled);
		public bool get_help_enabled ();
		public void set_ignore_unknown_options (bool ignore_unknown);
		public bool get_ignore_unknown_options ();
		[Version (since = "2.14")]
		public string get_help (bool main_help, OptionGroup? group);
		public void add_main_entries ([CCode (array_length = false, array_null_terminated = true)] OptionEntry[] entries, string? translation_domain);
		public void add_group (owned OptionGroup group);
		public void set_main_group (owned OptionGroup group);
		public unowned OptionGroup get_main_group ();
		[Version (since = "2.44")]
		public void set_strict_posix (bool strict_posix);
		[Version (since = "2.44")]
		public bool get_strict_posix ();
	}

	public delegate unowned string TranslateFunc (string str);

	public const string OPTION_REMAINING;

	[CCode (has_type_id = false)]
	public enum OptionArg {
		NONE,
		STRING,
		INT,
		CALLBACK,
		FILENAME,
		STRING_ARRAY,
		FILENAME_ARRAY,
		DOUBLE,
		INT64
	}

	[Flags]
	[CCode (cprefix = "G_OPTION_FLAG_", has_type_id = false)]
	public enum OptionFlags {
		[Version (since = "2.42")]
		NONE,
		HIDDEN,
		IN_MAIN,
		REVERSE,
		NO_ARG,
		FILENAME,
		OPTIONAL_ARG,
		NOALIAS
	}

	public struct OptionEntry {
		public unowned string long_name;
		public char short_name;
		public int flags;

		public OptionArg arg;
		public void* arg_data;

		public unowned string description;
		public unowned string? arg_description;
	}

	[Compact]
#if GLIB_2_44
	[Version (since = "2.44")]
	[CCode (ref_function = "g_option_group_ref", unref_function = "g_option_group_unref", type_id = "G_TYPE_OPTION_GROUP")]
#else
	[Version (since = "2.6")]
	[CCode (free_function = "g_option_group_free")]
#endif
	public class OptionGroup {
		public OptionGroup (string name, string description, string help_description, void* user_data = null, DestroyNotify? destroy = null);
		public void add_entries ([CCode (array_length = false, array_null_terminated = true)] OptionEntry[] entries);
		public void set_parse_hooks (OptionParseFunc? pre_parse_func, OptionParseFunc? post_parse_hook);
		public void set_error_hook (OptionErrorFunc? error_func);
		public void set_translate_func (owned TranslateFunc? func);
		public void set_translation_domain (string domain);
	}

	[CCode (has_target = false)]
	public delegate bool OptionParseFunc (OptionContext context, OptionGroup group, void* data) throws OptionError;
	[CCode (has_target = false)]
	public delegate void OptionErrorFunc (OptionContext context, OptionGroup group, void* data, ref Error error);
	[CCode (has_target = false)]
	public delegate bool OptionArgFunc (string option_name, string val, void* data) throws OptionError;

	/* Perl-compatible regular expressions */

	[Version (since = "2.14")]
	public errordomain RegexError {
		COMPILE,
		OPTIMIZE,
		REPLACE,
		MATCH,
		INTERNAL,
		STRAY_BACKSLASH,
		MISSING_CONTROL_CHAR,
		UNRECOGNIZED_ESCAPE,
		QUANTIFIERS_OUT_OF_ORDER,
		QUANTIFIER_TOO_BIG,
		UNTERMINATED_CHARACTER_CLASS,
		INVALID_ESCAPE_IN_CHARACTER_CLASS,
		RANGE_OUT_OF_ORDER,
		NOTHING_TO_REPEAT,
		UNRECOGNIZED_CHARACTER,
		POSIX_NAMED_CLASS_OUTSIDE_CLASS,
		UNMATCHED_PARENTHESIS,
		INEXISTENT_SUBPATTERN_REFERENCE,
		UNTERMINATED_COMMENT,
		EXPRESSION_TOO_LARGE,
		MEMORY_ERROR,
		VARIABLE_LENGTH_LOOKBEHIND,
		MALFORMED_CONDITION,
		TOO_MANY_CONDITIONAL_BRANCHES,
		ASSERTION_EXPECTED,
		UNKNOWN_POSIX_CLASS_NAME,
		POSIX_COLLATING_ELEMENTS_NOT_SUPPORTED,
		HEX_CODE_TOO_LARGE,
		INVALID_CONDITION,
		SINGLE_BYTE_MATCH_IN_LOOKBEHIND,
		INFINITE_LOOP,
		MISSING_SUBPATTERN_NAME_TERMINATOR,
		DUPLICATE_SUBPATTERN_NAME,
		MALFORMED_PROPERTY,
		UNKNOWN_PROPERTY,
		SUBPATTERN_NAME_TOO_LONG,
		TOO_MANY_SUBPATTERNS,
		INVALID_OCTAL_VALUE,
		TOO_MANY_BRANCHES_IN_DEFINE,
		DEFINE_REPETION,
		INCONSISTENT_NEWLINE_OPTIONS,
		MISSING_BACK_REFERENCE,
		INVALID_RELATIVE_REFERENCE,
		BACKTRACKING_CONTROL_VERB_ARGUMENT_FORBIDDEN,
		UNKNOWN_BACKTRACKING_CONTROL_VERB,
		NUMBER_TOO_BIG,
		MISSING_SUBPATTERN_NAME,
		MISSING_DIGIT,
		INVALID_DATA_CHARACTER,
		EXTRA_SUBPATTERN_NAME,
		BACKTRACKING_CONTROL_VERB_ARGUMENT_REQUIRED,
		INVALID_CONTROL_CHAR,
		MISSING_NAME,
		NOT_SUPPORTED_IN_CLASS,
		TOO_MANY_FORWARD_REFERENCES,
		NAME_TOO_LONG,
		CHARACTER_VALUE_TOO_LARGE;
		public static GLib.Quark quark ();
	}

	[Version (since = "2.14")]
	[CCode (cprefix = "G_REGEX_", has_type_id = false)]
	[Flags]
	public enum RegexCompileFlags {
		CASELESS,
		MULTILINE,
		DOTALL,
		EXTENDED,
		ANCHORED,
		DOLLAR_ENDONLY,
		UNGREEDY,
		RAW,
		NO_AUTO_CAPTURE,
		OPTIMIZE,
		DUPNAMES,
		NEWLINE_CR,
		NEWLINE_LF,
		NEWLINE_CRLF,
		NEWLINE_ANYCRLF,
		BSR_ANYCRLF,
		JAVASCRIPT_COMPAT
	}

	[Version (since = "2.14")]
	[CCode (cprefix = "G_REGEX_MATCH_", has_type_id = false)]
	[Flags]
	public enum RegexMatchFlags {
		ANCHORED,
		NOTBOL,
		NOTEOL,
		NOTEMPTY,
		PARTIAL,
		NEWLINE_CR,
		NEWLINE_LF,
		NEWLINE_CRLF,
		NEWLINE_ANY,
		NEWLINE_ANYCRLF,
		BSR_ANYCRLF,
		BSR_ANY,
		PARTIAL_SOFT,
		PARTIAL_HARD,
		NOTEMPTY_ATSTART
	}

	[Compact]
	[Version (since = "2.14")]
	[CCode (ref_function = "g_regex_ref", unref_function = "g_regex_unref", type_id = "G_TYPE_REGEX")]
	public class Regex {
		public Regex (string pattern, RegexCompileFlags compile_options = 0, RegexMatchFlags match_options = 0) throws RegexError;
		public unowned string get_pattern ();
		[Version (since = "2.26")]
		public RegexCompileFlags get_compile_flags ();
		[Version (since = "2.34")]
		public bool get_has_cr_or_lf ();
		[Version (since = "2.26")]
		public RegexMatchFlags get_match_flags ();
		public int get_max_backref ();
		[Version (since = "2.38")]
		public int get_max_lookbehind ();
		public int get_capture_count ();
		public int get_string_number (string name);
		public static string escape_string (string str, int length = -1);
		public static bool match_simple (string pattern, string str, RegexCompileFlags compile_options = 0, RegexMatchFlags match_options = 0);
		public bool match (string str, RegexMatchFlags match_options = 0, out MatchInfo match_info = null);
		public bool match_full (string str, ssize_t string_len = -1, int start_position = 0, RegexMatchFlags match_options = 0, out MatchInfo match_info = null) throws RegexError;
		public bool match_all (string str, RegexMatchFlags match_options = 0, out MatchInfo match_info = null);
		public bool match_all_full (string str, ssize_t string_len = -1, int start_position = 0, RegexMatchFlags match_options = 0, out MatchInfo match_info = null) throws RegexError;
		[CCode (array_length = false, array_null_terminated = true)]
		public static string[] split_simple (string pattern, string str, RegexCompileFlags compile_options = 0, RegexMatchFlags match_options = 0);
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] split (string str, RegexMatchFlags match_options = 0);
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] split_full (string str, ssize_t string_len = -1, int start_position = 0, RegexMatchFlags match_options = 0, int max_tokens = 0) throws RegexError;
		public string replace (string str, ssize_t string_len, int start_position, string replacement, RegexMatchFlags match_options = 0) throws RegexError;
		public string replace_literal (string str, ssize_t string_len, int start_position, string replacement, RegexMatchFlags match_options = 0) throws RegexError;
		public string replace_eval (string str, ssize_t string_len, int start_position, RegexMatchFlags match_options, RegexEvalCallback eval) throws RegexError;
		public static bool check_replacement (string replacement, out bool has_references = null) throws RegexError;
	}

	[Version (since = "2.14")]
	public delegate bool RegexEvalCallback (MatchInfo match_info, StringBuilder result);

	[Compact]
	[Version (since = "2.30")]
	[CCode (ref_function = "g_match_info_ref", unref_function = "g_match_info_unref", type_id = "G_TYPE_MATCH_INFO")]
	public class MatchInfo {
		public unowned Regex get_regex ();
		public unowned string get_string ();
		public bool matches ();
		public bool next () throws RegexError;
		public int get_match_count ();
		public bool is_partial_match ();
		public string expand_references (string string_to_expand) throws RegexError;
		public string? fetch (int match_num);
		public bool fetch_pos (int match_num, out int start_pos, out int end_pos);
		public string? fetch_named (string name);
		public bool fetch_named_pos (string name, out int start_pos, out int end_pos);
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] fetch_all ();
	}

	/* Simple XML Subset Parser
	   See http://live.gnome.org/Vala/MarkupSample for an example */

	public errordomain MarkupError {
		BAD_UTF8,
		EMPTY,
		PARSE,
		UNKNOWN_ELEMENT,
		UNKNOWN_ATTRIBUTE,
		INVALID_CONTENT,
		MISSING_ATTRIBUTE;
		public static GLib.Quark quark ();
	}

	[CCode (cprefix = "G_MARKUP_", has_type_id = false)]
	[Flags]
	public enum MarkupParseFlags {
		TREAT_CDATA_AS_TEXT,
		PREFIX_ERROR_POSITION
	}

	[Compact]
	[Version (since = "2.36")]
	[CCode (ref_function = "g_markup_parse_context_ref", unref_function = "g_markup_parse_context_unref", type_id = "G_TYPE_MARKUP_PARSE_CONTEXT")]
	public class MarkupParseContext {
		public MarkupParseContext (MarkupParser parser, MarkupParseFlags _flags, void* user_data, DestroyNotify? user_data_dnotify);
		public bool parse (string text, ssize_t text_len) throws MarkupError;
		public bool end_parse () throws MarkupError;
		[Version (since = "2.2")]
		public unowned string get_element ();
		[Version (since = "2.16")]
		public unowned SList<string> get_element_stack ();
		public void get_position (out int line_number, out int char_number);
		[Version (since = "2.18")]
		public void push (MarkupParser parser, void* user_data);
		[Version (since = "2.18")]
		public void* pop ();
		[Version (since = "2.18")]
		public void* get_user_data ();
	}

	public delegate void MarkupParserStartElementFunc (MarkupParseContext context, string element_name, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_names, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_values) throws MarkupError;

	public delegate void MarkupParserEndElementFunc (MarkupParseContext context, string element_name) throws MarkupError;

	public delegate void MarkupParserTextFunc (MarkupParseContext context, string text, size_t text_len) throws MarkupError;

	public delegate void MarkupParserPassthroughFunc (MarkupParseContext context, string passthrough_text, size_t text_len) throws MarkupError;

	public delegate void MarkupParserErrorFunc (MarkupParseContext context, Error error);

	public struct MarkupParser {
		[CCode (delegate_target = false)]
		public unowned MarkupParserStartElementFunc start_element;
		[CCode (delegate_target = false)]
		public unowned MarkupParserEndElementFunc end_element;
		[CCode (delegate_target = false)]
		public unowned MarkupParserTextFunc text;
		[CCode (delegate_target = false)]
		public unowned MarkupParserPassthroughFunc passthrough;
		[CCode (delegate_target = false)]
		public unowned MarkupParserErrorFunc error;
	}

	namespace Markup {
		[CCode (cprefix = "G_MARKUP_COLLECT_", has_type_id = false)]
		public enum CollectType {
			INVALID,
			STRING,
			STRDUP,
			BOOLEAN,
			TRISTATE,
			OPTIONAL
		}

		public static string escape_text (string text, ssize_t length = -1);
		[Version (since = "2.4")]
		[PrintfFormat]
		public static string printf_escaped (string format, ...);
		[Version (since = "2.4")]
		public static string vprintf_escaped (string format, va_list args);
		[Version (since = "2.16")]
		[CCode (sentinel = "G_MARKUP_COLLECT_INVALID")]
		public static bool collect_attributes (string element_name, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_names, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_values, ...) throws MarkupError;
	}

	/* Key-value file parser */

	public errordomain KeyFileError {
		UNKNOWN_ENCODING,
		PARSE,
		NOT_FOUND,
		KEY_NOT_FOUND,
		GROUP_NOT_FOUND,
		INVALID_VALUE;
		public static GLib.Quark quark ();
	}

	[Compact]
	[Version (since = "2.32")]
	[CCode (ref_function = "g_key_file_ref", unref_function = "g_key_file_unref", type_id = "G_TYPE_KEY_FILE")]
	public class KeyFile {
		public KeyFile ();
		public void set_list_separator (char separator);
		[Version (since = "2.50")]
		public bool load_from_bytes (Bytes bytes, KeyFileFlags @flags) throws KeyFileError;
		public bool load_from_file (string file, KeyFileFlags @flags) throws KeyFileError, FileError;
		[Version (since = "2.14")]
		public bool load_from_dirs (string file, [CCode (array_length = false, array_null_terminated = true)] string[] search_dirs, out string full_path, KeyFileFlags @flags) throws KeyFileError, FileError;
		public bool load_from_data (string data, size_t length, KeyFileFlags @flags) throws KeyFileError;
		public bool load_from_data_dirs (string file, out string full_path, KeyFileFlags @flags) throws KeyFileError, FileError;
		// g_key_file_to_data never throws an error according to the documentation
		public string to_data (out size_t length = null, out GLib.Error error = null);
		public string get_start_group ();
		[CCode (array_length_type = "gsize")]
		public string[] get_groups ();
		[CCode (array_length_type = "gsize")]
		public string[] get_keys (string group_name) throws KeyFileError;
		public bool has_group (string group_name);
		public bool has_key (string group_name, string key) throws KeyFileError;
		public string get_value (string group_name, string key) throws KeyFileError;
		public string get_string (string group_name, string key) throws KeyFileError;
		public string get_locale_string (string group_name, string key, string? locale = null) throws KeyFileError;
		[Version (since = "2.56")]
		public string? get_locale_for_key (string group_name, string key, string? locale = null);
		public bool get_boolean (string group_name, string key) throws KeyFileError;
		public int get_integer (string group_name, string key) throws KeyFileError;
		[Version (since = "2.26")]
		public int64 get_int64 (string group_name, string key) throws KeyFileError;
		[Version (since = "2.26")]
		public uint64 get_uint64 (string group_name, string key) throws KeyFileError;
		[Version (since = "2.12")]
		public double get_double (string group_name, string key) throws KeyFileError;
		[CCode (array_length = true, array_length_type = "gsize", array_null_terminated = true)]
		public string[] get_string_list (string group_name, string key) throws KeyFileError;
		[CCode (array_length_type = "gsize")]
		public string[] get_locale_string_list (string group_name, string key, string? locale = null) throws KeyFileError;
		[CCode (array_length_type = "gsize")]
		public bool[] get_boolean_list (string group_name, string key) throws KeyFileError;
		[CCode (array_length_type = "gsize")]
		public int[] get_integer_list (string group_name, string key) throws KeyFileError;
		[Version (since = "2.12")]
		[CCode (array_length_type = "gsize")]
		public double[] get_double_list (string group_name, string key) throws KeyFileError;
		public string get_comment (string? group_name, string? key) throws KeyFileError;
		[Version (since = "2.40")]
		public bool save_to_file (string filename) throws GLib.FileError;
		public void set_value (string group_name, string key, string value);
		public void set_string (string group_name, string key, string str);
		public void set_locale_string (string group_name, string key, string locale, string str);
		public void set_boolean (string group_name, string key, bool value);
		public void set_integer (string group_name, string key, int value);
		[Version (since = "2.26")]
		public void set_int64 (string group_name, string key, int64 value);
		[Version (since = "2.26")]
		public void set_uint64 (string group_name, string key, uint64 value);
		[Version (since = "2.12")]
		public void set_double (string group_name, string key, double value);
		public void set_string_list (string group_name, string key, [CCode (type = "const gchar* const*")] string[] list);
		public void set_locale_string_list (string group_name, string key, string locale, string[] list);
		public void set_boolean_list (string group_name, string key, bool[] list);
		public void set_integer_list (string group_name, string key, int[] list);
		[Version (since = "2.12")]
		public void set_double_list (string group_name, string key, double[] list);
		public void set_comment (string? group_name, string? key, string comment) throws KeyFileError;
		public void remove_group (string group_name) throws KeyFileError;
		public void remove_key (string group_name, string key) throws KeyFileError;
		public void remove_comment (string group_name, string key) throws KeyFileError;
	}

	[CCode (cprefix = "G_KEY_FILE_", has_type_id = false)]
	[Flags]
	public enum KeyFileFlags {
		NONE,
		KEEP_COMMENTS,
		KEEP_TRANSLATIONS
	}

	[Version (since = "2.14")]
	[CCode (cprefix = "G_KEY_FILE_DESKTOP_")]
	namespace KeyFileDesktop {
		public const string GROUP;
		public const string KEY_ACTIONS;
		public const string KEY_CATEGORIES;
		public const string KEY_COMMENT;
		public const string KEY_DBUS_ACTIVATABLE;
		public const string KEY_EXEC;
		public const string KEY_FULLNAME;
		public const string KEY_GENERIC_NAME;
		public const string KEY_GETTEXT_DOMAIN;
		public const string KEY_HIDDEN;
		public const string KEY_ICON;
		public const string KEY_KEYWORDS;
		public const string KEY_MIME_TYPE;
		public const string KEY_NAME;
		public const string KEY_NOT_SHOW_IN;
		public const string KEY_NO_DISPLAY;
		public const string KEY_ONLY_SHOW_IN;
		public const string KEY_PATH;
		public const string KEY_STARTUP_NOTIFY;
		public const string KEY_STARTUP_WM_CLASS;
		public const string KEY_TERMINAL;
		public const string KEY_TRY_EXEC;
		public const string KEY_TYPE;
		public const string KEY_URL;
		public const string KEY_VERSION;
		public const string TYPE_APPLICATION;
		public const string TYPE_DIRECTORY;
		public const string TYPE_LINK;
	}

	/* Bookmark file parser */

	[Compact]
	[Version (since = "2.12")]
	[CCode (free_function = "g_bookmark_file_free")]
	public class BookmarkFile {
		public BookmarkFile ();
		public bool load_from_file (string file) throws BookmarkFileError, FileError;
		public bool load_from_data (string data, size_t length) throws BookmarkFileError;
		public bool load_from_data_dirs (string file, out string full_path) throws BookmarkFileError, FileError;
		public string to_data (out size_t length) throws BookmarkFileError;
		public bool to_file (string filename) throws BookmarkFileError, FileError;
		public bool has_item (string uri);
		public bool has_group (string uri, string group) throws BookmarkFileError;
		public bool has_application (string uri, string name) throws BookmarkFileError;
		public int get_size ();
		public string[] get_uris ();
		public string get_title (string uri) throws BookmarkFileError;
		public string get_description (string uri) throws BookmarkFileError;
		public string get_mime_type (string uri) throws BookmarkFileError;
		public bool get_is_private (string uri) throws BookmarkFileError;
		public bool get_icon (string uri, out string href, out string mime_type) throws BookmarkFileError;
		public time_t get_added (string uri) throws BookmarkFileError;
		public time_t get_modified (string uri) throws BookmarkFileError;
		public time_t get_visited (string uri) throws BookmarkFileError;
		public string[] get_groups (string uri) throws BookmarkFileError;
		public string[] get_applications (string uri) throws BookmarkFileError;
		public bool get_app_info (string uri, string name, out string exec, out uint count, out time_t stamp) throws BookmarkFileError;
		public void set_title (string uri, string title);
		public void set_description (string uri, string description);
		public void set_mime_type (string uri, string mime_type);
		public void set_is_private (string uri, bool is_private);
		public void set_icon (string uri, string href, string mime_type);
		public void set_added (string uri, time_t added);
		public void set_groups (string uri, string[] groups);
		public void set_modified (string uri, time_t modified);
		public void set_visited (string uri, time_t visited);
		public bool set_app_info (string uri, string name, string exec, int count, time_t stamp) throws BookmarkFileError;
		public void add_group (string uri, string group);
		public void add_application (string uri, string name, string exec);
		public bool remove_group (string uri, string group) throws BookmarkFileError;
		public bool remove_application (string uri, string name) throws BookmarkFileError;
		public bool remove_item (string uri) throws BookmarkFileError;
		public bool move_item (string old_uri, string new_uri) throws BookmarkFileError;
	}

	public errordomain BookmarkFileError {
		INVALID_URI,
		INVALID_VALUE,
		APP_NOT_REGISTERED,
		URI_NOT_FOUND,
		READ,
		UNKNOWN_ENCODING,
		WRITE,
		FILE_NOT_FOUND;
		public static GLib.Quark quark ();
	}

	/* Testing */

	namespace Test {
		[CCode (cprefix = "G_TEST_", has_type_id = false)]
		public enum FileType {
			DIST,
			BUILT
		}

		[PrintfFormat]
		[Version (since = "2.16")]
		public static void minimized_result (double minimized_quantity, string format, ...);
		[PrintfFormat]
		[Version (since = "2.16")]
		public static void maximized_result (double maximized_quantity, string format, ...);
		[Version (since = "2.16")]
		public static void init ([CCode (array_length_pos = 0.9)] ref unowned string[] args, ...);
		public static bool quick ();
		public static bool slow ();
		public static bool thorough ();
		public static bool perf ();
		public static bool verbose ();
		public static bool quiet ();
		[Version (since = "2.16")]
		public static int run ();
		[Version (since = "2.16")]
		public static void add (string testpath, void* fixture, [CCode (delegate_target_pos = 2.9)] TestFixtureFunc fsetup, [CCode (delegate_target_pos = 2.9)] TestFixtureFunc ftest, [CCode (delegate_target_pos = 2.9)] TestFixtureFunc fteardown);
		[Version (since = "2.16")]
		public static void add_func (string testpath, [CCode (scope = "async")] owned TestFunc test_funcvoid);
		[Version (since = "2.16")]
		public static void add_data_func (string testpath, [CCode (delegate_target_pos = 1.9, scope = "async")] owned TestDataFunc test_funcvoid);
		[Version (since = "2.34")]
		public static void add_data_func_full (string testpath, [CCode (delegate_target_pos = 1.9)] owned TestDataFunc test_func);
		[Version (since = "2.34")]
		public static void assert_expected_messages ();
		[Version (since = "2.38")]
		public static string build_filename (GLib.Test.FileType file_type, params string[] path_segments);
		[Version (since = "2.34")]
		public static void expect_message (string? log_domain, LogLevelFlags log_level, string pattern);
		[Version (since = "2.30")]
		public static void fail ();
		[Version (since = "2.38")]
		public static bool failed ();
		[Version (since = "2.38")]
		public static unowned string get_dir (GLib.Test.FileType file_type);
		[Version (since = "2.38")]
		public static unowned string get_filename (GLib.Test.FileType file_type, params string[] path_segments);
		[Version (since = "2.38")]
		public static void incomplete (string? msg = null);
		[Version (since = "2.36")]
		public static bool initialized ();
		[PrintfFormat]
		[Version (since = "2.16")]
		public static void message (string format, ...);
		[Version (since = "2.38")]
		public static void set_nonfatal_assertions ();
		[Version (since = "2.38")]
		public static void skip (string? msg = null);
		[Version (since = "2.38")]
		public static bool subprocess ();
		[Version (since = "2.16")]
		public static void bug_base (string uri_pattern);
		[Version (since = "2.16")]
		public static void bug (string bug_uri_snippet);
		[Version (since = "2.16")]
		public static void timer_start ();
		[Version (since = "2.16")]
		public static double timer_elapsed ();
		[Version (since = "2.16")]
		public static double timer_last ();
		[Version (since = "2.16", deprecated_since = "2.38", replacement = "trap_subprocess")]
		public static bool trap_fork (uint64 usec_timeout, TestTrapFlags test_trap_flags);
		[Version (since = "2.16")]
		public static bool trap_has_passed ();
		[Version (since = "2.16")]
		public static bool trap_reached_timeout ();
		[Version (since = "2.38")]
		public static void trap_subprocess (string? test_path, uint64 usec_timeout, TestSubprocessFlags test_flags);
		[Version (since = "2.16")]
		public static void trap_assert_passed ();
		[Version (since = "2.16")]
		public static void trap_assert_failed ();
		[Version (since = "2.16")]
		public static void trap_assert_stdout (string soutpattern);
		[Version (since = "2.16")]
		public static void trap_assert_stdout_unmatched (string soutpattern);
		[Version (since = "2.16")]
		public static void trap_assert_stderr (string serrpattern);
		[Version (since = "2.16")]
		public static void trap_assert_stderr_unmatched (string serrpattern);
		[Version (since = "2.16")]
		public static bool rand_bit ();
		[Version (since = "2.16")]
		public static int32 rand_int ();
		[Version (since = "2.16")]
		public static int32 rand_int_range (int32 begin, int32 end);
		[Version (since = "2.16")]
		public static double rand_double ();
		[Version (since = "2.16")]
		public static double rand_double_range (double begin, double end);
		[Version (since = "2.22")]
		public static void log_set_fatal_handler (LogFatalFunc log_func);
	}

	public delegate bool LogFatalFunc (string? log_domain, LogLevelFlags log_levels, string message);

	[Compact]
	[CCode (cname = "GTestCase", ref_function = "", unref_function = "")]
	public class TestCase {
		[Version (since = "2.16")]
		[CCode (cname = "g_test_create_case")]
		public TestCase (string test_name, [CCode (delegate_target_pos = 1.9)] TestFixtureFunc data_setup, [CCode (delegate_target_pos = 1.9)] TestFixtureFunc data_func, [CCode (delegate_target_pos = 1.9)] TestFixtureFunc data_teardown, [CCode (pos = 1.8)] size_t data_size = 0);
	}

	[Compact]
	[CCode (cname = "GTestSuite", ref_function = "", unref_function = "")]
	public class TestSuite {
		[Version (since = "2.16")]
		[CCode (cname = "g_test_create_suite")]
		public TestSuite (string name);
		[Version (since = "2.16")]
		[CCode (cname = "g_test_get_root")]
		public static TestSuite get_root ();
		[Version (since = "2.16")]
		[CCode (cname = "g_test_suite_add")]
		public void add (TestCase test_case);
		[Version (since = "2.16")]
		[CCode (cname = "g_test_suite_add_suite")]
		public void add_suite (TestSuite test_suite);
	}

	[Version (since = "2.26")]
	[CCode (has_target = false)]
	public delegate void TestFunc ();
	[Version (since = "2.26")]
	public delegate void TestDataFunc ();
	[Version (since = "2.26")]
	public delegate void TestFixtureFunc (void* fixture);

	[CCode (cprefix = "G_TEST_SUBPROCESS_INHERIT_", has_type_id = false)]
	[Flags]
	public enum TestSubprocessFlags {
		STDIN,
		STDOUT,
		STDERR
	}

	[Flags]
	[CCode (cprefix = "G_TEST_TRAP_", has_type_id = false)]
	public enum TestTrapFlags {
		SILENCE_STDOUT,
		SILENCE_STDERR,
		INHERIT_STDIN
	}

	/* Doubly-Linked Lists */

	[Compact]
	[CCode (dup_function = "g_list_copy", free_function = "g_list_free")]
	public class List<G> {
		public List ();

		[ReturnsModifiedPointer ()]
		public void append (owned G data);
		[ReturnsModifiedPointer ()]
		public void prepend (owned G data);
		[ReturnsModifiedPointer ()]
		public void insert (owned G data, int position);
		[ReturnsModifiedPointer ()]
		public void insert_before (List<G> sibling, owned G data);
		[ReturnsModifiedPointer ()]
		public void insert_sorted (owned G data, CompareFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void remove (G data);
		[ReturnsModifiedPointer ()]
		public void remove_link (List<G> llink);
		[ReturnsModifiedPointer ()]
		public void delete_link (List<G> link_);
		[ReturnsModifiedPointer ()]
		public void remove_all (G data);

		public uint length ();
		public List<unowned G> copy ();
		[Version (since = "2.34")]
		public List<G> copy_deep (CopyFunc<G> func);
		[ReturnsModifiedPointer ()]
		public void reverse ();
		[ReturnsModifiedPointer ()]
		public void sort (CompareFunc<G> compare_func);
		[Version (since = "2.10")]
		[ReturnsModifiedPointer ()]
		public void insert_sorted_with_data (owned G data, CompareDataFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void sort_with_data (CompareDataFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void concat (owned List<G> list2);
		public void @foreach (Func<G> func);

		public unowned List<G> first ();
		public unowned List<G> last ();
		public unowned List<G> nth (uint n);
		public unowned G nth_data (uint n);
		public unowned List<G> nth_prev (uint n);

		public unowned List<G> find (G data);
		public unowned List<G> find_custom (G data, CompareFunc<G> func);
		[CCode (cname = "g_list_find_custom", simple_generics = true)]
		public unowned List<G> search<T> (T data, SearchFunc<G,T> func);

		public int position (List<G> llink);
		public int index (G data);

		public G data;
		public List<G> next;
		public unowned List<G> prev;
	}

	/* Singly-Linked Lists */

	[Compact]
	[CCode (dup_function = "g_slist_copy", free_function = "g_slist_free")]
	public class SList<G> {
		public SList ();

		[ReturnsModifiedPointer ()]
		public void append (owned G data);
		[ReturnsModifiedPointer ()]
		public void prepend (owned G data);
		[ReturnsModifiedPointer ()]
		public void insert (owned G data, int position);
		[ReturnsModifiedPointer ()]
		public void insert_before (SList<G> sibling, owned G data);
		[ReturnsModifiedPointer ()]
		public void insert_sorted (owned G data, CompareFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void remove (G data);
		[ReturnsModifiedPointer ()]
		public void remove_link (SList<G> llink);
		[ReturnsModifiedPointer ()]
		public void delete_link (SList<G> link_);
		[ReturnsModifiedPointer ()]
		public void remove_all (G data);

		public uint length ();
		public SList<unowned G> copy ();
		[Version (since = "2.34")]
		public SList<G> copy_deep (CopyFunc<G> func);
		[ReturnsModifiedPointer ()]
		public void reverse ();
		[Version (since = "2.10")]
		[ReturnsModifiedPointer ()]
		public void insert_sorted_with_data (owned G data, CompareDataFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void sort (CompareFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void sort_with_data (CompareDataFunc<G> compare_func);
		[ReturnsModifiedPointer ()]
		public void concat (owned SList<G> list2);
		public void @foreach (Func<G> func);

		public unowned SList<G> last ();
		public unowned SList<G> nth (uint n);
		public unowned G nth_data (uint n);

		public unowned SList<G> find (G data);
		public unowned SList<G> find_custom (G data, CompareFunc<G> func);
		[CCode (cname = "g_slist_find_custom", simple_generics = true)]
		public unowned SList<G> search<T> (T data, SearchFunc<G,T> func);

		public int position (SList<G> llink);
		public int index (G data);

		public G data;
		public SList<G> next;
	}

	[CCode (has_target = false)]
	public delegate int CompareFunc<G> (G a, G b);

	public delegate int CompareDataFunc<G> (G a, G b);

	[Version (since = "2.16")]
	[CCode (cname = "g_strcmp0")]
	public static GLib.CompareFunc<string> strcmp;

	public delegate G CopyFunc<G> (G src);

	[CCode (cname = "GCompareFunc", has_target = false)]
	public delegate int SearchFunc<G,T> (G a, T b);

	/* Double-ended Queues */

	[Compact]
	[CCode (dup_function = "g_queue_copy", free_function = "g_queue_free")]
	public class Queue<G> {
		public unowned List<G> head;
		public unowned List<G> tail;
		public uint length;

		public Queue ();

		[Version (since = "2.14")]
		public void clear ();
		public bool is_empty ();
		[Version (since = "2.4")]
		public uint get_length ();
		[Version (since = "2.4")]
		public void reverse ();
		public Queue copy ();
		[Version (since = "2.4")]
		public unowned List<G> find (G data);
		[Version (since = "2.4")]
		public unowned List<G> find_custom (G data, CompareFunc<G> func);
		[CCode (cname = "g_queue_find_custom", simple_generics = true)]
		public unowned List<G> search<T> (T data, SearchFunc<G,T> func);
		[Version (since = "2.4")]
		public void sort (CompareDataFunc<G> compare_func);
		public void push_head (owned G data);
		public void push_tail (owned G data);
		[Version (since = "2.4")]
		public void push_nth (owned G data, int n);
		public G pop_head ();
		public G pop_tail ();
		[Version (since = "2.4")]
		public G pop_nth (uint n);
		public unowned G peek_head ();
		public unowned G peek_tail ();
		[Version (since = "2.4")]
		public unowned G peek_nth (uint n);
		[Version (since = "2.4")]
		public int index (G data);
		[Version (since = "2.4")]
		public bool remove (G data);
		[Version (since = "2.4")]
		public uint remove_all (G data);
		[Version (since = "2.4")]
		public void delete_link (List<G> link);
		[Version (since = "2.4")]
		public void unlink (List<G> link);
		[Version (since = "2.4")]
		public void insert_before (List<G> sibling, owned G data);
		[Version (since = "2.4")]
		public void insert_after (List<G> sibling, owned G data);
		[Version (since = "2.4")]
		public void insert_sorted (owned G data, CompareDataFunc<G> func);
	}

	/* Sequences */

	[Compact]
	[Version (since = "2.14")]
	[CCode (free_function = "g_sequence_free")]
	public class Sequence<G> {
		[CCode (simple_generics = true)]
		public Sequence ();
		public int get_length ();
		public void @foreach (Func<G> func);
		public void sort (CompareDataFunc<G> cmp_func);
		public void sort_iter (SequenceIterCompareFunc<G> func);
		public SequenceIter<G> get_begin_iter ();
		public SequenceIter<G> get_end_iter ();
		public SequenceIter<G> get_iter_at_pos (int pos);
		public SequenceIter<G> append (owned G data);
		public SequenceIter<G> prepend (owned G data);
		public SequenceIter<G> insert_sorted (owned G data, CompareDataFunc<G> cmp_func);
		[Version (since = "2.48")]
		public bool is_empty ();
		public SequenceIter<G> insert_sorted_iter (owned G data, SequenceIterCompareFunc<G> iter_cmp);
		public SequenceIter<G> search (G data, CompareDataFunc<G> cmp_func);
		public SequenceIter<G> search_iter (G data, SequenceIterCompareFunc<G> iter_cmp);
		[Version (since = "2.28")]
		public SequenceIter<G> lookup (G data, CompareDataFunc<G> cmp_func);
		[Version (since = "2.28")]
		public SequenceIter<G> lookup_iter (G data, SequenceIterCompareFunc<G> iter_cmp);

		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.foreach_range")]
		public static void foreach_range (SequenceIter<G> begin, SequenceIter<G> end, Func<G> func);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.insert_before")]
		public static SequenceIter<G> insert_before (SequenceIter<G> iter, owned G data);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.move_to")]
		public static void move (SequenceIter<G> src, SequenceIter<G> dest);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.swap")]
		public static void swap (SequenceIter<G> src, SequenceIter<G> dest);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.sort_changed")]
		public static void sort_changed (SequenceIter<G> iter, CompareDataFunc<G> cmp_func);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.sort_changed_iter")]
		public static void sort_changed_iter (SequenceIter<G> iter, SequenceIterCompareFunc<G> iter_cmp);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.remove")]
		public static void remove (SequenceIter<G> iter);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.remove_range")]
		public static void remove_range (SequenceIter<G> begin, SequenceIter<G> end);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.move_range")]
		public static void move_range (SequenceIter<G> dest, SequenceIter<G> begin, SequenceIter<G> end);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.get")]
		public static unowned G get (SequenceIter<G> iter);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.set")]
		public static void set (SequenceIter<G> iter, owned G data);
		[Version (deprecated_since = "vala-0.26", replacement = "SequenceIter.range_get_midpoint")]
		public static SequenceIter<G> range_get_midpoint (SequenceIter<G> begin, SequenceIter<G> end);
	}

	[Compact]
	[Version (since = "2.14")]
	[CCode (ref_function = "", unref_function = "")]
	public class SequenceIter<G> {
		public bool is_begin ();
		public bool is_end ();
		public SequenceIter<G> next ();
		public SequenceIter<G> prev ();
		public int get_position ();
		public SequenceIter<G> move (int delta);
		public unowned Sequence<G> get_sequence ();
		public int compare (SequenceIter<G> other);

		[CCode (cname = "g_sequence_foreach_range")]
		public void foreach_range (SequenceIter<G> end, Func<G> func);
		[CCode (cname = "g_sequence_insert_before")]
		public SequenceIter<G> insert_before (owned G data);
		[CCode (cname = "g_sequence_move")]
		public void move_to (SequenceIter<G> dest);
		[CCode (cname = "g_sequence_swap")]
		public void swap (SequenceIter<G> dest);
		[CCode (cname = "g_sequence_sort_changed")]
		public void sort_changed (CompareDataFunc<G> cmp_func);
		[CCode (cname = "g_sequence_sort_changed_iter")]
		public void sort_changed_iter (SequenceIterCompareFunc<G> iter_cmp);
		[CCode (cname = "g_sequence_remove")]
		public void remove ();
		[CCode (cname = "g_sequence_remove_range")]
		public void remove_range (SequenceIter<G> end);
		[CCode (cname = "g_sequence_move_range")]
		public void move_range (SequenceIter<G> begin, SequenceIter<G> end);
		[CCode (cname = "g_sequence_get")]
		public unowned G get ();
		[CCode (cname = "g_sequence_set")]
		public void set (owned G data);
		[CCode (cname = "g_sequence_range_get_midpoint")]
		public SequenceIter<G> range_get_midpoint (SequenceIter<G> end);
	}

	public delegate int SequenceIterCompareFunc<G> (SequenceIter<G> a, SequenceIter<G> b);

	/* Hash Tables */

	[Compact]
	[CCode (ref_function = "g_hash_table_ref", unref_function = "g_hash_table_unref", type_id = "G_TYPE_HASH_TABLE", type_signature = "a{%s}")]
	public class HashTable<K,V> {
		[CCode (cname = "g_hash_table_new_full", simple_generics = true)]
		public HashTable (HashFunc<K>? hash_func, EqualFunc<K>? key_equal_func);
		public HashTable.full (HashFunc<K>? hash_func, EqualFunc<K>? key_equal_func, DestroyNotify? key_destroy_func, DestroyNotify? value_destroy_func);
		public void insert (owned K key, owned V value);
		public void replace (owned K key, owned V value);
		[Version (since = "2.32", deprecated_since = "vala-0.26", replacement = "GenericSet.add")]
		public void add (owned K key);
		public unowned V? lookup (K key);
		public bool lookup_extended (K lookup_key, out unowned K orig_key, out unowned V value);
		[Version (since = "2.32")]
		public bool contains (K key);
		public bool remove (K key);
		[Version (since = "2.12")]
		public void remove_all ();
		public uint foreach_remove (HRFunc<K,V> predicate);
		public uint foreach_steal (HRFunc<K,V> predicate);
		[CCode (cname = "g_hash_table_lookup")]
		public unowned V? @get (K key);
		[CCode (cname = "g_hash_table_insert")]
		public void @set (owned K key, owned V value);
		[Version (since = "2.14")]
		public List<unowned K> get_keys ();
#if VALA_0_26
		[Version (since = "2.40")]
		public (unowned K)[] get_keys_as_array ();
#endif
		[Version (since = "2.14")]
		public List<unowned V> get_values ();
		public void @foreach (HFunc<K,V> func);
		[CCode (cname = "g_hash_table_foreach")]
		public void for_each (HFunc<K,V> func);
		[Version (since = "2.4")]
		public unowned V? find (HRFunc<K,V> predicate);
		public uint size ();
		public bool steal (K key);
		[Version (since = "2.12")]
		public void steal_all ();
		[CCode (cname = "_vala_g_hash_table_take")]
		public V? take (K key, out bool exists = null) {
			GLib.HashTable<K,V>? ht = null;
			void** htp = &ht;
			*htp = this.lookup (key);
			exists = this.steal (key);
			return ht;
		}
		public uint length {
			[CCode (cname = "g_hash_table_size")]
			get;
		}
	}

	[Version (since = "2.16")]
	public struct HashTableIter<K,V> {
		public HashTableIter (GLib.HashTable<K,V> table);
		public bool next ([CCode (type = "gpointer*")] out unowned K key, [CCode (type = "gpointer*")] out unowned V value);
		public void remove ();
		public void steal ();
		public unowned GLib.HashTable<K,V> get_hash_table ();
	}

	[Version (since = "2.32")]
	[Compact, CCode (cname = "GHashTable", lower_case_cprefix = "g_hash_table_", ref_function = "g_hash_table_ref", unref_function = "g_hash_table_unref", type_id = "G_TYPE_HASH_TABLE", type_signature = "a{%s}")]
	public class GenericSet<T> {
		[CCode (cname = "g_hash_table_new_full", simple_generics = true)]
		public GenericSet (HashFunc<T>? hash_func, EqualFunc<T>? equal_func, GLib.DestroyNotify? always_pass_null_here = null);
		public void add (owned T value);
		public bool contains (T valule);
		public bool remove (T value);
		public void remove_all ();
		public GLib.List<unowned T> get_values ();
		[CCode (cname = "g_hash_table_iter_init", instance_pos = -1)]
		public GLib.GenericSetIter<T> iterator ();
		[CCode (cname = "_vala_g_hash_set_foreach")]
		public void @foreach (GLib.Func<T> func) {
			((GLib.HashTable<unowned T,T>) this).foreach ((k, v) => func (v));
		}
		public uint length {
			[CCode (cname = "g_hash_table_size")]
			get;
		}
	}

	[Version (since = "2.32")]
	[CCode (cname = "GHashTableIter", lower_case_cprefix = "g_hash_table_iter_")]
	public struct GenericSetIter<T> {
		[CCode (cname = "_vala_hash_set_next_value")]
		public unowned T? next_value () {
			void* vi = &this;
			GLib.HashTableIter<unowned T,T>* htp = vi;
			unowned T? value;
			return htp->next (out value, null) ? value : null;
		}
		public void remove ();
	}

	[CCode (has_target = false)]
	public delegate uint HashFunc<K> (K key);
	[CCode (has_target = false)]
	public delegate bool EqualFunc<G> (G a, G b);
	public delegate void HFunc<K,V> (K key, V value);
	public delegate bool HRFunc<K,V> (K key, V value);

	[CCode (has_target = false)]
	public delegate void DestroyNotify (void* data);

	[CCode (cname = "g_direct_hash")]
	public static GLib.HashFunc<void*> direct_hash;
	[CCode (cname = "g_direct_equal")]
	public static GLib.EqualFunc<void*> direct_equal;
	[CCode (cname = "g_int64_hash")]
	public static GLib.HashFunc<int64?> int64_hash;
	[Version (since = "2.22")]
	[CCode (cname = "g_int64_equal")]
	public static GLib.EqualFunc<int64?> int64_equal;
	[Version (since = "2.22")]
	[CCode (cname = "g_int_hash")]
	public static GLib.HashFunc<int?> int_hash;
	[CCode (cname = "g_int_equal")]
	public static GLib.EqualFunc<int?> int_equal;
	[CCode (cname = "g_str_hash")]
	public static GLib.HashFunc<string> str_hash;
	[CCode (cname = "g_str_equal")]
	public static GLib.EqualFunc<string> str_equal;
	[CCode (cname = "g_free")]
	public static GLib.DestroyNotify g_free;
	[CCode (cname = "g_object_unref")]
	public static GLib.DestroyNotify g_object_unref;
	[CCode (cname = "g_list_free")]
	public static GLib.DestroyNotify g_list_free;
	[CCode (cname = "((GDestroyNotify) g_variant_unref)")]
	public static GLib.DestroyNotify g_variant_unref;

	/* Strings */

	[Compact]
	[GIR (name = "String")]
	[CCode (cname = "GString", cprefix = "g_string_", free_function = "g_string_free", type_id = "G_TYPE_GSTRING")]
	public class StringBuilder {
		public StringBuilder (string init = "");
		[CCode (cname = "g_string_sized_new")]
		public StringBuilder.sized (size_t dfl_size);
		public unowned StringBuilder assign (string rval);
		public unowned StringBuilder append (string val);
		public unowned StringBuilder append_c (char c);
		public unowned StringBuilder append_unichar (unichar wc);
		public unowned StringBuilder append_len (string val, ssize_t len);
		public unowned StringBuilder prepend (string val);
		public unowned StringBuilder prepend_c (char c);
		public unowned StringBuilder prepend_unichar (unichar wc);
		public unowned StringBuilder prepend_len (string val, ssize_t len);
		public unowned StringBuilder insert (ssize_t pos, string val);
		public unowned StringBuilder insert_len (ssize_t pos, string val, ssize_t len);
		public unowned StringBuilder insert_unichar (ssize_t pos, unichar wc);
		[Version (since = "2.14")]
		public unowned StringBuilder overwrite (size_t pos, string val);
		[Version (since = "2.14")]
		public unowned StringBuilder overwrite_len (size_t pos, string val, ssize_t len);
		public unowned StringBuilder erase (ssize_t pos = 0, ssize_t len = -1);
		public unowned StringBuilder truncate (size_t len = 0);

		[PrintfFormat]
		public void printf (string format, ...);
		[PrintfFormat]
		public void append_printf (string format, ...);
		[Version (since = "2.14")]
		public void vprintf (string format, va_list args);
		[Version (since = "2.14")]
		public void append_vprintf (string format, va_list args);

		public string str;
		public ssize_t len;
		public ssize_t allocated_len;

		public uint8[] data {
			get {
				unowned uint8[] res = (uint8[]) this.str;
				res.length = (int) this.len;
				return res;
			}
		}

		[Version (since = "2.34")]
		public static Bytes free_to_bytes (owned StringBuilder str);
	}

	/* String Chunks */

	[Compact]
	[CCode (free_function = "g_string_chunk_free")]
	public class StringChunk {
		public StringChunk (size_t size);
		public unowned string insert (string str);
		public unowned string insert_const (string str);
		[Version (since = "2.4")]
		public unowned string insert_len (string str, ssize_t len);
		[Version (since = "2.14")]
		public void clear ();
	}

	/* Pointer Arrays */

	[Compact]
	[Version (since = "2.22", deprecated_since = "vala-0.26", replacement="GenericArray")]
	[CCode (ref_function = "g_ptr_array_ref", unref_function = "g_ptr_array_unref", type_id = "G_TYPE_PTR_ARRAY")]
	public class PtrArray {
		public PtrArray ();
		[Version (since = "2.22")]
		public PtrArray.with_free_func (GLib.DestroyNotify? element_free_func);
		[CCode (cname = "g_ptr_array_sized_new")]
		public PtrArray.sized (uint reserved_size);
		public void add (void* data);
		[Version (since = "2.4")]
		public void foreach (GLib.Func<void*> func);
		[CCode (cname = "g_ptr_array_index")]
		public void* index(uint index);
		public bool remove (void* data);
		public void* remove_index (uint index);
		public bool remove_fast (void *data);
		public void remove_index_fast (uint index);
		[Version (since = "2.4")]
		public void remove_range (uint index, uint length);
		public void sort (CompareFunc<void**> compare_func);
		public void sort_with_data (CompareDataFunc<void**> compare_func);
		[Version (since = "2.22")]
		public void set_free_func (GLib.DestroyNotify? element_free_function);
		public void set_size (int length);

		public uint len;
		public void** pdata;
	}

	[Compact]
	[CCode (cname = "GPtrArray", cprefix = "g_ptr_array_", ref_function = "g_ptr_array_ref", unref_function = "g_ptr_array_unref", type_id = "G_TYPE_PTR_ARRAY")]
	[GIR (name = "PtrArray")]
	public class GenericArray<G> {
		[Version (since = "2.30")]
		[CCode (cname = "g_ptr_array_new_full", simple_generics = true)]
		public GenericArray (uint reserved_size = 0);
		public void add (owned G data);
		[Version (since = "2.54")]
		public bool find (G needle, out uint index = null);
		[Version (since = "2.54")]
		public bool find_with_equal_func (G needle, GLib.EqualFunc<G>? equal_func, out uint index = null);
		public void foreach (GLib.Func<G> func);
		[CCode (cname = "g_ptr_array_index")]
		public unowned G get (uint index);
		[Version (since = "2.40")]
		public void insert (int index, owned G data);
		public bool remove (G data);
		public void remove_index (uint index);
		public bool remove_fast (G data);
		public void remove_index_fast (uint index);
		public void remove_range (uint index, uint length);
		public void set (uint index, owned G data) {
			this.add ((owned) data);
			this.remove_index_fast (index);
		}
		[CCode (cname = "vala_g_ptr_array_sort")]
		public void sort (GLib.CompareFunc<G> compare_func) {
			this._sort_with_data ((a, b) => {
				return compare_func ((G**) (*a), (G**) (*b));
			});
		}
		[CCode (cname = "g_ptr_array_sort_with_data")]
		public void _sort_with_data (GLib.CompareDataFunc<G**> compare_func);
		[CCode (cname = "vala_g_ptr_array_sort_with_data")]
		public void sort_with_data (GLib.CompareDataFunc<G> compare_func) {
			this._sort_with_data ((a, b) => {
				return compare_func ((G**) (*a), (G**) (*b));
			});
		}
		private void set_size (int length);

		public int length {
			get { return (int) this.len; }
			set { this.set_size (value); }
		}

		[CCode (cname = "pdata", array_length_cname = "len", array_length_type = "guint")]
		public G[] data;

		private uint len;
	}

	[Compact]
	[Version (since = "2.32")]
	[CCode (cprefix = "g_bytes_", ref_function = "g_bytes_ref", unref_function = "g_bytes_unref", type_id = "G_TYPE_BYTES")]
	public class Bytes {
		public Bytes ([CCode (array_length_type = "gsize")] uint8[] data);
		public Bytes.take ([CCode (array_length_type = "gsize")] owned uint8[] data);
		public Bytes.static ([CCode (array_length_type = "gsize")] uint8[] data);
		public Bytes.with_free_func ([CCode (array_length_type = "gsize")] owned uint8[] data, GLib.DestroyNotify? free_func, void* user_data);
		public Bytes.from_bytes (GLib.Bytes bytes, size_t offset, size_t length);

		[CCode (cname = "g_bytes_new_with_free_func", simple_generics = true)]
		public static Bytes new_with_owner<T> ([CCode (array_length_type = "gsize")] uint8[] data, [CCode (destroy_notify_pos = 1.9)] owned T? owner = null);

		[CCode (array_length_type = "gsize")]
		public unowned uint8[] get_data ();
		public size_t get_size ();
		public uint hash ();
		public int compare (GLib.Bytes bytes2);
		public static uint8[] unref_to_data (owned GLib.Bytes bytes);
		public static GLib.ByteArray unref_to_array (owned GLib.Bytes bytes);

		[CCode (cname = "_vala_g_bytes_get")]
		public uint8 get (int index) {
			unowned uint8[] data = this.get_data ();
			return data[index];
		}

		[CCode (cname = "_vala_g_bytes_slice")]
		public GLib.Bytes slice (size_t start, size_t end) {
			return new GLib.Bytes.from_bytes (this, start, end - start);
		}

		public int length {
			[CCode (cname = "_vala_g_bytes_get_length")]
			get {
				return (int) this.get_size ();
			}
		}
	}

	/* Byte Arrays */

	[Compact]
	[Version (since = "2.22")]
	[CCode (cprefix = "g_byte_array_", ref_function = "g_byte_array_ref", unref_function = "g_byte_array_unref", type_id = "G_TYPE_BYTE_ARRAY")]
	public class ByteArray {
		public ByteArray ();
		[CCode (cname = "g_byte_array_sized_new")]
		public ByteArray.sized (uint reserved_size);
		[Version (since = "2.32")]
		public ByteArray.take (owned uint8[] data);
		public void append (uint8[] data);
		[Version (since = "2.32")]
		public static GLib.Bytes free_to_bytes (owned GLib.ByteArray array);
		public void prepend (uint8[] data);
		public void remove_index (uint index);
		public void remove_index_fast (uint index);
		[Version (since = "2.4")]
		public void remove_range (uint index, uint length);
		public void sort (CompareFunc<int8> compare_func);
		public void sort_with_data (CompareDataFunc<int8> compare_func);
		public void set_size (uint length);

		public uint len;
		[CCode (array_length_cname = "len", array_length_type = "guint")]
		public uint8[] data;
	}

	/* N-ary Trees */

	public delegate bool NodeTraverseFunc (Node node);
	public delegate void NodeForeachFunc (Node node);

	[CCode (cprefix = "G_TRAVERSE_")]
	public enum TraverseFlags {
		LEAVES,
		NON_LEAVES,
		ALL,
		MASK,
		LEAFS,
		NON_LEAFS
	}

	[Compact]
	[CCode (dup_function = "g_node_copy", free_function = "g_node_destroy")]
	public class Node<G> {
		public Node(owned G? data = null);
		public Node<unowned G> copy ();
		public Node<G> copy_deep (CopyFunc<G> copy_func);
		public unowned Node<G> insert (int position, owned Node<G> node);
		public unowned Node<G> insert_before (Node<G> sibling, owned Node<G> node);
		public unowned Node<G> insert_after (Node<G> sibling, owned Node<G> node);
		public unowned Node<G> append (owned Node<G> node);
		public unowned Node<G> prepend (owned Node<G> node);
		public unowned Node<G> insert_data (int position, owned G data);
		public unowned Node<G> insert_data_before (Node<G> sibling, owned G data);
		public unowned Node<G> append_data (owned G data);
		public unowned Node<G> prepend_data (owned G data);
		public void reverse_children ();
		public void traverse (TraverseType order, TraverseFlags flags, int max_depth, NodeTraverseFunc func);
		public void children_foreach (TraverseFlags flags, NodeForeachFunc func);
		public unowned Node<G> get_root ();
		public unowned Node<G> find (TraverseType order, TraverseFlags flags, G data);
		public unowned Node<G> find_child (TraverseFlags flags, G data);
		public int child_index (G data);
		public int child_position (Node<G> child);
		public unowned Node<G> first_child ();
		public unowned Node<G> last_child ();
		public unowned Node<G> nth_child (uint n);
		public unowned Node<G> first_sibling ();
		public unowned Node<G> next_sibling ();
		public unowned Node<G> prev_sibling ();
		public unowned Node<G> last_sibling ();

		[CCode (cname = "G_NODE_IS_LEAF")]
		public bool is_leaf ();
		[CCode (cname = "G_NODE_IS_ROOT")]
		public bool is_root ();
		public bool is_ancestor (Node<G> descendant);

		public uint depth ();
		public uint n_nodes (TraverseFlags flags);
		public uint n_children ();
		public uint max_height ();

		[CCode (cname = "g_node_unlink")]
		public void _unlink ();
		[CCode (cname = "g_node_unlink_vala")]
		public Node<G> unlink ()
		{
			void *ptr = this;
			_unlink ();
			return (Node<G>) (owned) ptr;
		}

		public G data;
		public Node next;
		public Node prev;
		public Node parent;
		public Node children;
	}

	/* Quarks */

	[CCode (type_id = "G_TYPE_UINT")]
	public struct Quark : uint32 {
		public static Quark from_string (string str);
		public static Quark try_string (string str);
		public unowned string to_string ();
	}

	/* Keyed Data Lists */

	[CCode (cname = "GData*")]
	public struct Datalist<G> {
		public Datalist ();
		public void clear ();
		[Version (since = "2.34")]
		public G id_dup_data (Quark key_id, DuplicateFunc<G> dup_func);
		public unowned G id_get_data (Quark key_id);
		public void id_set_data (Quark key_id, owned G data);
		public void id_set_data_full (Quark key_id, owned G data, DestroyNotify? destroy_func);
		public void id_remove_data (Quark key_id);
		public G id_remove_no_notify (Quark key_id);
		[Version (since = "2.34")]
		public bool id_replace_data (Quark key_id, G oldval, owned G newval, GLib.DestroyNotify? destroy, out GLib.DestroyNotify? old_destroy);
		public void @foreach (DataForeachFunc<G> func);
		public unowned G get_data (string key);
		public void set_data_full (string key, owned G data, DestroyNotify? destry_func);
		public G remove_no_notify (string key);
		public void set_data (string key, owned G data);
		public void remove_data (string key);
	}

	public delegate void DataForeachFunc<G> (Quark key_id, G data);
	public delegate G DuplicateFunc<G> (G data);

	/* GArray */

	[Compact]
	[Version (since = "2.22")]
	[CCode (ref_function = "g_array_ref", unref_function = "g_array_unref", type_id = "G_TYPE_ARRAY")]
	public class Array<G> {
		[CCode (cname = "len")]
		public uint length;
		[CCode (cname = "data", array_length_cname = "len", array_length_type = "uint")]
		public G[] data;

		public Array (bool zero_terminated = true, bool clear = true, ulong element_size = 0);
		[CCode (cname = "g_array_sized_new")]
		public Array.sized (bool zero_terminated, bool clear, ulong element_size, uint reserved_size);
		public void append_val (owned G value);
		public void append_vals (void* data, uint len);
		public void prepend_val (owned G value);
		public void prepend_vals (void* data, uint len);
		public void insert_val (uint index, owned G value);
		public void insert_vals (uint index, void* data, uint len);
		[CCode (cname = "g_array_remove_index")]
		public void _remove_index (uint index);
		[CCode (cname = "g_array_remove_index_fast")]
		public void _remove_index_fast (uint index);
		[CCode (cname = "g_array_remove_range")]
		public void _remove_range (uint index, uint length);
		[CCode (cname = "vala_g_array_remove_index")]
		public G remove_index (uint index) {
			assert (length > index);
			G g = data[index];
			_remove_index (index);
			return g;
		}
		[CCode (cname = "vala_g_array_remove_index_fast")]
		public G remove_index_fast (uint index) {
			assert (length > index);
			G g = data[index];
			_remove_index_fast (index);
			return g;
		}
		[CCode (cname = "vala_g_array_remove_range")]
		public G[] remove_range (uint index, uint length) {
			assert (this.length >= index + length);
			G[] ga = new G[length];
			for (uint i = 0; i < length; i++) {
				ga[i] = data[i + index];
			}
			_remove_range (index, length);
			return ga;
		}
		public void sort (CompareFunc<G> compare_func);
		public void sort_with_data (CompareDataFunc<G> compare_func);
		[CCode (generic_type_pos = 0.1)]
		public unowned G index (uint index);
		public void set_size (uint length);
	}

	/* GTree */

	public delegate bool TraverseFunc<K,V> (K key, V value);

	[CCode (cprefix = "G_", has_type_id = false)]
	public enum TraverseType {
		IN_ORDER,
		PRE_ORDER,
		POST_ORDER,
		LEVEL_ORDER
	}

	public delegate int TreeSearchFunc<K> (K key);

	[Compact]
	[Version (since = "2.22")]
	[CCode (ref_function = "g_tree_ref", unref_function = "g_tree_unref")]
	public class Tree<K,V> {
		[CCode (cname = "g_tree_new_full", simple_generics = true)]
		public Tree (CompareDataFunc<K> key_compare_func);
		[Version (deprecated_since = "vala-0.20", replacement = "Tree ()")]
		public Tree.with_data (CompareDataFunc<K> key_compare_func);
		public Tree.full (CompareDataFunc<K> key_compare_func, DestroyNotify? key_destroy_func, DestroyNotify? value_destroy_func);
		public void insert (owned K key, owned V value);
		public void replace (owned K key, owned V value);
		public int nnodes ();
		public int height ();
		public unowned V lookup (K key);
		public bool lookup_extended (K lookup_key, out unowned K orig_key, out unowned V value);
		public void foreach (TraverseFunc<K,V> traverse_func);
		public unowned V search (TreeSearchFunc<K> search_func);
		[CCode (cname = "g_tree_search")]
		public unowned V search_key (CompareFunc<K> search_func, K key);
		public bool remove (K key);
		public bool steal (K key);
	}

	/* Internationalization */

	[Version (since = "2.4")]
	[CCode (cname = "_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string _ ([FormatArg] string str);
	[Version (since = "2.4")]
	[CCode (cname = "Q_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string Q_ ([FormatArg] string str);
	[Version (since = "2.4")]
	[CCode (cname = "N_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string N_ ([FormatArg] string str);
	[Version (since = "2.16")]
	[CCode (cname = "C_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string C_ (string context, [FormatArg] string str);
	[Version (since = "2.18")]
	[CCode (cname = "NC_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string NC_ (string context, [FormatArg] string str);
	[CCode (cname = "ngettext", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string ngettext (string msgid, [FormatArg] string msgid_plural, ulong n);
	[Version (since = "2.18")]
	[CCode (cname = "g_dgettext", cheader_filename = "glib/gi18n-lib.h")]
	public static unowned string dgettext (string? domain, [FormatArg] string msgid);
	[Version (since = "2.26")]
	[CCode (cname = "g_dcgettext", cheader_filename = "glib/gi18n-lib.h")]
	public static unowned string dcgettext (string? domain, [FormatArg] string msgid, int category);
	[Version (since = "2.18")]
	[CCode (cname = "g_dngettext", cheader_filename = "glib/gi18n-lib.h")]
	public static unowned string dngettext (string? domain, string msgid, [FormatArg] string msgid_plural, ulong n);
	[Version (since = "2.16")]
	[CCode (cname = "g_dpgettext", cheader_filename = "glib/gi18n-lib.h")]
	public static unowned string dpgettext (string? domain, [FormatArg] string msgctxid, size_t msgidoffset);
	[Version (since = "2.18")]
	[CCode (cname = "g_dpgettext2", cheader_filename = "glib/gi18n-lib.h")]
	public static unowned string dpgettext2 (string? domain, string context, [FormatArg] string msgid);

	[CCode (cname = "int", cprefix = "LC_", cheader_filename = "locale.h", has_type_id = false)]
	public enum LocaleCategory {
		ALL,
		COLLATE,
		CTYPE,
		MESSAGES,
		MONETARY,
		NUMERIC,
		TIME
	}

	namespace Intl {
		[CCode (cname = "setlocale", cheader_filename = "locale.h")]
		public static unowned string? setlocale (LocaleCategory category = GLib.LocaleCategory.ALL, string? locale = "");
		[CCode (cname = "bindtextdomain", cheader_filename = "glib/gi18n-lib.h")]
		public static unowned string? bindtextdomain (string domainname, string? dirname);
		[CCode (cname = "textdomain", cheader_filename = "glib/gi18n-lib.h")]
		public static unowned string? textdomain (string? domainname);
		[CCode (cname = "bind_textdomain_codeset", cheader_filename = "glib/gi18n-lib.h")]
		public static unowned string? bind_textdomain_codeset (string domainname, string? codeset);
		[Version (since = "2.6")]
		[CCode (cname = "g_get_language_names", array_length = false, array_null_terminated = true)]
		public static unowned string[] get_language_names ();
		[Version (since = "2.4")]
		[CCode (cname = "g_strip_context", cheader_filename = "glib/gi18n-lib.h")]
		public static unowned string strip_context (string msgid, string msgval);
	}

	[Compact]
	public class PatternSpec {
		public PatternSpec (string pattern);
		public bool equal (PatternSpec pspec);
		[CCode (cname = "g_pattern_match")]
		public bool match (uint string_length, string str, string? str_reversed);
		[CCode (cname = "g_pattern_match_string")]
		public bool match_string (string str);
		[CCode (cname = "g_pattern_match_simple")]
		public static bool match_simple (string pattern, string str);
	}

	[CCode (lower_case_cprefix = "glib_version_")]
	namespace Version {
		[CCode (cname = "glib_major_version")]
		public const uint major;
		[CCode (cname = "glib_minor_version")]
		public const uint minor;
		[CCode (cname = "glib_micro_version")]
		public const uint micro;
		[CCode (cname = "glib_check_version")]
		public static unowned string? check (uint required_major, uint required_minor = 0, uint required_micro = 0);

		[CCode (cname = "GLIB_MAJOR_VERSION")]
		public const uint MAJOR;
		[CCode (cname = "GLIB_MINOR_VERSION")]
		public const uint MINOR;
		[CCode (cname = "GLIB_MICRO_VERSION")]
		public const uint MICRO;
		[CCode (cname = "GLIB_CHECK_VERSION")]
		public static bool CHECK (uint required_major, uint required_minor = 0, uint required_micro = 0);

		[CCode (cname = "G_ENCODE_VERSION")]
		public static uint encode (uint major, uint minor);

		public const uint CUR_STABLE;
		public const uint PREV_STABLE;
		public const uint MIN_REQUIRED;
		public const uint MAX_ALLOWED;

		public const uint @2_26;
		public const uint @2_28;
		public const uint @2_30;
		public const uint @2_32;
		public const uint @2_34;
		public const uint @2_36;
		public const uint @2_38;
		public const uint @2_40;
		public const uint @2_42;
		public const uint @2_44;
		public const uint @2_46;
		public const uint @2_48;
		public const uint @2_50;
		public const uint @2_52;
		public const uint @2_54;
		public const uint @2_56;

		[CCode (cname = "glib_binary_age")]
		public const uint binary_age;
		[CCode (cname = "glib_interface_age")]
		public const uint interface_age;
	}

	namespace Win32 {
		public enum OSType {
			[CCode (cname = "G_WIN32_OS_ANY")]
			ANY,
			[CCode (cname = "G_WIN32_OS_WORKSTATION")]
			WORKSTATION,
			[CCode (cname = "G_WIN32_OS_SERVER")]
			SERVER,
		}
		[Version (since = "2.44")]
		public bool check_windows_version (int major, int minor, int spver, GLib.Win32.OSType os_type);

		public string error_message (int error);
		public string getlocale ();
		[Version (since = "2.16")]
		public string get_package_installation_directory_of_module (void* hmodule);
		public uint get_windows_version ();
		[Version (since = "2.8")]
		public string locale_filename_from_utf8 (string utf8filename);
		[CCode (cname = "G_WIN32_HAVE_WIDECHAR_API")]
		public bool have_widechar_api ();
		[CCode (cname = "G_WIN32_IS_NT_BASED")]
		public bool is_nt_based ();
		[Version (since = "2.40")]
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] get_command_line ();
	}

	[Compact]
	[Immutable]
	[Version (since = "2.24")]
	[CCode (copy_function = "g_variant_type_copy", free_function = "g_variant_type_free", type_id = "G_TYPE_VARIANT_TYPE")]
	public class VariantType {
		[CCode (cname = "G_VARIANT_TYPE_BOOLEAN")]
		public static VariantType BOOLEAN;
		[CCode (cname = "G_VARIANT_TYPE_BYTE")]
		public static VariantType BYTE;
		[CCode (cname = "G_VARIANT_TYPE_INT16")]
		public static VariantType INT16;
		[CCode (cname = "G_VARIANT_TYPE_UINT16")]
		public static VariantType UINT16;
		[CCode (cname = "G_VARIANT_TYPE_INT32")]
		public static VariantType INT32;
		[CCode (cname = "G_VARIANT_TYPE_UINT32")]
		public static VariantType UINT32;
		[CCode (cname = "G_VARIANT_TYPE_INT64")]
		public static VariantType INT64;
		[CCode (cname = "G_VARIANT_TYPE_UINT64")]
		public static VariantType UINT64;
		[CCode (cname = "G_VARIANT_TYPE_HANDLE")]
		public static VariantType HANDLE;
		[CCode (cname = "G_VARIANT_TYPE_DOUBLE")]
		public static VariantType DOUBLE;
		[CCode (cname = "G_VARIANT_TYPE_STRING")]
		public static VariantType STRING;
		[CCode (cname = "G_VARIANT_TYPE_OBJECT_PATH")]
		public static VariantType OBJECT_PATH;
		[CCode (cname = "G_VARIANT_TYPE_SIGNATURE")]
		public static VariantType SIGNATURE;
		[CCode (cname = "G_VARIANT_TYPE_VARIANT")]
		public static VariantType VARIANT;
		[CCode (cname = "G_VARIANT_TYPE_UNIT")]
		public static VariantType UNIT;
		[CCode (cname = "G_VARIANT_TYPE_ANY")]
		public static VariantType ANY;
		[CCode (cname = "G_VARIANT_TYPE_BASIC")]
		public static VariantType BASIC;
		[CCode (cname = "G_VARIANT_TYPE_MAYBE")]
		public static VariantType MAYBE;
		[CCode (cname = "G_VARIANT_TYPE_ARRAY")]
		public static VariantType ARRAY;
		[CCode (cname = "G_VARIANT_TYPE_TUPLE")]
		public static VariantType TUPLE;
		[CCode (cname = "G_VARIANT_TYPE_DICT_ENTRY")]
		public static VariantType DICT_ENTRY;
		[CCode (cname = "G_VARIANT_TYPE_DICTIONARY")]
		public static VariantType DICTIONARY;
		[CCode (cname = "G_VARIANT_TYPE_STRING_ARRAY")]
		public static VariantType STRING_ARRAY;
		[CCode (cname = "G_VARIANT_TYPE_OBJECT_PATH_ARRAY")]
		public static VariantType OBJECT_PATH_ARRAY;
		[CCode (cname = "G_VARIANT_TYPE_BYTESTRING")]
		public static VariantType BYTESTRING;
		[CCode (cname = "G_VARIANT_TYPE_BYTESTRING_ARRAY")]
		public static VariantType BYTESTRING_ARRAY;
		[Version (since = "2.30")]
		[CCode (cname = "G_VARIANT_TYPE_VARDICT")]
		public static VariantType VARDICT;

		public static bool string_is_valid (string type_string);
		public static bool string_scan (string type_string, char *limit, out char* endptr);

		public VariantType (string type_string);
		public size_t get_string_length ();
		public char* peek_string ();
		public string dup_string ();

		public bool is_definite ();
		public bool is_container ();
		public bool is_basic ();
		public bool is_maybe ();
		public bool is_array ();
		public bool is_tuple ();
		public bool is_dict_entry ();
		public bool is_variant ();

		public uint hash ();
		public bool equal (VariantType other);
		public bool is_subtype_of (VariantType supertype);

		public unowned VariantType element ();
		public unowned VariantType first ();
		public unowned VariantType next ();
		public unowned VariantType n_items ();
		public unowned VariantType key ();
		public unowned VariantType value ();

		public VariantType.array (VariantType element);
		public VariantType.maybe (VariantType element);
		public VariantType.tuple (VariantType[] items);
		public VariantType.dict_entry (VariantType key, VariantType value);
	}

	[Compact]
	[Version (since = "2.24")]
	[CCode (ref_function = "g_variant_ref", unref_function = "g_variant_unref", ref_sink_function = "g_variant_ref_sink", type_id = "G_TYPE_VARIANT", marshaller_type_name = "VARIANT", param_spec_function = "g_param_spec_variant", get_value_function = "g_value_get_variant", set_value_function = "g_value_set_variant", take_value_function = "g_value_take_variant", type_signature = "v")]
	public class Variant {
		[CCode (has_type_id = false)]
		public enum Class {
			BOOLEAN, BYTE, INT16, UINT16, INT32, UINT32, INT64,
			UINT64, HANDLE, DOUBLE, STRING, OBJECT_PATH,
			SIGNATURE, VARIANT, MAYBE, ARRAY, TUPLE, DICT_ENTRY
		}

		public unowned VariantType get_type ();
		public unowned string get_type_string ();
		public bool is_of_type (VariantType type);
		public bool is_container ();
		[Version (since = "2.26")]
		public bool is_floating ();
		public Class classify ();
		[Version (since = "2.26")]
		public int compare (Variant other);

		public Variant.boolean (bool value);
		public Variant.byte (uint8 value);
		public Variant.int16 (int16 value);
		public Variant.uint16 (uint16 value);
		public Variant.int32 (int32 value);
		public Variant.uint32 (uint32 value);
		public Variant.int64 (int64 value);
		public Variant.uint64 (uint64 value);
		public Variant.handle (int32 value);
		public Variant.double (double value);
		public Variant.string (string value);
		[Version (since = "2.26")]
		public Variant.bytestring (string value);
		public Variant.object_path (string object_path);
		public static bool is_object_path (string object_path);
		public Variant.signature (string signature);
		public static bool is_signature (string signature);

		public bool get_boolean ();
		public uint8 get_byte ();
		public int16 get_int16 ();
		public uint16 get_uint16 ();
		public int32 get_int32 ();
		public uint32 get_uint32 ();
		public int64 get_int64 ();
		public uint64 get_uint64 ();
		public int32 get_handle ();
		public double get_double ();
		public unowned string get_string (out size_t length = null);
		public string dup_string (out size_t length = null);
		[Version (since = "2.26")]
		public unowned string get_bytestring ();
		[Version (since = "2.26")]
		public string dup_bytestring (out size_t length);

		public Variant.strv (string[] value);
		[CCode (array_length_type = "size_t")]
#if VALA_0_26
		public (unowned string)[] get_strv ();
#else
		public string*[] get_strv ();
#endif
		[CCode (array_length_type = "size_t")]
		public string[] dup_strv ();

		[Version (since = "2.26")]
		public Variant.bytestring_array (string[] value);
		[Version (since = "2.26")]
		[CCode (array_length_type = "size_t")]
#if VALA_0_26
		public (unowned string)[] get_bytestring_array ();
#else
		public string*[] get_bytestring_array ();
#endif
		[Version (since = "2.26")]
		[CCode (array_length_type = "size_t")]
		public string[] dup_bytestring_array ();

		[Version (since = "2.30")]
		public Variant.objv (string[] value);
		[Version (since = "2.30")]
		[CCode (array_length_type = "size_t")]
#if VALA_0_26
		public (unowned string)[] get_objv ();
#else
		public string*[] get_objv ();
#endif
		[Version (since = "2.30")]
		[CCode (array_length_type = "size_t")]
		public string[] dup_objv ();

		public Variant (string format, ...);
		// note: the function changes its behaviour when end_ptr is null, so 'out char *' is wrong
		public Variant.va (string format, char **end_ptr, va_list *app);
		public void get (string format, ...);
		public void get_va (string format, char **end_ptr, va_list *app);

		public Variant.variant (Variant value);
		public Variant.maybe (VariantType? child_type, Variant? child);
		public Variant.array (VariantType? child_type, Variant[] children);
		[Version (since = "2.32")]
		[CCode (simple_generics = true)]
		public static Variant new_fixed_array<T> (VariantType? element_type, [CCode (array_length_type = "gsize")] T[] elements, size_t element_size);
		public Variant.tuple (Variant[] children);
		public Variant.dict_entry (Variant key, Variant value);
		public Variant get_variant ();
		public Variant? get_maybe ();

		public size_t n_children ();
		public Variant get_child_value (size_t index);
		public void get_child (size_t index, string format_string, ...);

		[Version (since = "2.28")]
		public Variant? lookup_value (string key, VariantType? expected_type);
		[Version (since = "2.28")]
		public bool lookup (string key, string format_string, ...);

		public size_t get_size ();
		public void *get_data ();
		public void store (void *data);

		public string print (bool type_annotate);
		public StringBuilder print_string (StringBuilder? builder, bool type_annotate);

		public uint hash ();
		public bool equal (Variant other);

		public Variant byteswap ();
		public Variant get_normal_form ();
		public bool is_normal_form ();
		[CCode (returns_floating_reference = true, simple_generics = true)]
		public static Variant new_from_data<T> (VariantType type, uchar[] data, bool trusted, [CCode (destroy_notify_pos = 3.9)] owned T? owner = null);

		[CCode (cname = "g_variant_iter_new")]
		public VariantIter iterator ();

		public static Variant parse (VariantType? type, string text, char *limit = null, char **endptr = null) throws GLib.VariantParseError;
		public Variant.parsed (string format_string, ...);

		[Version (since = "2.34")]
		public bool check_format_string (string format_string, bool copy_only);

		[Version (since = "2.36")]
		public Variant.from_bytes (VariantType type, Bytes bytes, bool trusted);
		[Version (since = "2.36")]
		public Bytes get_data_as_bytes ();

		[Version (since = "2.38")]
		public Variant.printf (string format_string, ...);
		[Version (since = "2.38")]
		public Variant.take_string (owned string str);

		[Version (since = "2.40")]
		public static void parse_error_print_context (GLib.VariantParseError error, string source_str);
	}

	[Version (since = "2.24")]
	public errordomain VariantParseError {
		FAILED,
		BASIC_TYPE_EXPECTED,
		CANNOT_INFER_TYPE,
		DEFINITE_TYPE_EXPECTED,
		INPUT_NOT_AT_END,
		INVALID_CHARACTER,
		INVALID_FORMAT_STRING,
		INVALID_OBJECT_PATH,
		INVALID_SIGNATURE,
		INVALID_TYPE_STRING,
		NO_COMMON_TYPE,
		NUMBER_OUT_OF_RANGE,
		NUMBER_TOO_BIG,
		TYPE_ERROR,
		UNEXPECTED_TOKEN,
		UNKNOWN_KEYWORD,
		UNTERMINATED_STRING_CONSTANT,
		VALUE_EXPECTED;
		public static GLib.Quark quark ();
	}

	[Compact]
	[Version (since = "2.24")]
	public class VariantIter {
		public VariantIter (Variant value);
		public size_t n_children ();
		public Variant? next_value ();
		public bool next (string format_string, ...);
	}

	[Compact]
	[Version (since = "2.24")]
	[CCode (ref_function = "g_variant_builder_ref", unref_function = "g_variant_builder_unref")]
	public class VariantBuilder {
		public VariantBuilder (VariantType type);
		public void open (VariantType type);
		public void close ();
		public void add_value (Variant value);
		public void add (string format_string, ...);
		[CCode (returns_floating_reference = true)]
		public Variant end ();
	}

	[Version (since = "2.40")]
	[Compact, CCode (ref_function = "g_variant_dict_ref", unref_function = "g_variant_dict_unref")]
	public class VariantDict {
		public VariantDict (GLib.Variant? from_asv = null);
		public bool lookup (string key, string format_string, ...);
		public GLib.Variant lookup_value (string key, GLib.VariantType expected_type);
		public bool contains (string key);
		public void insert (string key, string format_string, ...);
		public void insert_value (string key, GLib.Variant value);
		public bool remove (string key);
		public void clear ();
		[CCode (returns_floating_reference = true)]
		public GLib.Variant end ();
	}

	[CCode (cname = "char", const_cname = "const char", copy_function = "g_strdup", free_function = "g_free", cheader_filename = "stdlib.h,string.h,glib.h", type_id = "G_TYPE_STRING", marshaller_type_name = "STRING", param_spec_function = "g_param_spec_string", get_value_function = "g_value_get_string", set_value_function = "g_value_set_string", take_value_function = "g_value_take_string", type_signature = "o")]
	public class ObjectPath : string {
		[CCode (cname = "g_strdup")]
		public ObjectPath (string path);
	}

	[CCode (cname = "char", const_cname = "const char", copy_function = "g_strdup", free_function = "g_free", cheader_filename = "stdlib.h,string.h,glib.h", type_id = "G_TYPE_STRING", marshaller_type_name = "STRING", param_spec_function = "g_param_spec_string", get_value_function = "g_value_get_string", set_value_function = "g_value_set_string", take_value_function = "g_value_take_string")]
	public class BusName : string {
		[CCode (cname = "g_strdup")]
		public BusName (string bus_name);
	}

	[CCode (cname = "G_LIKELY", cheader_filename = "glib.h")]
	public static bool likely (bool expression);
	[CCode (cname = "G_UNLIKELY", cheader_filename = "glib.h")]
	public static bool unlikely (bool expression);
	[Version (since = "2.20")]
	[CCode (cname = "G_STATIC_ASSERT", cheader_filename = "glib.h")]
	public static void static_assert (bool expression);

	[CCode (simple_generics = true, cname = "g_qsort_with_data")]
	private static void _qsort_with_data<T> (T[] elems, size_t size, [CCode (type = "GCompareDataFunc")] GLib.CompareDataFunc<T> compare_func);

	[CCode (cname = "_vala_g_qsort_with_data")]
	public static void qsort_with_data<T> (T[] elems, size_t size, [CCode (type = "GCompareDataFunc")] GLib.CompareDataFunc<T> compare_func) {
		_qsort_with_data<T*> (elems, size, (a, b) => {
				return compare_func (*a, *b);
			});
	}

	[Version (since = "2.54")]
	public errordomain NumberParserError {
		INVALID,
		OUT_OF_BOUNDS;
		public static GLib.Quark quark ();
	}

	/* Unix-specific functions. All of these have to include glib-unix.h. */
	namespace Unix {
		[Version (since = "2.30")]
		[CCode (cheader_filename = "glib-unix.h", cname = "g_unix_signal_add_full")]
		public static uint signal_add (int signum, owned GLib.SourceFunc handler, [CCode (pos = 0.9)] int priority = Priority.DEFAULT);

		[CCode (cheader_filename = "glib-unix.h", cname = "GSource")]
		public class SignalSource : GLib.Source {
			public SignalSource (int signum);
		}

		[Version (since = "2.30")]
		[CCode (cheader_filename = "glib-unix.h")]
		public static bool open_pipe ([CCode (array_length = false, array_null_terminated = false)] int[] fds, int flags) throws GLib.Error;
		[Version (since = "2.30")]
		[CCode (cheader_filename = "glib-unix.h")]
		public static bool set_fd_nonblocking (int fd, bool nonblock) throws GLib.Error;
	}

	[CCode (cname = "GUnicodeScript", cprefix = "G_UNICODE_SCRIPT_", has_type_id = false)]
	public enum UnicodeScript {
		INVALID_CODE,
		COMMON,
		INHERITED,
		ARABIC,
		ARMENIAN,
		BENGALI,
		BOPOMOFO,
		CHEROKEE,
		COPTIC,
		CYRILLIC,
		DESERET,
		DEVANAGARI,
		ETHIOPIC,
		GEORGIAN,
		GOTHIC,
		GREEK,
		GUJARATI,
		GURMUKHI,
		HAN,
		HANGUL,
		HEBREW,
		HIRAGANA,
		KANNADA,
		KATAKANA,
		KHMER,
		LAO,
		LATIN,
		MALAYALAM,
		MONGOLIAN,
		MYANMAR,
		OGHAM,
		OLD_ITALIC,
		ORIYA,
		RUNIC,
		SINHALA,
		SYRIAC,
		TAMIL,
		TELUGU,
		THAANA,
		THAI,
		TIBETAN,
		CANADIAN_ABORIGINAL,
		YI,
		TAGALOG,
		HANUNOO,
		BUHID,
		TAGBANWA,

		BRAILLE,
		CYPRIOT,
		LIMBU,
		OSMANYA,
		SHAVIAN,
		LINEAR_B,
		TAI_LE,
		UGARITIC,

		NEW_TAI_LUE,
		BUGINESE,
		GLAGOLITIC,
		TIFINAGH,
		SYLOTI_NAGRI,
		OLD_PERSIAN,
		KHAROSHTHI,

		UNKNOWN,
		BALINESE,
		CUNEIFORM,
		PHOENICIAN,
		PHAGS_PA,
		NKO,

		KAYAH_LI,
		LEPCHA,
		REJANG,
		SUNDANESE,
		SAURASHTRA,
		CHAM,
		OL_CHIKI,
		VAI,
		CARIAN,
		LYCIAN,
		LYDIAN,

		/* Unicode-5.2 additions */
		AVESTAN,                /* Avst */
		BAMUM,                  /* Bamu */
		EGYPTIAN_HIEROGLYPHS,   /* Egyp */
		IMPERIAL_ARAMAIC,       /* Armi */
		INSCRIPTIONAL_PAHLAVI,  /* Phli */
		INSCRIPTIONAL_PARTHIAN, /* Prti */
		JAVANESE,               /* Java */
		KAITHI,                 /* Kthi */
		LISU,                   /* Lisu */
		MEETEI_MAYEK,           /* Mtei */
		OLD_SOUTH_ARABIAN,      /* Sarb */
		OLD_TURKIC,             /* Orkh */
		SAMARITAN,              /* Samr */
		TAI_THAM,               /* Lana */
		TAI_VIET,               /* Tavt */

		/* Unicode-6.0 additions */
		BATAK,                  /* Batk */
		BRAHMI,                 /* Brah */
		MANDAIC,                /* Mand */

		/* Unicode-6.1 additions */
		CHAKMA,                 /* Cakm */
		MEROITIC_CURSIVE,       /* Merc */
		MEROITIC_HIEROGLYPHS,   /* Mero */
		MIAO,                   /* Plrd */
		SHARADA,                /* Shrd */
		SORA_SOMPENG,           /* Sora */
		TAKRI,                  /* Takr */

		/* Unicode 7.0 additions */
		BASSA_VAH,              /* Bass */
		CAUCASIAN_ALBANIAN,     /* Aghb */
		DUPLOYAN,               /* Dupl */
		ELBASAN,                /* Elba */
		GRANTHA,                /* Gran */
		KHOJKI,                 /* Khoj */
		KHUDAWADI,              /* Sind */
		LINEAR_A,               /* Lina */
		MAHAJANI,               /* Mahj */
		MANICHAEAN,             /* Manu */
		MENDE_KIKAKUI,          /* Mend */
		MODI,                   /* Modi */
		MRO,                    /* Mroo */
		NABATAEAN,              /* Nbat */
		OLD_NORTH_ARABIAN,      /* Narb */
		OLD_PERMIC,             /* Perm */
		PAHAWH_HMONG,           /* Hmng */
		PALMYRENE,              /* Palm */
		PAU_CIN_HAU,            /* Pauc */
		PSALTER_PAHLAVI,        /* Phlp */
		SIDDHAM,                /* Sidd */
		TIRHUTA,                /* Tirh */
		WARANG_CITI,            /* Wara */

		/* Unicode 8.0 additions */
		AHOM,                   /* Ahom */
		ANATOLIAN_HIEROGLYPHS,  /* Hluw */
		HATRAN,                 /* Hatr */
		MULTANI,                /* Mult */
		OLD_HUNGARIAN,          /* Hung */
		SIGNWRITING,            /* Sgnw */

		/* Unicode 9.0 additions */
		ADLAM,                  /* Adlm */
		BHAIKSUKI,              /* Bhks */
		MARCHEN,                /* Marc */
		NEWA,                   /* Newa */
		OSAGE,                  /* Osge */
		TANGUT,                 /* Tang */

		/* Unicode 10.0 additions */
		MASARAM_GONDI,          /* Gonm */
		NUSHU,                  /* Nshu */
		SOYOMBO,                /* Soyo */
		ZANABAZAR_SQUARE;       /* Zanb */

		[CCode (cname = "g_unicode_script_to_iso15924")]
		public uint32 to_iso15924 ();
		[CCode (cname = "g_unicode_script_from_iso15924")]
		public static GLib.UnicodeScript from_iso15924 (uint32 iso15924);
	}

	[CCode (cname = "GUnicodeType", cprefix = "G_UNICODE_", has_type_id = false)]
	public enum UnicodeType {
		CONTROL,
		FORMAT,
		UNASSIGNED,
		PRIVATE_USE,
		SURROGATE,
		LOWERCASE_LETTER,
		MODIFIER_LETTER,
		OTHER_LETTER,
		TITLECASE_LETTER,
		UPPERCASE_LETTER,
		COMBINING_MARK,
		ENCLOSING_MARK,
		NON_SPACING_MARK,
		DECIMAL_NUMBER,
		LETTER_NUMBER,
		OTHER_NUMBER,
		CONNECT_PUNCTUATION,
		DASH_PUNCTUATION,
		CLOSE_PUNCTUATION,
		FINAL_PUNCTUATION,
		INITIAL_PUNCTUATION,
		OTHER_PUNCTUATION,
		OPEN_PUNCTUATION,
		CURRENCY_SYMBOL,
		MODIFIER_SYMBOL,
		MATH_SYMBOL,
		OTHER_SYMBOL,
		LINE_SEPARATOR,
		PARAGRAPH_SEPARATOR,
		SPACE_SEPARATOR
	}

	[CCode (cname = "GUnicodeBreakType", cprefix = "G_UNICODE_BREAK_", has_type_id = false)]
	public enum UnicodeBreakType {
		MANDATORY,
		CARRIAGE_RETURN,
		LINE_FEED,
		COMBINING_MARK,
		SURROGATE,
		ZERO_WIDTH_SPACE,
		INSEPARABLE,
		NON_BREAKING_GLUE,
		CONTINGENT,
		SPACE,
		AFTER,
		BEFORE,
		BEFORE_AND_AFTER,
		HYPHEN,
		NON_STARTER,
		OPEN_PUNCTUATION,
		CLOSE_PUNCTUATION,
		QUOTATION,
		EXCLAMATION,
		IDEOGRAPHIC,
		NUMERIC,
		INFIX_SEPARATOR,
		SYMBOL,
		ALPHABETIC,
		PREFIX,
		POSTFIX,
		COMPLEX_CONTEXT,
		AMBIGUOUS,
		UNKNOWN,
		NEXT_LINE,
		WORD_JOINER,
		HANGUL_L_JAMO,
		HANGUL_V_JAMO,
		HANGUL_T_JAMO,
		HANGUL_LV_SYLLABLE,
		HANGUL_LVT_SYLLABLE,
		CLOSE_PARANTHESIS,
		CONDITIONAL_JAPANESE_STARTER,
		HEBREW_LETTER,
		REGIONAL_INDICATOR,
		EMOJI_BASE,
		EMOJI_MODIFIER,
		ZERO_WIDTH_JOINER
	}

	[CCode (cname = "GNormalizeMode", cprefix = "G_NORMALIZE_", has_type_id = false)]
	public enum NormalizeMode {
		DEFAULT,
		NFD,
		DEFAULT_COMPOSE,
		NFC,
		ALL,
		NFKD,
		ALL_COMPOSE,
		NFKC
	}
}
