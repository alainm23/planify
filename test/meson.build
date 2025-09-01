test_caldav_integration = executable(
    'test-caldav-integration',
    'test-caldav-integration.vala',
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('caldav-integration', test_caldav_integration, timeout: 60, suite: ['caldav-integration'])

