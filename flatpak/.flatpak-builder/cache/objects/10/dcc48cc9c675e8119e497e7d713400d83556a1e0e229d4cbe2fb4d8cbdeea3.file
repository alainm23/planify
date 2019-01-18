/*
 * e-source-refresh.h
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

#ifndef E_SOURCE_REFRESH_H
#define E_SOURCE_REFRESH_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_REFRESH \
	(e_source_refresh_get_type ())
#define E_SOURCE_REFRESH(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_REFRESH, ESourceRefresh))
#define E_SOURCE_REFRESH_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_REFRESH, ESourceRefreshClass))
#define E_IS_SOURCE_REFRESH(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_REFRESH))
#define E_IS_SOURCE_REFRESH_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_REFRESH))
#define E_SOURCE_REFRESH_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_REFRESH, ESourceRefreshClass))

/**
 * E_SOURCE_EXTENSION_REFRESH:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceRefresh.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_REFRESH "Refresh"

G_BEGIN_DECLS

typedef struct _ESourceRefresh ESourceRefresh;
typedef struct _ESourceRefreshClass ESourceRefreshClass;
typedef struct _ESourceRefreshPrivate ESourceRefreshPrivate;

/**
 * ESourceRefresh:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceRefresh {
	/*< private >*/
	ESourceExtension parent;
	ESourceRefreshPrivate *priv;
};

struct _ESourceRefreshClass {
	ESourceExtensionClass parent_class;
};

/**
 * ESourceRefreshFunc:
 * @source: an #ESource
 * @user_data: user data provided to the callback function
 *
 * Since: 3.6
 **/
typedef void	(*ESourceRefreshFunc)		(ESource *source,
						 gpointer user_data);

GType		e_source_refresh_get_type	(void) G_GNUC_CONST;
gboolean	e_source_refresh_get_enabled	(ESourceRefresh *extension);
void		e_source_refresh_set_enabled	(ESourceRefresh *extension,
						 gboolean enabled);
guint		e_source_refresh_get_interval_minutes
						(ESourceRefresh *extension);
void		e_source_refresh_set_interval_minutes
						(ESourceRefresh *extension,
						 guint interval_minutes);

guint		e_source_refresh_add_timeout	(ESource *source,
						 GMainContext *context,
						 ESourceRefreshFunc callback,
						 gpointer user_data,
						 GDestroyNotify notify);
void		e_source_refresh_force_timeout	(ESource *source);
gboolean	e_source_refresh_remove_timeout	(ESource *source,
						 guint refresh_timeout_id);
guint		e_source_refresh_remove_timeouts_by_data
						(ESource *source,
						 gpointer user_data);

G_END_DECLS

#endif /* E_SOURCE_REFRESH_H */
