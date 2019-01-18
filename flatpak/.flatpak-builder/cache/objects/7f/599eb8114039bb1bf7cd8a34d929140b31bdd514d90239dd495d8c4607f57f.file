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

#ifndef CAMEL_MSGPORT_H
#define CAMEL_MSGPORT_H

#include <glib.h>

G_BEGIN_DECLS

/**
 * CamelMsgPort:
 *
 * Since: 2.24
 **/

typedef struct _CamelMsg CamelMsg;
typedef struct _CamelMsgPort CamelMsgPort;

/**
 * CamelMsg:
 * @reply_port: a #CamelMsgPort this #CamelMsg belongs to
 *
 * Since: 2.24
 **/
struct _CamelMsg {
	CamelMsgPort *reply_port;

	/*< private >*/
	gint flags;
};

CamelMsgPort *	camel_msgport_new		(void);
void		camel_msgport_destroy		(CamelMsgPort *msgport);
gint		camel_msgport_fd		(CamelMsgPort *msgport);
void		camel_msgport_push		(CamelMsgPort *msgport,
						 CamelMsg *msg);
CamelMsg *	camel_msgport_pop		(CamelMsgPort *msgport);
CamelMsg *	camel_msgport_try_pop		(CamelMsgPort *msgport);
CamelMsg *	camel_msgport_timeout_pop	(CamelMsgPort *msgport,
						 guint64 timeout);
void		camel_msgport_reply		(CamelMsg *msg);

struct PRFileDesc * camel_msgport_prfd		(CamelMsgPort *msgport);

G_END_DECLS

#endif  /* CAMEL_MSGPORT_H */
