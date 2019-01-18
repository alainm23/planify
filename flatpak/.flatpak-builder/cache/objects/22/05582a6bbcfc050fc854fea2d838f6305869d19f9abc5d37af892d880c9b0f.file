/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_account_manager (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AccountRemoved",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "AccountValidityChanged",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_account_manager_collect_args_of_account_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Account,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (1);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Account);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_account_manager_invoke_callback_for_account_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_manager_signal_callback_account_removed callback =
      (tp_cli_account_manager_signal_callback_account_removed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_account_manager_connect_to_account_removed (TpAccountManager *proxy,
    tp_cli_account_manager_signal_callback_account_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_ACCOUNT_MANAGER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_ACCOUNT_MANAGER, "AccountRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_account_manager_collect_args_of_account_removed),
      _tp_cli_account_manager_invoke_callback_for_account_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_account_manager_collect_args_of_account_validity_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Account,
    gboolean arg_Valid,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (2);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Account);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_BOOLEAN);
  g_value_set_boolean (args->values + 1, arg_Valid);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_account_manager_invoke_callback_for_account_validity_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_manager_signal_callback_account_validity_changed callback =
      (tp_cli_account_manager_signal_callback_account_validity_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boolean (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_account_manager_connect_to_account_validity_changed (TpAccountManager *proxy,
    tp_cli_account_manager_signal_callback_account_validity_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_ACCOUNT_MANAGER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_ACCOUNT_MANAGER, "AccountValidityChanged",
      expected_types,
      G_CALLBACK (_tp_cli_account_manager_collect_args_of_account_validity_changed),
      _tp_cli_account_manager_invoke_callback_for_account_validity_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_account_manager_collect_callback_create_account (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Account;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Account,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_take_boxed (args->values + 0, out_Account);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_account_manager_invoke_callback_create_account (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_manager_callback_for_create_account callback = (tp_cli_account_manager_callback_for_create_account) generic_callback;

  if (error != NULL)
    {
      callback ((TpAccountManager *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpAccountManager *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_account_manager_call_create_account (TpAccountManager *proxy,
    gint timeout_ms,
    const gchar *in_Connection_Manager,
    const gchar *in_Protocol,
    const gchar *in_Display_Name,
    GHashTable *in_Parameters,
    GHashTable *in_Properties,
    tp_cli_account_manager_callback_for_create_account callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_ACCOUNT_MANAGER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_ACCOUNT_MANAGER (proxy), NULL);
  g_return_val_if_fail (callback != NULL || user_data == NULL, NULL);
  g_return_val_if_fail (callback != NULL || destroy == NULL, NULL);
  g_return_val_if_fail (callback != NULL || weak_object == NULL, NULL);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id (
      (TpProxy *) proxy,
      interface, &error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    {
      if (callback != NULL)
        callback (proxy,
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "CreateAccount",
          G_TYPE_STRING, in_Connection_Manager,
          G_TYPE_STRING, in_Protocol,
          G_TYPE_STRING, in_Display_Name,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CreateAccount", iface,
          _tp_cli_account_manager_invoke_callback_create_account,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CreateAccount",
              _tp_cli_account_manager_collect_callback_create_account,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Connection_Manager,
              G_TYPE_STRING, in_Protocol,
              G_TYPE_STRING, in_Display_Name,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_account_manager_add_signals:
 * @self: the #TpProxy
 * @quark: a quark whose string value is the interface
 *   name whose signals should be added
 * @proxy: the D-Bus proxy to which to add the signals
 * @unused: not used for anything
 *
 * Tell dbus-glib that @proxy has the signatures of all
 * signals on the given interface, if it's one we
 * support.
 *
 * This function should be used as a signal handler for
 * #TpProxy::interface-added.
 */
static void
tp_cli_account_manager_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_ACCOUNT_MANAGER)
    tp_cli_add_signals_for_account_manager (proxy);
}
