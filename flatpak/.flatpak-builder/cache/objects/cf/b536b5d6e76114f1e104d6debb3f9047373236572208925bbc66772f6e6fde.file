[CCode (cheader_filename = "pixman.h")]
namespace Pixman {
	namespace Version {
		public const int MAJOR;
		public const int MINOR;
		public const int MICRO;
		public const string STRING;
		[CCode (cname = "PIXMAN_VERSION")]
		public const int INT;

		public static int encode (int major, int minor, int micro);
		[CCode (cname = "pixman_version")]
		public static int library_int ();
		[CCode (cname = "pixman_string")]
		public static unowned string library_string ();
	}

	[SimpleType, IntegerType (rank = 6), CCode (cname = "pixman_fixed_16_16_t", has_type_id = false)]
	public struct Fixed1616 : int32 {
	}

	[SimpleType, IntegerType (rank = 6), CCode (cname = "pixman_fixed_t", has_type_id = false)]
	public struct Fixed : Fixed1616 {
		[CCode (cname = "pixman_double_to_fixed")]
		public Fixed.double (double val);
		[CCode (cname = "pixman_int_to_fixed")]
		public Fixed.int (int val);
		public int to_int ();
		public double to_double ();
		public Fixed frac ();
		public Fixed floor ();
		public Fixed ceil ();
		public Fixed fraction ();
		public Fixed mod_2 ();
		public Fixed sample_ceil_y (int bpp);
		public Fixed sample_floor_y (int bpp);
	}

	[CCode (cname = "struct pixman_color", has_type_id = false)]
	public struct Color {
		public uint16 red;
		public uint16 green;
		public uint16 blue;
		public uint16 alpha;
	}

	[CCode (cname = "struct pixman_point_fixed", has_type_id = false)]
	public struct PointFixed {
		public Pixman.Fixed x;
		public Pixman.Fixed y;
	}

	[CCode (cname = "struct pixman_line_fixed", has_type_id = false)]
	public struct LineFixed {
		public Pixman.PointFixed p1;
		public Pixman.PointFixed p2;
	}

	[CCode (cname = "struct pixman_vector", has_type_id = false)]
	public struct Vector {
		public Pixman.Fixed vector[3];
	}

	[CCode (cname = "struct pixman_transform", has_type_id = false)]
	public struct Transform {
		public Pixman.Fixed matrix[9];

		[CCode (cname = "pixman_transform_init_identity")]
		public Transform.identity ();
		public bool point_3d (Pixman.Vector vector);
		public bool point ();
		public bool multiply (Pixman.Transform l, Pixman.Transform r);
		[CCode (cname = "pixman_transform_init_scale")]
		public Transform.init_scale (Pixman.Fixed sx, Pixman.Fixed sy);
		public bool scale (Pixman.Transform reverse, Pixman.Fixed sx, Pixman.Fixed sy);
		[CCode (cname = "pixman_transform_init_rotate")]
		public Transform.init_rotate (Pixman.Fixed cos, Pixman.Fixed sin);
		public bool rotate (Pixman.Transform reverse, Pixman.Fixed c, Pixman.Fixed s);
		[CCode (cname = "pixman_transform_rotate")]
		public Transform.init_translate (Pixman.Fixed tx, Pixman.Fixed ty);
		public bool translate (Pixman.Transform reverse, Pixman.Fixed tx, Pixman.Fixed ty);
		public bool bounds (Pixman.Box16 b);
		public bool is_identity ();
		public bool is_scale ();
		public bool is_int_translate ();
		public bool is_inverse (Pixman.Transform b);
	}

	[CCode (cprefix = "PIXMAN_REGION_", has_type_id = false)]
	public enum RegionOverlap {
		OUT,
		IN,
		PART
	}

	[CCode (cname = "pixman_region16_t", has_type_id = false, cprefix = "pixman_region_", destroy_function = "pixman_region_fini")]
	public struct Region16 {
		Pixman.Box16 extents;

		public Region16 ();
		public Region16.rect (int x, int y, uint width, uint height);
		public Region16.rects (Pixman.Box16[] boxes);
		public Region16.with_extents (Pixman.Box16 extents);

