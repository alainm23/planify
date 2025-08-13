backend_dir = meson.project_source_root() / 'backend'
backend_install_dir = libexecdir / 'planify-backend'

custom_target(
  'install-backend',
  output: 'backend.installed',
  input: [],
  command: [
    'sh',
    '-c', 'cd "@0@" && npm install && npx tsc'.format(backend_dir),
  ],
  build_by_default: true,
)

install_subdir('backend', install_dir: backend_install_dir, strip_directory: true)