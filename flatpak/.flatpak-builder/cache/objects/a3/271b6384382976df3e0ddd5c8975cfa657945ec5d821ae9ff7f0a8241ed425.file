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

#include "evolution-data-server-config.h"

#include <errno.h>
#include <unistd.h>

#include <nspr.h>

#ifdef G_OS_WIN32
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#endif

#include "camel-msgport.h"

#ifdef G_OS_WIN32
#define MP_CLOSE(socket)		closesocket (socket)
#define MP_READ(socket, buf, nbytes)	recv((socket), (buf), (nbytes), 0)
#define MP_WRITE(socket, buf, nbytes)	send((socket), (buf), (nbytes), 0)
#define MP_IS_STATUS_INTR()		0 /* No WSAEINTR errors in WinSock2 */
#else
#define MP_CLOSE(socket)		close (socket)
#define MP_READ(socket, buf, nbytes)	read((socket), (buf), (nbytes))
#define MP_WRITE(socket, buf, nbytes)	write((socket), (buf), (nbytes))
#define MP_IS_STATUS_INTR()		(errno == EINTR)
#endif

/* message flags */
enum {
	MSG_FLAG_SYNC_WITH_PIPE = 1 << 0,
	MSG_FLAG_SYNC_WITH_PR_PIPE = 1 << 1
};

struct _CamelMsgPort {
	GAsyncQueue *queue;
	gint pipe[2];  /* on Win32, actually a pair of SOCKETs */
	PRFileDesc *prpipe[2];
};

static gint
msgport_pipe (gint *fds)
{
#ifndef G_OS_WIN32
	if (pipe (fds) != -1)
		return 0;

	fds[0] = -1;
	fds[1] = -1;

	return -1;
#else
	SOCKET temp, socket1 = -1, socket2 = -1;
	struct sockaddr_in saddr;
	gint len;
	u_long arg;
	fd_set read_set, write_set;
	struct timeval tv;

	temp = socket (AF_INET, SOCK_STREAM, 0);

	if (temp == INVALID_SOCKET) {
		goto out0;
	}

	arg = 1;
	if (ioctlsocket (temp, FIONBIO, &arg) == SOCKET_ERROR) {
		goto out0;
	}

	memset (&saddr, 0, sizeof (saddr));
	saddr.sin_family = AF_INET;
	saddr.sin_port = 0;
	saddr.sin_addr.s_addr = htonl (INADDR_LOOPBACK);

	if (bind (temp, (struct sockaddr *) &saddr, sizeof (saddr))) {
		goto out0;
	}

	if (listen (temp, 1) == SOCKET_ERROR) {
		goto out0;
	}

	len = sizeof (saddr);
	if (getsockname (temp, (struct sockaddr *) &saddr, &len)) {
		goto out0;
	}

	socket1 = socket (AF_INET, SOCK_STREAM, 0);

	if (socket1 == INVALID_SOCKET) {
		goto out0;
	}

	arg = 1;
	if (ioctlsocket (socket1, FIONBIO, &arg) == SOCKET_ERROR) {
		goto out1;
	}

	if (connect (socket1, (struct sockaddr  *) &saddr, len) != SOCKET_ERROR ||
	    WSAGetLastError () != WSAEWOULDBLOCK) {
		goto out1;
	}

	FD_ZERO (&read_set);
	FD_SET (temp, &read_set);

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	if (select (0, &read_set, NULL, NULL, NULL) == SOCKET_ERROR) {
		goto out1;
	}

	if (!FD_ISSET (temp, &read_set)) {
		goto out1;
	}

	socket2 = accept (temp, (struct sockaddr *) &saddr, &len);
	if (socket2 == INVALID_SOCKET) {
		goto out1;
	}

	FD_ZERO (&write_set);
	FD_SET (socket1, &write_set);

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	if (select (0, NULL, &write_set, NULL, NULL) == SOCKET_ERROR) {
		goto out2;
	}

	if (!FD_ISSET (socket1, &write_set)) {
		goto out2;
	}

	arg = 0;
	if (ioctlsocket (socket1, FIONBIO, &arg) == SOCKET_ERROR) {
		goto out2;
	}

	arg = 0;
	if (ioctlsocket (socket2, FIONBIO, &arg) == SOCKET_ERROR) {
		goto out2;
	}

	fds[0] = socket1;
	fds[1] = socket2;

	closesocket (temp);

	return 0;

out2:
	closesocket (socket2);
out1:
	closesocket (socket1);
out0:
	closesocket (temp);
	errno = EMFILE;		/* FIXME: use the real syscall errno? */

	fds[0] = -1;
	fds[1] = -1;

	return -1;

#endif
}

