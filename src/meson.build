conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('PLUGINDIR', pluginsdir)
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)


planner_files = files(
    'Application.vala',
    'MainWindow.vala',
    'Utils.vala',

    'Services/Database.vala',
    'Services/Todoist.vala',
    'Services/LabelsController.vala',
    'Services/Notifications.vala',
    'Services/Calendar/Util.vala',
    'Services/Calendar/CalendarModel.vala',
    'Services/DBusServer.vala',
    'Services/CustomShortcutSettings.vala',
    'Services/ActionManager.vala',
    'Services/EventBus.vala',
    'Services/ExportImport.vala',
    'Services/PluginManager.vala',

    # CalDav Support
    # 'Services/Tasks/Store.vala',
    # 'Services/Tasks/Utils.vala',
    
    'Widgets/ActionRow.vala',
    'Widgets/Pane.vala',
    'Widgets/New.vala',
    'Widgets/ProjectRow.vala',
    'Widgets/NewItem.vala',
    'Widgets/ItemRow.vala',
    'Widgets/ItemCompletedRow.vala',
    'Widgets/SectionRow.vala',
    'Widgets/DueButton.vala',
    'Widgets/LabelButton.vala',
    'Widgets/Toast.vala',
    'Widgets/MenuButtons.vala',
    'Widgets/MagicButton.vala',
    'Widgets/LabelRow.vala',
    'Widgets/NewCheck.vala',
    'Widgets/CheckRow.vala',
    'Widgets/LabelPreview.vala',
    'Widgets/LabelItem.vala',
    'Widgets/ProjectProgress.vala',
    'Widgets/UpcomingRow.vala',
    'Widgets/EventRow.vala',
    'Widgets/SourceItem.vala',
    'Widgets/ReminderButton.vala',
    'Widgets/ReminderRow.vala',
    'Widgets/NewSection.vala',
    'Widgets/Placeholder.vala',
    'Widgets/NewLabel.vala',
    'Widgets/PriorityButton.vala',
    'Widgets/Entry.vala',
    'Widgets/TextView.vala',
    'Widgets/MultiSelectToolbar.vala',
    'Widgets/ShortcutLabel.vala',
    'Widgets/WhatsNew.vala',
    'Widgets/LabelFilter.vala',
    'Widgets/BoardView.vala',
    'Widgets/BoardColumn.vala',
    'Widgets/ListView.vala',
    'Widgets/ToolsMenu.vala',

    # CalDav Support
    # 'Widgets/SourceRow.vala',
    # 'Widgets/CalDavList.vala',
    # 'Widgets/TaskRow.vala',

    'Widgets/Calendar/Calendar.vala',
    'Widgets/Calendar/CalendarDay.vala',
    'Widgets/Calendar/CalendarHeader.vala',
    'Widgets/Calendar/CalendarView.vala',
    'Widgets/Calendar/CalendarWeek.vala',

    'Views/Welcome.vala',
    'Views/Inbox.vala',
    'Views/Today.vala',
    'Views/Upcoming.vala',
    'Views/Project.vala',
    'Views/Label.vala',
    'Views/Completed.vala',
    'Views/Filter.vala',
    'Views/AllTasks.vala',

    # CalDav Support
    # 'Views/TaskList.vala',

    'Dialogs/TodoistOAuth.vala',
    'Dialogs/ProjectSettings.vala',
    'Dialogs/QuickFind.vala',
    'Dialogs/ShortcutsDialog.vala',
    'Dialogs/Project.vala',

    'Dialogs/Preferences/Preferences.vala',
    'Dialogs/Preferences/ItemSelect.vala',
    'Dialogs/Preferences/ItemSwitch.vala',
    'Dialogs/Preferences/ItemButton.vala',
    'Dialogs/Preferences/DatabaseSettings.vala',
    'Dialogs/Preferences/Item.vala',
    'Dialogs/Preferences/TopBox.vala',

    'Objects/Project.vala',
    'Objects/Item.vala',
    'Objects/Section.vala',
    'Objects/Label.vala',
    'Objects/Collaborator.vala',
    'Objects/Reminder.vala',
    'Objects/Queue.vala',
    'Objects/Shortcuts.vala',
)

executable(
    meson.project_name(),
    planner_files,
    asresources,
    config_header,
    dependencies: dependencies,
    install: true
)

executable(
    'com.github.alainm23.planner.quick-add',
    'QuickAdd/Application.vala',
    'QuickAdd/MainWindow.vala',
    'QuickAdd/DBusClient.vala',
    'QuickAdd/Database.vala',
    'QuickAdd/Project.vala',
    'QuickAdd/Item.vala',
    'QuickAdd/Queue.vala',
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

plannercore = library(
    'plannercore',
    planner_files,
    config_header,
    dependencies: dependencies,
    install: true,
    install_dir: [true, true, true],
    version: '0.0'
)

pkg = import('pkgconfig')

pkg.generate(
    version: '0.1',
    libraries: plannercore,
    description: 'Planner headers',
    name: 'plannercore',
    filebase: 'plannercore'
)

install_data ('plannercore.deps', install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'vala', 'vapi'))

plannercore_dep = declare_dependency(
    link_with: plannercore,
    dependencies: dependencies,
    include_directories: [include_directories('.')]
)
