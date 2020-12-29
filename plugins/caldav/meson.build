module_name = 'caldav'

module_files = [
    'caldav.vala',
    'Services/Store.vala',
    'Services/Utils.vala',
    'Widgets/SourceRow.vala',
    'Widgets/TaskList.vala',
    'Widgets/TaskRow.vala'
]

module_deps = [
    plannercore_dep
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
