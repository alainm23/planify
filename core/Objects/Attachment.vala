/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Objects.Attachment : GLib.Object {
    public string id { get; set; default = ""; }
    public string item_id { get; set; default = ""; }
    public string file_type { get; set; default = ""; }
    public string file_name { get; set; default = ""; }
    public int64 file_size { get; set; default = 0; }
    public string file_path { get; set; default = ""; }

    public signal void deleted ();
    
    Objects.Item? _item;
    public Objects.Item item {
        get {
            _item = Services.Store.instance ().get_item (item_id);
            return _item;
        }

        set {
            _item = value;
        }
    }
    
    public string to_string () {       
        return """
        _________________________________
            ID: %s
            ITEM ID: %s
            FILE TYPE: %s
            FILE NAME: %s
            FILE SIZE: %s
            FILE PATH: %s
        ---------------------------------
        """.printf (
            id,
            item_id,
            file_type,
            file_name,
            file_size.to_string (),
            file_path
        );
    }

    public void delete () {
        Services.Store.instance ().delete_attachment (this);
    }

    public Objects.Attachment duplicate () {
        var new_attachment = new Objects.Attachment ();
        new_attachment.file_type = file_type;
        new_attachment.file_name = file_name;
        new_attachment.file_size = file_size;
        new_attachment.file_path = file_path;

        return new_attachment;
    }
}
