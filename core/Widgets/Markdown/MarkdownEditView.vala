/*
 *
 * Based on Folio
 * https://github.com/toolstack/Folio
 */

public class Widgets.Markdown.EditView : Adw.Bin {
    public bool text_mode {
        set {
            markdown_view.text_mode = value;
        }
    }

    public Gdk.RGBA theme_color {
        get {
            return markdown_view.theme_color;
        }

        set {
            markdown_view.theme_color = value;
        }
    }

    public Gtk.TextBuffer buffer {
        get {
            return markdown_view.buffer;
        }

        set {
            markdown_view.buffer = value;
            Gtk.TextIter start;
            markdown_view.buffer.get_start_iter (out start);
            markdown_view.buffer.place_cursor (start);
        }
    }

    public bool card {
        set {
            if (value) {
                add_css_class ("card");
            } else {
                remove_css_class ("card");
            }
        }
    }

    public int left_margin {
        set {
            markdown_view.left_margin = value;
        }
    }

    public int right_margin {
        set {
            markdown_view.right_margin = value;
        }
    }

    public int top_margin {
        set {
            markdown_view.top_margin = value;
        }
    }

    public int bottom_margin {
        set {
            markdown_view.bottom_margin = value;
        }
    }

    public bool connect_typing { get; set; default = false; }

    private Widgets.Markdown.View markdown_view;

    private bool is_ctrl = false;

    public bool is_editable {
        set {
            markdown_view.editable = value;
        }

        get {
            return markdown_view.editable;
        }
    }
    public signal void enter ();
    public signal void leave ();
    public signal void changed ();
    public signal void escape ();

    ~EditView () {
        debug ("Destroying - Widgets.Markdown.EditView\n");
    }

