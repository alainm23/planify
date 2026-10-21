/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * Copyright © 2026 byquanton
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
 * Authored by: byquanton
 */

public class Services.CalDAV.CalDAVCapabilities : Object {
    public bool sync_collection { get; private set; default = true; }
    public bool calendar_multiget { get; private set; default = true; }

    public CalDAVCapabilities () {}

    public CalDAVCapabilities.from_prop (WebDAVXmlElement? supported_report_set) {
        if (supported_report_set == null) {
            return;
        }

        sync_collection = false;
        calendar_multiget = false;

        foreach (var supported_report in supported_report_set.get_children ("supported-report")) {
            var report = supported_report.get_child ("report");
            if (report == null) {
                continue;
            }

            if (report.get_child ("sync-collection") != null) {
                sync_collection = true;
            }

            if (report.get_child ("calendar-multiget") != null) {
                calendar_multiget = true;
            }
        }
    }
}
