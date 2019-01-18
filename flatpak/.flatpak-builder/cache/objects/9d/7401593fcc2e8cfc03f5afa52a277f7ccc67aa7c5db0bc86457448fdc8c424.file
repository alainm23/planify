/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_dbus_daemon (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NameOwnerChanged",
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "NameLost",
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "NameAcquired",
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_dbus_daemon_collect_args_of_name_owner_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg0,
    const gchar *arg1,
    const gchar *arg2,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_set_string (args->values + 0, arg0);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg1);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg2);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_for_name_owner_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_signal_callback_name_owner_changed callback =
      (tp_cli_dbus_daemon_signal_callback_name_owner_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_dbus_daemon_connect_to_name_owner_changed (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_owner_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_DBUS_DAEMON, "NameOwnerChanged",
      expected_types,
      G_CALLBACK (_tp_cli_dbus_daemon_collect_args_of_name_owner_changed),
      _tp_cli_dbus_daemon_invoke_callback_for_name_owner_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_dbus_daemon_collect_args_of_name_lost (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg0,
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
  g_value_set_string (args->values + 0, arg0);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_for_name_lost (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_signal_callback_name_lost callback =
      (tp_cli_dbus_daemon_signal_callback_name_lost) generic_callback;

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
tp_cli_dbus_daemon_connect_to_name_lost (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_lost callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_DBUS_DAEMON, "NameLost",
      expected_types,
      G_CALLBACK (_tp_cli_dbus_daemon_collect_args_of_name_lost),
      _tp_cli_dbus_daemon_invoke_callback_for_name_lost,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_dbus_daemon_collect_args_of_name_acquired (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg0,
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
  g_value_set_string (args->values + 0, arg0);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_for_name_acquired (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_signal_callback_name_acquired callback =
      (tp_cli_dbus_daemon_signal_callback_name_acquired) generic_callback;

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
tp_cli_dbus_daemon_connect_to_name_acquired (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_acquired callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_DBUS_DAEMON, "NameAcquired",
      expected_types,
      G_CALLBACK (_tp_cli_dbus_daemon_collect_args_of_name_acquired),
      _tp_cli_dbus_daemon_invoke_callback_for_name_acquired,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_dbus_daemon_collect_callback_hello (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out0,
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
  g_value_take_string (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_hello (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_hello callback = (tp_cli_dbus_daemon_callback_for_hello) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_hello (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_hello callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Hello",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Hello", iface,
          _tp_cli_dbus_daemon_invoke_callback_hello,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Hello",
              _tp_cli_dbus_daemon_collect_callback_hello,
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
    gchar **out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_hello;
static void
_tp_cli_dbus_daemon_finish_running_hello (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_hello *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_hello (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar **out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_hello state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Hello", iface,
      _tp_cli_dbus_daemon_finish_running_hello,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Hello",
          _tp_cli_dbus_daemon_collect_callback_hello,
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
_tp_cli_dbus_daemon_collect_callback_request_name (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out0,
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
  g_value_set_uint (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_request_name (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_request_name callback = (tp_cli_dbus_daemon_callback_for_request_name) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_request_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    tp_cli_dbus_daemon_callback_for_request_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestName",
          G_TYPE_STRING, in0,
          G_TYPE_UINT, in1,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestName", iface,
          _tp_cli_dbus_daemon_invoke_callback_request_name,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestName",
              _tp_cli_dbus_daemon_collect_callback_request_name,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_UINT, in1,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_request_name;
static void
_tp_cli_dbus_daemon_finish_running_request_name (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_request_name *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_request_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    guint *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_request_name state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestName", iface,
      _tp_cli_dbus_daemon_finish_running_request_name,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestName",
          _tp_cli_dbus_daemon_collect_callback_request_name,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_UINT, in1,
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
_tp_cli_dbus_daemon_collect_callback_release_name (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out0,
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
  g_value_set_uint (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_release_name (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_release_name callback = (tp_cli_dbus_daemon_callback_for_release_name) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_release_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_release_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReleaseName",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReleaseName", iface,
          _tp_cli_dbus_daemon_invoke_callback_release_name,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReleaseName",
              _tp_cli_dbus_daemon_collect_callback_release_name,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_release_name;
static void
_tp_cli_dbus_daemon_finish_running_release_name (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_release_name *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_release_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_release_name state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ReleaseName", iface,
      _tp_cli_dbus_daemon_finish_running_release_name,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ReleaseName",
          _tp_cli_dbus_daemon_collect_callback_release_name,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_start_service_by_name (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out0,
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
  g_value_set_uint (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_start_service_by_name (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_start_service_by_name callback = (tp_cli_dbus_daemon_callback_for_start_service_by_name) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_start_service_by_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    tp_cli_dbus_daemon_callback_for_start_service_by_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StartServiceByName",
          G_TYPE_STRING, in0,
          G_TYPE_UINT, in1,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StartServiceByName", iface,
          _tp_cli_dbus_daemon_invoke_callback_start_service_by_name,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StartServiceByName",
              _tp_cli_dbus_daemon_collect_callback_start_service_by_name,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_UINT, in1,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_start_service_by_name;
static void
_tp_cli_dbus_daemon_finish_running_start_service_by_name (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_start_service_by_name *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_start_service_by_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    guint *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_start_service_by_name state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StartServiceByName", iface,
      _tp_cli_dbus_daemon_finish_running_start_service_by_name,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StartServiceByName",
          _tp_cli_dbus_daemon_collect_callback_start_service_by_name,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_UINT, in1,
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
_tp_cli_dbus_daemon_collect_callback_name_has_owner (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gboolean out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_BOOLEAN, &out0,
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
  g_value_init (args->values + 0, G_TYPE_BOOLEAN);
  g_value_set_boolean (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_name_has_owner (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_name_has_owner callback = (tp_cli_dbus_daemon_callback_for_name_has_owner) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_boolean (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_name_has_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_name_has_owner callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "NameHasOwner",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NameHasOwner", iface,
          _tp_cli_dbus_daemon_invoke_callback_name_has_owner,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NameHasOwner",
              _tp_cli_dbus_daemon_collect_callback_name_has_owner,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gboolean *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_name_has_owner;
static void
_tp_cli_dbus_daemon_finish_running_name_has_owner (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_name_has_owner *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_boolean (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_name_has_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gboolean *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_name_has_owner state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "NameHasOwner", iface,
      _tp_cli_dbus_daemon_finish_running_name_has_owner,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "NameHasOwner",
          _tp_cli_dbus_daemon_collect_callback_name_has_owner,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_list_names (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out0,
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
  g_value_take_boxed (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_list_names (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_list_names callback = (tp_cli_dbus_daemon_callback_for_list_names) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_list_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_list_names callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListNames",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListNames", iface,
          _tp_cli_dbus_daemon_invoke_callback_list_names,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListNames",
              _tp_cli_dbus_daemon_collect_callback_list_names,
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
    gchar ***out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_list_names;
static void
_tp_cli_dbus_daemon_finish_running_list_names (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_list_names *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_list_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar ***out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_list_names state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListNames", iface,
      _tp_cli_dbus_daemon_finish_running_list_names,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListNames",
          _tp_cli_dbus_daemon_collect_callback_list_names,
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
_tp_cli_dbus_daemon_collect_callback_list_activatable_names (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out0,
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
  g_value_take_boxed (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_list_activatable_names (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_list_activatable_names callback = (tp_cli_dbus_daemon_callback_for_list_activatable_names) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_list_activatable_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_list_activatable_names callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListActivatableNames",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListActivatableNames", iface,
          _tp_cli_dbus_daemon_invoke_callback_list_activatable_names,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListActivatableNames",
              _tp_cli_dbus_daemon_collect_callback_list_activatable_names,
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
    gchar ***out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_list_activatable_names;
static void
_tp_cli_dbus_daemon_finish_running_list_activatable_names (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_list_activatable_names *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_list_activatable_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar ***out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_list_activatable_names state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListActivatableNames", iface,
      _tp_cli_dbus_daemon_finish_running_list_activatable_names,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListActivatableNames",
          _tp_cli_dbus_daemon_collect_callback_list_activatable_names,
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
_tp_cli_dbus_daemon_collect_callback_add_match (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_dbus_daemon_invoke_callback_add_match (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_add_match callback = (tp_cli_dbus_daemon_callback_for_add_match) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_add_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_add_match callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddMatch",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddMatch", iface,
          _tp_cli_dbus_daemon_invoke_callback_add_match,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddMatch",
              _tp_cli_dbus_daemon_collect_callback_add_match,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_add_match;
static void
_tp_cli_dbus_daemon_finish_running_add_match (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_add_match *state = user_data;

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
tp_cli_dbus_daemon_run_add_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_add_match state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AddMatch", iface,
      _tp_cli_dbus_daemon_finish_running_add_match,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AddMatch",
          _tp_cli_dbus_daemon_collect_callback_add_match,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_remove_match (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_dbus_daemon_invoke_callback_remove_match (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_remove_match callback = (tp_cli_dbus_daemon_callback_for_remove_match) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_remove_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_remove_match callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveMatch",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveMatch", iface,
          _tp_cli_dbus_daemon_invoke_callback_remove_match,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveMatch",
              _tp_cli_dbus_daemon_collect_callback_remove_match,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_remove_match;
static void
_tp_cli_dbus_daemon_finish_running_remove_match (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_remove_match *state = user_data;

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
tp_cli_dbus_daemon_run_remove_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_remove_match state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveMatch", iface,
      _tp_cli_dbus_daemon_finish_running_remove_match,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveMatch",
          _tp_cli_dbus_daemon_collect_callback_remove_match,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_get_name_owner (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out0,
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
  g_value_take_string (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_get_name_owner (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_get_name_owner callback = (tp_cli_dbus_daemon_callback_for_get_name_owner) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_get_name_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_name_owner callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetNameOwner",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetNameOwner", iface,
          _tp_cli_dbus_daemon_invoke_callback_get_name_owner,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetNameOwner",
              _tp_cli_dbus_daemon_collect_callback_get_name_owner,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_get_name_owner;
static void
_tp_cli_dbus_daemon_finish_running_get_name_owner (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_get_name_owner *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_get_name_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gchar **out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_get_name_owner state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetNameOwner", iface,
      _tp_cli_dbus_daemon_finish_running_get_name_owner,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetNameOwner",
          _tp_cli_dbus_daemon_collect_callback_get_name_owner,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_list_queued_owners (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out0,
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
  g_value_take_boxed (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_list_queued_owners (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_list_queued_owners callback = (tp_cli_dbus_daemon_callback_for_list_queued_owners) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_list_queued_owners (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_list_queued_owners callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListQueuedOwners",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListQueuedOwners", iface,
          _tp_cli_dbus_daemon_invoke_callback_list_queued_owners,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListQueuedOwners",
              _tp_cli_dbus_daemon_collect_callback_list_queued_owners,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar ***out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_list_queued_owners;
static void
_tp_cli_dbus_daemon_finish_running_list_queued_owners (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_list_queued_owners *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_list_queued_owners (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gchar ***out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_list_queued_owners state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListQueuedOwners", iface,
      _tp_cli_dbus_daemon_finish_running_list_queued_owners,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListQueuedOwners",
          _tp_cli_dbus_daemon_collect_callback_list_queued_owners,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_get_connection_unix_user (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out0,
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
  g_value_set_uint (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_get_connection_unix_user (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_get_connection_unix_user callback = (tp_cli_dbus_daemon_callback_for_get_connection_unix_user) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_get_connection_unix_user (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_unix_user callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetConnectionUnixUser",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetConnectionUnixUser", iface,
          _tp_cli_dbus_daemon_invoke_callback_get_connection_unix_user,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetConnectionUnixUser",
              _tp_cli_dbus_daemon_collect_callback_get_connection_unix_user,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_get_connection_unix_user;
static void
_tp_cli_dbus_daemon_finish_running_get_connection_unix_user (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_get_connection_unix_user *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_get_connection_unix_user (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_get_connection_unix_user state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetConnectionUnixUser", iface,
      _tp_cli_dbus_daemon_finish_running_get_connection_unix_user,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetConnectionUnixUser",
          _tp_cli_dbus_daemon_collect_callback_get_connection_unix_user,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_get_connection_unix_process_id (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out0,
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
  g_value_set_uint (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_get_connection_unix_process_id (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_get_connection_unix_process_id callback = (tp_cli_dbus_daemon_callback_for_get_connection_unix_process_id) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_get_connection_unix_process_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_unix_process_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetConnectionUnixProcessID",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetConnectionUnixProcessID", iface,
          _tp_cli_dbus_daemon_invoke_callback_get_connection_unix_process_id,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetConnectionUnixProcessID",
              _tp_cli_dbus_daemon_collect_callback_get_connection_unix_process_id,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_get_connection_unix_process_id;
static void
_tp_cli_dbus_daemon_finish_running_get_connection_unix_process_id (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_get_connection_unix_process_id *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_get_connection_unix_process_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_get_connection_unix_process_id state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetConnectionUnixProcessID", iface,
      _tp_cli_dbus_daemon_finish_running_get_connection_unix_process_id,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetConnectionUnixProcessID",
          _tp_cli_dbus_daemon_collect_callback_get_connection_unix_process_id,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_get_connection_se_linux_security_context (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), &out0,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR));
  g_value_take_boxed (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_get_connection_se_linux_security_context (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_get_connection_se_linux_security_context callback = (tp_cli_dbus_daemon_callback_for_get_connection_se_linux_security_context) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_get_connection_se_linux_security_context (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_se_linux_security_context callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetConnectionSELinuxSecurityContext",
          G_TYPE_STRING, in0,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetConnectionSELinuxSecurityContext", iface,
          _tp_cli_dbus_daemon_invoke_callback_get_connection_se_linux_security_context,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetConnectionSELinuxSecurityContext",
              _tp_cli_dbus_daemon_collect_callback_get_connection_se_linux_security_context,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in0,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GArray **out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_get_connection_se_linux_security_context;
static void
_tp_cli_dbus_daemon_finish_running_get_connection_se_linux_security_context (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_get_connection_se_linux_security_context *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_get_connection_se_linux_security_context (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GArray **out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_get_connection_se_linux_security_context state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetConnectionSELinuxSecurityContext", iface,
      _tp_cli_dbus_daemon_finish_running_get_connection_se_linux_security_context,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetConnectionSELinuxSecurityContext",
          _tp_cli_dbus_daemon_collect_callback_get_connection_se_linux_security_context,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in0,
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
_tp_cli_dbus_daemon_collect_callback_reload_config (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_dbus_daemon_invoke_callback_reload_config (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_reload_config callback = (tp_cli_dbus_daemon_callback_for_reload_config) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_reload_config (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_reload_config callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReloadConfig",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReloadConfig", iface,
          _tp_cli_dbus_daemon_invoke_callback_reload_config,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReloadConfig",
              _tp_cli_dbus_daemon_collect_callback_reload_config,
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
} _tp_cli_dbus_daemon_run_state_reload_config;
static void
_tp_cli_dbus_daemon_finish_running_reload_config (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_reload_config *state = user_data;

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
tp_cli_dbus_daemon_run_reload_config (TpDBusDaemon *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_reload_config state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ReloadConfig", iface,
      _tp_cli_dbus_daemon_finish_running_reload_config,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ReloadConfig",
          _tp_cli_dbus_daemon_collect_callback_reload_config,
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
_tp_cli_dbus_daemon_collect_callback_get_id (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out0;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out0,
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
  g_value_take_string (args->values + 0, out0);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_dbus_daemon_invoke_callback_get_id (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_dbus_daemon_callback_for_get_id callback = (tp_cli_dbus_daemon_callback_for_get_id) generic_callback;

  if (error != NULL)
    {
      callback ((TpDBusDaemon *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDBusDaemon *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_dbus_daemon_call_get_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_get_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetId",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetId", iface,
          _tp_cli_dbus_daemon_invoke_callback_get_id,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetId",
              _tp_cli_dbus_daemon_collect_callback_get_id,
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
    gchar **out0;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_dbus_daemon_run_state_get_id;
static void
_tp_cli_dbus_daemon_finish_running_get_id (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_dbus_daemon_run_state_get_id *state = user_data;

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

  if (state->out0 != NULL)
    *state->out0 = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_dbus_daemon_run_get_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar **out0,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_DBUS_DAEMON;
  TpProxyPendingCall *pc;
  _tp_cli_dbus_daemon_run_state_get_id state = {
      NULL /* loop */, error,
    out0,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetId", iface,
      _tp_cli_dbus_daemon_finish_running_get_id,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetId",
          _tp_cli_dbus_daemon_collect_callback_get_id,
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


/*
 * tp_cli_dbus_daemon_add_signals:
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
tp_cli_dbus_daemon_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_DBUS_DAEMON)
    tp_cli_add_signals_for_dbus_daemon (proxy);
}
