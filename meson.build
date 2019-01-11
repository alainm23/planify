project('com.github.alainm23.planner',
        'vala', 'c',
        version: '1.1')

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
    'src/Services/Notifications.vala',
    'src/Services/Weather.vala',
    'src/Services/Signals.vala',
    'src/Services/Github.vala',
    'src/Services/Calendar/CalendarModel.vala',
    'src/Services/Calendar/Utils.vala',
    'src/Services/Calendar/GesturesUtils.vala',
    'src/Services/Calendar/DateRange.vala',
    'src/Services/Calendar/LanguagesFormat.vala',
    'src/Services/Calendar/MayaSettings.vala',
    'src/Services/Calendar/SavedState.vala',

    'src/Views/Main.vala',
    'src/Views/Inbox.vala',
    'src/Views/Today.vala',
    'src/Views/Upcoming.vala',
    'src/Views/Project.vala',
    'src/Views/AllTasks.vala',
    'src/Views/CompletedTasks.vala',

    'src/Dialogs/PreferencesDialog.vala',
    'src/Dialogs/ShareDialog.vala',

    'src/Widgets/WhenButton.vala',
    'src/Widgets/LabelButton.vala',
    'src/Widgets/MoveButton.vala',
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
    'src/Widgets/AlertView.vala',
    'src/Widgets/TimePicker.vala',
    'src/Widgets/CalendarEvents.vala',
    'src/Widgets/Weather.vala',
    'src/Widgets/AgendaEventRow.vala',
    'src/Widgets/SourceItem.vala',
    'src/Widgets/QuickFind.vala',
    'src/Widgets/NoteChild.vala',
    'src/Widgets/RepositoryRow.vala',

    'src/Widgets/Calendar/Calendar.vala',
    'src/Widgets/Calendar/CalendarHeader.vala',
    'src/Widgets/Calendar/CalendarView.vala',
    'src/Widgets/Calendar/CalendarWeek.vala',
    'src/Widgets/Calendar/CalendarDay.vala',

    'src/Widgets/Popovers/NewProject.vala',
    'src/Widgets/Popovers/ProjectMenu.vala',
    'src/Widgets/Popovers/TaskMenu.vala',
    'src/Widgets/Popovers/WhenPopover.vala',
    'src/Widgets/Popovers/LabelsPopover.vala',
    'src/Widgets/Popovers/MovePopover.vala',
    'src/Widgets/Popovers/NotificationsPopover.vala',
    'src/Widgets/Popovers/NotificationActionPopover.vala',
    'src/Widgets/Popovers/DeadlinePopover.vala',


    'src/Objects/Project.vala',
    'src/Objects/Task.vala',
    'src/Objects/Label.vala',
    'src/Objects/Repository.vala',
    'src/Objects/User.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('sqlite3'),
        dependency('unity'),
        dependency('libnotify'),
        dependency('libgeoclue-2.0'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0'),
        dependency('gtksourceview-3.0'),
        dependency('libecal-1.2', version: '>=3.8.0'),
        dependency('libedataserver-1.2', version: '>=3.8.0'),
        dependency('libedataserverui-1.2', version: '>=3.8.0'),
        dependency('libical'),
        dependency('gmodule-2.0'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
