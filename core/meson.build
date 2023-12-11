core_files = files(
    'Util.vala',
    'Enum.vala',
    'Constants.vala',

    'Services/Settings.vala',
    'Services/EventBus.vala',
    'Services/Database.vala',
    'Services/Todoist.vala',

    'Widgets/DynamicIcon.vala',
    'Widgets/LoadingButton.vala',

    'Objects/BaseObject.vala',
    'Objects/Color.vala',
    'Objects/DueDate.vala',
    'Objects/Item.vala',
    'Objects/ItemLabel.vala',
    'Objects/Label.vala',
    'Objects/Project.vala',
    'Objects/Queue.vala',
    'Objects/Reminder.vala',
    'Objects/Section.vala',
    
    'Objects/Filters/Pinboard.vala',
    'Objects/Filters/Scheduled.vala',
    'Objects/Filters/Today.vala',
    'Objects/Filters/Priority.vala',
    'Objects/Filters/Completed.vala',
    'Objects/Filters/Labels.vala',
)

core_deps = [
  glib_dep,
  gee_dep,
  gtk_dep,
  sqlite3_dep,
  libadwaita_dep,
  granite_dep,
  json_dep,
  libsoup_dep
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

