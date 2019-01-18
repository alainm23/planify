/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
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
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_TRIE_H
#define CAMEL_TRIE_H

#include <glib.h>

G_BEGIN_DECLS

typedef struct _CamelTrie CamelTrie;

CamelTrie *	camel_trie_new			(gboolean icase);
void		camel_trie_free			(CamelTrie *trie);
void		camel_trie_add			(CamelTrie *trie,
						 const gchar *pattern,
						 gint pattern_id);
const gchar *	camel_trie_search		(CamelTrie *trie,
						 const gchar *buffer,
						 gsize buflen,
						 gint *matched_id);

G_END_DECLS

#endif /* CAMEL_TRIE_H */
