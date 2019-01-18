/* markupwriter.vala
 *
 * Copyright (C) 2008-2009 Florian Brosch
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
 * 	Florian Brosch <flo.brosch@gmail.com>
 */

function get_path (path) {
	var pos = path.lastIndexOf ('/');
	if (pos < 0) {
		return '';
	}

	return path.substring (pos, -1) + '/';
}

function toggle_box (self, id) {
	var element = document.getElementById (id);
	if (element == null) {
		return ;
	}

	var style = self.currentStyle || window.getComputedStyle (self, false);
	var orig_path = /url[ \t]*\(('(.*)'|"(.*)")\)/.exec (style.backgroundImage)[1].slice(1, -1);
	var orig_dir = get_path (orig_path);
	if (element.style.display == 'block') {
		element.style.display = 'none';
		self.style.backgroundImage = "url('" + orig_dir + 'coll_open.png' + "')";
	} else {
		element.style.display = 'block';
		self.style.backgroundImage = "url('" + orig_dir + 'coll_close.png' + "')";
	}
}

