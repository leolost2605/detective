lib_name = 'detective'

lib_sources = [
    'Engine.vala',
    'PluginLoader.vala',
    'Results' / 'Result.vala',
    'Results' / 'ResultAggregator.vala',
    'Results' / 'ResultType.vala',
    'Search' / 'Query.vala',
    'Search' / 'SearchProvider.vala',
    'Utils' / 'Algorithms.vala',
    'Utils' / 'ResultListStore.vala',
    'Utils' / 'ThreadedProvider.vala',
    'Utils' / 'TrackerProvider.vala',
    'Utils' / 'Utils.vala',
]

config_data = configuration_data()
config_data.set('GETTEXT_PACKAGE', meson.project_name())
config_data.set('LOCALEDIR', locale_dir)
config_data.set('PLUGIN_DIR', plugin_dir)

config_header = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: config_data,
)

detective_lib = library(
    lib_name,
    lib_sources,
    config_header,
    dependencies: lib_deps,
    vala_header: lib_name + '.h',
    vala_vapi: lib_name + '.vapi',
    version: meson.project_version(),
    install: true,
    install_dir: [true, true, true],
)

install_data(
    lib_name + '.deps',
    install_dir: get_option('datadir') / 'vala' / 'vapi'
)

detective_dep = declare_dependency(
    link_with: detective_lib,
    dependencies: lib_deps,
    include_directories: [include_directories('.')],
)

pkgconfig.generate(
    detective_lib,
    name: lib_name,
    requires: lib_deps,
    description: 'Easy to use search engine framework.',
    version: meson.project_version(),
    url: 'https://github.com/leolost2605/detective',
)
