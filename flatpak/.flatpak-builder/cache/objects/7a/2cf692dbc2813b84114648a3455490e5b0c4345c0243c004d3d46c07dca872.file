#include "_gen/tp-svc-call-stream.h"

static const DBusGObjectInfo _tp_svc_call_stream_object_info;

struct _TpSvcCallStreamClass {
    GTypeInterface parent_class;
    tp_svc_call_stream_set_sending_impl set_sending_cb;
    tp_svc_call_stream_request_receiving_impl request_receiving_cb;
};

enum {
    SIGNAL_CALL_STREAM_RemoteMembersChanged,
    SIGNAL_CALL_STREAM_LocalSendingStateChanged,
    N_CALL_STREAM_SIGNALS
};
static guint call_stream_signals[N_CALL_STREAM_SIGNALS] = {0};

static void tp_svc_call_stream_base_init (gpointer klass);

GType
tp_svc_call_stream_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallStreamClass),
        tp_svc_call_stream_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallStream", &info, 0);
    }

  return type;
}

static void
tp_svc_call_stream_set_sending (TpSvcCallStream *self,
    gboolean in_Send,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_set_sending_impl impl = (TP_SVC_CALL_STREAM_GET_CLASS (self)->set_sending_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Send,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_implement_set_sending (TpSvcCallStreamClass *klass, tp_svc_call_stream_set_sending_impl impl)
{
  klass->set_sending_cb = impl;
}

static void
tp_svc_call_stream_request_receiving (TpSvcCallStream *self,
    guint in_Contact,
    gboolean in_Receive,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_request_receiving_impl impl = (TP_SVC_CALL_STREAM_GET_CLASS (self)->request_receiving_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        in_Receive,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_implement_request_receiving (TpSvcCallStreamClass *klass, tp_svc_call_stream_request_receiving_impl impl)
{
  klass->request_receiving_cb = impl;
}

void
tp_svc_call_stream_emit_remote_members_changed (gpointer instance,
    GHashTable *arg_Updates,
    GHashTable *arg_Identifiers,
    const GArray *arg_Removed,
    const GValueArray *arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM));
  g_signal_emit (instance,
      call_stream_signals[SIGNAL_CALL_STREAM_RemoteMembersChanged],
      0,
      arg_Updates,
      arg_Identifiers,
      arg_Removed,
      arg_Reason);
}

void
tp_svc_call_stream_emit_local_sending_state_changed (gpointer instance,
    guint arg_State,
    const GValueArray *arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM));
  g_signal_emit (instance,
      call_stream_signals[SIGNAL_CALL_STREAM_LocalSendingStateChanged],
      0,
      arg_State,
      arg_Reason);
}

static inline void
tp_svc_call_stream_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uu}", 0, NULL, NULL }, /* RemoteMembers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{us}", 0, NULL, NULL }, /* RemoteMemberIdentifiers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* LocalSendingState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CanRequestReceiving */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_stream_get_type (),
      &_tp_svc_call_stream_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Stream");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("RemoteMembers");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT));
  properties[2].name = g_quark_from_static_string ("RemoteMemberIdentifiers");
  properties[2].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING));
  properties[3].name = g_quark_from_static_string ("LocalSendingState");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("CanRequestReceiving");
  properties[4].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_STREAM, &interface);

  call_stream_signals[SIGNAL_CALL_STREAM_RemoteMembersChanged] =
  g_signal_new ("remote-members-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));

  call_stream_signals[SIGNAL_CALL_STREAM_LocalSendingStateChanged] =
  g_signal_new ("local-sending-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));

}
static void
tp_svc_call_stream_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_stream_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_stream_methods[] = {
  { (GCallback) tp_svc_call_stream_set_sending, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_stream_request_receiving, g_cclosure_marshal_generic, 62 },
};

static const DBusGObjectInfo _tp_svc_call_stream_object_info = {
  0,
  _tp_svc_call_stream_methods,
  2,
"org.freedesktop.Telepathy.Call1.Stream\0SetSending\0A\0Send\0I\0b\0\0org.freedesktop.Telepathy.Call1.Stream\0RequestReceiving\0A\0Contact\0I\0u\0Receive\0I\0b\0\0\0",
"org.freedesktop.Telepathy.Call1.Stream\0RemoteMembersChanged\0org.freedesktop.Telepathy.Call1.Stream\0LocalSendingStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_stream_interface_media_object_info;

struct _TpSvcCallStreamInterfaceMediaClass {
    GTypeInterface parent_class;
    tp_svc_call_stream_interface_media_complete_sending_state_change_impl complete_sending_state_change_cb;
    tp_svc_call_stream_interface_media_report_sending_failure_impl report_sending_failure_cb;
    tp_svc_call_stream_interface_media_complete_receiving_state_change_impl complete_receiving_state_change_cb;
    tp_svc_call_stream_interface_media_report_receiving_failure_impl report_receiving_failure_cb;
    tp_svc_call_stream_interface_media_set_credentials_impl set_credentials_cb;
    tp_svc_call_stream_interface_media_add_candidates_impl add_candidates_cb;
    tp_svc_call_stream_interface_media_finish_initial_candidates_impl finish_initial_candidates_cb;
    tp_svc_call_stream_interface_media_fail_impl fail_cb;
};

enum {
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_SendingStateChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ReceivingStateChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCandidatesAdded,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCredentialsChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_RelayInfoChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_STUNServersChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ServerInfoRetrieved,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_EndpointsChanged,
    SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ICERestartRequested,
    N_CALL_STREAM_INTERFACE_MEDIA_SIGNALS
};
static guint call_stream_interface_media_signals[N_CALL_STREAM_INTERFACE_MEDIA_SIGNALS] = {0};

static void tp_svc_call_stream_interface_media_base_init (gpointer klass);

GType
tp_svc_call_stream_interface_media_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallStreamInterfaceMediaClass),
        tp_svc_call_stream_interface_media_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallStreamInterfaceMedia", &info, 0);
    }

  return type;
}

