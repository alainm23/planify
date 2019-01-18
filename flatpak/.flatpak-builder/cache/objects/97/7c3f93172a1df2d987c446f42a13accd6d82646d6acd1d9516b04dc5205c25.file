/* xcb.vapi
 *
 * Copyright (C) 2009  Jürg Billeter
 * Copyright (C) 2013  Sergio Costas
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
 * Authors:
 * 	Jürg Billeter <j@bitron.ch>
 *  Sergio Costas <raster@rastersoft.com>
 */

[Version (deprecated_since = "vala-0.26", replacement = "bindings distributed with vala-extra-vapis")]
[CCode (lower_case_cprefix = "xcb_", cheader_filename = "xcb/xcb.h,xcb/xproto.h")]
namespace Xcb {
	[Compact]
	[CCode (cname = "xcb_connection_t", cprefix = "xcb_", ref_function = "", unref_function = "xcb_disconnect")]
	public class Connection {
		[CCode (cname = "xcb_connect")]
		public Connection (string? display = null, out int screen = null);
		[CCode (cname = "xcb_connection_has_error")]
		public int has_error ();

		public void flush ();
		public uint32 generate_id ();
		public Setup get_setup ();
		public GenericEvent wait_for_event ();
		public GenericEvent poll_for_event ();
		public int get_file_descriptor ();
		public Xcb.GenericError? request_check (Xcb.VoidCookie cookie);

		public VoidCookie create_window (uint8 depth, Window wid, Window parent, int16 x, int16 y, uint16 width, uint16 height, uint16 border_width, uint16 _class, VisualID visual, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);
		public VoidCookie create_window_checked (uint8 depth, Window wid, Window parent, int16 x, int16 y, uint16 width, uint16 height, uint16 border_width, uint16 _class, VisualID visual, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);

		public VoidCookie destroy_window_checked (Window window);
		public VoidCookie destroy_window (Window window);

		public VoidCookie destroy_subwindows_checked (Window window);
		public VoidCookie destroy_subwindows (Window window);

		public VoidCookie change_save_set_checked (SetMode mode, Window window);
		public VoidCookie change_save_set (SetMode mode, Window window);

		public VoidCookie map_window (Window wid);
		public VoidCookie map_window_checked (Window wid);

		public VoidCookie map_subwindows_checked (Window window);
		public VoidCookie map_subwindows (Window window);

		public VoidCookie unmap_window (Window wid);
		public VoidCookie unmap_window_checked (Window wid);

		public VoidCookie unmap_subwindows_checked (Window window);
		public VoidCookie unmap_subwindows (Window window);

		public VoidCookie circulate_window_checked (Circulate direction, Window window);
		public VoidCookie circulate_window (Circulate direction, Window window);

		public GetWindowAttributesCookie get_window_attributes (Window wid);
		public GetWindowAttributesCookie get_window_attributes_unchecked (Window wid);
		public GetWindowAttributesReply? get_window_attributes_reply (GetWindowAttributesCookie cookie, out GenericError? e = null);

		public VoidCookie change_window_attributes (Window wid, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);
		public VoidCookie change_window_attributes_checked (Window wid, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);

		public QueryTreeCookie query_tree (Window wid);
		public QueryTreeCookie query_tree_unchecked (Window wid);
		public QueryTreeReply? query_tree_reply (QueryTreeCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_intern_atom")]
		private InternAtomCookie vala_intern_atom (bool only_if_exists, uint16 len, string name);
		[CCode (cname = "vala_xcb_intern_atom")]
		public InternAtomCookie intern_atom (bool only_if_exists, string name) {
			return this.vala_intern_atom (only_if_exists, (uint16) name.length, name);
		}
		[CCode (cname = "xcb_intern_atom_unchecked")]
		private InternAtomCookie vala_intern_atom_unchecked (bool only_if_exists, uint16 len, string name);
		[CCode (cname = "vala_xcb_intern_atom_unchecked")]
		public InternAtomCookie intern_atom_unchecked (bool only_if_exists, string name) {
			return this.vala_intern_atom (only_if_exists, (uint16) name.length, name);
		}
		public InternAtomReply? intern_atom_reply (InternAtomCookie cookie, out GenericError? e = null);

		public GetAtomNameCookie get_atom_name (AtomT atom);
		public GetAtomNameCookie get_atom_name_unchecked (AtomT atom);
		public GetAtomNameReply? get_atom_name_reply (GetAtomNameCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_change_property")]
		private VoidCookie vala_change_property (PropMode mode, Window window, AtomT property, AtomT type, uint8 format, uint32 len, void *data);
		[CCode (cname = "vala_xcb_change_property")]
		public VoidCookie change_property_uint8 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint8 *data) {
			return this.vala_change_property (mode, window, property, type, 8, len, (void *)data);
		}
		public VoidCookie change_property_uint16 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint16 *data) {
			return this.vala_change_property (mode, window, property, type, 16, len, (void *)data);
		}
		public VoidCookie change_property_uint32 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint32 *data) {
			return this.vala_change_property (mode, window, property, type, 32, len, (void *)data);
		}
		public VoidCookie change_property_atom (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, AtomT *data) {
			return this.vala_change_property (mode, window, property, type, 32, len, (void *)data);
		}
		public VoidCookie change_property_string (PropMode mode, Window window, AtomT property, AtomT type, string data) {
			return this.vala_change_property (mode, window, property, type, 8, data.length, (void *)data.data);
		}

