public class SignalMatch : Match {
    public delegate void ActivationCallback (Error? error);

    public signal void activated (ActivationCallback callback);

    public SignalMatch (MatchType match_type, int relevancy, string title, string? description, Icon? icon, Gdk.Paintable? paintable) {
        Object (
            match_type: match_type,
            relevancy: relevancy,
            title: title,
            description: description,
            icon: icon,
            paintable: paintable
        );
    }

    public override async void activate () throws Error {
        Error? error = null;
        activated ((e) => {
            error = e;
            Idle.add (() => {
                activate.callback ();
                return Source.REMOVE;
            });
        });
        yield;

        if (error != null) {
            throw error;
        }
    }
}
