/*
 * camel-offline-settings.h
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

#ifndef CAMEL_OFFLINE_SETTINGS_H
#define CAMEL_OFFLINE_SETTINGS_H

#include <camel/camel-enums.h>
#include <camel/camel-store-settings.h>

/* Standard GObject macros */
#define CAMEL_TYPE_OFFLINE_SETTINGS \
	(camel_offline_settings_get_type ())
#define CAMEL_OFFLINE_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_OFFLINE_SETTINGS, CamelOfflineSettings))
#define CAMEL_OFFLINE_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_OFFLINE_SETTINGS, CamelOfflineSettingsClass))
#define CAMEL_IS_OFFLINE_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_OFFLINE_SETTINGS))
#define CAMEL_IS_OFFLINE_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_OFFLINE_SETTINGS))
#define CAMEL_OFFLINE_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_OFFLINE_SETTINGS, CamelOfflineSettingsClass))

G_BEGIN_DECLS

/**
 * CamelOfflineSettings:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
typedef struct _CamelOfflineSettings CamelOfflineSettings;
typedef struct _CamelOfflineSettingsClass CamelOfflineSettingsClass;
typedef struct _CamelOfflineSettingsPrivate CamelOfflineSettingsPrivate;

struct _CamelOfflineSettings {
	/*< private >*/
	CamelStoreSettings parent;
	CamelOfflineSettingsPrivate *priv;
};

struct _CamelOfflineSettingsClass {
	CamelStoreSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_offline_settings_get_type
					(void) G_GNUC_CONST;
gboolean	camel_offline_settings_get_stay_synchronized
					(CamelOfflineSettings *settings);
void		camel_offline_settings_set_stay_synchronized
					(CamelOfflineSettings *settings,
					 gboolean stay_synchronized);
gint		camel_offline_settings_get_store_changes_interval
					(CamelOfflineSettings *settings);
void		camel_offline_settings_set_store_changes_interval
					(CamelOfflineSettings *settings,
					 gint interval);
gboolean	camel_offline_settings_get_limit_by_age
					(CamelOfflineSettings *settings);
void		camel_offline_settings_set_limit_by_age
					(CamelOfflineSettings *settings,
					 gboolean limit_by_age);
CamelTimeUnit	camel_offline_settings_get_limit_unit
					(CamelOfflineSettings *settings);
void		camel_offline_settings_set_limit_unit
					(CamelOfflineSettings *settings,
					 CamelTimeUnit limit_unit);
gint		camel_offline_settings_get_limit_value
					(CamelOfflineSettings *settings);
void		camel_offline_settings_set_limit_value
					(CamelOfflineSettings *settings,
					 gboolean limit_value);

G_END_DECLS

#endif /* CAMEL_OFFLINE_SETTINGS_H */
