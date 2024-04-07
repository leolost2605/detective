
// This whole thing is just for testing
public class ActionsProvider : SearchProvider {
    private const string NO_MATCH_TERM = "nsdfisdflksdflsdf"; //This is stupid lol

    private ListStore actions;
    private Gtk.CustomFilter filter;

    private string search_term = "";
    private bool searching = false;

    construct {
        var match_type = new MatchType ("actions", "Actions");

        actions = new ListStore (typeof (Match));

        filter = new Gtk.CustomFilter ((obj) => {
            var match = (Match) obj;
            if (searching) {
                return search_term.down () in match.text.down ();
            }

            return false;
        });

        matches = new Gtk.FilterListModel (actions, filter);

        //Fill with default actions
        actions.append (new Match (match_type, 1, "Shutdown", null, null));
        actions.append (new Match (match_type, 1, "Restart", null, null));
        actions.append (new Match (match_type, 1, "Logout", null, null));
    }

    public override void search (string search_term) {
        searching = true;
        this.search_term = search_term;
        actions.items_changed (0, actions.get_n_items (), actions.get_n_items ());
    }

    public override void clear () {
        searching = false;
    }
}
