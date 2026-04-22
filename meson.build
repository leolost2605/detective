# project name and programming language
project('io.github.leolost2605.detective', 'vala', 'c')

pkgconfig = import('pkgconfig')
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Enable DesktopIntegration feature if option is enabled
if get_option('desktopintegration')
    add_project_arguments(['--define', 'DESKTOP_INTEGRATION'], language: 'vala')
endif

subdir('lib')
subdir('src')
subdir('plugins')
subdir('data')
subdir('po')