		[CCode (cname = "xcb_change_property_checked")]
		private VoidCookie vala_change_property_checked (PropMode mode, Window window, AtomT property, AtomT type, uint8 format, uint32 len, void *data);
		[CCode (cname = "vala_xcb_change_property_checked")]
		public VoidCookie change_property_checked_uint8 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint8 *data) {
			return this.vala_change_property (mode, window, property, type, 8, len, (void *)data);
		}
		public VoidCookie change_property_checked_uint16 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint16 *data) {
			return this.vala_change_property (mode, window, property, type, 16, len, (void *)data);
		}
		public VoidCookie change_property_checked_uint32 (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, uint32 *data) {
			return this.vala_change_property (mode, window, property, type, 32, len, (void *)data);
		}
		public VoidCookie change_property_checked_atom (PropMode mode, Window window, AtomT property, AtomT type, uint32 len, AtomT *data) {
			return this.vala_change_property (mode, window, property, type, 32, len, (void *)data);
		}
		public VoidCookie change_property_checked_string (PropMode mode, Window window, AtomT property, AtomT type, string data) {
			return this.vala_change_property (mode, window, property, type, 8, data.length, (void *)data.data);
		}

		public VoidCookie delete_property_checked (Window window, AtomT property);
		public VoidCookie delete_property (Window window, AtomT property);

		public GetPropertyCookie get_property (bool _delete, Window window, AtomT property, AtomT type, uint32 long_offset, uint32 long_length);
		public GetPropertyCookie get_property_unchecked (bool _delete, Window window, AtomT property, AtomT type, uint32 long_offset, uint32 long_length);
		public GetPropertyReply? get_property_reply (GetPropertyCookie cookie, out GenericError? e = null);

		public ListPropertiesCookie list_properties (Window window);
		public ListPropertiesCookie list_properties_unchecked (Window window);
		public ListPropertiesReply? list_properties_reply (ListPropertiesCookie cookie, out GenericError? e = null);

		public VoidCookie configure_window (Window window, uint16 value_mask, uint32 *value_list);
		public VoidCookie configure_window_checked (Window window, uint16 value_mask, uint32 *value_list);
		
		public VoidCookie reparent_window (Window window, Window parent, uint16 x, uint16 y);
		public VoidCookie reparent_window_checked (Window window, Window parent, uint16 x, uint16 y);

		public GetGeometryCookie get_geometry (Drawable drawable);
		public GetGeometryCookie get_geometry_unchecked (Drawable drawable);
		public GetGeometryReply? get_geometry_reply (GetGeometryCookie cookie, out GenericError ? e);

		public VoidCookie set_selection_owner_checked (Window owner, AtomT selection, Timestamp time);
		public VoidCookie set_selection_owner (Window owner, AtomT selection, Timestamp time);

		public GetSelectionOwnerCookie get_selection_owner (AtomT selection);
		public GetSelectionOwnerCookie get_selection_owner_unchecked (AtomT selection);
		public GetSelectionOwnerReply? get_selection_owner_reply (GetSelectionOwnerCookie cookie, out GenericError? e = null);

		public VoidCookie convert_selection_checked (Window requestor, AtomT selection, AtomT target, AtomT property, Timestamp time);
		public VoidCookie convert_selection (Window requestor, AtomT selection, AtomT target, AtomT property, Timestamp time);

		//send_event

		public GrabPointerCookie grab_pointer (bool owner_events, Window grab_window, uint16 event_mask, GrabMode pointer_mode, GrabMode keyboard_mode, Window confine_to, Cursor cursor, Timestamp time);
		public GrabPointerCookie grab_pointer_unchecked (bool owner_events, Window grab_window, uint16 event_mask, GrabMode pointer_mode, GrabMode keyboard_mode, Window confine_to, Cursor cursor, Timestamp time);
		public GrabPointerReply? grab_pointer_reply (GrabPointerCookie cookie, out GenericError? e = null);

		public VoidCookie ungrab_pointer_checked (Timestamp time);
		public VoidCookie ungrab_pointer (Timestamp time);

		public VoidCookie grab_button_checked (bool owner_events, Window grab_window, uint16 event_mask, GrabMode pointer_mode, GrabMode keyboard_mode, Window confine_to, Cursor cursor, uint8 button, uint16 modifiers);
		public VoidCookie grab_button (bool owner_events, Window grab_window, uint16 event_mask, GrabMode pointer_mode, GrabMode keyboard_mode, Window confine_to, Cursor cursor, uint8 button, uint16 modifiers);

		public VoidCookie ungrab_button_checked (uint8 button, Window grab_window, uint16 modifiers);
		public VoidCookie ungrab_button (uint8 button, Window grab_window, uint16 modifiers);

		public VoidCookie change_active_pointer_grab_checked (Cursor cursor, Timestamp time, uint16 event_mask);
		public VoidCookie change_active_pointer_grab (Cursor cursor, Timestamp time, uint16 event_mask);

		public GrabKeyboardCookie grab_keyboard (bool owner_events, Window grab_window, Timestamp time, GrabMode pointer_mode, GrabMode keyboard_mode);
		public GrabKeyboardCookie grab_keyboard_unchecked (bool owner_events, Window grab_window, Timestamp time, GrabMode pointer_mode, GrabMode keyboard_mode);
		public GrabKeyboardReply? grab_keyboard_reply (GrabKeyboardCookie cookie, out GenericError? e = null);

		public VoidCookie ungrab_keyboard_checked (Timestamp time);
		public VoidCookie ungrab_keyboard (Timestamp time);

		public VoidCookie grab_key_checked (bool owner_events, Window grab_window, uint16 modifiers, Keycode key, GrabMode pointer_mode, GrabMode keyboard_mode);
		public VoidCookie grab_key (bool owner_events, Window grab_window, uint16 modifiers, Keycode key, GrabMode pointer_mode, GrabMode keyboard_mode);

		public VoidCookie ungrab_key_checked (Keycode key, Window grab_window, uint16 modifiers);
		public VoidCookie ungrab_key (Keycode key, Window grab_window, uint16 modifiers);

		//allow_events

		public VoidCookie grab_server_checked ();
		public VoidCookie grab_server ();

		public VoidCookie ungrab_server_checked ();
		public VoidCookie ungrab_server ();

		public QueryPointerCookie query_pointer (Window window);
		public QueryPointerCookie query_pointer_unchecked (Window window);
		public QueryPointerReply? query_pointer_reply (QueryPointerCookie cookie, out GenericError? e = null);

		public GetMotionEventsCookie get_motion_events (Window window, Timestamp start, Timestamp stop);
		public GetMotionEventsCookie get_motion_events_unchecked (Window window, Timestamp start, Timestamp stop);
		public GetMotionEventsReply? get_motion_events_reply (GetMotionEventsCookie cookie, out GenericError? e = null);

		public TranslateCoordinatesCookie translate_coordinates (Window src_window, Window dst_window, int16 src_x, int16 src_y);
		public TranslateCoordinatesCookie translate_coordinates_unchecked (Window src_window, Window dst_window, int16 src_x, int16 src_y);
		public TranslateCoordinatesReply? translate_coordinates_reply (TranslateCoordinatesCookie cookie, out GenericError? e = null);

		public VoidCookie warp_pointer_checked (Window src_window, Window dst_window, int16 src_x, int16 src_y, uint16 src_width, uint16 src_height, int16 dst_x, int16 dst_y);
		public VoidCookie warp_pointer (Window src_window, Window dst_window, int16 src_x, int16 src_y, uint16 src_width, uint16 src_height, int16 dst_x, int16 dst_y);

		public VoidCookie set_input_focus_checked (InputFocus revert_to, Window focus, Timestamp time);
		public VoidCookie set_input_focus (InputFocus revert_to, Window focus, Timestamp time);

		public GetInputFocusCookie get_input_focus ();
		public GetInputFocusCookie get_input_focus_unchecked ();
		public GetInputFocusReply? get_input_focus_reply (GetInputFocusCookie cookie, out GenericError? e = null);

		//query_keymap

		[CCode (cname = "xcb_open_font_checked")]
		private VoidCookie vala_open_font_checked (Font fid, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_open_font_checked")]
		public VoidCookie open_font_checked (Font fid, string name) {
			return this.vala_open_font_checked (fid, (uint16) name.length, name);
		}
		[CCode (cname = "xcb_open_font")]
		private VoidCookie vala_open_font (Font fid, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_open_font")]
		public VoidCookie open_font (Font fid, string name) {
			return this.vala_open_font (fid, (uint16) name.length, name);
		}

		public VoidCookie close_font_checked (Font fid);
		public VoidCookie close_font (Font fid);

		public QueryFontCookie query_font (Fontable font);
		public QueryFontCookie query_font_unchecked (Fontable font);
		public QueryFontReply? query_font_reply (QueryFontCookie cookie, out GenericError? e = null);

		/*[CCode (cname = "xcb_query_text_extents")]
		private QueryTextExtentsCookie vala_query_text_extents (Fontable font, uint32 string_len, Char2b* s);
		[CCode (cname = "vala_xcb_query_text_extents")]
		public QueryTextExtentsCookie query_text_extents (Fontable font, uint16[] s) {
			this.vala_query_text_extents (font, s.length, s);
		}
		[CCode (cname = "xcb_query_text_extents_unchecked")]
		private QueryTextExtentsCookie vala_query_text_extents_unchecked (Fontable font, uint32 string_len, Char2b* s);
		[CCode (cname = "vala_xcb_query_text_extents_unchecked")]
		public QueryTextExtentsCookie query_text_extents_unchecked (Fontable font, uint16[] s) { // FIXME: How to handle Char2b?
			this.vala_query_text_extents_unchecked (font, s.length, s);
		}
		public QueryTextExtentsReply? query_text_extents_reply (QueryTextExtentsCookie cookie, out GenericError? e = null);*/

		[CCode (cname = "xcb_list_fonts")]
		private ListFontsCookie vala_list_fonts (uint16 max_names, uint16 pattern_len, string pattern);
		[CCode (cname = "vala_xcb_list_fonts")]
		public ListFontsCookie list_fonts (uint16 max_names, string pattern) {
			return this.vala_list_fonts (max_names, (uint16) pattern.length, pattern);
		}
		[CCode (cname = "xcb_list_fonts_unchecked")]
		private ListFontsCookie vala_list_fonts_unchecked (uint16 max_names, uint16 pattern_len, string pattern);
		[CCode (cname = "vala_xcb_list_fonts_unchecked")]
		public ListFontsCookie list_fonts_unchecked (uint16 max_names, string pattern) {
			return this.vala_list_fonts_unchecked (max_names, (uint16) pattern.length, pattern);
		}
		public ListFontsReply? list_fonts_reply (ListFontsCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_list_fonts_with_info")]
		private ListFontsWithInfoCookie vala_list_fonts_with_info (uint16 max_names, uint16 pattern_len, string pattern);
		[CCode (cname = "vala_xcb_list_fonts_with_info")]
		public ListFontsWithInfoCookie list_fonts_with_info (uint16 max_names, string pattern) {
			return this.vala_list_fonts_with_info (max_names, (uint16) pattern.length, pattern);
		}
		[CCode (cname = "xcb_list_fonts_with_info_unchecked")]
		private ListFontsWithInfoCookie vala_list_fonts_with_info_unchecked (uint16 max_names, uint16 pattern_len, string pattern);
		[CCode (cname = "vala_xcb_list_fonts_with_info_unchecked")]
		public ListFontsWithInfoCookie list_fonts_with_info_unchecked (uint16 max_names, string pattern) {
			return this.vala_list_fonts_with_info_unchecked (max_names, (uint16) pattern.length, pattern);
		}
		public ListFontsWithInfoReply? list_fonts_with_info_reply (ListFontsWithInfoCookie cookie, out GenericError? e = null);

		//set_font_path

		public GetFontPathCookie get_font_path ();
		public GetFontPathCookie get_font_path_unchecked ();
		public GetFontPathReply? get_font_path_reply (GetFontPathCookie cookie, out GenericError? e = null);

		public VoidCookie create_pixmap_checked (uint8 depth, Pixmap pid, Drawable drawable, uint16 width, uint16 height);
		public VoidCookie create_pixmap (uint8 depth, Pixmap pid, Drawable drawable, uint16 width, uint16 height);

		public VoidCookie free_pixmap_checked (Pixmap pid);
		public VoidCookie free_pixmap (Pixmap pid);

		public VoidCookie create_gc_checked (GContext cid, Drawable drawable, uint32 value_mask = 0, [CCode (array_length = false)] uint32[]? value_list = null);
		public VoidCookie create_gc (GContext cid, Drawable drawable, uint32 value_mask = 0, [CCode (array_length = false)] uint32[]? value_list = null);

		public VoidCookie change_gc_checked (GContext gc, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);
		public VoidCookie change_gc (GContext gc, uint32 value_mask, [CCode (array_length = false)] uint32[]? value_list);

		public VoidCookie copy_gc_checked (GContext src_gc, GContext dst_gc, uint32 value_mask);
		public VoidCookie copy_gc (GContext src_gc, GContext dst_gc, uint32 value_mask);

		public VoidCookie set_dashes_checked (GContext gc, uint16 dash_offset, [CCode (array_length_pos = 2.9, array_length_type = "uint16_t")] uint8[] dashes);
		public VoidCookie set_dashes (GContext gc, uint16 dash_offset, [CCode (array_length_pos = 2.9, array_length_type = "uint16_t")] uint8[] dashes);

		public VoidCookie set_clip_rectangles_checked (ClipOrdering ordering, GContext gc, int16 clip_x_origin, int16 clip_y_origin, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] Rectangle[] rectangles);
		public VoidCookie set_clip_rectangles (ClipOrdering ordering, GContext gc, int16 clip_x_origin, int16 clip_y_origin, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] Rectangle[] rectangles);

		public VoidCookie free_gc_checked (GContext gc);
		public VoidCookie free_gc (GContext gc);

		public VoidCookie clear_area_checked (uint8 exposures, Window window, int16 x, int16 y, uint16 width, uint16 height);
		public VoidCookie clear_area (uint8 exposures, Window window, int16 x, int16 y, uint16 width, uint16 height);

		public VoidCookie copy_area_checked (Drawable src_drawable, Drawable dst_drawable, GContext gc, int16 src_x, int16 src_y, int16 dst_x, int16 dst_y, uint16 width, uint16 height);
		public VoidCookie copy_area (Drawable src_drawable, Drawable dst_drawable, GContext gc, int16 src_x, int16 src_y, int16 dst_x, int16 dst_y, uint16 width, uint16 height);

		public VoidCookie copy_plane_checked (Drawable src_drawable, Drawable dst_drawable, GContext gc, int16 src_x, int16 src_y, int16 dst_x, int16 dst_y, uint16 width, uint16 height, uint32 bit_plane);
		public VoidCookie copy_plane (Drawable src_drawable, Drawable dst_drawable, GContext gc, int16 src_x, int16 src_y, int16 dst_x, int16 dst_y, uint16 width, uint16 height, uint32 bit_plane);

		public VoidCookie poly_point_checked (CoordMode coordinate_mode, Drawable drawable, GContext gc, [CCode (array_length_pos = 3.9, array_length_type = "uint32_t")] Point[] points);
		public VoidCookie poly_point (CoordMode coordinate_mode, Drawable drawable, GContext gc, [CCode (array_length_pos = 3.9, array_length_type = "uint32_t")] Point[] points);

		public VoidCookie poly_line_checked (CoordMode coordinate_mode, Drawable drawable, GContext gc, [CCode (array_length = false)] Point[] points);
		public VoidCookie poly_line (CoordMode coordinate_mode, Drawable drawable, GContext gc, [CCode (array_length_pos = 3.9, array_length_type = "uint32_t")] Point[] points);

		public VoidCookie poly_segment_checked (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Segment[] segments);
		public VoidCookie poly_segment (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Segment[] segments);

		public VoidCookie poly_rectangle_checked (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Rectangle[] rectangles);
		public VoidCookie poly_rectangle (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Rectangle[] rectangles);

		public VoidCookie poly_arc_checked (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Arc[] arcs);
		public VoidCookie poly_arc (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Arc[] arcs);

		public VoidCookie fill_poly_checked (Drawable drawable, GContext gc, PolyShape shape, CoordMode coordinate_mode, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] Point[] points);
		public VoidCookie fill_poly (Drawable drawable, GContext gc, PolyShape shape, CoordMode coordinate_mode, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] Point[] points);

		public VoidCookie poly_fill_rectangle_checked (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Rectangle[] rectangles);
		public VoidCookie poly_fill_rectangle (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Rectangle[] rectangles);

		public VoidCookie poly_fill_arc_checked (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Arc[] arcs);
		public VoidCookie poly_fill_arc (Drawable drawable, GContext gc, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] Arc[] arcs);

		public VoidCookie put_image_checked (ImageFormat format, Drawable drawable, GContext gc, uint16 width, uint16 height, int16 dst_x, int16 dst_y, uint8 left_pad, uint8 depth, [CCode (array_length_pos = 9.9, array_length_type = "uint32_t")] uint8[] data);
		public VoidCookie put_image (ImageFormat format, Drawable drawable, GContext gc, uint16 width, uint16 height, int16 dst_x, int16 dst_y, uint8 left_pad, uint8 depth, [CCode (array_length_pos = 9.9, array_length_type = "uint32_t")] uint8[] data);

		public GetImageCookie get_image (ImageFormat format, Drawable drawable, int16 x, int16 y, uint16 width, uint16 height, uint32 plane_mask);
		public GetImageCookie get_image_unchecked (ImageFormat format, Drawable drawable, int16 x, int16 y, uint16 width, uint16 height, uint32 plane_mask);
		public GetImageReply? get_image_reply (GetImageCookie cookie, out GenericError? e = null);

		public VoidCookie poly_text_8_checked (Drawable drawable, GContext gc, int16 x, int16 y, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] uint8[] items);
		public VoidCookie poly_text_8 (Drawable drawable, GContext gc, int16 x, int16 y, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] uint8[] items);

		public VoidCookie poly_text_16_checked (Drawable drawable, GContext gc, int16 x, int16 y, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] uint8[] items);
		public VoidCookie poly_text_16 (Drawable drawable, GContext gc, int16 x, int16 y, [CCode (array_length_pos = 4.9, array_length_type = "uint32_t")] uint8[] items);

		[CCode (cname = "xcb_image_text_8_checked")]
		private VoidCookie vala_image_text_8_checked (uint8 string_len, Drawable drawable, GContext gc, int16 x, int16 y, string text);
		[CCode (cname = "vala_xcb_image_text8_checked")]
		public VoidCookie image_text_8_checked (Drawable drawable, GContext gc, int16 x, int16 y, string text) {
			this.vala_image_text_8_checked ((uint8) text.length, drawable, gc, x, y, text);
		}
		[CCode (cname = "xcb_image_text_8")]
		private VoidCookie vala_image_text_8 (uint8 string_len, Drawable drawable, GContext gc, int16 x, int16 y, string text);
		[CCode (cname = "vala_xcb_image_text8")]
		public VoidCookie image_text_8 (Drawable drawable, GContext gc, int16 x, int16 y, string text) {
			this.vala_image_text_8 ((uint8) text.length, drawable, gc, x, y, text);
		}

		//image_text_16

		public VoidCookie create_colormap_checked (bool alloc, Colormap mid, Window window, VisualID visual);
		public VoidCookie create_colormap (bool alloc, Colormap mid, Window window, VisualID visual);

		public VoidCookie free_colormap_checked (Colormap cmap);
		public VoidCookie free_colormap (Colormap cmap);

		public VoidCookie copy_colormap_and_free_checked (Colormap mid, Colormap src_cmap);
		public VoidCookie copy_colormap_and_free (Colormap mid, Colormap src_cmap);

		public VoidCookie install_colormap_checked (Colormap cmap);
		public VoidCookie install_colormap (Colormap cmap);

		public VoidCookie uninstall_colormap_checked (Colormap cmap);
		public VoidCookie uninstall_colormap (Colormap cmap);

		public ListInstalledColormapsCookie list_installed_colormaps (Window window);
		public ListInstalledColormapsCookie list_installed_colormaps_unchecked (Window window);
		public ListInstalledColormapsReply? list_installed_colormaps_reply (ListInstalledColormapsCookie cookie, out GenericError? e = null);

		public AllocColorCookie alloc_color (Colormap cmap, uint16 red, uint16 green, uint16 blue);
		public AllocColorCookie alloc_color_unchecked (Colormap cmap, uint16 red, uint16 green, uint16 blue);
		public AllocColorReply? alloc_color_reply (AllocColorCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_alloc_named_color")]
		private AllocNamedColorCookie vala_alloc_named_color (Colormap cmap, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_alloc_named_color")]
		public AllocNamedColorCookie alloc_named_color (Colormap cmap, string name) {
			this.vala_alloc_named_color (cmap, (uint16) name.length, name);
		}
		[CCode (cname = "xcb_alloc_named_color_unchecked")]
		private AllocNamedColorCookie vala_alloc_named_color_unchecked (Colormap cmap, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_alloc_named_color_unchecked")]
		public AllocNamedColorCookie alloc_named_color_unchecked (Colormap cmap, string name) {
			this.vala_alloc_named_color_unchecked (cmap, (uint16) name.length, name);
		}
		public AllocNamedColorReply? alloc_named_color_reply (AllocNamedColorCookie cookie, out GenericError? e = null);

		public AllocColorCellsCookie alloc_color_cells (bool contiguous, Colormap cmap, uint16 colors, uint16 planes);
		public AllocColorCellsCookie alloc_color_cells_unchecked (bool contiguous, Colormap cmap, uint16 colors, uint16 planes);
		public AllocColorCellsReply? alloc_color_cells_reply (AllocColorCellsCookie cookie, out GenericError? e = null);

		public AllocColorPlanesCookie alloc_color_planes (bool contiguous, Colormap cmap, uint16 colors, uint16 reds, uint16 greens, uint16 blues);
		public AllocColorPlanesCookie alloc_color_planes_unchecked (bool contiguous, Colormap cmap, uint16 colors, uint16 reds, uint16 greens, uint16 blues);
		public AllocColorPlanesReply? alloc_color_planes_reply (AllocColorPlanesCookie cookie, out GenericError? e = null);

		public VoidCookie free_colors_checked (Colormap cmap, uint32 plane_mask, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] uint32[] pixels);
		public VoidCookie free_colors (Colormap cmap, uint32 plane_mask, [CCode (array_length_pos = 2.9, array_length_type = "uint32_t")] uint32[] pixels);

		public VoidCookie store_colors_checked (Colormap cmap, [CCode (array_length_pos = 1.9, array_length_type = "uint32_t")] Coloritem[] items);
		public VoidCookie store_colors (Colormap cmap, [CCode (array_length_pos = 1.9, array_length_type = "uint32_t")] Coloritem[] items);

		[CCode (cname = "xcb_store_named_color_checked")]
		private VoidCookie vala_store_named_color_checked (ColorFlag flags, Colormap cmap, uint32 pixel, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_store_named_color_checked")]
		public VoidCookie store_named_color_checked (ColorFlag flags, Colormap cmap, uint32 pixel, string name) {
			this.vala_store_named_color_checked (flags, cmap, pixel, (uint16) name.length, name);
		}
		[CCode (cname = "xcb_store_named_color")]
		private VoidCookie vala_store_named_color (ColorFlag flags, Colormap cmap, uint32 pixel, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_store_named_color")]
		public VoidCookie store_named_color (ColorFlag flags, Colormap cmap, uint32 pixel, string name) {
			this.vala_store_named_color (flags, cmap, pixel, (uint16) name.length, name);
		}

		public QueryColorsCookie query_colors (Colormap cmap, [CCode (array_length_pos = 1.9, array_length_type = "uint32_t")] uint32[] pixels);
		public QueryColorsCookie query_colors_unchecked (Colormap cmap, [CCode (array_length_pos = 1.9, array_length_type = "uint32_t")] uint32[] pixels);
		public QueryColorsReply? query_colors_reply (QueryColorsCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_lookup_color")]
		private LookupColorCookie vala_lookup_color (Colormap cmap, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_lookup_color")]
		public LookupColorCookie lookup_color (Colormap cmap, string name) {
			this.vala_lookup_color (cmap, (uint16) name.length, name);
		}
		[CCode (cname = "xcb_lookup_color_unchecked")]
		private LookupColorCookie vala_lookup_color_unchecked (Colormap cmap, uint16 name_len, string name);
		[CCode (cname = "vala_xcb_lookup_color_unchecked")]
		public LookupColorCookie lookup_color_unchecked (Colormap cmap, string name) {
			this.vala_lookup_color_unchecked (cmap, (uint16) name.length, name);
		}
		public LookupColorReply? lookup_color_reply (LookupColorCookie cookie, out GenericError? e = null);

		public VoidCookie create_cursor_checked (Cursor cid, Pixmap source, Pixmap mask, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue, uint16 x, uint16 y);
		public VoidCookie create_cursor (Cursor cid, Pixmap source, Pixmap mask, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue, uint16 x, uint16 y);

		public VoidCookie create_glyph_cursor_checked (Cursor cid, Font source_font, Font mask_font, uint16 source_char, uint16 mask_char, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue);
		public VoidCookie create_glyph_cursor (Cursor cid, Font source_font, Font mask_font, uint16 source_char, uint16 mask_char, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue);

		public VoidCookie free_cursor_checked (Cursor cursor);
		public VoidCookie free_cursor (Cursor cursor);

		public VoidCookie recolor_cursor_checked (Cursor cursor, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue);
		public VoidCookie recolor_cursor (Cursor cursor, uint16 fore_red, uint16 fore_green, uint16 fore_blue, uint16 back_red, uint16 back_green, uint16 back_blue);

		public QueryBestSizeCookie query_best_size (uint8 _class, Drawable drawable, uint16 width, uint16 height); // FIXME: Is there an enum for class?
		public QueryBestSizeCookie query_best_size_unchecked (uint8 _class, Drawable drawable, uint16 width, uint16 height);
		public QueryBestSizeReply? query_best_size_reply (QueryBestSizeCookie cookie, out GenericError? e = null);

		[CCode (cname = "xcb_query_extension")]
		private QueryExtensionCookie vala_query_extension (uint16 name_len, string name);
		[CCode (cname = "vala_xcb_query_extension")]
		public QueryExtensionCookie query_extension (string name) {
			return this.vala_query_extension ((uint16) name.length, name);
		}
		[CCode (cname = "xcb_query_extension_unchecked")]
		private QueryExtensionCookie vala_query_extension_unchecked (uint16 name_len, string name);
		[CCode (cname = "vala_xcb_query_extension_unchecked")]
		public QueryExtensionCookie query_extension_unchecked (string name) {
			return this.vala_query_extension_unchecked ((uint16) name.length, name);
		}
		public QueryExtensionReply? query_extension_reply (QueryExtensionCookie cookie, out GenericError? e = null);

		public ListExtensionsCookie list_extensions ();
		public ListExtensionsCookie list_extensions_unchecked ();
		public ListExtensionsReply? list_extensions_reply (ListExtensionsCookie cookie, out GenericError? e = null);

		//change_keyboard_mapping

		//get_keyboard_mapping

		//change_keyboard_control

		//get_keyboard_control

		public VoidCookie bell_checked (int8 percent);
		public VoidCookie bell (int8 percent);

		//change_pointer_control

		//get_pointer_control

		public VoidCookie set_screen_saver_checked (int16 timeout, int16 interval, uint8 prefer_blanking, uint8 allow_exposures);
		public VoidCookie set_screen_saver (int16 timeout, int16 interval, uint8 prefer_blanking, uint8 allow_exposures);

		public GetScreenSaverCookie get_screen_saver ();
		public GetScreenSaverCookie get_screen_saver_unchecked ();
		public GetScreenSaverReply? get_screen_saver_reply (GetScreenSaverCookie cookie, out GenericError? e = null);

		public VoidCookie change_hosts_checked (HostMode mode, Family family, [CCode (array_length_pos = 2.9, array_length_type = "uint16_t")] uint8[] address);
		public VoidCookie change_hosts (HostMode mode, Family family, [CCode (array_length_pos = 2.9, array_length_type = "uint16_t")] uint8[] address);

		public ListHostsCookie list_hosts ();
		public ListHostsCookie list_hosts_unchecked ();
		public ListHostsReply? list_hosts_reply (ListHostsCookie cookie, out GenericError? e = null);

		public VoidCookie set_access_control_checked (AccessControl mode);
		public VoidCookie set_access_control (AccessControl mode);

		public VoidCookie set_close_down_mode_checked (CloseDown mode);
		public VoidCookie set_close_down_mode (CloseDown mode);

		public VoidCookie kill_client_checked (uint32 resource);
		public VoidCookie kill_client (uint32 resource);

		public VoidCookie rotate_properties_checked (Window window, int16 delta, [CCode (array_length_pos = 1.9, array_length_type = "uint16_t")] AtomT[] atoms);
		public VoidCookie rotate_properties (Window window, int16 delta, [CCode (array_length_pos = 1.9, array_length_type = "uint16_t")] AtomT[] atoms);

		public VoidCookie force_screen_saver_checked (ScreenSaver mode);
		public VoidCookie force_screen_saver (ScreenSaver mode);

		//set_pointer_mapping

		//get_pointer_mapping

		//set_modifier_mapping

		//get_modifier_mapping

		public VoidCookie no_operation_checked ();
		public VoidCookie no_operation ();
	}

	[CCode (cprefix = "XCB_CONN_", cname = "int", has_type_id = false)]
	public enum ConnectionError
	{
		ERROR,
		CLOSED_EXT_NOTSUPPORTED,
		CLOSED_MEM_INSUFFICIENT,
		CLOSED_REQ_LEN_EXCEED,
		CLOSED_PARSE_ERR,
		CLOSED_INVALID_SCREEN,
		CLOSED_FDPASSING_FAILED,
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_geometry_cookie_t", has_type_id = false)]
	public struct GetGeometryCookie {
	}

	[CCode (cname = "xcb_get_geometry_reply_t", ref_function = "", unref_function = "free")]
	public class GetGeometryReply {
		public uint8      response_type;
		public uint8      depth;
		public uint16     sequence;
		public uint32     length;
		public Window     root;
		public int16      x;
		public int16      y;
		public uint16     width;
		public uint16     height;
		public uint16     border_width;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_window_attributes_cookie_t", has_type_id = false)]
	public struct GetWindowAttributesCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_window_attributes_reply_t", ref_function = "", unref_function = "")]
	public class GetWindowAttributesReply {
		public uint8        response_type;
		public uint8        backing_store;
		public uint16       sequence;
		public uint32       length;
		public VisualID     visual;
		public uint16       _class;
		public uint8        bit_gravity;
		public uint8        win_gravity;
		public uint32       backing_planes;
		public uint32       backing_pixel;
		public uint8        save_under;
		public uint8        map_is_installed;
		public uint8        map_state;
		public uint8        override_redirect;
		public Colormap     colormap;
		public uint32       all_event_masks;
		public uint32       your_event_mask;
		public uint16       do_not_propagate_mask;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_property_cookie_t", has_type_id = false)]
	public struct GetPropertyCookie {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_intern_atom_cookie_t", has_type_id = false)]
	public struct InternAtomCookie {
	}

	[Compact]
	[CCode (cname = "xcb_intern_atom_reply_t", ref_function = "", unref_function = "free")]
	public class InternAtomReply {
		private uint8    response_type;
		private uint16   sequence;
		public  uint32   length;
		public  AtomT    atom;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_atom_name_cookie_t", has_type_id = false)]
	public struct GetAtomNameCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_atom_name_reply_t", ref_function = "", unref_function = "free")]
	public class GetAtomNameReply {
		private uint8 response_type;
		private uint16 sequence;
		public uint32 length;
		public uint16 name_len;
		[CCode (cname = "xcb_get_atom_name_name")]
		private unowned string vala_name ();
		public string name { owned get { return "%.*s".printf (name_len, vala_name ()); } }
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_properties_cookie_t", has_type_id = false)]
	public struct ListPropertiesCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_properties_reply_t", ref_function = "", unref_function = "free")]
	public class ListPropertiesReply {
		private uint16 atoms_len;
		[CCode (cname = "xcb_list_properties_atoms")]
		private Atom* vala_atoms ();
		public Atom[] atoms
		{
			get
			{
				unowned Atom[] res = (Atom[]) vala_atoms ();
				res.length = atoms_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_selection_owner_cookie_t", has_type_id = false)]
	public struct GetSelectionOwnerCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_selection_owner_reply_t", ref_function = "", unref_function = "free")]
	public class GetSelectionOwnerReply {
		public Window owner;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_grab_pointer_cookie_t", has_type_id = false)]
	public struct GrabPointerCookie {
	}

	[Compact]
	[CCode (cname = "xcb_grab_pointer_reply_t", ref_function = "", unref_function = "free")]
	public class GrabPointerReply {
		public GrabStatus status;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_grab_keyboard_cookie_t", has_type_id = false)]
	public struct GrabKeyboardCookie {
	}

	[Compact]
	[CCode (cname = "xcb_grab_keyboard_reply_t", ref_function = "", unref_function = "free")]
	public class GrabKeyboardReply {
		public GrabStatus status;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_pointer_cookie_t", has_type_id = false)]
	public struct QueryPointerCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_pointer_reply_t", ref_function = "", unref_function = "free")]
	public class QueryPointerReply {
		public uint8 same_screen;
		public Window root;
		public Window child;
		public int16 root_x;
		public int16 root_y;
		public int16 win_x;
		public int16 win_y;
		public uint16 mask;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_motion_events_cookie_t", has_type_id = false)]
	public struct GetMotionEventsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_motion_events_reply_t", ref_function = "", unref_function = "free")]
	public class GetMotionEventsReply {
		private uint32 events_len;
		[CCode (cname = "xcb_get_motion_events_events")]
		private Timecoord* vala_events ();
		public Timecoord[] events
		{
			get
			{
				unowned Timecoord[] res = (Timecoord[]) vala_events ();
				res.length = (int) events_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_image_cookie_t", has_type_id = false)]
	public struct GetImageCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_image_reply_t", ref_function = "", unref_function = "")]
	public class GetImageReply {
		public uint8 depth;
		public VisualID visual;
		private uint32 length;
		[CCode (cname = "xcb_get_image_data")]
		public uint8* vala_data ();
		public uint8[] data
		{
			get
			{
				unowned uint8[] res = (uint8[]) vala_data ();
				res.length = (int) length;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_installed_colormaps_cookie_t", has_type_id = false)]
	public struct ListInstalledColormapsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_installed_colormaps_reply_t", ref_function = "", unref_function = "free")]
	public class ListInstalledColormapsReply {
		private uint16 cmaps_len;
		[CCode (cname = "xcb_list_installed_colormaps_cmaps")]
		private Colormap* vala_cmaps ();
		public Colormap[] cmaps
		{
			get
			{
				unowned Colormap[] res = (Colormap[]) vala_cmaps ();
				res.length = (int) cmaps_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_alloc_color_cookie_t", has_type_id = false)]
	public struct AllocColorCookie {
	}

	[Compact]
	[CCode (cname = "xcb_alloc_color_reply_t", ref_function = "", unref_function = "free")]
	public class AllocColorReply {
		public uint16 red;
		public uint16 green;
		public uint16 blue;
		public uint32 pixel;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_alloc_named_color_cookie_t", has_type_id = false)]
	public struct AllocNamedColorCookie {
	}

	[Compact]
	[CCode (cname = "xcb_alloc_named_color_reply_t", ref_function = "", unref_function = "free")]
	public class AllocNamedColorReply {
		public uint32 pixel;
		public uint16 exact_red;
		public uint16 exact_green;
		public uint16 exact_blue;
		public uint16 visual_red;
		public uint16 visual_green;
		public uint16 visual_blue;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_alloc_color_cells_cookie_t", has_type_id = false)]
	public struct AllocColorCellsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_alloc_color_cells_reply_t", ref_function = "", unref_function = "free")]
	public class AllocColorCellsReply {
		private uint16 pixels_len;
		[CCode (cname = "xcb_alloc_color_cells_pixels")]
		private uint32* vala_pixels ();
		public uint32[] pixels
		{
			get {
				unowned uint32[] res = (uint32[]) vala_pixels ();
				res.length = (int) pixels_len;
				return res;
			}
		}
		private uint16 masks_len;
		[CCode (cname = "xcb_alloc_color_cells_masks")]
		private uint32* vala_masks ();
		public uint32[] masks
		{
			get {
				unowned uint32[] res = (uint32[]) vala_masks ();
				res.length = (int) masks_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_alloc_color_planes_cookie_t", has_type_id = false)]
	public struct AllocColorPlanesCookie {
	}

	[Compact]
	[CCode (cname = "xcb_alloc_color_planes_reply_t", ref_function = "", unref_function = "free")]
	public class AllocColorPlanesReply {
		public uint32 red_mask;
		public uint32 green_mask;
		public uint32 blue_mask;
		private uint16 pixels_len;
		[CCode (cname = "xcb_alloc_color_planes_pixels")]
		private uint32* vala_pixels ();
		public uint32[] pixels
		{
			get {
				unowned uint32[] res = (uint32[]) vala_pixels ();
				res.length = (int) pixels_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_colors_cookie_t", has_type_id = false)]
	public struct QueryColorsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_colors_reply_t", ref_function = "", unref_function = "free")]
	public class QueryColorsReply {
		private uint16 colors_len;
		[CCode (cname = "xcb_query_colors_colors")]
		private RGB* vala_colors ();
		public RGB[] colors
		{
			get {
				unowned RGB[] res = (RGB[]) vala_colors ();
				res.length = (int) colors_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_lookup_color_cookie_t", has_type_id = false)]
	public struct LookupColorCookie {
	}

	[Compact]
	[CCode (cname = "xcb_lookup_color_reply_t", ref_function = "", unref_function = "free")]
	public class LookupColorReply {
		public uint16 exact_red;
		public uint16 exact_green;
		public uint16 exact_blue;
		public uint16 visual_red;
		public uint16 visual_green;
		public uint16 visual_blue;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_best_size_cookie_t", has_type_id = false)]
	public struct QueryBestSizeCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_best_size_reply_t", ref_function = "", unref_function = "free")]
	public class QueryBestSizeReply {
		public uint16 width;
		public uint16 height;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_extension_cookie_t", has_type_id = false)]
	public struct QueryExtensionCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_extension_reply_t", ref_function = "", unref_function = "free")]
	public class QueryExtensionReply {
		public bool present;
		public uint8 major_opcode;
		public uint8 first_event;
		public uint8 first_error;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_extensions_cookie_t", has_type_id = false)]
	public struct ListExtensionsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_extensions_reply_t", ref_function = "", unref_function = "free")]
	public class ListExtensionsReply {
		private uint8 names_len;
		[CCode (cname = "xcb_list_extensions_names_iterator")]
		private StrIterator names_iterator ();
		public string[] names
		{
			owned get
			{
				var value = new string[names_len];
				var iter = names_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data.name;
					StrIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_keyboard_mapping_cookie_t", has_type_id = false)]
	public struct GetKeyboardMappingCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_get_keyboard_mapping_reply_t", ref_function = "", unref_function = "free")]
	//public class GetKeyboardMappingReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_keyboard_control_cookie_t", has_type_id = false)]
	public struct GetKeyboardControlCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_get_keyboard_control_reply_t", ref_function = "", unref_function = "free")]
	//public class GetKeyboardControlReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_pointer_control_cookie_t", has_type_id = false)]
	public struct GetPointerControlCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_get_pointer_control_reply_t", ref_function = "", unref_function = "free")]
	//public class GetPointerControlReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_screen_saver_cookie_t", has_type_id = false)]
	public struct GetScreenSaverCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_screen_saver_reply_t", ref_function = "", unref_function = "free")]
	public class GetScreenSaverReply {
		public uint16 timeout;
		public uint16 interval;
		public uint8 prefer_blanking;
		public uint8 allow_exposures;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_hosts_cookie_t", has_type_id = false)]
	public struct ListHostsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_hosts_reply_t", ref_function = "", unref_function = "free")]
	public class ListHostsReply {
		private uint16 hosts_len;
		[CCode (cname = "xcb_list_hosts_hosts_iterator")]
		private HostIterator hosts_iterator ();
		public Host[] hosts {
			owned get
			{
				var value = new Host[hosts_len];
				var iter = hosts_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data;
					HostIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_set_pointer_mapping_cookie_t", has_type_id = false)]
	public struct SetPointerMappingCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_set_pointer_mapping_reply_t", ref_function = "", unref_function = "free")]
	//public class SetPointerMappingReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_pointer_mapping_cookie_t", has_type_id = false)]
	public struct GetPointerMappingCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_get_pointer_mapping_reply_t", ref_function = "", unref_function = "free")]
	//public class GetPointerMappingReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_set_modifier_mapping_cookie_t", has_type_id = false)]
	public struct SetModifierMappingCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_set_modifier_mapping_reply_t", ref_function = "", unref_function = "free")]
	//public class SetModifierMappingReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_modifier_mapping_cookie_t", has_type_id = false)]
	public struct GetModifierMappingCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_get_modifier_mapping_reply_t", ref_function = "", unref_function = "free")]
	//public class GetModifierMappingReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_translate_coordinates_cookie_t", has_type_id = false)]
	public struct TranslateCoordinatesCookie {
	}

	[Compact]
	[CCode (cname = "xcb_translate_coordinates_reply_t", ref_function = "", unref_function = "free")]
	public class TranslateCoordinatesReply {
		public uint8 same_screen;
		public Window child;
		public int16 dst_x;
		public int16 dst_y;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_input_focus_cookie_t", has_type_id = false)]
	public struct GetInputFocusCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_input_focus_reply_t", ref_function = "", unref_function = "free")]
	public class GetInputFocusReply {
		public InputFocus revert_to;
		public Window focus;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_keymap_cookie_t", has_type_id = false)]
	public struct QueryKeymapCookie {
	}

	//[Compact]
	//[CCode (cname = "xcb_query_keymap_reply_t", ref_function = "", unref_function = "free")]
	//public class QueryKeymapReply {
	//}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_font_cookie_t", has_type_id = false)]
	public struct QueryFontCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_font_reply_t", ref_function = "", unref_function = "free")]
	public class QueryFontReply {
		public Charinfo min_bounds;
		public Charinfo max_bounds;
		public uint16 min_char_or_byte2;
		public uint16 max_char_or_byte2;
		public uint16 default_char;
		public uint8 draw_direction;
		public uint8 min_byte1;
		public uint8 max_byte1;
		public uint8 all_chars_exist;
		public int16 font_ascent;
		public int16 font_descent;
		private uint16 properties_len;
		[CCode (cname = "xcb_query_font_properties")]
		private Fontprop* vala_properties ();
		public Fontprop[] properties
		{
			get
			{
				unowned Fontprop[] res = (Fontprop[]) vala_properties ();
				res.length = properties_len;
				return res;
			}
		}
		private uint32 char_infos_len;
		[CCode (cname = "xcb_query_font_char_infos")]
		private Charinfo* vala_char_infos ();
		public Charinfo[] char_infos
		{
			get
			{
				unowned Charinfo[] res = (Charinfo[]) vala_char_infos ();
				res.length = (int) char_infos_len;
				return res;
			}
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_query_text_extents_cookie_t", has_type_id = false)]
	public struct QueryTextExtentsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_query_text_extents_reply_t", ref_function = "", unref_function = "free")]
	public class QueryTextExtentsReply {
		public FontDraw draw_direction;
		public int16 font_ascent;
		public int16 font_descent;
		public int16 overall_ascent;
		public int16 overall_descent;
		public int16 overall_width;
		public int16 overall_height;
		public int16 overall_left;
		public int16 overall_right;
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_fonts_cookie_t", has_type_id = false)]
	public struct ListFontsCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_fonts_reply_t", ref_function = "", unref_function = "free")]
	public class ListFontsReply {
		private uint16 names_len;
		[CCode (cname = "xcb_list_fonts_names_iterator")]
		private StrIterator names_iterator ();
		public string[] names
		{
			owned get
			{
				var value = new string[names_len];
				var iter = names_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data.name;
					StrIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	[Compact]
	[CCode (cname = "xcb_get_property_reply_t", ref_function = "", unref_function = "free")]
	public class GetPropertyReply {
		public AtomT type;
		public uint8 format;
		public uint32 bytes_after;
		private uint32 value_len;
		[CCode (cname = "xcb_get_property_value")]
		public unowned void *value ();
		[CCode (cname = "xcb_get_property_value_length")]
		public int32 value_length ();
		public string value_as_string () {
			GLib.assert (format == 8);
			return "%.*s".printf (value_len, value ());
		}
		public unowned uint8[] value_as_uint8_array () {
			GLib.assert (format == 8);
			unowned uint8[] res = (uint8[]) value ();
			res.length = (int) value_len;
			return res;
		}
		public unowned uint16[] value_as_uint16_array () {
			GLib.assert (format == 16);
			unowned uint16[] res = (uint16[]) value ();
			res.length = (int) value_len;
			return res;
		}
		public unowned uint32[] value_as_uint32_array () {
			GLib.assert (format == 32);
			unowned uint32[] res = (uint32[]) value ();
			res.length = (int) value_len;
			return res;
		}
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_list_fonts_with_info_cookie_t", has_type_id = false)]
	public struct ListFontsWithInfoCookie {
	}

	[Compact]
	[CCode (cname = "xcb_list_fonts_with_info_reply_t", ref_function = "", unref_function = "free")]
	public class ListFontsWithInfoReply {
		public Charinfo min_bounds;
		public Charinfo max_bounds;
		public uint16 min_char_or_byte2;
		public uint16 max_char_or_byte2;
		public uint16 default_char;
		public uint8 draw_direction;
		public uint8 min_byte1;
		public uint8 max_byte1;
		public uint8 all_chars_exist;
		public int16 font_ascent;
		public int16 font_descent;
		public uint32 replies_hint;
		private uint16 properties_len;
		[CCode (cname = "xcb_list_fonts_with_info_properties")]
		private Fontprop* vala_properties ();
		public Fontprop[] properties
		{
			get
			{
				unowned Fontprop[] res = (Fontprop[]) vala_properties ();
				res.length = properties_len;
				return res;
			}
		}
		private uint8 name_len;
		[CCode (cname = "xcb_list_fonts_with_info_name")]
		private unowned string vala_name ();
		public string name { owned get { return "%.*s".printf (name_len, vala_name ()); } }
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_get_font_path_cookie_t", has_type_id = false)]
	public struct GetFontPathCookie {
	}

	[Compact]
	[CCode (cname = "xcb_get_font_path_reply_t", ref_function = "", unref_function = "free")]
	public class GetFontPathReply {
		private uint16 path_len;
		[CCode (cname = "xcb_get_font_path_path_iterator")]
		private StrIterator path_iterator ();
		public string[] path
		{
			owned get
			{
				var value = new string[path_len];
				var iter = path_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data.name;
					StrIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	[CCode (cname = "xcb_circulate_t", has_type_id = false)]
	public enum Circulate {
		RAISE_LOWEST,
		LOWER_HIGHEST
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_atom_t", has_type_id = false)]
	public struct AtomT {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "xcb_fontable_t", has_type_id = false)]
	public struct Fontable {
	}

	[CCode (cname = "xcb_prop_mode_t", has_type_id = false)]
	public enum PropMode {
		REPLACE,
		PREPEND,
		APPEND
	}

	[CCode (cname = "xcb_grab_mode_t", has_type_id = false)]
	public enum GrabMode {
		SYNC,
		ASYNC
	}

	[CCode (cname = "xcb_grab_status_t", has_type_id = false)]
	public enum GrabStatus {
		SUCCESS,
		ALREADY_GRABBED,
		INVALID_TIME,
		NOT_VIEWABLE,
		FROZEN
	}

	[SimpleType]
	[CCode (cname = "xcb_timecoord_t", has_type_id = false)]
	public struct Timecoord {
		public Timestamp time;
		public int16 x;
		public int16 y;
	}

	[SimpleType]
	[CCode (cname = "xcb_timecoord_iterator_t", has_type_id = false)]
	private struct TimecoordIterator {
		public unowned Timecoord data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_timecoord_next")]
		public static void next (ref TimecoordIterator iter);
	}

	[CCode (cname = "xcb_atom_enum_t", has_type_id = false)]
	public enum Atom {
		NONE,
		ANY,
		PRIMARY,
		SECONDARY,
		ARC,
		ATOM,
		BITMAP,
		CARDINAL,
		COLORMAP,
		CURSOR,
		CUT_BUFFER0,
		CUT_BUFFER1,
		CUT_BUFFER2,
		CUT_BUFFER3,
		CUT_BUFFER4,
		CUT_BUFFER5,
		CUT_BUFFER6,
		CUT_BUFFER7,
		DRAWABLE,
		FONT,
		INTEGER,
		PIXMAP,
		POINT,
		RECTANGLE,
		RESOURCE_MANAGER,
		RGB_COLOR_MAP,
		RGB_BEST_MAP,
		RGB_BLUE_MAP,
		RGB_DEFAULT_MAP,
		RGB_GRAY_MAP,
		RGB_GREEN_MAP,
		RGB_RED_MAP,
		STRING,
		VISUALID,
		WINDOW,
		WM_COMMAND,
		WM_HINTS,
		WM_CLIENT_MACHINE,
		WM_ICON_NAME,
		WM_ICON_SIZE,
		WM_NAME,
		WM_NORMAL_HINTS,
		WM_SIZE_HINTS,
		WM_ZOOM_HINTS,
		MIN_SPACE,
		NORM_SPACE,
		MAX_SPACE,
		END_SPACE,
		SUPERSCRIPT_X,
		SUPERSCRIPT_Y,
		SUBSCRIPT_X,
		SUBSCRIPT_Y,
		UNDERLINE_POSITION,
		UNDERLINE_THICKNESS,
		STRIKEOUT_ASCENT,
		STRIKEOUT_DESCENT,
		ITALIC_ANGLE,
		X_HEIGHT,
		QUAD_WIDTH,
		WEIGHT,
		POINT_SIZE,
		RESOLUTION,
		COPYRIGHT,
		NOTICE,
		FONT_NAME,
		FAMILY_NAME,
		FULL_NAME,
		CAP_HEIGHT,
		WM_CLASS,
		WM_TRANSIENT_FOR
	}

	public const uint8 KEY_PRESS;
	public const uint8 KEY_RELEASE;
	public const uint8 BUTTON_PRESS;
	public const uint8 BUTTON_RELEASE;
	public const uint8 MOTION_NOTIFY;
	public const uint8 ENTER_NOTIFY;
	public const uint8 LEAVE_NOTIFY;
	public const uint8 FOCUS_IN;
	public const uint8 FOCUS_OUT;
	public const uint8 KEYMAP_NOTIFY;
	public const uint8 EXPOSE;
	public const uint8 GRAPHICS_EXPOSURE;
	public const uint8 NO_EXPOSURE;
	public const uint8 VISIBILITY_NOTIFY;
	public const uint8 CREATE_NOTIFY;
	public const uint8 DESTROY_NOTIFY;
	public const uint8 UNMAP_NOTIFY;
	public const uint8 MAP_NOTIFY;
	public const uint8 MAP_REQUEST;
	public const uint8 REPARENT_NOTIFY;
	public const uint8 CONFIGURE_NOTIFY;
	public const uint8 CONFIGURE_REQUEST;
	public const uint8 GRAVITY_NOTIFY;
	public const uint8 RESIZE_REQUEST;
	public const uint8 CIRCULATE_NOTIFY;
	public const uint8 CIRCULATE_REQUEST;
	public const uint8 PROPERTY_NOTIFY;
	public const uint8 SELECTION_CLEAR;
	public const uint8 SELECTION_REQUEST;
	public const uint8 SELECTION_NOTIFY;
	public const uint8 COLORMAP_NOTIFY;
	public const uint8 CLIENT_MESSAGE;
	public const uint8 MAPPING_NOTIFY;

	[CCode (cname = "xcb_config_window_t", has_type_id = false)]
	public enum ConfigWindow {
		X,
		Y,
		WIDTH,
		HEIGHT,
		BORDER_WIDTH,
		SIBLING,
		STACK_MODE
	}

	[CCode (cname = "xcb_image_order_t", has_type_id = false)]
	public enum ImageOrder {
		LSB_FIRST,
		MSB_FIRST
	}

	[Compact]
	[CCode (cname = "xcb_setup_t", ref_function = "", unref_function = "")]
	public class Setup {
		public uint8 status;
		public uint16 protocol_major_version;
		public uint16 protocol_minor_version;
		public uint32 release_number;
		public uint32 resource_id_base;
		public uint32 resource_id_mask;
		public uint32 motion_buffer_size;
		private uint16 vendor_len;
		[CCode (cname = "xcb_setup_vendor")]
		private unowned string vala_vendor ();
		public string vendor { owned get { return "%.*s".printf (vendor_len, vala_vendor ()); } }
		public uint32 maximum_request_length;
		public uint8 image_byte_order;
		public uint8 bitmap_format_bit_order;
		public uint8 bitmap_format_scanline_unit;
		public uint8 bitmap_format_scanline_pad;
		public Keycode min_keycode;
		public Keycode max_keycode;
		private uint8 pixmap_formats_len;
		[CCode (cname = "xcb_setup_pixmap_formats")]
		private Format* vala_pixmap_formats ();
		public Format[] pixmap_formats
		{
			get
			{
				unowned Format[] res = (Format[]) vala_pixmap_formats ();
				res.length = pixmap_formats_len;
				return res;
			}
		}
		private uint8 roots_len;
		[Version (deprecated_since = "vala-0.26", replacement = "Xcb.Setup.screens")]
		public int roots_length ();
		public ScreenIterator roots_iterator ();
		public Screen[] screens {
			owned get
			{
				var value = new Screen[roots_len];
				var iter = roots_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data;
					ScreenIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	public const char COPY_FROM_PARENT;

	[CCode (cname = "xcb_window_class_t", has_type_id = false)]
	public enum WindowClass {
		COPY_FROM_PARENT,
		INPUT_OUTPUT,
		INPUT_ONLY
	}

	[Compact]
	[CCode (cname = "xcb_generic_event_t", ref_function = "", unref_function = "")]
	public class GenericEvent {
		public uint8 response_type;
		public uint8 extension;
		public uint16 sequence;
		public uint32 length;
		public uint16 event_type;
		public uint32 full_sequence;
	}

	[SimpleType]
	[CCode (cname = "xcb_timestamp_t", has_type_id = false)]
	public struct Timestamp : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_keycode_t", has_type_id = false)]
	public struct Keycode : uint8 {
	}

	[SimpleType]
	[CCode (cname = "xcb_colormap_t", has_type_id = false)]
	public struct Colormap : uint32 {
	}

	[Compact]
	[CCode (cname = "xcb_key_press_event_t", ref_function = "", unref_function = "")]
	public class KeyPressEvent : GenericEvent {
		public Keycode detail;
		public uint16 sequence;
		public Timestamp time;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
		public uint16 state;
		public uint8 same_screen;
	}

	[Compact]
	[CCode (cname = "xcb_key_release_event_t", ref_function = "", unref_function = "")]
	public class KeyReleaseEvent : GenericEvent {
		public Keycode detail;
		public uint16 sequence;
		public Timestamp time;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
		public uint16 state;
		public uint8 same_screen;
	}

	[Compact]
	[CCode (cname = "xcb_generic_error_t", ref_function = "", unref_function = "")]
	public class GenericError {
		public uint8 response_type;
		public uint8 error_code;
		public uint16 sequence;
		public uint32 resource_id;
		public uint16 minor_code;
		public uint8 major_code;
	}

	[Compact]
	[CCode (cname = "xcb_button_press_event_t", ref_function = "", unref_function = "")]
	public class ButtonPressEvent : GenericEvent {
		public Button detail;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
	}

	[Compact]
	[CCode (cname = "xcb_button_release_event_t", ref_function = "", unref_function = "")]
	public class ButtonReleaseEvent : GenericEvent {
		public Button detail;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
	}

	[Compact]
	[CCode (cname = "xcb_motion_notify_event_t", ref_function = "", unref_function = "")]
	public class MotionNotifyEvent : GenericEvent {
		public uint8 detail;
		public uint16 sequence;
		public Timestamp time;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
		public uint16 state;
		public uint8 same_screen;
	}

	[Compact]
	[CCode (cname = "xcb_expose_event_t", ref_function = "", unref_function = "")]
	public class ExposeEvent : GenericEvent {
		public uint16 sequence;
		public Window window;
		public uint16 x;
		public uint16 y;
		public uint16 width;
		public uint16 height;
		public uint16 count;
	}

	[Compact]
	[CCode (cname = "xcb_enter_notify_event_t", ref_function = "", unref_function = "")]
	public class EnterNotifyEvent : GenericEvent {
		public uint8 detail;
		public uint16 sequence;
		public Timestamp time;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
		public uint16 state;
		public uint8 mode;
		public uint8 same_screen_focus;
	}

	[Compact]
	[CCode (cname = "xcb_leave_notify_event_t", ref_function = "", unref_function = "")]
	public class LeaveNotifyEvent : GenericEvent {
		public uint8 detail;
		public uint16 sequence;
		public Timestamp time;
		public Window root;
		public Window event;
		public Window child;
		public uint16 root_x;
		public uint16 root_y;
		public uint16 event_x;
		public uint16 event_y;
		public uint16 state;
		public uint8 mode;
		public uint8 same_screen_focus;
	}

	[Compact]
	[CCode (cname = "xcb_keymap_notify_event_t", ref_function = "", unref_function = "")]
	public class KeymapNotifyEvent : GenericEvent {
		public uint8[] keys;
	}

	[Compact]
	[CCode (cname = "xcb_visibility_notify_event_t", ref_function = "", unref_function = "")]
	public class VisibilityNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window window;
		public uint8 state;
	}

	[Compact]
	[CCode (cname = "xcb_create_notify_event_t", ref_function = "", unref_function = "")]
	public class CreateNotifyEvent {
		public uint8 response_type;
		public uint16 sequence;
		public Window parent;
		public Window window;
		public int16 x;
		public int16 y;
		public uint16 width;
		public uint16 height;
		public uint16 border_width;
		public uint8 override_redirect;
	}

	[Compact]
	[CCode (cname = "xcb_destroy_notify_event_t", ref_function = "", unref_function = "")]
	public class DestroyNotifyEvent {
		public uint8 response_type;
		public uint16 sequence;
		public Window event;
		public Window window;
	}

	[Compact]
	[CCode (cname = "xcb_unmap_notify_event_t", ref_function = "", unref_function = "")]
	public class UnmapNotifyEvent {
		public uint8 response_type;
		public uint16 sequence;
		public Window event;
		public Window window;
		public uint8 from_configure;
	}

	[Compact]
	[CCode (cname = "xcb_map_notify_event_t", ref_function = "", unref_function = "")]
	public class MapNotifyEvent {
		public uint8 response_type;
		public uint16 sequence;
		public Window event;
		public Window window;
		public uint8 override_redirect;
	}

	[Compact]
	[CCode (cname = "xcb_map_request_event_t", ref_function = "", unref_function = "")]
	public class MapRequestEvent {
		public uint8 response_type;
		public uint16 sequence;
		public Window parent;
		public Window window;
	}

	[Compact]
	[CCode (cname = "xcb_reparent_notify_event_t", ref_function = "", unref_function = "")]
	public class ReparentNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window event;
		public Window window;
		public Window parent;
		public int16 x;
		public int16 y;
		public uint8 override_redirect;
	}

	[Compact]
	[CCode (cname = "xcb_configure_request_event_t", ref_function = "", unref_function = "")]
	public class ConfigureRequestEvent {
		public uint8 response_type;
		public uint8 stack_mode;
		public uint16 sequence;
		public Window parent;
		public Window window;
		public Window sibling;
		public int16 x;
		public int16 y;
		public uint16 width;
		public uint16 height;
		public uint16 border_width;
		public uint16 value_mask;
	}

	[Compact]
	[CCode (cname = "xcb_configure_notify_event_t", ref_function = "", unref_function = "")]
	public class ConfigureNotifyEvent {
		public uint8      response_type;
		public uint16     sequence;
		public Window     event;
		public Window     window;
		public Window     above_sibling;
		public int16      x;
		public int16      y;
		public uint16     width;
		public uint16     height;
		public uint16     border_width;
		public uint8      override_redirect;
	}

	[Compact]
	[CCode (cname = "xcb_gravity_notify_event_t", ref_function = "", unref_function = "")]
	public class GravityNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window event;
		public Window window;
		public int16 x;
		public int16 y;
	}

	[Compact]
	[CCode (cname = "xcb_circulate_notify_event_t", ref_function = "", unref_function = "")]
	public class CirculateNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window event;
		public Window window;
		public uint8 place;
	}

	[Compact]
	[CCode (cname = "xcb_property_notify_event_t", ref_function = "", unref_function = "")]
	public class PropertyNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window window;
		public AtomT atom;
		public Timestamp time;
		public uint8 state;
	}

	[Compact]
	[CCode (cname = "xcb_selection_notify_event_t", ref_function = "", unref_function = "")]
	public class SelectionNotifyEvent : GenericEvent {
		uint16 sequence;
		public Timestamp time;
		public Window requestor;
		public AtomT selection;
		public AtomT target;
		public AtomT property;
	}

	[Compact]
	[CCode (cname = "xcb_colormap_notify_event_t", ref_function = "", unref_function = "")]
	public class ColormapNotifyEvent : GenericEvent {
		uint16 sequence;
		public Window window;
		public Colormap colormap;
		public uint8 _new;
		public uint8 state;
	}

	[Compact]
	[CCode (cname = "xcb_mapping_notify_event_t", ref_function = "", unref_function = "")]
	public class MappingNotifyEvent : GenericEvent {
		uint16 sequence;
		public uint8 request;
		public Keycode first_keycode;
		public uint8 count;
	}

	[CCode (cname = "xcb_cw_t", has_type_id = false)]
	public enum CW {
		BACK_PIXMAP,
		BACK_PIXEL,
		BORDER_PIXMAP,
		BORDER_PIXEL,
		BIT_GRAVITY,
		WIN_GRAVITY,
		BACKING_STORE,
		BACKING_PLANES,
		BACKING_PIXEL,
		OVERRIDE_REDIRECT,
		SAVE_UNDER,
		EVENT_MASK,
		DONT_PROPAGATE,
		COLORMAP,
		CURSOR
	}

	[CCode (cname = "xcb_event_mask_t", has_type_id = false)]
	public enum EventMask {
		NO_EVENT,
		KEY_PRESS,
		KEY_RELEASE,
		BUTTON_PRESS,
		BUTTON_RELEASE,
		ENTER_WINDOW,
		LEAVE_WINDOW,
		POINTER_MOTION,
		POINTER_MOTION_HINT,
		BUTTON_1_MOTION,
		BUTTON_2_MOTION,
		BUTTON_3_MOTION,
		BUTTON_4_MOTION,
		BUTTON_5_MOTION,
		BUTTON_MOTION,
		KEYMAP_STATE,
		EXPOSURE,
		VISIBILITY_CHANGE,
		STRUCTURE_NOTIFY,
		RESIZE_REDIRECT,
		SUBSTRUCTURE_NOTIFY,
		SUBSTRUCTURE_REDIRECT,
		FOCUS_CHANGE,
		PROPERTY_CHANGE,
		COLOR_MAP_CHANGE,
		OWNER_GRAB_BUTTON
	}

	[SimpleType]
	[CCode (cname = "xcb_format_t", has_type_id = false)]
	public struct Format {
		public uint8 depth;
		public uint8 bits_per_pixel;
		public uint8 scanline_pad;
	}

	[SimpleType]
	[CCode (cname = "xcb_format_iterator_t", has_type_id = false)]
	private struct FormatIterator {
		public unowned Format data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_format_next")]
		public static void next (ref FormatIterator iter);
	}

	[Compact]
	[CCode (cname = "xcb_screen_t", ref_function = "", unref_function = "")]
	public class Screen {
		public Window root;
		public Colormap default_colormap;
		public uint32 white_pixel;
		public uint32 black_pixel;
		public uint32 current_input_masks;
		public uint16 width_in_pixels;
		public uint16 height_in_pixels;
		public uint16 width_in_millimeters;
		public uint16 height_in_millimeters;
		public uint16 min_installed_maps;
		public uint16 max_installed_maps;
		public VisualID root_visual;
		public uint8 backing_stores;
		public uint8 save_unders;
		public uint8 root_depth;
		private uint8 allowed_depths_len;
		public DepthIterator allowed_depths_iterator ();
		public Depth[] allowed_depths
		{
			owned get
			{
				var value = new Depth[allowed_depths_len];
				var iter = allowed_depths_iterator ();
				for (var i = 0; i < value.length; i++)
				{
					value[i] = iter.data;
					DepthIterator.next (ref iter);
				}
				return value;
			}
		}
	}

	[SimpleType]
	[CCode (cname = "xcb_screen_iterator_t", has_type_id = false)]
	public struct ScreenIterator {
		public unowned Screen data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_screen_next")]
		public static void next (ref ScreenIterator iter);
	}

	[Compact]
	[CCode (cname = "xcb_depth_t", ref_function = "", unref_function = "")]
	public class Depth {
		public uint8 depth;
		private uint16 visuals_len;
		[CCode (cname = "xcb_depth_visuals")]
		private VisualType* vala_visuals ();
		public VisualType[] visuals
		{
			get {
				unowned VisualType[] res = (VisualType[]) vala_visuals ();
				res.length = (int) visuals_len;
				return res;
			}
		}
		[Version (deprecated_since = "vala-0.26", replacement = "Xcb.Depth.visuals")]
		public VisualTypeIterator visuals_iterator ();
	}

	[Compact]
	[CCode (cname = "xcb_query_tree_reply_t", ref_function = "", unref_function = "")]
	public class QueryTreeReply {
		public Window root;
		public Window parent;
		public uint16 children_len;
		[CCode (cname = "xcb_query_tree_children", array_length = false)]
		public Window* children ();
	}

	[SimpleType]
	[CCode (cname = "xcb_depth_iterator_t", has_type_id = false)]
	public struct DepthIterator {
		public unowned Depth data;
		public int rem;
		[CCode (cname = "xcb_depth_next")]
		public static void next (ref DepthIterator iter);
	}

	[Version (deprecated_since = "vala-0.26", replacement = "Xcb.Depth.visuals")]
	[SimpleType]
	[CCode (cname = "xcb_visualtype_iterator_t", has_type_id = false)]
	public struct VisualTypeIterator {
		public unowned VisualType data;
		public int rem;
		[CCode (cname = "xcb_visualtype_next")]
		public static void next (ref VisualTypeIterator iter);
	}

	[Version (deprecated_since = "vala-0.14", replacement = "Xcb.Connection")]
	public Connection connect (string? display = null, out int screen = null);
	[Version (deprecated_since = "vala-0.14", replacement = "Xcb.Connection.create_window")]
	public VoidCookie create_window (Connection connection, uint8 depth, Window wid, Window parent, int16 x, int16 y, uint16 width, uint16 height, uint16 border_width, uint16 _class, VisualID visual, uint32 value_mask, [CCode (array_length = false)] uint32[] value_list);
	[Version (deprecated_since = "vala-0.14", replacement = "Xcb.Connection.map_window")]
	public VoidCookie map_window (Connection connection, Window wid);

	[SimpleType]
	[CCode (cname = "xcb_void_cookie_t", has_type_id = false)]
	public struct VoidCookie {
	}

	[SimpleType]
	[CCode (cname = "xcb_query_tree_cookie_t", has_type_id = false)]
	public struct QueryTreeCookie {
	}

	[CCode (cname = "xcb_point_t", has_type_id = false)]
	public struct Point {
		public int16 x;
		public int16 y;
	}

	[CCode (cname = "xcb_rectangle_t", has_type_id = false)]
	public struct Rectangle {
		public int16 x;
		public int16 y;
		public uint16 width;
		public uint16 height;
	}

	[CCode (cname = "xcb_arc_t", has_type_id = false)]
	public struct Arc {
		public int16 x;
		public int16 y;
		public uint16 width;
		public uint16 height;
		public int16 angle1;
		public int16 angle2;
	}

	[CCode (cname = "xcb_segment_t", has_type_id = false)]
	public struct Segment {
		public int16 x1;
		public int16 y1;
		public int16 x2;
		public int16 y2;
	}

	[SimpleType]
	[CCode (cname = "xcb_visualid_t", has_type_id = false)]
	public struct VisualID : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_button_t", has_type_id = false)]
	public struct Button : uint8 {
	}

	[SimpleType]
	[CCode (cname = "xcb_gcontext_t", has_type_id = false)]
	public struct GContext : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_drawable_t", has_type_id = false)]
	public struct Drawable : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_pixmap_t", has_type_id = false)]
	public struct Pixmap : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_cursor_t", has_type_id = false)]
	public struct Cursor : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_font_t", has_type_id = false)]
	public struct Font : uint32 {
	}

	[SimpleType]
	[CCode (cname = "xcb_window_t", has_type_id = false)]
	public struct Window : uint32 {
	}

	[CCode (cname = "xcb_visual_class_t", has_type_id = false)]
	public enum VisualClass {
		STATIC_GRAY,
		GRAY_SCALE,
		STATIC_COLOR,
		PSEUDO_COLOR,
		TRUE_COLOR,
		DIRECT_COLOR
	}

	[SimpleType]
	[CCode (cname = "xcb_visualtype_t", has_type_id = false)]
	public struct VisualType {
		public VisualID visual_id;
		public uint8 _class;
		public uint8 bits_per_rgb_value;
		public uint16 colormap_entries;
		public uint32 red_mask;
		public uint32 green_mask;
		public uint32 blue_mask;
	}

	[CCode (cname = "xcb_input_focus_t", has_type_id = false)]
	public enum InputFocus {
		NONE,
		POINTER_ROOT,
		PARENT,
		FOLLOW_KEYBOARD
	}

	[CCode (cname = "xcb_font_draw_t", has_type_id = false)]
	public enum FontDraw {
		LEFT_TO_RIGHT,
		RIGHT_TO_LEFT
	}

	[CCode (cname = "xcb_gc_t", has_type_id = false)]
	public enum GC
	{
		FUNCTION,
		PLANE_MASK,
		FOREGROUND,
		BACKGROUND,
		LINE_WIDTH,
		LINE_STYLE,
		CAP_STYLE,
		JOIN_STYLE,
		FILL_STYLE,
		FILL_RULE,
		TILE,
		STIPPLE,
		TILE_STIPPLE_ORIGIN_X,
		TILE_STIPPLE_ORIGIN_Y,
		FONT,
		SUBWINDOW_MODE,
		GRAPHICS_EXPOSURES,
		CLIP_ORIGIN_X,
		CLIP_ORIGIN_Y,
		CLIP_MASK,
		DASH_OFFSET,
		DASH_LIST,
		ARC_MODE
	}

	[CCode (cname = "xcb_gx_t", has_type_id = false)]
	public enum GX
	{
		CLEAR,
		AND,
		AND_REVERSE,
		COPY,
		AND_INVERTED,
		NOOP,
		XOR,
		OR,
		NOR,
		EQUIV,
		INVERT,
		OR_REVERSE,
		COPY_INVERTED,
		OR_INVERTED,
		NAND,
		SET
	}

	[CCode (cname = "xcb_line_style_t", has_type_id = false)]
	public enum LineStyle
	{
		SOLID,
		ON_OFF_DASH,
		DOUBLE_DASH
	}

	[CCode (cname = "xcb_cap_style_t", has_type_id = false)]
	public enum CapStyle
	{
		NOT_LAST,
		BUTT,
		ROUND,
		PROJECTING
	}

	[CCode (cname = "xcb_join_style_t", has_type_id = false)]
	public enum JoinStyle
	{
		MITER,
		ROUND,
		BEVEL
	}

	[CCode (cname = "xcb_fill_style_t", has_type_id = false)]
	public enum FillStyle
	{
		SOLID,
		TILED,
		STIPPLED,
		OPAQUE_STIPPLED
	}

	[CCode (cname = "xcb_fill_rule_t", has_type_id = false)]
	public enum FillRuleStyle
	{
		EVEN_ODD,
		WINDING
	}

	[CCode (cname = "xcb_subwindow_mode_t", has_type_id = false)]
	public enum SubwindowMode
	{
		CLIP_BY_CHILDREN,
		INCLUDE_INFERIORS
	}

	[CCode (cname = "xcb_arc_mode_t", has_type_id = false)]
	public enum ArcMode
	{
		CHORD,
		PIE_SLICE
	}

	[CCode (cname = "xcb_clip_ordering_t", has_type_id = false)]
	public enum ClipOrdering
	{
		UNSORTED,
		Y_SORTED,
		YX_SORTED,
		YX_BANDED
	}

	[CCode (cname = "xcb_coord_mode_t", has_type_id = false)]
	public enum CoordMode
	{
		ORIGIN,
		PREVIOUS
	}

	[CCode (cname = "xcb_poly_shape_t", has_type_id = false)]
	public enum PolyShape
	{
		COMPLEX,
		NONCONVEX,
		CONVEX
	}

	[CCode (cname = "xcb_image_format_t", has_type_id = false)]
	public enum ImageFormat
	{
		XY_BITMAP,
		XY_PIXMAP,
		Z_PIXMAP
	}

	[CCode (cname = "xcb_color_flag_t", has_type_id = false)]
	public enum ColorFlag
	{
		RED,
		GREEN,
		BLUE
	}

	[SimpleType]
	[CCode (cname = "xcb_coloritem_t", has_type_id = false)]
	public struct Coloritem {
		public uint32 pixel;
		public uint16 red;
		public uint16 green;
		public uint16 blue;
		public ColorFlag flags;
	}

	[SimpleType]
	[CCode (cname = "xcb_rgb_t", has_type_id = false)]
	public struct RGB {
		public uint16 red;
		public uint16 green;
		public uint16 blue;
	}

	[CCode (cname = "xcb_set_mode_t", has_type_id = false)]
	public enum SetMode
	{
		INSERT,
		DELETE
	}

	[CCode (cname = "xcb_host_mode_t", has_type_id = false)]
	public enum HostMode
	{
		INSERT,
		DELETE
	}

	[CCode (cname = "xcb_family_t", has_type_id = false)]
	public enum Family
	{
		INTERNET,
		DECNET,
		CHAOS,
		SERVER_INTERPRETED,
		INTERNET_6
	}

	[CCode (cname = "xcb_access_control_t", has_type_id = false)]
	public enum AccessControl
	{
		DISABLE,
		ENABLE
	}

	[CCode (cname = "xcb_close_down_t", has_type_id = false)]
	public enum CloseDown
	{
		DESTROY_ALL,
		RETAIN_PERMANENT,
		RETAIN_TEMPORARY
	}

	[CCode (cname = "xcb_screen_saver_t", has_type_id = false)]
	public enum ScreenSaver
	{
		RESET,
		ACTIVE
	}

	[Compact]
	[CCode (cname = "xcb_str_t", ref_function = "", unref_function = "")]
	private class Str {
		private uint8 name_len;
		[CCode (cname = "xcb_str_name")]
		private unowned string vala_name ();
		public string name { owned get { return "%.*s".printf (name_len, vala_name ()); } }
	}

	[SimpleType]
	[CCode (cname = "xcb_str_iterator_t", has_type_id = false)]
	private struct StrIterator {
		public unowned Str data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_str_next")]
		public static void next (ref StrIterator iter);
	}

	[Compact]
	[CCode (cname = "xcb_host_t", ref_function = "", unref_function = "")]
	public class Host {
		public Family family;
		private uint16 address_len;
		[CCode (cname = "xcb_host_address")]
		public unowned uint8* vala_address ();
		public uint8[] address
		{
			get
			{
				unowned uint8[] res = (uint8[]) vala_address ();
				res.length = address_len;
				return res;
			}
		}
	}

	[SimpleType]
	[CCode (cname = "xcb_host_iterator_t", has_type_id = false)]
	private struct HostIterator {
		public unowned Host data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_host_next")]
		public static void next (ref HostIterator iter);
	}

	[SimpleType]
	[CCode (cname = "xcb_fontprop_t", has_type_id = false)]
	public struct Fontprop {
		public AtomT name;
		public uint32 value;
	}

	[Compact]
	[CCode (cname = "xcb_fontprop_t", ref_function = "", unref_function = "")]
	public class Charinfo {
		public int16 left_side_bearing;
		public int16 right_side_bearing;
		public int16 character_width;
		public int16 ascent;
		public int16 descent;
		public uint16 attributes;
	}

	[SimpleType]
	[CCode (cname = "xcb_fontprop_iterator_t", has_type_id = false)]
	private struct FontpropIterator {
		public unowned Fontprop data;
		public int rem;
		public int index;
		[CCode (cname = "xcb_fontprop_next")]
		public static void next (ref FontpropIterator iter);
	}
}
