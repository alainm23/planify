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

/**
 * A singleton persistent cache for avatars in folks.
 *
 * Avatars may be added to the cache, and referred to by a persistent
 * URI from that point onwards. The avatars will be stored on disk in the user's
 * XDG cache directory.
 *
 * The avatar cache is typically used by backends where retrieving avatars is an
 * expensive operation (for example, they have to be downloaded from the network
 * every time they're used).
 *
 * All avatars from all users of the {@link Folks.AvatarCache} are stored in the
 * same namespace, so callers must ensure that the IDs they use for avatars are
 * globally unique (e.g. by using the corresponding {@link Folks.Persona.uid}).
 *
 * Ongoing store operations ({@link Folks.AvatarCache.store_avatar}) are rate
 * limited to try and prevent file descriptor exhaustion. Load operations
 * ({@link Folks.AvatarCache.load_avatar}) must be rate limited by the client,
 * as the file I/O occurs when calling {@link GLib.LoadableIcon.load} rather
 * than when retrieving the {@link GLib.LoadableIcon} from the cache.
 *
 * @since 0.6.0
 */
public class Folks.AvatarCache : Object
{
  private static weak AvatarCache? _instance = null; /* needs to be locked */
  private File _cache_directory;
  private uint _n_ongoing_stores = 0;
  private Queue<DelegateWrapper> _pending_stores =
      new Queue<DelegateWrapper> ();
  private const uint _max_n_ongoing_stores = 10;

  /**
   * Private constructor for an instance of the avatar cache. The singleton
   * instance should be retrieved by calling {@link AvatarCache.dup()} instead.
   *
   * @since 0.6.0
   */
  private AvatarCache ()
    {
      Object ();
    }

  construct
    {
      this._cache_directory =
          File.new_for_path (Environment.get_user_cache_dir ())
              .get_child ("folks")
              .get_child ("avatars");
    }

  /**
   * Create or return the singleton {@link Folks.AvatarCache} class instance.
   * If the instance doesn't exist already, it will be created.
   *
   * This function is thread-safe.
   *
   * @return Singleton {@link Folks.AvatarCache} instance
   * @since 0.6.0
   */
  public static AvatarCache dup ()
    {
      var _retval = AvatarCache._instance;
      AvatarCache retval;

      if (_retval == null)
        {
          /* use an intermediate variable to force a strong reference */
          retval = new AvatarCache ();
          AvatarCache._instance = retval;
        }
      else
        {
          retval = (!) _retval;
        }

      return retval;
    }

  ~AvatarCache ()
    {
      /* Manually clear the singleton _instance */
      AvatarCache._instance = null;
    }

  /**
   * Fetch an avatar from the cache by its globally unique ID.
   *
   * It is up to the caller to ensure that file I/O is rate-limited when loading
   * many avatars in parallel, by limiting calls to
   * {@link GLib.LoadableIcon.load}.
   *
   * @param id the globally unique ID for the avatar
   * @return Avatar from the cache, or ``null`` if it doesn't exist in the cache
   * @throws GLib.Error if checking for existence of the cache file failed
   * @since 0.6.0
   */
  public async LoadableIcon? load_avatar (string id) throws GLib.Error
    {
      var avatar_file = this._get_avatar_file (id);

      debug ("Loading avatar '%s' from file '%s'.", id, avatar_file.get_uri ());

      // Return null if the avatar doesn't exist
      if (avatar_file.query_exists () == false)
        {
          return null;
        }

      return new FileIcon (avatar_file);
    }

