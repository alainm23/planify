/*
 * camel-local-settings.h
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

#ifndef CAMEL_LOCAL_SETTINGS_H
#define CAMEL_LOCAL_SETTINGS_H

#include <camel/camel-store-settings.h>

/* Standard GObject macros */
#define CAMEL_TYPE_LOCAL_SETTINGS \
	(camel_local_settings_get_type ())
#define CAMEL_LOCAL_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_LOCAL_SETTINGS, CamelLocalSettings))
#define CAMEL_LOCAL_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_LOCAL_SETTINGS, CamelLocalSettingsClass))
#define CAMEL_IS_LOCAL_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_LOCAL_SETTINGS))
#define CAMEL_IS_LOCAL_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_LOCAL_SETTINGS))
#define CAMEL_LOCAL_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_LOCAL_SETTINGS, CamelLocalSettingsClass))

G_BEGIN_DECLS

/**
 * CamelLocalSettings:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
typedef struct _CamelLocalSettings CamelLocalSettings;
typedef struct _CamelLocalSettingsClass CamelLocalSettingsClass;
typedef struct _CamelLocalSettingsPrivate CamelLocalSettingsPrivate;

struct _CamelLocalSettings {
	/*< private >*/
	CamelStoreSettings parent;
	CamelLocalSettingsPrivate *priv;
};

struct _CamelLocalSettingsClass {
	/*< private >*/
	CamelStoreSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_local_settings_get_type	(void) G_GNUC_CONST;
const gchar *	camel_local_settings_get_path	(CamelLocalSettings *settings);
gchar *		camel_local_settings_dup_path	(CamelLocalSettings *settings);
void		camel_local_settings_set_path	(CamelLocalSettings *settings,
						 const gchar *path);
gboolean	camel_local_settings_get_filter_all
					(CamelLocalSettings *settings);
void		camel_local_settings_set_filter_all
					(CamelLocalSettings *settings,
					 gboolean filter_all);
gboolean	camel_local_settings_get_filter_junk
					(CamelLocalSettings *settings);
void		camel_local_settings_set_filter_junk
					(CamelLocalSettings *settings,
					 gboolean filter_junk);

G_END_DECLS

#endif /* CAMEL_LOCAL_SETTINGS_H */

