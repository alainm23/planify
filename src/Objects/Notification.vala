public class Objects.Notification {
    public int id;
    public int task_id;
    public string summary;
    public string body;
    public string primary_icon;
    public string secondary_icon;

    public Notification (int id = 0,
                         int task_id = 0,
                         string summary = "",
                         string body = "",
                         string primary_icon = "",
                         string secondary_icon = "") {
        this.id = id;
        this.task_id = task_id;
        this.summary = summary;
        this.body = body;
        this.primary_icon = primary_icon;
        this.secondary_icon = secondary_icon;
    }
}
