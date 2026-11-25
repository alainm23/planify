/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 */

namespace Planify.Tests.ItemMemory {
    private Objects.Item make_item (string id) {
        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        return item;
    }

    private void test_deferred_extra_data_preserved_on_update () {
        ScratchDatabase.open ();
        var item = make_item ("deferred-details");
        item.extra_data = "{\"calendar-data\":\"payload\",\"etag\":\"v1\"}";
        assert_true (Services.Database.get_default ().insert_item (item));
        Objects.Item? deferred = null;
        foreach (var candidate in Services.Database.get_default ().get_items_collection (false)) {
            if (candidate.id == item.id) {
                deferred = candidate;
                break;
            }
        }
        assert_nonnull (deferred);
        deferred.content = "Edited without opening details";
        assert_true (Services.Database.get_default ().update_item (deferred));
        assert_cmpstr (Services.Database.get_default ().get_item_by_id (item.id).extra_data,
            CompareOperator.EQ, item.extra_data);
        deferred.defer_extra_data ();
        deferred.extra_data = "{\"etag\":\"v2\"}";
        assert_cmpstr (deferred.etag, CompareOperator.EQ, "v2");
    }

    private void test_streamed_backup () {
        ScratchDatabase.open ();
        var item = make_item ("streamed-backup");
        item.content = "A \"quoted\" task\nwith unicode: café";
        item.extra_data = "{\"calendar-data\":\"payload\"}";
        assert_true (Services.Database.get_default ().insert_item (item));
        var second = make_item ("streamed-backup-second");
        assert_true (Services.Database.get_default ().insert_item (second));
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (Services.BackupExporter.get_default ().export_to_json ());
            var root = parser.get_root ().get_object ();
            assert_true (root.has_member ("version"));
            assert_true (root.has_member ("sources"));
            assert_true (root.has_member ("projects"));
            bool found = false;
            foreach (var node in root.get_array_member ("items").get_elements ()) {
                var task = node.get_object ();
                if (task.get_string_member ("id") == item.id) {
                    assert_cmpstr (task.get_string_member ("content"), CompareOperator.EQ, item.content);
                    assert_cmpstr (task.get_string_member ("extra_data"), CompareOperator.EQ, item.extra_data);
                    found = true;
                }
            }
            assert_true (found);
        } catch (Error e) {
            error ("Backup must remain valid JSON: %s", e.message);
        }
    }

    public void register_tests () {
        Test.add_func ("/core/memory/deferred_details_preserved_on_update", test_deferred_extra_data_preserved_on_update);
        Test.add_func ("/core/memory/streamed_backup", test_streamed_backup);
    }
}