		public void translate (int x, int y);
		public bool copy (out Pixman.Region16 region);
		[CCode (instance_pos = 1.1)]
		public bool intersect (out Pixman.Region16 new_reg, Pixman.Region16 reg2);
		[CCode (instance_pos = 1.1)]
		public bool union (out Pixman.Region16 new_reg, Pixman.Region16 reg2);
		[CCode (instance_pos = 1.1)]
		public bool union_rect (out Pixman.Region16 dest, int x, int y, uint width, uint height);
		[CCode (instance_pos = 1.1)]
		public bool subtract (out Pixman.Region16 reg_d, Pixman.Region16 reg_s);
		[CCode (instance_pos = 1.1)]
		public bool inverse (out Pixman.Region16 new_reg, Pixman.Box16 inv_rect);
		public bool contains_point (int x, int y, Pixman.Box16 box);
		public Pixman.RegionOverlap contains_rectangle (Pixman.Box16 prect);
		public bool not_empty ();
		[CCode (cname = "pixman_region_extents")]
		public unowned Pixman.Box16? get_extents ();
		public int n_rects ();
		public unowned Pixman.Box16[] rectangles ();
		public bool equal (Pixman.Region16 region2);
		public bool selfcheck ();
		public void reset (Pixman.Box16 box);
	}

	[CCode (cname = "pixman_box16_t", has_type_id = false)]
	public struct Box16 {
		public int16 x1;
		public int16 y1;
		public int16 x2;
		public int16 y2;
	}

	[CCode (cname = "pixman_rectangle16_t", has_type_id = false)]
	public struct Rectangle16 {
		public Pixman.Box16 extents;
	}

	[CCode (cname = "pixman_region32_t", has_type_id = false, destroy_function = "pixman_region32_fini")]
	public struct Region32 {
		public Pixman.Box32 extents;

		public Region32 ();
		public Region32.rect (int x, int y, uint width, uint height);
		public Region32.rects (Pixman.Box32[] boxes);
		public Region32.with_extents (Pixman.Box32 extents);

		public void translate (int x, int y);
		public bool copy (out Pixman.Region32 region);
		[CCode (instance_pos = 1.1)]
		public bool intersect (out Pixman.Region32 new_reg, Pixman.Region32 reg2);
		[CCode (instance_pos = 1.1)]
		public bool union (out Pixman.Region32 new_reg, Pixman.Region32 reg2);
		[CCode (instance_pos = 1.1)]
		public bool union_rect (out Pixman.Region32 dest, int x, int y, uint width, uint height);
		[CCode (instance_pos = 1.1)]
		public bool subtract (out Pixman.Region32 reg_d, Pixman.Region32 reg_s);
		[CCode (instance_pos = 1.1)]
		public bool inverse (out Pixman.Region32 new_reg, Pixman.Box32 inv_rect);
		public bool contains_point (int x, int y, Pixman.Box32 box);
		public Pixman.RegionOverlap contains_rectangle (Pixman.Box32 prect);
		public bool not_empty ();
		[CCode (cname = "pixman_region32_extents")]
		public unowned Pixman.Box32? get_extents ();
		public int n_rects ();
		public unowned Pixman.Box32[] rectangles ();
		public bool equal (Pixman.Region32 region2);
		public bool selfcheck ();
		public void reset (Pixman.Box32 box);
	}

	[CCode (cname = "pixman_box32_t", has_type_id = false)]
	public struct Box32 {
		public int32 x1;
		public int32 y1;
		public int32 x2;
		public int32 y2;
	}

	[CCode (cname = "pixman_rectangle32_t", has_type_id = false)]
	public struct Rectangle32 {
		public Pixman.Box32 extents;
	}

	public static bool blt ([CCode (array_length = false, type = "uint32_t*")] uint8[] src_bits, [CCode (array_length = false, type = "uint32_t*")] uint8[] dst_bits, int src_stride, int dst_stride, int src_bpp, int dst_bpp, int src_x, int src_y, int dst_x, int dst_y, int width, int height);
	public static bool fill ([CCode (array_length = false, type = "uint32_t*")] uint8[] bits, int stride, int bpp, int x, int y, int width, int height, uint32 _xor);

	[CCode (cname = "pixman_read_memory_func_t", has_target = false)]
	public delegate int32 ReadMemoryFunc ([CCode (type = "void*")] uint8[] src);
	[CCode (cname = "pixman_write_memory_func_t", has_target = false)]
	public delegate void WriteMemoryFunc ([CCode (type = "void*", array_length = false)] uint8[] dst, uint32 value, int size);

