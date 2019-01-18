/*
 * camel-store-settings.h
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

#ifndef CAMEL_STORE_SETTINGS_H
#define CAMEL_STORE_SETTINGS_H

#include <camel/camel-settings.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STORE_SETTINGS \
	(camel_store_settings_get_type ())
#define CAMEL_STORE_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STORE_SETTINGS, CamelStoreSettings))
#define CAMEL_STORE_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STORE_SETTINGS, CamelStoreSettingsClass))
#define CAMEL_IS_STORE_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STORE_SETTINGS))
#define CAMEL_IS_STORE_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STORE_SETTINGS))
#define CAMEL_STORE_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STORE_SETTINGS, CamelStoreSettingsClass))

G_BEGIN_DECLS

/**
 * CamelStoreSettings:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
typedef struct _CamelStoreSettings CamelStoreSettings;
typedef struct _CamelStoreSettingsClass CamelStoreSettingsClass;
typedef struct _CamelStoreSettingsPrivate CamelStoreSettingsPrivate;

struct _CamelStoreSettings {
	/*< private >*/
	CamelSettings parent;
	CamelStoreSettingsPrivate *priv;
};

struct _CamelStoreSettingsClass {
	CamelSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_store_settings_get_type	(void) G_GNUC_CONST;
gboolean	camel_store_settings_get_filter_inbox
						(CamelStoreSettings *settings);
void		camel_store_settings_set_filter_inbox
						(CamelStoreSettings *settings,
						 gboolean filter_inbox);

G_END_DECLS

#endif /* CAMEL_STORE_SETTINGS_H */
