/*
 * Copyright (C) 2010 Collabora Ltd.
 * Copyright (C) 2012, 2013 Philip Withnall
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
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;
using GLib;

/**
 * Errors from {@link IndividualAggregator}s.
 */
public errordomain Folks.IndividualAggregatorError
{
  /**
   * Adding a {@link Persona} to a {@link PersonaStore} failed.
   */
  ADD_FAILED,

  /**
   * An operation which required the use of a writeable store failed because no
   * writeable store was available.
   *
   * @since 0.1.13
   */
  [Version (deprecated = true, deprecated_since = "0.6.2.1",
      replacement = "IndividualAggregatorError.NO_PRIMARY_STORE")]
  NO_WRITEABLE_STORE,

  /**
   * The {@link PersonaStore} was offline (ie, this is a temporary failure).
   *
   * @since 0.3.0
   */
  STORE_OFFLINE,

  /**
   * The {@link PersonaStore} did not support writing to a property which the
   * user requested to write to, or which was necessary to write to for storing
   * linking information.
   *
   * @since 0.6.2
   */
  PROPERTY_NOT_WRITEABLE,

  /**
   * An operation which required the use of a primary store failed because no
   * primary store was available.
   *
   * @since 0.6.3
   */
  NO_PRIMARY_STORE,
}

/**
 * Stores {@link Individual}s which have been created through
 * aggregation of all the {@link Persona}s provided by the various
 * {@link Backend}s.
 *
 * This is the main interface for client applications.
 *
 * Linking and unlinking of personas and individuals is performed entirely
 * through the aggregator. Personas may be linked together to form individuals;
 * for example, the personas which form ``individual1`` and ``individual2`` may
 * be linked together with ``another_persona`` to give a new {@link Individual}:
 *
 * {{{
 *   var personas = new HashSet<Persona> ();
 *   personas.add_all (individual1.personas);
 *   personas.add_all (individual2.personas);
 *   personas.add (another_persona);
 *   yield my_individual_aggregator.link_personas (personas);
 * }}}
 *
 * The individuals which contained those personas will be removed when
 * {@link IndividualAggregator.link_personas} is called. Any personas in those
 * individuals which were not included in the linking call may end up implicitly
 * linked to the new individual, or may be aggregated into other new
 * individuals.
 *
 * For example, consider the situation where ``individual1`` contains two
 * personas, ``persona1A`` and ``persona1B``; ``individual2`` contains one
 * persona, ``persona2A``; and ``another_persona`` comes from ``individual3``,
 * which also contains ``persona3A`` and ``persona3B``. Calling
 * {@link IndividualAggregator.link_personas} on ``persona1A``, ``persona1B``,
 * ``persona2A`` and ``another_persona`` will result in ``individual1`` and
 * ``individual2`` being removed. A new {@link Individual} will be created
 * containing all the personas passed to the linking function. It might also
 * contain ``persona3A`` and ``persona3B``; or they might be in one or two other
 * new individuals.
 *
 * An existing individual may be unlinked to form singleton
 * individuals for each of its personas:
 * {{{
 *   yield my_individual_aggregator.unlink_individual (my_individual);
 * }}}
 *
 * Note that to link two individuals together, their two sets of personas must
 * be linked together. There is no API to directly link the individuals
 * themselves, as conceptually folks links {@link Persona}s, not
 * {@link Individual}s.
 *
 * Folks does not support having more than one IndividualAggregator
 * instantiated at the same time. Most clients should use
 * {@link IndividualAggregator.dup} to retrieve the IndividualAggregator
 * singleton.
 *
 */
public class Folks.IndividualAggregator : Object
{
  private static weak IndividualAggregator? _instance = null; /* needs to be locked */

  private BackendStore _backend_store;
  private HashMap<string, PersonaStore> _stores;
  private unowned PersonaStore? _primary_store = null;
  private SmallSet<Backend> _backends;

  private Settings? _primary_store_setting = null;

  /* This is conceptually a MultiMap<string, Individual> but it's sufficiently
   * heavily-used that avoiding GObject overhead in favour of inlinable
   * GenericArray access is a significant performance win.
   *
   * key: iid or value of some linkable property (email/IM address etc.)
   * value: owned non-empty set of owned Individual refs
   */
  private HashTable<string, GenericArray<Individual>> _link_map;

  private bool _linking_enabled = true;
  private bool _is_prepared = false;
  private bool _prepare_pending = false;
  private Debug _debug;
  private string _configured_primary_store_type_id;
  private string _configured_primary_store_id;
  private const string _FOLKS_GSETTINGS_SCHEMA = "org.freedesktop.folks";
  private const string _PRIMARY_STORE_CONFIG_KEY = "primary-store";

  /* The number of persona stores and backends we're waiting to become
   * quiescent. Once these both reach 0, we should be in a quiescent state.
   * We have to count both of them so that we can handle the case where one
   * backend becomes available, and its persona stores all become quiescent,
   * long before any other backend becomes available. In this case, we want
   * the aggregator to signal that it's reached a quiescent state only once
   * all the other backends have also become available. */
  private uint _non_quiescent_persona_store_count = 0;
  /* Same for backends. */
  private uint _non_quiescent_backend_count = 0;
  private bool _is_quiescent = false;
  /* As a precaution against backends/persona stores which never reach
   * quiescence (due to bugs), we implement a timeout after which we forcibly
   * reach quiescence. */
  private uint _quiescent_timeout_id = 0;

  private const uint _QUIESCENT_TIMEOUT = 30; /* seconds */

  /* We use this to know if the primary PersonaStore has been explicitly
   * set by the user (either via GSettings or an env variable). If that is the
   * case, we don't want to override it with other PersonaStores that
   * announce themselves as default (i.e.: default address book from e-d-s). */
  private bool _user_configured_primary_store = false;

  /**
   * Whether {@link IndividualAggregator.prepare} has successfully completed for
   * this aggregator.
   *
   * @since 0.3.0
   */
  public bool is_prepared
    {
      get { return this._is_prepared; }
    }

  /**
   * Whether the aggregator has reached a quiescent state. This will happen at
   * some point after {@link IndividualAggregator.prepare} has successfully
   * completed for the aggregator. An aggregator is in a quiescent state when
   * all the {@link PersonaStore}s listed by its backends have reached a
   * quiescent state. Once it's reached a quiescent state, this property will
   * never change again (from ``true`` to ``false``).
   *
   * It's guaranteed that this property's value will only ever change after
   * {@link IndividualAggregator.is_prepared} has changed to ``true``.
   *
   * @since 0.6.2
   */
  public bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  /**
   * Our configured primary (writeable) store.
   *
   * Which one to use is decided (in order or precedence)
   * by:
   *
   * - the FOLKS_PRIMARY_STORE env var (mostly for debugging)
   * - the GSettings key set in ``_PRIMARY_STORE_CONFIG_KEY`` (system set store)
   * - going with the ``key-file`` or ``eds`` store as the fall-back option
   *
   * @since 0.5.0
   */
  public PersonaStore? primary_store
    {
      get { return this._primary_store; }
    }

  /**
   * The backend store providing the persona stores for this aggregator.
   *
   * @since 0.9.7
   */
  public BackendStore backend_store
    {
      get { return this._backend_store; }
      construct { this._backend_store = value; }
    }

  private Map<string, Individual> _individuals;
  private Map<string, Individual> _individuals_ro;

  /**
   * A map from {@link Individual.id}s to their {@link Individual}s.
   *
   * This is the canonical set of {@link Individual}s provided by this
   * IndividualAggregator.
   *
   * {@link Individual}s may be added or removed using
   * {@link IndividualAggregator.add_persona_from_details} and
   * {@link IndividualAggregator.remove_individual}, respectively.
   *
   * @since 0.5.1
   */
  public Map<string, Individual> individuals
    {
      get { return this._individuals_ro; }
      private set
        {
          this._individuals = value;
          this._individuals_ro = this._individuals.read_only_view;
        }
    }

  /**
   * The {@link Individual} representing the user.
   *
   * If it exists, this holds the {@link Individual} who is the user: the
   * {@link Individual} containing the {@link Persona}s who are the owners of
   * the accounts for their respective backends.
   *
   * @since 0.3.0
   */
  public Individual? user { get; private set; }

  /**
   * Emitted when one or more {@link Individual}s are added to or removed from
   * the aggregator.
   *
   * If more information about the relationships between {@link Individual}s
   * which have been linked and unlinked is needed, consider connecting to
   * {@link IndividualAggregator.individuals_changed_detailed} instead, which is
   * emitted at the same time as this signal.
   *
   * This will not be emitted until after {@link IndividualAggregator.prepare}
   * has been called.
   *
   * @param added a list of {@link Individual}s which have been added
   * @param removed a list of {@link Individual}s which have been removed
   * @param message a string message from the backend, if any
   * @param actor the {@link Persona} who made the change, if known
   * @param reason the reason for the change
   *
   * @since 0.5.1
   */
  [Version (deprecated = true, deprecated_since = "0.6.2",
      replacement = "IndividualAggregator.individuals_changed_detailed")]
  public signal void individuals_changed (Set<Individual> added,
      Set<Individual> removed,
      string? message,
      Persona? actor,
      GroupDetails.ChangeReason reason);

