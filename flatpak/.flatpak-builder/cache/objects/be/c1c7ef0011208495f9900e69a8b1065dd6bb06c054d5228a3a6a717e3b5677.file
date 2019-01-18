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
 * SECTION:dee-serializable-model
 * @short_description: Abstract base class for easing implementations of
 *                     #DeeModel<!-- -->s providing a unique version number
 *                     for each row
 * @include: dee.h
 *
 * #DeeSerializableModel is an abstract base class to ease implementation of
 * #DeeModel<!-- -->s providing rows versioned by a
 * <emphasis>sequence number</emphasis>.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <memory.h>
#include <time.h>
#include <unistd.h>

#include "dee-model.h"
#include "dee-serializable-model.h"
#include "dee-serializable.h"
#include "dee-marshal.h"
#include "trace-log.h"

static void     dee_serializable_model_model_iface_init (DeeModelIface *iface);
static void     dee_serializable_model_serializable_iface_init (DeeSerializableIface *iface);
static GObject* dee_serializable_model_parse_serialized (GVariant *data);
G_DEFINE_ABSTRACT_TYPE_WITH_CODE (DeeSerializableModel,
                                  dee_serializable_model,
                                  G_TYPE_OBJECT,
                                  G_IMPLEMENT_INTERFACE (DEE_TYPE_MODEL,
                                                         dee_serializable_model_model_iface_init)
                                  G_IMPLEMENT_INTERFACE (DEE_TYPE_SERIALIZABLE,
                                                         dee_serializable_model_serializable_iface_init));

#define DEE_SERIALIZABLE_MODEL_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_SERIALIZABLE_MODEL, DeeSerializableModelPrivate))

#define MODEL_VARIANT_TYPE_1_0 G_VARIANT_TYPE ("(asaav(tt))")
#define MODEL_VARIANT_TYPE     G_VARIANT_TYPE ("(asaav(tt)a{sv})")

/**
 * DeeSerializableModelPrivate:
 *
 * Ignore this structure.
 */
struct _DeeSerializableModelPrivate
{
  /* Seqnum tracking */
  guint64     seqnum;

  /* Column type info */
  guint       n_columns;
  gchar     **column_schemas; // NULL terminated
  gchar     **column_names;   // NULL terminated
  guint32    *column_name_hashes;
  GHashTable *field_schemas;
  gboolean    inside_changeset;
};

typedef struct _FieldSchemaInfo FieldSchemaInfo;

struct _FieldSchemaInfo
{
  gint   ref_count;     // thread unsafe refcount
  gchar *schema;
  guint  column;
};

/*
 * Public overridable DeeSerializableModel methods
 */
static guint64   dee_serializable_model_get_seqnum_real  (DeeModel     *self);

static void      dee_serializable_model_set_seqnum_real  (DeeModel     *self,
                                                       guint64       seqnum);

static guint64   dee_serializable_model_inc_seqnum_real  (DeeModel     *self);

/*
 * DeeModel forward declarations
 */
static const gchar* const*   dee_serializable_model_get_schema (DeeModel *self,
                                                             guint    *num_columns);

static const gchar*   dee_serializable_model_get_column_schema (DeeModel *self,
                                                                guint     column);

static const gchar*   dee_serializable_model_get_field_schema  (DeeModel    *self,
                                                                const gchar *field_name,
                                                                guint       *out_column);

static gint           dee_serializable_model_get_column_index  (DeeModel    *self,
                                                                const gchar *column_name);

static void           dee_serializable_model_set_schema_full  (DeeModel           *self,
                                                            const gchar* const *column_schemas,
                                                            guint               num_columns);

static void           dee_serializable_model_set_column_names_full (DeeModel     *self,
                                                                    const gchar **column_names,
                                                                    guint         num_columns);

static const gchar**  dee_serializable_model_get_column_names (DeeModel *self,
                                                               guint    *num_columns);

static void           dee_serializable_model_register_vardict_schema (DeeModel     *self,
                                                                      guint         column,
                                                                      GHashTable   *schema);

static GHashTable*    dee_serializable_model_get_vardict_schema (DeeModel *self,
                                                                 guint     column);

static guint          dee_serializable_model_get_n_columns  (DeeModel *self);

static guint          dee_serializable_model_get_n_rows     (DeeModel *self);

static void           dee_serializable_model_clear          (DeeModel *self);

static DeeModelIter*  dee_serializable_model_append_row  (DeeModel  *self,
                                                       GVariant **row_members);

static DeeModelIter*  dee_serializable_model_prepend_row  (DeeModel  *self,
                                                        GVariant **row_members);

static DeeModelIter*  dee_serializable_model_insert_row  (DeeModel  *self,
                                                       guint      pos,
                                                       GVariant **row_members);

static DeeModelIter*  dee_serializable_model_insert_row_before (DeeModel      *self,
                                                             DeeModelIter  *iter,
                                                             GVariant     **row_members);

static DeeModelIter*  dee_serializable_model_insert_row_sorted (DeeModel           *self,
                                                                GVariant          **row_members,
                                                                DeeCompareRowFunc   cmp_func,
                                                                gpointer            user_data);

static DeeModelIter*  dee_serializable_model_find_row_sorted   (DeeModel           *self,
                                                                GVariant          **row_spec,
                                                                DeeCompareRowFunc   cmp_func,
                                                                gpointer            user_data,
                                                                gboolean           *out_was_found);

static void           dee_serializable_model_remove         (DeeModel     *self,
                                                          DeeModelIter *iter);

static void           dee_serializable_model_set_value      (DeeModel       *self,
                                                          DeeModelIter   *iter,
                                                          guint           column,
                                                          GVariant       *value);

static void           dee_serializable_model_set_row            (DeeModel       *self,
                                                              DeeModelIter   *iter,
                                                              GVariant      **row_members);

