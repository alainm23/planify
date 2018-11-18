public class Objects.Project {
    public int id;
    public string name;
    public string note;
    public string deadline;
    public int item_order;
    public int is_deleted;
    public string color;

    public Project (int id = 0,
                    int item_order = 0,
                    int is_deleted = 0,
                    string name = "",
                    string note = "",
                    string deadline = "",
                    string color = "") {

        this.id = id;
        this.name = name;
        this.note = note;
        this.deadline = deadline;
        this.item_order = item_order;
        this.is_deleted = is_deleted;
        this.color = color;
    }
}
