/*
 * text-mixin.h - Header for GabbleTextMixin
 * Copyright (C) 2006 Collabora Ltd.
 * Copyright (C) 2006 Nokia Corporation
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

#ifndef __TP_TEXT_MIXIN_H__
#define __TP_TEXT_MIXIN_H__

#include <time.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/handle-repo.h>
#include <telepathy-glib/svc-channel.h>
#include "util.h"

G_BEGIN_DECLS

#ifndef TP_DISABLE_DEPRECATED

typedef struct _TpTextMixinClass TpTextMixinClass;
typedef struct _TpTextMixinClassPrivate TpTextMixinClassPrivate;
typedef struct _TpTextMixin TpTextMixin;
typedef struct _TpTextMixinPrivate TpTextMixinPrivate;

/**
 * TpTextMixinClass:
 *
 * Structure to be included in the class structure of objects that
 * use this mixin. Initialize it with tp_text_mixin_class_init().
 *
 * There are no public fields.
 */
struct _TpTextMixinClass {
    /*<private>*/
    TpTextMixinClassPrivate *priv;
};

/**
 * TpTextMixin:
 *
 * Structure to be included in the instance structure of objects that
 * use this mixin. Initialize it with tp_text_mixin_init().
 *
 * There are no public fields.
 */
struct _TpTextMixin {
  /*<private>*/
  TpTextMixinPrivate *priv;
};

/* TYPE MACROS */
#define TP_TEXT_MIXIN_CLASS_OFFSET_QUARK \
  (tp_text_mixin_class_get_offset_quark ())
#define TP_TEXT_MIXIN_CLASS_OFFSET(o) \
  tp_mixin_class_get_offset (o, TP_TEXT_MIXIN_CLASS_OFFSET_QUARK)
#define TP_TEXT_MIXIN_CLASS(o) \
  ((TpTextMixinClass *) tp_mixin_offset_cast (o, \
    TP_TEXT_MIXIN_CLASS_OFFSET (o)))

#define TP_TEXT_MIXIN_OFFSET_QUARK (tp_text_mixin_get_offset_quark ())
#define TP_TEXT_MIXIN_OFFSET(o) \
  tp_mixin_instance_get_offset (o, TP_TEXT_MIXIN_OFFSET_QUARK)
#define TP_TEXT_MIXIN(o) \
  ((TpTextMixin *) tp_mixin_offset_cast (o, TP_TEXT_MIXIN_OFFSET (o)))

_TP_DEPRECATED_IN_0_20
GQuark tp_text_mixin_class_get_offset_quark (void);
_TP_DEPRECATED_IN_0_20
GQuark tp_text_mixin_get_offset_quark (void);

_TP_DEPRECATED_IN_0_20
void tp_text_mixin_class_init (GObjectClass *obj_cls, glong offset);

_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_init)
void tp_text_mixin_init (GObject *obj, glong offset,
    TpHandleRepoIface *contacts_repo);
_TP_DEPRECATED_IN_0_20
void tp_text_mixin_set_message_types (GObject *obj, ...);
_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_finalize)
void tp_text_mixin_finalize (GObject *obj);

_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_take_received)
gboolean tp_text_mixin_receive_with_flags (GObject *obj,
    TpChannelTextMessageType type, TpHandle sender, time_t timestamp,
    const char *text, TpChannelTextMessageFlags flags);
_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_take_received)
gboolean tp_text_mixin_receive (GObject *obj, TpChannelTextMessageType type,
    TpHandle sender, time_t timestamp, const char *text);
_TP_DEPRECATED_IN_0_20
gboolean tp_text_mixin_acknowledge_pending_messages (GObject *obj,
    const GArray * ids, GError **error);
_TP_DEPRECATED_IN_0_20
gboolean tp_text_mixin_list_pending_messages (GObject *obj, gboolean clear,
    GPtrArray ** ret, GError **error);
_TP_DEPRECATED_IN_0_20
gboolean tp_text_mixin_get_message_types (GObject *obj, GArray **ret,
    GError **error);
_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_clear)
void tp_text_mixin_clear (GObject *obj);

_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_has_pending_messages)
gboolean tp_text_mixin_has_pending_messages (GObject *obj,
    TpHandle *first_sender);
_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_set_rescued)
void tp_text_mixin_set_rescued (GObject *obj);

_TP_DEPRECATED_IN_0_20_FOR (tp_message_mixin_text_iface_init)
void tp_text_mixin_iface_init (gpointer g_iface, gpointer iface_data);

#endif

G_END_DECLS

#endif /* #ifndef __TP_TEXT_MIXIN_H__ */
