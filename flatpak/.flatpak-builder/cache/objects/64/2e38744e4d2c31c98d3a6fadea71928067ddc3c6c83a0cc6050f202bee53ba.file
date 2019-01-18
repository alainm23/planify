/*
 * camel-pop3-settings.h
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

#ifndef CAMEL_POP3_SETTINGS_H
#define CAMEL_POP3_SETTINGS_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_POP3_SETTINGS \
	(camel_pop3_settings_get_type ())
#define CAMEL_POP3_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_POP3_SETTINGS, CamelPOP3Settings))
#define CAMEL_POP3_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_POP3_SETTINGS, CamelPOP3SettingsClass))
#define CAMEL_IS_POP3_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_POP3_SETTINGS))
#define CAMEL_IS_POP3_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_POP3_SETTINGS))
#define CAMEL_POP3_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_POP3_SETTINGS, CamelPOP3SettingsClass))

G_BEGIN_DECLS

typedef struct _CamelPOP3Settings CamelPOP3Settings;
typedef struct _CamelPOP3SettingsClass CamelPOP3SettingsClass;
typedef struct _CamelPOP3SettingsPrivate CamelPOP3SettingsPrivate;

struct _CamelPOP3Settings {
	CamelStoreSettings parent;
	CamelPOP3SettingsPrivate *priv;
};

struct _CamelPOP3SettingsClass {
	CamelStoreSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_pop3_settings_get_type	(void) G_GNUC_CONST;
gint		camel_pop3_settings_get_delete_after_days
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_delete_after_days
						(CamelPOP3Settings *settings,
						 gint delete_after_days);
gboolean	camel_pop3_settings_get_delete_expunged
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_delete_expunged
						(CamelPOP3Settings *settings,
						 gboolean delete_expunged);
gboolean	camel_pop3_settings_get_disable_extensions
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_disable_extensions
						(CamelPOP3Settings *settings,
						 gboolean disable_extensions);
gboolean	camel_pop3_settings_get_keep_on_server
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_keep_on_server
						(CamelPOP3Settings *settings,
						 gboolean keep_on_server);
gboolean	camel_pop3_settings_get_auto_fetch
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_auto_fetch
						(CamelPOP3Settings *settings,
						 gboolean auto_fetch);
guint32		camel_pop3_settings_get_last_cache_expunge
						(CamelPOP3Settings *settings);
void		camel_pop3_settings_set_last_cache_expunge
						(CamelPOP3Settings *settings,
						 guint32 last_cache_expunge);

G_END_DECLS

#endif /* CAMEL_POP3_SETTINGS_H */
