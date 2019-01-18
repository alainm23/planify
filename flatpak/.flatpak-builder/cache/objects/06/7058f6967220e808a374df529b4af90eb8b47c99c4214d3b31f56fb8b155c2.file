/*
 * e-source-registry.h
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

#ifndef E_SOURCE_REGISTRY_H
#define E_SOURCE_REGISTRY_H

#include <libedataserver/e-oauth2-services.h>
#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_REGISTRY \
	(e_source_registry_get_type ())
#define E_SOURCE_REGISTRY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_REGISTRY, ESourceRegistry))
#define E_SOURCE_REGISTRY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_REGISTRY, ESourceRegistryClass))
#define E_IS_SOURCE_REGISTRY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_REGISTRY))
#define E_IS_SOURCE_REGISTRY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_REGISTRY))
#define E_SOURCE_REGISTRY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_REGISTRY, ESourceRegistryClass))

G_BEGIN_DECLS

typedef struct _ESourceRegistry ESourceRegistry;
typedef struct _ESourceRegistryClass ESourceRegistryClass;
typedef struct _ESourceRegistryPrivate ESourceRegistryPrivate;

/**
 * ESourceRegistry:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceRegistry {
	/*< private >*/
	GObject parent;
	ESourceRegistryPrivate *priv;
};

struct _ESourceRegistryClass {
	GObjectClass parent_class;

	/* Signals */
	void		(*source_added)		(ESourceRegistry *registry,
						 ESource *source);
	void		(*source_changed)	(ESourceRegistry *registry,
						 ESource *source);
	void		(*source_removed)	(ESourceRegistry *registry,
						 ESource *source);
	void		(*source_enabled)	(ESourceRegistry *registry,
						 ESource *source);
	void		(*source_disabled)	(ESourceRegistry *registry,
						 ESource *source);
	void		(*credentials_required)	(ESourceRegistry *registry,
						 ESource *source,
						 ESourceCredentialsReason reason,
						 const gchar *certificate_pem,
						 GTlsCertificateFlags certificate_errors,
						 const GError *op_error);
};

GType		e_source_registry_get_type	(void) G_GNUC_CONST;
ESourceRegistry *
		e_source_registry_new_sync	(GCancellable *cancellable,
						 GError **error);
void		e_source_registry_new		(GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
ESourceRegistry *
		e_source_registry_new_finish	(GAsyncResult *result,
						 GError **error);
EOAuth2Services *
		e_source_registry_get_oauth2_services
						(ESourceRegistry *registry);
gboolean	e_source_registry_commit_source_sync
						(ESourceRegistry *registry,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_registry_commit_source	(ESourceRegistry *registry,
						 ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_registry_commit_source_finish
						(ESourceRegistry *registry,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_registry_create_sources_sync
						(ESourceRegistry *registry,
						 GList *list_of_sources,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_registry_create_sources
						(ESourceRegistry *registry,
						 GList *list_of_sources,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_registry_create_sources_finish
						(ESourceRegistry *registry,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_source_registry_refresh_backend_sync
						(ESourceRegistry *registry,
						 const gchar *source_uid,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_registry_refresh_backend
						(ESourceRegistry *registry,
						 const gchar *source_uid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_source_registry_refresh_backend_finish
						(ESourceRegistry *registry,
						 GAsyncResult *result,
						 GError **error);
ESource *	e_source_registry_ref_source	(ESourceRegistry *registry,
						 const gchar *uid);
GList *		e_source_registry_list_sources	(ESourceRegistry *registry,
						 const gchar *extension_name);
GList *		e_source_registry_list_enabled	(ESourceRegistry *registry,
						 const gchar *extension_name);
ESource *	e_source_registry_find_extension
						(ESourceRegistry *registry,
						 ESource *source,
						 const gchar *extension_name);
gboolean	e_source_registry_check_enabled	(ESourceRegistry *registry,
						 ESource *source);
GNode *		e_source_registry_build_display_tree
						(ESourceRegistry *registry,
						 const gchar *extension_name);
void		e_source_registry_free_display_tree
						(GNode *display_tree);
gchar *		e_source_registry_dup_unique_display_name
						(ESourceRegistry *registry,
						 ESource *source,
						 const gchar *extension_name);
void		e_source_registry_debug_dump	(ESourceRegistry *registry,
						 const gchar *extension_name);

/* These built-in ESource objects are always available. */

ESource *	e_source_registry_ref_builtin_address_book
						(ESourceRegistry *registry);
ESource *	e_source_registry_ref_builtin_calendar
						(ESourceRegistry *registry);
ESource *	e_source_registry_ref_builtin_mail_account
						(ESourceRegistry *registry);
ESource *	e_source_registry_ref_builtin_memo_list
						(ESourceRegistry *registry);
ESource *	e_source_registry_ref_builtin_proxy
						(ESourceRegistry *registry);
ESource *	e_source_registry_ref_builtin_task_list
						(ESourceRegistry *registry);

/* The following is a front-end for the "org.gnome.Evolution.DefaultSources"
 * GSettings schema, except that it gets and sets ESource objects instead of
 * ESource UID strings. */

ESource *	e_source_registry_ref_default_address_book
						(ESourceRegistry *registry);
void		e_source_registry_set_default_address_book
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_calendar
						(ESourceRegistry *registry);
void		e_source_registry_set_default_calendar
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_mail_account
						(ESourceRegistry *registry);
void		e_source_registry_set_default_mail_account
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_mail_identity
						(ESourceRegistry *registry);
void		e_source_registry_set_default_mail_identity
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_memo_list
						(ESourceRegistry *registry);
void		e_source_registry_set_default_memo_list
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_task_list
						(ESourceRegistry *registry);
void		e_source_registry_set_default_task_list
						(ESourceRegistry *registry,
						 ESource *default_source);
ESource *	e_source_registry_ref_default_for_extension_name
						(ESourceRegistry *registry,
						 const gchar *extension_name);
void		e_source_registry_set_default_for_extension_name
						(ESourceRegistry *registry,
						 const gchar *extension_name,
						 ESource *default_source);

G_END_DECLS

#endif /* E_SOURCE_REGISTRY_H */
