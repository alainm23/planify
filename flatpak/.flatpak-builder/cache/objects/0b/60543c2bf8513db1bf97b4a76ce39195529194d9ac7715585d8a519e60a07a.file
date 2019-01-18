/*
 * camel-nntp-settings.h
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

#ifndef CAMEL_NNTP_SETTINGS_H
#define CAMEL_NNTP_SETTINGS_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_NNTP_SETTINGS \
	(camel_nntp_settings_get_type ())
#define CAMEL_NNTP_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NNTP_SETTINGS, CamelNNTPSettings))
#define CAMEL_NNTP_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NNTP_SETTINGS, CamelNNTPSettingsClass))
#define CAMEL_IS_NNTP_SETTINGS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NNTP_SETTINGS))
#define CAMEL_IS_NNTP_SETTINGS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NNTP_SETTINGS))
#define CAMEL_NNTP_SETTINGS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_NNTP_SETTINGS, CamelNNTPSettingsClass))

G_BEGIN_DECLS

typedef struct _CamelNNTPSettings CamelNNTPSettings;
typedef struct _CamelNNTPSettingsClass CamelNNTPSettingsClass;
typedef struct _CamelNNTPSettingsPrivate CamelNNTPSettingsPrivate;

struct _CamelNNTPSettings {
	CamelOfflineSettings parent;
	CamelNNTPSettingsPrivate *priv;
};

struct _CamelNNTPSettingsClass {
	CamelOfflineSettingsClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_nntp_settings_get_type
					(void) G_GNUC_CONST;
gboolean	camel_nntp_settings_get_filter_all
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_filter_all
					(CamelNNTPSettings *settings,
					 gboolean filter_all);
gboolean	camel_nntp_settings_get_filter_junk
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_filter_junk
					(CamelNNTPSettings *settings,
					 gboolean filter_junk);
gboolean	camel_nntp_settings_get_folder_hierarchy_relative
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_folder_hierarchy_relative
					(CamelNNTPSettings *settings,
					 gboolean folder_hierarchy_relative);
gboolean	camel_nntp_settings_get_short_folder_names
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_short_folder_names
					(CamelNNTPSettings *settings,
					 gboolean short_folder_names);
gboolean	camel_nntp_settings_get_use_limit_latest
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_use_limit_latest
					(CamelNNTPSettings *settings,
					 gboolean use_limit_latest);
guint		camel_nntp_settings_get_limit_latest
					(CamelNNTPSettings *settings);
void		camel_nntp_settings_set_limit_latest
					(CamelNNTPSettings *settings,
					 guint limit_latest);

G_END_DECLS

#endif /* CAMEL_NNTP_SETTINGS_H */
