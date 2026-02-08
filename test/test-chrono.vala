void test_iso_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test YYYY-MM-DD
    print ("Testing: '2024-03-15'\n");
    var result = chrono.parse ("2024-03-15");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_year () == 2024);
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);
    
    // Test YYYY-MM-DDThh:mm
    print ("Testing: '2024-12-25T14:30'\n");
    result = chrono.parse ("2024-12-25T14:30");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_year () == 2024);
    assert (result.date.get_month () == 12);
    assert (result.date.get_day_of_month () == 25);
    assert (result.date.get_hour () == 14);
    assert (result.date.get_minute () == 30);
}

void test_slash_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test d/m
    print ("Testing: '15/3'\n");
    var result = chrono.parse ("15/3");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_day_of_month () == 15);
    assert (result.date.get_month () == 3);
    
    // Test d/m/yyyy
    print ("Testing: '25/12/2024'\n");
    result = chrono.parse ("25/12/2024");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_day_of_month () == 25);
    assert (result.date.get_month () == 12);
    assert (result.date.get_year () == 2024);
    
    // Test d.m.yyyy
    print ("Testing: '1.1.2025'\n");
    result = chrono.parse ("1.1.2025");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_day_of_month () == 1);
    assert (result.date.get_month () == 1);
    assert (result.date.get_year () == 2025);
}

void test_time_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test 24h format
    print ("Testing: '14:30'\n");
    var result = chrono.parse ("14:30");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 14);
    assert (result.date.get_minute () == 30);
    
    // Test 12h format with pm
    print ("Testing: '3pm'\n");
    result = chrono.parse ("3pm");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 15);
    
    // Test 12h format with am
    print ("Testing: '9:30am'\n");
    result = chrono.parse ("9:30am");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 9);
    assert (result.date.get_minute () == 30);
}

void test_casual_date_parser () {
    var chrono = new Chrono.Chrono ();
    var now = new DateTime.now_local ();
    
    // Test today
    print ("Testing: 'today'\n");
    var result = chrono.parse ("today");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_day_of_month () == now.get_day_of_month ());
    
    // Test tomorrow
    print ("Testing: 'tomorrow'\n");
    result = chrono.parse ("tomorrow");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var tomorrow = now.add_days (1);
    assert (result.date.get_day_of_month () == tomorrow.get_day_of_month ());
    
    // Test yesterday
    print ("Testing: 'yesterday'\n");
    result = chrono.parse ("yesterday");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var yesterday = now.add_days (-1);
    assert (result.date.get_day_of_month () == yesterday.get_day_of_month ());
}

void test_casual_time_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test morning
    print ("Testing: 'morning'\n");
    var result = chrono.parse ("morning");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 9);
    
    // Test afternoon
    print ("Testing: 'afternoon'\n");
    result = chrono.parse ("afternoon");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 14);
    
    // Test midnight
    print ("Testing: 'midnight'\n");
    result = chrono.parse ("midnight");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 0);
    
    // Test noon
    print ("Testing: 'noon'\n");
    result = chrono.parse ("noon");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 12);
}

void test_month_name_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test March 15
    print ("Testing: 'March 15'\n");
    var result = chrono.parse ("March 15");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);
    
    // Test 15 March
    print ("Testing: '15 March'\n");
    result = chrono.parse ("15 March");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);
    
    // Test Dec 25, 2024
    print ("Testing: 'Dec 25, 2024'\n");
    result = chrono.parse ("Dec 25, 2024");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 12);
    assert (result.date.get_day_of_month () == 25);
    assert (result.date.get_year () == 2024);
    
    // Test January 2012
    print ("Testing: 'January 2012'\n");
    result = chrono.parse ("January 2012");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 1);
    assert (result.date.get_year () == 2012);
    
    // Test January
    print ("Testing: 'January'\n");
    result = chrono.parse ("January");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 1);
}

void test_relative_date_parser () {
    var chrono = new Chrono.Chrono ();
    var now = new DateTime.now_local ();
    
    // Test next week
    print ("Testing: 'next week'\n");
    var result = chrono.parse ("next week");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    
    // Test last month
    print ("Testing: 'last month'\n");
    result = chrono.parse ("last month");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    
    // Test this year
    print ("Testing: 'this year'\n");
    result = chrono.parse ("this year");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
}

