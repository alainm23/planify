deps = [
  core_dep,
  gee_dep,
  m_dep
]

if get_option('webkit')
    if webkitgtk_dep.found()
        deps += webkitgtk_dep
    endif
endif


if get_option('portal')
    if libportal_dep.found()
        deps += libportal_dep
    endif
    if libportal_gtk4_dep.found()
        deps += libportal_gtk4_dep
    endif
endif


if get_option('evolution')
    if libedataserver_dep.found()
        deps += libedataserver_dep
    endif
endif


sources = files(
  'App.vala',
  'MainWindow.vala',

  'Objects/Backup.vala',
  'Services/ActionManager.vala',
  'Services/Api.vala',
  'Services/Notification.vala',
  'Services/TimeMonitor.vala',
  'Services/DBusServer.vala',
  'Services/Backups.vala',
  'Services/MigrateFromPlanner.vala',

  'Utils/TaskUtils.vala',

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
  'Widgets/SubItems.vala',
  'Widgets/LabelsSummary.vala',
  'Widgets/SectionsOrderPopover.vala',
  'Widgets/ScrolledWindow.vala',
  'Widgets/ReorderChild.vala',
  'Widgets/FilterFlowBox.vala',
  'Widgets/FilterFlowBoxChild.vala',
  'Widgets/BypassResolveSwitchRow.vala',
  'Widgets/IgnoreSSLSwitchRow.vala',
  'Widgets/Attachments.vala',
  'Widgets/AttachmentRow.vala',
  'Widgets/ItemChangeHistoryRow.vala',
  'Widgets/ErrorView.vala',
  'Widgets/CompletedTaskRow.vala',
  'Widgets/ItemDetailCompleted.vala',
  'Widgets/PinnedItemsBox.vala',
  'Widgets/TranslationRow.vala',
  'Widgets/NewVersionPopup.vala',
  'Widgets/ProjectItemRow.vala',
  'Widgets/SectionItemRow.vala',
  'Widgets/ComboWrapRow.vala',

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
  'Views/Scheduled/ScheduledOverdue.vala',

  'Dialogs/Project.vala',
  'Dialogs/Section.vala',
  'Dialogs/Label.vala',
  'Dialogs/QuickAdd.vala',
  'Dialogs/ManageSectionOrder.vala',
  'Dialogs/ProjectPicker.vala',
  'Dialogs/ManageProjects.vala',
  'Dialogs/DatePicker.vala',
  'Dialogs/LabelPicker.vala',
  'Dialogs/ItemChangeHistory.vala',
  'Dialogs/ErrorDialog.vala',
  'Dialogs/CompletedTasks.vala',
  
  'Dialogs/QuickFind/QuickFind.vala',
  'Dialogs/QuickFind/QuickFindItem.vala',
  'Dialogs/QuickFind/QuickFindSectionSorter.vala',
  'Dialogs/QuickFind/QuickFindFactory.vala',
  'Dialogs/QuickFind/Synapse.vala',

  'Dialogs/Preferences/PreferencesWindow.vala',
  'Dialogs/Preferences/Pages/BasePage.vala',
  'Dialogs/Preferences/Pages/Backup.vala',
  'Dialogs/Preferences/Pages/Sidebar.vala',
  'Dialogs/Preferences/Pages/Appearance.vala',
  'Dialogs/Preferences/Pages/HomeView.vala',
  'Dialogs/Preferences/Pages/General.vala',
  'Dialogs/Preferences/Pages/TaskSetting.vala',
  'Dialogs/Preferences/Pages/QuickAdd.vala',
  'Dialogs/Preferences/Pages/Donate.vala',
  'Dialogs/Preferences/Pages/Accounts/Accounts.vala',
  'Dialogs/Preferences/Pages/Accounts/NextcloudSetup.vala',
  'Dialogs/Preferences/Pages/Accounts/CalDAVSetup.vala',
  'Dialogs/Preferences/Pages/Accounts/TodoistSetup.vala',
  'Dialogs/Preferences/Pages/Accounts/SourceView.vala',
  'Dialogs/Preferences/Pages/Accounts/InboxPage.vala'
)

if get_option('evolution')
    sources += 'Widgets/EventRow.vala'
    sources += 'Widgets/EventsList.vala'
    sources += 'Dialogs/CalendarSync.vala'
endif

executable(
  application_id,
  sources,
  asresources,
  config_file,
  dependencies: deps,
  install: true
)


