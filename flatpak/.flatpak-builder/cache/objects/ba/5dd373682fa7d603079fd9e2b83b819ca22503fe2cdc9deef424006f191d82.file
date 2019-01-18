/*
 * base-call-content.h - Header for TpBaseBaseCallContent
 * Copyright © 2009–2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
 * @author Will Thompson <will.thompson@collabora.co.uk>
 * @author Xavier Claessens <xavier.claessens@collabora.co.uk>
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

#ifndef TP_BASE_CALL_CONTENT_H
#define TP_BASE_CALL_CONTENT_H

#include <glib-object.h>

#include <telepathy-glib/base-call-stream.h>
#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpBaseCallContent TpBaseCallContent;
typedef struct _TpBaseCallContentPrivate TpBaseCallContentPrivate;
typedef struct _TpBaseCallContentClass TpBaseCallContentClass;

typedef GPtrArray * (*TpBaseCallContentGetInterfacesFunc) (
    TpBaseCallContent *self);
typedef void (*TpBaseCallContentDeinitFunc) (TpBaseCallContent *self);
typedef gboolean (*TpBaseCallContentStartToneFunc) (TpBaseCallContent *self,
    TpDTMFEvent event,
    GError **error);
typedef gboolean (*TpBaseCallContentStopToneFunc) (TpBaseCallContent *self,
    GError **error);
typedef gboolean (*TpBaseCallContentMultipleTonesFunc) (TpBaseCallContent *self,
    const gchar *tones,
    GError **error);

struct _TpBaseCallContentClass {
  /*<private>*/
  GObjectClass parent_class;

  TpDBusPropertiesMixinClass dbus_props_class;

  /*< public >*/
  TpBaseCallContentDeinitFunc deinit;
  TpBaseCallContentGetInterfacesFunc get_interfaces;

  TpBaseCallContentStartToneFunc start_tone;
  TpBaseCallContentStopToneFunc stop_tone;
  TpBaseCallContentMultipleTonesFunc multiple_tones;

  /*<private>*/
  gpointer future[4];
};

struct _TpBaseCallContent {
  /*<private>*/
  GObject parent;

  TpBaseCallContentPrivate *priv;
};

_TP_AVAILABLE_IN_0_18
GType tp_base_call_content_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_BASE_CALL_CONTENT \
  (tp_base_call_content_get_type ())
#define TP_BASE_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), \
      TP_TYPE_BASE_CALL_CONTENT, TpBaseCallContent))
#define TP_BASE_CALL_CONTENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
    TP_TYPE_BASE_CALL_CONTENT, TpBaseCallContentClass))
#define TP_IS_BASE_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_CALL_CONTENT))
#define TP_IS_BASE_CALL_CONTENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_CALL_CONTENT))
#define TP_BASE_CALL_CONTENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
    TP_TYPE_BASE_CALL_CONTENT, TpBaseCallContentClass))

_TP_AVAILABLE_IN_0_18
TpBaseConnection *tp_base_call_content_get_connection (TpBaseCallContent *self);
_TP_AVAILABLE_IN_0_18
const gchar *tp_base_call_content_get_object_path (TpBaseCallContent *self);

_TP_AVAILABLE_IN_0_18
const gchar *tp_base_call_content_get_name (TpBaseCallContent *self);
_TP_AVAILABLE_IN_0_18
TpMediaStreamType tp_base_call_content_get_media_type (TpBaseCallContent *self);
_TP_AVAILABLE_IN_0_18
TpCallContentDisposition tp_base_call_content_get_disposition (
    TpBaseCallContent *self);

_TP_AVAILABLE_IN_0_18
GList *tp_base_call_content_get_streams (TpBaseCallContent *self);
_TP_AVAILABLE_IN_0_18
void tp_base_call_content_add_stream (TpBaseCallContent *self,
    TpBaseCallStream *stream);
_TP_AVAILABLE_IN_0_18
void tp_base_call_content_remove_stream (TpBaseCallContent *self,
    TpBaseCallStream *stream,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message);

G_END_DECLS

#endif /* #ifndef __TP_BASE_CALL_CONTENT_H__*/
