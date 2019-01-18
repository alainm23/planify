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
 * Authors: Michael Zucchi <notzed@ximian.com>
 *	    Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_NET_UTILS_H
#define CAMEL_NET_UTILS_H

#include <gio/gio.h>
#include <sys/types.h>

#ifndef _WIN32
#include <sys/socket.h>
#include <netdb.h>
#else
#define socklen_t int
struct sockaddr;
struct addrinfo;
#endif

G_BEGIN_DECLS

#ifndef _WIN32
#ifdef NEED_ADDRINFO
/* Some of this is copied from GNU's netdb.h
 *
 * Copyright (C) 1996 - 2002, 2003, 2004 Free Software Foundation, Inc.
 * This file is part of the GNU C Library.
 *
 * The GNU C Library is free software; you can redistribute it and / or
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 */
struct addrinfo {
	gint ai_flags;
	gint ai_family;
	gint ai_socktype;
	gint ai_protocol;
	gsize ai_addrlen;
	struct sockaddr *ai_addr;
	gchar *ai_canonname;
	struct addrinfo *ai_next;
};

#define AI_CANONNAME	0x0002	/* Request for canonical name.  */
#define AI_NUMERICHOST	0x0004	/* Don't use name resolution.  */

/* Error values for `getaddrinfo' function.  */
#define EAI_BADFLAGS	  -1	/* Invalid value for `ai_flags' field.  */
#define EAI_NONAME	  -2	/* NAME or SERVICE is unknown.  */
#define EAI_AGAIN	  -3	/* Temporary failure in name resolution.  */
#define EAI_FAIL	  -4	/* Non-recoverable failure in name res.  */
#define EAI_NODATA	  -5	/* No address associated with NAME.  */
#define EAI_FAMILY	  -6	/* `ai_family' not supported.  */
#define EAI_SOCKTYPE	  -7	/* `ai_socktype' not supported.  */
#define EAI_SERVICE	  -8	/* SERVICE not supported for `ai_socktype'.  */
#define EAI_ADDRFAMILY	  -9	/* Address family for NAME not supported.  */
#define EAI_MEMORY	  -10	/* Memory allocation failure.  */
#define EAI_SYSTEM	  -11	/* System error returned in `errno'.  */
#define EAI_OVERFLOW	  -12	/* Argument buffer overflow.  */

#define NI_NUMERICHOST	1	/* Don't try to look up hostname.  */
#define NI_NUMERICSERV	2	/* Don't convert port number to name.  */
#define NI_NOFQDN	4	/* Only return nodename portion.  */
#define NI_NAMEREQD	8	/* Don't return numeric addresses.  */
#define NI_DGRAM	16	/* Look up UDP service rather than TCP.  */
#endif
#endif

struct addrinfo *
		camel_getaddrinfo		(const gchar *name,
						 const gchar *service,
						 const struct addrinfo *hints,
						 GCancellable *cancellable,
						 GError **error);
void		camel_freeaddrinfo		(struct addrinfo *host);

gchar *		camel_host_idna_to_ascii	(const gchar *host);

G_END_DECLS

#ifdef _WIN32
#undef socklen_t
#endif

#endif /* CAMEL_NET_UTILS_H */
