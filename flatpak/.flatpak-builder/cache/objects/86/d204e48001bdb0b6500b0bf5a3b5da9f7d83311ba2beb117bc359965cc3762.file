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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_MODEL_READER_H
#define _HAVE_DEE_MODEL_READER_H

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>

G_BEGIN_DECLS

/**
 * DeeModelReaderFunc:
 * @model: The model being indexed
 * @iter: The row to extract terms for
 * @userdata: (closure):The data set when registering the reader
 *
 * Extracts a string from a row in a model.
 *
 * Returns: A newly allocated string with the row data to be indexed.
 *          Free with g_free().
 */
typedef gchar*          (*DeeModelReaderFunc) (DeeModel     *model,
                                               DeeModelIter *iter,
                                               gpointer      userdata);

/**
 * DeeModelReader:
 * @reader_func: (scope notified): The #DeeModelReaderFunc used to extract
 *                                 string from a model
 * @userdata: (closure): user data to pass to @reader_func
 * @destroy: Called when the reader is destroyed
 *
 * Structure encapsulating the information needed to read strings from a
 * model. Used for example by #DeeIndex.
 */
typedef struct {
  DeeModelReaderFunc reader_func;
  gpointer           userdata;
  GDestroyNotify     destroy;

  /*< private >*/
  gpointer           _padding1;
  gpointer           _padding2;
  gpointer           _padding3;
  gpointer           _padding4;
  gpointer           _padding5;
} DeeModelReader;

gchar*          dee_model_reader_read          (DeeModelReader *self,
                                                DeeModel       *model,
                                                DeeModelIter   *iter);

void            dee_model_reader_destroy       (DeeModelReader *reader);

void dee_model_reader_new                   (DeeModelReaderFunc  reader_func,
                                             gpointer            userdata,
                                             GDestroyNotify      destroy,
                                             DeeModelReader     *out_reader);

void dee_model_reader_new_for_string_column (guint           column,
                                             DeeModelReader *out_reader);

void dee_model_reader_new_for_int32_column  (guint           column,
                                             DeeModelReader *out_reader);

void dee_model_reader_new_for_uint32_column (guint           column,
                                             DeeModelReader *out_reader);

G_END_DECLS

#endif /* _HAVE_DEE_MODEL_READER_H */