    construct {
        markdown_view = new Widgets.Markdown.View () {
            hexpand = true,
            tab_width = 4,
            auto_indent = true,
            wrap_mode = Gtk.WrapMode.WORD,
            show_gutter = false,
            height_request = 64,
            text_mode = !Services.Settings.get_default ().settings.get_boolean ("enable-markdown-formatting"),
            accepts_tab = false,
            buffer = new Widgets.Markdown.Buffer ()
        };

        markdown_view.remove_css_class ("view");

        #if LIBSPELLING
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) markdown_view.buffer, Spelling.Checker.get_default ());

			markdown_view.extra_menu = adapter.get_menu_model ();
			markdown_view.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

        var click_controller = new Gtk.GestureClick ();
        markdown_view.add_controller (click_controller);
        click_controller.released.connect ((n, x, y) => {
            if (is_ctrl) {
                var ins = markdown_view.buffer.get_insert ();
                Gtk.TextIter cur;
                markdown_view.buffer.get_iter_at_mark (out cur, ins);
                var text_tag_url = markdown_view.buffer.tag_table.lookup ("markdown-link");

                if (cur.has_tag (text_tag_url)) {
                    Gtk.TextIter start_url, end_url;
                    string url_text = "";
                    if (!markdown_view.check_if_in_link (markdown_view, out url_text)) {
                        start_url = cur;
                        end_url = cur;
                        start_url.backward_to_tag_toggle (text_tag_url);
                        end_url.forward_to_tag_toggle (text_tag_url);

                        url_text = markdown_view.buffer.get_slice (start_url, end_url, true);
                        url_text = url_text.chomp ().chug ();
                    }

                    // Check to see if we have an e-mail link to open.
                    // check_if_email_link will validate a real url for us.
                    if (markdown_view.check_if_email_link (url_text)) {
                        if (!url_text.contains ("://"))
                            url_text = "mailto:" + url_text;

                        try {
                            GLib.AppInfo.launch_default_for_uri (url_text, null);
                        } catch (Error e) {
                            Util.get_default ().create_toast (_("Couldn't find an app to handle file URIs"));
                        }
                    } else {
                        // Since it wasn't an e-mail address, check to see if we have a valid url
                        // to open.  check_if_bare_link will validate a real url for us.
                        if (markdown_view.check_if_bare_link (url_text)) {
                            // If it's bare, add in http by default.
                            if (!url_text.contains ("://"))
                                url_text = "http://" + url_text;
                            try {
                                GLib.AppInfo.launch_default_for_uri (url_text, null);
                            } catch (Error e) {
                                Util.get_default ().create_toast (_("Couldn't find an app to handle file URIs"));
                            }
                        } else {
                            Util.get_default ().create_toast (_("Couldn't find an app to handle file URIs"));
                        }
                    }
                }
            }
        });

        var key_controller = new Gtk.EventControllerKey ();
        add_controller (key_controller);
        key_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R) {
                is_ctrl = true;
            }

            return false;
        });

        key_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R) {
                is_ctrl = false;
            }

            if (keyval == Gdk.Key.Escape) {
                escape ();
            }
        });

        var gesture = new Gtk.EventControllerFocus ();
        markdown_view.add_controller (gesture);
        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);
        markdown_view.buffer.changed.connect (handle_focus_in);

        child = markdown_view;

        on_dark_changed (Services.Settings.get_default ().settings.get_boolean ("dark-mode"));
        Services.EventBus.get_default ().theme_changed.connect (() => {
            on_dark_changed (Services.Settings.get_default ().settings.get_boolean ("dark-mode"));
        });

        Services.Settings.get_default ().settings.changed["enable-markdown-formatting"].connect (() => {
            markdown_view.text_mode = !Services.Settings.get_default ().settings.get_boolean ("enable-markdown-formatting");
        });

        recolor (Color.RGB ());
    }

    private void handle_focus_in () {
        Services.EventBus.get_default ().disconnect_typing_accel ();
        enter ();
    }

    public void update_on_leave () {
        if (connect_typing) {
            Services.EventBus.get_default ().connect_typing_accel ();
            leave ();
        }
    }

    public void on_dark_changed (bool dark) {
        markdown_view.dark = dark;
    }

    private void format_selection (string affix, string second_affix) {
        var buffer = markdown_view.buffer;

        buffer.begin_user_action ();

        if (!markdown_view.remove_formatting (markdown_view, affix) &&
            !markdown_view.remove_formatting (markdown_view, second_affix)) {
            Gtk.TextIter selection_start, selection_end, cursor;
            Gtk.TextMark cursor_mark, selection_start_mark, selection_end_mark;
            buffer.get_selection_bounds (out selection_start, out selection_end);
            buffer.get_iter_at_mark (out cursor, buffer.get_insert ());
            cursor_mark = buffer.create_mark (null, cursor, true);
            selection_start_mark = buffer.create_mark (null, selection_start, true);
            selection_end_mark = buffer.create_mark (null, selection_end, true);

            var is_selected = true;

            if (selection_start.equal (selection_end)) {
                is_selected = false;

                find_word_selection (ref selection_start, ref selection_end);

                buffer.select_range (selection_start, selection_end);
                selection_start_mark = buffer.create_mark (null, selection_start, true);
                selection_end_mark = buffer.create_mark (null, selection_end, true);
            }

            buffer.insert (ref selection_start, affix, affix.length);

            buffer.get_selection_bounds (out selection_start, out selection_end);
            buffer.insert (ref selection_end, affix, affix.length);

            buffer.get_iter_at_mark (out selection_start, selection_start_mark);
            buffer.get_iter_at_mark (out cursor, cursor_mark);

            if (cursor.equal (selection_start)) {
                cursor.forward_chars (affix.length);
            }

            buffer.place_cursor (cursor);

            if (is_selected) {
                buffer.get_iter_at_mark (out selection_start, selection_start_mark);
                buffer.get_iter_at_mark (out selection_end, selection_end_mark);
                selection_end.forward_chars (affix.length);
                buffer.select_range (selection_start, selection_end);
            } else {
                buffer.select_range (cursor, cursor);
            }

            markdown_view.grab_focus ();
        }

        buffer.end_user_action ();
    }

    public void format_selection_bold () {
        format_selection ("**", "__");
    }

    public void format_selection_italic () {
        format_selection ("_", "*");
    }

    public void format_selection_strikethrough () {
        format_selection ("~~", "~");
    }

    public void format_selection_highlight () {
        format_selection ("==", "");
    }

    public void insert_link () {
        var buffer = markdown_view.buffer;
        buffer.begin_user_action ();

        if (!markdown_view.check_if_in_link (markdown_view)) {
            var url_found = false;
            Gtk.TextIter selection_start, selection_end;
            buffer.get_selection_bounds (out selection_start, out selection_end);

            if (selection_start.equal (selection_end)) {
                find_word_selection (ref selection_start, ref selection_end);

                buffer.select_range (selection_start, selection_end);
            }

            buffer.get_selection_bounds (out selection_start, out selection_end);
            var selection_text = buffer.get_slice (selection_start, selection_end, true);
            url_found = markdown_view.check_if_bare_link (selection_text);

            Gtk.TextMark start_mark, end_mark;
            buffer.get_selection_bounds (out selection_start, out selection_end);
            // Make sure our marks in in ascending order to simplify things later.
            if (selection_start.compare (selection_end) > 1) {
                start_mark = buffer.create_mark (null, selection_end, true);
                end_mark = buffer.create_mark (null, selection_start, true);
            } else {
                start_mark = buffer.create_mark (null, selection_start, true);
                end_mark = buffer.create_mark (null, selection_end, true);
            }

            {
                buffer.get_iter_at_mark (out selection_start, start_mark);
                if (url_found) {
                    buffer.insert (ref selection_start, "[](", 3);
                } else {
                    buffer.insert (ref selection_start, "[", 1);
                }
            }
            {
                buffer.get_iter_at_mark (out selection_end, end_mark);
                if (url_found) {
                    buffer.insert (ref selection_end, ")", 1);
                } else {
                    buffer.insert (ref selection_end, "]()", 3);
                }
            }
            buffer.get_iter_at_mark (out selection_start, start_mark);
            buffer.get_iter_at_mark (out selection_end, end_mark);
            if (url_found) {
                selection_start.forward_char ();
                buffer.place_cursor (selection_start);
            } else {
                selection_end.forward_chars (2);
                buffer.place_cursor (selection_end);
            }
        }

        markdown_view.grab_focus ();
        buffer.end_user_action ();
    }

    public void insert_code_span () {
        format_selection ("`", "");
    }

    public void insert_horizontal_rule () {
        var buffer = markdown_view.buffer;

        buffer.begin_user_action ();

        var mark = buffer.get_selection_bound ();
        Gtk.TextIter iter, current_line_start, current_line_end;
        buffer.get_iter_at_mark (out iter, mark);
        current_line_start = iter.copy ();
        current_line_start.backward_line ();
        current_line_start.forward_char ();
        current_line_end = iter.copy ();
        current_line_end.forward_line ();
        current_line_end.backward_char ();

        string current_line = buffer.get_slice (current_line_start, current_line_end, true);

        if (current_line != "- - -") {
            current_line_start.backward_char ();
            current_line_start.forward_line ();
            buffer.insert (ref current_line_start, "- - -\n", 6);
            buffer.get_iter_at_mark (out iter, mark);
            buffer.place_cursor (iter);
        }

        markdown_view.grab_focus ();

        buffer.end_user_action ();
    }

    private void find_word_selection (ref Gtk.TextIter selection_start, ref Gtk.TextIter selection_end) {
        var current_char = selection_start.get_char ();
        // If we're at the end of line, move back one.
        if (current_char == '\n') {
            selection_start.backward_char ();
            current_char = selection_start.get_char ();
        }
        // If the cursor is in a blank spot (1 or more spaces/tabs) then go backwards until
        // we find a word/start of line/start of buffer.
        while ((current_char == ' ' || current_char == '\t') && current_char != '\n' && !selection_start.is_start ()) {
            selection_start.backward_char ();
            current_char = selection_start.get_char ();
        }
        // Now continue going backwards until we find the start of the word of end condition.
        while (current_char != '\n' && current_char != ' ' && current_char != '\t' && !selection_start.is_start ()) {
            selection_start.backward_char ();
            current_char = selection_start.get_char ();
        }
        // Since we are now on the end condition, move forward one character as long as
        // we're not at the very begining of the buffer.
        if (!selection_start.is_start ()) {
            selection_start.forward_char ();
        }
        current_char = selection_end.get_char ();
        // If we're at the end of line, we're done.
        if (current_char != '\n') {
            while (current_char != '\n' && current_char != ' ' && current_char != '\t' && !selection_end.is_end ()) {
                selection_end.forward_char ();
                current_char = selection_end.get_char ();
            }
        }
    }

    public void reset_scroll_position () {
        Gtk.TextIter start;
        markdown_view.buffer.get_start_iter (out start);
        markdown_view.buffer.place_cursor (start);
        markdown_view.grab_focus ();
    }

    private void recolor (Color.RGB rgb) {
        var rgba = Gdk.RGBA ();
        var light_rgba = Gdk.RGBA ();
        var hsl = Color.rgb_to_hsl (rgb);
        {
            hsl.l = 0.5f;
            Color.hsl_to_rgb (hsl, out rgb);
            Color.rgb_to_RGBA (rgb, out rgba);
            hsl.l = 0.7f;
            Color.hsl_to_rgb (hsl, out rgb);
            Color.rgb_to_RGBA (rgb, out light_rgba);
        }
        var css = new Gtk.CssProvider ();
        css.load_from_string (@"@define-color theme_color $rgba;@define-color notebook_light_color $light_rgba;");
        get_style_context ().add_provider (css, -1);
        theme_color = rgba;
    }

    public void view_focus () {
        markdown_view.grab_focus ();
    }

    public string get_all_text () {
        Gtk.TextIter start;
        Gtk.TextIter end;

        (markdown_view.buffer as Widgets.Markdown.Buffer).get_start_iter (out start);
        (markdown_view.buffer as Widgets.Markdown.Buffer).get_end_iter (out end);

        return (markdown_view.buffer as Widgets.Markdown.Buffer).get_text (start, end, true);
    }
}
