/*
 * camel-async-closure.h
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

#ifndef CAMEL_ASYNC_CLOSURE_H
#define CAMEL_ASYNC_CLOSURE_H

#include <gio/gio.h>

typedef struct _CamelAsyncClosure CamelAsyncClosure;

CamelAsyncClosure *
		camel_async_closure_new		(void);
GAsyncResult *	camel_async_closure_wait	(CamelAsyncClosure *closure);
void		camel_async_closure_free	(CamelAsyncClosure *closure);
void		camel_async_closure_callback	(GObject *source_object,
						 GAsyncResult *result,
						 gpointer closure);

#endif /* CAMEL_ASYNC_CLOSURE_H */

