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
 *	    Jacob Berkman <jacob@ximian.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_MEMORY_H
#define E_MEMORY_H

#include <glib.h>

G_BEGIN_DECLS

/* memchunks - allocate/free fixed-size blocks of memory */
/* this is like gmemchunk, only faster and less overhead (only 4 bytes for every atomcount allocations) */
typedef struct _EMemChunk EMemChunk;

EMemChunk *	e_memchunk_new			(gint atomcount,
						 gint atomsize);
gpointer	e_memchunk_alloc		(EMemChunk *memchunk);
gpointer	e_memchunk_alloc0		(EMemChunk *memchunk);
void		e_memchunk_free			(EMemChunk *memchunk,
						 gpointer mem);
void		e_memchunk_empty		(EMemChunk *memchunk);
void		e_memchunk_clean		(EMemChunk *memchunk);
void		e_memchunk_destroy		(EMemChunk *memchunk);

G_END_DECLS

#endif /* E_MEMORY_H */
