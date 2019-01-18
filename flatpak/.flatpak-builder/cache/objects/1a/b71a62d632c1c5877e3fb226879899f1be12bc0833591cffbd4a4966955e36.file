/* raptor.vapi
 *
 * Copyright (C) 2008  Nokia
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

[CCode (cheader_filename = "raptor.h")]
namespace Raptor {
	[CCode (has_type_id = false)]
	public enum IdentifierType {
		RESOURCE,
		ANONYMOUS,
		PREDICATE,
		ORDINAL,
		LITERAL,
		XML_LITERAL
	}

	[Compact]
	[CCode (cname = "raptor_parser", free_function = "raptor_free_parser")]
	public class Parser {
		[CCode (cname = "raptor_new_parser")]
		public Parser (string name);
		[CCode (cname = "raptor_set_statement_handler")]
		public void set_statement_handler ([CCode (delegate_target_pos = 0.9)] StatementHandler handler);
		[CCode (cname = "raptor_parse_file")]
		public void parse_file (Uri? uri, Uri? base_uri);
		[CCode (cname = "raptor_start_parse")]
		public void start_parse (Uri uri);
	}

	[Compact]
	[CCode (cname = "raptor_statement")]
	public class Statement {
		public void* subject;
		public void* predicate;
		public void* object;
		public IdentifierType object_type;
	}

	[CCode (cname = "raptor_statement_handler", instance_pos = 0)]
	public delegate void StatementHandler (Statement statement);

	[Compact]
	[CCode (cname = "raptor_uri", free_function = "raptor_free_uri")]
	public class Uri {
		[CCode (cname = "raptor_new_uri")]
		public Uri (string uri_string);
		public static string filename_to_uri_string (string filename);
		public unowned string as_string ();
	}
}