static GVariant*     dee_serializable_model_get_value      (DeeModel     *self,
                                                          DeeModelIter *iter,
                                                          guint         column);

static GVariant*     dee_serializable_model_get_value_by_name (DeeModel     *self,
                                                               DeeModelIter *iter,
                                                               const gchar  *column_name);

static GVariant**    dee_serializable_model_get_row         (DeeModel    *self,
                                                             DeeModelIter *iter,
                                                             GVariant    **out_row_members);

static DeeModelIter* dee_serializable_model_get_first_iter  (DeeModel     *self);

static DeeModelIter* dee_serializable_model_get_last_iter   (DeeModel     *self);

static DeeModelIter* dee_serializable_model_get_iter_at_row (DeeModel     *self,
                                                         guint          row);

static gboolean       dee_serializable_model_get_bool       (DeeModel    *self,
                                                         DeeModelIter *iter,
                                                         guint         column);

static guchar         dee_serializable_model_get_uchar      (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gint32         dee_serializable_model_get_int32     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static guint32        dee_serializable_model_get_uint32    (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gint64         dee_serializable_model_get_int64      (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static guint64        dee_serializable_model_get_uint64     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gdouble        dee_serializable_model_get_double     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static const gchar*   dee_serializable_model_get_string     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static DeeModelIter* dee_serializable_model_next            (DeeModel     *self,
                                                         DeeModelIter *iter);

static DeeModelIter* dee_serializable_model_prev            (DeeModel     *self,
                                                         DeeModelIter *iter);

static gboolean       dee_serializable_model_is_first       (DeeModel     *self,
                                                         DeeModelIter *iter);

static gboolean       dee_serializable_model_is_last        (DeeModel     *self,
                                                         DeeModelIter *iter);

static void           dee_serializable_model_begin_changeset (DeeModel    *self);

static void           dee_serializable_model_end_changeset   (DeeModel    *self);

static guint sigid_changeset_started = 0;
static guint sigid_changeset_finished = 0;

/* FieldSchemaInfo methods */
static FieldSchemaInfo*
field_schema_info_new (const gchar *schema, guint column)
{
  FieldSchemaInfo *info;

  info = g_slice_new (FieldSchemaInfo);
  info->ref_count = 1;
  info->schema = g_strdup (schema);
  info->column = column;

  return info;
}

static FieldSchemaInfo*
field_schema_info_ref (FieldSchemaInfo *info)
{
  g_return_val_if_fail (info, NULL);

  info->ref_count++;

  return info;
}

static void
field_schema_info_unref (FieldSchemaInfo *info)
{
  g_return_if_fail (info);
  g_return_if_fail (info->ref_count > 0);

  if (--info->ref_count <= 0)
  {
    g_free (info->schema);
    g_slice_free (FieldSchemaInfo, info);
  }
}

/* GObject Init */
static void
dee_serializable_model_finalize (GObject *object)
{
  DeeSerializableModelPrivate *priv = DEE_SERIALIZABLE_MODEL (object)->priv;

  priv->n_columns = 0;
  priv->seqnum = 0;

  if (priv->column_schemas != NULL)
    {
      g_strfreev (priv->column_schemas);
      priv->column_schemas = NULL;
    }

  if (priv->column_names != NULL)
    {
      g_strfreev (priv->column_names);
      priv->column_names = NULL;
    }

  if (priv->column_name_hashes != NULL)
    {
      g_free (priv->column_name_hashes);
      priv->column_name_hashes = NULL;
    }

  if (priv->field_schemas != NULL)
    {
      g_hash_table_unref (priv->field_schemas);
      priv->field_schemas = NULL;
    }

  G_OBJECT_CLASS (dee_serializable_model_parent_class)->finalize (object);
}

static void
dee_serializable_model_set_property (GObject      *object,
                                 guint         id,
                                 const GValue *value,
                                 GParamSpec   *pspec)
{
  switch (id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_serializable_model_get_property (GObject    *object,
                                 guint       id,
                                 GValue     *value,
                                 GParamSpec *pspec)
{
  switch (id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_serializable_model_class_init (DeeSerializableModelClass *klass)
{
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_serializable_model_finalize;  
  obj_class->set_property = dee_serializable_model_set_property;
  obj_class->get_property = dee_serializable_model_get_property;

  klass->get_seqnum = dee_serializable_model_get_seqnum_real;
  klass->set_seqnum = dee_serializable_model_set_seqnum_real;
  klass->inc_seqnum = dee_serializable_model_inc_seqnum_real;

  sigid_changeset_started = g_signal_lookup ("changeset-started", DEE_TYPE_MODEL);
  sigid_changeset_finished = g_signal_lookup ("changeset-finished", DEE_TYPE_MODEL);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeSerializableModelPrivate));
}

static void
dee_serializable_model_init (DeeSerializableModel *model)
{
  DeeSerializableModelPrivate *priv;

  priv = model->priv = DEE_SERIALIZABLE_MODEL_GET_PRIVATE (model);

  priv->seqnum = 0;

  priv->n_columns = 0;
  priv->column_schemas = NULL;
  
  
}

static guint64
dee_serializable_model_get_seqnum_real (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);
  
  return DEE_SERIALIZABLE_MODEL (self)->priv->seqnum;
}


/**
 * dee_serializable_model_get_seqnum:
 *
 * @self: (type DeeSerializableModel): A #DeeSerializableModel instance
 *
 * Return value: Sequence number of this #DeeSerializableModel.
 */
guint64
dee_serializable_model_get_seqnum (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  return DEE_SERIALIZABLE_MODEL_GET_CLASS (self)->get_seqnum (self);
}

static void
dee_serializable_model_set_seqnum_real (DeeModel *self,
                                          guint64   seqnum)
{
  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));
    
  DEE_SERIALIZABLE_MODEL (self)->priv->seqnum = seqnum;
}

/**
 * dee_serializable_model_set_seqnum:
 *
 * @self: (type DeeSerializableModel): A #DeeSerializableModel instance
 * @seqnum: Sequence number
 *
 * Sets sequence number of this #DeeSerializableModel.
 */
void
dee_serializable_model_set_seqnum (DeeModel *self,
                                     guint64   seqnum)
{
  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));

  DEE_SERIALIZABLE_MODEL_GET_CLASS (self)->set_seqnum (self, seqnum);
}

