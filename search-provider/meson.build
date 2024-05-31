search_provider_c_args = [
  '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
  '-DG_LOG_DOMAIN="PlanifySearchProvider"',
]

search_provider_sources = [
  'main.vala',
  'search-provider.vala'
]

search_provider_deps = [
  gio_dep,
  gtk_dep,
  sqlite3_dep,
]

executable (
  'io.github.alainmh23.planify-search-provider',
  search_provider_sources,
  config_file,
  dependencies: search_provider_deps,
  c_args: search_provider_c_args,
  install: true,
  install_dir: libexecdir
)

search_provider_conf = configuration_data()
search_provider_conf.set('appid', application_id)
search_provider_conf.set('path', application_path)
configure_file(
  configuration: search_provider_conf,
  input: 'io.github.alainm23.planify.SearchProvider.ini.in',
  install_dir: datadir / 'gnome-shell' / 'search-providers',
  install: true,
  output: '@0@.SearchProvider.ini'.format(application_id)
)

search_provider_dbus_conf = configuration_data()
search_provider_dbus_conf.set('appid', application_id)
search_provider_dbus_conf.set('libexecdir', libexecdir)
configure_file (
  input: 'io.github.alainm23.planify.SearchProvider.service.in',
  output: '@0@.SearchProvider.service'.format(application_id),
  configuration: search_provider_dbus_conf,
  install: true,
  install_dir: datadir / 'dbus-1' / 'services'
)
