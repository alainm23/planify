public class Widgets.WebView : WebKit.WebView {
    public Objects.Task task { get; construct; }

    public WebView (Objects.Task _task) {
        Object (
            task: _task,
            user_content_manager: new WebKit.UserContentManager ()
        );
    
        expand = true;

        var settings_web = get_settings ();
        settings_web.enable_plugins = false;
        settings_web.enable_page_cache = true;
        settings_web.enable_developer_extras = false;
        web_context.set_cache_model (WebKit.CacheModel.DOCUMENT_VIEWER);

        update_html_view ();
        connect_signals ();

        Application.signals.change_dark_theme.connect ((change) => {
            update_note (task.note);
        });
    }

    private void connect_signals () {
        create.connect ((navigation_action)=> {
            launch_browser (navigation_action.get_request().get_uri ());
            return null;
        });

        decide_policy.connect ((decision, type) => {
            switch (type) {
                case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                    if (decision is WebKit.ResponsePolicyDecision) {
                        launch_browser ((decision as WebKit.ResponsePolicyDecision).request.get_uri ());
                    }
                break;
                case WebKit.PolicyDecisionType.RESPONSE:
                    if (decision is WebKit.ResponsePolicyDecision) {
                        var policy = (WebKit.ResponsePolicyDecision) decision;
                        launch_browser (policy.request.get_uri ());
                        return false;
                    }
                break;
            }

            return true;
        });

        load_changed.connect ((event) => {
            if (event == WebKit.LoadEvent.FINISHED) {
                var rectangle = get_window_properties ().get_geometry ();
                set_size_request (rectangle.width, rectangle.height);
            }
        });
    }

    private void launch_browser (string url) {
        if (!url.contains ("/embed/")) {
            try {
                AppInfo.launch_default_for_uri (url, null);
            } catch (Error e) {
                warning ("No app to handle urls: %s", e.message);
            }
            stop_loading ();
        }
    }
    
    public void update_note (string note) {
        task.note = note;
        update_html_view ();
    }

    private string get_stylesheet () {
        if (!Application.settings.get_boolean ("prefer-dark-style")) {
            return Application.utils.WEBVIEW_STYLESHEET.printf (
                "#fafafa",
                "#fafafa",
                "#3d4248",
                "#fafafa"
            );
        } else {
            return Application.utils.WEBVIEW_STYLESHEET.printf (
                "#232629",
                "#232629",
                "#ffffff",
                "#fafafa"
            );
        }
    }

    private string[] process_frontmatter (string raw_mk, out string processed_mk) {
        string[] map = {};

        processed_mk = null;

        // Parse frontmatter
        if (raw_mk.length > 4 && raw_mk[0:4] == "---\n") {
            int i = 0;
            bool valid_frontmatter = true;
            int last_newline = 3;
            int next_newline;
            string line = "";
            while (true) {
                next_newline = raw_mk.index_of_char ('\n', last_newline + 1);
                if (next_newline == -1) { // End of file
                    valid_frontmatter = false;
                    break;
                }
                line = raw_mk[last_newline+1:next_newline];
                last_newline = next_newline;

                if (line == "---") { // End of frontmatter
                    break;
                }

                var sep_index = line.index_of_char (':');
                if (sep_index != -1) {
                    map += line[0:sep_index-1];
                    map += line[sep_index+1:line.length];
                } else { // No colon, invalid frontmatter
                    valid_frontmatter = false;
                    break;
                }

                i++;
            }

            if (valid_frontmatter) { // Strip frontmatter if it's a valid one
                processed_mk = raw_mk[last_newline:raw_mk.length];
            }
        }

        if (processed_mk == null) {
            processed_mk = raw_mk;
        }

        return map;
    }

    private string process () {
        string processed_mk;
        process_frontmatter (task.note, out processed_mk);
        var mkd = new Markdown.Document (
            processed_mk.data, 0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000 + 0x40000000
        );

        mkd.compile (0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000 + 0x40000000);

        string result;
        mkd.get_document (out result);

        return result;
    }

    public void update_html_view () {
        string html = "<!doctype html><meta charset=utf-8><head>";
        html += "<style>" + get_stylesheet () + "</style>";
        html += "</head><body><div class=\"markdown-body\">";
        html += process ();
        html += "</div></body></html>";
        
        load_html (html, "file:///");
    }
}