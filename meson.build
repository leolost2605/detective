project(
    'io.github.leolost2605.detective',
    'vala', 'c',
    version: '0.1.0'
)

pkgconfig = import('pkgconfig')
i18n = import('i18n')

locale_dir = get_option('prefix') / get_option('localedir')
plugin_dir = get_option('prefix') / get_option('libdir') / 'detective'

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Enable DesktopIntegration feature if option is enabled
if get_option('desktopintegration')
    add_project_arguments(['--define', 'DESKTOP_INTEGRATION'], language: 'vala')
endif

adw_dep = dependency('libadwaita-1')
gio_unix_dep = dependency('gio-unix-2.0')
gmodule_dep = dependency('gmodule-2.0')
granite_dep = dependency('granite-7')
gtk4_dep = dependency('gtk4')
portal_dep = dependency('libportal')
portal_gtk4_dep = dependency('libportal-gtk4')
tracker_dep = dependency('tracker-sparql-3.0')

lib_deps = [
    gio_unix_dep,
    gmodule_dep,
    gtk4_dep,
    tracker_dep,
]

subdir('lib')

app_deps = [
    adw_dep,
    detective_dep,
    granite_dep,
    portal_dep,
    portal_gtk4_dep,
    tracker_dep,
]

subdir('src')

subdir('plugins')
subdir('data')
subdir('po')
