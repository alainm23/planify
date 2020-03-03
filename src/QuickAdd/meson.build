project('com.github.alainm23.planner-quick-add',
        'vala', 'c',
        version: '0.1')

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

asresources = gnome.compile_resources (
    'as-resources', 'com.github.alainm23.planner.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    'Application.vala',
    'MainWindow.vala',
    'DBusClient.vala',
    'Database.vala',
    'Project.vala',
    'Item.vala',
    'Queue.vala',
    asresources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gee-0.8'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('sqlite3'),
        dependency('gtk+-3.0'),
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4'),
        meson.get_compiler('vala').find_library('posix'),
    ],
    install: true
)

meson.add_install_script('post_install.py')