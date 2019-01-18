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
 *          Jacob Berkman <jacob@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MEMCHUNK_H
#define CAMEL_MEMCHUNK_H

#include <glib.h>

G_BEGIN_DECLS

/* memchunks - allocate/free fixed-size blocks of memory */
/* this is like gmemchunk, only faster and less overhead (only 4 bytes for every atomcount allocations) */
typedef struct _CamelMemChunk CamelMemChunk;

CamelMemChunk *	camel_memchunk_new		(gint atomcount,
						 gint atomsize);
gpointer	camel_memchunk_alloc		(CamelMemChunk *memchunk);
gpointer	camel_memchunk_alloc0		(CamelMemChunk *memchunk);
void		camel_memchunk_free		(CamelMemChunk *memchunk,
						 gpointer mem);
void		camel_memchunk_empty		(CamelMemChunk *memchunk);
void		camel_memchunk_clean		(CamelMemChunk *memchunk);
void		camel_memchunk_destroy		(CamelMemChunk *memchunk);

G_END_DECLS

#endif /* CAMEL_MEMCHUNK_H */
