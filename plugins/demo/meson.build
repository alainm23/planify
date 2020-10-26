module_name = 'demo'

module_files = [
    'demo.vala',
]

module_deps = [
    dependency('gee-0.8'),
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('libpeas-1.0'),
]

shared_module(
    module_name,
    module_files,
    dependencies: module_deps,
    install: true,
    install_dir: join_paths(pluginsdir, module_name),
)

custom_target(module_name + '.plugin_merge',
    input: module_name + '.plugin',
    output: module_name + '.plugin',
    command : [msgfmt,
               '--desktop',
               '--keyword=Description',
               '--keyword=Name',
               '-d' + join_paths(meson.source_root (), 'po', 'plugins'),
               '--template=@INPUT@',
               '-o@OUTPUT@',
               ],
    install : true,
    install_dir: join_paths(pluginsdir, module_name),
)
