/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_VALIDATOR_ISSUE_H
#define __AS_VALIDATOR_ISSUE_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_VALIDATOR_ISSUE (as_validator_issue_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsValidatorIssue, as_validator_issue, AS, VALIDATOR_ISSUE, GObject)

struct _AsValidatorIssueClass
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
 * AsIssueImportance:
 * @AS_ISSUE_IMPORTANCE_ERROR:		There is a serious error in your metadata
 * @AS_ISSUE_IMPORTANCE_WARNING:	Something which should be fixed, but is not fatal
 * @AS_ISSUE_IMPORTANCE_INFO:		Non-essential information on how to improve your metadata
 * @AS_ISSUE_IMPORTANCE_PEDANTIC:	Pedantic information
 *
 * The importance of an issue found by #AsValidator
 **/
typedef enum {
	AS_ISSUE_IMPORTANCE_UNKNOWN,
	AS_ISSUE_IMPORTANCE_ERROR,
	AS_ISSUE_IMPORTANCE_WARNING,
	AS_ISSUE_IMPORTANCE_INFO,
	AS_ISSUE_IMPORTANCE_PEDANTIC,
	/*< private >*/
	AS_ISSUE_IMPORTANCE_LAST
} AsIssueImportance;

/**
 * AsIssueKind:
 * @AS_ISSUE_KIND_UNKNOWN:		Type invalid or not known
 * @AS_ISSUE_KIND_MARKUP_INVALID:	The XML markup is invalid
 * @AS_ISSUE_KIND_LEGACY:		An element from a legacy AppStream specification has been found
 * @AS_ISSUE_KIND_TAG_DUPLICATED:	A tag is duplicated
 * @AS_ISSUE_KIND_TAG_MISSING:		A required tag is missing
 * @AS_ISSUE_KIND_TAG_UNKNOWN:		An unknown tag was found
 * @AS_ISSUE_KIND_TAG_NOT_ALLOWED:	A tag is not allowed in the current context
 * @AS_ISSUE_KIND_PROPERTY_MISSING:	A required property is missing
 * @AS_ISSUE_KIND_PROPERTY_INVALID:	A property is invalid
 * @AS_ISSUE_KIND_VALUE_MISSING:	A value is missing
 * @AS_ISSUE_KIND_VALUE_WRONG:		The value of a tag or property is wrong
 * @AS_ISSUE_KIND_VALUE_ISSUE:		There is an issue with a tag or property value (often non-fatal)
 * @AS_ISSUE_KIND_FILE_MISSING:		A required file or other metadata was missing
 * @AS_ISSUE_KIND_WRONG_NAME:		The naming of an entity is wrong
 * @AS_ISSUE_KIND_READ_ERROR:		Reading of data failed
 * @AS_ISSUE_KIND_REMOTE_ERROR:		Getting additional content from a remote location failed
 * @AS_ISSUE_KIND_UNUSUAL:		Unusual combination of values and likely not intended
 *
 * The issue type.
 **/
typedef enum {
	AS_ISSUE_KIND_UNKNOWN,
	AS_ISSUE_KIND_MARKUP_INVALID,
	AS_ISSUE_KIND_LEGACY,
	AS_ISSUE_KIND_TAG_DUPLICATED,
	AS_ISSUE_KIND_TAG_MISSING,
	AS_ISSUE_KIND_TAG_UNKNOWN,
	AS_ISSUE_KIND_TAG_NOT_ALLOWED,
	AS_ISSUE_KIND_PROPERTY_MISSING,
	AS_ISSUE_KIND_PROPERTY_INVALID,
	AS_ISSUE_KIND_VALUE_MISSING,
	AS_ISSUE_KIND_VALUE_WRONG,
	AS_ISSUE_KIND_VALUE_ISSUE,
	AS_ISSUE_KIND_FILE_MISSING,
	AS_ISSUE_KIND_WRONG_NAME,
	AS_ISSUE_KIND_READ_ERROR,
	AS_ISSUE_KIND_REMOTE_ERROR,
	AS_ISSUE_KIND_UNUSUAL,
	/*< private >*/
	AS_ISSUE_KIND_LAST
} AsIssueKind;

AsValidatorIssue	*as_validator_issue_new (void);

AsIssueKind		as_validator_issue_get_kind (AsValidatorIssue *issue);
void			as_validator_issue_set_kind (AsValidatorIssue *issue,
							AsIssueKind kind);

AsIssueImportance	as_validator_issue_get_importance (AsValidatorIssue *issue);
void 			as_validator_issue_set_importance (AsValidatorIssue *issue,
								AsIssueImportance importance);

const gchar		*as_validator_issue_get_message (AsValidatorIssue *issue);
void			as_validator_issue_set_message (AsValidatorIssue *issue,
							const gchar *message);

const gchar		*as_validator_issue_get_cid (AsValidatorIssue *issue);
void			as_validator_issue_set_cid (AsValidatorIssue *issue,
						    const gchar *cid);

const gchar		*as_validator_issue_get_filename (AsValidatorIssue *issue);
void			as_validator_issue_set_filename (AsValidatorIssue *issue,
							 const gchar *fname);

gint			as_validator_issue_get_line (AsValidatorIssue *issue);
void			as_validator_issue_set_line (AsValidatorIssue *issue,
						     gint line);

gchar			*as_validator_issue_get_location (AsValidatorIssue *issue);


G_END_DECLS

#endif /* __AS_VALIDATOR_ISSUE_H */
