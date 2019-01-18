/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_account (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "Removed",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "AccountPropertyChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
}


static void
_tp_cli_account_invoke_callback_for_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_signal_callback_removed callback =
      (tp_cli_account_signal_callback_removed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);

  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_account_connect_to_removed (TpAccount *proxy,
    tp_cli_account_signal_callback_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_ACCOUNT, "Removed",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_account_invoke_callback_for_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_account_collect_args_of_account_property_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Properties,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 0, arg_Properties);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_account_invoke_callback_for_account_property_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_signal_callback_account_property_changed callback =
      (tp_cli_account_signal_callback_account_property_changed) generic_callback;

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
tp_cli_account_connect_to_account_property_changed (TpAccount *proxy,
    tp_cli_account_signal_callback_account_property_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_ACCOUNT, "AccountPropertyChanged",
      expected_types,
      G_CALLBACK (_tp_cli_account_collect_args_of_account_property_changed),
      _tp_cli_account_invoke_callback_for_account_property_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_account_collect_callback_remove (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_account_invoke_callback_remove (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_callback_for_remove callback = (tp_cli_account_callback_for_remove) generic_callback;

  if (error != NULL)
    {
      callback ((TpAccount *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpAccount *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_account_call_remove (TpAccount *proxy,
    gint timeout_ms,
    tp_cli_account_callback_for_remove callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_ACCOUNT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "Remove",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Remove", iface,
          _tp_cli_account_invoke_callback_remove,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Remove",
              _tp_cli_account_collect_callback_remove,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_account_collect_callback_update_parameters (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Reconnect_Required;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Reconnect_Required,
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
  g_value_init (args->values + 0, G_TYPE_STRV);
  g_value_take_boxed (args->values + 0, out_Reconnect_Required);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_account_invoke_callback_update_parameters (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_callback_for_update_parameters callback = (tp_cli_account_callback_for_update_parameters) generic_callback;

  if (error != NULL)
    {
      callback ((TpAccount *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpAccount *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_account_call_update_parameters (TpAccount *proxy,
    gint timeout_ms,
    GHashTable *in_Set,
    const gchar **in_Unset,
    tp_cli_account_callback_for_update_parameters callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_ACCOUNT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UpdateParameters",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Set,
          G_TYPE_STRV, in_Unset,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UpdateParameters", iface,
          _tp_cli_account_invoke_callback_update_parameters,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UpdateParameters",
              _tp_cli_account_collect_callback_update_parameters,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Set,
              G_TYPE_STRV, in_Unset,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_account_collect_callback_reconnect (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_account_invoke_callback_reconnect (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_callback_for_reconnect callback = (tp_cli_account_callback_for_reconnect) generic_callback;

  if (error != NULL)
    {
      callback ((TpAccount *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpAccount *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_account_call_reconnect (TpAccount *proxy,
    gint timeout_ms,
    tp_cli_account_callback_for_reconnect callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_ACCOUNT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "Reconnect",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Reconnect", iface,
          _tp_cli_account_invoke_callback_reconnect,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Reconnect",
              _tp_cli_account_collect_callback_reconnect,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_account_interface_addressing_collect_callback_set_uri_scheme_association (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_account_interface_addressing_invoke_callback_set_uri_scheme_association (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_interface_addressing_callback_for_set_uri_scheme_association callback = (tp_cli_account_interface_addressing_callback_for_set_uri_scheme_association) generic_callback;

  if (error != NULL)
    {
      callback ((TpAccount *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpAccount *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_account_interface_addressing_call_set_uri_scheme_association (TpAccount *proxy,
    gint timeout_ms,
    const gchar *in_URI_Scheme,
    gboolean in_Association,
    tp_cli_account_interface_addressing_callback_for_set_uri_scheme_association callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_ACCOUNT_INTERFACE_ADDRESSING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "SetURISchemeAssociation",
          G_TYPE_STRING, in_URI_Scheme,
          G_TYPE_BOOLEAN, in_Association,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetURISchemeAssociation", iface,
          _tp_cli_account_interface_addressing_invoke_callback_set_uri_scheme_association,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetURISchemeAssociation",
              _tp_cli_account_interface_addressing_collect_callback_set_uri_scheme_association,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_URI_Scheme,
              G_TYPE_BOOLEAN, in_Association,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_account_interface_avatar (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AvatarChanged",
      G_TYPE_INVALID);
}


static void
_tp_cli_account_interface_avatar_invoke_callback_for_avatar_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_account_interface_avatar_signal_callback_avatar_changed callback =
      (tp_cli_account_interface_avatar_signal_callback_avatar_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);

  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_account_interface_avatar_connect_to_avatar_changed (TpAccount *proxy,
    tp_cli_account_interface_avatar_signal_callback_avatar_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_ACCOUNT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_ACCOUNT_INTERFACE_AVATAR, "AvatarChanged",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_account_interface_avatar_invoke_callback_for_avatar_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

/*
 * tp_cli_account_add_signals:
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
tp_cli_account_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_ACCOUNT)
    tp_cli_add_signals_for_account (proxy);
  if (quark == TP_IFACE_QUARK_ACCOUNT_INTERFACE_AVATAR)
    tp_cli_add_signals_for_account_interface_avatar (proxy);
}
