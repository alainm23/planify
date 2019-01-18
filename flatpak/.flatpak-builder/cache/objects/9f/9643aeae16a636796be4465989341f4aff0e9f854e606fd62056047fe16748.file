#include "_gen/tp-svc-call-stream-endpoint.h"

static const DBusGObjectInfo _tp_svc_call_stream_endpoint_object_info;

struct _TpSvcCallStreamEndpointClass {
    GTypeInterface parent_class;
    tp_svc_call_stream_endpoint_set_selected_candidate_pair_impl set_selected_candidate_pair_cb;
    tp_svc_call_stream_endpoint_set_endpoint_state_impl set_endpoint_state_cb;
    tp_svc_call_stream_endpoint_accept_selected_candidate_pair_impl accept_selected_candidate_pair_cb;
    tp_svc_call_stream_endpoint_reject_selected_candidate_pair_impl reject_selected_candidate_pair_cb;
    tp_svc_call_stream_endpoint_set_controlling_impl set_controlling_cb;
};

enum {
    SIGNAL_CALL_STREAM_ENDPOINT_RemoteCredentialsSet,
    SIGNAL_CALL_STREAM_ENDPOINT_RemoteCandidatesAdded,
    SIGNAL_CALL_STREAM_ENDPOINT_CandidatePairSelected,
    SIGNAL_CALL_STREAM_ENDPOINT_EndpointStateChanged,
    SIGNAL_CALL_STREAM_ENDPOINT_ControllingChanged,
    N_CALL_STREAM_ENDPOINT_SIGNALS
};
static guint call_stream_endpoint_signals[N_CALL_STREAM_ENDPOINT_SIGNALS] = {0};

static void tp_svc_call_stream_endpoint_base_init (gpointer klass);

GType
tp_svc_call_stream_endpoint_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallStreamEndpointClass),
        tp_svc_call_stream_endpoint_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallStreamEndpoint", &info, 0);
    }

  return type;
}

static void
tp_svc_call_stream_endpoint_set_selected_candidate_pair (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_endpoint_set_selected_candidate_pair_impl impl = (TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS (self)->set_selected_candidate_pair_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Local_Candidate,
        in_Remote_Candidate,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_endpoint_implement_set_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_selected_candidate_pair_impl impl)
{
  klass->set_selected_candidate_pair_cb = impl;
}

static void
tp_svc_call_stream_endpoint_set_endpoint_state (TpSvcCallStreamEndpoint *self,
    guint in_Component,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_endpoint_set_endpoint_state_impl impl = (TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS (self)->set_endpoint_state_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Component,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_endpoint_implement_set_endpoint_state (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_endpoint_state_impl impl)
{
  klass->set_endpoint_state_cb = impl;
}

static void
tp_svc_call_stream_endpoint_accept_selected_candidate_pair (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_endpoint_accept_selected_candidate_pair_impl impl = (TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS (self)->accept_selected_candidate_pair_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Local_Candidate,
        in_Remote_Candidate,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_endpoint_implement_accept_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_accept_selected_candidate_pair_impl impl)
{
  klass->accept_selected_candidate_pair_cb = impl;
}

static void
tp_svc_call_stream_endpoint_reject_selected_candidate_pair (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_endpoint_reject_selected_candidate_pair_impl impl = (TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS (self)->reject_selected_candidate_pair_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Local_Candidate,
        in_Remote_Candidate,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_endpoint_implement_reject_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_reject_selected_candidate_pair_impl impl)
{
  klass->reject_selected_candidate_pair_cb = impl;
}

static void
tp_svc_call_stream_endpoint_set_controlling (TpSvcCallStreamEndpoint *self,
    gboolean in_Controlling,
    DBusGMethodInvocation *context)
{
  tp_svc_call_stream_endpoint_set_controlling_impl impl = (TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS (self)->set_controlling_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Controlling,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_stream_endpoint_implement_set_controlling (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_controlling_impl impl)
{
  klass->set_controlling_cb = impl;
}

void
tp_svc_call_stream_endpoint_emit_remote_credentials_set (gpointer instance,
    const gchar *arg_Username,
    const gchar *arg_Password)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_ENDPOINT));
  g_signal_emit (instance,
      call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_RemoteCredentialsSet],
      0,
      arg_Username,
      arg_Password);
}

void
tp_svc_call_stream_endpoint_emit_remote_candidates_added (gpointer instance,
    const GPtrArray *arg_Candidates)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_ENDPOINT));
  g_signal_emit (instance,
      call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_RemoteCandidatesAdded],
      0,
      arg_Candidates);
}

