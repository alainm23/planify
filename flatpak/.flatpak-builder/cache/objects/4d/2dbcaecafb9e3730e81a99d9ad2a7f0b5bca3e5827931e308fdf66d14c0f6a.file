#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcConnection TpSvcConnection;

typedef struct _TpSvcConnectionClass TpSvcConnectionClass;

GType tp_svc_connection_get_type (void);
#define TP_TYPE_SVC_CONNECTION \
  (tp_svc_connection_get_type ())
#define TP_SVC_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION, TpSvcConnection))
#define TP_IS_SVC_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION))
#define TP_SVC_CONNECTION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION, TpSvcConnectionClass))


typedef void (*tp_svc_connection_connect_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_connect (TpSvcConnectionClass *klass, tp_svc_connection_connect_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_connect (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_connect (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_disconnect_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_disconnect (TpSvcConnectionClass *klass, tp_svc_connection_disconnect_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_disconnect (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_disconnect (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_get_interfaces_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_get_interfaces (TpSvcConnectionClass *klass, tp_svc_connection_get_interfaces_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_get_interfaces (DBusGMethodInvocation *context,
    const gchar **out_Interfaces);
static inline void
tp_svc_connection_return_from_get_interfaces (DBusGMethodInvocation *context,
    const gchar **out_Interfaces)
{
  dbus_g_method_return (context,
      out_Interfaces);
}

typedef void (*tp_svc_connection_get_protocol_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_get_protocol (TpSvcConnectionClass *klass, tp_svc_connection_get_protocol_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_get_protocol (DBusGMethodInvocation *context,
    const gchar *out_Protocol);
static inline void
tp_svc_connection_return_from_get_protocol (DBusGMethodInvocation *context,
    const gchar *out_Protocol)
{
  dbus_g_method_return (context,
      out_Protocol);
}

typedef void (*tp_svc_connection_get_self_handle_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_get_self_handle (TpSvcConnectionClass *klass, tp_svc_connection_get_self_handle_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_get_self_handle (DBusGMethodInvocation *context,
    guint out_Self_Handle);
static inline void
tp_svc_connection_return_from_get_self_handle (DBusGMethodInvocation *context,
    guint out_Self_Handle)
{
  dbus_g_method_return (context,
      out_Self_Handle);
}

typedef void (*tp_svc_connection_get_status_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_get_status (TpSvcConnectionClass *klass, tp_svc_connection_get_status_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_get_status (DBusGMethodInvocation *context,
    guint out_Status);
static inline void
tp_svc_connection_return_from_get_status (DBusGMethodInvocation *context,
    guint out_Status)
{
  dbus_g_method_return (context,
      out_Status);
}

typedef void (*tp_svc_connection_hold_handles_impl) (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_hold_handles (TpSvcConnectionClass *klass, tp_svc_connection_hold_handles_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_hold_handles (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_hold_handles (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_inspect_handles_impl) (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_inspect_handles (TpSvcConnectionClass *klass, tp_svc_connection_inspect_handles_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_inspect_handles (DBusGMethodInvocation *context,
    const gchar **out_Identifiers);
static inline void
tp_svc_connection_return_from_inspect_handles (DBusGMethodInvocation *context,
    const gchar **out_Identifiers)
{
  dbus_g_method_return (context,
      out_Identifiers);
}

typedef void (*tp_svc_connection_list_channels_impl) (TpSvcConnection *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_list_channels (TpSvcConnectionClass *klass, tp_svc_connection_list_channels_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_list_channels (DBusGMethodInvocation *context,
    const GPtrArray *out_Channel_Info);
static inline void
tp_svc_connection_return_from_list_channels (DBusGMethodInvocation *context,
    const GPtrArray *out_Channel_Info)
{
  dbus_g_method_return (context,
      out_Channel_Info);
}

typedef void (*tp_svc_connection_release_handles_impl) (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_release_handles (TpSvcConnectionClass *klass, tp_svc_connection_release_handles_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_release_handles (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_release_handles (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_request_channel_impl) (TpSvcConnection *self,
    const gchar *in_Type,
    guint in_Handle_Type,
    guint in_Handle,
    gboolean in_Suppress_Handler,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_request_channel (TpSvcConnectionClass *klass, tp_svc_connection_request_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_request_channel (DBusGMethodInvocation *context,
    const gchar *out_Object_Path);
static inline void
tp_svc_connection_return_from_request_channel (DBusGMethodInvocation *context,
    const gchar *out_Object_Path)
{
  dbus_g_method_return (context,
      out_Object_Path);
}

typedef void (*tp_svc_connection_request_handles_impl) (TpSvcConnection *self,
    guint in_Handle_Type,
    const gchar **in_Identifiers,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_request_handles (TpSvcConnectionClass *klass, tp_svc_connection_request_handles_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_request_handles (DBusGMethodInvocation *context,
    const GArray *out_Handles);
static inline void
tp_svc_connection_return_from_request_handles (DBusGMethodInvocation *context,
    const GArray *out_Handles)
{
  dbus_g_method_return (context,
      out_Handles);
}

typedef void (*tp_svc_connection_add_client_interest_impl) (TpSvcConnection *self,
    const gchar **in_Tokens,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_add_client_interest (TpSvcConnectionClass *klass, tp_svc_connection_add_client_interest_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_add_client_interest (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_add_client_interest (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_remove_client_interest_impl) (TpSvcConnection *self,
    const gchar **in_Tokens,
    DBusGMethodInvocation *context);
void tp_svc_connection_implement_remove_client_interest (TpSvcConnectionClass *klass, tp_svc_connection_remove_client_interest_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_return_from_remove_client_interest (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_return_from_remove_client_interest (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_emit_self_handle_changed (gpointer instance,
    guint arg_Self_Handle);
void tp_svc_connection_emit_self_contact_changed (gpointer instance,
    guint arg_Self_Handle,
    const gchar *arg_Self_ID);
void tp_svc_connection_emit_new_channel (gpointer instance,
    const gchar *arg_Object_Path,
    const gchar *arg_Channel_Type,
    guint arg_Handle_Type,
    guint arg_Handle,
    gboolean arg_Suppress_Handler);
void tp_svc_connection_emit_connection_error (gpointer instance,
    const gchar *arg_Error,
    GHashTable *arg_Details);
void tp_svc_connection_emit_status_changed (gpointer instance,
    guint arg_Status,
    guint arg_Reason);

typedef struct _TpSvcConnectionInterfaceAddressing TpSvcConnectionInterfaceAddressing;

typedef struct _TpSvcConnectionInterfaceAddressingClass TpSvcConnectionInterfaceAddressingClass;

GType tp_svc_connection_interface_addressing_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_ADDRESSING \
  (tp_svc_connection_interface_addressing_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ADDRESSING, TpSvcConnectionInterfaceAddressing))
#define TP_IS_SVC_CONNECTION_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ADDRESSING))
#define TP_SVC_CONNECTION_INTERFACE_ADDRESSING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ADDRESSING, TpSvcConnectionInterfaceAddressingClass))


typedef void (*tp_svc_connection_interface_addressing_get_contacts_by_vcard_field_impl) (TpSvcConnectionInterfaceAddressing *self,
    const gchar *in_Field,
    const gchar **in_Addresses,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_addressing_implement_get_contacts_by_vcard_field (TpSvcConnectionInterfaceAddressingClass *klass, tp_svc_connection_interface_addressing_get_contacts_by_vcard_field_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_addressing_return_from_get_contacts_by_vcard_field (DBusGMethodInvocation *context,
    GHashTable *out_Requested,
    GHashTable *out_Attributes);
static inline void
tp_svc_connection_interface_addressing_return_from_get_contacts_by_vcard_field (DBusGMethodInvocation *context,
    GHashTable *out_Requested,
    GHashTable *out_Attributes)
{
  dbus_g_method_return (context,
      out_Requested,
      out_Attributes);
}

typedef void (*tp_svc_connection_interface_addressing_get_contacts_by_uri_impl) (TpSvcConnectionInterfaceAddressing *self,
    const gchar **in_URIs,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_addressing_implement_get_contacts_by_uri (TpSvcConnectionInterfaceAddressingClass *klass, tp_svc_connection_interface_addressing_get_contacts_by_uri_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_addressing_return_from_get_contacts_by_uri (DBusGMethodInvocation *context,
    GHashTable *out_Requested,
    GHashTable *out_Attributes);
static inline void
tp_svc_connection_interface_addressing_return_from_get_contacts_by_uri (DBusGMethodInvocation *context,
    GHashTable *out_Requested,
    GHashTable *out_Attributes)
{
  dbus_g_method_return (context,
      out_Requested,
      out_Attributes);
}


typedef struct _TpSvcConnectionInterfaceAliasing TpSvcConnectionInterfaceAliasing;

typedef struct _TpSvcConnectionInterfaceAliasingClass TpSvcConnectionInterfaceAliasingClass;

GType tp_svc_connection_interface_aliasing_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_ALIASING \
  (tp_svc_connection_interface_aliasing_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_ALIASING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ALIASING, TpSvcConnectionInterfaceAliasing))
#define TP_IS_SVC_CONNECTION_INTERFACE_ALIASING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ALIASING))
#define TP_SVC_CONNECTION_INTERFACE_ALIASING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ALIASING, TpSvcConnectionInterfaceAliasingClass))


typedef void (*tp_svc_connection_interface_aliasing_get_alias_flags_impl) (TpSvcConnectionInterfaceAliasing *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_aliasing_implement_get_alias_flags (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_get_alias_flags_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_aliasing_return_from_get_alias_flags (DBusGMethodInvocation *context,
    guint out_Alias_Flags);
static inline void
tp_svc_connection_interface_aliasing_return_from_get_alias_flags (DBusGMethodInvocation *context,
    guint out_Alias_Flags)
{
  dbus_g_method_return (context,
      out_Alias_Flags);
}

typedef void (*tp_svc_connection_interface_aliasing_request_aliases_impl) (TpSvcConnectionInterfaceAliasing *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_aliasing_implement_request_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_request_aliases_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_aliasing_return_from_request_aliases (DBusGMethodInvocation *context,
    const gchar **out_Aliases);
static inline void
tp_svc_connection_interface_aliasing_return_from_request_aliases (DBusGMethodInvocation *context,
    const gchar **out_Aliases)
{
  dbus_g_method_return (context,
      out_Aliases);
}

typedef void (*tp_svc_connection_interface_aliasing_get_aliases_impl) (TpSvcConnectionInterfaceAliasing *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_aliasing_implement_get_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_get_aliases_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_aliasing_return_from_get_aliases (DBusGMethodInvocation *context,
    GHashTable *out_Aliases);
static inline void
tp_svc_connection_interface_aliasing_return_from_get_aliases (DBusGMethodInvocation *context,
    GHashTable *out_Aliases)
{
  dbus_g_method_return (context,
      out_Aliases);
}

typedef void (*tp_svc_connection_interface_aliasing_set_aliases_impl) (TpSvcConnectionInterfaceAliasing *self,
    GHashTable *in_Aliases,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_aliasing_implement_set_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_set_aliases_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_aliasing_return_from_set_aliases (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_aliasing_return_from_set_aliases (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_aliasing_emit_aliases_changed (gpointer instance,
    const GPtrArray *arg_Aliases);

typedef struct _TpSvcConnectionInterfaceAnonymity TpSvcConnectionInterfaceAnonymity;

typedef struct _TpSvcConnectionInterfaceAnonymityClass TpSvcConnectionInterfaceAnonymityClass;

GType tp_svc_connection_interface_anonymity_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY \
  (tp_svc_connection_interface_anonymity_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_ANONYMITY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY, TpSvcConnectionInterfaceAnonymity))
#define TP_IS_SVC_CONNECTION_INTERFACE_ANONYMITY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY))
#define TP_SVC_CONNECTION_INTERFACE_ANONYMITY_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY, TpSvcConnectionInterfaceAnonymityClass))


void tp_svc_connection_interface_anonymity_emit_anonymity_modes_changed (gpointer instance,
    guint arg_Modes);

typedef struct _TpSvcConnectionInterfaceAvatars TpSvcConnectionInterfaceAvatars;

typedef struct _TpSvcConnectionInterfaceAvatarsClass TpSvcConnectionInterfaceAvatarsClass;

GType tp_svc_connection_interface_avatars_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS \
  (tp_svc_connection_interface_avatars_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_AVATARS(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS, TpSvcConnectionInterfaceAvatars))
#define TP_IS_SVC_CONNECTION_INTERFACE_AVATARS(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS))
#define TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS, TpSvcConnectionInterfaceAvatarsClass))


typedef void (*tp_svc_connection_interface_avatars_get_avatar_requirements_impl) (TpSvcConnectionInterfaceAvatars *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_get_avatar_requirements (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_avatar_requirements_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_get_avatar_requirements (DBusGMethodInvocation *context,
    const gchar **out_MIME_Types,
    guint out_Min_Width,
    guint out_Min_Height,
    guint out_Max_Width,
    guint out_Max_Height,
    guint out_Max_Bytes);
static inline void
tp_svc_connection_interface_avatars_return_from_get_avatar_requirements (DBusGMethodInvocation *context,
    const gchar **out_MIME_Types,
    guint out_Min_Width,
    guint out_Min_Height,
    guint out_Max_Width,
    guint out_Max_Height,
    guint out_Max_Bytes)
{
  dbus_g_method_return (context,
      out_MIME_Types,
      out_Min_Width,
      out_Min_Height,
      out_Max_Width,
      out_Max_Height,
      out_Max_Bytes);
}

typedef void (*tp_svc_connection_interface_avatars_get_avatar_tokens_impl) (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_get_avatar_tokens (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_avatar_tokens_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_get_avatar_tokens (DBusGMethodInvocation *context,
    const gchar **out_Tokens);
static inline void
tp_svc_connection_interface_avatars_return_from_get_avatar_tokens (DBusGMethodInvocation *context,
    const gchar **out_Tokens)
{
  dbus_g_method_return (context,
      out_Tokens);
}

typedef void (*tp_svc_connection_interface_avatars_get_known_avatar_tokens_impl) (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_get_known_avatar_tokens (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_known_avatar_tokens_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_get_known_avatar_tokens (DBusGMethodInvocation *context,
    GHashTable *out_Tokens);
static inline void
tp_svc_connection_interface_avatars_return_from_get_known_avatar_tokens (DBusGMethodInvocation *context,
    GHashTable *out_Tokens)
{
  dbus_g_method_return (context,
      out_Tokens);
}

typedef void (*tp_svc_connection_interface_avatars_request_avatar_impl) (TpSvcConnectionInterfaceAvatars *self,
    guint in_Contact,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_request_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_request_avatar_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_request_avatar (DBusGMethodInvocation *context,
    const GArray *out_Data,
    const gchar *out_MIME_Type);
static inline void
tp_svc_connection_interface_avatars_return_from_request_avatar (DBusGMethodInvocation *context,
    const GArray *out_Data,
    const gchar *out_MIME_Type)
{
  dbus_g_method_return (context,
      out_Data,
      out_MIME_Type);
}

typedef void (*tp_svc_connection_interface_avatars_request_avatars_impl) (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_request_avatars (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_request_avatars_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_request_avatars (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_avatars_return_from_request_avatars (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_avatars_set_avatar_impl) (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Avatar,
    const gchar *in_MIME_Type,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_set_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_set_avatar_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_set_avatar (DBusGMethodInvocation *context,
    const gchar *out_Token);
static inline void
tp_svc_connection_interface_avatars_return_from_set_avatar (DBusGMethodInvocation *context,
    const gchar *out_Token)
{
  dbus_g_method_return (context,
      out_Token);
}

typedef void (*tp_svc_connection_interface_avatars_clear_avatar_impl) (TpSvcConnectionInterfaceAvatars *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_avatars_implement_clear_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_clear_avatar_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_avatars_return_from_clear_avatar (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_avatars_return_from_clear_avatar (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_avatars_emit_avatar_updated (gpointer instance,
    guint arg_Contact,
    const gchar *arg_New_Avatar_Token);
void tp_svc_connection_interface_avatars_emit_avatar_retrieved (gpointer instance,
    guint arg_Contact,
    const gchar *arg_Token,
    const GArray *arg_Avatar,
    const gchar *arg_Type);

typedef struct _TpSvcConnectionInterfaceBalance TpSvcConnectionInterfaceBalance;

typedef struct _TpSvcConnectionInterfaceBalanceClass TpSvcConnectionInterfaceBalanceClass;

GType tp_svc_connection_interface_balance_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE \
  (tp_svc_connection_interface_balance_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_BALANCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE, TpSvcConnectionInterfaceBalance))
#define TP_IS_SVC_CONNECTION_INTERFACE_BALANCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE))
#define TP_SVC_CONNECTION_INTERFACE_BALANCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE, TpSvcConnectionInterfaceBalanceClass))


void tp_svc_connection_interface_balance_emit_balance_changed (gpointer instance,
    const GValueArray *arg_Balance);

typedef struct _TpSvcConnectionInterfaceCapabilities TpSvcConnectionInterfaceCapabilities;

typedef struct _TpSvcConnectionInterfaceCapabilitiesClass TpSvcConnectionInterfaceCapabilitiesClass;

GType tp_svc_connection_interface_capabilities_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CAPABILITIES \
  (tp_svc_connection_interface_capabilities_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CAPABILITIES(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CAPABILITIES, TpSvcConnectionInterfaceCapabilities))
#define TP_IS_SVC_CONNECTION_INTERFACE_CAPABILITIES(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CAPABILITIES))
#define TP_SVC_CONNECTION_INTERFACE_CAPABILITIES_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CAPABILITIES, TpSvcConnectionInterfaceCapabilitiesClass))


typedef void (*tp_svc_connection_interface_capabilities_advertise_capabilities_impl) (TpSvcConnectionInterfaceCapabilities *self,
    const GPtrArray *in_Add,
    const gchar **in_Remove,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_capabilities_implement_advertise_capabilities (TpSvcConnectionInterfaceCapabilitiesClass *klass, tp_svc_connection_interface_capabilities_advertise_capabilities_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_capabilities_return_from_advertise_capabilities (DBusGMethodInvocation *context,
    const GPtrArray *out_Self_Capabilities);
static inline void
tp_svc_connection_interface_capabilities_return_from_advertise_capabilities (DBusGMethodInvocation *context,
    const GPtrArray *out_Self_Capabilities)
{
  dbus_g_method_return (context,
      out_Self_Capabilities);
}

typedef void (*tp_svc_connection_interface_capabilities_get_capabilities_impl) (TpSvcConnectionInterfaceCapabilities *self,
    const GArray *in_Handles,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_capabilities_implement_get_capabilities (TpSvcConnectionInterfaceCapabilitiesClass *klass, tp_svc_connection_interface_capabilities_get_capabilities_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_capabilities_return_from_get_capabilities (DBusGMethodInvocation *context,
    const GPtrArray *out_Contact_Capabilities);
static inline void
tp_svc_connection_interface_capabilities_return_from_get_capabilities (DBusGMethodInvocation *context,
    const GPtrArray *out_Contact_Capabilities)
{
  dbus_g_method_return (context,
      out_Contact_Capabilities);
}

void tp_svc_connection_interface_capabilities_emit_capabilities_changed (gpointer instance,
    const GPtrArray *arg_Caps);

typedef struct _TpSvcConnectionInterfaceCellular TpSvcConnectionInterfaceCellular;

typedef struct _TpSvcConnectionInterfaceCellularClass TpSvcConnectionInterfaceCellularClass;

GType tp_svc_connection_interface_cellular_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR \
  (tp_svc_connection_interface_cellular_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CELLULAR(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR, TpSvcConnectionInterfaceCellular))
#define TP_IS_SVC_CONNECTION_INTERFACE_CELLULAR(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR))
#define TP_SVC_CONNECTION_INTERFACE_CELLULAR_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR, TpSvcConnectionInterfaceCellularClass))


void tp_svc_connection_interface_cellular_emit_imsi_changed (gpointer instance,
    const gchar *arg_IMSI);

typedef struct _TpSvcConnectionInterfaceClientTypes TpSvcConnectionInterfaceClientTypes;

typedef struct _TpSvcConnectionInterfaceClientTypesClass TpSvcConnectionInterfaceClientTypesClass;

GType tp_svc_connection_interface_client_types_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CLIENT_TYPES \
  (tp_svc_connection_interface_client_types_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CLIENT_TYPES(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CLIENT_TYPES, TpSvcConnectionInterfaceClientTypes))
#define TP_IS_SVC_CONNECTION_INTERFACE_CLIENT_TYPES(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CLIENT_TYPES))
#define TP_SVC_CONNECTION_INTERFACE_CLIENT_TYPES_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CLIENT_TYPES, TpSvcConnectionInterfaceClientTypesClass))


typedef void (*tp_svc_connection_interface_client_types_get_client_types_impl) (TpSvcConnectionInterfaceClientTypes *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_client_types_implement_get_client_types (TpSvcConnectionInterfaceClientTypesClass *klass, tp_svc_connection_interface_client_types_get_client_types_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_client_types_return_from_get_client_types (DBusGMethodInvocation *context,
    GHashTable *out_Client_Types);
static inline void
tp_svc_connection_interface_client_types_return_from_get_client_types (DBusGMethodInvocation *context,
    GHashTable *out_Client_Types)
{
  dbus_g_method_return (context,
      out_Client_Types);
}

typedef void (*tp_svc_connection_interface_client_types_request_client_types_impl) (TpSvcConnectionInterfaceClientTypes *self,
    guint in_Contact,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_client_types_implement_request_client_types (TpSvcConnectionInterfaceClientTypesClass *klass, tp_svc_connection_interface_client_types_request_client_types_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_client_types_return_from_request_client_types (DBusGMethodInvocation *context,
    const gchar **out_Client_Types);
static inline void
tp_svc_connection_interface_client_types_return_from_request_client_types (DBusGMethodInvocation *context,
    const gchar **out_Client_Types)
{
  dbus_g_method_return (context,
      out_Client_Types);
}

void tp_svc_connection_interface_client_types_emit_client_types_updated (gpointer instance,
    guint arg_Contact,
    const gchar **arg_Client_Types);

typedef struct _TpSvcConnectionInterfaceContactBlocking TpSvcConnectionInterfaceContactBlocking;

typedef struct _TpSvcConnectionInterfaceContactBlockingClass TpSvcConnectionInterfaceContactBlockingClass;

GType tp_svc_connection_interface_contact_blocking_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING \
  (tp_svc_connection_interface_contact_blocking_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING, TpSvcConnectionInterfaceContactBlocking))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING))
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING, TpSvcConnectionInterfaceContactBlockingClass))


typedef void (*tp_svc_connection_interface_contact_blocking_block_contacts_impl) (TpSvcConnectionInterfaceContactBlocking *self,
    const GArray *in_Contacts,
    gboolean in_Report_Abusive,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_blocking_implement_block_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_block_contacts_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_blocking_return_from_block_contacts (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_blocking_return_from_block_contacts (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_blocking_unblock_contacts_impl) (TpSvcConnectionInterfaceContactBlocking *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_blocking_implement_unblock_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_unblock_contacts_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_blocking_return_from_unblock_contacts (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_blocking_return_from_unblock_contacts (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_blocking_request_blocked_contacts_impl) (TpSvcConnectionInterfaceContactBlocking *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_blocking_implement_request_blocked_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_request_blocked_contacts_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_blocking_return_from_request_blocked_contacts (DBusGMethodInvocation *context,
    GHashTable *out_Contacts);
static inline void
tp_svc_connection_interface_contact_blocking_return_from_request_blocked_contacts (DBusGMethodInvocation *context,
    GHashTable *out_Contacts)
{
  dbus_g_method_return (context,
      out_Contacts);
}

void tp_svc_connection_interface_contact_blocking_emit_blocked_contacts_changed (gpointer instance,
    GHashTable *arg_Blocked_Contacts,
    GHashTable *arg_Unblocked_Contacts);

typedef struct _TpSvcConnectionInterfaceContactCapabilities TpSvcConnectionInterfaceContactCapabilities;

typedef struct _TpSvcConnectionInterfaceContactCapabilitiesClass TpSvcConnectionInterfaceContactCapabilitiesClass;

GType tp_svc_connection_interface_contact_capabilities_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES \
  (tp_svc_connection_interface_contact_capabilities_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES, TpSvcConnectionInterfaceContactCapabilities))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES))
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES, TpSvcConnectionInterfaceContactCapabilitiesClass))


typedef void (*tp_svc_connection_interface_contact_capabilities_update_capabilities_impl) (TpSvcConnectionInterfaceContactCapabilities *self,
    const GPtrArray *in_Handler_Capabilities,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_capabilities_implement_update_capabilities (TpSvcConnectionInterfaceContactCapabilitiesClass *klass, tp_svc_connection_interface_contact_capabilities_update_capabilities_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_capabilities_return_from_update_capabilities (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_capabilities_return_from_update_capabilities (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_capabilities_get_contact_capabilities_impl) (TpSvcConnectionInterfaceContactCapabilities *self,
    const GArray *in_Handles,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_capabilities_implement_get_contact_capabilities (TpSvcConnectionInterfaceContactCapabilitiesClass *klass, tp_svc_connection_interface_contact_capabilities_get_contact_capabilities_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_capabilities_return_from_get_contact_capabilities (DBusGMethodInvocation *context,
    GHashTable *out_Contact_Capabilities);
static inline void
tp_svc_connection_interface_contact_capabilities_return_from_get_contact_capabilities (DBusGMethodInvocation *context,
    GHashTable *out_Contact_Capabilities)
{
  dbus_g_method_return (context,
      out_Contact_Capabilities);
}

void tp_svc_connection_interface_contact_capabilities_emit_contact_capabilities_changed (gpointer instance,
    GHashTable *arg_caps);

typedef struct _TpSvcConnectionInterfaceContactGroups TpSvcConnectionInterfaceContactGroups;

typedef struct _TpSvcConnectionInterfaceContactGroupsClass TpSvcConnectionInterfaceContactGroupsClass;

GType tp_svc_connection_interface_contact_groups_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS \
  (tp_svc_connection_interface_contact_groups_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS, TpSvcConnectionInterfaceContactGroups))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS))
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS, TpSvcConnectionInterfaceContactGroupsClass))


typedef void (*tp_svc_connection_interface_contact_groups_set_contact_groups_impl) (TpSvcConnectionInterfaceContactGroups *self,
    guint in_Contact,
    const gchar **in_Groups,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_set_contact_groups (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_set_contact_groups_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_set_contact_groups (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_set_contact_groups (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_groups_set_group_members_impl) (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_set_group_members (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_set_group_members_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_set_group_members (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_set_group_members (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_groups_add_to_group_impl) (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_add_to_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_add_to_group_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_add_to_group (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_add_to_group (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_groups_remove_from_group_impl) (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_remove_from_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_remove_from_group_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_remove_from_group (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_remove_from_group (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_groups_remove_group_impl) (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_remove_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_remove_group_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_remove_group (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_remove_group (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_groups_rename_group_impl) (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Old_Name,
    const gchar *in_New_Name,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_groups_implement_rename_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_rename_group_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_groups_return_from_rename_group (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_groups_return_from_rename_group (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_contact_groups_emit_groups_changed (gpointer instance,
    const GArray *arg_Contact,
    const gchar **arg_Added,
    const gchar **arg_Removed);
void tp_svc_connection_interface_contact_groups_emit_groups_created (gpointer instance,
    const gchar **arg_Names);
void tp_svc_connection_interface_contact_groups_emit_group_renamed (gpointer instance,
    const gchar *arg_Old_Name,
    const gchar *arg_New_Name);
void tp_svc_connection_interface_contact_groups_emit_groups_removed (gpointer instance,
    const gchar **arg_Names);

typedef struct _TpSvcConnectionInterfaceContactInfo TpSvcConnectionInterfaceContactInfo;

typedef struct _TpSvcConnectionInterfaceContactInfoClass TpSvcConnectionInterfaceContactInfoClass;

GType tp_svc_connection_interface_contact_info_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO \
  (tp_svc_connection_interface_contact_info_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO, TpSvcConnectionInterfaceContactInfo))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACT_INFO(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO))
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO, TpSvcConnectionInterfaceContactInfoClass))


typedef void (*tp_svc_connection_interface_contact_info_get_contact_info_impl) (TpSvcConnectionInterfaceContactInfo *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_info_implement_get_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_get_contact_info_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_info_return_from_get_contact_info (DBusGMethodInvocation *context,
    GHashTable *out_ContactInfo);
static inline void
tp_svc_connection_interface_contact_info_return_from_get_contact_info (DBusGMethodInvocation *context,
    GHashTable *out_ContactInfo)
{
  dbus_g_method_return (context,
      out_ContactInfo);
}

typedef void (*tp_svc_connection_interface_contact_info_refresh_contact_info_impl) (TpSvcConnectionInterfaceContactInfo *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_info_implement_refresh_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_refresh_contact_info_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_info_return_from_refresh_contact_info (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_info_return_from_refresh_contact_info (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_info_request_contact_info_impl) (TpSvcConnectionInterfaceContactInfo *self,
    guint in_Contact,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_info_implement_request_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_request_contact_info_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_info_return_from_request_contact_info (DBusGMethodInvocation *context,
    const GPtrArray *out_Contact_Info);
static inline void
tp_svc_connection_interface_contact_info_return_from_request_contact_info (DBusGMethodInvocation *context,
    const GPtrArray *out_Contact_Info)
{
  dbus_g_method_return (context,
      out_Contact_Info);
}

typedef void (*tp_svc_connection_interface_contact_info_set_contact_info_impl) (TpSvcConnectionInterfaceContactInfo *self,
    const GPtrArray *in_ContactInfo,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_info_implement_set_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_set_contact_info_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_info_return_from_set_contact_info (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_info_return_from_set_contact_info (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_contact_info_emit_contact_info_changed (gpointer instance,
    guint arg_Contact,
    const GPtrArray *arg_ContactInfo);

typedef struct _TpSvcConnectionInterfaceContactList TpSvcConnectionInterfaceContactList;

typedef struct _TpSvcConnectionInterfaceContactListClass TpSvcConnectionInterfaceContactListClass;

GType tp_svc_connection_interface_contact_list_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST \
  (tp_svc_connection_interface_contact_list_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST, TpSvcConnectionInterfaceContactList))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACT_LIST(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST))
#define TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST, TpSvcConnectionInterfaceContactListClass))


typedef void (*tp_svc_connection_interface_contact_list_get_contact_list_attributes_impl) (TpSvcConnectionInterfaceContactList *self,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_get_contact_list_attributes (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_get_contact_list_attributes_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_get_contact_list_attributes (DBusGMethodInvocation *context,
    GHashTable *out_Attributes);
static inline void
tp_svc_connection_interface_contact_list_return_from_get_contact_list_attributes (DBusGMethodInvocation *context,
    GHashTable *out_Attributes)
{
  dbus_g_method_return (context,
      out_Attributes);
}

typedef void (*tp_svc_connection_interface_contact_list_request_subscription_impl) (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    const gchar *in_Message,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_request_subscription (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_request_subscription_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_request_subscription (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_request_subscription (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_list_authorize_publication_impl) (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_authorize_publication (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_authorize_publication_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_authorize_publication (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_authorize_publication (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_list_remove_contacts_impl) (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_remove_contacts (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_remove_contacts_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_remove_contacts (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_remove_contacts (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_list_unsubscribe_impl) (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_unsubscribe (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_unsubscribe_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_unsubscribe (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_unsubscribe (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_list_unpublish_impl) (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_unpublish (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_unpublish_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_unpublish (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_unpublish (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_contact_list_download_impl) (TpSvcConnectionInterfaceContactList *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contact_list_implement_download (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_download_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contact_list_return_from_download (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_contact_list_return_from_download (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_contact_list_emit_contact_list_state_changed (gpointer instance,
    guint arg_Contact_List_State);
void tp_svc_connection_interface_contact_list_emit_contacts_changed_with_id (gpointer instance,
    GHashTable *arg_Changes,
    GHashTable *arg_Identifiers,
    GHashTable *arg_Removals);
void tp_svc_connection_interface_contact_list_emit_contacts_changed (gpointer instance,
    GHashTable *arg_Changes,
    const GArray *arg_Removals);

typedef struct _TpSvcConnectionInterfaceContacts TpSvcConnectionInterfaceContacts;

typedef struct _TpSvcConnectionInterfaceContactsClass TpSvcConnectionInterfaceContactsClass;

GType tp_svc_connection_interface_contacts_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACTS \
  (tp_svc_connection_interface_contacts_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_CONTACTS(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACTS, TpSvcConnectionInterfaceContacts))
#define TP_IS_SVC_CONNECTION_INTERFACE_CONTACTS(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACTS))
#define TP_SVC_CONNECTION_INTERFACE_CONTACTS_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACTS, TpSvcConnectionInterfaceContactsClass))


typedef void (*tp_svc_connection_interface_contacts_get_contact_attributes_impl) (TpSvcConnectionInterfaceContacts *self,
    const GArray *in_Handles,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contacts_implement_get_contact_attributes (TpSvcConnectionInterfaceContactsClass *klass, tp_svc_connection_interface_contacts_get_contact_attributes_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contacts_return_from_get_contact_attributes (DBusGMethodInvocation *context,
    GHashTable *out_Attributes);
static inline void
tp_svc_connection_interface_contacts_return_from_get_contact_attributes (DBusGMethodInvocation *context,
    GHashTable *out_Attributes)
{
  dbus_g_method_return (context,
      out_Attributes);
}

typedef void (*tp_svc_connection_interface_contacts_get_contact_by_id_impl) (TpSvcConnectionInterfaceContacts *self,
    const gchar *in_Identifier,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_contacts_implement_get_contact_by_id (TpSvcConnectionInterfaceContactsClass *klass, tp_svc_connection_interface_contacts_get_contact_by_id_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_contacts_return_from_get_contact_by_id (DBusGMethodInvocation *context,
    guint out_Handle,
    GHashTable *out_Attributes);
static inline void
tp_svc_connection_interface_contacts_return_from_get_contact_by_id (DBusGMethodInvocation *context,
    guint out_Handle,
    GHashTable *out_Attributes)
{
  dbus_g_method_return (context,
      out_Handle,
      out_Attributes);
}


typedef struct _TpSvcConnectionInterfaceLocation TpSvcConnectionInterfaceLocation;

typedef struct _TpSvcConnectionInterfaceLocationClass TpSvcConnectionInterfaceLocationClass;

GType tp_svc_connection_interface_location_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION \
  (tp_svc_connection_interface_location_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_LOCATION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION, TpSvcConnectionInterfaceLocation))
#define TP_IS_SVC_CONNECTION_INTERFACE_LOCATION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION))
#define TP_SVC_CONNECTION_INTERFACE_LOCATION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION, TpSvcConnectionInterfaceLocationClass))


typedef void (*tp_svc_connection_interface_location_get_locations_impl) (TpSvcConnectionInterfaceLocation *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_location_implement_get_locations (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_get_locations_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_location_return_from_get_locations (DBusGMethodInvocation *context,
    GHashTable *out_Locations);
static inline void
tp_svc_connection_interface_location_return_from_get_locations (DBusGMethodInvocation *context,
    GHashTable *out_Locations)
{
  dbus_g_method_return (context,
      out_Locations);
}

typedef void (*tp_svc_connection_interface_location_request_location_impl) (TpSvcConnectionInterfaceLocation *self,
    guint in_Contact,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_location_implement_request_location (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_request_location_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_location_return_from_request_location (DBusGMethodInvocation *context,
    GHashTable *out_Location);
static inline void
tp_svc_connection_interface_location_return_from_request_location (DBusGMethodInvocation *context,
    GHashTable *out_Location)
{
  dbus_g_method_return (context,
      out_Location);
}

typedef void (*tp_svc_connection_interface_location_set_location_impl) (TpSvcConnectionInterfaceLocation *self,
    GHashTable *in_Location,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_location_implement_set_location (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_set_location_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_location_return_from_set_location (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_location_return_from_set_location (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_location_emit_location_updated (gpointer instance,
    guint arg_Contact,
    GHashTable *arg_Location);

typedef struct _TpSvcConnectionInterfaceMailNotification TpSvcConnectionInterfaceMailNotification;

typedef struct _TpSvcConnectionInterfaceMailNotificationClass TpSvcConnectionInterfaceMailNotificationClass;

GType tp_svc_connection_interface_mail_notification_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION \
  (tp_svc_connection_interface_mail_notification_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION, TpSvcConnectionInterfaceMailNotification))
#define TP_IS_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION))
#define TP_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION, TpSvcConnectionInterfaceMailNotificationClass))


typedef void (*tp_svc_connection_interface_mail_notification_request_inbox_url_impl) (TpSvcConnectionInterfaceMailNotification *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_mail_notification_implement_request_inbox_url (TpSvcConnectionInterfaceMailNotificationClass *klass, tp_svc_connection_interface_mail_notification_request_inbox_url_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_mail_notification_return_from_request_inbox_url (DBusGMethodInvocation *context,
    const GValueArray *out_URL);
static inline void
tp_svc_connection_interface_mail_notification_return_from_request_inbox_url (DBusGMethodInvocation *context,
    const GValueArray *out_URL)
{
  dbus_g_method_return (context,
      out_URL);
}

typedef void (*tp_svc_connection_interface_mail_notification_request_mail_url_impl) (TpSvcConnectionInterfaceMailNotification *self,
    const gchar *in_ID,
    const GValue *in_URL_Data,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_mail_notification_implement_request_mail_url (TpSvcConnectionInterfaceMailNotificationClass *klass, tp_svc_connection_interface_mail_notification_request_mail_url_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_mail_notification_return_from_request_mail_url (DBusGMethodInvocation *context,
    const GValueArray *out_URL);
static inline void
tp_svc_connection_interface_mail_notification_return_from_request_mail_url (DBusGMethodInvocation *context,
    const GValueArray *out_URL)
{
  dbus_g_method_return (context,
      out_URL);
}

void tp_svc_connection_interface_mail_notification_emit_mails_received (gpointer instance,
    const GPtrArray *arg_Mails);
void tp_svc_connection_interface_mail_notification_emit_unread_mails_changed (gpointer instance,
    guint arg_Count,
    const GPtrArray *arg_Mails_Added,
    const gchar **arg_Mails_Removed);

typedef struct _TpSvcConnectionInterfacePowerSaving TpSvcConnectionInterfacePowerSaving;

typedef struct _TpSvcConnectionInterfacePowerSavingClass TpSvcConnectionInterfacePowerSavingClass;

GType tp_svc_connection_interface_power_saving_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING \
  (tp_svc_connection_interface_power_saving_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_POWER_SAVING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING, TpSvcConnectionInterfacePowerSaving))
#define TP_IS_SVC_CONNECTION_INTERFACE_POWER_SAVING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING))
#define TP_SVC_CONNECTION_INTERFACE_POWER_SAVING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING, TpSvcConnectionInterfacePowerSavingClass))


typedef void (*tp_svc_connection_interface_power_saving_set_power_saving_impl) (TpSvcConnectionInterfacePowerSaving *self,
    gboolean in_Activate,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_power_saving_implement_set_power_saving (TpSvcConnectionInterfacePowerSavingClass *klass, tp_svc_connection_interface_power_saving_set_power_saving_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_power_saving_return_from_set_power_saving (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_power_saving_return_from_set_power_saving (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_power_saving_emit_power_saving_changed (gpointer instance,
    gboolean arg_Active);

typedef struct _TpSvcConnectionInterfacePresence TpSvcConnectionInterfacePresence;

typedef struct _TpSvcConnectionInterfacePresenceClass TpSvcConnectionInterfacePresenceClass;

GType tp_svc_connection_interface_presence_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE \
  (tp_svc_connection_interface_presence_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE, TpSvcConnectionInterfacePresence))
#define TP_IS_SVC_CONNECTION_INTERFACE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE))
#define TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE, TpSvcConnectionInterfacePresenceClass))


typedef void (*tp_svc_connection_interface_presence_add_status_impl) (TpSvcConnectionInterfacePresence *self,
    const gchar *in_Status,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_add_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_add_status_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_add_status (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_add_status (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_presence_clear_status_impl) (TpSvcConnectionInterfacePresence *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_clear_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_clear_status_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_clear_status (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_clear_status (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_presence_get_presence_impl) (TpSvcConnectionInterfacePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_get_presence (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_get_presence_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_get_presence (DBusGMethodInvocation *context,
    GHashTable *out_Presence);
static inline void
tp_svc_connection_interface_presence_return_from_get_presence (DBusGMethodInvocation *context,
    GHashTable *out_Presence)
{
  dbus_g_method_return (context,
      out_Presence);
}

typedef void (*tp_svc_connection_interface_presence_get_statuses_impl) (TpSvcConnectionInterfacePresence *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_get_statuses (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_get_statuses_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_get_statuses (DBusGMethodInvocation *context,
    GHashTable *out_Available_Statuses);
static inline void
tp_svc_connection_interface_presence_return_from_get_statuses (DBusGMethodInvocation *context,
    GHashTable *out_Available_Statuses)
{
  dbus_g_method_return (context,
      out_Available_Statuses);
}

typedef void (*tp_svc_connection_interface_presence_remove_status_impl) (TpSvcConnectionInterfacePresence *self,
    const gchar *in_Status,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_remove_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_remove_status_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_remove_status (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_remove_status (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_presence_request_presence_impl) (TpSvcConnectionInterfacePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_request_presence (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_request_presence_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_request_presence (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_request_presence (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_presence_set_last_activity_time_impl) (TpSvcConnectionInterfacePresence *self,
    guint in_Time,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_set_last_activity_time (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_set_last_activity_time_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_set_last_activity_time (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_set_last_activity_time (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_presence_set_status_impl) (TpSvcConnectionInterfacePresence *self,
    GHashTable *in_Statuses,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_presence_implement_set_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_set_status_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_presence_return_from_set_status (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_presence_return_from_set_status (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_presence_emit_presence_update (gpointer instance,
    GHashTable *arg_Presence);

typedef struct _TpSvcConnectionInterfaceRenaming TpSvcConnectionInterfaceRenaming;

typedef struct _TpSvcConnectionInterfaceRenamingClass TpSvcConnectionInterfaceRenamingClass;

GType tp_svc_connection_interface_renaming_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_RENAMING \
  (tp_svc_connection_interface_renaming_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_RENAMING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_RENAMING, TpSvcConnectionInterfaceRenaming))
#define TP_IS_SVC_CONNECTION_INTERFACE_RENAMING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_RENAMING))
#define TP_SVC_CONNECTION_INTERFACE_RENAMING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_RENAMING, TpSvcConnectionInterfaceRenamingClass))


typedef void (*tp_svc_connection_interface_renaming_request_rename_impl) (TpSvcConnectionInterfaceRenaming *self,
    const gchar *in_Identifier,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_renaming_implement_request_rename (TpSvcConnectionInterfaceRenamingClass *klass, tp_svc_connection_interface_renaming_request_rename_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_renaming_return_from_request_rename (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_renaming_return_from_request_rename (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_connection_interface_renaming_emit_renamed (gpointer instance,
    guint arg_Original,
    guint arg_New);

typedef struct _TpSvcConnectionInterfaceRequests TpSvcConnectionInterfaceRequests;

typedef struct _TpSvcConnectionInterfaceRequestsClass TpSvcConnectionInterfaceRequestsClass;

GType tp_svc_connection_interface_requests_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS \
  (tp_svc_connection_interface_requests_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_REQUESTS(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS, TpSvcConnectionInterfaceRequests))
#define TP_IS_SVC_CONNECTION_INTERFACE_REQUESTS(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS))
#define TP_SVC_CONNECTION_INTERFACE_REQUESTS_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS, TpSvcConnectionInterfaceRequestsClass))


typedef void (*tp_svc_connection_interface_requests_create_channel_impl) (TpSvcConnectionInterfaceRequests *self,
    GHashTable *in_Request,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_requests_implement_create_channel (TpSvcConnectionInterfaceRequestsClass *klass, tp_svc_connection_interface_requests_create_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_requests_return_from_create_channel (DBusGMethodInvocation *context,
    const gchar *out_Channel,
    GHashTable *out_Properties);
static inline void
tp_svc_connection_interface_requests_return_from_create_channel (DBusGMethodInvocation *context,
    const gchar *out_Channel,
    GHashTable *out_Properties)
{
  dbus_g_method_return (context,
      out_Channel,
      out_Properties);
}

typedef void (*tp_svc_connection_interface_requests_ensure_channel_impl) (TpSvcConnectionInterfaceRequests *self,
    GHashTable *in_Request,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_requests_implement_ensure_channel (TpSvcConnectionInterfaceRequestsClass *klass, tp_svc_connection_interface_requests_ensure_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_requests_return_from_ensure_channel (DBusGMethodInvocation *context,
    gboolean out_Yours,
    const gchar *out_Channel,
    GHashTable *out_Properties);
static inline void
tp_svc_connection_interface_requests_return_from_ensure_channel (DBusGMethodInvocation *context,
    gboolean out_Yours,
    const gchar *out_Channel,
    GHashTable *out_Properties)
{
  dbus_g_method_return (context,
      out_Yours,
      out_Channel,
      out_Properties);
}

void tp_svc_connection_interface_requests_emit_new_channels (gpointer instance,
    const GPtrArray *arg_Channels);
void tp_svc_connection_interface_requests_emit_channel_closed (gpointer instance,
    const gchar *arg_Removed);

typedef struct _TpSvcConnectionInterfaceServicePoint TpSvcConnectionInterfaceServicePoint;

typedef struct _TpSvcConnectionInterfaceServicePointClass TpSvcConnectionInterfaceServicePointClass;

GType tp_svc_connection_interface_service_point_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT \
  (tp_svc_connection_interface_service_point_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_SERVICE_POINT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT, TpSvcConnectionInterfaceServicePoint))
#define TP_IS_SVC_CONNECTION_INTERFACE_SERVICE_POINT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT))
#define TP_SVC_CONNECTION_INTERFACE_SERVICE_POINT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT, TpSvcConnectionInterfaceServicePointClass))


void tp_svc_connection_interface_service_point_emit_service_points_changed (gpointer instance,
    const GPtrArray *arg_Service_Points);

typedef struct _TpSvcConnectionInterfaceSidecars1 TpSvcConnectionInterfaceSidecars1;

typedef struct _TpSvcConnectionInterfaceSidecars1Class TpSvcConnectionInterfaceSidecars1Class;

GType tp_svc_connection_interface_sidecars1_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_SIDECARS1 \
  (tp_svc_connection_interface_sidecars1_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_SIDECARS1(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIDECARS1, TpSvcConnectionInterfaceSidecars1))
#define TP_IS_SVC_CONNECTION_INTERFACE_SIDECARS1(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIDECARS1))
#define TP_SVC_CONNECTION_INTERFACE_SIDECARS1_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIDECARS1, TpSvcConnectionInterfaceSidecars1Class))


typedef void (*tp_svc_connection_interface_sidecars1_ensure_sidecar_impl) (TpSvcConnectionInterfaceSidecars1 *self,
    const gchar *in_Main_Interface,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_sidecars1_implement_ensure_sidecar (TpSvcConnectionInterfaceSidecars1Class *klass, tp_svc_connection_interface_sidecars1_ensure_sidecar_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_sidecars1_return_from_ensure_sidecar (DBusGMethodInvocation *context,
    const gchar *out_Path,
    GHashTable *out_Properties);
static inline void
tp_svc_connection_interface_sidecars1_return_from_ensure_sidecar (DBusGMethodInvocation *context,
    const gchar *out_Path,
    GHashTable *out_Properties)
{
  dbus_g_method_return (context,
      out_Path,
      out_Properties);
}


typedef struct _TpSvcConnectionInterfaceSimplePresence TpSvcConnectionInterfaceSimplePresence;

typedef struct _TpSvcConnectionInterfaceSimplePresenceClass TpSvcConnectionInterfaceSimplePresenceClass;

GType tp_svc_connection_interface_simple_presence_get_type (void);
#define TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE \
  (tp_svc_connection_interface_simple_presence_get_type ())
#define TP_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE, TpSvcConnectionInterfaceSimplePresence))
#define TP_IS_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE))
#define TP_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE, TpSvcConnectionInterfaceSimplePresenceClass))


typedef void (*tp_svc_connection_interface_simple_presence_set_presence_impl) (TpSvcConnectionInterfaceSimplePresence *self,
    const gchar *in_Status,
    const gchar *in_Status_Message,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_simple_presence_implement_set_presence (TpSvcConnectionInterfaceSimplePresenceClass *klass, tp_svc_connection_interface_simple_presence_set_presence_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_simple_presence_return_from_set_presence (DBusGMethodInvocation *context);
static inline void
tp_svc_connection_interface_simple_presence_return_from_set_presence (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_connection_interface_simple_presence_get_presences_impl) (TpSvcConnectionInterfaceSimplePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context);
void tp_svc_connection_interface_simple_presence_implement_get_presences (TpSvcConnectionInterfaceSimplePresenceClass *klass, tp_svc_connection_interface_simple_presence_get_presences_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_interface_simple_presence_return_from_get_presences (DBusGMethodInvocation *context,
    GHashTable *out_Presence);
static inline void
tp_svc_connection_interface_simple_presence_return_from_get_presences (DBusGMethodInvocation *context,
    GHashTable *out_Presence)
{
  dbus_g_method_return (context,
      out_Presence);
}

void tp_svc_connection_interface_simple_presence_emit_presences_changed (gpointer instance,
    GHashTable *arg_Presence);


G_END_DECLS
