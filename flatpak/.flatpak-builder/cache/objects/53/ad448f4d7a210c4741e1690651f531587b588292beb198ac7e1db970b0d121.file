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
 *	    Chris Toshok <toshok@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>

#include <glib/gi18n-lib.h>
#include <unicode/uidna.h>
#include <unicode/ustring.h>

#include "camel-msgport.h"
#include "camel-net-utils.h"
#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#ifdef HAVE_WSPIAPI_H
#include <wspiapi.h>
#endif
#endif
#include "camel-object.h"
#include "camel-operation.h"
#include "camel-service.h"

#define d(x)

/* These are GNU extensions */
#ifndef NI_MAXHOST
#define NI_MAXHOST	1025
#endif
#ifndef NI_MAXSERV
#define NI_MAXSERV	32
#endif

#ifdef G_OS_WIN32

typedef gshort in_port_t;

#undef gai_strerror
#define gai_strerror my_gai_strerror

/* gai_strerror() is implemented as an inline function in Microsoft's
 * SDK, but mingw lacks that. So implement here. The EAI_* errors can
 * be handled with the normal FormatMessage() API,
 * i.e. g_win32_error_message().
 */

static const gchar *
gai_strerror (gint error_code)
{
	gchar *msg = g_win32_error_message (error_code);
	GQuark quark = g_quark_from_string (msg);
	const gchar *retval = g_quark_to_string (quark);

	g_free (msg);

	return retval;
}

#endif

/* gethostbyname emulation code for emulating getaddrinfo code ...
 *
 * This should probably go away */

#ifdef NEED_ADDRINFO

#if !defined (HAVE_GETHOSTBYNAME_R) || !defined (HAVE_GETHOSTBYADDR_R)
G_LOCK_DEFINE_STATIC (gethost_mutex);
#endif

#define ALIGN(x) (((x) + (sizeof (gchar *) - 1)) & ~(sizeof (gchar *) - 1))

#define GETHOST_PROCESS(h, host, buf, buflen, herr) G_STMT_START { \
	gint num_aliases = 0, num_addrs = 0; \
	gint req_length; \
	gchar *p; \
	gint i; \
 \
	/* check to make sure we have enough room in our buffer */ \
	req_length = 0; \
	if (h->h_aliases) { \
		for (i = 0; h->h_aliases[i]; i++) \
			req_length += strlen (h->h_aliases[i]) + 1; \
		num_aliases = i; \
	} \
 \
	if (h->h_addr_list) { \
		for (i = 0; h->h_addr_list[i]; i++) \
			req_length += h->h_length; \
		num_addrs = i; \
	} \
 \
	req_length += sizeof (gchar *) * (num_aliases + 1); \
	req_length += sizeof (gchar *) * (num_addrs + 1); \
	req_length += strlen (h->h_name) + 1; \
 \
	if (buflen < req_length) { \
		*herr = ERANGE; \
		G_UNLOCK (gethost_mutex); \
		return ERANGE; \
	} \
 \
	/* we store the alias/addr pointers in the buffer */ \
        /* their addresses here. */ \
	p = buf; \
	if (num_aliases) { \
		host->h_aliases = (gchar **) p; \
		p += sizeof (gchar *) * (num_aliases + 1); \
	} else \
		host->h_aliases = NULL; \
 \
	if (num_addrs) { \
		host->h_addr_list = (gchar **) p; \
		p += sizeof (gchar *) * (num_addrs + 1); \
	} else \
		host->h_addr_list = NULL; \
 \
	/* copy the host name into the buffer */ \
	host->h_name = p; \
	strcpy (p, h->h_name); \
	p += strlen (h->h_name) + 1; \
	host->h_addrtype = h->h_addrtype; \
	host->h_length = h->h_length; \
 \
	/* copy the aliases/addresses into the buffer */ \
        /* and assign pointers into the hostent */ \
	*p = 0; \
	if (num_aliases) { \
		for (i = 0; i < num_aliases; i++) { \
			strcpy (p, h->h_aliases[i]); \
			host->h_aliases[i] = p; \
			p += strlen (h->h_aliases[i]); \
		} \
		host->h_aliases[num_aliases] = NULL; \
	} \
 \
	if (num_addrs) { \
		for (i = 0; i < num_addrs; i++) { \
			memcpy (p, h->h_addr_list[i], h->h_length); \
			host->h_addr_list[i] = p; \
			p += h->h_length; \
		} \
		host->h_addr_list[num_addrs] = NULL; \
	} \
} G_STMT_END

