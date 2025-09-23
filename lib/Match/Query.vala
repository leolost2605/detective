public class Query : Object {
    public string search_term { get; construct; }

    public int n_results { get; construct; }

    public bool cancelled {
        get {
            return cancellable.is_cancelled ();
        }
    }

    public Cancellable cancellable { get; construct; }

    internal Query (string search_term, int n_results) {
        Object (search_term: search_term, n_results: n_results);
    }

    construct {
        cancellable = new Cancellable ();
    }

    internal void cancel () {
        cancellable.cancel ();
    }
}
