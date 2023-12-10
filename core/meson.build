conf_data = configuration_data()
conf_data.set_quoted('APPLICATION_ID', application_id)
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
conf_data.set_quoted('PACKAGE_VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
conf_data.set_quoted('PROFILE', profile)

config_file = configure_file(
    configuration : conf_data,
    input : 'config.vala.in',
    output : 'config.vala'
)

core_files = files(
    'Utils.vala',
    'Enum.vala',
    'Services/Settings.vala',
    'Widgets/DynamicIcon.vala'
)

core_deps = [
  glib_dep,
  gee_dep,
  gtk_dep,
  sqlite3_dep,
  libadwaita_dep,
  granite_dep,
  json_dep,
]

core_lib = shared_library(
    'planify',
    core_files,
    dependencies: [ core_deps, m_dep ],
    install: true,
    install_dir: [true, join_paths(get_option('includedir'), 'planify'), true],
    soversion: '0',
    version: '0.1'
)

core_dep = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('.')
)

install_data(
    'planify.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

pkgconfig.generate(
    core_lib,
    filebase: 'planify',
    version: meson.project_version(),
    name: 'Planify',
    description: 'Extension endpoint to the Planify application',
    subdirs: 'planify',
    requires: core_deps
)

