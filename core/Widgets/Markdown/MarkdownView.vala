/*
 *
 * Based on Folio
 * https://github.com/toolstack/Folio
 */

public class Widgets.Markdown.View : GtkSource.View {
	public bool text_mode { get; set; default = false; }

	public bool dark { get; set; default = false; }
	public Gdk.RGBA theme_color { get; set; }
	public string font_monospace { get; set; default = "Monospace 10"; }

	public Gdk.RGBA h6_color {
		get {
			var rgba = get_color ();
			rgba.alpha = 0.6f;
			return rgba;
		}
	}

	public Gdk.RGBA marking_color {
		get {
			var rgba = get_color ();
			rgba.alpha = 0.6f;
			return rgba;
		}
	}

	public Gdk.RGBA url_color {
		get {
			var hsl = Color.rgb_to_hsl (Color.RGBA_to_rgb (theme_color));
			hsl.l = 0.42f;
			return Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
		}
	}

	public Gdk.RGBA highlight_color {
		get {
			var rgb = Color.RGBA_to_rgb (theme_color);
			if (dark) {
				var hsl = Color.rgb_to_hsl (rgb);
				hsl.s = float.min (hsl.s * 1.2f, 1);
				hsl.l = 0.46f;
				var rgba = Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
				rgba.alpha = 0.5f;
				return rgba;
			} else {
				rgb.r = float.min (rgb.r * 1.8f, 1);
				rgb.g = float.min (rgb.g * 2.0f, 1);
				rgb.b = float.min (rgb.b * 1.4f, 1);
				var hsl = Color.rgb_to_hsl (rgb);
				hsl.l = 0.82f;
				return Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
			}
		}
	}

	public Gdk.RGBA tinted_foreground {
		get {
			var hsl = Color.rgb_to_hsl (Color.RGBA_to_rgb (theme_color));
			hsl.l = 0.5f;
			hsl.s *= 0.64f;
			return Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
		}
	}

	public Gdk.RGBA block_color {
		get {
			var hsl = Color.rgb_to_hsl (Color.RGBA_to_rgb (theme_color));
			hsl.l = dark ? 0.7f : 0.3f;
			hsl.s *= 0.64f;
			var rgba = Color.rgb_to_RGBA (Color.hsl_to_rgb (hsl));
			rgba.alpha = 0.1f;
			return rgba;
		}
	}

	public bool show_gutter { get; set; default = true; }

	public new Gtk.TextBuffer? buffer {
		get { return base.buffer; }
		set {
			base.buffer = value;
			update_color_scheme ();
			update_font ();
			buffer.changed.connect (restyle_text_all);
			buffer.notify["cursor-position"].connect (restyle_text_cursor);
			restyle_text_all ();
		}
	}

	public uint get_title_level (uint line) {
		Gtk.TextIter start;
		Gtk.TextIter end;
		buffer.get_iter_at_line (out start, (int) line);
		end = start.copy ();
		end.forward_to_line_end ();
		var str = start.get_text (end);
		var i = 0;
		while (i < 6 && i < str.length) {
			if (str[i] != '#') break;
			i++;
		}
		if (str[i] != ' ') return 0;
		return i;
	}

	public void set_title_level (uint line, uint level) {
		var old_title_level = get_title_level (line);
		if (old_title_level == level) return;
		if (level > old_title_level) {
			if (old_title_level == 0) {
				Gtk.TextIter start;
				buffer.get_iter_at_line (out start, (int) line);
				var end = start.copy ();
				end.forward_chars (1);
				var str = start.get_text (end);
				if (str[0] != ' ') {
					buffer.insert (ref start, " ", 1);
				}
			}
			Gtk.TextIter start;
			buffer.get_iter_at_line (out start, (int) line);
			var str = string.nfill (level - old_title_level, '#');
			buffer.insert (ref start, str, str.length);
		} else {
			Gtk.TextIter start;
			buffer.get_iter_at_line (out start, (int) line);
			var end = start.copy ();
			end.forward_chars ((int) (old_title_level - level));
			buffer.@delete (ref start, ref end);
			if (level == 0) {
				var e = end.copy ();
				e.forward_chars (1);
				var str = end.get_text (e);
				if (str[0] == ' ') {
					buffer.@delete (ref end, ref e);
				}
			}
		}
	}

	public bool check_if_bare_link (string text) {
		MatchInfo matches;
		try {
			if ( is_bare_link.match_full (text, text.length, 0, 0, out matches)) {
				return true;
			}
		} catch (Error e) {}
		return false;
	}

	public bool check_if_email_link (string text) {
		MatchInfo matches;
		try {
			if (is_email_link.match_full (text, text.length, 0, 0, out matches)) {
				return true;
			}
		} catch (Error e) {}
		return false;
	}

	public bool check_if_in_link (Widgets.Markdown.View markdown_view, out string? link_url = null) {
		Gtk.TextIter buffer_start, buffer_end;
		buffer.get_bounds (out buffer_start, out buffer_end);
		var buffer_text = buffer.get_text (buffer_start, buffer_end, true);

		Gtk.TextIter selection_start, selection_end, cursor;
		buffer.get_selection_bounds (out selection_start, out selection_end);
		buffer.get_iter_at_mark (out cursor, buffer.get_insert ());
		var cursor_offset = cursor.get_offset ();

		bool found_match = false;
		MatchInfo matches;
		link_url = "";

		try {
			if (is_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					int start_url_pos, end_url_pos;
					bool have_text = matches.fetch_pos (1, out start_text_pos, out end_text_pos);
					bool have_url = matches.fetch_pos (2, out start_url_pos, out end_url_pos);

					if (have_text && have_url) {

						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_url_pos = buffer_text.char_count ((ssize_t) end_url_pos);

						if (cursor_offset <= end_url_pos && cursor_offset >= start_text_pos) {
							found_match = true;
							link_url = buffer_text.slice (start_url_pos + 1, end_url_pos - 1);
						}
					}
				} while (matches.next ());
			}
		} catch (RegexError e) {}

