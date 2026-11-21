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

/**

/**
 * CalDAV Sync Failure Tests: a failed sync must not leave a project stuck in its syncing state.
 */

namespace Planify.Tests.CalDAVSyncFailure {
    private async bool sync_unreachable_project (Objects.Project project) {
        // Nothing listens on port 1, so the first request fails right away.
        var client = new Services.CalDAV.CalDAVClient (new Soup.Session (), "http://127.0.0.1:1/", "user", "password");

        try {
            yield client.sync_tasklist (project, new GLib.Cancellable ());
        } catch (Error e) {
            return true;
        }

        return false;
    }

    private void test_failed_sync_clears_project_state () {
        var project = new Objects.Project ();
        project.name = "Unreachable";
        project.calendar_url = "http://127.0.0.1:1/calendar/";
        project.sync_id = "http://example.org/sync/1";

        bool failed = false;
        var loop = new MainLoop ();
        sync_unreachable_project.begin (project, (obj, res) => {
            failed = sync_unreachable_project.end (res);
            loop.quit ();
        });
        loop.run ();

        assert_true (failed);
        assert_false (project.loading);
        assert_false (project.freeze_update);
    }

    public void register_tests () {
        Test.add_func ("/core/caldav_sync_failure/failed_sync_clears_project_state", test_failed_sync_clears_project_state);
    }
}
