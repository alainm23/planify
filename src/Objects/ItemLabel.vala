public class Objects.ItemLabel : Objects.BaseObject {
    public string item_id { get; set; default = ""; }
    public string label_id { get; set; default = ""; }

    Objects.Label? _label = null;
    public Objects.Label label {
        get {
            if (_label == null) {
                _label = Services.Database.get_default ().get_label (label_id);
            }
            return _label;
        }
    }

    Objects.Item? _item = null;
    public Objects.Item item {
        get {
            if (_item == null) {
                _item = Services.Database.get_default ().get_item (item_id);
            }
            return _item;
        }
    }
}