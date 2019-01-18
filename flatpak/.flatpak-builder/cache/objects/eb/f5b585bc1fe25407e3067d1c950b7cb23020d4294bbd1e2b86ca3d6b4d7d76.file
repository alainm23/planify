/*
 * camel-network-service.h
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

#ifndef CAMEL_NETWORK_SERVICE_H
#define CAMEL_NETWORK_SERVICE_H

#include <camel/camel-enums.h>
#include <camel/camel-network-settings.h>
#include <camel/camel-stream.h>

/* Standard GObject macros */
#define CAMEL_TYPE_NETWORK_SERVICE \
	(camel_network_service_get_type ())
#define CAMEL_NETWORK_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NETWORK_SERVICE, CamelNetworkService))
#define CAMEL_NETWORK_SERVICE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NETWORK_SERVICE, CamelNetworkServiceInterface))
#define CAMEL_IS_NETWORK_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NETWORK_SERVICE))
#define CAMEL_IS_NETWORK_SERVICE_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NETWORK_SERVICE))
#define CAMEL_NETWORK_SERVICE_GET_INTERFACE(obj) \
	(G_TYPE_INSTANCE_GET_INTERFACE \
	((obj), CAMEL_TYPE_NETWORK_SERVICE, CamelNetworkServiceInterface))

G_BEGIN_DECLS

/**
 * CamelNetworkService:
 *
 * Since: 3.2
 **/
typedef struct _CamelNetworkService CamelNetworkService;
typedef struct _CamelNetworkServiceInterface CamelNetworkServiceInterface;

struct _CamelNetworkServiceInterface {
	GTypeInterface parent_interface;

	const gchar *	(*get_service_name)
					(CamelNetworkService *service,
					 CamelNetworkSecurityMethod method);
	guint16		(*get_default_port)
					(CamelNetworkService *service,
					 CamelNetworkSecurityMethod method);

	GIOStream *	(*connect_sync)	(CamelNetworkService *service,
					 GCancellable *cancellable,
					 GError **error);

	GSocketConnectable *
			(*new_connectable)
					(CamelNetworkService *service);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_network_service_get_type	(void) G_GNUC_CONST;
const gchar *	camel_network_service_get_service_name
					(CamelNetworkService *service,
					 CamelNetworkSecurityMethod method);
guint16		camel_network_service_get_default_port
					(CamelNetworkService *service,
					 CamelNetworkSecurityMethod method);
GSocketConnectable *
		camel_network_service_ref_connectable
					(CamelNetworkService *service);
void		camel_network_service_set_connectable
					(CamelNetworkService *service,
					 GSocketConnectable *connectable);
gboolean	camel_network_service_get_host_reachable
					(CamelNetworkService *service);
GIOStream *	camel_network_service_connect_sync
					(CamelNetworkService *service,
					 GCancellable *cancellable,
					 GError **error);
GIOStream *	camel_network_service_starttls
					(CamelNetworkService *service,
					 GIOStream *base_stream,
					 GError **error);
gboolean	camel_network_service_can_reach_sync
					(CamelNetworkService *service,
					 GCancellable *cancellable,
					 GError **error);
void		camel_network_service_can_reach
					(CamelNetworkService *service,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	camel_network_service_can_reach_finish
					(CamelNetworkService *service,
					 GAsyncResult *result,
					 GError **error);

G_END_DECLS

#endif /* CAMEL_NETWORK_SERVICE_H */
