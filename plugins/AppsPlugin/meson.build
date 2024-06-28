shared_library(
    'AppsPlugin',
    sources: [
        'DesktopIntegration.vala',
        'Plugin.vala',
        'RelevancyService.vala'
    ],
    dependencies: [
        lib_dep,
        meson.get_compiler('c').find_library ('m')
    ],
    install: true,
    install_dir: plugin_dir
)
