/*<private_header>*/
/*
 * internal-handle-repo.h - private header for handle repositories
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

#ifndef __TP_INTERNAL_HANDLE_REPO_H__
#define __TP_INTERNAL_HANDLE_REPO_H__

#include <telepathy-glib/handle-repo.h>

G_BEGIN_DECLS

/* G_DEFINE_INTERFACE wants that name */
typedef struct _TpHandleRepoIfaceClass TpHandleRepoIfaceInterface;

/*      <-- this is no longer a gtkdoc comment because this is not public API
 * TpHandleRepoIfaceClass:
 * @parent_class: Fields shared with GTypeInterface
 * @handle_is_valid: Implementation for tp_handle_is_valid() for this repo
 * @handles_are_valid: Implementation for tp_handles_are_valid() for this repo
 * @ref_handle: Implementation for tp_handle_ref() for this repo
 * @unref_handle: Implementation for tp_handle_unref() for this repo
 * @client_hold_handle: Implementation for tp_handle_client_hold() for this
 *  repo
 * @client_release_handle: Implementation for tp_handle_client_release() for
 *  this repo
 * @inspect_handle: Implementation for tp_handle_inspect() for this repo
 * @ensure_handle: Implementation for tp_handle_ensure() for this repo
 * @lookup_handle: Implementation for tp_handle_lookup() for this repo
 * @get_qdata: Implementation for tp_handle_get_qdata() for this repo
 * @set_qdata: Implementation for tp_handle_set_qdata() for this repo
 *
 * The class of a #TpHandleRepoIface. All implementation callbacks must be
 * filled in by all implementations, and have the same semantics as the
 * global function that calls them.
 */
struct _TpHandleRepoIfaceClass {
    GTypeInterface parent_class;

    gboolean (*handle_is_valid) (TpHandleRepoIface *self, TpHandle handle,
        GError **error);
    gboolean (*handles_are_valid) (TpHandleRepoIface *self,
        const GArray *handles, gboolean allow_zero, GError **error);

    TpHandle (*ref_handle) (TpHandleRepoIface *self, TpHandle handle);
    void (*unref_handle) (TpHandleRepoIface *self, TpHandle handle);
    gboolean (*client_hold_handle) (TpHandleRepoIface *self,
        const gchar *client, TpHandle handle, GError **error);
    gboolean (*client_release_handle) (TpHandleRepoIface *self,
        const gchar *client, TpHandle handle, GError **error);

    const char *(*inspect_handle) (TpHandleRepoIface *self, TpHandle handle);
    TpHandle (*ensure_handle) (TpHandleRepoIface *self, const char *id,
        gpointer context, GError **error);
    TpHandle (*lookup_handle) (TpHandleRepoIface *self, const char *id,
        gpointer context, GError **error);

    void (*ensure_handle_async) (TpHandleRepoIface *self,
        TpBaseConnection *connection,
        const gchar *id,
        gpointer context,
        GAsyncReadyCallback callback,
        gpointer user_data);
    TpHandle (*ensure_handle_finish) (TpHandleRepoIface *self,
        GAsyncResult *result,
        GError **error);

    void (*set_qdata) (TpHandleRepoIface *repo, TpHandle handle,
        GQuark key_id, gpointer data, GDestroyNotify destroy);
    gpointer (*get_qdata) (TpHandleRepoIface *repo, TpHandle handle,
        GQuark key_id);
};

gpointer _tp_dynamic_handle_repo_get_normalization_data (
    TpHandleRepoIface *irepo);
void _tp_dynamic_handle_repo_set_normalization_data (TpHandleRepoIface *irepo,
    gpointer data,
    GDestroyNotify destroy);

G_END_DECLS

#endif /*__TP_INTERNAL_HANDLE_REPO_H__ */
