public class Services.TimeMonitor : Object {
    private static TimeMonitor? _instance;
    public static TimeMonitor get_default () {
        if (_instance == null) {
            _instance = new TimeMonitor ();
        }

        return _instance;
    }

    private uint timeout_id = 0;

    public TimeMonitor () {
        add_timeout ();
    }

    private void add_timeout () {
        uint interval = calculate_time_until_next_minute ();

        if (timeout_id > 0) {
            Source.remove (timeout_id);
        }
        
        timeout_id = Timeout.add_seconds (interval + 60, () => {
            Planner.event_bus.day_changed ();
            Services.Notification.get_default ().regresh ();
            add_timeout ();
            return false;
        });
    }

    private uint calculate_time_until_next_minute () {
        DateTime now = new DateTime.now_local ();
        DateTime tomorrow = new DateTime.local (
            now.get_year (),
            now.get_month (),
            now.get_day_of_month (),
            23,
            59,
            59
        );

        return (uint) (tomorrow.to_unix () - now.to_unix ());
    }
}