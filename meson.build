project(
  'com.github.alainm23.task-planner',
  'vala', 'c',
  version: '4.0'
)

gnome = import('gnome')
i18n = import('i18n')

base_id = 'com.github.alainm23.task-planner'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')

asresources = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name () + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

if get_option('production') == false
  profile = 'devel'
  vcs_tag = run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
  if vcs_tag == ''
    version_suffix = '-devel'
  else
    version_suffix = '-@0@'.format(vcs_tag)
  endif
  application_id = '@0@.@1@'.format(base_id, profile)
  production = 'false'
else
  profile = ''
  version_suffix = ''
  application_id = base_id
  production = 'true'
endif

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', application_id)
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PRODUCTION', production)
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
config_file = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

planner_deps = [
  dependency('glib-2.0'),
  dependency('gee-0.8', version: '>=0.8.5'),
  dependency('gtk4'),
  dependency('sqlite3'),
  dependency('libadwaita-1'),
  dependency('webkit2gtk-5.0'),
  dependency('granite-7'),
  dependency('json-glib-1.0'),
  dependency('libecal-2.0', version: '>= 3.45.1'),
  dependency('libedataserver-1.2', version: '>= 3.45.1'),
  dependency('libical-glib'),
  meson.get_compiler('c').find_library('m', required : false)
]

