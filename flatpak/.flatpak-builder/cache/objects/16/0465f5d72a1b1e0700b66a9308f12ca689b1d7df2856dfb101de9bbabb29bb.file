[CCode (cprefix = "ccss_", lower_case_cprefix = "ccss_", cheader_filename = "ccss/ccss.h")]
namespace CCss {
	[Compact]
	[CCode (cprefix = "ccss_background_attachment_", cname = "ccss_background_attachment_t")]
	public class BackgroundAttachment: Property {
		[CCode (cprefix = "CCSS_BACKGROUND_", has_type_id = false, cname = "ccss_background_attachment_type_t")]
		public enum Type {
			SCROLL,
			FIXED
		}
		public Type attachment {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_background_image_", cname = "ccss_background_image_t")]
	public class BackgroundImage: Property {
		public string uri {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_background_position_", cname = "ccss_background_position_t")]
	public class BackgroundPosition: Property {
		public Position horizontal_position {
			get;
		}
		public Position vertical_position {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_background_repeat_", cname = "ccss_background_repeat_t")]
	public class BackgroundRepeat: Property {
		[CCode (cprefix = "CCSS_BACKGROUND_", has_type_id = false, cname = "ccss_background_repeat_type_t")]
		public enum Type {
			REPEAT,
			REPEAT_X,
			REPEAT_Y,
			NO_REPEAT
		}
		public Type repeat {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_background_size_", cname = "ccss_background_size_t")]
	public class BackgroundSize: Property {
		public Position height {
			get;
		}
		public Position width {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_background_", cname = "ccss_background_t")]
	public class Background: Property {
		public BackgroundAttachment attachment {
			get;
		}
		public Color color {
			get;
		}
		public BackgroundImage image {
			get;
		}
		public BackgroundPosition position {
			get;
		}
		public BackgroundRepeat repeat {
			get;
		}
		public BackgroundSize size {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_block_", cname = "ccss_block_t")]
	public class Block {
		public void add_property (string property_name, Property property);
	}
	[Compact]
	[CCode (cprefix = "ccss_border_image_", cname = "ccss_border_image_t")]
	public class BorderImage: Property {
		[CCode (cprefix = "CCSS_BORDER_IMAGE_TILING_", has_type_id = false, cname = "ccss_border_image_tiling_t")]
		public enum Tiling {
			REPEAT,
			ROUND,
			STRETCH
		}
		public string uri {
			get;
		}
		public Position top {
			get;
		}
		public Position right {
			get;
		}
		public Position bottom {
			get;
		}
		public Position left {
			get;
		}
		public Tiling top_middle_bottom_horizontal_tiling {
			get;
		}
		public Tiling left_middle_right_vertical_tiling  {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_border_join_", cname = "ccss_border_join_t")]
	public class BorderRadius: Property {
		public double radius {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_border_spacing_", cname = "ccss_border_spacing_t")]
	public class BorderSpacing: Property {
		public double spacing {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_border_style_", cname = "ccss_border_style_t")]
	public class BorderStyle: Property {
		[CCode (cprefix = "CCSS_BORDER_STYLE_", has_type_id = false, cname = "ccss_border_style_type_t")]
		public enum Type {
			HIDDEN,
			DOTTED,
			DASHED,
			SOLID,
			DOUBLE,
			GROOVE,
			RIDGE,
			INSET,
			OUTSET
		}
		public Type style {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_border_width_", cname = "ccss_border_width_t")]
	public class BorderWidth: Property {
		public double width {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_color_", cname = "ccss_color_t", free_function = "ccss_color_destroy")]
	public class Color: Property {
		public double alpha {
			get;
		}
		public double blue {
			get;
		}
		public double green {
			get;
		}
		public double red {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_function_", cname = "ccss_function_t", ref_function = "ccss_function_reference", unref_function = "ccss_function_destroy")]
	public class Function {
		[CCode (cname = "ccss_function_create")]
		public Function (string name, FunctionDelegate function);
	}
	[CCode (cname = "ccss_function_f", has_target = false)]
	public delegate string? FunctionDelegate (GLib.SList<string> args, void* user_data);

	[Compact]
	[CCode (cprefix = "ccss_grammar_", cname = "ccss_grammar_t", ref_function = "ccss_grammar_reference", unref_function = "ccss_grammar_destroy")]
	public class Grammar {
		[CCode (cname = "ccss_grammar_create_generic")]
		public Grammar.generic ();
		[CCode (cname = "ccss_grammar_create_css")]
		public Grammar.css ();

		/*public void add_properties (PropertyClass properties);
		public unowned PropertyClass lookup_property (string name);*/

		public void add_function (Function function);
		public unowned Function lookup_function (string name);

		public Stylesheet create_stylesheet ();
		public Stylesheet create_stylesheet_from_buffer (char[] buffer, void* user_data);
		public Stylesheet create_stylesheet_from_file (string css_file, void* user_data);
	}
	[CCode (cname = "ccss_node_class_t")]
	public struct NodeClass {
		public Node.IsA is_a;
		public Node.GetContainer get_container;
		public Node.GetBaseStyle get_base_style;
		public Node.GetInstance get_instance;
		public Node.GetId get_id;
		public Node.GetType get_type;
		public Node.GetClasses get_classes;
		public Node.GetPseudoClasses get_pseudo_classes;
		public Node.GetAttribute get_attribute;
		public Node.GetStyle get_style;
		public Node.GetViewport get_viewport;
		public Node.Release release;
	}

	[Compact]
	[CCode (cprefix = "ccss_node_", cname = "ccss_node_t", free_function = "ccss_node_destroy")]
	public class Node {
		[CCode (cname = "ccss_node_create")]
		public Node (NodeClass node_class, uint n_methods, void* user_data);
		public void* get_user_data ();

		[CCode (cname = "ccss_node_get_attribute_f", has_target = false)]
		public delegate string? GetAttribute (Node node, string name);
		[CCode (cname = "ccss_node_get_base_style_f", has_target = false)]
		public delegate Node? GetBaseStyle (Node node);
		[CCode (cname = "ccss_node_get_classes_f", array_length = false, array_null_terminated = true, has_target = false)]
		public delegate string[]? GetClasses (Node node);
		[CCode (cname = "ccss_node_get_container_f", has_target = false)]
		public delegate Node? GetContainer (Node node);
		[CCode (cname = "ccss_node_get_id_f", has_target = false)]
		public delegate string? GetId (Node node);
		[CCode (cname = "ccss_node_get_instance_f", has_target = false)]
		public delegate long GetInstance (Node node);
		[CCode (cname = "ccss_node_get_pseudo_classes_f", array_length = false, array_null_terminated = true, has_target = false)]
		public delegate string[]? GetPseudoClasses (Node node);
		[CCode (cname = "ccss_node_get_style_f", has_target = false)]
		public delegate string? GetStyle (Node node, uint descriptor);
		[CCode (cname = "ccss_node_get_type_f", has_target = false)]
		public delegate string? GetType (Node node);
		[CCode (cname = "ccss_node_get_viewport_f", has_target = false)]
		public delegate bool GetViewport (Node node, double x, double y, double width, double height);
		[CCode (cname = "ccss_node_is_a_f", has_target = false)]
		public delegate bool IsA (Node node, string type_name);
		[CCode (cname = "ccss_node_release_f", has_target = false)]
		public delegate void Release (Node node);
	}
	[Compact]
	[CCode (cname = "ccss_padding_t")]
	public class Padding: Property {
		public double padding {
			get;
		}
	}
	[Compact]
	[CCode (cprefix = "ccss_position_", cname = "ccss_position_t")]
	public class Position: Property {
		[CCode (cprefix = "CCSS_POSITION_", has_type_id = false, cname = "ccss_position_type_t")]
		public enum Type {
			LENGTH,
			PERCENTAGE,
			MASK_NUMERIC,
			LEFT,
			TOP,
			RIGHT,
			BOTTOM,
			CENTER,
			MASK_HORIZONTAL,
			MASK_VERTICAL,
			AUTO,
			CONTAIN,
			COVER,
			MASK_AUTO
		}
		public double get_hsize (double extent_x, double extent_y, double width, double height);
		public double get_pos (double extent, double size);
		public double get_size (double extent);
		public double get_vsize (double extent_x, double extent_y, double width, double height);
		public string serialize ();
	}
	[Compact]
	[CCode (cname = "ccss_property_class_t")]
	public class PropertyClass {
		public string name;
		public Property.Convert convert;
		public Property.Create create;
		public Property.Destroy destroy;
		public Property.Factory factory;
		public Property.Inherit inherit;
		public Property.Serialize serialize;
	}

	/*[Compact]
	[CCode (cname = "ccss_property_generic_t")]
	public class PropertyGeneric: Property {
		public weak string name;
		public void* values;
	}*/

	[Compact]
	[CCode (cprefix = "ccss_property_", cname = "ccss_property_t", free_function = "ccss_property_destroy")]
	public class Property {
		[CCode (cprefix = "CCSS_PROPERTY_STATE_", has_type_id = false, cname = "ccss_property_state_t")]
		public enum State {
			INVALID,
			NONE,
			INHERIT,
			SET,
			ERROR_OVERFLOW;

			[CCode (cname = "ccss_property_parse_state")]
			public static State parse (string value);
			[CCode (cname = "ccss_property_state_serialize")]
			public unowned string serialize ();
		}
		[CCode (cprefix = "CCSS_PROPERTY_TYPE_", has_type_id = false, cname = "ccss_property_type_t")]
		public enum Type {
			DOUBLE,
			STRING
		}
		public Type type {
			get;
		}
		public State get_state {
			get;
		}

		[CCode (cname = "ccss_property_create_f")]
		public delegate Property Create (Grammar grammar, void* values);
		[CCode (cname = "ccss_property_convert_f", has_target = false)]
		public delegate bool Convert (Property property, Type target, void* value);
		[CCode (cname = "ccss_property_destroy_f", has_target = false)]
		public delegate void Destroy (Property property);
		[CCode (cname = "ccss_property_factory_f")]
		public delegate bool Factory (Grammar grammar, Block block, string name, void* values);
		[CCode (cname = "ccss_property_inherit_f", has_target = false)]
		public delegate bool Inherit (Style container_style, Style style);
		[CCode (cname = "ccss_property_serialize_f", has_target = false)]
		public delegate string Serialize (Property property);
	}
	[Compact]
	[CCode (cprefix = "ccss_style_", cname = "ccss_style_t", free_function = "ccss_style_destroy")]
	public class Style {
		public void dump ();
		public void @foreach (Iterator func);
		public bool get_double (string property_name, out double value);
		public bool get_property (string property_name, out unowned Property value);
		public bool get_string (string property_name, out unowned string value);
		public Stylesheet stylesheet {
			get;
		}

		[CCode (cname = "ccss_style_iterator_f")]
		public delegate void Iterator (Style style, string property_name);

		public static GLib.HashFunc hash;
	}
	[Compact]
	[CCode (cprefix = "ccss_stylesheet_", cname = "ccss_stylesheet_t", ref_function = "ccss_stylesheet_reference", unref_function = "ccss_stylesheet_destroy")]
	public class Stylesheet {
		[CCode (cprefix = "CCSS_STYLESHEET_", has_type_id = false, cname = "ccss_stylesheet_precedence_t")]
		public enum Precedence {
			USER_AGENT,
			USER,
			AUTHOR
		}
		public uint add_from_buffer (char[] buffer, Precedence precedence, void* user_data);
		public uint add_from_file (string css_file, Precedence precedence, void* user_data);
		public void dump ();
		public void @foreach (Iterator func);
		public Grammar grammar {
			owned get;
		}
		public Style? query (Node node);
		public Style? query_type (string type_name);
		public bool unload (uint descriptor);

		[CCode (cname = "ccss_stylesheet_iterator_f")]
		public delegate void Iterator (Stylesheet stylesheet, string type_name);
	}
}