#ifdef ENABLE_IPv6
/* some helpful utils for IPv6 lookups */
#define IPv6_BUFLEN_MIN  (sizeof (gchar *) * 3)

static gint
ai_to_herr (gint error)
{
	switch (error) {
	case EAI_NONAME:
	case EAI_FAIL:
		return HOST_NOT_FOUND;
		break;
	case EAI_SERVICE:
		return NO_DATA;
		break;
	case EAI_ADDRFAMILY:
		return NO_ADDRESS;
		break;
	case EAI_NODATA:
		return NO_DATA;
		break;
	case EAI_MEMORY:
		return ENOMEM;
		break;
	case EAI_AGAIN:
		return TRY_AGAIN;
		break;
	case EAI_SYSTEM:
		return errno;
		break;
	default:
		return NO_RECOVERY;
		break;
	}
}

#endif /* ENABLE_IPv6 */

static gint
camel_gethostbyname_r (const gchar *name,
                       struct hostent *host,
                       gchar *buf,
                       gsize buflen,
                       gint *herr)
{
#ifdef ENABLE_IPv6
	struct addrinfo hints, *res;
	gint retval, len;
	gchar *addr;

	memset (&hints, 0, sizeof (struct addrinfo));
#ifdef HAVE_AI_ADDRCONFIG
	hints.ai_flags = AI_CANONNAME | AI_ADDRCONFIG;
#else
	hints.ai_flags = AI_CANONNAME;
#endif
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;

	if ((retval = getaddrinfo (name, NULL, &hints, &res)) != 0) {
		*herr = ai_to_herr (retval);
		return -1;
	}

	len = ALIGN (strlen (res->ai_canonname) + 1);
	if (buflen < IPv6_BUFLEN_MIN + len + res->ai_addrlen + sizeof (gchar *))
		return ERANGE;

	/* h_name */
	g_strlcpy (buf, res->ai_canonname, buflen);
	host->h_name = buf;
	buf += len;

	/* h_aliases */
	((gchar **) buf)[0] = NULL;
	host->h_aliases = (gchar **) buf;
	buf += sizeof (gchar *);

	/* h_addrtype and h_length */
	host->h_length = res->ai_addrlen;
	if (res->ai_family == PF_INET6) {
		host->h_addrtype = AF_INET6;

		addr = (gchar *) &((struct sockaddr_in6 *) res->ai_addr)->sin6_addr;
	} else {
		host->h_addrtype = AF_INET;

		addr = (gchar *) &((struct sockaddr_in *) res->ai_addr)->sin_addr;
	}

	memcpy (buf, addr, host->h_length);
	addr = buf;
	buf += ALIGN (host->h_length);

	/* h_addr_list */
	((gchar **) buf)[0] = addr;
	((gchar **) buf)[1] = NULL;
	host->h_addr_list = (gchar **) buf;

	freeaddrinfo (res);

	return 0;
#else /* No support for IPv6 addresses */
#ifdef HAVE_GETHOSTBYNAME_R
#ifdef GETHOSTBYNAME_R_FIVE_ARGS
	if (gethostbyname_r (name, host, buf, buflen, herr))
		return 0;
	else
		return errno;
#else
	struct hostent *hp;
	gint retval;

	retval = gethostbyname_r (name, host, buf, buflen, &hp, herr);
	if (hp != NULL) {
		*herr = 0;
	} else if (retval == 0) {
		/* glibc 2.3.2 workaround - it seems that
		 * gethostbyname_r will sometimes return 0 on fail and
		 * not set the hostent values (hence the crash in bug
		 * #56337).  Hopefully we can depend on @hp being NULL
		 * in this error case like we do with
		 * gethostbyaddr_r().
		 */
		retval = -1;
	}

	return retval;
#endif
#else /* No support for gethostbyname_r */
	struct hostent *h;

	G_LOCK (gethost_mutex);

	h = gethostbyname (name);

	if (!h) {
		*herr = h_errno;
		G_UNLOCK (gethost_mutex);
		return -1;
	}

	GETHOST_PROCESS (h, host, buf, buflen, herr);

	G_UNLOCK (gethost_mutex);

	return 0;
#endif /* HAVE_GETHOSTBYNAME_R */
#endif /* ENABLE_IPv6 */
}

