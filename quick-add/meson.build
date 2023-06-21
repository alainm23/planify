quick_find_sources = files(
    'App.vala',
    'MainWindow.vala',
    'Util.vala',
    'Enum.vala',
    'ObjectsPatch.vala',

    'Objects/BaseObject.vala',
    'Objects/Color.vala',
    'Objects/DueDate.vala',
    'Objects/Item.vala',
    'Objects/Project.vala',
    'Objects/Queue.vala',

    'Services/Settings.vala',
    'Services/EventBus.vala',
    'Services/Database.vala',
    'Services/DBusClient.vala',
    'Services/Todoist.vala',
    
    'Widgets/DynamicIcon.vala',
    'Widgets/HyperTextView.vala',
    'Widgets/LoadingButton.vala',
    'Widgets/ProjectPickerRow.vala',
    'Widgets/IconColorProject.vala',
    'Widgets/HeaderItem.vala',
    'Widgets/ProjectPicker.vala'
)

executable(
  'io.github.alainm23.planify.quick-add',
  quick_find_sources,
  asresources,
  config_file,
  dependencies: deps,
  install: true
)