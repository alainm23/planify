/*
 * e-source-offline.h
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
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_OFFLINE_H
#define E_SOURCE_OFFLINE_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_OFFLINE \
	(e_source_offline_get_type ())
#define E_SOURCE_OFFLINE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_OFFLINE, ESourceOffline))
#define E_SOURCE_OFFLINE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_OFFLINE, ESourceOfflineClass))
#define E_IS_SOURCE_OFFLINE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_OFFLINE))
#define E_IS_SOURCE_OFFLINE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_OFFLINE))
#define E_SOURCE_OFFLINE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_OFFLINE, ESourceOfflineClass))

/**
 * E_SOURCE_EXTENSION_OFFLINE:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceOffline.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_OFFLINE "Offline"

G_BEGIN_DECLS

typedef struct _ESourceOffline ESourceOffline;
typedef struct _ESourceOfflineClass ESourceOfflineClass;
typedef struct _ESourceOfflinePrivate ESourceOfflinePrivate;

/**
 * ESourceOffline:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceOffline {
	/*< private >*/
	ESourceExtension parent;
	ESourceOfflinePrivate *priv;
};

struct _ESourceOfflineClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_offline_get_type	(void) G_GNUC_CONST;
gboolean	e_source_offline_get_stay_synchronized
						(ESourceOffline *extension);
void		e_source_offline_set_stay_synchronized
						(ESourceOffline *extension,
						 gboolean stay_synchronized);

G_END_DECLS

#endif /* E_SOURCE_OFFLINE_H */
