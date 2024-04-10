public class Query : Object {
    public string search_term { get; construct; }

    public bool cancelled {
        get {
            return cancellable.is_cancelled ();
        }
    }

    public Cancellable cancellable { get; construct; }

    internal Query (string search_term) {
        Object (search_term: search_term);
    }

    construct {
        cancellable = new Cancellable ();
    }

    internal void cancel () {
        cancellable.cancel ();
    }
}
