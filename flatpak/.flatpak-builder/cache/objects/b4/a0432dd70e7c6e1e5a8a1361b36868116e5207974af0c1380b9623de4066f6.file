/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2018 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_TAG_H
#define __AS_TAG_H

#include <glib.h>

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

/**
 * AsTag:
 * @AS_TAG_UNKNOWN:			Type invalid or not known
 * @AS_TAG_TYPE:			- / `Type`
 * @AS_TAG_PRIORITY:			- / `Priority`
 * @AS_TAG_MERGE:			- / `Merge`
 * @AS_TAG_ID:				`id` / `ID`
 * @AS_TAG_PKGNAME:			`pkgname` / `Package`
 * @AS_TAG_SOURCE_PKGNAME:		`source_pkgname` / `SourcePackage`
 * @AS_TAG_NAME:			`name` / `Name`
 * @AS_TAG_SUMMARY:			`summary` / `Summary`
 * @AS_TAG_DESCRIPTION:			`description` / `Description`
 * @AS_TAG_ICON:			`icon` / `Icon`
 * @AS_TAG_URL:				`url` / `Url`
 * @AS_TAG_CATEGORIES:			`categories` / `Categories`
 * @AS_TAG_KEYWORDS:			`keywords` / `Keywords`
 * @AS_TAG_MIMETYPES:			``mimetypes` / -
 * @AS_TAG_PROVIDES:			`provides` / `Provides`
 * @AS_TAG_SCREENSHOTS:			`screenshots` / `Screenshots`
 * @AS_TAG_METADATA_LICENSE:		`metadata_license` / `MetadataLicense`
 * @AS_TAG_PROJECT_LICENSE:		`project_license` / `ProjectLicense`
 * @AS_TAG_PROJECT_GROUP:		`project_group` / `ProjectGroup`
 * @AS_TAG_DEVELOPER_NAME:		`developer_name` / `DeveloperName`
 * @AS_TAG_COMPULSORY_FOR_DESKTOP:	`compulsory_for_desktop` / `CompulsoryForDesktops`
 * @AS_TAG_RELEASES:			`releases` / `Releases`
 * @AS_TAG_EXTENDS:			`extends` / `Extends`
 * @AS_TAG_LANGUAGES:			`languages` / `Languages`
 * @AS_TAG_LAUNCHABLE:			`launchable` / `Launchables`
 * @AS_TAG_BUNDLE:			`bundle` / `Bundles`
 * @AS_TAG_TRANSLATION:			`translation` / -
 * @AS_TAG_SUGGESTS:			`suggests` / `Suggests`
 * @AS_TAG_CUSTOM:			`custom` / `Custom`
 * @AS_TAG_CONTENT_RATING:		`content_rating` / `ContentRating`
 * @AS_TAG_RECOMMENDS:			`recommends` / `Recommends`
 * @AS_TAG_REQUIRES:			`requires` / `Requires`
 * @AS_TAG_AGREEMENT:			`agreement` / `Àgreement`
 *
 * The tag type.
 **/
typedef enum {
	AS_TAG_UNKNOWN,
	AS_TAG_TYPE,
	AS_TAG_PRIORITY,
	AS_TAG_MERGE,
	AS_TAG_ID,
	AS_TAG_PKGNAME,
	AS_TAG_SOURCE_PKGNAME,
	AS_TAG_NAME,
	AS_TAG_SUMMARY,
	AS_TAG_DESCRIPTION,
	AS_TAG_ICON,
	AS_TAG_URL,
	AS_TAG_CATEGORIES,
	AS_TAG_KEYWORDS,
	AS_TAG_MIMETYPES,
	AS_TAG_PROVIDES,
	AS_TAG_SCREENSHOTS,
	AS_TAG_METADATA_LICENSE,
	AS_TAG_PROJECT_LICENSE,
	AS_TAG_PROJECT_GROUP,
	AS_TAG_DEVELOPER_NAME,
	AS_TAG_COMPULSORY_FOR_DESKTOP,
	AS_TAG_RELEASES,
	AS_TAG_EXTENDS,
	AS_TAG_LANGUAGES,
	AS_TAG_LAUNCHABLE,
	AS_TAG_BUNDLE,
	AS_TAG_TRANSLATION,
	AS_TAG_SUGGESTS,
	AS_TAG_CUSTOM,
	AS_TAG_CONTENT_RATING,
	AS_TAG_RECOMMENDS,
	AS_TAG_REQUIRES,
	AS_TAG_AGREEMENT,

	/*< private >*/
	AS_TAG_LAST
} AsTag;

AsTag			as_xml_tag_from_string (const gchar *tag);

AsTag			as_yaml_tag_from_string (const gchar *tag);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_TAG_H */
