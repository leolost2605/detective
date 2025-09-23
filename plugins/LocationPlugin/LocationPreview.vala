/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.LocationPreview : Granite.Bin {
    private Gtk.Image icon;
    private Gtk.Label name_label;
    private Gtk.Label address_label;

    private Shumate.SimpleMap simple_map;

    private Shumate.Marker marker;

    construct {
        icon = new Gtk.Image () {
            icon_size = LARGE
        };

        name_label = new Gtk.Label (null) {
            halign = START
        };
        name_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        address_label = new Gtk.Label (null) {
            halign = START
        };
        address_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var header_grid = new Gtk.Grid () {
            column_spacing = 12,
        };
        header_grid.attach (icon, 0, 0, 1, 2);
        header_grid.attach (name_label, 1, 0, 1, 1);
        header_grid.attach (address_label, 1, 1, 1, 1);

        var source = new Shumate.RasterRenderer.from_url ("https://tile.openstreetmap.org/{z}/{x}/{y}.png");

        simple_map = new Shumate.SimpleMap () {
            map_source = source,
            height_request = 300
        };
        simple_map.add_css_class (Granite.STYLE_CLASS_CARD);
        simple_map.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        var marker_icon = new Gtk.Image.from_icon_name ("pointer") {
            icon_size = LARGE
        };

        marker = new Shumate.Marker () {
            child = marker_icon,
        };

        var marker_layer = new Shumate.MarkerLayer (simple_map.viewport);
        marker_layer.add_marker (marker);

        simple_map.add_overlay_layer (marker_layer);

        var content = new Gtk.Box (VERTICAL, 12) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        content.append (header_grid);
        content.append (simple_map);

        child = content;
    }

    public void bind (Geocode.Place place) {
        icon.gicon = place.icon;
        name_label.label = place.name;
        address_label.label = place.street_address;

        marker.latitude = place.location.latitude;
        marker.longitude = place.location.longitude;
        simple_map.map.go_to_full_with_duration (marker.latitude, marker.longitude, 10, 0);
    }
}
