/*
 * Copyright (C) 2010 Canonical, Ltd.
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
 * SECTION:dee-model-reader
 * @title: Model Readers
 * @short_description: Extracting strings from #DeeModel<!-- -->s
 * @include: dee.h
 *
 * The purpose of a #DeeModelReader is to extract string from a #DeeModel.
 * These strings are usually passed through a #DeeAnalyzer on into a #DeeIndex.
 *
 * Most readers will extract a value of a given type from a given column,
 * but it must be noted that this is not a requirement. The strings may be
 * built from several columns.
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h> // memset()

#include "dee-model.h"
#include "dee-model-reader.h"

/**
 * dee_model_reader_read:
 * @self: The #DeeModelReader used to read @model
 * @model: The #DeeModel to read a string from
 * @iter: The row to read a string from
 *
 * Read data from a row in a #DeeModel and extract a string representation from
 * it.
 *
 * Note that generally a #DeeModelReader need not be confined to reading from
 * one specific column, although in practice most are.
 *
 * Returns: A newly allocated string. Free with g_free().
 */
gchar*
dee_model_reader_read (DeeModelReader *self,
                       DeeModel       *model,
                       DeeModelIter   *iter)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->reader_func (model, iter, self->userdata);
}

/**
 * dee_model_reader_destroy:
 * @reader: The reader to destroy
 *
 * Release resources associated with @reader, but does not free the
 * #DeeModelReader structure itself.
 *
 * This will call the destroy() function registered with the reader
 * if it is set.
 */
void
dee_model_reader_destroy (DeeModelReader *reader)
{
  g_return_if_fail (reader != NULL);

  if (reader->destroy)
    reader->destroy (reader->userdata);
}

/**
 * dee_model_reader_new:
 * @reader_func: (scope notified): The #DeeModelReaderFunc to use for the reader
 * @userdata: (closure) (allow-none): The user data to pass to @reader_func
 * @destroy: (allow-none): The #GDestroyNotify to call on
 *                                        @userdata when disposing of the reader
 * @out_reader: (out): A pointer to an uninitialized #DeeModelReader struct
 *
 * Create a new #DeeModelReader with the given parameters. This call will zero
 * the @out_reader struct.
 *
 */
void
dee_model_reader_new (DeeModelReaderFunc  reader_func,
                      gpointer            userdata,
                      GDestroyNotify      destroy,
                      DeeModelReader     *out_reader)
{
  g_return_if_fail (reader_func != NULL);
  g_return_if_fail (out_reader != NULL);
  
  memset (out_reader, 0, sizeof (DeeModelReader));
  
  out_reader->reader_func = reader_func;
  out_reader->userdata = userdata;
  out_reader->destroy = destroy;
}

static gchar*
_string_reader_func (DeeModel     *model,
                     DeeModelIter *iter,
                     gpointer      userdata)
{
  return g_strdup (
             dee_model_get_string (model, iter, GPOINTER_TO_UINT (userdata)));
}

/**
 * dee_model_reader_new_for_string_column:
 * @column: The column index to read a string from
 * @out_reader: (out): A pointer to a #DeeModelReader instance which will have
 *                     all fields initialized appropriately
 *
 * A #DeeModelReader reading a string from a #DeeModel at a given column
 */
void
dee_model_reader_new_for_string_column (guint column,
                                        DeeModelReader *out_reader)
{
  dee_model_reader_new (_string_reader_func, GUINT_TO_POINTER (column),
                        NULL, out_reader);
}

static gchar*
_int32_reader_func (DeeModel     *model,
                    DeeModelIter *iter,
                    gpointer      userdata)
{
  return g_strdup_printf (
         "%i", dee_model_get_int32 (model, iter, GPOINTER_TO_UINT (userdata)));
}

/**
 * dee_model_reader_new_for_int32_column:
 * @column: The column index to read a %gint32 from
 * @out_reader: (out): A pointer to a #DeeModelReader instance which will have
 *                     all fields initialized appropriately
 *
 * A #DeeModelReader reading a %gint32 from a #DeeModel at a given column
 */
void
dee_model_reader_new_for_int32_column (guint column,
                                       DeeModelReader *out_reader)
{
  dee_model_reader_new (_int32_reader_func, GUINT_TO_POINTER (column),
                        NULL, out_reader);
}

static gchar*
_uint32_reader_func (DeeModel     *model,
                     DeeModelIter *iter,
                     gpointer      userdata)
{
  return g_strdup_printf ("%"G_GUINT32_FORMAT,
               dee_model_get_uint32 (model, iter, GPOINTER_TO_UINT (userdata)));
}

/**
 * dee_model_reader_new_for_uint32_column:
 * @column: The column index to read a %guint32 from
 * @out_reader: (out): A pointer to a #DeeModelReader instance which will have
 *                     all fields initialized appropriately
 *
 * A #DeeModelReader reading a %guint32 from a #DeeModel at a given column
 */
void
dee_model_reader_new_for_uint32_column (guint column,
                                        DeeModelReader *out_reader)
{
  dee_model_reader_new (_uint32_reader_func, GUINT_TO_POINTER (column),
                        NULL, out_reader);
}
