/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class MarkdownProcessor : Object {
    private static MarkdownProcessor ? _instance;
    public static MarkdownProcessor get_default () {
        if (_instance == null) {
            _instance = new MarkdownProcessor ();
        }

        return _instance;
    }

    private struct MarkupMatch {
        public int start_pos;
        public int end_pos;
        public string original;
        public string replacement;
        public int priority;

        public MarkupMatch (int start, int end, string orig, string repl, int prio = 0) {
            start_pos = start;
            end_pos = end;
            original = orig;
            replacement = repl;
            priority = prio;
        }
    }

    private enum MarkupPriority {
        URL_MARKDOWN = 1,
        EMAIL = 2,
        URL = 3,
        CODE = 4,
        ITALIC_BOLD_UNDERLINE = 5,
        BOLD_UNDERLINE = 6,
        ITALIC_UNDERLINE = 7,
        ITALIC_BOLD = 8,
        BOLD = 9,
        ITALIC = 10,
        UNDERLINE = 11
    }

    private Regex ? mailto_regex = null;
    private Regex ? url_regex = null;
    private Regex ? url_markdown_regex = null;
    private Regex ? code_regex = null;
    private Regex ? italic_bold_underline_regex = null;
    private Regex ? bold_underline_regex = null;
    private Regex ? italic_underline_regex = null;
    private Regex ? italic_bold_regex = null;
    private Regex ? bold_regex = null;
    private Regex ? italic_regex = null;
    private Regex ? underline_regex = null;

    public MarkdownProcessor () {
        compile_regexes ();
    }

    private void compile_regexes () {
        try {
            mailto_regex = new Regex (
                "(?P<mailto>[a-zA-Z0-9][a-zA-Z0-9._%-]*[a-zA-Z0-9]@[a-zA-Z0-9][a-zA-Z0-9.-]*\\.[a-zA-Z]{2,})",
                RegexCompileFlags.OPTIMIZE
            );

            url_regex = new Regex (
                "(?P<url>https?://[a-zA-Z0-9][a-zA-Z0-9.-]*\\.[a-zA-Z]{2,}(?:/[^\\s]*)?)",
                RegexCompileFlags.OPTIMIZE
            );

            url_markdown_regex = new Regex (
                "\\[([^\\]]+)\\]\\(([^\\)\\s]+)\\)",
                RegexCompileFlags.OPTIMIZE
            );

            code_regex = new Regex (
                "`([^`\\n]+?)`",
                RegexCompileFlags.OPTIMIZE
            );

            italic_bold_underline_regex = new Regex (
                "\\*\\*\\*_([^*_\\n]+?)_\\*\\*\\*",
                RegexCompileFlags.OPTIMIZE
            );

            bold_underline_regex = new Regex (
                "\\*\\*_([^*_\\n]+?)_\\*\\*",
                RegexCompileFlags.OPTIMIZE
            );

            italic_underline_regex = new Regex (
                "\\*_([^*_\\n]+?)_\\*",
                RegexCompileFlags.OPTIMIZE
            );

            italic_bold_regex = new Regex (
                "(?<!\\*)\\*\\*\\*([^*\\n]+?)\\*\\*\\*(?!\\*)",
                RegexCompileFlags.OPTIMIZE
            );

            bold_regex = new Regex (
                "(?<!\\*)\\*\\*([^*\\n]+?)\\*\\*(?!\\*)",
                RegexCompileFlags.OPTIMIZE
            );

            italic_regex = new Regex (
                "(?<!\\*)\\*([^*\\n]+?)\\*(?!\\*)",
                RegexCompileFlags.OPTIMIZE
            );

            underline_regex = new Regex (
                "_([^_\\n]+?)_",
                RegexCompileFlags.OPTIMIZE
            );
        } catch (RegexError e) {
            warning ("Error compiling regex: %s", e.message);
        }
    }

    public string markup_string (string text) {
        if (text.strip () == "") {
            return text;
        }

        var escaped_text = GLib.Markup.escape_text (text, text.length);
        var matches = new Gee.ArrayList<MarkupMatch ?> ();

        collect_url_markdown_matches (escaped_text, matches);
        collect_email_matches (escaped_text, matches);
        collect_url_matches (escaped_text, matches);
        collect_code_matches (escaped_text, matches);
        collect_formatting_matches (escaped_text, matches);

        var filtered_matches = filter_and_sort_matches (matches);

        return apply_matches (escaped_text, filtered_matches);
    }

    private void collect_url_markdown_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        if (url_markdown_regex == null)return;

        MatchInfo match_info;
        if (url_markdown_regex.match (text, 0, out match_info)) {
            do {
                int start_pos, end_pos;
                if (match_info.fetch_pos (0, out start_pos, out end_pos)) {
                    var full_match = match_info.fetch (0);
                    var link_text = match_info.fetch (1);
                    var link_url = match_info.fetch (2);
                    var replacement = @"<a href=\"$link_url\">$link_text</a>";

                    matches.add (MarkupMatch (start_pos, end_pos, full_match, replacement, MarkupPriority.URL_MARKDOWN));
                }
            } while (match_info.next ());
        }
    }

    private void collect_email_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        if (mailto_regex == null)return;

        MatchInfo match_info;
        if (mailto_regex.match (text, 0, out match_info)) {
            do {
                int start_pos, end_pos;
                if (match_info.fetch_pos (0, out start_pos, out end_pos)) {
                    var email = match_info.fetch_named ("mailto");
                    var replacement = @"<a href=\"mailto:$email\">$email</a>";

                    matches.add (MarkupMatch (start_pos, end_pos, email, replacement, MarkupPriority.EMAIL));
                }
            } while (match_info.next ());
        }
    }

    private void collect_url_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        if (url_regex == null)return;

        MatchInfo match_info;
        if (url_regex.match (text, 0, out match_info)) {
            do {
                int start_pos, end_pos;
                if (match_info.fetch_pos (0, out start_pos, out end_pos)) {
                    var url = match_info.fetch_named ("url");

                    if (!is_position_covered_by_priority (matches, start_pos, end_pos, MarkupPriority.URL_MARKDOWN)) {
                        var replacement = @"<a href=\"$url\">$url</a>";
                        matches.add (MarkupMatch (start_pos, end_pos, url, replacement, MarkupPriority.URL));
                    }
                }
            } while (match_info.next ());
        }
    }

    private void collect_code_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        if (code_regex == null)return;

        MatchInfo match_info;
        if (code_regex.match (text, 0, out match_info)) {
            do {
                int start_pos, end_pos;
                if (match_info.fetch_pos (0, out start_pos, out end_pos)) {
                    var full_match = match_info.fetch (0);
                    var code_content = match_info.fetch (1);

                    var replacement = @"<tt>$code_content</tt>";

                    matches.add (MarkupMatch (start_pos, end_pos, full_match, replacement, MarkupPriority.CODE));
                }
            } while (match_info.next ());
        }
    }

    private void collect_formatting_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        var format_patterns = new Gee.ArrayList<FormatPattern ?> ();
        format_patterns.add (FormatPattern (italic_bold_underline_regex, "<i><b><u>%s</u></b></i>", MarkupPriority.ITALIC_BOLD_UNDERLINE));
        format_patterns.add (FormatPattern (bold_underline_regex, "<b><u>%s</u></b>", MarkupPriority.BOLD_UNDERLINE));
        format_patterns.add (FormatPattern (italic_underline_regex, "<i><u>%s</u></i>", MarkupPriority.ITALIC_UNDERLINE));
        format_patterns.add (FormatPattern (italic_bold_regex, "<i><b>%s</b></i>", MarkupPriority.ITALIC_BOLD));
        format_patterns.add (FormatPattern (bold_regex, "<b>%s</b>", MarkupPriority.BOLD));
        format_patterns.add (FormatPattern (italic_regex, "<i>%s</i>", MarkupPriority.ITALIC));
        format_patterns.add (FormatPattern (underline_regex, "<u>%s</u>", MarkupPriority.UNDERLINE));

        foreach (var pattern in format_patterns) {
            collect_pattern_matches (text, matches, pattern);
        }
    }

    private struct FormatPattern {
        public Regex ? regex;
        public string format_template;
        public int priority;

        public FormatPattern (Regex ? r, string template, int prio) {
            regex = r;
            format_template = template;
            priority = prio;
        }
    }

    private void collect_pattern_matches (string text, Gee.ArrayList<MarkupMatch ?> matches, FormatPattern pattern) {
        if (pattern.regex == null)return;

        MatchInfo match_info;
        if (pattern.regex.match (text, 0, out match_info)) {
            do {
                int start_pos, end_pos;
                if (match_info.fetch_pos (0, out start_pos, out end_pos)) {
                    var full_match = match_info.fetch (0);
                    var inner_text = match_info.fetch (1);
                    var replacement = pattern.format_template.printf (inner_text);

                    matches.add (MarkupMatch (start_pos, end_pos, full_match, replacement, pattern.priority));
                }
            } while (match_info.next ());
        }
    }

    private bool is_position_covered_by_priority (Gee.ArrayList<MarkupMatch ?> matches,
                                                  int start_pos, int end_pos, int min_priority) {
        foreach (var match in matches) {
            if (match.priority <= min_priority &&
                ranges_overlap (match.start_pos, match.end_pos, start_pos, end_pos)) {
                return true;
            }
        }
        return false;
    }

    private bool ranges_overlap (int start1, int end1, int start2, int end2) {
        return !(end1 <= start2 || end2 <= start1);
    }

    private Gee.ArrayList<MarkupMatch ?> filter_and_sort_matches (Gee.ArrayList<MarkupMatch ?> matches) {
        var filtered = new Gee.ArrayList<MarkupMatch ?> ();

        matches.sort ((a, b) => {
            if (a.priority != b.priority) {
                return a.priority - b.priority;
            }
            return a.start_pos - b.start_pos;
        });

        foreach (var current_match in matches) {
            bool should_add = true;

            foreach (var existing_match in filtered) {
                if (ranges_overlap (existing_match.start_pos, existing_match.end_pos,
                                    current_match.start_pos, current_match.end_pos)) {
                    should_add = false;
                    break;
                }
            }

            if (should_add) {
                filtered.add (current_match);
            }
        }

        filtered.sort ((a, b) => b.start_pos - a.start_pos);

        return filtered;
    }

    private string apply_matches (string text, Gee.ArrayList<MarkupMatch ?> matches) {
        var result = new StringBuilder (text);

        foreach (var match in matches) {
            result.erase (match.start_pos, match.end_pos - match.start_pos);
            result.insert (match.start_pos, match.replacement);
        }

        return result.str;
    }
}
