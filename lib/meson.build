sources = [
    'Engine.vala',
    'Match.vala',
    'MatchType.vala',
    'SearchProvider.vala',
    'Utils' / 'TrackerProvider.vala',
    'Plugins' / 'ActionsPlugin.vala',
    'Plugins' / 'TrackerPlugin.vala',
    'Plugins' / 'FilePlugin.vala',
]

libdetective_deps = [
    dependency('gtk4'),
    dependency('tracker-sparql-3.0'),
    dependency('gio-unix-2.0'),
]

include_dir = join_paths(
    get_option('prefix'),
    get_option('includedir'),
    meson.project_name()
)

libdetective = library(
    meson.project_name(),
    sources,
    dependencies: libdetective_deps,
    vala_header: 'detective.h',
    vala_vapi: 'detective.vapi',
    install: true,
    install_dir: [true, include_dir, true],
)

lib_dep = declare_dependency(
    link_with: libdetective,
    dependencies: libdetective_deps,
    include_directories: [include_directories('.')],
)

pkgconfig.generate(
    libdetective,
    name: meson.project_name(),
    requires: libdetective_deps,
    description: 'Easy to use search engine framework.',
    version: meson.project_version(),
    url: 'https://github.com/leolost2605/detective',
)
