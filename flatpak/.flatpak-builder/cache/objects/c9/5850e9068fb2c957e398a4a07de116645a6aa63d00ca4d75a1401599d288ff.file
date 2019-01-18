#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcCallStreamEndpoint TpSvcCallStreamEndpoint;

typedef struct _TpSvcCallStreamEndpointClass TpSvcCallStreamEndpointClass;

GType tp_svc_call_stream_endpoint_get_type (void);
#define TP_TYPE_SVC_CALL_STREAM_ENDPOINT \
  (tp_svc_call_stream_endpoint_get_type ())
#define TP_SVC_CALL_STREAM_ENDPOINT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_STREAM_ENDPOINT, TpSvcCallStreamEndpoint))
#define TP_IS_SVC_CALL_STREAM_ENDPOINT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_STREAM_ENDPOINT))
#define TP_SVC_CALL_STREAM_ENDPOINT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_STREAM_ENDPOINT, TpSvcCallStreamEndpointClass))


typedef void (*tp_svc_call_stream_endpoint_set_selected_candidate_pair_impl) (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_endpoint_implement_set_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_selected_candidate_pair_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_endpoint_return_from_set_selected_candidate_pair (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_endpoint_return_from_set_selected_candidate_pair (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_endpoint_set_endpoint_state_impl) (TpSvcCallStreamEndpoint *self,
    guint in_Component,
    guint in_State,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_endpoint_implement_set_endpoint_state (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_endpoint_state_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_endpoint_return_from_set_endpoint_state (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_endpoint_return_from_set_endpoint_state (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_endpoint_accept_selected_candidate_pair_impl) (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_endpoint_implement_accept_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_accept_selected_candidate_pair_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_endpoint_return_from_accept_selected_candidate_pair (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_endpoint_return_from_accept_selected_candidate_pair (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_endpoint_reject_selected_candidate_pair_impl) (TpSvcCallStreamEndpoint *self,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_endpoint_implement_reject_selected_candidate_pair (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_reject_selected_candidate_pair_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_endpoint_return_from_reject_selected_candidate_pair (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_endpoint_return_from_reject_selected_candidate_pair (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_endpoint_set_controlling_impl) (TpSvcCallStreamEndpoint *self,
    gboolean in_Controlling,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_endpoint_implement_set_controlling (TpSvcCallStreamEndpointClass *klass, tp_svc_call_stream_endpoint_set_controlling_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_endpoint_return_from_set_controlling (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_endpoint_return_from_set_controlling (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_stream_endpoint_emit_remote_credentials_set (gpointer instance,
    const gchar *arg_Username,
    const gchar *arg_Password);
void tp_svc_call_stream_endpoint_emit_remote_candidates_added (gpointer instance,
    const GPtrArray *arg_Candidates);
void tp_svc_call_stream_endpoint_emit_candidate_pair_selected (gpointer instance,
    const GValueArray *arg_Local_Candidate,
    const GValueArray *arg_Remote_Candidate);
void tp_svc_call_stream_endpoint_emit_endpoint_state_changed (gpointer instance,
    guint arg_Component,
    guint arg_State);
void tp_svc_call_stream_endpoint_emit_controlling_changed (gpointer instance,
    gboolean arg_Controlling);


G_END_DECLS
