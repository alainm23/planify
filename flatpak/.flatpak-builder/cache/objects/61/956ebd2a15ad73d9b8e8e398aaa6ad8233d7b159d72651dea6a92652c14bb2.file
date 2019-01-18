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
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;
using TelepathyGLib;
using Folks;

private struct AccountFavourites
{
  ObjectPath account_path;
  string[] ids;
}

[DBus (name = "org.freedesktop.Telepathy.Logger.DRAFT")]
private interface LoggerIface : Object
{
  public abstract async AccountFavourites[] get_favourite_contacts ()
      throws GLib.Error;
  public abstract async void add_favourite_contact (
      ObjectPath account_path, string id) throws GLib.Error;
  public abstract async void remove_favourite_contact (
      ObjectPath account_path, string id) throws GLib.Error;

  public abstract signal void favourite_contacts_changed (
      ObjectPath account_path, string[] added, string[] removed);
}

/* See: https://mail.gnome.org/archives/vala-list/2011-June/msg00008.html */
[Compact]
private class DelegateWrapper
{
  public SourceFunc cb;
}

internal class Logger : GLib.Object
{
  private static DBusConnection _dbus_conn;
  private static LoggerIface _logger;
  private static DelegateWrapper[] _prepare_waiters = null;

  private uint _logger_watch_id;

  public signal void invalidated ();
  public signal void favourite_contacts_changed (string[] added,
      string[] removed);

  /**
   * D-Bus object path of the {@link TelepathyGLib.Account} to watch for
   * favourite contacts.
   *
   * @since 0.6.6
   */
  public string account_path { get; construct; }

  public Logger (string account_path)
    {
      Object (account_path: account_path);
    }

  ~Logger ()
    {
      /* Can only be 0 if prepare() hasn't been called. */
      if (this._logger_watch_id > 0)
        {
          Bus.unwatch_name (this._logger_watch_id);
        }
    }

  public async void prepare () throws GLib.Error
    {
      if (Logger._logger == null && Logger._prepare_waiters == null)
        {
          /* If this is the first call to prepare(), start some async calls. We
           * then yield to the main thread. Any subsequent calls to prepare()
           * will have their continuations added to the _prepare_waiters list,
           * and will be signalled once the first call returns.
           * See: https://bugzilla.gnome.org/show_bug.cgi?id=677633 */
          Logger._prepare_waiters = new DelegateWrapper[0];

          /* Create a logger proxy for favourites support */
          var dbus_conn = yield Bus.get (BusType.SESSION);
          Logger._logger = yield dbus_conn.get_proxy<LoggerIface> (
              "org.freedesktop.Telepathy.Logger",
              "/org/freedesktop/Telepathy/Logger");

          if (Logger._logger != null)
            {
              Logger._dbus_conn = dbus_conn;
            }

          /* Wake up any waiters. */
          foreach (unowned DelegateWrapper wrapper in Logger._prepare_waiters)
            {
              Idle.add ((owned) wrapper.cb);
            }

          Logger._prepare_waiters = null;
        }
      else if (Logger._logger == null && Logger._prepare_waiters != null)
        {
          /* Yield until the first ongoing prepare() call finishes. */
          var wrapper = new DelegateWrapper ();
          wrapper.cb = prepare.callback;
          Logger._prepare_waiters += (owned) wrapper;
          yield;
        }

      /* Failure? */
      if (Logger._logger == null)
        {
          this.invalidated ();
          return;
        }

      this._logger_watch_id = Bus.watch_name_on_connection (Logger._dbus_conn,
          "org.freedesktop.Telepathy.Logger", BusNameWatcherFlags.NONE,
          null, this._logger_vanished);

      Logger._logger.favourite_contacts_changed.connect ((ap, a, r) =>
        {
          if (ap != this._account_path)
            return;

          this.favourite_contacts_changed (a, r);
        });
    }

  private void _logger_vanished (DBusConnection? conn, string name)
    {
      /* The logger has vanished on the bus, so it and we are no longer valid */
      Logger._logger = null;
      Logger._dbus_conn = null;
      this.invalidated ();
    }

  public async string[] get_favourite_contacts () throws GLib.Error
    {
      /* Invalidated */
      if (Logger._logger == null)
        return {};

      /* Use an intermediate, since this._logger could disappear before this
       * async function finishes */
      var logger = Logger._logger;
      AccountFavourites[] favs = yield logger.get_favourite_contacts ();

      foreach (AccountFavourites account in favs)
        {
          /* We only want the favourites from this account */
          if (account.account_path == this._account_path)
            return account.ids;
        }

      return {};
    }

  public async void add_favourite_contact (string id) throws GLib.Error
    {
      /* Invalidated */
      if (Logger._logger == null)
        return;

      /* Use an intermediate, since this._logger could disappear before this
       * async function finishes */
      var logger = Logger._logger;
      yield logger.add_favourite_contact (
          new ObjectPath (this._account_path), id);
    }

  public async void remove_favourite_contact (string id) throws GLib.Error
    {
      /* Invalidated */
      if (Logger._logger == null)
        return;

      /* Use an intermediate, since this._logger could disappear before this
       * async function finishes */
      var logger = Logger._logger;
      yield logger.remove_favourite_contact (
          new ObjectPath (this._account_path), id);
    }
}
