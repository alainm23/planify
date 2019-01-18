/*
 * Copyright (C) 2011 Collabora Ltd.
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
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * A generic abstract cache for sets of objects. This can be used by subclasses
 * to implement caching of homogeneous sets of objects. Subclasses simply have
 * to implement serialisation and deserialisation of the objects to and from
 * {@link GLib.Variant}s.
 *
 * It's intended that this class be used for providing caching layers for
 * {@link PersonaStore}s, for example.
 *
 * @since 0.6.0
 */
public abstract class Folks.ObjectCache<T> : Object
{
  /* The version number of the header/wrapper for a cache file. When accompanied
   * by a version number for the serialised object type, this unambiguously
   * keys the variant type describing an entire cache file.
   *
   * The wrapper and object version numbers are stored as the first two bytes
   * of a cache file. They can't be stored as part of the Variant which forms
   * the rest of the file, as to interpret the Variant its entire type has to
   * be known — which depends on the version numbers. */
  private const uint8 _FILE_FORMAT_VERSION = 1;

  /* The length of the version header at the beginning of the file. This has
   * to be a multiple of 8 to keep Variant's alignment code happy.
   * As documented above, currently only the first two bytes of this header
   * are used (for version numbers). */
  private const size_t _HEADER_WIDTH = 8; /* bytes */

  private File _cache_directory;
  private File _cache_file;
  private string _cache_file_path; /* save calls to _cache_file.get_path() */

  /**
   * Get the {@link GLib.VariantType} of the serialised form of an object stored
   * in this cache.
   *
   * If a smooth upgrade path is needed in future due to cache file format
   * changes, this may be modified to take a version parameter.
   *
   * @param object_version the version of the object format to use, or
   * ``uint8.MAX`` for the latest version
   * @return variant type for that object version, or ``null`` if the version is
   * unsupported
   * @since 0.6.0
   */
  protected abstract VariantType? get_serialised_object_type (
      uint8 object_version);

  /**
   * Get the version of the variant type returned by
   * {@link ObjectCache.get_serialised_object_type}. This must be incremented
   * every time the variant type changes so that old cache files aren't
   * misinterpreted.
   *
   * @since 0.6.0
   */
  protected abstract uint8 get_serialised_object_version ();

  /**
   * Serialise the given ``object`` to a {@link GLib.Variant} and return the
   * variant. The variant must be of the type returned by
   * {@link ObjectCache.get_serialised_object_type}.
   *
   * @param object the object to serialise
   * @return serialised form of ``object``
   *
   * @since 0.6.0
   */
  protected abstract Variant serialise_object (T object);

  /**
   * Deserialise the given ``variant`` to a new instance of an object. The
   * variant is guaranteed to have the type returned by
   * {@link ObjectCache.get_serialised_object_type}.
   *
   * @param variant the serialised form to deserialise
   * @param object_version the version of the object format to deserialise from
   * @return the deserialised object
   *
   * @since 0.6.0
   */
  protected abstract T deserialise_object (Variant variant,
      uint8 object_version);

  /**
   * A string identifying the type of object being cached.
   *
   * This has to be suitable for use as a directory name; i.e. lower case,
   * hyphen-separated tokens.
   *
   * @since 0.6.6
   */
  public string type_id { get; construct; }

  /**
   * A string identifying the particular cache instance.
   *
   * This will form the file name of the cache file, but will be escaped
   * beforehand, so can be an arbitrary non-empty string.
   *
   * @since 0.6.6
   */
  public string id
    {
      get { return this._id; }
      construct { assert (value != ""); this._id = value; }
    }
  private string _id;

  /**
   * Create a new cache instance using the given type ID and ID. This is
   * protected as the ``type_id`` will typically be set statically by
   * subclasses.
   *
   * @param type_id A string identifying the type of object being cached. This
   * has to be suitable for use as a directory name; i.e. lower case,
   * hyphen-separated.
   * @param id A string identifying the particular cache instance. This will
   * form the file name of the cache file, but will be escaped beforehand, so
   * can be an arbitrary non-empty string.
   * @return A new cache instance
   *
   * @since 0.6.0
   */
  protected ObjectCache (string type_id, string id)
    {
      Object (type_id: type_id,
              id: id);
    }

