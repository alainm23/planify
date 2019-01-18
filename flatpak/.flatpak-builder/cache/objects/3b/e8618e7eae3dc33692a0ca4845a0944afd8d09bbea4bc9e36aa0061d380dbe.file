/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static void
_tp_cli_protocol_collect_callback_identify_account (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Account_ID;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Account_ID,
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
  g_value_take_string (args->values + 0, out_Account_ID);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_protocol_invoke_callback_identify_account (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_protocol_callback_for_identify_account callback = (tp_cli_protocol_callback_for_identify_account) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_protocol_call_identify_account (gpointer proxy,
    gint timeout_ms,
    GHashTable *in_Parameters,
    tp_cli_protocol_callback_for_identify_account callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_PROTOCOL;
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "IdentifyAccount",
          (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "IdentifyAccount", iface,
          _tp_cli_protocol_invoke_callback_identify_account,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "IdentifyAccount",
              _tp_cli_protocol_collect_callback_identify_account,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), in_Parameters,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_protocol_collect_callback_normalize_contact (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Normalized_Contact_ID;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Normalized_Contact_ID,
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
  g_value_take_string (args->values + 0, out_Normalized_Contact_ID);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_protocol_invoke_callback_normalize_contact (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_protocol_callback_for_normalize_contact callback = (tp_cli_protocol_callback_for_normalize_contact) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_protocol_call_normalize_contact (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Contact_ID,
    tp_cli_protocol_callback_for_normalize_contact callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_PROTOCOL;
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "NormalizeContact",
          G_TYPE_STRING, in_Contact_ID,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NormalizeContact", iface,
          _tp_cli_protocol_invoke_callback_normalize_contact,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NormalizeContact",
              _tp_cli_protocol_collect_callback_normalize_contact,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Contact_ID,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_protocol_interface_addressing_collect_callback_normalize_vcard_address (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Normalized_VCard_Address;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Normalized_VCard_Address,
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
  g_value_take_string (args->values + 0, out_Normalized_VCard_Address);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_protocol_interface_addressing_invoke_callback_normalize_vcard_address (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_protocol_interface_addressing_callback_for_normalize_vcard_address callback = (tp_cli_protocol_interface_addressing_callback_for_normalize_vcard_address) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_protocol_interface_addressing_call_normalize_vcard_address (gpointer proxy,
    gint timeout_ms,
    const gchar *in_VCard_Field,
    const gchar *in_VCard_Address,
    tp_cli_protocol_interface_addressing_callback_for_normalize_vcard_address callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_PROTOCOL_INTERFACE_ADDRESSING;
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "NormalizeVCardAddress",
          G_TYPE_STRING, in_VCard_Field,
          G_TYPE_STRING, in_VCard_Address,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NormalizeVCardAddress", iface,
          _tp_cli_protocol_interface_addressing_invoke_callback_normalize_vcard_address,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NormalizeVCardAddress",
              _tp_cli_protocol_interface_addressing_collect_callback_normalize_vcard_address,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_VCard_Field,
              G_TYPE_STRING, in_VCard_Address,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_protocol_interface_addressing_collect_callback_normalize_contact_uri (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  gchar *out_Normalized_URI;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_STRING, &out_Normalized_URI,
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
  g_value_take_string (args->values + 0, out_Normalized_URI);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_protocol_interface_addressing_invoke_callback_normalize_contact_uri (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_protocol_interface_addressing_callback_for_normalize_contact_uri callback = (tp_cli_protocol_interface_addressing_callback_for_normalize_contact_uri) generic_callback;

  if (error != NULL)
    {
      callback ((TpProxy *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpProxy *) self,
      g_value_get_string (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_protocol_interface_addressing_call_normalize_contact_uri (gpointer proxy,
    gint timeout_ms,
    const gchar *in_URI,
    tp_cli_protocol_interface_addressing_callback_for_normalize_contact_uri callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_PROTOCOL_INTERFACE_ADDRESSING;
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
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "NormalizeContactURI",
          G_TYPE_STRING, in_URI,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "NormalizeContactURI", iface,
          _tp_cli_protocol_interface_addressing_invoke_callback_normalize_contact_uri,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "NormalizeContactURI",
              _tp_cli_protocol_interface_addressing_collect_callback_normalize_contact_uri,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_URI,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_protocol_add_signals:
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
tp_cli_protocol_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
}
