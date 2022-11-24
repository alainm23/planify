public class Objects.Color : GLib.Object {
    public int id { get; construct; }
    public string name { get; construct; }
    public string hexadecimal { get; construct; }

    public Color (int id, string name, string hexadecimal) {
        Object (
            id: id,
            name: name,
            hexadecimal: hexadecimal
        );
    }
}