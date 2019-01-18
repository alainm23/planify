/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static void
_tp_cli_client_approver_collect_callback_add_dispatch_operation (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_client_approver_invoke_callback_add_dispatch_operation (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_client_approver_callback_for_add_dispatch_operation callback = (tp_cli_client_approver_callback_for_add_dispatch_operation) generic_callback;

  if (error != NULL)
    {
      callback ((TpClient *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpClient *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_client_approver_call_add_dispatch_operation (TpClient *proxy,
    gint timeout_ms,
    const GPtrArray *in_Channels,
    const gchar *in_DispatchOperation,
    GHashTable *in_Properties,
    tp_cli_client_approver_callback_for_add_dispatch_operation callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CLIENT_APPROVER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CLIENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddDispatchOperation",
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
          DBUS_TYPE_G_OBJECT_PATH, in_DispatchOperation,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddDispatchOperation", iface,
          _tp_cli_client_approver_invoke_callback_add_dispatch_operation,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddDispatchOperation",
              _tp_cli_client_approver_collect_callback_add_dispatch_operation,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
              DBUS_TYPE_G_OBJECT_PATH, in_DispatchOperation,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_client_handler_collect_callback_handle_channels (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_client_handler_invoke_callback_handle_channels (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_client_handler_callback_for_handle_channels callback = (tp_cli_client_handler_callback_for_handle_channels) generic_callback;

  if (error != NULL)
    {
      callback ((TpClient *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpClient *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_client_handler_call_handle_channels (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const GPtrArray *in_Requests_Satisfied,
    guint64 in_User_Action_Time,
    GHashTable *in_Handler_Info,
    tp_cli_client_handler_callback_for_handle_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CLIENT_HANDLER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CLIENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "HandleChannels",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          DBUS_TYPE_G_OBJECT_PATH, in_Connection,
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
          dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Requests_Satisfied,
          G_TYPE_UINT64, in_User_Action_Time,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Handler_Info,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "HandleChannels", iface,
          _tp_cli_client_handler_invoke_callback_handle_channels,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "HandleChannels",
              _tp_cli_client_handler_collect_callback_handle_channels,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              DBUS_TYPE_G_OBJECT_PATH, in_Connection,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
              dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Requests_Satisfied,
              G_TYPE_UINT64, in_User_Action_Time,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Handler_Info,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_client_interface_requests_collect_callback_add_request (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_client_interface_requests_invoke_callback_add_request (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_client_interface_requests_callback_for_add_request callback = (tp_cli_client_interface_requests_callback_for_add_request) generic_callback;

  if (error != NULL)
    {
      callback ((TpClient *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpClient *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_client_interface_requests_call_add_request (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Request,
    GHashTable *in_Properties,
    tp_cli_client_interface_requests_callback_for_add_request callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CLIENT_INTERFACE_REQUESTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CLIENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "AddRequest",
          DBUS_TYPE_G_OBJECT_PATH, in_Request,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "AddRequest", iface,
          _tp_cli_client_interface_requests_invoke_callback_add_request,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "AddRequest",
              _tp_cli_client_interface_requests_collect_callback_add_request,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Request,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Properties,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_client_interface_requests_collect_callback_remove_request (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_client_interface_requests_invoke_callback_remove_request (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_client_interface_requests_callback_for_remove_request callback = (tp_cli_client_interface_requests_callback_for_remove_request) generic_callback;

  if (error != NULL)
    {
      callback ((TpClient *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpClient *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_client_interface_requests_call_remove_request (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Request,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_client_interface_requests_callback_for_remove_request callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CLIENT_INTERFACE_REQUESTS;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CLIENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "RemoveRequest",
          DBUS_TYPE_G_OBJECT_PATH, in_Request,
          G_TYPE_STRING, in_Error,
          G_TYPE_STRING, in_Message,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "RemoveRequest", iface,
          _tp_cli_client_interface_requests_invoke_callback_remove_request,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "RemoveRequest",
              _tp_cli_client_interface_requests_collect_callback_remove_request,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Request,
              G_TYPE_STRING, in_Error,
              G_TYPE_STRING, in_Message,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_client_observer_collect_callback_observe_channels (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_client_observer_invoke_callback_observe_channels (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_client_observer_callback_for_observe_channels callback = (tp_cli_client_observer_callback_for_observe_channels) generic_callback;

  if (error != NULL)
    {
      callback ((TpClient *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpClient *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_client_observer_call_observe_channels (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const gchar *in_Dispatch_Operation,
    const GPtrArray *in_Requests_Satisfied,
    GHashTable *in_Observer_Info,
    tp_cli_client_observer_callback_for_observe_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CLIENT_OBSERVER;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CLIENT (proxy), NULL);
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
      dbus_g_proxy_call_no_reply (iface, "ObserveChannels",
          DBUS_TYPE_G_OBJECT_PATH, in_Account,
          DBUS_TYPE_G_OBJECT_PATH, in_Connection,
          (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
          DBUS_TYPE_G_OBJECT_PATH, in_Dispatch_Operation,
          dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Requests_Satisfied,
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Observer_Info,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "ObserveChannels", iface,
          _tp_cli_client_observer_invoke_callback_observe_channels,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "ObserveChannels",
              _tp_cli_client_observer_collect_callback_observe_channels,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              DBUS_TYPE_G_OBJECT_PATH, in_Account,
              DBUS_TYPE_G_OBJECT_PATH, in_Connection,
              (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))), in_Channels,
              DBUS_TYPE_G_OBJECT_PATH, in_Dispatch_Operation,
              dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH), in_Requests_Satisfied,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Observer_Info,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_client_add_signals:
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
tp_cli_client_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
}
