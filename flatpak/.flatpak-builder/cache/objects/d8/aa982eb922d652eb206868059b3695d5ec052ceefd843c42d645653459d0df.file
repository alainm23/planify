/*
 * Copyright (C) 2011 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/*
 * This file contains some special GObject-centric debugging macros that
 * can be compiled completely out out of the final binary 
 */

#include <glib.h>

#ifndef _UNITY_TRACE_LOG_H
#define _UNITY_TRACE_LOG_H

G_BEGIN_DECLS

/*
 * Make trace() a noop if ENABLE_UNITY_TRACE_LOG is not defined
 */
#ifdef ENABLE_UNITY_TRACE_LOG

void     unity_trace_log_object_va   (void *obj, const gchar *format, va_list args);
void     unity_trace_log_object_real (void *obj, const gchar *format, ...);

#   ifdef G_HAVE_ISO_VARARGS
#	   define unity_trace_log(...) g_log (G_LOG_DOMAIN, \
                              G_LOG_LEVEL_DEBUG,  \
                              __VA_ARGS__)
#	   define unity_trace_log_object(object, ...) unity_trace_log_object_real (object, __VA_ARGS__)

#   elif defined(G_HAVE_GNUC_VARARGS)
#	   define unity_trace_log(format...) g_log (G_LOG_DOMAIN,   \
                                    G_LOG_LEVEL_DEBUG,	\
                                    format)
#	   define unity_trace_log_object(object, format...) unity_trace_log_object_real (object, format)
#   else   /* no varargs macros */
static void
unity_trace_log (const gchar *format,
                 ...)
{
	va_list args;
	va_start (args, format);
	g_logv (TRACE_LOG_DOMAIN, G_LOG_LEVEL_DEBUG, format, args);
	va_end (args);
}

static void
unity_trace_log_object (void        *obj,
                        const gchar *format,
                        ...)
{
	va_list args;
	va_start (args, format);
	unity_trace_log_object_va (obj, format, args);
	va_end (args);
}

#   endif  /* !__GNUC__ */

#else /* NO TRACE LOGGING OUTPUT */

#   ifdef G_HAVE_ISO_VARARGS
#	   define unity_trace_log(...) G_STMT_START{ (void)0; }G_STMT_END
#	   define unity_trace_log_object(object, ...) G_STMT_START{ (void)0; }G_STMT_END
#   elif defined(G_HAVE_GNUC_VARARGS)
#	   define unity_trace_log(format...) G_STMT_START{ (void)0; }G_STMT_END
#	   define unity_trace_log_object(object, format...) G_STMT_START{ (void)0; }G_STMT_END
#   else   /* no varargs macros */

static void unity_trace_log (const gchar *format, ...) { ; }
static void unity_trace_log_object (GObject *obj, const gchar *format, ...) { ; }

#   endif /* !__GNUC__ */

#endif /* ENABLE_UNITY_TRACE_LOG */

#ifdef ENABLE_LTTNG
void     unity_trace_tracepoint_va (const gchar *format, va_list args);

static void unity_trace_tracepoint (const gchar *format, ...)
{
  va_list args;
  va_start (args, format);
  unity_trace_tracepoint_va (format, args);
  va_end (args);
}
#else
#   ifdef G_HAVE_ISO_VARARGS
#	   define unity_trace_tracepoint(...) G_STMT_START{ (void)0; }G_STMT_END
#   elif defined(G_HAVE_GNUC_VARARGS)
#	   define unity_trace_tracepoint(format...) G_STMT_START{ (void)0; }G_STMT_END
#   else  /* no varargs macros */
static void unity_trace_tracepoint (const gchar *format, ...) { ; }
#   endif

#endif /* ENABLE_LTTNG */


G_END_DECLS

#endif /* _UNITY_TRACE_LOG_H */

