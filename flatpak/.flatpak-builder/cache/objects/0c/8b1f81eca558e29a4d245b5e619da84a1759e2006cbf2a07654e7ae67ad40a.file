/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_call_content (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "StreamsAdded",
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StreamsRemoved",
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID);
}


static void
_tp_cli_call_content_collect_args_of_streams_added (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Streams,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));
  g_value_set_boxed (args->values + 0, arg_Streams);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_invoke_callback_for_streams_added (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_signal_callback_streams_added callback =
      (tp_cli_call_content_signal_callback_streams_added) generic_callback;

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
tp_cli_call_content_connect_to_streams_added (TpCallContent *proxy,
    tp_cli_call_content_signal_callback_streams_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT, "StreamsAdded",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_collect_args_of_streams_added),
      _tp_cli_call_content_invoke_callback_for_streams_added,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_collect_args_of_streams_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Streams,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));
  g_value_set_boxed (args->values + 0, arg_Streams);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 1, arg_Reason);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_invoke_callback_for_streams_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_signal_callback_streams_removed callback =
      (tp_cli_call_content_signal_callback_streams_removed) generic_callback;

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
tp_cli_call_content_connect_to_streams_removed (TpCallContent *proxy,
    tp_cli_call_content_signal_callback_streams_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT, "StreamsRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_collect_args_of_streams_removed),
      _tp_cli_call_content_invoke_callback_for_streams_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_collect_callback_remove (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_invoke_callback_remove (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_callback_for_remove callback = (tp_cli_call_content_callback_for_remove) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_call_remove (TpCallContent *proxy,
    gint timeout_ms,
    tp_cli_call_content_callback_for_remove callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
          _tp_cli_call_content_invoke_callback_remove,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Remove",
              _tp_cli_call_content_collect_callback_remove,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_audio_control_collect_callback_report_input_volume (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_audio_control_invoke_callback_report_input_volume (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_audio_control_callback_for_report_input_volume callback = (tp_cli_call_content_interface_audio_control_callback_for_report_input_volume) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_audio_control_call_report_input_volume (TpCallContent *proxy,
    gint timeout_ms,
    gint in_Volume,
    tp_cli_call_content_interface_audio_control_callback_for_report_input_volume callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_AUDIO_CONTROL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReportInputVolume",
          G_TYPE_INT, in_Volume,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReportInputVolume", iface,
          _tp_cli_call_content_interface_audio_control_invoke_callback_report_input_volume,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReportInputVolume",
              _tp_cli_call_content_interface_audio_control_collect_callback_report_input_volume,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INT, in_Volume,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_audio_control_collect_callback_report_output_volume (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_audio_control_invoke_callback_report_output_volume (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_audio_control_callback_for_report_output_volume callback = (tp_cli_call_content_interface_audio_control_callback_for_report_output_volume) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_audio_control_call_report_output_volume (TpCallContent *proxy,
    gint timeout_ms,
    gint in_Volume,
    tp_cli_call_content_interface_audio_control_callback_for_report_output_volume callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_AUDIO_CONTROL;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ReportOutputVolume",
          G_TYPE_INT, in_Volume,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ReportOutputVolume", iface,
          _tp_cli_call_content_interface_audio_control_invoke_callback_report_output_volume,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ReportOutputVolume",
              _tp_cli_call_content_interface_audio_control_collect_callback_report_output_volume,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INT, in_Volume,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_call_content_interface_dtmf (DBusGProxy *proxy)
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
_tp_cli_call_content_interface_dtmf_collect_args_of_tones_deferred (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_call_content_interface_dtmf_invoke_callback_for_tones_deferred (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_signal_callback_tones_deferred callback =
      (tp_cli_call_content_interface_dtmf_signal_callback_tones_deferred) generic_callback;

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
tp_cli_call_content_interface_dtmf_connect_to_tones_deferred (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_tones_deferred callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF, "TonesDeferred",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_dtmf_collect_args_of_tones_deferred),
      _tp_cli_call_content_interface_dtmf_invoke_callback_for_tones_deferred,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_dtmf_collect_args_of_sending_tones (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_call_content_interface_dtmf_invoke_callback_for_sending_tones (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_signal_callback_sending_tones callback =
      (tp_cli_call_content_interface_dtmf_signal_callback_sending_tones) generic_callback;

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
tp_cli_call_content_interface_dtmf_connect_to_sending_tones (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_sending_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF, "SendingTones",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_dtmf_collect_args_of_sending_tones),
      _tp_cli_call_content_interface_dtmf_invoke_callback_for_sending_tones,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_dtmf_collect_args_of_stopped_tones (DBusGProxy *proxy G_GNUC_UNUSED,
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
_tp_cli_call_content_interface_dtmf_invoke_callback_for_stopped_tones (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_signal_callback_stopped_tones callback =
      (tp_cli_call_content_interface_dtmf_signal_callback_stopped_tones) generic_callback;

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
tp_cli_call_content_interface_dtmf_connect_to_stopped_tones (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_stopped_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF, "StoppedTones",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_dtmf_collect_args_of_stopped_tones),
      _tp_cli_call_content_interface_dtmf_invoke_callback_for_stopped_tones,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_dtmf_collect_callback_start_tone (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_dtmf_invoke_callback_start_tone (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_callback_for_start_tone callback = (tp_cli_call_content_interface_dtmf_callback_for_start_tone) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_dtmf_call_start_tone (TpCallContent *proxy,
    gint timeout_ms,
    guchar in_Event,
    tp_cli_call_content_interface_dtmf_callback_for_start_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
          G_TYPE_UCHAR, in_Event,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StartTone", iface,
          _tp_cli_call_content_interface_dtmf_invoke_callback_start_tone,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StartTone",
              _tp_cli_call_content_interface_dtmf_collect_callback_start_tone,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UCHAR, in_Event,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_dtmf_collect_callback_stop_tone (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_dtmf_invoke_callback_stop_tone (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_callback_for_stop_tone callback = (tp_cli_call_content_interface_dtmf_callback_for_stop_tone) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_dtmf_call_stop_tone (TpCallContent *proxy,
    gint timeout_ms,
    tp_cli_call_content_interface_dtmf_callback_for_stop_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StopTone", iface,
          _tp_cli_call_content_interface_dtmf_invoke_callback_stop_tone,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StopTone",
              _tp_cli_call_content_interface_dtmf_collect_callback_stop_tone,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_dtmf_collect_callback_multiple_tones (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_dtmf_invoke_callback_multiple_tones (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_dtmf_callback_for_multiple_tones callback = (tp_cli_call_content_interface_dtmf_callback_for_multiple_tones) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_dtmf_call_multiple_tones (TpCallContent *proxy,
    gint timeout_ms,
    const gchar *in_Tones,
    tp_cli_call_content_interface_dtmf_callback_for_multiple_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
          _tp_cli_call_content_interface_dtmf_invoke_callback_multiple_tones,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "MultipleTones",
              _tp_cli_call_content_interface_dtmf_collect_callback_multiple_tones,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Tones,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_call_content_interface_media (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewMediaDescriptionOffer",
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MediaDescriptionOfferDone",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "LocalMediaDescriptionChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "RemoteMediaDescriptionsChanged",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MediaDescriptionsRemoved",
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "DTMFChangeRequested",
      G_TYPE_UCHAR,
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_call_content_interface_media_collect_args_of_new_media_description_offer (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Media_Description,
    GHashTable *arg_Properties,
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
  g_value_set_boxed (args->values + 0, arg_Media_Description);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 1, arg_Properties);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_for_new_media_description_offer (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_new_media_description_offer callback =
      (tp_cli_call_content_interface_media_signal_callback_new_media_description_offer) generic_callback;

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
tp_cli_call_content_interface_media_connect_to_new_media_description_offer (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_new_media_description_offer callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "NewMediaDescriptionOffer",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_media_collect_args_of_new_media_description_offer),
      _tp_cli_call_content_interface_media_invoke_callback_for_new_media_description_offer,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_invoke_callback_for_media_description_offer_done (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_media_description_offer_done callback =
      (tp_cli_call_content_interface_media_signal_callback_media_description_offer_done) generic_callback;

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
tp_cli_call_content_interface_media_connect_to_media_description_offer_done (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_media_description_offer_done callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "MediaDescriptionOfferDone",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_call_content_interface_media_invoke_callback_for_media_description_offer_done,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_collect_args_of_local_media_description_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Updated_Media_Description,
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
  g_value_set_boxed (args->values + 0, arg_Updated_Media_Description);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_for_local_media_description_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_local_media_description_changed callback =
      (tp_cli_call_content_interface_media_signal_callback_local_media_description_changed) generic_callback;

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
tp_cli_call_content_interface_media_connect_to_local_media_description_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_local_media_description_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "LocalMediaDescriptionChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_media_collect_args_of_local_media_description_changed),
      _tp_cli_call_content_interface_media_invoke_callback_for_local_media_description_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_collect_args_of_remote_media_descriptions_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Updated_Media_Descriptions,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));
  g_value_set_boxed (args->values + 0, arg_Updated_Media_Descriptions);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_for_remote_media_descriptions_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_remote_media_descriptions_changed callback =
      (tp_cli_call_content_interface_media_signal_callback_remote_media_descriptions_changed) generic_callback;

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
tp_cli_call_content_interface_media_connect_to_remote_media_descriptions_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_remote_media_descriptions_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "RemoteMediaDescriptionsChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_media_collect_args_of_remote_media_descriptions_changed),
      _tp_cli_call_content_interface_media_invoke_callback_for_remote_media_descriptions_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_collect_args_of_media_descriptions_removed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GArray *arg_Removed_Media_Descriptions,
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
  g_value_set_boxed (args->values + 0, arg_Removed_Media_Descriptions);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_for_media_descriptions_removed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_media_descriptions_removed callback =
      (tp_cli_call_content_interface_media_signal_callback_media_descriptions_removed) generic_callback;

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
tp_cli_call_content_interface_media_connect_to_media_descriptions_removed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_media_descriptions_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "MediaDescriptionsRemoved",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_media_collect_args_of_media_descriptions_removed),
      _tp_cli_call_content_interface_media_invoke_callback_for_media_descriptions_removed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_collect_args_of_dtmf_change_requested (DBusGProxy *proxy G_GNUC_UNUSED,
    guchar arg_Event,
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
  g_value_init (args->values + 0, G_TYPE_UCHAR);
  g_value_set_uchar (args->values + 0, arg_Event);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_UINT);
  g_value_set_uint (args->values + 1, arg_State);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_for_dtmf_change_requested (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_signal_callback_dtmf_change_requested callback =
      (tp_cli_call_content_interface_media_signal_callback_dtmf_change_requested) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uchar (args->values + 0),
      g_value_get_uint (args->values + 1),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_call_content_interface_media_connect_to_dtmf_change_requested (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_dtmf_change_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UCHAR,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA, "DTMFChangeRequested",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_media_collect_args_of_dtmf_change_requested),
      _tp_cli_call_content_interface_media_invoke_callback_for_dtmf_change_requested,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_media_collect_callback_update_local_media_description (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_update_local_media_description (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_callback_for_update_local_media_description callback = (tp_cli_call_content_interface_media_callback_for_update_local_media_description) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_media_call_update_local_media_description (TpCallContent *proxy,
    gint timeout_ms,
    GHashTable *in_MediaDescription,
    tp_cli_call_content_interface_media_callback_for_update_local_media_description callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UpdateLocalMediaDescription",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_MediaDescription,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UpdateLocalMediaDescription", iface,
          _tp_cli_call_content_interface_media_invoke_callback_update_local_media_description,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UpdateLocalMediaDescription",
              _tp_cli_call_content_interface_media_collect_callback_update_local_media_description,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_MediaDescription,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_media_collect_callback_acknowledge_dtmf_change (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_acknowledge_dtmf_change (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_callback_for_acknowledge_dtmf_change callback = (tp_cli_call_content_interface_media_callback_for_acknowledge_dtmf_change) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_media_call_acknowledge_dtmf_change (TpCallContent *proxy,
    gint timeout_ms,
    guchar in_Event,
    guint in_State,
    tp_cli_call_content_interface_media_callback_for_acknowledge_dtmf_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AcknowledgeDTMFChange",
          G_TYPE_UCHAR, in_Event,
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AcknowledgeDTMFChange", iface,
          _tp_cli_call_content_interface_media_invoke_callback_acknowledge_dtmf_change,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AcknowledgeDTMFChange",
              _tp_cli_call_content_interface_media_collect_callback_acknowledge_dtmf_change,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UCHAR, in_Event,
              G_TYPE_UINT, in_State,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_call_content_interface_media_collect_callback_fail (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_call_content_interface_media_invoke_callback_fail (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_media_callback_for_fail callback = (tp_cli_call_content_interface_media_callback_for_fail) generic_callback;

  if (error != NULL)
    {
      callback ((TpCallContent *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpCallContent *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_call_content_interface_media_call_fail (TpCallContent *proxy,
    gint timeout_ms,
    const GValueArray *in_Reason,
    tp_cli_call_content_interface_media_callback_for_fail callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
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
          _tp_cli_call_content_interface_media_invoke_callback_fail,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Fail",
              _tp_cli_call_content_interface_media_collect_callback_fail,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Reason,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_call_content_interface_video_control (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "KeyFrameRequested",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "VideoResolutionChanged",
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "BitrateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "FramerateChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "MTUChanged",
      G_TYPE_UINT,
      G_TYPE_INVALID);
}


static void
_tp_cli_call_content_interface_video_control_invoke_callback_for_key_frame_requested (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_video_control_signal_callback_key_frame_requested callback =
      (tp_cli_call_content_interface_video_control_signal_callback_key_frame_requested) generic_callback;

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
tp_cli_call_content_interface_video_control_connect_to_key_frame_requested (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_key_frame_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, "KeyFrameRequested",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_call_content_interface_video_control_invoke_callback_for_key_frame_requested,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_video_control_collect_args_of_video_resolution_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    const GValueArray *arg_NewResolution,
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
  g_value_init (args->values + 0, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)));
  g_value_set_boxed (args->values + 0, arg_NewResolution);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_video_control_invoke_callback_for_video_resolution_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_video_control_signal_callback_video_resolution_changed callback =
      (tp_cli_call_content_interface_video_control_signal_callback_video_resolution_changed) generic_callback;

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
tp_cli_call_content_interface_video_control_connect_to_video_resolution_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_video_resolution_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, "VideoResolutionChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_video_control_collect_args_of_video_resolution_changed),
      _tp_cli_call_content_interface_video_control_invoke_callback_for_video_resolution_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_video_control_collect_args_of_bitrate_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_NewBitrate,
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
  g_value_set_uint (args->values + 0, arg_NewBitrate);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_video_control_invoke_callback_for_bitrate_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_video_control_signal_callback_bitrate_changed callback =
      (tp_cli_call_content_interface_video_control_signal_callback_bitrate_changed) generic_callback;

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
tp_cli_call_content_interface_video_control_connect_to_bitrate_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_bitrate_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, "BitrateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_video_control_collect_args_of_bitrate_changed),
      _tp_cli_call_content_interface_video_control_invoke_callback_for_bitrate_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_video_control_collect_args_of_framerate_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_NewFramerate,
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
  g_value_set_uint (args->values + 0, arg_NewFramerate);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_video_control_invoke_callback_for_framerate_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_video_control_signal_callback_framerate_changed callback =
      (tp_cli_call_content_interface_video_control_signal_callback_framerate_changed) generic_callback;

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
tp_cli_call_content_interface_video_control_connect_to_framerate_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_framerate_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, "FramerateChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_video_control_collect_args_of_framerate_changed),
      _tp_cli_call_content_interface_video_control_invoke_callback_for_framerate_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_call_content_interface_video_control_collect_args_of_mtu_changed (DBusGProxy *proxy G_GNUC_UNUSED,
    guint arg_NewMTU,
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
  g_value_set_uint (args->values + 0, arg_NewMTU);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_call_content_interface_video_control_invoke_callback_for_mtu_changed (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_call_content_interface_video_control_signal_callback_mtu_changed callback =
      (tp_cli_call_content_interface_video_control_signal_callback_mtu_changed) generic_callback;

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
tp_cli_call_content_interface_video_control_connect_to_mtu_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_mtu_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CALL_CONTENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, "MTUChanged",
      expected_types,
      G_CALLBACK (_tp_cli_call_content_interface_video_control_collect_args_of_mtu_changed),
      _tp_cli_call_content_interface_video_control_invoke_callback_for_mtu_changed,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

/*
 * tp_cli_call_content_add_signals:
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
tp_cli_call_content_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CALL_CONTENT)
    tp_cli_add_signals_for_call_content (proxy);
  if (quark == TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF)
    tp_cli_add_signals_for_call_content_interface_dtmf (proxy);
  if (quark == TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA)
    tp_cli_add_signals_for_call_content_interface_media (proxy);
  if (quark == TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_VIDEO_CONTROL)
    tp_cli_add_signals_for_call_content_interface_video_control (proxy);
}
