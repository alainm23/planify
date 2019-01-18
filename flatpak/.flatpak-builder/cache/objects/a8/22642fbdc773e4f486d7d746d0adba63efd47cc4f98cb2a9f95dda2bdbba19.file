/*
 * Simple implementation of an Observer
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

#ifndef __TP_SIMPLE_OBSERVER_H__
#define __TP_SIMPLE_OBSERVER_H__

#include <dbus/dbus-glib.h>
#include <glib-object.h>

#include <telepathy-glib/base-client.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpSimpleObserver TpSimpleObserver;
typedef struct _TpSimpleObserverClass TpSimpleObserverClass;
typedef struct _TpSimpleObserverPrivate TpSimpleObserverPrivate;

struct _TpSimpleObserverClass {
    /*<private>*/
    TpBaseClientClass parent_class;
    GCallback _padding[7];
};

struct _TpSimpleObserver {
    /*<private>*/
    TpBaseClient parent;
    TpSimpleObserverPrivate *priv;
};

GType tp_simple_observer_get_type (void);

#define TP_TYPE_SIMPLE_OBSERVER \
  (tp_simple_observer_get_type ())
#define TP_SIMPLE_OBSERVER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_SIMPLE_OBSERVER, \
                               TpSimpleObserver))
#define TP_SIMPLE_OBSERVER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_SIMPLE_OBSERVER, \
                            TpSimpleObserverClass))
#define TP_IS_SIMPLE_OBSERVER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_SIMPLE_OBSERVER))
#define TP_IS_SIMPLE_OBSERVER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_SIMPLE_OBSERVER))
#define TP_SIMPLE_OBSERVER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_SIMPLE_OBSERVER, \
                              TpSimpleObserverClass))

typedef void (*TpSimpleObserverObserveChannelsImpl) (
    TpSimpleObserver *observer,
    TpAccount *account,
    TpConnection *connection,
    GList *channels,
    TpChannelDispatchOperation *dispatch_operation,
    GList *requests,
    TpObserveChannelsContext *context,
    gpointer user_data);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_16_FOR (tp_simple_observer_new_with_factory)
TpBaseClient * tp_simple_observer_new (TpDBusDaemon *dbus,
    gboolean recover,
    const gchar *name,
    gboolean uniquify,
    TpSimpleObserverObserveChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy);
#endif

TpBaseClient *tp_simple_observer_new_with_am (
    TpAccountManager *account_manager,
    gboolean recover,
    const gchar *name,
    gboolean uniquify,
    TpSimpleObserverObserveChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy);

_TP_AVAILABLE_IN_0_16
TpBaseClient *tp_simple_observer_new_with_factory (
    TpSimpleClientFactory *factory,
    gboolean recover,
    const gchar *name,
    gboolean uniquify,
    TpSimpleObserverObserveChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy);

G_END_DECLS

#endif
