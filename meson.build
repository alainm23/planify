project('com.github.alainm23.planner',
        'vala', 'c',
        version: '1.2.1')

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
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

# Find libMarkdown
libmarkdown = dependency('libmarkdown', version: '>= 2.2.1', required: false)
if libmarkdown.found() == false
    cc = meson.get_compiler('c')
    libmarkdown = cc.find_library('libmarkdown', required: true)
endif

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

    'src/Widgets/HeaderBar.vala',
    'src/Widgets/ProjectsList.vala',
    'src/Widgets/ItemRow.vala',
    'src/Widgets/NewProject.vala',
    'src/Widgets/ProjectRow.vala',

    'src/Widgets/Popovers/ColorPicker.vala',
    'src/Widgets/Popovers/Tooltip.vala',
    'src/Widgets/Popovers/MenuProject.vala',
    'src/Widgets/Popovers/SourceProject.vala',
    
    'src/Services/Database.vala',
    'src/Services/Todoist.vala',

    'src/Objects/Project.vala',
    'src/Objects/User.vala',

    'src/Views/Main.vala',
    'src/Views/Welcome.vala',
    'src/Views/Inbox.vala',
    'src/Views/TodoistAccess.vala',

    'src/Dialogs/Settings.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('sqlite3'),
        dependency('unity'),
        dependency('libgeoclue-2.0'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0'),
        dependency('gtksourceview-3.0'),
        dependency('libecal-1.2', version: '>=3.8.0'),
        dependency('libedataserver-1.2', version: '>=3.8.0'),
        dependency('libedataserverui-1.2', version: '>=3.8.0'),
        dependency('libical'),
        dependency('gmodule-2.0'),
        dependency('webkit2gtk-4.0'),
        libmarkdown,
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

subdir('data')
#subdir('po')

meson.add_install_script('meson/post_install.py')
