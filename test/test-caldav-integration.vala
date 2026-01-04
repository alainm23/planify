using GLib;

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


int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/caldav/login", test_caldav_login);
    return Test.run ();
}

