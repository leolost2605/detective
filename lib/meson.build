sources = [
    'Engine.vala',
    'Match.vala',
    'MatchType.vala',
    'PluginLoader.vala',
    'Query.vala',
    'SearchProvider.vala',
    'Utils' / 'TrackerProvider.vala',
]

libdetective_deps = [
    dependency('gtk4'),
    dependency('tracker-sparql-3.0'),
    dependency('gio-unix-2.0'),
    dependency('gmodule-2.0'),
]

plugin_dir = join_paths(get_option('prefix'), get_option('libdir'), 'detective')

config_vapi = meson.get_compiler('vala').find_library('config', dirs: meson.current_source_dir())

config_data = configuration_data()
config_data.set_quoted('PLUGIN_DIR', plugin_dir)

config_header = configure_file(
    configuration: config_data,
    output: 'config.h'
)

libdetective = library(
    meson.project_name(),
    sources,
    config_header,
    dependencies: [
        libdetective_deps,
        config_vapi,
    ],
    vala_header: 'detective.h',
    install: true,
)

lib_dep = declare_dependency(
    link_with: libdetective,
    dependencies: libdetective_deps,
    include_directories: [include_directories('.')],
)

# pkgconfig.generate(
#     libdetective,
#     name: meson.project_name(),
#     requires: libdetective_deps,
#     description: 'Easy to use search engine framework.',
#     version: meson.project_version(),
#     url: 'https://github.com/leolost2605/detective',
# )
