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

public class Detective.CalculatorProvider : ThreadedProvider {
    private uint result_type_id;

    public override void register_with_aggregator (ResultAggregator aggregator) {
        result_type_id = aggregator.register_result_type_simple (_("Calculation"));
    }

    protected override void search_threaded (Query query, ResultAggregator aggregator) {
        try {
            var solution = get_solution (query.search_term,  query.cancellable);

            var icon = new ThemedIcon ("accessories-calculator");
            var result = new Result (Relevancy.HIGH, solution, null, icon, null);

            aggregator.add_result (result_type_id, result);
        } catch (Error e) {
            if (!(e is IOError.FAILED_HANDLED) && !(e is IOError.CANCELLED)) {
                warning ("Error processing %s with math parse: %s", query.search_term, e.message);
            }
        }

        aggregator.commit_results_threadsafe (result_type_id);
    }

    private string get_solution (string query_string, Cancellable cancellable) throws Error {
        string[] argv = { "run_mathparse.py", query_string };

        var subprocess = new Subprocess.newv (argv, STDOUT_PIPE | STDERR_SILENCE);

        string result;
        subprocess.communicate_utf8 (null, cancellable, out result, null);

        if (subprocess.get_exit_status () != 0) {
            throw new IOError.FAILED_HANDLED ("No valid solution found");
        }

        return result.strip ();
    }
}

public Detective.CalculatorProvider get_provider () {
    return new Detective.CalculatorProvider ();
}
