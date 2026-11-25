/* Observational counterpart to the strict UI memory scenarios. The same UI
 * actions run on both revisions; retention/bounds failures are recorded so a
 * baseline can complete. Never use this target against a personal database. */
namespace PlanifyTransitionProfile {
    private int64 started;
    private string output_dir;
    private StringBuilder events;
    private int checked_widgets;

    private class Tracked : Object {
        public GLib.WeakRef reference;
        public string type_name;
        public Tracked (Gtk.Widget widget) {
            reference = GLib.WeakRef (widget);
            type_name = widget.get_type ().name ();
        }
    }

    private void pause (uint milliseconds) {
        var loop = new MainLoop ();
        Timeout.add (milliseconds, () => { loop.quit (); return Source.REMOVE; });
        loop.run ();
    }

    private Gtk.Widget? find (Gtk.Widget widget, Type kind) {
        if (widget.get_type ().is_a (kind)) return widget;
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            var result = find (child, kind);
            if (result != null) return result;
        }
        return null;
    }

    private void wait_for (Gtk.Widget widget, Type kind) {
        var deadline = get_monotonic_time () + 20 * TimeSpan.SECOND;
        while (find (widget, kind) == null && get_monotonic_time () < deadline) pause (25);
        assert_true (find (widget, kind) != null);
        pause (350);
    }

    private void collect (Gtk.Widget widget, Gee.ArrayList<Tracked> tracked) {
        tracked.add (new Tracked (widget));
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) collect (child, tracked);
    }

    private void release_check (Gee.ArrayList<Tracked> tracked) {
        // Fixed grace period on both revisions, independent of retention outcome.
        pause (5000);
        int retained = 0;
        var types = new Gee.HashMap<string, int> ();
        foreach (var entry in tracked) {
            if (entry.reference.get () != null) {
                retained++;
                types[entry.type_name] = types.has_key (entry.type_name) ? types[entry.type_name] + 1 : 1;
            }
        }
        foreach (var entry in types.entries) print ("RETAINED %s %d\n", entry.key, entry.value);
        checked_widgets += tracked.size;
        record ("release_sample", 0, retained);
        tracked.clear ();
    }

    private void record (string name, int cycle = 0, int value = 0) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("seconds");
        builder.add_double_value ((get_monotonic_time () - started) / 1000000.0);
        builder.set_member_name ("event");
        builder.add_string_value (name);
        builder.set_member_name ("cycle");
        builder.add_int_value (cycle);
        builder.set_member_name ("value");
        builder.add_int_value (value);
        builder.set_member_name ("checked_widgets");
        builder.add_int_value (checked_widgets);
        builder.end_object ();
        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        string line = generator.to_data (null);
        events.append (line + "\n");
        try { FileUtils.set_contents (output_dir + "/events.jsonl", events.str); }
        catch (Error e) { error ("Cannot record scenario: %s", e.message); }
        print ("%s\n", line);
        stdout.flush ();
    }

    private void select_view_style (Views.Project page, ProjectViewStyle style) {
        var toggles = (Adw.ToggleGroup) find (page, typeof (Adw.ToggleGroup));
        assert_nonnull (toggles);
        toggles.active_name = style.to_string ();
        assert_true (page.project.view_style == style);
        record ("layout_control", 0, (int) style);
    }

    private void rapid_views (MainWindow window) {
        var project = Services.Store.instance ().get_project ("synthetic-project-1");
        var inbox = Services.Store.instance ().get_project ("synthetic-inbox");
        assert_nonnull (project);
        record ("rapid_start");
        for (int cycle = 1; cycle <= 4; cycle++) {
            Views.Project? page = window.add_project_view (project);
            // Main retains this page and its control state across navigation.
            // Reset through the same real UI control on both revisions.
            select_view_style (page, ProjectViewStyle.LIST);
            wait_for (page, typeof (Views.List));
            foreach (var style in new ProjectViewStyle[] { ProjectViewStyle.BOARD, ProjectViewStyle.LIST }) {
                var tracked = new Gee.ArrayList<Tracked> ();
                var old_kind = style == ProjectViewStyle.BOARD ? typeof (Views.List) : typeof (Views.Board);
                collect (find (page, old_kind), tracked);
                // Three model changes inside one transition; only the last layout should be built.
                select_view_style (page, style);
                pause (40);
                select_view_style (page, style == ProjectViewStyle.BOARD ? ProjectViewStyle.LIST : ProjectViewStyle.BOARD);
                pause (40);
                select_view_style (page, style);
                wait_for (page, style == ProjectViewStyle.BOARD ? typeof (Views.Board) : typeof (Views.List));
                assert_true (find (page, old_kind) == null);
                record ("layout_ready", cycle, (int) style);
                release_check (tracked);
            }
            var tracked = new Gee.ArrayList<Tracked> ();
            collect (page, tracked);
            select_view_style (page, ProjectViewStyle.BOARD);
            pause (40);
            window.add_project_view (inbox);
            page = null;
            release_check (tracked);
            pause (500);
            record ("rapid_cycle_end", cycle);
        }
        pause (10000);
        record ("rapid_idle_end");
    }

    private Gtk.Box months (Widgets.Calendar.CalendarScroll calendar) {
        var overlay = (Gtk.Overlay) calendar.child;
        var content = ((Gtk.ScrolledWindow) overlay.child).child;
        if (content is Gtk.Viewport) content = ((Gtk.Viewport) content).child;
        return (Gtk.Box) content;
    }

    private int month_count (Widgets.Calendar.CalendarScroll calendar) {
        int count = 0;
        for (var child = months (calendar).get_first_child (); child != null; child = child.get_next_sibling ()) count++;
        return count;
    }

    private void calendar () {
        record ("calendar_start");
        var calendar = new Widgets.Calendar.CalendarScroll ();
        var window = new Gtk.Window () { child = calendar, default_width = 500, default_height = 700 };
        window.present ();
        pause (400);
        var first = GLib.WeakRef (months (calendar).get_first_child ());
        var scroller = (Gtk.ScrolledWindow) ((Gtk.Overlay) calendar.child).child;
        for (int i = 0; i < 60; i++) {
            // Old CalendarScroll observes adjustment changes; the PR also has
            // edge handlers. Drive both public surfaces identically.
            scroller.vadjustment.value = i < 30 ?
                double.max (0, scroller.vadjustment.upper - scroller.vadjustment.page_size) : 0;
            scroller.edge_reached (i < 30 ? Gtk.PositionType.BOTTOM : Gtk.PositionType.TOP);
            pause (25);
            record ("calendar_edge", i + 1, month_count (calendar));
        }
        var today = new DateTime.now_local ();
        foreach (int years in new int[] { 50, -50, 100, -100, 0 }) {
            calendar.date = today.add_years (years);
            pause (25);
            record ("calendar_date", years, month_count (calendar));
            assert_true (calendar.date.equal (today.add_years (years)));
        }
        record ("calendar_initial_month_retained", 0, first.get () != null ? 1 : 0);
        scroller = null;
        var tracked = new Gee.ArrayList<Tracked> ();
        collect (calendar, tracked);
        window.child = null;
        calendar = null;
        window.destroy ();
        window = null;
        release_check (tracked);
        record ("calendar_end", 0, 60);
    }

    private void collect_filters (Gtk.Widget widget, Type kind, Gee.ArrayList<Tracked> tracked) {
        if (widget.get_type ().is_a (kind)) { collect (widget, tracked); return; }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) collect_filters (child, kind, tracked);
    }

    private void sidebar (MainWindow window) {
        record ("sidebar_start");
        var sidebar = find (window, typeof (Layouts.Sidebar));
        var settings = Services.Settings.get_default ().settings;
        settings.set_boolean ("filters-list-view", true);
        wait_for (sidebar, typeof (Layouts.FilterPaneRow));
        for (int i = 0; i < 8; i++) {
            var old_kind = i % 2 == 0 ? typeof (Layouts.FilterPaneRow) : typeof (Layouts.FilterPaneChild);
            var tracked = new Gee.ArrayList<Tracked> ();
            collect_filters (sidebar, old_kind, tracked);
            settings.set_boolean ("filters-list-view", i % 2 != 0);
            wait_for (sidebar, i % 2 == 0 ? typeof (Layouts.FilterPaneChild) : typeof (Layouts.FilterPaneRow));
            assert_true (find (sidebar, old_kind) == null);
            release_check (tracked);
        }
        record ("sidebar_end", 0, 8);
    }

    public int main (string[] args) {
        if (!Gtk.init_check ()) return 77;
        Adw.init ();
        return run ();
    }

    public int run () {
        started = get_monotonic_time ();
        events = new StringBuilder ();
        string data_home = Environment.get_variable ("XDG_DATA_HOME");
        // This mode must never open the normal user database.
        assert_true (data_home != null && data_home.has_suffix ("/data"));
        output_dir = Path.get_dirname (data_home) + "/recording";
        DirUtils.create_with_parents (output_dir, 0700);
        try {
            var manifest = new Json.Parser ();
            manifest.load_from_file (Path.get_dirname (data_home) + "/manifest.json");
            var root = manifest.get_root ().get_object ();
            assert_false (root.get_boolean_member ("network_accounts"));
            uint8[] database_bytes;
            FileUtils.get_data (data_home + "/io.github.alainm23.planify/database.db", out database_bytes);
            assert_cmpstr (Checksum.compute_for_data (ChecksumType.SHA256, database_bytes),
                CompareOperator.EQ, root.get_string_member ("sha256"));
            database_bytes = null;
            int count = (int) root.get_object_member ("counts").get_int_member ("items");
            assert_true (count == 450 || count == 5000);
            Services.Database.get_default ().init_database ();
            assert_cmpint (Services.Store.instance ().items.size, CompareOperator.EQ, count);
            foreach (var source in Services.Store.instance ().sources) assert_true (source.source_type == SourceType.LOCAL);
            var app = Planify.instance;
            assert_true (app.register ());
            var window = new MainWindow (app);
            app.main_window = window;
            window.present ();
            pause (1000);
            // A unique allocation aligns event times with the interpreted Heaptrack clock.
            uint8[] clock_marker = new uint8[1234567];
            clock_marker[0] = 1;
            record ("clock_anchor");
            clock_marker = null;
            record ("ready", 0, count);
            rapid_views (window);
            calendar ();
            sidebar (window);
            pause (10000);
            record ("final_idle_end");
            assert_cmpint (Services.Store.instance ().items.size, CompareOperator.EQ, count);
            window.destroy ();
            record ("success", 0, count);
            return 0;
        } catch (Error e) {
            stderr.printf ("Scenario failed: %s\n", e.message);
            return 1;
        }
    }
}
