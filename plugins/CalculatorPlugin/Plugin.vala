/*
* Copyright (c) 2010 Michal Hruby <michal.mhr@gmail.com>
*               2022 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Michal Hruby <michal.mhr@gmail.com>
*/

public class Detective.CalculatorProvider : SearchProvider {
    private CalculatorPluginBackend backend;
    private ListStore matches_internal;

    construct {
        backend = new CalculatorPluginBackend ();
        matches_internal = new ListStore (typeof (Match));

        var match_types = new ListStore (typeof (MatchType));
        match_types.append (new MatchType (_("Calculation"), matches_internal));
        this.match_types = match_types;
    }

    public override void search (Query query) {
        search_internal.begin (query);
    }

    private async void search_internal (Query query) {
        matches_internal.remove_all ();

        try {
            string d = yield backend.get_solution (
                query.search_term,
                query.cancellable
            ); // throws error if no valid solution found

            var icon = new ThemedIcon ("accessories-calculator");
            var match = new Match ( 0, d, null, icon, null);

            matches_internal.append (match);
        } catch (Error e) {
            if (!(e is IOError.FAILED_HANDLED)) {
                warning ("Error processing %s with bc: %s", query.search_term, e.message);
            }
        }
    }

    public override void clear () {
        matches_internal.remove_all ();
    }
}

public Detective.CalculatorProvider get_provider () {
    return new Detective.CalculatorProvider ();
}
