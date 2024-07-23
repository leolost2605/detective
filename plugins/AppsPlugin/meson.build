desktopintegration = get_option('desktopintegration')

sources = [
    'Plugin.vala',
    'RelevancyService.vala'
]

if desktopintegration
    sources += 'DesktopIntegration.vala'
    add_project_arguments(['--define', 'DESKTOP_INTEGRATION'], language: 'vala')
endif

shared_library(
    'AppsPlugin',
    sources: sources,
    dependencies: [
        lib_dep,
        meson.get_compiler('c').find_library ('m')
    ],
    install: true,
    install_dir: plugin_dir,
)
