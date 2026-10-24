/* Regression coverage for the bounded calendar widget window. */
namespace Planify.Tests.CalendarMemory {
    private Gtk.Box months (Widgets.Calendar.CalendarScroll calendar) {
        var overlay = (Gtk.Overlay) calendar.child;
        var content = ((Gtk.ScrolledWindow) overlay.child).child;
        if (content is Gtk.Viewport) {
            content = ((Gtk.Viewport) content).child;
        }
        return (Gtk.Box) content;
    }

    private int count_months (Widgets.Calendar.CalendarScroll calendar) {
        int count = 0;
        for (var row = months (calendar).get_first_child (); row != null; row = row.get_next_sibling ()) {
            count++;
        }
        return count;
    }

    public void test_distant_dates () {
        var calendar = new Widgets.Calendar.CalendarScroll ();
        var today = new GLib.DateTime.now_local ();
        var first = GLib.WeakRef (months (calendar).get_first_child ());
        foreach (int years in new int[] { 50, -50, 100, -100, 0 }) {
            calendar.date = today.add_years (years);
            assert_cmpint (count_months (calendar), CompareOperator.LE, 12);
            assert_cmpint (count_months (calendar), CompareOperator.GT, 0);
            assert_true (calendar.date.equal (today.add_years (years)));
        }
        assert_null (first.get ());
        calendar.dispose ();
    }

    public void test_scroll_both_directions () {
        var calendar = new Widgets.Calendar.CalendarScroll ();
        var overlay = (Gtk.Overlay) calendar.child;
        var scroller = (Gtk.ScrolledWindow) overlay.child;
        for (int i = 0; i < 60; i++) {
            // Clear deferred position restoration between user scroll gestures.
            while (MainContext.default ().pending ()) {
                MainContext.default ().iteration (false);
            }
            scroller.edge_reached (i < 30 ? Gtk.PositionType.BOTTOM : Gtk.PositionType.TOP);
            assert_cmpint (count_months (calendar), CompareOperator.LE, 12);
        }
        calendar.date = new GLib.DateTime.now_local ();
        assert_cmpint (count_months (calendar), CompareOperator.LE, 12);
        calendar.dispose ();
    }
}

int main (string[] args) {
    Test.init (ref args);
    if (!Gtk.init_check ()) {
        return 77;
    }
    Adw.init ();
    Test.add_func ("/widgets/calendar/distant_dates", Planify.Tests.CalendarMemory.test_distant_dates);
    Test.add_func ("/widgets/calendar/scroll_both_directions", Planify.Tests.CalendarMemory.test_scroll_both_directions);
    return Test.run ();
}
