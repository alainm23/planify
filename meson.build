project('com.github.alainm23.planner',
        'vala', 'c',
        version: '0.1')

gnome = import('gnome')
i18n = import('i18n')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

asresources = gnome.compile_resources (
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

    'src/Widgets/ActionRow.vala',
    'src/Widgets/Pane.vala',
    'src/Widgets/NewProject.vala',
    'src/Widgets/ProjectRow.vala',
    
    'src/Views/Welcome.vala',
    'src/Views/Inbox.vala',
    'src/Views/Today.vala',
    'src/Views/Upcoming.vala',
    
    'src/Services/Database.vala',
    'src/Services/Todoist.vala',

    'src/Dialogs/TodoistOAuth.vala',

    'src/Objects/Project.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('gobject-2.0'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('sqlite3'),
        dependency('gtk+-3.0'),
        dependency('json-glib-1.0'),
        dependency('webkit2gtk-4.0'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

subdir('data')
meson.add_install_script('meson/post_install.py')