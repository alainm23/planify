/*
 * camel-smtp-settings.h
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

#ifndef CAMEL_SMTP_SETTINGS_H
#define CAMEL_SMTP_SETTINGS_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SMTP_SETTINGS \
	(camel_smtp_settings_get_type ())
#define CAMEL_SMTP_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SMTP_SETTINGS, CamelSmtpSettings))
#define CAMEL_SMTP_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SMTP_SETTINGS, CamelSmtpSettingsClass))
#define CAMEL_IS_SMTP_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SMTP_SETTINGS))
#define CAMEL_IS_SMTP_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SMTP_SETTINGS))
#define CAMEL_SMTP_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SMTP_SETTINGS, CamelSmtpSettingsClass))

G_BEGIN_DECLS

typedef struct _CamelSmtpSettings CamelSmtpSettings;
typedef struct _CamelSmtpSettingsClass CamelSmtpSettingsClass;
typedef struct _CamelSmtpSettingsPrivate CamelSmtpSettingsPrivate;

struct _CamelSmtpSettings {
	CamelSettings parent;
	CamelSmtpSettingsPrivate *priv;
};

struct _CamelSmtpSettingsClass {
	CamelSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_smtp_settings_get_type	(void) G_GNUC_CONST;

G_END_DECLS

#endif /* CAMEL_SMTP_SETTINGS_H */
