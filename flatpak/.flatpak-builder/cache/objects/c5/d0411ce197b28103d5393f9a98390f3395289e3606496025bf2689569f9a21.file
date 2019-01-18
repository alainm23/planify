/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Richard Hughes <richard@hughsie.com>
 * Copyright (C) 2018 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_AGREEMENT_H
#define __AS_AGREEMENT_H

#include <glib-object.h>

#include "as-agreement-section.h"

G_BEGIN_DECLS

#define AS_TYPE_AGREEMENT (as_agreement_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsAgreement, as_agreement, AS, AGREEMENT, GObject)

struct _AsAgreementClass
{
	GObjectClass		parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
	void (*_as_reserved5)	(void);
	void (*_as_reserved6)	(void);
	void (*_as_reserved7)	(void);
	void (*_as_reserved8)	(void);
};

/**
 * AsAgreementKind:
 * @AS_AGREEMENT_KIND_UNKNOWN:		Unknown value
 * @AS_AGREEMENT_KIND_GENERIC:		A generic agreement without a specific type
 * @AS_AGREEMENT_KIND_EULA:		An End User License Agreement
 * @AS_AGREEMENT_KIND_PRIVACY:		A privacy agreement, typically a GDPR statement
 *
 * The kind of the agreement.
 **/
typedef enum {
	AS_AGREEMENT_KIND_UNKNOWN,
	AS_AGREEMENT_KIND_GENERIC,
	AS_AGREEMENT_KIND_EULA,
	AS_AGREEMENT_KIND_PRIVACY,
	/*< private >*/
	AS_AGREEMENT_KIND_LAST
} AsAgreementKind;

AsAgreement		*as_agreement_new (void);

const gchar		*as_agreement_kind_to_string (AsAgreementKind value);
AsAgreementKind	 	as_agreement_kind_from_string (const gchar *value);

AsAgreementKind	 	as_agreement_get_kind (AsAgreement *agreement);
void		 	as_agreement_set_kind (AsAgreement *agreement,
						AsAgreementKind	 kind);

const gchar		*as_agreement_get_version_id (AsAgreement *agreement);
void			as_agreement_set_version_id (AsAgreement *agreement,
							const gchar *version_id);

AsAgreementSection	*as_agreement_get_section_default (AsAgreement *agreement);
GPtrArray		*as_agreement_get_sections (AsAgreement *agreement);
void		 	as_agreement_add_section (AsAgreement *agreement,
						  AsAgreementSection *agreement_section);

G_END_DECLS

#endif /* __AS_AGREEMENT_H */
