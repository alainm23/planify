# Desktop
desktop_conf = configuration_data()
desktop_conf.set('exec', application_id)
desktop_conf.set('icon', application_id)
desktop_file = i18n.merge_file(
  input: configure_file(
    input: files('io.github.alainm23.planify.desktop.in.in'),
    output: 'io.github.alainm23.planify.desktop.in',
    configuration: desktop_conf,
  ),
  output: '@0@.desktop'.format(application_id),
  type: 'desktop',
  po_dir: join_paths(meson.project_source_root(), 'po'),
  install: true,
  install_dir: get_option('datadir') / 'applications',
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif


# AppStream 
appdata_conf = configuration_data()
appdata_conf.set('appid', application_id)
appstream_file = i18n.merge_file(
  input: configure_file(
    input: files('io.github.alainm23.planify.appdata.xml.in.in'),
    output: 'io.github.alainm23.planify.appdata.xml.in',
    configuration: appdata_conf
  ),
  output: '@0@.appdata.xml'.format(application_id),
  po_dir: join_paths(meson.project_source_root(), 'po'),
  install: true,
  install_dir: get_option('datadir') / 'appdata',
)

install_data('io.github.alainm23.planify.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0/schemas',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()]
  )
endif

install_data('markdown.xml',
  install_dir: get_option('datadir') / 'gtksourceview-5' / 'styles'
)
install_data('markdown_dark.xml',
  install_dir: get_option('datadir') / 'gtksourceview-5' / 'styles'
)
install_data('markdownpp.lang',
  install_dir: get_option('datadir') / 'gtksourceview-5' / 'language-specs'
)

subdir('icons')