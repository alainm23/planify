/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_media_stream_handler (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "AddRemoteCandidate",
      G_TYPE_STRING,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "Close",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "RemoveRemoteCandidate",
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetActiveCandidatePair",
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetRemoteCandidateList",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetRemoteCodecs",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetStreamPlaying",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetStreamSending",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StartTelephonyEvent",
      G_TYPE_UCHAR,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StartNamedTelephonyEvent",
      G_TYPE_UCHAR,
      G_TYPE_UINT,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StartSoundTelephonyEvent",
      G_TYPE_UCHAR,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "StopTelephonyEvent",
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetStreamHeld",
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetRemoteFeedbackMessages",
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "SetRemoteHeaderExtensions",
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID);
}


static void
_tp_cli_media_stream_handler_collect_args_of_add_remote_candidate (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Candidate_ID,
    const GPtrArray *arg_Transports,
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
  g_value_set_string (args->values + 0, arg_Candidate_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 1, arg_Transports);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_add_remote_candidate (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_add_remote_candidate callback =
      (tp_cli_media_stream_handler_signal_callback_add_remote_candidate) generic_callback;

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
tp_cli_media_stream_handler_connect_to_add_remote_candidate (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_add_remote_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "AddRemoteCandidate",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_add_remote_candidate),
      _tp_cli_media_stream_handler_invoke_callback_for_add_remote_candidate,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_invoke_callback_for_close (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_close callback =
      (tp_cli_media_stream_handler_signal_callback_close) generic_callback;

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
tp_cli_media_stream_handler_connect_to_close (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_close callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "Close",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_media_stream_handler_invoke_callback_for_close,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_remove_remote_candidate (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Candidate_ID,
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
  g_value_set_string (args->values + 0, arg_Candidate_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_remove_remote_candidate (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_remove_remote_candidate callback =
      (tp_cli_media_stream_handler_signal_callback_remove_remote_candidate) generic_callback;

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
tp_cli_media_stream_handler_connect_to_remove_remote_candidate (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_remove_remote_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "RemoveRemoteCandidate",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_remove_remote_candidate),
      _tp_cli_media_stream_handler_invoke_callback_for_remove_remote_candidate,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_active_candidate_pair (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Native_Candidate_ID,
    const gchar *arg_Remote_Candidate_ID,
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
  g_value_set_string (args->values + 0, arg_Native_Candidate_ID);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Remote_Candidate_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_active_candidate_pair (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_active_candidate_pair callback =
      (tp_cli_media_stream_handler_signal_callback_set_active_candidate_pair) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_active_candidate_pair (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_active_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetActiveCandidatePair",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_active_candidate_pair),
      _tp_cli_media_stream_handler_invoke_callback_for_set_active_candidate_pair,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_remote_candidate_list (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Remote_Candidates,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Remote_Candidates);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_remote_candidate_list (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_remote_candidate_list callback =
      (tp_cli_media_stream_handler_signal_callback_set_remote_candidate_list) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_remote_candidate_list (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_candidate_list callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetRemoteCandidateList",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_remote_candidate_list),
      _tp_cli_media_stream_handler_invoke_callback_for_set_remote_candidate_list,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_remote_codecs (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Codecs,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Codecs);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_remote_codecs (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_remote_codecs callback =
      (tp_cli_media_stream_handler_signal_callback_set_remote_codecs) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_remote_codecs (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetRemoteCodecs",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_remote_codecs),
      _tp_cli_media_stream_handler_invoke_callback_for_set_remote_codecs,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_stream_playing (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Playing,
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
  g_value_set_boolean (args->values + 0, arg_Playing);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_stream_playing (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_stream_playing callback =
      (tp_cli_media_stream_handler_signal_callback_set_stream_playing) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_stream_playing (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_playing callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetStreamPlaying",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_stream_playing),
      _tp_cli_media_stream_handler_invoke_callback_for_set_stream_playing,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_stream_sending (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Sending,
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
  g_value_set_boolean (args->values + 0, arg_Sending);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_stream_sending (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_stream_sending callback =
      (tp_cli_media_stream_handler_signal_callback_set_stream_sending) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_stream_sending (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_sending callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetStreamSending",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_stream_sending),
      _tp_cli_media_stream_handler_invoke_callback_for_set_stream_sending,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_start_telephony_event (DBusGProxy *proxy G_GNUC_UNUSED,
    guchar arg_Event,
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
  g_value_init (args->values + 0, G_TYPE_UCHAR);
  g_value_set_uchar (args->values + 0, arg_Event);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_start_telephony_event (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_start_telephony_event callback =
      (tp_cli_media_stream_handler_signal_callback_start_telephony_event) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uchar (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_media_stream_handler_connect_to_start_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UCHAR,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "StartTelephonyEvent",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_start_telephony_event),
      _tp_cli_media_stream_handler_invoke_callback_for_start_telephony_event,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_start_named_telephony_event (DBusGProxy *proxy G_GNUC_UNUSED,
    guchar arg_Event,
    guint arg_Codec_ID,
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
  g_value_set_uint (args->values + 1, arg_Codec_ID);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_start_named_telephony_event (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_start_named_telephony_event callback =
      (tp_cli_media_stream_handler_signal_callback_start_named_telephony_event) generic_callback;

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
tp_cli_media_stream_handler_connect_to_start_named_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_named_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      G_TYPE_UCHAR,
      G_TYPE_UINT,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "StartNamedTelephonyEvent",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_start_named_telephony_event),
      _tp_cli_media_stream_handler_invoke_callback_for_start_named_telephony_event,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_start_sound_telephony_event (DBusGProxy *proxy G_GNUC_UNUSED,
    guchar arg_Event,
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
  g_value_init (args->values + 0, G_TYPE_UCHAR);
  g_value_set_uchar (args->values + 0, arg_Event);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_start_sound_telephony_event (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_start_sound_telephony_event callback =
      (tp_cli_media_stream_handler_signal_callback_start_sound_telephony_event) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_uchar (args->values + 0),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_media_stream_handler_connect_to_start_sound_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_sound_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_UCHAR,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "StartSoundTelephonyEvent",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_start_sound_telephony_event),
      _tp_cli_media_stream_handler_invoke_callback_for_start_sound_telephony_event,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_invoke_callback_for_stop_telephony_event (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_stop_telephony_event callback =
      (tp_cli_media_stream_handler_signal_callback_stop_telephony_event) generic_callback;

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
tp_cli_media_stream_handler_connect_to_stop_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_stop_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "StopTelephonyEvent",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_media_stream_handler_invoke_callback_for_stop_telephony_event,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_stream_held (DBusGProxy *proxy G_GNUC_UNUSED,
    gboolean arg_Held,
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
  g_value_set_boolean (args->values + 0, arg_Held);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_stream_held (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_stream_held callback =
      (tp_cli_media_stream_handler_signal_callback_set_stream_held) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_stream_held (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_held callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      G_TYPE_BOOLEAN,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetStreamHeld",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_stream_held),
      _tp_cli_media_stream_handler_invoke_callback_for_set_stream_held,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_remote_feedback_messages (DBusGProxy *proxy G_GNUC_UNUSED,
    GHashTable *arg_Messages,
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
  g_value_init (args->values + 0, (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Messages);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_remote_feedback_messages (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_remote_feedback_messages callback =
      (tp_cli_media_stream_handler_signal_callback_set_remote_feedback_messages) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_remote_feedback_messages (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_feedback_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetRemoteFeedbackMessages",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_remote_feedback_messages),
      _tp_cli_media_stream_handler_invoke_callback_for_set_remote_feedback_messages,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_args_of_set_remote_header_extensions (DBusGProxy *proxy G_GNUC_UNUSED,
    const GPtrArray *arg_Header_Extensions,
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
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_set_boxed (args->values + 0, arg_Header_Extensions);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_media_stream_handler_invoke_callback_for_set_remote_header_extensions (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_signal_callback_set_remote_header_extensions callback =
      (tp_cli_media_stream_handler_signal_callback_set_remote_header_extensions) generic_callback;

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
tp_cli_media_stream_handler_connect_to_set_remote_header_extensions (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_header_extensions callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_MEDIA_STREAM_HANDLER, "SetRemoteHeaderExtensions",
      expected_types,
      G_CALLBACK (_tp_cli_media_stream_handler_collect_args_of_set_remote_header_extensions),
      _tp_cli_media_stream_handler_invoke_callback_for_set_remote_header_extensions,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_media_stream_handler_collect_callback_codec_choice (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_codec_choice (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_codec_choice callback = (tp_cli_media_stream_handler_callback_for_codec_choice) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_codec_choice (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Codec_ID,
    tp_cli_media_stream_handler_callback_for_codec_choice callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CodecChoice",
          G_TYPE_UINT, in_Codec_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CodecChoice", iface,
          _tp_cli_media_stream_handler_invoke_callback_codec_choice,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CodecChoice",
              _tp_cli_media_stream_handler_collect_callback_codec_choice,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_UINT, in_Codec_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_codec_choice;
static void
_tp_cli_media_stream_handler_finish_running_codec_choice (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_codec_choice *state = user_data;

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
tp_cli_media_stream_handler_run_codec_choice (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Codec_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_codec_choice state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "CodecChoice", iface,
      _tp_cli_media_stream_handler_finish_running_codec_choice,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "CodecChoice",
          _tp_cli_media_stream_handler_collect_callback_codec_choice,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_UINT, in_Codec_ID,
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
_tp_cli_media_stream_handler_collect_callback_error (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_error (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_error callback = (tp_cli_media_stream_handler_callback_for_error) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_error (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    tp_cli_media_stream_handler_callback_for_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
          _tp_cli_media_stream_handler_invoke_callback_error,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Error",
              _tp_cli_media_stream_handler_collect_callback_error,
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
} _tp_cli_media_stream_handler_run_state_error;
static void
_tp_cli_media_stream_handler_finish_running_error (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_error *state = user_data;

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
tp_cli_media_stream_handler_run_error (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_error state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Error", iface,
      _tp_cli_media_stream_handler_finish_running_error,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Error",
          _tp_cli_media_stream_handler_collect_callback_error,
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
_tp_cli_media_stream_handler_collect_callback_native_candidates_prepared (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_native_candidates_prepared (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_native_candidates_prepared callback = (tp_cli_media_stream_handler_callback_for_native_candidates_prepared) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_native_candidates_prepared (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    tp_cli_media_stream_handler_callback_for_native_candidates_prepared callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "NativeCandidatesPrepared",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NativeCandidatesPrepared", iface,
          _tp_cli_media_stream_handler_invoke_callback_native_candidates_prepared,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NativeCandidatesPrepared",
              _tp_cli_media_stream_handler_collect_callback_native_candidates_prepared,
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
} _tp_cli_media_stream_handler_run_state_native_candidates_prepared;
static void
_tp_cli_media_stream_handler_finish_running_native_candidates_prepared (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_native_candidates_prepared *state = user_data;

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
tp_cli_media_stream_handler_run_native_candidates_prepared (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_native_candidates_prepared state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "NativeCandidatesPrepared", iface,
      _tp_cli_media_stream_handler_finish_running_native_candidates_prepared,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "NativeCandidatesPrepared",
          _tp_cli_media_stream_handler_collect_callback_native_candidates_prepared,
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
_tp_cli_media_stream_handler_collect_callback_new_active_candidate_pair (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_new_active_candidate_pair (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_new_active_candidate_pair callback = (tp_cli_media_stream_handler_callback_for_new_active_candidate_pair) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_new_active_candidate_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const gchar *in_Remote_Candidate_ID,
    tp_cli_media_stream_handler_callback_for_new_active_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "NewActiveCandidatePair",
          G_TYPE_STRING, in_Native_Candidate_ID,
          G_TYPE_STRING, in_Remote_Candidate_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NewActiveCandidatePair", iface,
          _tp_cli_media_stream_handler_invoke_callback_new_active_candidate_pair,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NewActiveCandidatePair",
              _tp_cli_media_stream_handler_collect_callback_new_active_candidate_pair,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Native_Candidate_ID,
              G_TYPE_STRING, in_Remote_Candidate_ID,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_new_active_candidate_pair;
static void
_tp_cli_media_stream_handler_finish_running_new_active_candidate_pair (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_new_active_candidate_pair *state = user_data;

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
tp_cli_media_stream_handler_run_new_active_candidate_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const gchar *in_Remote_Candidate_ID,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_new_active_candidate_pair state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "NewActiveCandidatePair", iface,
      _tp_cli_media_stream_handler_finish_running_new_active_candidate_pair,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "NewActiveCandidatePair",
          _tp_cli_media_stream_handler_collect_callback_new_active_candidate_pair,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Native_Candidate_ID,
              G_TYPE_STRING, in_Remote_Candidate_ID,
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
_tp_cli_media_stream_handler_collect_callback_new_active_transport_pair (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_new_active_transport_pair (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_new_active_transport_pair callback = (tp_cli_media_stream_handler_callback_for_new_active_transport_pair) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_new_active_transport_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const GValueArray *in_Native_Transport,
    const gchar *in_Remote_Candidate_ID,
    const GValueArray *in_Remote_Transport,
    tp_cli_media_stream_handler_callback_for_new_active_transport_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "NewActiveTransportPair",
          G_TYPE_STRING, in_Native_Candidate_ID,
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Native_Transport,
          G_TYPE_STRING, in_Remote_Candidate_ID,
          (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Remote_Transport,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NewActiveTransportPair", iface,
          _tp_cli_media_stream_handler_invoke_callback_new_active_transport_pair,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NewActiveTransportPair",
              _tp_cli_media_stream_handler_collect_callback_new_active_transport_pair,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Native_Candidate_ID,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Native_Transport,
              G_TYPE_STRING, in_Remote_Candidate_ID,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Remote_Transport,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_new_active_transport_pair;
static void
_tp_cli_media_stream_handler_finish_running_new_active_transport_pair (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_new_active_transport_pair *state = user_data;

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
tp_cli_media_stream_handler_run_new_active_transport_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const GValueArray *in_Native_Transport,
    const gchar *in_Remote_Candidate_ID,
    const GValueArray *in_Remote_Transport,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_new_active_transport_pair state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "NewActiveTransportPair", iface,
      _tp_cli_media_stream_handler_finish_running_new_active_transport_pair,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "NewActiveTransportPair",
          _tp_cli_media_stream_handler_collect_callback_new_active_transport_pair,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Native_Candidate_ID,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Native_Transport,
              G_TYPE_STRING, in_Remote_Candidate_ID,
              (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)), in_Remote_Transport,
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
_tp_cli_media_stream_handler_collect_callback_new_native_candidate (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_new_native_candidate (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_new_native_candidate callback = (tp_cli_media_stream_handler_callback_for_new_native_candidate) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_new_native_candidate (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Candidate_ID,
    const GPtrArray *in_Transports,
    tp_cli_media_stream_handler_callback_for_new_native_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "NewNativeCandidate",
          G_TYPE_STRING, in_Candidate_ID,
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Transports,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NewNativeCandidate", iface,
          _tp_cli_media_stream_handler_invoke_callback_new_native_candidate,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NewNativeCandidate",
              _tp_cli_media_stream_handler_collect_callback_new_native_candidate,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Candidate_ID,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Transports,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_new_native_candidate;
static void
_tp_cli_media_stream_handler_finish_running_new_native_candidate (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_new_native_candidate *state = user_data;

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
tp_cli_media_stream_handler_run_new_native_candidate (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Candidate_ID,
    const GPtrArray *in_Transports,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_new_native_candidate state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "NewNativeCandidate", iface,
      _tp_cli_media_stream_handler_finish_running_new_native_candidate,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "NewNativeCandidate",
          _tp_cli_media_stream_handler_collect_callback_new_native_candidate,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_STRING, in_Candidate_ID,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Transports,
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
_tp_cli_media_stream_handler_collect_callback_ready (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_ready (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_ready callback = (tp_cli_media_stream_handler_callback_for_ready) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_ready (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_ready callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Ready", iface,
          _tp_cli_media_stream_handler_invoke_callback_ready,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Ready",
              _tp_cli_media_stream_handler_collect_callback_ready,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_ready;
static void
_tp_cli_media_stream_handler_finish_running_ready (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_ready *state = user_data;

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
tp_cli_media_stream_handler_run_ready (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_ready state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "Ready", iface,
      _tp_cli_media_stream_handler_finish_running_ready,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "Ready",
          _tp_cli_media_stream_handler_collect_callback_ready,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
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
_tp_cli_media_stream_handler_collect_callback_set_local_codecs (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_set_local_codecs (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_set_local_codecs callback = (tp_cli_media_stream_handler_callback_for_set_local_codecs) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_set_local_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_set_local_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SetLocalCodecs",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SetLocalCodecs", iface,
          _tp_cli_media_stream_handler_invoke_callback_set_local_codecs,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SetLocalCodecs",
              _tp_cli_media_stream_handler_collect_callback_set_local_codecs,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_set_local_codecs;
static void
_tp_cli_media_stream_handler_finish_running_set_local_codecs (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_set_local_codecs *state = user_data;

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
tp_cli_media_stream_handler_run_set_local_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_set_local_codecs state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SetLocalCodecs", iface,
      _tp_cli_media_stream_handler_finish_running_set_local_codecs,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SetLocalCodecs",
          _tp_cli_media_stream_handler_collect_callback_set_local_codecs,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
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
_tp_cli_media_stream_handler_collect_callback_stream_state (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_stream_state (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_stream_state callback = (tp_cli_media_stream_handler_callback_for_stream_state) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_stream_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_media_stream_handler_callback_for_stream_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "StreamState",
          G_TYPE_UINT, in_State,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "StreamState", iface,
          _tp_cli_media_stream_handler_invoke_callback_stream_state,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "StreamState",
              _tp_cli_media_stream_handler_collect_callback_stream_state,
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
} _tp_cli_media_stream_handler_run_state_stream_state;
static void
_tp_cli_media_stream_handler_finish_running_stream_state (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_stream_state *state = user_data;

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
tp_cli_media_stream_handler_run_stream_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_State,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_stream_state state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "StreamState", iface,
      _tp_cli_media_stream_handler_finish_running_stream_state,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "StreamState",
          _tp_cli_media_stream_handler_collect_callback_stream_state,
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


static void
_tp_cli_media_stream_handler_collect_callback_supported_codecs (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_supported_codecs (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_supported_codecs callback = (tp_cli_media_stream_handler_callback_for_supported_codecs) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_supported_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_supported_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SupportedCodecs",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SupportedCodecs", iface,
          _tp_cli_media_stream_handler_invoke_callback_supported_codecs,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SupportedCodecs",
              _tp_cli_media_stream_handler_collect_callback_supported_codecs,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_supported_codecs;
static void
_tp_cli_media_stream_handler_finish_running_supported_codecs (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_supported_codecs *state = user_data;

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
tp_cli_media_stream_handler_run_supported_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_supported_codecs state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SupportedCodecs", iface,
      _tp_cli_media_stream_handler_finish_running_supported_codecs,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SupportedCodecs",
          _tp_cli_media_stream_handler_collect_callback_supported_codecs,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
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
_tp_cli_media_stream_handler_collect_callback_codecs_updated (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_codecs_updated (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_codecs_updated callback = (tp_cli_media_stream_handler_callback_for_codecs_updated) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_codecs_updated (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_codecs_updated callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CodecsUpdated",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CodecsUpdated", iface,
          _tp_cli_media_stream_handler_invoke_callback_codecs_updated,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CodecsUpdated",
              _tp_cli_media_stream_handler_collect_callback_codecs_updated,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_codecs_updated;
static void
_tp_cli_media_stream_handler_finish_running_codecs_updated (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_codecs_updated *state = user_data;

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
tp_cli_media_stream_handler_run_codecs_updated (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_codecs_updated state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "CodecsUpdated", iface,
      _tp_cli_media_stream_handler_finish_running_codecs_updated,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "CodecsUpdated",
          _tp_cli_media_stream_handler_collect_callback_codecs_updated,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))), in_Codecs,
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
_tp_cli_media_stream_handler_collect_callback_hold_state (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_hold_state (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_hold_state callback = (tp_cli_media_stream_handler_callback_for_hold_state) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_hold_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    gboolean in_Held,
    tp_cli_media_stream_handler_callback_for_hold_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "HoldState",
          G_TYPE_BOOLEAN, in_Held,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "HoldState", iface,
          _tp_cli_media_stream_handler_invoke_callback_hold_state,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "HoldState",
              _tp_cli_media_stream_handler_collect_callback_hold_state,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_BOOLEAN, in_Held,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_hold_state;
static void
_tp_cli_media_stream_handler_finish_running_hold_state (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_hold_state *state = user_data;

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
tp_cli_media_stream_handler_run_hold_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    gboolean in_Held,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_hold_state state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "HoldState", iface,
      _tp_cli_media_stream_handler_finish_running_hold_state,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "HoldState",
          _tp_cli_media_stream_handler_collect_callback_hold_state,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              G_TYPE_BOOLEAN, in_Held,
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
_tp_cli_media_stream_handler_collect_callback_unhold_failure (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_unhold_failure (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_unhold_failure callback = (tp_cli_media_stream_handler_callback_for_unhold_failure) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_unhold_failure (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    tp_cli_media_stream_handler_callback_for_unhold_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "UnholdFailure",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "UnholdFailure", iface,
          _tp_cli_media_stream_handler_invoke_callback_unhold_failure,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "UnholdFailure",
              _tp_cli_media_stream_handler_collect_callback_unhold_failure,
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
} _tp_cli_media_stream_handler_run_state_unhold_failure;
static void
_tp_cli_media_stream_handler_finish_running_unhold_failure (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_unhold_failure *state = user_data;

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
tp_cli_media_stream_handler_run_unhold_failure (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_unhold_failure state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "UnholdFailure", iface,
      _tp_cli_media_stream_handler_finish_running_unhold_failure,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "UnholdFailure",
          _tp_cli_media_stream_handler_collect_callback_unhold_failure,
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
_tp_cli_media_stream_handler_collect_callback_supported_feedback_messages (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_supported_feedback_messages (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_supported_feedback_messages callback = (tp_cli_media_stream_handler_callback_for_supported_feedback_messages) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_supported_feedback_messages (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GHashTable *in_Messages,
    tp_cli_media_stream_handler_callback_for_supported_feedback_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SupportedFeedbackMessages",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))), in_Messages,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SupportedFeedbackMessages", iface,
          _tp_cli_media_stream_handler_invoke_callback_supported_feedback_messages,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SupportedFeedbackMessages",
              _tp_cli_media_stream_handler_collect_callback_supported_feedback_messages,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))), in_Messages,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_supported_feedback_messages;
static void
_tp_cli_media_stream_handler_finish_running_supported_feedback_messages (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_supported_feedback_messages *state = user_data;

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
tp_cli_media_stream_handler_run_supported_feedback_messages (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GHashTable *in_Messages,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_supported_feedback_messages state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SupportedFeedbackMessages", iface,
      _tp_cli_media_stream_handler_finish_running_supported_feedback_messages,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SupportedFeedbackMessages",
          _tp_cli_media_stream_handler_collect_callback_supported_feedback_messages,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))), in_Messages,
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
_tp_cli_media_stream_handler_collect_callback_supported_header_extensions (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_media_stream_handler_invoke_callback_supported_header_extensions (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_media_stream_handler_callback_for_supported_header_extensions callback = (tp_cli_media_stream_handler_callback_for_supported_header_extensions) generic_callback;

  if (error != NULL)
    {
      callback ((TpMediaStreamHandler *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpMediaStreamHandler *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_media_stream_handler_call_supported_header_extensions (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Header_Extensions,
    tp_cli_media_stream_handler_callback_for_supported_header_extensions callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "SupportedHeaderExtensions",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Header_Extensions,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "SupportedHeaderExtensions", iface,
          _tp_cli_media_stream_handler_invoke_callback_supported_header_extensions,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SupportedHeaderExtensions",
              _tp_cli_media_stream_handler_collect_callback_supported_header_extensions,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Header_Extensions,
              G_TYPE_INVALID));

      return data;
    }
}

typedef struct {
    GMainLoop *loop;
    GError **error;
    unsigned success:1;
    unsigned completed:1;
} _tp_cli_media_stream_handler_run_state_supported_header_extensions;
static void
_tp_cli_media_stream_handler_finish_running_supported_header_extensions (TpProxy *self G_GNUC_UNUSED,
    GError *error,
    GValueArray *args,
    GCallback unused G_GNUC_UNUSED,
    gpointer user_data G_GNUC_UNUSED,
    GObject *unused2 G_GNUC_UNUSED)
{
  _tp_cli_media_stream_handler_run_state_supported_header_extensions *state = user_data;

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
tp_cli_media_stream_handler_run_supported_header_extensions (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Header_Extensions,
    GError **error,
    GMainLoop **loop)
{
  DBusGProxy *iface;
  GQuark interface = TP_IFACE_QUARK_MEDIA_STREAM_HANDLER;
  TpProxyPendingCall *pc;
  _tp_cli_media_stream_handler_run_state_supported_header_extensions state = {
      NULL /* loop */, error,
      FALSE /* completed */, FALSE /* success */ };

  g_return_val_if_fail (TP_IS_MEDIA_STREAM_HANDLER (proxy), FALSE);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id
       ((TpProxy *) proxy, interface, error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    return FALSE;

  state.loop = g_main_loop_new (NULL, FALSE);

  pc = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
      interface, "SupportedHeaderExtensions", iface,
      _tp_cli_media_stream_handler_finish_running_supported_header_extensions,
      NULL, &state, NULL, NULL, TRUE);

  if (loop != NULL)
    *loop = state.loop;

  tp_proxy_pending_call_v0_take_pending_call (pc,
      dbus_g_proxy_begin_call_with_timeout (iface,
          "SupportedHeaderExtensions",
          _tp_cli_media_stream_handler_collect_callback_supported_header_extensions,
          pc,
          tp_proxy_pending_call_v0_completed,
          timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), in_Header_Extensions,
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
 * tp_cli_media_stream_handler_add_signals:
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
tp_cli_media_stream_handler_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_MEDIA_STREAM_HANDLER)
    tp_cli_add_signals_for_media_stream_handler (proxy);
}
