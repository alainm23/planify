/*
 * account-manager.h - proxy for the Telepathy account manager
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2009 Nokia Corporation
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

#ifndef TP_ACCOUNT_MANAGER_H
#define TP_ACCOUNT_MANAGER_H

#include <telepathy-glib/account.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS

typedef struct _TpAccountManager TpAccountManager;
typedef struct _TpAccountManagerClass TpAccountManagerClass;
typedef struct _TpAccountManagerPrivate TpAccountManagerPrivate;
typedef struct _TpAccountManagerClassPrivate TpAccountManagerClassPrivate;

struct _TpAccountManager {
    /*<private>*/
    TpProxy parent;
    TpAccountManagerPrivate *priv;
};

struct _TpAccountManagerClass {
    /*<private>*/
    TpProxyClass parent_class;
    GCallback _padding[7];
    TpAccountManagerClassPrivate *priv;
};

GType tp_account_manager_get_type (void);

#define TP_TYPE_ACCOUNT_MANAGER \
  (tp_account_manager_get_type ())
#define TP_ACCOUNT_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_ACCOUNT_MANAGER, \
                               TpAccountManager))
#define TP_ACCOUNT_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_ACCOUNT_MANAGER, \
                            TpAccountManagerClass))
#define TP_IS_ACCOUNT_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_ACCOUNT_MANAGER))
#define TP_IS_ACCOUNT_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_ACCOUNT_MANAGER))
#define TP_ACCOUNT_MANAGER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_ACCOUNT_MANAGER, \
                              TpAccountManagerClass))

#define TP_ACCOUNT_MANAGER_FEATURE_CORE \
  tp_account_manager_get_feature_quark_core ()

GQuark tp_account_manager_get_feature_quark_core (void) G_GNUC_CONST;

TpAccountManager *tp_account_manager_new (TpDBusDaemon *bus_daemon)
  G_GNUC_WARN_UNUSED_RESULT;

TpAccountManager *tp_account_manager_new_with_factory (
    TpSimpleClientFactory *factory) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_16
void tp_account_manager_set_default (TpAccountManager *manager);

_TP_AVAILABLE_IN_0_20
gboolean tp_account_manager_can_set_default (void);

TpAccountManager *tp_account_manager_dup (void) G_GNUC_WARN_UNUSED_RESULT;

void tp_account_manager_init_known_interfaces (void);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_16_FOR (tp_simple_client_factory_ensure_account)
TpAccount *tp_account_manager_ensure_account (TpAccountManager *manager,
    const gchar *path);
#endif

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR (tp_account_manager_dup_valid_accounts)
GList *tp_account_manager_get_valid_accounts (TpAccountManager *manager)
  G_GNUC_WARN_UNUSED_RESULT;
#endif

_TP_AVAILABLE_IN_0_20
GList *tp_account_manager_dup_valid_accounts (TpAccountManager *manager)
  G_GNUC_WARN_UNUSED_RESULT;

void tp_account_manager_set_all_requested_presences (TpAccountManager *manager,
    TpConnectionPresenceType type, const gchar *status, const gchar *message);

TpConnectionPresenceType tp_account_manager_get_most_available_presence (
    TpAccountManager *manager, gchar **status, gchar **message);

void tp_account_manager_create_account_async (TpAccountManager *manager,
    const gchar *connection_manager, const gchar *protocol,
    const gchar *display_name, GHashTable *parameters, GHashTable *properties,
    GAsyncReadyCallback callback, gpointer user_data);

TpAccount * tp_account_manager_create_account_finish (
    TpAccountManager *manager, GAsyncResult *result, GError **error)
  G_GNUC_WARN_UNUSED_RESULT;

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_24_FOR(tp_proxy_is_prepared)
gboolean tp_account_manager_is_prepared (TpAccountManager *manager,
    GQuark feature);

_TP_DEPRECATED_IN_0_16_FOR (tp_proxy_prepare_async)
void tp_account_manager_prepare_async (TpAccountManager *manager,
    const GQuark *features,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_DEPRECATED_IN_0_16_FOR (tp_proxy_prepare_finish)
gboolean tp_account_manager_prepare_finish (TpAccountManager *manager,
    GAsyncResult *result,
    GError **error);
#endif

void tp_account_manager_enable_restart (TpAccountManager *manager);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-account-manager.h>

#endif