  /**
   * Emitted when one or more {@link Individual}s are added to or removed from
   * the aggregator.
   *
   * This is emitted at the same time as
   * {@link IndividualAggregator.individuals_changed}, but includes more
   * information about the relationships between {@link Individual}s which have
   * been linked and unlinked.
   *
   * Individuals which have been linked will be listed in the multi-map as
   * mappings from the old individuals to the single new individual which
   * replaces them (i.e. each of the old individuals will map to the same new
   * individual). This new individual is the one which will be specified as the
   * ``replacement_individual`` in the {@link Individual.removed} signal for the
   * old individuals.
   *
   * Individuals which have been unlinked will be listed in the multi-map as
   * a mapping from the unlinked individual to a set of one or more individuals
   * which replace it.
   *
   * Individuals which have been added will be listed in the multi-map as a
   * mapping from ``null`` to the set of added individuals. If ``null`` doesn't
   * map to anything, no individuals have been added to the aggregator.
   *
   * Individuals which have been removed will be listed in the multi-map as
   * mappings from the removed individual to ``null``.
   *
   * This will not be emitted until after {@link IndividualAggregator.prepare}
   * has been called.
   *
   * @param changes a mapping of old {@link Individual}s to new
   * {@link Individual}s for the individuals which have changed in the
   * aggregator
   *
   * @since 0.6.2
   */
  public signal void individuals_changed_detailed (
      MultiMap<Individual?, Individual?> changes);

  /**
   * Create or return the singleton {@link IndividualAggregator} class instance.
   * If the instance doesn't exist already, it will be created with the
   * default {@link BackendStore}.
   *
   * This function is thread-safe.
   *
   * @return Singleton {@link IndividualAggregator} instance
   * @since 0.9.5
   */
  public static IndividualAggregator dup ()
    {
      IndividualAggregator? _retval = IndividualAggregator._instance;
      IndividualAggregator retval;

      if (_retval == null)
        {
          /* use an intermediate variable to force a strong reference */
          retval = new IndividualAggregator ();
          IndividualAggregator._instance = retval;
        }
      else
        {
          retval = (!) _retval;
        }

      return retval;
    }

  /**
   * Create a new IndividualAggregator.
   *
   * Clients should connect to the
   * {@link IndividualAggregator.individuals_changed} signal (or the
   * {@link IndividualAggregator.individuals_changed_detailed} signal), then
   * call {@link IndividualAggregator.prepare} to load the backends and start
   * aggregating individuals.
   *
   * An example of how to set up an IndividualAggregator:
   * {{{
   *   IndividualAggregator agg = new IndividualAggregator ();
   *   agg.individuals_changed_detailed.connect (individuals_changed_cb);
   *   agg.prepare ();
   * }}}
   *
   * Folks does not support having more than one IndividualAggregator
   * instantiated at the same time. So it's recommended to use
   * {@link IndividualAggregator.dup} instead.
   */
  [Version (deprecated = true, deprecated_since = "0.9.5",
      replacement = "IndividualAggregator.dup")]
  public IndividualAggregator ()
  {
    Object (backend_store: BackendStore.dup ());
  }

  /**
   * Create or return the singleton {@link IndividualAggregator} class instance
   * with a custom {@link BackendStore}.
   * If the instance doesn't exist already, it will be created with
   * the given {@link BackendStore} rather than the default one.
   * If the instance already exists but is using another {@link BackendStore}
   * then a warning is raised and null is returned.
   *
   * This function is thread-safe.
   *
   * @param store the {@link BackendStore} to use instead of the default one.

   * @return Singleton {@link IndividualAggregator} instance, or null
   * @since 0.9.5
   */
  public static IndividualAggregator? dup_with_backend_store (BackendStore store)
    {
      IndividualAggregator? _retval = IndividualAggregator._instance;
      IndividualAggregator retval;

      if (_retval == null)
        {
          /* use an intermediate variable to force a strong reference */
          retval = new IndividualAggregator.with_backend_store (store);
          IndividualAggregator._instance = retval;
        }
      else if (_retval._backend_store != store)
        {
          warning ("An aggregator already exists using another backend store");
          return null;
        }
      else
        {
          retval = (!) _retval;
        }

      return retval;
    }

  /**
   * Create a new IndividualAggregator with a custom {@link BackendStore}.
   *
   * This behaves the same as the default constructor for 
   * {@link IndividualAggregator}, but uses the given {@link BackendStore}
   * rather than the default one.
   *
   * @param store the {@link BackendStore} to use instead of the default one.
   *
   * @since 0.9.0
   */
  [Version (deprecated = true, deprecated_since = "0.9.5",
      replacement = "IndividualAggregator.dup_with_backend_store")]
  public IndividualAggregator.with_backend_store (BackendStore store)
  {
    Object (backend_store: store);
  }
  
  construct
    {
      this._stores = new HashMap<string, PersonaStore> ();
      this._individuals = new HashMap<string, Individual> ();
      this._individuals_ro = this._individuals.read_only_view;
      this._link_map = new HashTable<string, GenericArray<Individual>> (
          str_hash, str_equal);

      this._backends = new SmallSet<Backend> ();
      this._debug = Debug.dup ();
      this._debug.print_status.connect (this._debug_print_status);

      /* Check out the configured primary store */
      var store_config_ids = Environment.get_variable ("FOLKS_PRIMARY_STORE");
      if (store_config_ids == null)
        {
          store_config_ids = Environment.get_variable ("FOLKS_WRITEABLE_STORE");
          if (store_config_ids != null)
            {
              var deprecated_warn = "FOLKS_WRITEABLE_STORE is deprecated, ";
              deprecated_warn += "use FOLKS_PRIMARY_STORE";
              warning (deprecated_warn);
            }
        }

      if (store_config_ids != null)
        {
          debug ("Setting primary store IDs from environment variable.");
          this._configure_primary_store ((!) store_config_ids);
        }
      else
        {
          debug ("Setting primary store IDs to defaults.");
          if (BuildConf.HAVE_EDS)
            {
              this._configured_primary_store_type_id = "eds";
              this._configured_primary_store_id = "system-address-book";
            }
          else
            {
              this._configured_primary_store_type_id = "key-file";
              this._configured_primary_store_id = "";
            }

          this._primary_store_setting = new Settings (
              IndividualAggregator._FOLKS_GSETTINGS_SCHEMA);
          this._primary_store_setting.changed[IndividualAggregator._PRIMARY_STORE_CONFIG_KEY].connect (
              this._primary_store_setting_changed_cb);
          this._primary_store_setting_changed_cb (_primary_store_setting,
              IndividualAggregator._PRIMARY_STORE_CONFIG_KEY);
        }

      debug ("Primary store IDs are '%s' and '%s'.",
          this._configured_primary_store_type_id,
          this._configured_primary_store_id);

      var disable_linking = Environment.get_variable ("FOLKS_DISABLE_LINKING");
      if (disable_linking != null)
        disable_linking = ((!) disable_linking).strip ().down ();
      this._linking_enabled = (disable_linking == null ||
          disable_linking == "no" || disable_linking == "0");

      debug ("Constructing IndividualAggregator %p", this);
    }

  ~IndividualAggregator ()
    {
      debug ("Destroying IndividualAggregator %p", this);

      if (this._quiescent_timeout_id != 0)
        {
          Source.remove (this._quiescent_timeout_id);
          this._quiescent_timeout_id = 0;
        }

      this._backend_store.backend_available.disconnect (
          this._backend_available_cb);

      this._debug.print_status.disconnect (this._debug_print_status);

      /* Manually clear the singleton _instance */
      IndividualAggregator._instance = null;
    }

  private void _primary_store_setting_changed_cb (Settings settings,
        string key)
    {
        var val = settings.get_string (key);
        if (val != null && val != "")
        {
            debug ("Setting primary store IDs from GSettings.");
            this._configure_primary_store ((!) val);

            var store_full_id = this._get_store_full_id (
                this._configured_primary_store_type_id,
                this._configured_primary_store_id);
            if (this._stores.has_key (store_full_id))
              {
                  var selected_store = this._stores.get (store_full_id);
                  this._set_primary_store (selected_store);
              }
        }
    }

  private void _configure_primary_store (string store_config_ids)
    {
      debug ("_configure_primary_store to '%s'", store_config_ids);
      this._user_configured_primary_store = true;

      if (store_config_ids.index_of (":") != -1)
        {
          var ids = store_config_ids.split (":", 2);
          this._configured_primary_store_type_id = ids[0];
          this._configured_primary_store_id = ids[1];
        }
      else
        {
          this._configured_primary_store_type_id = store_config_ids;
          this._configured_primary_store_id = "";
        }
    }

