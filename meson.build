project(
  'io.github.alainm23.planify',
  'vala', 'c',
  version: '4.19.5'
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
  application_path = '/io/github/alainm23/planify/Devel'
  add_project_arguments(['--define=DEVELOPMENT'], language: 'vala')
else
  rev = ''
  application_id = 'io.github.alainm23.planify'
  application_path = '/io/github/alainm23/planify'
endif

################
# Dependencies #
################


cc = meson.get_compiler('c')

gnome = import('gnome')
i18n = import('i18n')
pkgconfig = import('pkgconfig')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (application_id), language:'c')
add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')

gio_dep = dependency('gio-2.0')
glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')
gtk_dep = dependency('gtk4')
libsoup_dep = dependency('libsoup-3.0')
sqlite3_dep = dependency('sqlite3')
libadwaita_dep = dependency('libadwaita-1', version: '>= 1.7.0')
json_dep = dependency('json-glib-1.0')
libgxml_dep = dependency('gxml-0.20')
libsecret_dep = dependency('libsecret-1', required : false)
libspelling = dependency('libspelling-1', required: get_option('spelling'))
gtksourceview_dep = dependency('gtksourceview-5')
m_dep = meson.get_compiler('c').find_library('m', required : false)
icu_uc_dep = dependency('icu-uc',
  required: host_machine.system() != 'android',
  allow_fallback: host_machine.system() != 'android',
)

if host_machine.system() == 'android'
  if meson.version().version_compare('<1.12.0')
    error(
      'Android build requires meson >= 1.12.0 (for cmake.subproject(native: true)); found @0@.'.format(meson.version())
    )
  endif

  # Getting libical to compile correctly:
  cmake = import('cmake')
  libical_common_defines = {
    'LIBICAL_GLIB': 'True',
    'LIBICAL_GLIB_VAPI': 'False',
    'LIBICAL_GOBJECT_INTROSPECTION': 'False',
    'LIBICAL_JAVA_BINDINGS': 'False',
    'LIBICAL_CXX_BINDINGS': 'False',
    'LIBICAL_BUILD_EXAMPLES': 'False',
    'LIBICAL_BUILD_DOCS': 'False',
    'LIBICAL_BUILD_TESTING': 'False',
    'LIBICAL_BUILD_VZIC': 'False',
  }
  native_opts = cmake.subproject_options()
  native_opts.add_cmake_defines(libical_common_defines)

  libical_native = cmake.subproject('libical', native: true, options: native_opts)
  generator = libical_native.target('ical-glib-src-generator')

  meson_uninstalled_pkgconfig_dir = meson.global_build_root() / 'meson-uninstalled'
  libxml2_includedir = run_command(
    'pkg-config', '--variable=includedir', 'libxml-2.0',
    check: true,
  ).stdout().strip()

  cross_opts = cmake.subproject_options()
  cross_opts.add_cmake_defines(libical_common_defines)
  cross_opts.add_cmake_defines({
    'IMPORT_ICAL_GLIB_SRC_GENERATOR': generator.full_path(),
    'MESON_UNINSTALLED_PKGCONFIG_DIR': meson_uninstalled_pkgconfig_dir,
    'LIBXML2_INCLUDE_DIR': libxml2_includedir,
  })
  libical_cross = cmake.subproject('libical', options: cross_opts)
  libical_dep = libical_cross.dependency('ical-glib')

  meson.add_postconf_script(
    find_program('ninja'),
    '-C', meson.current_build_dir(),
    'build.subprojects/libical/ical_glib_src_generator',
  )

  add_project_arguments(['--define=ANDROID'], language: 'vala')
  add_project_arguments([
    '--pkg', 'gtk4',
    '--pkg', 'libadwaita-1',
    '--pkg', 'json-glib-1.0',
    '--pkg', 'libsoup-3.0',
    '--pkg', 'gtksourceview-5',
    '--pkg', 'sqlite3',
    '--pkg', 'libical-glib',
    '--pkg', 'posix',
    '--disable-since-check',
  ], language: 'vala')
else
  libical_dep = dependency('libical-glib')
endif

# is libical version 4 or higher?
is_libical4 = libical_dep.version().version_compare('>= 4.0.0')
if is_libical4
  add_project_arguments('-D', 'IS_LIBICAL4', language: 'vala')
endif

if icu_uc_dep.found () or host_machine.system() == 'android'
  add_project_arguments(['--vapidir=' + meson.project_source_root() / 'vapi'], language: 'vala')
endif

if libspelling.found ()
  add_project_arguments(['--define=WITH_LIBSPELLING'], language: 'vala')
endif

if get_option('portal')
    libportal_dep = dependency('libportal', required: true)
    libportal_gtk4_dep = dependency('libportal-gtk4', required: true)
    add_project_arguments('-D', 'WITH_LIBPORTAL', language: 'vala')
    if not libportal_dep.found()
        error('libportal requested but not found')
    endif
    if not libportal_gtk4_dep.found()
        error('libportal-gtk4 requested but not found')
    endif
endif

if get_option('evolution')
    libecal_dep = dependency('libecal-2.0', version: '>= 3.45.1')
    libedataserver_dep = dependency('libedataserver-1.2', version: '>= 3.45.1')
    add_project_arguments('-D', 'WITH_EVOLUTION', language: 'vala')
    if not libecal_dep.found()
        error('libecal-2.0 requested but not found')
    endif
    if not libedataserver_dep.found()
        error('libedataserver-1.2 requested but not found')
    endif
endif

############
# Resources #
############

asresources = gnome.compile_resources (
    'as-resources', 'data/io.github.alainm23.planify.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

############
# Config #
############
prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option ('localedir')
libexecdir = prefix / get_option('libexecdir')

grep = find_program('grep')
total_strings_res = run_command(grep, '-c', 'msgid', meson.project_source_root() + '/po/io.github.alainm23.planify.pot', check : true)
total_strings = total_strings_res.stdout().strip().to_int() - 1

# _NL_TIME_FIRST_WEEKDAY is a glibc-ism
nl_time_first_weekday_src = '''
  #include <langinfo.h>
  int main() {
    nl_langinfo(_NL_TIME_FIRST_WEEKDAY);
  };
'''
if cc.compiles(nl_time_first_weekday_src)
    add_project_arguments('-D', 'HAVE__NL_TIME_FIRST_WEEKDAY', language: 'vala')
endif

conf_data = configuration_data()
conf_data.set('TOTAL_STRINGS', total_strings)
conf_data.set_quoted('APPLICATION_ID', application_id)
conf_data.set_quoted('GETTEXT_PACKAGE', application_id)
conf_data.set_quoted('GNOMELOCALEDIR', localedir)
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('LOCALEDIR', localedir)
conf_data.set_quoted('PACKAGE_VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', prefix)
conf_data.set_quoted('DATADIR', datadir)
conf_data.set_quoted('PROFILE', profile)

config_file = configure_file(
    configuration : conf_data,
    input : 'config.vala.in',
    output : 'config.vala'
)

subdir('core')
subdir('src')
subdir('quick-add')
subdir('cli')
subdir('data')
subdir('search-provider')
subdir('po')

# Testing
subdir('test')

summary({
  'Tracing': get_option('tracing'),
  'Profile': get_option('profile'),
}, section: 'Development')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: host_machine.system() != 'android',
  update_desktop_database: true,
)
