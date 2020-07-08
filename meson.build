project ('com.github.alainm23.planner', 'vala', 'c', version: '2.4.6')

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

asresources = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

libecal_dep = dependency('libecal-2.0', required: false)
if libecal_dep.found()
    libical_dep = dependency('libical-glib')
    add_project_arguments('--define=E_CAL_2_0', language: 'vala')
    add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')
else
    libecal_dep = dependency('libecal-1.2', version: '>=3.8.0')
    libical_dep = dependency('libical')
    add_project_arguments('--vapidir', join_paths(meson.current_source_dir(), 'vapi'), language: 'vala')
endif

executable(
    meson.project_name(),
    asresources,
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Utils.vala',

    'src/Services/Database.vala',
    'src/Services/Todoist.vala',
    'src/Services/LabelsController.vala',
    'src/Services/Notifications.vala',
    'src/Services/Calendar/Util.vala',
    'src/Services/Calendar/CalendarModel.vala',
    'src/Services/DBusServer.vala',
    'src/Services/CustomShortcutSettings.vala',
    'src/Services/ActionManager.vala',
    'src/Services/EventBus.vala',
    
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
    'src/Widgets/SourceItem.vala',
    'src/Widgets/ReminderButton.vala',
    'src/Widgets/ReminderRow.vala',
    'src/Widgets/NewSection.vala',
    'src/Widgets/Placeholder.vala',
    'src/Widgets/NewLabel.vala',
    'src/Widgets/PriorityButton.vala',
    'src/Widgets/Entry.vala',
    'src/Widgets/TextView.vala',
    
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
    'src/Views/Label.vala',
    'src/Views/Completed.vala',
    'src/Views/Priority.vala',

    'src/Dialogs/TodoistOAuth.vala',
    'src/Dialogs/ProjectSettings.vala',
    'src/Dialogs/QuickFind.vala',
    'src/Dialogs/ShortcutsDialog.vala',
    'src/Dialogs/ReleaseDialog.vala',

    'src/Dialogs/Preferences/Preferences.vala',
    'src/Dialogs/Preferences/ItemSelect.vala',
    'src/Dialogs/Preferences/ItemSwitch.vala',
    'src/Dialogs/Preferences/ItemButton.vala',
    'src/Dialogs/Preferences/DatabaseSettings.vala',
    'src/Dialogs/Preferences/Item.vala',
    'src/Dialogs/Preferences/TopBox.vala',

    'src/Objects/Project.vala',
    'src/Objects/Item.vala',
    'src/Objects/Area.vala',
    'src/Objects/Section.vala',
    'src/Objects/Label.vala',
    'src/Objects/Collaborator.vala',
    'src/Objects/Reminder.vala',
    'src/Objects/Queue.vala',
    'src/Objects/Shortcuts.vala',
    config_header,
    dependencies: [
        dependency('gee-0.8'),
        dependency('gobject-2.0'),
        dependency('glib-2.0'),
        dependency('granite'),
        dependency('sqlite3'),
        dependency('gtk+-3.0'),
        dependency('json-glib-1.0'),
        dependency('webkit2gtk-4.0'),
        libecal_dep,
        libical_dep,
        dependency('libedataserver-1.2', version: '>=3.8.0'),
        dependency('libsoup-2.4'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install: true
)

executable(
    'com.github.alainm23.planner.quick-add',
    'src/QuickAdd/Application.vala',
    'src/QuickAdd/MainWindow.vala',
    'src/QuickAdd/DBusClient.vala',
    'src/QuickAdd/Database.vala',
    'src/QuickAdd/Project.vala',
    'src/QuickAdd/Item.vala',
    'src/QuickAdd/Queue.vala',
    asresources,
    config_header,
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

subdir('data')
subdir('po')
meson.add_install_script('build-aux/meson/post_install.py')