  private void _debug_print_status (Debug debug)
    {
      const string domain = Debug.STATUS_LOG_DOMAIN;
      const LogLevelFlags level = LogLevelFlags.LEVEL_INFO;

      debug.print_heading (domain, level, "IndividualAggregator (%p)", this);
      debug.print_key_value_pairs (domain, level,
          "Ref. count", this.ref_count.to_string (),
          "Primary store", "%p".printf (this._primary_store),
          "Configured store type id", this._configured_primary_store_type_id,
          "Configured store id", this._configured_primary_store_id,
          "Linking enabled?", this._linking_enabled ? "yes" : "no",
          "Prepared?", this._is_prepared ? "yes" : "no",
          "Quiescent?", this._is_quiescent
              ? "yes"
              : "no (%u backends, %u persona stores left)".printf (
                  this._non_quiescent_backend_count,
                  this._non_quiescent_persona_store_count)
      );

      debug.print_line (domain, level,
          "%u Individuals:", this.individuals.size);
      debug.indent ();

      foreach (var individual in this.individuals.values)
        {
          string? trust_level = null;

          switch (individual.trust_level)
            {
              case TrustLevel.NONE:
                trust_level = "none";
                break;
              case TrustLevel.PERSONAS:
                trust_level = "personas";
                break;
              default:
                assert_not_reached ();
            }

          debug.print_heading (domain, level, "Individual (%p)", individual);
          debug.print_key_value_pairs (domain, level,
              "Ref. count", individual.ref_count.to_string (),
              "ID", individual.id,
              "User?", individual.is_user ? "yes" : "no",
              "Trust level", trust_level
          );
          debug.print_line (domain, level, "%u Personas:",
              individual.personas.size);

          debug.indent ();

          foreach (var persona in individual.personas)
            {
              debug.print_heading (domain, level, "Persona (%p)", persona);
              debug.print_key_value_pairs (domain, level,
                  "Ref. count", persona.ref_count.to_string (),
                  "UID", persona.uid,
                  "IID", persona.iid,
                  "Display ID", persona.display_id,
                  "User?", persona.is_user ? "yes" : "no"
              );
            }

          debug.unindent ();
        }

      debug.unindent ();

      debug.print_line (domain, level, "%u keys in the link map:",
          this._link_map.size ());
      debug.indent ();

      var iter = HashTableIter<string, GenericArray<Individual>> (
          this._link_map);
      unowned string link_key;
      unowned GenericArray<Individual> individuals;

      while (iter.next (out link_key, out individuals))
        {
          debug.print_line (domain, level, "%s → {", link_key);
          debug.indent ();

          for (uint i = 0; i < individuals.length; i++)
            {
              unowned Individual ind = individuals[i];

              debug.print_line (domain, level, "%p", ind);
            }

          debug.unindent ();
          debug.print_line (domain, level, "}");
        }

      debug.unindent ();

      /* Finish with a blank line. The format string must be non-empty. */
      debug.print_line (domain, level, "%s", "");
    }

  /**
   * Prepare the IndividualAggregator for use.
   *
   * This loads all the available backends and prepares them for use by the
   * IndividualAggregator. This should be called //after// connecting to the
   * {@link IndividualAggregator.individuals_changed} signal (or
   * {@link IndividualAggregator.individuals_changed_detailed} signal), or a
   * race condition could occur, with the signal being emitted before your code
   * has connected to them, and {@link Individual}s getting "lost" as a result.
   *
   * This function is guaranteed to be idempotent (since version 0.3.0).
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @throws GLib.Error if preparing any of the backends failed — this error
   * will be passed through from {@link BackendStore.load_backends}
   *
   * @since 0.1.11
   */
  public async void prepare () throws GLib.Error
    {
      Internal.profiling_start ("preparing IndividualAggregator");

      /* Once this async function returns, all the {@link Backend}s will have
       * been prepared (though no {@link PersonaStore}s are guaranteed to be
       * available yet). This last guarantee is new as of version 0.2.0. */

      if (this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;

          /* Temporarily increase the non-quiescent backend count so that
           * we don't prematurely reach quiescence due to odd timing of the
           * backend-available signals. */
          this._non_quiescent_backend_count++;

          this._backend_store.backend_available.connect (
              this._backend_available_cb);

          /* Load any backends which already exist. This could happen if the
           * BackendStore has stayed alive after being used by a previous
           * IndividualAggregator instance. */
          var backends = this._backend_store.enabled_backends.values;
          foreach (var backend in backends)
            {
              this._backend_available_cb (this._backend_store, backend);
            }

          /* Load any backends which haven't been loaded already. (Typically
           * all of them.) */
          yield this._backend_store.load_backends ();

          this._non_quiescent_backend_count--;

          this._is_prepared = true;
          this._prepare_pending = false;
          this.notify_property ("is-prepared");

          /* Mark the aggregator as having reached a quiescent state if
           * appropriate. This will typically only happen here in cases
           * where the stores were all prepared and quiescent before the
           * aggregator was created. */
          if (this._is_quiescent == false)
            {
              this._notify_if_is_quiescent ();
            }
        }
      finally
        {
          this._prepare_pending = false;
        }

      Internal.profiling_end ("preparing IndividualAggregator");
    }

  /**
   * Clean up and release resources used by the aggregator.
   *
   * This will disconnect the aggregator cleanly from any resources it or its
   * persona stores are using. It is recommended to call this method before
   * finalising the individual aggregator, but calling it is not required. If
   * this method is not called then, for example, unsaved changes in backends
   * may not be flushed.
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @since 0.7.3
   * @throws GLib.Error if unpreparing the backend-specific services failed —
   * this will be a backend-specific error
   */
  public async void unprepare () throws GLib.Error
    {
      if (!this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          /* Flush any PersonaStores which need it. */
          foreach (var p in this._stores.values)
            {
              yield p.flush ();
            }
        }
      finally
        {
          this._prepare_pending = false;
        }
    }

  /**
   * Get all matches for a given {@link Individual}.
   *
   * @param matchee the individual to find matches for
   * @param min_threshold the threshold for accepting a match
   * @return a map from matched individuals to the degree with which they match
   * ``matchee`` (which is guaranteed to at least equal ``min_threshold``);
   * if no matches could be found, an empty map is returned
   *
   * @since 0.5.1
   */
  public Map<Individual, MatchResult> get_potential_matches
      (Individual matchee, MatchResult min_threshold = MatchResult.VERY_HIGH)
    {
      HashMap<Individual, MatchResult> matches =
          new HashMap<Individual, MatchResult> ();
      Folks.PotentialMatch matchObj = new Folks.PotentialMatch ();

      foreach (var i in this._individuals.values)
        {
          if (i.id == matchee.id)
                continue;

          var result = matchObj.potential_match (i, matchee);
          if (result >= min_threshold)
            {
              matches.set (i, result);
            }
        }

      return matches;
    }

  /**
   * Get all combinations between all {@link Individual}s.
   *
   * @param min_threshold the threshold for accepting a match
   * @return a map from each individual in the aggregator to a map of the
   * other individuals in the aggregator which can be matched with that
   * individual, mapped to the degree with which they match the original
   * individual (which is guaranteed to at least equal ``min_threshold``)
   *
   * @since 0.5.1
   */
  public Map<Individual, Map<Individual, MatchResult>>
      get_all_potential_matches
        (MatchResult min_threshold = MatchResult.VERY_HIGH)
    {
      HashMap<Individual, HashMap<Individual, MatchResult>> matches =
        new HashMap<Individual, HashMap<Individual, MatchResult>> ();
      var individuals = this._individuals.values.to_array ();
      Folks.PotentialMatch matchObj = new Folks.PotentialMatch ();

      for (var i = 0; i < individuals.length; i++)
        {
          var a = individuals[i];

          HashMap<Individual, MatchResult>? _matches_a = matches.get (a);
          HashMap<Individual, MatchResult> matches_a;
          if (_matches_a == null)
            {
              matches_a = new HashMap<Individual, MatchResult> ();
              matches.set (a, matches_a);
            }
          else
            {
              matches_a = (!) _matches_a;
            }

          for (var f = i + 1; f < individuals.length; f++)
            {
              var b = individuals[f];

              HashMap<Individual, MatchResult>? _matches_b = matches.get (b);
              HashMap<Individual, MatchResult> matches_b;
              if (_matches_b == null)
                {
                  matches_b = new HashMap<Individual, MatchResult> ();
                  matches.set (b, matches_b);
                }
              else
                {
                  matches_b = (!) _matches_b;
                }

              var result = matchObj.potential_match (a, b);

              if (result >= min_threshold)
                {
                  matches_a.set (b, result);
                  matches_b.set (a, result);
                }
            }
        }

      return matches;
    }

  private void _add_backend (Backend backend)
    {
      if (!this._backends.contains (backend))
        {
          this._backends.add (backend);

          backend.persona_store_added.connect (
              this._backend_persona_store_added_cb);
          backend.persona_store_removed.connect (
              this._backend_persona_store_removed_cb);
          backend.notify["is-quiescent"].connect (
              this._backend_is_quiescent_changed_cb);

          /* Handle the stores that have already been signaled. Since
           * this might change while we are looping, get a copy first.
           */
          var stores = backend.persona_stores.values.to_array ();
          foreach (var persona_store in stores)
            {
              this._backend_persona_store_added_cb (backend, persona_store);
            }
        }
    }

  private void _backend_available_cb (BackendStore backend_store,
      Backend backend)
    {
      /* Increase the number of non-quiescent backends we're waiting for.
       * If we've already reached a quiescent state, this is ignored. If we
       * haven't, this delays us reaching a quiescent state until the
       * _backend_is_quiescent_changed_cb() callback is called for this
       * backend. */
      if (backend.is_quiescent == false)
        {
          this._non_quiescent_backend_count++;

          /* Start the timeout to force quiescence if the backend (or its
           * persona stores) misbehave and don't reach quiescence. */
          if (this._quiescent_timeout_id == 0)
            {
              this._quiescent_timeout_id =
                  Timeout.add_seconds (IndividualAggregator._QUIESCENT_TIMEOUT,
                      this._quiescent_timeout_cb);
            }
        }

      this._add_backend (backend);
    }

  private void _set_primary_store (PersonaStore store)
    {
      debug ("_set_primary_store()");

      if (this._primary_store == store)
        return;

      /* We use the configured PersonaStore as the primary PersonaStore.
       *
       * If the type_id is ``eds`` we *must* know the actual store
       * (address book) we are talking about or we might end up using
       * a random store on every run.
       */
      if (store.type_id == this._configured_primary_store_type_id)
        {
          if ((store.type_id != "eds" &&
                  this._configured_primary_store_id == "") ||
              this._configured_primary_store_id == store.id)
            {
              debug ("Setting primary store to %p (type ID: %s, ID: %s)",
                  store, store.type_id, store.id);

              var previous_store = this._primary_store;
              this._primary_store = store;

              store.freeze_notify ();
              if (previous_store != null)
                {
                  ((!) previous_store).freeze_notify ();
                  ((!) previous_store).is_primary_store = false;
                }
              store.is_primary_store = true;
              if (previous_store != null)
                ((!) previous_store).thaw_notify ();
              store.thaw_notify ();

              this.notify_property ("primary-store");
            }
        }
    }

