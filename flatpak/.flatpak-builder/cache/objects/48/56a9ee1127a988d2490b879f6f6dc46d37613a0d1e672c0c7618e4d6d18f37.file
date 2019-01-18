/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 *          Veerapuram Varadhan <vvaradhan@novell.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_PROXY_H
#define E_PROXY_H

#include <libsoup/soup-uri.h>

/* Standard GObject macros */
#define E_TYPE_PROXY \
	(e_proxy_get_type ())
#define E_PROXY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_PROXY, EProxy))
#define E_PROXY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_PROXY, EProxyClass))
#define E_IS_PROXY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_PROXY))
#define E_IS_PROXY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_PROXY))
#define E_PROXY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_PROXY, EProxyClass))

G_BEGIN_DECLS

typedef struct _EProxy EProxy;
typedef struct _EProxyClass EProxyClass;
typedef struct _EProxyPrivate EProxyPrivate;

/**
 * EProxy:
 *
 * Contains only private data that should be read and manipulated using the
 * function below.
 *
 * Since: 2.24
 **/
struct _EProxy {
	/*< private >*/
	GObject parent;
	EProxyPrivate *priv;
};

struct _EProxyClass {
	GObjectClass parent_class;

	/* Signals  */
	void (*changed) (EProxy *proxy);
};

GType		e_proxy_get_type		(void) G_GNUC_CONST;
EProxy *	e_proxy_new			(void);
void		e_proxy_setup_proxy		(EProxy *proxy);
SoupURI *	e_proxy_peek_uri_for		(EProxy *proxy,
						 const gchar *uri);
gboolean	e_proxy_require_proxy_for_uri	(EProxy *proxy,
						 const gchar *uri);

G_END_DECLS

#endif /* E_PROXY_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */
