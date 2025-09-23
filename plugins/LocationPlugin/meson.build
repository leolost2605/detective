gnome = import('gnome')

location_plugin_resources = gnome.compile_resources(
    'resources',
    'data' / 'io.github.leolost2605.detective.location-plugin.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

shared_library(
    'LocationPlugin',
    location_plugin_resources,
    'LocationPreview.vala',
    'Plugin.vala',
    dependencies: [
        lib_dep,
        dependency('geocode-glib-2.0'),
        dependency('granite-7'),
        dependency('libsoup-3.0'),
        dependency('json-glib-1.0'),
        dependency('shumate-1.0'),
    ],
    install: true,
    install_dir: plugin_dir
)
