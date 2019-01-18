/*
 * Copyright (C) 2008 Nokia Corporation.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
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
 * Authors: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *          Travis Reitter <travis.reitter@collabora.co.uk>
 *
 * This file was originally part of Rygel.
 */

using Gee;
using GLib;

extern const string G_LOG_DOMAIN;

/**
 * Responsible for backend loading.
 *
 * The BackendStore manages the set of available Folks backends. The
 * {@link BackendStore.load_backends} function loads all compatible and enabled
 * backends and the {@link BackendStore.backend_available} signal notifies when
 * these backends are ready.
 */
public class Folks.BackendStore : Object {
  [CCode (has_target = false)]
  private delegate void ModuleInitFunc (BackendStore store);
  [CCode (has_target = false)]
  private delegate void ModuleFinalizeFunc (BackendStore store);

  /* this contains all backends, regardless of enabled or prepared state */
  private HashMap<string,Backend> _backend_hash;
  /* if null, all backends are allowed */
  private SmallSet<string>? _backends_allowed;
  /* if null, no backends are disabled */
  private SmallSet<string>? _backends_disabled;
  private HashMap<string, Backend> _prepared_backends;
  private Map<string, Backend> _prepared_backends_ro;
  private File _config_file;
  private GLib.KeyFile _backends_key_file;
  private HashMap<string,unowned Module> _modules;
  private static weak BackendStore? _instance = null;
  private bool _is_prepared = false;
  private Debug _debug;

  /**
   * This keyword in the keyfile acts as a wildcard for all backends not already
   * listed in the same file.
   *
   * This is particularly useful for tests which want to ensure they're only
   * operating with backends they were designed for (and thus may not be able to
   * enumerate entries for).
   *
   * To avoid conflicts, backends must not use this as a name.
   *
   * @since 0.4.0
   */
  public static string KEY_FILE_GROUP_ALL_OTHERS = "all-others";

  /**
   * Emitted when a backend has been added to the BackendStore.
   *
   * This will not be emitted until after {@link BackendStore.load_backends}
   * has been called.
   *
   * {@link Backend}s referenced in this signal are also included in
   * {@link BackendStore.enabled_backends}.
   *
   * @param backend the new {@link Backend}
   */
  public signal void backend_available (Backend backend);

  /**
   * The list of backends visible to this store which have not been explicitly
   * disabled.
   *
   * This list will be empty before {@link BackendStore.load_backends} has been
   * called.
   *
   * The backends in this list have been prepared and are ready to use.
   *
   * @since 0.5.1
   */
  public Map<string, Backend> enabled_backends
    {
      /* Return a read-only view of the map */
      get { return this._prepared_backends_ro; }

      private set {}
    }

  /**
   * Whether {@link BackendStore.prepare} has successfully completed for this
   * store.
   *
   * @since 0.3.0
   */
  public bool is_prepared
    {
      get { return this._is_prepared; }

      private set {}
    }

  /**
   * Create a new BackendStore.
   */
  public static BackendStore dup ()
    {
      if (BackendStore._instance == null)
        {
          /* use an intermediate variable to force a strong reference */
          var new_instance = new BackendStore ();
          BackendStore._instance = new_instance;

          return new_instance;
        }

      return (!) BackendStore._instance;
    }

  private BackendStore ()
    {
      Object ();
    }

  construct
    {
      /* Treat this as a library init function */
      var debug_no_colour = Environment.get_variable ("FOLKS_DEBUG_NO_COLOUR");
      var debug_no_color = Environment.get_variable ("FOLKS_DEBUG_NO_COLOR");
      this._debug =
          Debug.dup_with_flags (Environment.get_variable ("G_MESSAGES_DEBUG"),
              (debug_no_colour == null || debug_no_colour == "0") &&
              (debug_no_color == null || debug_no_color == "0"));

      /* register the core debug messages */
      this._debug._register_domain (G_LOG_DOMAIN);

      this._debug.print_status.connect (this._debug_print_status);

      this._modules = new HashMap<string,unowned Module> ();
      this._backend_hash = new HashMap<string,Backend> ();
      this._prepared_backends = new HashMap<string,Backend> ();
      this._prepared_backends_ro = this._prepared_backends.read_only_view;
    }