  private void _backend_persona_store_added_cb (Backend backend,
      PersonaStore store)
    {
      debug ("_backend_persona_store_added_cb(): backend: %s, store: %s (%p)",
          backend.name, store.id, store);

      var store_id = this._get_store_full_id (store.type_id, store.id);

      this._maybe_configure_as_primary (store);
      this._set_primary_store (store);

      this._stores.set (store_id, store);
      store.personas_changed.connect (this._personas_changed_cb);
      store.notify["is-primary-store"].connect (
          this._is_primary_store_changed_cb);
      store.notify["is-quiescent"].connect (
          this._persona_store_is_quiescent_changed_cb);
      store.notify["is-user-set-default"].connect (
          this._persona_store_is_user_set_default_changed_cb);

      /* Increase the number of non-quiescent persona stores we're waiting for.
       * If we've already reached a quiescent state, this is ignored. If we
       * haven't, this delays us reaching a quiescent state until the
       * _persona_store_is_quiescent_changed_cb() callback is called for this
       * store. */
      if (store.is_quiescent == false)
        {
          this._non_quiescent_persona_store_count++;

          /* Start the timeout to force quiescence if the backend (or its
           * persona stores) misbehave and don't reach quiescence. */
          if (this._quiescent_timeout_id == 0)
            {
              this._quiescent_timeout_id =
                  Timeout.add_seconds (IndividualAggregator._QUIESCENT_TIMEOUT,
                      this._quiescent_timeout_cb);
            }
        }

      /* Handle any pre-existing personas in the store. This can happen if the
       * store existed (and was prepared) before this IndividualAggregator was
       * constructed. */
      if (store.personas.size > 0)
        {
          var persona_set = new HashSet<Persona> ();
          foreach (var p in store.personas.values)
            {
              persona_set.add (p);
            }

          this._personas_changed_cb (store, persona_set,
              SmallSet.empty<Persona> (), null, null,
              GroupDetails.ChangeReason.NONE);
        }

      /* Prepare the store and receive a load of other personas-changed
       * signals. */
      store.prepare.begin ((obj, result) =>
        {
          try
            {
              store.prepare.end (result);
            }
          catch (GLib.Error e)
            {
              /* Translators: the first parameter is a persona store identifier
               * and the second is an error message. */
              warning (_("Error preparing persona store ‘%s’: %s"), store_id,
                  e.message);
            }
        });
    }

  private void _backend_persona_store_removed_cb (Backend backend,
      PersonaStore store)
    {
      store.personas_changed.disconnect (this._personas_changed_cb);
      store.notify["is-quiescent"].disconnect (
          this._persona_store_is_quiescent_changed_cb);
      store.notify["is-primary-store"].disconnect (
          this._is_primary_store_changed_cb);
      store.notify["is-user-set-default"].disconnect (
          this._persona_store_is_user_set_default_changed_cb);

      /* If we were still waiting on this persona store to reach a quiescent
       * state, stop waiting. */
      if (this._is_quiescent == false && store.is_quiescent == false)
        {
          this._non_quiescent_persona_store_count--;
          this._notify_if_is_quiescent ();
        }

      /* Not all stores emit a 'removed' signal under all circumstances.
       * The EDS backend doesn't do it when set_persona_stores() or disable_store()
       * are used to disable a store.
       * Therefore remove this store's personas from all the individuals. Should
       * not have any effect if a store already triggered the 'removed' signals,
       * because then we won't have anything here.
       * See https://bugzilla.gnome.org/show_bug.cgi?id=689146
       */

      var removed_personas = new HashSet<Persona> ();
      var iter = store.personas.map_iterator ();

      while (iter.next () == true)
        {
          removed_personas.add (iter.get_value ());
        }
      this._personas_changed_cb (store, SmallSet.empty<Persona> (),
          removed_personas, null, null, GroupDetails.ChangeReason.NONE);

      if (this._primary_store == store)
        {
          debug ("Unsetting primary store as store %p (type ID: %s, ID: %s) " +
              "has been removed", store, store.type_id, store.id);
          this._primary_store = null;
          this.notify_property ("primary-store");
        }
      this._stores.unset (this._get_store_full_id (store.type_id, store.id));
    }

  private string _get_store_full_id (string type_id, string id)
    {
      return type_id + ":" + id;
    }

  /* Emit the individuals-changed signal ensuring that null parameters are
   * turned into empty sets, and both sets passed to signal handlers are
   * read-only. */
  private void _emit_individuals_changed (Set<Individual>? added,
      Set<Individual>? removed,
      MultiMap<Individual?, Individual?>? changes,
      string? message = null,
      Persona? actor = null,
      GroupDetails.ChangeReason reason = GroupDetails.ChangeReason.NONE)
    {
      Set<Individual> _added;
      Set<Individual> _removed;
      MultiMap<Individual?, Individual?> _changes;

      if ((added == null || ((!) added).size == 0) &&
          (removed == null || ((!) removed).size == 0) &&
          (changes == null || ((!) changes).size == 0))
        {
          /* Don't bother emitting it if nothing's changed */
          return;
        }

      Internal.profiling_point ("emitting " +
          "IndividualAggregator::individuals-changed");

      _added = (added != null) ? (!) added : SmallSet.empty<Individual> ();
      _removed = (removed != null) ? (!) removed : SmallSet.empty<Individual> ();

      if (changes != null)
        {
          _changes = (!) changes;
        }
      else
        {
          _changes = new HashMultiMap<Individual?, Individual?> ();
        }

      /* Debug output. */
      if (this._debug.debug_output_enabled == true)
        {
          debug ("Emitting individuals-changed-detailed with %u mappings:",
              _changes.size);

          var iter = _changes.map_iterator ();

          while (iter.next ())
            {
              var removed_ind = iter.get_key ();
              var added_ind = iter.get_value ();

              debug ("    %s (%p) → %s (%p)",
                  (removed_ind != null) ? ((!) removed_ind).id : "",
                  removed_ind,
                  (added_ind != null) ? ((!) added_ind).id : "", added_ind);

              if (removed_ind != null)
                {
                  debug ("      Removed individual's personas:");

                  foreach (var p in ((!) removed_ind).personas)
                    {
                      debug ("        %s (%p)", p.uid, p);
                    }
                }

              if (added_ind != null)
                {
                  debug ("      Added individual's personas:");

                  foreach (var p in ((!) added_ind).personas)
                    {
                      debug ("        %s (%p)", p.uid, p);
                    }
                }
            }
        }

      this.individuals_changed (_added.read_only_view, _removed.read_only_view,
          message, actor, reason);
      this.individuals_changed_detailed (_changes);
    }

  private void _connect_to_individual (Individual individual)
    {
      individual.removed.connect (this._individual_removed_cb);
      this._individuals.set (individual.id, individual);
    }

  private void _disconnect_from_individual (Individual individual)
    {
      this._individuals.unset (individual.id);
      individual.removed.disconnect (this._individual_removed_cb);
    }