void
tp_svc_call_stream_endpoint_emit_candidate_pair_selected (gpointer instance,
    const GValueArray *arg_Local_Candidate,
    const GValueArray *arg_Remote_Candidate)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_ENDPOINT));
  g_signal_emit (instance,
      call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_CandidatePairSelected],
      0,
      arg_Local_Candidate,
      arg_Remote_Candidate);
}

void
tp_svc_call_stream_endpoint_emit_endpoint_state_changed (gpointer instance,
    guint arg_Component,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_ENDPOINT));
  g_signal_emit (instance,
      call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_EndpointStateChanged],
      0,
      arg_Component,
      arg_State);
}

void
tp_svc_call_stream_endpoint_emit_controlling_changed (gpointer instance,
    gboolean arg_Controlling)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_STREAM_ENDPOINT));
  g_signal_emit (instance,
      call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_ControllingChanged],
      0,
      arg_Controlling);
}

static inline void
tp_svc_call_stream_endpoint_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[8] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(ss)", 0, NULL, NULL }, /* RemoteCredentials */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(usua{sv})", 0, NULL, NULL }, /* RemoteCandidates */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a((usua{sv})(usua{sv}))", 0, NULL, NULL }, /* SelectedCandidatePairs */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uu}", 0, NULL, NULL }, /* EndpointState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Transport */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Controlling */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* IsICELite */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_stream_endpoint_get_type (),
      &_tp_svc_call_stream_endpoint_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Stream.Endpoint");
  properties[0].name = g_quark_from_static_string ("RemoteCredentials");
  properties[0].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[1].name = g_quark_from_static_string ("RemoteCandidates");
  properties[1].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  properties[2].name = g_quark_from_static_string ("SelectedCandidatePairs");
  properties[2].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)), G_TYPE_INVALID))));
  properties[3].name = g_quark_from_static_string ("EndpointState");
  properties[3].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT));
  properties[4].name = g_quark_from_static_string ("Transport");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("Controlling");
  properties[5].type = G_TYPE_BOOLEAN;
  properties[6].name = g_quark_from_static_string ("IsICELite");
  properties[6].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_STREAM_ENDPOINT, &interface);

  call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_RemoteCredentialsSet] =
  g_signal_new ("remote-credentials-set",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      G_TYPE_STRING);

  call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_RemoteCandidatesAdded] =
  g_signal_new ("remote-candidates-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));

  call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_CandidatePairSelected] =
  g_signal_new ("candidate-pair-selected",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)));

  call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_EndpointStateChanged] =
  g_signal_new ("endpoint-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

  call_stream_endpoint_signals[SIGNAL_CALL_STREAM_ENDPOINT_ControllingChanged] =
  g_signal_new ("controlling-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_call_stream_endpoint_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_stream_endpoint_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_stream_endpoint_methods[] = {
  { (GCallback) tp_svc_call_stream_endpoint_set_selected_candidate_pair, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_stream_endpoint_set_endpoint_state, g_cclosure_marshal_generic, 135 },
  { (GCallback) tp_svc_call_stream_endpoint_accept_selected_candidate_pair, g_cclosure_marshal_generic, 227 },
  { (GCallback) tp_svc_call_stream_endpoint_reject_selected_candidate_pair, g_cclosure_marshal_generic, 365 },
  { (GCallback) tp_svc_call_stream_endpoint_set_controlling, g_cclosure_marshal_generic, 503 },
};

static const DBusGObjectInfo _tp_svc_call_stream_endpoint_object_info = {
  0,
  _tp_svc_call_stream_endpoint_methods,
  5,
"org.freedesktop.Telepathy.Call1.Stream.Endpoint\0SetSelectedCandidatePair\0A\0Local_Candidate\0I\0(usua{sv})\0Remote_Candidate\0I\0(usua{sv})\0\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0SetEndpointState\0A\0Component\0I\0u\0State\0I\0u\0\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0AcceptSelectedCandidatePair\0A\0Local_Candidate\0I\0(usua{sv})\0Remote_Candidate\0I\0(usua{sv})\0\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0RejectSelectedCandidatePair\0A\0Local_Candidate\0I\0(usua{sv})\0Remote_Candidate\0I\0(usua{sv})\0\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0SetControlling\0A\0Controlling\0I\0b\0\0\0",
"org.freedesktop.Telepathy.Call1.Stream.Endpoint\0RemoteCredentialsSet\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0RemoteCandidatesAdded\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0CandidatePairSelected\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0EndpointStateChanged\0org.freedesktop.Telepathy.Call1.Stream.Endpoint\0ControllingChanged\0\0",
"\0\0",
};


