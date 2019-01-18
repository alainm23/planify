/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_call_stream (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "RemoteMembersChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "LocalSendingStateChanged",
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
}


static void
_tp_cli_call_stream_collect_args_of_remote_members_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Updates,
    GHashTable *arg_Identifiers,
    const GArray *arg_Removed,
    const GValueArray *arg_Reason,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (4);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 4; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)));
  g_value_set_boxed (args->values + 0, arg_Updates);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 1, arg_Identifiers);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 2, arg_Removed);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 3, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_invoke_callback_for_remote_members_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_signal_callback_remote_members_changed callback =
      (tp_cli_call_stream_signal_callback_remote_members_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      g_value_get_boxed (args->values + 3),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_connect_to_remote_members_changed (TpCallStream *proxy,
    tp_cli_call_stream_signal_callback_remote_members_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM, "RemoteMembersChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_collect_args_of_remote_members_changed),
      _tp_cli_call_stream_invoke_callback_for_remote_members_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_collect_args_of_local_sending_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_State,
    const GValueArray *arg_Reason,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_State);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_invoke_callback_for_local_sending_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_signal_callback_local_sending_state_changed callback =
      (tp_cli_call_stream_signal_callback_local_sending_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_boxed (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_connect_to_local_sending_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_signal_callback_local_sending_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM, "LocalSendingStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_collect_args_of_local_sending_state_changed),
      _tp_cli_call_stream_invoke_callback_for_local_sending_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_collect_callback_set_sending (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_invoke_callback_set_sending (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_callback_for_set_sending callback = (tp_cli_call_stream_callback_for_set_sending) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_call_set_sending (TpCallStream *proxy,
    gint timeout_ms,
    gboolean in_Send,
    tp_cli_call_stream_callback_for_set_sending callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetSending",
          G_TYPE_BOOLEAN, in_Send,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetSending", iface,
          _tp_cli_call_stream_invoke_callback_set_sending,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetSending",
              _tp_cli_call_stream_collect_callback_set_sending,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Send,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_collect_callback_request_receiving (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_invoke_callback_request_receiving (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_callback_for_request_receiving callback = (tp_cli_call_stream_callback_for_request_receiving) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_call_request_receiving (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Contact,
    gboolean in_Receive,
    tp_cli_call_stream_callback_for_request_receiving callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestReceiving",
          G_TYPE_UINT, in_Contact,
          G_TYPE_BOOLEAN, in_Receive,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestReceiving", iface,
          _tp_cli_call_stream_invoke_callback_request_receiving,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestReceiving",
              _tp_cli_call_stream_collect_callback_request_receiving,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_BOOLEAN, in_Receive,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_call_stream_interface_media (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "SendingStateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ReceivingStateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "LocalCandidatesAdded",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "LocalCredentialsChanged",
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "RelayInfoChanged",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "STUNServersChanged",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ServerInfoRetrieved",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "EndpointsChanged",
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ICERestartRequested",
      G_TYPE_INVALID);
}


static void
_tp_cli_call_stream_interface_media_collect_args_of_sending_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_State,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_sending_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_sending_state_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_sending_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_interface_media_connect_to_sending_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_sending_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "SendingStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_sending_state_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_sending_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_receiving_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_State,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_receiving_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_receiving_state_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_receiving_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_interface_media_connect_to_receiving_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_receiving_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "ReceivingStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_receiving_state_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_receiving_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_local_candidates_added (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Candidates,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Candidates);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_local_candidates_added (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_local_candidates_added callback =
      (tp_cli_call_stream_interface_media_signal_callback_local_candidates_added) generic_callback;

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
tp_cli_call_stream_interface_media_connect_to_local_candidates_added (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_local_candidates_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "LocalCandidatesAdded",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_local_candidates_added),
      _tp_cli_call_stream_interface_media_invoke_callback_for_local_candidates_added,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_local_credentials_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Username,
    const gchar *arg_Password,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_set_string (args->values + 0, arg_Username);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Password);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_local_credentials_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_local_credentials_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_local_credentials_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      g_value_get_string (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_interface_media_connect_to_local_credentials_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_local_credentials_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "LocalCredentialsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_local_credentials_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_local_credentials_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_relay_info_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Relay_Info,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_set_boxed (args->values + 0, arg_Relay_Info);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_relay_info_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_relay_info_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_relay_info_changed) generic_callback;

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
tp_cli_call_stream_interface_media_connect_to_relay_info_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_relay_info_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "RelayInfoChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_relay_info_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_relay_info_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_stun_servers_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Servers,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Servers);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_stun_servers_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_stun_servers_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_stun_servers_changed) generic_callback;

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
tp_cli_call_stream_interface_media_connect_to_stun_servers_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_stun_servers_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "STUNServersChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_stun_servers_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_stun_servers_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_invoke_callback_for_server_info_retrieved (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_server_info_retrieved callback =
      (tp_cli_call_stream_interface_media_signal_callback_server_info_retrieved) generic_callback;

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
tp_cli_call_stream_interface_media_connect_to_server_info_retrieved (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_server_info_retrieved callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "ServerInfoRetrieved",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_call_stream_interface_media_invoke_callback_for_server_info_retrieved,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_args_of_endpoints_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Endpoints_Added,
    const GPtrArray *arg_Endpoints_Removed,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));
  g_value_set_boxed (args->values + 0, arg_Endpoints_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));
  g_value_set_boxed (args->values + 1, arg_Endpoints_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_for_endpoints_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_endpoints_changed callback =
      (tp_cli_call_stream_interface_media_signal_callback_endpoints_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_interface_media_connect_to_endpoints_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_endpoints_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "EndpointsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_interface_media_collect_args_of_endpoints_changed),
      _tp_cli_call_stream_interface_media_invoke_callback_for_endpoints_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_invoke_callback_for_ice_restart_requested (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_signal_callback_ice_restart_requested callback =
      (tp_cli_call_stream_interface_media_signal_callback_ice_restart_requested) generic_callback;

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
tp_cli_call_stream_interface_media_connect_to_ice_restart_requested (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_ice_restart_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA, "ICERestartRequested",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_call_stream_interface_media_invoke_callback_for_ice_restart_requested,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_interface_media_collect_callback_complete_sending_state_change (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_complete_sending_state_change (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_complete_sending_state_change callback = (tp_cli_call_stream_interface_media_callback_for_complete_sending_state_change) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_complete_sending_state_change (TpCallStream *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_call_stream_interface_media_callback_for_complete_sending_state_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CompleteSendingStateChange",
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CompleteSendingStateChange", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_complete_sending_state_change,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CompleteSendingStateChange",
              _tp_cli_call_stream_interface_media_collect_callback_complete_sending_state_change,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_State,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_report_sending_failure (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_report_sending_failure (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_report_sending_failure callback = (tp_cli_call_stream_interface_media_callback_for_report_sending_failure) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_report_sending_failure (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_call_stream_interface_media_callback_for_report_sending_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReportSendingFailure",
          G_TYPE_UINT, in_Reason,
          G_TYPE_STRING, in_Error,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReportSendingFailure", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_report_sending_failure,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReportSendingFailure",
              _tp_cli_call_stream_interface_media_collect_callback_report_sending_failure,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Error,
              G_TYPE_STRING, in_Message,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_complete_receiving_state_change (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_complete_receiving_state_change (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_complete_receiving_state_change callback = (tp_cli_call_stream_interface_media_callback_for_complete_receiving_state_change) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_complete_receiving_state_change (TpCallStream *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_call_stream_interface_media_callback_for_complete_receiving_state_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CompleteReceivingStateChange",
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CompleteReceivingStateChange", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_complete_receiving_state_change,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CompleteReceivingStateChange",
              _tp_cli_call_stream_interface_media_collect_callback_complete_receiving_state_change,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_State,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_report_receiving_failure (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_report_receiving_failure (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_report_receiving_failure callback = (tp_cli_call_stream_interface_media_callback_for_report_receiving_failure) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_report_receiving_failure (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_call_stream_interface_media_callback_for_report_receiving_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReportReceivingFailure",
          G_TYPE_UINT, in_Reason,
          G_TYPE_STRING, in_Error,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReportReceivingFailure", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_report_receiving_failure,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReportReceivingFailure",
              _tp_cli_call_stream_interface_media_collect_callback_report_receiving_failure,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Error,
              G_TYPE_STRING, in_Message,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_set_credentials (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_set_credentials (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_set_credentials callback = (tp_cli_call_stream_interface_media_callback_for_set_credentials) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_set_credentials (TpCallStream *proxy,
    gint timeout_ms,
    const gchar *in_Username,
    const gchar *in_Password,
    tp_cli_call_stream_interface_media_callback_for_set_credentials callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetCredentials",
          G_TYPE_STRING, in_Username,
          G_TYPE_STRING, in_Password,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetCredentials", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_set_credentials,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetCredentials",
              _tp_cli_call_stream_interface_media_collect_callback_set_credentials,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Username,
              G_TYPE_STRING, in_Password,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_add_candidates (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_add_candidates (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_add_candidates callback = (tp_cli_call_stream_interface_media_callback_for_add_candidates) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_add_candidates (TpCallStream *proxy,
    gint timeout_ms,
    const GPtrArray *in_Candidates,
    tp_cli_call_stream_interface_media_callback_for_add_candidates callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddCandidates",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Candidates,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddCandidates", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_add_candidates,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddCandidates",
              _tp_cli_call_stream_interface_media_collect_callback_add_candidates,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Candidates,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_finish_initial_candidates (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_finish_initial_candidates (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_finish_initial_candidates callback = (tp_cli_call_stream_interface_media_callback_for_finish_initial_candidates) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_finish_initial_candidates (TpCallStream *proxy,
    gint timeout_ms,
    tp_cli_call_stream_interface_media_callback_for_finish_initial_candidates callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "FinishInitialCandidates",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "FinishInitialCandidates", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_finish_initial_candidates,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "FinishInitialCandidates",
              _tp_cli_call_stream_interface_media_collect_callback_finish_initial_candidates,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_interface_media_collect_callback_fail (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_interface_media_invoke_callback_fail (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_interface_media_callback_for_fail callback = (tp_cli_call_stream_interface_media_callback_for_fail) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallStream *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallStream *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_interface_media_call_fail (TpCallStream *proxy,
    gint timeout_ms,
    const GValueArray *in_Reason,
    tp_cli_call_stream_interface_media_callback_for_fail callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_STREAM (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Fail",
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Reason,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Fail", iface,
          _tp_cli_call_stream_interface_media_invoke_callback_fail,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Fail",
              _tp_cli_call_stream_interface_media_collect_callback_fail,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Reason,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_call_stream_add_signals:
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
tp_cli_call_stream_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CALL_STREAM)
    tp_cli_add_signals_for_call_stream (proxy);
  if (quark == TP_IFACE_QUARK_CALL_STREAM_INTERFACE_MEDIA)
    tp_cli_add_signals_for_call_stream_interface_media (proxy);
}
