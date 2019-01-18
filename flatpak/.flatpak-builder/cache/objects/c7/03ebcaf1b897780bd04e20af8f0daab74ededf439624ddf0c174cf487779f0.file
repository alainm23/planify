/*
 * account-request.h - object for a currently non-existent account to create
 *
 * Copyright (C) 2012 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef TP_ACCOUNT_REQUEST_H
#define TP_ACCOUNT_REQUEST_H

#include <telepathy-glib/account-manager.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/protocol.h>

G_BEGIN_DECLS

typedef struct _TpAccountRequest TpAccountRequest;
typedef struct _TpAccountRequestClass TpAccountRequestClass;
typedef struct _TpAccountRequestPrivate TpAccountRequestPrivate;

struct _TpAccountRequest {
    /*<private>*/
    GObject parent;
    TpAccountRequestPrivate *priv;
};

struct _TpAccountRequestClass {
    /*<private>*/
    GObjectClass parent_class;
    GCallback _padding[7];
};

GType tp_account_request_get_type (void);

#define TP_TYPE_ACCOUNT_REQUEST \
  (tp_account_request_get_type ())
#define TP_ACCOUNT_REQUEST(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_ACCOUNT_REQUEST, \
                               TpAccountRequest))
#define TP_ACCOUNT_REQUEST_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_ACCOUNT_REQUEST, \
                            TpAccountRequestClass))
#define TP_IS_ACCOUNT_REQUEST(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_ACCOUNT_REQUEST))
#define TP_IS_ACCOUNT_REQUEST_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_ACCOUNT_REQUEST))
#define TP_ACCOUNT_REQUEST_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_ACCOUNT_REQUEST, \
                              TpAccountRequestClass))

_TP_AVAILABLE_IN_0_20
TpAccountRequest * tp_account_request_new (
    TpAccountManager *account_manager,
    const gchar *manager,
    const gchar *protocol,
    const gchar *display_name) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_20
TpAccountRequest * tp_account_request_new_from_protocol (
    TpAccountManager *account_manager,
    TpProtocol *protocol,
    const gchar *display_name) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_display_name (TpAccountRequest *self,
    const gchar *name);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_icon_name (TpAccountRequest *self,
    const gchar *icon);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_nickname (TpAccountRequest *self,
    const gchar *nickname);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_requested_presence (TpAccountRequest *self,
    TpConnectionPresenceType presence,
    const gchar *status, const gchar *message);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_automatic_presence (TpAccountRequest *self,
    TpConnectionPresenceType presence,
    const gchar *status, const gchar *message);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_enabled (TpAccountRequest *self,
    gboolean enabled);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_connect_automatically (TpAccountRequest *self,
    gboolean connect_automatically);

_TP_AVAILABLE_IN_0_20
void tp_account_request_add_supersedes (TpAccountRequest *self,
    const gchar *superseded_path);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_avatar (TpAccountRequest *self,
    const guchar *avatar, gsize len, const gchar *mime_type);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_service (TpAccountRequest *self,
    const gchar *service);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_storage_provider (TpAccountRequest *self,
    const gchar *provider);

/* parameters */
_TP_AVAILABLE_IN_0_20
void tp_account_request_set_parameter (TpAccountRequest *self,
    const gchar *key,
    GVariant *value);

_TP_AVAILABLE_IN_0_20
void tp_account_request_unset_parameter (TpAccountRequest *self,
    const gchar *key);

_TP_AVAILABLE_IN_0_20
void tp_account_request_set_parameter_string (TpAccountRequest *self,
    const gchar *key,
    const gchar *value);

/* create it */
_TP_AVAILABLE_IN_0_20
void tp_account_request_create_account_async (TpAccountRequest *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_20
TpAccount * tp_account_request_create_account_finish (TpAccountRequest *self,
    GAsyncResult *result,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

G_END_DECLS

#endif