static gint
camel_gethostbyaddr_r (const gchar *addr,
                       gint addrlen,
                       gint type,
                       struct hostent *host,
                       gchar *buf,
                       gsize buflen,
                       gint *herr)
{
#ifdef ENABLE_IPv6
	gint retval, len;

	if ((retval = getnameinfo (addr, addrlen, buf, buflen, NULL, 0, NI_NAMEREQD)) != 0) {
		*herr = ai_to_herr (retval);
		return -1;
	}

	len = ALIGN (strlen (buf) + 1);
	if (buflen < IPv6_BUFLEN_MIN + len + addrlen + sizeof (gchar *))
		return ERANGE;

	/* h_name */
	host->h_name = buf;
	buf += len;

	/* h_aliases */
	((gchar **) buf)[0] = NULL;
	host->h_aliases = (gchar **) buf;
	buf += sizeof (gchar *);

	/* h_addrtype and h_length */
	host->h_length = addrlen;
	host->h_addrtype = type;

	memcpy (buf, addr, host->h_length);
	addr = buf;
	buf += ALIGN (host->h_length);

	/* h_addr_list */
	((gchar **) buf)[0] = addr;
	((gchar **) buf)[1] = NULL;
	host->h_addr_list = (gchar **) buf;

	return 0;
#else /* No support for IPv6 addresses */
#ifdef HAVE_GETHOSTBYADDR_R
#ifdef GETHOSTBYADDR_R_SEVEN_ARGS
	if (gethostbyaddr_r (addr, addrlen, type, host, buf, buflen, herr))
		return 0;
	else
		return errno;
#else
	struct hostent *hp;
	gint retval;

	retval = gethostbyaddr_r (addr, addrlen, type, host, buf, buflen, &hp, herr);
	if (hp != NULL) {
		*herr = 0;
		retval = 0;
	} else if (retval == 0) {
		/* glibc 2.3.2 workaround - it seems that
		 * gethostbyaddr_r will sometimes return 0 on fail and
		 * fill @host with garbage strings from /etc/hosts
		 * (failure to parse the file? who knows). Luckily, it
		 * seems that we can rely on @hp being NULL on
		 * fail.
		 */
		retval = -1;
	}

	return retval;
#endif
#else /* No support for gethostbyaddr_r */
	struct hostent *h;

	G_LOCK (gethost_mutex);

	h = gethostbyaddr (addr, addrlen, type);

	if (!h) {
		*herr = h_errno;
		G_UNLOCK (gethost_mutex);
		return -1;
	}

	GETHOST_PROCESS (h, host, buf, buflen, herr);

	G_UNLOCK (gethost_mutex);

	return 0;
#endif /* HAVE_GETHOSTBYADDR_R */
#endif /* ENABLE_IPv6 */
}
#endif /* NEED_ADDRINFO */

/* ********************************************************************** */
struct _addrinfo_msg {
	CamelMsg msg;
	guint cancelled : 1;

	/* for host lookup */
	const gchar *name;
	const gchar *service;
	gint result;
	const struct addrinfo *hints;
	struct addrinfo **res;

	/* for host lookup emulation */
#ifdef NEED_ADDRINFO
	struct hostent hostbuf;
	gint hostbuflen;
	gchar *hostbufmem;
#endif

	/* for name lookup */
	const struct sockaddr *addr;
	socklen_t addrlen;
	gchar *host;
	gint hostlen;
	gchar *serv;
	gint servlen;
	gint flags;
};

static void
cs_freeinfo (struct _addrinfo_msg *msg)
{
	g_free (msg->host);
	g_free (msg->serv);
#ifdef NEED_ADDRINFO
	g_free (msg->hostbufmem);
#endif
	g_free (msg);
}

