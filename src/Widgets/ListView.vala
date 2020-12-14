public class Widgets.ListView : Gtk.EventBox {
    public Objects.Project project { get; construct; }
    
    private Gtk.ListBox section_listbox;
    private Widgets.SectionRow inbox_section;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_SECTION = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private uint timeout = 0;

    public ListView (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        section_listbox = new Gtk.ListBox ();
        section_listbox.valign = Gtk.Align.START;
        section_listbox.get_style_context ().add_class ("listbox");
        section_listbox.activate_on_single_click = true;
        section_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        section_listbox.expand = true;
        Gtk.drag_dest_set (section_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
        section_listbox.drag_data_received.connect (on_drag_section_received);

        var grid = new Gtk.Grid ();
        grid.expand = true;
        grid.add (section_listbox);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.expand = true;
        scrolled.add (grid);

        add (scrolled);
        add_sections ();

        Planner.database.section_added.connect ((section) => {
            if (project.id == section.project_id) {
                var row = new Widgets.SectionRow (section, project);
                section_listbox.add (row);
                section_listbox.show_all ();

                update_section_order ();
            }
        });

        Planner.database.section_moved.connect ((section, project_id, old_project_id) => {
            Idle.add (() => {
                if (project.id == old_project_id) {
                    section_listbox.foreach ((widget) => {
                        var row = (Widgets.SectionRow) widget;

                        if (row.section.id == section.id) {
                            row.destroy ();
                        }
                    });
                }

                if (project.id == project_id) {
                    section.project_id = project_id;

                    var row = new Widgets.SectionRow (section, project);
                    section_listbox.add (row);
                    section_listbox.show_all ();
                }

                return false;
            });
        });

        Planner.event_bus.show_new_window_project.connect ((id) => {
            if (project.id == id) {
                add_sections ();
            }
        });
    }

    public void add_sections () {
        foreach (unowned Gtk.Widget child in section_listbox.get_children ()) {
            child.destroy ();
        }

        inbox_section = new Widgets.SectionRow.for_project (project);
        section_listbox.add (inbox_section);
        foreach (var section in Planner.database.get_all_sections_by_project (project.id)) {
            var row = new Widgets.SectionRow (section, project);
            section_listbox.add (row);
        }
        section_listbox.show_all ();
    }

    public void add_new_item (int index=-1) {
        inbox_section.add_new_item (index);
    }

    private void on_drag_section_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.SectionRow target;
        Widgets.SectionRow source;
        Gtk.Allocation alloc;

        target = (Widgets.SectionRow) section_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        source = (Widgets.SectionRow) row;

        if (target != null) {
            source.get_parent ().remove (source);

            section_listbox.insert (source, target.get_index () + 1);
            section_listbox.show_all ();

            update_section_order ();
        }
    }

    private void update_section_order () {
        if (timeout != 0) {
            Source.remove (timeout);
        }

        timeout = Timeout.add (150, () => {
            timeout = 0;

            new Thread<void*> ("update_section_order", () => {
                section_listbox.foreach ((widget) => {
                    var row = (Gtk.ListBoxRow) widget;
                    int index = row.get_index ();

                    var section = ((Widgets.SectionRow) row).section;

                    new Thread<void*> ("update_section_order", () => {
                        Planner.database.update_section_item_order (section.id, index);
                        return null;
                    });
                });

                return null;
            });

            return GLib.Source.REMOVE;
        });
    }
}
