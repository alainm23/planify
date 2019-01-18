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

#ifndef __AS_AGREEMENT_SECTION_H
#define __AS_AGREEMENT_SECTION_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_AGREEMENT_SECTION (as_agreement_section_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsAgreementSection, as_agreement_section, AS, AGREEMENT_SECTION, GObject)

struct _AsAgreementSectionClass
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

AsAgreementSection	*as_agreement_section_new (void);

const gchar		*as_agreement_section_get_kind (AsAgreementSection *agreement_section);
void			as_agreement_section_set_kind (AsAgreementSection *agreement_section,
							const gchar *kind);

const gchar		*as_agreement_section_get_name (AsAgreementSection *agreement_section);
void		 	as_agreement_section_set_name (AsAgreementSection *agreement_section,
							const gchar *name,
							const gchar *locale);

const gchar		*as_agreement_section_get_description (AsAgreementSection *agreement_section);
void			as_agreement_section_set_description (AsAgreementSection *agreement_section,
								const gchar *desc,
								const gchar *locale);

const gchar		*as_agreement_section_get_active_locale (AsAgreementSection *agreement_section);
void			as_agreement_section_set_active_locale (AsAgreementSection *agreement_section,
								const gchar *locale);

G_END_DECLS

#endif /* __AS_AGREEMENT_SECTION_H */
