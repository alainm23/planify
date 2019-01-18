/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_connection (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "SelfHandleChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SelfContactChanged",
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "NewChannel",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ConnectionError",
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StatusChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_collect_args_of_self_handle_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Self_Handle,
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
  g_value_set_uint (args->values + 0, arg_Self_Handle);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_invoke_callback_for_self_handle_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_signal_callback_self_handle_changed callback =
      (tp_cli_connection_signal_callback_self_handle_changed) generic_callback;

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
tp_cli_connection_connect_to_self_handle_changed (TpConnection *proxy,
    tp_cli_connection_signal_callback_self_handle_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION, "SelfHandleChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_collect_args_of_self_handle_changed),
      _tp_cli_connection_invoke_callback_for_self_handle_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_collect_args_of_self_contact_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Self_Handle,
    const gchar *arg_Self_ID,
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
  g_value_set_uint (args->values + 0, arg_Self_Handle);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Self_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_invoke_callback_for_self_contact_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_signal_callback_self_contact_changed callback =
      (tp_cli_connection_signal_callback_self_contact_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_string (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_connect_to_self_contact_changed (TpConnection *proxy,
    tp_cli_connection_signal_callback_self_contact_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION, "SelfContactChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_collect_args_of_self_contact_changed),
      _tp_cli_connection_invoke_callback_for_self_contact_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_collect_args_of_new_channel (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Object_Path,
    const gchar *arg_Channel_Type,
    guint arg_Handle_Type,
    guint arg_Handle,
    gboolean arg_Suppress_Handler,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (5);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 5; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Object_Path);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Channel_Type);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Handle_Type);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_UINT);
  g_value_set_uint (args->values + 3, arg_Handle);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, G_TYPE_BOOLEAN);
  g_value_set_boolean (args->values + 4, arg_Suppress_Handler);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_invoke_callback_for_new_channel (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_signal_callback_new_channel callback =
      (tp_cli_connection_signal_callback_new_channel) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_uint (args->values + 3),
      g_value_get_boolean (args->values + 4),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_connect_to_new_channel (TpConnection *proxy,
    tp_cli_connection_signal_callback_new_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[6] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION, "NewChannel",
      expected_types,
      G_CALLBACK (_tp_cli_connection_collect_args_of_new_channel),
      _tp_cli_connection_invoke_callback_for_new_channel,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_collect_args_of_connection_error (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Error,
    GHashTable *arg_Details,
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
  g_value_set_string (args->values + 0, arg_Error);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 1, arg_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_invoke_callback_for_connection_error (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_signal_callback_connection_error callback =
      (tp_cli_connection_signal_callback_connection_error) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      g_value_get_boxed (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_connect_to_connection_error (TpConnection *proxy,
    tp_cli_connection_signal_callback_connection_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION, "ConnectionError",
      expected_types,
      G_CALLBACK (_tp_cli_connection_collect_args_of_connection_error),
      _tp_cli_connection_invoke_callback_for_connection_error,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_collect_args_of_status_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Status,
    guint arg_Reason,
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
  g_value_set_uint (args->values + 0, arg_Status);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_invoke_callback_for_status_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_signal_callback_status_changed callback =
      (tp_cli_connection_signal_callback_status_changed) generic_callback;

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
tp_cli_connection_connect_to_status_changed (TpConnection *proxy,
    tp_cli_connection_signal_callback_status_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION, "StatusChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_collect_args_of_status_changed),
      _tp_cli_connection_invoke_callback_for_status_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_collect_callback_connect (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_connect (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_connect callback = (tp_cli_connection_callback_for_connect) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_connect (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_connect callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Connect",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Connect", iface,
          _tp_cli_connection_invoke_callback_connect,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Connect",
              _tp_cli_connection_collect_callback_connect,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_connect;
static void
_tp_cli_connection_finish_running_connect (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_connect *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_connect (TpConnection *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_connect state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Connect", iface,
      _tp_cli_connection_finish_running_connect,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Connect",
          _tp_cli_connection_collect_callback_connect,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_disconnect (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_disconnect (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_disconnect callback = (tp_cli_connection_callback_for_disconnect) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_disconnect (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_disconnect callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Disconnect",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Disconnect", iface,
          _tp_cli_connection_invoke_callback_disconnect,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Disconnect",
              _tp_cli_connection_collect_callback_disconnect,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_disconnect;
static void
_tp_cli_connection_finish_running_disconnect (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_disconnect *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_disconnect (TpConnection *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_disconnect state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Disconnect", iface,
      _tp_cli_connection_finish_running_disconnect,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Disconnect",
          _tp_cli_connection_collect_callback_disconnect,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_get_interfaces (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Interfaces;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Interfaces,
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
  g_value_take_boxed (args->values + 0, out_Interfaces);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_get_interfaces (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_get_interfaces callback = (tp_cli_connection_callback_for_get_interfaces) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_get_interfaces (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_get_interfaces callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetInterfaces",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetInterfaces", iface,
          _tp_cli_connection_invoke_callback_get_interfaces,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetInterfaces",
              _tp_cli_connection_collect_callback_get_interfaces,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_Interfaces;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_get_interfaces;
static void
_tp_cli_connection_finish_running_get_interfaces (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_get_interfaces *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Interfaces != NULL)
    *state->out_Interfaces = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_get_interfaces (TpConnection *proxy,
    gint timeout_ms,
    gchar ***out_Interfaces,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_get_interfaces state = {
      NULL /* loop */, error,
    out_Interfaces,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetInterfaces", iface,
      _tp_cli_connection_finish_running_get_interfaces,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetInterfaces",
          _tp_cli_connection_collect_callback_get_interfaces,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_get_protocol (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Protocol;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Protocol,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_take_string (args->values + 0, out_Protocol);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_get_protocol (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_get_protocol callback = (tp_cli_connection_callback_for_get_protocol) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_get_protocol (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_get_protocol callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetProtocol",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetProtocol", iface,
          _tp_cli_connection_invoke_callback_get_protocol,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetProtocol",
              _tp_cli_connection_collect_callback_get_protocol,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Protocol;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_get_protocol;
static void
_tp_cli_connection_finish_running_get_protocol (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_get_protocol *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Protocol != NULL)
    *state->out_Protocol = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_get_protocol (TpConnection *proxy,
    gint timeout_ms,
    gchar **out_Protocol,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_get_protocol state = {
      NULL /* loop */, error,
    out_Protocol,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetProtocol", iface,
      _tp_cli_connection_finish_running_get_protocol,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetProtocol",
          _tp_cli_connection_collect_callback_get_protocol,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_get_self_handle (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Self_Handle;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Self_Handle,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, out_Self_Handle);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_get_self_handle (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_get_self_handle callback = (tp_cli_connection_callback_for_get_self_handle) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_get_self_handle (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_get_self_handle callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetSelfHandle",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetSelfHandle", iface,
          _tp_cli_connection_invoke_callback_get_self_handle,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetSelfHandle",
              _tp_cli_connection_collect_callback_get_self_handle,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Self_Handle;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_get_self_handle;
static void
_tp_cli_connection_finish_running_get_self_handle (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_get_self_handle *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Self_Handle != NULL)
    *state->out_Self_Handle = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_get_self_handle (TpConnection *proxy,
    gint timeout_ms,
    guint *out_Self_Handle,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_get_self_handle state = {
      NULL /* loop */, error,
    out_Self_Handle,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetSelfHandle", iface,
      _tp_cli_connection_finish_running_get_self_handle,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetSelfHandle",
          _tp_cli_connection_collect_callback_get_self_handle,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_get_status (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Status;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Status,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, out_Status);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_get_status (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_get_status callback = (tp_cli_connection_callback_for_get_status) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_get_status (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_get_status callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetStatus",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetStatus", iface,
          _tp_cli_connection_invoke_callback_get_status,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetStatus",
              _tp_cli_connection_collect_callback_get_status,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Status;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_get_status;
static void
_tp_cli_connection_finish_running_get_status (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_get_status *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Status != NULL)
    *state->out_Status = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_get_status (TpConnection *proxy,
    gint timeout_ms,
    guint *out_Status,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_get_status state = {
      NULL /* loop */, error,
    out_Status,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetStatus", iface,
      _tp_cli_connection_finish_running_get_status,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetStatus",
          _tp_cli_connection_collect_callback_get_status,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_hold_handles (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_hold_handles (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_hold_handles callback = (tp_cli_connection_callback_for_hold_handles) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_hold_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    tp_cli_connection_callback_for_hold_handles callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "HoldHandles",
          G_TYPE_UINT, in_Handle_Type,
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "HoldHandles", iface,
          _tp_cli_connection_invoke_callback_hold_handles,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "HoldHandles",
              _tp_cli_connection_collect_callback_hold_handles,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_hold_handles;
static void
_tp_cli_connection_finish_running_hold_handles (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_hold_handles *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_hold_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_hold_handles state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "HoldHandles", iface,
      _tp_cli_connection_finish_running_hold_handles,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "HoldHandles",
          _tp_cli_connection_collect_callback_hold_handles,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_inspect_handles (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Identifiers;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Identifiers,
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
  g_value_take_boxed (args->values + 0, out_Identifiers);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_inspect_handles (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_inspect_handles callback = (tp_cli_connection_callback_for_inspect_handles) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_inspect_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    tp_cli_connection_callback_for_inspect_handles callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "InspectHandles",
          G_TYPE_UINT, in_Handle_Type,
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "InspectHandles", iface,
          _tp_cli_connection_invoke_callback_inspect_handles,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "InspectHandles",
              _tp_cli_connection_collect_callback_inspect_handles,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_Identifiers;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_inspect_handles;
static void
_tp_cli_connection_finish_running_inspect_handles (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_inspect_handles *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Identifiers != NULL)
    *state->out_Identifiers = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_inspect_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    gchar ***out_Identifiers,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_inspect_handles state = {
      NULL /* loop */, error,
    out_Identifiers,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "InspectHandles", iface,
      _tp_cli_connection_finish_running_inspect_handles,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "InspectHandles",
          _tp_cli_connection_collect_callback_inspect_handles,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_list_channels (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Channel_Info;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))), &out_Channel_Info,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Channel_Info);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_list_channels (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_list_channels callback = (tp_cli_connection_callback_for_list_channels) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_list_channels (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_callback_for_list_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListChannels",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListChannels", iface,
          _tp_cli_connection_invoke_callback_list_channels,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListChannels",
              _tp_cli_connection_collect_callback_list_channels,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Channel_Info;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_list_channels;
static void
_tp_cli_connection_finish_running_list_channels (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_list_channels *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Channel_Info != NULL)
    *state->out_Channel_Info = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_list_channels (TpConnection *proxy,
    gint timeout_ms,
    GPtrArray **out_Channel_Info,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_list_channels state = {
      NULL /* loop */, error,
    out_Channel_Info,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListChannels", iface,
      _tp_cli_connection_finish_running_list_channels,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListChannels",
          _tp_cli_connection_collect_callback_list_channels,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_release_handles (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_release_handles (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_release_handles callback = (tp_cli_connection_callback_for_release_handles) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_release_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    tp_cli_connection_callback_for_release_handles callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReleaseHandles",
          G_TYPE_UINT, in_Handle_Type,
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReleaseHandles", iface,
          _tp_cli_connection_invoke_callback_release_handles,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReleaseHandles",
              _tp_cli_connection_collect_callback_release_handles,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_release_handles;
static void
_tp_cli_connection_finish_running_release_handles (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_release_handles *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_release_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const GArray *in_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_release_handles state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ReleaseHandles", iface,
      _tp_cli_connection_finish_running_release_handles,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ReleaseHandles",
          _tp_cli_connection_collect_callback_release_handles,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_request_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Object_Path;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Object_Path,
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
  g_value_take_boxed (args->values + 0, out_Object_Path);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_request_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_request_channel callback = (tp_cli_connection_callback_for_request_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_request_channel (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Type,
    guint in_Handle_Type,
    guint in_Handle,
    gboolean in_Suppress_Handler,
    tp_cli_connection_callback_for_request_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestChannel",
          G_TYPE_STRING, in_Type,
          G_TYPE_UINT, in_Handle_Type,
          G_TYPE_UINT, in_Handle,
          G_TYPE_BOOLEAN, in_Suppress_Handler,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestChannel", iface,
          _tp_cli_connection_invoke_callback_request_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestChannel",
              _tp_cli_connection_collect_callback_request_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Type,
              G_TYPE_UINT, in_Handle_Type,
              G_TYPE_UINT, in_Handle,
              G_TYPE_BOOLEAN, in_Suppress_Handler,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Object_Path;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_request_channel;
static void
_tp_cli_connection_finish_running_request_channel (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_request_channel *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Object_Path != NULL)
    *state->out_Object_Path = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_request_channel (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Type,
    guint in_Handle_Type,
    guint in_Handle,
    gboolean in_Suppress_Handler,
    gchar **out_Object_Path,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_request_channel state = {
      NULL /* loop */, error,
    out_Object_Path,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestChannel", iface,
      _tp_cli_connection_finish_running_request_channel,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestChannel",
          _tp_cli_connection_collect_callback_request_channel,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Type,
              G_TYPE_UINT, in_Handle_Type,
              G_TYPE_UINT, in_Handle,
              G_TYPE_BOOLEAN, in_Suppress_Handler,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_request_handles (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Handles;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_UINT_ARRAY, &out_Handles,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_UINT_ARRAY);
  g_value_take_boxed (args->values + 0, out_Handles);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_invoke_callback_request_handles (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_request_handles callback = (tp_cli_connection_callback_for_request_handles) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_request_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const gchar **in_Identifiers,
    tp_cli_connection_callback_for_request_handles callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestHandles",
          G_TYPE_UINT, in_Handle_Type,
          G_TYPE_STRV, in_Identifiers,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestHandles", iface,
          _tp_cli_connection_invoke_callback_request_handles,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestHandles",
              _tp_cli_connection_collect_callback_request_handles,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              G_TYPE_STRV, in_Identifiers,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GArray **out_Handles;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_request_handles;
static void
_tp_cli_connection_finish_running_request_handles (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_request_handles *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Handles != NULL)
    *state->out_Handles = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_request_handles (TpConnection *proxy,
    gint timeout_ms,
    guint in_Handle_Type,
    const gchar **in_Identifiers,
    GArray **out_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_request_handles state = {
      NULL /* loop */, error,
    out_Handles,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestHandles", iface,
      _tp_cli_connection_finish_running_request_handles,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestHandles",
          _tp_cli_connection_collect_callback_request_handles,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Handle_Type,
              G_TYPE_STRV, in_Identifiers,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_add_client_interest (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_add_client_interest (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_add_client_interest callback = (tp_cli_connection_callback_for_add_client_interest) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_add_client_interest (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Tokens,
    tp_cli_connection_callback_for_add_client_interest callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddClientInterest",
          G_TYPE_STRV, in_Tokens,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddClientInterest", iface,
          _tp_cli_connection_invoke_callback_add_client_interest,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddClientInterest",
              _tp_cli_connection_collect_callback_add_client_interest,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRV, in_Tokens,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_add_client_interest;
static void
_tp_cli_connection_finish_running_add_client_interest (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_add_client_interest *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_add_client_interest (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Tokens,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_add_client_interest state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AddClientInterest", iface,
      _tp_cli_connection_finish_running_add_client_interest,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AddClientInterest",
          _tp_cli_connection_collect_callback_add_client_interest,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRV, in_Tokens,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_collect_callback_remove_client_interest (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_invoke_callback_remove_client_interest (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_callback_for_remove_client_interest callback = (tp_cli_connection_callback_for_remove_client_interest) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_call_remove_client_interest (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Tokens,
    tp_cli_connection_callback_for_remove_client_interest callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveClientInterest",
          G_TYPE_STRV, in_Tokens,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveClientInterest", iface,
          _tp_cli_connection_invoke_callback_remove_client_interest,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveClientInterest",
              _tp_cli_connection_collect_callback_remove_client_interest,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRV, in_Tokens,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_run_state_remove_client_interest;
static void
_tp_cli_connection_finish_running_remove_client_interest (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_run_state_remove_client_interest *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_run_remove_client_interest (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Tokens,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_run_state_remove_client_interest state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveClientInterest", iface,
      _tp_cli_connection_finish_running_remove_client_interest,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveClientInterest",
          _tp_cli_connection_collect_callback_remove_client_interest,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRV, in_Tokens,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_addressing_collect_callback_get_contacts_by_vcard_field (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Requested;
  GHashTable *out_Attributes;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_UINT)), &out_Requested,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), &out_Attributes,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_UINT)));
  g_value_take_boxed (args->values + 0, out_Requested);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_take_boxed (args->values + 1, out_Attributes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_addressing_invoke_callback_get_contacts_by_vcard_field (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_addressing_callback_for_get_contacts_by_vcard_field callback = (tp_cli_connection_interface_addressing_callback_for_get_contacts_by_vcard_field) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_addressing_call_get_contacts_by_vcard_field (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Field,
    const gchar **in_Addresses,
    const gchar **in_Interfaces,
    tp_cli_connection_interface_addressing_callback_for_get_contacts_by_vcard_field callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ADDRESSING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactsByVCardField",
          G_TYPE_STRING, in_Field,
          G_TYPE_STRV, in_Addresses,
          G_TYPE_STRV, in_Interfaces,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactsByVCardField", iface,
          _tp_cli_connection_interface_addressing_invoke_callback_get_contacts_by_vcard_field,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactsByVCardField",
              _tp_cli_connection_interface_addressing_collect_callback_get_contacts_by_vcard_field,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Field,
              G_TYPE_STRV, in_Addresses,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_connection_interface_addressing_collect_callback_get_contacts_by_uri (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Requested;
  GHashTable *out_Attributes;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_UINT)), &out_Requested,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), &out_Attributes,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_UINT)));
  g_value_take_boxed (args->values + 0, out_Requested);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_take_boxed (args->values + 1, out_Attributes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_addressing_invoke_callback_get_contacts_by_uri (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_addressing_callback_for_get_contacts_by_uri callback = (tp_cli_connection_interface_addressing_callback_for_get_contacts_by_uri) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_addressing_call_get_contacts_by_uri (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_URIs,
    const gchar **in_Interfaces,
    tp_cli_connection_interface_addressing_callback_for_get_contacts_by_uri callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ADDRESSING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactsByURI",
          G_TYPE_STRV, in_URIs,
          G_TYPE_STRV, in_Interfaces,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactsByURI", iface,
          _tp_cli_connection_interface_addressing_invoke_callback_get_contacts_by_uri,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactsByURI",
              _tp_cli_connection_interface_addressing_collect_callback_get_contacts_by_uri,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRV, in_URIs,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_connection_interface_aliasing (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AliasesChanged",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_aliasing_collect_args_of_aliases_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Aliases,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Aliases);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_aliasing_invoke_callback_for_aliases_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_aliasing_signal_callback_aliases_changed callback =
      (tp_cli_connection_interface_aliasing_signal_callback_aliases_changed) generic_callback;

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
tp_cli_connection_interface_aliasing_connect_to_aliases_changed (TpConnection *proxy,
    tp_cli_connection_interface_aliasing_signal_callback_aliases_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING, "AliasesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_aliasing_collect_args_of_aliases_changed),
      _tp_cli_connection_interface_aliasing_invoke_callback_for_aliases_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_aliasing_collect_callback_get_alias_flags (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Alias_Flags;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Alias_Flags,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, out_Alias_Flags);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_aliasing_invoke_callback_get_alias_flags (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_aliasing_callback_for_get_alias_flags callback = (tp_cli_connection_interface_aliasing_callback_for_get_alias_flags) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_aliasing_call_get_alias_flags (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_aliasing_callback_for_get_alias_flags callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetAliasFlags",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAliasFlags", iface,
          _tp_cli_connection_interface_aliasing_invoke_callback_get_alias_flags,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAliasFlags",
              _tp_cli_connection_interface_aliasing_collect_callback_get_alias_flags,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Alias_Flags;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_aliasing_run_state_get_alias_flags;
static void
_tp_cli_connection_interface_aliasing_finish_running_get_alias_flags (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_aliasing_run_state_get_alias_flags *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Alias_Flags != NULL)
    *state->out_Alias_Flags = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_aliasing_run_get_alias_flags (TpConnection *proxy,
    gint timeout_ms,
    guint *out_Alias_Flags,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_aliasing_run_state_get_alias_flags state = {
      NULL /* loop */, error,
    out_Alias_Flags,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAliasFlags", iface,
      _tp_cli_connection_interface_aliasing_finish_running_get_alias_flags,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAliasFlags",
          _tp_cli_connection_interface_aliasing_collect_callback_get_alias_flags,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_aliasing_collect_callback_request_aliases (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Aliases;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Aliases,
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
  g_value_take_boxed (args->values + 0, out_Aliases);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_aliasing_invoke_callback_request_aliases (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_aliasing_callback_for_request_aliases callback = (tp_cli_connection_interface_aliasing_callback_for_request_aliases) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_aliasing_call_request_aliases (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_aliasing_callback_for_request_aliases callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestAliases",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestAliases", iface,
          _tp_cli_connection_interface_aliasing_invoke_callback_request_aliases,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestAliases",
              _tp_cli_connection_interface_aliasing_collect_callback_request_aliases,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_Aliases;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_aliasing_run_state_request_aliases;
static void
_tp_cli_connection_interface_aliasing_finish_running_request_aliases (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_aliasing_run_state_request_aliases *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Aliases != NULL)
    *state->out_Aliases = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_aliasing_run_request_aliases (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    gchar ***out_Aliases,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_aliasing_run_state_request_aliases state = {
      NULL /* loop */, error,
    out_Aliases,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestAliases", iface,
      _tp_cli_connection_interface_aliasing_finish_running_request_aliases,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestAliases",
          _tp_cli_connection_interface_aliasing_collect_callback_request_aliases,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_aliasing_collect_callback_get_aliases (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Aliases;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), &out_Aliases,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_take_boxed (args->values + 0, out_Aliases);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_aliasing_invoke_callback_get_aliases (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_aliasing_callback_for_get_aliases callback = (tp_cli_connection_interface_aliasing_callback_for_get_aliases) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_aliasing_call_get_aliases (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_aliasing_callback_for_get_aliases callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetAliases",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAliases", iface,
          _tp_cli_connection_interface_aliasing_invoke_callback_get_aliases,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAliases",
              _tp_cli_connection_interface_aliasing_collect_callback_get_aliases,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Aliases;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_aliasing_run_state_get_aliases;
static void
_tp_cli_connection_interface_aliasing_finish_running_get_aliases (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_aliasing_run_state_get_aliases *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Aliases != NULL)
    *state->out_Aliases = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_aliasing_run_get_aliases (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Aliases,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_aliasing_run_state_get_aliases state = {
      NULL /* loop */, error,
    out_Aliases,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAliases", iface,
      _tp_cli_connection_interface_aliasing_finish_running_get_aliases,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAliases",
          _tp_cli_connection_interface_aliasing_collect_callback_get_aliases,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_aliasing_collect_callback_set_aliases (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_aliasing_invoke_callback_set_aliases (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_aliasing_callback_for_set_aliases callback = (tp_cli_connection_interface_aliasing_callback_for_set_aliases) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_aliasing_call_set_aliases (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Aliases,
    tp_cli_connection_interface_aliasing_callback_for_set_aliases callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetAliases",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), in_Aliases,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetAliases", iface,
          _tp_cli_connection_interface_aliasing_invoke_callback_set_aliases,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetAliases",
              _tp_cli_connection_interface_aliasing_collect_callback_set_aliases,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), in_Aliases,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_aliasing_run_state_set_aliases;
static void
_tp_cli_connection_interface_aliasing_finish_running_set_aliases (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_aliasing_run_state_set_aliases *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_aliasing_run_set_aliases (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Aliases,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_aliasing_run_state_set_aliases state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetAliases", iface,
      _tp_cli_connection_interface_aliasing_finish_running_set_aliases,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetAliases",
          _tp_cli_connection_interface_aliasing_collect_callback_set_aliases,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), in_Aliases,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_anonymity (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AnonymityModesChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_anonymity_collect_args_of_anonymity_modes_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Modes,
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
  g_value_set_uint (args->values + 0, arg_Modes);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_anonymity_invoke_callback_for_anonymity_modes_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_anonymity_signal_callback_anonymity_modes_changed callback =
      (tp_cli_connection_interface_anonymity_signal_callback_anonymity_modes_changed) generic_callback;

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
tp_cli_connection_interface_anonymity_connect_to_anonymity_modes_changed (TpConnection *proxy,
    tp_cli_connection_interface_anonymity_signal_callback_anonymity_modes_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_ANONYMITY, "AnonymityModesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_anonymity_collect_args_of_anonymity_modes_changed),
      _tp_cli_connection_interface_anonymity_invoke_callback_for_anonymity_modes_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static inline void
tp_cli_add_signals_for_connection_interface_avatars (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AvatarUpdated",
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "AvatarRetrieved",
      G_TYPE_UINT,
      G_TYPE_STRING,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR),
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_avatars_collect_args_of_avatar_updated (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
    const gchar *arg_New_Avatar_Token,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_New_Avatar_Token);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_for_avatar_updated (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_signal_callback_avatar_updated callback =
      (tp_cli_connection_interface_avatars_signal_callback_avatar_updated) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_string (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_avatars_connect_to_avatar_updated (TpConnection *proxy,
    tp_cli_connection_interface_avatars_signal_callback_avatar_updated callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS, "AvatarUpdated",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_avatars_collect_args_of_avatar_updated),
      _tp_cli_connection_interface_avatars_invoke_callback_for_avatar_updated,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_avatars_collect_args_of_avatar_retrieved (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
    const gchar *arg_Token,
    const GArray *arg_Avatar,
    const gchar *arg_Type,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Token);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR));
  g_value_set_boxed (args->values + 2, arg_Avatar);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_STRING);
  g_value_set_string (args->values + 3, arg_Type);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_for_avatar_retrieved (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_signal_callback_avatar_retrieved callback =
      (tp_cli_connection_interface_avatars_signal_callback_avatar_retrieved) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_boxed (args->values + 2),
      g_value_get_string (args->values + 3),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_avatars_connect_to_avatar_retrieved (TpConnection *proxy,
    tp_cli_connection_interface_avatars_signal_callback_avatar_retrieved callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR),
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS, "AvatarRetrieved",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_avatars_collect_args_of_avatar_retrieved),
      _tp_cli_connection_interface_avatars_invoke_callback_for_avatar_retrieved,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_avatars_collect_callback_get_avatar_requirements (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_MIME_Types;
  guint out_Min_Width;
  guint out_Min_Height;
  guint out_Max_Width;
  guint out_Max_Height;
  guint out_Max_Bytes;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_MIME_Types,
      G_TYPE_UINT, &out_Min_Width,
      G_TYPE_UINT, &out_Min_Height,
      G_TYPE_UINT, &out_Max_Width,
      G_TYPE_UINT, &out_Max_Height,
      G_TYPE_UINT, &out_Max_Bytes,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (6);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 6; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_STRV);
  g_value_take_boxed (args->values + 0, out_MIME_Types);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, out_Min_Width);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, out_Min_Height);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_UINT);
  g_value_set_uint (args->values + 3, out_Max_Width);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, G_TYPE_UINT);
  g_value_set_uint (args->values + 4, out_Max_Height);

  g_value_unset (args->values + 5);
  g_value_init (args->values + 5, G_TYPE_UINT);
  g_value_set_uint (args->values + 5, out_Max_Bytes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_get_avatar_requirements (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_get_avatar_requirements callback = (tp_cli_connection_interface_avatars_callback_for_get_avatar_requirements) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          0,
          0,
          0,
          0,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_uint (args->values + 3),
      g_value_get_uint (args->values + 4),
      g_value_get_uint (args->values + 5),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_get_avatar_requirements (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_avatars_callback_for_get_avatar_requirements callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            0,
            0,
            0,
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetAvatarRequirements",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAvatarRequirements", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_get_avatar_requirements,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAvatarRequirements",
              _tp_cli_connection_interface_avatars_collect_callback_get_avatar_requirements,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_MIME_Types;
    guint *out_Min_Width;
    guint *out_Min_Height;
    guint *out_Max_Width;
    guint *out_Max_Height;
    guint *out_Max_Bytes;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_get_avatar_requirements;
static void
_tp_cli_connection_interface_avatars_finish_running_get_avatar_requirements (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_get_avatar_requirements *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_MIME_Types != NULL)
    *state->out_MIME_Types = g_value_dup_boxed (args->values + 0);

  if (state->out_Min_Width != NULL)
    *state->out_Min_Width = g_value_get_uint (args->values + 1);

  if (state->out_Min_Height != NULL)
    *state->out_Min_Height = g_value_get_uint (args->values + 2);

  if (state->out_Max_Width != NULL)
    *state->out_Max_Width = g_value_get_uint (args->values + 3);

  if (state->out_Max_Height != NULL)
    *state->out_Max_Height = g_value_get_uint (args->values + 4);

  if (state->out_Max_Bytes != NULL)
    *state->out_Max_Bytes = g_value_get_uint (args->values + 5);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_get_avatar_requirements (TpConnection *proxy,
    gint timeout_ms,
    gchar ***out_MIME_Types,
    guint *out_Min_Width,
    guint *out_Min_Height,
    guint *out_Max_Width,
    guint *out_Max_Height,
    guint *out_Max_Bytes,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_get_avatar_requirements state = {
      NULL /* loop */, error,
    out_MIME_Types,
    out_Min_Width,
    out_Min_Height,
    out_Max_Width,
    out_Max_Height,
    out_Max_Bytes,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAvatarRequirements", iface,
      _tp_cli_connection_interface_avatars_finish_running_get_avatar_requirements,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAvatarRequirements",
          _tp_cli_connection_interface_avatars_collect_callback_get_avatar_requirements,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_get_avatar_tokens (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Tokens;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Tokens,
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
  g_value_take_boxed (args->values + 0, out_Tokens);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_get_avatar_tokens (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_get_avatar_tokens callback = (tp_cli_connection_interface_avatars_callback_for_get_avatar_tokens) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_get_avatar_tokens (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_avatars_callback_for_get_avatar_tokens callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetAvatarTokens",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAvatarTokens", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_get_avatar_tokens,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAvatarTokens",
              _tp_cli_connection_interface_avatars_collect_callback_get_avatar_tokens,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_Tokens;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_get_avatar_tokens;
static void
_tp_cli_connection_interface_avatars_finish_running_get_avatar_tokens (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_get_avatar_tokens *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Tokens != NULL)
    *state->out_Tokens = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_get_avatar_tokens (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    gchar ***out_Tokens,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_get_avatar_tokens state = {
      NULL /* loop */, error,
    out_Tokens,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAvatarTokens", iface,
      _tp_cli_connection_interface_avatars_finish_running_get_avatar_tokens,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAvatarTokens",
          _tp_cli_connection_interface_avatars_collect_callback_get_avatar_tokens,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_get_known_avatar_tokens (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Tokens;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), &out_Tokens,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_take_boxed (args->values + 0, out_Tokens);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_get_known_avatar_tokens (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_get_known_avatar_tokens callback = (tp_cli_connection_interface_avatars_callback_for_get_known_avatar_tokens) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_get_known_avatar_tokens (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_avatars_callback_for_get_known_avatar_tokens callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetKnownAvatarTokens",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetKnownAvatarTokens", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_get_known_avatar_tokens,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetKnownAvatarTokens",
              _tp_cli_connection_interface_avatars_collect_callback_get_known_avatar_tokens,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Tokens;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_get_known_avatar_tokens;
static void
_tp_cli_connection_interface_avatars_finish_running_get_known_avatar_tokens (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_get_known_avatar_tokens *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Tokens != NULL)
    *state->out_Tokens = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_get_known_avatar_tokens (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Tokens,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_get_known_avatar_tokens state = {
      NULL /* loop */, error,
    out_Tokens,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetKnownAvatarTokens", iface,
      _tp_cli_connection_interface_avatars_finish_running_get_known_avatar_tokens,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetKnownAvatarTokens",
          _tp_cli_connection_interface_avatars_collect_callback_get_known_avatar_tokens,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_request_avatar (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Data;
  gchar *out_MIME_Type;

  dbus_g_proxy_end_call (proxy, call, &error,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), &out_Data,
      G_TYPE_STRING, &out_MIME_Type,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR));
  g_value_take_boxed (args->values + 0, out_Data);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_take_string (args->values + 1, out_MIME_Type);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_request_avatar (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_request_avatar callback = (tp_cli_connection_interface_avatars_callback_for_request_avatar) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_string (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_request_avatar (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    tp_cli_connection_interface_avatars_callback_for_request_avatar callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "RequestAvatar",
          G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestAvatar", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_request_avatar,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestAvatar",
              _tp_cli_connection_interface_avatars_collect_callback_request_avatar,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GArray **out_Data;
    gchar **out_MIME_Type;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_request_avatar;
static void
_tp_cli_connection_interface_avatars_finish_running_request_avatar (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_request_avatar *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Data != NULL)
    *state->out_Data = g_value_dup_boxed (args->values + 0);

  if (state->out_MIME_Type != NULL)
    *state->out_MIME_Type = g_value_dup_string (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_request_avatar (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    GArray **out_Data,
    gchar **out_MIME_Type,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_request_avatar state = {
      NULL /* loop */, error,
    out_Data,
    out_MIME_Type,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestAvatar", iface,
      _tp_cli_connection_interface_avatars_finish_running_request_avatar,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestAvatar",
          _tp_cli_connection_interface_avatars_collect_callback_request_avatar,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_request_avatars (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_request_avatars (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_request_avatars callback = (tp_cli_connection_interface_avatars_callback_for_request_avatars) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_request_avatars (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_avatars_callback_for_request_avatars callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestAvatars",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestAvatars", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_request_avatars,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestAvatars",
              _tp_cli_connection_interface_avatars_collect_callback_request_avatars,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_request_avatars;
static void
_tp_cli_connection_interface_avatars_finish_running_request_avatars (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_request_avatars *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_request_avatars (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_request_avatars state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestAvatars", iface,
      _tp_cli_connection_interface_avatars_finish_running_request_avatars,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestAvatars",
          _tp_cli_connection_interface_avatars_collect_callback_request_avatars,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_set_avatar (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Token;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Token,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_take_string (args->values + 0, out_Token);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_set_avatar (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_set_avatar callback = (tp_cli_connection_interface_avatars_callback_for_set_avatar) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_set_avatar (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Avatar,
    const gchar *in_MIME_Type,
    tp_cli_connection_interface_avatars_callback_for_set_avatar callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetAvatar",
          dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Avatar,
          G_TYPE_STRING, in_MIME_Type,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetAvatar", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_set_avatar,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetAvatar",
              _tp_cli_connection_interface_avatars_collect_callback_set_avatar,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Avatar,
              G_TYPE_STRING, in_MIME_Type,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Token;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_set_avatar;
static void
_tp_cli_connection_interface_avatars_finish_running_set_avatar (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_set_avatar *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Token != NULL)
    *state->out_Token = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_set_avatar (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Avatar,
    const gchar *in_MIME_Type,
    gchar **out_Token,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_set_avatar state = {
      NULL /* loop */, error,
    out_Token,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetAvatar", iface,
      _tp_cli_connection_interface_avatars_finish_running_set_avatar,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetAvatar",
          _tp_cli_connection_interface_avatars_collect_callback_set_avatar,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Avatar,
              G_TYPE_STRING, in_MIME_Type,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_avatars_collect_callback_clear_avatar (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_avatars_invoke_callback_clear_avatar (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_avatars_callback_for_clear_avatar callback = (tp_cli_connection_interface_avatars_callback_for_clear_avatar) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_avatars_call_clear_avatar (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_avatars_callback_for_clear_avatar callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ClearAvatar",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ClearAvatar", iface,
          _tp_cli_connection_interface_avatars_invoke_callback_clear_avatar,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ClearAvatar",
              _tp_cli_connection_interface_avatars_collect_callback_clear_avatar,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_avatars_run_state_clear_avatar;
static void
_tp_cli_connection_interface_avatars_finish_running_clear_avatar (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_avatars_run_state_clear_avatar *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_avatars_run_clear_avatar (TpConnection *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_avatars_run_state_clear_avatar state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ClearAvatar", iface,
      _tp_cli_connection_interface_avatars_finish_running_clear_avatar,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ClearAvatar",
          _tp_cli_connection_interface_avatars_collect_callback_clear_avatar,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_balance (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "BalanceChanged",
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_balance_collect_args_of_balance_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GValueArray *arg_Balance,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 0, arg_Balance);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_balance_invoke_callback_for_balance_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_balance_signal_callback_balance_changed callback =
      (tp_cli_connection_interface_balance_signal_callback_balance_changed) generic_callback;

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
tp_cli_connection_interface_balance_connect_to_balance_changed (TpConnection *proxy,
    tp_cli_connection_interface_balance_signal_callback_balance_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_BALANCE, "BalanceChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_balance_collect_args_of_balance_changed),
      _tp_cli_connection_interface_balance_invoke_callback_for_balance_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static inline void
tp_cli_add_signals_for_connection_interface_capabilities (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "CapabilitiesChanged",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_capabilities_collect_args_of_capabilities_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Caps,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Caps);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_capabilities_invoke_callback_for_capabilities_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_capabilities_signal_callback_capabilities_changed callback =
      (tp_cli_connection_interface_capabilities_signal_callback_capabilities_changed) generic_callback;

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
tp_cli_connection_interface_capabilities_connect_to_capabilities_changed (TpConnection *proxy,
    tp_cli_connection_interface_capabilities_signal_callback_capabilities_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES, "CapabilitiesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_capabilities_collect_args_of_capabilities_changed),
      _tp_cli_connection_interface_capabilities_invoke_callback_for_capabilities_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_capabilities_collect_callback_advertise_capabilities (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Self_Capabilities;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))), &out_Self_Capabilities,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Self_Capabilities);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_capabilities_invoke_callback_advertise_capabilities (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_capabilities_callback_for_advertise_capabilities callback = (tp_cli_connection_interface_capabilities_callback_for_advertise_capabilities) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_capabilities_call_advertise_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_Add,
    const gchar **in_Remove,
    tp_cli_connection_interface_capabilities_callback_for_advertise_capabilities callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AdvertiseCapabilities",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))), in_Add,
          G_TYPE_STRV, in_Remove,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AdvertiseCapabilities", iface,
          _tp_cli_connection_interface_capabilities_invoke_callback_advertise_capabilities,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AdvertiseCapabilities",
              _tp_cli_connection_interface_capabilities_collect_callback_advertise_capabilities,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))), in_Add,
              G_TYPE_STRV, in_Remove,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Self_Capabilities;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_capabilities_run_state_advertise_capabilities;
static void
_tp_cli_connection_interface_capabilities_finish_running_advertise_capabilities (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_capabilities_run_state_advertise_capabilities *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Self_Capabilities != NULL)
    *state->out_Self_Capabilities = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_capabilities_run_advertise_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_Add,
    const gchar **in_Remove,
    GPtrArray **out_Self_Capabilities,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_capabilities_run_state_advertise_capabilities state = {
      NULL /* loop */, error,
    out_Self_Capabilities,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AdvertiseCapabilities", iface,
      _tp_cli_connection_interface_capabilities_finish_running_advertise_capabilities,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AdvertiseCapabilities",
          _tp_cli_connection_interface_capabilities_collect_callback_advertise_capabilities,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))), in_Add,
              G_TYPE_STRV, in_Remove,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_capabilities_collect_callback_get_capabilities (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Contact_Capabilities;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))), &out_Contact_Capabilities,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Contact_Capabilities);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_capabilities_invoke_callback_get_capabilities (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_capabilities_callback_for_get_capabilities callback = (tp_cli_connection_interface_capabilities_callback_for_get_capabilities) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_capabilities_call_get_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    tp_cli_connection_interface_capabilities_callback_for_get_capabilities callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetCapabilities",
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetCapabilities", iface,
          _tp_cli_connection_interface_capabilities_invoke_callback_get_capabilities,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetCapabilities",
              _tp_cli_connection_interface_capabilities_collect_callback_get_capabilities,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Contact_Capabilities;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_capabilities_run_state_get_capabilities;
static void
_tp_cli_connection_interface_capabilities_finish_running_get_capabilities (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_capabilities_run_state_get_capabilities *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Contact_Capabilities != NULL)
    *state->out_Contact_Capabilities = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_capabilities_run_get_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    GPtrArray **out_Contact_Capabilities,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_capabilities_run_state_get_capabilities state = {
      NULL /* loop */, error,
    out_Contact_Capabilities,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetCapabilities", iface,
      _tp_cli_connection_interface_capabilities_finish_running_get_capabilities,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetCapabilities",
          _tp_cli_connection_interface_capabilities_collect_callback_get_capabilities,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_cellular (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "IMSIChanged",
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_cellular_collect_args_of_imsi_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_IMSI,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_set_string (args->values + 0, arg_IMSI);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_cellular_invoke_callback_for_imsi_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_cellular_signal_callback_imsi_changed callback =
      (tp_cli_connection_interface_cellular_signal_callback_imsi_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_cellular_connect_to_imsi_changed (TpConnection *proxy,
    tp_cli_connection_interface_cellular_signal_callback_imsi_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CELLULAR, "IMSIChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_cellular_collect_args_of_imsi_changed),
      _tp_cli_connection_interface_cellular_invoke_callback_for_imsi_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static inline void
tp_cli_add_signals_for_connection_interface_client_types (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ClientTypesUpdated",
      G_TYPE_UINT,
      G_TYPE_STRV,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_client_types_collect_args_of_client_types_updated (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
    const gchar **arg_Client_Types,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRV);
  g_value_set_boxed (args->values + 1, arg_Client_Types);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_client_types_invoke_callback_for_client_types_updated (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_client_types_signal_callback_client_types_updated callback =
      (tp_cli_connection_interface_client_types_signal_callback_client_types_updated) generic_callback;

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
tp_cli_connection_interface_client_types_connect_to_client_types_updated (TpConnection *proxy,
    tp_cli_connection_interface_client_types_signal_callback_client_types_updated callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_STRV,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES, "ClientTypesUpdated",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_client_types_collect_args_of_client_types_updated),
      _tp_cli_connection_interface_client_types_invoke_callback_for_client_types_updated,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_client_types_collect_callback_get_client_types (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Client_Types;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRV)), &out_Client_Types,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRV)));
  g_value_take_boxed (args->values + 0, out_Client_Types);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_client_types_invoke_callback_get_client_types (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_client_types_callback_for_get_client_types callback = (tp_cli_connection_interface_client_types_callback_for_get_client_types) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_client_types_call_get_client_types (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_client_types_callback_for_get_client_types callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetClientTypes",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetClientTypes", iface,
          _tp_cli_connection_interface_client_types_invoke_callback_get_client_types,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetClientTypes",
              _tp_cli_connection_interface_client_types_collect_callback_get_client_types,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Client_Types;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_client_types_run_state_get_client_types;
static void
_tp_cli_connection_interface_client_types_finish_running_get_client_types (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_client_types_run_state_get_client_types *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Client_Types != NULL)
    *state->out_Client_Types = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_client_types_run_get_client_types (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Client_Types,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_client_types_run_state_get_client_types state = {
      NULL /* loop */, error,
    out_Client_Types,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetClientTypes", iface,
      _tp_cli_connection_interface_client_types_finish_running_get_client_types,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetClientTypes",
          _tp_cli_connection_interface_client_types_collect_callback_get_client_types,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_client_types_collect_callback_request_client_types (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Client_Types;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Client_Types,
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
  g_value_take_boxed (args->values + 0, out_Client_Types);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_client_types_invoke_callback_request_client_types (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_client_types_callback_for_request_client_types callback = (tp_cli_connection_interface_client_types_callback_for_request_client_types) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_client_types_call_request_client_types (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    tp_cli_connection_interface_client_types_callback_for_request_client_types callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestClientTypes",
          G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestClientTypes", iface,
          _tp_cli_connection_interface_client_types_invoke_callback_request_client_types,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestClientTypes",
              _tp_cli_connection_interface_client_types_collect_callback_request_client_types,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out_Client_Types;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_client_types_run_state_request_client_types;
static void
_tp_cli_connection_interface_client_types_finish_running_request_client_types (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_client_types_run_state_request_client_types *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Client_Types != NULL)
    *state->out_Client_Types = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_client_types_run_request_client_types (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    gchar ***out_Client_Types,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_client_types_run_state_request_client_types state = {
      NULL /* loop */, error,
    out_Client_Types,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestClientTypes", iface,
      _tp_cli_connection_interface_client_types_finish_running_request_client_types,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestClientTypes",
          _tp_cli_connection_interface_client_types_collect_callback_request_client_types,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_contact_blocking (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "BlockedContactsChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_contact_blocking_collect_args_of_blocked_contacts_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Blocked_Contacts,
    GHashTable *arg_Unblocked_Contacts,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 0, arg_Blocked_Contacts);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 1, arg_Unblocked_Contacts);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_blocking_invoke_callback_for_blocked_contacts_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_blocking_signal_callback_blocked_contacts_changed callback =
      (tp_cli_connection_interface_contact_blocking_signal_callback_blocked_contacts_changed) generic_callback;

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
tp_cli_connection_interface_contact_blocking_connect_to_blocked_contacts_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_blocking_signal_callback_blocked_contacts_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING, "BlockedContactsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_blocking_collect_args_of_blocked_contacts_changed),
      _tp_cli_connection_interface_contact_blocking_invoke_callback_for_blocked_contacts_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_blocking_collect_callback_block_contacts (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_blocking_invoke_callback_block_contacts (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_blocking_callback_for_block_contacts callback = (tp_cli_connection_interface_contact_blocking_callback_for_block_contacts) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_blocking_call_block_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    gboolean in_Report_Abusive,
    tp_cli_connection_interface_contact_blocking_callback_for_block_contacts callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "BlockContacts",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_BOOLEAN, in_Report_Abusive,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "BlockContacts", iface,
          _tp_cli_connection_interface_contact_blocking_invoke_callback_block_contacts,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "BlockContacts",
              _tp_cli_connection_interface_contact_blocking_collect_callback_block_contacts,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_BOOLEAN, in_Report_Abusive,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_blocking_run_state_block_contacts;
static void
_tp_cli_connection_interface_contact_blocking_finish_running_block_contacts (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_blocking_run_state_block_contacts *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_blocking_run_block_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    gboolean in_Report_Abusive,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_blocking_run_state_block_contacts state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "BlockContacts", iface,
      _tp_cli_connection_interface_contact_blocking_finish_running_block_contacts,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "BlockContacts",
          _tp_cli_connection_interface_contact_blocking_collect_callback_block_contacts,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_BOOLEAN, in_Report_Abusive,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_blocking_collect_callback_unblock_contacts (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_blocking_invoke_callback_unblock_contacts (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_blocking_callback_for_unblock_contacts callback = (tp_cli_connection_interface_contact_blocking_callback_for_unblock_contacts) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_blocking_call_unblock_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_blocking_callback_for_unblock_contacts callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UnblockContacts",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UnblockContacts", iface,
          _tp_cli_connection_interface_contact_blocking_invoke_callback_unblock_contacts,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UnblockContacts",
              _tp_cli_connection_interface_contact_blocking_collect_callback_unblock_contacts,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_blocking_run_state_unblock_contacts;
static void
_tp_cli_connection_interface_contact_blocking_finish_running_unblock_contacts (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_blocking_run_state_unblock_contacts *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_blocking_run_unblock_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_blocking_run_state_unblock_contacts state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "UnblockContacts", iface,
      _tp_cli_connection_interface_contact_blocking_finish_running_unblock_contacts,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "UnblockContacts",
          _tp_cli_connection_interface_contact_blocking_collect_callback_unblock_contacts,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_blocking_collect_callback_request_blocked_contacts (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Contacts;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), &out_Contacts,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_take_boxed (args->values + 0, out_Contacts);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contact_blocking_invoke_callback_request_blocked_contacts (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_blocking_callback_for_request_blocked_contacts callback = (tp_cli_connection_interface_contact_blocking_callback_for_request_blocked_contacts) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_blocking_call_request_blocked_contacts (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_contact_blocking_callback_for_request_blocked_contacts callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "RequestBlockedContacts",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestBlockedContacts", iface,
          _tp_cli_connection_interface_contact_blocking_invoke_callback_request_blocked_contacts,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestBlockedContacts",
              _tp_cli_connection_interface_contact_blocking_collect_callback_request_blocked_contacts,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Contacts;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_blocking_run_state_request_blocked_contacts;
static void
_tp_cli_connection_interface_contact_blocking_finish_running_request_blocked_contacts (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_blocking_run_state_request_blocked_contacts *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Contacts != NULL)
    *state->out_Contacts = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_blocking_run_request_blocked_contacts (TpConnection *proxy,
    gint timeout_ms,
    GHashTable **out_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_blocking_run_state_request_blocked_contacts state = {
      NULL /* loop */, error,
    out_Contacts,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestBlockedContacts", iface,
      _tp_cli_connection_interface_contact_blocking_finish_running_request_blocked_contacts,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestBlockedContacts",
          _tp_cli_connection_interface_contact_blocking_collect_callback_request_blocked_contacts,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_contact_capabilities (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ContactCapabilitiesChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_contact_capabilities_collect_args_of_contact_capabilities_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_caps,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))));
  g_value_set_boxed (args->values + 0, arg_caps);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_capabilities_invoke_callback_for_contact_capabilities_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_capabilities_signal_callback_contact_capabilities_changed callback =
      (tp_cli_connection_interface_contact_capabilities_signal_callback_contact_capabilities_changed) generic_callback;

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
tp_cli_connection_interface_contact_capabilities_connect_to_contact_capabilities_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_capabilities_signal_callback_contact_capabilities_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES, "ContactCapabilitiesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_capabilities_collect_args_of_contact_capabilities_changed),
      _tp_cli_connection_interface_contact_capabilities_invoke_callback_for_contact_capabilities_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_capabilities_collect_callback_update_capabilities (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_capabilities_invoke_callback_update_capabilities (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_capabilities_callback_for_update_capabilities callback = (tp_cli_connection_interface_contact_capabilities_callback_for_update_capabilities) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_capabilities_call_update_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_Handler_Capabilities,
    tp_cli_connection_interface_contact_capabilities_callback_for_update_capabilities callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UpdateCapabilities",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_STRV, G_TYPE_INVALID)))), in_Handler_Capabilities,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UpdateCapabilities", iface,
          _tp_cli_connection_interface_contact_capabilities_invoke_callback_update_capabilities,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UpdateCapabilities",
              _tp_cli_connection_interface_contact_capabilities_collect_callback_update_capabilities,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_STRV, G_TYPE_INVALID)))), in_Handler_Capabilities,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_capabilities_run_state_update_capabilities;
static void
_tp_cli_connection_interface_contact_capabilities_finish_running_update_capabilities (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_capabilities_run_state_update_capabilities *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_capabilities_run_update_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_Handler_Capabilities,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_capabilities_run_state_update_capabilities state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "UpdateCapabilities", iface,
      _tp_cli_connection_interface_contact_capabilities_finish_running_update_capabilities,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "UpdateCapabilities",
          _tp_cli_connection_interface_contact_capabilities_collect_callback_update_capabilities,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_STRV, G_TYPE_INVALID)))), in_Handler_Capabilities,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_capabilities_collect_callback_get_contact_capabilities (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Contact_Capabilities;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))), &out_Contact_Capabilities,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))));
  g_value_take_boxed (args->values + 0, out_Contact_Capabilities);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contact_capabilities_invoke_callback_get_contact_capabilities (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_capabilities_callback_for_get_contact_capabilities callback = (tp_cli_connection_interface_contact_capabilities_callback_for_get_contact_capabilities) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_capabilities_call_get_contact_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    tp_cli_connection_interface_contact_capabilities_callback_for_get_contact_capabilities callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactCapabilities",
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactCapabilities", iface,
          _tp_cli_connection_interface_contact_capabilities_invoke_callback_get_contact_capabilities,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactCapabilities",
              _tp_cli_connection_interface_contact_capabilities_collect_callback_get_contact_capabilities,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Contact_Capabilities;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_capabilities_run_state_get_contact_capabilities;
static void
_tp_cli_connection_interface_contact_capabilities_finish_running_get_contact_capabilities (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_capabilities_run_state_get_contact_capabilities *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Contact_Capabilities != NULL)
    *state->out_Contact_Capabilities = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_capabilities_run_get_contact_capabilities (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    GHashTable **out_Contact_Capabilities,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_capabilities_run_state_get_contact_capabilities state = {
      NULL /* loop */, error,
    out_Contact_Capabilities,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetContactCapabilities", iface,
      _tp_cli_connection_interface_contact_capabilities_finish_running_get_contact_capabilities,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetContactCapabilities",
          _tp_cli_connection_interface_contact_capabilities_collect_callback_get_contact_capabilities,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_contact_groups (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "GroupsChanged",
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_STRV,
      G_TYPE_STRV,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "GroupsCreated",
      G_TYPE_STRV,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "GroupRenamed",
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "GroupsRemoved",
      G_TYPE_STRV,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_contact_groups_collect_args_of_groups_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GArray *arg_Contact,
    const gchar **arg_Added,
    const gchar **arg_Removed,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (3);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 3; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRV);
  g_value_set_boxed (args->values + 1, arg_Added);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRV);
  g_value_set_boxed (args->values + 2, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_signal_callback_groups_changed callback =
      (tp_cli_connection_interface_contact_groups_signal_callback_groups_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_contact_groups_connect_to_groups_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_groups_signal_callback_groups_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_STRV,
      G_TYPE_STRV,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS, "GroupsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_groups_collect_args_of_groups_changed),
      _tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_groups_collect_args_of_groups_created (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar **arg_Names,
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
  g_value_init (args->values + 0, G_TYPE_STRV);
  g_value_set_boxed (args->values + 0, arg_Names);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_created (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_signal_callback_groups_created callback =
      (tp_cli_connection_interface_contact_groups_signal_callback_groups_created) generic_callback;

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
tp_cli_connection_interface_contact_groups_connect_to_groups_created (TpConnection *proxy,
    tp_cli_connection_interface_contact_groups_signal_callback_groups_created callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRV,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS, "GroupsCreated",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_groups_collect_args_of_groups_created),
      _tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_created,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_groups_collect_args_of_group_renamed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Old_Name,
    const gchar *arg_New_Name,
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
  g_value_set_string (args->values + 0, arg_Old_Name);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_New_Name);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_for_group_renamed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_signal_callback_group_renamed callback =
      (tp_cli_connection_interface_contact_groups_signal_callback_group_renamed) generic_callback;

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
tp_cli_connection_interface_contact_groups_connect_to_group_renamed (TpConnection *proxy,
    tp_cli_connection_interface_contact_groups_signal_callback_group_renamed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS, "GroupRenamed",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_groups_collect_args_of_group_renamed),
      _tp_cli_connection_interface_contact_groups_invoke_callback_for_group_renamed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_groups_collect_args_of_groups_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar **arg_Names,
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
  g_value_init (args->values + 0, G_TYPE_STRV);
  g_value_set_boxed (args->values + 0, arg_Names);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_signal_callback_groups_removed callback =
      (tp_cli_connection_interface_contact_groups_signal_callback_groups_removed) generic_callback;

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
tp_cli_connection_interface_contact_groups_connect_to_groups_removed (TpConnection *proxy,
    tp_cli_connection_interface_contact_groups_signal_callback_groups_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRV,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS, "GroupsRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_groups_collect_args_of_groups_removed),
      _tp_cli_connection_interface_contact_groups_invoke_callback_for_groups_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_groups_collect_callback_set_contact_groups (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_set_contact_groups (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_set_contact_groups callback = (tp_cli_connection_interface_contact_groups_callback_for_set_contact_groups) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_set_contact_groups (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    const gchar **in_Groups,
    tp_cli_connection_interface_contact_groups_callback_for_set_contact_groups callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetContactGroups",
          G_TYPE_UINT, in_Contact,
          G_TYPE_STRV, in_Groups,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetContactGroups", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_set_contact_groups,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetContactGroups",
              _tp_cli_connection_interface_contact_groups_collect_callback_set_contact_groups,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_STRV, in_Groups,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_set_contact_groups;
static void
_tp_cli_connection_interface_contact_groups_finish_running_set_contact_groups (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_set_contact_groups *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_set_contact_groups (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    const gchar **in_Groups,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_set_contact_groups state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetContactGroups", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_set_contact_groups,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetContactGroups",
          _tp_cli_connection_interface_contact_groups_collect_callback_set_contact_groups,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_STRV, in_Groups,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_groups_collect_callback_set_group_members (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_set_group_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_set_group_members callback = (tp_cli_connection_interface_contact_groups_callback_for_set_group_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_set_group_members (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    tp_cli_connection_interface_contact_groups_callback_for_set_group_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetGroupMembers",
          G_TYPE_STRING, in_Group,
          DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetGroupMembers", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_set_group_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetGroupMembers",
              _tp_cli_connection_interface_contact_groups_collect_callback_set_group_members,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_set_group_members;
static void
_tp_cli_connection_interface_contact_groups_finish_running_set_group_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_set_group_members *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_set_group_members (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_set_group_members state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetGroupMembers", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_set_group_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetGroupMembers",
          _tp_cli_connection_interface_contact_groups_collect_callback_set_group_members,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_groups_collect_callback_add_to_group (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_add_to_group (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_add_to_group callback = (tp_cli_connection_interface_contact_groups_callback_for_add_to_group) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_add_to_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    tp_cli_connection_interface_contact_groups_callback_for_add_to_group callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddToGroup",
          G_TYPE_STRING, in_Group,
          DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddToGroup", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_add_to_group,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddToGroup",
              _tp_cli_connection_interface_contact_groups_collect_callback_add_to_group,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_add_to_group;
static void
_tp_cli_connection_interface_contact_groups_finish_running_add_to_group (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_add_to_group *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_add_to_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_add_to_group state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AddToGroup", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_add_to_group,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AddToGroup",
          _tp_cli_connection_interface_contact_groups_collect_callback_add_to_group,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_groups_collect_callback_remove_from_group (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_remove_from_group (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_remove_from_group callback = (tp_cli_connection_interface_contact_groups_callback_for_remove_from_group) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_remove_from_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    tp_cli_connection_interface_contact_groups_callback_for_remove_from_group callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveFromGroup",
          G_TYPE_STRING, in_Group,
          DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveFromGroup", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_remove_from_group,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveFromGroup",
              _tp_cli_connection_interface_contact_groups_collect_callback_remove_from_group,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_remove_from_group;
static void
_tp_cli_connection_interface_contact_groups_finish_running_remove_from_group (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_remove_from_group *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_remove_from_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    const GArray *in_Members,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_remove_from_group state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveFromGroup", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_remove_from_group,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveFromGroup",
          _tp_cli_connection_interface_contact_groups_collect_callback_remove_from_group,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Group,
              DBUS_TYPE_G_UINT_ARRAY, in_Members,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_groups_collect_callback_remove_group (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_remove_group (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_remove_group callback = (tp_cli_connection_interface_contact_groups_callback_for_remove_group) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_remove_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    tp_cli_connection_interface_contact_groups_callback_for_remove_group callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveGroup",
          G_TYPE_STRING, in_Group,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveGroup", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_remove_group,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveGroup",
              _tp_cli_connection_interface_contact_groups_collect_callback_remove_group,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Group,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_remove_group;
static void
_tp_cli_connection_interface_contact_groups_finish_running_remove_group (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_remove_group *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_remove_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Group,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_remove_group state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveGroup", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_remove_group,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveGroup",
          _tp_cli_connection_interface_contact_groups_collect_callback_remove_group,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Group,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_groups_collect_callback_rename_group (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_groups_invoke_callback_rename_group (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_groups_callback_for_rename_group callback = (tp_cli_connection_interface_contact_groups_callback_for_rename_group) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_groups_call_rename_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Old_Name,
    const gchar *in_New_Name,
    tp_cli_connection_interface_contact_groups_callback_for_rename_group callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RenameGroup",
          G_TYPE_STRING, in_Old_Name,
          G_TYPE_STRING, in_New_Name,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RenameGroup", iface,
          _tp_cli_connection_interface_contact_groups_invoke_callback_rename_group,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RenameGroup",
              _tp_cli_connection_interface_contact_groups_collect_callback_rename_group,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Old_Name,
              G_TYPE_STRING, in_New_Name,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_groups_run_state_rename_group;
static void
_tp_cli_connection_interface_contact_groups_finish_running_rename_group (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_groups_run_state_rename_group *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_groups_run_rename_group (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Old_Name,
    const gchar *in_New_Name,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_groups_run_state_rename_group state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RenameGroup", iface,
      _tp_cli_connection_interface_contact_groups_finish_running_rename_group,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RenameGroup",
          _tp_cli_connection_interface_contact_groups_collect_callback_rename_group,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Old_Name,
              G_TYPE_STRING, in_New_Name,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_contact_info (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ContactInfoChanged",
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_contact_info_collect_args_of_contact_info_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
    const GPtrArray *arg_ContactInfo,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 1, arg_ContactInfo);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_info_invoke_callback_for_contact_info_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_info_signal_callback_contact_info_changed callback =
      (tp_cli_connection_interface_contact_info_signal_callback_contact_info_changed) generic_callback;

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
tp_cli_connection_interface_contact_info_connect_to_contact_info_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_info_signal_callback_contact_info_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO, "ContactInfoChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_info_collect_args_of_contact_info_changed),
      _tp_cli_connection_interface_contact_info_invoke_callback_for_contact_info_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_info_collect_callback_get_contact_info (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_ContactInfo;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))), &out_ContactInfo,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))));
  g_value_take_boxed (args->values + 0, out_ContactInfo);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contact_info_invoke_callback_get_contact_info (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_info_callback_for_get_contact_info callback = (tp_cli_connection_interface_contact_info_callback_for_get_contact_info) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_info_call_get_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_info_callback_for_get_contact_info callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactInfo",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactInfo", iface,
          _tp_cli_connection_interface_contact_info_invoke_callback_get_contact_info,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactInfo",
              _tp_cli_connection_interface_contact_info_collect_callback_get_contact_info,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_ContactInfo;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_info_run_state_get_contact_info;
static void
_tp_cli_connection_interface_contact_info_finish_running_get_contact_info (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_info_run_state_get_contact_info *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_ContactInfo != NULL)
    *state->out_ContactInfo = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_info_run_get_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_ContactInfo,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_info_run_state_get_contact_info state = {
      NULL /* loop */, error,
    out_ContactInfo,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetContactInfo", iface,
      _tp_cli_connection_interface_contact_info_finish_running_get_contact_info,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetContactInfo",
          _tp_cli_connection_interface_contact_info_collect_callback_get_contact_info,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_info_collect_callback_refresh_contact_info (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_info_invoke_callback_refresh_contact_info (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_info_callback_for_refresh_contact_info callback = (tp_cli_connection_interface_contact_info_callback_for_refresh_contact_info) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_info_call_refresh_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_info_callback_for_refresh_contact_info callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RefreshContactInfo",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RefreshContactInfo", iface,
          _tp_cli_connection_interface_contact_info_invoke_callback_refresh_contact_info,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RefreshContactInfo",
              _tp_cli_connection_interface_contact_info_collect_callback_refresh_contact_info,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_info_run_state_refresh_contact_info;
static void
_tp_cli_connection_interface_contact_info_finish_running_refresh_contact_info (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_info_run_state_refresh_contact_info *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_info_run_refresh_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_info_run_state_refresh_contact_info state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RefreshContactInfo", iface,
      _tp_cli_connection_interface_contact_info_finish_running_refresh_contact_info,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RefreshContactInfo",
          _tp_cli_connection_interface_contact_info_collect_callback_refresh_contact_info,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_info_collect_callback_request_contact_info (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Contact_Info;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))), &out_Contact_Info,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Contact_Info);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contact_info_invoke_callback_request_contact_info (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_info_callback_for_request_contact_info callback = (tp_cli_connection_interface_contact_info_callback_for_request_contact_info) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_info_call_request_contact_info (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    tp_cli_connection_interface_contact_info_callback_for_request_contact_info callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestContactInfo",
          G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestContactInfo", iface,
          _tp_cli_connection_interface_contact_info_invoke_callback_request_contact_info,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestContactInfo",
              _tp_cli_connection_interface_contact_info_collect_callback_request_contact_info,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Contact_Info;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_info_run_state_request_contact_info;
static void
_tp_cli_connection_interface_contact_info_finish_running_request_contact_info (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_info_run_state_request_contact_info *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Contact_Info != NULL)
    *state->out_Contact_Info = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_info_run_request_contact_info (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    GPtrArray **out_Contact_Info,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_info_run_state_request_contact_info state = {
      NULL /* loop */, error,
    out_Contact_Info,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestContactInfo", iface,
      _tp_cli_connection_interface_contact_info_finish_running_request_contact_info,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestContactInfo",
          _tp_cli_connection_interface_contact_info_collect_callback_request_contact_info,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_info_collect_callback_set_contact_info (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_info_invoke_callback_set_contact_info (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_info_callback_for_set_contact_info callback = (tp_cli_connection_interface_contact_info_callback_for_set_contact_info) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_info_call_set_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_ContactInfo,
    tp_cli_connection_interface_contact_info_callback_for_set_contact_info callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetContactInfo",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))), in_ContactInfo,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetContactInfo", iface,
          _tp_cli_connection_interface_contact_info_invoke_callback_set_contact_info,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetContactInfo",
              _tp_cli_connection_interface_contact_info_collect_callback_set_contact_info,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))), in_ContactInfo,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_info_run_state_set_contact_info;
static void
_tp_cli_connection_interface_contact_info_finish_running_set_contact_info (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_info_run_state_set_contact_info *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_info_run_set_contact_info (TpConnection *proxy,
    gint timeout_ms,
    const GPtrArray *in_ContactInfo,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_info_run_state_set_contact_info state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetContactInfo", iface,
      _tp_cli_connection_interface_contact_info_finish_running_set_contact_info,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetContactInfo",
          _tp_cli_connection_interface_contact_info_collect_callback_set_contact_info,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))), in_ContactInfo,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_contact_list (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ContactListStateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ContactsChangedWithID",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ContactsChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_contact_list_collect_args_of_contact_list_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact_List_State,
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
  g_value_set_uint (args->values + 0, arg_Contact_List_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_for_contact_list_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_signal_callback_contact_list_state_changed callback =
      (tp_cli_connection_interface_contact_list_signal_callback_contact_list_state_changed) generic_callback;

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
tp_cli_connection_interface_contact_list_connect_to_contact_list_state_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_list_signal_callback_contact_list_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST, "ContactListStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_list_collect_args_of_contact_list_state_changed),
      _tp_cli_connection_interface_contact_list_invoke_callback_for_contact_list_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_list_collect_args_of_contacts_changed_with_id (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Changes,
    GHashTable *arg_Identifiers,
    GHashTable *arg_Removals,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (3);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 3; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Changes);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 1, arg_Identifiers);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 2, arg_Removals);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_for_contacts_changed_with_id (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_signal_callback_contacts_changed_with_id callback =
      (tp_cli_connection_interface_contact_list_signal_callback_contacts_changed_with_id) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_contact_list_connect_to_contacts_changed_with_id (TpConnection *proxy,
    tp_cli_connection_interface_contact_list_signal_callback_contacts_changed_with_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST, "ContactsChangedWithID",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_list_collect_args_of_contacts_changed_with_id),
      _tp_cli_connection_interface_contact_list_invoke_callback_for_contacts_changed_with_id,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_list_collect_args_of_contacts_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Changes,
    const GArray *arg_Removals,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Changes);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Removals);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_for_contacts_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_signal_callback_contacts_changed callback =
      (tp_cli_connection_interface_contact_list_signal_callback_contacts_changed) generic_callback;

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
tp_cli_connection_interface_contact_list_connect_to_contacts_changed (TpConnection *proxy,
    tp_cli_connection_interface_contact_list_signal_callback_contacts_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST, "ContactsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_contact_list_collect_args_of_contacts_changed),
      _tp_cli_connection_interface_contact_list_invoke_callback_for_contacts_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_contact_list_collect_callback_get_contact_list_attributes (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Attributes;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), &out_Attributes,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_take_boxed (args->values + 0, out_Attributes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_get_contact_list_attributes (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_get_contact_list_attributes callback = (tp_cli_connection_interface_contact_list_callback_for_get_contact_list_attributes) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_get_contact_list_attributes (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    tp_cli_connection_interface_contact_list_callback_for_get_contact_list_attributes callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactListAttributes",
          G_TYPE_STRV, in_Interfaces,
          G_TYPE_BOOLEAN, in_Hold,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactListAttributes", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_get_contact_list_attributes,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactListAttributes",
              _tp_cli_connection_interface_contact_list_collect_callback_get_contact_list_attributes,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_BOOLEAN, in_Hold,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Attributes;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_get_contact_list_attributes;
static void
_tp_cli_connection_interface_contact_list_finish_running_get_contact_list_attributes (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_get_contact_list_attributes *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Attributes != NULL)
    *state->out_Attributes = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_get_contact_list_attributes (TpConnection *proxy,
    gint timeout_ms,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    GHashTable **out_Attributes,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_get_contact_list_attributes state = {
      NULL /* loop */, error,
    out_Attributes,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetContactListAttributes", iface,
      _tp_cli_connection_interface_contact_list_finish_running_get_contact_list_attributes,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetContactListAttributes",
          _tp_cli_connection_interface_contact_list_collect_callback_get_contact_list_attributes,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_BOOLEAN, in_Hold,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_request_subscription (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_request_subscription (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_request_subscription callback = (tp_cli_connection_interface_contact_list_callback_for_request_subscription) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_request_subscription (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    tp_cli_connection_interface_contact_list_callback_for_request_subscription callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestSubscription",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestSubscription", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_request_subscription,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestSubscription",
              _tp_cli_connection_interface_contact_list_collect_callback_request_subscription,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_STRING, in_Message,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_request_subscription;
static void
_tp_cli_connection_interface_contact_list_finish_running_request_subscription (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_request_subscription *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_request_subscription (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_request_subscription state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestSubscription", iface,
      _tp_cli_connection_interface_contact_list_finish_running_request_subscription,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestSubscription",
          _tp_cli_connection_interface_contact_list_collect_callback_request_subscription,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_STRING, in_Message,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_authorize_publication (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_authorize_publication (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_authorize_publication callback = (tp_cli_connection_interface_contact_list_callback_for_authorize_publication) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_authorize_publication (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_list_callback_for_authorize_publication callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AuthorizePublication",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AuthorizePublication", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_authorize_publication,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AuthorizePublication",
              _tp_cli_connection_interface_contact_list_collect_callback_authorize_publication,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_authorize_publication;
static void
_tp_cli_connection_interface_contact_list_finish_running_authorize_publication (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_authorize_publication *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_authorize_publication (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_authorize_publication state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AuthorizePublication", iface,
      _tp_cli_connection_interface_contact_list_finish_running_authorize_publication,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AuthorizePublication",
          _tp_cli_connection_interface_contact_list_collect_callback_authorize_publication,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_remove_contacts (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_remove_contacts (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_remove_contacts callback = (tp_cli_connection_interface_contact_list_callback_for_remove_contacts) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_remove_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_list_callback_for_remove_contacts callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveContacts",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveContacts", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_remove_contacts,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveContacts",
              _tp_cli_connection_interface_contact_list_collect_callback_remove_contacts,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_remove_contacts;
static void
_tp_cli_connection_interface_contact_list_finish_running_remove_contacts (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_remove_contacts *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_remove_contacts (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_remove_contacts state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveContacts", iface,
      _tp_cli_connection_interface_contact_list_finish_running_remove_contacts,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveContacts",
          _tp_cli_connection_interface_contact_list_collect_callback_remove_contacts,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_unsubscribe (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_unsubscribe (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_unsubscribe callback = (tp_cli_connection_interface_contact_list_callback_for_unsubscribe) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_unsubscribe (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_list_callback_for_unsubscribe callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Unsubscribe",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Unsubscribe", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_unsubscribe,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Unsubscribe",
              _tp_cli_connection_interface_contact_list_collect_callback_unsubscribe,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_unsubscribe;
static void
_tp_cli_connection_interface_contact_list_finish_running_unsubscribe (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_unsubscribe *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_unsubscribe (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_unsubscribe state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Unsubscribe", iface,
      _tp_cli_connection_interface_contact_list_finish_running_unsubscribe,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Unsubscribe",
          _tp_cli_connection_interface_contact_list_collect_callback_unsubscribe,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_unpublish (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_unpublish (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_unpublish callback = (tp_cli_connection_interface_contact_list_callback_for_unpublish) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_unpublish (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_contact_list_callback_for_unpublish callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Unpublish",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Unpublish", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_unpublish,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Unpublish",
              _tp_cli_connection_interface_contact_list_collect_callback_unpublish,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contact_list_run_state_unpublish;
static void
_tp_cli_connection_interface_contact_list_finish_running_unpublish (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contact_list_run_state_unpublish *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contact_list_run_unpublish (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contact_list_run_state_unpublish state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Unpublish", iface,
      _tp_cli_connection_interface_contact_list_finish_running_unpublish,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Unpublish",
          _tp_cli_connection_interface_contact_list_collect_callback_unpublish,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contact_list_collect_callback_download (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_contact_list_invoke_callback_download (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contact_list_callback_for_download callback = (tp_cli_connection_interface_contact_list_callback_for_download) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contact_list_call_download (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_contact_list_callback_for_download callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Download",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Download", iface,
          _tp_cli_connection_interface_contact_list_invoke_callback_download,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Download",
              _tp_cli_connection_interface_contact_list_collect_callback_download,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_connection_interface_contacts_collect_callback_get_contact_attributes (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Attributes;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), &out_Attributes,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_take_boxed (args->values + 0, out_Attributes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contacts_invoke_callback_get_contact_attributes (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback = (tp_cli_connection_interface_contacts_callback_for_get_contact_attributes) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contacts_call_get_contact_attributes (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    tp_cli_connection_interface_contacts_callback_for_get_contact_attributes callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactAttributes",
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_STRV, in_Interfaces,
          G_TYPE_BOOLEAN, in_Hold,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactAttributes", iface,
          _tp_cli_connection_interface_contacts_invoke_callback_get_contact_attributes,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactAttributes",
              _tp_cli_connection_interface_contacts_collect_callback_get_contact_attributes,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_BOOLEAN, in_Hold,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Attributes;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_contacts_run_state_get_contact_attributes;
static void
_tp_cli_connection_interface_contacts_finish_running_get_contact_attributes (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_contacts_run_state_get_contact_attributes *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Attributes != NULL)
    *state->out_Attributes = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_contacts_run_get_contact_attributes (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    GHashTable **out_Attributes,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_contacts_run_state_get_contact_attributes state = {
      NULL /* loop */, error,
    out_Attributes,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetContactAttributes", iface,
      _tp_cli_connection_interface_contacts_finish_running_get_contact_attributes,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetContactAttributes",
          _tp_cli_connection_interface_contacts_collect_callback_get_contact_attributes,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Handles,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_BOOLEAN, in_Hold,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_contacts_collect_callback_get_contact_by_id (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Handle;
  GHashTable *out_Attributes;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Handle,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), &out_Attributes,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, out_Handle);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 1, out_Attributes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_contacts_invoke_callback_get_contact_by_id (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_contacts_callback_for_get_contact_by_id callback = (tp_cli_connection_interface_contacts_callback_for_get_contact_by_id) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          0,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_uint (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_contacts_call_get_contact_by_id (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Identifier,
    const gchar **in_Interfaces,
    tp_cli_connection_interface_contacts_callback_for_get_contact_by_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetContactByID",
          G_TYPE_STRING, in_Identifier,
          G_TYPE_STRV, in_Interfaces,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetContactByID", iface,
          _tp_cli_connection_interface_contacts_invoke_callback_get_contact_by_id,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetContactByID",
              _tp_cli_connection_interface_contacts_collect_callback_get_contact_by_id,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Identifier,
              G_TYPE_STRV, in_Interfaces,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_connection_interface_location (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "LocationUpdated",
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_location_collect_args_of_location_updated (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
    GHashTable *arg_Location,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 1, arg_Location);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_location_invoke_callback_for_location_updated (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_location_signal_callback_location_updated callback =
      (tp_cli_connection_interface_location_signal_callback_location_updated) generic_callback;

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
tp_cli_connection_interface_location_connect_to_location_updated (TpConnection *proxy,
    tp_cli_connection_interface_location_signal_callback_location_updated callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION, "LocationUpdated",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_location_collect_args_of_location_updated),
      _tp_cli_connection_interface_location_invoke_callback_for_location_updated,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_location_collect_callback_get_locations (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Locations;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), &out_Locations,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_take_boxed (args->values + 0, out_Locations);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_location_invoke_callback_get_locations (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_location_callback_for_get_locations callback = (tp_cli_connection_interface_location_callback_for_get_locations) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_location_call_get_locations (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_location_callback_for_get_locations callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetLocations",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetLocations", iface,
          _tp_cli_connection_interface_location_invoke_callback_get_locations,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetLocations",
              _tp_cli_connection_interface_location_collect_callback_get_locations,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Locations;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_location_run_state_get_locations;
static void
_tp_cli_connection_interface_location_finish_running_get_locations (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_location_run_state_get_locations *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Locations != NULL)
    *state->out_Locations = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_location_run_get_locations (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Locations,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_location_run_state_get_locations state = {
      NULL /* loop */, error,
    out_Locations,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetLocations", iface,
      _tp_cli_connection_interface_location_finish_running_get_locations,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetLocations",
          _tp_cli_connection_interface_location_collect_callback_get_locations,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_location_collect_callback_request_location (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Location;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), &out_Location,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 0, out_Location);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_location_invoke_callback_request_location (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_location_callback_for_request_location callback = (tp_cli_connection_interface_location_callback_for_request_location) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_location_call_request_location (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    tp_cli_connection_interface_location_callback_for_request_location callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "RequestLocation",
          G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestLocation", iface,
          _tp_cli_connection_interface_location_invoke_callback_request_location,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestLocation",
              _tp_cli_connection_interface_location_collect_callback_request_location,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Location;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_location_run_state_request_location;
static void
_tp_cli_connection_interface_location_finish_running_request_location (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_location_run_state_request_location *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Location != NULL)
    *state->out_Location = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_location_run_request_location (TpConnection *proxy,
    gint timeout_ms,
    guint in_Contact,
    GHashTable **out_Location,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_location_run_state_request_location state = {
      NULL /* loop */, error,
    out_Location,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestLocation", iface,
      _tp_cli_connection_interface_location_finish_running_request_location,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestLocation",
          _tp_cli_connection_interface_location_collect_callback_request_location,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_location_collect_callback_set_location (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_location_invoke_callback_set_location (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_location_callback_for_set_location callback = (tp_cli_connection_interface_location_callback_for_set_location) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_location_call_set_location (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Location,
    tp_cli_connection_interface_location_callback_for_set_location callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetLocation",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Location,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetLocation", iface,
          _tp_cli_connection_interface_location_invoke_callback_set_location,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetLocation",
              _tp_cli_connection_interface_location_collect_callback_set_location,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Location,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_location_run_state_set_location;
static void
_tp_cli_connection_interface_location_finish_running_set_location (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_location_run_state_set_location *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_location_run_set_location (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Location,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_location_run_state_set_location state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetLocation", iface,
      _tp_cli_connection_interface_location_finish_running_set_location,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetLocation",
          _tp_cli_connection_interface_location_collect_callback_set_location,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Location,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_mail_notification (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "MailsReceived",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "UnreadMailsChanged",
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_STRV,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_mail_notification_collect_args_of_mails_received (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Mails,
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
  g_value_set_boxed (args->values + 0, arg_Mails);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_mail_notification_invoke_callback_for_mails_received (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_mail_notification_signal_callback_mails_received callback =
      (tp_cli_connection_interface_mail_notification_signal_callback_mails_received) generic_callback;

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
tp_cli_connection_interface_mail_notification_connect_to_mails_received (TpConnection *proxy,
    tp_cli_connection_interface_mail_notification_signal_callback_mails_received callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION, "MailsReceived",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_mail_notification_collect_args_of_mails_received),
      _tp_cli_connection_interface_mail_notification_invoke_callback_for_mails_received,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_mail_notification_collect_args_of_unread_mails_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Count,
    const GPtrArray *arg_Mails_Added,
    const gchar **arg_Mails_Removed,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (3);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 3; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_Count);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_set_boxed (args->values + 1, arg_Mails_Added);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRV);
  g_value_set_boxed (args->values + 2, arg_Mails_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_mail_notification_invoke_callback_for_unread_mails_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_mail_notification_signal_callback_unread_mails_changed callback =
      (tp_cli_connection_interface_mail_notification_signal_callback_unread_mails_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_interface_mail_notification_connect_to_unread_mails_changed (TpConnection *proxy,
    tp_cli_connection_interface_mail_notification_signal_callback_unread_mails_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_STRV,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION, "UnreadMailsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_mail_notification_collect_args_of_unread_mails_changed),
      _tp_cli_connection_interface_mail_notification_invoke_callback_for_unread_mails_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_mail_notification_collect_callback_request_inbox_url (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValueArray *out_URL;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)), &out_URL,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)));
  g_value_take_boxed (args->values + 0, out_URL);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_mail_notification_invoke_callback_request_inbox_url (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_mail_notification_callback_for_request_inbox_url callback = (tp_cli_connection_interface_mail_notification_callback_for_request_inbox_url) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_mail_notification_call_request_inbox_url (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_mail_notification_callback_for_request_inbox_url callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestInboxURL",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestInboxURL", iface,
          _tp_cli_connection_interface_mail_notification_invoke_callback_request_inbox_url,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestInboxURL",
              _tp_cli_connection_interface_mail_notification_collect_callback_request_inbox_url,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValueArray **out_URL;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_mail_notification_run_state_request_inbox_url;
static void
_tp_cli_connection_interface_mail_notification_finish_running_request_inbox_url (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_mail_notification_run_state_request_inbox_url *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_URL != NULL)
    *state->out_URL = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_mail_notification_run_request_inbox_url (TpConnection *proxy,
    gint timeout_ms,
    GValueArray **out_URL,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_mail_notification_run_state_request_inbox_url state = {
      NULL /* loop */, error,
    out_URL,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestInboxURL", iface,
      _tp_cli_connection_interface_mail_notification_finish_running_request_inbox_url,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestInboxURL",
          _tp_cli_connection_interface_mail_notification_collect_callback_request_inbox_url,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_mail_notification_collect_callback_request_mail_url (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValueArray *out_URL;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)), &out_URL,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)));
  g_value_take_boxed (args->values + 0, out_URL);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_mail_notification_invoke_callback_request_mail_url (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_mail_notification_callback_for_request_mail_url callback = (tp_cli_connection_interface_mail_notification_callback_for_request_mail_url) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_mail_notification_call_request_mail_url (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_ID,
    const GValue *in_URL_Data,
    tp_cli_connection_interface_mail_notification_callback_for_request_mail_url callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestMailURL",
          G_TYPE_STRING, in_ID,
          G_TYPE_VALUE, in_URL_Data,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestMailURL", iface,
          _tp_cli_connection_interface_mail_notification_invoke_callback_request_mail_url,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestMailURL",
              _tp_cli_connection_interface_mail_notification_collect_callback_request_mail_url,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_ID,
              G_TYPE_VALUE, in_URL_Data,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValueArray **out_URL;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_mail_notification_run_state_request_mail_url;
static void
_tp_cli_connection_interface_mail_notification_finish_running_request_mail_url (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_mail_notification_run_state_request_mail_url *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_URL != NULL)
    *state->out_URL = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_mail_notification_run_request_mail_url (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_ID,
    const GValue *in_URL_Data,
    GValueArray **out_URL,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_mail_notification_run_state_request_mail_url state = {
      NULL /* loop */, error,
    out_URL,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestMailURL", iface,
      _tp_cli_connection_interface_mail_notification_finish_running_request_mail_url,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestMailURL",
          _tp_cli_connection_interface_mail_notification_collect_callback_request_mail_url,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_ID,
              G_TYPE_VALUE, in_URL_Data,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_power_saving (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "PowerSavingChanged",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_power_saving_collect_args_of_power_saving_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Active,
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
  g_value_set_boolean (args->values + 0, arg_Active);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_power_saving_invoke_callback_for_power_saving_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_power_saving_signal_callback_power_saving_changed callback =
      (tp_cli_connection_interface_power_saving_signal_callback_power_saving_changed) generic_callback;

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
tp_cli_connection_interface_power_saving_connect_to_power_saving_changed (TpConnection *proxy,
    tp_cli_connection_interface_power_saving_signal_callback_power_saving_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_POWER_SAVING, "PowerSavingChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_power_saving_collect_args_of_power_saving_changed),
      _tp_cli_connection_interface_power_saving_invoke_callback_for_power_saving_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_power_saving_collect_callback_set_power_saving (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_power_saving_invoke_callback_set_power_saving (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_power_saving_callback_for_set_power_saving callback = (tp_cli_connection_interface_power_saving_callback_for_set_power_saving) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_power_saving_call_set_power_saving (TpConnection *proxy,
    gint timeout_ms,
    gboolean in_Activate,
    tp_cli_connection_interface_power_saving_callback_for_set_power_saving callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_POWER_SAVING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetPowerSaving",
          G_TYPE_BOOLEAN, in_Activate,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetPowerSaving", iface,
          _tp_cli_connection_interface_power_saving_invoke_callback_set_power_saving,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetPowerSaving",
              _tp_cli_connection_interface_power_saving_collect_callback_set_power_saving,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Activate,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_power_saving_run_state_set_power_saving;
static void
_tp_cli_connection_interface_power_saving_finish_running_set_power_saving (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_power_saving_run_state_set_power_saving *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_power_saving_run_set_power_saving (TpConnection *proxy,
    gint timeout_ms,
    gboolean in_Activate,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_POWER_SAVING;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_power_saving_run_state_set_power_saving state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetPowerSaving", iface,
      _tp_cli_connection_interface_power_saving_finish_running_set_power_saving,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetPowerSaving",
          _tp_cli_connection_interface_power_saving_collect_callback_set_power_saving,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_BOOLEAN, in_Activate,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_presence (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "PresenceUpdate",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_presence_collect_args_of_presence_update (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Presence,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Presence);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_for_presence_update (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_signal_callback_presence_update callback =
      (tp_cli_connection_interface_presence_signal_callback_presence_update) generic_callback;

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
tp_cli_connection_interface_presence_connect_to_presence_update (TpConnection *proxy,
    tp_cli_connection_interface_presence_signal_callback_presence_update callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE, "PresenceUpdate",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_presence_collect_args_of_presence_update),
      _tp_cli_connection_interface_presence_invoke_callback_for_presence_update,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_presence_collect_callback_add_status (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_add_status (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_add_status callback = (tp_cli_connection_interface_presence_callback_for_add_status) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_add_status (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    GHashTable *in_Parameters,
    tp_cli_connection_interface_presence_callback_for_add_status callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddStatus",
          G_TYPE_STRING, in_Status,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddStatus", iface,
          _tp_cli_connection_interface_presence_invoke_callback_add_status,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddStatus",
              _tp_cli_connection_interface_presence_collect_callback_add_status,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Status,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_add_status;
static void
_tp_cli_connection_interface_presence_finish_running_add_status (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_add_status *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_add_status (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    GHashTable *in_Parameters,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_add_status state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AddStatus", iface,
      _tp_cli_connection_interface_presence_finish_running_add_status,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AddStatus",
          _tp_cli_connection_interface_presence_collect_callback_add_status,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Status,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_clear_status (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_clear_status (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_clear_status callback = (tp_cli_connection_interface_presence_callback_for_clear_status) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_clear_status (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_presence_callback_for_clear_status callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ClearStatus",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ClearStatus", iface,
          _tp_cli_connection_interface_presence_invoke_callback_clear_status,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ClearStatus",
              _tp_cli_connection_interface_presence_collect_callback_clear_status,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_clear_status;
static void
_tp_cli_connection_interface_presence_finish_running_clear_status (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_clear_status *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_clear_status (TpConnection *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_clear_status state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ClearStatus", iface,
      _tp_cli_connection_interface_presence_finish_running_clear_status,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ClearStatus",
          _tp_cli_connection_interface_presence_collect_callback_clear_status,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_get_presence (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Presence;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))), &out_Presence,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Presence);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_get_presence (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_get_presence callback = (tp_cli_connection_interface_presence_callback_for_get_presence) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_get_presence (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_presence_callback_for_get_presence callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetPresence",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetPresence", iface,
          _tp_cli_connection_interface_presence_invoke_callback_get_presence,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetPresence",
              _tp_cli_connection_interface_presence_collect_callback_get_presence,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Presence;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_get_presence;
static void
_tp_cli_connection_interface_presence_finish_running_get_presence (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_get_presence *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Presence != NULL)
    *state->out_Presence = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_get_presence (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Presence,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_get_presence state = {
      NULL /* loop */, error,
    out_Presence,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetPresence", iface,
      _tp_cli_connection_interface_presence_finish_running_get_presence,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetPresence",
          _tp_cli_connection_interface_presence_collect_callback_get_presence,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_get_statuses (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Available_Statuses;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_BOOLEAN, G_TYPE_BOOLEAN, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), &out_Available_Statuses,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_BOOLEAN, G_TYPE_BOOLEAN, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Available_Statuses);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_get_statuses (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_get_statuses callback = (tp_cli_connection_interface_presence_callback_for_get_statuses) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_get_statuses (TpConnection *proxy,
    gint timeout_ms,
    tp_cli_connection_interface_presence_callback_for_get_statuses callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetStatuses",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetStatuses", iface,
          _tp_cli_connection_interface_presence_invoke_callback_get_statuses,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetStatuses",
              _tp_cli_connection_interface_presence_collect_callback_get_statuses,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Available_Statuses;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_get_statuses;
static void
_tp_cli_connection_interface_presence_finish_running_get_statuses (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_get_statuses *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Available_Statuses != NULL)
    *state->out_Available_Statuses = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_get_statuses (TpConnection *proxy,
    gint timeout_ms,
    GHashTable **out_Available_Statuses,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_get_statuses state = {
      NULL /* loop */, error,
    out_Available_Statuses,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetStatuses", iface,
      _tp_cli_connection_interface_presence_finish_running_get_statuses,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetStatuses",
          _tp_cli_connection_interface_presence_collect_callback_get_statuses,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_remove_status (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_remove_status (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_remove_status callback = (tp_cli_connection_interface_presence_callback_for_remove_status) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_remove_status (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    tp_cli_connection_interface_presence_callback_for_remove_status callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveStatus",
          G_TYPE_STRING, in_Status,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveStatus", iface,
          _tp_cli_connection_interface_presence_invoke_callback_remove_status,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveStatus",
              _tp_cli_connection_interface_presence_collect_callback_remove_status,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Status,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_remove_status;
static void
_tp_cli_connection_interface_presence_finish_running_remove_status (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_remove_status *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_remove_status (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_remove_status state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveStatus", iface,
      _tp_cli_connection_interface_presence_finish_running_remove_status,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveStatus",
          _tp_cli_connection_interface_presence_collect_callback_remove_status,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Status,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_request_presence (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_request_presence (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_request_presence callback = (tp_cli_connection_interface_presence_callback_for_request_presence) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_request_presence (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_presence_callback_for_request_presence callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestPresence",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestPresence", iface,
          _tp_cli_connection_interface_presence_invoke_callback_request_presence,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestPresence",
              _tp_cli_connection_interface_presence_collect_callback_request_presence,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_request_presence;
static void
_tp_cli_connection_interface_presence_finish_running_request_presence (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_request_presence *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_request_presence (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_request_presence state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestPresence", iface,
      _tp_cli_connection_interface_presence_finish_running_request_presence,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestPresence",
          _tp_cli_connection_interface_presence_collect_callback_request_presence,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_set_last_activity_time (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_set_last_activity_time (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_set_last_activity_time callback = (tp_cli_connection_interface_presence_callback_for_set_last_activity_time) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_set_last_activity_time (TpConnection *proxy,
    gint timeout_ms,
    guint in_Time,
    tp_cli_connection_interface_presence_callback_for_set_last_activity_time callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetLastActivityTime",
          G_TYPE_UINT, in_Time,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetLastActivityTime", iface,
          _tp_cli_connection_interface_presence_invoke_callback_set_last_activity_time,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetLastActivityTime",
              _tp_cli_connection_interface_presence_collect_callback_set_last_activity_time,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Time,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_set_last_activity_time;
static void
_tp_cli_connection_interface_presence_finish_running_set_last_activity_time (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_set_last_activity_time *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_set_last_activity_time (TpConnection *proxy,
    gint timeout_ms,
    guint in_Time,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_set_last_activity_time state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetLastActivityTime", iface,
      _tp_cli_connection_interface_presence_finish_running_set_last_activity_time,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetLastActivityTime",
          _tp_cli_connection_interface_presence_collect_callback_set_last_activity_time,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Time,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_presence_collect_callback_set_status (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_presence_invoke_callback_set_status (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_presence_callback_for_set_status callback = (tp_cli_connection_interface_presence_callback_for_set_status) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_presence_call_set_status (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Statuses,
    tp_cli_connection_interface_presence_callback_for_set_status callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetStatus",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Statuses,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetStatus", iface,
          _tp_cli_connection_interface_presence_invoke_callback_set_status,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetStatus",
              _tp_cli_connection_interface_presence_collect_callback_set_status,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Statuses,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_presence_run_state_set_status;
static void
_tp_cli_connection_interface_presence_finish_running_set_status (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_presence_run_state_set_status *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_presence_run_set_status (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Statuses,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_presence_run_state_set_status state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetStatus", iface,
      _tp_cli_connection_interface_presence_finish_running_set_status,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetStatus",
          _tp_cli_connection_interface_presence_collect_callback_set_status,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Statuses,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_renaming (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "Renamed",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_renaming_collect_args_of_renamed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Original,
    guint arg_New,
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
  g_value_set_uint (args->values + 0, arg_Original);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_New);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_renaming_invoke_callback_for_renamed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_renaming_signal_callback_renamed callback =
      (tp_cli_connection_interface_renaming_signal_callback_renamed) generic_callback;

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
tp_cli_connection_interface_renaming_connect_to_renamed (TpConnection *proxy,
    tp_cli_connection_interface_renaming_signal_callback_renamed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_RENAMING, "Renamed",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_renaming_collect_args_of_renamed),
      _tp_cli_connection_interface_renaming_invoke_callback_for_renamed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_renaming_collect_callback_request_rename (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_renaming_invoke_callback_request_rename (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_renaming_callback_for_request_rename callback = (tp_cli_connection_interface_renaming_callback_for_request_rename) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_renaming_call_request_rename (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Identifier,
    tp_cli_connection_interface_renaming_callback_for_request_rename callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_RENAMING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestRename",
          G_TYPE_STRING, in_Identifier,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestRename", iface,
          _tp_cli_connection_interface_renaming_invoke_callback_request_rename,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestRename",
              _tp_cli_connection_interface_renaming_collect_callback_request_rename,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Identifier,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_connection_interface_requests (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewChannels",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ChannelClosed",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_requests_collect_args_of_new_channels (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Channels,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Channels);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_requests_invoke_callback_for_new_channels (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_requests_signal_callback_new_channels callback =
      (tp_cli_connection_interface_requests_signal_callback_new_channels) generic_callback;

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
tp_cli_connection_interface_requests_connect_to_new_channels (TpConnection *proxy,
    tp_cli_connection_interface_requests_signal_callback_new_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS, "NewChannels",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_requests_collect_args_of_new_channels),
      _tp_cli_connection_interface_requests_invoke_callback_for_new_channels,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_requests_collect_args_of_channel_closed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Removed,
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
  g_value_set_boxed (args->values + 0, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_requests_invoke_callback_for_channel_closed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_requests_signal_callback_channel_closed callback =
      (tp_cli_connection_interface_requests_signal_callback_channel_closed) generic_callback;

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
tp_cli_connection_interface_requests_connect_to_channel_closed (TpConnection *proxy,
    tp_cli_connection_interface_requests_signal_callback_channel_closed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS, "ChannelClosed",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_requests_collect_args_of_channel_closed),
      _tp_cli_connection_interface_requests_invoke_callback_for_channel_closed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_requests_collect_callback_create_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Channel;
  GHashTable *out_Properties;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Channel,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), &out_Properties,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_take_boxed (args->values + 0, out_Channel);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 1, out_Properties);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_requests_invoke_callback_create_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_requests_callback_for_create_channel callback = (tp_cli_connection_interface_requests_callback_for_create_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_requests_call_create_channel (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Request,
    tp_cli_connection_interface_requests_callback_for_create_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "CreateChannel",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CreateChannel", iface,
          _tp_cli_connection_interface_requests_invoke_callback_create_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CreateChannel",
              _tp_cli_connection_interface_requests_collect_callback_create_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Channel;
    GHashTable **out_Properties;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_requests_run_state_create_channel;
static void
_tp_cli_connection_interface_requests_finish_running_create_channel (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_requests_run_state_create_channel *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Channel != NULL)
    *state->out_Channel = g_value_dup_boxed (args->values + 0);

  if (state->out_Properties != NULL)
    *state->out_Properties = g_value_dup_boxed (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_requests_run_create_channel (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Request,
    gchar **out_Channel,
    GHashTable **out_Properties,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_requests_run_state_create_channel state = {
      NULL /* loop */, error,
    out_Channel,
    out_Properties,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "CreateChannel", iface,
      _tp_cli_connection_interface_requests_finish_running_create_channel,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "CreateChannel",
          _tp_cli_connection_interface_requests_collect_callback_create_channel,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_requests_collect_callback_ensure_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gboolean out_Yours;
  gchar *out_Channel;
  GHashTable *out_Properties;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_BOOLEAN, &out_Yours,
      DBUS_TYPE_G_OBJECT_PATH, &out_Channel,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), &out_Properties,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (3);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 3; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_BOOLEAN);
  g_value_set_boolean (args->values + 0, out_Yours);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_OBJECT_PATH);
  g_value_take_boxed (args->values + 1, out_Channel);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 2, out_Properties);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_requests_invoke_callback_ensure_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_requests_callback_for_ensure_channel callback = (tp_cli_connection_interface_requests_callback_for_ensure_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          0,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boolean (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_requests_call_ensure_channel (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Request,
    tp_cli_connection_interface_requests_callback_for_ensure_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            NULL,
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "EnsureChannel",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "EnsureChannel", iface,
          _tp_cli_connection_interface_requests_invoke_callback_ensure_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "EnsureChannel",
              _tp_cli_connection_interface_requests_collect_callback_ensure_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gboolean *out_Yours;
    gchar **out_Channel;
    GHashTable **out_Properties;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_requests_run_state_ensure_channel;
static void
_tp_cli_connection_interface_requests_finish_running_ensure_channel (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_requests_run_state_ensure_channel *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Yours != NULL)
    *state->out_Yours = g_value_get_boolean (args->values + 0);

  if (state->out_Channel != NULL)
    *state->out_Channel = g_value_dup_boxed (args->values + 1);

  if (state->out_Properties != NULL)
    *state->out_Properties = g_value_dup_boxed (args->values + 2);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_requests_run_ensure_channel (TpConnection *proxy,
    gint timeout_ms,
    GHashTable *in_Request,
    gboolean *out_Yours,
    gchar **out_Channel,
    GHashTable **out_Properties,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_requests_run_state_ensure_channel state = {
      NULL /* loop */, error,
    out_Yours,
    out_Channel,
    out_Properties,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "EnsureChannel", iface,
      _tp_cli_connection_interface_requests_finish_running_ensure_channel,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "EnsureChannel",
          _tp_cli_connection_interface_requests_collect_callback_ensure_channel,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Request,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static inline void
tp_cli_add_signals_for_connection_interface_service_point (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ServicePointsChanged",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)), G_TYPE_STRV, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_service_point_collect_args_of_service_points_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Service_Points,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)), G_TYPE_STRV, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Service_Points);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_service_point_invoke_callback_for_service_points_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_service_point_signal_callback_service_points_changed callback =
      (tp_cli_connection_interface_service_point_signal_callback_service_points_changed) generic_callback;

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
tp_cli_connection_interface_service_point_connect_to_service_points_changed (TpConnection *proxy,
    tp_cli_connection_interface_service_point_signal_callback_service_points_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)), G_TYPE_STRV, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_SERVICE_POINT, "ServicePointsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_service_point_collect_args_of_service_points_changed),
      _tp_cli_connection_interface_service_point_invoke_callback_for_service_points_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_sidecars1_collect_callback_ensure_sidecar (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Path;
  GHashTable *out_Properties;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Path,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), &out_Properties,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (2);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 2; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_take_boxed (args->values + 0, out_Path);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 1, out_Properties);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_sidecars1_invoke_callback_ensure_sidecar (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_sidecars1_callback_for_ensure_sidecar callback = (tp_cli_connection_interface_sidecars1_callback_for_ensure_sidecar) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_sidecars1_call_ensure_sidecar (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Main_Interface,
    tp_cli_connection_interface_sidecars1_callback_for_ensure_sidecar callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_SIDECARS1;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "EnsureSidecar",
          G_TYPE_STRING, in_Main_Interface,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "EnsureSidecar", iface,
          _tp_cli_connection_interface_sidecars1_invoke_callback_ensure_sidecar,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "EnsureSidecar",
              _tp_cli_connection_interface_sidecars1_collect_callback_ensure_sidecar,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Main_Interface,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_connection_interface_simple_presence (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "PresencesChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_interface_simple_presence_collect_args_of_presences_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Presence,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Presence);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_interface_simple_presence_invoke_callback_for_presences_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_simple_presence_signal_callback_presences_changed callback =
      (tp_cli_connection_interface_simple_presence_signal_callback_presences_changed) generic_callback;

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
tp_cli_connection_interface_simple_presence_connect_to_presences_changed (TpConnection *proxy,
    tp_cli_connection_interface_simple_presence_signal_callback_presences_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE, "PresencesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_connection_interface_simple_presence_collect_args_of_presences_changed),
      _tp_cli_connection_interface_simple_presence_invoke_callback_for_presences_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_interface_simple_presence_collect_callback_set_presence (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_connection_interface_simple_presence_invoke_callback_set_presence (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_simple_presence_callback_for_set_presence callback = (tp_cli_connection_interface_simple_presence_callback_for_set_presence) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_simple_presence_call_set_presence (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    const gchar *in_Status_Message,
    tp_cli_connection_interface_simple_presence_callback_for_set_presence callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetPresence",
          G_TYPE_STRING, in_Status,
          G_TYPE_STRING, in_Status_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetPresence", iface,
          _tp_cli_connection_interface_simple_presence_invoke_callback_set_presence,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetPresence",
              _tp_cli_connection_interface_simple_presence_collect_callback_set_presence,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Status,
              G_TYPE_STRING, in_Status_Message,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_simple_presence_run_state_set_presence;
static void
_tp_cli_connection_interface_simple_presence_finish_running_set_presence (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_simple_presence_run_state_set_presence *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_simple_presence_run_set_presence (TpConnection *proxy,
    gint timeout_ms,
    const gchar *in_Status,
    const gchar *in_Status_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_simple_presence_run_state_set_presence state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetPresence", iface,
      _tp_cli_connection_interface_simple_presence_finish_running_set_presence,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetPresence",
          _tp_cli_connection_interface_simple_presence_collect_callback_set_presence,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Status,
              G_TYPE_STRING, in_Status_Message,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


static void
_tp_cli_connection_interface_simple_presence_collect_callback_get_presences (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Presence;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Presence,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Presence);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_interface_simple_presence_invoke_callback_get_presences (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_interface_simple_presence_callback_for_get_presences callback = (tp_cli_connection_interface_simple_presence_callback_for_get_presences) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnection *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnection *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_interface_simple_presence_call_get_presences (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    tp_cli_connection_interface_simple_presence_callback_for_get_presences callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetPresences",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetPresences", iface,
          _tp_cli_connection_interface_simple_presence_invoke_callback_get_presences,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetPresences",
              _tp_cli_connection_interface_simple_presence_collect_callback_get_presences,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Presence;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_interface_simple_presence_run_state_get_presences;
static void
_tp_cli_connection_interface_simple_presence_finish_running_get_presences (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_interface_simple_presence_run_state_get_presences *state = user_data;

  state->success = (error == NULL);
  state->completed = TRUE;
  g_main_loop_quit (state->loop);

  if (error != NULL)
    {
      if (state->error != NULL)
        *state->error = error;
      else
        g_error_free (error);

      return;
    }

  if (state->out_Presence != NULL)
    *state->out_Presence = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_interface_simple_presence_run_get_presences (TpConnection *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    GHashTable **out_Presence,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE;
  TpProxyPendingCall *pc;
  _tp_cli_connection_interface_simple_presence_run_state_get_presences state = {
      NULL /* loop */, error,
    out_Presence,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetPresences", iface,
      _tp_cli_connection_interface_simple_presence_finish_running_get_presences,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetPresences",
          _tp_cli_connection_interface_simple_presence_collect_callback_get_presences,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_INVALID));

  if (!state.completed)
    g_main_loop_run (state.loop);

  if (!state.completed)
    tp_proxy_pending_call_cancel (pc);

  if (loop != NULL)
    *loop = NULL;

  g_main_loop_unref (state.loop);

  return state.success;
}


/*
 * tp_cli_connection_add_signals:
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
tp_cli_connection_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CONNECTION)
    tp_cli_add_signals_for_connection (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING)
    tp_cli_add_signals_for_connection_interface_aliasing (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_ANONYMITY)
    tp_cli_add_signals_for_connection_interface_anonymity (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS)
    tp_cli_add_signals_for_connection_interface_avatars (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_BALANCE)
    tp_cli_add_signals_for_connection_interface_balance (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CAPABILITIES)
    tp_cli_add_signals_for_connection_interface_capabilities (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CELLULAR)
    tp_cli_add_signals_for_connection_interface_cellular (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES)
    tp_cli_add_signals_for_connection_interface_client_types (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING)
    tp_cli_add_signals_for_connection_interface_contact_blocking (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES)
    tp_cli_add_signals_for_connection_interface_contact_capabilities (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS)
    tp_cli_add_signals_for_connection_interface_contact_groups (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO)
    tp_cli_add_signals_for_connection_interface_contact_info (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST)
    tp_cli_add_signals_for_connection_interface_contact_list (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION)
    tp_cli_add_signals_for_connection_interface_location (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_MAIL_NOTIFICATION)
    tp_cli_add_signals_for_connection_interface_mail_notification (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_POWER_SAVING)
    tp_cli_add_signals_for_connection_interface_power_saving (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE)
    tp_cli_add_signals_for_connection_interface_presence (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_RENAMING)
    tp_cli_add_signals_for_connection_interface_renaming (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS)
    tp_cli_add_signals_for_connection_interface_requests (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_SERVICE_POINT)
    tp_cli_add_signals_for_connection_interface_service_point (proxy);
  if (quark == TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE)
    tp_cli_add_signals_for_connection_interface_simple_presence (proxy);
}