  ~BackendStore ()
    {
      /* Unprepare all existing backends. */
      var iter = this._prepared_backends.map_iterator ();
      while (iter.next () == true)
        {
          var backend = iter.get_value ();
          backend.unprepare.begin ();
        }

      this._prepared_backends.clear ();

      /* Finalize all the loaded modules that have finalize functions */
      foreach (var module in this._modules.values)
        {
          void* func;
          if (module.symbol ("module_finalize", out func))
            {
              ModuleFinalizeFunc module_finalize = (ModuleFinalizeFunc) func;
              module_finalize (this);
            }
        }

      this._modules.clear ();

      /* Disconnect from the debug handler */
      this._debug.print_status.disconnect (this._debug_print_status);

      /* manually clear the singleton instance */
      BackendStore._instance = null;
    }

  private void _debug_print_status (Debug debug)
    {
      const string domain = Debug.STATUS_LOG_DOMAIN;
      const LogLevelFlags level = LogLevelFlags.LEVEL_INFO;

      debug.print_heading (domain, level, "BackendStore (%p)", this);
      debug.print_line (domain, level, "%u Backends:",
          this._backend_hash.size);

      debug.indent ();

      foreach (var backend in this._backend_hash.values)
        {
          debug.print_heading (domain, level, "Backend (%p)", backend);
          debug.print_key_value_pairs (domain, level,
              "Ref. count", this.ref_count.to_string (),
              "Name", backend.name,
              "Prepared?", backend.is_prepared ? "yes" : "no",
              "Quiescent?", backend.is_quiescent ? "yes" : "no"
          );
          debug.print_line (domain, level, "%u PersonaStores:",
              backend.persona_stores.size);

          debug.indent ();

          foreach (var persona_store in backend.persona_stores.values)
            {
              string? trust_level = null;

              switch (persona_store.trust_level)
                {
                  case PersonaStoreTrust.NONE:
                    trust_level = "none";
                    break;
                  case PersonaStoreTrust.PARTIAL:
                    trust_level = "partial";
                    break;
                  case PersonaStoreTrust.FULL:
                    trust_level = "full";
                    break;
                  default:
                    assert_not_reached ();
                }

              var writeable_props = string.joinv (",",
                  persona_store.always_writeable_properties);

              debug.print_heading (domain, level, "PersonaStore (%p)",
                  persona_store);
              debug.print_key_value_pairs (domain, level,
                  "Ref. count", this.ref_count.to_string (),
                  "ID", persona_store.id,
                  "Prepared?", persona_store.is_prepared ? "yes" : "no",
                  "Is primary store?",
                  persona_store.is_primary_store ? "yes" : "no",
                  "Always writeable properties", writeable_props,
                  "Quiescent?", persona_store.is_quiescent ? "yes" : "no",
                  "Trust level", trust_level,
                  "Persona count", persona_store.personas.size.to_string ()
              );
            }

          debug.unindent ();
        }

      debug.unindent ();

      /* Finish with a blank line. The format string must be non-empty. */
      debug.print_line (domain, level, "%s", "");
    }

  /**
   * Prepare the BackendStore for use.
   *
   * This must only ever be called before {@link BackendStore.load_backends} is
   * called for the first time. If it isn't called explicitly,
   * {@link BackendStore.load_backends} will call it.
   *
   * This method is safe to call multiple times concurrently (e.g. an
   * asynchronous call may begin between a subsequent asynchronous call
   * beginning and finishing).
   *
   * @since 0.3.0
   */
  public async void prepare ()
    {
      Internal.profiling_start ("preparing BackendStore");

      /* (re-)load the list of disabled backends */
      yield this._load_disabled_backend_names ();

      if (this._is_prepared == false)
        {
          this._is_prepared = true;
          this.notify_property ("is-prepared");
        }

      Internal.profiling_end ("preparing BackendStore");
    }

