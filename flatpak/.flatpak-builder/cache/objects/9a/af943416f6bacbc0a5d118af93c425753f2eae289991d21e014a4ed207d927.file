/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_COMPONENT_H
#define __AS_COMPONENT_H

#include <glib-object.h>
#include "as-enums.h"
#include "as-provided.h"
#include "as-icon.h"
#include "as-screenshot.h"
#include "as-release.h"
#include "as-translation.h"
#include "as-suggested.h"
#include "as-category.h"
#include "as-bundle.h"
#include "as-content-rating.h"
#include "as-launchable.h"
#include "as-relation.h"
#include "as-agreement.h"

G_BEGIN_DECLS

#define AS_TYPE_COMPONENT (as_component_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsComponent, as_component, AS, COMPONENT, GObject)

struct _AsComponentClass
{
	GObjectClass		parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
	void (*_as_reserved5)	(void);
	void (*_as_reserved6)	(void);
};

/**
 * AsComponentKind:
 * @AS_COMPONENT_KIND_UNKNOWN:		Type invalid or not known
 * @AS_COMPONENT_KIND_GENERIC:		A generic (= without specialized type) component
 * @AS_COMPONENT_KIND_DESKTOP_APP:	An application with a .desktop-file
 * @AS_COMPONENT_KIND_CONSOLE_APP:	A console application
 * @AS_COMPONENT_KIND_WEB_APP:		A web application
 * @AS_COMPONENT_KIND_ADDON:		An extension of existing software, which does not run standalone
 * @AS_COMPONENT_KIND_FONT:		A font
 * @AS_COMPONENT_KIND_CODEC:		A multimedia codec
 * @AS_COMPONENT_KIND_INPUTMETHOD:	An input-method provider
 * @AS_COMPONENT_KIND_FIRMWARE:		Firmware
 * @AS_COMPONENT_KIND_DRIVER:		A driver
 * @AS_COMPONENT_KIND_LOCALIZATION:	Software localization (usually l10n resources)
 * @AS_COMPONENT_KIND_REPOSITORY:	A remote software or data source
 *
 * The type of an #AsComponent.
 **/
typedef enum  {
	AS_COMPONENT_KIND_UNKNOWN,
	AS_COMPONENT_KIND_GENERIC,
	AS_COMPONENT_KIND_DESKTOP_APP,
	AS_COMPONENT_KIND_CONSOLE_APP,
	AS_COMPONENT_KIND_WEB_APP,
	AS_COMPONENT_KIND_ADDON,
	AS_COMPONENT_KIND_FONT,
	AS_COMPONENT_KIND_CODEC,
	AS_COMPONENT_KIND_INPUTMETHOD,
	AS_COMPONENT_KIND_FIRMWARE,
	AS_COMPONENT_KIND_DRIVER,
	AS_COMPONENT_KIND_LOCALIZATION,
	AS_COMPONENT_KIND_SERVICE,
	AS_COMPONENT_KIND_REPOSITORY,
	/*< private >*/
	AS_COMPONENT_KIND_LAST
} AsComponentKind;

#define AS_TYPE_COMPONENT_KIND (as_component_kind_get_type ())
GType			as_component_kind_get_type (void) G_GNUC_CONST;
const gchar		*as_component_kind_to_string (AsComponentKind kind);
AsComponentKind		as_component_kind_from_string (const gchar *kind_str);

/**
 * AsMergeKind:
 * @AS_MERGE_KIND_NONE:		No merge is happening.
 * @AS_MERGE_KIND_REPLACE:	Merge replacing data of target.
 * @AS_MERGE_KIND_APPEND:	Merge appending data to target.
 * @AS_MERGE_KIND_REMOVE_COMPONENT: Remove the entire component if it matches.
 *
 * Defines how #AsComponent data should be merged if the component is
 * set for merge.
 **/
typedef enum  {
	AS_MERGE_KIND_NONE,
	AS_MERGE_KIND_REPLACE,
	AS_MERGE_KIND_APPEND,
	AS_MERGE_KIND_REMOVE_COMPONENT,
	/*< private >*/
	AS_MERGE_KIND_LAST
} AsMergeKind;

const gchar		*as_merge_kind_to_string (AsMergeKind kind);
AsMergeKind		as_merge_kind_from_string (const gchar *kind_str);

