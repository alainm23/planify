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
 *               Neil Jagdish Patel <neil.patel@canonical.com>
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 *
 * NB: Inspiration for column storage taken from GtkListStore
 *     API inspired by ClutterModel by Matthew Allumn <mallum@openedhand.com>
 *                                     Neil Patel <njp@o-hand.com>
 *                                     Emmanuele Bassi <ebassi@openedhand.com>
 */
/**
 * SECTION:dee-model
 * @short_description: A generic table model interface
 * @include: dee.h
 *
 * #DeeModel is a generic table model that can holds #GVariant<!-- -->s as
 * column values. Each column is restricted to hold variants with some
 * predefined type signature. This is known as the
 * <emphasis>column schema</emphasis>.
 *
 * <refsect2 id="dee-1.0-DeeModel.on_indexes">
 * <title>Indexes - Access by Key or Full Text Analysis</title>
 * <para>
 * Instead of forcing you to search the rows and columns for given values
 * or patterns #DeeModel is integrated with a powerful #DeeIndex that allows
 * you to create custom indexes over the model content that are updated
 * automatically as the model changes.
 * </para>
 * <para>
 * Indexes can be created for integer keys, string keys (fx. URIs), or for
 * full text search into the model contents. The indexing API is flexible
 * and extensible and can provide huge optimizations in terms of access times
 * if you find yourself iterating over the model searching for something.
 * </para>
 * </refsect2>
 *
 * <refsect2 id="dee-1.0-DeeModel.on_sorting">
 * <title>Sorting</title>
 * <para>
 * As a simpler alternative to using indexes you can rely on sorted models.
 * This is done by using the dee_model_insert_sorted() and
 * dee_model_find_sorted() family of APIs. Some model classes have 
 * accelerated implementations of sorted inserts and lookups.
 * Notably #DeeSequenceModel.
 * </para>
 * </refsect2>
 *
 * <refsect2 id="dee-1.0-DeeModel.on_tags">
 * <title>Tags - Attach Arbitrary Data to Rows</title>
 * <para>
 * It's a very common pattern that you want to render a #DeeModel into some
 * view in a classinc MVC pattern. If the view needs to reflect changes in the
 * model dynamically you often find yourself creating ad-hoc mappings between
 * the rows of the model and the widgets in your view.
 * </para>
 * <para>
 * In situations where you need to pair the rows in a model with some external
 * data structure the <emphasis>tags API</emphasis> may come in handy.
 * It consists of the functions dee_model_register_tag(), dee_model_set_tag(),
 * dee_model_get_tag(), and dee_model_clear_tag().
 * </para>
 * </refsect2>
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <memory.h>
#include <time.h>
#include <unistd.h>

#include "dee-model.h"
#include "dee-marshal.h"
#include "trace-log.h"

typedef DeeModelIface DeeModelInterface;
G_DEFINE_INTERFACE (DeeModel, dee_model, G_TYPE_OBJECT)

enum
{
  /* Public signals */
  DEE_MODEL_SIGNAL_ROW_ADDED,
  DEE_MODEL_SIGNAL_ROW_REMOVED,
  DEE_MODEL_SIGNAL_ROW_CHANGED,
  DEE_MODEL_SIGNAL_CHANGESET_STARTED,
  DEE_MODEL_SIGNAL_CHANGESET_FINISHED,

  DEE_MODEL_LAST_SIGNAL
};

static guint32 dee_model_signals[DEE_MODEL_LAST_SIGNAL] = { 0 };

#define CHECK_SCHEMA(self,out_num_cols,return_expression) \
if (G_UNLIKELY (dee_model_get_schema (self, out_num_cols) == NULL)) \
  { \
    g_critical ("The model %s@%p doesn't have a schema", \
                G_OBJECT_TYPE_NAME (self), self); \
    return_expression; \
  }

static void            dee_model_set_schema_valist (DeeModel    *self,
                                                    va_list     *args);

static void            dee_model_set_column_names_valist (DeeModel    *self,
                                                          const gchar *first_column_name,
                                                          va_list     *args);

static DeeModelIter*   dee_model_append_valist  (DeeModel *self,
                                                 va_list  *args);

static DeeModelIter*   dee_model_prepend_valist (DeeModel *self,
                                                 va_list  *args);

static DeeModelIter*   dee_model_insert_valist  (DeeModel *self,
                                                 guint     pos,
                                                 va_list  *args);

static DeeModelIter*   dee_model_insert_before_valist (DeeModel     *self,
                                                       DeeModelIter *iter,
                                                       va_list      *args);

static void            dee_model_set_valist     (DeeModel       *self,
                                                 DeeModelIter   *iter,
                                                 va_list        *args);

static void            dee_model_get_valist      (DeeModel     *self,
                                                  DeeModelIter *iter,
                                                  va_list       args);

static GVariant**      dee_model_build_row_valist (DeeModel  *self,
                                                   GVariant **out_row_members,
                                                   va_list   *args);

/* 
 * We provide here a couple of DeeModelIter functions, so that they're usable
 * from introspected languages.
 */

static gpointer
dee_model_iter_copy (gpointer boxed)
{
  /* FIXME: this implementation will work fine with DeeSequenceModel, but what
   * about others? */
  return boxed;
}

static void
dee_model_iter_free (gpointer boxed)
{
}

GType dee_model_iter_get_type (void)
{
  static GType dee_model_iter_type = 0;

  if (dee_model_iter_type == 0)
  {
    dee_model_iter_type = g_boxed_type_register_static ("DeeModelIter",
                                                        dee_model_iter_copy,
                                                        dee_model_iter_free);
  }

  return dee_model_iter_type;
}

static void
dee_model_default_init (DeeModelInterface *klass)
{
  /**
   * DeeModel::row-added:
   * @self: the #DeeModel on which the signal is emitted
   * @iter: (transfer none) (type Dee.ModelIter): a #DeeModelIter pointing to the newly added row
   *
   * Connect to this signal to be notified when a row is added to @self.
   **/
  dee_model_signals[DEE_MODEL_SIGNAL_ROW_ADDED] =
    g_signal_new ("row-added",
                  DEE_TYPE_MODEL,
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeeModelIface,row_added),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__BOXED,
                  G_TYPE_NONE, 1,
                  DEE_TYPE_MODEL_ITER);
  /**
   * DeeModel::row-removed:
   * @self: the #DeeModel on which the signal is emitted
   * @iter: (transfer none) (type Dee.ModelIter): a #DeeModelIter pointing to the removed row
   *
   * Connect to this signal to be notified when a row is removed from @self.
   *   The row is still valid while the signal is being emitted.
   **/
  dee_model_signals[DEE_MODEL_SIGNAL_ROW_REMOVED] =
    g_signal_new ("row-removed",
                  DEE_TYPE_MODEL,
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeeModelIface,row_removed),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__BOXED,
                  G_TYPE_NONE, 1,
                  DEE_TYPE_MODEL_ITER);
  /**
   * DeeModel::row-changed:
   * @self: the #DeeModel on which the signal is emitted
   * @iter: (transfer none) (type Dee.ModelIter): a #DeeModelIter pointing to the changed row
   *
   * Connect to this signal to be notified when a row is changed.
   **/
  dee_model_signals[DEE_MODEL_SIGNAL_ROW_CHANGED] =
    g_signal_new ("row-changed",
                  DEE_TYPE_MODEL,
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeeModelIface,row_changed),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__BOXED,
                  G_TYPE_NONE, 1,
                  DEE_TYPE_MODEL_ITER);

  /**
   * DeeModel::changeset-started
   * @self: the #DeeModel on which the signal is emitted
   *
   * Connect to this signal to be notified when a changeset that can contain
   * multiple row additions / changes / removals is about to be committed
   * to the model.
   * Note that not all model implementations use the changeset approach and
   * you might still get a row change signal outside of changeset-started and
   * changeset-finished signals. It also isn't guaranteed that a changeset
   * would always be non-empty.
   */
  dee_model_signals[DEE_MODEL_SIGNAL_CHANGESET_STARTED] =
    g_signal_new ("changeset-started",
                  DEE_TYPE_MODEL,
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeeModelIface, changeset_started),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__VOID,
                  G_TYPE_NONE, 0);

  /**
   * DeeModel::changeset-finished
   * @self: the #DeeModel on which the signal is emitted
   *
   * Connect to this signal to be notified when a changeset that can contain
   * multiple row additions / changes / removals has been committed
   * to the model.
   */
  dee_model_signals[DEE_MODEL_SIGNAL_CHANGESET_FINISHED] =
    g_signal_new ("changeset-finished",
                  DEE_TYPE_MODEL,
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeeModelIface, changeset_finished),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__VOID,
                  G_TYPE_NONE, 0);
}

