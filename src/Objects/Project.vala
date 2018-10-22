public class Objects.Project {
    public int id;
    public string name;
    public string description;
    public string duedate;
    public int item_order;
    public int is_deleted;
    public string color;

    public Project (int id = 0,
                    int item_order = 0,
                    int is_deleted = 0,
                    string name = "",
                    string description = "",
                    string duedate = "",
                    string color = "") {

        this.id = id;
        this.name = name;
        this.description = description;
        this.duedate = duedate;
        this.item_order = item_order;
        this.is_deleted = is_deleted;
        this.color = color;
    }
}
