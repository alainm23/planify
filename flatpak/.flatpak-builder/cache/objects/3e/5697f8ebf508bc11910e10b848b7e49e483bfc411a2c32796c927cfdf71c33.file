/*
 * connection.h - proxy for a Telepathy connection
 *
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007 Nokia Corporation
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

#ifndef __TP_CONNECTION_H__
#define __TP_CONNECTION_H__

#include <telepathy-glib/capabilities.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS

typedef struct _TpContactInfoFieldSpec TpContactInfoFieldSpec;
struct _TpContactInfoFieldSpec
{
  /*<public>*/
  gchar *name;
  GStrv parameters;
  TpContactInfoFieldFlags flags;
  guint max;
  /*<private>*/
  gpointer priv;
};

#define TP_TYPE_CONTACT_INFO_FIELD_SPEC (tp_contact_info_field_spec_get_type ())
GType tp_contact_info_field_spec_get_type (void);
TpContactInfoFieldSpec *tp_contact_info_field_spec_copy (
    const TpContactInfoFieldSpec *self);
void tp_contact_info_field_spec_free (TpContactInfoFieldSpec *self);

#ifndef __GI_SCANNER__
/* the typedef only exists for G_DEFINE_BOXED_TYPE's benefit, and
 * g-ir-scanner 1.32.1 doesn't parse a skip annotation */
typedef GList TpContactInfoSpecList;
#endif

#define TP_TYPE_CONTACT_INFO_SPEC_LIST (tp_contact_info_spec_list_get_type ())
GType tp_contact_info_spec_list_get_type (void);
GList *tp_contact_info_spec_list_copy (GList *list);
void tp_contact_info_spec_list_free (GList *list);

typedef struct _TpContactInfoField TpContactInfoField;
struct _TpContactInfoField
{
  /*<public>*/
  gchar *field_name;
  GStrv parameters;
  GStrv field_value;
  /*<private>*/
  gpointer priv;
};

#define TP_TYPE_CONTACT_INFO_FIELD (tp_contact_info_field_get_type ())
GType tp_contact_info_field_get_type (void);
TpContactInfoField *tp_contact_info_field_new (const gchar *field_name,
    GStrv parameters, GStrv field_value);
TpContactInfoField *tp_contact_info_field_copy (const TpContactInfoField *self);
void tp_contact_info_field_free (TpContactInfoField *self);

#ifndef __GI_SCANNER__
/* the typedef only exists for G_DEFINE_BOXED_TYPE's benefit, and
 * g-ir-scanner 1.32.1 doesn't parse a skip annotation */
typedef GList TpContactInfoList;
#endif

#define TP_TYPE_CONTACT_INFO_LIST (tp_contact_info_list_get_type ())
GType tp_contact_info_list_get_type (void);
GList *tp_contact_info_list_copy (GList *list);
void tp_contact_info_list_free (GList *list);

/* forward declaration, see contact.h for the rest */
typedef struct _TpContact TpContact;
/* forward declaration, see account.h for the rest */
typedef struct _TpAccount TpAccount;

typedef struct _TpConnection TpConnection;
typedef struct _TpConnectionPrivate TpConnectionPrivate;
typedef struct _TpConnectionClass TpConnectionClass;

struct _TpConnectionClass {
    TpProxyClass parent_class;
    /*<private>*/
    GCallback _1;
    GCallback _2;
    GCallback _3;
    GCallback _4;
};

struct _TpConnection {
    /*<private>*/
    TpProxy parent;
    TpConnectionPrivate *priv;
};

GType tp_connection_get_type (void);

#define TP_ERRORS_DISCONNECTED (tp_errors_disconnected_quark ())
GQuark tp_errors_disconnected_quark (void);

#define TP_UNKNOWN_CONNECTION_STATUS ((TpConnectionStatus) -1)

/* TYPE MACROS */
#define TP_TYPE_CONNECTION \
  (tp_connection_get_type ())
#define TP_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_CONNECTION, \
                              TpConnection))
#define TP_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_CONNECTION, \
                           TpConnectionClass))
#define TP_IS_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_CONNECTION))
#define TP_IS_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_CONNECTION))
#define TP_CONNECTION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CONNECTION, \
                              TpConnectionClass))

_TP_DEPRECATED_IN_0_20_FOR(tp_simple_client_factory_ensure_connection)
TpConnection *tp_connection_new (TpDBusDaemon *dbus, const gchar *bus_name,
    const gchar *object_path, GError **error) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_16