static guint64
dee_serializable_model_inc_seqnum_real (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  return ++DEE_SERIALIZABLE_MODEL (self)->priv->seqnum;
}

/**
 * dee_serializable_model_inc_seqnum:
 *
 * @self: (type DeeSerializableModel): A #DeeSerializableModel instance
 *
 * Increments sequence number of this #DeeSerializableModel.
 */
guint64
dee_serializable_model_inc_seqnum (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  return DEE_SERIALIZABLE_MODEL_GET_CLASS (self)->inc_seqnum (self);
}

/*
 * DeeModel API
 */

static void
dee_serializable_model_set_schema_full  (DeeModel           *self,
                                      const gchar* const *column_schemas,
                                      guint               num_columns)
{
  DeeSerializableModelPrivate  *priv;
  gchar                    **column_schemas_copy;
  guint                      i;
  
  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));
  g_return_if_fail (column_schemas != NULL);

  priv = DEE_SERIALIZABLE_MODEL (self)->priv;

  if (priv->column_schemas != NULL)
    {
      g_critical ("The DeeModel %p already has a schema", self);
      return;
    }

  /* Allocate space to store the column schemas. We NULL terminate it
   * in order to play well with g_strfreev() */
  column_schemas_copy = g_new0 (gchar*, num_columns + 1);

  /* Validate the type strings and copy the schema for our selves */
  for (i = 0; i < num_columns; i++)
    {
      if (!g_variant_type_string_is_valid (column_schemas[i]))
        {
          g_critical ("When setting schema for DeeModel %p: '%s' is not a "
                      "valid type string", self, column_schemas[i]);
          return;
        }
      column_schemas_copy[i] = g_strdup (column_schemas[i]);
    }

  /* Register the validated types as our column types */
  priv->column_schemas = column_schemas_copy; // steal
  priv->n_columns = num_columns;

#ifdef ENABLE_TRACE_LOG
  gchar* schema = g_strjoinv (", ", priv->column_schemas);
  trace_object (self, "Set schema: (%s)", schema);
  g_free (schema);
#endif
}

static void
dee_serializable_model_set_column_names_full (DeeModel     *self,
                                              const gchar **column_names,
                                              guint         num_columns)
{
  DeeSerializableModelPrivate *priv;
  guint i, j;
  gboolean any_name_null;

  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));

  priv = DEE_SERIALIZABLE_MODEL (self)->priv;

  any_name_null = FALSE;
  for (i = 0; i < num_columns; i++)
    any_name_null |= column_names[i] == NULL;

  if (num_columns < priv->n_columns || any_name_null)
    {
      g_critical ("All column names have to be set!");
      return;
    }

  if (priv->column_names) g_strfreev (priv->column_names);
  if (priv->column_name_hashes) g_free (priv->column_name_hashes);

  priv->column_names = g_new0 (gchar*, priv->n_columns + 1);
  priv->column_name_hashes = g_new0 (guint32, priv->n_columns);

  for (i = 0; i < num_columns; i++)
    {
      priv->column_names[i] = g_strdup (column_names[i]);

      // hash for fast compares
      priv->column_name_hashes[i] = column_names[i] != NULL ?
        g_str_hash (column_names[i]) : 0;
    }

  // check for uniqueness
  for (i = 0; i < num_columns; i++)
    {
      for (j = i+1; j < num_columns; j++)
        {
          if (g_strcmp0 (priv->column_names[i], priv->column_names[j]) == 0)
            {
              g_warning ("Column names for columns %u and %u are the same!",
                         i, j);
            }
        }
    }
}

static const gchar**
dee_serializable_model_get_column_names (DeeModel *self,
                                         guint    *n_columns)
{
  DeeSerializableModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  priv = ((DeeSerializableModel*) self)->priv;

  if (n_columns != NULL)
    *n_columns = priv->n_columns;

  return (const gchar**) priv->column_names;
}

static void
dee_serializable_model_register_vardict_schema (DeeModel     *self,
                                                guint         column,
                                                GHashTable   *schema)
{
  DeeSerializableModelPrivate *priv;
  GHashTableIter iter;
  gpointer       key, value;

  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));
  g_return_if_fail (schema);

  priv = ((DeeSerializableModel*) self)->priv;
  g_return_if_fail (priv->column_schemas);
  g_return_if_fail (column < priv->n_columns);
  g_return_if_fail (g_variant_type_is_subtype_of (G_VARIANT_TYPE (priv->column_schemas[column]),
                                                  G_VARIANT_TYPE_VARDICT));

  if (priv->column_names == NULL || priv->column_names[column] == NULL)
    {
      g_critical ("Column name for column %u has to be set before calling "
                  "dee_model_register_vardict_schema", column);
      return;
    }

  if (priv->field_schemas == NULL)
    priv->field_schemas = g_hash_table_new_full (g_str_hash, g_str_equal,
                                                 g_free,
                                                 (GDestroyNotify) field_schema_info_unref);

  g_hash_table_iter_init (&iter, schema);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      FieldSchemaInfo *info;
      const gchar     *field_schema;
      gchar *full_name;
      guint  registered_column;

      field_schema = dee_model_get_field_schema (self, key, &registered_column);
      if (field_schema && registered_column != column)
        {
          g_warning ("Field '%s' is already registered for column %u! Please "
                     "use fully qualified names to refer to it ('%s::%s' and "
                     "'%s::%s')",
                     (gchar*) key, registered_column,
                     priv->column_names[registered_column], (gchar*) key,
                     priv->column_names[column], (gchar*) key);
        }
      else if (field_schema && !g_str_equal (field_schema, value))
        {
          g_warning ("Field '%s' was already registered with schema '%s'! "
                     "Overwriting with schema '%s'",
                     (gchar*) key, field_schema, (gchar*) value);
        }

      info = field_schema_info_new (value, column);
      g_hash_table_insert (priv->field_schemas, g_strdup (key), info);
      full_name = g_strdup_printf ("%s::%s", priv->column_names[column],
                                   (gchar*) key);
      /* transfering ownership of full_name to hashtable */
      g_hash_table_insert (priv->field_schemas, full_name,
                           field_schema_info_ref (info));
    }
}