void test_time_expression_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test in 5 minutes
    print ("Testing: 'in 5 minutes'\n");
    var result = chrono.parse ("in 5 minutes");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    
    // Test in 2 hours
    print ("Testing: 'in 2 hours'\n");
    result = chrono.parse ("in 2 hours");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    
    // Test 3 days from now
    print ("Testing: '3 days from now'\n");
    result = chrono.parse ("3 days from now");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
}

void test_datetime_combo_parser () {
    var chrono = new Chrono.Chrono ();
    
    // Test tomorrow at 3pm
    print ("Testing: 'tomorrow at 3pm'\n");
    var result = chrono.parse ("tomorrow at 3pm");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 15);
    
    // Test today at 9:30am
    print ("Testing: 'today at 9:30am'\n");
    result = chrono.parse ("today at 9:30am");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 9);
    assert (result.date.get_minute () == 30);
    
    // Test March 15 at 14:30
    print ("Testing: 'March 15 at 14:30'\n");
    result = chrono.parse ("March 15 at 14:30");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);
    assert (result.date.get_hour () == 14);
    assert (result.date.get_minute () == 30);
}

void test_recurrence_parser () {
    var chrono = new Chrono.Chrono ();
    
    print ("Testing: 'every day'\n");
    var result = chrono.parse ("every day", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s\n---\n", result.recurrence.recurrence_type.to_string ());
    
    print ("Testing: 'daily'\n");
    result = chrono.parse ("daily", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s\n---\n", result.recurrence.recurrence_type.to_string ());
    
    print ("Testing: 'every morning'\n");
    result = chrono.parse ("every morning", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s, Hour: %d\n---\n", result.recurrence.recurrence_type.to_string (), result.recurrence.hour);
    
    print ("Testing: 'every weekday'\n");
    result = chrono.parse ("every weekday", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s, Days: %d\n---\n", result.recurrence.recurrence_type.to_string (), result.recurrence.days_of_week.size);
    
    print ("Testing: 'every weekend'\n");
    result = chrono.parse ("every weekend", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s\n---\n", result.recurrence.recurrence_type.to_string ());
    
    print ("Testing: 'every 27th'\n");
    result = chrono.parse ("every 27th", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s, Day: %d\n---\n", result.recurrence.recurrence_type.to_string (), result.recurrence.day_of_month);
    
    print ("Testing: 'every last day'\n");
    result = chrono.parse ("every last day", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s, Last: %s\n---\n", result.recurrence.recurrence_type.to_string (), result.recurrence.last_day.to_string ());
    
    print ("Testing: 'every jan 27th'\n");
    result = chrono.parse ("every jan 27th", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s, Month: %d, Day: %d\n---\n", result.recurrence.recurrence_type.to_string (), result.recurrence.month_of_year, result.recurrence.day_of_month);
    
    print ("Testing: 'every hour'\n");
    result = chrono.parse ("every hour", true);
    assert (result != null && result.recurrence != null);
    print ("  Type: %s\n---\n", result.recurrence.recurrence_type.to_string ());
}

void main (string[] args) {
    Test.init (ref args);
    
    Test.add_func ("/chrono/iso_parser", test_iso_parser);
    Test.add_func ("/chrono/slash_parser", test_slash_parser);
    Test.add_func ("/chrono/time_parser", test_time_parser);
    Test.add_func ("/chrono/casual_date_parser", test_casual_date_parser);
    Test.add_func ("/chrono/casual_time_parser", test_casual_time_parser);
    Test.add_func ("/chrono/month_name_parser", test_month_name_parser);
    Test.add_func ("/chrono/relative_date_parser", test_relative_date_parser);
    Test.add_func ("/chrono/time_expression_parser", test_time_expression_parser);
    Test.add_func ("/chrono/datetime_combo_parser", test_datetime_combo_parser);
    Test.add_func ("/chrono/recurrence_parser", test_recurrence_parser);
    
    Test.run ();
}
