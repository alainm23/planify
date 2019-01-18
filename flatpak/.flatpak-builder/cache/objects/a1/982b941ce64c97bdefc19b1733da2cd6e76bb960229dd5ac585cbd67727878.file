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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_FLAG_H
#define E_FLAG_H

/* An EFlag is essentially a binary semaphore with a more intuitive interface.
 * Based on Python's threading.Event class ("EEvent" was already taken). */

#include <glib.h>

G_BEGIN_DECLS

/**
 * EFlag:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 1.12
 **/
typedef struct _EFlag EFlag;

EFlag *		e_flag_new			(void);
gboolean	e_flag_is_set			(EFlag *flag);
void		e_flag_set			(EFlag *flag);
void		e_flag_clear			(EFlag *flag);
void		e_flag_wait			(EFlag *flag);
gboolean	e_flag_wait_until		(EFlag *flag,
						 gint64 end_time);
void		e_flag_free			(EFlag *flag);

#ifndef EDS_DISABLE_DEPRECATED
gboolean	e_flag_timed_wait		(EFlag *flag,
						 GTimeVal *abs_time);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_FLAG_H */
