/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static void
_tp_cli_channel_dispatcher_collect_callback_create_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Request;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Request,
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
  g_value_take_boxed (args->values + 0, out_Request);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_create_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_create_channel callback = (tp_cli_channel_dispatcher_callback_for_create_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_create_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_create_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CreateChannel",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_STRING, in_Preferred_Handler,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CreateChannel", iface,
          _tp_cli_channel_dispatcher_invoke_callback_create_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CreateChannel",
              _tp_cli_channel_dispatcher_collect_callback_create_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_STRING, in_Preferred_Handler,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_collect_callback_ensure_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Request;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Request,
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
  g_value_take_boxed (args->values + 0, out_Request);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_ensure_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_ensure_channel callback = (tp_cli_channel_dispatcher_callback_for_ensure_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_ensure_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_ensure_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "EnsureChannel",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_STRING, in_Preferred_Handler,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "EnsureChannel", iface,
          _tp_cli_channel_dispatcher_invoke_callback_ensure_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "EnsureChannel",
              _tp_cli_channel_dispatcher_collect_callback_ensure_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_STRING, in_Preferred_Handler,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_collect_callback_create_channel_with_hints (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Request;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Request,
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
  g_value_take_boxed (args->values + 0, out_Request);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_create_channel_with_hints (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_create_channel_with_hints callback = (tp_cli_channel_dispatcher_callback_for_create_channel_with_hints) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_create_channel_with_hints (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    tp_cli_channel_dispatcher_callback_for_create_channel_with_hints callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "CreateChannelWithHints",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_STRING, in_Preferred_Handler,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Hints,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "CreateChannelWithHints", iface,
          _tp_cli_channel_dispatcher_invoke_callback_create_channel_with_hints,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "CreateChannelWithHints",
              _tp_cli_channel_dispatcher_collect_callback_create_channel_with_hints,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_STRING, in_Preferred_Handler,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Hints,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_collect_callback_ensure_channel_with_hints (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Request;

  dbus_g_proxy_end_call (proxy, call, &error,
      DBUS_TYPE_G_OBJECT_PATH, &out_Request,
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
  g_value_take_boxed (args->values + 0, out_Request);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_ensure_channel_with_hints (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_ensure_channel_with_hints callback = (tp_cli_channel_dispatcher_callback_for_ensure_channel_with_hints) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_ensure_channel_with_hints (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    tp_cli_channel_dispatcher_callback_for_ensure_channel_with_hints callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "EnsureChannelWithHints",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_STRING, in_Preferred_Handler,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Hints,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "EnsureChannelWithHints", iface,
          _tp_cli_channel_dispatcher_invoke_callback_ensure_channel_with_hints,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "EnsureChannelWithHints",
              _tp_cli_channel_dispatcher_collect_callback_ensure_channel_with_hints,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Requested_Properties,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_STRING, in_Preferred_Handler,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Hints,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_collect_callback_delegate_channels (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Delegated;
  GHashTable *out_Not_Delegated;

  dbus_g_proxy_end_call (proxy, call, &error,
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), &out_Delegated,
      (dbus_g_type_get_map ("GHashTable", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Not_Delegated,
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
  g_value_init (args->values + 0, dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));
  g_value_take_boxed (args->values + 0, out_Delegated);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 1, out_Not_Delegated);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_delegate_channels (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_delegate_channels callback = (tp_cli_channel_dispatcher_callback_for_delegate_channels) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_boxed (args->values + 0),
      g_value_get_boxed (args->values + 1),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_delegate_channels (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const GPtrArray *in_Channels,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_delegate_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "DelegateChannels",
          dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Channels,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_STRING, in_Preferred_Handler,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "DelegateChannels", iface,
          _tp_cli_channel_dispatcher_invoke_callback_delegate_channels,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "DelegateChannels",
              _tp_cli_channel_dispatcher_collect_callback_delegate_channels,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Channels,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_STRING, in_Preferred_Handler,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_collect_callback_present_channel (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_dispatcher_invoke_callback_present_channel (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_callback_for_present_channel callback = (tp_cli_channel_dispatcher_callback_for_present_channel) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_call_present_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Channel,
    gint64 in_User_Action_Time,
    tp_cli_channel_dispatcher_callback_for_present_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "PresentChannel",
          DBUS_TYPE_G_OBJECT_PATH, in_Channel,
          G_TYPE_INT64, in_User_Action_Time,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "PresentChannel", iface,
          _tp_cli_channel_dispatcher_invoke_callback_present_channel,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "PresentChannel",
              _tp_cli_channel_dispatcher_collect_callback_present_channel,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Channel,
              G_TYPE_INT64, in_User_Action_Time,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatcher_interface_messages1_collect_callback_send_message (DBusGProxy *proxy,
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
_tp_cli_channel_dispatcher_interface_messages1_invoke_callback_send_message (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_interface_messages1_callback_for_send_message callback = (tp_cli_channel_dispatcher_interface_messages1_callback_for_send_message) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatcher *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatcher *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatcher_interface_messages1_call_send_message (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Target_ID,
    const GPtrArray *in_Message,
    guint in_Flags,
    tp_cli_channel_dispatcher_interface_messages1_callback_for_send_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
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
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          G_TYPE_STRING, in_Target_ID,
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
          _tp_cli_channel_dispatcher_interface_messages1_invoke_callback_send_message,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "SendMessage",
              _tp_cli_channel_dispatcher_interface_messages1_collect_callback_send_message,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              G_TYPE_STRING, in_Target_ID,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), in_Message,
              G_TYPE_UINT, in_Flags,
              G_TYPE_INVALID));

      return data;
    }
}


static inline void
tp_cli_add_signals_for_channel_dispatcher_interface_operation_list (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewDispatchOperation",
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "DispatchOperationFinished",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_dispatcher_interface_operation_list_collect_args_of_new_dispatch_operation (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Dispatch_Operation,
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
  g_value_set_boxed (args->values + 0, arg_Dispatch_Operation);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));
  g_value_set_boxed (args->values + 1, arg_Properties);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_dispatcher_interface_operation_list_invoke_callback_for_new_dispatch_operation (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_interface_operation_list_signal_callback_new_dispatch_operation callback =
      (tp_cli_channel_dispatcher_interface_operation_list_signal_callback_new_dispatch_operation) generic_callback;

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
tp_cli_channel_dispatcher_interface_operation_list_connect_to_new_dispatch_operation (TpChannelDispatcher *proxy,
    tp_cli_channel_dispatcher_interface_operation_list_signal_callback_new_dispatch_operation callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[3] = {
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST, "NewDispatchOperation",
      expected_types,
      G_CALLBACK (_tp_cli_channel_dispatcher_interface_operation_list_collect_args_of_new_dispatch_operation),
      _tp_cli_channel_dispatcher_interface_operation_list_invoke_callback_for_new_dispatch_operation,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_dispatcher_interface_operation_list_collect_args_of_dispatch_operation_finished (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Dispatch_Operation,
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
  g_value_set_boxed (args->values + 0, arg_Dispatch_Operation);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_dispatcher_interface_operation_list_invoke_callback_for_dispatch_operation_finished (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatcher_interface_operation_list_signal_callback_dispatch_operation_finished callback =
      (tp_cli_channel_dispatcher_interface_operation_list_signal_callback_dispatch_operation_finished) generic_callback;

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
tp_cli_channel_dispatcher_interface_operation_list_connect_to_dispatch_operation_finished (TpChannelDispatcher *proxy,
    tp_cli_channel_dispatcher_interface_operation_list_signal_callback_dispatch_operation_finished callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[2] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCHER (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST, "DispatchOperationFinished",
      expected_types,
      G_CALLBACK (_tp_cli_channel_dispatcher_interface_operation_list_collect_args_of_dispatch_operation_finished),
      _tp_cli_channel_dispatcher_interface_operation_list_invoke_callback_for_dispatch_operation_finished,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

/*
 * tp_cli_channel_dispatcher_add_signals:
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
tp_cli_channel_dispatcher_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST)
    tp_cli_add_signals_for_channel_dispatcher_interface_operation_list (proxy);
}