  private void _add_personas (Set<Persona> added, ref Individual? user,
      ref HashMultiMap<Individual?, Individual?> individuals_changes)
    {
      foreach (var persona in added)
        {
          PersonaStoreTrust trust_level = persona.store.trust_level;

          /* These are the Individuals whose Personas will be linked together
           * to form the ``final_individual``.
           * Since a given Persona can only be part of one Individual, and the
           * code in Persona._set_personas() ensures that there are no duplicate
           * Personas in a given Individual, ensuring that there are no
           * duplicate Individuals in ``candidate_inds`` (by using a
           * HashSet) guarantees that there will be no duplicate Personas
           * in the ``final_individual``. */
          HashSet<Individual> candidate_inds = new HashSet<Individual> ();

          var final_personas = new HashSet<Persona> ();

          debug ("Aggregating persona '%s' on '%s'.", persona.uid, persona.iid);

          /* If the Persona is the user, we *always* want to link it to the
           * existing this.user. */
          if (this._linking_enabled == true &&
              persona.is_user == true && user != null &&
              ((!) user).has_anti_link_with_persona (persona) == false)
            {
              debug ("    Found candidate individual '%s' as user.",
                  ((!) user).id);
              candidate_inds.add ((!) user);
            }

          /* If we don't trust the PersonaStore at all, we can't link the
           * Persona to any existing Individual */
          if (this._linking_enabled == true &&
              trust_level != PersonaStoreTrust.NONE)
            {
              unowned GenericArray<Individual>? candidates =
                  this._link_map.get (persona.iid);
              if (candidates != null)
                {
                  for (uint i = 0; i < ((!) candidates).length; i++)
                    {
                      var candidate_ind = ((!) candidates)[i];

                      if (candidate_ind.trust_level != TrustLevel.NONE &&
                          candidate_ind.has_anti_link_with_persona (
                              persona) == false &&
                          candidate_inds.add (candidate_ind))
                        {
                          debug ("    Found candidate individual '%s' by " +
                              "IID '%s'.", candidate_ind.id, persona.iid);
                        }
                    }
                }
            }

          if (this._linking_enabled == true &&
              persona.store.trust_level == PersonaStoreTrust.FULL)
            {
              /* If we trust the PersonaStore the Persona came from, we can
               * attempt to link based on its linkable properties. */
              foreach (unowned string foo in persona.linkable_properties)
                {
                  /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
                  if (foo == null)
                      continue;

                  /* FIXME: If we just use string prop_name directly in the
                   * foreach, Vala doesn't copy it into the closure data, and
                   * prop_name ends up as NULL. bgo#628336 */
                  unowned string prop_name = foo;

                  unowned ObjectClass pclass = persona.get_class ();
                  if (pclass.find_property (prop_name) == null)
                    {
                      warning (
                          /* Translators: the parameter is a property name. */
                          _("Unknown property ‘%s’ in linkable property list."),
                          prop_name);
                      continue;
                    }

                  persona.linkable_property_to_links (prop_name, (l) =>
                    {
                      unowned string prop_linking_value = l;
                      unowned GenericArray<Individual>? candidates =
                          this._link_map.get (prop_linking_value);

                      if (candidates != null)
                        {
                          for (uint i = 0; i < ((!) candidates).length; i++)
                            {
                              var candidate_ind = ((!) candidates)[i];

                              if (candidate_ind.trust_level !=
                                      TrustLevel.NONE &&
                                  candidate_ind.
                                      has_anti_link_with_persona (
                                          persona) == false &&
                                  candidate_inds.add (candidate_ind))
                                {
                                  debug ("    Found candidate individual '%s'" +
                                      " by linkable property '%s' = '%s'.",
                                      candidate_ind.id, prop_name,
                                      prop_linking_value);
                                }
                            }
                        }
                    });
                }
            }

          /* Ensure the original persona makes it into the final individual */
          final_personas.add (persona);

          assert (this._linking_enabled == true || candidate_inds.size == 0);
          if (candidate_inds.size > 0 && this._linking_enabled == true)
            {
              /* The Persona's IID or linkable properties match one or more
               * linkable fields which are already in the link map, so we link
               * together all the Individuals we found to form a new
               * final_individual. Later, we remove the Personas from the old
               * Individuals so that the Individuals themselves are removed. */
              foreach (var individual in candidate_inds)
                {
                  final_personas.add_all (individual.personas);
                }
            }
          else if (!this._linking_enabled)
            {
              debug ("    Linking disabled.");
            }
          else
            {
              debug ("    Did not find any candidate individuals.");
            }

          /* Create the final linked Individual */
          var final_individual = new Individual (final_personas);
          debug ("    Created new individual '%s' (%p) with personas:",
              final_individual.id, final_individual);
          foreach (var p in final_personas)
            {
              debug ("        %s (%p)", p.uid, p);
              this._add_persona_to_link_map (p, final_individual);
            }

          uint num_mappings_added = 0;

          foreach (var i in candidate_inds)
            {
              /* Remove the old individuals from the link map. */
              this._remove_individual_from_link_map (i);

              /* Transitively update the individuals_changes. We have to do this
               * in two stages as we can't modify individuals_changes while
               * iterating over it. */
              var transitive_updates = new HashSet<Individual?> ();

              var iter = individuals_changes.map_iterator ();

              while (iter.next ())
                {
                  if (i == iter.get_value ())
                    {
                      transitive_updates.add (iter.get_key ());
                    }
                }

              foreach (var k in transitive_updates)
                {
                  assert (individuals_changes.remove (k, i) == true);

                  /* If we're saying the final_individual is replacing some of
                   * these candidate individuals, we don't also want to say that
                   * it's been added (by also emitting a mapping from
                   * null → final_individual). */
                  if (k != null)
                    {
                      individuals_changes.set (k, final_individual);
                      num_mappings_added++;
                    }
                }

              /* If there were no transitive changes to make, it's because this
               * candidate individual existed before this call to
               * _add_personas(), so it's safe to say it's being replaced by
               * the final_individual. */
              if (transitive_updates.size == 0)
                {
                  individuals_changes.set (i, final_individual);
                  num_mappings_added++;
                }
            }

          /* If there were no candidate individuals or they were all freshly
           * added (i.e. mapped from null → candidate_individual), mark the
           * final_individual as added. */
          if (num_mappings_added == 0)
            {
              individuals_changes.set (null, final_individual);
            }

          /* If the final Individual is the user, set them as such. */
          if (final_individual.is_user == true)
            user = final_individual;
        }
    }

  private void _persona_linkable_property_changed_cb (Object obj,
      ParamSpec pspec)
    {
      /* Ignore it if the link is disabled */
      if (this._linking_enabled == false)
        {
          return;
        }

      /* The value of one of the linkable properties of one the personas has
       * changed, so that persona might require re-linking. We do this in a
       * simplistic and hacky way (which should work) by simply treating the
       * persona as if it's been removed and re-added. */
      var persona = (!) (obj as Persona);

      debug ("Linkable property '%s' changed for persona '%s' " +
          "(is user: %s, IID: %s).", pspec.name, persona.uid,
          persona.is_user ? "yes" : "no", persona.iid);

      var persona_set = new SmallSet<Persona> ();
      persona_set.add (persona);

      this._personas_changed_cb (persona.store, persona_set, persona_set,
          null, null, GroupDetails.ChangeReason.NONE);
    }

  private void _persona_anti_links_changed_cb (Object obj, ParamSpec pspec)
    {
      var persona = obj as Persona;

      /* The anti-links associated with the persona has changed, so that persona
       * might require re-linking. We do this in a simplistic and hacky way
       * (which should work) by simply treating the persona as if it's been
       * removed and re-added. */
      debug ("Anti-links changed for persona '%s' (is user: %s, IID: %s).",
          persona.uid, persona.is_user ? "yes" : "no", persona.iid);

      var persona_set = new SmallSet<Persona> ();
      persona_set.add (persona);

      this._personas_changed_cb (persona.store, persona_set, persona_set,
          null, null, GroupDetails.ChangeReason.NONE);
    }

  private void _connect_to_persona (Persona persona)
    {
      foreach (var prop_name in persona.linkable_properties)
        {
          /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
          if (prop_name == null)
              continue;

          persona.notify[prop_name].connect (
              this._persona_linkable_property_changed_cb);
        }

      var al = persona as AntiLinkable;
      if (al != null)
        {
          al.notify["anti-links"].connect (this._persona_anti_links_changed_cb);
        }
    }

  private void _disconnect_from_persona (Persona persona)
    {
      var al = persona as AntiLinkable;
      if (al != null)
        {
          al.notify["anti-links"].disconnect (
              this._persona_anti_links_changed_cb);
        }

      foreach (var prop_name in persona.linkable_properties)
        {
          /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
          if (prop_name == null)
              continue;

          persona.notify[prop_name].disconnect (
              this._persona_linkable_property_changed_cb);
        }
    }

  /*
   * Ensure that ``_link_map[key]`` contains ``individual``.
   *
   * Equivalent to MultiMap.set().
   */
  private void _link_map_set (string key, Individual individual)
    {
      GenericArray<Individual>? inds = this._link_map[key];

      if (inds == null)
        {
          inds = new GenericArray<Individual> ();
          this._link_map.insert (key, (!) inds);
        }
      else
        {
          for (uint i = 0; i < ((!) inds).length; i++)
            {
              if (((!) inds)[i] == individual)
                return;
            }
        }

      ((!) inds).add (individual);
    }

  private void _add_persona_to_link_map (Persona persona, Individual individual)
    {
      debug ("Connecting to Persona: %s (is user: %s, IID: %s)", persona.uid,
          persona.is_user ? "yes" : "no", persona.iid);
      debug ("    Mapping to Individual: %s", individual.id);

      /* Add the Persona to the link map. Its trust level will be reflected in
       * final_individual.trust_level, so other Personas won't be linked against
       * it in error if the trust level is NONE. */
      this._link_map_set (persona.iid, individual);

      /* Only allow linking on non-IID properties of the Persona if we fully
       * trust the PersonaStore it came from. */
      if (persona.store.trust_level == PersonaStoreTrust.FULL)
        {
          debug ("    Inserting links:");

          /* Insert maps from the Persona's linkable properties to the
           * Individual. */
          foreach (unowned string prop_name in persona.linkable_properties)
            {
              /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
              if (prop_name == null)
                  continue;

              debug ("        %s", prop_name);

              unowned ObjectClass pclass = persona.get_class ();
              if (pclass.find_property (prop_name) == null)
                {
                  warning (
                      /* Translators: the parameter is a property name. */
                      _("Unknown property ‘%s’ in linkable property list."),
                      prop_name);
                  continue;
                }

              persona.linkable_property_to_links (prop_name, (l) =>
                {
                  unowned string prop_linking_value = l;

                  debug ("            %s", prop_linking_value);
                  this._link_map_set (prop_linking_value, individual);
                });
            }
        }
    }

  /* We remove individuals as a whole from the link map, rather than iterating
   * through the link map keys generated by their personas (as in
   * _add_persona_to_link_map()) because the values of the personas' linkable
   * properties may well have changed since we added the personas to the link
   * map. If that's the case, we don't want to end up leaving stale entries in
   * the link map, since that *will* cause problems later on. */
  private void _remove_individual_from_link_map (Individual individual)
    {
      debug ("Removing Individual '%s' from the link map.", individual.id);

      var iter =
          HashTableIter<string, GenericArray<Individual>> (this._link_map);
      unowned string link_key;
      unowned GenericArray<Individual> inds;

      while (iter.next (out link_key, out inds))
        {
          for (uint i = 0; i < inds.length; i++)
            {
              if (inds[i] == individual)
                {
                  debug ("    %s → %s (%p)",
                      link_key, individual.id, individual);

                  inds.remove_index_fast (i);

                  if (inds.length == 0)
                    iter.remove ();

                  /* stop looking at inds - it might be invalid now, and in
                   * any case, we've already removed @individual */
                  break;
                }
            }
        }
    }

