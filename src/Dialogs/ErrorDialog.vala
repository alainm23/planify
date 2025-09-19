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

public class Dialogs.ErrorDialog : Adw.Dialog {
    public int error_code { get; construct; }
    public string error_message { get; construct; }

    public ErrorDialog (int error_code, string error_message) {
        Object (
            error_code: error_code,
            error_message: error_message,
            content_width: 375,
            content_height: 450
        );
    }

    ~ErrorDialog () {
        debug ("Destroying - Dialogs.ErrorDialog\n");
    }

    construct {
        var error_view = new Widgets.ErrorView () {
            error_code = error_code,
            error_message = error_message,
        };

        child = error_view;
    }
}
