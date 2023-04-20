public class Models.ItemList : GLib.Object, GLib.ListModel {
    public Gee.ArrayList<Objects.Item> entries { get; construct; }

    public ItemList (Gee.ArrayList<Objects.Item> entries) {
        Object (entries: entries);
    }

    public uint get_n_items () {
        return entries.size;
    }

    public GLib.Type get_item_type () {
        return typeof (Objects.Item);
    }

    public GLib.Object ? get_item (uint position) {
        if (position > entries.size) {
            return null;
        }
        
        return entries[(int) position];
    }
}