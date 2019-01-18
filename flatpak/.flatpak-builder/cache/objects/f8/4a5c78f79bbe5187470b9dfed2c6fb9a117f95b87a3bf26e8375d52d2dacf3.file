/*
 * Factory creating higher level proxy objects
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

#ifndef __TP_AUTOMATIC_PROXY_FACTORY_H__
#define __TP_AUTOMATIC_PROXY_FACTORY_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpAutomaticProxyFactory TpAutomaticProxyFactory;
typedef struct _TpAutomaticProxyFactoryClass TpAutomaticProxyFactoryClass;

struct _TpAutomaticProxyFactoryClass {
    /*<public>*/
    GObjectClass parent_class;
};

struct _TpAutomaticProxyFactory {
    /*<private>*/
    GObject parent;
};

GType tp_automatic_proxy_factory_get_type (void);

#define TP_TYPE_AUTOMATIC_PROXY_FACTORY \
  (tp_automatic_proxy_factory_get_type ())
#define TP_AUTOMATIC_PROXY_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_AUTOMATIC_PROXY_FACTORY, \
                               TpAutomaticProxyFactory))
#define TP_AUTOMATIC_PROXY_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_AUTOMATIC_PROXY_FACTORY, \
                            TpAutomaticProxyFactoryClass))
#define TP_IS_AUTOMATIC_PROXY_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_AUTOMATIC_PROXY_FACTORY))
#define TP_IS_AUTOMATIC_PROXY_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_AUTOMATIC_PROXY_FACTORY))
#define TP_AUTOMATIC_PROXY_FACTORY_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_AUTOMATIC_PROXY_FACTORY, \
                              TpAutomaticProxyFactoryClass))

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_16_FOR (tp_automatic_client_factory_new)
TpAutomaticProxyFactory * tp_automatic_proxy_factory_new (void);

_TP_DEPRECATED_IN_0_16_FOR (tp_automatic_client_factory_new)
TpAutomaticProxyFactory * tp_automatic_proxy_factory_dup (void);
#endif

G_END_DECLS

#endif
