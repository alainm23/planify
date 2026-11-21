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
 * CLI Test Runner
 * 
 * Main test runner that orchestrates all CLI component tests.
 * Each component has its own test file in test/cli/ directory.
 */
 
async void test_caldav_login_async () throws GLib.Error {
    string? server_url = Environment.get_variable ("CALDAV_URL");
    string? username = Environment.get_variable ("CALDAV_USER");
    string? password = Environment.get_variable ("CALDAV_PASS");

    if (server_url == null || username == null || password == null) {
        message ("Skipping CalDAV login test: missing environment variables.");
        return;
    }

    var cancellable = new GLib.Cancellable ();

    var core = Services.CalDAV.Core.get_default ();
    core.clear ();


    var dav_endpoint = yield core.resolve_well_known_caldav (new Soup.Session (), server_url);

    assert (dav_endpoint != null && dav_endpoint != "");
    assert (Uri.parse_scheme (dav_endpoint) != null);

    message ("Using DAV Endpoint: %s", dav_endpoint);

    var calendar_home = yield core.resolve_calendar_home (CalDAVType.GENERIC, dav_endpoint, username, password, cancellable);

    assert (calendar_home != null && calendar_home != "");
    assert (Uri.parse_scheme (calendar_home) != null);

    message ("Calendar Home: %s", calendar_home);

    HttpResponse response = yield core.login (CalDAVType.GENERIC, dav_endpoint, username, password, calendar_home, cancellable);

    assert (response.status);
    message ("Login successful");
}

void test_caldav_login () {
    var loop = new MainLoop ();
    test_caldav_login_async.begin ((obj, res) => {
        test_caldav_login_async.end (res);
        loop.quit ();
    });
    loop.run ();
}


/*
 * Tasks in a section point at the section's entry with RELATED-TO. The server returns
 * entries in no particular order, so a task can come before its section, both on the
 * first sync of a list and on later ones (#2816).
 */
const int SECTION_TASKS = 8;

async void put_vtodo (Soup.Session session, string auth, string url, string uid, string summary, string? related_to) throws GLib.Error {
    var body = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Planify Tests//EN\r\nBEGIN:VTODO\r\n" +
        "UID:%s\r\nDTSTAMP:20260101T000000Z\r\nSUMMARY:%s\r\n".printf (uid, summary) +
        (related_to != null ? "RELATED-TO:%s\r\n".printf (related_to) : "") +
        "END:VTODO\r\nEND:VCALENDAR\r\n";

    var msg = new Soup.Message ("PUT", url + uid + ".ics");
    msg.request_headers.append ("Authorization", auth);
    msg.set_request_body_from_bytes ("text/calendar", new Bytes (body.data));
    yield session.send_and_read_async (msg, Priority.DEFAULT, null);
    assert (msg.status_code == Soup.Status.CREATED);
}

async void put_section_with_tasks (Soup.Session session, string auth, string url, string section_uid) throws GLib.Error {
    // Planify keeps sections as tasks named "List : <name>"
    yield put_vtodo (session, auth, url, section_uid, "List : " + section_uid, null);
    for (int i = 0; i < SECTION_TASKS; i++) {
        yield put_vtodo (session, auth, url, "%s-task-%d".printf (section_uid, i), "Task %d".printf (i), section_uid);
    }
}

void assert_tasks_in_section (Objects.Project project, string section_uid) {
    assert (Services.Store.instance ().get_section (section_uid) != null);

    int found = 0;
    foreach (var item in Services.Store.instance ().get_items_by_project (project)) {
        if (item.id.has_prefix (section_uid + "-task-")) {
            assert_cmpstr (item.section_id, CompareOperator.EQ, section_uid);
            assert_cmpstr (item.parent_id, CompareOperator.EQ, "");
            found++;
        }
    }

    assert_cmpint (found, CompareOperator.EQ, SECTION_TASKS);
}