TpAccount *tp_connection_get_account (TpConnection *self);

TpConnectionStatus tp_connection_get_status (TpConnection *self,
    TpConnectionStatusReason *reason);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR (tp_connection_get_cm_name)
const gchar *tp_connection_get_connection_manager_name (TpConnection *self);
#endif

_TP_AVAILABLE_IN_0_20
const gchar *tp_connection_get_cm_name (TpConnection *self);

const gchar *tp_connection_get_protocol_name (TpConnection *self);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR (tp_connection_get_self_contact)
TpHandle tp_connection_get_self_handle (TpConnection *self);
#endif

TpContact *tp_connection_get_self_contact (TpConnection *self);

TpCapabilities * tp_connection_get_capabilities (TpConnection *self);

TpContactInfoFlags tp_connection_get_contact_info_flags (TpConnection *self);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR (tp_connection_dup_contact_info_supported_fields)
GList *tp_connection_get_contact_info_supported_fields (TpConnection *self);
#endif

_TP_AVAILABLE_IN_0_20
GList *tp_connection_dup_contact_info_supported_fields (TpConnection *self);

void tp_connection_set_contact_info_async (TpConnection *self,
    GList *info, GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_connection_set_contact_info_finish (TpConnection *self,
    GAsyncResult *result, GError **error);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_18_FOR (tp_proxy_is_prepared)
gboolean tp_connection_is_ready (TpConnection *self);

_TP_DEPRECATED_IN_0_18
gboolean tp_connection_run_until_ready (TpConnection *self,
    gboolean connect, GError **error,
    GMainLoop **loop);

typedef void (*TpConnectionWhenReadyCb) (TpConnection *connection,
    const GError *error, gpointer user_data);

_TP_DEPRECATED_IN_0_18_FOR (tp_proxy_prepare_async)
void tp_connection_call_when_ready (TpConnection *self,
    TpConnectionWhenReadyCb callback,
    gpointer user_data);
#endif

typedef void (*TpConnectionNameListCb) (const gchar * const *names,
    gsize n, const gchar * const *cms, const gchar * const *protocols,
    const GError *error, gpointer user_data,
    GObject *weak_object);

void tp_list_connection_names (TpDBusDaemon *bus_daemon,
    TpConnectionNameListCb callback,
    gpointer user_data, GDestroyNotify destroy,
    GObject *weak_object);

void tp_connection_init_known_interfaces (void);

gint tp_connection_presence_type_cmp_availability (TpConnectionPresenceType p1,
  TpConnectionPresenceType p2);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR(tp_connection_get_protocol_name)
gboolean tp_connection_parse_object_path (TpConnection *self, gchar **protocol,
    gchar **cm_name);
#endif

_TP_AVAILABLE_IN_0_20
const gchar *tp_connection_get_detailed_error (TpConnection *self,
    const GHashTable **details);
_TP_AVAILABLE_IN_0_20
gchar *tp_connection_dup_detailed_error_vardict (TpConnection *self,
    GVariant **details) G_GNUC_WARN_UNUSED_RESULT;


void tp_connection_add_client_interest (TpConnection *self,
    const gchar *interested_in);

void tp_connection_add_client_interest_by_id (TpConnection *self,
    GQuark interested_in);

gboolean tp_connection_has_immortal_handles (TpConnection *self);

#define TP_CONNECTION_FEATURE_CORE \
  (tp_connection_get_feature_quark_core ())
GQuark tp_connection_get_feature_quark_core (void) G_GNUC_CONST;

#define TP_CONNECTION_FEATURE_CONNECTED \
  (tp_connection_get_feature_quark_connected ())
GQuark tp_connection_get_feature_quark_connected (void) G_GNUC_CONST;

#define TP_CONNECTION_FEATURE_CAPABILITIES \
  (tp_connection_get_feature_quark_capabilities ())
GQuark tp_connection_get_feature_quark_capabilities (void) G_GNUC_CONST;

#define TP_CONNECTION_FEATURE_CONTACT_INFO \
  (tp_connection_get_feature_quark_contact_info ())
GQuark tp_connection_get_feature_quark_contact_info (void) G_GNUC_CONST;

/* connection-handles.c */

#ifndef TP_DISABLE_DEPRECATED
typedef void (*TpConnectionHoldHandlesCb) (TpConnection *connection,
    TpHandleType handle_type, guint n_handles, const TpHandle *handles,
    const GError *error, gpointer user_data, GObject *weak_object);

_TP_DEPRECATED_IN_0_20
void tp_connection_hold_handles (TpConnection *self, gint timeout_ms,
    TpHandleType handle_type, guint n_handles, const TpHandle *handles,
    TpConnectionHoldHandlesCb callback,
    gpointer user_data, GDestroyNotify destroy, GObject *weak_object);

typedef void (*TpConnectionRequestHandlesCb) (TpConnection *connection,
    TpHandleType handle_type,
    guint n_handles, const TpHandle *handles, const gchar * const *ids,
    const GError *error, gpointer user_data, GObject *weak_object);

_TP_DEPRECATED_IN_0_20
void tp_connection_request_handles (TpConnection *self, gint timeout_ms,
    TpHandleType handle_type, const gchar * const *ids,
    TpConnectionRequestHandlesCb callback,
    gpointer user_data, GDestroyNotify destroy, GObject *weak_object);

_TP_DEPRECATED_IN_0_20
void tp_connection_unref_handles (TpConnection *self,
    TpHandleType handle_type, guint n_handles, const TpHandle *handles);
#endif

/* connection-avatars.c */

typedef struct _TpAvatarRequirements TpAvatarRequirements;
struct _TpAvatarRequirements
{
  /*<public>*/
  GStrv supported_mime_types;
  guint minimum_width;
  guint minimum_height;
  guint recommended_width;
  guint recommended_height;
  guint maximum_width;
  guint maximum_height;
  guint maximum_bytes;

  /*<private>*/
  gpointer _1;
  gpointer _2;
  gpointer _3;
  gpointer _4;
};

#define TP_TYPE_AVATAR_REQUIREMENTS (tp_avatar_requirements_get_type ())
GType tp_avatar_requirements_get_type (void);
TpAvatarRequirements * tp_avatar_requirements_new (GStrv supported_mime_types,
    guint minimum_width,
    guint minimum_height,
    guint recommended_width,
    guint recommended_height,
    guint maximum_width,
    guint maximum_height,
    guint maximum_bytes);
TpAvatarRequirements * tp_avatar_requirements_copy (
    const TpAvatarRequirements *self);
void tp_avatar_requirements_destroy (TpAvatarRequirements *self);

#define TP_CONNECTION_FEATURE_AVATAR_REQUIREMENTS \
  (tp_connection_get_feature_quark_avatar_requirements ())
GQuark tp_connection_get_feature_quark_avatar_requirements (void) G_GNUC_CONST;

TpAvatarRequirements * tp_connection_get_avatar_requirements (
    TpConnection *self);

#define TP_CONNECTION_FEATURE_ALIASING \
  (tp_connection_get_feature_quark_aliasing ())
_TP_AVAILABLE_IN_0_18
GQuark tp_connection_get_feature_quark_aliasing (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_18
gboolean tp_connection_can_set_contact_alias (TpConnection *self);

#define TP_CONNECTION_FEATURE_BALANCE \
  (tp_connection_get_feature_quark_balance ())
_TP_AVAILABLE_IN_0_16
GQuark tp_connection_get_feature_quark_balance (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_16
gboolean tp_connection_get_balance (TpConnection *self,
    gint *balance, guint *scale, const gchar **currency);
_TP_AVAILABLE_IN_0_16
const gchar * tp_connection_get_balance_uri (TpConnection *self);

_TP_AVAILABLE_IN_0_18
void tp_connection_disconnect_async (TpConnection *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_connection_disconnect_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-connection.h>

G_BEGIN_DECLS

/* connection-handles.c again - this has to come after the auto-generated
 * stuff because it uses an auto-generated typedef */

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR(tp_simple_client_factory_ensure_contact)
void tp_connection_get_contact_attributes (TpConnection *self,
    gint timeout_ms, guint n_handles, const TpHandle *handles,
    const gchar * const *interfaces, gboolean hold,
    tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback,
    gpointer user_data, GDestroyNotify destroy, GObject *weak_object);

_TP_DEPRECATED_IN_0_20_FOR(tp_connection_dup_contact_list)
void tp_connection_get_contact_list_attributes (TpConnection *self,
    gint timeout_ms, const gchar * const *interfaces, gboolean hold,
    tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback,
    gpointer user_data, GDestroyNotify destroy, GObject *weak_object);
#endif

GBinding *tp_connection_bind_connection_status_to_property (TpConnection *self,
    gpointer target, const char *target_property, gboolean invert);

G_END_DECLS

#endif