  /**
   * Find, load, and prepare all backends which are not disabled.
   *
   * Backends will be searched for in the path given by the
   * ``FOLKS_BACKEND_PATH`` environment variable, if it's set. If it's not set,
   * backends will be searched for in a path set at compilation time.
   *
   * This method is not safe to call multiple times concurrently.
   *
   * @throws GLib.Error currently unused
   */
  public async void load_backends () throws GLib.Error
    {
      assert (Module.supported());

      Internal.profiling_start ("loading backends in BackendStore");

      yield this.prepare ();

      /* unload backends that have been disabled since they were loaded */
      foreach (var backend_existing in this._backend_hash.values)
        {
          yield this._backend_unload_if_needed (backend_existing);
        }

      Internal.profiling_point ("unloaded backends in BackendStore");

      string? _path = Environment.get_variable ("FOLKS_BACKEND_PATH");
      string path;

      if (_path == null)
        {
          path = BuildConf.BACKEND_DIR;

          debug ("Using built-in backend dir '%s' (override with " +
              "environment variable FOLKS_BACKEND_PATH)", path);
        }
      else
        {
          path = (!) _path;

          debug ("Using environment variable FOLKS_BACKEND_PATH = " +
              "'%s' to look for backends", path);
        }

      var modules = new HashMap<string, File> ();
      var path_split = path.split (":");
      foreach (unowned string subpath in path_split)
        {
          var file = File.new_for_path (subpath);

          bool is_file;
          bool is_dir;
          yield BackendStore._get_file_info (file, out is_file, out is_dir);
          if (is_file)
            {
              modules.set (subpath, file);
            }
          else if (is_dir)
            {
              var cur_modules = yield this._get_modules_from_dir (file);
              if (cur_modules != null)
                {
                  foreach (var entry in ((!) cur_modules).entries)
                    {
                      modules.set (entry.key, entry.value);
                    }
                }
            }
          else
            {
              critical ("FOLKS_BACKEND_PATH component '%s' is not a regular " +
                  "file or directory; ignoring...",
                  subpath);
              assert_not_reached ();
            }
        }

      Internal.profiling_point ("found modules in BackendStore");

      /* this will load any new modules found in the backends dir and will
       * prepare and unprepare backends such that they match the state in the
       * backend store key file */
      foreach (var module in modules.values)
        this._load_module_from_file (module);

      Internal.profiling_point ("loaded modules in BackendStore");

      /* this is populated indirectly from _load_module_from_file(), above */
      var backends_remaining = 1;
      foreach (var backend in this._backend_hash.values)
        {
          backends_remaining++;
          this._backend_load_if_needed.begin (backend, (o, r) =>
            {
              this._backend_load_if_needed.end (r);
              backends_remaining--;

              if (backends_remaining == 0)
                {
                  this.load_backends.callback ();
                }
            });
        }
      backends_remaining--;
      if (backends_remaining > 0)
        {
          yield;
        }

      Internal.profiling_end ("loading backends in BackendStore");
    }

  /* This method is not safe to call multiple times concurrently, since there's
   * a race in updating this._prepared_backends. */
  private async void _backend_load_if_needed (Backend backend)
    {
      if (this._backend_is_enabled (backend.name))
        {
          if (!this._prepared_backends.has_key (backend.name))
            {
              try
                {
                  yield backend.prepare ();

                  debug ("New backend '%s' prepared", backend.name);
                  this._prepared_backends.set (backend.name, backend);
                  this.backend_available (backend);
                }
              catch (GLib.Error e)
                {
                  if (e is DBusError.SERVICE_UNKNOWN)
                    {
                      /* Don’t warn if a D-Bus service is unknown; it probably
                       * means the backend is deliberately not running and the
                       * user is running folks from git, so hasn’t appropriately
                       * enabled/disabled backends from building. */
                      debug ("Error preparing Backend '%s': %s",
                          backend.name, e.message);
                    }
                  else
                    {
                      warning ("Error preparing Backend '%s': %s",
                          backend.name, e.message);
                    }
                }
            }
        }
    }

