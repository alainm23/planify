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
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-result-set
 * @short_description: Cursor-like interface for results sets
 * @include: dee.h
 *
 * Interface for results returned by dee_index_lookup().
 *
 * This interface utilizes a cursor-like metaphor. You advance the cursor
 * by calling dee_result_set_next() or adjust it manually by calling
 * dee_result_set_seek().
 *
 * Calling dee_result_set_next() will also return the row at the
 * current cursor position. You may retrieve the current row without advancing
 * the cursor by calling dee_result_set_peek().
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "dee-result-set.h"

typedef DeeResultSetIface DeeResultSetInterface;
G_DEFINE_INTERFACE (DeeResultSet, dee_result_set, G_TYPE_OBJECT)

enum
{
  /* Public signals */
  
  DEE_RESULT_SET_LAST_SIGNAL
};

static void
dee_result_set_default_init (DeeResultSetInterface *klass)
{
  
}

/**
 * dee_result_set_get_n_rows:
 * @self: The #DeeResultSet to get the size of
 *
 * Get the number of #DeeModelIter<!-- -->s held in a #DeeResultSet.
 *
 * Returns: The number of rows held in the result set
 */ 
guint
dee_result_set_get_n_rows (DeeResultSet *self)
{
  DeeResultSetIface *iface;
  
  g_return_val_if_fail (DEE_IS_RESULT_SET (self), 0);
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->get_n_rows) (self);
}

/**
 * dee_result_set_next:
 * @self: The #DeeResultSet to get a row from
 *
 * Get the current row from the result set and advance the cursor.
 * To ensure that calls to this method will succeed you can call
 * dee_result_set_has_next().
 *
 * To retrieve the current row without advancing the cursor call
 * dee_result_set_peek() in stead of this method.
 *
 * Returns: (transfer none):The #DeeModelIter at the current cursor position
 */
DeeModelIter*
dee_result_set_next (DeeResultSet *self)
{
  DeeResultSetIface *iface;
  
  g_return_val_if_fail (DEE_IS_RESULT_SET (self), NULL);
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->next) (self);
}

/**
 * dee_result_set_has_next:
 * @self: The #DeeResultSet to check
 *
 * Check if a call to dee_result_set_next() will succeed.
 *
 * Returns: %TRUE if and only if more rows can be retrieved by calling
 *          dee_result_set_next()
 */
gboolean
dee_result_set_has_next (DeeResultSet *self)
{
  DeeResultSetIface *iface;
  
  g_return_val_if_fail (DEE_IS_RESULT_SET (self), FALSE);
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->has_next) (self);
}

/**
 * dee_result_set_peek:
 * @self: The #DeeResultSet to get a row from
 *
 * Get the row at the current cursor position.
 *
 * To retrieve the current row and advance the cursor position call
 * dee_result_set_next() in stead of this method.
 *
 * Returns: (transfer none):The #DeeModelIter at the current cursor position
 */
DeeModelIter*
dee_result_set_peek (DeeResultSet *self)
{
  DeeResultSetIface *iface;
  
  g_return_val_if_fail (DEE_IS_RESULT_SET (self), NULL);
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->peek) (self);
}

/**
 * dee_result_set_seek:
 * @self: The #DeeResultSet to seek in
 * @pos: The position to seek to
 *
 * Set the cursor position. Following calls to dee_result_set_peek()
 * or dee_result_set_next() will read the row at position @pos.
 */
void
dee_result_set_seek (DeeResultSet *self,
                     guint         pos)
{
  DeeResultSetIface *iface;
  
  g_return_if_fail (DEE_IS_RESULT_SET (self));
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  (* iface->seek) (self, pos);
}

/**
 * dee_result_set_tell:
 * @self: The #DeeResultSet to check the cursor position for
 *
 * Get the current position of the cursor.
 *
 * Returns: The current position of the cursor
 */
guint
dee_result_set_tell (DeeResultSet *self)
{
  DeeResultSetIface *iface;
  
  g_return_val_if_fail (DEE_IS_RESULT_SET (self), 0);
  
  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->tell) (self);
}

/**
 * dee_result_set_get_model:
 * @self: The #DeeResultSet to get the mode for
 *
 * Get the model associated with a result set
 *
 * Returns: (transfer none): The model that the rows point into
 */
DeeModel*
dee_result_set_get_model (DeeResultSet *self)
{
  DeeResultSetIface *iface;

  g_return_val_if_fail (DEE_IS_RESULT_SET (self), NULL);

  iface = DEE_RESULT_SET_GET_IFACE (self);

  return (* iface->get_model) (self);
}
