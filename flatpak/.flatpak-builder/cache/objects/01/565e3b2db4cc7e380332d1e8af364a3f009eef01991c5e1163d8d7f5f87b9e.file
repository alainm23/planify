/*
 * camel-imapx-settings.h
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

#ifndef CAMEL_IMAPX_SETTINGS_H
#define CAMEL_IMAPX_SETTINGS_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_SETTINGS \
	(camel_imapx_settings_get_type ())
#define CAMEL_IMAPX_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_SETTINGS, CamelIMAPXSettings))
#define CAMEL_IMAPX_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_SETTINGS, CamelIMAPXSettingsClass))
#define CAMEL_IS_IMAPX_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_SETTINGS))
#define CAMEL_IS_IMAPX_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_SETTINGS))
#define CAMEL_IMAPX_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_SETTINGS, CamelIMAPXSettingsClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXSettings CamelIMAPXSettings;
typedef struct _CamelIMAPXSettingsClass CamelIMAPXSettingsClass;
typedef struct _CamelIMAPXSettingsPrivate CamelIMAPXSettingsPrivate;

struct _CamelIMAPXSettings {
	CamelOfflineSettings parent;
	CamelIMAPXSettingsPrivate *priv;
};

struct _CamelIMAPXSettingsClass {
	CamelOfflineSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_settings_get_type	(void) G_GNUC_CONST;
guint		camel_imapx_settings_get_use_multi_fetch
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_multi_fetch
						(CamelIMAPXSettings *settings,
						 guint use_multi_fetch);
gboolean	camel_imapx_settings_get_check_all
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_check_all
						(CamelIMAPXSettings *settings,
						 gboolean check_all);
gboolean	camel_imapx_settings_get_check_subscribed
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_check_subscribed
						(CamelIMAPXSettings *settings,
						 gboolean check_subscribed);
guint		camel_imapx_settings_get_concurrent_connections
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_concurrent_connections
						(CamelIMAPXSettings *settings,
						 guint concurrent_connections);
CamelSortType	camel_imapx_settings_get_fetch_order
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_fetch_order
						(CamelIMAPXSettings *settings,
						 CamelSortType fetch_order);
gboolean	camel_imapx_settings_get_filter_all
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_filter_all
						(CamelIMAPXSettings *settings,
						 gboolean filter_all);
gboolean	camel_imapx_settings_get_filter_junk
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_filter_junk
						(CamelIMAPXSettings *settings,
						 gboolean filter_junk);
gboolean	camel_imapx_settings_get_filter_junk_inbox
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_filter_junk_inbox
						(CamelIMAPXSettings *settings,
						 gboolean filter_junk_inbox);
const gchar *	camel_imapx_settings_get_namespace
						(CamelIMAPXSettings *settings);
gchar *		camel_imapx_settings_dup_namespace
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_namespace
						(CamelIMAPXSettings *settings,
						 const gchar *namespace_);
const gchar *	camel_imapx_settings_get_real_junk_path
						(CamelIMAPXSettings *settings);
gchar *		camel_imapx_settings_dup_real_junk_path
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_real_junk_path
						(CamelIMAPXSettings *settings,
						 const gchar *real_junk_path);
const gchar *	camel_imapx_settings_get_real_trash_path
						(CamelIMAPXSettings *settings);
gchar *		camel_imapx_settings_dup_real_trash_path
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_real_trash_path
						(CamelIMAPXSettings *settings,
						 const gchar *real_trash_path);
const gchar *	camel_imapx_settings_get_shell_command
						(CamelIMAPXSettings *settings);
gchar *		camel_imapx_settings_dup_shell_command
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_shell_command
						(CamelIMAPXSettings *settings,
						 const gchar *shell_command);
gboolean	camel_imapx_settings_get_use_idle
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_idle
						(CamelIMAPXSettings *settings,
						 gboolean use_idle);
gboolean	camel_imapx_settings_get_use_namespace
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_namespace
						(CamelIMAPXSettings *settings,
						 gboolean use_namespace);
gboolean	camel_imapx_settings_get_ignore_other_users_namespace
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_ignore_other_users_namespace
						(CamelIMAPXSettings *settings,
						 gboolean ignore);
gboolean	camel_imapx_settings_get_ignore_shared_folders_namespace
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_ignore_shared_folders_namespace
						(CamelIMAPXSettings *settings,
						 gboolean ignore);
gboolean	camel_imapx_settings_get_use_qresync
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_qresync
						(CamelIMAPXSettings *settings,
						 gboolean use_qresync);
gboolean	camel_imapx_settings_get_use_real_junk_path
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_real_junk_path
						(CamelIMAPXSettings *settings,
						 gboolean use_real_junk_path);
gboolean	camel_imapx_settings_get_use_real_trash_path
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_real_trash_path
						(CamelIMAPXSettings *settings,
						 gboolean use_real_trash_path);
gboolean	camel_imapx_settings_get_use_shell_command
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_shell_command
						(CamelIMAPXSettings *settings,
						 gboolean use_shell_command);
gboolean	camel_imapx_settings_get_use_subscriptions
						(CamelIMAPXSettings *settings);
void		camel_imapx_settings_set_use_subscriptions
						(CamelIMAPXSettings *settings,
						 gboolean use_subscriptions);

G_END_DECLS

#endif /* CAMEL_IMAPX_SETTINGS_H */
