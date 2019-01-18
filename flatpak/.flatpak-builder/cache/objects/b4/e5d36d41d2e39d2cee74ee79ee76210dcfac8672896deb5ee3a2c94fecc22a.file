/*
 * contact-search.h - a representation for an ongoing search for contacts
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

#ifndef __TP_CONTACT_SEARCH_H__
#define __TP_CONTACT_SEARCH_H__

#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>
#include <telepathy-glib/proxy.h>
#include <telepathy-glib/account.h>

G_BEGIN_DECLS

#define TP_TYPE_CONTACT_SEARCH \
  (tp_contact_search_get_type ())
#define TP_CONTACT_SEARCH(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CONTACT_SEARCH, \
                               TpContactSearch))
#define TP_CONTACT_SEARCH_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CONTACT_SEARCH, \
                            TpContactSearchClass))
#define TP_IS_CONTACT_SEARCH(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CONTACT_SEARCH))
#define TP_IS_CONTACT_SEARCH_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CONTACT_SEARCH))
#define TP_CONTACT_SEARCH_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CONTACT_SEARCH, \
                              TpContactSearchClass))

typedef struct _TpContactSearch TpContactSearch;
typedef struct _TpContactSearchPrivate TpContactSearchPrivate;
typedef struct _TpContactSearchClass TpContactSearchClass;

struct _TpContactSearch
{
    /*<private>*/
    GObject parent;
    TpContactSearchPrivate *priv;
};

struct _TpContactSearchClass
{
    /*<private>*/
    GObjectClass parent_class;
    GCallback _padding[7];
};

GType tp_contact_search_get_type (void);

void tp_contact_search_new_async (TpAccount *account,
    const gchar *server,
    guint limit,
    GAsyncReadyCallback callback,
    gpointer user_data);
TpContactSearch *tp_contact_search_new_finish (GAsyncResult *result,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

void tp_contact_search_reset_async (TpContactSearch *self,
    const gchar *server,
    guint limit,
    GAsyncReadyCallback callback,
    gpointer user_data);

const gchar * const *
/* this comment stops gtkdoc denying that this function exists */
tp_contact_search_reset_finish (TpContactSearch *self,
    GAsyncResult *result,
    GError **error);

void tp_contact_search_start (TpContactSearch *self,
    GHashTable *criteria);

const gchar * const *
/* this comment stops gtkdoc denying that this function exists */
tp_contact_search_get_search_keys (TpContactSearch *self);

TpAccount * tp_contact_search_get_account (TpContactSearch *self);
const gchar * tp_contact_search_get_server (TpContactSearch *self);
guint tp_contact_search_get_limit (TpContactSearch *self);

G_END_DECLS

#endif
