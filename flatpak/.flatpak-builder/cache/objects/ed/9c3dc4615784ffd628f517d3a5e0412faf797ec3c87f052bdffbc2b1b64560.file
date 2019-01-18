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

#include "config.h"

#include "champlain-debug.h"

#include <errno.h>
#include <fcntl.h>
#include <glib.h>
#include <glib/gstdio.h>
#include <stdarg.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef ENABLE_DEBUG

static ChamplainDebugFlags flags = 0;

static GDebugKey keys[] = {
  { "Loading", CHAMPLAIN_DEBUG_LOADING },
  { "Engine", CHAMPLAIN_DEBUG_ENGINE },
  { "View", CHAMPLAIN_DEBUG_VIEW },
  { "Network", CHAMPLAIN_DEBUG_NETWORK },
  { "Cache", CHAMPLAIN_DEBUG_CACHE },
  { "Selection", CHAMPLAIN_DEBUG_SELECTION },
  { "Memphis", CHAMPLAIN_DEBUG_MEMPHIS },
  { "Other", CHAMPLAIN_DEBUG_OTHER },
  { 0, }
};

static void
debug_set_flags (ChamplainDebugFlags new_flags)
{
  flags |= new_flags;
}


void
champlain_debug_set_flags (const gchar *flags_string)
{
  guint nkeys;

  for (nkeys = 0; keys[nkeys].value; nkeys++)
    ;

  if (flags_string)
    debug_set_flags (g_parse_debug_string (flags_string, keys, nkeys));
}


gboolean
champlain_debug_flag_is_set (ChamplainDebugFlags flag)
{
  return (flag & flags) != 0;
}


void
champlain_debug (ChamplainDebugFlags flag,
    const gchar *format,
    ...)
{
  if (flag & flags)
    {
      va_list args;
      va_start (args, format);
      g_logv (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG, format, args);
      va_end (args);
    }
}


#else

gboolean
champlain_debug_flag_is_set (ChamplainDebugFlags flag)
{
  return FALSE;
}


void
champlain_debug (ChamplainDebugFlags flag, const gchar *format, ...)
{
}


void
champlain_debug_set_flags (const gchar *flags_string)
{
}


#endif /* ENABLE_DEBUG */