static GHashTable*
dee_serializable_model_get_vardict_schema (DeeModel     *self,
                                           guint         column)
{
  DeeSerializableModelPrivate *priv;
  GHashTable    *result;
  GHashTableIter iter;
  gpointer       key, value;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  priv = ((DeeSerializableModel*) self)->priv;
  g_return_val_if_fail (priv->column_schemas, NULL);
  g_return_val_if_fail (column < priv->n_columns, NULL);
  g_return_val_if_fail (g_variant_type_is_subtype_of (G_VARIANT_TYPE (priv->column_schemas[column]),
                                                  G_VARIANT_TYPE_VARDICT), NULL);

  if (priv->field_schemas == NULL) return NULL;

  result = g_hash_table_new (g_str_hash, g_str_equal);
  g_hash_table_iter_init (&iter, priv->field_schemas);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gchar *field, *field_name;
      FieldSchemaInfo *info;

      field = (gchar*) key;
      info = (FieldSchemaInfo*) value;
      if (info->column != column) continue;

      field_name = strstr (field, "::");
      field_name = field_name != NULL ? field_name + 2 : field;

      g_hash_table_insert (result, field_name, info->schema);
    }

  return result;
}

static const gchar* const*
dee_serializable_model_get_schema (DeeModel *self,
                                   guint    *n_columns)
{
  DeeSerializableModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  priv = ((DeeSerializableModel*) self)->priv;

  if (n_columns != NULL)
    *n_columns = priv->n_columns;

  return (const gchar**) priv->column_schemas;
}

static const gchar*
dee_serializable_model_get_column_schema (DeeModel *self,
                                       guint     column)
{
  DeeSerializableModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  priv = ((DeeSerializableModel*) self)->priv;
  g_return_val_if_fail (column < priv->n_columns, NULL);

  return priv->column_schemas[column];
}

static const gchar*
dee_serializable_model_get_field_schema (DeeModel    *self,
                                         const gchar *field_name,
                                         guint       *out_column)
{
  DeeSerializableModelPrivate *priv;
  FieldSchemaInfo *info;
  
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);
  g_return_val_if_fail (field_name, NULL);

  priv = ((DeeSerializableModel*) self)->priv;

  if (priv->field_schemas == NULL) return NULL;

  info = g_hash_table_lookup (priv->field_schemas, field_name);
  if (info == NULL) return NULL;

  if (out_column) *out_column = info->column;

  return info->schema;
}

static gint
dee_serializable_model_get_column_index (DeeModel    *self,
                                         const gchar *column_name)
{
  gint                         i;
  guint                        hash;
  DeeSerializableModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), -1);

  priv = ((DeeSerializableModel*) self)->priv;

  if (priv->column_names == NULL || column_name == NULL) return -1;

  hash = g_str_hash (column_name);

  // FIXME: use a hashtable instead?
  for (i = 0; i < priv->n_columns; i++)
  {
    if (priv->column_name_hashes[i] == hash &&
        g_str_equal (priv->column_names[i], column_name)) return i;
  }

  return -1;
}

static guint
dee_serializable_model_get_n_columns (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  return ((DeeSerializableModel*) self)->priv->n_columns;
}

static guint
dee_serializable_model_get_n_rows (DeeModel *self)
{
  DeeModelIter *iter, *end;
  guint         count;

  count = 0;
  end = dee_model_get_last_iter (self);
  iter = dee_model_get_first_iter (self);
  while (iter != end)
    {
      iter = dee_model_next (self, iter);
      count++;
    }

  return count;
}

static void
dee_serializable_model_clear (DeeModel *self)
{
  DeeModelIter            *iter, *end;

  g_return_if_fail (DEE_IS_SERIALIZABLE_MODEL (self));

  iter = dee_model_get_first_iter (self);
  end = dee_model_get_last_iter (self);

  while (iter != end)
    {
      dee_model_remove (self, iter);
      iter = dee_model_get_first_iter (self);      
    }
}

static DeeModelIter*
dee_serializable_model_prepend_row (DeeModel  *self,
                                 GVariant **row_members)
{
  DeeModelIter *iter;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  iter = dee_model_get_first_iter (self);
  return dee_model_insert_row_before (self, iter, row_members);
}

static DeeModelIter*
dee_serializable_model_append_row (DeeModel  *self,
                                   GVariant **row_members)
{
  DeeModelIter *iter;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  iter = dee_model_get_last_iter (self);
  return dee_model_insert_row_before (self, iter, row_members);
}

static DeeModelIter*
dee_serializable_model_insert_row (DeeModel  *self,
                                   guint      pos,
                                   GVariant **row_members)
{
  DeeModelIter *iter;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  if (pos > 0)
    {
      iter = dee_model_get_iter_at_row (self, pos);
      return dee_model_insert_row_before (self, iter, row_members);
    }
  else if (pos == 0)
    return dee_model_prepend_row (self, row_members);
  else
    return dee_model_append_row (self, row_members);
}

static DeeModelIter*
dee_serializable_model_insert_row_before (DeeModel      *self,
                                       DeeModelIter  *iter,
                                       GVariant     **row_members)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static DeeModelIter*
