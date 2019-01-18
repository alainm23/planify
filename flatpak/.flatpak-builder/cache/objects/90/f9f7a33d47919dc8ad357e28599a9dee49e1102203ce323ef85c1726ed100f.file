/*
 * e-soup-auth-bearer.h
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedateserver.h> should be included directly."
#endif

#ifndef E_SOUP_AUTH_BEARER_H
#define E_SOUP_AUTH_BEARER_H

#include <libsoup/soup.h>

/* Standard GObject macros */
#define E_TYPE_SOUP_AUTH_BEARER \
	(e_soup_auth_bearer_get_type ())
#define E_SOUP_AUTH_BEARER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOUP_AUTH_BEARER, ESoupAuthBearer))
#define E_SOUP_AUTH_BEARER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOUP_AUTH_BEARER, ESoupAuthBearerClass))
#define E_IS_SOUP_AUTH_BEARER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOUP_AUTH_BEARER))
#define E_IS_SOUP_AUTH_BEARER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOUP_AUTH_BEARER))
#define E_SOUP_AUTH_BEARER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOUP_AUTH_BEARER, ESoupAuthBearerClass))

G_BEGIN_DECLS

typedef struct _ESoupAuthBearer ESoupAuthBearer;
typedef struct _ESoupAuthBearerClass ESoupAuthBearerClass;
typedef struct _ESoupAuthBearerPrivate ESoupAuthBearerPrivate;

/**
 * ESoupAuthBearer:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.10
 **/
struct _ESoupAuthBearer {
	/*< private >*/
	SoupAuth parent;
	ESoupAuthBearerPrivate *priv;
};

struct _ESoupAuthBearerClass {
	SoupAuthClass parent_class;
};

GType		e_soup_auth_bearer_get_type	(void) G_GNUC_CONST;
void		e_soup_auth_bearer_set_access_token
						(ESoupAuthBearer *bearer,
						 const gchar *access_token,
						 gint expires_in_seconds);
gboolean	e_soup_auth_bearer_is_expired	(ESoupAuthBearer *bearer);

G_END_DECLS

#endif /* E_SOUP_AUTH_BEARER_H */

