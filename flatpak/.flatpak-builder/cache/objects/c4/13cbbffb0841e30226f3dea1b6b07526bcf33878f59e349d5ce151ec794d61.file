/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_authentication_tls_certificate (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "Accepted",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "Rejected",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_authentication_tls_certificate_invoke_callback_for_accepted (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_authentication_tls_certificate_signal_callback_accepted callback =
      (tp_cli_authentication_tls_certificate_signal_callback_accepted) generic_callback;

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
tp_cli_authentication_tls_certificate_connect_to_accepted (TpTLSCertificate *proxy,
    tp_cli_authentication_tls_certificate_signal_callback_accepted callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_TLS_CERTIFICATE (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_AUTHENTICATION_TLS_CERTIFICATE, "Accepted",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_authentication_tls_certificate_invoke_callback_for_accepted,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_authentication_tls_certificate_collect_args_of_rejected (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Rejections,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Rejections);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_authentication_tls_certificate_invoke_callback_for_rejected (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_authentication_tls_certificate_signal_callback_rejected callback =
      (tp_cli_authentication_tls_certificate_signal_callback_rejected) generic_callback;

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
tp_cli_authentication_tls_certificate_connect_to_rejected (TpTLSCertificate *proxy,
    tp_cli_authentication_tls_certificate_signal_callback_rejected callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_TLS_CERTIFICATE (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_AUTHENTICATION_TLS_CERTIFICATE, "Rejected",
      expected_types,
      G_CALLBACK (_tp_cli_authentication_tls_certificate_collect_args_of_rejected),
      _tp_cli_authentication_tls_certificate_invoke_callback_for_rejected,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_authentication_tls_certificate_collect_callback_accept (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_authentication_tls_certificate_invoke_callback_accept (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_authentication_tls_certificate_callback_for_accept callback = (tp_cli_authentication_tls_certificate_callback_for_accept) generic_callback;

  if (error != NULL)
    {
      callback ((TpTLSCertificate *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpTLSCertificate *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_authentication_tls_certificate_call_accept (TpTLSCertificate *proxy,
    gint timeout_ms,
    tp_cli_authentication_tls_certificate_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_AUTHENTICATION_TLS_CERTIFICATE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_TLS_CERTIFICATE (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Accept",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Accept", iface,
          _tp_cli_authentication_tls_certificate_invoke_callback_accept,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Accept",
              _tp_cli_authentication_tls_certificate_collect_callback_accept,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_authentication_tls_certificate_collect_callback_reject (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_authentication_tls_certificate_invoke_callback_reject (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_authentication_tls_certificate_callback_for_reject callback = (tp_cli_authentication_tls_certificate_callback_for_reject) generic_callback;

  if (error != NULL)
    {
      callback ((TpTLSCertificate *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpTLSCertificate *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_authentication_tls_certificate_call_reject (TpTLSCertificate *proxy,
    gint timeout_ms,
    const GPtrArray *in_Rejections,
    tp_cli_authentication_tls_certificate_callback_for_reject callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_AUTHENTICATION_TLS_CERTIFICATE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_TLS_CERTIFICATE (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Reject",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Rejections,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Reject", iface,
          _tp_cli_authentication_tls_certificate_invoke_callback_reject,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Reject",
              _tp_cli_authentication_tls_certificate_collect_callback_reject,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Rejections,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_tls_cert_add_signals:
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
tp_cli_tls_cert_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_AUTHENTICATION_TLS_CERTIFICATE)
    tp_cli_add_signals_for_authentication_tls_certificate (proxy);
}
