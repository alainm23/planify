/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_media_session_handler (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewStreamHandler",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_media_session_handler_collect_args_of_new_stream_handler (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Stream_Handler,
    guint arg_ID,
    guint arg_Media_Type,
    guint arg_Direction,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Stream_Handler);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_ID);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Media_Type);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_UINT);
  g_value_set_uint (args->values + 3, arg_Direction);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_session_handler_invoke_callback_for_new_stream_handler (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_session_handler_signal_callback_new_stream_handler callback =
      (tp_cli_media_session_handler_signal_callback_new_stream_handler) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_uint (args->values + 3),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_media_session_handler_connect_to_new_stream_handler (TpMediaSessionHandler *proxy,
    tp_cli_media_session_handler_signal_callback_new_stream_handler callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_SESSION_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_SESSION_HANDLER, "NewStreamHandler",
      expected_types,
      G_CALLBACK (_tp_cli_media_session_handler_collect_args_of_new_stream_handler),
      _tp_cli_media_session_handler_invoke_callback_for_new_stream_handler,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_session_handler_collect_callback_error (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_session_handler_invoke_callback_error (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_session_handler_callback_for_error callback = (tp_cli_media_session_handler_callback_for_error) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaSessionHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaSessionHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_session_handler_call_error (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    tp_cli_media_session_handler_callback_for_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_SESSION_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_SESSION_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Error",
          G_TYPE_UINT, in_Error_Code,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Error", iface,
          _tp_cli_media_session_handler_invoke_callback_error,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Error",
              _tp_cli_media_session_handler_collect_callback_error,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Error_Code,
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
} _tp_cli_media_session_handler_run_state_error;
static void
_tp_cli_media_session_handler_finish_running_error (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_session_handler_run_state_error *state = user_data;

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
tp_cli_media_session_handler_run_error (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_SESSION_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_session_handler_run_state_error state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_SESSION_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Error", iface,
      _tp_cli_media_session_handler_finish_running_error,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Error",
          _tp_cli_media_session_handler_collect_callback_error,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Error_Code,
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
_tp_cli_media_session_handler_collect_callback_ready (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_session_handler_invoke_callback_ready (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_session_handler_callback_for_ready callback = (tp_cli_media_session_handler_callback_for_ready) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaSessionHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaSessionHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_session_handler_call_ready (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    tp_cli_media_session_handler_callback_for_ready callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_SESSION_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_SESSION_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Ready",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Ready", iface,
          _tp_cli_media_session_handler_invoke_callback_ready,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Ready",
              _tp_cli_media_session_handler_collect_callback_ready,
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
} _tp_cli_media_session_handler_run_state_ready;
static void
_tp_cli_media_session_handler_finish_running_ready (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_session_handler_run_state_ready *state = user_data;

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
tp_cli_media_session_handler_run_ready (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_SESSION_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_session_handler_run_state_ready state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_SESSION_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Ready", iface,
      _tp_cli_media_session_handler_finish_running_ready,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Ready",
          _tp_cli_media_session_handler_collect_callback_ready,
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
 * tp_cli_media_session_handler_add_signals:
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
tp_cli_media_session_handler_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_MEDIA_SESSION_HANDLER)
    tp_cli_add_signals_for_media_session_handler (proxy);
}
