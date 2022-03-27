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
}