dee_serializable_model_insert_row_sorted (DeeModel           *self,
                                          GVariant          **row_members,
                                          DeeCompareRowFunc   cmp_func,
                                          gpointer            user_data)
{
  DeeModelIter *iter;
  gboolean was_found;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);
  g_return_val_if_fail (row_members != NULL, NULL);
  g_return_val_if_fail (cmp_func != NULL, NULL);

  iter = dee_model_find_row_sorted (self, row_members, cmp_func,
                                    user_data, &was_found);
  if (was_found)
    iter = dee_model_next (self, iter);

  return dee_model_insert_row_before (self, iter, row_members);
}

static DeeModelIter*
dee_serializable_model_find_row_sorted   (DeeModel           *self,
                                          GVariant          **row_spec,
                                          DeeCompareRowFunc   cmp_func,
                                          gpointer            user_data,
                                          gboolean           *out_was_found)
{
  DeeModelIter  *iter, *end, *last_matching;
  GVariant     **row_buf;
  gint           cmp_result;
  guint          n_cols, i;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);
  g_return_val_if_fail (row_spec != NULL, NULL);
  g_return_val_if_fail (cmp_func != NULL, NULL);

  last_matching = NULL;
  if (out_was_found != NULL) *out_was_found = FALSE;
  n_cols = dee_model_get_n_columns (self);

  /* Stack allocate the buffer for speed, and so we don't have to free */
  row_buf = g_alloca (n_cols * sizeof (gpointer));

  iter = dee_model_get_first_iter (self);
  end = dee_model_get_last_iter (self);
  while (iter != end)
    {
      dee_model_get_row (self, iter, row_buf);
      cmp_result = cmp_func (row_buf, row_spec, user_data);
      /* we're returning last matching row to make ordering
       * of insert_row_sorted stable and fast */
      while (cmp_result == 0)
        {
          last_matching = iter;
          iter = dee_model_next (self, iter);
          if (iter == end)
            {
              iter = last_matching;
              break;
            }
          for (i = 0; i < n_cols; i++) g_variant_unref (row_buf[i]);
          dee_model_get_row (self, iter, row_buf);
          cmp_result = cmp_func (row_buf, row_spec, user_data);
        }

      for (i = 0; i < n_cols; i++) g_variant_unref (row_buf[i]);
      /* if we're past the matching row, the loop can be quit */
      if (cmp_result >= 0) break;
      iter = dee_model_next (self, iter);
    }

  if (out_was_found != NULL && last_matching != NULL) *out_was_found = TRUE;
  return last_matching ? last_matching : iter;
}

static void
dee_serializable_model_remove (DeeModel     *self,
                            DeeModelIter *iter_)
{
  g_critical ("%s not implemented", G_STRFUNC);
}

static void
dee_serializable_model_set_value (DeeModel       *self,
                               DeeModelIter   *iter,
                               guint           column,
                               GVariant       *value)
{
  g_critical ("%s not implemented", G_STRFUNC);
}

static void
dee_serializable_model_set_row (DeeModel       *self,
                             DeeModelIter   *iter,
                             GVariant      **row_members)
{
  g_critical ("%s not implemented", G_STRFUNC);
}

static GVariant*
dee_serializable_model_get_value (DeeModel     *self,
                               DeeModelIter *iter,
                               guint         column)
{
  g_critical ("%s not implemented", G_STRFUNC);

  return NULL;
}

static GVariant*
dee_serializable_model_get_value_by_name (DeeModel     *self,
                                          DeeModelIter *iter,
                                          const gchar  *column_name)
{
  gint col_index;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  col_index = dee_model_get_column_index (self, column_name);

  if (col_index >= 0)
    {
      return dee_model_get_value (self, iter, col_index);
    }
  else if (dee_model_get_field_schema (self, column_name, (guint*) &col_index))
    {
      GVariant    *dict, *result;
      const gchar *key_name;

      dict = dee_model_get_value (self, iter, col_index);
      // handle full "column::field" name
      key_name = strstr(column_name, "::");
      key_name = key_name != NULL ? key_name + 2 : column_name;
      result = g_variant_lookup_value (dict, key_name, NULL);
      g_variant_unref (dict);

      return result;
    }

  return NULL;
}

static GVariant**
dee_serializable_model_get_row (DeeModel      *self,
                                DeeModelIter  *iter,
                                GVariant     **out_row_members)
{
  guint            col, n_cols;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  n_cols = dee_model_get_n_columns (self);

  if (out_row_members == NULL)
    out_row_members = g_new0 (GVariant*, n_cols + 1);

  for (col = 0; col < n_cols; col++)
    out_row_members[col] = dee_model_get_value (self, iter, col);

  return out_row_members;
}

static gboolean
dee_serializable_model_get_bool (DeeModel     *self,
                                 DeeModelIter *iter,
                                 guint         column)
{
  GVariant *value;
  gboolean  b;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), FALSE);

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve bool from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return FALSE;
    }

  b = g_variant_get_boolean (value);
  g_variant_unref (value);

  return b;
}

static guchar
dee_serializable_model_get_uchar (DeeModel      *self,
                                  DeeModelIter  *iter,
                                  guint          column)
{
  GVariant *value;
  guchar    u;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), '\0');

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve uchar from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return '\0';
    }

  u = g_variant_get_byte(value);
  g_variant_unref (value);

  return u;
}

static gint32
dee_serializable_model_get_int32 (DeeModel        *self,
                                  DeeModelIter    *iter,
                                  guint            column)
{
  GVariant *value;
  gint32    i;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve int64 from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return 0;
    }

  i = g_variant_get_int32 (value);
  g_variant_unref (value);

  return i;
}