/**
 * dee_model_set_schema:
 * @self: The #DeeModel to set the column layout for
 * @VarArgs: A list of #GVariant type strings terminated by a %NULL
 *
 * Set the #GVariant types and the number of columns used by @self.
 * This method must be called exactly once before using @self. Note that
 * some constructors will do this for you.
 *
 * To create a model with three columns; a 32 bit integer, a string,
 * and lastly an array of strings, you would do:
 * <informalexample><programlisting>
 *  DeeModel *model;
 *  model = dee_sequence_model_new ();
 *  dee_model_set_schema (model, "i", "s", "as", NULL);
 * </programlisting></informalexample>
 */ 
void
dee_model_set_schema (DeeModel    *self,
                      ...)
{
  va_list        args;

  g_return_if_fail (DEE_IS_MODEL (self));

  va_start (args, self);
  dee_model_set_schema_valist(self, &args);
  va_end (args);
}

/**
 * dee_model_set_schema_valist: (skip)
 * @self: The #DeeModel to change
 * @VarArgs: A list of #GVariant type strings terminated by a %NULL
 *
 * Like dee_model_set_schema() but for language bindings.
 */
static void
dee_model_set_schema_valist (DeeModel    *self,
                             va_list     *args)
{
  DeeModelIface *iface;
  GSList        *columns, *iter;
  const gchar   *column_schema;
  gchar        **column_schemas;
  guint          n_columns, i;

  g_return_if_fail (DEE_IS_MODEL (self));

  /* Extract and validate the column schema strings from the va_list */
  column_schema = va_arg (*args, const gchar*);
  n_columns = 0;
  columns = NULL;
  while (column_schema != NULL)
    {
      if (!g_variant_type_string_is_valid (column_schema))
        {
          g_critical ("When setting schema for DeeModel %p: '%s' is not a "
                      "valid GVariant type string", self, column_schema);
          return;
        }

      columns = g_slist_prepend (columns, g_strdup (column_schema));
      column_schema = va_arg (*args, const gchar*);
      n_columns++;
    }

  /* Construct a string array with the validated column schemas */
  columns = g_slist_reverse (columns);
  column_schemas = g_new0 (gchar*, n_columns + 1);

  for ((i = 0, iter = columns); iter; (i++, iter = iter->next))
    {
      column_schemas[i] = iter->data; // steal the duped type string
    }

#ifdef ENABLE_TRACE_LOG
  gchar* schema = g_strjoinv (", ", column_schemas);
  trace_object (self, "Set schema: (%s)", schema);
  g_free (schema);
#endif

  iface = DEE_MODEL_GET_IFACE (self);
  (* iface->set_schema_full) (self, (const gchar**) column_schemas, n_columns);

  g_slist_free (columns);
  g_strfreev (column_schemas);
}

/**
 * dee_model_set_schema_full:
 * @self: The #DeeModel to set the column layout for
 * @column_schemas: (array length=num_columns zero-terminated=1) (element-type utf8) (transfer none): A list of #GVariant type strings terminated by a %NULL
 * @num_columns: an integer specifying the array length for @VarArgs
 *
 * Set the #GVariant types and the number of columns used by @self.
 * This method must be called exactly once before using @self. Note that
 * some constructors will do this for you.
 */
void
dee_model_set_schema_full (DeeModel           *self,
                           const gchar* const *column_schemas,
                           guint               num_columns)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  if (dee_model_get_schema (self, NULL) != NULL)
    {
      g_critical ("The model %s@%p already has a schema set",
                  G_OBJECT_TYPE_NAME (self), self);
      return;
    }

  iface = DEE_MODEL_GET_IFACE (self);

  (* iface->set_schema_full) (self, column_schemas, num_columns);
}

void
dee_model_set_column_names (DeeModel *self, const gchar *first_column_name,
                            ...)
{
  va_list        args;

  g_return_if_fail (DEE_IS_MODEL (self));

  va_start (args, first_column_name);
  dee_model_set_column_names_valist (self, first_column_name, &args);
  va_end (args);
}

static void
dee_model_set_column_names_valist (DeeModel *self,
                                   const gchar *first_column_name,
                                   va_list *args)
{
  DeeModelIface *iface;
  const gchar  **column_names;
  guint          n_columns, i;

  g_return_if_fail (DEE_IS_MODEL (self));

  n_columns = dee_model_get_n_columns (self);

  g_return_if_fail (n_columns != 0);

  column_names = g_alloca (sizeof (gchar*) * n_columns);
  column_names[0] = first_column_name;

  i = 1;
  /* Extract and validate the column schema strings from the va_list */
  while (i < n_columns)
    {
      gchar *name = va_arg (*args, gchar*);
      column_names[i++] = name;
      if (name == NULL) break;
    }

  iface = DEE_MODEL_GET_IFACE (self);
  (* iface->set_column_names_full) (self, column_names, i);
}

/**
 * dee_model_set_column_names_full:
 * @self: A #DeeModel.
 * @column_names: (array length=num_columns zero-terminated=1) (element-type utf8) (transfer none): A list of column names terminated by a %NULL
 * @num_columns: an integer specifying the array length for @annotations
 *
 * Set column names used by @self.
 * This method must be called exactly once, but only after setting
 * a schema of the model. Note that some constructors will do this for you.
 */
void
dee_model_set_column_names_full (DeeModel     *self,
                                 const gchar **column_names,
                                 guint         num_columns)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  if (dee_model_get_schema (self, NULL) == NULL)
    {
      g_critical ("The model %s@%p doesn't have a schema set",
                  G_OBJECT_TYPE_NAME (self), self);
      return;
    }

  iface = DEE_MODEL_GET_IFACE (self);
  (* iface->set_column_names_full) (self, column_names, num_columns);
}

/**
 * dee_model_get_column_names:
 * @self: The #DeeModel to get the the schema for
 * @num_columns: (out) (allow-none): Address of an integer in which to store the
 *               number of columns in @self. Or %NULL to ignore the array length.
 *
 * Get a %NULL-terminated array of column names for the columns of @self.
 * These names can be used in calls to dee_model_build_named_row().
 *
 * Returns: (array length=num_columns) (element-type utf8) (transfer none):
 *          A %NULL-terminated array of #GVariant type strings. The length of
 *          the returned array is written to @num_columns. The returned array
 *          should not be freed or modified. It is owned by the model.
 */
const gchar**
dee_model_get_column_names (DeeModel *self,
                            guint    *num_columns)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_column_names) (self, num_columns);
}

/**
 * dee_model_get_schema:
 * @self: The #DeeModel to get the the schema for
 * @num_columns: (out) (allow-none): Address of an integer in which to store the
 *               number of columns in @self. Or %NULL to ignore the array length.
 *
 * Get a %NULL-terminated array of #GVariant type strings that defines the
 * required formats for the columns of @self.
 *
 * Returns: (array length=num_columns) (element-type utf8) (transfer none):
 *          A %NULL-terminated array of #GVariant type strings. The length of
 *          the returned array is written to @num_columns. The returned array
 *          should not be freed or modified. It is owned by the model.
 */
const gchar* const*
dee_model_get_schema (DeeModel *self,
                      guint    *num_columns)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_schema) (self, num_columns);
}

/**
 * dee_model_get_column_schema:
 * @self: a #DeeModel
 * @column: the column to get retrieve the #GVariant type string of
 *
 * Get the #GVariant signature of a column
 *
 * Return value: the #GVariant signature of the column at index @column
 */
const gchar*
dee_model_get_column_schema (DeeModel *self,
                             guint     column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_column_schema) (self, column);
}

/**
 * dee_model_get_field_schema:
 * @self: a #DeeModel
 * @field_name: name of vardict field to get schema of
 * @out_column: (out): column index of the associated vardict
 *
 * Get the #GVariant signature of field previously registered with 
 * dee_model_register_vardict_schema().
 *
 * Return value: the #GVariant signature for the field, or %NULL if given field
 *               wasn't registered with dee_model_register_vardict_schema().
 */
const gchar*
dee_model_get_field_schema (DeeModel    *self,
                            const gchar *field_name,
                            guint       *out_column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_field_schema) (self, field_name, out_column);
}

/**
 * dee_model_get_column_index:
 * @self: a #DeeModel
 * @column_name: the column name to retrieve the index of
 *
 * Get the column index of a column.
 *
 * Return value: 0-based index of the column or -1 if column with this name 
 *               wasn't found
 */
