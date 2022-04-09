namespace CalDAVUtil {
    public string get_esource_collection_display_name (E.Source source) {
        var display_name = "";
    
        try {
            var registry = Services.CalDAV.get_default ().get_registry_sync ();
            var collection_source = registry.find_extension (source, E.SOURCE_EXTENSION_COLLECTION);
    
            if (collection_source != null) {
                display_name = collection_source.display_name;
            } else if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
                display_name = ((E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
            }
        } catch (Error e) {
            warning (e.message);
        }

        return display_name;
    }

    /*
     * Gee Utility Functions
     */

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    private bool calcomponent_equal_func (ECal.Component a, ECal.Component b) {
        return a.get_id ().equal (b.get_id ());
    }

    public bool esource_equal_func (E.Source a, E.Source b) {
        return a.equal (b);
    }

    public uint esource_hash_func (E.Source source) {
        return source.hash ();
    }

    //--- X-Property ---//

    public string? get_x_property_value (ECal.Component ecalcomponent, string x_name) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            return ECal.util_component_dup_x_property (icalcomponent, x_name);
        }

        return null;
    }

    public void set_x_property_value (ECal.Component ecalcomponent, string x_name, string? value) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            ECal.util_component_set_x_property (icalcomponent, x_name, value);
        }
    }

    public ICal.Duration get_apple_sortorder_default_value (ECal.Component ecalcomponent) {
        return ecalcomponent.get_created ().subtract (new ICal.Time.from_string ("20010101T000000Z"));
    }

    public void set_apple_sortorder_property_value (ECal.Component ecalcomponent, string? value) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            ECal.util_component_set_x_property (icalcomponent, "X-APPLE-SORT-ORDER", value);
        }
    }

    /**
     * Returns the value of X-APPLE-SORT-ORDER property if set
     */

    public string? get_apple_sortorder_property_value (ECal.Component ecalcomponent) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            return ECal.util_component_dup_x_property (icalcomponent, "X-APPLE-SORT-ORDER");
        }
        return null;
    }

    public void set_gtasks_position_property_value (ECal.Component ecalcomponent, string? value) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            ECal.util_component_set_x_property (icalcomponent, "X-EVOLUTION-GTASKS-POSITION", value);
        }
    }

    /**
     * Returns the value of X-EVOLUTION-GTASKS-POSITION property if set,
     * otherwise return "00000000000000000000"
     */
     public string get_gtasks_position_property_value (ECal.Component ecalcomponent) {
        unowned ICal.Component? icalcomponent = ecalcomponent.get_icalcomponent ();
        if (icalcomponent != null) {
            var gtasks_position = ECal.util_component_dup_x_property (icalcomponent, "X-EVOLUTION-GTASKS-POSITION");

            if (gtasks_position != null) {
                return gtasks_position;
            }
        }

        // returns the default value for a task created without a position
        return "00000000000000000000";
    }

    public int caldav_priority_to_planner (ECal.Component task) {
        if (task != null) {
            int priority = task.get_priority ();

            if (priority <= 0) {
                return 1;
            } else if (priority >= 1 && priority <= 4) {
                return 4;
            } else if (priority == 5) {
                return 3;
            } else if (priority > 5 && priority <= 9) {
                return 2;
            } else {
                return 1;
            }
        }

        return 1;
    }

    /**
     * Converts the given ICal.Time to a GLib.DateTime, represented in the
     * system timezone.
     *
     * All timezone information in the original @date is lost. However, the
     * {@link GLib.TimeZone} contained in the resulting DateTime is correct,
     * since there is a well-defined local timezone between both libical and
     * GLib.
     */
     public DateTime ical_to_date_time_local (ICal.Time date) {
        assert (!date.is_null_time ());
        var converted = ical_convert_to_local (date);
        int year, month, day, hour, minute, second;
        converted.get_date (out year, out month, out day);
        converted.get_time (out hour, out minute, out second);
        return new DateTime.local (year, month,
            day, hour, minute, second);
    }

    /** Converts the given ICal.Time to the local (or system) timezone
     */
     public ICal.Time ical_convert_to_local (ICal.Time time) {
        var system_tz = ECal.util_get_system_timezone ();
        return time.convert_to_zone (system_tz);
    }

    /**
     * Converts two DateTimes representing a date and a time to one TimeType.
     *
     * The first contains the date; its time settings are ignored. The second
     * one contains the time itself; its date settings are ignored. If the time
     * is `null`, the resulting TimeType is of `DATE` type; if it is given, the
     * TimeType is of `DATE-TIME` type.
     *
     * This also accepts an optional `timezone` argument. If it is given a
     * timezone, the resulting TimeType will be relative to the given timezone.
     * If it is `null`, the resulting TimeType will be "floating" with no
     * timezone. If the argument is not given, it will default to the system
     * timezone.
     */
     
    public ICal.Time datetimes_to_icaltime (GLib.DateTime date, GLib.DateTime? time_local,
        ICal.Timezone? timezone = ECal.util_get_system_timezone ().copy ()) {

        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());

        // Check if it's a date. If so, set is_date to true and fix the time to be sure.
        // If it's not a date, first thing set is_date to false.
        // Then, set the timezone.
        // Then, set the time.
        if (time_local == null) {
            // Date type: ensure that everything corresponds to a date
            result.set_is_date (true);
            result.set_time (0, 0, 0);
        } else {
            // Includes time
            // Set is_date first (otherwise timezone won't change)
            result.set_is_date (false);

            // Set timezone for the time to be relative to
            // (doesn't affect DATE-type times)
            result.set_timezone (timezone);

            // Set the time with the updated time zone
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
            debug (result.get_tzid ());
            debug (result.as_ical_string ());
        }

        return result;
    }
}