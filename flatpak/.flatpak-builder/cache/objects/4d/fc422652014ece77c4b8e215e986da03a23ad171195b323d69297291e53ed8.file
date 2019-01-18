/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_call_stream_endpoint (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "RemoteCredentialsSet",
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "RemoteCandidatesAdded",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "CandidatePairSelected",
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "EndpointStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ControllingChanged",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_call_stream_endpoint_collect_args_of_remote_credentials_set (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_call_stream_endpoint_invoke_callback_for_remote_credentials_set (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_signal_callback_remote_credentials_set callback =
      (tp_cli_call_stream_endpoint_signal_callback_remote_credentials_set) generic_callback;

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
tp_cli_call_stream_endpoint_connect_to_remote_credentials_set (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_remote_credentials_set callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_ENDPOINT, "RemoteCredentialsSet",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_endpoint_collect_args_of_remote_credentials_set),
      _tp_cli_call_stream_endpoint_invoke_callback_for_remote_credentials_set,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_endpoint_collect_args_of_remote_candidates_added (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_call_stream_endpoint_invoke_callback_for_remote_candidates_added (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_signal_callback_remote_candidates_added callback =
      (tp_cli_call_stream_endpoint_signal_callback_remote_candidates_added) generic_callback;

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
tp_cli_call_stream_endpoint_connect_to_remote_candidates_added (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_remote_candidates_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_ENDPOINT, "RemoteCandidatesAdded",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_endpoint_collect_args_of_remote_candidates_added),
      _tp_cli_call_stream_endpoint_invoke_callback_for_remote_candidates_added,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_endpoint_collect_args_of_candidate_pair_selected (DBusGProxy *proxy G_GNUC_UNUSED,
    const GValueArray *arg_Local_Candidate,
    const GValueArray *arg_Remote_Candidate,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 0, arg_Local_Candidate);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 1, arg_Remote_Candidate);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_for_candidate_pair_selected (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_signal_callback_candidate_pair_selected callback =
      (tp_cli_call_stream_endpoint_signal_callback_candidate_pair_selected) generic_callback;

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
tp_cli_call_stream_endpoint_connect_to_candidate_pair_selected (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_candidate_pair_selected callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_ENDPOINT, "CandidatePairSelected",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_endpoint_collect_args_of_candidate_pair_selected),
      _tp_cli_call_stream_endpoint_invoke_callback_for_candidate_pair_selected,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_endpoint_collect_args_of_endpoint_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Component,
    guint arg_State,
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
  g_value_set_uint (args->values + 0, arg_Component);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_for_endpoint_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_signal_callback_endpoint_state_changed callback =
      (tp_cli_call_stream_endpoint_signal_callback_endpoint_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_endpoint_connect_to_endpoint_state_changed (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_endpoint_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_ENDPOINT, "EndpointStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_endpoint_collect_args_of_endpoint_state_changed),
      _tp_cli_call_stream_endpoint_invoke_callback_for_endpoint_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_endpoint_collect_args_of_controlling_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Controlling,
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
  g_value_init (args->values + 0, G_TYPE_BOOLEAN);
  g_value_set_boolean (args->values + 0, arg_Controlling);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_for_controlling_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_signal_callback_controlling_changed callback =
      (tp_cli_call_stream_endpoint_signal_callback_controlling_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boolean (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_stream_endpoint_connect_to_controlling_changed (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_controlling_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_STREAM_ENDPOINT, "ControllingChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_stream_endpoint_collect_args_of_controlling_changed),
      _tp_cli_call_stream_endpoint_invoke_callback_for_controlling_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_stream_endpoint_collect_callback_set_selected_candidate_pair (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_set_selected_candidate_pair (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_callback_for_set_selected_candidate_pair callback = (tp_cli_call_stream_endpoint_callback_for_set_selected_candidate_pair) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_endpoint_call_set_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_set_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_ENDPOINT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetSelectedCandidatePair",
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetSelectedCandidatePair", iface,
          _tp_cli_call_stream_endpoint_invoke_callback_set_selected_candidate_pair,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetSelectedCandidatePair",
              _tp_cli_call_stream_endpoint_collect_callback_set_selected_candidate_pair,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_endpoint_collect_callback_set_endpoint_state (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_set_endpoint_state (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_callback_for_set_endpoint_state callback = (tp_cli_call_stream_endpoint_callback_for_set_endpoint_state) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_endpoint_call_set_endpoint_state (gpointer proxy,
    gint timeout_ms,
    guint in_Component,
    guint in_State,
    tp_cli_call_stream_endpoint_callback_for_set_endpoint_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_ENDPOINT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetEndpointState",
          G_TYPE_UINT, in_Component,
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetEndpointState", iface,
          _tp_cli_call_stream_endpoint_invoke_callback_set_endpoint_state,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetEndpointState",
              _tp_cli_call_stream_endpoint_collect_callback_set_endpoint_state,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Component,
              G_TYPE_UINT, in_State,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_endpoint_collect_callback_accept_selected_candidate_pair (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_accept_selected_candidate_pair (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_callback_for_accept_selected_candidate_pair callback = (tp_cli_call_stream_endpoint_callback_for_accept_selected_candidate_pair) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_endpoint_call_accept_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_accept_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_ENDPOINT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcceptSelectedCandidatePair",
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcceptSelectedCandidatePair", iface,
          _tp_cli_call_stream_endpoint_invoke_callback_accept_selected_candidate_pair,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcceptSelectedCandidatePair",
              _tp_cli_call_stream_endpoint_collect_callback_accept_selected_candidate_pair,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_endpoint_collect_callback_reject_selected_candidate_pair (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_reject_selected_candidate_pair (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_callback_for_reject_selected_candidate_pair callback = (tp_cli_call_stream_endpoint_callback_for_reject_selected_candidate_pair) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_endpoint_call_reject_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_reject_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_ENDPOINT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RejectSelectedCandidatePair",
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RejectSelectedCandidatePair", iface,
          _tp_cli_call_stream_endpoint_invoke_callback_reject_selected_candidate_pair,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RejectSelectedCandidatePair",
              _tp_cli_call_stream_endpoint_collect_callback_reject_selected_candidate_pair,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Local_Candidate,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), in_Remote_Candidate,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_stream_endpoint_collect_callback_set_controlling (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_stream_endpoint_invoke_callback_set_controlling (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_stream_endpoint_callback_for_set_controlling callback = (tp_cli_call_stream_endpoint_callback_for_set_controlling) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_stream_endpoint_call_set_controlling (gpointer proxy,
    gint timeout_ms,
    gboolean in_Controlling,
    tp_cli_call_stream_endpoint_callback_for_set_controlling callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_STREAM_ENDPOINT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_PROXY (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetControlling",
          G_TYPE_BOOLEAN, in_Controlling,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetControlling", iface,
          _tp_cli_call_stream_endpoint_invoke_callback_set_controlling,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetControlling",
              _tp_cli_call_stream_endpoint_collect_callback_set_controlling,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Controlling,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_call_stream_endpoint_add_signals:
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
tp_cli_call_stream_endpoint_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CALL_STREAM_ENDPOINT)
    tp_cli_add_signals_for_call_stream_endpoint (proxy);
}
