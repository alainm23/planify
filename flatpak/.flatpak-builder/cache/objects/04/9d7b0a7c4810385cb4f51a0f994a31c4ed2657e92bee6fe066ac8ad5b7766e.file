/*
 * Copyright (C) 2011, 2012 Philip Withnall
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;
using GLib;

/**
 * Interface for {@link Persona} subclasses from backends which support storage
 * of, anti-linking data.
 *
 * Anti-links are stored as a set of {@link Persona.uid}s with each
 * {@link Persona} (A), specifying that A must not be linked into an
 * {@link Individual} with any of the personas in its anti-links set.
 *
 * @since 0.7.3
 */
public interface Folks.AntiLinkable : Folks.Persona
{
  /**
   * UIDs of anti-linked {@link Persona}s.
   *
   * The {@link Persona}s identified by their UIDs in this set are guaranteed to
   * not be linked to this {@link Persona}, even if their linkable properties
   * match.
   *
   * No UIDs may be ``null``. Well-formed but non-existent UIDs (i.e. UIDs which
   * can be successfully parsed, but which don't currently correspond to a
   * {@link Persona} instance) are permitted, as personas may appear and
   * disappear over time.
   *
   * The special UID ``*`` is used as a wildcard to mark the persona as globally
   * anti-linked. See {@link AntiLinkable.has_global_anti_link}.
   *
   * It is expected, but not guaranteed, that anti-links made between personas
   * will be reciprocal. That is, if persona A lists persona B's UID in its
   * {@link AntiLinkable.anti_links} set, persona B will typically also list
   * persona A in its anti-links set.
   *
   * @since 0.7.3
   */
  public abstract Set<string> anti_links { get; set; }

  /**
   * Change the {@link Persona}'s set of anti-links.
   *
   * It's preferred to call this rather than setting
   * {@link AntiLinkable.anti_links} directly, as this method gives error
   * notification and will only return once the anti-links have been written
   * to the relevant backing store (or the operation's failed).
   *
   * It should be noted that {@link IndividualAggregator.link_personas} and
   * {@link IndividualAggregator.unlink_individual} will modify the anti-links
   * sets of the personas they touch, in order to remove and add anti-links,
   * respectively. It is expected that these {@link IndividualAggregator}
   * methods will be used to modify anti-links indirectly, rather than calling
   * {@link AntiLinkable.change_anti_links} directly.
   *
   * @param anti_links the new set of anti-links from this persona
   * @throws PropertyError if setting the anti-links failed
   * @since 0.7.3
   */
  public virtual async void change_anti_links (Set<string> anti_links)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Anti-links are not writeable on this contact."));
    }

  /**
   * Check for an anti-link with another persona.
   *
   * This will return ``true`` if ``other_persona``'s UID is listed in this
   * persona's anti-links set. Note that this check is not symmetric.
   *
   * @param other_persona the persona to check is anti-linked
   * @return ``true`` if an anti-link exists, ``false`` otherwise
   * @since 0.7.3
   */
  public bool has_anti_link_with_persona (Persona other_persona)
    {
      return (this.has_global_anti_link ()) ||
             (other_persona.uid in this.anti_links);
    }

  /**
   * Add anti-links to other personas.
   *
   * The UIDs of all personas in ``other_personas`` will be added to this
   * persona's anti-links set and the changes propagated to backends.
   *
   * Any attempt to anti-link a persona with itself is not an error, but is
   * ignored.
   *
   * This method is safe to call multiple times concurrently (e.g. begin one
   * asynchronous call, then begin another before the first has finished).
   *
   * @param other_personas the personas to anti-link to this one
   * @throws PropertyError if setting the anti-links failed
   * @since 0.7.3
   */
  public async void add_anti_links (Set<Persona> other_personas)
      throws PropertyError
    {
      var new_anti_links = SmallSet<string>.copy (this.anti_links);

      foreach (var p in other_personas)
        {
          /* Don't anti-link ourselves. */
          if (p == this)
            {
              continue;
            }

          new_anti_links.add (p.uid);
        }

      yield this.change_anti_links (new_anti_links);
    }

  /**
   * Remove anti-links to other personas.
   *
   * The UIDs of all personas in ``other_personas`` will be removed from this
   * persona's anti-links set and the changes propagated to backends.
   *
   * If the global anti-link is set, this will not have any effect until the 
   * global anti-link is removed.
   *
   * This method is safe to call multiple times concurrently (e.g. begin one
   * asynchronous call, then begin another before the first has finished).
   *
   * @param other_personas the personas to remove anti-links from this one
   * @throws PropertyError if setting the anti-links failed
   * @since 0.7.3
   */
  public async void remove_anti_links (Set<Persona> other_personas)
      throws PropertyError
    {
      var new_anti_links = SmallSet<string>.copy (this.anti_links);

      foreach (var p in other_personas)
        {
          new_anti_links.remove (p.uid);
        }

      yield this.change_anti_links (new_anti_links);
    }

  /**
   * Prevent persona from being linked with any other personas
   *
   * This function will add a wildcard ``*`` to the set of anti-links, which will
   * prevent the persona from being linked with any other personas.
   *
   * To make the persona linkable again you need to remove the global anti-link
   *
   * This method is safe to call multiple times concurrently (e.g. begin one
   * asynchronous call, then begin another before the first has finished).
   *
   * @throws PropertyError if setting the anti-links failed
   * @since 0.9.7
   */
  public async void add_global_anti_link()
      throws PropertyError
    {
       if (!this.has_global_anti_link())
         {
           var new_anti_links = SmallSet<string>.copy (this.anti_links);
           new_anti_links.add ("*");
           yield this.change_anti_links (new_anti_links);
         }
    }

  /**
   * Allow persona to be linked with other personas
   *
   * This function removes the wildcard ``*`` from the set of anti-links, allowing
   * the persona to be linked again.
   *
   * This method is safe to call multiple times concurrently (e.g. begin one
   * asynchronous call, then begin another before the first has finished).
   *
   * @throws PropertyError if setting the anti-links failed
   * @since 0.9.7
   */
  public async void remove_global_anti_link()
      throws PropertyError
    {
       if (this.has_global_anti_link())
         {
           var new_anti_links = SmallSet<string>.copy (this.anti_links);
           new_anti_links.remove ("*");
           yield this.change_anti_links (new_anti_links);
         }
    }

  /**
   * Check if the persona has a global anti link.
   *
   * If the persona has global anti link this means that the persona can not be
   * linked with any other persona.
   *
   * @since 0.9.7
   */
  public bool has_global_anti_link()
    {
       return (this.anti_links.contains ("*"));
    }
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */
