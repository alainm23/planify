public class Objects.ItemLabel : Objects.BaseObject {
    public int64 item_id { get; set; default = Constants.INACTIVE; }
    public int64 label_id { get; set; default = Constants.INACTIVE; }

    Objects.Label? _label = null;
    public Objects.Label label {
        get {
            if (_label == null) {
                _label = Planner.database.get_label (label_id);
            }
            return _label;
        }
    }

    Objects.Item? _item = null;
    public Objects.Item item {
        get {
            if (_item == null) {
                _item = Planner.database.get_item (item_id);
            }
            return _item;
        }
    }
}
