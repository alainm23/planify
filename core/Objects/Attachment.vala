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
    public string file_size { get; set; default = ""; }
    public string file_path { get; set; default = ""; }

    public signal void deleted ();

    Objects.Item ? _item;
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
            file_size,
            file_path
        );
    }

    public static string get_storage_dir () {
        return Path.build_filename (Environment.get_user_data_dir (), "io.github.alainm23.planify", "attachments");
    }

    // Builds an attachment for file (item_id still to be set), keeping a copy in the attachments folder.
    // Links the original file if the copy fails. Returns null if the file can't be read.
    public static async Objects.Attachment ? from_file (File file) {
        var attachment = new Objects.Attachment ();

        try {
            var file_info = file.query_info ("standard::size,standard::content-type", 0);
            var file_content_type = file_info.get_content_type ();
            if (file_content_type == null) {
                return null;
            }

            attachment.id = Util.get_default ().generate_id ();
            attachment.file_size = file_info.get_size ().to_string ();
            attachment.file_type = file_content_type.down ();
            attachment.file_name = file.get_basename ();
            attachment.file_path = file.get_uri ();
        } catch (Error e) {
            warning (e.message);
            return null;
        }

        try {
            var stored_file = yield store_copy (file, attachment.id);
            attachment.file_path = stored_file.get_uri ();
        } catch (Error e) {
            warning ("Couldn't copy attachment, linking the original file instead: %s", e.message);
        }

        return attachment;
    }

    // Keeps a copy in Planify's data folder so the attachment still opens if the original is moved or deleted
    private static async File store_copy (File file, string attachment_id) throws Error {
        var dir = File.new_for_path (Path.build_filename (get_storage_dir (), attachment_id));
        dir.make_directory_with_parents ();

        var destination = dir.get_child (file.get_basename ());
        try {
            yield file.copy_async (destination, FileCopyFlags.NONE, Priority.DEFAULT, null, null);
        } catch (Error e) {
            // Don't leave a partial copy behind (e.g. disk full)
            try {
                destination.delete ();
            } catch (Error ignored) {}

            try {
                dir.delete ();
            } catch (Error ignored) {}

            throw e;
        }

        return destination;
    }

    public void delete () {
        Services.Store.instance ().delete_attachment (this);
        delete_stored_copy ();
    }

    // Removes the copy kept in the attachments folder, unless another attachment (e.g. from a duplicated task) still uses it
    public void delete_stored_copy () {
        var file = File.new_for_uri (file_path);
        if (!file.has_prefix (File.new_for_path (get_storage_dir ()))) {
            return;
        }

        foreach (Objects.Attachment attachment in Services.Store.instance ().attachments) {
            if (attachment.file_path == file_path) {
                return;
            }
        }

        try {
            file.delete ();
            file.get_parent ().delete ();
        } catch (Error e) {
            warning (e.message);
        }
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
