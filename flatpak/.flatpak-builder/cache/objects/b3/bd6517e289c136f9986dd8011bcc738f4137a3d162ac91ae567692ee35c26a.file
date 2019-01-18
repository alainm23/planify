#ifndef TP_GEN_TP_CLI_CALL_CONTENT_MEDIA_DESCRIPTION_H_INCLUDED
#define TP_GEN_TP_CLI_CALL_CONTENT_MEDIA_DESCRIPTION_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_call_content_media_description_callback_for_accept) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_media_description_call_accept (gpointer proxy,
    gint timeout_ms,
    GHashTable *in_Local_Media_Description,
    tp_cli_call_content_media_description_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_media_description_callback_for_reject) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_media_description_call_reject (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Reason,
    tp_cli_call_content_media_description_callback_for_reject callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CALL_CONTENT_MEDIA_DESCRIPTION_H_INCLUDED) */
