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

public class Objects.Filters.Priority : Objects.BaseObject {
    public int priority { get; construct; }

    public const int HIGH = 4;
    public const int MEDIUM = 3;
    public const int LOW = 2;
    public const int NONE = 1;

    private static Gee.HashMap<int, Priority> _instances;

    private static Priority ? _high_instance;
    private static Priority ? _medium_instance;
    private static Priority ? _low_instance;
    private static Priority ? _none_instance;

    public static Priority high () {
        if (_high_instance == null) {
            _high_instance = new Priority (HIGH);
        }
        
        return _high_instance;
    }

    public static Priority medium () {
        if (_medium_instance == null) {
            _medium_instance = new Priority (MEDIUM);
        }
        return _medium_instance;
    }

    public static Priority low () {
        if (_low_instance == null) {
            _low_instance = new Priority (LOW);
        }
        return _low_instance;
    }

    public static Priority none () {
        if (_none_instance == null) {
            _none_instance = new Priority (NONE);
        }
        return _none_instance;
    }

    public static Priority get_default (int priority) {
        if (_instances == null) {
            _instances = new Gee.HashMap<int, Priority> ();
        }

        if (priority < 1 || priority > 4) {
            warning ("Prioridad inválida: %d. Debe estar entre 1 y 4", priority);
            priority = NONE;
        }

        if (!_instances.has_key (priority)) {
            _instances[priority] = new Priority (priority);
        }

        return _instances[priority];
    }

    public Priority (int priority) {
        Object (
            priority : priority
        );
    }

    int ? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Store.instance ().get_items_by_priority (priority, false).size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public string icon {
        get {
            return "flag-outline-thick-symbolic";
        }
    }

    public string color {
        get {
            if (priority == HIGH) {
                return "#ff7066";
            } else if (priority == MEDIUM) {
                return "#ff9914";
            } else if (priority == LOW) {
                return "#5297ff";
            } else {
                return Services.Settings.get_default ().settings.get_boolean ("dark-mode") ? "#fafafa" : "#333333";
            }
        }
    }

    public string title {
        get {
            if (priority == HIGH) {
                return _("Priority 1: high");
            } else if (priority == MEDIUM) {
                return _("Priority 2: medium");
            } else if (priority == LOW) {
                return _("Priority 3: low");
            } else {
                return _("Priority 4: none");
            }
        }
    }
    
    construct {
        keywords = get_keywords () + ";" + _("filters");
        view_id = "priority-%d".printf (priority);


        Services.Store.instance ().item_added.connect ((item, updated) => {
            if (!item.project.freeze_update) {
                count_update ();
            }
        });

        Services.Store.instance ().item_deleted.connect ((item) => {
            if (!item.project.freeze_update) {
                count_update ();
            }
        });

        Services.Store.instance ().item_archived.connect ((item) => {
            if (!item.project.freeze_update) {
                count_update ();
            }
        });

        Services.Store.instance ().item_unarchived.connect ((item) => {
            if (!item.project.freeze_update) {
                count_update ();
            }
        });

        Services.Store.instance ().item_updated.connect ((item, update_id) => {
            if (!item.project.freeze_update) {
                count_update ();
            }
        });

        Services.Store.instance ().project_updated.connect ((project) => {
            if (!project.freeze_update) {
                count_update ();
            }
        });
    }

    private string get_keywords () {
        if (priority == HIGH) {
            return "%s;%s".printf ("p1", _("high"));
        } else if (priority == MEDIUM) {
            return "%s;%s".printf ("p2", _("medium"));
        } else if (priority == LOW) {
            return "%s;%s".printf ("p3", _("low"));
        } else {
            return "%s;%s".printf ("p4", _("none"));
        }
    }

    public override void count_update () {
        _count = Services.Store.instance ().get_items_by_priority (priority, false).size;

        count_updated ();
    }
}