  private void _personas_changed_cb (PersonaStore store,
      Set<Persona> added,
      Set<Persona> removed,
      string? message,
      Persona? actor,
      GroupDetails.ChangeReason reason)
    {
      var removed_individuals = new HashSet<Individual> ();
      var individuals_changes = new HashMultiMap<Individual?, Individual?> ();
      var relinked_personas = new HashSet<Persona> ();
      var replaced_individuals = new HashMap<Individual, Individual> ();

      /* We store the value of this.user locally and only update it at the end
       * of the function to prevent spamming notifications of changes to the
       * property. */
      var user = this.user;

      debug ("Removing Personas:");

      foreach (var persona in removed)
        {
          debug ("    %s (is user: %s, IID: %s)", persona.uid,
              persona.is_user ? "yes" : "no", persona.iid);

          /* Find the Individual containing the Persona (if any) and mark them
           * for removal (any other Personas they have which aren't being
           * removed will be re-linked into other Individuals). */
          Individual? ind = persona.individual;
          if (ind != null)
            {
              removed_individuals.add ((!) ind);
            }

          /* Stop listening to notifications about the persona's linkable
           * properties. */
          this._disconnect_from_persona (persona);
        }

      /* Remove the Individuals which were pointed to by the linkable properties
       * of the removed Personas. We can then re-link the other Personas in
       * those Individuals, since their links may have changed.
       * Note that we remove the Individual from this.individuals, meaning that
       * _individual_removed_cb() ignores this Individual. This allows us to
       * group together the IndividualAggregator.individuals_changed signals
       * for all the removed Individuals. */
      debug ("Removing Individuals due to removed links:");
      foreach (var individual in removed_individuals)
        {
          /* Ensure we don't remove the same Individual twice */
          if (this._individuals.has_key (individual.id) == false)
            continue;

          debug ("    %s", individual.id);

          /* Build a list of Personas which need relinking. Ensure we don't
           * include any of the Personas which have just been removed. */
          foreach (var persona in individual.personas)
            {
              if (removed.contains (persona) == true ||
                  relinked_personas.contains (persona) == true)
                continue;

              relinked_personas.add (persona);
            }

          if (user == individual)
            user = null;

          this._disconnect_from_individual (individual);

          /* Remove the Individual's links from the link map */
          this._remove_individual_from_link_map (individual);
        }

      debug ("Adding Personas:");
      foreach (var persona in added)
        {
          debug ("    %s (is user: %s, IID: %s)", persona.uid,
              persona.is_user ? "yes" : "no", persona.iid);

          /* Connect to notifications about the persona's linkable
           * properties. */
          this._connect_to_persona (persona);
        }

      if (added.size > 0)
        {
          this._add_personas (added, ref user, ref individuals_changes);
        }

      debug ("Relinking Personas:");
      foreach (var persona in relinked_personas)
        {
          debug ("    %s (is user: %s, IID: %s)", persona.uid,
              persona.is_user ? "yes" : "no", persona.iid);
        }

      this._add_personas (relinked_personas, ref user, ref individuals_changes);

      /* Work out which final individuals have replaced the removed_individuals
       * and update individuals_changes accordingly. */
      foreach (var individual in removed_individuals)
        {
          var added_mapping = false;

          foreach (var persona in individual.personas)
            {
              if (!(persona in removed) || (persona in added))
                {
                  individuals_changes.remove (null, persona.individual);
                  individuals_changes.set (individual, persona.individual);
                  added_mapping = true;
                }
            }

          /* Has the individual been removed entirely? */
          if (added_mapping == false)
            {
              individuals_changes.set (individual, null);
            }

          individual.personas = null;
        }

      /* Notify of changes to this.user */
      this.user = user;

      /* Signal the addition of new individuals and removal of old ones to the
       * aggregator */
      if (individuals_changes.size > 0)
        {
          var added_individuals = new HashSet<Individual> ();

          /* Extract the deprecated added and removed sets from
           * individuals_changes, to be used in the individuals_changed
           * signal. */
          var iter1 = individuals_changes.map_iterator ();

          while (iter1.next ())
            {
              var old_ind = iter1.get_key ();
              var new_ind = iter1.get_value ();

              assert (old_ind != null || new_ind != null);

              if (old_ind != null)
                {
                  removed_individuals.add ((!) old_ind);
                }

              if (new_ind != null)
                {
                  added_individuals.add ((!) new_ind);
                  this._connect_to_individual ((!) new_ind);
                }

              if (old_ind != null && new_ind != null)
                {
                  replaced_individuals.set ((!) old_ind, (!) new_ind);
                }
            }

          this._emit_individuals_changed (added_individuals,
              removed_individuals, individuals_changes);
        }

      /* Signal the replacement of various Individuals as a consequence of
       * linking. */
      debug ("Replacing Individuals due to linking:");
      var iter2 = replaced_individuals.map_iterator ();
      while (iter2.next () == true)
        {
          var old_ind = iter2.get_key ();
          var new_ind = iter2.get_value ();

          debug ("    %s (%p) → %s (%p)", old_ind.id, old_ind,
              new_ind.id, new_ind);

          old_ind.replace (new_ind);
        }

      /* Validate the link map. */
      if (this._debug.debug_output_enabled == true)
        {
          var link_map_iter =
              HashTableIter<string, GenericArray<Individual>> (this._link_map);
          unowned string link_key;
          unowned GenericArray<Individual> inds;

          while (link_map_iter.next (out link_key, out inds))
            {
              for (uint i = 0; i < inds.length; i++)
                {
                  var individual = inds[i];
                  assert (individual != null);

                  if (this._individuals.get (individual.id) != individual)
                    {
                      warning ("Link map contains invalid mapping:\n" +
                          "    %s → %s (%p)",
                              link_key, individual.id, individual);
                      warning ("Individual %s (%p) personas:", individual.id,
                          individual);
                      foreach (var p in individual.personas)
                        {
                          warning ("    %s (%p)", p.uid, p);
                        }
                    }

                  for (uint j = i + 1; j < inds.length; j++)
                    {
                      if (inds[i] == inds[j])
                        {
                          warning ("Link map contains non-unique " +
                              "Individual: %s → %s (%p) twice",
                              link_key, individual.id, individual);
                        }
                    }
                }
            }
        }
    }

  private void _is_primary_store_changed_cb (Object object, ParamSpec pspec)
    {
      /* Ensure that we only have one primary PersonaStore */
      var store = (PersonaStore) object;
      assert ((store.is_primary_store == true &&
              store == this._primary_store) ||
          (store.is_primary_store == false &&
              store != this._primary_store));
    }

  private void _persona_store_is_quiescent_changed_cb (Object obj,
      ParamSpec pspec)
    {
      /* Have we reached a quiescent state yet? */
      if (this._non_quiescent_persona_store_count > 0)
        {
          this._non_quiescent_persona_store_count--;
          this._notify_if_is_quiescent ();
        }
    }

  private void _backend_is_quiescent_changed_cb (Object obj, ParamSpec pspec)
    {
      if (this._non_quiescent_backend_count > 0)
        {
          this._non_quiescent_backend_count--;
          this._notify_if_is_quiescent ();
        }
    }

  private void _notify_if_is_quiescent ()
    {
      if (this._non_quiescent_backend_count == 0 &&
          this._non_quiescent_persona_store_count == 0 &&
          this._is_quiescent == false)
        {
          if (this._configured_primary_store_type_id.length > 0 &&
              this._primary_store == null)
            {
              warning ("Failed to find primary PersonaStore with type ID " +
                  "'%s' and ID '%s'.\n" +
                  "Individuals will not be linked properly " +
                  "and creating new links between Personas will not work.\n" +
                  "The configured primary PersonaStore's backend may not be " +
                  "installed. If you are unsure, check with your " +
                  "distribution.",
                  this._configured_primary_store_type_id,
                  this._configured_primary_store_id);
            }

          Internal.profiling_point ("reached quiescence in " +
              "IndividualAggregator");

          this._is_quiescent = true;
          this.notify_property ("is-quiescent");

          /* Remove the quiescence timeout, if it exists. */
          if (this._quiescent_timeout_id != 0)
            {
              Source.remove (this._quiescent_timeout_id);
              this._quiescent_timeout_id = 0;
            }
        }
    }

  private bool _quiescent_timeout_cb ()
    {
      /* If we're not quiescent by the time the timeout is triggered, force
       * quiescence anyway, just so that we don't leave clients hanging if our
       * backends have bugs. */
      if (this._is_quiescent == false)
        {
          warning ("Failed to reach quiescence normally (%u backends and %u " +
              "persona stores still haven't reached quiescence). Forcing " +
              "IndividualAggregator quiescence due to reaching the timeout.",
              this._non_quiescent_backend_count,
              this._non_quiescent_persona_store_count);

          this._is_quiescent = true;
          this.notify_property ("is-quiescent");
        }

      /* One-shot timeout */
      this._quiescent_timeout_id = 0;
      return false;
    }

  private void _persona_store_is_user_set_default_changed_cb (Object obj,
      ParamSpec pspec)
    {
      var store = (PersonaStore) obj;

      debug ("PersonaStore.is-user-set-default changed for store %p " +
          "(type ID: %s, ID: %s)", store, store.type_id, store.id);

      if (this._maybe_configure_as_primary (store))
        this._set_primary_store (store);
    }