static void
tp_svc_call_stream_interface_media_complete_sending_state_change (TpSvcCallStreamInterfaceMedia *self,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_complete_sending_state_change_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->complete_sending_state_change_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_complete_sending_state_change (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_complete_sending_state_change_impl impl)
{
  klass->complete_sending_state_change_cb = impl;
}

static void
tp_svc_call_stream_interface_media_report_sending_failure (TpSvcCallStreamInterfaceMedia *self,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_report_sending_failure_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->report_sending_failure_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        in_Error,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_report_sending_failure (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_report_sending_failure_impl impl)
{
  klass->report_sending_failure_cb = impl;
}

static void
tp_svc_call_stream_interface_media_complete_receiving_state_change (TpSvcCallStreamInterfaceMedia *self,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_complete_receiving_state_change_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->complete_receiving_state_change_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_complete_receiving_state_change (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_complete_receiving_state_change_impl impl)
{
  klass->complete_receiving_state_change_cb = impl;
}

static void
tp_svc_call_stream_interface_media_report_receiving_failure (TpSvcCallStreamInterfaceMedia *self,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_report_receiving_failure_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->report_receiving_failure_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        in_Error,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_report_receiving_failure (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_report_receiving_failure_impl impl)
{
  klass->report_receiving_failure_cb = impl;
}

static void
tp_svc_call_stream_interface_media_set_credentials (TpSvcCallStreamInterfaceMedia *self,
    const gchar *in_Username,
    const gchar *in_Password,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_set_credentials_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->set_credentials_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Username,
        in_Password,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_set_credentials (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_set_credentials_impl impl)
{
  klass->set_credentials_cb = impl;
}

static void
tp_svc_call_stream_interface_media_add_candidates (TpSvcCallStreamInterfaceMedia *self,
    const GPtrArray *in_Candidates,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_add_candidates_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->add_candidates_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Candidates,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_add_candidates (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_add_candidates_impl impl)
{
  klass->add_candidates_cb = impl;
}

static void
tp_svc_call_stream_interface_media_finish_initial_candidates (TpSvcCallStreamInterfaceMedia *self,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_finish_initial_candidates_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->finish_initial_candidates_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_finish_initial_candidates (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_finish_initial_candidates_impl impl)
{
  klass->finish_initial_candidates_cb = impl;
}

static void
tp_svc_call_stream_interface_media_fail (TpSvcCallStreamInterfaceMedia *self,
    const GValueArray *in_Reason,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_interface_media_fail_impl impl = (TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS (self)->fail_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_interface_media_implement_fail (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_fail_impl impl)
{
  klass->fail_cb = impl;
}

void
tp_svc_call_stream_interface_media_emit_sending_state_changed (gpointer instance,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_SendingStateChanged],
      0,
      arg_State);
}

void
tp_svc_call_stream_interface_media_emit_receiving_state_changed (gpointer instance,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ReceivingStateChanged],
      0,
      arg_State);
}

void
tp_svc_call_stream_interface_media_emit_local_candidates_added (gpointer instance,
    const GPtrArray *arg_Candidates)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCandidatesAdded],
      0,
      arg_Candidates);
}

void
tp_svc_call_stream_interface_media_emit_local_credentials_changed (gpointer instance,
    const gchar *arg_Username,
    const gchar *arg_Password)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCredentialsChanged],
      0,
      arg_Username,
      arg_Password);
}

void
tp_svc_call_stream_interface_media_emit_relay_info_changed (gpointer instance,
    const GPtrArray *arg_Relay_Info)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_RelayInfoChanged],
      0,
      arg_Relay_Info);
}

void
tp_svc_call_stream_interface_media_emit_stun_servers_changed (gpointer instance,
    const GPtrArray *arg_Servers)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_STUNServersChanged],
      0,
      arg_Servers);
}

