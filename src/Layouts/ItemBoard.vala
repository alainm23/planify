public class Layouts.ItemBoard : Gtk.ListBoxRow {
	public Objects.Item item { get; construct; }

	private Gtk.CheckButton checked_button;
    private Widgets.SourceView content_textview;

    private Widgets.LoadingButton hide_loading_button;
    private Gtk.Revealer hide_loading_revealer;

	private Gtk.Label description_label;
	private Gtk.Revealer description_label_revealer;

	private Gtk.FlowBox labels_flowbox;
	private Gtk.Revealer flowbox_revealer;

	private Gtk.Label due_label;
	private Gtk.Box due_box;
	private Gtk.Revealer due_revealer;

	private Gtk.Revealer footer_revealer;

	private Gtk.Box handle_grid;
	private Gtk.Revealer main_revealer;

    public int64 update_id { get; set; default = int64.parse (Util.get_default ().generate_id ()); }
	public uint complete_timeout { get; set; default = 0; }
	Gee.HashMap<string, Widgets.ItemLabelChild> labels;

	public bool is_loading {
		set {
			if (value) {
				hide_loading_revealer.reveal_child = value;
				hide_loading_button.is_loading = value;
			} else {
				hide_loading_button.is_loading = value;
				hide_loading_revealer.reveal_child = false;
			}
		}
	}

	private Gtk.DragSource drag_source;
	private Gtk.DropTarget drop_target;

    public bool on_drag = false;

	public ItemBoard (Objects.Item item) {
		Object (
			item: item,
			focusable: false,
			can_focus: true
			);
	}

	public ItemBoard.for_item (Objects.Item _item) {
		var item = new Objects.Item ();
		item.project_id = _item.project_id;
		item.section_id = _item.section_id;

		Object (
			item: item,
			focusable: false,
			can_focus: true
			);
	}

	public ItemBoard.for_project (Objects.Project project) {
		var item = new Objects.Item ();
		item.project_id = project.id;

		Object (
			item: item,
			focusable: false,
			can_focus: true
			);
	}

	public ItemBoard.for_parent (Objects.Item _item) {
		var item = new Objects.Item ();
		item.project_id = _item.project_id;
		item.section_id = _item.section_id;
		item.parent_id = _item.id;

		Object (
			item: item,
			focusable: false,
			can_focus: true
			);
	}

	public ItemBoard.for_section (Objects.Section section) {
		var item = new Objects.Item ();
		item.section_id = section.id;
		item.project_id = section.project.id;

		Object (
			item: item,
			focusable: false,
			can_focus: true
			);
	}

	construct {
		labels = new Gee.HashMap<string, Widgets.ItemLabelChild> ();
		add_css_class ("row");

		checked_button = new Gtk.CheckButton () {
			valign = Gtk.Align.START
		};

		checked_button.add_css_class ("priority-color");

        content_textview = new Widgets.SourceView () {
            hexpand = true
        };
        content_textview.wrap_mode = Gtk.WrapMode.WORD;
        content_textview.buffer.text = item.content;
        content_textview.editable = !item.completed;
        content_textview.remove_css_class ("view");

        hide_loading_button = new Widgets.LoadingButton.with_icon ("information", 19) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_top = 9,
            margin_end = 9
        };
        hide_loading_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        hide_loading_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        hide_loading_button.add_css_class ("no-padding");
        hide_loading_button.add_css_class ("min-height-0");

        hide_loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.START,
            halign = Gtk.Align.END
        };
        hide_loading_revealer.child = hide_loading_button;

		var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			margin_top = 6,
			margin_start = 6,
			margin_end = 6
		};

		content_box.append (checked_button);
		content_box.append (content_textview);

		description_label = new Gtk.Label (null) {
			xalign = 0,
			lines = 1,
			ellipsize = Pango.EllipsizeMode.END,
			margin_start = 30,
			margin_end = 6
		};
		description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
		description_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

		description_label_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = description_label
		};

		labels_flowbox = new Gtk.FlowBox () {
			column_spacing = 6,
			row_spacing = 6,
			homogeneous = false,
			hexpand = true,
			halign = Gtk.Align.START,
			valign = Gtk.Align.START,
			min_children_per_line = 3,
			max_children_per_line = 20,
			margin_end = 6,
			margin_start = 30,
			margin_top = 6
		};

		flowbox_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = labels_flowbox
		};

		// Due label

		due_label = new Gtk.Label (null);
		due_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

		due_box = new Gtk.Box (VERTICAL, 0);
		due_box.append (due_label);

		due_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = due_box
		};

		var footer_box = new Gtk.Box (HORIZONTAL, 0) {
			hexpand = true,
			margin_start = 30,
			margin_top = 6,
			margin_end = 6
		};
		footer_box.append (due_revealer);

		footer_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = footer_box
		};

		handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };
		handle_grid.append (content_box);
		handle_grid.append (description_label_revealer);
		handle_grid.append (flowbox_revealer);
		handle_grid.append (footer_revealer);
		handle_grid.add_css_class (Granite.STYLE_CLASS_CARD);
		handle_grid.add_css_class ("border-radius-9");
		handle_grid.add_css_class ("pb-6");

        var overlay = new Gtk.Overlay ();
		overlay.child = handle_grid;
		overlay.add_overlay (hide_loading_revealer);

		main_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
		};

		main_revealer.child = overlay;

		child = main_revealer;
		update_request ();

		Timeout.add (main_revealer.transition_duration, () => {
			main_revealer.reveal_child = true;

			if (!item.checked) {
				build_drag_and_drop ();
			}

			if (item.activate_name_editable) {
                content_textview.grab_focus ();
			}

			return GLib.Source.REMOVE;
		});

		var checked_button_gesture = new Gtk.GestureClick ();
		checked_button_gesture.set_button (1);
		checked_button.add_controller (checked_button_gesture);

		checked_button_gesture.pressed.connect (() => {
			checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
			checked_button.active = !checked_button.active;
			checked_toggled (checked_button.active);
		});

        var content_controller_key = new Gtk.EventControllerKey ();
        content_textview.add_controller (content_controller_key);

        content_controller_key.key_released.connect ((keyval, keycode, state) => {
            update ();
        });


        var motion_gesture = new Gtk.EventControllerMotion ();
        add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            hide_loading_revealer.reveal_child = true;
        });

        motion_gesture.leave.connect (() => {
            hide_loading_revealer.reveal_child = false;
        });

		hide_loading_button.clicked.connect (() => {
            var dialog = new Dialogs.Item (item);
            dialog.show ();
        });

		var handle_gesture_click = new Gtk.GestureClick ();
        handle_grid.add_controller (handle_gesture_click);

        handle_gesture_click.pressed.connect ((n_press, x, y) => {
            if (n_press >= 2) {
                var dialog = new Dialogs.Item (item);
                dialog.show ();
            }
        });
	}

	private void update () {
        if (item.content != content_textview.buffer.text) {
            item.content = content_textview.buffer.text;
            item.update_async_timeout (update_id, this);
        }
    }

	public void checked_toggled (bool active, uint? time = null) {
		Services.EventBus.get_default ().unselect_all ();
		bool old_checked = item.checked;

		if (active) {
			complete_item (old_checked, time);
		} else {
			if (complete_timeout != 0) {
				GLib.Source.remove (complete_timeout);
				complete_timeout = 0;
			} else {
				item.checked = false;
				item.completed_at = "";

				if (item.project.backend_type == BackendType.TODOIST) {
					checked_button.sensitive = false;
					is_loading = true;
					Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
						if (Services.Todoist.get_default ().complete_item.end (res)) {
							Services.Database.get_default ().checked_toggled (item, old_checked);
							is_loading = false;
							checked_button.sensitive = true;
						}
					});
				} else {
					Services.Database.get_default ().checked_toggled (item, old_checked);
				}
			}
		}
	}

	private void complete_item (bool old_checked, uint? time = null) {
		uint timeout = 2500;
		if (Services.Settings.get_default ().settings.get_enum ("complete-task") == 0) {
			timeout = 0;
		}

		if (time != null) {
			timeout = time;
		}

		complete_timeout = Timeout.add (timeout, () => {
			complete_timeout = 0;

			if (item.due.is_recurring) {
				update_recurrency ();
			} else {
				item.checked = true;
				item.completed_at = Util.get_default ().get_format_date (
					new GLib.DateTime.now_local ()).to_string ();

				if (item.project.backend_type == BackendType.TODOIST) {
					checked_button.sensitive = false;
					is_loading = true;
					Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
						if (Services.Todoist.get_default ().complete_item.end (res)) {
							Services.Database.get_default ().checked_toggled (item, old_checked);
							is_loading = false;
							checked_button.sensitive = true;
						} else {
							is_loading = false;
							checked_button.sensitive = true;
						}
					});
				} else {
					Services.Database.get_default ().checked_toggled (item, old_checked);
				}
			}

			return GLib.Source.REMOVE;
		});
	}

	private void update_recurrency () {
		var next_recurrency = Util.get_default ().next_recurrency (item.due.datetime, item.due);
		item.due.date = Util.get_default ().get_todoist_datetime_format (
			next_recurrency
			);

		if (item.project.backend_type == BackendType.TODOIST) {
			checked_button.sensitive = false;
			is_loading = true;
			Services.Todoist.get_default ().update.begin (item, (obj, res) => {
				if (Services.Todoist.get_default ().update.end (res)) {
					Services.Database.get_default ().update_item (item);
					is_loading = false;
					checked_button.sensitive = true;
					recurrency_update_complete (next_recurrency);
				} else {
					is_loading = false;
					checked_button.sensitive = true;
				}
			});
		} else {
			Services.Database.get_default ().update_item (item);
			recurrency_update_complete (next_recurrency);
		}
	}

	private void recurrency_update_complete (GLib.DateTime next_recurrency) {
		checked_button.active = false;
		complete_timeout = 0;

		var title = _("Completed. Next occurrence: %s".printf (Util.get_default ().get_default_date_format_from_date (next_recurrency)));
		var toast = Util.get_default ().create_toast (title, 3);

		Services.EventBus.get_default ().send_notification (toast);
	}

	public void update_request () {
		if (complete_timeout <= 0) {
			Util.get_default ().set_widget_priority (item.priority, checked_button);
			checked_button.active = item.completed;
		}

		content_textview.buffer.text = item.content;
		description_label.label = Util.get_default ().line_break_to_space (item.description);
		description_label_revealer.reveal_child = description_label.label.length > 0;
		update_due_label ();
		update_labels ();
		footer_revealer.reveal_child = due_revealer.reveal_child;
	}

	public void update_due_label () {
		due_box.remove_css_class ("overdue-grid");
		due_box.remove_css_class ("today-grid");
		due_box.remove_css_class ("upcoming-grid");

		if (item.completed) {
			due_label.label = Util.get_default ().get_relative_date_from_date (
				Util.get_default ().get_date_from_string (item.completed_at)
				);
			due_box.add_css_class ("completed-grid");
			due_revealer.reveal_child = true;
			return;
		}

		if (item.has_due) {
			due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
			due_revealer.reveal_child = true;

			if (Util.get_default ().is_today (item.due.datetime)) {
				due_box.add_css_class ("today-grid");
			} else if (Util.get_default ().is_overdue (item.due.datetime)) {
				due_box.add_css_class ("overdue-grid");
			} else {
				due_box.add_css_class ("upcoming-grid");
			}
		} else {
			due_label.label = "";
			due_revealer.reveal_child = false;
		}
	}

	private void update_labels () {
		// int more = 0;
		// int count = 0;
		// string tooltip_text = "";
		// more_label_revealer.reveal_child = false;

		foreach (Objects.ItemLabel item_label in item.labels.values) {
			if (!labels.has_key (item_label.id_string)) {
				//  if (itemrow == null && labels.size >= 1) {
				//      more++;
				//      more_label.label = "+%d".printf (more);
				//      tooltip_text += "- %s%s".printf (
				//          item_label.label.name,
				//          more + 1 >= item.labels.values.size ? "" : "\n"
				//      );
				//      more_label_grid.tooltip_text = tooltip_text;
				//      more_label_revealer.reveal_child = true;
				//  } else {
				//  Util.get_default ().set_widget_color (
				//      Util.get_default ().get_color (item_label.label.color),
				//      more_label_grid
				//  );

				labels[item_label.id_string] = new Widgets.ItemLabelChild (item_label);
				labels_flowbox.append (labels[item_label.id_string]);
				// }

				// count++;
			}
		}

		flowbox_revealer.reveal_child = labels.size > 0;
	}

	private void build_drag_and_drop () {
		drag_source = new Gtk.DragSource ();
		drag_source.set_actions (Gdk.DragAction.MOVE);

		drag_source.prepare.connect ((source, x, y) => {
			return new Gdk.ContentProvider.for_value (this);
		});

		drag_source.drag_begin.connect ((source, drag) => {
			var paintable = new Gtk.WidgetPaintable (handle_grid);
			source.set_icon (paintable, 0, 0);
			drag_begin ();
		});

		drag_source.drag_end.connect ((source, drag, delete_data) => {
			drag_end ();
		});

		drag_source.drag_cancel.connect ((source, drag, reason) => {
			drag_end ();
			return false;
		});

		add_controller (drag_source);

		drop_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
		drop_target.preload = true;

		drop_target.drop.connect ((value, x, y) => {
			var picked_widget = (Layouts.ItemBoard) value;
			var target_widget = this;

			Gtk.Allocation alloc;
			target_widget.get_allocation (out alloc);

			picked_widget.drag_end ();
			target_widget.drag_end ();

			if (picked_widget == target_widget || target_widget == null) {
				return false;
			}

			var source_list = (Gtk.ListBox) picked_widget.parent;
			var target_list = (Gtk.ListBox) target_widget.parent;

			source_list.remove (picked_widget);

			if (target_widget.get_index () == 0) {
				if (y < (alloc.height / 2)) {
					target_list.insert (picked_widget, 0);
				} else {
					target_list.insert (picked_widget, target_widget.get_index () + 1);
				}
			} else {
				target_list.insert (picked_widget, target_widget.get_index () + 1);
			}

			return true;
		});

		add_controller (drop_target);
	}

	public void drag_begin () {
        on_drag = true;
        opacity = 0.3;

        Services.EventBus.get_default ().item_drag_begin (item);
	}

	public void drag_end () {
        on_drag = false;
        opacity = 1;

        Services.EventBus.get_default ().item_drag_end (item);
	}

	public void hide_destroy () {
		main_revealer.reveal_child = false;
		Timeout.add (main_revealer.transition_duration, () => {
			((Gtk.ListBox) parent).remove (this);
			return GLib.Source.REMOVE;
		});
	}
}
