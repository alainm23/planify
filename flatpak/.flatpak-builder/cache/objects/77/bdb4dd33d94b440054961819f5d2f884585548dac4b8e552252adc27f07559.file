/* gmodule-2.0.vala
 *
 * Copyright (C) 2006-2008  Jürg Billeter
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

[CCode (cprefix = "G", lower_case_cprefix = "g_", cheader_filename = "gmodule.h", gir_namespace = "GModule", gir_version = "2.0")]
namespace GLib {
	/* Dynamic Loading of Modules */

	[Compact]
	[CCode (free_function = "g_module_close", cheader_filename = "gmodule.h")]
	public class Module {
		public const string SUFFIX;
		public static bool supported ();
		public static string build_path (string? directory, string module_name);
		public static Module? open (string? file_name, ModuleFlags flags);
		public bool symbol (string symbol_name, out void* symbol);
		public unowned string name ();
		public void make_resident ();
		public static unowned string error ();
	}

	[CCode (cprefix = "G_MODULE_")]
	public enum ModuleFlags {
		BIND_LAZY,
		BIND_LOCAL,
		BIND_MASK
	}
}

