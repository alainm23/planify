project('com.github.artegeek.planner', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')

asresources = gnome.compile_resources(
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    asresources,
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Utils.vala',

    'src/Services/Database.vala',
    'src/Services/Notifications.vala',

    'src/Views/Main.vala',
    'src/Views/Inbox.vala',
    'src/Views/Today.vala',
    'src/Views/Tomorrow.vala',

    'src/Widgets/WhenButton.vala',
    'src/Widgets/LabelButton.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/ProjectsList.vala',
    'src/Widgets/ProjectRow.vala',
    'src/Widgets/ItemRow.vala',
    'src/Widgets/CheckRow.vala',
    'src/Widgets/TaskRow.vala',
    'src/Widgets/LabelRow.vala',
    'src/Widgets/LabelChild.vala',
    'src/Widgets/TaskNew.vala',
    'src/Widgets/ModelButton.vala',

    'src/Widgets/Popovers/AddProject.vala',
    'src/Widgets/Popovers/ProjectMenu.vala',
    'src/Widgets/Popovers/ItemMenu.vala',
    'src/Widgets/Popovers/WhenPopover.vala',
    'src/Widgets/Popovers/LabelsPopover.vala',

    'src/Objects/Project.vala',
    'src/Objects/Task.vala',
    'src/Objects/Label.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('sqlite3'),
        dependency('unity'),
        dependency('libnotify'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

subdir('data')
meson.add_install_script('meson/post_install.py')