  /**
   * Store an avatar in the cache, assigning the given globally unique ID to it,
   * which can later be used to load and remove the avatar from the cache. For
   * example, this ID could be the UID of a persona. The URI of the cached
   * avatar file will be returned.
   *
   * This method may be called multiple times concurrently for the same avatar
   * ID (e.g. an asynchronous call may be made, and a subsequent asynchronous
   * call may begin before the first has finished).
   *
   * Concurrent file I/O may be rate limited within each {@link AvatarCache}
   * instance to avoid file descriptor exhaustion.
   *
   * @param id the globally unique ID for the avatar
   * @param avatar the avatar data to cache
   * @return a URI for the file storing the cached avatar
   * @throws GLib.Error if the avatar data couldn't be loaded, or if creating
   * the avatar directory or cache file failed
   * @since 0.6.0
   */
  public async string store_avatar (string id, LoadableIcon avatar)
      throws GLib.Error
    {
      string avatar_uri = "";

      if (this._n_ongoing_stores > AvatarCache._max_n_ongoing_stores)
        {
          /* Add to the pending queue. */
          var wrapper = new DelegateWrapper ();
          wrapper.cb = store_avatar.callback;
          this._pending_stores.push_tail ((owned) wrapper);
          yield;
        }

      /* Do the actual store operation. */
      try
        {
          this._n_ongoing_stores++;
          avatar_uri = yield this._store_avatar_unlimited (id, avatar);
        }
      finally
        {
          this._n_ongoing_stores--;

          /* If there is a store operation pending, resume it, FIFO-style. */
          var wrapper = this._pending_stores.pop_head ();
          if (wrapper != null)
            {
              wrapper.cb ();
            }
        }

      return avatar_uri;
    }

  private async string _store_avatar_unlimited (string id, LoadableIcon avatar)
      throws GLib.Error
    {
      var dest_avatar_file = this._get_avatar_file (id);

      debug ("Storing avatar '%s' in file '%s'.", id,
          dest_avatar_file.get_uri ());

      InputStream src_avatar_stream =
          yield avatar.load_async (-1, null, null);

      // Copy the icon data into a file
      while (true)
        {
          OutputStream? dest_avatar_stream = null;

          try
            {
              /* In order for this to be concurrency-safe, we assume that
               * replace_async() does an atomic substitution of the new file for
               * the old when the stream is closed. (i.e. It's
               * concurrency-safe). */
              dest_avatar_stream =
                  yield dest_avatar_file.replace_async (null, false,
                      FileCreateFlags.PRIVATE);
              yield ((!) dest_avatar_stream).splice_async (src_avatar_stream,
                  OutputStreamSpliceFlags.NONE);
              yield ((!) dest_avatar_stream).close_async ();

              break;
            }
          catch (GLib.Error e)
            {
              /* If the parent directory wasn't found, create it and loop
               * round to try again. */
              if (e is IOError.NOT_FOUND)
                {
                  this._create_cache_directory ();
                  continue;
                }

              if (dest_avatar_stream != null)
                {
                  yield ((!) dest_avatar_stream).close_async ();
                }

              throw e;
            }
        }

      yield src_avatar_stream.close_async ();

      return this.build_uri_for_avatar (id);
    }

  /**
   * Remove an avatar from the cache, if it exists in the cache. If the avatar
   * exists in the cache but there is a problem in removing it, a
   * {@link GLib.Error} will be thrown.
   *
   * @param id the globally unique ID for the avatar
   * @throws GLib.Error if deleting the cache file failed
   * @since 0.6.0
   */
  public async void remove_avatar (string id) throws GLib.Error
    {
      var avatar_file = this._get_avatar_file (id);

      debug ("Removing avatar '%s' in file '%s'.", id, avatar_file.get_uri ());

      try
        {
          avatar_file.delete (null);
        }
      catch (GLib.Error e)
        {
          // Ignore file not found errors
          if (!(e is IOError.NOT_FOUND))
            {
              throw e;
            }
        }
    }

  /**
   * Build the URI of an avatar file in the cache from a globally unique ID.
   * This will always succeed, even if the avatar doesn't exist in the cache.
   *
   * @param id the globally unique ID for the avatar
   * @return URI of the avatar file with the given globally unique ID
   * @since 0.6.0
   */
  public string build_uri_for_avatar (string id)
    {
      return this._get_avatar_file (id).get_uri ();
    }

  private File _get_avatar_file (string id)
    {
      var escaped_uri = Uri.escape_string (id, "", false);
      var file = this._cache_directory.get_child (escaped_uri);

      assert (file.has_parent (this._cache_directory) == true);

      return file;
    }

  private void _create_cache_directory () throws GLib.Error
    {
      try
        {
          this._cache_directory.make_directory_with_parents ();
        }
      catch (GLib.Error e)
        {
          // Ignore errors caused by the directory existing already
          if (!(e is IOError.EXISTS))
            {
              throw e;
            }
        }
    }
}

/* See: https://mail.gnome.org/archives/vala-list/2011-June/msg00005.html */
[Compact]
private class DelegateWrapper
{
  public SourceFunc cb;
}
