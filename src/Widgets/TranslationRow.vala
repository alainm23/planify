/*
* Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.TranslationRow : Adw.PreferencesRow {
    private Gtk.Image _icon;
    private Gtk.Label _title_label;
    private Gtk.Label _subtitle_label;
    private Gtk.LevelBar _level_bar;

    public string? icon_name {
        owned get {
            return _icon.icon_name;
        }

        set {
            _icon.icon_name = value;
        }
    }

    public string title {
        owned get {
             return _title_label.label;
        }

        set {
            _title_label.label = value;
        }
    }

    public string subtitle {
        owned get {
            return _subtitle_label.label;
        }

        set {
            _subtitle_label.label = value;
        }
    }

    public double progress {
        get {
            return _level_bar.value;
        }

        set {
            _level_bar.value = value;
        }
    }
    
    public void hide_level_bar () {
        _level_bar.visible = false;
    }
    
    public void show_level_bar () {
        _level_bar.visible = true;
    }

    private string _language_name = "";
    private double _target_percent = 0.0;
    public bool is_ready_to_animate { get; private set; default = false; }
    private bool _animation_played = false;
    
    public void prepare_animation (string language_name, double target_percent) {
        _language_name = language_name;
        _target_percent = target_percent;
        is_ready_to_animate = true;
    }
    
    public void trigger_animation () {
        if (_animation_played || !is_ready_to_animate) {
            return;
        }
        
        _animation_played = true;
        
        var animation_target = new Adw.CallbackAnimationTarget ((val) => {
            _subtitle_label.label = _("<b>%s</b> is %.0f%% complete. You can help finish it!").printf (_language_name, Math.round (val));
            _level_bar.value = val / 100.0;
        });

        var animation = new Adw.TimedAnimation (
            this, 0, _target_percent, 1000,
            animation_target
        ) {
            easing = Adw.Easing.EASE_IN_OUT_QUAD
        };

        animation.play ();
    }

    public async void load_translation_data () {
        try {
            var metrics = yield Services.Api.get_default ().get_translation_metrics ();
            var languages = Util.get_default ().get_current_languages ();

            string user_lang = "";
            string full_lang = "";
            foreach (string lang in languages) {
                if (lang == "C" || lang == "POSIX") {
                    continue;
                }
                
                full_lang = lang;
                if (lang.contains ("_")) {
                    user_lang = lang.split ("_")[0];
                } else {
                    user_lang = lang;
                }
                
                if (user_lang == "en") {
                    title = _("Translations");
                    subtitle = _("Help make Planify available worldwide");
                    hide_level_bar ();
                    return;
                }
                
                if (metrics.has_key (user_lang) || metrics.has_key (full_lang)) {
                    var metric = metrics.has_key (full_lang) ? metrics.get (full_lang) : metrics.get (user_lang);
                    if (metric.translated_percent > 0.0) {
                        title = _("Help improve translations");
                        prepare_animation (metric.language, metric.translated_percent);
                        return;
                    }
                }
                
                string language_name = get_language_name (full_lang);
                title = _("Start a new translation");
                subtitle = _("<b>%s</b> is not available yet. Be the first to translate it!").printf (language_name);
                hide_level_bar ();
                return;
            }
            
            title = _("Translations");
            subtitle = _("Help make Planify available worldwide");
            hide_level_bar ();
        } catch (Error e) {
            title = _("Translations");
            subtitle = _("Help make Planify available worldwide");
            hide_level_bar ();
        }
    }

    private string get_language_name (string lang_code) {
        var locale_names = new Gee.HashMap<string, string> ();
        locale_names.set ("af", "Afrikaans");
        locale_names.set ("ak", "Akan");
        locale_names.set ("ar", "Arabic");
        locale_names.set ("az", "Azerbaijani");
        locale_names.set ("be", "Belarusian");
        locale_names.set ("bg", "Bulgarian");
        locale_names.set ("bn", "Bengali");
        locale_names.set ("bs", "Bosnian");
        locale_names.set ("ca", "Catalan");
        locale_names.set ("ckb", "Central Kurdish");
        locale_names.set ("cs", "Czech");
        locale_names.set ("cv", "Chuvash");
        locale_names.set ("da", "Danish");
        locale_names.set ("de", "German");
        locale_names.set ("el", "Greek");
        locale_names.set ("eo", "Esperanto");
        locale_names.set ("es", "Spanish");
        locale_names.set ("et", "Estonian");
        locale_names.set ("eu", "Basque");
        locale_names.set ("fa", "Persian");
        locale_names.set ("fi", "Finnish");
        locale_names.set ("fr", "French");
        locale_names.set ("ga", "Irish");
        locale_names.set ("gl", "Galician");
        locale_names.set ("he", "Hebrew");
        locale_names.set ("hi", "Hindi");
        locale_names.set ("hr", "Croatian");
        locale_names.set ("hu", "Hungarian");
        locale_names.set ("hy", "Armenian");
        locale_names.set ("id", "Indonesian");
        locale_names.set ("is", "Icelandic");
        locale_names.set ("it", "Italian");
        locale_names.set ("ja", "Japanese");
        locale_names.set ("jv", "Javanese");
        locale_names.set ("ka", "Georgian");
        locale_names.set ("kk", "Kazakh");
        locale_names.set ("kn", "Kannada");
        locale_names.set ("ko", "Korean");
        locale_names.set ("ku", "Kurdish");
        locale_names.set ("lb", "Luxembourgish");
        locale_names.set ("lg", "Luganda");
        locale_names.set ("lt", "Lithuanian");
        locale_names.set ("lv", "Latvian");
        locale_names.set ("mg", "Malagasy");
        locale_names.set ("mk", "Macedonian");
        locale_names.set ("mn", "Mongolian");
        locale_names.set ("mo", "Moldovan");
        locale_names.set ("mr", "Marathi");
        locale_names.set ("ms", "Malay");
        locale_names.set ("my", "Burmese");
        locale_names.set ("nb", "Norwegian Bokmål");
        locale_names.set ("nl", "Dutch");
        locale_names.set ("nn", "Norwegian Nynorsk");
        locale_names.set ("no", "Norwegian");
        locale_names.set ("pa", "Punjabi");
        locale_names.set ("pl", "Polish");
        locale_names.set ("pt", "Portuguese");
        locale_names.set ("ro", "Romanian");
        locale_names.set ("ru", "Russian");
        locale_names.set ("sa", "Sanskrit");
        locale_names.set ("si", "Sinhala");
        locale_names.set ("sk", "Slovak");
        locale_names.set ("sl", "Slovenian");
        locale_names.set ("sma", "Southern Sami");
        locale_names.set ("sq", "Albanian");
        locale_names.set ("sr", "Serbian");
        locale_names.set ("sv", "Swedish");
        locale_names.set ("szl", "Silesian");
        locale_names.set ("ta", "Tamil");
        locale_names.set ("te", "Telugu");
        locale_names.set ("th", "Thai");
        locale_names.set ("tl", "Tagalog");
        locale_names.set ("tr", "Turkish");
        locale_names.set ("ug", "Uyghur");
        locale_names.set ("uk", "Ukrainian");
        locale_names.set ("ur", "Urdu");
        locale_names.set ("uz", "Uzbek");
        locale_names.set ("vi", "Vietnamese");
        locale_names.set ("zh", "Chinese");
        locale_names.set ("zu", "Zulu");
        locale_names.set ("en_AU", "English (Australia)");
        locale_names.set ("en_CA", "English (Canada)");
        locale_names.set ("en_GB", "English (UK)");
        locale_names.set ("fr_CA", "French (Canada)");
        locale_names.set ("pt_BR", "Portuguese (Brazil)");
        locale_names.set ("zh_CN", "Chinese (Simplified)");
        locale_names.set ("zh_TW", "Chinese (Traditional)");
        locale_names.set ("tr_TR", "Turkish (Turkey)");
        locale_names.set ("nb_NO", "Norwegian Bokmål (Norway)");

        if (locale_names.has_key (lang_code)) {
            return locale_names.get (lang_code);
        }
        
        string base_lang = lang_code.contains ("_") ? lang_code.split ("_")[0] : lang_code;
        return locale_names.has_key (base_lang) ? locale_names.get (base_lang) : base_lang.up ();
    }

    construct {
        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 8,
            margin_bottom = 8
        };

        _icon = new Gtk.Image () {
            pixel_size = 16,
            valign = Gtk.Align.CENTER
        };

        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true,
            valign = Gtk.Align.CENTER
        };

        _title_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
        };

        _subtitle_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            use_markup = true
        };
        _subtitle_label.add_css_class ("dimmed");
        _subtitle_label.add_css_class ("caption");

        _level_bar = new Gtk.LevelBar () {
            hexpand = true,
            margin_top = 6,
            min_value = 0.0,
            max_value = 1.0
        };

        text_box.append (_title_label);
        text_box.append (_subtitle_label);
        text_box.append (_level_bar);

        main_box.append (_icon);
        main_box.append (text_box);

        child = main_box;
    }
}