void
tp_svc_call_stream_interface_media_emit_server_info_retrieved (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ServerInfoRetrieved],
      0);
}

void
tp_svc_call_stream_interface_media_emit_endpoints_changed (gpointer instance,
    const GPtrArray *arg_Endpoints_Added,
    const GPtrArray *arg_Endpoints_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_EndpointsChanged],
      0,
      arg_Endpoints_Added,
      arg_Endpoints_Removed);
}

void
tp_svc_call_stream_interface_media_emit_ice_restart_requested (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ICERestartRequested],
      0);
}

static inline void
tp_svc_call_stream_interface_media_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[11] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SendingState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ReceivingState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Transport */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(usua{sv})", 0, NULL, NULL }, /* LocalCandidates */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(ss)", 0, NULL, NULL }, /* LocalCredentials */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(sq)", 0, NULL, NULL }, /* STUNServers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* RelayInfo */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HasServerInfo */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* Endpoints */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* ICERestartPending */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_stream_interface_media_get_type (),
      &_tp_svc_call_stream_interface_media_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Stream.Interface.Media");
  properties[0].name = g_quark_from_static_string ("SendingState");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("ReceivingState");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("Transport");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("LocalCandidates");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  properties[4].name = g_quark_from_static_string ("LocalCredentials");
  properties[4].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[5].name = g_quark_from_static_string ("STUNServers");
  properties[5].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID))));
  properties[6].name = g_quark_from_static_string ("RelayInfo");
  properties[6].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[7].name = g_quark_from_static_string ("HasServerInfo");
  properties[7].type = G_TYPE_BOOLEAN;
  properties[8].name = g_quark_from_static_string ("Endpoints");
  properties[8].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[9].name = g_quark_from_static_string ("ICERestartPending");
  properties[9].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA, &interface);

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_SendingStateChanged] =
  g_signal_new ("sending-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ReceivingStateChanged] =
  g_signal_new ("receiving-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCandidatesAdded] =
  g_signal_new ("local-candidates-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_LocalCredentialsChanged] =
  g_signal_new ("local-credentials-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      G_TYPE_STRING);

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_RelayInfoChanged] =
  g_signal_new ("relay-info-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_STUNServersChanged] =
  g_signal_new ("s-tu-nservers-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID)))));

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ServerInfoRetrieved] =
  g_signal_new ("server-info-retrieved",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_EndpointsChanged] =
  g_signal_new ("endpoints-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));

  call_stream_interface_media_signals[SIGNAL_CALL_STREAM_INTERFACE_MEDIA_ICERestartRequested] =
  g_signal_new ("i-ce-restart-requested",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

}
static void
tp_svc_call_stream_interface_media_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_stream_interface_media_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_stream_interface_media_methods[] = {
  { (GCallback) tp_svc_call_stream_interface_media_complete_sending_state_change, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_stream_interface_media_report_sending_failure, g_cclosure_marshal_generic, 95 },
  { (GCallback) tp_svc_call_stream_interface_media_complete_receiving_state_change, g_cclosure_marshal_generic, 207 },
  { (GCallback) tp_svc_call_stream_interface_media_report_receiving_failure, g_cclosure_marshal_generic, 304 },
  { (GCallback) tp_svc_call_stream_interface_media_set_credentials, g_cclosure_marshal_generic, 418 },
  { (GCallback) tp_svc_call_stream_interface_media_add_candidates, g_cclosure_marshal_generic, 517 },
  { (GCallback) tp_svc_call_stream_interface_media_finish_initial_candidates, g_cclosure_marshal_generic, 614 },
  { (GCallback) tp_svc_call_stream_interface_media_fail, g_cclosure_marshal_generic, 696 },
};

static const DBusGObjectInfo _tp_svc_call_stream_interface_media_object_info = {
  0,
  _tp_svc_call_stream_interface_media_methods,
  8,
"org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0CompleteSendingStateChange\0A\0State\0I\0u\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0ReportSendingFailure\0A\0Reason\0I\0u\0Error\0I\0s\0Message\0I\0s\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0CompleteReceivingStateChange\0A\0State\0I\0u\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0ReportReceivingFailure\0A\0Reason\0I\0u\0Error\0I\0s\0Message\0I\0s\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0SetCredentials\0A\0Username\0I\0s\0Password\0I\0s\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0AddCandidates\0A\0Candidates\0I\0a(usua{sv})\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0FinishInitialCandidates\0A\0\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0Fail\0A\0Reason\0I\0(uuss)\0\0\0",
"org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0SendingStateChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0ReceivingStateChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0LocalCandidatesAdded\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0LocalCredentialsChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0RelayInfoChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0STUNServersChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0ServerInfoRetrieved\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0EndpointsChanged\0org.freedesktop.Telepathy.Call1.Stream.Interface.Media\0ICERestartRequested\0\0",
"\0\0",
};


