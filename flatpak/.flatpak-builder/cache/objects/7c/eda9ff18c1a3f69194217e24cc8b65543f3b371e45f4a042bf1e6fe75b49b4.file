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

#ifndef CAMEL_MEMPOOL_H
#define CAMEL_MEMPOOL_H

#include <glib.h>

G_BEGIN_DECLS

/* mempools - allocate variable sized blocks of memory, and free as one */
/* allocation is very fast, but cannot be freed individually */

/**
 * CamelMemPool:
 *
 * Since: 2.32
 **/
typedef struct _CamelMemPool CamelMemPool;

/**
 * CamelMemPoolFlags:
 * @CAMEL_MEMPOOL_ALIGN_STRUCT:
 *	Allocate to native structure alignment
 * @CAMEL_MEMPOOL_ALIGN_WORD:
 *	Allocate to words - 16 bit alignment
 * @CAMEL_MEMPOOL_ALIGN_BYTE:
 *	Allocate to bytes - 8 bit alignment
 * @CAMEL_MEMPOOL_ALIGN_MASK:
 *	Which bits determine the alignment information
 *
 * Since: 2.32
 **/
typedef enum {
	CAMEL_MEMPOOL_ALIGN_STRUCT,
	CAMEL_MEMPOOL_ALIGN_WORD,
	CAMEL_MEMPOOL_ALIGN_BYTE,
	CAMEL_MEMPOOL_ALIGN_MASK = 0x3
} CamelMemPoolFlags;

CamelMemPool *	camel_mempool_new		(gint blocksize,
						 gint threshold,
						 CamelMemPoolFlags flags);
gpointer	camel_mempool_alloc		(CamelMemPool *pool,
						 gint size);
gchar *		camel_mempool_strdup		(CamelMemPool *pool,
						 const gchar *str);
void		camel_mempool_flush		(CamelMemPool *pool,
						 gint freeall);
void		camel_mempool_destroy		(CamelMemPool *pool);

G_END_DECLS

#endif /* CAMEL_MEMPOOL_H */
