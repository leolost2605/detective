app_sources = [
    'Application.vala',
    'ShellKeyGrabber.vala',
    'Window.vala',
    'SearchView' / 'ResultRow.vala',
    'SearchView' / 'SearchView.vala',
    'SearchView' / 'Preview' / 'GenericPreview.vala',
    'SearchView' / 'Preview' / 'Preview.vala',
]

app_deps = [
    dependency('gtk4'),
    dependency('granite-7'),
    dependency('libadwaita-1'),
    dependency('libportal'),
    dependency('libportal-gtk4'),
    dependency('tracker-sparql-3.0'),
    lib_dep
]

executable(
    meson.project_name(),
    app_sources,
    dependencies: app_deps,
    install: true
)
