core_files = files(
    'Enum.vala',
    'Constants.vala',
    'QuickAdd.vala',

    'Utils/Util.vala',
    'Utils/Datetime.vala',
    'Utils/MarkdownProcessor.vala',

    'Services/Settings.vala',
    'Services/EventBus.vala',
    'Services/Database.vala',
    'Services/Store.vala',
    'Services/Todoist.vala',
    'Services/ColorSchemeSettings.vala',

    'Services/CalDAV/Core.vala',
    'Services/CalDAV/CalDAVClient.vala',
    'Services/CalDAV/WebDAVClient.vala',
    'Services/CalDAV/Providers/Nextcloud.vala',

    'Services/Chrono/Chrono.vala',
    'Services/Chrono/Enum.vala',
    'Services/Chrono/Types.vala',
    'Services/Chrono/Locales/En/En.vala',
    'Services/Chrono/Locales/En/Constants.vala',
    'Services/Chrono/Locales/En/Parsers/ENCasualDateParser.vala',

    'Layouts/HeaderItem.vala',

    'Widgets/LoadingButton.vala',
    'Widgets/Entries.vala',
    'Widgets/IconColorProject.vala',
    'Widgets/PinButton.vala',
    'Widgets/PriorityButton.vala',
    'Widgets/ItemLabels.vala',
    'Widgets/ItemLabelChild.vala',
    'Widgets/CircularProgressBar.vala',
    'Widgets/StatusButton.vala',
    'Widgets/LabelsPickerCore.vala',

    'Widgets/Calendar/Calendar.vala',
    'Widgets/Calendar/CalendarDay.vala',
    'Widgets/Calendar/CalendarHeader.vala',
    'Widgets/Calendar/CalendarView.vala',
    'Widgets/Calendar/CalendarWeek.vala',

    'Widgets/ContextMenu/MenuItem.vala',
    'Widgets/ContextMenu/MenuSeparator.vala',
    'Widgets/ContextMenu/MenuPicker.vala',
    'Widgets/ContextMenu/MenuCheckPicker.vala',
    'Widgets/ContextMenu/MenuSwitch.vala',
    
    'Widgets/DateTimePicker/ScheduleButton.vala',
    'Widgets/DateTimePicker/DateTimePicker.vala',
    'Widgets/DateTimePicker/TimePicker.vala',
    'Widgets/DateTimePicker/RepeatConfig.vala',

    'Widgets/LabelPicker/LabelPicker.vala',
    'Widgets/LabelPicker/LabelRow.vala',
    'Widgets/LabelPicker/LabelButton.vala',

    'Widgets/ProjectPicker/ProjectPickerPopover.vala',
    'Widgets/ProjectPicker/ProjectPickerRow.vala',
    'Widgets/ProjectPicker/ProjectPickerButton.vala',
    'Widgets/ProjectPicker/SectionPickerRow.vala',

    'Widgets/SectionPicker/SectionButton.vala',
    'Widgets/SectionPicker/SectionPicker.vala',
    'Widgets/SectionPicker/SectionPickerRow.vala',

    'Widgets/ReminderPicker/ReminderButton.vala',
    'Widgets/ReminderPicker/ReminderPicker.vala',
    'Widgets/ReminderPicker/ReminderRow.vala',

    'Widgets/Markdown/MarkdownEditView.vala',
    'Widgets/Markdown/MarkdownView.vala',
    'Widgets/Markdown/Color.vala',
    'Widgets/Markdown/MarkdownBuffer.vala',

    'Objects/BaseObject.vala',
    'Objects/Color.vala',
    'Objects/DueDate.vala',
    'Objects/Item.vala',
    'Objects/Label.vala',
    'Objects/Project.vala',
    'Objects/Queue.vala',
    'Objects/Reminder.vala',
    'Objects/Section.vala',
    'Objects/Promise.vala',
    'Objects/Attachment.vala',
    'Objects/ObjectEvent.vala',
    'Objects/Source.vala',
    
    'Objects/Filters/Inbox.vala',
    'Objects/Filters/Pinboard.vala',
    'Objects/Filters/Scheduled.vala',
    'Objects/Filters/Today.vala',
    'Objects/Filters/Priority.vala',
    'Objects/Filters/Completed.vala',
    'Objects/Filters/Labels.vala',
    'Objects/Filters/Tomorrow.vala',
    'Objects/Filters/Anytime.vala',
    'Objects/Filters/Repeating.vala',
    'Objects/Filters/Unlabeled.vala',
    'Objects/Filters/FilterItem.vala',
    'Objects/Filters/AllItems.vala'
)

core_deps = [
  gio_dep,
  glib_dep,
  gee_dep,
  gtk_dep,
  sqlite3_dep,
  libadwaita_dep,
  json_dep,
  libsoup_dep,
  gtksourceview_dep,
  libical_dep,
  libecal_dep,
  libgxml_dep,
  libsecret_dep,
  libspelling
]

core_lib = shared_library(
    'planify',
    core_files,
    dependencies: [ core_deps, m_dep ],
    install: true,
    install_dir: [true, join_paths(get_option('includedir'), 'planify'), true],
    soversion: '0',
    version: '0.1'
)

core_dep = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('.')
)

install_data(
    'planify.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

pkgconfig.generate(
    core_lib,
    filebase: 'planify',
    version: meson.project_version(),
    name: 'Planify',
    description: 'Extension endpoint to the Planify application',
    subdirs: 'planify',
    libraries: core_deps
)