	[CCode (cname = "struct pixman_gradient_stop", has_type_id = false)]
	public struct GradientStop {
		public Pixman.Fixed x;
		public Pixman.Color color;
	}

	[CCode (cname = "struct pixman_indexed", has_type_id = false)]
	public struct Indexed {
		public bool color;
		public uint32 rgba[256];
		public uint8 ent[32768];
	}

	[CCode (cname = "enum pixman_repeat_t", has_type_id = false)]
	public enum Repeat {
		NONE,
		NORMAL,
		PAD,
		REFLECT
	}

	[CCode (cname = "enum pixman_filter_t", has_type_id = false)]
	public enum Filter {
		FAST,
		GOOD,
		BEST,
		NEAREST,
		BILINEAR,
		CONVOLUTION
	}

	[CCode (cname = "enum pixman_op_t", has_type_id = false, cprefix = "PIXMAN_OP_")]
	public enum Operation {
		CLEAR,
		SRC,
		DST,
		OVER,
		OVER_REVERSE,
		IN,
		IN_REVERSE,
		OUT,
		OUT_REVERSE,
		ATOP,
		ATOP_REVERSE,
		XOR,
		ADD,
		SATURATE,

		DISJOINT_CLEAR,
		DISJOINT_SRC,
		DISJOINT_DST,
		DISJOINT_OVER,
		DISJOINT_OVER_REVERSE,
		DISJOINT_IN,
		DISJOINT_IN_REVERSE,
		DISJOINT_OUT,
		DISJOINT_OUT_REVERSE,
		DISJOINT_ATOP,
		DISJOINT_ATOP_REVERSE,
		DISJOINT_XOR,

		CONJOINT_CLEAR,
		CONJOINT_SRC,
		CONJOINT_DST,
		CONJOINT_OVER,
		CONJOINT_OVER_REVERSE,
		CONJOINT_IN,
		CONJOINT_IN_REVERSE,
		CONJOINT_OUT,
		CONJOINT_OUT_REVERSE,
		CONJOINT_ATOP,
		CONJOINT_ATOP_REVERSE,
		CONJOINT_XOR,

		MULTIPLY,
		SCREEN,
		OVERLAY,
		DARKEN,
		LIGHTEN,
		COLOR_DODGE,
		COLOR_BURN,
		HARD_LIGHT,
		SOFT_LIGHT,
		DIFFERENCE,
		EXCLUSION,
		HSL_HUE,
		HSL_SATURATION,
		HSL_COLOR,
		HSL_LUMINOSITY
	}

	[CCode (cname = "int", cprefix = "PIXMAN_TYPE_", has_type_id = false)]
	public enum FormatType {
		OTHER,
		A,
		ARGB,
		ABGR,
		COLOR,
		GRAY,
		YUV2,
		YV12,
		BGRA;

		[CCode (cname = "PIXMAN_FORMAT_COLOR")]
		public bool is_color ();
	}