async void test_caldav_section_order_async () throws GLib.Error {
    string? server_url = Environment.get_variable ("CALDAV_URL");
    string? username = Environment.get_variable ("CALDAV_USER");
    string? password = Environment.get_variable ("CALDAV_PASS");

    if (server_url == null || username == null || password == null) {
        message ("Skipping CalDAV section order test: missing environment variables.");
        return;
    }

    // Keep the test's database away from the user's own one.
    string data_home = Environment.get_variable ("XDG_DATA_HOME");
    if (data_home == null || !data_home.has_suffix ("/test-caldav-data")) {
        error ("XDG_DATA_HOME must point at the test-caldav-data scratch dir");
    }
    string app_dir = data_home + "/io.github.alainm23.planify";
    DirUtils.create_with_parents (app_dir, 0700);
    FileUtils.remove (app_dir + "/database.db");
    Services.Database.get_default ().init_database ();

    var cancellable = new GLib.Cancellable ();
    var session = new Soup.Session ();
    var core = Services.CalDAV.Core.get_default ();

    var dav_endpoint = yield core.resolve_well_known_caldav (session, server_url);
    var calendar_home = yield core.resolve_calendar_home (CalDAVType.GENERIC, dav_endpoint, username, password, cancellable);
    if (!calendar_home.has_suffix ("/")) {
        calendar_home += "/";
    }

    var auth = "Basic " + Base64.encode ("%s:%s".printf (username, password).data);
    var calendar_url = calendar_home + "section-order-%s/".printf (Uuid.string_random ());

    var mkcalendar = new Soup.Message ("MKCALENDAR", calendar_url);
    mkcalendar.request_headers.append ("Authorization", auth);
    mkcalendar.set_request_body_from_bytes ("application/xml", new Bytes ("""<?xml version="1.0" encoding="utf-8"?>
        <c:mkcalendar xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
            <d:set><d:prop>
                <d:displayname>Section order</d:displayname>
                <c:supported-calendar-component-set><c:comp name="VTODO"/></c:supported-calendar-component-set>
            </d:prop></d:set>
        </c:mkcalendar>""".data));
    yield session.send_and_read_async (mkcalendar, Priority.DEFAULT, null);
    assert (mkcalendar.status_code == Soup.Status.CREATED);

    GLib.Error? failure = null;
    try {
        yield check_section_order (session, auth, dav_endpoint, calendar_home, calendar_url, username, password, cancellable);
    } catch (GLib.Error e) {
        failure = e;
    }

    var delete_msg = new Soup.Message ("DELETE", calendar_url);
    delete_msg.request_headers.append ("Authorization", auth);
    yield session.send_and_read_async (delete_msg, Priority.DEFAULT, null);

    if (failure != null) {
        throw failure;
    }
}

async void check_section_order (Soup.Session session, string auth, string dav_endpoint, string calendar_home,
                                 string calendar_url, string username, string password,
                                 GLib.Cancellable cancellable) throws GLib.Error {
    yield put_section_with_tasks (session, auth, calendar_url, "first-sync-section");

    var source = new Objects.Source ();
    source.id = "section-order-source";
    source.source_type = SourceType.CALDAV;
    var caldav_data = new Objects.SourceCalDAVData ();
    caldav_data.server_url = dav_endpoint;
    caldav_data.calendar_home_url = calendar_home;
    caldav_data.username = username;
    caldav_data.password = password;
    caldav_data.caldav_type = CalDAVType.GENERIC;
    source.data = caldav_data;
    Services.Store.instance ().insert_source (source);

    var client = new Services.CalDAV.CalDAVClient (session, dav_endpoint, username, password);

    // Section.CALDAV_PREFIX is set when the class is first used, as the app has done by now.
    typeof (Objects.Section).class_ref ();

    Objects.Project? project = null;
    foreach (var candidate in yield client.fetch_project_list (source, cancellable)) {
        if (candidate.calendar_url == calendar_url) {
            project = candidate;
        }
    }
    assert (project != null);
    Services.Store.instance ().insert_project (project);

    // First sync of the list
    yield client.fetch_items_for_project (project, cancellable);
    assert_tasks_in_section (project, "first-sync-section");

    // A section and its tasks added on another device, picked up by a later sync
    yield put_section_with_tasks (session, auth, calendar_url, "later-sync-section");
    yield client.sync_tasklist (project, cancellable);
    assert_tasks_in_section (project, "later-sync-section");
}

void test_caldav_section_order () {
    var loop = new MainLoop ();
    test_caldav_section_order_async.begin ((obj, res) => {
        try {
            test_caldav_section_order_async.end (res);
        } catch (Error e) {
            error ("%s", e.message);
        }
        loop.quit ();
    });
    loop.run ();
}


int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/caldav/login", test_caldav_login);
    Test.add_func ("/caldav/section-order", test_caldav_section_order);
    return Test.run ();
}

