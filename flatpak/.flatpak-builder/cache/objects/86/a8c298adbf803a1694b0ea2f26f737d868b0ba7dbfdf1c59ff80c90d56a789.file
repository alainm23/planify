/*
 * camel-network-settings.h
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

#ifndef CAMEL_NETWORK_SETTINGS_H
#define CAMEL_NETWORK_SETTINGS_H

#include <glib-object.h>
#include <camel/camel-enums.h>

/* Standard GObject macros */
#define CAMEL_TYPE_NETWORK_SETTINGS \
	(camel_network_settings_get_type ())
#define CAMEL_NETWORK_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NETWORK_SETTINGS, CamelNetworkSettings))
#define CAMEL_NETWORK_SETTINGS_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NETWORK_SETTINGS, CamelNetworkSettingsInterface))
#define CAMEL_IS_NETWORK_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NETWORK_SETTINGS))
#define CAMEL_IS_NETWORK_SETTINGS_INTERFACE(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NETWORK_SETTINGS))
#define CAMEL_NETWORK_SETTINGS_GET_INTERFACE(obj) \
	(G_TYPE_INSTANCE_GET_INTERFACE \
	((obj), CAMEL_TYPE_NETWORK_SETTINGS, CamelNetworkSettingsInterface))

G_BEGIN_DECLS

/**
 * CamelNetworkSettings:
 *
 * Since: 3.2
 **/
typedef struct _CamelNetworkSettings CamelNetworkSettings;
typedef struct _CamelNetworkSettingsInterface CamelNetworkSettingsInterface;

struct _CamelNetworkSettingsInterface {
	GTypeInterface parent_interface;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_network_settings_get_type
					(void) G_GNUC_CONST;
const gchar *	camel_network_settings_get_auth_mechanism
					(CamelNetworkSettings *settings);
gchar *		camel_network_settings_dup_auth_mechanism
					(CamelNetworkSettings *settings);
void		camel_network_settings_set_auth_mechanism
					(CamelNetworkSettings *settings,
					 const gchar *auth_mechanism);
const gchar *	camel_network_settings_get_host
					(CamelNetworkSettings *settings);
gchar *		camel_network_settings_dup_host
					(CamelNetworkSettings *settings);
gchar *		camel_network_settings_dup_host_ensure_ascii
					(CamelNetworkSettings *settings);
void		camel_network_settings_set_host
					(CamelNetworkSettings *settings,
					 const gchar *host);
guint16		camel_network_settings_get_port
					(CamelNetworkSettings *settings);
void		camel_network_settings_set_port
					(CamelNetworkSettings *settings,
					 guint16 port);
CamelNetworkSecurityMethod
		camel_network_settings_get_security_method
					(CamelNetworkSettings *settings);
void		camel_network_settings_set_security_method
					(CamelNetworkSettings *settings,
					 CamelNetworkSecurityMethod method);
const gchar *	camel_network_settings_get_user
					(CamelNetworkSettings *settings);
gchar *		camel_network_settings_dup_user
					(CamelNetworkSettings *settings);
void		camel_network_settings_set_user
					(CamelNetworkSettings *settings,
					 const gchar *user);

G_END_DECLS

#endif /* CAMEL_NETWORK_SETTINGS_H */
