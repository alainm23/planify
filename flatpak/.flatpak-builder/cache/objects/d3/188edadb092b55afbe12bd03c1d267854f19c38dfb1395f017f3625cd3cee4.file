/*
 * base-media-call-content.h - Header for TpBaseMediaCallContent
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
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

#ifndef __TP_BASE_MEDIA_CALL_CONTENT_H__
#define __TP_BASE_MEDIA_CALL_CONTENT_H__

#include <gio/gio.h>

#include <telepathy-glib/base-call-content.h>
#include <telepathy-glib/call-content-media-description.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpBaseMediaCallContent TpBaseMediaCallContent;
typedef struct _TpBaseMediaCallContentPrivate TpBaseMediaCallContentPrivate;
typedef struct _TpBaseMediaCallContentClass TpBaseMediaCallContentClass;

struct _TpBaseMediaCallContentClass {
  /*<private>*/
  TpBaseCallContentClass parent_class;

  gpointer future[4];
};

struct _TpBaseMediaCallContent {
  /*<private>*/
  TpBaseCallContent parent;

  TpBaseMediaCallContentPrivate *priv;
};

GType tp_base_media_call_content_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_BASE_MEDIA_CALL_CONTENT \
  (tp_base_media_call_content_get_type ())
#define TP_BASE_MEDIA_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), \
      TP_TYPE_BASE_MEDIA_CALL_CONTENT, TpBaseMediaCallContent))
#define TP_BASE_MEDIA_CALL_CONTENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
    TP_TYPE_BASE_MEDIA_CALL_CONTENT, TpBaseMediaCallContentClass))
#define TP_IS_BASE_MEDIA_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_MEDIA_CALL_CONTENT))
#define TP_IS_BASE_MEDIA_CALL_CONTENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_MEDIA_CALL_CONTENT))
#define TP_BASE_MEDIA_CALL_CONTENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
    TP_TYPE_BASE_MEDIA_CALL_CONTENT, TpBaseMediaCallContentClass))

_TP_AVAILABLE_IN_0_18
GHashTable *tp_base_media_call_content_get_local_media_description (
    TpBaseMediaCallContent *self,
    TpHandle contact);

_TP_AVAILABLE_IN_0_18
void tp_base_media_call_content_offer_media_description_async (
    TpBaseMediaCallContent *self,
    TpCallContentMediaDescription *md,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_base_media_call_content_offer_media_description_finish (
    TpBaseMediaCallContent *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#endif /* #ifndef __TP_BASE_MEDIA_CALL_CONTENT_H__*/
