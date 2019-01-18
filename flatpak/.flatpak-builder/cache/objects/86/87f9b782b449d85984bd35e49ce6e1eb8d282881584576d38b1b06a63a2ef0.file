/*
 * Copyright (C) 2007 Collabora Ltd.
 * Copyright (C) 2007 Nokia Corporation
 * Copyright (C) 2008-2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef __CHAMPLAIN_DEBUG_H__
#define __CHAMPLAIN_DEBUG_H__

#include "config.h"

#include <glib.h>

G_BEGIN_DECLS

/* Please keep this enum in sync with #keys in champlain-debug.c */
typedef enum
{
  CHAMPLAIN_DEBUG_LOADING = 1 << 1,
  CHAMPLAIN_DEBUG_ENGINE = 1 << 2,
  CHAMPLAIN_DEBUG_VIEW = 1 << 3,
  CHAMPLAIN_DEBUG_NETWORK = 1 << 4,
  CHAMPLAIN_DEBUG_CACHE = 1 << 5,
  CHAMPLAIN_DEBUG_SELECTION = 1 << 6,
  CHAMPLAIN_DEBUG_MEMPHIS = 1 << 7,
  CHAMPLAIN_DEBUG_OTHER = 1 << 8,
} ChamplainDebugFlags;

gboolean champlain_debug_flag_is_set (ChamplainDebugFlags flag);
void champlain_debug (ChamplainDebugFlags flag,
    const gchar *format,
    ...) G_GNUC_PRINTF (2, 3);
void champlain_debug_set_flags (const gchar *flags_string);
G_END_DECLS

#endif /* __CHAMPLAIN_DEBUG_H__ */

/* ------------------------------------ */

/* Below this point is outside the __DEBUG_H__ guard - so it can take effect
 * more than once. So you can do:
 *
 * #define DEBUG_FLAG CHAMPLAIN_DEBUG_ONE_THING
 * #include "debug.h"
 * ...
 * DEBUG ("if we're debugging one thing");
 * ...
 * #undef DEBUG_FLAG
 * #define DEBUG_FLAG CHAMPLAIN_DEBUG_OTHER_THING
 * #include "debug.h"
 * ...
 * DEBUG ("if we're debugging the other thing");
 * ...
 */

#ifdef DEBUG_FLAG
#ifdef ENABLE_DEBUG

#undef DEBUG
#define DEBUG(format, ...) \
  champlain_debug (DEBUG_FLAG, "%s: " format, G_STRFUNC, ## __VA_ARGS__)

#undef DEBUGGING
#define DEBUGGING champlain_debug_flag_is_set (DEBUG_FLAG)

#else /* !defined (ENABLE_DEBUG) */

#undef DEBUG
#define DEBUG(format, ...) do {} while (0)

#undef DEBUGGING
#define DEBUGGING 0

#endif /* !defined (ENABLE_DEBUG) */
#endif /* defined (DEBUG_FLAG) */