  private bool _maybe_configure_as_primary (PersonaStore store)
    {
      debug ("_maybe_configure_as_primary()");

      var configured = false;

      if (!this._user_configured_primary_store &&
          store.is_user_set_default)
        {
          debug ("Setting primary store IDs to '%s' and '%s'.", store.type_id,
              store.id);
          this._configured_primary_store_type_id = store.type_id;
          this._configured_primary_store_id = store.id;
          configured = true;
        }

      return configured;
    }

  private void _individual_removed_cb (Individual i, Individual? replacement)
    {
      if (this.user == i)
        this.user = null;

      /* Only signal if the individual is still in this.individuals. This allows
       * us to group removals together in, e.g., _personas_changed_cb(). */
      if (this._individuals.get (i.id) != i)
        return;

      if (replacement != null)
        {
          debug ("Individual '%s' removed (replaced by '%s')", i.id,
              ((!) replacement).id);
        }
      else
        {
          debug ("Individual '%s' removed (not replaced)", i.id);
        }

      /* If the individual has 0 personas, we've already signaled removal */
      if (i.personas.size > 0)
        {
          var changes = new HashMultiMap<Individual?, Individual?> ();
          var individuals = new SmallSet<Individual> ();

          individuals.add (i);
          changes.set (i, replacement);

          this._emit_individuals_changed (null, individuals, changes);
        }

      this._disconnect_from_individual (i);
    }

  /**
   * Add a new persona in the given {@link PersonaStore} based on the
   * ``details`` provided.
   *
   * If the target store is offline, this function will throw
   * {@link IndividualAggregatorError.STORE_OFFLINE}. It's the responsibility of
   * the caller to cache details and re-try this function if it wishes to make
   * offline adds work.
   *
   * The details hash is a backend-specific mapping of key, value strings.
   * Common keys include:
   *
   *  * contact - service-specific contact ID
   *  * message - a user-readable message to pass to the persona being added
   *
   * If a {@link Persona} with the given details already exists in the store, no
   * error will be thrown and this function will return ``null``.
   *
   * @param parent an optional {@link Individual} to add the new {@link Persona}
   * to. This persona will be appended to its ordered list of personas.
   * @param persona_store the {@link PersonaStore} to add the persona to
   * @param details a key-value map of details to use in creating the new
   * {@link Persona}
   * @return the new {@link Persona} or ``null`` if the corresponding
   * {@link Persona} already existed. If non-``null``, the new {@link Persona}
   * will also be added to a new or existing {@link Individual} as necessary.
   * @throws IndividualAggregatorError.STORE_OFFLINE if the persona store was
   * offline
   * @throws IndividualAggregatorError.ADD_FAILED if any other error occurred
   * while adding the persona
   *
   * @since 0.3.5
   */
  public async Persona? add_persona_from_details (Individual? parent,
      PersonaStore persona_store,
      HashTable<string, Value?> details) throws IndividualAggregatorError
    {
      Persona? persona = null;
      try
        {
          var details_copy = this._asv_copy (details);
          persona = yield persona_store.add_persona_from_details (details_copy);
        }
      catch (PersonaStoreError e)
        {
          if (e is PersonaStoreError.STORE_OFFLINE)
            {
              throw new IndividualAggregatorError.STORE_OFFLINE (e.message);
            }
          else
            {
              var full_id = this._get_store_full_id (persona_store.type_id,
                  persona_store.id);

              throw new IndividualAggregatorError.ADD_FAILED (
                  /* Translators: the first parameter is a store identifier
                   * and the second parameter is an error message. */
                  _("Failed to add contact for persona store ID ‘%s’: %s"),
                  full_id, e.message);
            }
        }

      if (parent != null && persona != null)
        {
          ((!) parent).personas.add ((!) persona);
        }

      return persona;
    }

  private HashTable<string, Value?> _asv_copy (HashTable<string, Value?> asv)
    {
      var retval = new HashTable<string, Value?> (str_hash, str_equal);

      asv.foreach ((k, v) =>
        {
          retval.insert ((string) k, v);
        });

      return retval;
    }

  /**
   * Completely remove the individual and all of its personas from their
   * backing stores.
   *
   * This method is safe to call multiple times concurrently (for the same
   * individual or different individuals).
   *
   * @param individual the {@link Individual} to remove
   * @throws GLib.Error if removing the persona failed — this will be passed
   * through from {@link PersonaStore.remove_persona}
   *
   * @since 0.1.11
   */
  public async void remove_individual (Individual individual) throws GLib.Error
    {
      /* Removing personas changes the persona set so we need to make a copy
       * first */
      var personas = SmallSet<Persona>.copy (individual.personas);

      foreach (var persona in personas)
        {
          yield persona.store.remove_persona (persona);
        }
    }

  /**
   * Completely remove the persona from its backing store.
   *
   * This will leave other personas in the same individual alone.
   *
   * This method is safe to call multiple times concurrently (for the same
   * persona or different personas).
   *
   * @param persona the {@link Persona} to remove
   * @throws GLib.Error if removing the persona failed — this will be passed
   * through from {@link PersonaStore.remove_persona}
   *
   * @since 0.1.11
   */
  public async void remove_persona (Persona persona) throws GLib.Error
    {
      yield persona.store.remove_persona (persona);
    }

  /**
   * Link the given {@link Persona}s together.
   *
   * Create links between the given {@link Persona}s so that they form a single
   * {@link Individual}. The new {@link Individual} will be returned via the
   * {@link IndividualAggregator.individuals_changed} signal.
   *
   * Removal of the {@link Individual}s which the {@link Persona}s were in
   * before is signalled by {@link IndividualAggregator.individuals_changed} and
   * {@link Individual.removed}.
   *
   * This method is safe to call multiple times concurrently.
   *
   * @param personas the {@link Persona}s to be linked
   * @throws IndividualAggregatorError.NO_PRIMARY_STORE if no primary store has
   * been configured for the individual aggregator
   * @throws IndividualAggregatorError if adding the linking persona failed —
   * this will be passed through from
   * {@link IndividualAggregator.add_persona_from_details}
   *
   * @since 0.5.1
   */
  public async void link_personas (Set<Persona> personas)
      throws IndividualAggregatorError
    {
      if (this._primary_store == null)
        {
          throw new IndividualAggregatorError.NO_PRIMARY_STORE (
              _("Can’t link personas with no primary store.") + "\n" +
              _("Persona store ‘%s:%s’ is configured as primary, but could not be found or failed to load.") + "\n" +
              _("Check the relevant service is running, or change the default store in that service or using the ‘%s’ GSettings key."),
              this._configured_primary_store_type_id,
              this._configured_primary_store_id,
              "%s %s".printf (IndividualAggregator._FOLKS_GSETTINGS_SCHEMA,
                  IndividualAggregator._PRIMARY_STORE_CONFIG_KEY));
        }

      /* Don't bother linking if it's just one Persona */
      if (personas.size <= 1)
        return;

      /* Disallow linking if it's disabled */
      if (this._linking_enabled == false)
        {
          debug ("Can't link Personas: linking disabled.");
          return;
        }

      /* Remove all edges in the connected graph between the personas from the
       * anti-link map to ensure that linking the personas actually succeeds. */
      foreach (var p in personas)
        {
          var al = p as AntiLinkable;
          if (al != null)
            {
              try
                {
                  yield ((!) al).remove_anti_links (personas);
                }
              catch (PropertyError e)
                {
                  throw new IndividualAggregatorError.PROPERTY_NOT_WRITEABLE (
                      _("Anti-links can’t be removed between personas being linked."));
                }
            }
        }

      /* Create a new persona in the primary store which links together the
       * given personas */
      assert (((!) this._primary_store).type_id ==
          this._configured_primary_store_type_id);

      var details = this._build_linking_details (personas);

      yield this.add_persona_from_details (null,
          (!) this._primary_store, details);
    }

  private HashTable<string, Value?> _build_linking_details (
      Set<Persona> personas)
    {
      /* ``protocols_addrs_set`` will be passed to the new Kf.Persona */
      var protocols_addrs_set = new HashMultiMap<string, ImFieldDetails> (
            null, null, AbstractFieldDetails<string>.hash_static,
            AbstractFieldDetails<string>.equal_static);
      var web_service_addrs_set =
        new HashMultiMap<string, WebServiceFieldDetails> (
            null, null, AbstractFieldDetails<string>.hash_static,
            AbstractFieldDetails<string>.equal_static);

      /* List of local_ids */
      var local_ids = new SmallSet<string> ();

      foreach (var persona in personas)
        {
          if (persona is ImDetails)
            {
              ImDetails im_details = (ImDetails) persona;
              var iter = im_details.im_addresses.map_iterator ();

              /* protocols_addrs_set = union (all personas' IM addresses) */
              while (iter.next ())
                protocols_addrs_set.set (iter.get_key (), iter.get_value ());
            }

          if (persona is WebServiceDetails)
            {
              WebServiceDetails ws_details = (WebServiceDetails) persona;
              var iter = ws_details.web_service_addresses.map_iterator ();

              /* web_service_addrs_set = union (all personas' WS addresses) */
              while (iter.next ())
                web_service_addrs_set.set (iter.get_key (), iter.get_value ());
            }

          if (persona is LocalIdDetails)
            {
              foreach (var id in ((LocalIdDetails) persona).local_ids)
                {
                  local_ids.add (id);
                }
            }
        }

      var details = new HashTable<string, Value?> (str_hash, str_equal);

      if (protocols_addrs_set.size > 0)
        {
          var im_addresses_value = Value (typeof (MultiMap));
          im_addresses_value.set_object (protocols_addrs_set);
          details.insert (
              (!) PersonaStore.detail_key (PersonaDetail.IM_ADDRESSES),
              im_addresses_value);
        }

      if (web_service_addrs_set.size > 0)
        {
          var web_service_addresses_value = Value (typeof (MultiMap));
          web_service_addresses_value.set_object (web_service_addrs_set);
          details.insert (
              (!) PersonaStore.detail_key (PersonaDetail.WEB_SERVICE_ADDRESSES),
              web_service_addresses_value);
        }

      if (local_ids.size > 0)
        {
          var local_ids_value = Value (typeof (Set));
          local_ids_value.set_object (local_ids);
          details.insert (
              (!) Folks.PersonaStore.detail_key (PersonaDetail.LOCAL_IDS),
              local_ids_value);
        }

      return details;
    }