planner_files = files(
  'src/App.vala',
  'src/MainWindow.vala',
  'src/Util.vala',
  'src/Enum.vala',

  'src/Services/Database.vala',
  'src/Services/EventBus.vala',
  'src/Services/Todoist.vala',
  'src/Services/ActionManager.vala',
  'src/Services/Notification.vala',
  'src/Services/TimeMonitor.vala',
  'src/Services/DBusServer.vala',

  'src/Services/CalendarEvents/CalendarEvents.vala',
  'src/Services/CalendarEvents/DateIterator.vala',
  'src/Services/CalendarEvents/DateRange.vala',
  'src/Services/CalendarEvents/Util.vala',

  'src/Layouts/Sidebar.vala',
  'src/Layouts/FilterPaneRow.vala',
  'src/Layouts/HeaderItem.vala',
  'src/Layouts/ProjectRow.vala',
  'src/Layouts/SectionRow.vala',
  'src/Layouts/ItemRow.vala',
  'src/Layouts/LabelRow.vala',
  
  'src/Widgets/DynamicIcon.vala',
  'src/Widgets/ColorPickerRow.vala',
  'src/Widgets/LoadingButton.vala',
  'src/Widgets/CircularProgressBar.vala',
  'src/Widgets/MagicButton.vala',
  'src/Widgets/HeaderProject.vala',
  'src/Widgets/EditableLabel.vala',
  'src/Widgets/Entries.vala',
  'src/Widgets/Placeholder.vala',
  'src/Widgets/SyncButton.vala',
  'src/Widgets/ScheduleButton.vala',
  'src/Widgets/PriorityButton.vala',
  'src/Widgets/ItemSummary.vala',
  'src/Widgets/PinButton.vala',
  'src/Widgets/LabelButton.vala',
  'src/Widgets/ItemLabels.vala',
  'src/Widgets/ItemLabelChild.vala',
  'src/Widgets/ProjectViewHeaderBar.vala',
  'src/Widgets/IconColorProject.vala',
  'src/Widgets/LabelsHeader.vala',
  'src/Widgets/ReminderButton.vala',
  'src/Widgets/MultiSelectToolbar.vala',
  'src/Widgets/EventsList.vala',
  'src/Widgets/EventRow.vala',
  'src/Widgets/CalendarSourceRow.vala',
  'src/Widgets/SettingsHeader.vala',

  'src/Widgets/Calendar/Calendar.vala',
  'src/Widgets/Calendar/CalendarDay.vala',
  'src/Widgets/Calendar/CalendarHeader.vala',
  'src/Widgets/Calendar/CalendarView.vala',
  'src/Widgets/Calendar/CalendarWeek.vala',

  'src/Widgets/DateTimePicker/DateTimePicker.vala',
  'src/Widgets/DateTimePicker/TimePicker.vala',

  'src/Widgets/LabelPicker/LabelPicker.vala',
  'src/Widgets/LabelPicker/LabelRow.vala',

  'src/Widgets/ReminderPicker/ReminderPicker.vala',
  'src/Widgets/ReminderPicker/ReminderRow.vala',
  
  'src/Widgets/ContextMenu/MenuItem.vala',
  'src/Widgets/ContextMenu/MenuSeparator.vala',
  'src/Widgets/ContextMenu/MenuItemPicker.vala',

  'src/Views/Project.vala',
  'src/Views/List.vala',
  'src/Views/Date.vala',
  'src/Views/Today.vala',
  'src/Views/Pinboard.vala',
  'src/Views/Label.vala',
  'src/Views/Filter.vala',
  
  'src/Views/Scheduled/Scheduled.vala',
  'src/Views/Scheduled/ScheduledDay.vala',
  'src/Views/Scheduled/ScheduledRange.vala',
  'src/Views/Scheduled/ScheduledMonth.vala',

  'src/Objects/BaseObject.vala',
  'src/Objects/Color.vala',
  'src/Objects/DueDate.vala',
  'src/Objects/Item.vala',
  'src/Objects/ItemLabel.vala',
  'src/Objects/Label.vala',
  'src/Objects/Project.vala',
  'src/Objects/Queue.vala',
  'src/Objects/Reminder.vala',
  'src/Objects/Section.vala',
  
  'src/Objects/Filters/Pinboard.vala',
  'src/Objects/Filters/Scheduled.vala',
  'src/Objects/Filters/Today.vala',
  'src/Objects/Filters/Priority.vala',
  'src/Objects/Filters/Completed.vala',

  'src/Dialogs/Project.vala',
  'src/Dialogs/Label.vala',
  'src/Dialogs/TodoistOAuth.vala',
  'src/Dialogs/ProjectPicker/ProjectPicker.vala',
  'src/Dialogs/ProjectPicker/ProjectPickerRow.vala',
  'src/Dialogs/DatePicker.vala',
  'src/Dialogs/LabelPicker.vala',
  'src/Dialogs/RepeatConfig.vala',
  
  'src/Dialogs/QuickFind/QuickFind.vala',
  'src/Dialogs/QuickFind/QuickFindItem.vala',
  'src/Dialogs/QuickFind/Synapse.vala',

  'src/Dialogs/Preferences/PreferencesWindow.vala',
)

quick_find_files = files(
    'quick-add/App.vala',
    'quick-add/MainWindow.vala',
    'quick-add/Util.vala',
    'src/Enum.vala',

    'quick-add/Objects/BaseObject.vala',
    'quick-add/Objects/Color.vala',
    'quick-add/Objects/DueDate.vala',
    'quick-add/Objects/Item.vala',
    'quick-add/Objects/Project.vala',
    'quick-add/Objects/Queue.vala',

    'quick-add/Services/EventBus.vala',
    'quick-add/Services/Database.vala',
    'quick-add/Services/DBusClient.vala',
    'quick-add/Services/Todoist.vala',

    'quick-add/Widgets/DynamicIcon.vala',
    'quick-add/Widgets/LoadingButton.vala',
    'quick-add/Widgets/HyperTextView.vala',
)

executable(
  application_id,
  planner_files,
  asresources,
  config_file,
  dependencies: planner_deps,
  install: true
)

executable (
    'com.github.alainm23.task-planner.quick-add',
    quick_find_files,
    asresources,
    config_file,
    dependencies: planner_deps,
    install: true
)

subdir('data')
subdir('po')
meson.add_install_script('build-aux/meson'/ 'post_install.py')