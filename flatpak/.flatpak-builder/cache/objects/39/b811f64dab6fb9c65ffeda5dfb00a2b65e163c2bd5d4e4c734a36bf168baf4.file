/* xcb-icccm.vapi
 *
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
 * Author:
 *  Sergio Costas <raster@rastersoft.com>
 */

using Xcb;

[Version (deprecated_since = "vala-0.26", replacement = "bindings distributed with vala-extra-vapis")]
namespace Xcb {

	[CCode (lower_case_cprefix = "xcb_icccm_", cheader_filename = "xcb/xcb_icccm.h")]
	namespace Icccm {

		/**
		 * A factory method that creates an Icccm object. It allows to call the Xcb Icccm methods
		 * @param conn The current Xcb connection
		 * @return the new Icccm object
		 */
		public static Icccm new(Xcb.Connection conn) {
			unowned Xcb.Icccm.Icccm retval = (Xcb.Icccm.Icccm)conn;
			return retval;
		}

		// The Icccm class is, in fact, a Xcb.Connection class in disguise
		[Compact, CCode (cname = "xcb_connection_t", cprefix = "xcb_icccm_")]
		public class Icccm : Xcb.Connection {
			public GetPropertyCookie get_wm_class(Window window);
			public GetPropertyCookie get_wm_class_unchecked(Window window);
		}

		[SimpleType]
		[CCode (cname = "xcb_icccm_get_wm_class_reply_t", has_type_id = false)]
		public struct GetWmClassFromReply {
			unowned string instance_name;
			unowned string class_name;
		}

		public void get_wm_class_from_reply(out GetWmClassFromReply reply, GetPropertyReply input);
	}
}
