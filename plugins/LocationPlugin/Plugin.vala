public class LocationMatch : Match {
    private static LocationPreview preview = new LocationPreview ();

    public Geocode.Place place { get; construct; }

    public LocationMatch (Geocode.Place place) {
        Object (place: place);
    }

    construct {
        relevancy = 30;
        title = place.name;
        icon = place.icon;
        description = place.street_address;
    }

    public override Gtk.Widget? get_custom_preview () {
        preview.bind (place);
        return preview;
    }

    public override async void activate () throws Error {
    }
}

public class LocationProvider : SearchProvider {
    private ListStore store;
    private Soup.Session session;

    construct {
        store = new ListStore (typeof (LocationMatch));

        var location_match_type = new MatchType (_("Places"), store);

        var match_types = new ListStore (typeof (MatchType));
        match_types.append (location_match_type);

        this.match_types = match_types;

        session = new Soup.Session ();
    }

    public override void search (Query query) {
        store.remove_all ();
        search_internal.begin (query);
    }

    private async void search_internal (Query query) {
        if (query.cancelled) {
            return;
        }

        var message = new Soup.Message ("GET", "https://photon.komoot.io/api/?q=%s&limit=%d".printf (Uri.escape_string (query.search_term), query.n_results));

        try {
            var input_stream = yield session.send_async (message, Priority.DEFAULT, query.cancellable);

            var parser = new Json.Parser ();
            yield parser.load_from_stream_async (input_stream, query.cancellable);

            parse_geo_json (parser.get_root ().get_object ());
        } catch (IOError.CANCELLED e) {
            // Ignore cancelled errors
        } catch (Error e) {
            warning ("Failed to search forward via geocode: %s", e.message);
        }
    }

    private void parse_geo_json (Json.Object root) {
        if (root.get_string_member ("type") != "FeatureCollection") {
            warning ("Invalid GeoJSON response");
            return;
        }

        var features = root.get_array_member ("features");
        features.foreach_element (parse_feature);
    }

    private void parse_feature (Json.Array array, uint index, Json.Node node) {
        var feature = node.get_object ();
        if (feature.get_string_member ("type") != "Feature") {
            return;
        }

        var geometry = feature.get_object_member ("geometry");
        if (geometry.get_string_member ("type") != "Point") {
            return;
        }

        var coordinates = geometry.get_array_member ("coordinates");
        if (coordinates.get_length () != 2) {
            return;
        }

        double lon = coordinates.get_double_element (0);
        double lat = coordinates.get_double_element (1);

        var properties = feature.get_object_member ("properties");
        var place = parse_place (lat, lon, properties);

        store.append (new LocationMatch (place));
    }

    private Geocode.Place parse_place (double lat, double lon, Json.Object properties) {
        var name = parse_name (properties);
        var type = parse_place_type (properties);

        var place = new Geocode.Place.with_location (name, type, new Geocode.Location (lat, lon));

        string[] address_parts = {};

        string? street = null;

        if (properties.has_member ("street")) {
            street = properties.get_string_member ("street");
        }

        if (properties.has_member ("housenumber")) {
            street += " " + properties.get_string_member ("housenumber");
        }

        if (street != null) {
            address_parts += street;
        }

        if (properties.has_member ("city")) {
            address_parts += properties.get_string_member ("city");
        } else if (properties.has_member ("town")) {
            address_parts += properties.get_string_member ("town");
        } else if (properties.has_member ("village")) {
            address_parts += properties.get_string_member ("village");
        }

        if (properties.has_member ("state")) {
            address_parts += properties.get_string_member ("state");
        }

        if (properties.has_member ("postcode")) {
            address_parts += properties.get_string_member ("postcode");
        }

        if (properties.has_member ("country")) {
            address_parts += properties.get_string_member ("country");
        }

        // We abuse the street_address field to show the full address
        place.street_address = string.joinv (", ", address_parts);
        return place;
    }

    private string parse_name (Json.Object properties) {
        var name = properties.get_string_member ("name");
        if (name != null) {
            return name;
        }

        var housenumber = properties.get_string_member ("housenumber");
        var street = properties.get_string_member ("street");
        var city = properties.get_string_member ("city");
        var state = properties.get_string_member ("state");
        var country = properties.get_string_member ("country");

        var parts = new GenericArray<string> ();

        if (housenumber != null && street != null) {
            parts.add (housenumber + " " + street);
        } else if (street != null) {
            parts.add (street);
        }

        if (city != null) {
            parts.add (city);
        }

        if (state != null) {
            parts.add (state);
        }

        if (country != null) {
            parts.add (country);
        }

        return string.joinv (", ", parts.data);
    }

    private Geocode.PlaceType parse_place_type (Json.Object properties) {
        var key = properties.get_string_member ("osm_key");
        var value = properties.get_string_member ("osm_value");

        switch (key) {
            case "place":
                switch (value) {
                    case "continent":
                        return Geocode.PlaceType.CONTINENT;
                    case "country":
                        return Geocode.PlaceType.COUNTRY;
                    case "city":
                    case "town":
                    case "village":
                        return Geocode.PlaceType.TOWN;
                    case "suburb":
                        return Geocode.PlaceType.SUBURB;
                    case "house":
                        return Geocode.PlaceType.BUILDING;
                    case "island":
                        return Geocode.PlaceType.ISLAND;
                    case "municipality":
                        return Geocode.PlaceType.COUNTY;
                    default:
                        return Geocode.PlaceType.MISCELLANEOUS;
                }
            case "amenity":
                switch (value) {
                    case "bar":
                    case "pub":
                    case "nightclub":
                        return Geocode.PlaceType.BAR;
                    case "restaurant":
                    case "fast_food":
                        return Geocode.PlaceType.RESTAURANT;
                    case "school":
                    case "kindergarten":
                        return Geocode.PlaceType.SCHOOL;
                    case "place_of_worship":
                        return Geocode.PlaceType.PLACE_OF_WORSHIP;
                    case "bus_station":
                        return Geocode.PlaceType.BUS_STOP;
                    default:
                        return Geocode.PlaceType.MISCELLANEOUS;
                }
            case "highway":
                switch (value) {
                    case "bus_stop":
                        return Geocode.PlaceType.BUS_STOP;
                    case "motorway":
                        return Geocode.PlaceType.MOTORWAY;
                    default:
                        return Geocode.PlaceType.STREET;
                }
            case "railway":
                switch (value) {
                    case "station":
                    case "stop":
                    case "halt":
                        return Geocode.PlaceType.RAILWAY_STATION;
                    case "tram_stop":
                        return Geocode.PlaceType.LIGHT_RAIL_STATION;
                    default:
                        return Geocode.PlaceType.MISCELLANEOUS;
                }
            case "aeroway":
                switch (value) {
                    case "aerodrome":
                        return Geocode.PlaceType.AIRPORT;
                    default:
                        return Geocode.PlaceType.MISCELLANEOUS;
                }
            case "building":
                switch (value) {
                    case "yes":
                        return Geocode.PlaceType.BUILDING;
                    case "railway_station":
                        return Geocode.PlaceType.RAILWAY_STATION;
                    default:
                        return Geocode.PlaceType.MISCELLANEOUS;
                }
            default:
                return Geocode.PlaceType.MISCELLANEOUS;
        }
    }

    public override void clear () {
        store.remove_all ();
    }
}

public static LocationProvider get_provider () {
    Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/io/github/leolost2605/detective/location-plugin/");
    return new LocationProvider ();
}
