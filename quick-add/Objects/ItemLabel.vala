public class Objects.ItemLabel : GLib.Object {
    public int64 id { get; set; default = Constants.INACTIVE; }
    public int64 item_id { get; set; default = Constants.INACTIVE; }
    public int64 label_id { get; set; default = Constants.INACTIVE; }

    Objects.Label? _label = null;
    public Objects.Label label {
        get {
            if (_label == null) {
                _label = Services.Database.get_default ().get_label (label_id);
            }
            return _label;
        }
    }

    //  Objects.Item? _item = null;
    //  public Objects.Item item {
    //      get {
    //          if (_item == null) {
    //              _item = Planner.database.get_item (item_id);
    //          }
    //          return _item;
    //      }
    //  }
}
