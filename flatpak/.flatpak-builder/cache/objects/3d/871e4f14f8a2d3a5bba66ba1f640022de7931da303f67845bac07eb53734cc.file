#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcAccount TpSvcAccount;

typedef struct _TpSvcAccountClass TpSvcAccountClass;

GType tp_svc_account_get_type (void);
#define TP_TYPE_SVC_ACCOUNT \
  (tp_svc_account_get_type ())
#define TP_SVC_ACCOUNT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_ACCOUNT, TpSvcAccount))
#define TP_IS_SVC_ACCOUNT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_ACCOUNT))
#define TP_SVC_ACCOUNT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_ACCOUNT, TpSvcAccountClass))


typedef void (*tp_svc_account_remove_impl) (TpSvcAccount *self,
    DBusGMethodInvocation *context);
void tp_svc_account_implement_remove (TpSvcAccountClass *klass, tp_svc_account_remove_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_account_return_from_remove (DBusGMethodInvocation *context);
static inline void
tp_svc_account_return_from_remove (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_account_update_parameters_impl) (TpSvcAccount *self,
    GHashTable *in_Set,
    const gchar **in_Unset,
    DBusGMethodInvocation *context);
void tp_svc_account_implement_update_parameters (TpSvcAccountClass *klass, tp_svc_account_update_parameters_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_account_return_from_update_parameters (DBusGMethodInvocation *context,
    const gchar **out_Reconnect_Required);
static inline void
tp_svc_account_return_from_update_parameters (DBusGMethodInvocation *context,
    const gchar **out_Reconnect_Required)
{
  dbus_g_method_return (context,
      out_Reconnect_Required);
}

typedef void (*tp_svc_account_reconnect_impl) (TpSvcAccount *self,
    DBusGMethodInvocation *context);
void tp_svc_account_implement_reconnect (TpSvcAccountClass *klass, tp_svc_account_reconnect_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_account_return_from_reconnect (DBusGMethodInvocation *context);
static inline void
tp_svc_account_return_from_reconnect (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_account_emit_removed (gpointer instance);
void tp_svc_account_emit_account_property_changed (gpointer instance,
    GHashTable *arg_Properties);

typedef struct _TpSvcAccountInterfaceAddressing TpSvcAccountInterfaceAddressing;

typedef struct _TpSvcAccountInterfaceAddressingClass TpSvcAccountInterfaceAddressingClass;

GType tp_svc_account_interface_addressing_get_type (void);
#define TP_TYPE_SVC_ACCOUNT_INTERFACE_ADDRESSING \
  (tp_svc_account_interface_addressing_get_type ())
#define TP_SVC_ACCOUNT_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_ADDRESSING, TpSvcAccountInterfaceAddressing))
#define TP_IS_SVC_ACCOUNT_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_ADDRESSING))
#define TP_SVC_ACCOUNT_INTERFACE_ADDRESSING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_ADDRESSING, TpSvcAccountInterfaceAddressingClass))


typedef void (*tp_svc_account_interface_addressing_set_uri_scheme_association_impl) (TpSvcAccountInterfaceAddressing *self,
    const gchar *in_URI_Scheme,
    gboolean in_Association,
    DBusGMethodInvocation *context);
void tp_svc_account_interface_addressing_implement_set_uri_scheme_association (TpSvcAccountInterfaceAddressingClass *klass, tp_svc_account_interface_addressing_set_uri_scheme_association_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_account_interface_addressing_return_from_set_uri_scheme_association (DBusGMethodInvocation *context);
static inline void
tp_svc_account_interface_addressing_return_from_set_uri_scheme_association (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}


typedef struct _TpSvcAccountInterfaceAvatar TpSvcAccountInterfaceAvatar;

typedef struct _TpSvcAccountInterfaceAvatarClass TpSvcAccountInterfaceAvatarClass;

GType tp_svc_account_interface_avatar_get_type (void);
#define TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR \
  (tp_svc_account_interface_avatar_get_type ())
#define TP_SVC_ACCOUNT_INTERFACE_AVATAR(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR, TpSvcAccountInterfaceAvatar))
#define TP_IS_SVC_ACCOUNT_INTERFACE_AVATAR(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR))
#define TP_SVC_ACCOUNT_INTERFACE_AVATAR_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR, TpSvcAccountInterfaceAvatarClass))


void tp_svc_account_interface_avatar_emit_avatar_changed (gpointer instance);

typedef struct _TpSvcAccountInterfaceStorage TpSvcAccountInterfaceStorage;

typedef struct _TpSvcAccountInterfaceStorageClass TpSvcAccountInterfaceStorageClass;

GType tp_svc_account_interface_storage_get_type (void);
#define TP_TYPE_SVC_ACCOUNT_INTERFACE_STORAGE \
  (tp_svc_account_interface_storage_get_type ())
#define TP_SVC_ACCOUNT_INTERFACE_STORAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_STORAGE, TpSvcAccountInterfaceStorage))
#define TP_IS_SVC_ACCOUNT_INTERFACE_STORAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_STORAGE))
#define TP_SVC_ACCOUNT_INTERFACE_STORAGE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_ACCOUNT_INTERFACE_STORAGE, TpSvcAccountInterfaceStorageClass))




G_END_DECLS
