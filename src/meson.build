deps = [
  core_dep,
  gee_dep,
  libedataserver_dep,
  libportal_dep,
  libportal_gtk4_dep,
  m_dep
]

if get_option('webkit')
    if webkitgtk_dep.found()
        deps += webkitgtk_dep
    endif
endif

sources = files(
  'App.vala',
  'MainWindow.vala',

  'Objects/Backup.vala',

  # 'Services/GoogleTasks.vala', No longer used?
  'Services/ActionManager.vala',
  'Services/Notification.vala',
  'Services/TimeMonitor.vala',
  'Services/DBusServer.vala',
  'Services/Backups.vala',
  'Services/MigrateFromPlanner.vala',

  'Services/CalendarEvents/CalendarEvents.vala',
  'Services/CalendarEvents/DateIterator.vala',
  'Services/CalendarEvents/DateRange.vala',
  'Services/CalendarEvents/Util.vala',
  
  'Layouts/Sidebar.vala',
  'Layouts/FilterPaneChild.vala',
  'Layouts/FilterPaneRow.vala',
  'Layouts/ProjectRow.vala',
  'Layouts/SectionRow.vala',
  'Layouts/ItemBase.vala',
  'Layouts/ItemRow.vala',
  'Layouts/ItemBoard.vala',
  'Layouts/LabelRow.vala',
  'Layouts/ItemSidebarView.vala',
  'Layouts/SectionBoard.vala',
  'Layouts/HeaderBar.vala',
  'Layouts/SidebarSourceRow.vala',
  'Layouts/ProjectContainerRow.vala',
  
  'Widgets/ColorPickerRow.vala',
  'Widgets/MagicButton.vala',
  'Widgets/EditableTextView.vala',
  'Widgets/SyncButton.vala',
  'Widgets/MultiSelectToolbar.vala',
  'Widgets/EventsList.vala',
  'Widgets/EventRow.vala',
  'Widgets/SubItems.vala',
  'Widgets/LabelsSummary.vala',
  'Widgets/SectionsOrderPopover.vala',
  'Widgets/ScrolledWindow.vala',
  'Widgets/ReorderChild.vala',
  'Widgets/FilterFlowBox.vala',
  'Widgets/FilterFlowBoxChild.vala',
  'Widgets/IgnoreSSLSwitchRow.vala',
  'Widgets/Attachments.vala',
  'Widgets/AttachmentRow.vala',
  'Widgets/ItemChangeHistoryRow.vala',
  'Widgets/SourceRow.vala',
  'Widgets/ErrorView.vala',
  'Widgets/CompletedTaskRow.vala',
  'Widgets/ItemDetailCompleted.vala',
  'Widgets/PinnedItemsFlowBox.vala',

  'Views/Project/Project.vala',
  'Views/Project/List.vala',
  'Views/Project/Board.vala',
  'Views/Today.vala',
  'Views/Label/Label.vala',
  'Views/Label/Labels.vala',
  'Views/Label/LabelSourceRow.vala',
  'Views/Filter.vala',
  
  'Views/Scheduled/Scheduled.vala',
  'Views/Scheduled/ScheduledDay.vala',
  'Views/Scheduled/ScheduledRange.vala',
  'Views/Scheduled/ScheduledMonth.vala',

  'Dialogs/Project.vala',
  'Dialogs/Section.vala',
  'Dialogs/Label.vala',
  #'Dialogs/GoogleOAuth.vala', No longer used?
  'Dialogs/WhatsNew.vala',
  'Dialogs/QuickAdd.vala',
  'Dialogs/ManageSectionOrder.vala',
  'Dialogs/ProjectPicker/ProjectPicker.vala',
  'Dialogs/ProjectPicker/ProjectPickerRow.vala',
  'Dialogs/ProjectPicker/SectionPickerRow.vala',
  'Dialogs/ProjectPicker/ProjectPickerSourceRow.vala',
  'Dialogs/ManageProjects.vala',
  'Dialogs/DatePicker.vala',
  'Dialogs/LabelPicker.vala',
  'Dialogs/ItemChangeHistory.vala',
  'Dialogs/ErrorDialog.vala',
  'Dialogs/CompletedTasks.vala',
  
  'Dialogs/QuickFind/QuickFind.vala',
  'Dialogs/QuickFind/QuickFindItem.vala',
  'Dialogs/QuickFind/Synapse.vala',

  'Dialogs/Preferences/PreferencesWindow.vala',
  'Dialogs/Preferences/SettingsHeader.vala',
  'Dialogs/Preferences/Pages/Backup.vala',
  'Dialogs/Preferences/Pages/Sidebar.vala',
  'Dialogs/Preferences/Pages/Accounts.vala',
  'Dialogs/Preferences/Pages/Appearance.vala',
  'Dialogs/Preferences/Pages/NextcloudSetup.vala',
  'Dialogs/Preferences/Pages/CalDAVSetup.vala',
  'Dialogs/Preferences/Pages/HomeView.vala',
  'Dialogs/Preferences/Pages/TodoistSetup.vala',
)

executable(
  application_id,
  sources,
  asresources,
  config_file,
  dependencies: deps,
  install: true
)


