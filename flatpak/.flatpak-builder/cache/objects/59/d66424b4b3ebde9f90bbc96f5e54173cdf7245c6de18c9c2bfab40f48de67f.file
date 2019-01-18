#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcAccountManager TpSvcAccountManager;

typedef struct _TpSvcAccountManagerClass TpSvcAccountManagerClass;

GType tp_svc_account_manager_get_type (void);
#define TP_TYPE_SVC_ACCOUNT_MANAGER \
  (tp_svc_account_manager_get_type ())
#define TP_SVC_ACCOUNT_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_ACCOUNT_MANAGER, TpSvcAccountManager))
#define TP_IS_SVC_ACCOUNT_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_ACCOUNT_MANAGER))
#define TP_SVC_ACCOUNT_MANAGER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_ACCOUNT_MANAGER, TpSvcAccountManagerClass))


typedef void (*tp_svc_account_manager_create_account_impl) (TpSvcAccountManager *self,
    const gchar *in_Connection_Manager,
    const gchar *in_Protocol,
    const gchar *in_Display_Name,
    GHashTable *in_Parameters,
    GHashTable *in_Properties,
    DBusGMethodInvocation *context);
void tp_svc_account_manager_implement_create_account (TpSvcAccountManagerClass *klass, tp_svc_account_manager_create_account_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_account_manager_return_from_create_account (DBusGMethodInvocation *context,
    const gchar *out_Account);
static inline void
tp_svc_account_manager_return_from_create_account (DBusGMethodInvocation *context,
    const gchar *out_Account)
{
  dbus_g_method_return (context,
      out_Account);
}

void tp_svc_account_manager_emit_account_removed (gpointer instance,
    const gchar *arg_Account);
void tp_svc_account_manager_emit_account_validity_changed (gpointer instance,
    const gchar *arg_Account,
    gboolean arg_Valid);


G_END_DECLS