static gint
msgport_prpipe (PRFileDesc **fds)
{
#ifdef G_OS_WIN32
	if (PR_NewTCPSocketPair (fds) != PR_FAILURE)
		return 0;
#else
	if (PR_CreatePipe (&fds[0], &fds[1]) != PR_FAILURE)
		return 0;
#endif

	fds[0] = NULL;
	fds[1] = NULL;

	return -1;
}

static void
msgport_sync_with_pipe (gint fd)
{
	gchar buffer[1];

	while (fd >= 0) {
		if (MP_READ (fd, buffer, 1) > 0)
			break;
		else if (!MP_IS_STATUS_INTR ()) {
			g_warning (
				"%s: Failed to read from pipe: %s",
				G_STRFUNC, g_strerror (errno));
			break;
		}
	}
}

static void
msgport_sync_with_prpipe (PRFileDesc *prfd)
{
	gchar buffer[1];

	while (prfd != NULL) {
		if (PR_Read (prfd, buffer, 1) > 0)
			break;
		else if (PR_GetError () != PR_PENDING_INTERRUPT_ERROR) {
			gchar *text = g_alloca (PR_GetErrorTextLength ());
			PR_GetErrorText (text);
			g_warning (
				"%s: Failed to read from NSPR pipe: %s",
				G_STRFUNC, text);
			break;
		}
	}
}

/**
 * camel_msgport_new: (skip)
 *
 * Returns: (transfer full): a new #CamelMsgPort
 *
 * Since: 2.24
 **/
CamelMsgPort *
camel_msgport_new (void)
{
	CamelMsgPort *msgport;

	msgport = g_slice_new (CamelMsgPort);
	msgport->queue = g_async_queue_new ();
	msgport->pipe[0] = -1;
	msgport->pipe[1] = -1;
	msgport->prpipe[0] = NULL;
	msgport->prpipe[1] = NULL;

	return msgport;
}

/**
 * camel_msgport_destroy: (skip)
 * @msgport: a #CamelMsgPort
 *
 * Since: 2.24
 **/
void
camel_msgport_destroy (CamelMsgPort *msgport)
{
	g_return_if_fail (msgport != NULL);

	if (msgport->pipe[0] >= 0) {
		MP_CLOSE (msgport->pipe[0]);
		MP_CLOSE (msgport->pipe[1]);
	}
	if (msgport->prpipe[0] != NULL) {
		PR_Close (msgport->prpipe[0]);
		PR_Close (msgport->prpipe[1]);
	}

	g_async_queue_unref (msgport->queue);
	g_slice_free (CamelMsgPort, msgport);
}

/**
 * camel_msgport_fd: (skip)
 * @msgport: a #CamelMsgPort
 *
 * Since: 2.24
 **/
gint
camel_msgport_fd (CamelMsgPort *msgport)
{
	gint fd;

	g_return_val_if_fail (msgport != NULL, -1);

	g_async_queue_lock (msgport->queue);
	fd = msgport->pipe[0];
	if (fd < 0 && msgport_pipe (msgport->pipe) == 0)
		fd = msgport->pipe[0];
	g_async_queue_unlock (msgport->queue);

	return fd;
}

/**
 * camel_msgport_prfd: (skip)
 * @msgport: a #CamelMsgPort
 *
 * Returns: (transfer none):
 *
 * Since: 2.24
 **/
PRFileDesc *
camel_msgport_prfd (CamelMsgPort *msgport)
{
	PRFileDesc *prfd;

	g_return_val_if_fail (msgport != NULL, NULL);

	g_async_queue_lock (msgport->queue);
	prfd = msgport->prpipe[0];
	if (prfd == NULL && msgport_prpipe (msgport->prpipe) == 0)
		prfd = msgport->prpipe[0];
	g_async_queue_unlock (msgport->queue);

	return prfd;
}

/**
 * camel_msgport_push: (skip)
 * @msgport: a #CamelMsgPort
 * @msg: a #CamelMsg
 *
 * Since: 2.24
 **/
