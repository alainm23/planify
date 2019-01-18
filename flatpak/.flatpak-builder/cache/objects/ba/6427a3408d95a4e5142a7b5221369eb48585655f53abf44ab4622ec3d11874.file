/*
 * Copyright (C) 2013 Philip Withnall
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Authors:
 * 	Philip Withnall <philip@tecnocode.co.uk>
 */

using Folks;
using GLib;
using TelepathyGLib;

/**
 * Dummy interface for the Zeitgeist code for libfolks-telepathy.la. This must
 * implement exactly the same interface as tp-zeitgeist.vala, but without
 * linking to Zeitgeist.
 *
 * See the note in Makefile.am, and
 * [[https://bugzilla.gnome.org/show_bug.cgi?id=701099]].
 */
public class FolksTpZeitgeist.Controller : Object
{
  [CCode (has_target = false)]
  public delegate void IncreasePersonaCounter (Persona p,
      DateTime converted_datetime);

  public Controller (PersonaStore store, TelepathyGLib.Account account,
      IncreasePersonaCounter im_interaction_cb,
      IncreasePersonaCounter last_call_interaction_cb)
    {
      /* Dummy. */
    }

  public async void populate_counters ()
    {
      /* Dummy. */
    }
}
