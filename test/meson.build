test_caldav_integration = executable(
    'test-caldav-integration',
    'test-caldav-integration.vala',
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('caldav-integration', test_caldav_integration, timeout: 60, suite: ['caldav-integration'])

test_chrono = executable(
    'test-chrono',
    'test-chrono.vala',
    dependencies: [ core_dep, glib_dep, gee_dep ],
    install: false
)

test('chrono', test_chrono, timeout: 30, suite: ['chrono'])


test_chrono_es = executable(
    'test-chrono-es',
    'test-chrono-es.vala',
    dependencies: [ core_dep, glib_dep, gee_dep ],
    install: false
)

test('chrono-es', test_chrono_es, timeout: 30, suite: ['chrono-es'])