/* returns -1 if we didn't wait for reply from thread */
static gint
cs_waitinfo (gpointer (worker)(gpointer),
             struct _addrinfo_msg *msg,
             const gchar *errmsg,
             GCancellable *cancellable,
             GError **error)
{
	CamelMsgPort *reply_port;
	GThread *thread;
	gint cancel_fd, cancel = 0, fd;

	cancel_fd = g_cancellable_get_fd (cancellable);
	if (cancel_fd == -1) {
		worker (msg);
		return 0;
	}

	reply_port = msg->msg.reply_port = camel_msgport_new ();
	fd = camel_msgport_fd (msg->msg.reply_port);
	if ((thread = g_thread_new (NULL, worker, msg)) != NULL) {
		gint status;
#ifndef G_OS_WIN32
		GPollFD polls[2];

		polls[0].fd = fd;
		polls[0].events = G_IO_IN;
		polls[1].fd = cancel_fd;
		polls[1].events = G_IO_IN;

		d (printf ("waiting for name return/cancellation in main process\n"));
		do {
			polls[0].revents = 0;
			polls[1].revents = 0;
			status = g_poll (polls, 2, -1);
		} while (status == -1 && errno == EINTR);
#else
		fd_set read_set;

		FD_ZERO (&read_set);
		FD_SET (fd, &read_set);
		FD_SET (cancel_fd, &read_set);

		status = select (MAX (fd, cancel_fd) + 1, &read_set, NULL, NULL, NULL);
#endif

		if (status == -1 ||
#ifndef G_OS_WIN32
		    (polls[1].revents & G_IO_IN)
#else
		    FD_ISSET (cancel_fd, &read_set)
#endif
						   ) {
			if (status == -1)
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					"%s: %s", errmsg,
#ifndef G_OS_WIN32
					g_strerror (errno)
#else
					g_win32_error_message (WSAGetLastError ())
#endif
					);
			else
				g_set_error (
					error, G_IO_ERROR,
					G_IO_ERROR_CANCELLED,
					_("Cancelled"));

			/* We cancel so if the thread impl is decent it causes immediate exit.
			 * We check the reply port incase we had a reply in the mean time, which we free later */
			d (printf ("Canceling lookup thread and leaving it\n"));
			msg->cancelled = 1;
			g_thread_join (thread);
			cancel = 1;
		} else {
			struct _addrinfo_msg *reply;

			d (printf ("waiting for child to exit\n"));
			g_thread_join (thread);
			d (printf ("child done\n"));

			reply = (struct _addrinfo_msg *) camel_msgport_try_pop (reply_port);
			if (reply != msg)
				g_warning ("%s: Received msg reply %p doesn't match msg %p", G_STRFUNC, reply, msg);
		}
	}
	camel_msgport_destroy (reply_port);

	g_cancellable_release_fd (cancellable);

	return cancel;
}

