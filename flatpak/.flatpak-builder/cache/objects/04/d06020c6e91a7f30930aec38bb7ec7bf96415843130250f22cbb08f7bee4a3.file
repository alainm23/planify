/* cairo-xcb.vala
 *
 * Copyright (C) 2009  Jürg Billeter
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

[Version (deprecated_since = "vala-0.26", replacement = "bindings distributed with vala-extra-vapis")]
namespace Cairo {
	[Compact]
	[CCode (cname = "cairo_surface_t", cheader_filename = "cairo-xcb.h")]
	public class XcbSurface : Surface {
		[CCode (cname = "cairo_xcb_surface_create")]
		public XcbSurface (Xcb.Connection connection, Xcb.Drawable drawable, Xcb.VisualType visual, int width, int height);
		public void set_size (int width, int height);
	}
}