/**
 * AsComponentScope:
 * @AS_COMPONENT_SCOPE_UNKNOWN:		Unknown scope
 * @AS_COMPONENT_SCOPE_SYSTEM:		System scope
 * @AS_COMPONENT_SCOPE_USER:		User scope
 *
 * Scope of the #AsComponent (system-wide or user-scope)
 **/
typedef enum {
	AS_COMPONENT_SCOPE_UNKNOWN,
	AS_COMPONENT_SCOPE_SYSTEM,
	AS_COMPONENT_SCOPE_USER,
	/*< private >*/
	AS_COMPONENT_SCOPE_LAST
} AsComponentScope;

/**
 * AsValueFlags:
 * @AS_VALUE_FLAG_NONE:				No flags.
 * @AS_VALUE_FLAG_DUPLICATE_CHECK:		Check for duplicates when adding items to list values.
 * @AS_VALUE_FLAG_NO_TRANSLATION_FALLBACK:	Don't fall back to C when retrieving translated values.
 *
 * Set how values assigned to an #AsComponent should be treated when
 * they are set or retrieved.
 */
typedef enum {
	AS_VALUE_FLAG_NONE = 0,
	AS_VALUE_FLAG_DUPLICATE_CHECK = 1 << 0,
	AS_VALUE_FLAG_NO_TRANSLATION_FALLBACK = 1 << 1
} AsValueFlags;

AsComponent		*as_component_new (void);

AsValueFlags		as_component_get_value_flags (AsComponent *cpt);
void			as_component_set_value_flags (AsComponent *cpt,
						      AsValueFlags flags);

const gchar		*as_component_get_active_locale (AsComponent *cpt);
void			as_component_set_active_locale (AsComponent *cpt,
							const gchar *locale);

const gchar		*as_component_get_id (AsComponent *cpt);
void			as_component_set_id (AsComponent *cpt,
						const gchar *value);

const gchar		*as_component_get_data_id (AsComponent *cpt);
void			as_component_set_data_id (AsComponent *cpt,
							const gchar *value);

AsComponentKind		as_component_get_kind (AsComponent *cpt);
void			as_component_set_kind (AsComponent *cpt,
						AsComponentKind value);

const gchar		*as_component_get_origin (AsComponent *cpt);
void			as_component_set_origin (AsComponent *cpt,
							const gchar *origin);

gchar			*as_component_get_pkgname (AsComponent *cpt);
gchar			**as_component_get_pkgnames (AsComponent *cpt);
void			as_component_set_pkgnames (AsComponent *cpt,
							gchar **packages);

const gchar		*as_component_get_source_pkgname (AsComponent *cpt);
void			as_component_set_source_pkgname (AsComponent *cpt,
							 const gchar *spkgname);

const gchar		*as_component_get_name (AsComponent *cpt);
void			as_component_set_name (AsComponent *cpt,
						const gchar *value,
						const gchar *locale);

const gchar		*as_component_get_summary (AsComponent *cpt);
void			as_component_set_summary (AsComponent *cpt,
							const gchar *value,
							const gchar *locale);

const gchar		*as_component_get_description (AsComponent *cpt);
void			as_component_set_description (AsComponent *cpt,
							const gchar *value,
							const gchar *locale);

GPtrArray		*as_component_get_launchables (AsComponent *cpt);
AsLaunchable		*as_component_get_launchable (AsComponent *cpt,
							AsLaunchableKind kind);
void			as_component_add_launchable (AsComponent *cpt,
							 AsLaunchable *launchable);

const gchar		*as_component_get_metadata_license (AsComponent *cpt);
void			as_component_set_metadata_license (AsComponent *cpt,
							   const gchar *value);

const gchar		*as_component_get_project_license (AsComponent *cpt);
void			as_component_set_project_license (AsComponent *cpt,
							  const gchar *value);

const gchar		*as_component_get_project_group (AsComponent *cpt);
void			as_component_set_project_group (AsComponent *cpt,
								const gchar *value);

const gchar		*as_component_get_developer_name (AsComponent *cpt);
void			as_component_set_developer_name (AsComponent *cpt,
								const gchar *value,
								const gchar *locale);

GPtrArray		*as_component_get_compulsory_for_desktops (AsComponent *cpt);
void			as_component_set_compulsory_for_desktop (AsComponent *cpt,
								  const gchar *desktop);
gboolean		as_component_is_compulsory_for_desktop (AsComponent *cpt,
								const gchar *desktop);

GPtrArray		*as_component_get_categories (AsComponent *cpt);
void			as_component_add_category (AsComponent *cpt,
							const gchar *category);
