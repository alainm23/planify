/*
 * e-source-memo-list.h
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_MEMO_LIST_H
#define E_SOURCE_MEMO_LIST_H

#include <libedataserver/e-source-selectable.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MEMO_LIST \
	(e_source_memo_list_get_type ())
#define E_SOURCE_MEMO_LIST(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MEMO_LIST, ESourceMemoList))
#define E_SOURCE_MEMO_LIST_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MEMO_LIST, ESourceMemoListClass))
#define E_IS_SOURCE_MEMO_LIST(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MEMO_LIST))
#define E_IS_SOURCE_MEMO_LIST_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MEMO_LIST))
#define E_SOURCE_MEMO_LIST_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MEMO_LIST, ESourceMemoListClass))

/**
 * E_SOURCE_EXTENSION_MEMO_LIST:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMemoList.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MEMO_LIST "Memo List"

G_BEGIN_DECLS

typedef struct _ESourceMemoList ESourceMemoList;
typedef struct _ESourceMemoListClass ESourceMemoListClass;
typedef struct _ESourceMemoListPrivate ESourceMemoListPrivate;

/**
 * ESourceMemoList:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceMemoList {
	/*< private >*/
	ESourceSelectable parent;
	ESourceMemoListPrivate *priv;
};

struct _ESourceMemoListClass {
	ESourceSelectableClass parent_class;
};

GType		e_source_memo_list_get_type	(void);

G_END_DECLS

#endif /* E_SOURCE_MEMO_LIST_H */