gint
dee_model_get_column_index (DeeModel    *self,
                            const gchar *column_name)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), -1);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_column_index) (self, column_name);
}

/**
 * dee_model_register_vardict_schema:
 * @self: a #DeeModel
 * @column: the column index to register the schemas with
 * @schemas: (element-type utf8 utf8): hashtable with keys specifying
 *           names of the fields and values defining their schema
 *
 * Register schema for fields in a model containing column with variant
 * dictionary schema ('a{sv}').
 * The keys registered with this function can be later used
 * with dee_model_build_named_row() function, as well as
 * dee_model_get_value_by_name(). Note that it is possible to register
 * the same field name for multiple columns, in which case you need to use
 * fully-qualified "column_name::field" name in the calls to
 * dee_model_build_named_row() and dee_model_get_field_schema().
 */
void
dee_model_register_vardict_schema (DeeModel   *self,
                                   guint       column,
                                   GHashTable *schemas)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->register_vardict_schema) (self, column, schemas);
}

/**
 * dee_model_get_vardict_schema:
 * @self: a #DeeModel
 * @column: the column index to get the schemas for
 *
 * Get a schema for variant dictionary column previously registered using
 * dee_model_register_vardict_schema().
 *
 * Return value: (transfer container) (element-type utf8 utf8): Hashtable 
 *               containing a mapping from field names to schemas or NULL.
 *               Note that keys and values in the hashtable may be owned
 *               by the model, so you need to create a deep copy if you
 *               intend to keep the hashtable around.
 */
GHashTable*
dee_model_get_vardict_schema (DeeModel *self, guint column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_vardict_schema) (self, column);
}

/**
 * dee_model_get_n_columns:
 * @self: a #DeeModel
 *
 * Gets the number of columns in @self
 *
 * Return value: the number of columns per row in @self
 **/
guint
dee_model_get_n_columns (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_n_columns) (self);
}

/**
 * dee_model_get_n_rows:
 * @self: a #DeeModel
 *
 * Gets the number of rows in @self
 *
 * Return value: the number of rows in @self
 **/
guint
dee_model_get_n_rows (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_n_rows) (self);
}

/**
 * dee_model_begin_changeset:
 * @self: a #DeeModel
 *
 * Notify listeners that the model is about to be changed, which means that
 * multiple row additions / changes / removals will follow.
 * The default implementation of this method will emit
 * the ::changeset-started signal.
 *
 * It is not stricly necessary to enclose every change to a model 
 * in a dee_model_begin_changeset() and dee_model_end_changeset() calls, but
 * doing so is highly recommended and allows implementing various optimizations.
 *
 * The usual way to perform multiple changes to a model is as follows:
 *
 * <programlisting>
 * void update_model (DeeModel *model)
 * {
 *   GVariant **added_row_data1 = ...;
 *   GVariant **added_row_data2 = ...;
 *
 *   dee_model_begin_changeset (model);
 *
 *   dee_model_remove (model, dee_model_get_first_iter (model));
 *   dee_model_append_row (model, added_row_data1);
 *   dee_model_append_row (model, added_row_data2);
 *
 *   dee_model_end_changeset (model);
 * }
 * </programlisting>
 */
void
dee_model_begin_changeset (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);

  if (iface->begin_changeset)
    (* iface->begin_changeset) (self);
  else
    g_signal_emit (self, dee_model_signals[DEE_MODEL_SIGNAL_CHANGESET_STARTED], 0);
}

/**
 * dee_model_end_changeset:
 * @self: a #DeeModel
 *
 * Notify listeners that all changes have been committed to the model.
 * The default implementation of this method will emit
 * the ::changeset-finished signal.
 *
 * See also dee_model_begin_changeset().
 */
void
dee_model_end_changeset (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);

  if (iface->end_changeset)
    (* iface->end_changeset) (self);
  else
    g_signal_emit (self, dee_model_signals[DEE_MODEL_SIGNAL_CHANGESET_FINISHED], 0);
}

static GVariant*
collect_variant (const gchar* col_schema, va_list *args)
{
  const gchar *col_string;
  GVariant    *result;

  if (g_variant_type_is_basic (G_VARIANT_TYPE (col_schema)))
    {
      switch (col_schema[0])
        {
          case 's':
          case 'o':
          case 'g':
            col_string = va_arg (*args, const gchar*);
            result = g_variant_new (col_schema, col_string ? col_string : "");
            break;
          default:
            result = g_variant_new_va (col_schema, NULL, args);
        }
    }
  else
    result = va_arg (*args, GVariant*);

  return result;
}

/**
 * dee_model_build_row:
 * @self: The model to create a row for
 * @out_row_members: An array to write the values to or %NULL to allocate
 *                   a new array. If non-%NULL it must have a length
 *                   that is longer or equal to the number of columns in @self
 * @VarArgs: A list with values matching the column schemas of @self.
 *           Basic variant types are passed directly while any other
 *           types must be boxed in a #GVariant. It's important to note that
 *           any floating references on variants passed to this method will be
 *           <emphasis>not</emphasis> be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Build an array of #GVariant<!-- -->s with values from the variadic argument
 * list according to the model schema for @self. The caller must call
 * g_variant_ref_sink() and g_variant_unref() on all the returned variants and
 * g_free() the array itself if %NULL was passed as @out_row_members.
 *
 * This is utility function and will not touch or modify @self in any way.
 *
 * Returns: If @out_row_members is %NULL a newly allocated array of variants
 *          will be returned and the array must be freed with g_free().
 *          If @out_row_members is non-%NULL it will be reused, and variants in
 *          the array may or may not have floating references, which means the
 *          caller must make sure that g_variant_ref_sink() and
 *          g_variant_unref() are called on them.
 *
 */
GVariant**
dee_model_build_row (DeeModel  *self,
                     GVariant **out_row_members,
                     ...)
{
  va_list    args;
  GVariant **result;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  va_start (args, out_row_members);
  result = dee_model_build_row_valist (self, out_row_members, &args);
  va_end (args);

  return result;
}

/**
 * dee_model_build_row_valist: (skip):
 * @self: The model to build a row for
 * @out_row_members: An array to write the values to or %NULL to allocate
 *                   a new array
 * @args: A %va_list of arguments as described in dee_model_build_row()
 *
 * Like dee_model_build_row() but intended for language bindings.
 *
 * Returns: See dee_model_build_row()
 */
static GVariant**
dee_model_build_row_valist (DeeModel  *self,
                            GVariant **out_row_members,
                            va_list   *args)
{
  guint         i, n_cols;
  const gchar  *col_schema;
  const gchar  *const *schema;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  schema = dee_model_get_schema (self, &n_cols);

  if (out_row_members == NULL)
    out_row_members = g_new0 (GVariant*, n_cols);

  for (i = 0; i < n_cols; i++)
    {
      col_schema = schema[i];

      out_row_members[i] = collect_variant (col_schema, args);

      if (G_UNLIKELY (out_row_members[i] == NULL))
        {
          g_critical ("Trying to build a row with a NULL member on position"
                      " %i. This is probably an error in an application using"
                      " libdee", i);
          return NULL;
        }
    }

  return out_row_members;
}

/**
 * dee_model_build_named_row:
 * @self: The model to create a row for
 * @out_row_members: An array to write the values to or %NULL to allocate
 *                   a new array. If non-%NULL it must have a length
 *                   that is longer or equal to the number of columns in @self
 * @first_column_name: A column name
 * @VarArgs: Value for given column, followed by more name/value pairs,
 *           followed by %NULL. The passed names have to match the column names
 *           (or field names registered with
 *           dee_model_register_vardict_schema()) and values have to be set
 *           according to schema of the given column or field.
 *           Basic variant types are passed directly while any other types
 *           must be boxed in a #GVariant, similar to dee_model_build_row().
 *
 * Build an array of #GVariant<!-- -->s with values from the variadic argument
 * list according to the column names and model schema for @self.
 * The caller must call g_variant_ref_sink() and g_variant_unref() 
 * on all the returned variants and g_free() the array itself if %NULL
 * was passed as @out_row_members.
 *
 * This is utility function and will not touch or modify @self in any way.
 *
 * For example, to append a row to model with signature ("s", "u", "s") and
 * column names set to ("uri", "count", "description") you could do:
 * <informalexample><programlisting>
 *  GVariant    *row_buf[3];
 *
 *  dee_model_append_row (model,
 *    dee_model_build_named_row (model, row_buf,
 *                               "uri", "http://example.org",
 *                               "count", 435,
 *                               "description", "Example.org site", NULL));
 * </programlisting></informalexample>
 * 
 * Returns: If @out_row_members is %NULL a newly allocated array of variants
 *          will be returned and the array must be freed with g_free().
 *          If @out_row_members is non-%NULL it will be reused, and variants in
 *          the array may or may not have floating references, which means the
 *          caller must make sure that g_variant_ref_sink() and
 *          g_variant_unref() are called on them.
 *
 */