  /* This method is not safe to call multiple times concurrently, since there's
   * a race in updating this._prepared_backends. */
  private async bool _backend_unload_if_needed (Backend backend)
    {
      var unloaded = false;

      if (!this._backend_is_enabled (backend.name))
        {
          Backend? backend_existing = this._backend_hash.get (backend.name);
          if (backend_existing != null)
            {
              try
                {
                  yield ((!) backend_existing).unprepare ();
                }
              catch (GLib.Error e)
                {
                  warning ("Error unpreparing Backend '%s': %s", backend.name,
                      e.message);
                }

              this._prepared_backends.unset (((!) backend_existing).name);

              unloaded = true;
            }
        }

      return unloaded;
    }

  /**
   * Add a new {@link Backend} to the BackendStore.
   *
   * @param backend the {@link Backend} to add
   */
  public void add_backend (Backend backend)
    {
      /* Purge any other backend with the same name; re-add if enabled */
      Backend? backend_existing = this._backend_hash.get (backend.name);
      if (backend_existing != null && backend_existing != backend)
        {
          ((!) backend_existing).unprepare.begin ();
          this._prepared_backends.unset (((!) backend_existing).name);
        }

      this._debug._register_domain (backend.name);

      this._backend_hash.set (backend.name, backend);
    }

  private bool _backend_is_enabled (string name)
    {
      var all_others_enabled = true;

      if (this._backends_allowed != null &&
          !(name in (!) this._backends_allowed))
        return false;

      if (this._backends_disabled != null &&
          name in (!) this._backends_disabled)
        return false;

      try
        {
          all_others_enabled = this._backends_key_file.get_boolean (
              BackendStore.KEY_FILE_GROUP_ALL_OTHERS, "enabled");
        }
      catch (KeyFileError e)
        {
          if (!(e is KeyFileError.GROUP_NOT_FOUND) &&
              !(e is KeyFileError.KEY_NOT_FOUND))
            {
              warning ("Couldn't determine whether to enable or disable " +
                  "backends not listed in backend key file. Defaulting to %s.",
                  all_others_enabled ? "enabled" : "disabled");
            }
          else
            {
              debug ("No catch-all entry in the backend key file. %s " +
                  "unlisted backends.",
                  all_others_enabled ? "Enabling" : "Disabling");
            }

          /* fall back to the default in case of any level of failure */
        }

      var enabled = true;
      try
        {
          enabled = this._backends_key_file.get_boolean (name, "enabled");
        }
      catch (KeyFileError e)
        {
          /* if there's no entry for this backend, use the default set above */
          if ((e is KeyFileError.GROUP_NOT_FOUND) ||
              (e is KeyFileError.KEY_NOT_FOUND))
            {
              debug ("Found no entry for backend '%s'.enabled in backend " +
                  "keyfile. %s according to '%s' setting.",
                  name,
                  all_others_enabled ? "Enabling" : "Disabling",
                  BackendStore.KEY_FILE_GROUP_ALL_OTHERS);
              enabled = all_others_enabled;
            }
          else if (!(e is KeyFileError.GROUP_NOT_FOUND) &&
              !(e is KeyFileError.KEY_NOT_FOUND))
            {
              warning ("Couldn't check enabled state of backend '%s': %s\n" +
                  "Disabling backend.",
                  name, e.message);
              enabled = false;
            }
        }

      return enabled;
    }

  /**
   * Get a backend from the store by name. If a backend is returned, its
   * reference count is increased.
   *
   * @param name the backend name to retrieve
   * @return the backend, or ``null`` if none could be found
   *
   * @since 0.3.5
   */
  public Backend? dup_backend_by_name (string name)
    {
      return this._backend_hash.get (name);
    }

  /**
   * List the currently loaded backends.
   *
   * @return a list of the backends currently in the BackendStore
   */
  public Collection<Backend> list_backends ()
    {
      return this._backend_hash.values.read_only_view;
    }