  construct
    {
      debug ("Creating object cache for type ID '%s' with ID '%s'.",
          this.type_id, this.id);

      this._cache_directory =
          File.new_for_path (Environment.get_user_cache_dir ())
              .get_child ("folks")
              .get_child (this.type_id);
      this._cache_file =
          this._cache_directory.get_child (Uri.escape_string (this.id,
              "", false));
      var path = this._cache_file.get_path ();
      this._cache_file_path = (path != null) ? (!) path : "(null)";
    }

  /**
   * Load a set of objects from the cache and return them as a new set. If the
   * cache file doesn't exist, ``null`` will be returned. An empty set will be
   * returned if the cache file existed but was empty (i.e. was stored with
   * an empty set originally).
   *
   * Loading the objects can be cancelled using ``cancellable``. If it is,
   * ``null`` will be returned.
   *
   * If any errors are encountered while loading the objects, warnings will be
   * logged as appropriate and ``null`` will be returned.
   *
   * This method is safe to call multiple times concurrently.
   *
   * @param cancellable A {@link GLib.Cancellable} for the operation, or
   * ``null``.
   * @return A set of objects from the cache, or ``null``.
   *
   * @since 0.6.0
   */
  public async Set<T>? load_objects (Cancellable? cancellable = null)
    {
      debug ("Loading cache (type ID '%s', ID '%s') from file '%s'.",
          this.type_id, this._id, this._cache_file_path);

      // Read in the file
      uint8[] data;

      try
        {
          yield this._cache_file.load_contents_async (cancellable, out data, null);
        }
      catch (Error e)
        {
          if (e is IOError.CANCELLED)
            {
              /* not a true error */
            }
          else if (e is IOError.NOT_FOUND)
            {
              debug ("Couldn't load cache file '%s': %s",
                  this._cache_file_path, e.message);
            }
          else
            {
              warning ("Couldn't load cache file '%s': %s",
                  this._cache_file_path, e.message);
            }

          return null;
        }

      // Check the length
      if (data.length < ObjectCache._HEADER_WIDTH)
        {
          warning ("Cache file '%s' was too small. The file was deleted.",
              this._cache_file_path);
          yield this.clear_cache ();

          return null;
        }

      // Check the version
      var wrapper_version = data[0];
      var object_version = data[1];

      if (wrapper_version != ObjectCache._FILE_FORMAT_VERSION)
        {
          warning ("Cache file '%s' was version %u of the file format, " +
              "but only version %u is supported. The file was deleted.",
              this._cache_file_path, wrapper_version,
              ObjectCache._FILE_FORMAT_VERSION);
          yield this.clear_cache ();

          return null;
        }

      unowned uint8[] variant_data = data[ObjectCache._HEADER_WIDTH:data.length];

      // Deserialise the variant according to the given version numbers
      var _variant_type =
          this._get_cache_file_variant_type (wrapper_version, object_version);

      if (_variant_type == null)
        {
          warning ("Cache file '%s' was version %u of the object file " +
              "format, which is not supported. The file was deleted.",
              this._cache_file_path, object_version);
          yield this.clear_cache ();

          return null;
        }
      var variant_type = (!) _variant_type;

      var variant =
          Variant.new_from_data<uint8[]> (variant_type, variant_data, false,
              data);

      // Check the variant was deserialised correctly
      if (variant.is_normal_form () == false)
        {
          warning ("Cache file '%s' was corrupt and was deleted.",
              this._cache_file_path);
          yield this.clear_cache ();

          return null;
        }

      // Unpack the stored data
      var type_id = variant.get_child_value (0).get_string ();

      if (type_id != this.type_id)
        {
          warning ("Cache file '%s' had type ID '%s', but '%s' was expected." +
              "The file was deleted.", this._cache_file_path, type_id,
              this.type_id);
          yield this.clear_cache ();

          return null;
        }

      var id = variant.get_child_value (1).get_string ();

      if (id != this._id)
        {
          warning ("Cache file '%s' had ID '%s', but '%s' was expected." +
              "The file was deleted.", this._cache_file_path, id,
              this._id);
          yield this.clear_cache ();

          return null;
        }

      var objects_variant = variant.get_child_value (2);

      var objects = new HashSet<T> ();

      for (uint i = 0; i < objects_variant.n_children (); i++)
        {
          var object_variant = objects_variant.get_child_value (i);
          var object = this.deserialise_object (object_variant, object_version);

          objects.add (object);
        }

      return objects;
    }

