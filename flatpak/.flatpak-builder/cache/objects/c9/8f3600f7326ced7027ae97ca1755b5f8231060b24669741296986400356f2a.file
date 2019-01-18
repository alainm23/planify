/*
 * libgvc.vapi
 *
 * Copyright (C) 2009  Martin Olsson
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
 *      Martin Olsson <martin@minimum.se>
 */

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "graphviz/gvc.h")]
namespace Gvc {

	[CCode (cname = "aginitlib", cheader_filename="gvc.h")]
	public void initlib ( size_t graphinfo, size_t nodeinfo, size_t  edgeinfo);

	[CCode (cname = "aginit")]
#if WITH_CGRAPH
	public void init (Graph g, int kind, string rec_name, bool move_to_front);
#else
	public void init ();
#endif

#if WITH_CGRAPH
	[SimpleType]
	[CCode (cname = "Agdesc_t")]
	public struct Desc {
	}

	public Desc Agdirected; // Desc.DIRECTED | Desc.MAINGRAPH;
	public Desc Agstrictdirected; //  Desc.DIRECTED | Desc.STRICT | Desc.MAINGRAPH;
	public Desc Agundirected; // Desc.MAINGRAPH;
	public Desc Agstrictundirected; // Desc.STRICT | Desc.MAINGRAPH;
#else
	[CCode (cprefix = "", has_type_id = false)]
	public enum GraphKind {
		AGRAPH,
		AGRAPHSTRICT,
		AGDIGRAPH,
		AGDIGRAPHSTRICT,
		AGMETAGRAPH,
	}
#endif

	[CCode (cname = "agerrlevel_t", cheader_filename = "gvc.h", cprefix = "", has_type_id = false)]
	public enum ErrorLevel {
		AGWARN,
		AGERR,
		AGMAX,
		AGPREV
	}

	[Compact]
	[CCode (cname = "GVC_t", free_function = "gvFreeContext")]
	public class Context {
		[CCode (cname = "gvContext")]
		public Context ();

		[CCode (cname = "gvParseArgs")]
		public int parse_args ( [CCode (array_length_pos = 0.9)] string[] argv );

		[CCode (cname = "gvLayout")]
		public int layout (Graph graph, [CCode (type = "char*")] string layout_engine);

		[CCode (cname = "gvFreeLayout")]
		public int free_layout (Graph graph);

		[CCode (cname = "gvRender")]
		public int render (Graph graph, [CCode (type = "char*")] string file_type, GLib.FileStream? file);

		[CCode (cname = "gvRenderFilename")]
		public int render_filename (Graph graph, [CCode (type = "char*")] string file_type, [CCode (type = "char*")] string filename);

		[CCode (cname = "gvLayoutJobs")]
		public int layout_jobs (Graph graph);

		[CCode (cname = "gvRenderJobs")]
		public int render_jobs (Graph graph);

		[CCode (cname = "gvRenderData")]
		public int render_data (Graph graph, [CCode (type = "char*")] string file_type, [CCode (type = "char**")] out uint8[] output_data);
	}

	[Compact]
	[CCode (cname = "Agnode_t", ref_function = "", unref_function = "", free_function = "")]
	public class Node {
		[CCode (cname = "name")]
		public string name;

		[CCode (cname = "agget")]
		public unowned string? get ([CCode (type = "char*")] string attribute_name);

		[CCode (cname = "agset")]
		public void set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value);

		[CCode (cname = "agsafeset")]
		public void safe_set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value, [CCode (type = "char*")] string? default_value);
	}

	[Compact]
	[CCode (cname = "Agedge_t", ref_function = "", unref_function = "", free_function = "")]
	public class Edge {
		[CCode (cname = "agget")]
		public unowned string? get ([CCode (type = "char*")] string attribute_name);

		[CCode (cname = "agset")]
		public int set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value);

		[CCode (cname = "agsafeset")]
		public int safe_set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value, [CCode (type = "char*")] string? default_value);
	}

	[Compact]
	[CCode (cname = "Agraph_t", free_function = "agclose")]
	public class Graph {
		[CCode (cname = "agopen")]
#if WITH_CGRAPH
		public Graph ([CCode (type = "char*")] string graph_name, Desc desc, int disc = 0);
#else
		public Graph ([CCode (type = "char*")] string graph_name, GraphKind kind);
#endif

		[CCode (cname = "agread")]
		public static Graph read (GLib.FileStream file);

		[CCode (cname = "agmemread")]
		public static Graph read_string (string str);

		[CCode (cname = "agnode")]
#if WITH_CGRAPH
		public Node create_node ([CCode (type = "char*")] string node_name, int createflag = 1);
#else
		public Node create_node ([CCode (type = "char*")] string node_name);
#endif

		[CCode (cname = "agedge")]
#if WITH_CGRAPH
		public Edge create_edge (Node from, Node to, string? name = null, int createflag = 1);
#else
		public Edge create_edge (Node from, Node to);
#endif

		[CCode (cname = "agsubg")]
		public unowned Graph create_subgraph ([CCode (type = "char*")] string? name);

		[CCode (cname = "agfindsubg")]
		public Graph find_subgraph ([CCode (type = "char*")] string name);

		[CCode (cname = "agidsubg")]
		public Graph create_subgraph_id (ulong id);

		[CCode (cname = "agfstsubg")]
		public Graph get_first_subgraph ();

		[CCode (cname = "agnxtsubg")]
		public Graph get_next_subgraph ();

		[CCode (cname = "agparent")]
		public Graph get_parent_graph ();

		[CCode (cname = "agdelsubg")]
		public int delete_subgraph (Graph subgraph);

		[CCode (cname = "agfindnode")]
		public Node? find_node ([CCode (type = "char*")] string node_name);

		[CCode (cname = "agfstnode")]
		public Node? get_first_node ();

		[CCode (cname = "agnxtnode")]
		public Node? get_next_node (Node node);

		[CCode (cname = "agget")]
		public unowned string? get ([CCode (type = "char*")] string attribute_name);

		[CCode (cname = "agset")]
		public int set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value);

		[CCode (cname = "agsafeset")]
		public int safe_set ([CCode (type = "char*")] string attribute_name, [CCode (type = "char*")] string attribute_value, [CCode (type = "char*")] string? default_value);

		[CCode (cname = "AG_IS_DIRECTED")]
		public bool is_directed ();

		[CCode (cname = "AG_IS_STRICT")]
		public bool is_strict ();

	}

	[CCode (cname = "char", copy_function = "agdupstr_html", free_function = "agstrfree")]
	public class HtmlString : string {
		[CCode (cname = "agstrdup_html")]
		public HtmlString (string markup);
	}

	[CCode(cprefix = "ag")]
	namespace Error {
		[CCode (cname = "agerrno")]
		public static ErrorLevel errno;

		[CCode (cname = "agerr")]
		[PrintfFormat]
		public static int error (ErrorLevel level, string fmt, ...);

		[CCode (cname = "agerrors")]
		public static int errors ();

		[CCode (cname = "agseterr")]
		public static void set_error (ErrorLevel err);

		[CCode (cname = "aglasterr")]
		public static string? last_error ();

		[CCode (cname = "agerrorf")]
		[PrintfFormat]
		public static void errorf (string format, ...);

		[CCode (cname = "agwarningf")]
		[PrintfFormat]
		void warningf (string fmt, ...);
	}

}
