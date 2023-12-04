project(
  'io.github.alainm23.planify',
  'vala', 'c',
  version: '4.2'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')

############
# Resources #
############

asresources = gnome.compile_resources (
    'as-resources', 'data/resources/io.github.alainm23.planify.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)


###########
# Profile #
###########

profile = get_option('profile')
if profile == 'development'
  find_program('git')
  rev_txt = run_command('git','rev-parse','--short','HEAD').stdout().strip()
  rev = '-@0@'.format(rev_txt)
  application_id = 'io.github.alainm23.planify.Devel'
else
  rev = ''
  application_id = 'io.github.alainm23.planify'
endif

############
# config.vala #
############

conf_data = configuration_data()
conf_data.set_quoted('APPLICATION_ID', application_id)
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
conf_data.set_quoted('PACKAGE_VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
conf_data.set_quoted('PROFILE', profile)

config_file = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

subdir('src')
subdir('quick-add')
subdir('data')
subdir('po')

summary({
  'Tracing': get_option('tracing'),
  'Profile': get_option('profile'),
}, section: 'Development')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
