/*
 * tp-handle-repo.h - handle reference-counting for connection managers
 *
 * Copyright (C) 2005,2006,2007 Collabora Ltd.
 * Copyright (C) 2005,2006,2007 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_HANDLE_REPO_H__
#define __TP_HANDLE_REPO_H__

#include <glib-object.h>

#include <gio/gio.h>

#include <telepathy-glib/intset.h>
#include <telepathy-glib/handle.h>

G_BEGIN_DECLS

/* Forward declaration to avoid circular includes */
typedef struct _TpBaseConnection TpBaseConnection;

/* Forward declaration because it's in the HandleRepo API */

#define TP_TYPE_HANDLE_SET (tp_handle_set_get_type ())
GType tp_handle_set_get_type (void);

typedef struct _TpHandleSet TpHandleSet;

/* Handle repository abstract interface */

#define TP_TYPE_HANDLE_REPO_IFACE (tp_handle_repo_iface_get_type ())

#define TP_HANDLE_REPO_IFACE(obj) \
    (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
    TP_TYPE_HANDLE_REPO_IFACE, TpHandleRepoIface))

#define TP_IS_HANDLE_REPO_IFACE(obj) \
    (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
    TP_TYPE_HANDLE_REPO_IFACE))

#define TP_HANDLE_REPO_IFACE_GET_CLASS(obj) \
    (G_TYPE_INSTANCE_GET_INTERFACE ((obj), \
    TP_TYPE_HANDLE_REPO_IFACE, TpHandleRepoIfaceClass))

/**
 * TpHandleRepoIface:
 *
 * Dummy typedef representing any implementation of this interface.
 */
typedef struct _TpHandleRepoIface TpHandleRepoIface;

/**
 * TpHandleRepoIfaceClass:
 *
 * The class of a handle repository interface. The structure layout is
 * only available within telepathy-glib, for the handle repository
 * implementations' benefit.
 */
typedef struct _TpHandleRepoIfaceClass TpHandleRepoIfaceClass;

GType tp_handle_repo_iface_get_type (void);

/* Public API for handle repositories */

gboolean tp_handle_is_valid (TpHandleRepoIface *self,
    TpHandle handle, GError **error);
gboolean tp_handles_are_valid (TpHandleRepoIface *self,
    const GArray *handles, gboolean allow_zero, GError **error);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20
TpHandle tp_handle_ref (TpHandleRepoIface *self, TpHandle handle);
_TP_DEPRECATED_IN_0_20
void tp_handles_ref (TpHandleRepoIface *self, const GArray *handles);
_TP_DEPRECATED_IN_0_20
void tp_handle_unref (TpHandleRepoIface *self, TpHandle handle);
_TP_DEPRECATED_IN_0_20
void tp_handles_unref (TpHandleRepoIface *self, const GArray *handles);

_TP_DEPRECATED_IN_0_20
gboolean tp_handle_client_hold (TpHandleRepoIface *self,
    const gchar *client, TpHandle handle, GError **error);
_TP_DEPRECATED_IN_0_20
gboolean tp_handles_client_hold (TpHandleRepoIface *self,
    const gchar *client, const GArray *handles, GError **error);
_TP_DEPRECATED_IN_0_20
gboolean tp_handle_client_release (TpHandleRepoIface *self,
    const gchar *client, TpHandle handle, GError **error);
_TP_DEPRECATED_IN_0_20
gboolean tp_handles_client_release (TpHandleRepoIface *self,
    const gchar *client, const GArray *handles, GError **error);
#endif

const char *tp_handle_inspect (TpHandleRepoIface *self,
    TpHandle handle) G_GNUC_WARN_UNUSED_RESULT;
TpHandle tp_handle_lookup (TpHandleRepoIface *self,
    const gchar *id, gpointer context, GError **error);
TpHandle tp_handle_ensure (TpHandleRepoIface *self,
    const gchar *id, gpointer context, GError **error)
    G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_20
