quick_find_sources = files(
    'App.vala',
    'MainWindow.vala',

    'Services/DBusClient.vala',
    
    'Widgets/HyperTextView.vala',
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