  /**
   * Enable a backend.
   *
   * Mark a backend as enabled, such that the BackendStore will always attempt
   * to load it when {@link BackendStore.load_backends} is called. This will
   * not load the backend if it's not currently loaded.
   *
   * This method is safe to call multiple times concurrently (e.g. an
   * asynchronous call may begin after a previous asynchronous call for the same
   * backend name has begun and before it has finished).
   *
   * If the backend is disallowed by the FOLKS_BACKENDS_ALLOWED
   * and/or FOLKS_BACKENDS_DISABLED environment variables, this method
   * will store the fact that it should be enabled in future, but will
   * not enable it during this application run.
   *
   * @param name the name of the backend to enable
   * @since 0.3.2
   */
  public async void enable_backend (string name)
    {
      this._backends_key_file.set_boolean (name, "enabled", true);
      yield this._save_key_file ();
    }

  /**
   * Disable a backend.
   *
   * Mark a backend as disabled, such that it won't be loaded even when the
   * client application is restarted. This will not remove the backend if it's
   * already loaded.
   *
   * This method is safe to call multiple times concurrently (e.g. an
   * asynchronous call may begin after a previous asynchronous call for the same
   * backend name has begun and before it has finished).
   *
   * @param name the name of the backend to disable
   * @since 0.3.2
   */
  public async void disable_backend (string name)
    {
      this._backends_key_file.set_boolean (name, "enabled", false);
      yield this._save_key_file ();
    }

  /* This method is safe to call multiple times concurrently. */
  private async HashMap<string, File>? _get_modules_from_dir (File dir)
    {
      debug ("Searching for modules in folder '%s' ..", dir.get_path ());

      var attributes =
          FileAttribute.STANDARD_NAME + "," +
          FileAttribute.STANDARD_TYPE + "," +
          FileAttribute.STANDARD_IS_SYMLINK + "," +
          FileAttribute.STANDARD_SYMLINK_TARGET + "," +
          FileAttribute.STANDARD_CONTENT_TYPE;

      GLib.List<FileInfo> infos;
      try
        {
          FileEnumerator enumerator =
            yield dir.enumerate_children_async (attributes,
                FileQueryInfoFlags.NONE, Priority.DEFAULT, null);

          infos = yield enumerator.next_files_async (int.MAX,
              Priority.DEFAULT, null);
        }
      catch (Error error)
        {
          /* Translators: the first parameter is a folder path and the second
           * is an error message. */
          critical (_("Error listing contents of folder ‘%s’: %s"),
              dir.get_path (), error.message);

          return null;
        }

      var modules_final = new HashMap<string, File> ();

      string? _path = Environment.get_variable ("FOLKS_BACKEND_PATH");
      foreach (var info in infos)
        {
          var file = dir.get_child (info.get_name ());

          /* Handle symlinks by derefencing them. If we look at two symlinks
           * with the same target, we don’t end up loading that backend twice
           * due to hashing the backend’s absolute path in @modules_final.
           *
           * We can’t just ignore symlinks due to the way Tinycorelinux installs
           * software: /usr/local/lib/folks/41/backends/bluez/bluez.so is a
           * symlink to
           * /tmp/tcloop/folks/usr/local/lib/folks/41/backends/bluez/bluez.so,
           * a loopback squashfs mount of the folks file system. Ignoring
           * symlinks means we would never load backends in that environment. */
          if (info.get_is_symlink ())
            {
              debug ("Handling symlink ‘%s’ to ‘%s’.",
                  file.get_path (), info.get_symlink_target ());

              var old_file = file;
              file = dir.resolve_relative_path (info.get_symlink_target ());

              try
                {
                  info =
                      yield file.query_info_async (attributes,
                          FileQueryInfoFlags.NONE);
                }
              catch (Error error)
                {
                  /* Translators: the first parameter is a folder path and the second
                   * is an error message. */
                  warning (_("Error querying info for target ‘%s’ of symlink ‘%s’: %s"),
                      file.get_path (), old_file.get_path (), error.message);

                  continue;
                }
            }

          /* Handle proper files. */
          var file_type = info.get_file_type ();
          unowned string content_type = info.get_content_type ();

          string? mime = ContentType.get_mime_type (content_type);

          if (file_type == FileType.DIRECTORY)
            {
              var modules = yield this._get_modules_from_dir (file);
              if (modules != null)
                {
                  foreach (var entry in ((!) modules).entries)
                    {
                      modules_final.set (entry.key, entry.value);
                    }
                }
            }
          else if (mime == "application/x-sharedlib")
            {
              var path = file.get_path ();
              if (path != null)
                {
                  modules_final.set ((!) path, file);
                }
            }
          else if (mime == null)
            {
              warning (
                  "The content type of '%s' could not be determined. Have you installed shared-mime-info?",
                  file.get_path ());
            }
          /*
           * We should have only .la .so and sub-directories, except if FOLKS_BACKEND_PATH is set.
           * Then we will run into all kinds of files.
           */
          else if (_path == null &&
                   mime != "application/x-sharedlib" &&
                   mime != "application/x-shared-library-la" &&
                   mime != "inode/directory")
            {
              warning ("The content type of '%s' appears to be '%s' which looks suspicious. Have you installed shared-mime-info?", file.get_path (), mime);
            }
        }

      debug ("Finished searching for modules in folder '%s'",
          dir.get_path ());

      return modules_final;
    }

