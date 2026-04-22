shared_library (
    'CalculatorPlugin',
    'Plugin.vala',
    dependencies: detective_dep,
    install: true,
    install_dir: plugin_dir
)

install_data (
    'run_mathparse.py',
    install_dir: get_option('prefix') / get_option('bindir'),
    install_mode: 'rwxr-xr-x',
)
