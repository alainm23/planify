quick_find_sources = files(
  'Services/DBusClient.vala',
  'App.vala',
  'MainWindow.vala',
)

executable(
  'io.github.alainm23.planify.quick-add',
  quick_find_sources,
  asresources,
  config_file,
  dependencies: deps,
  install: true,
)

# CLI executable
cli_sources = files(
  'Services/DBusClient.vala',
  'cli/ArgumentParser.vala',
  'cli/TaskValidator.vala',
  'cli/TaskCreator.vala',
  'cli/OutputFormatter.vala',
  'cli/Main.vala',
)

executable(
  'io.github.alainm23.planify.cli',
  cli_sources,
  config_file,
  dependencies: deps,
  install: true,
)
