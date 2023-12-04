public class Services.TimeMonitor : Object {
    private static TimeMonitor? _instance;
    public static TimeMonitor get_default () {
        if (_instance == null) {
            _instance = new TimeMonitor ();
        }

        return _instance;
    }

    private DateTime last_registered_date;

    public void init_timeout () {
        last_registered_date = new DateTime.now_local ();
        uint interval = calculate_seconds_until_midnight ();

        Timeout.add_seconds (interval, on_timeout);
    }

    private bool on_timeout() {
        DateTime now = new DateTime.now_local ();

        if (now.get_day_of_month () != last_registered_date.get_day_of_month() ||
            now.get_month() != last_registered_date.get_month() ||
            now.get_year() != last_registered_date.get_year()) {

            Services.EventBus.get_default ().day_changed ();
            Services.Notification.get_default ().regresh ();

            last_registered_date = now;
            uint interval = calculate_seconds_until_midnight();

            Timeout.add_seconds(interval, on_timeout);
        } else {
            uint interval = calculate_seconds_until_midnight();
            Timeout.add_seconds(interval, on_timeout);
        }

        return false;
    }

    private uint calculate_seconds_until_midnight () {
        DateTime now = new DateTime.now_local ();

        uint value = (24 * 60 * 60) -
            (now.get_hour() * 60 * 60 + now.get_minute() * 60 + now.get_second());

        return value;
    }
}