#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcProtocol TpSvcProtocol;

typedef struct _TpSvcProtocolClass TpSvcProtocolClass;

GType tp_svc_protocol_get_type (void);
#define TP_TYPE_SVC_PROTOCOL \
  (tp_svc_protocol_get_type ())
#define TP_SVC_PROTOCOL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_PROTOCOL, TpSvcProtocol))
#define TP_IS_SVC_PROTOCOL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_PROTOCOL))
#define TP_SVC_PROTOCOL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_PROTOCOL, TpSvcProtocolClass))


typedef void (*tp_svc_protocol_identify_account_impl) (TpSvcProtocol *self,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context);
void tp_svc_protocol_implement_identify_account (TpSvcProtocolClass *klass, tp_svc_protocol_identify_account_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_protocol_return_from_identify_account (DBusGMethodInvocation *context,
    const gchar *out_Account_ID);
static inline void
tp_svc_protocol_return_from_identify_account (DBusGMethodInvocation *context,
    const gchar *out_Account_ID)
{
  dbus_g_method_return (context,
      out_Account_ID);
}

typedef void (*tp_svc_protocol_normalize_contact_impl) (TpSvcProtocol *self,
    const gchar *in_Contact_ID,
    DBusGMethodInvocation *context);
void tp_svc_protocol_implement_normalize_contact (TpSvcProtocolClass *klass, tp_svc_protocol_normalize_contact_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_protocol_return_from_normalize_contact (DBusGMethodInvocation *context,
    const gchar *out_Normalized_Contact_ID);
static inline void
tp_svc_protocol_return_from_normalize_contact (DBusGMethodInvocation *context,
    const gchar *out_Normalized_Contact_ID)
{
  dbus_g_method_return (context,
      out_Normalized_Contact_ID);
}


typedef struct _TpSvcProtocolInterfaceAddressing TpSvcProtocolInterfaceAddressing;

typedef struct _TpSvcProtocolInterfaceAddressingClass TpSvcProtocolInterfaceAddressingClass;

GType tp_svc_protocol_interface_addressing_get_type (void);
#define TP_TYPE_SVC_PROTOCOL_INTERFACE_ADDRESSING \
  (tp_svc_protocol_interface_addressing_get_type ())
#define TP_SVC_PROTOCOL_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_ADDRESSING, TpSvcProtocolInterfaceAddressing))
#define TP_IS_SVC_PROTOCOL_INTERFACE_ADDRESSING(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_ADDRESSING))
#define TP_SVC_PROTOCOL_INTERFACE_ADDRESSING_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_ADDRESSING, TpSvcProtocolInterfaceAddressingClass))


typedef void (*tp_svc_protocol_interface_addressing_normalize_vcard_address_impl) (TpSvcProtocolInterfaceAddressing *self,
    const gchar *in_VCard_Field,
    const gchar *in_VCard_Address,
    DBusGMethodInvocation *context);
void tp_svc_protocol_interface_addressing_implement_normalize_vcard_address (TpSvcProtocolInterfaceAddressingClass *klass, tp_svc_protocol_interface_addressing_normalize_vcard_address_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_protocol_interface_addressing_return_from_normalize_vcard_address (DBusGMethodInvocation *context,
    const gchar *out_Normalized_VCard_Address);
static inline void
tp_svc_protocol_interface_addressing_return_from_normalize_vcard_address (DBusGMethodInvocation *context,
    const gchar *out_Normalized_VCard_Address)
{
  dbus_g_method_return (context,
      out_Normalized_VCard_Address);
}

typedef void (*tp_svc_protocol_interface_addressing_normalize_contact_uri_impl) (TpSvcProtocolInterfaceAddressing *self,
    const gchar *in_URI,
    DBusGMethodInvocation *context);
void tp_svc_protocol_interface_addressing_implement_normalize_contact_uri (TpSvcProtocolInterfaceAddressingClass *klass, tp_svc_protocol_interface_addressing_normalize_contact_uri_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_protocol_interface_addressing_return_from_normalize_contact_uri (DBusGMethodInvocation *context,
    const gchar *out_Normalized_URI);
static inline void
tp_svc_protocol_interface_addressing_return_from_normalize_contact_uri (DBusGMethodInvocation *context,
    const gchar *out_Normalized_URI)
{
  dbus_g_method_return (context,
      out_Normalized_URI);
}


typedef struct _TpSvcProtocolInterfaceAvatars TpSvcProtocolInterfaceAvatars;

typedef struct _TpSvcProtocolInterfaceAvatarsClass TpSvcProtocolInterfaceAvatarsClass;

GType tp_svc_protocol_interface_avatars_get_type (void);
#define TP_TYPE_SVC_PROTOCOL_INTERFACE_AVATARS \
  (tp_svc_protocol_interface_avatars_get_type ())
#define TP_SVC_PROTOCOL_INTERFACE_AVATARS(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_AVATARS, TpSvcProtocolInterfaceAvatars))
#define TP_IS_SVC_PROTOCOL_INTERFACE_AVATARS(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_AVATARS))
#define TP_SVC_PROTOCOL_INTERFACE_AVATARS_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_AVATARS, TpSvcProtocolInterfaceAvatarsClass))



typedef struct _TpSvcProtocolInterfacePresence TpSvcProtocolInterfacePresence;

typedef struct _TpSvcProtocolInterfacePresenceClass TpSvcProtocolInterfacePresenceClass;

GType tp_svc_protocol_interface_presence_get_type (void);
#define TP_TYPE_SVC_PROTOCOL_INTERFACE_PRESENCE \
  (tp_svc_protocol_interface_presence_get_type ())
#define TP_SVC_PROTOCOL_INTERFACE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_PRESENCE, TpSvcProtocolInterfacePresence))
#define TP_IS_SVC_PROTOCOL_INTERFACE_PRESENCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_PRESENCE))
#define TP_SVC_PROTOCOL_INTERFACE_PRESENCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_PROTOCOL_INTERFACE_PRESENCE, TpSvcProtocolInterfacePresenceClass))




G_END_DECLS
