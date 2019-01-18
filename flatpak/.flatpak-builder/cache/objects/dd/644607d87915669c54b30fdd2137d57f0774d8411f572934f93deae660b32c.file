/* DTMF utility functions
 *
 * Copyright © 2010 Collabora Ltd.
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_DTMF_H__
#define __TP_DTMF_H__

#include <glib-object.h>
#include <telepathy-glib/enums.h>

gchar tp_dtmf_event_to_char (TpDTMFEvent event);

typedef struct _TpDTMFPlayer TpDTMFPlayer;
typedef struct _TpDTMFPlayerClass TpDTMFPlayerClass;
typedef struct _TpDTMFPlayerPrivate TpDTMFPlayerPrivate;

GType tp_dtmf_player_get_type (void);

#define TP_TYPE_DTMF_PLAYER \
  (tp_dtmf_player_get_type ())
#define TP_DTMF_PLAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_DTMF_PLAYER, \
                               TpDTMFPlayer))
#define TP_DTMF_PLAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_DTMF_PLAYER, \
                            TpDTMFPlayerClass))
#define TP_IS_DTMF_PLAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_DTMF_PLAYER))
#define TP_IS_DTMF_PLAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_DTMF_PLAYER))
#define TP_DTMF_PLAYER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_DTMF_PLAYER, \
                              TpDTMFPlayerClass))

struct _TpDTMFPlayer
{
  GObject parent;
  TpDTMFPlayerPrivate *priv;
};

struct _TpDTMFPlayerClass
{
  GObjectClass parent_class;
  gpointer priv;
};

TpDTMFPlayer *tp_dtmf_player_new (void);

gboolean tp_dtmf_player_play (TpDTMFPlayer *self,
    const gchar *tones, guint tone_ms, guint gap_ms, guint pause_ms,
    GError **error);

gboolean tp_dtmf_player_is_active (TpDTMFPlayer *self);

void tp_dtmf_player_cancel (TpDTMFPlayer *self);

#endif
