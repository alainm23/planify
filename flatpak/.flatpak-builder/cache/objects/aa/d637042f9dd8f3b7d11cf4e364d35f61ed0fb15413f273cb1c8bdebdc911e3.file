/*
 * Copyright (C) 2009 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_TRANSACTION_H
#define _HAVE_DEE_TRANSACTION_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>
#include <dee-serializable-model.h>

G_BEGIN_DECLS

#define DEE_TYPE_TRANSACTION (dee_transaction_get_type ())

#define DEE_TRANSACTION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_TRANSACTION, DeeTransaction))

#define DEE_TRANSACTION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_TRANSACTION, DeeTransactionClass))

#define DEE_IS_TRANSACTION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_TRANSACTION))

#define DEE_IS_TRANSACTION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_TRANSACTION))

#define DEE_TRANSACTION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_SEQUENCE_MODEL, DeeTransactionClass))

typedef struct _DeeTransaction DeeTransaction;
typedef struct _DeeTransactionClass DeeTransactionClass;
typedef struct _DeeTransactionPrivate DeeTransactionPrivate;

/**
 * DeeTransaction:
 *
 * All fields in the DeeTransaction structure are private and should never be
 * accessed directly
 */
struct _DeeTransaction
{
  /*< private >*/
  DeeSerializableModel     parent;

  DeeTransactionPrivate *priv;
};

struct _DeeTransactionClass
{
  /*< private >*/
  DeeSerializableModelClass parent_class;
                                             
  /*< private >*/
  void     (*_dee_transaction_1) (void);
  void     (*_dee_transaction_2) (void);
  void     (*_dee_transaction_3) (void);
  void     (*_dee_transaction_4) (void);
};

/**
 * DEE_TRANSACTION_ERROR:
 *
 * Error domain for the #DeeTransaction. Error codes will be from the
 * #DeeTransactionError enumeration
 */
#define DEE_TRANSACTION_ERROR dee_transaction_error_quark()

/**
 * DeeTransactionError:
 *
 * Error codes for the #DeeTransaction class. These codes will be set when the
 * error domain is #DEE_TRANSACTION_ERROR.
 *
 * @DEE_TRANSACTION_ERROR_CONCURRENT_MODIFICATION: The target model has been
 *   modified while the transaction was open.
 *
 * @DEE_TRANSACTION_ERROR_COMMITTED: Raised when someone tries to commit a
 *   transaction that has already been committed
 */
typedef enum {
  DEE_TRANSACTION_ERROR_CONCURRENT_MODIFICATION = 1,
  DEE_TRANSACTION_ERROR_COMMITTED = 2
} DeeTransactionError;

/**
 * dee_transaction_get_type:
 *
 * The GType of #DeeTransaction
 *
 * Return value: the #GType of #DeeTransaction
 **/
GType           dee_transaction_get_type               (void);

DeeModel*       dee_transaction_new                    (DeeModel        *target);

DeeModel*       dee_transaction_get_target             (DeeTransaction  *self);

gboolean        dee_transaction_is_committed           (DeeTransaction  *self);

gboolean        dee_transaction_commit                 (DeeTransaction  *self,
                                                        GError         **error);

GQuark          dee_transaction_error_quark            (void);

G_END_DECLS

#endif /* _HAVE_DEE_TRANSACTION_H */
