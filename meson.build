project('com.github.alainm23.planner',
        'vala', 'c',
        version: '2.0.0')

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

    'src/Services/Database.vala',
    'src/Services/Todoist.vala',
    'src/Services/LabelsController.vala',
    'src/Services/Notification.vala',
    'src/Services/Calendar/Util.vala',
    'src/Services/Calendar/CalendarModel.vala',
    
    'src/Widgets/ActionRow.vala',
    'src/Widgets/Pane.vala',
    'src/Widgets/New.vala',
    'src/Widgets/ProjectRow.vala',
    'src/Widgets/NewItem.vala',
    'src/Widgets/ItemRow.vala',
    'src/Widgets/ItemCompletedRow.vala',
    'src/Widgets/SectionRow.vala',
    'src/Widgets/DueButton.vala',
    'src/Widgets/LabelButton.vala',
    'src/Widgets/Toast.vala',
    'src/Widgets/MenuButtons.vala',
    'src/Widgets/AreaRow.vala',
    'src/Widgets/MagicButton.vala',
    'src/Widgets/LabelRow.vala',
    'src/Widgets/NewCheck.vala',
    'src/Widgets/CheckRow.vala',
    'src/Widgets/LabelPreview.vala',
    'src/Widgets/LabelItem.vala',
    'src/Widgets/ProjectProgress.vala',
    'src/Widgets/UpcomingRow.vala',
    'src/Widgets/EventRow.vala',
    'src/Widgets/QuickSearch.vala',
    
    'src/Widgets/Calendar/Calendar.vala',
    'src/Widgets/Calendar/CalendarDay.vala',
    'src/Widgets/Calendar/CalendarHeader.vala',
    'src/Widgets/Calendar/CalendarView.vala',
    'src/Widgets/Calendar/CalendarWeek.vala',
    
    'src/Views/Welcome.vala',
    'src/Views/Inbox.vala',
    'src/Views/Today.vala',
    'src/Views/Upcoming.vala',
    'src/Views/Project.vala',

    'src/Dialogs/TodoistOAuth.vala',
    'src/Dialogs/ProjectSettings.vala',
    'src/Dialogs/Preferences.vala',
    
    'src/Objects/Project.vala',
    'src/Objects/Item.vala',
    'src/Objects/Area.vala',
    'src/Objects/Section.vala',
    'src/Objects/Label.vala',
    'src/Objects/Collaborator.vala',

    dependencies: [
        dependency('gee-0.8'),
        dependency('gobject-2.0'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('sqlite3'),
        dependency('gtk+-3.0'),
        dependency('json-glib-1.0'),
        dependency('webkit2gtk-4.0'),
        dependency('libecal-1.2'),
        dependency('libedataserver-1.2'),
        dependency('libical'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

subdir('data')
#subdir('po')
meson.add_install_script('meson/post_install.py')