#ifdef NEED_ADDRINFO
static gpointer
cs_getaddrinfo (gpointer data)
{
	struct _addrinfo_msg *msg = data;
	gint herr;
	struct hostent h;
	struct addrinfo *res, *last = NULL;
	struct sockaddr_in *sin;
	in_port_t port = 0;
	gint i;

	/* This is a pretty simplistic emulation of getaddrinfo */

	while ((msg->result = camel_gethostbyname_r (msg->name, &h, msg->hostbufmem, msg->hostbuflen, &herr)) == ERANGE) {
		if (msg->cancelled)
			break;
		msg->hostbuflen *= 2;
		msg->hostbufmem = g_realloc (msg->hostbufmem, msg->hostbuflen);
	}

	/* If we got cancelled, dont reply, just free it */
	if (msg->cancelled)
		goto cancel;

	/* FIXME: map error numbers across */
	if (msg->result != 0)
		goto reply;

	/* check hints matched */
	if (msg->hints && msg->hints->ai_family && msg->hints->ai_family != h.h_addrtype) {
		msg->result = EAI_FAMILY;
		goto reply;
	}

	/* we only support ipv4 for this interface, even if it could supply ipv6 */
	if (h.h_addrtype != AF_INET) {
		msg->result = EAI_FAMILY;
		goto reply;
	}

	/* check service mapping */
	if (msg->service) {
		const gchar *p = msg->service;

		while (*p) {
			if (*p < '0' || *p > '9')
				break;
			p++;
		}

		if (*p) {
			const gchar *socktype = NULL;
			struct servent *serv;

			if (msg->hints && msg->hints->ai_socktype) {
				if (msg->hints->ai_socktype == SOCK_STREAM)
					socktype = "tcp";
				else if (msg->hints->ai_socktype == SOCK_DGRAM)
					socktype = "udp";
			}

			serv = getservbyname (msg->service, socktype);
			if (serv == NULL) {
				msg->result = EAI_NONAME;
				goto reply;
			}
			port = serv->s_port;
		} else {
			port = htons (strtoul (msg->service, NULL, 10));
		}
	}

	for (i = 0; h.h_addr_list[i] && !msg->cancelled; i++) {
		res = g_malloc0 (sizeof (*res));
		if (msg->hints) {
			res->ai_flags = msg->hints->ai_flags;
			if (msg->hints->ai_flags & AI_CANONNAME)
				res->ai_canonname = g_strdup (h.h_name);
			res->ai_socktype = msg->hints->ai_socktype;
			res->ai_protocol = msg->hints->ai_protocol;
		} else {
			res->ai_flags = 0;
			res->ai_socktype = SOCK_STREAM;	/* fudge */
			res->ai_protocol = 0;	/* fudge */
		}
		res->ai_family = AF_INET;
		res->ai_addrlen = sizeof (*sin);
		res->ai_addr = g_malloc (sizeof (*sin));
		sin = (struct sockaddr_in *) res->ai_addr;
		sin->sin_family = AF_INET;
		sin->sin_port = port;
		memcpy (&sin->sin_addr, h.h_addr_list[i], sizeof (sin->sin_addr));

		if (last == NULL) {
			*msg->res = last = res;
		} else {
			last->ai_next = res;
			last = res;
		}
	}
reply:
	camel_msgport_reply ((CamelMsg *) msg);
cancel:
	return NULL;
}
#else
static gpointer
cs_getaddrinfo (gpointer data)
{
	struct _addrinfo_msg *info = data;

	info->result = getaddrinfo (info->name, info->service, info->hints, info->res);

	/* On Solaris, the service name 'http' or 'https' is not defined.
	 * Use the port as the service name directly. */
	if (info->result && info->service) {
		if (strcmp (info->service, "http") == 0)
			info->result = getaddrinfo (info->name, "80", info->hints, info->res);
		else if (strcmp (info->service, "https") == 0)
			info->result = getaddrinfo (info->name, "443", info->hints, info->res);
	}

	if (!info->cancelled)
		camel_msgport_reply ((CamelMsg *) info);

	return NULL;
}
#endif /* NEED_ADDRINFO */

/**
 * camel_getaddrinfo:
 * @name: an address name to resolve
 * @service: a service name to use
 * @hints: (nullable): an #addrinfo hints, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Resolves a host @name and returns an information about its address.
 *
 * Returns: (transfer full) (nullable): a newly allocated #addrinfo. Free it
 *    with camel_freeaddrinfo() when done with it.
 *
 * Since: 2.22
 **/
