deps = [
  core_dep,
  glib_dep,
  gee_dep,
  gtk_dep,
  sqlite3_dep,
  libadwaita_dep,
  webkitgtk_dep,
  gtksourceview_dep,
  granite_dep,
  json_dep,
  libsoup_dep,
  libecal_dep,
  libedataserver_dep,
  libical_dep,
  libportal_dep,
  m_dep
]

sources = files(
  'App.vala',
  'MainWindow.vala',

  'Objects/Backup.vala',

  'Services/GoogleTasks.vala',
  'Services/ActionManager.vala',
  'Services/Notification.vala',
  'Services/TimeMonitor.vala',
  'Services/DBusServer.vala',
  'Services/Backups.vala',

  'Services/CalendarEvents/CalendarEvents.vala',
  'Services/CalendarEvents/DateIterator.vala',
  'Services/CalendarEvents/DateRange.vala',
  'Services/CalendarEvents/Util.vala',

  'Layouts/Sidebar.vala',
  'Layouts/FilterPaneRow.vala',
  'Layouts/ProjectRow.vala',
  'Layouts/SectionRow.vala',
  'Layouts/ItemRow.vala',
  'Layouts/LabelRow.vala',
  'Layouts/SectionBoard.vala',
  'Layouts/ItemBoard.vala',
  'Layouts/HeaderBar.vala',
  
  'Widgets/ColorPickerRow.vala',
  'Widgets/MagicButton.vala',
  'Widgets/EditableLabel.vala',
  'Widgets/Placeholder.vala',
  'Widgets/SyncButton.vala',
  'Widgets/ReminderButton.vala',
  'Widgets/MultiSelectToolbar.vala',
  'Widgets/EventsList.vala',
  'Widgets/EventRow.vala',
  'Widgets/SubItems.vala',
  'Widgets/LabelChild.vala',
  'Widgets/LabelsSummary.vala',
  'Widgets/SectionsOrderPopover.vala',
  'Widgets/ScrolledWindow.vala',
  'Widgets/ReorderChild.vala',

  'Widgets/ReminderPicker/ReminderPicker.vala',
  'Widgets/ReminderPicker/ReminderRow.vala',

  'Views/Project/Project.vala',
  'Views/Project/List.vala',
  'Views/Project/Board.vala',
  'Views/Today.vala',
  'Views/Pinboard.vala',
  'Views/Label/Label.vala',
  'Views/Label/Labels.vala',
  'Views/Filter.vala',
  
  'Views/Scheduled/Scheduled.vala',
  'Views/Scheduled/ScheduledDay.vala',
  'Views/Scheduled/ScheduledRange.vala',
  'Views/Scheduled/ScheduledMonth.vala',

  'Dialogs/Project.vala',
  'Dialogs/Label.vala',
  'Dialogs/Item.vala',
  'Dialogs/GoogleOAuth.vala',
  'Dialogs/WhatsNew.vala',
  'Dialogs/QuickAdd.vala',
  'Dialogs/ProjectDescription.vala',
  'Dialogs/ManageSectionOrder.vala',
  'Dialogs/ProjectPicker/ProjectPicker.vala',
  'Dialogs/ProjectPicker/ProjectPickerRow.vala',
  'Dialogs/ProjectPicker/SectionPickerRow.vala',

  'Dialogs/DatePicker.vala',
  'Dialogs/LabelPicker.vala',
  'Dialogs/RepeatConfig.vala',
  
  'Dialogs/QuickFind/QuickFind.vala',
  'Dialogs/QuickFind/QuickFindItem.vala',
  'Dialogs/QuickFind/Synapse.vala',

  'Dialogs/Preferences/PreferencesWindow.vala',
  'Dialogs/Preferences/SettingsHeader.vala',
  'Dialogs/Preferences/Pages/Backup.vala',
  'Dialogs/Preferences/Pages/Sidebar.vala'
)

executable(
  application_id,
  sources,
  asresources,
  config_file,
  dependencies: deps,
  install: true
)
