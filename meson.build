project(
  'com.github.alainm23.planner',
  'vala', 'c',
  version: '3.10'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

asresources = gnome.compile_resources (
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

executable(
  meson.project_name(),
  'src/App.vala',
  'src/MainWindow.vala',
  'src/Utils.vala',

  'src/Services/Database.vala',
  'src/Services/EventBus.vala',
  'src/Services/Todoist.vala',

  'src/Layouts/Sidebar.vala',
  'src/Layouts/FilterPaneRow.vala',
  'src/Layouts/HeaderItem.vala',
  'src/Layouts/ProjectRow.vala',
  'src/Layouts/SectionRow.vala',
  'src/Layouts/ItemRow.vala',
  
  'src/Widgets/DynamicIcon.vala',
  'src/Widgets/ColorPickerRow.vala',
  'src/Widgets/EntryRow.vala',
  'src/Widgets/LoadingButton.vala',
  'src/Widgets/SwitchRow.vala',
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

  'src/Widgets/Calendar/Calendar.vala',
  'src/Widgets/Calendar/CalendarDay.vala',
  'src/Widgets/Calendar/CalendarHeader.vala',
  'src/Widgets/Calendar/CalendarView.vala',
  'src/Widgets/Calendar/CalendarWeek.vala',

  'src/Widgets/DateTimePicker/DateTimePicker.vala',
  'src/Widgets/DateTimePicker/TimePicker.vala',

  'src/Widgets/LabelPicker/LabelPicker.vala',
  'src/Widgets/LabelPicker/LabelRow.vala',
  
  'src/Widgets/ContextMenu/MenuItem.vala',
  'src/Widgets/ContextMenu/MenuSeparator.vala',

  'src/Views/Project.vala',
  'src/Views/List.vala',
  'src/Views/Date.vala',
  'src/Views/Today.vala',
  'src/Views/Pinboard.vala',

  'src/Objects/BaseObject.vala',
  'src/Objects/Color.vala',
  'src/Objects/DueDate.vala',
  'src/Objects/Item.vala',
  'src/Objects/ItemLabel.vala',
  'src/Objects/Label.vala',
  'src/Objects/Pinboard.vala',
  'src/Objects/Project.vala',
  'src/Objects/Queue.vala',
  'src/Objects/Reminder.vala',
  'src/Objects/Scheduled.vala',
  'src/Objects/Section.vala',
  # 'src/Objects/SourceTaskList.vala',
  # 'src/Objects/Task.vala',
  'src/Objects/Today.vala',

  'src/Dialogs/Project.vala',
  'src/Dialogs/TodoistOAuth.vala',

  asresources,
  config_file,
  dependencies: [
    dependency('glib-2.0'),
    dependency('gee-0.8', version: '>=0.8.5'),
    dependency('gtk4'),
    dependency('sqlite3'),
    dependency('libadwaita-1'),
    dependency('webkit2gtk-5.0'),
    dependency('granite-7'),
    dependency('json-glib-1.0'),
    meson.get_compiler('c').find_library('m', required : false)
  ],
  install: true
)
subdir('data')
# subdir('po')

meson.add_install_script('build-aux/meson'/ 'post_install.py')