struct addrinfo *
camel_getaddrinfo (const gchar *name,
                   const gchar *service,
                   const struct addrinfo *hints,
                   GCancellable *cancellable,
                   GError **error)
{
	struct _addrinfo_msg *msg;
	struct addrinfo *res = NULL;
#ifndef ENABLE_IPv6
	struct addrinfo myhints;
#endif
	gchar *ascii_name;

	g_return_val_if_fail (name != NULL, NULL);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return NULL;

	camel_operation_push_message (
		cancellable, _("Resolving: %s"), name);

	/* force ipv4 addresses only */
#ifndef ENABLE_IPv6
	if (hints == NULL)
		memset (&myhints, 0, sizeof (myhints));
	else
		memcpy (&myhints, hints, sizeof (myhints));

	myhints.ai_family = AF_INET;
	hints = &myhints;
#endif

	ascii_name = camel_host_idna_to_ascii (name);

	msg = g_malloc0 (sizeof (*msg));
	msg->name = ascii_name;
	msg->service = service;
	msg->hints = hints;
	msg->res = &res;
#ifdef NEED_ADDRINFO
	msg->hostbuflen = 1024;
	msg->hostbufmem = g_malloc (msg->hostbuflen);
#endif
	if (cs_waitinfo (
		cs_getaddrinfo, msg, _("Host lookup failed"),
		cancellable, error) == 0) {

		if (msg->result == EAI_NONAME || msg->result == EAI_FAIL) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_URL_INVALID,
				_("Host lookup “%s” failed. Check your host name for spelling errors."), name);
		} else if (msg->result != 0) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_URL_INVALID,
				_("Host lookup “%s” failed: %s"),
				name, gai_strerror (msg->result));
		}
	} else
		res = NULL;

	cs_freeinfo (msg);
	g_free (ascii_name);

	camel_operation_pop_message (cancellable);

	return res;
}

/**
 * camel_freeaddrinfo:
 * @host: (nullable): a host address information structure to free, or %NULL
 *
 * Frees a structure returned with camel_getaddrinfo(). It does
 * nothing when the @host is %NULL.
 *
 * Since: 2.22
 **/
void
camel_freeaddrinfo (struct addrinfo *host)
{
	if (!host)
		return;

#ifdef NEED_ADDRINFO
	while (host) {
		struct addrinfo *next = host->ai_next;

		g_free (host->ai_canonname);
		g_free (host->ai_addr);
		g_free (host);
		host = next;
	}
#else
	freeaddrinfo (host);
#endif
}

/**
 * camel_host_idna_to_ascii:
 * @host: Host name, with or without non-ascii letters in utf8
 *
 * Converts IDN (Internationalized Domain Name) into ASCII representation.
 * If there's a failure or the @host has only ASCII letters, then a copy
 * of @host is returned.
 *
 * Returns: Newly allocated string with only ASCII letters describing the @host.
 *   Free it with g_free() when done with it.
 *
 * Since: 3.16
 **/
gchar *
camel_host_idna_to_ascii (const gchar *host)
{
	UErrorCode uerror = U_ZERO_ERROR;
	int32_t uhost_len = 0;
	const gchar *ptr;
	gchar *ascii = NULL;

	g_return_val_if_fail (host != NULL, NULL);

	ptr = host;
	while (*ptr > 0)
		ptr++;

	if (!*ptr) {
		/* Did read whole buffer, it should be ASCII string already */
		return g_strdup (host);
	}

	u_strFromUTF8 (NULL, 0, &uhost_len, host, -1, &uerror);
	if (uhost_len > 0) {
		UChar *uhost = g_new0 (UChar, uhost_len + 2);

		uerror = U_ZERO_ERROR;
		u_strFromUTF8 (uhost, uhost_len + 1, &uhost_len, host, -1, &uerror);
		if (uerror == U_ZERO_ERROR && uhost_len > 0) {
			int32_t buffer_len = uhost_len * 6 + 6, nconverted;
			UChar *buffer = g_new0 (UChar, buffer_len);

			nconverted = uidna_IDNToASCII (uhost, uhost_len, buffer, buffer_len, UIDNA_ALLOW_UNASSIGNED, 0, &uerror);
			if (uerror == U_ZERO_ERROR && nconverted > 0) {
				int32_t ascii_len = 0;

				u_strToUTF8 (NULL, 0, &ascii_len, buffer, nconverted, &uerror);
				if (ascii_len > 0) {
					uerror = U_ZERO_ERROR;
					ascii = g_new0 (gchar, ascii_len + 2);

					u_strToUTF8 (ascii, ascii_len + 1, &ascii_len, buffer, nconverted, &uerror);
					if (uerror == U_ZERO_ERROR && ascii_len > 0) {
						ascii[ascii_len] = '\0';
					} else {
						g_free (ascii);
						ascii = NULL;
					}
				}
			}

			g_free (buffer);
		}

		g_free (uhost);
	}

	if (!ascii)
		ascii = g_strdup (host);

	return ascii;
}