static guint32
dee_serializable_model_get_uint32 (DeeModel      *self,
                                   DeeModelIter  *iter,
                                   guint          column)
{
  GVariant *value;
  guint32    u;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve uint32 from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return 0;
    }

  u = g_variant_get_uint32 (value);
  g_variant_unref (value);

  return u;
}


static gint64
dee_serializable_model_get_int64 (DeeModel      *self,
                                  DeeModelIter  *iter,
                                  guint          column)
{
  GVariant *value;
  gint64    i;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self),
                        G_GINT64_CONSTANT (0));

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve int64 from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return G_GINT64_CONSTANT (0);
    }

  i = g_variant_get_int64 (value);
  g_variant_unref (value);

  return i;
}


static guint64
dee_serializable_model_get_uint64 (DeeModel      *self,
                                   DeeModelIter  *iter,
                                   guint          column)
{
  GVariant *value;
  guint64   u;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self),
                        G_GUINT64_CONSTANT (0));

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve uint64 from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return G_GUINT64_CONSTANT (0);
    }

  u = g_variant_get_uint64 (value);
  g_variant_unref (value);

  return u;
}

static gdouble
dee_serializable_model_get_double (DeeModel      *self,
                                   DeeModelIter  *iter,
                                   guint          column)
{
  GVariant *value;
  gdouble   d;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve double from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return 0;
    }

  d = g_variant_get_double (value);
  g_variant_unref (value);

  return d;
}

static const gchar*
dee_serializable_model_get_string (DeeModel      *self,
                                   DeeModelIter  *iter,
                                   guint          column)
{
  GVariant    *value;
  const gchar *s;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  value = dee_model_get_value (self, iter, column);

  if (G_UNLIKELY (value == NULL))
    {
      g_critical ("Failed to retrieve string from row %u column %u in %s@%p",
                  dee_model_get_position (self, iter), column,
                  G_OBJECT_TYPE_NAME (self), self);
      return NULL;
    }

  s = g_variant_get_string (value, NULL);
  g_variant_unref (value);

  return s;
}

static DeeModelIter*
dee_serializable_model_get_first_iter (DeeModel     *self)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static DeeModelIter*
dee_serializable_model_get_last_iter (DeeModel *self)
{
  DeeModelIter *iter;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  iter = dee_model_get_first_iter (self);
  while (!dee_model_is_last (self, iter))
    iter = dee_model_next (self, iter);

  return iter;
}

static DeeModelIter*
dee_serializable_model_get_iter_at_row (DeeModel *self,
                                     guint     row)
{
  DeeModelIter *iter;
  guint         pos;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), NULL);

  pos = 0;
  iter = dee_model_get_first_iter (self);
  while (!dee_model_is_last (self, iter) && pos < row)
    {
      iter = dee_model_next (self, iter);
      pos++;
    }

  if (dee_model_is_last (self, iter))
    {
      g_critical ("Index %u is out of bounds in model of size %u",
                  row, pos);
    }

  return iter;
}

static DeeModelIter*
dee_serializable_model_next (DeeModel     *self,
                          DeeModelIter *iter)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static DeeModelIter*
dee_serializable_model_prev (DeeModel     *self,
                          DeeModelIter *iter)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static gboolean
dee_serializable_model_is_first (DeeModel     *self,
                              DeeModelIter *iter)
{
  DeeModelIter *first;
  
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), FALSE);

  first = dee_model_get_first_iter (self);
  return first == iter;
}

static gboolean
dee_serializable_model_is_last (DeeModel     *self,
                             DeeModelIter *iter)
{
  DeeModelIter *last;
  
  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), FALSE);

  last = dee_model_get_last_iter (self);
  return last == iter;
}

static guint
dee_serializable_model_get_position (DeeModel     *self,
                                  DeeModelIter *iter)
{
  DeeModelIter *_iter;
  guint          pos;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), 0);

  pos = 0;
  _iter = dee_model_get_first_iter (self);
  while (!dee_model_is_last (self, iter) && iter != _iter)
    _iter = dee_model_next (self, _iter);
    pos++;

  if (iter == _iter)
    return pos;
  else
    {
      g_critical ("Can not find position of unknown iter %p", iter);
      return -1;
    }
}

static void
dee_serializable_model_begin_changeset (DeeModel *self)
{
  DeeSerializableModelPrivate  *priv;
  
  priv = DEE_SERIALIZABLE_MODEL (self)->priv;

  if (!priv->inside_changeset)
    {
      priv->inside_changeset = TRUE;
      g_signal_emit (self, sigid_changeset_started, 0);
    }
  else
    {
      g_warning ("Ignored call to dee_model_begin_changeset, finish "
                 "the current changeset using dee_model_end_changeset first");
    }
}

static void
dee_serializable_model_end_changeset (DeeModel *self)
{
  DeeSerializableModelPrivate  *priv;
  
  priv = DEE_SERIALIZABLE_MODEL (self)->priv;

  if (priv->inside_changeset)
    {
      priv->inside_changeset = FALSE;
      g_signal_emit (self, sigid_changeset_finished, 0);
    }
  else
    {
      g_warning ("Ignored call to dee_model_end_changeset, "
                 "dee_model_begin_changeset has to be called first");
    }
}

static DeeModelTag*
dee_serializable_model_register_tag    (DeeModel       *self,
                                        GDestroyNotify  tag_destroy)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static gpointer
dee_serializable_model_get_tag (DeeModel       *self,
                            DeeModelIter   *iter,
                            DeeModelTag    *tag)
{
  g_critical ("%s not implemented", G_STRFUNC);
  return NULL;
}

static void
dee_serializable_model_set_tag (DeeModel       *self,
                            DeeModelIter   *iter,
                            DeeModelTag    *tag,
                            gpointer        value)
{
  g_critical ("%s not implemented", G_STRFUNC);
}

