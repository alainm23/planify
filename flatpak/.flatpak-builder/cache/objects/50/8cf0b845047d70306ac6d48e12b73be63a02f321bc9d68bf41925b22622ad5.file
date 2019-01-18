/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_channel (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "Closed",
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_invoke_callback_for_closed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_signal_callback_closed callback =
      (tp_cli_channel_signal_callback_closed) generic_callback;

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
tp_cli_channel_connect_to_closed (TpChannel *proxy,
    tp_cli_channel_signal_callback_closed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL, "Closed",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_channel_invoke_callback_for_closed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_collect_callback_close (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_invoke_callback_close (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_callback_for_close callback = (tp_cli_channel_callback_for_close) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_call_close (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_callback_for_close callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Close",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Close", iface,
          _tp_cli_channel_invoke_callback_close,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Close",
              _tp_cli_channel_collect_callback_close,
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
} _tp_cli_channel_run_state_close;
static void
_tp_cli_channel_finish_running_close (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_run_state_close *state = user_data;

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
tp_cli_channel_run_close (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  TpProxyPendingCall *pc;
  _tp_cli_channel_run_state_close state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Close", iface,
      _tp_cli_channel_finish_running_close,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Close",
          _tp_cli_channel_collect_callback_close,
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
_tp_cli_channel_collect_callback_get_channel_type (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Channel_Type;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Channel_Type,
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
  g_value_take_string (args->values + 0, out_Channel_Type);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_invoke_callback_get_channel_type (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_callback_for_get_channel_type callback = (tp_cli_channel_callback_for_get_channel_type) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_call_get_channel_type (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_callback_for_get_channel_type callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetChannelType",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetChannelType", iface,
          _tp_cli_channel_invoke_callback_get_channel_type,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetChannelType",
              _tp_cli_channel_collect_callback_get_channel_type,
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
    gchar **out_Channel_Type;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_run_state_get_channel_type;
static void
_tp_cli_channel_finish_running_get_channel_type (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_run_state_get_channel_type *state = user_data;

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

  if (state->out_Channel_Type != NULL)
    *state->out_Channel_Type = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_run_get_channel_type (TpChannel *proxy,
    gint timeout_ms,
    gchar **out_Channel_Type,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  TpProxyPendingCall *pc;
  _tp_cli_channel_run_state_get_channel_type state = {
      NULL /* loop */, error,
    out_Channel_Type,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetChannelType", iface,
      _tp_cli_channel_finish_running_get_channel_type,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetChannelType",
          _tp_cli_channel_collect_callback_get_channel_type,
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
_tp_cli_channel_collect_callback_get_handle (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Target_Handle_Type;
  guint out_Target_Handle;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Target_Handle_Type,
      G_TYPE_UINT, &out_Target_Handle,
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
  g_value_set_uint (args->values + 0, out_Target_Handle_Type);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, out_Target_Handle);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_invoke_callback_get_handle (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_callback_for_get_handle callback = (tp_cli_channel_callback_for_get_handle) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_call_get_handle (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_callback_for_get_handle callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetHandle",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetHandle", iface,
          _tp_cli_channel_invoke_callback_get_handle,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetHandle",
              _tp_cli_channel_collect_callback_get_handle,
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
    guint *out_Target_Handle_Type;
    guint *out_Target_Handle;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_run_state_get_handle;
static void
_tp_cli_channel_finish_running_get_handle (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_run_state_get_handle *state = user_data;

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

  if (state->out_Target_Handle_Type != NULL)
    *state->out_Target_Handle_Type = g_value_get_uint (args->values + 0);

  if (state->out_Target_Handle != NULL)
    *state->out_Target_Handle = g_value_get_uint (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_run_get_handle (TpChannel *proxy,
    gint timeout_ms,
    guint *out_Target_Handle_Type,
    guint *out_Target_Handle,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  TpProxyPendingCall *pc;
  _tp_cli_channel_run_state_get_handle state = {
      NULL /* loop */, error,
    out_Target_Handle_Type,
    out_Target_Handle,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetHandle", iface,
      _tp_cli_channel_finish_running_get_handle,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetHandle",
          _tp_cli_channel_collect_callback_get_handle,
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
_tp_cli_channel_collect_callback_get_interfaces (DBusGProxy *proxy,
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
_tp_cli_channel_invoke_callback_get_interfaces (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_callback_for_get_interfaces callback = (tp_cli_channel_callback_for_get_interfaces) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_call_get_interfaces (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_callback_for_get_interfaces callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
          _tp_cli_channel_invoke_callback_get_interfaces,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetInterfaces",
              _tp_cli_channel_collect_callback_get_interfaces,
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
} _tp_cli_channel_run_state_get_interfaces;
static void
_tp_cli_channel_finish_running_get_interfaces (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_run_state_get_interfaces *state = user_data;

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
tp_cli_channel_run_get_interfaces (TpChannel *proxy,
    gint timeout_ms,
    gchar ***out_Interfaces,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL;
  TpProxyPendingCall *pc;
  _tp_cli_channel_run_state_get_interfaces state = {
      NULL /* loop */, error,
    out_Interfaces,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetInterfaces", iface,
      _tp_cli_channel_finish_running_get_interfaces,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetInterfaces",
          _tp_cli_channel_collect_callback_get_interfaces,
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
tp_cli_add_signals_for_channel_interface_call_state (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "CallStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_call_state_collect_args_of_call_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_call_state_invoke_callback_for_call_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_call_state_signal_callback_call_state_changed callback =
      (tp_cli_channel_interface_call_state_signal_callback_call_state_changed) generic_callback;

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
tp_cli_channel_interface_call_state_connect_to_call_state_changed (TpChannel *proxy,
    tp_cli_channel_interface_call_state_signal_callback_call_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_CALL_STATE, "CallStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_call_state_collect_args_of_call_state_changed),
      _tp_cli_channel_interface_call_state_invoke_callback_for_call_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_call_state_collect_callback_get_call_states (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_States;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)), &out_States,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)));
  g_value_take_boxed (args->values + 0, out_States);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_call_state_invoke_callback_get_call_states (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_call_state_callback_for_get_call_states callback = (tp_cli_channel_interface_call_state_callback_for_get_call_states) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_call_state_call_get_call_states (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_call_state_callback_for_get_call_states callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CALL_STATE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetCallStates",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetCallStates", iface,
          _tp_cli_channel_interface_call_state_invoke_callback_get_call_states,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetCallStates",
              _tp_cli_channel_interface_call_state_collect_callback_get_call_states,
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
    GHashTable **out_States;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_call_state_run_state_get_call_states;
static void
_tp_cli_channel_interface_call_state_finish_running_get_call_states (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_call_state_run_state_get_call_states *state = user_data;

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

  if (state->out_States != NULL)
    *state->out_States = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_call_state_run_get_call_states (TpChannel *proxy,
    gint timeout_ms,
    GHashTable **out_States,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CALL_STATE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_call_state_run_state_get_call_states state = {
      NULL /* loop */, error,
    out_States,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetCallStates", iface,
      _tp_cli_channel_interface_call_state_finish_running_get_call_states,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetCallStates",
          _tp_cli_channel_interface_call_state_collect_callback_get_call_states,
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
_tp_cli_channel_interface_captcha_authentication_collect_callback_get_captchas (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Captcha_Info;
  guint out_Number_Required;
  gchar *out_Language;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRV, G_TYPE_INVALID)))), &out_Captcha_Info,
      G_TYPE_UINT, &out_Number_Required,
      G_TYPE_STRING, &out_Language,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRV, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Captcha_Info);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, out_Number_Required);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_take_string (args->values + 2, out_Language);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_captcha_authentication_invoke_callback_get_captchas (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_captcha_authentication_callback_for_get_captchas callback = (tp_cli_channel_interface_captcha_authentication_callback_for_get_captchas) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          0,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_string (args->values + 2),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_captcha_authentication_call_get_captchas (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_captcha_authentication_callback_for_get_captchas callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetCaptchas",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetCaptchas", iface,
          _tp_cli_channel_interface_captcha_authentication_invoke_callback_get_captchas,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetCaptchas",
              _tp_cli_channel_interface_captcha_authentication_collect_callback_get_captchas,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_interface_captcha_authentication_collect_callback_get_captcha_data (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Captcha_Data;

  dbus_g_proxy_end_call (proxy, call, &error,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), &out_Captcha_Data,
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
  g_value_take_boxed (args->values + 0, out_Captcha_Data);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_captcha_authentication_invoke_callback_get_captcha_data (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_captcha_authentication_callback_for_get_captcha_data callback = (tp_cli_channel_interface_captcha_authentication_callback_for_get_captcha_data) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_captcha_authentication_call_get_captcha_data (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    const gchar *in_Mime_Type,
    tp_cli_channel_interface_captcha_authentication_callback_for_get_captcha_data callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetCaptchaData",
          G_TYPE_UINT, in_ID,
          G_TYPE_STRING, in_Mime_Type,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetCaptchaData", iface,
          _tp_cli_channel_interface_captcha_authentication_invoke_callback_get_captcha_data,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetCaptchaData",
              _tp_cli_channel_interface_captcha_authentication_collect_callback_get_captcha_data,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_STRING, in_Mime_Type,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_interface_captcha_authentication_collect_callback_answer_captchas (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_captcha_authentication_invoke_callback_answer_captchas (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_captcha_authentication_callback_for_answer_captchas callback = (tp_cli_channel_interface_captcha_authentication_callback_for_answer_captchas) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_captcha_authentication_call_answer_captchas (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_Answers,
    tp_cli_channel_interface_captcha_authentication_callback_for_answer_captchas callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AnswerCaptchas",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), in_Answers,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AnswerCaptchas", iface,
          _tp_cli_channel_interface_captcha_authentication_invoke_callback_answer_captchas,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AnswerCaptchas",
              _tp_cli_channel_interface_captcha_authentication_collect_callback_answer_captchas,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)), in_Answers,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_interface_captcha_authentication_collect_callback_cancel_captcha (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_captcha_authentication_invoke_callback_cancel_captcha (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_captcha_authentication_callback_for_cancel_captcha callback = (tp_cli_channel_interface_captcha_authentication_callback_for_cancel_captcha) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_captcha_authentication_call_cancel_captcha (TpChannel *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Debug_Message,
    tp_cli_channel_interface_captcha_authentication_callback_for_cancel_captcha callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CancelCaptcha",
          G_TYPE_UINT, in_Reason,
          G_TYPE_STRING, in_Debug_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CancelCaptcha", iface,
          _tp_cli_channel_interface_captcha_authentication_invoke_callback_cancel_captcha,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CancelCaptcha",
              _tp_cli_channel_interface_captcha_authentication_collect_callback_cancel_captcha,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Debug_Message,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_channel_interface_chat_state (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ChatStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_chat_state_collect_args_of_chat_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Contact,
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
  g_value_set_uint (args->values + 0, arg_Contact);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_chat_state_invoke_callback_for_chat_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_chat_state_signal_callback_chat_state_changed callback =
      (tp_cli_channel_interface_chat_state_signal_callback_chat_state_changed) generic_callback;

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
tp_cli_channel_interface_chat_state_connect_to_chat_state_changed (TpChannel *proxy,
    tp_cli_channel_interface_chat_state_signal_callback_chat_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_CHAT_STATE, "ChatStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_chat_state_collect_args_of_chat_state_changed),
      _tp_cli_channel_interface_chat_state_invoke_callback_for_chat_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_chat_state_collect_callback_set_chat_state (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_chat_state_invoke_callback_set_chat_state (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_chat_state_callback_for_set_chat_state callback = (tp_cli_channel_interface_chat_state_callback_for_set_chat_state) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_chat_state_call_set_chat_state (TpChannel *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_channel_interface_chat_state_callback_for_set_chat_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CHAT_STATE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetChatState",
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetChatState", iface,
          _tp_cli_channel_interface_chat_state_invoke_callback_set_chat_state,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetChatState",
              _tp_cli_channel_interface_chat_state_collect_callback_set_chat_state,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_State,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_chat_state_run_state_set_chat_state;
static void
_tp_cli_channel_interface_chat_state_finish_running_set_chat_state (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_chat_state_run_state_set_chat_state *state = user_data;

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
tp_cli_channel_interface_chat_state_run_set_chat_state (TpChannel *proxy,
    gint timeout_ms,
    guint in_State,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_CHAT_STATE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_chat_state_run_state_set_chat_state state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetChatState", iface,
      _tp_cli_channel_interface_chat_state_finish_running_set_chat_state,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetChatState",
          _tp_cli_channel_interface_chat_state_collect_callback_set_chat_state,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_State,
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
tp_cli_add_signals_for_channel_interface_conference (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ChannelMerged",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ChannelRemoved",
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_conference_collect_args_of_channel_merged (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Channel,
    guint arg_Channel_Specific_Handle,
    GHashTable *arg_Properties,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Channel);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Channel_Specific_Handle);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 2, arg_Properties);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_conference_invoke_callback_for_channel_merged (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_conference_signal_callback_channel_merged callback =
      (tp_cli_channel_interface_conference_signal_callback_channel_merged) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_conference_connect_to_channel_merged (TpChannel *proxy,
    tp_cli_channel_interface_conference_signal_callback_channel_merged callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_CONFERENCE, "ChannelMerged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_conference_collect_args_of_channel_merged),
      _tp_cli_channel_interface_conference_invoke_callback_for_channel_merged,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_conference_collect_args_of_channel_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Channel,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Channel);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 1, arg_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_conference_invoke_callback_for_channel_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_conference_signal_callback_channel_removed callback =
      (tp_cli_channel_interface_conference_signal_callback_channel_removed) generic_callback;

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
tp_cli_channel_interface_conference_connect_to_channel_removed (TpChannel *proxy,
    tp_cli_channel_interface_conference_signal_callback_channel_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_CONFERENCE, "ChannelRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_conference_collect_args_of_channel_removed),
      _tp_cli_channel_interface_conference_invoke_callback_for_channel_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static inline void
tp_cli_add_signals_for_channel_interface_dtmf (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "TonesDeferred",
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SendingTones",
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StoppedTones",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_dtmf_collect_args_of_tones_deferred (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Tones,
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
  g_value_set_string (args->values + 0, arg_Tones);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_for_tones_deferred (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_signal_callback_tones_deferred callback =
      (tp_cli_channel_interface_dtmf_signal_callback_tones_deferred) generic_callback;

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
tp_cli_channel_interface_dtmf_connect_to_tones_deferred (TpChannel *proxy,
    tp_cli_channel_interface_dtmf_signal_callback_tones_deferred callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF, "TonesDeferred",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_dtmf_collect_args_of_tones_deferred),
      _tp_cli_channel_interface_dtmf_invoke_callback_for_tones_deferred,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_dtmf_collect_args_of_sending_tones (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Tones,
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
  g_value_set_string (args->values + 0, arg_Tones);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_for_sending_tones (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_signal_callback_sending_tones callback =
      (tp_cli_channel_interface_dtmf_signal_callback_sending_tones) generic_callback;

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
tp_cli_channel_interface_dtmf_connect_to_sending_tones (TpChannel *proxy,
    tp_cli_channel_interface_dtmf_signal_callback_sending_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF, "SendingTones",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_dtmf_collect_args_of_sending_tones),
      _tp_cli_channel_interface_dtmf_invoke_callback_for_sending_tones,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_dtmf_collect_args_of_stopped_tones (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Cancelled,
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
  g_value_set_boolean (args->values + 0, arg_Cancelled);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_for_stopped_tones (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_signal_callback_stopped_tones callback =
      (tp_cli_channel_interface_dtmf_signal_callback_stopped_tones) generic_callback;

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
tp_cli_channel_interface_dtmf_connect_to_stopped_tones (TpChannel *proxy,
    tp_cli_channel_interface_dtmf_signal_callback_stopped_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF, "StoppedTones",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_dtmf_collect_args_of_stopped_tones),
      _tp_cli_channel_interface_dtmf_invoke_callback_for_stopped_tones,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_dtmf_collect_callback_start_tone (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_start_tone (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_callback_for_start_tone callback = (tp_cli_channel_interface_dtmf_callback_for_start_tone) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_dtmf_call_start_tone (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    guchar in_Event,
    tp_cli_channel_interface_dtmf_callback_for_start_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StartTone",
          G_TYPE_UINT, in_Stream_ID,
          G_TYPE_UCHAR, in_Event,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StartTone", iface,
          _tp_cli_channel_interface_dtmf_invoke_callback_start_tone,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StartTone",
              _tp_cli_channel_interface_dtmf_collect_callback_start_tone,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
              G_TYPE_UCHAR, in_Event,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_dtmf_run_state_start_tone;
static void
_tp_cli_channel_interface_dtmf_finish_running_start_tone (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_dtmf_run_state_start_tone *state = user_data;

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
tp_cli_channel_interface_dtmf_run_start_tone (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    guchar in_Event,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_dtmf_run_state_start_tone state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StartTone", iface,
      _tp_cli_channel_interface_dtmf_finish_running_start_tone,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StartTone",
          _tp_cli_channel_interface_dtmf_collect_callback_start_tone,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
              G_TYPE_UCHAR, in_Event,
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
_tp_cli_channel_interface_dtmf_collect_callback_stop_tone (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_stop_tone (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_callback_for_stop_tone callback = (tp_cli_channel_interface_dtmf_callback_for_stop_tone) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_dtmf_call_stop_tone (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    tp_cli_channel_interface_dtmf_callback_for_stop_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StopTone",
          G_TYPE_UINT, in_Stream_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StopTone", iface,
          _tp_cli_channel_interface_dtmf_invoke_callback_stop_tone,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StopTone",
              _tp_cli_channel_interface_dtmf_collect_callback_stop_tone,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_dtmf_run_state_stop_tone;
static void
_tp_cli_channel_interface_dtmf_finish_running_stop_tone (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_dtmf_run_state_stop_tone *state = user_data;

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
tp_cli_channel_interface_dtmf_run_stop_tone (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_dtmf_run_state_stop_tone state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StopTone", iface,
      _tp_cli_channel_interface_dtmf_finish_running_stop_tone,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StopTone",
          _tp_cli_channel_interface_dtmf_collect_callback_stop_tone,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
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
_tp_cli_channel_interface_dtmf_collect_callback_multiple_tones (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_dtmf_invoke_callback_multiple_tones (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_dtmf_callback_for_multiple_tones callback = (tp_cli_channel_interface_dtmf_callback_for_multiple_tones) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_dtmf_call_multiple_tones (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Tones,
    tp_cli_channel_interface_dtmf_callback_for_multiple_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "MultipleTones",
          G_TYPE_STRING, in_Tones,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "MultipleTones", iface,
          _tp_cli_channel_interface_dtmf_invoke_callback_multiple_tones,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "MultipleTones",
              _tp_cli_channel_interface_dtmf_collect_callback_multiple_tones,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Tones,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_dtmf_run_state_multiple_tones;
static void
_tp_cli_channel_interface_dtmf_finish_running_multiple_tones (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_dtmf_run_state_multiple_tones *state = user_data;

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
tp_cli_channel_interface_dtmf_run_multiple_tones (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Tones,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_dtmf_run_state_multiple_tones state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "MultipleTones", iface,
      _tp_cli_channel_interface_dtmf_finish_running_multiple_tones,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "MultipleTones",
          _tp_cli_channel_interface_dtmf_collect_callback_multiple_tones,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Tones,
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
_tp_cli_channel_interface_destroyable_collect_callback_destroy (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_destroyable_invoke_callback_destroy (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_destroyable_callback_for_destroy callback = (tp_cli_channel_interface_destroyable_callback_for_destroy) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_destroyable_call_destroy (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_destroyable_callback_for_destroy callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DESTROYABLE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Destroy",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Destroy", iface,
          _tp_cli_channel_interface_destroyable_invoke_callback_destroy,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Destroy",
              _tp_cli_channel_interface_destroyable_collect_callback_destroy,
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
} _tp_cli_channel_interface_destroyable_run_state_destroy;
static void
_tp_cli_channel_interface_destroyable_finish_running_destroy (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_destroyable_run_state_destroy *state = user_data;

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
tp_cli_channel_interface_destroyable_run_destroy (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_DESTROYABLE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_destroyable_run_state_destroy state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Destroy", iface,
      _tp_cli_channel_interface_destroyable_finish_running_destroy,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Destroy",
          _tp_cli_channel_interface_destroyable_collect_callback_destroy,
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
tp_cli_add_signals_for_channel_interface_group (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "HandleOwnersChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "HandleOwnersChangedDetailed",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SelfHandleChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SelfContactChanged",
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "GroupFlagsChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MembersChanged",
      G_TYPE_STRING,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MembersChangedDetailed",
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_group_collect_args_of_handle_owners_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Added,
    const GArray *arg_Removed,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)));
  g_value_set_boxed (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_for_handle_owners_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_handle_owners_changed callback =
      (tp_cli_channel_interface_group_signal_callback_handle_owners_changed) generic_callback;

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
tp_cli_channel_interface_group_connect_to_handle_owners_changed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_handle_owners_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "HandleOwnersChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_handle_owners_changed),
      _tp_cli_channel_interface_group_invoke_callback_for_handle_owners_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_handle_owners_changed_detailed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Added,
    const GArray *arg_Removed,
    GHashTable *arg_Identifiers,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)));
  g_value_set_boxed (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Removed);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));
  g_value_set_boxed (args->values + 2, arg_Identifiers);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_for_handle_owners_changed_detailed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_handle_owners_changed_detailed callback =
      (tp_cli_channel_interface_group_signal_callback_handle_owners_changed_detailed) generic_callback;

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
tp_cli_channel_interface_group_connect_to_handle_owners_changed_detailed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_handle_owners_changed_detailed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "HandleOwnersChangedDetailed",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_handle_owners_changed_detailed),
      _tp_cli_channel_interface_group_invoke_callback_for_handle_owners_changed_detailed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_self_handle_changed (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_channel_interface_group_invoke_callback_for_self_handle_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_self_handle_changed callback =
      (tp_cli_channel_interface_group_signal_callback_self_handle_changed) generic_callback;

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
tp_cli_channel_interface_group_connect_to_self_handle_changed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_self_handle_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "SelfHandleChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_self_handle_changed),
      _tp_cli_channel_interface_group_invoke_callback_for_self_handle_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_self_contact_changed (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_channel_interface_group_invoke_callback_for_self_contact_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_self_contact_changed callback =
      (tp_cli_channel_interface_group_signal_callback_self_contact_changed) generic_callback;

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
tp_cli_channel_interface_group_connect_to_self_contact_changed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_self_contact_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "SelfContactChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_self_contact_changed),
      _tp_cli_channel_interface_group_invoke_callback_for_self_contact_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_group_flags_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Added,
    guint arg_Removed,
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
  g_value_set_uint (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_for_group_flags_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_group_flags_changed callback =
      (tp_cli_channel_interface_group_signal_callback_group_flags_changed) generic_callback;

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
tp_cli_channel_interface_group_connect_to_group_flags_changed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_group_flags_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "GroupFlagsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_group_flags_changed),
      _tp_cli_channel_interface_group_invoke_callback_for_group_flags_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_members_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Message,
    const GArray *arg_Added,
    const GArray *arg_Removed,
    const GArray *arg_Local_Pending,
    const GArray *arg_Remote_Pending,
    guint arg_Actor,
    guint arg_Reason,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (7);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 7; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_set_string (args->values + 0, arg_Message);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Added);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 2, arg_Removed);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 3, arg_Local_Pending);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 4, arg_Remote_Pending);

  g_value_unset (args->values + 5);
  g_value_init (args->values + 5, G_TYPE_UINT);
  g_value_set_uint (args->values + 5, arg_Actor);

  g_value_unset (args->values + 6);
  g_value_init (args->values + 6, G_TYPE_UINT);
  g_value_set_uint (args->values + 6, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_for_members_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_members_changed callback =
      (tp_cli_channel_interface_group_signal_callback_members_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      g_value_get_boxed (args->values + 3),
      g_value_get_boxed (args->values + 4),
      g_value_get_uint (args->values + 5),
      g_value_get_uint (args->values + 6),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_group_connect_to_members_changed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_members_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[8] = {
      G_TYPE_STRING,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "MembersChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_members_changed),
      _tp_cli_channel_interface_group_invoke_callback_for_members_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_args_of_members_changed_detailed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GArray *arg_Added,
    const GArray *arg_Removed,
    const GArray *arg_Local_Pending,
    const GArray *arg_Remote_Pending,
    GHashTable *arg_Details,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Removed);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 2, arg_Local_Pending);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 3, arg_Remote_Pending);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 4, arg_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_for_members_changed_detailed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_signal_callback_members_changed_detailed callback =
      (tp_cli_channel_interface_group_signal_callback_members_changed_detailed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      g_value_get_boxed (args->values + 3),
      g_value_get_boxed (args->values + 4),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_group_connect_to_members_changed_detailed (TpChannel *proxy,
    tp_cli_channel_interface_group_signal_callback_members_changed_detailed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[6] = {
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, "MembersChangedDetailed",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_group_collect_args_of_members_changed_detailed),
      _tp_cli_channel_interface_group_invoke_callback_for_members_changed_detailed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_group_collect_callback_add_members (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_group_invoke_callback_add_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_add_members callback = (tp_cli_channel_interface_group_callback_for_add_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_add_members (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    tp_cli_channel_interface_group_callback_for_add_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddMembers",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_add_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddMembers",
              _tp_cli_channel_interface_group_collect_callback_add_members,
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
} _tp_cli_channel_interface_group_run_state_add_members;
static void
_tp_cli_channel_interface_group_finish_running_add_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_add_members *state = user_data;

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
tp_cli_channel_interface_group_run_add_members (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_add_members state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AddMembers", iface,
      _tp_cli_channel_interface_group_finish_running_add_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AddMembers",
          _tp_cli_channel_interface_group_collect_callback_add_members,
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
_tp_cli_channel_interface_group_collect_callback_get_all_members (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Members;
  GArray *out_Local_Pending;
  GArray *out_Remote_Pending;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_UINT_ARRAY, &out_Members,
      DBUS_TYPE_G_UINT_ARRAY, &out_Local_Pending,
      DBUS_TYPE_G_UINT_ARRAY, &out_Remote_Pending,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_UINT_ARRAY);
  g_value_take_boxed (args->values + 0, out_Members);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_take_boxed (args->values + 1, out_Local_Pending);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, DBUS_TYPE_G_UINT_ARRAY);
  g_value_take_boxed (args->values + 2, out_Remote_Pending);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_get_all_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_all_members callback = (tp_cli_channel_interface_group_callback_for_get_all_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_boxed (args->values + 2),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_all_members (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_all_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetAllMembers",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAllMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_all_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAllMembers",
              _tp_cli_channel_interface_group_collect_callback_get_all_members,
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
    GArray **out_Members;
    GArray **out_Local_Pending;
    GArray **out_Remote_Pending;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_all_members;
static void
_tp_cli_channel_interface_group_finish_running_get_all_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_all_members *state = user_data;

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

  if (state->out_Members != NULL)
    *state->out_Members = g_value_dup_boxed (args->values + 0);

  if (state->out_Local_Pending != NULL)
    *state->out_Local_Pending = g_value_dup_boxed (args->values + 1);

  if (state->out_Remote_Pending != NULL)
    *state->out_Remote_Pending = g_value_dup_boxed (args->values + 2);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_group_run_get_all_members (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Members,
    GArray **out_Local_Pending,
    GArray **out_Remote_Pending,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_all_members state = {
      NULL /* loop */, error,
    out_Members,
    out_Local_Pending,
    out_Remote_Pending,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAllMembers", iface,
      _tp_cli_channel_interface_group_finish_running_get_all_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAllMembers",
          _tp_cli_channel_interface_group_collect_callback_get_all_members,
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
_tp_cli_channel_interface_group_collect_callback_get_group_flags (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Group_Flags;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Group_Flags,
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
  g_value_set_uint (args->values + 0, out_Group_Flags);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_get_group_flags (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_group_flags callback = (tp_cli_channel_interface_group_callback_for_get_group_flags) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_group_flags (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_group_flags callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetGroupFlags",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetGroupFlags", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_group_flags,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetGroupFlags",
              _tp_cli_channel_interface_group_collect_callback_get_group_flags,
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
    guint *out_Group_Flags;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_group_flags;
static void
_tp_cli_channel_interface_group_finish_running_get_group_flags (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_group_flags *state = user_data;

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

  if (state->out_Group_Flags != NULL)
    *state->out_Group_Flags = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_group_run_get_group_flags (TpChannel *proxy,
    gint timeout_ms,
    guint *out_Group_Flags,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_group_flags state = {
      NULL /* loop */, error,
    out_Group_Flags,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetGroupFlags", iface,
      _tp_cli_channel_interface_group_finish_running_get_group_flags,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetGroupFlags",
          _tp_cli_channel_interface_group_collect_callback_get_group_flags,
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
_tp_cli_channel_interface_group_collect_callback_get_handle_owners (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Owners;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_UINT_ARRAY, &out_Owners,
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
  g_value_take_boxed (args->values + 0, out_Owners);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_get_handle_owners (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_handle_owners callback = (tp_cli_channel_interface_group_callback_for_get_handle_owners) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_handle_owners (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    tp_cli_channel_interface_group_callback_for_get_handle_owners callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetHandleOwners",
          DBUS_TYPE_G_UINT_ARRAY, in_Handles,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetHandleOwners", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_handle_owners,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetHandleOwners",
              _tp_cli_channel_interface_group_collect_callback_get_handle_owners,
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
    GArray **out_Owners;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_handle_owners;
static void
_tp_cli_channel_interface_group_finish_running_get_handle_owners (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_handle_owners *state = user_data;

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

  if (state->out_Owners != NULL)
    *state->out_Owners = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_group_run_get_handle_owners (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Handles,
    GArray **out_Owners,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_handle_owners state = {
      NULL /* loop */, error,
    out_Owners,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetHandleOwners", iface,
      _tp_cli_channel_interface_group_finish_running_get_handle_owners,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetHandleOwners",
          _tp_cli_channel_interface_group_collect_callback_get_handle_owners,
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


static void
_tp_cli_channel_interface_group_collect_callback_get_local_pending_members (DBusGProxy *proxy,
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
_tp_cli_channel_interface_group_invoke_callback_get_local_pending_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_local_pending_members callback = (tp_cli_channel_interface_group_callback_for_get_local_pending_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_local_pending_members (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_local_pending_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetLocalPendingMembers",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetLocalPendingMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_local_pending_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetLocalPendingMembers",
              _tp_cli_channel_interface_group_collect_callback_get_local_pending_members,
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
    GArray **out_Handles;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_local_pending_members;
static void
_tp_cli_channel_interface_group_finish_running_get_local_pending_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_local_pending_members *state = user_data;

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
tp_cli_channel_interface_group_run_get_local_pending_members (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_local_pending_members state = {
      NULL /* loop */, error,
    out_Handles,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetLocalPendingMembers", iface,
      _tp_cli_channel_interface_group_finish_running_get_local_pending_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetLocalPendingMembers",
          _tp_cli_channel_interface_group_collect_callback_get_local_pending_members,
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
_tp_cli_channel_interface_group_collect_callback_get_local_pending_members_with_info (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Info;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Info,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Info);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_group_invoke_callback_get_local_pending_members_with_info (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_local_pending_members_with_info callback = (tp_cli_channel_interface_group_callback_for_get_local_pending_members_with_info) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_local_pending_members_with_info (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_local_pending_members_with_info callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetLocalPendingMembersWithInfo",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetLocalPendingMembersWithInfo", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_local_pending_members_with_info,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetLocalPendingMembersWithInfo",
              _tp_cli_channel_interface_group_collect_callback_get_local_pending_members_with_info,
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
    GPtrArray **out_Info;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_local_pending_members_with_info;
static void
_tp_cli_channel_interface_group_finish_running_get_local_pending_members_with_info (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_local_pending_members_with_info *state = user_data;

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

  if (state->out_Info != NULL)
    *state->out_Info = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_group_run_get_local_pending_members_with_info (TpChannel *proxy,
    gint timeout_ms,
    GPtrArray **out_Info,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_local_pending_members_with_info state = {
      NULL /* loop */, error,
    out_Info,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetLocalPendingMembersWithInfo", iface,
      _tp_cli_channel_interface_group_finish_running_get_local_pending_members_with_info,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetLocalPendingMembersWithInfo",
          _tp_cli_channel_interface_group_collect_callback_get_local_pending_members_with_info,
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
_tp_cli_channel_interface_group_collect_callback_get_members (DBusGProxy *proxy,
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
_tp_cli_channel_interface_group_invoke_callback_get_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_members callback = (tp_cli_channel_interface_group_callback_for_get_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_members (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetMembers",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetMembers",
              _tp_cli_channel_interface_group_collect_callback_get_members,
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
    GArray **out_Handles;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_members;
static void
_tp_cli_channel_interface_group_finish_running_get_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_members *state = user_data;

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
tp_cli_channel_interface_group_run_get_members (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_members state = {
      NULL /* loop */, error,
    out_Handles,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetMembers", iface,
      _tp_cli_channel_interface_group_finish_running_get_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetMembers",
          _tp_cli_channel_interface_group_collect_callback_get_members,
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
_tp_cli_channel_interface_group_collect_callback_get_remote_pending_members (DBusGProxy *proxy,
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
_tp_cli_channel_interface_group_invoke_callback_get_remote_pending_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_remote_pending_members callback = (tp_cli_channel_interface_group_callback_for_get_remote_pending_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_remote_pending_members (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_remote_pending_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetRemotePendingMembers",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetRemotePendingMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_get_remote_pending_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetRemotePendingMembers",
              _tp_cli_channel_interface_group_collect_callback_get_remote_pending_members,
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
    GArray **out_Handles;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_get_remote_pending_members;
static void
_tp_cli_channel_interface_group_finish_running_get_remote_pending_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_remote_pending_members *state = user_data;

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
tp_cli_channel_interface_group_run_get_remote_pending_members (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Handles,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_remote_pending_members state = {
      NULL /* loop */, error,
    out_Handles,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetRemotePendingMembers", iface,
      _tp_cli_channel_interface_group_finish_running_get_remote_pending_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetRemotePendingMembers",
          _tp_cli_channel_interface_group_collect_callback_get_remote_pending_members,
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
_tp_cli_channel_interface_group_collect_callback_get_self_handle (DBusGProxy *proxy,
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
_tp_cli_channel_interface_group_invoke_callback_get_self_handle (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_get_self_handle callback = (tp_cli_channel_interface_group_callback_for_get_self_handle) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_get_self_handle (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_group_callback_for_get_self_handle callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
          _tp_cli_channel_interface_group_invoke_callback_get_self_handle,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetSelfHandle",
              _tp_cli_channel_interface_group_collect_callback_get_self_handle,
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
} _tp_cli_channel_interface_group_run_state_get_self_handle;
static void
_tp_cli_channel_interface_group_finish_running_get_self_handle (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_get_self_handle *state = user_data;

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
tp_cli_channel_interface_group_run_get_self_handle (TpChannel *proxy,
    gint timeout_ms,
    guint *out_Self_Handle,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_get_self_handle state = {
      NULL /* loop */, error,
    out_Self_Handle,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetSelfHandle", iface,
      _tp_cli_channel_interface_group_finish_running_get_self_handle,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetSelfHandle",
          _tp_cli_channel_interface_group_collect_callback_get_self_handle,
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
_tp_cli_channel_interface_group_collect_callback_remove_members (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_group_invoke_callback_remove_members (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_remove_members callback = (tp_cli_channel_interface_group_callback_for_remove_members) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_remove_members (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    tp_cli_channel_interface_group_callback_for_remove_members callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveMembers",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveMembers", iface,
          _tp_cli_channel_interface_group_invoke_callback_remove_members,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveMembers",
              _tp_cli_channel_interface_group_collect_callback_remove_members,
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
} _tp_cli_channel_interface_group_run_state_remove_members;
static void
_tp_cli_channel_interface_group_finish_running_remove_members (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_remove_members *state = user_data;

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
tp_cli_channel_interface_group_run_remove_members (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_remove_members state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveMembers", iface,
      _tp_cli_channel_interface_group_finish_running_remove_members,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveMembers",
          _tp_cli_channel_interface_group_collect_callback_remove_members,
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
_tp_cli_channel_interface_group_collect_callback_remove_members_with_reason (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_group_invoke_callback_remove_members_with_reason (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_group_callback_for_remove_members_with_reason callback = (tp_cli_channel_interface_group_callback_for_remove_members_with_reason) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_group_call_remove_members_with_reason (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    guint in_Reason,
    tp_cli_channel_interface_group_callback_for_remove_members_with_reason callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveMembersWithReason",
          DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
          G_TYPE_STRING, in_Message,
          G_TYPE_UINT, in_Reason,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveMembersWithReason", iface,
          _tp_cli_channel_interface_group_invoke_callback_remove_members_with_reason,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveMembersWithReason",
              _tp_cli_channel_interface_group_collect_callback_remove_members_with_reason,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_STRING, in_Message,
              G_TYPE_UINT, in_Reason,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_group_run_state_remove_members_with_reason;
static void
_tp_cli_channel_interface_group_finish_running_remove_members_with_reason (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_group_run_state_remove_members_with_reason *state = user_data;

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
tp_cli_channel_interface_group_run_remove_members_with_reason (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Contacts,
    const gchar *in_Message,
    guint in_Reason,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_group_run_state_remove_members_with_reason state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveMembersWithReason", iface,
      _tp_cli_channel_interface_group_finish_running_remove_members_with_reason,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveMembersWithReason",
          _tp_cli_channel_interface_group_collect_callback_remove_members_with_reason,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Contacts,
              G_TYPE_STRING, in_Message,
              G_TYPE_UINT, in_Reason,
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
tp_cli_add_signals_for_channel_interface_hold (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "HoldStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_hold_collect_args_of_hold_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_HoldState,
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
  g_value_set_uint (args->values + 0, arg_HoldState);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_hold_invoke_callback_for_hold_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_hold_signal_callback_hold_state_changed callback =
      (tp_cli_channel_interface_hold_signal_callback_hold_state_changed) generic_callback;

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
tp_cli_channel_interface_hold_connect_to_hold_state_changed (TpChannel *proxy,
    tp_cli_channel_interface_hold_signal_callback_hold_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD, "HoldStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_hold_collect_args_of_hold_state_changed),
      _tp_cli_channel_interface_hold_invoke_callback_for_hold_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_hold_collect_callback_get_hold_state (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_HoldState;
  guint out_Reason;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_HoldState,
      G_TYPE_UINT, &out_Reason,
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
  g_value_set_uint (args->values + 0, out_HoldState);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, out_Reason);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_hold_invoke_callback_get_hold_state (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_hold_callback_for_get_hold_state callback = (tp_cli_channel_interface_hold_callback_for_get_hold_state) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_hold_call_get_hold_state (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_hold_callback_for_get_hold_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetHoldState",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetHoldState", iface,
          _tp_cli_channel_interface_hold_invoke_callback_get_hold_state,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetHoldState",
              _tp_cli_channel_interface_hold_collect_callback_get_hold_state,
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
    guint *out_HoldState;
    guint *out_Reason;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_hold_run_state_get_hold_state;
static void
_tp_cli_channel_interface_hold_finish_running_get_hold_state (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_hold_run_state_get_hold_state *state = user_data;

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

  if (state->out_HoldState != NULL)
    *state->out_HoldState = g_value_get_uint (args->values + 0);

  if (state->out_Reason != NULL)
    *state->out_Reason = g_value_get_uint (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_hold_run_get_hold_state (TpChannel *proxy,
    gint timeout_ms,
    guint *out_HoldState,
    guint *out_Reason,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_hold_run_state_get_hold_state state = {
      NULL /* loop */, error,
    out_HoldState,
    out_Reason,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetHoldState", iface,
      _tp_cli_channel_interface_hold_finish_running_get_hold_state,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetHoldState",
          _tp_cli_channel_interface_hold_collect_callback_get_hold_state,
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
_tp_cli_channel_interface_hold_collect_callback_request_hold (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_hold_invoke_callback_request_hold (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_hold_callback_for_request_hold callback = (tp_cli_channel_interface_hold_callback_for_request_hold) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_hold_call_request_hold (TpChannel *proxy,
    gint timeout_ms,
    gboolean in_Hold,
    tp_cli_channel_interface_hold_callback_for_request_hold callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestHold",
          G_TYPE_BOOLEAN, in_Hold,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestHold", iface,
          _tp_cli_channel_interface_hold_invoke_callback_request_hold,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestHold",
              _tp_cli_channel_interface_hold_collect_callback_request_hold,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Hold,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_hold_run_state_request_hold;
static void
_tp_cli_channel_interface_hold_finish_running_request_hold (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_hold_run_state_request_hold *state = user_data;

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
tp_cli_channel_interface_hold_run_request_hold (TpChannel *proxy,
    gint timeout_ms,
    gboolean in_Hold,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_hold_run_state_request_hold state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestHold", iface,
      _tp_cli_channel_interface_hold_finish_running_request_hold,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestHold",
          _tp_cli_channel_interface_hold_collect_callback_request_hold,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
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


static inline void
tp_cli_add_signals_for_channel_interface_media_signalling (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewSessionHandler",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_media_signalling_collect_args_of_new_session_handler (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Session_Handler,
    const gchar *arg_Session_Type,
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
  g_value_set_boxed (args->values + 0, arg_Session_Handler);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Session_Type);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_media_signalling_invoke_callback_for_new_session_handler (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_media_signalling_signal_callback_new_session_handler callback =
      (tp_cli_channel_interface_media_signalling_signal_callback_new_session_handler) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_string (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_media_signalling_connect_to_new_session_handler (TpChannel *proxy,
    tp_cli_channel_interface_media_signalling_signal_callback_new_session_handler callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_MEDIA_SIGNALLING, "NewSessionHandler",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_media_signalling_collect_args_of_new_session_handler),
      _tp_cli_channel_interface_media_signalling_invoke_callback_for_new_session_handler,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_media_signalling_collect_callback_get_session_handlers (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Session_Handlers;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Session_Handlers,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Session_Handlers);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_media_signalling_invoke_callback_get_session_handlers (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_media_signalling_callback_for_get_session_handlers callback = (tp_cli_channel_interface_media_signalling_callback_for_get_session_handlers) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_media_signalling_call_get_session_handlers (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_media_signalling_callback_for_get_session_handlers callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MEDIA_SIGNALLING;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetSessionHandlers",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetSessionHandlers", iface,
          _tp_cli_channel_interface_media_signalling_invoke_callback_get_session_handlers,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetSessionHandlers",
              _tp_cli_channel_interface_media_signalling_collect_callback_get_session_handlers,
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
    GPtrArray **out_Session_Handlers;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_media_signalling_run_state_get_session_handlers;
static void
_tp_cli_channel_interface_media_signalling_finish_running_get_session_handlers (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_media_signalling_run_state_get_session_handlers *state = user_data;

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

  if (state->out_Session_Handlers != NULL)
    *state->out_Session_Handlers = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_media_signalling_run_get_session_handlers (TpChannel *proxy,
    gint timeout_ms,
    GPtrArray **out_Session_Handlers,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MEDIA_SIGNALLING;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_media_signalling_run_state_get_session_handlers state = {
      NULL /* loop */, error,
    out_Session_Handlers,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetSessionHandlers", iface,
      _tp_cli_channel_interface_media_signalling_finish_running_get_session_handlers,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetSessionHandlers",
          _tp_cli_channel_interface_media_signalling_collect_callback_get_session_handlers,
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
tp_cli_add_signals_for_channel_interface_messages (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "MessageSent",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "PendingMessagesRemoved",
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MessageReceived",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_messages_collect_args_of_message_sent (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Content,
    guint arg_Flags,
    const gchar *arg_Message_Token,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_set_boxed (args->values + 0, arg_Content);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Flags);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Message_Token);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_messages_invoke_callback_for_message_sent (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_messages_signal_callback_message_sent callback =
      (tp_cli_channel_interface_messages_signal_callback_message_sent) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_messages_connect_to_message_sent (TpChannel *proxy,
    tp_cli_channel_interface_messages_signal_callback_message_sent callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES, "MessageSent",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_messages_collect_args_of_message_sent),
      _tp_cli_channel_interface_messages_invoke_callback_for_message_sent,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_messages_collect_args_of_pending_messages_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GArray *arg_Message_IDs,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 0, arg_Message_IDs);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_messages_invoke_callback_for_pending_messages_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_messages_signal_callback_pending_messages_removed callback =
      (tp_cli_channel_interface_messages_signal_callback_pending_messages_removed) generic_callback;

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
tp_cli_channel_interface_messages_connect_to_pending_messages_removed (TpChannel *proxy,
    tp_cli_channel_interface_messages_signal_callback_pending_messages_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES, "PendingMessagesRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_messages_collect_args_of_pending_messages_removed),
      _tp_cli_channel_interface_messages_invoke_callback_for_pending_messages_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_messages_collect_args_of_message_received (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Message,
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
  g_value_set_boxed (args->values + 0, arg_Message);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_messages_invoke_callback_for_message_received (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_messages_signal_callback_message_received callback =
      (tp_cli_channel_interface_messages_signal_callback_message_received) generic_callback;

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
tp_cli_channel_interface_messages_connect_to_message_received (TpChannel *proxy,
    tp_cli_channel_interface_messages_signal_callback_message_received callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES, "MessageReceived",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_messages_collect_args_of_message_received),
      _tp_cli_channel_interface_messages_invoke_callback_for_message_received,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_messages_collect_callback_send_message (DBusGProxy *proxy,
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
_tp_cli_channel_interface_messages_invoke_callback_send_message (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_messages_callback_for_send_message callback = (tp_cli_channel_interface_messages_callback_for_send_message) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_messages_call_send_message (TpChannel *proxy,
    gint timeout_ms,
    const GPtrArray *in_Message,
    guint in_Flags,
    tp_cli_channel_interface_messages_callback_for_send_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SendMessage",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
          G_TYPE_UINT, in_Flags,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SendMessage", iface,
          _tp_cli_channel_interface_messages_invoke_callback_send_message,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SendMessage",
              _tp_cli_channel_interface_messages_collect_callback_send_message,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
              G_TYPE_UINT, in_Flags,
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
} _tp_cli_channel_interface_messages_run_state_send_message;
static void
_tp_cli_channel_interface_messages_finish_running_send_message (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_messages_run_state_send_message *state = user_data;

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
tp_cli_channel_interface_messages_run_send_message (TpChannel *proxy,
    gint timeout_ms,
    const GPtrArray *in_Message,
    guint in_Flags,
    gchar **out_Token,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_messages_run_state_send_message state = {
      NULL /* loop */, error,
    out_Token,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SendMessage", iface,
      _tp_cli_channel_interface_messages_finish_running_send_message,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SendMessage",
          _tp_cli_channel_interface_messages_collect_callback_send_message,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
              G_TYPE_UINT, in_Flags,
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
_tp_cli_channel_interface_messages_collect_callback_get_pending_message_content (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Content;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_VALUE)), &out_Content,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_VALUE)));
  g_value_take_boxed (args->values + 0, out_Content);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_messages_invoke_callback_get_pending_message_content (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_messages_callback_for_get_pending_message_content callback = (tp_cli_channel_interface_messages_callback_for_get_pending_message_content) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_messages_call_get_pending_message_content (TpChannel *proxy,
    gint timeout_ms,
    guint in_Message_ID,
    const GArray *in_Parts,
    tp_cli_channel_interface_messages_callback_for_get_pending_message_content callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetPendingMessageContent",
          G_TYPE_UINT, in_Message_ID,
          DBUS_TYPE_G_UINT_ARRAY, in_Parts,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetPendingMessageContent", iface,
          _tp_cli_channel_interface_messages_invoke_callback_get_pending_message_content,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetPendingMessageContent",
              _tp_cli_channel_interface_messages_collect_callback_get_pending_message_content,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Message_ID,
              DBUS_TYPE_G_UINT_ARRAY, in_Parts,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GHashTable **out_Content;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_messages_run_state_get_pending_message_content;
static void
_tp_cli_channel_interface_messages_finish_running_get_pending_message_content (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_messages_run_state_get_pending_message_content *state = user_data;

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

  if (state->out_Content != NULL)
    *state->out_Content = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_messages_run_get_pending_message_content (TpChannel *proxy,
    gint timeout_ms,
    guint in_Message_ID,
    const GArray *in_Parts,
    GHashTable **out_Content,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_messages_run_state_get_pending_message_content state = {
      NULL /* loop */, error,
    out_Content,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetPendingMessageContent", iface,
      _tp_cli_channel_interface_messages_finish_running_get_pending_message_content,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetPendingMessageContent",
          _tp_cli_channel_interface_messages_collect_callback_get_pending_message_content,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Message_ID,
              DBUS_TYPE_G_UINT_ARRAY, in_Parts,
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
tp_cli_add_signals_for_channel_interface_password (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "PasswordFlagsChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_password_collect_args_of_password_flags_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Added,
    guint arg_Removed,
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
  g_value_set_uint (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_password_invoke_callback_for_password_flags_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_password_signal_callback_password_flags_changed callback =
      (tp_cli_channel_interface_password_signal_callback_password_flags_changed) generic_callback;

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
tp_cli_channel_interface_password_connect_to_password_flags_changed (TpChannel *proxy,
    tp_cli_channel_interface_password_signal_callback_password_flags_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD, "PasswordFlagsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_password_collect_args_of_password_flags_changed),
      _tp_cli_channel_interface_password_invoke_callback_for_password_flags_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_password_collect_callback_get_password_flags (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Password_Flags;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Password_Flags,
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
  g_value_set_uint (args->values + 0, out_Password_Flags);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_password_invoke_callback_get_password_flags (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_password_callback_for_get_password_flags callback = (tp_cli_channel_interface_password_callback_for_get_password_flags) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_password_call_get_password_flags (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_password_callback_for_get_password_flags callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetPasswordFlags",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetPasswordFlags", iface,
          _tp_cli_channel_interface_password_invoke_callback_get_password_flags,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetPasswordFlags",
              _tp_cli_channel_interface_password_collect_callback_get_password_flags,
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
    guint *out_Password_Flags;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_password_run_state_get_password_flags;
static void
_tp_cli_channel_interface_password_finish_running_get_password_flags (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_password_run_state_get_password_flags *state = user_data;

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

  if (state->out_Password_Flags != NULL)
    *state->out_Password_Flags = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_password_run_get_password_flags (TpChannel *proxy,
    gint timeout_ms,
    guint *out_Password_Flags,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_password_run_state_get_password_flags state = {
      NULL /* loop */, error,
    out_Password_Flags,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetPasswordFlags", iface,
      _tp_cli_channel_interface_password_finish_running_get_password_flags,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetPasswordFlags",
          _tp_cli_channel_interface_password_collect_callback_get_password_flags,
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
_tp_cli_channel_interface_password_collect_callback_provide_password (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gboolean out_Correct;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_BOOLEAN, &out_Correct,
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
  g_value_set_boolean (args->values + 0, out_Correct);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_password_invoke_callback_provide_password (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_password_callback_for_provide_password callback = (tp_cli_channel_interface_password_callback_for_provide_password) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boolean (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_password_call_provide_password (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Password,
    tp_cli_channel_interface_password_callback_for_provide_password callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ProvidePassword",
          G_TYPE_STRING, in_Password,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ProvidePassword", iface,
          _tp_cli_channel_interface_password_invoke_callback_provide_password,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ProvidePassword",
              _tp_cli_channel_interface_password_collect_callback_provide_password,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Password,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gboolean *out_Correct;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_password_run_state_provide_password;
static void
_tp_cli_channel_interface_password_finish_running_provide_password (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_password_run_state_provide_password *state = user_data;

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

  if (state->out_Correct != NULL)
    *state->out_Correct = g_value_get_boolean (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_password_run_provide_password (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Password,
    gboolean *out_Correct,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_password_run_state_provide_password state = {
      NULL /* loop */, error,
    out_Correct,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ProvidePassword", iface,
      _tp_cli_channel_interface_password_finish_running_provide_password,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ProvidePassword",
          _tp_cli_channel_interface_password_collect_callback_provide_password,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Password,
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
_tp_cli_channel_interface_room_config_collect_callback_update_configuration (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_room_config_invoke_callback_update_configuration (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_room_config_callback_for_update_configuration callback = (tp_cli_channel_interface_room_config_callback_for_update_configuration) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_room_config_call_update_configuration (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_Properties,
    tp_cli_channel_interface_room_config_callback_for_update_configuration callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_ROOM_CONFIG;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UpdateConfiguration",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UpdateConfiguration", iface,
          _tp_cli_channel_interface_room_config_invoke_callback_update_configuration,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UpdateConfiguration",
              _tp_cli_channel_interface_room_config_collect_callback_update_configuration,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_channel_interface_sasl_authentication (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "SASLStatusChanged",
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "NewChallenge",
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_sasl_authentication_collect_args_of_sasl_status_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Status,
    const gchar *arg_Reason,
    GHashTable *arg_Details,
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
  g_value_set_uint (args->values + 0, arg_Status);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Reason);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 2, arg_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_for_sasl_status_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_signal_callback_sasl_status_changed callback =
      (tp_cli_channel_interface_sasl_authentication_signal_callback_sasl_status_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_interface_sasl_authentication_connect_to_sasl_status_changed (TpChannel *proxy,
    tp_cli_channel_interface_sasl_authentication_signal_callback_sasl_status_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION, "SASLStatusChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_sasl_authentication_collect_args_of_sasl_status_changed),
      _tp_cli_channel_interface_sasl_authentication_invoke_callback_for_sasl_status_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_sasl_authentication_collect_args_of_new_challenge (DBusGProxy *proxy G_GNUC_UNUSED,
    const GArray *arg_Challenge_Data,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR));
  g_value_set_boxed (args->values + 0, arg_Challenge_Data);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_for_new_challenge (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_signal_callback_new_challenge callback =
      (tp_cli_channel_interface_sasl_authentication_signal_callback_new_challenge) generic_callback;

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
tp_cli_channel_interface_sasl_authentication_connect_to_new_challenge (TpChannel *proxy,
    tp_cli_channel_interface_sasl_authentication_signal_callback_new_challenge callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION, "NewChallenge",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_sasl_authentication_collect_args_of_new_challenge),
      _tp_cli_channel_interface_sasl_authentication_invoke_callback_for_new_challenge,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_start_mechanism (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism callback = (tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sasl_authentication_call_start_mechanism (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Mechanism,
    tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StartMechanism",
          G_TYPE_STRING, in_Mechanism,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StartMechanism", iface,
          _tp_cli_channel_interface_sasl_authentication_invoke_callback_start_mechanism,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StartMechanism",
              _tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Mechanism,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism;
static void
_tp_cli_channel_interface_sasl_authentication_finish_running_start_mechanism (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism *state = user_data;

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
tp_cli_channel_interface_sasl_authentication_run_start_mechanism (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Mechanism,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StartMechanism", iface,
      _tp_cli_channel_interface_sasl_authentication_finish_running_start_mechanism,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StartMechanism",
          _tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Mechanism,
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
_tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism_with_data (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_start_mechanism_with_data (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism_with_data callback = (tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism_with_data) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sasl_authentication_call_start_mechanism_with_data (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Mechanism,
    const GArray *in_Initial_Data,
    tp_cli_channel_interface_sasl_authentication_callback_for_start_mechanism_with_data callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StartMechanismWithData",
          G_TYPE_STRING, in_Mechanism,
          dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Initial_Data,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StartMechanismWithData", iface,
          _tp_cli_channel_interface_sasl_authentication_invoke_callback_start_mechanism_with_data,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StartMechanismWithData",
              _tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism_with_data,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Mechanism,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Initial_Data,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism_with_data;
static void
_tp_cli_channel_interface_sasl_authentication_finish_running_start_mechanism_with_data (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism_with_data *state = user_data;

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
tp_cli_channel_interface_sasl_authentication_run_start_mechanism_with_data (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Mechanism,
    const GArray *in_Initial_Data,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sasl_authentication_run_state_start_mechanism_with_data state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StartMechanismWithData", iface,
      _tp_cli_channel_interface_sasl_authentication_finish_running_start_mechanism_with_data,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StartMechanismWithData",
          _tp_cli_channel_interface_sasl_authentication_collect_callback_start_mechanism_with_data,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Mechanism,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Initial_Data,
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
_tp_cli_channel_interface_sasl_authentication_collect_callback_respond (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_respond (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_callback_for_respond callback = (tp_cli_channel_interface_sasl_authentication_callback_for_respond) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sasl_authentication_call_respond (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Response_Data,
    tp_cli_channel_interface_sasl_authentication_callback_for_respond callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Respond",
          dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Response_Data,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Respond", iface,
          _tp_cli_channel_interface_sasl_authentication_invoke_callback_respond,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Respond",
              _tp_cli_channel_interface_sasl_authentication_collect_callback_respond,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Response_Data,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_sasl_authentication_run_state_respond;
static void
_tp_cli_channel_interface_sasl_authentication_finish_running_respond (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sasl_authentication_run_state_respond *state = user_data;

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
tp_cli_channel_interface_sasl_authentication_run_respond (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Response_Data,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sasl_authentication_run_state_respond state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Respond", iface,
      _tp_cli_channel_interface_sasl_authentication_finish_running_respond,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Respond",
          _tp_cli_channel_interface_sasl_authentication_collect_callback_respond,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), in_Response_Data,
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
_tp_cli_channel_interface_sasl_authentication_collect_callback_accept_sasl (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_accept_sasl (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_callback_for_accept_sasl callback = (tp_cli_channel_interface_sasl_authentication_callback_for_accept_sasl) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sasl_authentication_call_accept_sasl (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_interface_sasl_authentication_callback_for_accept_sasl callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcceptSASL",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcceptSASL", iface,
          _tp_cli_channel_interface_sasl_authentication_invoke_callback_accept_sasl,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcceptSASL",
              _tp_cli_channel_interface_sasl_authentication_collect_callback_accept_sasl,
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
} _tp_cli_channel_interface_sasl_authentication_run_state_accept_sasl;
static void
_tp_cli_channel_interface_sasl_authentication_finish_running_accept_sasl (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sasl_authentication_run_state_accept_sasl *state = user_data;

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
tp_cli_channel_interface_sasl_authentication_run_accept_sasl (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sasl_authentication_run_state_accept_sasl state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AcceptSASL", iface,
      _tp_cli_channel_interface_sasl_authentication_finish_running_accept_sasl,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AcceptSASL",
          _tp_cli_channel_interface_sasl_authentication_collect_callback_accept_sasl,
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
_tp_cli_channel_interface_sasl_authentication_collect_callback_abort_sasl (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_sasl_authentication_invoke_callback_abort_sasl (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sasl_authentication_callback_for_abort_sasl callback = (tp_cli_channel_interface_sasl_authentication_callback_for_abort_sasl) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sasl_authentication_call_abort_sasl (TpChannel *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Debug_Message,
    tp_cli_channel_interface_sasl_authentication_callback_for_abort_sasl callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AbortSASL",
          G_TYPE_UINT, in_Reason,
          G_TYPE_STRING, in_Debug_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AbortSASL", iface,
          _tp_cli_channel_interface_sasl_authentication_invoke_callback_abort_sasl,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AbortSASL",
              _tp_cli_channel_interface_sasl_authentication_collect_callback_abort_sasl,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Debug_Message,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_sasl_authentication_run_state_abort_sasl;
static void
_tp_cli_channel_interface_sasl_authentication_finish_running_abort_sasl (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sasl_authentication_run_state_abort_sasl *state = user_data;

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
tp_cli_channel_interface_sasl_authentication_run_abort_sasl (TpChannel *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Debug_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sasl_authentication_run_state_abort_sasl state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AbortSASL", iface,
      _tp_cli_channel_interface_sasl_authentication_finish_running_abort_sasl,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AbortSASL",
          _tp_cli_channel_interface_sasl_authentication_collect_callback_abort_sasl,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Debug_Message,
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
tp_cli_add_signals_for_channel_interface_sms (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "SMSChannelChanged",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_sms_collect_args_of_sms_channel_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_SMSChannel,
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
  g_value_set_boolean (args->values + 0, arg_SMSChannel);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_sms_invoke_callback_for_sms_channel_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sms_signal_callback_sms_channel_changed callback =
      (tp_cli_channel_interface_sms_signal_callback_sms_channel_changed) generic_callback;

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
tp_cli_channel_interface_sms_connect_to_sms_channel_changed (TpChannel *proxy,
    tp_cli_channel_interface_sms_signal_callback_sms_channel_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_SMS, "SMSChannelChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_sms_collect_args_of_sms_channel_changed),
      _tp_cli_channel_interface_sms_invoke_callback_for_sms_channel_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_sms_collect_callback_get_sms_length (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Chunks_Required;
  gint out_Remaining_Characters;
  gint out_Estimated_Cost;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Chunks_Required,
      G_TYPE_INT, &out_Remaining_Characters,
      G_TYPE_INT, &out_Estimated_Cost,
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
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, out_Chunks_Required);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_INT);
  g_value_set_int (args->values + 1, out_Remaining_Characters);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_INT);
  g_value_set_int (args->values + 2, out_Estimated_Cost);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_interface_sms_invoke_callback_get_sms_length (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_sms_callback_for_get_sms_length callback = (tp_cli_channel_interface_sms_callback_for_get_sms_length) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          0,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      g_value_get_int (args->values + 1),
      g_value_get_int (args->values + 2),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_sms_call_get_sms_length (TpChannel *proxy,
    gint timeout_ms,
    const GPtrArray *in_Message,
    tp_cli_channel_interface_sms_callback_for_get_sms_length callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SMS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
            0,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetSMSLength",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetSMSLength", iface,
          _tp_cli_channel_interface_sms_invoke_callback_get_sms_length,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetSMSLength",
              _tp_cli_channel_interface_sms_collect_callback_get_sms_length,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Chunks_Required;
    gint *out_Remaining_Characters;
    gint *out_Estimated_Cost;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_interface_sms_run_state_get_sms_length;
static void
_tp_cli_channel_interface_sms_finish_running_get_sms_length (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_interface_sms_run_state_get_sms_length *state = user_data;

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

  if (state->out_Chunks_Required != NULL)
    *state->out_Chunks_Required = g_value_get_uint (args->values + 0);

  if (state->out_Remaining_Characters != NULL)
    *state->out_Remaining_Characters = g_value_get_int (args->values + 1);

  if (state->out_Estimated_Cost != NULL)
    *state->out_Estimated_Cost = g_value_get_int (args->values + 2);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_interface_sms_run_get_sms_length (TpChannel *proxy,
    gint timeout_ms,
    const GPtrArray *in_Message,
    guint *out_Chunks_Required,
    gint *out_Remaining_Characters,
    gint *out_Estimated_Cost,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SMS;
  TpProxyPendingCall *pc;
  _tp_cli_channel_interface_sms_run_state_get_sms_length state = {
      NULL /* loop */, error,
    out_Chunks_Required,
    out_Remaining_Characters,
    out_Estimated_Cost,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetSMSLength", iface,
      _tp_cli_channel_interface_sms_finish_running_get_sms_length,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetSMSLength",
          _tp_cli_channel_interface_sms_collect_callback_get_sms_length,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
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
tp_cli_add_signals_for_channel_interface_service_point (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ServicePointChanged",
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_service_point_collect_args_of_service_point_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GValueArray *arg_Service_Point,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 0, arg_Service_Point);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_interface_service_point_invoke_callback_for_service_point_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_service_point_signal_callback_service_point_changed callback =
      (tp_cli_channel_interface_service_point_signal_callback_service_point_changed) generic_callback;

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
tp_cli_channel_interface_service_point_connect_to_service_point_changed (TpChannel *proxy,
    tp_cli_channel_interface_service_point_signal_callback_service_point_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_SERVICE_POINT, "ServicePointChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_service_point_collect_args_of_service_point_changed),
      _tp_cli_channel_interface_service_point_invoke_callback_for_service_point_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_interface_subject_collect_callback_set_subject (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_interface_subject_invoke_callback_set_subject (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_subject_callback_for_set_subject callback = (tp_cli_channel_interface_subject_callback_for_set_subject) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_interface_subject_call_set_subject (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Subject,
    tp_cli_channel_interface_subject_callback_for_set_subject callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_INTERFACE_SUBJECT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetSubject",
          G_TYPE_STRING, in_Subject,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetSubject", iface,
          _tp_cli_channel_interface_subject_invoke_callback_set_subject,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetSubject",
              _tp_cli_channel_interface_subject_collect_callback_set_subject,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Subject,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_channel_interface_tube (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "TubeChannelStateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_interface_tube_collect_args_of_tube_channel_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_channel_interface_tube_invoke_callback_for_tube_channel_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_interface_tube_signal_callback_tube_channel_state_changed callback =
      (tp_cli_channel_interface_tube_signal_callback_tube_channel_state_changed) generic_callback;

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
tp_cli_channel_interface_tube_connect_to_tube_channel_state_changed (TpChannel *proxy,
    tp_cli_channel_interface_tube_signal_callback_tube_channel_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_TUBE, "TubeChannelStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_interface_tube_collect_args_of_tube_channel_state_changed),
      _tp_cli_channel_interface_tube_invoke_callback_for_tube_channel_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static inline void
tp_cli_add_signals_for_channel_type_call (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ContentAdded",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ContentRemoved",
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "CallStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "CallMembersChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_call_collect_args_of_content_added (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Content,
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
  g_value_set_boxed (args->values + 0, arg_Content);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_call_invoke_callback_for_content_added (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_signal_callback_content_added callback =
      (tp_cli_channel_type_call_signal_callback_content_added) generic_callback;

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
tp_cli_channel_type_call_connect_to_content_added (TpChannel *proxy,
    tp_cli_channel_type_call_signal_callback_content_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CALL, "ContentAdded",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_call_collect_args_of_content_added),
      _tp_cli_channel_type_call_invoke_callback_for_content_added,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_call_collect_args_of_content_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Content,
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
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Content);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_call_invoke_callback_for_content_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_signal_callback_content_removed callback =
      (tp_cli_channel_type_call_signal_callback_content_removed) generic_callback;

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
tp_cli_channel_type_call_connect_to_content_removed (TpChannel *proxy,
    tp_cli_channel_type_call_signal_callback_content_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CALL, "ContentRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_call_collect_args_of_content_removed),
      _tp_cli_channel_type_call_invoke_callback_for_content_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_call_collect_args_of_call_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Call_State,
    guint arg_Call_Flags,
    const GValueArray *arg_Call_State_Reason,
    GHashTable *arg_Call_State_Details,
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
  g_value_set_uint (args->values + 0, arg_Call_State);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Call_Flags);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 2, arg_Call_State_Reason);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 3, arg_Call_State_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_call_invoke_callback_for_call_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_signal_callback_call_state_changed callback =
      (tp_cli_channel_type_call_signal_callback_call_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
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
tp_cli_channel_type_call_connect_to_call_state_changed (TpChannel *proxy,
    tp_cli_channel_type_call_signal_callback_call_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CALL, "CallStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_call_collect_args_of_call_state_changed),
      _tp_cli_channel_type_call_invoke_callback_for_call_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_call_collect_args_of_call_members_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Flags_Changed,
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
  g_value_set_boxed (args->values + 0, arg_Flags_Changed);

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
_tp_cli_channel_type_call_invoke_callback_for_call_members_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_signal_callback_call_members_changed callback =
      (tp_cli_channel_type_call_signal_callback_call_members_changed) generic_callback;

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
tp_cli_channel_type_call_connect_to_call_members_changed (TpChannel *proxy,
    tp_cli_channel_type_call_signal_callback_call_members_changed callback,
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

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CALL, "CallMembersChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_call_collect_args_of_call_members_changed),
      _tp_cli_channel_type_call_invoke_callback_for_call_members_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_call_collect_callback_set_ringing (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_call_invoke_callback_set_ringing (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_callback_for_set_ringing callback = (tp_cli_channel_type_call_callback_for_set_ringing) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_call_call_set_ringing (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_call_callback_for_set_ringing callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CALL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetRinging",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetRinging", iface,
          _tp_cli_channel_type_call_invoke_callback_set_ringing,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetRinging",
              _tp_cli_channel_type_call_collect_callback_set_ringing,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_type_call_collect_callback_set_queued (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_call_invoke_callback_set_queued (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_callback_for_set_queued callback = (tp_cli_channel_type_call_callback_for_set_queued) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_call_call_set_queued (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_call_callback_for_set_queued callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CALL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetQueued",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetQueued", iface,
          _tp_cli_channel_type_call_invoke_callback_set_queued,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetQueued",
              _tp_cli_channel_type_call_collect_callback_set_queued,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_type_call_collect_callback_accept (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_call_invoke_callback_accept (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_callback_for_accept callback = (tp_cli_channel_type_call_callback_for_accept) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_call_call_accept (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_call_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CALL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
          _tp_cli_channel_type_call_invoke_callback_accept,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Accept",
              _tp_cli_channel_type_call_collect_callback_accept,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_type_call_collect_callback_hangup (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_call_invoke_callback_hangup (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_callback_for_hangup callback = (tp_cli_channel_type_call_callback_for_hangup) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_call_call_hangup (TpChannel *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Detailed_Hangup_Reason,
    const gchar *in_Message,
    tp_cli_channel_type_call_callback_for_hangup callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CALL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Hangup",
          G_TYPE_UINT, in_Reason,
          G_TYPE_STRING, in_Detailed_Hangup_Reason,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Hangup", iface,
          _tp_cli_channel_type_call_invoke_callback_hangup,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Hangup",
              _tp_cli_channel_type_call_collect_callback_hangup,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Reason,
              G_TYPE_STRING, in_Detailed_Hangup_Reason,
              G_TYPE_STRING, in_Message,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_type_call_collect_callback_add_content (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Content;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Content,
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
  g_value_take_boxed (args->values + 0, out_Content);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_call_invoke_callback_add_content (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_call_callback_for_add_content callback = (tp_cli_channel_type_call_callback_for_add_content) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_call_call_add_content (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Content_Name,
    guint in_Content_Type,
    guint in_InitialDirection,
    tp_cli_channel_type_call_callback_for_add_content callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CALL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddContent",
          G_TYPE_STRING, in_Content_Name,
          G_TYPE_UINT, in_Content_Type,
          G_TYPE_UINT, in_InitialDirection,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddContent", iface,
          _tp_cli_channel_type_call_invoke_callback_add_content,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddContent",
              _tp_cli_channel_type_call_collect_callback_add_content,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Content_Name,
              G_TYPE_UINT, in_Content_Type,
              G_TYPE_UINT, in_InitialDirection,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_channel_type_contact_search (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "SearchStateChanged",
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SearchResultReceived",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))),
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_contact_search_collect_args_of_search_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_State,
    const gchar *arg_Error,
    GHashTable *arg_Details,
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
  g_value_set_uint (args->values + 0, arg_State);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Error);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 2, arg_Details);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_contact_search_invoke_callback_for_search_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_contact_search_signal_callback_search_state_changed callback =
      (tp_cli_channel_type_contact_search_signal_callback_search_state_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_boxed (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_contact_search_connect_to_search_state_changed (TpChannel *proxy,
    tp_cli_channel_type_contact_search_signal_callback_search_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH, "SearchStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_contact_search_collect_args_of_search_state_changed),
      _tp_cli_channel_type_contact_search_invoke_callback_for_search_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_contact_search_collect_args_of_search_result_received (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Result,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))));
  g_value_set_boxed (args->values + 0, arg_Result);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_contact_search_invoke_callback_for_search_result_received (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_contact_search_signal_callback_search_result_received callback =
      (tp_cli_channel_type_contact_search_signal_callback_search_result_received) generic_callback;

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
tp_cli_channel_type_contact_search_connect_to_search_result_received (TpChannel *proxy,
    tp_cli_channel_type_contact_search_signal_callback_search_result_received callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH, "SearchResultReceived",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_contact_search_collect_args_of_search_result_received),
      _tp_cli_channel_type_contact_search_invoke_callback_for_search_result_received,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_contact_search_collect_callback_search (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_contact_search_invoke_callback_search (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_contact_search_callback_for_search callback = (tp_cli_channel_type_contact_search_callback_for_search) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_contact_search_call_search (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_Terms,
    tp_cli_channel_type_contact_search_callback_for_search callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Search",
          DBUS_TYPE_G_STRING_STRING_HASHTABLE, in_Terms,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Search", iface,
          _tp_cli_channel_type_contact_search_invoke_callback_search,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Search",
              _tp_cli_channel_type_contact_search_collect_callback_search,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_STRING_STRING_HASHTABLE, in_Terms,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_contact_search_run_state_search;
static void
_tp_cli_channel_type_contact_search_finish_running_search (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_contact_search_run_state_search *state = user_data;

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
tp_cli_channel_type_contact_search_run_search (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_Terms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_contact_search_run_state_search state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Search", iface,
      _tp_cli_channel_type_contact_search_finish_running_search,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Search",
          _tp_cli_channel_type_contact_search_collect_callback_search,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_STRING_STRING_HASHTABLE, in_Terms,
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
_tp_cli_channel_type_contact_search_collect_callback_more (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_contact_search_invoke_callback_more (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_contact_search_callback_for_more callback = (tp_cli_channel_type_contact_search_callback_for_more) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_contact_search_call_more (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_contact_search_callback_for_more callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "More",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "More", iface,
          _tp_cli_channel_type_contact_search_invoke_callback_more,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "More",
              _tp_cli_channel_type_contact_search_collect_callback_more,
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
} _tp_cli_channel_type_contact_search_run_state_more;
static void
_tp_cli_channel_type_contact_search_finish_running_more (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_contact_search_run_state_more *state = user_data;

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
tp_cli_channel_type_contact_search_run_more (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_contact_search_run_state_more state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "More", iface,
      _tp_cli_channel_type_contact_search_finish_running_more,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "More",
          _tp_cli_channel_type_contact_search_collect_callback_more,
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
_tp_cli_channel_type_contact_search_collect_callback_stop (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_contact_search_invoke_callback_stop (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_contact_search_callback_for_stop callback = (tp_cli_channel_type_contact_search_callback_for_stop) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_contact_search_call_stop (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_contact_search_callback_for_stop callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Stop",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Stop", iface,
          _tp_cli_channel_type_contact_search_invoke_callback_stop,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Stop",
              _tp_cli_channel_type_contact_search_collect_callback_stop,
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
} _tp_cli_channel_type_contact_search_run_state_stop;
static void
_tp_cli_channel_type_contact_search_finish_running_stop (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_contact_search_run_state_stop *state = user_data;

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
tp_cli_channel_type_contact_search_run_stop (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_contact_search_run_state_stop state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Stop", iface,
      _tp_cli_channel_type_contact_search_finish_running_stop,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Stop",
          _tp_cli_channel_type_contact_search_collect_callback_stop,
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
tp_cli_add_signals_for_channel_type_dbus_tube (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "DBusNamesChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_dbus_tube_collect_args_of_dbus_names_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Added,
    const GArray *arg_Removed,
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
  g_value_set_boxed (args->values + 0, arg_Added);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 1, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_dbus_tube_invoke_callback_for_dbus_names_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_dbus_tube_signal_callback_dbus_names_changed callback =
      (tp_cli_channel_type_dbus_tube_signal_callback_dbus_names_changed) generic_callback;

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
tp_cli_channel_type_dbus_tube_connect_to_dbus_names_changed (TpChannel *proxy,
    tp_cli_channel_type_dbus_tube_signal_callback_dbus_names_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE, "DBusNamesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_dbus_tube_collect_args_of_dbus_names_changed),
      _tp_cli_channel_type_dbus_tube_invoke_callback_for_dbus_names_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_dbus_tube_collect_callback_offer (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_address;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_address,
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
  g_value_take_string (args->values + 0, out_address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_dbus_tube_invoke_callback_offer (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_dbus_tube_callback_for_offer callback = (tp_cli_channel_type_dbus_tube_callback_for_offer) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_dbus_tube_call_offer (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_parameters,
    guint in_access_control,
    tp_cli_channel_type_dbus_tube_callback_for_offer callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Offer",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
          G_TYPE_UINT, in_access_control,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Offer", iface,
          _tp_cli_channel_type_dbus_tube_invoke_callback_offer,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Offer",
              _tp_cli_channel_type_dbus_tube_collect_callback_offer,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
              G_TYPE_UINT, in_access_control,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_dbus_tube_run_state_offer;
static void
_tp_cli_channel_type_dbus_tube_finish_running_offer (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_dbus_tube_run_state_offer *state = user_data;

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

  if (state->out_address != NULL)
    *state->out_address = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_dbus_tube_run_offer (TpChannel *proxy,
    gint timeout_ms,
    GHashTable *in_parameters,
    guint in_access_control,
    gchar **out_address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_dbus_tube_run_state_offer state = {
      NULL /* loop */, error,
    out_address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Offer", iface,
      _tp_cli_channel_type_dbus_tube_finish_running_offer,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Offer",
          _tp_cli_channel_type_dbus_tube_collect_callback_offer,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
              G_TYPE_UINT, in_access_control,
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
_tp_cli_channel_type_dbus_tube_collect_callback_accept (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_address;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_address,
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
  g_value_take_string (args->values + 0, out_address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_dbus_tube_invoke_callback_accept (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_dbus_tube_callback_for_accept callback = (tp_cli_channel_type_dbus_tube_callback_for_accept) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_dbus_tube_call_accept (TpChannel *proxy,
    gint timeout_ms,
    guint in_access_control,
    tp_cli_channel_type_dbus_tube_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Accept",
          G_TYPE_UINT, in_access_control,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Accept", iface,
          _tp_cli_channel_type_dbus_tube_invoke_callback_accept,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Accept",
              _tp_cli_channel_type_dbus_tube_collect_callback_accept,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_access_control,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_dbus_tube_run_state_accept;
static void
_tp_cli_channel_type_dbus_tube_finish_running_accept (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_dbus_tube_run_state_accept *state = user_data;

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

  if (state->out_address != NULL)
    *state->out_address = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_dbus_tube_run_accept (TpChannel *proxy,
    gint timeout_ms,
    guint in_access_control,
    gchar **out_address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_dbus_tube_run_state_accept state = {
      NULL /* loop */, error,
    out_address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Accept", iface,
      _tp_cli_channel_type_dbus_tube_finish_running_accept,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Accept",
          _tp_cli_channel_type_dbus_tube_collect_callback_accept,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_access_control,
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
tp_cli_add_signals_for_channel_type_file_transfer (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "FileTransferStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "TransferredBytesChanged",
      G_TYPE_UINT64,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "InitialOffsetDefined",
      G_TYPE_UINT64,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "URIDefined",
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_file_transfer_collect_args_of_file_transfer_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_State,
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
  g_value_set_uint (args->values + 0, arg_State);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_for_file_transfer_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_signal_callback_file_transfer_state_changed callback =
      (tp_cli_channel_type_file_transfer_signal_callback_file_transfer_state_changed) generic_callback;

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
tp_cli_channel_type_file_transfer_connect_to_file_transfer_state_changed (TpChannel *proxy,
    tp_cli_channel_type_file_transfer_signal_callback_file_transfer_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER, "FileTransferStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_file_transfer_collect_args_of_file_transfer_state_changed),
      _tp_cli_channel_type_file_transfer_invoke_callback_for_file_transfer_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_file_transfer_collect_args_of_transferred_bytes_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint64 arg_Count,
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
  g_value_init (args->values + 0, G_TYPE_UINT64);
  g_value_set_uint64 (args->values + 0, arg_Count);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_for_transferred_bytes_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_signal_callback_transferred_bytes_changed callback =
      (tp_cli_channel_type_file_transfer_signal_callback_transferred_bytes_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint64 (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_file_transfer_connect_to_transferred_bytes_changed (TpChannel *proxy,
    tp_cli_channel_type_file_transfer_signal_callback_transferred_bytes_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT64,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER, "TransferredBytesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_file_transfer_collect_args_of_transferred_bytes_changed),
      _tp_cli_channel_type_file_transfer_invoke_callback_for_transferred_bytes_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_file_transfer_collect_args_of_initial_offset_defined (DBusGProxy *proxy G_GNUC_UNUSED,
    guint64 arg_InitialOffset,
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
  g_value_init (args->values + 0, G_TYPE_UINT64);
  g_value_set_uint64 (args->values + 0, arg_InitialOffset);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_for_initial_offset_defined (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_signal_callback_initial_offset_defined callback =
      (tp_cli_channel_type_file_transfer_signal_callback_initial_offset_defined) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint64 (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_file_transfer_connect_to_initial_offset_defined (TpChannel *proxy,
    tp_cli_channel_type_file_transfer_signal_callback_initial_offset_defined callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT64,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER, "InitialOffsetDefined",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_file_transfer_collect_args_of_initial_offset_defined),
      _tp_cli_channel_type_file_transfer_invoke_callback_for_initial_offset_defined,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_file_transfer_collect_args_of_uri_defined (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_URI,
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
  g_value_set_string (args->values + 0, arg_URI);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_for_uri_defined (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_signal_callback_uri_defined callback =
      (tp_cli_channel_type_file_transfer_signal_callback_uri_defined) generic_callback;

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
tp_cli_channel_type_file_transfer_connect_to_uri_defined (TpChannel *proxy,
    tp_cli_channel_type_file_transfer_signal_callback_uri_defined callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER, "URIDefined",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_file_transfer_collect_args_of_uri_defined),
      _tp_cli_channel_type_file_transfer_invoke_callback_for_uri_defined,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_file_transfer_collect_callback_accept_file (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValue *out_Address = g_new0 (GValue, 1);

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_VALUE, out_Address,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      g_free (out_Address);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_VALUE);
  g_value_take_boxed (args->values + 0, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_accept_file (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_callback_for_accept_file callback = (tp_cli_channel_type_file_transfer_callback_for_accept_file) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_file_transfer_call_accept_file (TpChannel *proxy,
    gint timeout_ms,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    guint64 in_Offset,
    tp_cli_channel_type_file_transfer_callback_for_accept_file callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcceptFile",
          G_TYPE_UINT, in_Address_Type,
          G_TYPE_UINT, in_Access_Control,
          G_TYPE_VALUE, in_Access_Control_Param,
          G_TYPE_UINT64, in_Offset,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcceptFile", iface,
          _tp_cli_channel_type_file_transfer_invoke_callback_accept_file,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcceptFile",
              _tp_cli_channel_type_file_transfer_collect_callback_accept_file,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
              G_TYPE_UINT64, in_Offset,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValue **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_file_transfer_run_state_accept_file;
static void
_tp_cli_channel_type_file_transfer_finish_running_accept_file (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_file_transfer_run_state_accept_file *state = user_data;

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

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_file_transfer_run_accept_file (TpChannel *proxy,
    gint timeout_ms,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    guint64 in_Offset,
    GValue **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_file_transfer_run_state_accept_file state = {
      NULL /* loop */, error,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AcceptFile", iface,
      _tp_cli_channel_type_file_transfer_finish_running_accept_file,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AcceptFile",
          _tp_cli_channel_type_file_transfer_collect_callback_accept_file,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
              G_TYPE_UINT64, in_Offset,
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
_tp_cli_channel_type_file_transfer_collect_callback_provide_file (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValue *out_Address = g_new0 (GValue, 1);

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_VALUE, out_Address,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      g_free (out_Address);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_VALUE);
  g_value_take_boxed (args->values + 0, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_file_transfer_invoke_callback_provide_file (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_file_transfer_callback_for_provide_file callback = (tp_cli_channel_type_file_transfer_callback_for_provide_file) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_file_transfer_call_provide_file (TpChannel *proxy,
    gint timeout_ms,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    tp_cli_channel_type_file_transfer_callback_for_provide_file callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ProvideFile",
          G_TYPE_UINT, in_Address_Type,
          G_TYPE_UINT, in_Access_Control,
          G_TYPE_VALUE, in_Access_Control_Param,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ProvideFile", iface,
          _tp_cli_channel_type_file_transfer_invoke_callback_provide_file,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ProvideFile",
              _tp_cli_channel_type_file_transfer_collect_callback_provide_file,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValue **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_file_transfer_run_state_provide_file;
static void
_tp_cli_channel_type_file_transfer_finish_running_provide_file (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_file_transfer_run_state_provide_file *state = user_data;

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

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_file_transfer_run_provide_file (TpChannel *proxy,
    gint timeout_ms,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    GValue **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_file_transfer_run_state_provide_file state = {
      NULL /* loop */, error,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ProvideFile", iface,
      _tp_cli_channel_type_file_transfer_finish_running_provide_file,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ProvideFile",
          _tp_cli_channel_type_file_transfer_collect_callback_provide_file,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
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
tp_cli_add_signals_for_channel_type_room_list (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "GotRooms",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ListingRooms",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_room_list_collect_args_of_got_rooms (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Rooms,
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
  g_value_set_boxed (args->values + 0, arg_Rooms);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_room_list_invoke_callback_for_got_rooms (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_room_list_signal_callback_got_rooms callback =
      (tp_cli_channel_type_room_list_signal_callback_got_rooms) generic_callback;

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
tp_cli_channel_type_room_list_connect_to_got_rooms (TpChannel *proxy,
    tp_cli_channel_type_room_list_signal_callback_got_rooms callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST, "GotRooms",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_room_list_collect_args_of_got_rooms),
      _tp_cli_channel_type_room_list_invoke_callback_for_got_rooms,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_room_list_collect_args_of_listing_rooms (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Listing,
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
  g_value_set_boolean (args->values + 0, arg_Listing);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_room_list_invoke_callback_for_listing_rooms (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_room_list_signal_callback_listing_rooms callback =
      (tp_cli_channel_type_room_list_signal_callback_listing_rooms) generic_callback;

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
tp_cli_channel_type_room_list_connect_to_listing_rooms (TpChannel *proxy,
    tp_cli_channel_type_room_list_signal_callback_listing_rooms callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST, "ListingRooms",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_room_list_collect_args_of_listing_rooms),
      _tp_cli_channel_type_room_list_invoke_callback_for_listing_rooms,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_room_list_collect_callback_get_listing_rooms (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gboolean out_In_Progress;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_BOOLEAN, &out_In_Progress,
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
  g_value_set_boolean (args->values + 0, out_In_Progress);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_room_list_invoke_callback_get_listing_rooms (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_room_list_callback_for_get_listing_rooms callback = (tp_cli_channel_type_room_list_callback_for_get_listing_rooms) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boolean (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_room_list_call_get_listing_rooms (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_room_list_callback_for_get_listing_rooms callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetListingRooms",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetListingRooms", iface,
          _tp_cli_channel_type_room_list_invoke_callback_get_listing_rooms,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetListingRooms",
              _tp_cli_channel_type_room_list_collect_callback_get_listing_rooms,
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
    gboolean *out_In_Progress;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_room_list_run_state_get_listing_rooms;
static void
_tp_cli_channel_type_room_list_finish_running_get_listing_rooms (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_room_list_run_state_get_listing_rooms *state = user_data;

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

  if (state->out_In_Progress != NULL)
    *state->out_In_Progress = g_value_get_boolean (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_room_list_run_get_listing_rooms (TpChannel *proxy,
    gint timeout_ms,
    gboolean *out_In_Progress,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_room_list_run_state_get_listing_rooms state = {
      NULL /* loop */, error,
    out_In_Progress,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetListingRooms", iface,
      _tp_cli_channel_type_room_list_finish_running_get_listing_rooms,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetListingRooms",
          _tp_cli_channel_type_room_list_collect_callback_get_listing_rooms,
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
_tp_cli_channel_type_room_list_collect_callback_list_rooms (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_room_list_invoke_callback_list_rooms (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_room_list_callback_for_list_rooms callback = (tp_cli_channel_type_room_list_callback_for_list_rooms) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_room_list_call_list_rooms (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_room_list_callback_for_list_rooms callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListRooms",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListRooms", iface,
          _tp_cli_channel_type_room_list_invoke_callback_list_rooms,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListRooms",
              _tp_cli_channel_type_room_list_collect_callback_list_rooms,
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
} _tp_cli_channel_type_room_list_run_state_list_rooms;
static void
_tp_cli_channel_type_room_list_finish_running_list_rooms (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_room_list_run_state_list_rooms *state = user_data;

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
tp_cli_channel_type_room_list_run_list_rooms (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_room_list_run_state_list_rooms state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListRooms", iface,
      _tp_cli_channel_type_room_list_finish_running_list_rooms,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListRooms",
          _tp_cli_channel_type_room_list_collect_callback_list_rooms,
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
_tp_cli_channel_type_room_list_collect_callback_stop_listing (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_room_list_invoke_callback_stop_listing (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_room_list_callback_for_stop_listing callback = (tp_cli_channel_type_room_list_callback_for_stop_listing) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_room_list_call_stop_listing (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_room_list_callback_for_stop_listing callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StopListing",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StopListing", iface,
          _tp_cli_channel_type_room_list_invoke_callback_stop_listing,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StopListing",
              _tp_cli_channel_type_room_list_collect_callback_stop_listing,
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
} _tp_cli_channel_type_room_list_run_state_stop_listing;
static void
_tp_cli_channel_type_room_list_finish_running_stop_listing (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_room_list_run_state_stop_listing *state = user_data;

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
tp_cli_channel_type_room_list_run_stop_listing (TpChannel *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_room_list_run_state_stop_listing state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StopListing", iface,
      _tp_cli_channel_type_room_list_finish_running_stop_listing,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StopListing",
          _tp_cli_channel_type_room_list_collect_callback_stop_listing,
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
tp_cli_add_signals_for_channel_type_stream_tube (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewRemoteConnection",
      G_TYPE_UINT,
      G_TYPE_VALUE,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "NewLocalConnection",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "ConnectionClosed",
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_stream_tube_collect_args_of_new_remote_connection (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Handle,
    const GValue *arg_Connection_Param,
    guint arg_Connection_ID,
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
  g_value_set_uint (args->values + 0, arg_Handle);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_VALUE);
  g_value_set_boxed (args->values + 1, arg_Connection_Param);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Connection_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_stream_tube_invoke_callback_for_new_remote_connection (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_stream_tube_signal_callback_new_remote_connection callback =
      (tp_cli_channel_type_stream_tube_signal_callback_new_remote_connection) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_uint (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_stream_tube_connect_to_new_remote_connection (TpChannel *proxy,
    tp_cli_channel_type_stream_tube_signal_callback_new_remote_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_VALUE,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE, "NewRemoteConnection",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_stream_tube_collect_args_of_new_remote_connection),
      _tp_cli_channel_type_stream_tube_invoke_callback_for_new_remote_connection,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_stream_tube_collect_args_of_new_local_connection (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Connection_ID,
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
  g_value_set_uint (args->values + 0, arg_Connection_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_stream_tube_invoke_callback_for_new_local_connection (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_stream_tube_signal_callback_new_local_connection callback =
      (tp_cli_channel_type_stream_tube_signal_callback_new_local_connection) generic_callback;

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
tp_cli_channel_type_stream_tube_connect_to_new_local_connection (TpChannel *proxy,
    tp_cli_channel_type_stream_tube_signal_callback_new_local_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE, "NewLocalConnection",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_stream_tube_collect_args_of_new_local_connection),
      _tp_cli_channel_type_stream_tube_invoke_callback_for_new_local_connection,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_stream_tube_collect_args_of_connection_closed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Connection_ID,
    const gchar *arg_Error,
    const gchar *arg_Message,
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
  g_value_set_uint (args->values + 0, arg_Connection_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Error);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Message);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_stream_tube_invoke_callback_for_connection_closed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_stream_tube_signal_callback_connection_closed callback =
      (tp_cli_channel_type_stream_tube_signal_callback_connection_closed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
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
tp_cli_channel_type_stream_tube_connect_to_connection_closed (TpChannel *proxy,
    tp_cli_channel_type_stream_tube_signal_callback_connection_closed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE, "ConnectionClosed",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_stream_tube_collect_args_of_connection_closed),
      _tp_cli_channel_type_stream_tube_invoke_callback_for_connection_closed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_stream_tube_collect_callback_offer (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_stream_tube_invoke_callback_offer (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_stream_tube_callback_for_offer callback = (tp_cli_channel_type_stream_tube_callback_for_offer) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_stream_tube_call_offer (TpChannel *proxy,
    gint timeout_ms,
    guint in_address_type,
    const GValue *in_address,
    guint in_access_control,
    GHashTable *in_parameters,
    tp_cli_channel_type_stream_tube_callback_for_offer callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Offer",
          G_TYPE_UINT, in_address_type,
          G_TYPE_VALUE, in_address,
          G_TYPE_UINT, in_access_control,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Offer", iface,
          _tp_cli_channel_type_stream_tube_invoke_callback_offer,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Offer",
              _tp_cli_channel_type_stream_tube_collect_callback_offer,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_address_type,
              G_TYPE_VALUE, in_address,
              G_TYPE_UINT, in_access_control,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_stream_tube_run_state_offer;
static void
_tp_cli_channel_type_stream_tube_finish_running_offer (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_stream_tube_run_state_offer *state = user_data;

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
tp_cli_channel_type_stream_tube_run_offer (TpChannel *proxy,
    gint timeout_ms,
    guint in_address_type,
    const GValue *in_address,
    guint in_access_control,
    GHashTable *in_parameters,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_stream_tube_run_state_offer state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Offer", iface,
      _tp_cli_channel_type_stream_tube_finish_running_offer,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Offer",
          _tp_cli_channel_type_stream_tube_collect_callback_offer,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_address_type,
              G_TYPE_VALUE, in_address,
              G_TYPE_UINT, in_access_control,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_parameters,
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
_tp_cli_channel_type_stream_tube_collect_callback_accept (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValue *out_address = g_new0 (GValue, 1);

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_VALUE, out_address,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      g_free (out_address);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_VALUE);
  g_value_take_boxed (args->values + 0, out_address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_stream_tube_invoke_callback_accept (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_stream_tube_callback_for_accept callback = (tp_cli_channel_type_stream_tube_callback_for_accept) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_stream_tube_call_accept (TpChannel *proxy,
    gint timeout_ms,
    guint in_address_type,
    guint in_access_control,
    const GValue *in_access_control_param,
    tp_cli_channel_type_stream_tube_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Accept",
          G_TYPE_UINT, in_address_type,
          G_TYPE_UINT, in_access_control,
          G_TYPE_VALUE, in_access_control_param,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Accept", iface,
          _tp_cli_channel_type_stream_tube_invoke_callback_accept,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Accept",
              _tp_cli_channel_type_stream_tube_collect_callback_accept,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_address_type,
              G_TYPE_UINT, in_access_control,
              G_TYPE_VALUE, in_access_control_param,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValue **out_address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_stream_tube_run_state_accept;
static void
_tp_cli_channel_type_stream_tube_finish_running_accept (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_stream_tube_run_state_accept *state = user_data;

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

  if (state->out_address != NULL)
    *state->out_address = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_stream_tube_run_accept (TpChannel *proxy,
    gint timeout_ms,
    guint in_address_type,
    guint in_access_control,
    const GValue *in_access_control_param,
    GValue **out_address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_stream_tube_run_state_accept state = {
      NULL /* loop */, error,
    out_address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Accept", iface,
      _tp_cli_channel_type_stream_tube_finish_running_accept,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Accept",
          _tp_cli_channel_type_stream_tube_collect_callback_accept,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_address_type,
              G_TYPE_UINT, in_access_control,
              G_TYPE_VALUE, in_access_control_param,
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
tp_cli_add_signals_for_channel_type_streamed_media (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "StreamAdded",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamDirectionChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamError",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamRemoved",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_streamed_media_collect_args_of_stream_added (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Stream_ID,
    guint arg_Contact_Handle,
    guint arg_Stream_Type,
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
  g_value_set_uint (args->values + 0, arg_Stream_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Contact_Handle);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Stream_Type);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_for_stream_added (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_signal_callback_stream_added callback =
      (tp_cli_channel_type_streamed_media_signal_callback_stream_added) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_streamed_media_connect_to_stream_added (TpChannel *proxy,
    tp_cli_channel_type_streamed_media_signal_callback_stream_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA, "StreamAdded",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_streamed_media_collect_args_of_stream_added),
      _tp_cli_channel_type_streamed_media_invoke_callback_for_stream_added,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_streamed_media_collect_args_of_stream_direction_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Stream_ID,
    guint arg_Stream_Direction,
    guint arg_Pending_Flags,
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
  g_value_set_uint (args->values + 0, arg_Stream_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Stream_Direction);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Pending_Flags);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_for_stream_direction_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_signal_callback_stream_direction_changed callback =
      (tp_cli_channel_type_streamed_media_signal_callback_stream_direction_changed) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_streamed_media_connect_to_stream_direction_changed (TpChannel *proxy,
    tp_cli_channel_type_streamed_media_signal_callback_stream_direction_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA, "StreamDirectionChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_streamed_media_collect_args_of_stream_direction_changed),
      _tp_cli_channel_type_streamed_media_invoke_callback_for_stream_direction_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_streamed_media_collect_args_of_stream_error (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Stream_ID,
    guint arg_Error_Code,
    const gchar *arg_Message,
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
  g_value_set_uint (args->values + 0, arg_Stream_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Error_Code);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Message);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_for_stream_error (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_signal_callback_stream_error callback =
      (tp_cli_channel_type_streamed_media_signal_callback_stream_error) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_streamed_media_connect_to_stream_error (TpChannel *proxy,
    tp_cli_channel_type_streamed_media_signal_callback_stream_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA, "StreamError",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_streamed_media_collect_args_of_stream_error),
      _tp_cli_channel_type_streamed_media_invoke_callback_for_stream_error,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_streamed_media_collect_args_of_stream_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Stream_ID,
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
  g_value_set_uint (args->values + 0, arg_Stream_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_for_stream_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_signal_callback_stream_removed callback =
      (tp_cli_channel_type_streamed_media_signal_callback_stream_removed) generic_callback;

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
tp_cli_channel_type_streamed_media_connect_to_stream_removed (TpChannel *proxy,
    tp_cli_channel_type_streamed_media_signal_callback_stream_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA, "StreamRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_streamed_media_collect_args_of_stream_removed),
      _tp_cli_channel_type_streamed_media_invoke_callback_for_stream_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_streamed_media_collect_args_of_stream_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Stream_ID,
    guint arg_Stream_State,
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
  g_value_set_uint (args->values + 0, arg_Stream_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Stream_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_for_stream_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_signal_callback_stream_state_changed callback =
      (tp_cli_channel_type_streamed_media_signal_callback_stream_state_changed) generic_callback;

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
tp_cli_channel_type_streamed_media_connect_to_stream_state_changed (TpChannel *proxy,
    tp_cli_channel_type_streamed_media_signal_callback_stream_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA, "StreamStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_streamed_media_collect_args_of_stream_state_changed),
      _tp_cli_channel_type_streamed_media_invoke_callback_for_stream_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_streamed_media_collect_callback_list_streams (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Streams;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))), &out_Streams,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Streams);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_list_streams (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_callback_for_list_streams callback = (tp_cli_channel_type_streamed_media_callback_for_list_streams) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_streamed_media_call_list_streams (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_streamed_media_callback_for_list_streams callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListStreams",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListStreams", iface,
          _tp_cli_channel_type_streamed_media_invoke_callback_list_streams,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListStreams",
              _tp_cli_channel_type_streamed_media_collect_callback_list_streams,
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
    GPtrArray **out_Streams;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_streamed_media_run_state_list_streams;
static void
_tp_cli_channel_type_streamed_media_finish_running_list_streams (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_streamed_media_run_state_list_streams *state = user_data;

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

  if (state->out_Streams != NULL)
    *state->out_Streams = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_streamed_media_run_list_streams (TpChannel *proxy,
    gint timeout_ms,
    GPtrArray **out_Streams,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_streamed_media_run_state_list_streams state = {
      NULL /* loop */, error,
    out_Streams,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListStreams", iface,
      _tp_cli_channel_type_streamed_media_finish_running_list_streams,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListStreams",
          _tp_cli_channel_type_streamed_media_collect_callback_list_streams,
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
_tp_cli_channel_type_streamed_media_collect_callback_remove_streams (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_remove_streams (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_callback_for_remove_streams callback = (tp_cli_channel_type_streamed_media_callback_for_remove_streams) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_streamed_media_call_remove_streams (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Streams,
    tp_cli_channel_type_streamed_media_callback_for_remove_streams callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveStreams",
          DBUS_TYPE_G_UINT_ARRAY, in_Streams,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveStreams", iface,
          _tp_cli_channel_type_streamed_media_invoke_callback_remove_streams,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveStreams",
              _tp_cli_channel_type_streamed_media_collect_callback_remove_streams,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Streams,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_streamed_media_run_state_remove_streams;
static void
_tp_cli_channel_type_streamed_media_finish_running_remove_streams (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_streamed_media_run_state_remove_streams *state = user_data;

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
tp_cli_channel_type_streamed_media_run_remove_streams (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_Streams,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_streamed_media_run_state_remove_streams state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RemoveStreams", iface,
      _tp_cli_channel_type_streamed_media_finish_running_remove_streams,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RemoveStreams",
          _tp_cli_channel_type_streamed_media_collect_callback_remove_streams,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_Streams,
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
_tp_cli_channel_type_streamed_media_collect_callback_request_stream_direction (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_request_stream_direction (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_callback_for_request_stream_direction callback = (tp_cli_channel_type_streamed_media_callback_for_request_stream_direction) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_streamed_media_call_request_stream_direction (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    guint in_Stream_Direction,
    tp_cli_channel_type_streamed_media_callback_for_request_stream_direction callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestStreamDirection",
          G_TYPE_UINT, in_Stream_ID,
          G_TYPE_UINT, in_Stream_Direction,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestStreamDirection", iface,
          _tp_cli_channel_type_streamed_media_invoke_callback_request_stream_direction,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestStreamDirection",
              _tp_cli_channel_type_streamed_media_collect_callback_request_stream_direction,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
              G_TYPE_UINT, in_Stream_Direction,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_streamed_media_run_state_request_stream_direction;
static void
_tp_cli_channel_type_streamed_media_finish_running_request_stream_direction (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_streamed_media_run_state_request_stream_direction *state = user_data;

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
tp_cli_channel_type_streamed_media_run_request_stream_direction (TpChannel *proxy,
    gint timeout_ms,
    guint in_Stream_ID,
    guint in_Stream_Direction,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_streamed_media_run_state_request_stream_direction state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestStreamDirection", iface,
      _tp_cli_channel_type_streamed_media_finish_running_request_stream_direction,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestStreamDirection",
          _tp_cli_channel_type_streamed_media_collect_callback_request_stream_direction,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Stream_ID,
              G_TYPE_UINT, in_Stream_Direction,
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
_tp_cli_channel_type_streamed_media_collect_callback_request_streams (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Streams;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))), &out_Streams,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Streams);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_streamed_media_invoke_callback_request_streams (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_streamed_media_callback_for_request_streams callback = (tp_cli_channel_type_streamed_media_callback_for_request_streams) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_streamed_media_call_request_streams (TpChannel *proxy,
    gint timeout_ms,
    guint in_Contact_Handle,
    const GArray *in_Types,
    tp_cli_channel_type_streamed_media_callback_for_request_streams callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestStreams",
          G_TYPE_UINT, in_Contact_Handle,
          DBUS_TYPE_G_UINT_ARRAY, in_Types,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestStreams", iface,
          _tp_cli_channel_type_streamed_media_invoke_callback_request_streams,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestStreams",
              _tp_cli_channel_type_streamed_media_collect_callback_request_streams,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Contact_Handle,
              DBUS_TYPE_G_UINT_ARRAY, in_Types,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Streams;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_streamed_media_run_state_request_streams;
static void
_tp_cli_channel_type_streamed_media_finish_running_request_streams (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_streamed_media_run_state_request_streams *state = user_data;

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

  if (state->out_Streams != NULL)
    *state->out_Streams = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_streamed_media_run_request_streams (TpChannel *proxy,
    gint timeout_ms,
    guint in_Contact_Handle,
    const GArray *in_Types,
    GPtrArray **out_Streams,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_streamed_media_run_state_request_streams state = {
      NULL /* loop */, error,
    out_Streams,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestStreams", iface,
      _tp_cli_channel_type_streamed_media_finish_running_request_streams,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestStreams",
          _tp_cli_channel_type_streamed_media_collect_callback_request_streams,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Contact_Handle,
              DBUS_TYPE_G_UINT_ARRAY, in_Types,
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
tp_cli_add_signals_for_channel_type_text (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "LostMessage",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "Received",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SendError",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "Sent",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_text_invoke_callback_for_lost_message (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_signal_callback_lost_message callback =
      (tp_cli_channel_type_text_signal_callback_lost_message) generic_callback;

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
tp_cli_channel_type_text_connect_to_lost_message (TpChannel *proxy,
    tp_cli_channel_type_text_signal_callback_lost_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TEXT, "LostMessage",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_channel_type_text_invoke_callback_for_lost_message,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_text_collect_args_of_received (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
    guint arg_Timestamp,
    guint arg_Sender,
    guint arg_Type,
    guint arg_Flags,
    const gchar *arg_Text,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (6);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 6; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Timestamp);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Sender);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_UINT);
  g_value_set_uint (args->values + 3, arg_Type);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, G_TYPE_UINT);
  g_value_set_uint (args->values + 4, arg_Flags);

  g_value_unset (args->values + 5);
  g_value_init (args->values + 5, G_TYPE_STRING);
  g_value_set_string (args->values + 5, arg_Text);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_text_invoke_callback_for_received (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_signal_callback_received callback =
      (tp_cli_channel_type_text_signal_callback_received) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_uint (args->values + 3),
      g_value_get_uint (args->values + 4),
      g_value_get_string (args->values + 5),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_text_connect_to_received (TpChannel *proxy,
    tp_cli_channel_type_text_signal_callback_received callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[7] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TEXT, "Received",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_text_collect_args_of_received),
      _tp_cli_channel_type_text_invoke_callback_for_received,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_text_collect_args_of_send_error (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Error,
    guint arg_Timestamp,
    guint arg_Type,
    const gchar *arg_Text,
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
  g_value_set_uint (args->values + 0, arg_Error);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Timestamp);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Type);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_STRING);
  g_value_set_string (args->values + 3, arg_Text);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_text_invoke_callback_for_send_error (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_signal_callback_send_error callback =
      (tp_cli_channel_type_text_signal_callback_send_error) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_string (args->values + 3),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_text_connect_to_send_error (TpChannel *proxy,
    tp_cli_channel_type_text_signal_callback_send_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TEXT, "SendError",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_text_collect_args_of_send_error),
      _tp_cli_channel_type_text_invoke_callback_for_send_error,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_text_collect_args_of_sent (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_Timestamp,
    guint arg_Type,
    const gchar *arg_Text,
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
  g_value_set_uint (args->values + 0, arg_Timestamp);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Type);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Text);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_text_invoke_callback_for_sent (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_signal_callback_sent callback =
      (tp_cli_channel_type_text_signal_callback_sent) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_text_connect_to_sent (TpChannel *proxy,
    tp_cli_channel_type_text_signal_callback_sent callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TEXT, "Sent",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_text_collect_args_of_sent),
      _tp_cli_channel_type_text_invoke_callback_for_sent,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_text_collect_callback_acknowledge_pending_messages (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_text_invoke_callback_acknowledge_pending_messages (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_callback_for_acknowledge_pending_messages callback = (tp_cli_channel_type_text_callback_for_acknowledge_pending_messages) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_text_call_acknowledge_pending_messages (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_IDs,
    tp_cli_channel_type_text_callback_for_acknowledge_pending_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcknowledgePendingMessages",
          DBUS_TYPE_G_UINT_ARRAY, in_IDs,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcknowledgePendingMessages", iface,
          _tp_cli_channel_type_text_invoke_callback_acknowledge_pending_messages,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcknowledgePendingMessages",
              _tp_cli_channel_type_text_collect_callback_acknowledge_pending_messages,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_IDs,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_text_run_state_acknowledge_pending_messages;
static void
_tp_cli_channel_type_text_finish_running_acknowledge_pending_messages (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_text_run_state_acknowledge_pending_messages *state = user_data;

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
tp_cli_channel_type_text_run_acknowledge_pending_messages (TpChannel *proxy,
    gint timeout_ms,
    const GArray *in_IDs,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_text_run_state_acknowledge_pending_messages state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AcknowledgePendingMessages", iface,
      _tp_cli_channel_type_text_finish_running_acknowledge_pending_messages,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AcknowledgePendingMessages",
          _tp_cli_channel_type_text_collect_callback_acknowledge_pending_messages,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              DBUS_TYPE_G_UINT_ARRAY, in_IDs,
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
_tp_cli_channel_type_text_collect_callback_get_message_types (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Available_Types;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_UINT_ARRAY, &out_Available_Types,
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
  g_value_take_boxed (args->values + 0, out_Available_Types);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_text_invoke_callback_get_message_types (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_callback_for_get_message_types callback = (tp_cli_channel_type_text_callback_for_get_message_types) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_text_call_get_message_types (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_text_callback_for_get_message_types callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetMessageTypes",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetMessageTypes", iface,
          _tp_cli_channel_type_text_invoke_callback_get_message_types,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetMessageTypes",
              _tp_cli_channel_type_text_collect_callback_get_message_types,
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
    GArray **out_Available_Types;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_text_run_state_get_message_types;
static void
_tp_cli_channel_type_text_finish_running_get_message_types (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_text_run_state_get_message_types *state = user_data;

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

  if (state->out_Available_Types != NULL)
    *state->out_Available_Types = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_text_run_get_message_types (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Available_Types,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_text_run_state_get_message_types state = {
      NULL /* loop */, error,
    out_Available_Types,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetMessageTypes", iface,
      _tp_cli_channel_type_text_finish_running_get_message_types,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetMessageTypes",
          _tp_cli_channel_type_text_collect_callback_get_message_types,
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
_tp_cli_channel_type_text_collect_callback_list_pending_messages (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Pending_Messages;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Pending_Messages,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Pending_Messages);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_text_invoke_callback_list_pending_messages (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_callback_for_list_pending_messages callback = (tp_cli_channel_type_text_callback_for_list_pending_messages) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_text_call_list_pending_messages (TpChannel *proxy,
    gint timeout_ms,
    gboolean in_Clear,
    tp_cli_channel_type_text_callback_for_list_pending_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListPendingMessages",
          G_TYPE_BOOLEAN, in_Clear,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListPendingMessages", iface,
          _tp_cli_channel_type_text_invoke_callback_list_pending_messages,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListPendingMessages",
              _tp_cli_channel_type_text_collect_callback_list_pending_messages,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Clear,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Pending_Messages;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_text_run_state_list_pending_messages;
static void
_tp_cli_channel_type_text_finish_running_list_pending_messages (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_text_run_state_list_pending_messages *state = user_data;

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

  if (state->out_Pending_Messages != NULL)
    *state->out_Pending_Messages = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_text_run_list_pending_messages (TpChannel *proxy,
    gint timeout_ms,
    gboolean in_Clear,
    GPtrArray **out_Pending_Messages,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_text_run_state_list_pending_messages state = {
      NULL /* loop */, error,
    out_Pending_Messages,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListPendingMessages", iface,
      _tp_cli_channel_type_text_finish_running_list_pending_messages,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListPendingMessages",
          _tp_cli_channel_type_text_collect_callback_list_pending_messages,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_BOOLEAN, in_Clear,
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
_tp_cli_channel_type_text_collect_callback_send (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_text_invoke_callback_send (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_text_callback_for_send callback = (tp_cli_channel_type_text_callback_for_send) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_text_call_send (TpChannel *proxy,
    gint timeout_ms,
    guint in_Type,
    const gchar *in_Text,
    tp_cli_channel_type_text_callback_for_send callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "Send",
          G_TYPE_UINT, in_Type,
          G_TYPE_STRING, in_Text,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Send", iface,
          _tp_cli_channel_type_text_invoke_callback_send,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Send",
              _tp_cli_channel_type_text_collect_callback_send,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Type,
              G_TYPE_STRING, in_Text,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_text_run_state_send;
static void
_tp_cli_channel_type_text_finish_running_send (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_text_run_state_send *state = user_data;

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
tp_cli_channel_type_text_run_send (TpChannel *proxy,
    gint timeout_ms,
    guint in_Type,
    const gchar *in_Text,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TEXT;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_text_run_state_send state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Send", iface,
      _tp_cli_channel_type_text_finish_running_send,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Send",
          _tp_cli_channel_type_text_collect_callback_send,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Type,
              G_TYPE_STRING, in_Text,
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
tp_cli_add_signals_for_channel_type_tubes (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewTube",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "TubeStateChanged",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "TubeClosed",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "DBusNamesChanged",
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamTubeNewConnection",
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_type_tubes_collect_args_of_new_tube (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
    guint arg_Initiator,
    guint arg_Type,
    const gchar *arg_Service,
    GHashTable *arg_Parameters,
    guint arg_State,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (6);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 6; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_UINT);
  g_value_set_uint (args->values + 0, arg_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Initiator);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_Type);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_STRING);
  g_value_set_string (args->values + 3, arg_Service);

  g_value_unset (args->values + 4);
  g_value_init (args->values + 4, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 4, arg_Parameters);

  g_value_unset (args->values + 5);
  g_value_init (args->values + 5, G_TYPE_UINT);
  g_value_set_uint (args->values + 5, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_for_new_tube (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_signal_callback_new_tube callback =
      (tp_cli_channel_type_tubes_signal_callback_new_tube) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uint (args->values + 0),
      g_value_get_uint (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_string (args->values + 3),
      g_value_get_boxed (args->values + 4),
      g_value_get_uint (args->values + 5),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_type_tubes_connect_to_new_tube (TpChannel *proxy,
    tp_cli_channel_type_tubes_signal_callback_new_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[7] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TUBES, "NewTube",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_tubes_collect_args_of_new_tube),
      _tp_cli_channel_type_tubes_invoke_callback_for_new_tube,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_tubes_collect_args_of_tube_state_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
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
  g_value_set_uint (args->values + 0, arg_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_for_tube_state_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_signal_callback_tube_state_changed callback =
      (tp_cli_channel_type_tubes_signal_callback_tube_state_changed) generic_callback;

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
tp_cli_channel_type_tubes_connect_to_tube_state_changed (TpChannel *proxy,
    tp_cli_channel_type_tubes_signal_callback_tube_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TUBES, "TubeStateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_tubes_collect_args_of_tube_state_changed),
      _tp_cli_channel_type_tubes_invoke_callback_for_tube_state_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_tubes_collect_args_of_tube_closed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
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
  g_value_set_uint (args->values + 0, arg_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_for_tube_closed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_signal_callback_tube_closed callback =
      (tp_cli_channel_type_tubes_signal_callback_tube_closed) generic_callback;

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
tp_cli_channel_type_tubes_connect_to_tube_closed (TpChannel *proxy,
    tp_cli_channel_type_tubes_signal_callback_tube_closed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TUBES, "TubeClosed",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_tubes_collect_args_of_tube_closed),
      _tp_cli_channel_type_tubes_invoke_callback_for_tube_closed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_tubes_collect_args_of_d_bus_names_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
    const GPtrArray *arg_Added,
    const GArray *arg_Removed,
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
  g_value_set_uint (args->values + 0, arg_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 1, arg_Added);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, DBUS_TYPE_G_UINT_ARRAY);
  g_value_set_boxed (args->values + 2, arg_Removed);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_for_d_bus_names_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_signal_callback_d_bus_names_changed callback =
      (tp_cli_channel_type_tubes_signal_callback_d_bus_names_changed) generic_callback;

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
tp_cli_channel_type_tubes_connect_to_d_bus_names_changed (TpChannel *proxy,
    tp_cli_channel_type_tubes_signal_callback_d_bus_names_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TUBES, "DBusNamesChanged",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_tubes_collect_args_of_d_bus_names_changed),
      _tp_cli_channel_type_tubes_invoke_callback_for_d_bus_names_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_tubes_collect_args_of_stream_tube_new_connection (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_ID,
    guint arg_Handle,
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
  g_value_set_uint (args->values + 0, arg_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_Handle);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_for_stream_tube_new_connection (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_signal_callback_stream_tube_new_connection callback =
      (tp_cli_channel_type_tubes_signal_callback_stream_tube_new_connection) generic_callback;

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
tp_cli_channel_type_tubes_connect_to_stream_tube_new_connection (TpChannel *proxy,
    tp_cli_channel_type_tubes_signal_callback_stream_tube_new_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_TYPE_TUBES, "StreamTubeNewConnection",
      expected_types,
      G_CALLBACK (_tp_cli_channel_type_tubes_collect_args_of_stream_tube_new_connection),
      _tp_cli_channel_type_tubes_invoke_callback_for_stream_tube_new_connection,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_type_tubes_collect_callback_get_available_stream_tube_types (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GHashTable *out_Available_Stream_Tube_Types;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_UINT_ARRAY)), &out_Available_Stream_Tube_Types,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_UINT_ARRAY)));
  g_value_take_boxed (args->values + 0, out_Available_Stream_Tube_Types);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_get_available_stream_tube_types (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_get_available_stream_tube_types callback = (tp_cli_channel_type_tubes_callback_for_get_available_stream_tube_types) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_get_available_stream_tube_types (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_tubes_callback_for_get_available_stream_tube_types callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetAvailableStreamTubeTypes",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAvailableStreamTubeTypes", iface,
          _tp_cli_channel_type_tubes_invoke_callback_get_available_stream_tube_types,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAvailableStreamTubeTypes",
              _tp_cli_channel_type_tubes_collect_callback_get_available_stream_tube_types,
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
    GHashTable **out_Available_Stream_Tube_Types;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_get_available_stream_tube_types;
static void
_tp_cli_channel_type_tubes_finish_running_get_available_stream_tube_types (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_get_available_stream_tube_types *state = user_data;

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

  if (state->out_Available_Stream_Tube_Types != NULL)
    *state->out_Available_Stream_Tube_Types = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_get_available_stream_tube_types (TpChannel *proxy,
    gint timeout_ms,
    GHashTable **out_Available_Stream_Tube_Types,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_get_available_stream_tube_types state = {
      NULL /* loop */, error,
    out_Available_Stream_Tube_Types,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAvailableStreamTubeTypes", iface,
      _tp_cli_channel_type_tubes_finish_running_get_available_stream_tube_types,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAvailableStreamTubeTypes",
          _tp_cli_channel_type_tubes_collect_callback_get_available_stream_tube_types,
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
_tp_cli_channel_type_tubes_collect_callback_get_available_tube_types (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GArray *out_Available_Tube_Types;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_UINT_ARRAY, &out_Available_Tube_Types,
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
  g_value_take_boxed (args->values + 0, out_Available_Tube_Types);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_get_available_tube_types (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_get_available_tube_types callback = (tp_cli_channel_type_tubes_callback_for_get_available_tube_types) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_get_available_tube_types (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_tubes_callback_for_get_available_tube_types callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetAvailableTubeTypes",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetAvailableTubeTypes", iface,
          _tp_cli_channel_type_tubes_invoke_callback_get_available_tube_types,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetAvailableTubeTypes",
              _tp_cli_channel_type_tubes_collect_callback_get_available_tube_types,
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
    GArray **out_Available_Tube_Types;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_get_available_tube_types;
static void
_tp_cli_channel_type_tubes_finish_running_get_available_tube_types (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_get_available_tube_types *state = user_data;

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

  if (state->out_Available_Tube_Types != NULL)
    *state->out_Available_Tube_Types = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_get_available_tube_types (TpChannel *proxy,
    gint timeout_ms,
    GArray **out_Available_Tube_Types,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_get_available_tube_types state = {
      NULL /* loop */, error,
    out_Available_Tube_Types,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetAvailableTubeTypes", iface,
      _tp_cli_channel_type_tubes_finish_running_get_available_tube_types,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetAvailableTubeTypes",
          _tp_cli_channel_type_tubes_collect_callback_get_available_tube_types,
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
_tp_cli_channel_type_tubes_collect_callback_list_tubes (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Tubes;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_UINT, G_TYPE_INVALID)))), &out_Tubes,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_UINT, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Tubes);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_list_tubes (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_list_tubes callback = (tp_cli_channel_type_tubes_callback_for_list_tubes) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_list_tubes (TpChannel *proxy,
    gint timeout_ms,
    tp_cli_channel_type_tubes_callback_for_list_tubes callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListTubes",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListTubes", iface,
          _tp_cli_channel_type_tubes_invoke_callback_list_tubes,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListTubes",
              _tp_cli_channel_type_tubes_collect_callback_list_tubes,
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
    GPtrArray **out_Tubes;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_list_tubes;
static void
_tp_cli_channel_type_tubes_finish_running_list_tubes (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_list_tubes *state = user_data;

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

  if (state->out_Tubes != NULL)
    *state->out_Tubes = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_list_tubes (TpChannel *proxy,
    gint timeout_ms,
    GPtrArray **out_Tubes,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_list_tubes state = {
      NULL /* loop */, error,
    out_Tubes,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListTubes", iface,
      _tp_cli_channel_type_tubes_finish_running_list_tubes,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListTubes",
          _tp_cli_channel_type_tubes_collect_callback_list_tubes,
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
_tp_cli_channel_type_tubes_collect_callback_offer_d_bus_tube (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Tube_ID;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Tube_ID,
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
  g_value_set_uint (args->values + 0, out_Tube_ID);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_offer_d_bus_tube (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_offer_d_bus_tube callback = (tp_cli_channel_type_tubes_callback_for_offer_d_bus_tube) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_offer_d_bus_tube (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    tp_cli_channel_type_tubes_callback_for_offer_d_bus_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "OfferDBusTube",
          G_TYPE_STRING, in_Service,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "OfferDBusTube", iface,
          _tp_cli_channel_type_tubes_invoke_callback_offer_d_bus_tube,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "OfferDBusTube",
              _tp_cli_channel_type_tubes_collect_callback_offer_d_bus_tube,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Service,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Tube_ID;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_offer_d_bus_tube;
static void
_tp_cli_channel_type_tubes_finish_running_offer_d_bus_tube (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_offer_d_bus_tube *state = user_data;

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

  if (state->out_Tube_ID != NULL)
    *state->out_Tube_ID = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_offer_d_bus_tube (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    guint *out_Tube_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_offer_d_bus_tube state = {
      NULL /* loop */, error,
    out_Tube_ID,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "OfferDBusTube", iface,
      _tp_cli_channel_type_tubes_finish_running_offer_d_bus_tube,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "OfferDBusTube",
          _tp_cli_channel_type_tubes_collect_callback_offer_d_bus_tube,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Service,
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
_tp_cli_channel_type_tubes_collect_callback_offer_stream_tube (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Tube_ID;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Tube_ID,
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
  g_value_set_uint (args->values + 0, out_Tube_ID);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_offer_stream_tube (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_offer_stream_tube callback = (tp_cli_channel_type_tubes_callback_for_offer_stream_tube) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_offer_stream_tube (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    guint in_Address_Type,
    const GValue *in_Address,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    tp_cli_channel_type_tubes_callback_for_offer_stream_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "OfferStreamTube",
          G_TYPE_STRING, in_Service,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_UINT, in_Address_Type,
          G_TYPE_VALUE, in_Address,
          G_TYPE_UINT, in_Access_Control,
          G_TYPE_VALUE, in_Access_Control_Param,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "OfferStreamTube", iface,
          _tp_cli_channel_type_tubes_invoke_callback_offer_stream_tube,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "OfferStreamTube",
              _tp_cli_channel_type_tubes_collect_callback_offer_stream_tube,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Service,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_VALUE, in_Address,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Tube_ID;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_offer_stream_tube;
static void
_tp_cli_channel_type_tubes_finish_running_offer_stream_tube (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_offer_stream_tube *state = user_data;

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

  if (state->out_Tube_ID != NULL)
    *state->out_Tube_ID = g_value_get_uint (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_offer_stream_tube (TpChannel *proxy,
    gint timeout_ms,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    guint in_Address_Type,
    const GValue *in_Address,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    guint *out_Tube_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_offer_stream_tube state = {
      NULL /* loop */, error,
    out_Tube_ID,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "OfferStreamTube", iface,
      _tp_cli_channel_type_tubes_finish_running_offer_stream_tube,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "OfferStreamTube",
          _tp_cli_channel_type_tubes_collect_callback_offer_stream_tube,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Service,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_VALUE, in_Address,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
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
_tp_cli_channel_type_tubes_collect_callback_accept_d_bus_tube (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Address;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Address,
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
  g_value_take_string (args->values + 0, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_accept_d_bus_tube (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_accept_d_bus_tube callback = (tp_cli_channel_type_tubes_callback_for_accept_d_bus_tube) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_accept_d_bus_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    tp_cli_channel_type_tubes_callback_for_accept_d_bus_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcceptDBusTube",
          G_TYPE_UINT, in_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcceptDBusTube", iface,
          _tp_cli_channel_type_tubes_invoke_callback_accept_d_bus_tube,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcceptDBusTube",
              _tp_cli_channel_type_tubes_collect_callback_accept_d_bus_tube,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_accept_d_bus_tube;
static void
_tp_cli_channel_type_tubes_finish_running_accept_d_bus_tube (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_accept_d_bus_tube *state = user_data;

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

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_accept_d_bus_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    gchar **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_accept_d_bus_tube state = {
      NULL /* loop */, error,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AcceptDBusTube", iface,
      _tp_cli_channel_type_tubes_finish_running_accept_d_bus_tube,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AcceptDBusTube",
          _tp_cli_channel_type_tubes_collect_callback_accept_d_bus_tube,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
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
_tp_cli_channel_type_tubes_collect_callback_accept_stream_tube (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GValue *out_Address = g_new0 (GValue, 1);

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_VALUE, out_Address,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      g_free (out_Address);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_VALUE);
  g_value_take_boxed (args->values + 0, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_accept_stream_tube (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_accept_stream_tube callback = (tp_cli_channel_type_tubes_callback_for_accept_stream_tube) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_accept_stream_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    tp_cli_channel_type_tubes_callback_for_accept_stream_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcceptStreamTube",
          G_TYPE_UINT, in_ID,
          G_TYPE_UINT, in_Address_Type,
          G_TYPE_UINT, in_Access_Control,
          G_TYPE_VALUE, in_Access_Control_Param,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcceptStreamTube", iface,
          _tp_cli_channel_type_tubes_invoke_callback_accept_stream_tube,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcceptStreamTube",
              _tp_cli_channel_type_tubes_collect_callback_accept_stream_tube,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GValue **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_accept_stream_tube;
static void
_tp_cli_channel_type_tubes_finish_running_accept_stream_tube (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_accept_stream_tube *state = user_data;

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

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_accept_stream_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    GValue **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_accept_stream_tube state = {
      NULL /* loop */, error,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "AcceptStreamTube", iface,
      _tp_cli_channel_type_tubes_finish_running_accept_stream_tube,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "AcceptStreamTube",
          _tp_cli_channel_type_tubes_collect_callback_accept_stream_tube,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_UINT, in_Address_Type,
              G_TYPE_UINT, in_Access_Control,
              G_TYPE_VALUE, in_Access_Control_Param,
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
_tp_cli_channel_type_tubes_collect_callback_close_tube (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_close_tube (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_close_tube callback = (tp_cli_channel_type_tubes_callback_for_close_tube) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_close_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    tp_cli_channel_type_tubes_callback_for_close_tube callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CloseTube",
          G_TYPE_UINT, in_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CloseTube", iface,
          _tp_cli_channel_type_tubes_invoke_callback_close_tube,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CloseTube",
              _tp_cli_channel_type_tubes_collect_callback_close_tube,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_close_tube;
static void
_tp_cli_channel_type_tubes_finish_running_close_tube (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_close_tube *state = user_data;

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
tp_cli_channel_type_tubes_run_close_tube (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_close_tube state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "CloseTube", iface,
      _tp_cli_channel_type_tubes_finish_running_close_tube,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "CloseTube",
          _tp_cli_channel_type_tubes_collect_callback_close_tube,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
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
_tp_cli_channel_type_tubes_collect_callback_get_d_bus_tube_address (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Address;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Address,
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
  g_value_take_string (args->values + 0, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_get_d_bus_tube_address (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_get_d_bus_tube_address callback = (tp_cli_channel_type_tubes_callback_for_get_d_bus_tube_address) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_get_d_bus_tube_address (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    tp_cli_channel_type_tubes_callback_for_get_d_bus_tube_address callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetDBusTubeAddress",
          G_TYPE_UINT, in_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetDBusTubeAddress", iface,
          _tp_cli_channel_type_tubes_invoke_callback_get_d_bus_tube_address,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetDBusTubeAddress",
              _tp_cli_channel_type_tubes_collect_callback_get_d_bus_tube_address,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_get_d_bus_tube_address;
static void
_tp_cli_channel_type_tubes_finish_running_get_d_bus_tube_address (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_get_d_bus_tube_address *state = user_data;

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

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_string (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_get_d_bus_tube_address (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    gchar **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_get_d_bus_tube_address state = {
      NULL /* loop */, error,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetDBusTubeAddress", iface,
      _tp_cli_channel_type_tubes_finish_running_get_d_bus_tube_address,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetDBusTubeAddress",
          _tp_cli_channel_type_tubes_collect_callback_get_d_bus_tube_address,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
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
_tp_cli_channel_type_tubes_collect_callback_get_d_bus_names (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_DBus_Names;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))), &out_DBus_Names,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_DBus_Names);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_get_d_bus_names (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_get_d_bus_names callback = (tp_cli_channel_type_tubes_callback_for_get_d_bus_names) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_get_d_bus_names (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    tp_cli_channel_type_tubes_callback_for_get_d_bus_names callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetDBusNames",
          G_TYPE_UINT, in_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetDBusNames", iface,
          _tp_cli_channel_type_tubes_invoke_callback_get_d_bus_names,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetDBusNames",
              _tp_cli_channel_type_tubes_collect_callback_get_d_bus_names,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_DBus_Names;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_get_d_bus_names;
static void
_tp_cli_channel_type_tubes_finish_running_get_d_bus_names (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_get_d_bus_names *state = user_data;

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

  if (state->out_DBus_Names != NULL)
    *state->out_DBus_Names = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_get_d_bus_names (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    GPtrArray **out_DBus_Names,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_get_d_bus_names state = {
      NULL /* loop */, error,
    out_DBus_Names,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetDBusNames", iface,
      _tp_cli_channel_type_tubes_finish_running_get_d_bus_names,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetDBusNames",
          _tp_cli_channel_type_tubes_collect_callback_get_d_bus_names,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
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
_tp_cli_channel_type_tubes_collect_callback_get_stream_tube_socket_address (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  guint out_Address_Type;
  GValue *out_Address = g_new0 (GValue, 1);

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_UINT, &out_Address_Type,
      G_TYPE_VALUE, out_Address,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      g_free (out_Address);
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
  g_value_set_uint (args->values + 0, out_Address_Type);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_VALUE);
  g_value_take_boxed (args->values + 1, out_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_type_tubes_invoke_callback_get_stream_tube_socket_address (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_type_tubes_callback_for_get_stream_tube_socket_address callback = (tp_cli_channel_type_tubes_callback_for_get_stream_tube_socket_address) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannel *) self,
          0,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannel *) self,
      g_value_get_uint (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_type_tubes_call_get_stream_tube_socket_address (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    tp_cli_channel_type_tubes_callback_for_get_stream_tube_socket_address callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetStreamTubeSocketAddress",
          G_TYPE_UINT, in_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetStreamTubeSocketAddress", iface,
          _tp_cli_channel_type_tubes_invoke_callback_get_stream_tube_socket_address,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetStreamTubeSocketAddress",
              _tp_cli_channel_type_tubes_collect_callback_get_stream_tube_socket_address,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    guint *out_Address_Type;
    GValue **out_Address;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_channel_type_tubes_run_state_get_stream_tube_socket_address;
static void
_tp_cli_channel_type_tubes_finish_running_get_stream_tube_socket_address (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_channel_type_tubes_run_state_get_stream_tube_socket_address *state = user_data;

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

  if (state->out_Address_Type != NULL)
    *state->out_Address_Type = g_value_get_uint (args->values + 0);

  if (state->out_Address != NULL)
    *state->out_Address = g_value_dup_boxed (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_channel_type_tubes_run_get_stream_tube_socket_address (TpChannel *proxy,
    gint timeout_ms,
    guint in_ID,
    guint *out_Address_Type,
    GValue **out_Address,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_TYPE_TUBES;
  TpProxyPendingCall *pc;
  _tp_cli_channel_type_tubes_run_state_get_stream_tube_socket_address state = {
      NULL /* loop */, error,
    out_Address_Type,
    out_Address,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CHANNEL (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetStreamTubeSocketAddress", iface,
      _tp_cli_channel_type_tubes_finish_running_get_stream_tube_socket_address,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetStreamTubeSocketAddress",
          _tp_cli_channel_type_tubes_collect_callback_get_stream_tube_socket_address,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_ID,
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
 * tp_cli_channel_add_signals:
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
tp_cli_channel_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CHANNEL)
    tp_cli_add_signals_for_channel (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_CALL_STATE)
    tp_cli_add_signals_for_channel_interface_call_state (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_CHAT_STATE)
    tp_cli_add_signals_for_channel_interface_chat_state (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_CONFERENCE)
    tp_cli_add_signals_for_channel_interface_conference (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF)
    tp_cli_add_signals_for_channel_interface_dtmf (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP)
    tp_cli_add_signals_for_channel_interface_group (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD)
    tp_cli_add_signals_for_channel_interface_hold (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_MEDIA_SIGNALLING)
    tp_cli_add_signals_for_channel_interface_media_signalling (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_MESSAGES)
    tp_cli_add_signals_for_channel_interface_messages (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_PASSWORD)
    tp_cli_add_signals_for_channel_interface_password (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_SASL_AUTHENTICATION)
    tp_cli_add_signals_for_channel_interface_sasl_authentication (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_SMS)
    tp_cli_add_signals_for_channel_interface_sms (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_SERVICE_POINT)
    tp_cli_add_signals_for_channel_interface_service_point (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_INTERFACE_TUBE)
    tp_cli_add_signals_for_channel_interface_tube (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_CALL)
    tp_cli_add_signals_for_channel_type_call (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_CONTACT_SEARCH)
    tp_cli_add_signals_for_channel_type_contact_search (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE)
    tp_cli_add_signals_for_channel_type_dbus_tube (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_FILE_TRANSFER)
    tp_cli_add_signals_for_channel_type_file_transfer (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_ROOM_LIST)
    tp_cli_add_signals_for_channel_type_room_list (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE)
    tp_cli_add_signals_for_channel_type_stream_tube (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_STREAMED_MEDIA)
    tp_cli_add_signals_for_channel_type_streamed_media (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_TEXT)
    tp_cli_add_signals_for_channel_type_text (proxy);
  if (quark == TP_IFACE_QUARK_CHANNEL_TYPE_TUBES)
    tp_cli_add_signals_for_channel_type_tubes (proxy);
}
