project (
    'com.github.alainm23.planner',
    'vala', 'c',
    version: '3.0.4'
)

gnome = import ('gnome')
i18n = import ('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

gresource = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name () + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_file = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

# libecal_dep = dependency('libecal-2.0')

planner_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8', version: '>=0.8.5'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('sqlite3'),
    dependency('json-glib-1.0'),
    dependency('webkit2gtk-4.0'),
    dependency('libhandy-1', version: '>= 0.90.0'),
    ## libecal_dep,
    # dependency('libedataserver-1.2'),
    # dependency('libical-glib'),
    # dependency('libgdata'),
    meson.get_compiler ('c').find_library ('m', required : false)
]

# if libecal_dep.version().version_compare('>=3.39.2')
#     add_project_arguments('--define=HAS_EDS_3_40', language: 'vala')
# else
#     planner_deps += meson.get_compiler('vala').find_library('libecal-2.0-fixes', dirs: meson.current_source_dir() / 'vapi')
# endif

executable (
    meson.project_name (),
    'src/Util.vala',
    'src/Application.vala',
    'src/MainWindow.vala',
    
    'src/Layouts/Sidebar.vala',
    'src/Layouts/FilterPaneRow.vala',
    'src/Layouts/HeaderItem.vala',
    'src/Layouts/LabelRow.vala',
    'src/Layouts/ItemRow.vala',
    'src/Layouts/ProjectRow.vala',
    'src/Layouts/ViewHeader.vala',
    'src/Layouts/SectionRow.vala',
    'src/Layouts/LabelChild.vala',
    'src/Layouts/SectionChild.vala',

    'src/Widgets/Entry.vala',
    'src/Widgets/DynamicIcon.vala',
    'src/Widgets/TodoistSync.vala',
    'src/Widgets/ProjectProgress.vala',
    'src/Widgets/EditableLabel.vala',
    'src/Widgets/TopHeaderProject.vala',
    'src/Widgets/ColorPopover.vala',
    'src/Widgets/MagicButton.vala',
    'src/Widgets/HyperTextView.vala',
    'src/Widgets/LoadingButton.vala',
    'src/Widgets/ProjectButton.vala',
    'src/Widgets/PinButton.vala',
    'src/Widgets/IconColorProject.vala',
    'src/Widgets/ItemSummary.vala',
    'src/Widgets/ScheduleButton.vala',
    'src/Widgets/PriorityButton.vala',
    'src/Widgets/LabelButton.vala',
    'src/Widgets/ItemLabels.vala',
    'src/Widgets/ItemLabelChild.vala',
    'src/Widgets/Placeholder.vala',

    'src/Widgets/Calendar/Calendar.vala',
    'src/Widgets/Calendar/CalendarDay.vala',
    'src/Widgets/Calendar/CalendarHeader.vala',
    'src/Widgets/Calendar/CalendarView.vala',
    'src/Widgets/Calendar/CalendarWeek.vala',

    'src/Views/Welcome.vala',
    'src/Views/Project.vala',
    'src/Views/List.vala',
    'src/Views/Today.vala',
    'src/Views/Date.vala',
    'src/Views/Pinboard.vala',
    'src/Views/Scheduled/Scheduled.vala',
    'src/Views/Scheduled/ScheduledHeader.vala',
    'src/Views/Scheduled/ScheduledDay.vala',
    'src/Views/Label.vala',
    'src/Views/Board.vala',

    'src/Dialogs/TodoistOAuth.vala',
    'src/Dialogs/Project.vala',
    'src/Dialogs/Label.vala',
    'src/Dialogs/MessageDialog.vala',
    'src/Dialogs/QuickFind/QuickFind.vala',
    'src/Dialogs/QuickFind/QuickFindItem.vala',
    'src/Dialogs/QuickFind/Synapse.vala',

    'src/Dialogs/Settings/Settings.vala',
    'src/Dialogs/Settings/SettingsHeader.vala',
    'src/Dialogs/Settings/SettingsContent.vala',
    'src/Dialogs/Settings/SettingsItem.vala',
    
    'src/Dialogs/ProjectPicker/ProjectPicker.vala',
    'src/Dialogs/ProjectPicker/ProjectRow.vala',
    'src/Dialogs/ProjectPicker/SectionRow.vala',
    
    'src/Dialogs/DateTimePicker/DateTimePicker.vala',
    'src/Dialogs/DateTimePicker/TimePicker.vala',

    'src/Dialogs/LabelPicker/LabelPicker.vala',
    'src/Dialogs/LabelPicker/LabelRow.vala',
    
    'src/Dialogs/ContextMenu/Menu.vala',
    'src/Dialogs/ContextMenu/MenuItem.vala',
    'src/Dialogs/ContextMenu/MenuItemSelector.vala',
    'src/Dialogs/ContextMenu/MenuSeparator.vala',
    'src/Dialogs/ContextMenu/MenuCalendarPicker.vala',
    'src/Dialogs/ContextMenu/MenuSwitch.vala',

    'src/Services/EventBus.vala',
    'src/Services/Database.vala',
    'src/Services/Todoist.vala',
    'src/Services/ActionManager.vala',
    'src/Services/Badge.vala',

    'src/Objects/v2.vala',
    'src/Objects/BaseObject.vala',
    'src/Objects/Project.vala',
    'src/Objects/Label.vala',
    'src/Objects/Section.vala',
    'src/Objects/Item.vala',
    'src/Objects/Color.vala',
    'src/Objects/DueDate.vala',
    'src/Objects/ItemLabel.vala',
    gresource,
    config_file,
    dependencies: planner_deps,
    install: true
)

subdir('data')
subdir('po')
meson.add_install_script('build-aux/meson/post_install.py')