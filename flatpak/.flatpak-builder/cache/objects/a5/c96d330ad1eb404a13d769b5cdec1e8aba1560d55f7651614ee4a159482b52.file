/*
 * tp-handle-repo-static.h - mechanism to store and retrieve handles on
 * a connection - implementation for static list of supported handle
 * types (currently used for LIST handles)
 *
 * Copyright (C) 2005, 2007 Collabora Ltd.
 * Copyright (C) 2005, 2007 Nokia Corp.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_HANDLE_REPO_STATIC_H__
#define __TP_HANDLE_REPO_STATIC_H__

#include <telepathy-glib/handle-repo.h>

G_BEGIN_DECLS


/**
 * TpStaticHandleRepo:
 *
 * A static handle repository contains a fixed set of handles.
 *
 * As well as setting the #TpHandleRepoIface:handle-type property, code
 * which creates a static handle repository must set the
 * #TpStaticHandleRepo:handle-names construction property to a strv of
 * valid handle names. All of these are preallocated; no more may be
 * created, and attempts to do so will fail.
 *
 * Handles in this repository are 1 more than the index in the string
 * vector of the handle's name, so the first name in the vector has
 * handle 1 and so on. Connection managers which use a static repository
 * may assume this to be true, and use an enumeration starting at 1, in the
 * same order as the string vector, to avoid having to look up handles
 * internally.
 *
 * This is intended for handles of type %TP_HANDLE_TYPE_LIST,
 * for which the connection manager should only accept a static list of
 * supported handle names.
 *
 * All structure fields are private.
 */

typedef struct _TpStaticHandleRepo TpStaticHandleRepo;

/**
 * TpStaticHandleRepoClass:
 *
 * The class of a TpStaticHandleRepo. All fields are private.
 */

typedef struct _TpStaticHandleRepoClass TpStaticHandleRepoClass;
GType tp_static_handle_repo_get_type (void);

#define TP_TYPE_STATIC_HANDLE_REPO \
  (tp_static_handle_repo_get_type ())
#define TP_STATIC_HANDLE_REPO(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_STATIC_HANDLE_REPO,\
  TpStaticHandleRepo))
#define TP_STATIC_HANDLE_REPO_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_STATIC_HANDLE_REPO,\
  TpStaticHandleRepo))
#define TP_IS_STATIC_HANDLE_REPO(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_STATIC_HANDLE_REPO))
#define TP_IS_STATIC_HANDLE_REPO_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_STATIC_HANDLE_REPO))
#define TP_STATIC_HANDLE_REPO_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_STATIC_HANDLE_REPO,\
  TpStaticHandleRepoClass))

/**
 * tp_static_handle_repo_new:
 * @handle_type: The type of handle to store in the
 *  new repository
 * @handle_names: Same as #TpStaticHandleRepo:handle-names
 *
 * <!---->
 *
 * Returns: a new static handle repository
 */
static inline
/* spacer so gtkdoc documents this function as though not static */
TpHandleRepoIface *tp_static_handle_repo_new (TpHandleType handle_type,
    const gchar **handle_names);

static inline TpHandleRepoIface *
tp_static_handle_repo_new (TpHandleType handle_type,
                           const gchar **handle_names)
{
  return (TpHandleRepoIface *) g_object_new (TP_TYPE_STATIC_HANDLE_REPO,
      "handle-type", (guint)handle_type,
      "handle-names", handle_names,
      NULL);
}

G_END_DECLS

#endif