void tp_handle_ensure_async (TpHandleRepoIface *self,
    TpBaseConnection *connection,
    const gchar *id,
    gpointer context,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_20
TpHandle tp_handle_ensure_finish (TpHandleRepoIface *self,
    GAsyncResult *result,
    GError **error);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20
void tp_handle_set_qdata (TpHandleRepoIface *repo, TpHandle handle,
    GQuark key_id, gpointer data, GDestroyNotify destroy);
_TP_DEPRECATED_IN_0_20
gpointer tp_handle_get_qdata (TpHandleRepoIface *repo, TpHandle handle,
    GQuark key_id);
#endif

/* Handle set helper class */

typedef void (*TpHandleSetMemberFunc)(TpHandleSet *set, TpHandle handle,
    gpointer userdata);

TpHandleSet * tp_handle_set_new (TpHandleRepoIface *repo)
  G_GNUC_WARN_UNUSED_RESULT;
TpHandleSet *tp_handle_set_copy (const TpHandleSet *other)
  G_GNUC_WARN_UNUSED_RESULT;
TpHandleSet *tp_handle_set_new_from_intset (TpHandleRepoIface *repo,
    const TpIntset *intset);
TpHandleSet *tp_handle_set_new_containing (TpHandleRepoIface *repo,
    TpHandle handle);

void tp_handle_set_clear (TpHandleSet *set);
void tp_handle_set_destroy (TpHandleSet *set);

TpIntset *tp_handle_set_peek (TpHandleSet *set) G_GNUC_WARN_UNUSED_RESULT;

void tp_handle_set_add (TpHandleSet *set, TpHandle handle);
gboolean tp_handle_set_remove (TpHandleSet *set, TpHandle handle);
gboolean tp_handle_set_is_member (const TpHandleSet *set, TpHandle handle);

void tp_handle_set_foreach (TpHandleSet *set, TpHandleSetMemberFunc func,
    gpointer user_data);

gboolean tp_handle_set_is_empty (const TpHandleSet *set);
int tp_handle_set_size (const TpHandleSet *set);
GArray *tp_handle_set_to_array (const TpHandleSet *set)
  G_GNUC_WARN_UNUSED_RESULT;
GHashTable *tp_handle_set_to_identifier_map (TpHandleSet *self)
    G_GNUC_WARN_UNUSED_RESULT;
TpHandleSet *tp_handle_set_new_from_array (TpHandleRepoIface *repo,
    const GArray *array) G_GNUC_WARN_UNUSED_RESULT;

TpIntset *tp_handle_set_update (TpHandleSet *set, const TpIntset *add)
  G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_handle_set_difference_update (TpHandleSet *set,
    const TpIntset *remove) G_GNUC_WARN_UNUSED_RESULT;

gchar *tp_handle_set_dump (const TpHandleSet *self) G_GNUC_WARN_UNUSED_RESULT;

/* static inline because it relies on TP_NUM_HANDLE_TYPES */
/**
 * tp_handles_supported_and_valid: (skip)
 * @repos: An array of possibly null pointers to handle repositories, indexed
 *         by handle type, where a null pointer means an unsupported handle
 *         type
 * @handle_type: The handle type
 * @handles: A GArray of guint representing handles of the given type
 * @allow_zero: If %TRUE, zero is treated like a valid handle
 * @error: Used to return an error if %FALSE is returned
 *
 * Return %TRUE if the given handle type is supported (i.e. repos[handle_type]
 * is not %NULL) and the given handles are all valid in that repository.
 * If not, set @error and return %FALSE.
 *
 * Returns: %TRUE if the handle type is supported and the handles are all
 * valid.
 */

static inline
/* spacer so gtkdoc documents this function as though not static */
gboolean tp_handles_supported_and_valid (
    TpHandleRepoIface *repos[TP_NUM_HANDLE_TYPES],
    TpHandleType handle_type, const GArray *handles, gboolean allow_zero,
    GError **error);

static inline gboolean
tp_handles_supported_and_valid (TpHandleRepoIface *repos[TP_NUM_HANDLE_TYPES],
                                TpHandleType handle_type,
                                const GArray *handles,
                                gboolean allow_zero,
                                GError **error)
{
  if (!tp_handle_type_is_valid (handle_type, error))
    return FALSE;

  if (!repos[handle_type])
    {
      tp_g_set_error_unsupported_handle_type (handle_type, error);
      return FALSE;
    }
  return tp_handles_are_valid (repos[handle_type], handles, allow_zero, error);
}

G_END_DECLS

#endif /*__HANDLE_SET_H__*/
