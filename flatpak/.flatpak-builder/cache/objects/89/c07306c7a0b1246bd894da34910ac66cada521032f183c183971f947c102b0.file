#include "_gen/tp-svc-account-manager.h"

static const DBusGObjectInfo _tp_svc_account_manager_object_info;

struct _TpSvcAccountManagerClass {
    GTypeInterface parent_class;
    tp_svc_account_manager_create_account_impl create_account_cb;
};

enum {
    SIGNAL_ACCOUNT_MANAGER_AccountRemoved,
    SIGNAL_ACCOUNT_MANAGER_AccountValidityChanged,
    N_ACCOUNT_MANAGER_SIGNALS
};
static guint account_manager_signals[N_ACCOUNT_MANAGER_SIGNALS] = {0};

static void tp_svc_account_manager_base_init (gpointer klass);

GType
tp_svc_account_manager_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAccountManagerClass),
        tp_svc_account_manager_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAccountManager", &info, 0);
    }

  return type;
}

static void
tp_svc_account_manager_create_account (TpSvcAccountManager *self,
    const gchar *in_Connection_Manager,
    const gchar *in_Protocol,
    const gchar *in_Display_Name,
    GHashTable *in_Parameters,
    GHashTable *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_account_manager_create_account_impl impl = (TP_SVC_ACCOUNT_MANAGER_GET_CLASS (self)->create_account_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Connection_Manager,
        in_Protocol,
        in_Display_Name,
        in_Parameters,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_account_manager_implement_create_account (TpSvcAccountManagerClass *klass, tp_svc_account_manager_create_account_impl impl)
{
  klass->create_account_cb = impl;
}

void
tp_svc_account_manager_emit_account_removed (gpointer instance,
    const gchar *arg_Account)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_ACCOUNT_MANAGER));
  g_signal_emit (instance,
      account_manager_signals[SIGNAL_ACCOUNT_MANAGER_AccountRemoved],
      0,
      arg_Account);
}

void
tp_svc_account_manager_emit_account_validity_changed (gpointer instance,
    const gchar *arg_Account,
    gboolean arg_Valid)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_ACCOUNT_MANAGER));
  g_signal_emit (instance,
      account_manager_signals[SIGNAL_ACCOUNT_MANAGER_AccountValidityChanged],
      0,
      arg_Account,
      arg_Valid);
}

static inline void
tp_svc_account_manager_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* ValidAccounts */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* InvalidAccounts */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* SupportedAccountProperties */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_account_manager_get_type (),
      &_tp_svc_account_manager_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.AccountManager");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("ValidAccounts");
  properties[1].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[2].name = g_quark_from_static_string ("InvalidAccounts");
  properties[2].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[3].name = g_quark_from_static_string ("SupportedAccountProperties");
  properties[3].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_ACCOUNT_MANAGER, &interface);

  account_manager_signals[SIGNAL_ACCOUNT_MANAGER_AccountRemoved] =
  g_signal_new ("account-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      DBUS_TYPE_G_OBJECT_PATH);

  account_manager_signals[SIGNAL_ACCOUNT_MANAGER_AccountValidityChanged] =
  g_signal_new ("account-validity-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_account_manager_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_account_manager_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_account_manager_methods[] = {
  { (GCallback) tp_svc_account_manager_create_account, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_account_manager_object_info = {
  0,
  _tp_svc_account_manager_methods,
  1,
"org.freedesktop.Telepathy.AccountManager\0CreateAccount\0A\0Connection_Manager\0I\0s\0Protocol\0I\0s\0Display_Name\0I\0s\0Parameters\0I\0a{sv}\0Properties\0I\0a{sv}\0Account\0O\0F\0N\0o\0\0\0",
"org.freedesktop.Telepathy.AccountManager\0AccountRemoved\0org.freedesktop.Telepathy.AccountManager\0AccountValidityChanged\0\0",
"\0\0",
};