/* Build a '(sasaavauay(tt))' suitable for sending in a Clone response */
static GVariant*
dee_serializable_model_serialize (DeeSerializable *self)
{
  DeeModel               *_self;
  GVariantBuilder         aav, clone, fields, vardict;
  GVariant               *val, *tt, *schema, *col_names;
  DeeModelIter           *iter;
  guint                   i, j, n_rows, n_columns;
  guint64                 last_seqnum;
  const gchar* const     *column_schemas;
  const gchar           **column_names;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE_MODEL (self), FALSE);

  trace_object (self, "Building clone");

  _self = DEE_MODEL (self);
  n_columns = dee_model_get_n_columns (_self);

  g_variant_builder_init (&aav, G_VARIANT_TYPE ("aav"));

  /* Clone the rows */
  i = 0;
  iter = dee_model_get_first_iter (_self);
  while (!dee_model_is_last (_self, iter))
    {
      g_variant_builder_open (&aav, G_VARIANT_TYPE ("av"));
      for (j = 0; j < n_columns; j++)
        {
          val = dee_model_get_value (_self, iter, j);
          g_variant_builder_add_value (&aav, g_variant_new_variant (val));
          g_variant_unref (val);
        }
      g_variant_builder_close (&aav);

      iter = dee_model_next (_self, iter);
      i++;
    }

  n_rows = i;

  /* Collect the schema */
  column_schemas = dee_model_get_schema(_self, NULL);
  schema = g_variant_new_strv (column_schemas, -1);

  /* Collect the column names */
  column_names = dee_model_get_column_names (_self, NULL);
  col_names = g_variant_new_strv (column_names,
                                  column_names != NULL ? n_columns : 0);

  g_variant_builder_init (&fields, G_VARIANT_TYPE ("a(uss)"));
  for (i = 0; i < n_columns; i++)
    {
      GHashTable *field_schemas;
      GHashTableIter ht_iter;
      gpointer       key, value;

      if (!g_variant_type_is_subtype_of (G_VARIANT_TYPE (column_schemas[i]),
                                         G_VARIANT_TYPE_VARDICT))
        continue;

      field_schemas = dee_model_get_vardict_schema (_self, i);
      if (field_schemas == NULL) continue;
      g_hash_table_iter_init (&ht_iter, field_schemas);
      while (g_hash_table_iter_next (&ht_iter, &key, &value))
        {
          g_variant_builder_add (&fields, "(uss)", i, key, value);
        }

      g_hash_table_unref (field_schemas);
    }

  /* Collect the seqnum */
  last_seqnum = dee_serializable_model_get_seqnum (_self);
  tt = g_variant_new ("(tt)", last_seqnum - n_rows, last_seqnum);

  /* Put all extra properties in a vardict */
  g_variant_builder_init (&vardict, G_VARIANT_TYPE ("a{sv}"));
  g_variant_builder_add (&vardict, "{sv}", "column-names", col_names);
  g_variant_builder_add (&vardict, "{sv}", "fields", g_variant_builder_end (&fields));

  /* Build the final clone */
  g_variant_builder_init (&clone, MODEL_VARIANT_TYPE);
  g_variant_builder_add_value (&clone, schema);
  g_variant_builder_add_value (&clone, g_variant_builder_end (&aav));
  g_variant_builder_add_value (&clone, tt);
  g_variant_builder_add_value (&clone, g_variant_builder_end (&vardict));

  trace_object (self, "Serialized with %i rows", dee_model_get_n_rows (_self));

  return g_variant_builder_end (&clone);
}

static GObject*
dee_serializable_model_parse_serialized (GVariant *data)
{
  DeeModel      *model;
  GVariant      *seqnumsv, *col, *vardict;
  GVariantIter  *row_iter, *col_iter, *vardict_schema_iter;
  GVariant     **row;
  const gchar  **schemas;
  const gchar  **column_names;
  gsize          n_cols, i, j, tuple_items;
  guint64        seqnum_start, seqnum_end;
  static GType   default_model_type = G_TYPE_INVALID;

  if (default_model_type == G_TYPE_INVALID)
    {
      default_model_type = g_type_from_name ("DeeSequenceModel");
      if (default_model_type == 0)
        {
          g_critical ("Unable to look up default DeeModel type, DeeSequenceModel, for deserialization");
          return NULL;
        }
    }

  tuple_items = g_variant_n_children (data);
  /* We support schema used by both dee 1.0 and 1.2 */
  if (tuple_items == 3) /* "(asaav(tt))" */
    {
      g_variant_get (data, "(^a&saav@(tt))", &schemas, &row_iter, &seqnumsv);
      vardict = NULL;
    }
  else if (tuple_items == 4) /* "(asaav(tt)a{sv})" */
    {
      g_variant_get (data, "(^a&saav@(tt)@a{sv})", &schemas, &row_iter,
                     &seqnumsv, &vardict);

      if (!g_variant_lookup (vardict, "column-names", "^a&s", &column_names))
        column_names = NULL;
      if (!g_variant_lookup (vardict, "fields", "a(uss)", &vardict_schema_iter))
        vardict_schema_iter = NULL;
    }
  else
    {
      g_critical ("Unable to deserialize model: Unrecognized schema");
      return NULL;
    }

  n_cols = g_strv_length ((gchar**) schemas);
  g_variant_get (seqnumsv, "(tt)", &seqnum_start, &seqnum_end);

  model = DEE_MODEL (g_object_new (default_model_type, NULL));
  dee_model_set_schema_full (model, schemas, n_cols);
  dee_serializable_model_set_seqnum (model, seqnum_start);

  if (vardict)
    {
      if (column_names && g_strv_length ((gchar**) column_names) == n_cols)
        {
          dee_model_set_column_names_full (model, column_names, n_cols);
        }

      if (vardict_schema_iter != NULL)
        {
          GHashTable **vardict_schemas;
          gchar *field_name, *field_schema;
          guint column_index;

          vardict_schemas = g_alloca (n_cols * sizeof (GHashTable*));
          memset (vardict_schemas, 0, n_cols * sizeof (GHashTable*));

          while (g_variant_iter_next (vardict_schema_iter, "(uss)",
                                      &column_index, &field_name, &field_schema))
            {
              if (vardict_schemas[column_index] == NULL)
                {
                  vardict_schemas[column_index] = g_hash_table_new_full (
                      g_str_hash, g_str_equal, g_free, g_free);
                }

              // using g_variant_iter_next, so we own field_name & schema
              g_hash_table_insert (vardict_schemas[column_index],
                                   field_name, field_schema);
            }

          for (column_index = 0; column_index < n_cols; column_index++)
            {
              if (vardict_schemas[column_index] == NULL) continue;
              dee_model_register_vardict_schema (model, column_index,
                                                 vardict_schemas[column_index]);
              g_hash_table_unref (vardict_schemas[column_index]);
            }

          g_variant_iter_free (vardict_schema_iter);
        }

      g_free (column_names);
      g_variant_unref (vardict);
    }

  /* Note: The 'row' variable is stack allocated. No need to free it */
  row = g_alloca (n_cols * sizeof (GVariant *));

  i = 0;
  while (g_variant_iter_next (row_iter, "av", &col_iter))
    {
      if (g_variant_iter_n_children (col_iter) != n_cols)
        {
          g_warning ("Row %"G_GSIZE_FORMAT" of serialized DeeSerializableModel "
                     "data has illegal length %"G_GSIZE_FORMAT". Expected %"
                     G_GSIZE_FORMAT, i, g_variant_iter_n_children (col_iter),
                     n_cols);
          /* Just skip this row - parsers for DeeSerializable should
           * generally never return NULL */
          continue;
        }

      j = 0;
      while (g_variant_iter_next (col_iter, "v", &col))
        {
          row[j] = col; // transfering variant reference to row[j]
          j++;
        }

      dee_model_append_row (model, row);

      for (j = 0; j < n_cols; j++)
        {
          g_variant_unref (row[j]);
        }

      i++;
      g_variant_iter_free (col_iter);
    }
  g_variant_iter_free (row_iter);
  g_free (schemas);
  g_variant_unref (seqnumsv);

  return (GObject *) model;
}

