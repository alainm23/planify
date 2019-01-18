/* cairo.vala
 *
 * Copyright (C) 2006-2009  Jürg Billeter
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

[CCode (cheader_filename = "cairo.h", gir_namespace = "cairo", gir_version = "1.0")]
namespace Cairo {
	[CCode (lower_case_cprefix = "CAIRO_MIME_TYPE_")]
	namespace MimeType {
		public const string JBIG2;
		public const string JBIG2_GLOBAL;
		public const string JBIG2_GLOBAL_ID;
		public const string JP2;
		public const string JPEG;
		public const string PNG;
		public const string UNIQUE_ID;
		public const string URI;
	}
	[CCode (cname = "cairo_t", cprefix = "cairo_", ref_function = "cairo_reference", unref_function = "cairo_destroy")]
	[Compact]
	public class Context {
		[CCode (cname = "cairo_create")]
		public Context (Cairo.Surface target);
		public void append_path (Cairo.Path path);
		public void arc (double xc, double yc, double radius, double angle1, double angle2);
		public void arc_negative (double xc, double yc, double radius, double angle1, double angle2);
		public void clip ();
		public void clip_extents (out double x1, out double y1, out double x2, out double y2);
		public void clip_preserve ();
		public void close_path ();
		public Cairo.RectangleList copy_clip_rectangle_list ();
		public void copy_page ();
		public Cairo.Path copy_path ();
		public Cairo.Path copy_path_flat ();
		public void curve_to (double x1, double y1, double x2, double y2, double x3, double y3);
		public void device_to_user (ref double x, ref double y);
		public void device_to_user_distance (ref double dx, ref double dy);
		public void fill ();
		public void fill_extents (out double x1, out double y1, out double x2, out double y2);
		public void fill_preserve ();
		public void font_extents (out Cairo.FontExtents extents);
		public Cairo.Antialias get_antialias ();
		public void get_current_point (out double x, out double y);
		public void get_dash (double[]? dashes, double[]? offset);
		public int get_dash_count ();
		public Cairo.FillRule get_fill_rule ();
		public unowned Cairo.FontFace get_font_face ();
		public void get_font_matrix (out Cairo.Matrix matrix);
		public void get_font_options (out Cairo.FontOptions options);
		public unowned Cairo.Surface get_group_target ();
		public Cairo.LineCap get_line_cap ();
		public Cairo.LineJoin get_line_join ();
		public double get_line_width ();
		public Cairo.Matrix get_matrix ();
		public double get_miter_limit ();
		public Cairo.Operator get_operator ();
		public uint get_reference_count ();
		public unowned Cairo.ScaledFont get_scaled_font ();
		public unowned Cairo.Pattern get_source ();
		public unowned Cairo.Surface get_target ();
		public double get_tolerance ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		public void glyph_extents (Cairo.Glyph[] glyphs, out Cairo.TextExtents extents);
		public void glyph_path (Cairo.Glyph[] glyphs);
		public bool has_current_point ();
		public void identity_matrix ();
		public bool in_clip (double x, double y);
		public bool in_fill (double x, double y);
		public bool in_stroke (double x, double y);
		public void line_to (double x, double y);
		public void mask (Cairo.Pattern pattern);
		public void mask_surface (Cairo.Surface surface, double surface_x, double surface_y);
		public void move_to (double x, double y);
		public void new_path ();
		public void new_sub_path ();
		public void paint ();
		public void paint_with_alpha (double alpha);
		public void path_extents (out double x1, out double y1, out double x2, out double y2);
		public Cairo.Pattern pop_group ();
		public void pop_group_to_source ();
		public void push_group ();
		public void push_group_with_content (Cairo.Content content);
		public void rectangle (double x, double y, double width, double height);
		public void rel_curve_to (double dx1, double dy1, double dx2, double dy2, double dx3, double dy3);
		public void rel_line_to (double dx, double dy);
		public void rel_move_to (double dx, double dy);
		public void reset_clip ();
		public void restore ();
		public void rotate (double angle);
		public void save ();
		public void scale (double sx, double sy);
		public void select_font_face (string family, Cairo.FontSlant slant, Cairo.FontWeight weight);
		public void set_antialias (Cairo.Antialias antialias);
		public void set_dash (double[]? dashes, double offset);
		public void set_fill_rule (Cairo.FillRule fill_rule);
		public void set_font_face (Cairo.FontFace font_face);
		public void set_font_matrix (Cairo.Matrix matrix);
		public void set_font_options (Cairo.FontOptions options);
		public void set_font_size (double size);
		public void set_line_cap (Cairo.LineCap line_cap);
		public void set_line_join (Cairo.LineJoin line_join);
		public void set_line_width (double width);
		public void set_matrix (Cairo.Matrix matrix);
		public void set_miter_limit (double limit);
		public void set_operator (Cairo.Operator op);
		public void set_scaled_font (Cairo.ScaledFont font);
		public void set_source (Cairo.Pattern source);
		public void set_source_rgb (double red, double green, double blue);
		public void set_source_rgba (double red, double green, double blue, double alpha);
		public void set_source_surface (Cairo.Surface surface, double x, double y);
		public void set_tolerance (double tolerance);
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public void show_glyphs (Cairo.Glyph[] glyphs);
		public void show_page ();
		public void show_text (string utf8);
		public Cairo.Status show_text_glyphs (string utf8, int utf8_len, Cairo.Glyph[] glyphs, Cairo.TextCluster[] clusters, out Cairo.TextClusterFlags cluster_flags);
		public Cairo.Status status ();
		public void stroke ();
		public void stroke_extents (out double x1, out double y1, out double x2, out double y2);
		public void stroke_preserve ();
		public void text_extents (string utf8, out Cairo.TextExtents extents);
		public void text_path (string utf8);
		public void transform (Cairo.Matrix matrix);
		public void translate (double tx, double ty);
		public void user_to_device (ref double x, ref double y);
		public void user_to_device_distance (ref double dx, ref double dy);
	}
	[CCode (cname = "cairo_device_t", ref_function = "cairo_device_reference", unref_function = "cairo_device_destroy")]
	[Compact]
	public class Device {
		public Cairo.Status acquire ();
		public void finish ();
		public void flush ();
		public uint get_reference_count ();
		public Cairo.DeviceType get_type ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		public void release ();
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public Cairo.Status status ();
	}
	[CCode (cname = "cairo_device_t", ref_function = "cairo_device_reference", unref_function = "cairo_device_destroy")]
	[Compact]
	public class DeviceObserver {
		protected DeviceObserver ();
		public double elapsed ();
		public double fill_elapsed ();
		public double glyphs_elapsed ();
		public double mask_elapsed ();
		public double paint_elapsed ();
		public Cairo.Status print (Cairo.WriteFunc write_func);
		public double stroke_elapsed ();
	}
	[CCode (cname = "cairo_font_face_t", ref_function = "cairo_font_face_reference", unref_function = "cairo_font_face_destroy")]
	[Compact]
	public class FontFace {
		public uint get_reference_count ();
		public Cairo.FontType get_type ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public Cairo.Status status ();
	}
	[CCode (cname = "cairo_font_options_t", copy_function = "cairo_font_options_copy", free_function = "cairo_font_options_destroy")]
	[Compact]
	public class FontOptions {
		[CCode (cname = "cairo_font_options_create")]
		public FontOptions ();
		public bool equal (Cairo.FontOptions other);
		public Cairo.Antialias get_antialias ();
		public Cairo.HintMetrics get_hint_metrics ();
		public Cairo.HintStyle get_hint_style ();
		public Cairo.SubpixelOrder get_subpixel_order ();
		public ulong hash ();
		public void merge (Cairo.FontOptions other);
		public void set_antialias (Cairo.Antialias antialias);
		public void set_hint_metrics (Cairo.HintMetrics hint_metrics);
		public void set_hint_style (Cairo.HintStyle hint_style);
		public void set_subpixel_order (Cairo.SubpixelOrder subpixel_order);
		public Cairo.Status status ();
	}
	[CCode (cname = "cairo_surface_t")]
	[Compact]
	public class ImageSurface : Cairo.Surface {
		[CCode (cname = "cairo_image_surface_create")]
		public ImageSurface (Cairo.Format format, int width, int height);
		[CCode (cname = "cairo_image_surface_create_for_data")]
		public ImageSurface.for_data ([CCode (array_length = false)] uchar[] data, Cairo.Format format, int width, int height, int stride);
		[CCode (cname = "cairo_image_surface_create_from_png")]
		public ImageSurface.from_png (string filename);
		[CCode (cname = "cairo_image_surface_create_from_png_stream")]
		public ImageSurface.from_png_stream (Cairo.ReadFunc read_func);
		[CCode (array_length = false)]
		public unowned uchar[] get_data ();
		public Cairo.Format get_format ();
		public int get_height ();
		public int get_stride ();
		public int get_width ();
	}
	[CCode (cname = "cairo_pattern_t", ref_function = "cairo_pattern_reference", unref_function = "cairo_pattern_destroy")]
	[Compact]
	public class MeshPattern : Cairo.Pattern {
		[CCode (cname = "cairo_pattern_create_mesh")]
		public MeshPattern ();
		public void begin_patch ();
		public void curve_to (double x1, double y1, double x2, double y2, double x3, double y3);
		public void end_patch ();
		public Cairo.Status get_control_point (uint patch_num, uint point_num, out double x, out double y);
		public Cairo.Status get_corner_color_rgba (uint patch_num, uint corner_num, out double red, out double green, out double blue, out double alpha);
		public Cairo.Status get_patch_count (out uint count);
		public Cairo.Path get_path (uint patch_num);
		public void line_to (double x, double y);
		public void move_to (double x, double y);
		public void set_control_point (uint point_num, double x, double y);
		public void set_corner_color_rgb (uint corner_num, double red, double green, double blue);
		public void set_corner_color_rgba (uint corner_num, double red, double green, double blue, double alpha);
	}
	[CCode (cname = "cairo_path_t", free_function = "cairo_path_destroy")]
	[Compact]
	public class Path {
		[CCode (array_length = false)]
		public Cairo.PathData[] data;
		public int num_data;
		public Cairo.Status status;
	}
	[CCode (cname = "cairo_pattern_t", ref_function = "cairo_pattern_reference", unref_function = "cairo_pattern_destroy")]
	[Compact]
	public class Pattern {
		public void add_color_stop_rgb (double offset, double red, double green, double blue);
		public void add_color_stop_rgba (double offset, double red, double green, double blue, double alpha);
		[CCode (cname = "cairo_pattern_create_for_surface")]
		public Pattern.for_surface (Cairo.Surface surface);
		public Cairo.Status get_color_stop_count (out int count);
		public Cairo.Status get_color_stop_rgba (int index, out double offset, out double red, out double green, out double blue, out double alpha);
		public Cairo.Extend get_extend ();
		public Cairo.Filter get_filter ();
		public Cairo.Status get_linear_points (out double x0, out double y0, out double x1, out double y1);
		public void get_matrix (out Cairo.Matrix matrix);
		public Cairo.Status get_surface (out unowned Cairo.Surface surface);
		public Cairo.PatternType get_type ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		[CCode (cname = "cairo_pattern_create_linear")]
		public Pattern.linear (double x0, double y0, double x1, double y1);
		[CCode (cname = "cairo_pattern_create_radial")]
		public Pattern.radial (double cx0, double cy0, double radius0, double cx1, double cy1, double radius1);
		[CCode (cname = "cairo_pattern_create_rgb")]
		public Pattern.rgb (double red, double green, double blue);
		[CCode (cname = "cairo_pattern_create_rgba")]
		public Pattern.rgba (double red, double green, double blue, double alpha);
		public void set_extend (Cairo.Extend extend);
		public void set_filter (Cairo.Filter filter);
		public void set_matrix (Cairo.Matrix matrix);
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public Cairo.Status status ();
	}
	[CCode (cheader_filename = "cairo-pdf.h", cname = "cairo_surface_t")]
	[Compact]
	public class PdfSurface : Cairo.Surface {
		[CCode (cname = "cairo_pdf_surface_create")]
		public PdfSurface (string? filename, double width_in_points, double height_in_points);
		[CCode (cname = "cairo_pdf_surface_create_for_stream")]
		public PdfSurface.for_stream (Cairo.WriteFunc write_func, double width_in_points, double height_in_points);
		public void restrict_to_version (Cairo.PdfVersion version);
		public void set_size (double width_in_points, double height_in_points);
	}
	[CCode (cheader_filename = "cairo-ps.h", cname = "cairo_surface_t")]
	[Compact]
	public class PsSurface : Cairo.Surface {
		[CCode (cname = "cairo_ps_surface_create")]
		public PsSurface (string filename, double width_in_points, double height_in_points);
		public void dsc_begin_page_setup ();
		public void dsc_begin_setup ();
		public void dsc_comment (string comment);
		[CCode (cname = "cairo_ps_surface_create_for_stream")]
		public PsSurface.for_stream (Cairo.WriteFunc write_func, double width_in_points, double height_in_points);
		public bool get_eps ();
		public static void get_levels (out unowned Cairo.PsLevel[] levels);
		public void restrict_to_level (Cairo.PsLevel level);
		public void set_eps (bool eps);
		public void set_size (double width_in_points, double height_in_points);
	}
	[CCode (cname = "cairo_pattern_t", ref_function = "cairo_pattern_reference", unref_function = "cairo_pattern_destroy")]
	[Compact]
	public class RasterSourcePattern : Cairo.Pattern {
		[CCode (cname = "cairo_pattern_create_raster_source")]
		public RasterSourcePattern ();
		public void get_acquire (out Cairo.RasterSourceAcquireFunc acquire, out Cairo.RasterSourceReleaseFunc release);
		public void* get_callback_data ();
		public Cairo.RasterSourceCopyFunc get_copy ();
		public Cairo.RasterSourceFinishFunc get_finish ();
		public Cairo.RasterSourceSnapshotFunc get_snapshot ();
		public void set_acquire (Cairo.RasterSourceAcquireFunc acquire, Cairo.RasterSourceReleaseFunc release);
		public void set_callback_data (void* data);
		public void set_copy (Cairo.RasterSourceCopyFunc copy);
		public void set_finish (Cairo.RasterSourceFinishFunc finish);
		public void set_snapshot (Cairo.RasterSourceSnapshotFunc snapshot);
	}
	[CCode (cname = "cairo_surface_t")]
	[Compact]
	public class RecordingSurface : Cairo.Surface {
		[CCode (cname = "cairo_recording_surface_create")]
		public RecordingSurface (Cairo.Content content, Cairo.Rectangle? extents = null);
		public bool get_extents (out Cairo.Rectangle extents);
		public void ink_extents (out double x0, out double y0, out double width, out double height);
	}
	[CCode (cname = "cairo_rectangle_list_t", free_function = "cairo_rectangle_list_destroy")]
	[Compact]
	public class RectangleList {
		[CCode (array_length_cname = "num_rectangles")]
		public Cairo.Rectangle[] rectangles;
		public Cairo.Status status;
	}
	[CCode (cname = "cairo_region_t", ref_function = "cairo_region_reference", unref_function = "cairo_region_destroy")]
	[Compact]
	public class Region {
		[CCode (cname = "cairo_region_create")]
		public Region ();
		public bool contains_point (int x, int y);
		public Cairo.RegionOverlap contains_rectangle (Cairo.RectangleInt rectangle);
		public Cairo.Region copy ();
		public bool equal (Cairo.Region other);
		public Cairo.RectangleInt get_extents ();
		public Cairo.RectangleInt get_rectangle (int nth);
		public Cairo.Status intersect (Cairo.Region other);
		public Cairo.Status intersect_rectangle (Cairo.RectangleInt rectangle);
		public bool is_empty ();
		public int num_rectangles ();
		[CCode (cname = "cairo_region_create_rectangle")]
		public Region.rectangle (Cairo.RectangleInt rectangle);
		[CCode (cname = "cairo_region_create_rectangles")]
		public Region.rectangles (Cairo.RectangleInt[] rects);
		public Cairo.Status status ();
		public Cairo.Status subtract (Cairo.Region other);
		public Cairo.Status subtract_rectangle (Cairo.RectangleInt rectangle);
		public void translate (int dx, int dy);
		public Cairo.Status union (Cairo.Region other);
		public Cairo.Status union_rectangle (Cairo.RectangleInt rectangle);
		public Cairo.Status xor (Cairo.Region other);
		public Cairo.Status xor_rectangle (Cairo.RectangleInt rectangle);
	}
	[CCode (cname = "cairo_scaled_font_t", ref_function = "cairo_scaled_font_reference", unref_function = "cairo_scaled_font_destroy")]
	[Compact]
	public class ScaledFont {
		[CCode (cname = "cairo_scaled_font_create")]
		public ScaledFont (Cairo.FontFace font_face, Cairo.Matrix font_matrix, Cairo.Matrix ctm, Cairo.FontOptions options);
		public void extents (out Cairo.FontExtents extents);
		public void get_ctm (out Cairo.Matrix ctm);
		public unowned Cairo.FontFace get_font_face ();
		public void get_font_matrix (out Cairo.Matrix font_matrix);
		public void get_font_options (out Cairo.FontOptions options);
		public uint get_reference_count ();
		public void get_scale_matrix (out Cairo.Matrix scale_matrix);
		public Cairo.FontType get_type ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		public void glyph_extents (Cairo.Glyph[] glyphs, out Cairo.TextExtents extents);
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public Cairo.Status status ();
		public void text_extents (string utf8, out Cairo.TextExtents extents);
		public Cairo.Status text_to_glyphs (double x, double y, string utf8, int utf8_len, out Cairo.Glyph[] glyphs, out Cairo.TextCluster[] clusters, out Cairo.TextClusterFlags cluster_flags);
		[CCode (cname = "cairo_win32_scaled_font_get_device_to_logical")]
		public Cairo.Matrix win32_get_device_to_logical ();
		[CCode (cname = "cairo_win32_scaled_font_get_logical_to_device")]
		public Cairo.Matrix win32_get_logical_to_device ();
	}
	[CCode (cname = "cairo_device_t", ref_function = "cairo_device_reference", unref_function = "cairo_device_destroy")]
	[Compact]
	public class Script : Cairo.Device {
		[CCode (cname = "cairo_script_create")]
		public Script (string filename);
		[CCode (cname = "cairo_script_create_for_stream")]
		public Script.for_stream (Cairo.WriteFunc write_func);
		[CCode (cname = "cairo_script_from_recording_surface")]
		public Script.from_recording_surface ([CCode (type = "cairo_surface_t")] Cairo.RecordingSurface recording_surface);
		public Cairo.ScriptMode get_mode ();
		public void set_mode (Cairo.ScriptMode mode);
		public void write_comment (string comment, int len = -1);
	}
	[CCode (cheader_filename = "cairo-svg.h", cname = "cairo_surface_t")]
	[Compact]
	public class ScriptSurface : Cairo.Surface {
		[CCode (cname = "cairo_script_surface_create")]
		public ScriptSurface (Cairo.Script script, Cairo.Content content, double width, double height);
		[CCode (cname = "cairo_script_surface_create_for_target")]
		public ScriptSurface.for_target (Cairo.Script script, Cairo.Surface target);
	}
	[CCode (cname = "cairo_surface_t", ref_function = "cairo_surface_reference", unref_function = "cairo_surface_destroy")]
	[Compact]
	public class Surface {
		public void copy_page ();
		public void finish ();
		public void flush ();
		[CCode (cname = "cairo_surface_create_for_rectangle")]
		public Surface.for_rectangle (Cairo.Surface target, double x, double y, double width, double height);
		public Cairo.Content get_content ();
		public Cairo.Device get_device ();
		public void get_device_offset (out double x_offset, out double y_offset);
		public void get_device_scale (out double x_scale, out double y_scale);
		public void get_fallback_resolution (out double x_pixels_per_inch, out double y_pixels_per_inch);
		public void get_font_options (out Cairo.FontOptions options);
		public uint get_reference_count ();
		public Cairo.SurfaceType get_type ();
		[CCode (simple_generics = true)]
		public unowned G? get_user_data<G> (Cairo.UserDataKey? key);
		public bool has_show_text_glyphs ();
		public Cairo.Surface map_to_image (Cairo.RectangleInt extents);
		public void mark_dirty ();
		public void mark_dirty_rectangle (int x, int y, int width, int height);
		public void set_device_offset (double x_offset, double y_offset);
		public void set_device_scale (double x_scale, double y_scale);
		public void set_fallback_resolution (double x_pixels_per_inch, double y_pixels_per_inch);
		[CCode (simple_generics = true)]
		public Cairo.Status set_user_data<G> (Cairo.UserDataKey? key, owned G? data);
		public void show_page ();
		[CCode (cname = "cairo_surface_create_similar")]
		public Surface.similar (Cairo.Surface other, Cairo.Content content, int width, int height);
		[CCode (cname = "cairo_surface_create_similar_image")]
		public Surface.similar_image (Cairo.Surface other, Cairo.Format format, int width, int height);
		public Cairo.Status status ();
		public bool supports_mime_type (string mime_type);
		public void unmap_image (Cairo.Surface image);
		[CCode (cname = "cairo_win32_surface_get_image")]
		public Cairo.Surface? win32_get_image ();
		public Cairo.Status write_to_png (string filename);
		public Cairo.Status write_to_png_stream (Cairo.WriteFunc write_func);
	}
	[CCode (cname = "cairo_surface_t", ref_function = "cairo_surface_reference", unref_function = "cairo_surface_destroy")]
	[Compact]
	public class SurfaceObserver {
		[CCode (cname = "cairo_surface_create_observer")]
		public SurfaceObserver (Cairo.Surface target, Cairo.SurfaceObserverMode mode);
		public Cairo.Status add_fill_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_finish_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_flush_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_glyphs_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_mask_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_paint_callback (Cairo.SurfaceObserverCallback func);
		public Cairo.Status add_stroke_callback (Cairo.SurfaceObserverCallback func);
		public double elapsed ();
		public Cairo.Status print (Cairo.WriteFunc write_func);
	}
	[CCode (cheader_filename = "cairo-svg.h", cname = "cairo_surface_t")]
	[Compact]
	public class SvgSurface : Cairo.Surface {
		[CCode (cname = "cairo_svg_surface_create")]
		public SvgSurface (string filename, double width_in_points, double height_in_points);
		[CCode (cname = "cairo_svg_surface_create_for_stream")]
		public SvgSurface.for_stream (Cairo.WriteFunc write_func, double width_in_points, double height_in_points);
		public void restrict_to_version (Cairo.SvgVersion version);
	}
	[CCode (cname = "cairo_font_face_t", ref_function = "cairo_font_face_reference", unref_function = "cairo_font_face_destroy")]
	[Compact]
	public class ToyFontFace : Cairo.FontFace {
		[CCode (cname = "cairo_toy_font_face_create")]
		public ToyFontFace (string family, Cairo.FontSlant slant, Cairo.FontWeight weight);
		public unowned string get_family ();
		public Cairo.FontSlant get_slant ();
		public Cairo.FontWeight get_weight ();
	}
	[CCode (cname = "cairo_font_face_t", ref_function = "cairo_font_face_reference", unref_function = "cairo_font_face_destroy")]
	[Compact]
	public class UserFontFace : Cairo.FontFace {
		[CCode (cname = "cairo_user_font_face_create")]
		public UserFontFace ();
		public Cairo.UserScaledFontInitFunc get_init_func ();
		public Cairo.UserScaledFontRenderGlyphFunc get_render_glyph_func ();
		public Cairo.UserScaledFontTextToGlyphsFunc get_text_to_glyphs_func ();
		public Cairo.UserScaledFontUnicodeToGlyphFunc get_unicode_to_glyph_func ();
		public void set_init_func (Cairo.UserScaledFontInitFunc init_func);
		public void set_render_glyph_func (Cairo.UserScaledFontRenderGlyphFunc render_glyph_func);
		public void set_text_to_glyphs_func (Cairo.UserScaledFontTextToGlyphsFunc text_to_glyphs_func);
		public void set_unicode_to_glyph_func (Cairo.UserScaledFontUnicodeToGlyphFunc unicode_to_glyph_func);
	}
	[CCode (cname = "cairo_scaled_font_t", ref_function = "cairo_scaled_font_reference", unref_function = "cairo_scaled_font_destroy")]
	[Compact]
	public class UserScaledFont {
	}
	[CCode (cheader_filename = "cairo-xlib.h", cname = "cairo_surface_t")]
	[Compact]
	public class XlibSurface : Cairo.Surface {
		[CCode (cname = "cairo_xlib_surface_create")]
		public XlibSurface (void* dpy, int drawable, void* visual, int width, int height);
		[CCode (cname = "cairo_xlib_surface_create_for_bitmap")]
		public XlibSurface.for_bitmap (void* dpy, int bitmap, void* screen, int width, int height);
		public int get_depth ();
		public void* get_display ();
		public int get_drawable ();
		public int get_height ();
		public void* get_screen ();
		public void* get_visual ();
		public int get_width ();
		public void set_drawable (int drawable, int width, int height);
		public void set_size (int width, int height);
	}
	[CCode (cname = "cairo_font_extents_t", has_type_id = false)]
	public struct FontExtents {
		public double ascent;
		public double descent;
		public double height;
		public double max_x_advance;
		public double max_y_advance;
	}
	[CCode (cname = "cairo_glyph_t", has_type_id = false)]
	public struct Glyph {
		public ulong index;
		public double x;
		public double y;
	}
	[CCode (cname = "cairo_matrix_t", has_type_id = false)]
	public struct Matrix {
		public double xx;
		public double yx;
		public double xy;
		public double yy;
		public double x0;
		public double y0;
		[CCode (cname = "cairo_matrix_init")]
		public Matrix (double xx, double yx, double xy, double yy, double x0, double y0);
		[CCode (cname = "cairo_matrix_init_identity")]
		public Matrix.identity ();
		public Cairo.Status invert ();
		public void multiply (Cairo.Matrix a, Cairo.Matrix b);
		public void rotate (double radians);
		public void scale (double sx, double sy);
		public void transform_distance (ref double dx, ref double dy);
		public void transform_point (ref double x, ref double y);
		public void translate (double tx, double ty);
	}
	[CCode (cname = "cairo_path_data_t", has_type_id = false)]
	public struct PathData {
		public Cairo.PathDataHeader header;
		public Cairo.PathDataPoint point;
	}
	[CCode (cname = "struct { cairo_path_data_type_t type; int length; }", has_type_id = false)]
	public struct PathDataHeader {
		public Cairo.PathDataType type;
		public int length;
	}
	[CCode (cname = "struct { double x, y; }", has_type_id = false)]
	public struct PathDataPoint {
		public double x;
		public double y;
	}
	[CCode (cname = "cairo_rectangle_t", has_type_id = false)]
	public struct Rectangle {
		public double x;
		public double y;
		public double width;
		public double height;
	}
	[CCode (cname = "cairo_rectangle_int_t", has_type_id = false)]
	public struct RectangleInt {
		public int x;
		public int y;
		public int width;
		public int height;
	}
	[CCode (cname = "cairo_text_cluster_t", has_type_id = false)]
	public struct TextCluster {
		public int num_bytes;
		public int num_glyphs;
	}
	[CCode (cname = "cairo_text_extents_t", has_type_id = false)]
	public struct TextExtents {
		public double x_bearing;
		public double y_bearing;
		public double width;
		public double height;
		public double x_advance;
		public double y_advance;
	}
	[CCode (cname = "cairo_user_data_key_t", has_copy_function = false, has_destroy_function = false, has_type_id = false, lvalue_access = false)]
	public struct UserDataKey {
	}
	[CCode (cname = "cairo_antialias_t", has_type_id = false)]
	public enum Antialias {
		DEFAULT,
		NONE,
		GRAY,
		SUBPIXEL,
		FAST,
		GOOD,
		BEST
	}
	[CCode (cname = "cairo_content_t", has_type_id = false)]
	public enum Content {
		COLOR,
		ALPHA,
		COLOR_ALPHA
	}
	[CCode (cname = "cairo_device_type_t", has_type_id = false)]
	public enum DeviceType {
		DRM,
		GL,
		SCRIPT,
		XCB,
		XLIB,
		XML,
		COGL,
		WIN32
	}
	[CCode (cname = "cairo_extend_t", has_type_id = false)]
	public enum Extend {
		NONE,
		REPEAT,
		REFLECT,
		PAD
	}
	[CCode (cname = "cairo_fill_rule_t", has_type_id = false)]
	public enum FillRule {
		WINDING,
		EVEN_ODD
	}
	[CCode (cname = "cairo_filter_t", has_type_id = false)]
	public enum Filter {
		FAST,
		GOOD,
		BEST,
		NEAREST,
		BILINEAR,
		GAUSSIAN
	}
	[CCode (cname = "cairo_font_slant_t", has_type_id = false)]
	public enum FontSlant {
		NORMAL,
		ITALIC,
		OBLIQUE
	}
	[CCode (cname = "cairo_font_type_t", has_type_id = false)]
	public enum FontType {
		TOY,
		FT,
		WIN32,
		QUARTZ,
		USER
	}
	[CCode (cname = "cairo_font_weight_t", has_type_id = false)]
	public enum FontWeight {
		NORMAL,
		BOLD
	}
	[CCode (cname = "cairo_format_t", has_type_id = false)]
	public enum Format {
		ARGB32,
		RGB24,
		A8,
		A1,
		RGB16_565,
		RGB30;
		public int stride_for_width (int width);
	}
	[CCode (cname = "cairo_hint_metrics_t", has_type_id = false)]
	public enum HintMetrics {
		DEFAULT,
		OFF,
		ON
	}
	[CCode (cname = "cairo_hint_style_t", has_type_id = false)]
	public enum HintStyle {
		DEFAULT,
		NONE,
		SLIGHT,
		MEDIUM,
		FULL
	}
	[CCode (cname = "cairo_line_cap_t", has_type_id = false)]
	public enum LineCap {
		BUTT,
		ROUND,
		SQUARE
	}
	[CCode (cname = "cairo_line_join_t", has_type_id = false)]
	public enum LineJoin {
		MITER,
		ROUND,
		BEVEL
	}
	[CCode (cname = "cairo_operator_t", has_type_id = false)]
	public enum Operator {
		CLEAR,
		SOURCE,
		OVER,
		IN,
		OUT,
		ATOP,
		DEST,
		DEST_OVER,
		DEST_IN,
		DEST_OUT,
		DEST_ATOP,
		XOR,
		ADD,
		SATURATE,
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
	[CCode (cname = "cairo_path_data_type_t", cprefix = "CAIRO_PATH_", has_type_id = false)]
	public enum PathDataType {
		MOVE_TO,
		LINE_TO,
		CURVE_TO,
		CLOSE_PATH
	}
	[CCode (cname = "cairo_pattern_type_t", has_type_id = false)]
	public enum PatternType {
		SOLID,
		SURFACE,
		LINEAR,
		RADIAL,
		MESH,
		RASTER_SOURCE
	}
	[CCode (cname = "cairo_pdf_version_t", cprefix = "CAIRO_PDF_", has_type_id = false)]
	public enum PdfVersion {
		VERSION_1_4,
		VERSION_1_5;
		[CCode (cname = "cairo_pdf_version_to_string")]
		public unowned string to_string ();
		[CCode (cname = "cairo_pdf_get_versions")]
		public static void get_versions (out unowned Cairo.PdfVersion[] versions);
	}
	[CCode (cname = "cairo_ps_level_t", cprefix = "CAIRO_PS_", has_type_id = false)]
	public enum PsLevel {
		LEVEL_2,
		LEVEL_3;
		[CCode (cname = "cairo_ps_level_to_string")]
		public unowned string to_string ();
		[CCode (cname = "cairo_ps_get_levels")]
		public static void get_levels (out unowned Cairo.PsLevel[] levels);
	}
	[CCode (cname = "cairo_region_overlap_t", has_type_id = false)]
	public enum RegionOverlap {
		IN,
		OUT,
		PART
	}
	[CCode (cname = "cairo_script_mode_t", has_type_id = false)]
	public enum ScriptMode {
		ASCII,
		BINARY
	}
	[CCode (cname = "cairo_status_t", has_type_id = false)]
	public enum Status {
		SUCCESS,
		NO_MEMORY,
		INVALID_RESTORE,
		INVALID_POP_GROUP,
		NO_CURRENT_POINT,
		INVALID_MATRIX,
		INVALID_STATUS,
		NULL_POINTER,
		INVALID_STRING,
		INVALID_PATH_DATA,
		READ_ERROR,
		WRITE_ERROR,
		SURFACE_FINISHED,
		SURFACE_TYPE_MISMATCH,
		PATTERN_TYPE_MISMATCH,
		INVALID_CONTENT,
		INVALID_FORMAT,
		INVALID_VISUAL,
		FILE_NOT_FOUND,
		INVALID_DASH,
		INVALID_DSC_COMMENT,
		INVALID_INDEX,
		CLIP_NOT_REPRESENTABLE,
		TEMP_FILE_ERROR,
		INVALID_STRIDE,
		FONT_TYPE_MISMATCH,
		USER_FONT_IMMUTABLE,
		USER_FONT_ERROR,
		NEGATIVE_COUNT,
		INVALID_CLUSTERS,
		INVALID_SLANT,
		INVALID_WEIGHT,
		INVALID_SIZE,
		USER_FONT_NOT_IMPLEMENTED,
		DEVICE_TYPE_MISMATCH,
		DEVICE_ERROR,
		INVALID_MESH_CONSTRUCTION,
		DEVICE_FINISHED,
		JBIG2_GLOBAL_MISSING,
		PNG_ERROR,
		FREETYPE_ERROR,
		WIN32_GDI_ERROR;
		[CCode (cname = "cairo_status_to_string")]
		public unowned string to_string ();
	}
	[CCode (cname = "cairo_subpixel_order_t", has_type_id = false)]
	public enum SubpixelOrder {
		DEFAULT,
		RGB,
		BGR,
		VRGB,
		VBGR
	}
	[CCode (cname = "cairo_surface_observer_mode_t", has_type_id = false)]
	public enum SurfaceObserverMode {
		NORMAL,
		RECORD_OPERATIONS
	}
	[CCode (cname = "cairo_surface_type_t", has_type_id = false)]
	public enum SurfaceType {
		IMAGE,
		PDF,
		PS,
		XLIB,
		XCB,
		GLITZ,
		QUARTZ,
		WIN32,
		BEOS,
		DIRECTFB,
		SVG,
		OS2,
		WIN32_PRINTING,
		QUARTZ_IMAGE,
		SCRIPT,
		QT,
		RECORDING,
		VG,
		GL,
		DRM,
		TEE,
		XML,
		SKIA,
		SUBSURFACE,
		COGL
	}
	[CCode (cname = "cairo_svg_version_t", cprefix = "CAIRO_SVG_", has_type_id = false)]
	public enum SvgVersion {
		VERSION_1_1,
		VERSION_1_2;
		[CCode (cname = "cairo_svg_version_to_string")]
		public unowned string to_string ();
		[CCode (cname = "cairo_svg_get_versions")]
		public static void get_versions (out unowned Cairo.SvgVersion[] versions);
	}
	[CCode (cname = "cairo_text_cluster_flags_t", cprefix = "CAIRO_TEXT_CLUSTER_FLAG_", has_type_id = false)]
	public enum TextClusterFlags {
		BACKWARD
	}
	[CCode (cname = "cairo_raster_source_acquire_func_t", has_target = false)]
	public delegate Cairo.Surface RasterSourceAcquireFunc (Cairo.Pattern pattern, void* callback_data, Cairo.Surface target, Cairo.RectangleInt? extents);
	[CCode (cname = "cairo_raster_source_copy_func_t", has_target = false)]
	public delegate Cairo.Status RasterSourceCopyFunc (Cairo.Pattern pattern, void* callback_data, Cairo.Pattern other_pattern);
	[CCode (cname = "cairo_raster_source_finish_func_t", has_target = false)]
	public delegate void RasterSourceFinishFunc (Cairo.Pattern pattern, void* callback_data);
	[CCode (cname = "cairo_raster_source_release_func_t", has_target = false)]
	public delegate void RasterSourceReleaseFunc (Cairo.Pattern pattern, void* callback_data, Cairo.Surface surface);
	[CCode (cname = "cairo_raster_source_snapshot_func_t", has_target = false)]
	public delegate Cairo.Status RasterSourceSnapshotFunc (Cairo.Pattern pattern, void* callback_data);
	[CCode (cname = "cairo_read_func_t", instance_pos = 0)]
	public delegate Cairo.Status ReadFunc (uchar[] data);
	[CCode (cname = "cairo_surface_observer_callback_t", instance_pos = 2.9)]
	public delegate void SurfaceObserverCallback (Cairo.SurfaceObserver observer, Cairo.Surface target);
	[CCode (cname = "cairo_user_scaled_font_init_func_t", has_target = false)]
	public delegate Cairo.Status UserScaledFontInitFunc (Cairo.UserScaledFont scaled_font, Cairo.Context cr, Cairo.FontExtents extents);
	[CCode (cname = "cairo_user_scaled_font_render_glyph_func_t", has_target = false)]
	public delegate Cairo.Status UserScaledFontRenderGlyphFunc (Cairo.UserScaledFont scaled_font, ulong glyph, Cairo.Context cr, out Cairo.TextExtents extents);
	[CCode (cname = "cairo_user_font_face_get_text_to_glyphs_func", has_target = false)]
	public delegate Cairo.Status UserScaledFontTextToGlyphsFunc (Cairo.UserScaledFont scaled_font, string utf8, int utf8_len, out Cairo.Glyph[] glyphs, out Cairo.TextCluster[] clusters, out Cairo.TextClusterFlags cluster_flags);
	[CCode (cname = "cairo_user_scaled_font_unicode_to_glyph_func_t", has_target = false)]
	public delegate Cairo.Status UserScaledFontUnicodeToGlyphFunc (Cairo.UserScaledFont scaled_font, ulong unicode, out ulong glyph_index);
	[CCode (cname = "cairo_write_func_t", instance_pos = 0)]
	public delegate Cairo.Status WriteFunc (uchar[] data);
	public static int version ();
	public static unowned string version_string ();
}
