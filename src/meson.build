app_sources = [
    'Application.vala',
    'MainView.vala',
    'ShellKeyGrabber.vala',
    'Window.vala',
    'AppCarousel' / 'AppCarousel.vala',
    'AppCarousel' / 'AppCarouselPage.vala',
    'AppCarousel' / 'AppListItem.vala',
    'AppSystem' / 'App.vala',
    'AppSystem' / 'AppCache.vala',
    'SearchView' / 'ResultRow.vala',
    'SearchView' / 'SearchView.vala',
    'SearchView' / 'Preview' / 'GenericPreview.vala',
    'SearchView' / 'Preview' / 'Preview.vala',
]

executable(
    meson.project_name(),
    app_sources,
    gresource,
    dependencies: app_deps,
    install: true
)
