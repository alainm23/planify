void test_es_iso_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test YYYY-MM-DD (ISO parser is language-independent)
    print ("Testing: '2024-03-15'\n");
    var result = chrono.parse ("2024-03-15");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_year () == 2024);
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);

    // Test YYYY-MM-DDTHH:MM
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

void test_es_casual_date_parser () {
    var chrono = new Chrono.Chrono ("es");
    var now = new DateTime.now_local ();

    // Test hoy (today)
    print ("Testing: 'hoy'\n");
    var result = chrono.parse ("hoy");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_day_of_month () == now.get_day_of_month ());
    assert (result.date.get_month () == now.get_month ());

    // Test manana (tomorrow - ASCII form also accepted by parser)
    print ("Testing: 'manana'\n");
    result = chrono.parse ("manana");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var tomorrow = now.add_days (1);
    assert (result.date.get_day_of_month () == tomorrow.get_day_of_month ());

    // Test ayer (yesterday)
    print ("Testing: 'ayer'\n");
    result = chrono.parse ("ayer");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var yesterday = now.add_days (-1);
    assert (result.date.get_day_of_month () == yesterday.get_day_of_month ());

    // Test pasado manana (day after tomorrow)
    print ("Testing: 'pasado manana'\n");
    result = chrono.parse ("pasado manana");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var overmorrow = now.add_days (2);
    assert (result.date.get_day_of_month () == overmorrow.get_day_of_month ());

    // Test anteayer (day before yesterday)
    print ("Testing: 'anteayer'\n");
    result = chrono.parse ("anteayer");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    var before_yesterday = now.add_days (-2);
    assert (result.date.get_day_of_month () == before_yesterday.get_day_of_month ());
}

void test_es_casual_time_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test tarde (afternoon, 14h)
    print ("Testing: 'tarde'\n");
    var result = chrono.parse ("tarde");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 14);

    // Test noche (evening, 20h)
    print ("Testing: 'noche'\n");
    result = chrono.parse ("noche");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 20);

    // Test medianoche (midnight, 0h)
    print ("Testing: 'medianoche'\n");
    result = chrono.parse ("medianoche");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 0);

    // Test mediodia (noon, 12h - ASCII form accepted by parser)
    print ("Testing: 'mediodia'\n");
    result = chrono.parse ("mediodia");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 12);
}

void test_es_month_name_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test "15 de marzo" (15th of March)
    print ("Testing: '15 de marzo'\n");
    var result = chrono.parse ("15 de marzo");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);

    // Test "25 de diciembre" (25th of December)
    print ("Testing: '25 de diciembre'\n");
    result = chrono.parse ("25 de diciembre");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 12);
    assert (result.date.get_day_of_month () == 25);

    // Test month-day order: "marzo 15"
    print ("Testing: 'marzo 15'\n");
    result = chrono.parse ("marzo 15");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 3);
    assert (result.date.get_day_of_month () == 15);

    // Test month with year: "enero de 2012"
    print ("Testing: 'enero de 2012'\n");
    result = chrono.parse ("enero de 2012");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 1);
    assert (result.date.get_year () == 2012);

    // Test month name only: "enero"
    print ("Testing: 'enero'\n");
    result = chrono.parse ("enero");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_month () == 1);
}

void test_es_relative_date_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test "proxima semana" (next week - ASCII form accepted by parser)
    print ("Testing: 'proxima semana'\n");
    var result = chrono.parse ("proxima semana");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");

    // Test "mes pasado" (last month)
    print ("Testing: 'mes pasado'\n");
    result = chrono.parse ("mes pasado");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");

    // Test "este ano" (this year - ASCII form accepted by parser)
    print ("Testing: 'este ano'\n");
    result = chrono.parse ("este ano");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
}

void test_es_time_expression_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test "en 5 minutos" (in 5 minutes)
    print ("Testing: 'en 5 minutos'\n");
    var result = chrono.parse ("en 5 minutos");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");

    // Test "en 2 horas" (in 2 hours)
    print ("Testing: 'en 2 horas'\n");
    result = chrono.parse ("en 2 horas");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");

    // Test "en 3 dias" (in 3 days - ASCII form accepted by parser)
    print ("Testing: 'en 3 dias'\n");
    result = chrono.parse ("en 3 dias");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
}

void test_es_datetime_combo_parser () {
    var chrono = new Chrono.Chrono ("es");

    // Test "manana a las 3pm" (tomorrow at 3pm)
    print ("Testing: 'manana a las 3pm'\n");
    var result = chrono.parse ("manana a las 3pm");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 15);

    // Test "hoy a las 9:30am" (today at 9:30am)
    print ("Testing: 'hoy a las 9:30am'\n");
    result = chrono.parse ("hoy a las 9:30am");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 9);
    assert (result.date.get_minute () == 30);

    // Test "ayer a las 14:30" (yesterday at 14:30)
    print ("Testing: 'ayer a las 14:30'\n");
    result = chrono.parse ("ayer a las 14:30");
    assert (result != null);
    print ("  Result: %s\n", result.date.format ("%Y-%m-%d %H:%M"));
    print ("---\n");
    assert (result.date.get_hour () == 14);
    assert (result.date.get_minute () == 30);
}

void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/chrono/es/iso_parser", test_es_iso_parser);
    Test.add_func ("/chrono/es/casual_date_parser", test_es_casual_date_parser);
    Test.add_func ("/chrono/es/casual_time_parser", test_es_casual_time_parser);
    Test.add_func ("/chrono/es/month_name_parser", test_es_month_name_parser);
    Test.add_func ("/chrono/es/relative_date_parser", test_es_relative_date_parser);
    Test.add_func ("/chrono/es/time_expression_parser", test_es_time_expression_parser);
    Test.add_func ("/chrono/es/datetime_combo_parser", test_es_datetime_combo_parser);

    Test.run ();
}