void
camel_msgport_push (CamelMsgPort *msgport,
                    CamelMsg *msg)
{
	gint fd;
	PRFileDesc *prfd;

	g_return_if_fail (msgport != NULL);
	g_return_if_fail (msg != NULL);

	g_async_queue_lock (msgport->queue);

	msg->flags = 0;

	fd = msgport->pipe[1];
	while (fd >= 0) {
		if (MP_WRITE (fd, "E", 1) > 0) {
			msg->flags |= MSG_FLAG_SYNC_WITH_PIPE;
			break;
		} else if (!MP_IS_STATUS_INTR ()) {
			g_warning (
				"%s: Failed to write to pipe: %s",
				G_STRFUNC, g_strerror (errno));
			break;
		}
	}

	prfd = msgport->prpipe[1];
	while (prfd != NULL) {
		if (PR_Write (prfd, "E", 1) > 0) {
			msg->flags |= MSG_FLAG_SYNC_WITH_PR_PIPE;
			break;
		} else if (PR_GetError () != PR_PENDING_INTERRUPT_ERROR) {
			gchar *text = g_alloca (PR_GetErrorTextLength ());
			PR_GetErrorText (text);
			g_warning (
				"%s: Failed to write to NSPR pipe: %s",
				G_STRFUNC, text);
			break;
		}
	}

	g_async_queue_push_unlocked (msgport->queue, msg);
	g_async_queue_unlock (msgport->queue);
}

/**
 * camel_msgport_pop: (skip)
 * @msgport: a #CamelMsgPort
 *
 * Since: 2.24
 **/
CamelMsg *
camel_msgport_pop (CamelMsgPort *msgport)
{
	CamelMsg *msg;

	g_return_val_if_fail (msgport != NULL, NULL);

	g_async_queue_lock (msgport->queue);

	msg = g_async_queue_pop_unlocked (msgport->queue);

	g_return_val_if_fail (msg != NULL, NULL);

	if (msg->flags & MSG_FLAG_SYNC_WITH_PIPE)
		msgport_sync_with_pipe (msgport->pipe[0]);
	if (msg->flags & MSG_FLAG_SYNC_WITH_PR_PIPE)
		msgport_sync_with_prpipe (msgport->prpipe[0]);

	g_async_queue_unlock (msgport->queue);

	return msg;
}

/**
 * camel_msgport_try_pop: (skip)
 * @msgport: a #CamelMsgPort
 *
 * Since: 2.24
 **/
CamelMsg *
camel_msgport_try_pop (CamelMsgPort *msgport)
{
	CamelMsg *msg;

	g_return_val_if_fail (msgport != NULL, NULL);

	g_async_queue_lock (msgport->queue);

	msg = g_async_queue_try_pop_unlocked (msgport->queue);

	if (msg != NULL && msg->flags & MSG_FLAG_SYNC_WITH_PIPE)
		msgport_sync_with_pipe (msgport->pipe[0]);
	if (msg != NULL && msg->flags & MSG_FLAG_SYNC_WITH_PR_PIPE)
		msgport_sync_with_prpipe (msgport->prpipe[0]);

	g_async_queue_unlock (msgport->queue);

	return msg;
}

/**
 * camel_msgport_timeout_pop: (skip)
 * @msgport: a #CamelMsgPort
 * @timeout: number of microseconds to wait
 *
 * Since: 3.8
 **/
CamelMsg *
camel_msgport_timeout_pop (CamelMsgPort *msgport,
                           guint64 timeout)
{
	CamelMsg *msg;

	g_return_val_if_fail (msgport != NULL, NULL);

	g_async_queue_lock (msgport->queue);

	msg = g_async_queue_timeout_pop_unlocked (msgport->queue, timeout);

	if (msg != NULL && msg->flags & MSG_FLAG_SYNC_WITH_PIPE)
		msgport_sync_with_pipe (msgport->pipe[0]);
	if (msg != NULL && msg->flags & MSG_FLAG_SYNC_WITH_PR_PIPE)
		msgport_sync_with_prpipe (msgport->prpipe[0]);

	g_async_queue_unlock (msgport->queue);

	return msg;
}

/**
 * camel_msgport_reply: (skip)
 * @msg: a #CamelMsg
 *
 * Since: 2.24
 **/
void
camel_msgport_reply (CamelMsg *msg)
{
	g_return_if_fail (msg != NULL);

	if (msg->reply_port)
		camel_msgport_push (msg->reply_port, msg);

	/* else lost? */
}
