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

test_cli_sources = [
    'test-cli-runner.vala',
    'cli/test-argument-parser.vala',
    'cli/test-task-validator.vala',
    'cli/test-priority-conversion.vala',
    join_paths(meson.project_source_root(), 'quick-add', 'cli', 'ArgumentParser.vala'),
    join_paths(meson.project_source_root(), 'quick-add', 'cli', 'TaskValidator.vala')
]

test_cli = executable(
    'test-cli',
    test_cli_sources,
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('cli', test_cli, timeout: 30, suite: ['cli'])

