/*
 * e-server-side-source.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_SERVER_SIDE_SOURCE_H
#define E_SERVER_SIDE_SOURCE_H

#include <libebackend/e-oauth2-support.h>
#include <libebackend/e-source-registry-server.h>

/* Standard GObject macros */
#define E_TYPE_SERVER_SIDE_SOURCE \
	(e_server_side_source_get_type ())
#define E_SERVER_SIDE_SOURCE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SERVER_SIDE_SOURCE, EServerSideSource))
#define E_SERVER_SIDE_SOURCE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SERVER_SIDE_SOURCE, EServerSideSourceClass))
#define E_IS_SERVER_SIDE_SOURCE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SERVER_SIDE_SOURCE))
#define E_IS_SERVER_SIDE_SOURCE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SERVER_SIDE_SOURCE))
#define E_SERVER_SIDE_SOURCE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SERVER_SIDE_SOURCE, EServerSideSourceClass))

G_BEGIN_DECLS

typedef struct _EServerSideSource EServerSideSource;
typedef struct _EServerSideSourceClass EServerSideSourceClass;
typedef struct _EServerSideSourcePrivate EServerSideSourcePrivate;

/**
 * EServerSideSource:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _EServerSideSource {
	/*< private >*/
	ESource parent;
	EServerSideSourcePrivate *priv;
};

struct _EServerSideSourceClass {
	ESourceClass parent_class;
};

GType		e_server_side_source_get_type	(void) G_GNUC_CONST;
const gchar *	e_server_side_source_get_user_dir
						(void) G_GNUC_CONST;
GFile *		e_server_side_source_new_user_file
						(const gchar *uid);
gchar *		e_server_side_source_uid_from_file
						(GFile *file,
						 GError **error);
ESource *	e_server_side_source_new	(ESourceRegistryServer *server,
						 GFile *file,
						 GError **error);
ESource *	e_server_side_source_new_memory_only
						(ESourceRegistryServer *server,
						 const gchar *uid,
						 GError **error);
gboolean	e_server_side_source_load	(EServerSideSource *source,
						 GCancellable *cancellable,
						 GError **error);
GFile *		e_server_side_source_get_file	(EServerSideSource *source);
GNode *		e_server_side_source_get_node	(EServerSideSource *source);
ESourceRegistryServer *
		e_server_side_source_get_server	(EServerSideSource *source);
gboolean	e_server_side_source_get_exported
						(EServerSideSource *source);
const gchar *	e_server_side_source_get_write_directory
						(EServerSideSource *source);
void		e_server_side_source_set_write_directory
						(EServerSideSource *source,
						 const gchar *write_directory);
void		e_server_side_source_set_removable
						(EServerSideSource *source,
						 gboolean removable);
void		e_server_side_source_set_writable
						(EServerSideSource *source,
						 gboolean writable);
void		e_server_side_source_set_remote_creatable
						(EServerSideSource *source,
						 gboolean remote_creatable);
void		e_server_side_source_set_remote_deletable
						(EServerSideSource *source,
						 gboolean remote_deletable);
EOAuth2Support *
		e_server_side_source_ref_oauth2_support
						(EServerSideSource *source);
void		e_server_side_source_set_oauth2_support
						(EServerSideSource *source,
						 EOAuth2Support *oauth2_support);

G_END_DECLS

#endif /* E_SERVER_SIDE_SOURCE_H */

