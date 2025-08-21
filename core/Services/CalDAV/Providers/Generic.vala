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

public class Services.CalDAV.Providers.Generic : Services.CalDAV.Providers.Base {
    public Generic () {

    }

    public string get_id_from_url (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("href").length <= 0) {
            return "";
        }

        GXml.DomElement href = element.get_elements_by_tag_name ("href").get_element (0);

        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    public string get_prop_value (GXml.DomElement element, string key) {
        if (element.get_elements_by_tag_name ("propstat").length <= 0) {
            return "";
        }

        GXml.DomElement propstat = element.get_elements_by_tag_name ("propstat").get_element (0);

        if (propstat.get_elements_by_tag_name ("prop").length <= 0) {
            return "";
        }

        GXml.DomElement prop = propstat.get_elements_by_tag_name ("prop").get_element (0);

        if (prop.get_elements_by_tag_name (key).length <= 0) {
            return "";
        }

        return prop.get_elements_by_tag_name (key).get_element (0).text_content;
    }

    public override bool is_vtodo_calendar (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("propstat").length <= 0) {
            return false;
        }

        GXml.DomElement propstat = element.get_elements_by_tag_name ("propstat").get_element (0);

        if (propstat.get_elements_by_tag_name ("prop").length <= 0) {
            return false;
        }

        GXml.DomElement prop = propstat.get_elements_by_tag_name ("prop").get_element (0);

        if (prop.get_elements_by_tag_name ("resourcetype").length <= 0) {
            return false;
        }

        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("resourcetype").get_element (0);

        bool is_calendar = resourcetype.get_elements_by_tag_name ("C:calendar").length > 0;
        bool is_vtodo = false;

        if (is_calendar) {
            if (prop.get_elements_by_tag_name ("C:supported-calendar-component-set").length <= 0) {
                return false;
            }

            GXml.DomElement supported_calendar = prop.get_elements_by_tag_name ("C:supported-calendar-component-set").get_element (0);
            GXml.DomHTMLCollection calendar_comps = supported_calendar.get_elements_by_tag_name ("C:comp");
            foreach (GXml.DomElement calendar_comp in calendar_comps) {
                if (calendar_comp.get_attribute ("name") == "VTODO") {
                    is_vtodo = true;
                }
            }
        }

        return is_vtodo;
    }
}
