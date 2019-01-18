/*
 * camel-settings.h
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

#ifndef CAMEL_SETTINGS_H
#define CAMEL_SETTINGS_H

#include <glib-object.h>
#include <camel/camel-url.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SETTINGS \
	(camel_settings_get_type ())
#define CAMEL_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SETTINGS, CamelSettings))
#define CAMEL_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SETTINGS, CamelSettingsClass))
#define CAMEL_IS_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SETTINGS))
#define CAMEL_IS_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SETTINGS))
#define CAMEL_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SETTINGS, CamelSettingsClass))

G_BEGIN_DECLS

/**
 * CamelSettings:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
typedef struct _CamelSettings CamelSettings;
typedef struct _CamelSettingsClass CamelSettingsClass;
typedef struct _CamelSettingsPrivate CamelSettingsPrivate;

struct _CamelSettings {
	/*< private >*/
	GObject parent;
	CamelSettingsPrivate *priv;
};

struct _CamelSettingsClass {
	GObjectClass parent_class;

	GParamSpec **	(*list_settings)	(CamelSettingsClass *klass,
						 guint *n_settings);

	CamelSettings *	(*clone)		(CamelSettings *settings);
	gboolean	(*equal)		(CamelSettings *settings_a,
						 CamelSettings *settings_b);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_settings_get_type		(void) G_GNUC_CONST;
GParamSpec **	camel_settings_class_list_settings
						(CamelSettingsClass *settings_class,
						 guint *n_settings);
CamelSettings *	camel_settings_clone		(CamelSettings *settings);
gboolean	camel_settings_equal		(CamelSettings *settings_a,
						 CamelSettings *settings_b);

G_END_DECLS

#endif /* CAMEL_SETTINGS_H */
