
public class Views.Project : Gtk.Grid {
	public Objects.Project project { get; construct; }

	private Gtk.Stack view_stack;

	public Project (Objects.Project project) {
		Object (
			project: project
		);
	}

	construct {
		var sidebar_image = new Widgets.DynamicIcon ();
		sidebar_image.size = 16;
		if (Services.Settings.get_default ().settings.get_boolean ("slim-mode")) {
			sidebar_image.update_icon_name ("sidebar-left");
		} else {
			sidebar_image.update_icon_name ("sidebar-right");
		}

		var sidebar_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER
		};

		sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);
		sidebar_button.child = sidebar_image;

		var inbox_icon = new Gtk.Image () {
			gicon = new ThemedIcon ("planner-inbox"),
			pixel_size = 16
		};

		var title_label = new Gtk.Label (project.name);
		title_label.add_css_class ("font-bold");

		var menu_image = new Widgets.DynamicIcon ();
		menu_image.size = 16;
		menu_image.update_icon_name ("dots-vertical");

		var menu_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			popover = build_context_menu ()
		};

		menu_button.child = menu_image;
		menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var list_image = new Widgets.DynamicIcon ();
		list_image.size = 21;
		list_image.update_icon_name ("unordered-list");

		var board_image = new Widgets.DynamicIcon ();
		board_image.size = 21;
		board_image.update_icon_name ("planner-board");

		var list_button = new Gtk.ToggleButton () {
			active = true,
			child = list_image,
			valign = Gtk.Align.CENTER,
			tooltip_text = _("List View"),
			active = project.view_style == ProjectViewStyle.LIST
		};

		list_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var board_button = new Gtk.ToggleButton () {
			child = board_image,
			valign = Gtk.Align.CENTER,
			tooltip_text = _("Board View"),
			active = project.view_style == ProjectViewStyle.BOARD
		};

		board_button.set_group (list_button);
		board_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var view_mode_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			hexpand = true,
			homogeneous = true,
			valign = Gtk.Align.CENTER
		};

		view_mode_box.add_css_class (Granite.STYLE_CLASS_LINKED);
		view_mode_box.append (list_button);
		view_mode_box.append (board_button);

		var add_image = new Widgets.DynamicIcon ();
		add_image.size = 16;
		add_image.update_icon_name ("plus");

		var add_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Add To-Do")
		};

		add_button.child = add_image;
		add_button.add_css_class (Granite.STYLE_CLASS_FLAT);
		// add_button.tooltip_markup = Granite.markup_accel_tooltip ({"a"}, _("Add To-Do"));

		var search_image = new Widgets.DynamicIcon ();
		search_image.size = 16;
		search_image.update_icon_name ("planner-search");

		var search_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER
		};

		search_button.add_css_class (Granite.STYLE_CLASS_FLAT);
		search_button.child = search_image;
		// search_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control>f"}, _("Quick Find"));

		var sections_image = new Widgets.DynamicIcon ();
		sections_image.size = 16;
		sections_image.update_icon_name ("dropdown");

		var sections_order_popover = new Widgets.SectionsOrderPopover (project);

		var sections_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			child = sections_image,
			popover = sections_order_popover
		};
		sections_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
			decoration_layout = ":close"
		};

		headerbar.add_css_class ("flat");
		headerbar.pack_start (sidebar_button);
		if (project.id == Services.Settings.get_default ().settings.get_string ("inbox-project-id")) {
			headerbar.pack_start (inbox_icon);
		}
		headerbar.pack_start (title_label);
		headerbar.pack_end (menu_button);
		headerbar.pack_end (search_button);
		// headerbar.pack_end (sections_button);
		headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
			margin_start = 3,
			margin_end = 3,
			opacity = 0
		});
		//  headerbar.pack_end (view_mode_box);
		//  headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
		//  	margin_start = 3,
		//  	margin_end = 3,
		//  	opacity = 0
		//  });
		headerbar.pack_end (add_button);
		headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
			margin_start = 3,
			margin_end = 3,
			opacity = 0
		});

		view_stack = new Gtk.Stack () {
			hexpand = true,
			vexpand = true,
			transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
		};

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true,
			vexpand = true
		};

		content_box.append (view_stack);

		var content_overlay = new Gtk.Overlay () {
			hexpand = true,
			vexpand = true
		};

		content_overlay.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_overlay;

		attach (toolbar_view, 0, 0);
		update_project_view (ProjectViewStyle.LIST);
		show();

		add_button.clicked.connect (() => {
			prepare_new_item ();
		});

		list_button.toggled.connect (() => {
			update_project_view (ProjectViewStyle.LIST);
		});

		board_button.toggled.connect (() => {
			update_project_view (ProjectViewStyle.BOARD);
		});

		search_button.clicked.connect (() => {
			var dialog = new Dialogs.QuickFind.QuickFind ();
			dialog.show ();
		});

		sidebar_button.clicked.connect (() => {
			Planner._instance.main_window.show_hide_sidebar ();
		});

		project.updated.connect (() => {
			title_label.label = project.name;
		});
	}

	private void update_project_view (ProjectViewStyle view_style) {
		if (view_style == ProjectViewStyle.LIST) {
			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
			if (list_view == null) {
				list_view = new Views.List (project);
				view_stack.add_named (list_view, view_style.to_string ());
			}

			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name ("board");
			if (board_view != null) {
				view_stack.remove (board_view);
			}
		} else if (view_style == ProjectViewStyle.BOARD) {
			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
			if (board_view == null) {
				board_view = new Views.Board (project);
				view_stack.add_named (board_view, view_style.to_string ());
			}

			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name ("list");
			if (list_view != null) {
				view_stack.remove (list_view);
			}
		}

		view_stack.set_visible_child_name (view_style.to_string ());
		project.view_style = view_style;
		project.update (false);
	}

	public void prepare_new_item (string content = "") {
		if (project.view_style == ProjectViewStyle.LIST) {
			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name (project.view_style.to_string ());
			if (list_view != null) {
				list_view.prepare_new_item (content);
			}
		} else {
			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name (project.view_style.to_string ());
			if (board_view != null) {
                board_view.prepare_new_item (content);
			}
		}
	}

	private Widgets.ContextMenu.MenuItem show_completed_item;
	private Gtk.Popover build_context_menu () {
		var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Project"), "planner-edit");
		var schedule_item = new Widgets.ContextMenu.MenuItem (_("When?"), "planner-calendar");
		var description_item = new Widgets.ContextMenu.MenuItem (_("Description"), "planner-note");

		var add_section_item = new Widgets.ContextMenu.MenuItem (_("Add Section"), "planner-section");
		show_completed_item = new Widgets.ContextMenu.MenuItem (
			project.show_completed ? _("Hide completed tasks") : _("Show Completed Tasks"),
			"planner-check-circle"
			);

		var filter_by_tags = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "planner-tag");

		var select_item = new Widgets.ContextMenu.MenuItem (_("Select"), "unordered-list");

		var paste_item = new Widgets.ContextMenu.MenuItem (_("Paste"), "planner-clipboard");

		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "planner-trash");
		delete_item.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		if (!project.is_inbox_project) {
			menu_box.append (edit_item);
			menu_box.append (description_item);
			menu_box.append (schedule_item);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		}

		menu_box.append (add_section_item);
		menu_box.append (select_item);
		menu_box.append (paste_item);
		menu_box.append (show_completed_item);

		if (!project.inbox_project) {
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
			menu_box.append (delete_item);
		}

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box
		};

		edit_item.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.Project (project);
			dialog.show ();
		});

		description_item.activate_item.connect (() => {
			popover.popdown ();
			var dialog = new Dialogs.ProjectDescription (project);
			dialog.show ();
		});

		schedule_item.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.DatePicker (_("When?"));
			dialog.clear = project.due_date != "";
			dialog.show ();

			dialog.date_changed.connect (() => {
				if (dialog.datetime == null) {
					project.due_date = "";
				} else {
					project.due_date = dialog.datetime.to_string ();
				}

				project.update_no_timeout ();
			});
		});

		filter_by_tags.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.LabelPicker ();
			dialog.labels = project.label_filter;
			dialog.show ();

			dialog.labels_changed.connect ((labels) => {
				project.label_filter = labels;
			});
		});

		show_completed_item.activate_item.connect (() => {
			popover.popdown ();

			project.show_completed = !project.show_completed;
			project.update ();

			show_completed_item.title = project.show_completed ? _("Hide Completed Tasks") : _("Show completed tasks");
		});

		add_section_item.activate_item.connect (() => {
			Objects.Section new_section = prepare_new_section ();

			if (project.backend_type == BackendType.TODOIST) {
				add_section_item.is_loading = true;
				Services.Todoist.get_default ().add.begin (new_section, (obj, res) => {
					new_section.id = Services.Todoist.get_default ().add.end (res);
					project.add_section_if_not_exists (new_section);
					add_section_item.is_loading = false;
					popover.popdown ();
				});
			} else {
				new_section.id = Util.get_default ().generate_id ();
				project.add_section_if_not_exists (new_section);
				popover.popdown ();
			}
		});

		paste_item.clicked.connect (() => {
			popover.popdown ();
			Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();

			clipboard.read_text_async.begin (null, (obj, res) => {
				try {
					string content = clipboard.read_text_async.end (res);
					Services.EventBus.get_default ().paste_action (project.id, content);
				} catch (GLib.Error error) {
					debug (error.message);
				}
			});
		});

		select_item.clicked.connect (() => {
			popover.popdown ();
			Services.EventBus.get_default ().multi_select_enabled = true;
			Services.EventBus.get_default ().show_multi_select (true);
		});

		delete_item.clicked.connect (() => {
			popover.popdown ();

			var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window,
			                                    _("Delete project"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (project.short_name))));

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("delete", _("Delete"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.show ();

			dialog.response.connect ((response) => {
				if (response == "delete") {
					if (project.backend_type == BackendType.TODOIST) {
						Services.Todoist.get_default ().delete.begin (project, (obj, res) => {
							if (Services.Todoist.get_default ().delete.end (res)) {
								Services.Database.get_default ().delete_project (project);
							}
						});
					} else if (project.backend_type == BackendType.LOCAL) {
						Services.Database.get_default ().delete_project (project);
					}
				}
			});
		});

		return popover;
	}

	public Objects.Section prepare_new_section () {
		Objects.Section new_section = new Objects.Section ();
		new_section.project_id = project.id;
		new_section.name = _("New section");
		new_section.activate_name_editable = true;
		new_section.section_order = project.sections.size;

		return new_section;
	}
}
