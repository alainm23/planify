public class Widgets.ItemCompletedRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Label content_label;

    public ItemCompletedRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");
        
        tooltip_markup =  "<b>%s</b>:\n%s\n<b>%s</b>:\n%s\n<b>%s</b>:\n%s\n<b>%s</b>:\n%s".printf (
            _("Content"), item.content,
            _("Note"), item.note,
            _("Due date"), Application.utils.get_relative_date_from_string (item.due_date),
            _("Date completed"), Application.utils.get_relative_date_from_string (item.date_completed)
        );

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.margin_start = 17;
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);
    
        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_start = 9;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.START;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.active = true;

        var completed_label = new Gtk.Label (Application.utils.get_relative_date_from_string (item.date_completed));
        completed_label.halign = Gtk.Align.START;
        completed_label.valign = Gtk.Align.CENTER;
        
        completed_label.get_style_context ().add_class ("due-preview");

        content_label = new Gtk.Label ("<s>%s</s>".printf (item.content));
        content_label.margin_start = 9;
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.xalign = 0;
        content_label.use_markup = true;
        content_label.get_style_context ().add_class ("label");
        content_label.ellipsize = Pango.EllipsizeMode.END;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin = 3;
        box.margin_start = 0;
        box.pack_start (loading_revealer, false, false, 0);
        box.pack_start (checked_button, false, false, 0);
        //box.pack_start (completed_label, false, false, 0);
        box.pack_start (content_label, false, false, 0);

        add (box);

        checked_button.toggled.connect (() => {
            if (checked_button.active == false) { 
                item.checked = 0;
                item.date_completed = "";

                if (Application.database.update_item_completed (item)) {
                    if (item.is_todoist == 1) {
                        Application.todoist.item_uncomplete (item);
                    }

                    destroy ();
                }   
            }
        });

        Application.todoist.item_uncompleted_started.connect ((i) => {
            if (item.id == i.id) {
                sensitive = false;
                loading_revealer.reveal_child = true;
            }
        });

        Application.todoist.item_uncompleted_completed.connect ((i) => {
            if (item.id == i.id) {
                destroy ();
            }
        });
    }
}
    