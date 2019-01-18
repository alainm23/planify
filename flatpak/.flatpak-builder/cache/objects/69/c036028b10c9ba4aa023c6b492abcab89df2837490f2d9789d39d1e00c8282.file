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

#ifndef __AS_VALIDATOR_H
#define __AS_VALIDATOR_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_VALIDATOR (as_validator_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsValidator, as_validator, AS, VALIDATOR, GObject)

struct _AsValidatorClass
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

AsValidator	*as_validator_new (void);

void		as_validator_clear_issues (AsValidator *validator);
gboolean	as_validator_validate_file (AsValidator *validator,
						GFile* metadata_file);
gboolean	as_validator_validate_data (AsValidator *validator,
						const gchar *metadata);
gboolean	as_validator_validate_tree (AsValidator *validator,
						const gchar *root_dir);

GList		*as_validator_get_issues (AsValidator *validator);

gboolean	as_validator_get_check_urls (AsValidator *validator);
void		as_validator_set_check_urls (AsValidator *validator,
						gboolean value);

G_END_DECLS

#endif /* __AS_VALIDATOR_H */
