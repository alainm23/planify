/*
 * camel-sendmail-settings.h
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

#ifndef CAMEL_SENDMAIL_SETTINGS_H
#define CAMEL_SENDMAIL_SETTINGS_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SENDMAIL_SETTINGS \
	(camel_sendmail_settings_get_type ())
#define CAMEL_SENDMAIL_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SENDMAIL_SETTINGS, CamelSendmailSettings))
#define CAMEL_SENDMAIL_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SENDMAIL_SETTINGS, CamelSendmailSettingsClass))
#define CAMEL_IS_SENDMAIL_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SENDMAIL_SETTINGS))
#define CAMEL_IS_SENDMAIL_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SENDMAIL_SETTINGS))
#define CAMEL_SENDMAIL_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SENDMAIL_SETTINGS))

G_BEGIN_DECLS

typedef struct _CamelSendmailSettings CamelSendmailSettings;
typedef struct _CamelSendmailSettingsClass CamelSendmailSettingsClass;
typedef struct _CamelSendmailSettingsPrivate CamelSendmailSettingsPrivate;

struct _CamelSendmailSettings {
	CamelSettings parent;
	CamelSendmailSettingsPrivate *priv;
};

struct _CamelSendmailSettingsClass {
	CamelSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_sendmail_settings_get_type
					(void) G_GNUC_CONST;
gboolean	camel_sendmail_settings_get_use_custom_binary
					(CamelSendmailSettings *settings);
void		camel_sendmail_settings_set_use_custom_binary
					(CamelSendmailSettings *settings,
					 gboolean use_custom_binary);
const gchar *	camel_sendmail_settings_get_custom_binary
					(CamelSendmailSettings *settings);
gchar *		camel_sendmail_settings_dup_custom_binary
					(CamelSendmailSettings *settings);
void		camel_sendmail_settings_set_custom_binary
					(CamelSendmailSettings *settings,
					 const gchar *custom_binary);
gboolean	camel_sendmail_settings_get_use_custom_args
					(CamelSendmailSettings *settings);
void		camel_sendmail_settings_set_use_custom_args
					(CamelSendmailSettings *settings,
					 gboolean use_custom_args);
const gchar *	camel_sendmail_settings_get_custom_args
					(CamelSendmailSettings *settings);
gchar *		camel_sendmail_settings_dup_custom_args
					(CamelSendmailSettings *settings);
void		camel_sendmail_settings_set_custom_args
					(CamelSendmailSettings *settings,
					 const gchar *custom_args);
gboolean	camel_sendmail_settings_get_send_in_offline
					(CamelSendmailSettings *settings);
void		camel_sendmail_settings_set_send_in_offline
					(CamelSendmailSettings *settings,
					 gboolean send_in_offline);

G_END_DECLS

#endif /* CAMEL_SENDMAIL_SETTINGS_H */