  private void _load_module_from_file (File file)
    {
      var _file_path = file.get_path ();
      if (_file_path == null)
        {
          return;
        }
      var file_path = (!) _file_path;

      if (this._modules.has_key (file_path))
        return;

      var _module = Module.open (file_path, ModuleFlags.BIND_LOCAL);
      if (_module == null)
        {
          warning ("Failed to load module from path '%s': %s",
                    file_path, Module.error ());

          return;
        }
      unowned Module module = (!) _module;

      void* function;

      /* this causes the module to call add_backend() for its backends (adding
       * them to the backend hash); any backends that already existed will be
       * removed if they've since been disabled */
      if (!module.symbol("module_init", out function))
        {
          warning ("Failed to find entry point function '%s' in '%s': %s",
                    "module_init",
                    file_path,
                    Module.error ());

          return;
        }

      ModuleInitFunc module_init = (ModuleInitFunc) function;
      assert (module_init != null);

      this._modules.set (file_path, module);

      /* We don't want our modules to ever unload */
      module.make_resident ();

      module_init (this);

      debug ("Loaded module source: '%s'", module.name ());
    }

  /* This method is safe to call multiple times concurrently. */
  private async static void _get_file_info (File file,
      out bool is_file,
      out bool is_dir)
    {
      FileInfo file_info;
      is_file = false;
      is_dir = false;

      try
        {
          /* Query for the MIME type; if the file doesn't exist, we'll get an
           * appropriate error back, so this also checks for existence. */
          file_info = yield file.query_info_async (FileAttribute.STANDARD_TYPE,
              FileQueryInfoFlags.NONE, Priority.DEFAULT, null);
        }
      catch (Error error)
        {
          if (error is IOError.NOT_FOUND)
            {
              /* Translators: the parameter is a filename. */
              critical (_("File or directory ‘%s’ does not exist."),
                  file.get_path ());
            }
          else
            {
              /* Translators: the parameter is a filename. */
              critical (_("Failed to get content type for ‘%s’."),
                  file.get_path ());
            }

          return;
        }

      is_file = (file_info.get_file_type () == FileType.REGULAR);
      is_dir = (file_info.get_file_type () == FileType.DIRECTORY);
    }

