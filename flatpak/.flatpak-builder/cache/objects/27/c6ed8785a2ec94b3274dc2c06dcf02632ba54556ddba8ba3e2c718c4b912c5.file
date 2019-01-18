/*
 * Copyright (C) 2010 Collabora Ltd.
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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * A single backend to libfolks, such as Telepathy or evolution-data-server.
 * Each backend provides {@link Persona}s which are aggregated to form
 * {@link Individual}s.
 *
 * After creating a Backend instance, you must connect to the
 * {@link Backend.persona_store_added} and
 * {@link Backend.persona_store_removed} signals, //then// call
 * {@link Backend.prepare}, otherwise a race condition may occur between
 * emission of {@link Backend.persona_store_added} and your code connecting to
 * it.
 */
public abstract class Folks.Backend : Object
{
  construct
    {
      debug ("Constructing Backend ‘%s’ (%p)", this.name, this);
    }

  ~Backend ()
    {
      debug ("Destroying Backend ‘%s’ (%p)", this.name, this);
    }

  /**
   * Whether {@link Backend.prepare} has successfully completed for this
   * backend.
   *
   * @since 0.3.0
   */
  public abstract bool is_prepared { get; default = false; }

  /**
   * Whether the backend has reached a quiescent state. This will happen at some
   * point after {@link Backend.prepare} has successfully completed for the
   * backend. A backend is in a quiescent state when all the
   * {@link PersonaStore}s that it originally knows about have been loaded.
   *
   * It's guaranteed that this property's value will only ever change after
   * {@link Backend.is_prepared} has changed to ``true``.
   *
   * When {@link Backend.unprepare} is called, this will be reset to ``false``.
   *
   * @since 0.6.2
   */
  public abstract bool is_quiescent { get; default = false; }

  /**
   * A unique name for the backend.
   *
   * This will be used to identify the backend, and should also be used as the
   * {@link PersonaStore.type_id} of the {@link PersonaStore}s used by the
   * backend.
   *
   * This is guaranteed to always be available; even before
   * {@link Backend.prepare} is called.
   */
  public abstract string name { get; }

  /**
   * The {@link PersonaStore}s in use by the backend.
   *
   * A backend may expose {@link Persona}s from multiple servers or accounts
   * (for example), so may have a {@link PersonaStore} for each.
   *
   * @since 0.5.1
   */
  public abstract Map<string, PersonaStore> persona_stores { get; }

  /**
   * Disable a {@link PersonaStore}.
   *
   * If the given persona store is in this backend {@link Backend.persona_stores},
   * it will be removed, and we will disconnect from its signals.
   *
   * @param store the {@link PersonaStore} to disable.
   *
   * @since 0.9.0
   */
  public abstract void disable_persona_store (PersonaStore store);

  /**
   * Enable a {@link PersonaStore}.
   *
   * If the given persona store is not already in this backend
   * {@link Backend.persona_stores}, it will be added to the backend and
   * {@link Backend.persona_stores} property notification will be emitted,
   * along with {@link Backend.persona_store_added}.
   *
   * @param store the {@link PersonaStore} to enable.
   *
   * @since 0.9.0
   */
  public abstract void enable_persona_store (PersonaStore store);

  /**
   * Set the {@link PersonaStore}s to use in this backend.
   *
   * This will cause {@link Backend.persona_store_removed} signals to be emitted
   * for all removed stores, followed by {@link Backend.persona_store_added}
   * signals for all added stores. As these signals are emitted, the sets of
   * individuals in any associated {@link IndividualAggregator}s will be
   * updated, and {@link IndividualAggregator.individuals_changed} may be
   * emitted multiple times as appropriate. A property change notification for
   * {@link Backend.persona_stores} will be emitted last.
   * Note: pass null storeids to use all available persona stores.
   *
   * @param storeids a Set of {@link PersonaStore} IDs to use.
   *
   * @since 0.9.0
   */
  public abstract void set_persona_stores (Set<string>? storeids);

  /**
   * Emitted when a {@link PersonaStore} is added to the backend.
   *
   * This will not be emitted until after {@link Backend.prepare} has been
   * called.
   *
   * @param store the {@link PersonaStore}
   */
  public abstract signal void persona_store_added (PersonaStore store);

  /**
   * Emitted when a {@link PersonaStore} is removed from the backend.
   *
   * This will not be emitted until after {@link Backend.prepare} has been
   * called.
   *
   * @param store the {@link PersonaStore}
   */
  public abstract signal void persona_store_removed (PersonaStore store);

  /**
   * Prepare the Backend for use.
   *
   * This connects the Backend to whichever backend-specific services it
   * requires, and causes it to create its {@link PersonaStore}s. This should be
   * called //after// connecting to the {@link Backend.persona_store_added} and
   * {@link Backend.persona_store_removed} signals, or a race condition could
   * occur, with the signals being emitted before your code has connected to
   * them, and {@link PersonaStore}s getting "lost" as a result.
   *
   * This is normally handled transparently by the {@link IndividualAggregator}.
   *
   * If this function throws an error, the Backend will not be functional.
   *
   * This function is guaranteed to be idempotent (since version 0.3.0).
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @since 0.1.11
   * @throws GLib.Error if preparing the backend-specific services failed — this
   * will be a backend-specific error
   * @throws GLib.DBusError.SERVICE_UNKNOWN if a required D-Bus service was not
   * installed or could not be started
   */
  public abstract async void prepare () throws GLib.Error;

  /**
   * Revert the Backend to its pre-prepared state.
   *
   * This will disconnect this Backend and its dependencies from their
   * respective services and the Backend will issue
   * {@link Backend.persona_store_removed} for each of its
   * {@link PersonaStore}s.
   *
   * Most users won't need to use this function.
   *
   * If this function throws an error, the Backend will not be functional.
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @since 0.3.2
   * @throws GLib.Error if unpreparing the backend-specific services failed —
   * this will be a backend-specific error
   */
  public abstract async void unprepare () throws GLib.Error;
}
