/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation.
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

using Folks;

/**
 * The Telepathy backend module entry point.
 *
 * @backend_store a store to add the Telepathy backends to
 */
public void module_init (BackendStore backend_store)
{
  backend_store.add_backend (new Folks.Backends.Tp.Backend ());
}

/**
 * The Telepathy backend module exit point.
 *
 * @param backend_store the store to remove the backends from
 */
public void module_finalize (BackendStore backend_store)
{
  /* FIXME: No way to remove backends from the store. */
}