  /* This method is safe to call multiple times concurrently. */
  private async void _load_disabled_backend_names ()
    {
      /* If set, this is a list of allowed backends. No others can be enabled,
       * even if the keyfile says they ought to be.
       * The default is equivalent to "all", which allows any backend.
       *
       * Regression tests and benchmarks can use this to restrict themselves
       * to a small set of backends for which they have done the necessary
       * setup/configuration/sandboxing. */
      var envvar = Environment.get_variable ("FOLKS_BACKENDS_ALLOWED");

      if (envvar != null)
        {
          /* Allow space, comma or colon separation, consistent with
           * g_parse_debug_string(). */
          var tokens = envvar.split_set (" ,:");

          this._backends_allowed = new SmallSet<string> ();

          foreach (unowned string s in tokens)
            {
              if (s == "all")
                {
                  this._backends_allowed = null;
                  break;
                }

              if (s != "")
                this._backends_allowed.add (s);
            }

          if (this._backends_allowed != null)
            {
              debug ("Backends limited by FOLKS_BACKENDS_ALLOWED:");

              foreach (unowned string s in tokens)
                debug ("Backend '%s' is allowed", s);

              debug ("All other backends disabled by FOLKS_BACKENDS_ALLOWED");
            }
        }

      /* If set, this is a list of disallowed backends.
       * They are not enabled, even if the keyfile says they ought to be. */
      envvar = Environment.get_variable ("FOLKS_BACKENDS_DISABLED");

      if (envvar != null)
        {
          var tokens = envvar.split_set (" ,:");

          this._backends_disabled = new SmallSet<string> ();

          foreach (unowned string s in tokens)
            {
              if (s != "")
                {
                  debug ("Backend '%s' disabled by FOLKS_BACKENDS_DISABLED", s);
                  this._backends_disabled.add (s);
                }
            }
        }

      File file;
      unowned string? path = Environment.get_variable (
          "FOLKS_BACKEND_STORE_KEY_FILE_PATH");
      if (path == null)
        {
          file = File.new_for_path (Environment.get_user_data_dir ());
          file = file.get_child ("folks");
          file = file.get_child ("backends.ini");

          debug ("Using built-in backends key file '%s' (override with " +
              "environment variable FOLKS_BACKEND_STORE_KEY_FILE_PATH)",
              file.get_path ());
        }
      else
        {
          file = File.new_for_path ((!) path);
          debug ("Using environment variable " +
              "FOLKS_BACKEND_STORE_KEY_FILE_PATH = '%s' to load the backends " +
              "key file.", (!) path);
        }

      this._config_file = file;

      /* Load the disabled backends file */
      var key_file = new GLib.KeyFile ();
      try
        {
          uint8[] contents;

          yield file.load_contents_async (null, out contents, null);
          unowned string contents_s = (string) contents;

          if (contents_s.length > 0)
            {
              key_file.load_from_data (contents_s,
                  contents_s.length, KeyFileFlags.KEEP_COMMENTS);
            }
        }
      catch (Error e1)
        {
          if (!(e1 is IOError.NOT_FOUND))
            {
              warning ("The backends key file '%s' could not be loaded: %s",
                  file.get_path (), e1.message);
              return;
            }
        }
      finally
        {
          /* Update the key file in memory, whether the new one is empty or
           * full. */
          this._backends_key_file = (owned) key_file;
        }
    }

  /* This method is safe to call multiple times concurrently. */
  private async void _save_key_file ()
    {
      var key_file_data = this._backends_key_file.to_data ();

      debug ("Saving backend key file '%s'.", this._config_file.get_path ());

      try
        {
          /* Note: We have to use key_file_data.size () here to get its length
           * in _bytes_ rather than _characters_. bgo#628930.
           * In Vala >= 0.11, string.size() has been deprecated in favour of
           * string.length (which now returns the byte length, whereas in
           * Vala <= 0.10, it returned the character length). FIXME: We need to
           * take this into account until we depend explicitly on
           * Vala >= 0.11. */
          yield this._config_file.replace_contents_async (key_file_data.data,
              null, false, FileCreateFlags.PRIVATE,
              null, null);
        }
      catch (Error e)
        {
          warning ("Could not write updated backend key file '%s': %s",
              this._config_file.get_path (), e.message);
        }
    }
}