	[CCode (cname = "pixman_format_code_t", has_type_id = false, cprefix = "PIXMAN_")]
	public enum Format {
		[CCode (cname = "PIXMAN_a8r8g8b8")]
		A8R8G8B8,
		[CCode (cname = "PIXMAN_x8r8g8b8")]
		X8R8G8B8,
		[CCode (cname = "PIXMAN_a8b8g8r8")]
		A8B8G8R8,
		[CCode (cname = "PIXMAN_x8b8g8r8")]
		X8B8G8R8,
		[CCode (cname = "PIXMAN_b8g8r8a8")]
		B8G8R8A8,
		[CCode (cname = "PIXMAN_b8g8r8x8")]
		B8G8R8X8,
		[CCode (cname = "PIXMAN_x14r6g6b6")]
		X14R6G6B6,
		[CCode (cname = "PIXMAN_x2r10g10b10")]
		X2R10G10B10,
		[CCode (cname = "PIXMAN_a2r10g10b10")]
		A2R10G10B10,
		[CCode (cname = "PIXMAN_x2b10g10r10")]
		X2B10G10R10,
		[CCode (cname = "PIXMAN_a2b10g10r10")]
		A2B10G10R10,
		[CCode (cname = "PIXMAN_r8g8b8")]
		R8G8B8,
		[CCode (cname = "PIXMAN_b8g8r8")]
		B8G8R8,
		[CCode (cname = "PIXMAN_r5g6b5")]
		R5G6B5,
		[CCode (cname = "PIXMAN_b5g6r5")]
		B5G6R5,
		[CCode (cname = "PIXMAN_a1r5g5b5")]
		A1R5G5B5,
		[CCode (cname = "PIXMAN_x1r5g5b5")]
		X1R5G5B5,
		[CCode (cname = "PIXMAN_a1b5g5r5")]
		A1B5G5R5,
		[CCode (cname = "PIXMAN_x1b5g5r5")]
		X1B5G5R5,
		[CCode (cname = "PIXMAN_a4r4g4b4")]
		A4R4G4B4,
		[CCode (cname = "PIXMAN_x4r4g4b4")]
		X4R4G4B4,
		[CCode (cname = "PIXMAN_a4b4g4r4")]
		A4B4G4R4,
		[CCode (cname = "PIXMAN_x4b4g4r4")]
		X4B4G4R4,
		/* 8bpp formats */
		[CCode (cname = "PIXMAN_a8")]
		A8,
		[CCode (cname = "PIXMAN_r3g3b2")]
		R3G3B2,
		[CCode (cname = "PIXMAN_b2g3r3")]
		B2G3R3,
		[CCode (cname = "PIXMAN_a2r2g2b2")]
		A2R2G2B2,
		[CCode (cname = "PIXMAN_a2b2g2r2")]
		A2B2G2R2,
		[CCode (cname = "PIXMAN_c8")]
		C8,
		[CCode (cname = "PIXMAN_g8")]
		G8,
		[CCode (cname = "PIXMAN_x4a4")]
		X4A4,
		[CCode (cname = "PIXMAN_x4c4")]
		X4C4,
		[CCode (cname = "PIXMAN_x4g4")]
		X4G4,
		/* 4bpp formats */
		[CCode (cname = "PIXMAN_a4")]
		A4,
		[CCode (cname = "PIXMAN_r1g2b1")]
		R1G2B1,
		[CCode (cname = "PIXMAN_b1g2r1")]
		B1G2R1,
		[CCode (cname = "PIXMAN_a1r1g1b1")]
		A1R1G1B1,
		[CCode (cname = "PIXMAN_a1b1g1r1")]
		A1B1G1R1,
		[CCode (cname = "PIXMAN_c4")]
		C4,
		[CCode (cname = "PIXMAN_g4")]
		G4,
		/* 1bpp formats */
		[CCode (cname = "PIXMAN_a1")]
		A1,
		[CCode (cname = "PIXMAN_g1")]
		G1,
		/* YUV formats */
		[CCode (cname = "PIXMAN_yuy2")]
		YUY2,
		[CCode (cname = "PIXMAN_yv12")]
		YV12;

		[CCode (cname = "PIXMAN_FORMAT")]
		public static Pixman.Format create (int bpp, Pixman.FormatType type, int a, int r, int g, int b);
		[CCode (cname = "pixman_format_supported_destination")]
		public bool supported_destination ();
		[CCode (cname = "pixman_format_supported_source")]
		public bool supported_source ();
	}

	[CCode (cname = "pixman_image_t", cprefix = "pixman_image_", ref_function = "pixman_image_ref", unref_function = "pixman_image_unref", has_type_id = false)]
	public class Image {
		[CCode (cname = "pixman_image_create_solid_fill")]
		public Image.solid_fill (Pixman.Color color);
		[CCode (cname = "pixman_image_create_linear_gradient")]
		public Image.linear_gradient (Pixman.PointFixed p1, Pixman.PointFixed p2, Pixman.GradientStop[] stops);
		[CCode (cname = "pixman_image_create_radial_gradient")]
		public Image.radial_gradient (Pixman.PointFixed inner, Pixman.PointFixed outer, Pixman.Fixed inner_radius, Pixman.Fixed outer_radius, Pixman.GradientStop[] stops);
		[CCode (cname = "pixman_image_create_conical_gradient")]
		public Image.conical_gradient (Pixman.PointFixed center, Pixman.Fixed angle, Pixman.GradientStop[] stops);
		[CCode (cname = "pixman_image_create_bits")]
		public Image.bits (Pixman.Format format, int width, int height, [CCode (type = "uint32_t*", array_length = false)] uint8[]? bits, int rowstride_bytes);