  /**
   * Unlinks the given {@link Individual} into its constituent {@link Persona}s.
   *
   * This completely unlinks the given {@link Individual}, destroying all of
   * its writeable {@link Persona}s.
   *
   * The {@link Individual}'s removal is signalled by
   * {@link IndividualAggregator.individuals_changed} and
   * {@link Individual.removed}.
   *
   * The {@link Persona}s comprising the {@link Individual} will be re-linked
   * into one or more new {@link Individual}s, depending on how much linking
   * data remains (typically only implicit links remain). The addition of these
   * new {@link Individual}s will be signalled by
   * {@link IndividualAggregator.individuals_changed}.
   *
   * This method is safe to call multiple times concurrently, although
   * concurrent calls for the same individual may result in duplicate personas
   * being created.
   *
   * @param individual the {@link Individual} to unlink
   * @throws GLib.Error if removing the linking persona failed — this will be
   * passed through from {@link PersonaStore.remove_persona}
   *
   * @since 0.1.13
   */
  public async void unlink_individual (Individual individual) throws GLib.Error
    {
      if (this._linking_enabled == false)
        {
          debug ("Can't unlink Individual '%s': linking disabled.",
              individual.id);
          return;
        }

      debug ("Unlinking Individual '%s':", individual.id);

      /* Add all edges in the connected graph between the personas to the
       * anti-link map to ensure that unlinking the personas actually succeeds,
       * and that they aren't immediately re-linked.
       *
       * Perversely, this requires that we ensure the anti-links property is
       * writeable on all personas before continuing. Ignore errors from it in
       * the hope that everything works anyway.
       *
       * In the worst case, this will double the number of personas, since if
       * none of the personas have anti-links writeable, each will have to be
       * linked with a new writeable persona. */
      /* Copy it, since we modify it */
      var individual_personas = SmallSet<Persona>.copy (individual.personas);

      debug ("    Inserting anti-links:");
      foreach (var pers in individual_personas)
        {
          try
            {
              var personas = new SmallSet<Persona> ();
              personas.add (pers);
              debug ("        Anti-linking persona '%s' (%p)", pers.uid, pers);

              var writeable_persona =
                  yield this._ensure_personas_property_writeable (personas,
                      "anti-links");
              debug ("        Writeable persona '%s' (%p)",
                  writeable_persona.uid, writeable_persona);

              /* Make sure not to anti-link the new persona to pers. */
              var anti_link_personas = SmallSet<Persona>.copy (individual_personas);
              anti_link_personas.remove (pers);

              var al = writeable_persona as AntiLinkable;
              assert (al != null);
              yield ((!) al).add_anti_links (anti_link_personas);
              debug ("");
            }
          catch (IndividualAggregatorError e1)
            {
              debug ("    Failed to ensure anti-links property is writeable " +
                  "(continuing anyway): %s", e1.message);
            }
        }
    }

  /**
   * Ensure that the given property is writeable for the given
   * {@link Individual}.
   *
   * This makes sure that there is at least one {@link Persona} in the
   * individual which has ``property_name`` in its
   * {@link Persona.writeable_properties}. If no such persona exists in the
   * individual, a new one will be created and linked to the individual. (Note
   * that due to the design of the aggregator, this will result in the previous
   * individual being removed and replaced by a new one with the new persona;
   * listen to the {@link Individual.removed} signal to see the replacement.)
   *
   * It may not be possible to create a new persona which has the given property
   * as writeable. In that case, a
   * {@link IndividualAggregatorError.NO_PRIMARY_STORE} or
   * {@link IndividualAggregatorError.PROPERTY_NOT_WRITEABLE} error will be
   * thrown.
   *
   * This method is safe to call multiple times concurrently, although
   * concurrent calls for the same individual may result in duplicate personas
   * being created.
   *
   * @param individual the individual for which ``property_name`` should be
   * writeable
   * @param property_name the name of the property which needs to be writeable
   * (this should be in lower case using hyphens, e.g. “web-service-addresses”)
   * @return a persona (new or existing) which has the given property as
   * writeable
   * @throws IndividualAggregatorError.NO_PRIMARY_STORE if no primary store was
   * configured for this individual aggregator
   * @throws IndividualAggregatorError.PROPERTY_NOT_WRITEABLE if the given
   * ``property_name`` referred to a non-writeable property
   * @throws IndividualAggregatorError if adding a new persona (using
   * {@link IndividualAggregator.add_persona_from_details}) failed, or if
   * linking personas (using {@link IndividualAggregator.link_personas}) failed
   *
   * @since 0.6.2
   */
  public async Persona ensure_individual_property_writeable (
      Individual individual, string property_name)
      throws IndividualAggregatorError
    {
      debug ("ensure_individual_property_writeable: %s, %s",
          individual.id, property_name);

      var p = yield this._ensure_personas_property_writeable (
          individual.personas, property_name);
      return p;
    }

  /* This is safe to call multiple times concurrently, *but* if the set of
   * personas doesn't change, multiple duplicate personas may be created in the
   * writeable store. */
  private async Persona _ensure_personas_property_writeable (
      Set<Persona> personas, string property_name)
      throws IndividualAggregatorError
    {
      /* See if the persona set already contains the property we want. */
      foreach (var p1 in personas)
        {
          if (property_name in p1.writeable_properties)
            {
              debug ("    Returning existing persona: %s", p1.uid);
              return p1;
            }
        }

      /* Otherwise, create a new persona in the writeable store. If the
       * writeable store doesn't exist or doesn't support writing to the given
       * property, we try the other persona stores. */
      var details = this._build_linking_details (personas);
      Persona? new_persona = null;

      if (this._primary_store != null &&
          property_name in
              ((!) this._primary_store).always_writeable_properties)
        {
          try
            {
              debug ("    Using writeable store");
              new_persona = yield this.add_persona_from_details (null,
                  (!) this._primary_store, details);
            }
          catch (IndividualAggregatorError e1)
            {
              /* Ignore it */
              new_persona = null;
            }
        }

      if (new_persona == null)
        {
          foreach (var s in this._stores.values)
            {
              if (s == this._primary_store ||
                  !(property_name in s.always_writeable_properties))
                {
                  /* Skip the store we've just tried */
                  continue;
                }

              try
                {
                  debug ("    Using store %s", s.id);
                  new_persona = yield this.add_persona_from_details (null, s,
                      details);
                }
              catch (IndividualAggregatorError e2)
                {
                  /* Ignore it */
                  new_persona = null;
                  continue;
                }
            }
        }

      /* Throw an error if we haven't managed to find a suitable store */
      if (new_persona == null && this._primary_store == null)
        {
          throw new IndividualAggregatorError.NO_PRIMARY_STORE (
              _("Can’t add personas with no primary store.") + "\n" +
              _("Persona store ‘%s:%s’ is configured as primary, but could not be found or failed to load.") + "\n" +
              _("Check the relevant service is running, or change the default store in that service or using the ‘%s’ GSettings key."),
              this._configured_primary_store_type_id,
              this._configured_primary_store_id,
              "%s %s".printf (IndividualAggregator._FOLKS_GSETTINGS_SCHEMA,
                  IndividualAggregator._PRIMARY_STORE_CONFIG_KEY));
        }
      else if (new_persona == null)
        {
          throw new IndividualAggregatorError.PROPERTY_NOT_WRITEABLE (
              _("Can’t write to requested property (‘%s’) of the writeable store."),
              property_name);
        }

      /* We can guarantee new_persona != null because we'd have bailed out above
       * otherwise. */
      return (!) new_persona;
    }

  /**
   * Look up an individual in the aggregator.
   *
   * This returns the {@link Individual} with the given ``id`` if it exists in
   * the aggregator, and ``null`` otherwise.
   *
   * In future, when lazy-loading of individuals' properties is added to folks,
   * this method guarantees to load all properties of the individual, even if
   * the aggregator hasn't lazy-loaded anything else.
   *
   * This method is safe to call before {@link IndividualAggregator.prepare} has
   * been called, and will call {@link IndividualAggregator.prepare} itself in
   * that case.
   *
   * This method is safe to call multiple times concurrently.
   *
   * @param id ID of the individual to look up
   * @return individual with ``id``, or ``null`` if no such individual was found
   * @throws GLib.Error from {@link IndividualAggregator.prepare}
   *
   * @since 0.7.0
   */
  public async Individual? look_up_individual (string id) throws GLib.Error
    {
      /* Ensure the aggregator's prepared. */
      yield this.prepare ();

      /* FIXME: When bgo#648805 is fixed, this needs to support lazy-loading. */
      return this._individuals.get (id);
    }
}
