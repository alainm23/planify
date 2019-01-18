/* rasqal.vapi
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

[CCode (cheader_filename = "rasqal.h")]
namespace Rasqal {
	public void init ();
	public void finish ();

	[Compact]
	[CCode (cname = "rasqal_graph_pattern")]
	public class GraphPattern {
		[CCode (has_type_id = false)]
		public enum Operator {
			BASIC,
			OPTIONAL,
			UNION,
			GROUP,
			GRAPH
		}

		public Operator get_operator ();
		public unowned Triple get_triple (int idx);
		public void print (GLib.FileStream fh);
	}

	[CCode (cprefix = "RASQAL_EXPR_", has_type_id = false)]
	public enum Op {
		AND,
		OR,
		LITERAL,
		ORDER_COND_ASC,
		ORDER_COND_DESC,
		GROUP_COND_ASC,
		GROUP_COND_DESC,
		COUNT,
		VARSTAR
	}

	[Compact]
	[CCode (cname = "rasqal_expression", free_function = "rasqal_free_expression")]
	public class Expression {
		public Op op;
		public Expression? arg1;
		public Expression? arg2;
		public Expression? arg3;
		public Literal? literal;
	}

	[Compact]
	[CCode (cname = "rasqal_literal", free_function = "rasqal_free_literal")]
	public class Literal {
		[CCode (cprefix = "RASQAL_LITERAL_", has_type_id = false)]
		public enum Type {
			BLANK,
			URI,
			STRING,
			BOOLEAN,
			INTEGER,
			DOUBLE,
			FLOAT,
			DECIMAL,
			DATETIME,
			PATTERN,
			QNAME,
			VARIABLE
		}

		public Type type;

		public unowned string? as_string ();
		public unowned Variable? as_variable ();
	}

	[Compact]
	[CCode (cname = "rasqal_query", free_function = "rasqal_free_query")]
	public class Query {
		[CCode (cname = "rasqal_new_query")]
		public Query (string? name, string? uri);
		public bool get_distinct ();
		public int get_limit ();
		public int get_offset ();
		public unowned Expression? get_group_condition (int idx);
		public unowned Expression? get_order_condition (int idx);
		public unowned GraphPattern get_query_graph_pattern ();
		public unowned Variable? get_variable (int idx);
		public int prepare (string? query_string, Raptor.Uri? base_uri);
	}

	[Compact]
	[CCode (cname = "rasqal_triple", free_function = "rasqal_free_triple")]
	public class Triple {
		public Literal subject;
		public Literal predicate;
		public Literal object;
		public Literal origin;

		public void print (GLib.FileStream fh);
	}

	[Compact]
	[CCode (cname = "rasqal_variable", free_function = "rasqal_free_variable")]
	public class Variable {
		public weak string? name;
		public Expression? expression;
	}
}