		public bool set_clip_region (Pixman.Region16 clip_region);
		public Pixman.Region16 clip_region { set; }
		public bool set_clip_region32 (Pixman.Region32 clip_region32);
		public Pixman.Region32 clip_region32 { set; }
		public void set_has_client_clip (bool client_clip);
		public bool has_client_clip { set; }
		public bool set_transform (Pixman.Transform transform);
		public Pixman.Transform transform { set; }
		public void set_repeat (Pixman.Repeat repeat);
		public Pixman.Repeat repeat { set; }
		public bool set_filter (Pixman.Filter filter, Pixman.Fixed[]? filter_params);
		public void set_source_clipping (bool source_clipping);
		public bool source_clipping { set; }
		public void set_alpha_map (Pixman.Image alpha_map, int16 x, int16 y);
		public void set_component_alpha (bool component_alpha);
		public bool component_alpha { set; }
		public bool set_accessors (Pixman.ReadMemoryFunc read_func, Pixman.WriteMemoryFunc write_func);
		public bool set_indexed (Pixman.Indexed indexed);
		public Pixman.Indexed indexed { set; }
		[CCode (array_length = false)]
		public unowned uint32[] get_data ();
		public int get_width ();
		public int width { get; }
		public int get_height ();
		public int height { get; }
		public int get_stride ();
		public int stride { get; }
		public int get_depth ();
		public int depth { get; }
		[CCode (instance_pos = 1.1)]
		public bool fill_rectangles (Pixman.Operation op, Pixman.Color color, [CCode (array_length_pos = 2.1)] Pixman.Rectangle16[] rects);

		public static bool compute_composite_region (Pixman.Region16 region, Pixman.Image src_image, Pixman.Image? mask_image, Pixman.Image dst_image, int src_x, int src_y, int mask_x, int mask_y, int dest_x, int dest_y, int width, int height);
		public static void composite (Pixman.Operation op, Pixman.Image src, Pixman.Image? mask, Pixman.Image dest, int16 src_x, int16 src_y, int16 mask_x, int16 mask_y, int16 dest_x, int16 dest_y, uint16 width, uint16 height);

		[CCode (cname = "pixman_rasterize_edges")]
		public void rasterize_edges (Pixman.Edge l, Pixman.Edge r, Pixman.Fixed t, Pixman.Fixed b);
		[CCode (cname = "pixman_add_traps")]
		public void add_traps (int16 x_off, int16 y_off, [CCode (array_length_pos = 2.9)] Pixman.Trap[] traps);
		[CCode (cname = "pixman_add_trapezoids")]
		public void add_trapezoids (int16 x_off, int y_off, [CCode (array_length_pos = 2.9)] Pixman.Trap[] traps);
		[CCode (cname = "pixman_rasterize_trapezoid")]
		public void rasterize_trapezoid (Pixman.Trapezoid trap, int x_off, int y_off);
	}

	[CCode (cname = "struct pixman_edge", has_type_id = false)]
	public struct Edge {
		public Pixman.Fixed x;
		public Pixman.Fixed e;
		public Pixman.Fixed stepx;
		public Pixman.Fixed signdx;
		public Pixman.Fixed dy;
		public Pixman.Fixed dx;

		public Pixman.Fixed stepx_small;
		public Pixman.Fixed stepx_big;
		public Pixman.Fixed dx_small;
		public Pixman.Fixed dx_big;

		public void step (int n);
		public Edge (int bpp, Pixman.Fixed y_start, Pixman.Fixed x_top, Pixman.Fixed y_top, Pixman.Fixed x_bot, Pixman.Fixed y_bot);
		[CCode (cname = "pixman_line_fixed_edge_init")]
		public Edge.line_fixed (int bpp, Pixman.Fixed y, Pixman.LineFixed line, int x_off, int y_off);
	}

	[CCode (cname = "struct pixman_trapezoid", has_type_id = false)]
	public struct Trapezoid {
		public Pixman.Fixed top;
		public Pixman.Fixed bottom;
		public Pixman.LineFixed left;
		public Pixman.LineFixed right;

		public bool valid ();
	}

	[CCode (cname = "struct pixman_span_fix", has_type_id = false)]
	public struct SpanFix {
		public Pixman.Fixed l;
		public Pixman.Fixed r;
		public Pixman.Fixed y;
	}

	[CCode (cname = "struct pixman_trap", has_type_id = false)]
	public struct Trap {
		public Pixman.SpanFix top;
		public Pixman.SpanFix bot;
	}
}
