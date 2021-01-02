project (
    'com.github.alainm23.planner',
    'vala', 'c',
    version: '2.6.5'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)


libexecdir = join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name())
pluginsdir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name(), 'plugins')

gnome = import('gnome')
i18n = import('i18n')

glib_dep = dependency('glib-2.0', version: '>=2.30.0')
gee_dep = dependency('gee-0.8', version: '>=0.8.5')
gtk_dep = dependency('gtk+-3.0', version: '>=3.6.0')
granite_dep = dependency('granite', version: '>=5.2.0')
peas_dep = dependency('libpeas-1.0')
peasgtk_dep = dependency('libpeas-gtk-1.0')
sqlite3_dep = dependency('sqlite3')
json_dep = dependency('json-glib-1.0')
webkit2gtk_dep = dependency('webkit2gtk-4.0')
libedataserver_dep = dependency('libedataserver-1.2', version: '>=3.8.0')
libsoup_dep = dependency('libsoup-2.4')
posix_dep = meson.get_compiler('c').find_library('m', required : false)

asresources = gnome.compile_resources (
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

libecal_dep = dependency('libecal-2.0', required: false)
if libecal_dep.found()
    libical_dep = dependency('libical-glib')
    add_project_arguments('--define=E_CAL_2_0', language: 'vala')
    add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')
else
    libecal_dep = dependency('libecal-1.2', version: '>=3.8.0')
    libical_dep = dependency('libical')
    add_project_arguments('--vapidir', join_paths(meson.current_source_dir(), 'vapi'), language: 'vala')
endif

dependencies = [
    glib_dep,
    gee_dep,
    gtk_dep,
    granite_dep,
    peas_dep,
    peasgtk_dep,
    sqlite3_dep,
    json_dep,
    webkit2gtk_dep,
    libedataserver_dep,
    libsoup_dep,
    libecal_dep,
    libical_dep,
    posix_dep
]

subdir('data')
subdir('src')
if get_option('plugins')
    subdir('plugins')
endif
subdir('po')
meson.add_install_script('build-aux/meson/post_install.py')