GVariant**
dee_model_build_named_row (DeeModel    *self,
                           GVariant   **out_row_members,
                           const gchar *first_column_name,
                           ...)
{
  va_list    args;
  GVariant **result;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  va_start (args, first_column_name);
  result = dee_model_build_named_row_valist (self, out_row_members,
                                             first_column_name, &args);
  va_end (args);

  return result;
}

/**
 * dee_model_build_named_row_sunk:
 * @self: The model to create a row for
 * @out_row_members: (array): An array to write the values to or %NULL to
 *                   allocate a new array. If non-%NULL it must have a length
 *                   that is longer or equal to the number of columns in @self
 * @out_array_length: (out): Length of the returned variant array
 * @first_column_name: A column name
 * @VarArgs: Value for given column, followed by more name/value pairs,
 *           followed by %NULL. The passed names have to match the column names
 *           and values have to be set according to schema of @self.
 *           Basic variant types are passed directly while any other types
 *           must be boxed in a #GVariant, similar to dee_model_build_row().
 *
 * Version of dee_model_build_named_row() for language bindings - as opposed to
 * dee_model_build_named_row(), the returned variants will be strong
 * references, therefore you always have to call g_variant_unref() on the items
 * and g_free() the array itself if %NULL was passed as @out_row_members.
 *
 * If @out_row_members is non-%NULL, g_variant_unref() will be called
 * on its elements (if also non-%NULL), which allows easy reuse of the array
 * memory in loops.
 *
 * This is utility function and will not touch or modify @self in any way.
 *
 * Example of memory management for model with schema ("s", "i") and 
 * column names ("uri", "count"):
 * <informalexample><programlisting>
 *  GVariant    **row_buf;
 *
 *  row_buf = dee_model_build_named_row_sunk (model, NULL, "uri", "file:///",
 *                                            "count", 0, NULL);
 *  dee_model_append_row (model, row_buf);
 *
 *  for (int i = 1; i < 100; i++)
 *  {
 *    dee_model_append_row (model,
 *      dee_model_build_named_row_sunk (model, row_buf, "uri", "file:///",
 *                                      "count", i, NULL));
 *  }
 *  
 *  g_variant_unref (row_buf[0]);
 *  g_variant_unref (row_buf[1]);
 *  g_free (row_buf);
 * </programlisting></informalexample>
 * 
 * Returns: (array length=out_array_length): If @out_row_members is %NULL
 *          a newly allocated array of variants will be returned and the array
 *          must be freed with g_free().
 *          If @out_row_members is non-%NULL it will be reused. Variants in
 *          the array will have strong references, which means the
 *          caller must make sure that g_variant_unref() is called on them.
 *
 */
GVariant**
dee_model_build_named_row_sunk (DeeModel    *self,
                                GVariant   **out_row_members,
                                guint       *out_array_length,
                                const gchar *first_column_name,
                                ...)
{
  va_list    args;
  guint      num_columns, i;
  GVariant **result;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, &num_columns, return NULL);

  if (out_row_members)
    {
      for (i = 0; i < num_columns; i++)
        {
          if (out_row_members[i]) g_variant_unref (out_row_members[i]);
        }
    }

  va_start (args, first_column_name);
  result = dee_model_build_named_row_valist (self, out_row_members,
                                             first_column_name, &args);
  va_end (args);

  if (result)
    {
      for (i = 0; i < num_columns; i++)
        {
          g_variant_ref_sink (result[i]);
        }
    }

  if (out_array_length)
    *out_array_length = result != NULL ? num_columns : 0;

  return result;
}

GVariant**
dee_model_build_named_row_valist (DeeModel    *self,
                                  GVariant   **out_row_members,
                                  const gchar *first_column_name,
                                  va_list     *args)
{
  DeeModelIface    *iface;
  guint             n_cols, i;
  gint              col_idx, last_unset_col;
  gboolean         *variant_set;
  GVariantBuilder **builders;
  const gchar      *col_name, *col_schema;
  const gchar      *const *schema;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  schema = dee_model_get_schema (self, &n_cols);

  if (out_row_members == NULL)
    out_row_members = g_new0 (GVariant*, n_cols);

  variant_set = g_alloca (n_cols * sizeof (gboolean));
  memset (variant_set, 0, n_cols * sizeof (gboolean));

  builders = g_alloca (n_cols * sizeof (GVariantBuilder*));
  memset (builders, 0, n_cols * sizeof (GVariantBuilder*));

  iface = DEE_MODEL_GET_IFACE (self);

  col_name = first_column_name;
  while (col_name != NULL)
    {
      col_idx = (* iface->get_column_index) (self, col_name);
      if (col_idx >= 0)
        {
          col_schema = schema[col_idx];

          out_row_members[col_idx] = collect_variant (col_schema, args);

          if (G_UNLIKELY (out_row_members[col_idx] == NULL))
            {
              g_critical ("Trying to build a row with a NULL member for column"
                          " %s. This is probably an error in an application using"
                          " libdee", col_name);
              break;
            }
          else
            {
              variant_set[col_idx] = TRUE;
            }
        }
      else
        {
          // check if we have hints
          col_schema = (* iface->get_field_schema) (self, col_name, (guint*) &col_idx);
          if (col_schema != NULL)
            {
              const gchar *key_name;
              if (builders[col_idx] == NULL)
                {
                  builders[col_idx] = g_variant_builder_new (G_VARIANT_TYPE (schema[col_idx]));
                }

              key_name = strstr (col_name, "::");
              key_name = key_name != NULL ? key_name + 2 : col_name;
              g_variant_builder_add (builders[col_idx], "{sv}",
                                     key_name,
                                     collect_variant (col_schema, args));
            }
          else
            {
              g_warning ("Unable to find column index for \"%s\"", col_name);
              /* need to break, cause there's no way to know size of the value */
              break;
            }
        }
      col_name = va_arg (*args, const gchar*);
    }

  /* Finish builders */
  for (i = 0; i < n_cols; i++)
    {
      if (builders[i])
        {
          out_row_members[i] = g_variant_builder_end (builders[i]);
          g_variant_builder_unref (builders[i]);
          variant_set[i] = TRUE;
        }
    }

  /* Check if all columns were set */
  last_unset_col = -1;
  for (i = 0; i < n_cols; i++)
    {
      if (!variant_set[i])
        {
          /* Create empty a{sv} if needed */
          if (g_variant_type_is_subtype_of (G_VARIANT_TYPE (schema[i]),
                                            G_VARIANT_TYPE_VARDICT))
            {
              GVariantBuilder builder;
              g_variant_builder_init (&builder, G_VARIANT_TYPE (schema[i]));
              out_row_members[i] = g_variant_builder_end (&builder);
              variant_set[i] = TRUE;
            }
          else
            {
              last_unset_col = i;
            }
        }
    }

  if (last_unset_col >= 0)
    {
      /* Be nice and unref the variants we created */
      for (i = 0; i < n_cols; i++)
        {
          if (variant_set[i])
            {
              g_variant_unref (g_variant_ref_sink (out_row_members[i]));
              out_row_members[i] = NULL;
            }
        }

      const gchar **names = dee_model_get_column_names (self, NULL);
      g_critical ("Unable to build row: Column %d '%s' wasn't set",
                  last_unset_col, names ? names[last_unset_col] : "unnamed");
      return NULL;
    }

  return out_row_members;
}

/**
 * dee_model_append:
 * @self: a #DeeModel
 * @VarArgs: A list of values matching the column schemas of @self.
 *           Any basic variant type is passed as the standard C type while
 *           any other type must be boxed in a #GVariant. Any floating
 *           references will be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Creates and appends a new row to the end of a #DeeModel, setting the row
 * values upon creation.
 *
 * For and example see dee_model_insert_before().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_append (DeeModel *self,
                  ...)
{
  DeeModelIter     *iter;
  va_list           args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  va_start (args, self);
  iter = dee_model_append_valist (self, &args);
  va_end (args);

  return iter;
}

/**
 * dee_model_append_valist: (skip):
 * @self: A #DeeModel
 * @args: A pointer to a variable argument list
 *
 * Returns: A #DeeModelIter pointing to the new row
 */
