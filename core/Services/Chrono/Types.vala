/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Chrono.Configuration : GLib.Object {
    public Gee.ArrayList<Chrono.AbstractParser> parsers { get; set; default = new Gee.ArrayList<Chrono.AbstractParser> (); }
}

public interface Chrono.AbstractParser : GLib.Object {
    public abstract GLib.Regex inner_pattern ();
    public abstract Chrono.ParsingResult inner_extract (GLib.MatchInfo match);
}

public class Chrono.ParsingResult : GLib.Object {
    public int index { get; set; default = 0; }
    public string text { get; set; default = ""; }
    public GLib.DateTime? datetime { get; set; default = null; }
}
