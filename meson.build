project ('com.github.alainm23.planner', 'vala', 'c')

gnome = import ('gnome')
i18n = import ('i18n')

add_global_arguments ('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()), language:'c')

asresources = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name () + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

executable (
    meson.project_name (),
    'src/Util.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    
    'src/Widgets/Sidebar.vala',
    'src/Widgets/FilterPaneRow.vala',
    'src/Widgets/DynamicIcon.vala',
    'src/Widgets/HeaderItem.vala',
    'src/Widgets/TodoistSync.vala',
    'src/Widgets/ProjectRow.vala',
    'src/Widgets/ProjectProgress.vala',
    'src/Widgets/LabelRow.vala',

    'src/Views/Welcome.vala',

    'src/Dialogs/TodoistOAuth.vala',

    'src/Services/EventBus.vala',
    'src/Services/Database.vala',
    'src/Services/Todoist.vala',

    'src/Objects/Project.vala',
    'src/Objects/Label.vala',
    asresources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gee-0.8', version: '>=0.8.5'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('sqlite3'),
        dependency('json-glib-1.0'),
        dependency('webkit2gtk-4.0'),
        dependency('libhandy-1', version: '>= 0.90.0'),
        meson.get_compiler ('c').find_library ('m', required : false)
    ],
    install: true
)

subdir('data')
# subdir('po')
meson.add_install_script('build-aux/meson/post_install.py')