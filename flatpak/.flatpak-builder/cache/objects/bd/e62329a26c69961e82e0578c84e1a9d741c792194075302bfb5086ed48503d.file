/*<private_header>*/

#ifndef __DEBUG_H__
#define __DEBUG_H__

#include "config.h"

#include <glib.h>

#include <telepathy-glib/debug.h>

G_BEGIN_DECLS

/* Please keep this enum in sync with #keys, the section gtkdoc,
 * and #key_to_domain, in debug.c */
typedef enum
{
  TP_DEBUG_MISC          = 1 << 0,
  TP_DEBUG_GROUPS        = 1 << 1,
  TP_DEBUG_PROPERTIES    = 1 << 2,
  TP_DEBUG_IM            = 1 << 3,
  TP_DEBUG_CONNECTION    = 1 << 4,
  TP_DEBUG_PARAMS        = 1 << 5,
  TP_DEBUG_PRESENCE      = 1 << 6,
  TP_DEBUG_MANAGER       = 1 << 7,
  TP_DEBUG_CHANNEL       = 1 << 8,
  TP_DEBUG_PROXY         = 1 << 9,
  TP_DEBUG_HANDLES       = 1 << 10,
  TP_DEBUG_CONTACTS      = 1 << 11,
  TP_DEBUG_ACCOUNTS      = 1 << 12,
  TP_DEBUG_DISPATCHER    = 1 << 13,
  TP_DEBUG_CLIENT        = 1 << 14,
  TP_DEBUG_CONTACT_LISTS = 1 << 15,
  TP_DEBUG_SASL          = 1 << 16,
  TP_DEBUG_ROOM_CONFIG   = 1 << 17,
  TP_DEBUG_CALL          = 1 << 18,
  /* Quis custodiet ipsos custodes? */
  TP_DEBUG_DEBUGGER      = 1 << 19,
  TP_DEBUG_TLS           = 1 << 20
} TpDebugFlags;

gboolean _tp_debug_flag_is_set (TpDebugFlags flag);
void _tp_debug_set_flags (TpDebugFlags flags);
void _tp_log (GLogLevelFlags level, TpDebugFlags flag, const gchar *format, ...)
    G_GNUC_PRINTF (3, 4);
gboolean _tp_debug_is_persistent (void);

#define _TP_DEBUG_IS_PERSISTENT (_tp_debug_is_persistent ())

G_END_DECLS

#endif /* __DEBUG_H__ */

/* ------------------------------------ */

/* Below this point is outside the __DEBUG_H__ guard - so it can take effect
 * more than once. So you can do:
 *
 * #define DEBUG_FLAG TP_DEBUG_ONE_THING
 * #include "telepathy-glib/debug-internal.h"
 * ...
 * DEBUG ("if we're debugging one thing");
 * ...
 * #undef DEBUG_FLAG
 * #define DEBUG_FLAG TP_DEBUG_OTHER_THING
 * #include "telepathy-glib/debug-internal.h"
 * ...
 * DEBUG ("if we're debugging the other thing");
 * ...
 */

#ifdef DEBUG_FLAG

#undef ERROR
#define ERROR(format, ...) \
  do \
    { \
      _tp_log (G_LOG_LEVEL_ERROR, DEBUG_FLAG, "%s: " format, \
          G_STRFUNC, ##__VA_ARGS__); \
      g_assert_not_reached (); \
    } \
  while (0)

#undef CRITICAL
#define CRITICAL(format, ...) \
  _tp_log (G_LOG_LEVEL_CRITICAL, DEBUG_FLAG, "%s: " format, \
      G_STRFUNC, ##__VA_ARGS__)
#undef WARNING
#define WARNING(format, ...) \
  _tp_log (G_LOG_LEVEL_WARNING, DEBUG_FLAG, "%s: " format, \
      G_STRFUNC, ##__VA_ARGS__)
#undef MESSAGE
#define MESSAGE(format, ...) \
  _tp_log (G_LOG_LEVEL_MESSAGE, DEBUG_FLAG, "%s: " format, \
      G_STRFUNC, ##__VA_ARGS__)
#undef INFO
#define INFO(format, ...) \
  _tp_log (G_LOG_LEVEL_INFO, DEBUG_FLAG, "%s: " format, \
      G_STRFUNC, ##__VA_ARGS__)

#undef DEBUG
#undef DEBUGGING

#ifdef ENABLE_DEBUG
#   define DEBUG(format, ...) \
      _tp_log (G_LOG_LEVEL_DEBUG, DEBUG_FLAG, "%s: " format, \
          G_STRFUNC, ##__VA_ARGS__)
#   define DEBUGGING _tp_debug_flag_is_set (DEBUG_FLAG)
#else /* !defined (ENABLE_DEBUG) */
#   ifndef DEBUG_STUB_DEFINED
static inline void
DEBUG (
    const gchar *format,
    ...)
{
}
#   define DEBUG_STUB_DEFINED 1
#   endif // ifndef DEBUG_STUB_DEFINED

#   define DEBUGGING 0
#endif /* !defined (ENABLE_DEBUG) */

#endif /* defined (DEBUG_FLAG) */