static DeeModelIter*
dee_model_append_valist (DeeModel *self,
                         va_list  *args)
{
  DeeModelIface *iface;
  DeeModelIter  *iter;
  GVariant     **row_members;
  guint          num_columns;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);
  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  dee_model_build_row_valist (self, row_members, args);

  iter = (* iface->append_row) (self, row_members);
  return iter;
}

/**
 * dee_model_append_row:
 * @self: The model to prepend a row to
 * @row_members: (array zero-terminated=1): An array of  #GVariants with type
 *               signature matching those of the column schemas of @self.
 *               If any of the variants have floating references they will be
 *               consumed
 *
 * Like dee_model_append() but intended for language bindings or
 * situations where you work with models on a meta level and may not have
 * a prior knowledge of the column schemas of the models. See also
 * dee_model_build_row().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_append_row (DeeModel  *self,
                      GVariant **row_members)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);
  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->append_row) (self, row_members);
}

/**
 * dee_model_prepend:
 * @self: a #DeeModel
 * @VarArgs: A list of values  matching the column schemas of @self.
 *           Any basic variant type is passed as the standard C type while
 *           any other type must be boxed in a #GVariant. Any floating
 *           references will be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Creates and prepends a new row to the beginning of a #DeeModel, setting the
 * row values upon creation.
 *
 * Example:
 *
 * <informalexample><programlisting>
 *  DeeModel *model;
 *  model = ...
 *  dee_model_set_schema (model, "i", "s", NULL);
 *  dee_model_prepend (model, 10, "Rooney");
 * </programlisting></informalexample>
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_prepend (DeeModel *self,
                    ...)
{
  DeeModelIter     *iter;
  va_list           args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  va_start (args, self);
  iter = dee_model_prepend_valist (self, &args);
  va_end (args);
  
  return iter;
}

/**
 * dee_model_prepend_valist: (skip):
 * @self: A #DeeModel
 * @args: A pointer to a variable argument list
 *
 * Returns: A #DeeModelIter pointing to the new row
 */
static DeeModelIter*
dee_model_prepend_valist (DeeModel *self,
                          va_list  *args)
{
  DeeModelIface *iface;
  DeeModelIter  *iter;
  GVariant     **row_members;
  guint          num_columns;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);
  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  dee_model_build_row_valist (self, row_members, args);

  iter = (* iface->prepend_row) (self, row_members);
  return iter;
}

/**
 * dee_model_prepend_row:
 * @self: The model to prepend a row to
 * @row_members: (array zero-terminated=1): An array of
 *               #GVariants with type signature matching those of
 *               the column schemas of @self. If any of the variants have
 *               floating references they will be consumed.
 *
 * Like dee_model_prepend() but intended for language bindings or
 * situations where you work with models on a meta level and may not have
 * a priori knowledge of the column schemas of the models. See also
 * dee_model_build_row().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_prepend_row (DeeModel  *self,
                       GVariant **row_members)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->prepend_row) (self, row_members);
}

/**
 * dee_model_insert:
 * @self: a #DeeModel
 * @pos: The index to insert the row on. The existing row will be pushed down
 * @VarArgs: A list of values  matching the column schemas of @self.
 *           Any basic variant type is passed as the standard C type while
 *           any other type must be boxed in a #GVariant. Any floating
 *           references will be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Creates and inserts a new row into a #DeeModel, pushing the existing
 * rows down.
 *
 * For and example see dee_model_insert_before().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert (DeeModel *self,
                  guint     pos,
                  ...)
{
  DeeModelIter     *iter;
  va_list           args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  va_start (args, pos);
  iter = dee_model_insert_valist (self, pos, &args);
  va_end (args);
  
  return iter;
}

/**
 * dee_model_insert_valist: (skip):
 * @self: A #DeeModel
 * @pos: The index to insert the row on. The existing row will be pushed down
 * @args: A pointer to a variable argument list
 *
 * Returns: A #DeeModelIter pointing to the new row
 */
static DeeModelIter*
dee_model_insert_valist (DeeModel *self,
                         guint     pos,
                         va_list  *args)
{
  DeeModelIface *iface;
  DeeModelIter  *iter;
  GVariant     **row_members;
  guint          num_columns;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);
  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  dee_model_build_row_valist (self, row_members, args);

  iter = (* iface->insert_row) (self, pos, row_members);
  return iter;
}

/**
 * dee_model_insert_row:
 * @self: a #DeeModel
 * @pos: The index to insert the row on. The existing row will be pushed down.
 * @row_members: (array zero-terminated=1): An array of
 *               #GVariants with type signature matching those of
 *               the column schemas of @self. If any of the variants have
 *               floating references they will be consumed.
 *
 * As dee_model_insert(), but intended for language bindings or
 * situations where you work with models on a meta level and may not have
 * a priori knowledge of the column schemas of the models. See also
 * dee_model_build_row().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert_row (DeeModel  *self,
                      guint      pos,
                      GVariant **row_members)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->insert_row) (self, pos, row_members);
}

/**
 * dee_model_insert_before:
 * @self: a #DeeModel
 * @iter: An iter pointing to the row before which to insert the new one
 * @VarArgs: A list of values  matching the column schemas of @self.
 *           Any basic variant type is passed as the standard C type while
 *           any other type must be boxed in a #GVariant. Any floating
 *           references will be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Creates and inserts a new row into a #DeeModel just before the row pointed
 * to by @iter.
 *
 * For example, to insert a new row in a model with schema ("u", "s", "as")
 * you would do:
 *
 * <informalexample><programlisting>
 *  DeeModelIter    *iter;
 *  GVariantBuilder  b;
 *
 *  g_variant_builder_init (&amp;b, "as");
 *  g_variant_builder_add (&amp;b, "s", "Hello");
 *  g_variant_builder_add (&amp;b, "s", "World");
 *
 *  iter = find_my_special_row (model);
 *  dee_model_insert_before (model, iter,
 *                           27,
 *                           "Howdy",
 *                           g_variant_builder_end (&amp;b));
 * </programlisting></informalexample>
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert_before (DeeModel     *self,
                         DeeModelIter *iter,
                         ...)
{
  va_list           args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  va_start (args, iter);
  iter = dee_model_insert_before_valist (self, iter, &args);
  va_end (args);
  
  return iter;
}

/**
 * dee_model_insert_before_valist: (skip):
 * @self: a #DeeModel
 * @iter: An iter pointing to the row before which to insert the new one
 * @args: See dee_model_insert_before()
 *
 * As dee_model_insert_before(), but intended for language bindings.
 *
 * Returns: A #DeeModelIter pointing to the new row
 */
static DeeModelIter*
dee_model_insert_before_valist (DeeModel     *self,
                                DeeModelIter *iter,
                                va_list      *args)
{
  DeeModelIface  *iface;
  GVariant      **row_members;
  guint           num_columns;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);
  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  dee_model_build_row_valist (self, row_members, args);

  iter = (* iface->insert_row_before) (self, iter, row_members);
  return iter;
}

/**
 * dee_model_insert_row_before:
 * @self: a #DeeModel
 * @iter: An iter pointing to the row before which to insert the new one
 * @row_members: (array zero-terminated=1): An array of
 *       #GVariants with type signature matching those of the
 *       column schemas of @self. If any of the variants have floating
 *       references they will be consumed.
 *
 * As dee_model_insert_before(), but intended for language bindings or
 * situations where you work with models on a meta level and may not have
 * a priori knowledge of the column schemas of the models. See also
 * dee_model_build_row().
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 **/
DeeModelIter*
dee_model_insert_row_before (DeeModel      *self,
                             DeeModelIter  *iter,
                             GVariant     **row_members)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->insert_row_before) (self, iter, row_members);
}

/* Translates DeeCompareRowFunc callback into DeeCompareRowSizedFunc */
static gint
dee_model_cmp_func_translate_func (GVariant **row1,
                                   GVariant **row2,
                                   gpointer data)
{
  gpointer *all_data = (gpointer*) data;
  DeeCompareRowSizedFunc cmp_func = (DeeCompareRowSizedFunc) all_data[0];
  gpointer user_data = all_data[1];
  guint array_length = GPOINTER_TO_UINT (all_data[2]);

  return cmp_func (row1, array_length, row2, array_length, user_data);
}

