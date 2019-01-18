/*<private_header>*/
/*
 * variant-util-internal.h - Headers for non-public GVariant utility functions
 *
 * Copyright (C) 2012 Collabora Ltd. <http://www.collabora.co.uk/>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef __TP_VARIANT_UTIL_INTERNAL_H__
#define __TP_VARIANT_UTIL_INTERNAL_H__

#include <glib.h>
#include <gio/gio.h>

GVariant *_tp_asv_to_vardict (const GHashTable *asv);

GVariant * _tp_boxed_to_variant (GType gtype,
    const gchar *variant_type,
    gpointer boxed);

GHashTable * _tp_asv_from_vardict (GVariant *variant);

#endif /* __TP_VARIANT_UTIL_INTERNAL_H__ */
