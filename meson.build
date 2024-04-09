# project name and programming language
project('io.github.leolost2605.detective', 'vala', 'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src' / 'Application.vala',
    'src' / 'MatchRow.vala',
    'src' / 'SearchWindow.vala',
    'src' / 'Core' / 'Engine.vala',
    'src' / 'Core' / 'Match.vala',
    'src' / 'Core' / 'MatchType.vala',
    'src' / 'Core' / 'SearchProvider.vala',
    'src' / 'Core' / 'Utils' / 'TrackerProvider.vala',
    'src' / 'Plugins' / 'ActionsPlugin.vala',
    'src' / 'Plugins' / 'TrackerPlugin.vala',
    dependencies: [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('tracker-sparql-3.0')
    ],
    install: true
)

# Install our .desktop file so the Applications Menu will see it
install_data(
    'data' / meson.project_name() + '.desktop',
    install_dir: get_option('datadir') / 'applications'
)

# Install our .appdata.xml file so AppCenter will see it
install_data(
    'data' / meson.project_name() + '.appdata.xml',
    install_dir: get_option('datadir') / 'metainfo',
)

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']
foreach i : icon_sizes
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: meson.project_name() + '.svg'
    )
    install_data(
        'data' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: meson.project_name() + '.svg'
    )
endforeach