/**
 * dee_model_insert_row_sorted:
 * @self: The model to do a sorted insert on
 * @row_members: (array zero-terminated=1): An array of
 *       #GVariants with type signature matching those of the
 *       column schemas of @self. If any of the variants have floating
 *       references they will be consumed.
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 *
 * Inserts a row in @self according to the sorting specified by @cmp_func.
 * If you use this method for insertion you should not use other methods as this
 * method assumes the model to be already sorted by @cmp_func.
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert_row_sorted (DeeModel           *self,
                             GVariant          **row_members,
                             DeeCompareRowFunc   cmp_func,
                             gpointer            user_data)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->insert_row_sorted) (self, row_members, cmp_func, user_data);
}

/**
 * dee_model_insert_row_sorted_with_sizes:
 * @self: The model to do a sorted insert on
 * @row_members: (array zero-terminated=1): An array of
 *       #GVariants with type signature matching those of the
 *       column schemas of @self. If any of the variants have floating
 *       references they will be consumed.
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 *
 * Inserts a row in @self according to the sorting specified by @cmp_func.
 * If you use this method for insertion you should not use other methods as this
 * method assumes the model to be already sorted by @cmp_func.
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert_row_sorted_with_sizes (DeeModel               *self,
                                        GVariant              **row_members,
                                        DeeCompareRowSizedFunc  cmp_func,
                                        gpointer                user_data)
{
  gpointer all_data[3];

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  all_data[0] = cmp_func;
  all_data[1] = user_data;
  all_data[2] = GUINT_TO_POINTER (dee_model_get_n_columns (self));

  return dee_model_insert_row_sorted (self, row_members,
                                      dee_model_cmp_func_translate_func,
                                      all_data);
}

/**
 * dee_model_insert_sorted:
 * @self: The model to do a sorted insert on
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 * @VarArgs: Specifies the row to insert. A collection of #GVariant<!-- -->s
 *           matching the number of columns @self
 *
 * Convenience function for calling dee_model_insert_row_sorted().
 * Inserts a row in @self according to the sorting specified by @cmp_func.
 * If you use this method for insertion you should not use other methods as this
 * method assumes the model to be already sorted by @cmp_func.
 *
 * Returns: (transfer none) (type Dee.ModelIter): A #DeeModelIter pointing to the new row
 */
DeeModelIter*
dee_model_insert_sorted (DeeModel           *self,
                         DeeCompareRowFunc   cmp_func,
                         gpointer            user_data,
                         ...)
{
  DeeModelIface  *iface;
  DeeModelIter   *iter;
  GVariant      **row_members;
  guint           num_columns;
  va_list         args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  va_start (args, user_data);
  dee_model_build_row_valist (self, row_members, &args);
  va_end (args);

  iter = (* iface->insert_row_sorted) (self, row_members, cmp_func, user_data);
  return iter;
}

/**
 * dee_model_find_row_sorted:
 * @self: The model to search
 * @row_spec: (array zero-terminated=1): An array of
 *       #GVariants with type signature matching those of the
 *       column schemas of @self. No references will be taken on the variants.
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 * @out_was_found: (out): A place to store a boolean value that will be set when
 *                 this method returns. If %TRUE then an exact match was found.
 *                 If %FALSE then the returned iter points to a row just after
 *                 where @row_spec would have been inserted.
 *                 Pass %NULL to ignore.
 *
 * Finds a row in @self according to the sorting specified by @cmp_func.
 * This method will assume that @self is already sorted by @cmp_func.
 *
 * If you use this method for searching you should only use
 * dee_model_insert_row_sorted() to insert rows in the model.
 *
 * Returns: (transfer none) (type Dee.ModelIter): If @out_was_found is set to
 *           %TRUE then a #DeeModelIter pointing to the last matching row.
 *           If it is %FALSE then the iter pointing to the row just after where
 *           @row_spec_would have been inserted.
 */
DeeModelIter*
dee_model_find_row_sorted (DeeModel           *self,
                           GVariant          **row_spec,
                           DeeCompareRowFunc   cmp_func,
                           gpointer            user_data,
                           gboolean           *out_was_found)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, NULL, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->find_row_sorted) (self, row_spec, cmp_func,
                                     user_data, out_was_found);
}

/**
 * dee_model_find_row_sorted_with_sizes:
 * @self: The model to search
 * @row_spec: (array zero-terminated=1): An array of
 *       #GVariants with type signature matching those of the
 *       column schemas of @self. No references will be taken on the variants.
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 * @out_was_found: (out): A place to store a boolean value that will be set when
 *                 this method returns. If %TRUE then an exact match was found.
 *                 If %FALSE then the returned iter points to a row just after
 *                 where @row_spec would have been inserted.
 *                 Pass %NULL to ignore.
 *
 * Like dee_model_find_row_sorted(), but uses DeeCompareRowSizedFunc and
 * therefore doesn't cause trouble when used from introspected languages.
 *
 * Finds a row in @self according to the sorting specified by @cmp_func.
 * This method will assume that @self is already sorted by @cmp_func.
 *
 * If you use this method for searching you should only use
 * dee_model_insert_row_sorted() (or dee_model_insert_row_sorted_with_sizes())
 * to insert rows in the model.
 *
 * Returns: (transfer none) (type Dee.ModelIter): If @out_was_found is set to
 *           %TRUE then a #DeeModelIter pointing to the last matching row.
 *           If it is %FALSE then the iter pointing to the row just after where
 *           @row_spec_would have been inserted.
 */
DeeModelIter*
dee_model_find_row_sorted_with_sizes (DeeModel                *self,
                                      GVariant               **row_spec,
                                      DeeCompareRowSizedFunc   cmp_func,
                                      gpointer                 user_data,
                                      gboolean                *out_was_found)
{
  gpointer all_data[3];

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  all_data[0] = cmp_func;
  all_data[1] = user_data;
  all_data[2] = GUINT_TO_POINTER (dee_model_get_n_columns (self));

  return dee_model_find_row_sorted (self, row_spec,
                                    dee_model_cmp_func_translate_func,
                                    all_data, out_was_found);
}

/**
 * dee_model_find_sorted:
 * @self: The model to search
 * @cmp_func: (scope call): Callback used for comparison or rows
 * @user_data: (closure): Arbitrary pointer passed to @cmp_func during search
 * @out_was_found: (out): A place to store a boolean value that will be set when
 *                 this method returns. If %TRUE then an exact match was found.
 *                 If %FALSE then the returned iter points to a row just after
 *                 where @row_spec would have been inserted.
 *                 Pass %NULL to ignore.
 * @VarArgs: A sequence of variables with type signature matching those of the
 *       column schemas of @self.
 *
 * Finds a row in @self according to the sorting specified by @cmp_func.
 * This method will assume that @self is already sorted by @cmp_func.
 *
 * If you use this method for searching you should only use
 * dee_model_insert_row_sorted() to insert rows in the model.
 *
 * Returns: (transfer none) (type Dee.ModelIter): If @out_was_found is set to
 *           %TRUE then a #DeeModelIter pointing to the last matching row.
 *           If it is %FALSE then the iter pointing to the row just after where
 *           @row_spec_would have been inserted.
 */
DeeModelIter*
dee_model_find_sorted (DeeModel           *self,
                       DeeCompareRowFunc   cmp_func,
                       gpointer            user_data,
                       gboolean           *out_was_found,
                       ...)
{
  DeeModelIface  *iface;
  DeeModelIter   *iter;
  GVariant      **row_members;
  guint           num_columns;
  va_list         args;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  CHECK_SCHEMA (self, &num_columns, return NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  row_members = g_alloca (num_columns * sizeof (gpointer));

  va_start (args, out_was_found);
  dee_model_build_row_valist (self, row_members, &args);
  va_end (args);

  iter = (* iface->find_row_sorted) (self, row_members, cmp_func,
                                     user_data, out_was_found);

  return iter;
}

/**
 * dee_model_remove:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter pointing to the row to remove
 *
 * Removes the row at the given position from the model.
 */
void
dee_model_remove (DeeModel     *self,
                  DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  CHECK_SCHEMA (self, NULL, return);

  iface = DEE_MODEL_GET_IFACE (self);

  (* iface->remove) (self, iter);
}

/**
 * dee_model_clear:
 * @self: a #DeeModel object to clear
 *
 * Removes all rows in the model. Signals are emitted for each row in the model
 */
void
dee_model_clear (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  CHECK_SCHEMA (self, NULL, return);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->clear) (self);
}

/**
 * dee_model_set:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @VarArgs: A list of values to set matching the column schemas.
 *           Any basic variant type is passed as the standard C type while
 *           any other type must be boxed in a #GVariant. Any floating
 *           references will be consumed. A %NULL value for a string
 *           type column will be converted to the empty string.
 *
 * Sets all values across the entire row referenced by @iter. The
 * variable argument list should contain values that match the column schemas
 * for the model. All basic variant type (see g_variant_type_is_basic()) are
 * passed in as their raw C type while all other types are passed in boxed in
 * a #GVariant. Any floating references on variants passed to this method are
 * consumed.
 *
 * For example, to set the values for a row on model with the schema
 * ("u", "s", "as"):
 * <informalexample><programlisting>
 *   GVariantBuilder b;
 *
 *   g_variant_builder_init (&amp;b, "as");
 *   g_variant_builder_add (&amp;b, "Hello");
 *   g_variant_builder_add (&amp;b, "World");
 *
 *   dee_model_set (model, iter, 27, "foo", g_variant_builder_end (&amp;b));
 * </programlisting></informalexample>
 **/
