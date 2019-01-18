/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_connection_manager (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewConnection",
      G_TYPE_STRING,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_connection_manager_collect_args_of_new_connection (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Bus_Name,
    const gchar *arg_Object_Path,
    const gchar *arg_Protocol,
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
  g_value_set_string (args->values + 0, arg_Bus_Name);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 1, arg_Object_Path);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Protocol);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_connection_manager_invoke_callback_for_new_connection (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_manager_signal_callback_new_connection callback =
      (tp_cli_connection_manager_signal_callback_new_connection) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_string (args->values + 0),
      g_value_get_boxed (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_connection_manager_connect_to_new_connection (TpConnectionManager *proxy,
    tp_cli_connection_manager_signal_callback_new_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      G_TYPE_STRING,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CONNECTION_MANAGER, "NewConnection",
      expected_types,
      G_CALLBACK (_tp_cli_connection_manager_collect_args_of_new_connection),
      _tp_cli_connection_manager_invoke_callback_for_new_connection,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_connection_manager_collect_callback_get_parameters (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Parameters;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_VALUE, G_TYPE_INVALID)))), &out_Parameters,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_VALUE, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Parameters);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_manager_invoke_callback_get_parameters (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_manager_callback_for_get_parameters callback = (tp_cli_connection_manager_callback_for_get_parameters) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnectionManager *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnectionManager *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_manager_call_get_parameters (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    tp_cli_connection_manager_callback_for_get_parameters callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "GetParameters",
          G_TYPE_STRING, in_Protocol,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetParameters", iface,
          _tp_cli_connection_manager_invoke_callback_get_parameters,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetParameters",
              _tp_cli_connection_manager_collect_callback_get_parameters,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Protocol,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    GPtrArray **out_Parameters;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_manager_run_state_get_parameters;
static void
_tp_cli_connection_manager_finish_running_get_parameters (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_manager_run_state_get_parameters *state = user_data;

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

  if (state->out_Parameters != NULL)
    *state->out_Parameters = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_manager_run_get_parameters (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GPtrArray **out_Parameters,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  TpProxyPendingCall *pc;
  _tp_cli_connection_manager_run_state_get_parameters state = {
      NULL /* loop */, error,
    out_Parameters,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "GetParameters", iface,
      _tp_cli_connection_manager_finish_running_get_parameters,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "GetParameters",
          _tp_cli_connection_manager_collect_callback_get_parameters,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Protocol,
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
_tp_cli_connection_manager_collect_callback_list_protocols (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar **out_Protocols;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRV, &out_Protocols,
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
  g_value_take_boxed (args->values + 0, out_Protocols);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_manager_invoke_callback_list_protocols (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_manager_callback_for_list_protocols callback = (tp_cli_connection_manager_callback_for_list_protocols) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnectionManager *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnectionManager *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_manager_call_list_protocols (TpConnectionManager *proxy,
    gint timeout_ms,
    tp_cli_connection_manager_callback_for_list_protocols callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ListProtocols",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ListProtocols", iface,
          _tp_cli_connection_manager_invoke_callback_list_protocols,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ListProtocols",
              _tp_cli_connection_manager_collect_callback_list_protocols,
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
    gchar ***out_Protocols;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_manager_run_state_list_protocols;
static void
_tp_cli_connection_manager_finish_running_list_protocols (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_manager_run_state_list_protocols *state = user_data;

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

  if (state->out_Protocols != NULL)
    *state->out_Protocols = g_value_dup_boxed (args->values + 0);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_manager_run_list_protocols (TpConnectionManager *proxy,
    gint timeout_ms,
    gchar ***out_Protocols,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  TpProxyPendingCall *pc;
  _tp_cli_connection_manager_run_state_list_protocols state = {
      NULL /* loop */, error,
    out_Protocols,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "ListProtocols", iface,
      _tp_cli_connection_manager_finish_running_list_protocols,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "ListProtocols",
          _tp_cli_connection_manager_collect_callback_list_protocols,
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
_tp_cli_connection_manager_collect_callback_request_connection (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Bus_Name;
  gchar *out_Object_Path;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Bus_Name,
      DBUS_TYPE_G_OBJECT_PATH, &out_Object_Path,
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
  g_value_init (args->values + 0, G_TYPE_STRING);
  g_value_take_string (args->values + 0, out_Bus_Name);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, DBUS_TYPE_G_OBJECT_PATH);
  g_value_take_boxed (args->values + 1, out_Object_Path);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_connection_manager_invoke_callback_request_connection (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_connection_manager_callback_for_request_connection callback = (tp_cli_connection_manager_callback_for_request_connection) generic_callback;

  if (error != NULL)
    {
      callback ((TpConnectionManager *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpConnectionManager *) self,
      g_value_get_string (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_connection_manager_call_request_connection (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    tp_cli_connection_manager_callback_for_request_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RequestConnection",
          G_TYPE_STRING, in_Protocol,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RequestConnection", iface,
          _tp_cli_connection_manager_invoke_callback_request_connection,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RequestConnection",
              _tp_cli_connection_manager_collect_callback_request_connection,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Protocol,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    gchar **out_Bus_Name;
    gchar **out_Object_Path;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_connection_manager_run_state_request_connection;
static void
_tp_cli_connection_manager_finish_running_request_connection (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_connection_manager_run_state_request_connection *state = user_data;

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

  if (state->out_Bus_Name != NULL)
    *state->out_Bus_Name = g_value_dup_string (args->values + 0);

  if (state->out_Object_Path != NULL)
    *state->out_Object_Path = g_value_dup_boxed (args->values + 1);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

gboolean
tp_cli_connection_manager_run_request_connection (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    gchar **out_Bus_Name,
    gchar **out_Object_Path,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_CONNECTION_MANAGER;
  TpProxyPendingCall *pc;
  _tp_cli_connection_manager_run_state_request_connection state = {
      NULL /* loop */, error,
    out_Bus_Name,
    out_Object_Path,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_CONNECTION_MANAGER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "RequestConnection", iface,
      _tp_cli_connection_manager_finish_running_request_connection,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "RequestConnection",
          _tp_cli_connection_manager_collect_callback_request_connection,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Protocol,
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


/*
 * tp_cli_connection_manager_add_signals:
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
tp_cli_connection_manager_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CONNECTION_MANAGER)
    tp_cli_add_signals_for_connection_manager (proxy);
}
