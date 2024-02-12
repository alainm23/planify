public class Services.Promise<T> : Object {
    public signal void resolved (T value);
    public signal void rejected (string error);

    public void resolve (T result) {
        resolved (result);
    }

    public void reject (string error) {
        rejected (error);
    }
}