void
dee_model_set (DeeModel     *self,
               DeeModelIter *iter,
               ...)
{
  va_list           args;

  g_return_if_fail (DEE_IS_MODEL (self));

  /* Update data */
  va_start (args, iter);
  dee_model_set_valist (self, iter, &args);
  va_end (args);
}

/**
 * dee_model_set_valist: (skip):
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @args: See dee_model_set()
 *
 * See dee_model_set(). This version takes a va_list for language bindings.
 */
static void
dee_model_set_valist (DeeModel       *self,
                      DeeModelIter   *iter,
                      va_list        *args)
{
  DeeModelIface  *iface;
  GVariant      **row_members;
  guint           num_columns;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);
  num_columns = dee_model_get_n_columns (self);
  row_members = g_alloca (num_columns * sizeof (gpointer));

  dee_model_build_row_valist (self, row_members, args);

  (* iface->set_row) (self, iter, row_members);
}

/**
 * dee_model_set_value:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: column number to set the value
 * @value: New value for cell. If @value is a floating reference the model
 *         will assume ownership of the variant
 *
 * Sets the data in @column for the row @iter points to, to @value. The type
 * of @value must be convertible to the type of the column.
 *
 * When this method call completes the model will emit ::row-changed. You can
 * edit the model in place without triggering the change signals by calling
 * dee_model_set_value_silently().
 */
void
dee_model_set_value (DeeModel       *self,
                     DeeModelIter   *iter,
                     guint           column,
                     GVariant       *value)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  CHECK_SCHEMA (self, NULL, return);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->set_value) (self, iter, column, value);
}

/**
 * dee_model_set_row:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @row_members: (array): And array of 
 *               #GVariant<!-- -->s with type signature matching
 *               those from the model schema. If any of the variants have
 *               floating references these will be consumed
 *
 * Sets all columns in the row @iter points to, to those found in
 * @row_members. The variants in @row_members must match the types defined in
 * the model's schema.
 */
void
dee_model_set_row (DeeModel       *self,
                   DeeModelIter   *iter,
                   GVariant      **row_members)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  CHECK_SCHEMA (self, NULL, return);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->set_row) (self, iter, row_members);
}

/**
 * dee_model_get:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @VarArgs: a list of return locations matching the types defined in the
 *           column schemas. To ignore the data in a specific column pass
 *           a %NULL on that position
 *
 * Gets all the values across the entire row referenced by @iter. The
 * variable argument list should contain pointers to variables that match
 * the column schemas of this model.
 *
 * For all basic variant types (see g_variant_type_is_basic()) this method
 * expects pointers to their native C types while for all other types it
 * expects a pointer to a pointer to a #GVariant.
 *
 * For string values you are passed a constant reference which is owned by the
 * model, but any returned variants must be freed with g_variant_unref ().
 *
 * For example, to get all values a model with signature ("u", "s", "as") you
 * would do:
 * <informalexample><programlisting>
 *  guint32      u;
 *  const gchar *s;
 *  GVariant    *v;
 *
 *  dee_model_get (model, iter, &u, &s, &v);
 *
 *  // do stuff
 *
 *  g_variant_unref (v);
 * </programlisting></informalexample>
 **/
void
dee_model_get (DeeModel *self,
               DeeModelIter *iter,
               ...)
{
  va_list args;

  g_return_if_fail (DEE_IS_MODEL (self));
  g_return_if_fail (iter);

  va_start (args, iter);
  dee_model_get_valist (self, iter, args);
  va_end (args);
}

/**
 * dee_model_get_valist: (skip):
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @args: a list of column/return location pairs, terminated by -1
 *
 * See #dee_model_get(). This version takes a va_list for language bindings.
 **/
static void
dee_model_get_valist (DeeModel       *self,
                      DeeModelIter   *iter,
                      va_list         args)
{
  GVariant           *val;
  const GVariantType *val_t;
  guint               col, n_cols;
  gpointer           *col_data;

  g_return_if_fail (DEE_IS_MODEL (self));
  g_return_if_fail (iter != NULL);

  n_cols = dee_model_get_n_columns (self);

  for (col = 0; col < n_cols; col++)
    {
      col_data = va_arg (args, gpointer*);

      /* Skip past here if this column's data was not request */
      if (col_data == NULL)
        {
          continue;
        }

      val = dee_model_get_value (self, iter, col);
      val_t = g_variant_get_type (val);

      /* Basic types are passed back unboxed, and non-basic types are passed
       * back wrapped in variants. Strings are special because we pass them
       * back without copying them */
      if (g_variant_type_is_basic (val_t))
        {
          if (g_variant_type_equal (val_t, G_VARIANT_TYPE_SIGNATURE) ||
              g_variant_type_equal (val_t, G_VARIANT_TYPE_STRING) ||
              g_variant_type_equal (val_t, G_VARIANT_TYPE_OBJECT_PATH))
            {
              /* We need to cast away the constness */
              *col_data = (gpointer) g_variant_get_string (val, NULL);
            }
          else
            g_variant_get (val, dee_model_get_column_schema (self, col),
                           col_data);

          /* dee_model_get_value() returns a ref we need to free */
          g_variant_unref (val);
        }
      else
        {
          /* For complex types the ref on val is transfered to the caller */
          *col_data = val;
        }
    }
}

/**
 * dee_model_get_row:
 * @self: A #DeeModel to get a row from
 * @iter: A #DeeModelIter pointing to the row to get
 * @out_row_members: (array) (out) (allow-none) (default NULL):
 *                   An array of variants with a length bigger than or equal to
 *                   the number of columns in @self, or %NULL. If you pass
 *                   %NULL here a new array will be allocated for you. The
 *                   returned variants will have a non-floating reference
 *
 * Returns: (array zero-terminated=1): @out_row_members if it was not %NULL
 *          or a newly allocated array otherwise which you must free
 *          with g_free(). The variants in the array will have a strong
 *          reference and needs to be freed with g_variant_unref().
 */
GVariant**
dee_model_get_row (DeeModel      *self,
                   DeeModelIter  *iter,
                   GVariant     **out_row_members)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_row) (self, iter, out_row_members);
}

/**
 * dee_model_get_value:
 * @self: The #DeeModel to inspect
 * @iter: a #DeeModelIter pointing to the row to inspect
 * @column: column number to retrieve the value from
 *
 * Returns: (transfer full): A, guaranteed non-floating, reference to a
 *          #GVariant containing the row data. Free with g_variant_unref().
 */
GVariant*
dee_model_get_value (DeeModel     *self,
                     DeeModelIter *iter,
                     guint         column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_value) (self, iter, column);
}

/**
 * dee_model_get_value_by_name:
 * @self: The #DeeModel to inspect
 * @iter: a #DeeModelIter pointing to the row to inspect
 * @column: column name to retrieve the value from
 *
 * Returns: (transfer full): A, guaranteed non-floating, reference to a
 *          #GVariant containing the row data. Free with g_variant_unref().
 */
GVariant*
dee_model_get_value_by_name (DeeModel     *self,
                             DeeModelIter *iter,
                             const gchar  *column_name)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_value_by_name) (self, iter, column_name);
}

/**
 * dee_model_get_bool:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a boolean from
 *
 * Return value: if @iter and @column are valid, the boolean stored at @column.
 *               Otherwise %FALSE
 */
gboolean
dee_model_get_bool (DeeModel      *self,
                    DeeModelIter  *iter,
                    guint          column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), FALSE);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_bool) (self, iter, column);
}

/**
 * dee_model_get_uchar:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a uchar from
 *
 * Return value: if @iter and @column are valid, the uchar stored at @column.
 *  Otherwise 0.
 **/
guchar
dee_model_get_uchar (DeeModel      *self,
                      DeeModelIter  *iter,
                      guint           column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), '\0');

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_uchar) (self, iter, column);
}

/**
 * dee_model_get_int32:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a int from
 *
 * Return value: if @iter and @column are valid, the int stored at @column.
 *  Otherwise 0.
 **/
gint32
dee_model_get_int32 (DeeModel        *self,
                     DeeModelIter    *iter,
                     guint            column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_int32) (self, iter, column);
}

