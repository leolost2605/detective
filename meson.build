# project name and programming language
project('io.github.leolost2605.detective', 'vala', 'c')

pkgconfig = import('pkgconfig')
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

subdir('lib')
subdir('plugins')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src' / 'Application.vala',
    'src' / 'MatchRow.vala',
    'src' / 'SearchWindow.vala',
    'src' / 'ShellKeyGrabber.vala',
    dependencies: [
        dependency('gtk4'),
        dependency('granite-7'),
        dependency('libadwaita-1'),
        dependency('libportal'),
        dependency('libportal-gtk4'),
        dependency('tracker-sparql-3.0'),
        lib_dep
    ],
    install: true
)

subdir('data')
subdir('po')
