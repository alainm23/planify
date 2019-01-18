/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_TEXT_INDEX_H
#define CAMEL_TEXT_INDEX_H

#include <camel/camel-index.h>

/* Standard GObject macros */
#define CAMEL_TYPE_TEXT_INDEX \
	(camel_text_index_get_type ())
#define CAMEL_TEXT_INDEX(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_TEXT_INDEX, CamelTextIndex))
#define CAMEL_TEXT_INDEX_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_TEXT_INDEX, CamelTextIndexClass))
#define CAMEL_IS_TEXT_INDEX(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_TEXT_INDEX))
#define CAMEL_IS_TEXT_INDEX_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_TEXT_INDEX))
#define CAMEL_TEXT_INDEX_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_TEXT_INDEX, CamelTextIndexClass))

#define CAMEL_TYPE_TEXT_INDEX_NAME \
	(camel_text_index_name_get_type ())
#define CAMEL_TEXT_INDEX_NAME(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_TEXT_INDEX_NAME, CamelTextIndexName))
#define CAMEL_TEXT_INDEX_NAME_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_TEXT_INDEX_NAME, CamelTextIndexNameClass))
#define CAMEL_IS_TEXT_INDEX_NAME(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_TEXT_INDEX_NAME))
#define CAMEL_IS_TEXT_INDEX_NAME_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_TEXT_INDEX_NAME))
#define CAMEL_TEXT_INDEX_NAME_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_TEXT_INDEX_NAME, CamelTextIndexNameClass))

#define CAMEL_TYPE_TEXT_INDEX_CURSOR \
	(camel_text_index_cursor_get_type ())
#define CAMEL_TEXT_INDEX_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_TEXT_INDEX_CURSOR, CamelTextIndexCursor))
#define CAMEL_TEXT_INDEX_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_TEXT_INDEX_CURSOR, CamelTextIndexCursorClass))
#define CAMEL_IS_TEXT_INDEX_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_TEXT_INDEX_CURSOR))
#define CAMEL_IS_TEXT_INDEX_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_TEXT_INDEX_CURSOR))
#define CAMEL_TEXT_INDEX_CURSOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_TEXT_INDEX_CURSOR, CamelTextIndexCursorClass))

#define CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR \
	(camel_text_index_key_cursor_get_type ())
#define CAMEL_TEXT_INDEX_KEY_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR, CamelTextIndexKeyCursor))
#define CAMEL_TEXT_INDEX_KEY_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR, CamelTextIndexKeyCursorClass))
#define CAMEL_IS_TEXT_INDEX_KEY_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR))
#define CAMEL_IS_TEXT_INDEX_KEY_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR))
#define CAMEL_TEXT_INDEX_KEY_CURSOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR, CamelTextIndexKeyCursorClass))

G_BEGIN_DECLS

typedef struct _CamelTextIndex CamelTextIndex;
typedef struct _CamelTextIndexClass CamelTextIndexClass;
typedef struct _CamelTextIndexPrivate CamelTextIndexPrivate;

typedef struct _CamelTextIndexName CamelTextIndexName;
typedef struct _CamelTextIndexNameClass CamelTextIndexNameClass;
typedef struct _CamelTextIndexNamePrivate CamelTextIndexNamePrivate;

typedef struct _CamelTextIndexCursor CamelTextIndexCursor;
typedef struct _CamelTextIndexCursorClass CamelTextIndexCursorClass;
typedef struct _CamelTextIndexCursorPrivate CamelTextIndexCursorPrivate;

typedef struct _CamelTextIndexKeyCursor CamelTextIndexKeyCursor;
typedef struct _CamelTextIndexKeyCursorClass CamelTextIndexKeyCursorClass;
typedef struct _CamelTextIndexKeyCursorPrivate CamelTextIndexKeyCursorPrivate;

typedef void (*CamelTextIndexFunc)(CamelTextIndex *idx, const gchar *word, gchar *buffer);

/* ********************************************************************** */

struct _CamelTextIndexCursor {
	CamelIndexCursor parent;
	CamelTextIndexCursorPrivate *priv;
};

struct _CamelTextIndexCursorClass {
	CamelIndexCursorClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_text_index_cursor_get_type (void);

/* ********************************************************************** */

struct _CamelTextIndexKeyCursor {
	CamelIndexCursor parent;
	CamelTextIndexKeyCursorPrivate *priv;
};

struct _CamelTextIndexKeyCursorClass {
	CamelIndexCursorClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_text_index_key_cursor_get_type (void);

/* ********************************************************************** */

struct _CamelTextIndexName {
	CamelIndexName parent;
	CamelTextIndexNamePrivate *priv;
};

struct _CamelTextIndexNameClass {
	CamelIndexNameClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_text_index_name_get_type (void);

/* ********************************************************************** */

struct _CamelTextIndex {
	CamelIndex parent;
	CamelTextIndexPrivate *priv;
};

struct _CamelTextIndexClass {
	CamelIndexClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_text_index_get_type	(void);
CamelTextIndex *camel_text_index_new		(const gchar *path,
						 gint flags);

/* static utility functions */
gint		camel_text_index_check		(const gchar *path);
gint		camel_text_index_rename		(const gchar *old,
						 const gchar *new_);
gint		camel_text_index_remove		(const gchar *old);

void		camel_text_index_dump		(CamelTextIndex *idx);
void		camel_text_index_info		(CamelTextIndex *idx);
void		camel_text_index_validate	(CamelTextIndex *idx);

G_END_DECLS

#endif /* CAMEL_TEXT_INDEX_H */