/**
 * dee_model_get_uint32:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a uint from
 *
 * Return value: if @iter and @column are valid, the uint stored at @column.
 *  Otherwise 0.
 **/
guint32
dee_model_get_uint32 (DeeModel      *self,
                      DeeModelIter  *iter,
                      guint           column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_uint32) (self, iter, column);
}


/**
 * dee_model_get_int64:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a int64 from
 *
 * Return value: if @iter and @column are valid, the int64 stored at @column.
 *  Otherwise 0.
 **/
gint64
dee_model_get_int64 (DeeModel      *self,
                     DeeModelIter  *iter,
                     guint          column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_int64) (self, iter, column);
}


/**
 * dee_model_get_uint64:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a uint64 from
 *
 * Return value: if @iter and @column are valid, the uint64 stored at @column.
 *  Otherwise 0.
 **/
guint64
dee_model_get_uint64 (DeeModel      *self,
                      DeeModelIter  *iter,
                      guint          column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_uint64) (self, iter, column);
}

/**
 * dee_model_get_double:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a double from
 *
 * Return value: if @iter and @column are valid, the double stored at @column.
 *  Otherwise 0.
 **/
gdouble
dee_model_get_double (DeeModel       *self,
                       DeeModelIter  *iter,
                       guint          column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), 0);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_double) (self, iter, column);
}

/**
 * dee_model_get_string:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 * @column: the column to retrieve a string from
 *
 * Return value: if @iter and @column are valid, the string stored at @column.
 *               Otherwise %NULL.
 **/
const gchar*
dee_model_get_string (DeeModel      *self,
                      DeeModelIter  *iter,
                      guint          column)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_string) (self, iter, column);
}

/**
 * dee_model_get_first_iter:
 * @self: a #DeeModel
 *
 * Retrieves a #DeeModelIter representing the first row in @self.
 *
 * Return value: (transfer none): A #DeeModelIter (owned by @self, do not
 *  free it)
 */
DeeModelIter*
dee_model_get_first_iter (DeeModel     *self)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_first_iter) (self);
}

/**
 * dee_model_get_last_iter:
 * @self: a #DeeModel
 *
 * Retrieves a #DeeModelIter pointing right <emphasis>after</emphasis> the
 * last row in @self. This is refered to also the the
 * <emphasis>end iter</emphasis>.
 *
 * As with other iters the end iter, in particular, is stable over inserts,
 * changes, or removals.
 *
 * Return value: (transfer none): A #DeeModelIter (owned by @self, do not
 *  free it)
 **/
DeeModelIter*
dee_model_get_last_iter (DeeModel *self)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_last_iter) (self);
}

/**
 * dee_model_get_iter_at_row:
 * @self: a #DeeModel
 * @row: position of the row to retrieve
 *
 * Retrieves a #DeeModelIter representing the row at the given index.
 *
 * Note that this method does not have any performance guarantees. In particular
 * it is not guaranteed to be <emphasis>O(1)</emphasis>.
 *
 * Return value: (transfer none): A new #DeeModelIter, or %NULL if @row
 *   was out of bounds. The returned iter is owned by @self, so do not free it.
 **/
DeeModelIter*
dee_model_get_iter_at_row (DeeModel *self, guint row)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_iter_at_row) (self, row);
}

/**
 * dee_model_next:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 *
 * Returns a #DeeModelIter that points to the next position in the model.
 *
 * Return value: (transfer none): A #DeeModelIter, pointing to the next row in
 *   the model. The iter is owned by @self, do not free it.
 **/
DeeModelIter*
dee_model_next (DeeModel     *self,
                DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->next) (self, iter);
}

/**
 * dee_model_prev:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 *
 * Returns a #DeeModelIter that points to the previous position in the model.
 *
 * Return value: (transfer none): A #DeeModelIter, pointing to the previous
 *   row in the model. The iter is owned by @self, do not free it.
 **/
DeeModelIter *
dee_model_prev (DeeModel     *self,
                DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->prev) (self, iter);
}

/**
 * dee_model_is_first:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 *
 * Checks if @iter is the very first iter @self.
 *
 * Return value: #TRUE if @iter is the first iter in the model
 */
gboolean
dee_model_is_first (DeeModel     *self,
                    DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), FALSE);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->is_first) (self, iter);
}

/**
 * dee_model_is_last:
 * @self: a #DeeModel
 * @iter: a #DeeModelIter
 *
 * Whether @iter is the end iter of @self. Note that the end iter points
 * right <emphasis>after</emphasis> the last valid row in @self.
 *
 * Return value: #TRUE if @iter is the last iter in the model
 */
gboolean
dee_model_is_last (DeeModel     *self,
                   DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), FALSE);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->is_last) (self, iter);
}

/**
 * dee_model_get_position:
 * @self: The model to inspect
 * @iter: The iter to get the position of
 *
 * Get the numeric offset of @iter into @self. Note that this method is
 * <emphasis>not</emphasis>  guaranteed to be <emphasis>O(1)</emphasis>.
 *
 * Returns: The integer offset of @iter in @self
 */
guint
dee_model_get_position (DeeModel     *self,
                        DeeModelIter *iter)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), -1);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_position) (self, iter);
}

/**
 * dee_model_register_tag:
 * @self: The model to register a tag on
 * @tag_destroy: Function called when a tagged row is removed from the model.
 *               This function will also be called on all tagged rows when the
 *               model is finalized.
 *
 * Register a new tag on a #DeeModel. A <emphasis>tag</emphasis> is an extra
 * value attached to a given row on a model. The tags are invisible to all
 * that doesn't have the tag handle returned by this method. #DeeModel
 * implementations must ensure that dee_model_get_tag() is an O(1) operation.
 *
 * Tags can be very useful in associating some extra data to a row in a model
 * and have that automatically synced when the model changes. If you're
 * writing a tiled view for a model you might want to tag each row with the
 * tile widget for that row. That way you have very convenient access to the
 * tile widget given any row in the model.
 *
 * The private nature of tags and the fact that you can store arbitrary pointers
 * and binary data in them also means that they are not serialized if you
 * utilize a model implementation that exposes the #DeeSerializable interface.
 *
 * Return value: (transfer none) (type Dee.ModelTag): A #DeeModelTag handle
 *               that you can use to set and get tags with
 */
DeeModelTag*
dee_model_register_tag (DeeModel       *self,
                        GDestroyNotify  tag_destroy)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->register_tag) (self, tag_destroy);
}

/**
 * dee_model_get_tag:
 * @self: The model to get a tag from
 * @iter: A #DeeModelIter pointing to the row to get the tag from
 * @tag: The tag handle to retrieve the tag value for
 *
 * Look up a tag value for a given row in a model. This method is guaranteed
 * to be O(1).
 *
 * Return value: (transfer none): Returns %NULL if @tag is unset otherwise the
 *               value of the tag as it was set with dee_model_set_tag().
 */
gpointer
dee_model_get_tag (DeeModel       *self,
                   DeeModelIter   *iter,
                   DeeModelTag    *tag)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_MODEL (self), NULL);

  iface = DEE_MODEL_GET_IFACE (self);

  return (* iface->get_tag) (self, iter, tag);
}

/**
 * dee_model_set_tag:
 * @self: The model to set a tag on
 * @iter: The row to set the tag on
 * @tag: The tag handle for the tag as obtained from dee_model_register_tag()
 * @value: The value to set for @tag. Note that %NULL represents an unset tag
 *
 * Set a tag on a row in a model. This function is guaranteed to be O(1).
 * See also dee_model_register_tag().
 *
 * If @tag is already set on this row the existing tag value will be destroyed
 * with the #GDestroyNotify passed to the dee_model_register_tag().
 */
void
dee_model_set_tag (DeeModel       *self,
                   DeeModelIter   *iter,
                   DeeModelTag    *tag,
                   gpointer        value)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);

  (* iface->set_tag) (self, iter, tag, value);
}

/**
 * dee_model_clear_tag:
 * @self: The model to clear a tag on
 * @iter: The row to clear the tag from
 * @tag: The tag to clear from @iter
 *
 * This method is purely syntactic sugar for calling dee_model_set_tag() with
 * a @value of %NULL. It's included in order to help developers write more
 * readable code.
 */
void
dee_model_clear_tag (DeeModel       *self,
                     DeeModelIter   *iter,
                     DeeModelTag    *tag)
{
  DeeModelIface *iface;

  g_return_if_fail (DEE_IS_MODEL (self));

  iface = DEE_MODEL_GET_IFACE (self);

  (* iface->set_tag) (self, iter, tag, NULL);
}

