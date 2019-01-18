/*
 * Copyright (C) 2012 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#ifndef _HAVE_DEE_ICU_H
#define _HAVE_DEE_ICU_H

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

/**
 * DEE_ICU_ERROR:
 *
 * Error domain for the ICU extension to Dee. Error codes will be from the
 * #DeeICUError enumeration
 */
#define DEE_ICU_ERROR dee_icu_error_quark()

/**
 * DeeICUError:
 *
 * Error codes for the ICU extension to Dee. These codes will be set when the
 * error domain is #DEE_ICU_ERROR.
 *
 * @DEE_ICU_ERROR_BAD_RULE: Error parsing a transliteration rule
 * @DEE_ICU_ERROR_BAD_ID: Error parsing a transliterator system id
 * @DEE_ICU_ERROR_UNKNOWN: The ICU subsystem returned an error that is not
 *                         handled in Dee
 */
typedef enum {
  DEE_ICU_ERROR_BAD_RULE,
  DEE_ICU_ERROR_BAD_ID,
  DEE_ICU_ERROR_UNKNOWN
} DeeICUError;

typedef struct _DeeICUTermFilter DeeICUTermFilter;

DeeICUTermFilter*        dee_icu_term_filter_new         (const gchar* system_id,
                                                          const gchar  *rules,
                                                       GError      **error);

DeeICUTermFilter*        dee_icu_term_filter_new_ascii_folder ();

gchar*                   dee_icu_term_filter_apply       (DeeICUTermFilter *self,
                                                          const gchar *text);

void                     dee_icu_term_filter_destroy     (DeeICUTermFilter *filter);

GQuark                   dee_icu_error_quark              (void);

G_END_DECLS

#endif /* _HAVE_DEE_ICU_H */