		return found_match;
	}

	public bool remove_formatting (Widgets.Markdown.View markdown_view, string affix) {
		var buffer = markdown_view.buffer;
		Regex affix_regex;

		switch (affix) {
			case "**":
				affix_regex = is_bold_0;
				break;
			case "__":
				affix_regex = is_bold_1;
				break;
			case "*":
				affix_regex = is_italic_0;
				break;
			case "_":
				affix_regex = is_italic_0;
				break;
			case "~":
				affix_regex = is_strikethrough_0;
				break;
			case "~~":
				affix_regex = is_strikethrough_1;
				break;
			case "==":
				affix_regex = is_highlight;
				break;
			case "`":
				affix_regex = is_code_span;
				break;
			default:
				return false;
		}

		Gtk.TextIter buffer_start, buffer_end;
		buffer.get_bounds (out buffer_start, out buffer_end);
		var buffer_text = buffer.get_text (buffer_start, buffer_end, true);

		Gtk.TextIter selection_start, selection_end, cursor;
		buffer.get_selection_bounds (out selection_start, out selection_end);
		buffer.get_iter_at_mark (out cursor, buffer.get_insert ());
		var cursor_offset = cursor.get_offset ();

		bool found_match = false;
		MatchInfo matches;

		try {
			if (affix_regex.match_full (buffer_text, buffer_text.length, 0, 0, out matches) ) {
				do {
					int start_before_pos, end_before_pos;
					int start_code_pos, end_code_pos;
					int start_after_pos, end_after_pos;
					bool have_code_start = matches.fetch_pos (1, out start_before_pos, out end_before_pos);
					bool have_code = matches.fetch_pos (2, out start_code_pos, out end_code_pos);
					bool have_code_close = matches.fetch_pos (3, out start_after_pos, out end_after_pos);

					if (have_code_start && have_code && have_code_close) {
						start_before_pos = buffer_text.char_count ((ssize_t) start_before_pos);
						end_before_pos = buffer_text.char_count ((ssize_t) end_before_pos);
						start_code_pos = buffer_text.char_count ((ssize_t) start_code_pos);
						end_code_pos = buffer_text.char_count ((ssize_t) end_code_pos);
						start_after_pos = buffer_text.char_count ((ssize_t) start_after_pos);
						end_after_pos = buffer_text.char_count ((ssize_t) end_after_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_before_iter, end_before_iter;
						Gtk.TextIter start_code_iter, end_code_iter;
						Gtk.TextIter start_after_iter, end_after_iter;
						buffer.get_iter_at_offset (out start_before_iter, start_before_pos);
						buffer.get_iter_at_offset (out end_before_iter, end_before_pos);
						buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
						buffer.get_iter_at_offset (out end_code_iter, end_code_pos);
						buffer.get_iter_at_offset (out start_after_iter, start_after_pos);
						buffer.get_iter_at_offset (out end_after_iter, end_after_pos);

						if (cursor_offset <= end_after_pos && cursor_offset >= start_before_pos) {
							// First remove the tag from the text buffer.
							buffer.remove_tag (buffer.tag_table.lookup ("markdown-bold"), start_before_iter, end_after_iter);

							// Now delete the trailing markdown.
							buffer.delete (ref start_after_iter, ref end_after_iter);

							// We have to recalculate the iterators since we change the buffer, but since
							// we deleted the traling markdown first, the actual positions for the starting
							// markdown are still the same.
							buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
							buffer.get_iter_at_offset (out start_before_iter, start_before_pos);

							// Now delete the starting markdown.
							buffer.delete (ref start_before_iter, ref start_code_iter);

							// Since we clicked on the toolbar, giving it focus, grab the focus from it background_rgba
							// to the editor window.
							markdown_view.grab_focus ();

							found_match = true;
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		return found_match;
	}

	private GtkSource.GutterRendererText renderer;

	private Regex is_link;
	private Regex is_bare_link;
	private Regex is_email_link;
	private Regex is_escape;
	private Regex is_blockquote;

	private Regex is_horizontal_rule;

	private Regex is_list_row;
	private Regex is_table_row;

	private Regex is_bold_0;
	private Regex is_bold_1;
	private Regex is_italic_0;
	private Regex is_italic_1;
	private Regex is_strikethrough_0;
	private Regex is_strikethrough_1;
	private Regex is_highlight;

	private Regex is_code_span;
	private Regex is_code_span_double;
	private Regex is_code_block;

	private Regex filter_escapes;

	construct {
		try {
			var f = RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS;
			is_link = new Regex ("\\[([^\\[]*?)\\](\\([^\\)\\n]*?\\))", f, 0);
			is_bare_link = new Regex ("((?:http|ftp|https):\\/\\/)?([\\w_-]+(?:(?:\\.[\\w_-]+)+))([\\w.,@?^=%&:\\/~+#-]*[\\w@?^=%&\\/~+#-])", f, 0);
			is_email_link = new Regex ("[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*", f, 0);
			is_escape = new Regex ("\\\\[\\\\`*_{}\\[\\]()#+\\-.!]", f, 0);

			/* Examples:
			 * > Quoted text.
			 * > Quoted text with `code span`.
			 * >> Blockquote **nested**.
			 */
			is_blockquote = new Regex ("^( {0,3}>( {0,4}>)*).*", f | RegexCompileFlags.MULTILINE, 0);

			/* Examples:
			 * - - -
			 * * * *
			 * ***
			 * ************
			 */
			is_horizontal_rule = new Regex ("^[ ]{0,3}((-[ ]{0,2}){3,}|(_[ ]{0,2}){3,}|(\\*[ ]{0,2}){3,})[ \\t]*$", f | RegexCompileFlags.MULTILINE, 0);

			/* Examples:
			 * - list item
			 * + list item
			 * * list item
			 * 0. list item
			 */
			is_list_row = new Regex ("^[\\t ]*([-*+]|[.0-9])+[\\t ]+", f | RegexCompileFlags.MULTILINE, 0);

			/* Examples:
			 * |column 1|column 2|
			 * |--------|--------|
			 * |value 1 |value 2 |
			 */
			is_table_row = new Regex ("^[\\t ]*[|].*$", f | RegexCompileFlags.MULTILINE, 0);

			/* Examples:
			 * Lorem *ipsum dolor* sit amet.
			 * Here's an *emphasized text containing an asterisk (\*)*.
			 */
			is_italic_0 = new Regex ("((?<!\\*)\\*)([^\\* \\t].*?(?<!\\\\|\\*| |\\t))(\\*(?!\\*))", f, 0);

			/* Examples:
			 * Lorem _ipsum dolor_ sit amet.
			 * Here's an _emphasized text containing an underscore (\_)_.
			 */
			is_italic_1 = new Regex ("((?<!_)_)([^_ \\t].*?(?<!\\\\|_| |\\t))(_(?!_))", f, 0);

			/* Examples:
			 * Lorem **ipsum dolor** sit amet.
			 * Here's a **strongly emphasized text containing an asterisk (\*).**
			 */
			is_bold_0 = new Regex ("(\\*\\*)([^\\* \\t].*?(?<!\\\\|\\*| |\\t))(\\*\\*)", f, 0);

			/* Examples:
			 * Lorem __ipsum dolor__ sit amet.
			 * Here's a __strongly emphasized text containing an underscore (\_)__.
			 */
			is_bold_1 = new Regex ("(__)([^_ \\t].*?(?<!\\\\|_| |\\t))(__)", f, 0);

			is_strikethrough_0 = new Regex ("((?<!\\~)\\~)([^\\~ \\t].*?(?<!\\\\|\\~| |\\t))(\\~(?!\\~))", f, 0);
			is_strikethrough_1 = new Regex ("(~~)([^~ \\t].*?(?<!\\\\|~| |\\t))(~~)", f, 0);
			is_highlight = new Regex ("(\\=\\=)([^\\= \\t].*?(?<!\\\\|\\=| |\\t))(\\=\\=)", f, 0);

			is_code_span = new Regex ("(?<!`)(`)([^`]+(?:`{2,}[^`]+)*)(`)(?!`)", RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS | RegexCompileFlags.MULTILINE, 0);
			is_code_span_double = new Regex ("(``)(.*)(``)", RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS | RegexCompileFlags.MULTILINE | RegexCompileFlags.UNGREEDY, 0);
			is_code_block = new Regex ("(?<![^\\n])(```[^`\\n]*)\\n([^`]*)(```)(?=\\n)", f, 0);

			filter_escapes = new Regex ("(\\\\\\\\|\\\\`|\\\\\\*|\\\\_|\\\\\\{|\\\\\\}|\\\\\\[|\\\\\\]|\\\\\\(|\\\\\\)|\\\\#|\\\\\\+|\\\\-|\\\\\\.|\\\\!)", f, 0);
		} catch (RegexError e) {
			error (e.message);
		}

		notify["text-mode"].connect (() => {
			if (text_mode) {
				Gtk.TextIter buffer_start, buffer_end;
				buffer.get_bounds (out buffer_start, out buffer_end);
				remove_tags_format (buffer_start, buffer_end);
				remove_tags_cursor (buffer_start, buffer_end);
			} else {
				update_color_scheme ();
				if (buffer is GtkSource.Buffer) {
					var buf = buffer as GtkSource.Buffer;
					if (buf != null ) {
						buf.language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
					}
				}
				restyle_text_all ();
			}
		});

		if (buffer is GtkSource.Buffer) {
			var buf = buffer as GtkSource.Buffer;
			if (buf != null ) {
				buf.language = GtkSource.LanguageManager.get_default ().get_language ("markdownpp");
			}
		}

		notify["dark"].connect ((s, p) => update_color_scheme ());
		notify["theme-color"].connect ((s, p) => update_color_scheme ());
		notify["font-monospace"].connect ((s, p) => update_font ());

		var font_desc = Pango.FontDescription.from_string (font_monospace);
		var font_size = font_desc.get_size ();
		if (!font_desc.get_size_is_absolute ()) {
			font_size = font_size / Pango.SCALE;
		}
		if (font_size < 3) {
			font_desc.set_size (10 * Pango.SCALE);
			font_monospace = font_desc.to_string ();
		}

		update_color_scheme ();
		update_font ();

		{
			var gutter = get_gutter (Gtk.TextWindowType.LEFT);
			renderer = new GtkSource.GutterRendererText ();
			renderer.xalign = 0.5f;
			renderer.yalign = 0.5f;
			renderer.query_data.connect ((lines, line) => {
				var title_level = get_title_level (line);
				if (title_level != 0 && show_gutter && !text_mode) {
					renderer.text = @"H$title_level";
				} else {
					renderer.text = null;
				}
			});
			renderer.query_activatable.connect ((iter, area) => true);
			renderer.activate.connect ((iter, area, button, state, n_presses) => {
				if (button != 1) return;
				var line = iter.get_line ();
				var title_level = get_title_level (line);
                // TODO: HeadingPopover
				//  if (title_level == 0) return;
				//  var popover = new HeadingPopover(this, line);
				//  popover.autohide = true;
				//  popover.has_arrow = true;
				//  popover.position = Gtk.PositionType.LEFT;
				//  popover.set_parent (this);
				//  popover.pointing_to = area;
				//  popover.popup ();
			});
			gutter.insert (renderer, 0);
		}
	}


	private Gtk.TextTag[] text_tags_title;

	private Gtk.TextTag text_tag_url;
	private Gtk.TextTag text_tag_escaped;
	private Gtk.TextTag text_tag_blockquote;
	private Gtk.TextTag text_tag_blockquote_marker;

	private Gtk.TextTag text_tag_horizontal_rule;

	private Gtk.TextTag text_tag_list;
	private Gtk.TextTag text_tag_table;

	private Gtk.TextTag text_tag_bold;
	private Gtk.TextTag text_tag_italic;
	private Gtk.TextTag text_tag_strikethrough;
	private Gtk.TextTag text_tag_highlight;

	private Gtk.TextTag text_tag_code_span;
	private Gtk.TextTag text_tag_code_block;
	private Gtk.TextTag text_tag_around;

	private Gtk.TextTag text_tag_hidden;
	private Gtk.TextTag text_tag_invisible;

	private Gtk.TextTag get_or_create_tag (string name) {
		return buffer.tag_table.lookup (name) ?? buffer.create_tag (name); }

	private void update_color_scheme () {

		float interpolate (float x) {
			return 1 - (float) Math.sqrt (1 - x);
		}

		void update_title_styling () {
			var tags = new Gtk.TextTag[6];
			var last_i = tags.length - 1;
			for (var i = 0; i < tags.length; i++) {
				var tag = get_or_create_tag (@"markdown-h$i");
				var bold_f = (last_i - int.min (i, last_i - 1) - 1) / (float) last_i;
				tag.weight = 600 + (int) (bold_f * 300);
				var scale_f = (last_i - i) / (float) last_i;
				tag.scale = 1.0f + interpolate (scale_f) * 1.4f;
				if (i == last_i)
					tag.foreground_rgba = h6_color;
				tags[i] = tag;
			}
			text_tags_title = tags;
		}

		if (buffer is GtkSource.Buffer) {
			var buffer = buffer as GtkSource.Buffer;

			buffer.style_scheme = GtkSource.StyleSchemeManager.get_default ().get_scheme (dark ? "folio-dark" : "folio");

			if (text_mode)
				return;

			var block_color = block_color;
			var tinted_foreground = tinted_foreground;

			update_title_styling ();

			text_tag_url = get_or_create_tag ("markdown-link");
			text_tag_url.foreground_rgba = url_color;
			text_tag_url.underline = Pango.Underline.SINGLE;

			text_tag_escaped = get_or_create_tag ("markdown-escaped-char");
			text_tag_escaped.foreground_rgba = tinted_foreground;

			text_tag_blockquote = get_or_create_tag ("markdown-blockquote");
			text_tag_blockquote.paragraph_background_rgba = block_color;
			text_tag_blockquote.line_height = 2;

			text_tag_blockquote_marker = get_or_create_tag ("markdown-blockquote-marker");
			text_tag_blockquote_marker.background_rgba = tinted_foreground;
			text_tag_blockquote_marker.foreground_rgba = tinted_foreground;
			text_tag_blockquote_marker.size_points = 8;

			text_tag_horizontal_rule = get_or_create_tag ("markdown-horizontal-rule");
			text_tag_horizontal_rule.justification = Gtk.Justification.CENTER;
			text_tag_horizontal_rule.foreground_rgba = marking_color;

			text_tag_table = get_or_create_tag ("markdown-table");
			text_tag_table.justification = Gtk.Justification.CENTER;
			text_tag_table.font = font_monospace;

			text_tag_list = get_or_create_tag ("markdown-list");
			text_tag_list.indent = 16;

			text_tag_bold = get_or_create_tag ("markdown-bold");
			text_tag_bold.weight = 700;

			text_tag_italic = get_or_create_tag ("markdown-italic");
			text_tag_italic.style = Pango.Style.ITALIC;

			text_tag_strikethrough = get_or_create_tag ("markdown-strikethrough");
			text_tag_strikethrough.strikethrough = true;

			text_tag_highlight = get_or_create_tag ("markdown-highlight");
			text_tag_highlight.background_rgba = highlight_color;

			text_tag_around = get_or_create_tag ("markdown-code-block-around");
			var around_block_color = block_color;
			around_block_color.alpha = 0.8f;
			text_tag_around.foreground_rgba = around_block_color;

			text_tag_code_span = get_or_create_tag ("markdown-code-span");
			text_tag_code_span.background_rgba = block_color;

			text_tag_code_block = get_or_create_tag ("markdown-code-block");
			text_tag_code_block.indent = 16;

			text_tag_hidden = get_or_create_tag ("hidden-character");
			text_tag_hidden.invisible = true;

			text_tag_invisible = get_or_create_tag ("invisible-character");
			text_tag_invisible.foreground = "rgba(0,0,0,0.001)";
		}
	}

	private void update_font () {
		var font_desc = Pango.FontDescription.from_string (font_monospace);
		var font_size = font_desc.get_size ();
		if (!font_desc.get_size_is_absolute ()) {
			font_size = font_size / Pango.SCALE;
		}
		if (font_size < 3) {
			font_desc.set_size (10 * Pango.SCALE);
			font_monospace = font_desc.to_string ();
		}

		text_tag_around = get_or_create_tag ("markdown-code-block-around");
		text_tag_around.font = font_monospace;

		text_tag_code_span = get_or_create_tag ("markdown-code-span");
		text_tag_code_span.font = font_monospace;

		text_tag_code_block = get_or_create_tag ("markdown-code-block");
		text_tag_code_block.font = font_monospace;

		text_tag_table = get_or_create_tag ("markdown-table");
		text_tag_table.font = font_monospace;
	}

	private void remove_tags_format (Gtk.TextIter start, Gtk.TextIter end) {
		buffer.remove_tag (text_tag_url, start, end);
		buffer.remove_tag (text_tag_escaped, start, end);
		buffer.remove_tag (text_tag_code_span, start, end);
		buffer.remove_tag (text_tag_code_block, start, end);
		buffer.remove_tag (text_tag_around, start, end);
		buffer.remove_tag (text_tag_bold, start, end);
		buffer.remove_tag (text_tag_italic, start, end);
		buffer.remove_tag (text_tag_strikethrough, start, end);
		buffer.remove_tag (text_tag_highlight, start, end);
		buffer.remove_tag (text_tag_blockquote, start, end);
		buffer.remove_tag (text_tag_blockquote_marker, start, end);
		buffer.remove_tag (text_tag_list, start, end);
		buffer.remove_tag (text_tag_table, start, end);
		foreach (var t in text_tags_title)
			buffer.remove_tag (t, start, end);
	}

	private void remove_tags_cursor (Gtk.TextIter start, Gtk.TextIter end) {
		buffer.remove_tag (text_tag_hidden, start, end);
		buffer.remove_tag (text_tag_invisible, start, end);
	}

	private string create_filtered_buffer (string buffer_text) {
		MatchInfo matches;

		if (buffer_text == null || buffer_text.length <= 5) { return buffer_text; }

		try {
			// Create a filtered buffer that replaces escaped backticks with a placeholder so that
			// we can use to ensure code spans/blocks don't misinterpret them.
			string filtered_buffer_text = (string)filter_escapes.replace (buffer_text, buffer_text.length, 0, "\\\\'", 0);

			// Filter out any single backticks inside of double backticks as well.
			if (is_code_span_double.match_full (filtered_buffer_text, filtered_buffer_text.length, 0, 0, out matches)) {
				do {
					int start_code_pos, end_code_pos;

					if (matches.fetch_pos (2, out start_code_pos, out end_code_pos)) {
						end_code_pos = end_code_pos - 2;

						for (var i = start_code_pos; i <= end_code_pos; i++) {
							if (filtered_buffer_text[i] == '`') {
								filtered_buffer_text = filtered_buffer_text.substring (0, i) + " " + filtered_buffer_text.substring (i + 1);
							}
						}
					}
				} while (matches.next ());
			}
			return filtered_buffer_text;
		}
		catch (Error e) {}

		return buffer_text;
	}

	private void restyle_text_format () {
		if (text_mode) return;
		renderer.queue_draw ();
		Gtk.TextIter buffer_start, buffer_end;
		buffer.get_bounds (out buffer_start, out buffer_end);
		remove_tags_format (buffer_start, buffer_end);

		// Check to see if the last character in the buffer is a LF, if not, add it, otherwise
		// some of the tagging operations will crash.
		var buffer_end_minus_one = buffer_end.copy ();
		buffer_end_minus_one.backward_char ();
		string end_text = buffer.get_text (buffer_end_minus_one, buffer_end, true);
		if (end_text != "\n") {
			var cursor = buffer.get_insert ();
			Gtk.TextIter cursor_location;
			buffer.get_iter_at_mark (out cursor_location, cursor);
			var cursor_mark = buffer.create_mark (null, cursor_location, true);
			buffer.insert (ref buffer_end, "\n", 1);
			buffer.get_iter_at_mark (out cursor_location, cursor_mark);
			buffer.place_cursor (cursor_location);
			buffer.get_bounds (out buffer_start, out buffer_end);
		}

		string buffer_text = buffer.get_text (buffer_start, buffer_end, true);

		{
			var lines = buffer.get_line_count ();
			for (var line = 0; line < lines; line++) {
				var title_level = get_title_level (line);
				if (title_level != 0) {
					Gtk.TextIter start, end;
					buffer.get_iter_at_line (out start, line);
					end = start.copy ();
					end.forward_to_line_end ();
					buffer.apply_tag (text_tags_title[title_level - 1], start, end);
				}
			}
		}

		MatchInfo matches;

		// Create a filtered buffer that replaces some characters we don't want to match on.
		string filtered_buffer_text = create_filtered_buffer (buffer_text);

		try {
			format_horizontal_rule (buffer_text, out matches);
		} catch (Error e) {}

		try {
			format_blockquote (buffer_text, out matches);
		} catch (Error e) {}

		try {
			// Check for links
			if (is_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					int start_url_pos, end_url_pos;
					bool have_text = matches.fetch_pos (1, out start_text_pos, out end_text_pos);
					bool have_url = matches.fetch_pos (2, out start_url_pos, out end_url_pos);

					if (have_text && have_url) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);
						start_url_pos = buffer_text.char_count ((ssize_t) start_url_pos);
						end_url_pos = buffer_text.char_count ((ssize_t) end_url_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter, start_url_iter, end_url_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);
						buffer.get_iter_at_offset (out start_url_iter, start_url_pos);
						buffer.get_iter_at_offset (out end_url_iter, end_url_pos);

						// If the styling has already been applied, don't both re-applying it.
						if (!start_text_iter.has_tag (text_tag_url) && !end_text_iter.has_tag (text_tag_url) && !start_url_iter.has_tag (text_tag_url) && !end_url_iter.has_tag (text_tag_url)) {
							// Apply our styling
							buffer.apply_tag (text_tag_url, start_text_iter, end_text_iter);
							buffer.apply_tag (text_tag_url, start_url_iter, end_url_iter);
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		try {
			// Check for bare links
			if (is_bare_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

					if (have_text) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

						// If the styling has already been applied, don't both re-applying it.
						if (!start_text_iter.has_tag (text_tag_url) && !end_text_iter.has_tag (text_tag_url)) {
							// Apply our styling
							buffer.apply_tag (text_tag_url, start_text_iter, end_text_iter);
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		try {
			// Check lists
			if (is_list_row.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

					if (have_text) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

						// If the styling has already been applied, don't both re-applying it.
						if (!start_text_iter.has_tag (text_tag_list) && !end_text_iter.has_tag (text_tag_list)) {
							// Apply our styling
							buffer.apply_tag (text_tag_list, start_text_iter, end_text_iter);
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		try {
			// Check tables
			if (is_table_row.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

					if (have_text) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

						// If the styling has already been applied, don't both re-applying it.
						if (!start_text_iter.has_tag (text_tag_table) && !end_text_iter.has_tag (text_tag_table)) {
							// Apply our styling
							buffer.apply_tag (text_tag_table, start_text_iter, end_text_iter);
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		try {
			// Check for email links
			if (is_email_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

					if (have_text) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

						// If the styling has already been applied, don't both re-applying it.
						if (!start_text_iter.has_tag (text_tag_url) && !end_text_iter.has_tag (text_tag_url)) {
							// Apply our styling
							buffer.apply_tag (text_tag_url, start_text_iter, end_text_iter);
						}
					}
				} while (matches.next ());
			}
		} catch (Error e) {}

		// Check for formatting
		try {
			do_formatting_pass_format (is_bold_0, text_tag_bold, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_bold_1, text_tag_bold, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_italic_0, text_tag_italic, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_italic_1, text_tag_italic, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_strikethrough_0, text_tag_strikethrough, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_strikethrough_1, text_tag_strikethrough, buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_highlight, text_tag_highlight, buffer_text, out matches);
		} catch (Error e) {}

		try {
			format_escape_format (buffer_text, out matches);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_code_span_double, text_tag_code_span, filtered_buffer_text, out matches, true);
		} catch (Error e) {}

		try {
			do_formatting_pass_format (is_code_span, text_tag_code_span, filtered_buffer_text, out matches, true);
		} catch (Error e) {}

		try {
			format_code_block_format (filtered_buffer_text, out matches);
		} catch (Error e) {}
	}

	private void restyle_text_cursor () {
		if (text_mode) return;
		renderer.queue_draw ();
		Gtk.TextIter buffer_start, buffer_end, cursor_location;
		buffer.get_bounds (out buffer_start, out buffer_end);
		remove_tags_cursor (buffer_start, buffer_end);
		var cursor = buffer.get_insert ();
		buffer.get_iter_at_mark (out cursor_location, cursor);
		string buffer_text = buffer.get_text (buffer_start, buffer_end, true);

		{
			var lines = buffer.get_line_count ();
			for (var line = 0; line < lines; line++) {
				var title_level = get_title_level (line);
				if (title_level != 0) {
					Gtk.TextIter start, end;
					buffer.get_iter_at_line (out start, line);
					end = start.copy ();
					end.forward_chars ((int) title_level + 1);
					buffer.apply_tag (text_tag_hidden, start, end);
				}
			}
		}

		try {
			MatchInfo matches;

			// Create a filtered buffer that replaces some characters we don't want to match on.
			string filtered_buffer_text = create_filtered_buffer (buffer_text);

			// Check for links
			if (is_link.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
				do {
					int start_text_pos, end_text_pos;
					int start_url_pos, end_url_pos;
					bool have_text = matches.fetch_pos (1, out start_text_pos, out end_text_pos);
					bool have_url = matches.fetch_pos (2, out start_url_pos, out end_url_pos);

					if (have_text && have_url) {
						start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
						end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);
						start_url_pos = buffer_text.char_count ((ssize_t) start_url_pos);
						end_url_pos = buffer_text.char_count ((ssize_t) end_url_pos);

						// Convert the character offsets to TextIter's
						Gtk.TextIter start_text_iter, end_text_iter, start_url_iter, end_url_iter;
						buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
						buffer.get_iter_at_offset (out end_text_iter, end_text_pos);
						buffer.get_iter_at_offset (out start_url_iter, start_url_pos);
						buffer.get_iter_at_offset (out end_url_iter, end_url_pos);

						// Skip if our cursor is inside the URL text
						if (cursor_location.in_range (start_text_iter, end_url_iter)) {
							continue;
						}

						var start_bracket_iter = start_text_iter.copy ();
						start_bracket_iter.backward_char ();
						var end_bracket_iter = end_text_iter.copy ();
						end_bracket_iter.forward_char ();

						// Apply our styling
						buffer.apply_tag (text_tag_hidden, start_url_iter, end_url_iter);
						buffer.apply_tag (text_tag_hidden, start_bracket_iter, start_text_iter);
						buffer.apply_tag (text_tag_hidden, end_text_iter, end_bracket_iter);
					}
				} while (matches.next ());
			}

			// Check for formatting
			do_formatting_pass_cursor (is_bold_0, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_bold_1, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_italic_0, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_italic_1, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_strikethrough_0, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_strikethrough_1, buffer_text, cursor_location, out matches);
			do_formatting_pass_cursor (is_highlight, buffer_text, cursor_location, out matches);

			format_escape_cursor (buffer_text, cursor_location, out matches);

			do_formatting_pass_cursor (is_code_span_double, filtered_buffer_text, cursor_location, out matches, true);
			do_formatting_pass_cursor (is_code_span, filtered_buffer_text, cursor_location, out matches, true);
			format_code_block_cursor (filtered_buffer_text, cursor_location, out matches);
		} catch (RegexError e) {
			critical (e.message);
		}
	}

	private void restyle_text_all () {
		restyle_text_format ();
		restyle_text_cursor ();
	}

	void format_horizontal_rule (
		string buffer_text,
		out MatchInfo matches
	) throws RegexError {
		// Check for code blocks
		if (is_horizontal_rule.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_pos, end_pos;
				bool have = matches.fetch_pos (0, out start_pos, out end_pos);

				if (have) {
					start_pos = buffer_text.char_count ((ssize_t) start_pos);
					end_pos = buffer_text.char_count ((ssize_t) end_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_iter, end_iter;
					buffer.get_iter_at_offset (out start_iter, start_pos);
					buffer.get_iter_at_offset (out end_iter, end_pos);

					// Apply styling
					buffer.apply_tag (text_tag_horizontal_rule, start_iter, end_iter);
				}
			} while (matches.next ());
		}
	}

	void format_blockquote (
		string buffer_text,
		out MatchInfo matches
	) throws RegexError {
		// Check for code blocks
		if (is_blockquote.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_marker_pos, end_marker_pos;
				int start_full_pos, end_full_pos;
				bool have_marker = matches.fetch_pos (1, out start_marker_pos, out end_marker_pos);
				bool have_full = matches.fetch_pos (0, out start_full_pos, out end_full_pos);

				if (have_marker && have_full) {
					start_marker_pos = buffer_text.char_count ((ssize_t) start_marker_pos);
					end_marker_pos = buffer_text.char_count ((ssize_t) end_marker_pos);
					start_full_pos = buffer_text.char_count ((ssize_t) start_full_pos);
					end_full_pos = buffer_text.char_count ((ssize_t) end_full_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_marker_iter, end_marker_iter;
					Gtk.TextIter start_full_iter, end_full_iter;
					buffer.get_iter_at_offset (out start_marker_iter, start_marker_pos);
					buffer.get_iter_at_offset (out end_marker_iter, end_marker_pos);
					buffer.get_iter_at_offset (out start_full_iter, start_full_pos);
					buffer.get_iter_at_offset (out end_full_iter, end_full_pos);

					// Apply styling
					buffer.apply_tag (text_tag_blockquote, start_full_iter, end_full_iter);
					buffer.apply_tag (text_tag_blockquote_marker, start_marker_iter, end_marker_iter);
				}
			} while (matches.next ());
		}
	}

	void format_escape_format (
		string buffer_text,
		out MatchInfo matches
	) throws RegexError {
		// Check for escapes
		if (is_escape.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_text_pos, end_text_pos;
				bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

				if (have_text) {
					start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
					end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_text_iter, end_text_iter;
					buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
					buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

					// Apply styling
					buffer.apply_tag (text_tag_escaped, start_text_iter, end_text_iter);
				}
			} while (matches.next ());
		}
	}

	void format_escape_cursor (
		string buffer_text,
		Gtk.TextIter cursor_location,
		out MatchInfo matches
	) throws RegexError {
		// Check for escapes
		if (is_escape.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_text_pos, end_text_pos;
				bool have_text = matches.fetch_pos (0, out start_text_pos, out end_text_pos);

				if (have_text) {
					start_text_pos = buffer_text.char_count ((ssize_t) start_text_pos);
					end_text_pos = buffer_text.char_count ((ssize_t) end_text_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_text_iter, end_text_iter;
					buffer.get_iter_at_offset (out start_text_iter, start_text_pos);
					buffer.get_iter_at_offset (out end_text_iter, end_text_pos);

					var start_escaped_char_iter = start_text_iter.copy ();
					start_escaped_char_iter.forward_char ();

					// Skip if our cursor is inside the URL text
					if (cursor_location.in_range (start_text_iter, end_text_iter)) {
						continue;
					}

					// Apply styling
					buffer.apply_tag (text_tag_hidden, start_text_iter, start_escaped_char_iter);
				}
			} while (matches.next ());
		}
	}

	void format_code_block_format (
		string buffer_text,
		out MatchInfo matches
	) throws RegexError {
		// Check for code blocks
		if (is_code_block.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_before_pos, end_before_pos;
				int start_code_pos, end_code_pos;
				int start_after_pos, end_after_pos;
				bool have_code_start = matches.fetch_pos (1, out start_before_pos, out end_before_pos);
				bool have_code = matches.fetch_pos (2, out start_code_pos, out end_code_pos);
				bool have_code_close = matches.fetch_pos (3, out start_after_pos, out end_after_pos);

				if (have_code_start && have_code && have_code_close) {
					start_before_pos = buffer_text.char_count ((ssize_t) start_before_pos);
					end_before_pos = buffer_text.char_count ((ssize_t) end_before_pos);
					start_code_pos = buffer_text.char_count ((ssize_t) start_code_pos);
					end_code_pos = buffer_text.char_count ((ssize_t) end_code_pos);
					start_after_pos = buffer_text.char_count ((ssize_t) start_after_pos);
					end_after_pos = buffer_text.char_count ((ssize_t) end_after_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_before_iter, end_before_iter;
					Gtk.TextIter start_code_iter, end_code_iter;
					Gtk.TextIter start_after_iter, end_after_iter;
					buffer.get_iter_at_offset (out start_before_iter, start_before_pos);
					buffer.get_iter_at_offset (out end_before_iter, end_before_pos);
					buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
					buffer.get_iter_at_offset (out end_code_iter, end_code_pos);
					buffer.get_iter_at_offset (out start_after_iter, start_after_pos);
					buffer.get_iter_at_offset (out end_after_iter, end_after_pos);

					// Apply styling
					remove_tags_format (start_before_iter, end_after_iter);

					buffer.apply_tag (text_tag_code_block, start_code_iter, end_code_iter);
					buffer.apply_tag (text_tag_around, start_before_iter, end_before_iter);
					buffer.apply_tag (text_tag_around, start_after_iter, end_after_iter);
				}
			} while (matches.next ());
		}
	}

	void format_code_block_cursor (
		string buffer_text,
		Gtk.TextIter cursor_location,
		out MatchInfo matches
	) throws RegexError {
		// Check for code blocks
		if (is_code_block.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_before_pos, end_before_pos;
				int start_code_pos, end_code_pos;
				int start_after_pos, end_after_pos;
				bool have_code_start = matches.fetch_pos (1, out start_before_pos, out end_before_pos);
				bool have_code = matches.fetch_pos (2, out start_code_pos, out end_code_pos);
				bool have_code_close = matches.fetch_pos (3, out start_after_pos, out end_after_pos);

				if (have_code_start && have_code && have_code_close) {
					start_before_pos = buffer_text.char_count ((ssize_t) start_before_pos);
					end_before_pos = buffer_text.char_count ((ssize_t) end_before_pos);
					start_code_pos = buffer_text.char_count ((ssize_t) start_code_pos);
					end_code_pos = buffer_text.char_count ((ssize_t) end_code_pos);
					start_after_pos = buffer_text.char_count ((ssize_t) start_after_pos);
					end_after_pos = buffer_text.char_count ((ssize_t) end_after_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_before_iter, end_before_iter;
					Gtk.TextIter start_code_iter, end_code_iter;
					Gtk.TextIter start_after_iter, end_after_iter;
					buffer.get_iter_at_offset (out start_before_iter, start_before_pos);
					buffer.get_iter_at_offset (out end_before_iter, end_before_pos);
					buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
					buffer.get_iter_at_offset (out end_code_iter, end_code_pos);
					buffer.get_iter_at_offset (out start_after_iter, start_after_pos);
					buffer.get_iter_at_offset (out end_after_iter, end_after_pos);

					// Apply styling
					remove_tags_cursor (start_before_iter, end_after_iter);

					// Skip if our cursor is inside the code
					if (cursor_location.in_range (start_before_iter, end_after_iter)) {
						continue;
					}

					buffer.apply_tag (text_tag_invisible, start_before_iter, end_before_iter);
					buffer.apply_tag (text_tag_invisible, start_after_iter, end_after_iter);
				}
			} while (matches.next ());
		}
	}

	void do_formatting_pass_format (
		Regex regex,
		Gtk.TextTag text_tag,
		string buffer_text,
		out MatchInfo matches,
		bool remove_other_tags = false
	) throws RegexError {
		if (regex.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_before_pos, end_before_pos;
				int start_code_pos, end_code_pos;
				int start_after_pos, end_after_pos;
				bool have_code_start = matches.fetch_pos (1, out start_before_pos, out end_before_pos);
				bool have_code = matches.fetch_pos (2, out start_code_pos, out end_code_pos);
				bool have_code_close = matches.fetch_pos (3, out start_after_pos, out end_after_pos);

				if (have_code_start && have_code && have_code_close) {
					start_before_pos = buffer_text.char_count ((ssize_t) start_before_pos);
					end_before_pos = buffer_text.char_count ((ssize_t) end_before_pos);
					start_code_pos = buffer_text.char_count ((ssize_t) start_code_pos);
					end_code_pos = buffer_text.char_count ((ssize_t) end_code_pos);
					start_after_pos = buffer_text.char_count ((ssize_t) start_after_pos);
					end_after_pos = buffer_text.char_count ((ssize_t) end_after_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_before_iter, end_before_iter;
					Gtk.TextIter start_code_iter, end_code_iter;
					Gtk.TextIter start_after_iter, end_after_iter;
					buffer.get_iter_at_offset (out start_before_iter, start_before_pos);
					buffer.get_iter_at_offset (out end_before_iter, end_before_pos);
					buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
					buffer.get_iter_at_offset (out end_code_iter, end_code_pos);
					buffer.get_iter_at_offset (out start_after_iter, start_after_pos);
					buffer.get_iter_at_offset (out end_after_iter, end_after_pos);

					// Check to see if the tag has already been applied, if so, skip it.
					if (start_code_iter.has_tag (text_tag) && end_code_iter.has_tag (text_tag) && start_before_iter.has_tag (text_tag_around) && start_after_iter.has_tag (text_tag_around)) {
						continue;
					}

					// Apply styling
					if (remove_other_tags)
						remove_tags_format (start_before_iter, end_after_iter);

					buffer.apply_tag (text_tag, start_code_iter, end_code_iter);
					buffer.apply_tag (text_tag_around, start_before_iter, end_before_iter);
					buffer.apply_tag (text_tag_around, start_after_iter, end_after_iter);
				}
			} while (matches.next ());
		}
	}

	void do_formatting_pass_cursor (
		Regex regex,
		string buffer_text,
		Gtk.TextIter cursor_location,
		out MatchInfo matches,
		bool remove_other_tags = false
	) throws RegexError {
		if (regex.match_full (buffer_text, buffer_text.length, 0, 0, out matches)) {
			do {
				int start_before_pos, end_before_pos;
				int start_code_pos, end_code_pos;
				int start_after_pos, end_after_pos;
				bool have_code_start = matches.fetch_pos (1, out start_before_pos, out end_before_pos);
				bool have_code = matches.fetch_pos (2, out start_code_pos, out end_code_pos);
				bool have_code_close = matches.fetch_pos (3, out start_after_pos, out end_after_pos);

				if (have_code_start && have_code && have_code_close) {
					start_before_pos = buffer_text.char_count ((ssize_t) start_before_pos);
					end_before_pos = buffer_text.char_count ((ssize_t) end_before_pos);
					start_code_pos = buffer_text.char_count ((ssize_t) start_code_pos);
					end_code_pos = buffer_text.char_count ((ssize_t) end_code_pos);
					start_after_pos = buffer_text.char_count ((ssize_t) start_after_pos);
					end_after_pos = buffer_text.char_count ((ssize_t) end_after_pos);

					// Convert the character offsets to TextIter's
					Gtk.TextIter start_before_iter, end_before_iter;
					Gtk.TextIter start_code_iter, end_code_iter;
					Gtk.TextIter start_after_iter, end_after_iter;
					buffer.get_iter_at_offset (out start_before_iter, start_before_pos);
					buffer.get_iter_at_offset (out end_before_iter, end_before_pos);
					buffer.get_iter_at_offset (out start_code_iter, start_code_pos);
					buffer.get_iter_at_offset (out end_code_iter, end_code_pos);
					buffer.get_iter_at_offset (out start_after_iter, start_after_pos);
					buffer.get_iter_at_offset (out end_after_iter, end_after_pos);

					if (remove_other_tags)
						remove_tags_cursor (start_before_iter, end_after_iter);

					// Skip if our cursor is inside the code
					if (cursor_location.in_range (start_before_iter, end_after_iter)) {
						continue;
					}

					// Apply styling
					buffer.apply_tag (text_tag_hidden, start_before_iter, end_before_iter);
					buffer.apply_tag (text_tag_hidden, start_after_iter, end_after_iter);
				}
			} while (matches.next ());
		}
	}
}