gboolean		as_component_has_category (AsComponent *cpt,
							const gchar *category);

GPtrArray		*as_component_get_screenshots (AsComponent *cpt);
void			as_component_add_screenshot (AsComponent *cpt,
							AsScreenshot *sshot);

gchar			**as_component_get_keywords (AsComponent *cpt);
void			as_component_set_keywords (AsComponent *cpt,
							gchar **value,
							const gchar *locale);

GPtrArray		*as_component_get_icons (AsComponent *cpt);
AsIcon			*as_component_get_icon_by_size (AsComponent *cpt,
							guint width,
							guint height);
void			as_component_add_icon (AsComponent *cpt,
						AsIcon *icon);

GPtrArray		*as_component_get_provided (AsComponent *cpt);
void			as_component_add_provided (AsComponent *cpt,
							AsProvided *prov);
AsProvided		*as_component_get_provided_for_kind (AsComponent *cpt,
							AsProvidedKind kind);

const gchar		*as_component_get_url (AsComponent *cpt,
						AsUrlKind url_kind);
void			as_component_add_url (AsComponent *cpt,
						AsUrlKind url_kind,
						const gchar *url);

GPtrArray		*as_component_get_releases (AsComponent *cpt);
void			as_component_add_release (AsComponent *cpt,
							AsRelease* release);

GPtrArray		*as_component_get_extends (AsComponent *cpt);
void			as_component_add_extends (AsComponent *cpt,
							const gchar *cpt_id);

GPtrArray		*as_component_get_addons (AsComponent *cpt);
void			as_component_add_addon (AsComponent *cpt,
						AsComponent *addon);

GList			*as_component_get_languages (AsComponent *cpt);
gint			as_component_get_language (AsComponent *cpt,
							const gchar *locale);
void			as_component_add_language (AsComponent *cpt,
							const gchar *locale,
							gint percentage);

GPtrArray		*as_component_get_translations (AsComponent *cpt);
void			as_component_add_translation (AsComponent *cpt,
							AsTranslation *tr);

gboolean		as_component_has_bundle (AsComponent *cpt);
GPtrArray		*as_component_get_bundles (AsComponent *cpt);
AsBundle		*as_component_get_bundle (AsComponent *cpt,
						  AsBundleKind bundle_kind);
void			as_component_add_bundle (AsComponent *cpt,
						 AsBundle *bundle);

GPtrArray		*as_component_get_suggested (AsComponent *cpt);
void			as_component_add_suggested (AsComponent *cpt,
						    AsSuggested *suggested);

GPtrArray		*as_component_get_search_tokens (AsComponent *cpt);
guint			as_component_search_matches (AsComponent *cpt,
						      const gchar *term);
guint			as_component_search_matches_all (AsComponent *cpt,
							 gchar **terms);

AsMergeKind		as_component_get_merge_kind (AsComponent *cpt);
void			as_component_set_merge_kind (AsComponent *cpt,
							AsMergeKind kind);

gboolean		as_component_is_member_of_category (AsComponent *cpt,
							    AsCategory *category);

gboolean		as_component_is_ignored (AsComponent *cpt);

gboolean		as_component_is_valid (AsComponent *cpt);
gchar			*as_component_to_string (AsComponent *cpt);

GHashTable		*as_component_get_custom (AsComponent *cpt);
const gchar		*as_component_get_custom_value (AsComponent *cpt,
							const gchar *key);
gboolean		as_component_insert_custom_value (AsComponent *cpt,
							  const gchar *key,
							  const gchar *value);

GPtrArray		*as_component_get_content_ratings (AsComponent *cpt);
AsContentRating		*as_component_get_content_rating (AsComponent *cpt,
							  const gchar *kind);
void			as_component_add_content_rating (AsComponent *cpt,
							 AsContentRating *content_rating);

GPtrArray		*as_component_get_recommends (AsComponent *cpt);
GPtrArray		*as_component_get_requires (AsComponent *cpt);
void			as_component_add_relation (AsComponent *cpt,
						   AsRelation *relation);

void			as_component_add_agreement (AsComponent *cpt,
						    AsAgreement *agreement);
AsAgreement		*as_component_get_agreement_by_kind (AsComponent *cpt,
							     AsAgreementKind kind);


/* DEPRECATED */

G_GNUC_DEPRECATED
const gchar		*as_component_get_desktop_id (AsComponent *cpt);

G_END_DECLS

#endif /* __AS_COMPONENT_H */
