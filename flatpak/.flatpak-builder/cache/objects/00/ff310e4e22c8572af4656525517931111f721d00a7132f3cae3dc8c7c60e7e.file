/*
 * camel-subscribable.h
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SUBSCRIBABLE_H
#define CAMEL_SUBSCRIBABLE_H

#include <camel/camel-store.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SUBSCRIBABLE \
	(camel_subscribable_get_type ())
#define CAMEL_SUBSCRIBABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SUBSCRIBABLE, CamelSubscribable))
#define CAMEL_SUBSCRIBABLE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SUBSCRIBABLE, CamelSubscribableInterface))
#define CAMEL_IS_SUBSCRIBABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SUBSCRIBABLE))
#define CAMEL_IS_SUBSCRIBABLE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SUBSCRIBABLE))
#define CAMEL_SUBSCRIBABLE_GET_INTERFACE(obj) \
	(G_TYPE_INSTANCE_GET_INTERFACE \
	((obj), CAMEL_TYPE_SUBSCRIBABLE, CamelSubscribableInterface))

G_BEGIN_DECLS

/**
 * CamelSubscribable:
 *
 * Since: 3.2
 **/
typedef struct _CamelSubscribable CamelSubscribable;
typedef struct _CamelSubscribableInterface CamelSubscribableInterface;

struct _CamelSubscribableInterface {
	GTypeInterface parent_interface;

	/* Non-Blocking Methods */
	gboolean	(*folder_is_subscribed)
					(CamelSubscribable *subscribable,
					 const gchar *folder_name);

	/* Synchronous I/O Methods */
	gboolean	(*subscribe_folder_sync)
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 GCancellable *cancellable,
					 GError **error);
	gboolean	(*unsubscribe_folder_sync)
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 GCancellable *cancellable,
					 GError **error);

	/* Padding for future expansion */
	gpointer reserved_methods[20];

	/* Signals */
	void		(*folder_subscribed)
					(CamelSubscribable *subscribable,
					 CamelFolderInfo *folder_info);
	void		(*folder_unsubscribed)
					(CamelSubscribable *subscribable,
					 CamelFolderInfo *folder_info);

	/* Padding for future expansion */
	gpointer reserved_signals[20];
};

GType		camel_subscribable_get_type
					(void) G_GNUC_CONST;
gboolean	camel_subscribable_folder_is_subscribed
					(CamelSubscribable *subscribable,
					 const gchar *folder_name);
gboolean	camel_subscribable_subscribe_folder_sync
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 GCancellable *cancellable,
					 GError **error);
void		camel_subscribable_subscribe_folder
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 gint io_priority,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	camel_subscribable_subscribe_folder_finish
					(CamelSubscribable *subscribable,
					 GAsyncResult *result,
					 GError **error);
gboolean	camel_subscribable_unsubscribe_folder_sync
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 GCancellable *cancellable,
					 GError **error);
void		camel_subscribable_unsubscribe_folder
					(CamelSubscribable *subscribable,
					 const gchar *folder_name,
					 gint io_priority,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	camel_subscribable_unsubscribe_folder_finish
					(CamelSubscribable *subscribable,
					 GAsyncResult *result,
					 GError **error);
void		camel_subscribable_folder_subscribed
					(CamelSubscribable *subscribable,
					 CamelFolderInfo *folder_info);
void		camel_subscribable_folder_unsubscribed
					(CamelSubscribable *subscribable,
					 CamelFolderInfo *folder_info);

G_END_DECLS

#endif /* CAMEL_SUBSCRIBABLE_H */
