#ifndef TP_GEN_TP_CLI_PROTOCOL_H_INCLUDED
#define TP_GEN_TP_CLI_PROTOCOL_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_protocol_callback_for_identify_account) (TpProxy *proxy,
    const gchar *out_Account_ID,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_protocol_call_identify_account (gpointer proxy,
    gint timeout_ms,
    GHashTable *in_Parameters,
    tp_cli_protocol_callback_for_identify_account callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_protocol_callback_for_normalize_contact) (TpProxy *proxy,
    const gchar *out_Normalized_Contact_ID,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_protocol_call_normalize_contact (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Contact_ID,
    tp_cli_protocol_callback_for_normalize_contact callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_protocol_interface_addressing_callback_for_normalize_vcard_address) (TpProxy *proxy,
    const gchar *out_Normalized_VCard_Address,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_protocol_interface_addressing_call_normalize_vcard_address (gpointer proxy,
    gint timeout_ms,
    const gchar *in_VCard_Field,
    const gchar *in_VCard_Address,
    tp_cli_protocol_interface_addressing_callback_for_normalize_vcard_address callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_protocol_interface_addressing_callback_for_normalize_contact_uri) (TpProxy *proxy,
    const gchar *out_Normalized_URI,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_protocol_interface_addressing_call_normalize_contact_uri (gpointer proxy,
    gint timeout_ms,
    const gchar *in_URI,
    tp_cli_protocol_interface_addressing_callback_for_normalize_contact_uri callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_PROTOCOL_H_INCLUDED) */
