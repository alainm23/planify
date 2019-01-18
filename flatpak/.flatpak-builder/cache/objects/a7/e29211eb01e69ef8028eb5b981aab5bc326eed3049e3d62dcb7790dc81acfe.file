#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_DEBUG_H__
#define __TP_DEBUG_H__

#include <glib.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

void tp_debug_set_flags (const gchar *flags_string);

void tp_debug_set_persistent (gboolean persistent);

void tp_debug_divert_messages (const gchar *filename);

void tp_debug_timestamped_log_handler (const gchar *log_domain,
    GLogLevelFlags log_level, const gchar *message, gpointer ignored);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED
void tp_debug_set_flags_from_string (const gchar *flags_string);

_TP_DEPRECATED
void tp_debug_set_flags_from_env (const gchar *var);

_TP_DEPRECATED
void tp_debug_set_all_flags (void);
#endif

G_END_DECLS

#endif