static void
dee_serializable_model_model_iface_init (DeeModelIface *iface)
{
  iface->set_schema_full       = dee_serializable_model_set_schema_full;
  iface->get_schema            = dee_serializable_model_get_schema;
  iface->get_column_schema     = dee_serializable_model_get_column_schema;
  iface->get_field_schema      = dee_serializable_model_get_field_schema;
  iface->get_column_index      = dee_serializable_model_get_column_index;
  iface->set_column_names_full = dee_serializable_model_set_column_names_full;
  iface->get_column_names      = dee_serializable_model_get_column_names;
  iface->get_n_columns         = dee_serializable_model_get_n_columns;
  iface->get_n_rows            = dee_serializable_model_get_n_rows;
  iface->append_row            = dee_serializable_model_append_row;
  iface->prepend_row           = dee_serializable_model_prepend_row;
  iface->insert_row            = dee_serializable_model_insert_row;
  iface->insert_row_before     = dee_serializable_model_insert_row_before;
  iface->insert_row_sorted     = dee_serializable_model_insert_row_sorted;
  iface->find_row_sorted       = dee_serializable_model_find_row_sorted;
  iface->remove                = dee_serializable_model_remove;
  iface->clear                 = dee_serializable_model_clear;
  iface->set_value             = dee_serializable_model_set_value;
  iface->set_row               = dee_serializable_model_set_row;
  iface->get_value             = dee_serializable_model_get_value;
  iface->get_value_by_name     = dee_serializable_model_get_value_by_name;
  iface->get_row               = dee_serializable_model_get_row;
  iface->get_first_iter        = dee_serializable_model_get_first_iter;
  iface->get_last_iter         = dee_serializable_model_get_last_iter;
  iface->get_iter_at_row       = dee_serializable_model_get_iter_at_row;
  iface->get_bool              = dee_serializable_model_get_bool;
  iface->get_uchar             = dee_serializable_model_get_uchar;
  iface->get_int32             = dee_serializable_model_get_int32;
  iface->get_uint32            = dee_serializable_model_get_uint32;
  iface->get_int64             = dee_serializable_model_get_int64;
  iface->get_uint64            = dee_serializable_model_get_uint64;
  iface->get_double            = dee_serializable_model_get_double;
  iface->get_string            = dee_serializable_model_get_string;
  iface->next                  = dee_serializable_model_next;
  iface->prev                  = dee_serializable_model_prev;
  iface->is_first              = dee_serializable_model_is_first;
  iface->is_last               = dee_serializable_model_is_last;
  iface->get_position          = dee_serializable_model_get_position;
  iface->register_tag          = dee_serializable_model_register_tag;
  iface->get_tag               = dee_serializable_model_get_tag;
  iface->set_tag               = dee_serializable_model_set_tag;
  iface->register_vardict_schema =
    dee_serializable_model_register_vardict_schema;
  iface->get_vardict_schema =
    dee_serializable_model_get_vardict_schema;

  iface->begin_changeset       = dee_serializable_model_begin_changeset;
  iface->end_changeset         = dee_serializable_model_end_changeset;
}

static void
dee_serializable_model_serializable_iface_init (DeeSerializableIface *iface)
{
  iface->serialize      = dee_serializable_model_serialize;

  dee_serializable_register_parser (DEE_TYPE_SERIALIZABLE_MODEL,
                                    MODEL_VARIANT_TYPE_1_0,
                                    dee_serializable_model_parse_serialized);
  dee_serializable_register_parser (DEE_TYPE_SERIALIZABLE_MODEL,
                                    MODEL_VARIANT_TYPE,
                                    dee_serializable_model_parse_serialized);
}

