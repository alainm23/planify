/*
 * contact-search-result.h - a result from a contact search
 *
 * Copyright (C) 2010-2011 Collabora Ltd.
 *
 * The code contained in this file is free software; you can redistribute
 * it and/or modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this code; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_CONTACT_SEARCH_RESULT_H__
#define __TP_CONTACT_SEARCH_RESULT_H__

#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/util.h>

G_BEGIN_DECLS

#define TP_TYPE_CONTACT_SEARCH_RESULT \
  (tp_contact_search_result_get_type ())
#define TP_CONTACT_SEARCH_RESULT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CONTACT_SEARCH_RESULT, \
                               TpContactSearchResult))
#define TP_CONTACT_SEARCH_RESULT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CONTACT_SEARCH_RESULT, \
                            TpContactSearchResultClass))
#define TP_IS_CONTACT_SEARCH_RESULT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CONTACT_SEARCH_RESULT))
#define TP_IS_CONTACT_SEARCH_RESULT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CONTACT_SEARCH_RESULT))
#define TP_CONTACT_SEARCH_RESULT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CONTACT_SEARCH_RESULT, \
                              TpContactSearchResultClass))

typedef struct _TpContactSearchResult TpContactSearchResult;
typedef struct _TpContactSearchResultPrivate TpContactSearchResultPrivate;
typedef struct _TpContactSearchResultClass TpContactSearchResultClass;

struct _TpContactSearchResult
{
    /*<private>*/
    GObject parent;
    TpContactSearchResultPrivate *priv;
};

struct _TpContactSearchResultClass
{
    /*<private>*/
    GObjectClass parent_class;
    GCallback _padding[7];
};

GType tp_contact_search_result_get_type (void);

const gchar *tp_contact_search_result_get_identifier (TpContactSearchResult *self);
TpContactInfoField *tp_contact_search_result_get_field (TpContactSearchResult *self,
    const gchar *field);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR (tp_contact_search_result_dup_fields)
GList *tp_contact_search_result_get_fields (TpContactSearchResult *self);
#endif

_TP_AVAILABLE_IN_0_20
GList *tp_contact_search_result_dup_fields (TpContactSearchResult *self);

G_END_DECLS

#endif