  /**
   * Store a set of objects to the cache file, overwriting any existing set of
   * objects in the cache, or creating the cache file from scratch if it didn't
   * previously exist.
   *
   * Storing the objects can be cancelled using ``cancellable``. If it is, the
   * cache will be left in a consistent state, but may be storing the old set
   * of objects or the new set.
   *
   * This method is safe to call multiple times concurrently.
   *
   * @param objects A set of objects to store. This may be empty, but may not
   * be ``null``.
   * @param cancellable A {@link GLib.Cancellable} for the operation, or
   * ``null``.
   *
   * @since 0.6.0
   */
  public async void store_objects (Set<T> objects,
      Cancellable? cancellable = null)
    {
      debug ("Storing cache (type ID '%s', ID '%s') to file '%s'.",
          this.type_id, this._id, this._cache_file_path);

      var child_type = this.get_serialised_object_type (uint8.MAX);
      assert (child_type != null); // uint8.MAX should always be supported
      Variant[] children = new Variant[objects.size];

      // Serialise all the objects in the set
      uint i = 0;
      foreach (var object in objects)
        {
          children[i++] = this.serialise_object (object);
        }

      // File format
      var wrapper_version = ObjectCache._FILE_FORMAT_VERSION;
      var object_version = this.get_serialised_object_version ();

      var variant = new Variant.tuple ({
        new Variant.string (this.type_id), // Type ID
        new Variant.string (this._id), // ID
        new Variant.array (child_type, children) // Array of objects
      });

      var desired_variant_type =
          this._get_cache_file_variant_type (wrapper_version, object_version);
      assert (desired_variant_type != null &&
          variant.get_type ().equal ((!) desired_variant_type));

      // Prepend the version numbers to the data
      uint8[] data = new uint8[ObjectCache._HEADER_WIDTH + variant.get_size ()];
      data[0] = wrapper_version;
      data[1] = object_version;
      variant.store (data[ObjectCache._HEADER_WIDTH:data.length]);

      // Write the data out to the file
      while (true)
        {
          try
            {
              /* We assume that replace_contents_async() is atomic. */
              yield this._cache_file.replace_contents_async (
                  data, null, false,
                  FileCreateFlags.PRIVATE, cancellable, null);
              break;
            }
          catch (Error e)
            {
              if (e is IOError.NOT_FOUND)
                {
                  try
                    {
                      yield this._create_cache_directory ();
                      continue;
                    }
                  catch (Error e2)
                    {
                      warning ("Couldn't create cache directory '%s': %s",
                          this._cache_directory.get_path (), e.message);
                      return;
                    }
                }
              else if (e is IOError.CANCELLED)
                {
                  /* We assume the replace_contents_async() call is atomic,
                   * so cancelling it is atomic as well. */
                  return;
                }

              /* Print a warning and delete the cache file so we don't leave
               * stale cached objects lying around. */
              warning ("Couldn't write to cache file '%s', so deleting it: %s",
                  this._cache_file_path, e.message);
              yield this.clear_cache ();

              return;
            }
        }
    }

  /**
   * Clear this cache object, deleting its backing file.
   *
   * @since 0.6.0
   */
  public async void clear_cache ()
    {
      debug ("Clearing cache (type ID '%s', ID '%s'); deleting file '%s'.",
          this.type_id, this._id, this._cache_file_path);

      try
        {
          this._cache_file.delete ();
        }
      catch (Error e)
        {
          // Ignore errors
        }
    }

  private VariantType? _get_cache_file_variant_type (uint8 wrapper_version,
      uint8 object_version)
    {
      var _object_type = this.get_serialised_object_type (object_version);

      if (_object_type == null)
        {
          // Unsupported version
          return null;
        }
      var object_type = (!) _object_type;

      return new VariantType.tuple ({
        VariantType.STRING, // Type ID
        VariantType.STRING, // ID
        new VariantType.array (object_type) // Objects
      });
    }

  private async void _create_cache_directory () throws Error
    {
      try
        {
          this._cache_directory.make_directory_with_parents ();
        }
      catch (Error e)
        {
          // Ignore errors caused by the directory existing already
          if (!(e is IOError.EXISTS))
            {
              throw e;
            }
        }
    }
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */
