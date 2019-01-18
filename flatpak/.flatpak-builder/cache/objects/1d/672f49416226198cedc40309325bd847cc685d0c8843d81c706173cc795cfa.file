/*
 * Factory for specialized TpChannel subclasses.
 *
 * Copyright © 2011 Collabora Ltd.
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

#ifndef __TP_AUTOMATIC_CLIENT_FACTORY_H__
#define __TP_AUTOMATIC_CLIENT_FACTORY_H__

#include <telepathy-glib/call-channel.h>
#include <telepathy-glib/dbus-tube-channel.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/file-transfer-channel.h>
#include <telepathy-glib/simple-client-factory.h>
#include <telepathy-glib/stream-tube-channel.h>
#include <telepathy-glib/text-channel.h>

G_BEGIN_DECLS

typedef struct _TpAutomaticClientFactory TpAutomaticClientFactory;
typedef struct _TpAutomaticClientFactoryClass TpAutomaticClientFactoryClass;

struct _TpAutomaticClientFactoryClass {
    /*<public>*/
    TpSimpleClientFactoryClass parent_class;
};

struct _TpAutomaticClientFactory {
    /*<private>*/
    TpSimpleClientFactory parent;
};

_TP_AVAILABLE_IN_0_16
GType tp_automatic_client_factory_get_type (void);

#define TP_TYPE_AUTOMATIC_CLIENT_FACTORY \
  (tp_automatic_client_factory_get_type ())
#define TP_AUTOMATIC_CLIENT_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_AUTOMATIC_CLIENT_FACTORY, \
                               TpAutomaticClientFactory))
#define TP_AUTOMATIC_CLIENT_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_AUTOMATIC_CLIENT_FACTORY, \
                            TpAutomaticClientFactoryClass))
#define TP_IS_AUTOMATIC_CLIENT_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_AUTOMATIC_CLIENT_FACTORY))
#define TP_IS_AUTOMATIC_CLIENT_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_AUTOMATIC_CLIENT_FACTORY))
#define TP_AUTOMATIC_CLIENT_FACTORY_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_AUTOMATIC_CLIENT_FACTORY, \
                              TpAutomaticClientFactoryClass))

_TP_AVAILABLE_IN_0_16
TpAutomaticClientFactory *tp_automatic_client_factory_new (TpDBusDaemon *dbus);

G_END_DECLS

#endif
