/*
 * Copyright (C) 2010 Canonical, Ltd.
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

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_TERM_LIST_H
#define _HAVE_DEE_TERM_LIST_H

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define DEE_TYPE_TERM_LIST (dee_term_list_get_type ())

#define DEE_TERM_LIST(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_TERM_LIST, DeeTermList))

#define DEE_TERM_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_TERM_LIST, DeeTermListClass))

#define DEE_IS_TERM_LIST(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_TERM_LIST))

#define DEE_IS_TERM_LIST_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_TERM_LIST))

#define DEE_TERM_LIST_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_TERM_LIST, DeeTermListClass))

typedef struct _DeeTermListClass DeeTermListClass;
typedef struct _DeeTermList DeeTermList;
typedef struct _DeeTermListPrivate DeeTermListPrivate;

/**
 * DeeTermList:
 *
 * All fields in the DeeTermList structure are private and should never be
 * accessed directly
 */
struct _DeeTermList
{
  /*< private >*/
  GObject          parent;

  DeeTermListPrivate *priv;
};

struct _DeeTermListClass
{
  GObjectClass     parent_class;

  /*< public >*/
  const gchar*   (* get_term)           (DeeTermList     *self,
                                         guint            n);

  DeeTermList*   (* add_term)           (DeeTermList     *self,
                                         const gchar     *term);

  guint          (* num_terms)          (DeeTermList     *self);

  DeeTermList*   (* clear)              (DeeTermList     *self);

  DeeTermList*   (* clone)              (DeeTermList     *self);

  /*< private >*/
  void (*_dee_term_list_1) (void);
  void (*_dee_term_list_2) (void);
  void (*_dee_term_list_3) (void);
  void (*_dee_term_list_4) (void);

};

GType                dee_term_list_get_type        (void);

const gchar*         dee_term_list_get_term        (DeeTermList *self,
                                                    guint        n);

DeeTermList*         dee_term_list_add_term        (DeeTermList *self,
                                                    const gchar *term);

guint                dee_term_list_num_terms       (DeeTermList *self);

DeeTermList*         dee_term_list_clear           (DeeTermList *self);

DeeTermList*         dee_term_list_clone           (DeeTermList *self);

G_END_DECLS

#endif /* _HAVE_DEE_TERM_LIST_H */
