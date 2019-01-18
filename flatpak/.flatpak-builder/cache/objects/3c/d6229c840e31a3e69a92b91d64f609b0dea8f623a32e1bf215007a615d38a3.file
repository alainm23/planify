/*
 * handle-repo-dynamic.c - mechanism to store and retrieve handles on a
 * connection (general implementation with dynamic handle allocation and
 * recycling)
 *
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * SECTION:handle-repo-dynamic
 * @title: TpDynamicHandleRepo
 * @short_description: general handle repository implementation, with dynamic
 *  handle allocation and recycling
 * @see_also: TpHandleRepoIface, TpStaticHandleRepo
 *
 * A dynamic handle repository will accept arbitrary handles, which can
 * be created and destroyed at runtime.
 *
 * The #TpHandleRepoIface:handle-type property must be set at construction
 * time; the #TpDynamicHandleRepo:normalize-function property may be set to
 * perform validation and normalization on handle ID strings.
 *
 * Most connection managers will use this for all supported handle types
 * except %TP_HANDLE_TYPE_LIST.
 *
 * Changed in 0.13.8: handles are no longer reference-counted, and
 * the reference-count-related functions are stubs. Instead, handles remain
 * valid until the handle repository is destroyed.
 */

#include "config.h"

#include <telepathy-glib/handle-repo-dynamic.h>

#include <dbus/dbus-glib.h>

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/heap.h>
#include <telepathy-glib/handle-repo-internal.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_HANDLES
#include "telepathy-glib/debug-internal.h"

/**
 * TpDynamicHandleRepoNormalizeFunc:
 * @repo: The repository on which tp_handle_lookup() or tp_handle_ensure()
 *        was called
 * @id: The name to be normalized
 * @context: Arbitrary context passed to tp_handle_lookup() or
 *           tp_handle_ensure()
 * @error: Used to raise the Telepathy error InvalidHandle with an appropriate
 *         message if NULL is returned
 *
 * Signature of the normalization function optionally used by
 * #TpDynamicHandleRepo instances.
 *
 * Returns: a normalized version of @id (to be freed with g_free by the
 *          caller), or NULL if @id is not valid for this repository
 */

/**
 * TpDynamicHandleRepoNormalizeAsync:
 * @repo: The repository on which tp_handle_ensure_async() was called
 * @connection: the #TpBaseConnection using this handle repo
 * @id: The name to be normalized
 * @context: Arbitrary context passed to tp_handle_ensure_async()
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Signature of a function to asynchronously normalize an identifier. See
 * tp_dynamic_handle_repo_set_normalize_async().
 *
 * Since: 0.19.2
 */

/**
 * TpDynamicHandleRepoNormalizeFinish:
 * @repo: The repository on which tp_handle_ensure_async() was called
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Signature of a function to finish the operation started with
 * #TpDynamicHandleRepoNormalizeAsync.
 *
 * Since: 0.19.2
 */

/**
 * tp_dynamic_handle_repo_new:
 * @handle_type: The handle type
 * @normalize_func: The function to be used to normalize and validate handles,
 *  or %NULL to accept all handles as-is
 * @default_normalize_context: The context pointer to be passed to the
 *  @normalize_func if a %NULL context is passed to tp_handle_lookup() and
 *  tp_handle_ensure(); this may itself be %NULL
 *
 * <!---->
 *
 * Returns: a new dynamic handle repository
 */

/* Handle private data structure */

typedef struct _TpHandlePriv TpHandlePriv;

struct _TpHandlePriv
{
  /* Unique ID */
  gchar *string;
  GData *datalist;
};

static const TpHandlePriv empty_priv = { NULL, NULL };

static void
handle_priv_init_take_string (TpHandlePriv *priv,
    gchar *string)
{
  priv->string = string;
  g_datalist_init (&(priv->datalist));
}

static void
handle_priv_free_contents (TpHandlePriv *priv)
{
  g_free (priv->string);
  g_datalist_clear (&(priv->datalist));
}

enum
{
  PROP_HANDLE_TYPE = 1,
  PROP_NORMALIZE_FUNCTION,
  PROP_DEFAULT_NORMALIZE_CONTEXT,
};

/**
 * TpDynamicHandleRepoClass:
 *
 * The class of a dynamic handle repository. The contents of the struct
 * are private.
 */

struct _TpDynamicHandleRepoClass {
  GObjectClass parent_class;
};

/**
 * TpDynamicHandleRepo:
 *
 * A dynamic handle repository. The contents of the struct are private.
 */

struct _TpDynamicHandleRepo {
  GObject parent;

  TpHandleType handle_type;

  /* Array of TpHandlePriv keyed by handle; 0th element is unused */
  GArray *handle_to_priv;
  /* Map contact unique ID -> GUINT_TO_POINTER(handle) */
  GHashTable *string_to_handle;
  /* Normalization function */
  TpDynamicHandleRepoNormalizeFunc normalize_function;
  /* Context for normalization function if NULL is passed to _ensure or
   * _lookup
   */
  gpointer default_normalize_context;

  /* Extra data for normalization */
  gpointer normalization_data;
  /* Destructor for extra data */
  GDestroyNotify free_normalization_data;

  /* Async normalization function */
  TpDynamicHandleRepoNormalizeAsync normalize_async;
  TpDynamicHandleRepoNormalizeFinish normalize_finish;
};

static void dynamic_repo_iface_init (gpointer g_iface,
    gpointer iface_data);

G_DEFINE_TYPE_WITH_CODE (TpDynamicHandleRepo, tp_dynamic_handle_repo,
    G_TYPE_OBJECT, G_IMPLEMENT_INTERFACE (TP_TYPE_HANDLE_REPO_IFACE,
        dynamic_repo_iface_init))

static inline TpHandlePriv *
handle_priv_lookup (TpDynamicHandleRepo *repo,
    TpHandle handle)
{
  if (handle == 0 || handle >= repo->handle_to_priv->len)
    return NULL;

  return &g_array_index (repo->handle_to_priv, TpHandlePriv, handle);
}

static void
tp_dynamic_handle_repo_init (TpDynamicHandleRepo *self)
{
  self->handle_to_priv = g_array_new (FALSE, FALSE, sizeof (TpHandlePriv));
  /* dummy 0'th entry */
  g_array_append_val (self->handle_to_priv, empty_priv);

  self->string_to_handle = g_hash_table_new (g_str_hash, g_str_equal);
}

static void
dynamic_dispose (GObject *obj)
{
  _tp_dynamic_handle_repo_set_normalization_data ((TpHandleRepoIface *) obj,
      NULL, NULL);

  G_OBJECT_CLASS (tp_dynamic_handle_repo_parent_class)->dispose (obj);
}

static void
dynamic_finalize (GObject *obj)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (obj);
  GObjectClass *parent = G_OBJECT_CLASS (tp_dynamic_handle_repo_parent_class);
  guint i;

  g_assert (self->handle_to_priv != NULL);
  g_assert (self->string_to_handle != NULL);

  for (i = 0; i < self->handle_to_priv->len; i++)
    {
      handle_priv_free_contents (&g_array_index (self->handle_to_priv,
            TpHandlePriv, i));
    }

  g_array_unref (self->handle_to_priv);
  g_hash_table_unref (self->string_to_handle);

  if (parent->finalize)
    parent->finalize (obj);
}

static void
dynamic_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (object);

  switch (property_id)
    {
    case PROP_HANDLE_TYPE:
      g_value_set_uint (value, self->handle_type);
      break;
    case PROP_NORMALIZE_FUNCTION:
      g_value_set_pointer (value, self->normalize_function);
      break;
    case PROP_DEFAULT_NORMALIZE_CONTEXT:
      g_value_set_pointer (value, self->default_normalize_context);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
dynamic_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (object);

  switch (property_id)
    {
    case PROP_HANDLE_TYPE:
      self->handle_type = g_value_get_uint (value);
      break;
    case PROP_NORMALIZE_FUNCTION:
      self->normalize_function = g_value_get_pointer (value);
      break;
    case PROP_DEFAULT_NORMALIZE_CONTEXT:
      self->default_normalize_context = g_value_get_pointer (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
tp_dynamic_handle_repo_class_init (TpDynamicHandleRepoClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;

  object_class->dispose = dynamic_dispose;
  object_class->finalize = dynamic_finalize;

  object_class->get_property = dynamic_get_property;
  object_class->set_property = dynamic_set_property;

  g_object_class_override_property (object_class, PROP_HANDLE_TYPE,
      "handle-type");

  /**
   * TpDynamicHandleRepo:normalize-function:
   *
   * An optional #TpDynamicHandleRepoNormalizeFunc used to validate and
   * normalize handle IDs. If %NULL (which is the default), any handle ID is
   * accepted as-is (equivalent to supplying a pointer to a function that just
   * calls g_strdup).
   */
  param_spec = g_param_spec_pointer ("normalize-function",
      "Normalization function",
      "A TpDynamicHandleRepoNormalizeFunc used to normalize handle IDs.",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_NORMALIZE_FUNCTION,
      param_spec);

  /**
   * TpDynamicHandleRepo:default-normalize-context:
   *
   * An optional default context given to the
   * #TpDynamicHandleRepo:normalize-function if %NULL is passed as context to
   * the ensure or lookup functions, e.g. when RequestHandle is called via
   * D-Bus. The default is %NULL.
   */
  param_spec = g_param_spec_pointer ("default-normalize-context",
      "Default normalization context",
      "The default context given to the normalize-function if NULL is passed "
      "as context to the ensure or lookup function, e.g. when RequestHandle"
      "is called via D-Bus. The default is NULL.",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_DEFAULT_NORMALIZE_CONTEXT, param_spec);
}

static gboolean
dynamic_handle_is_valid (TpHandleRepoIface *irepo,
    TpHandle handle,
    GError **error)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (irepo);

  if (handle_priv_lookup (self, handle) == NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_HANDLE,
          "handle %u is not currently a valid %s handle (type %u)",
          handle, tp_handle_type_to_string (self->handle_type),
          self->handle_type);
      return FALSE;
    }
  else
    {
      return TRUE;
    }
}

static gboolean
dynamic_handles_are_valid (TpHandleRepoIface *irepo,
    const GArray *handles,
    gboolean allow_zero,
    GError **error)
{
  guint i;

  g_return_val_if_fail (handles != NULL, FALSE);

  for (i = 0; i < handles->len; i++)
    {
      TpHandle handle = g_array_index (handles, TpHandle, i);

      if (handle == 0 && allow_zero)
        continue;

      if (!dynamic_handle_is_valid (irepo, handle, error))
        return FALSE;
    }

  return TRUE;
}

static void
dynamic_unref_handle (TpHandleRepoIface *repo G_GNUC_UNUSED,
    TpHandle handle G_GNUC_UNUSED)
{
}

static TpHandle
dynamic_ref_handle (TpHandleRepoIface *repo G_GNUC_UNUSED,
    TpHandle handle)
{
  return handle;
}

static gboolean
dynamic_client_hold_handle (TpHandleRepoIface *repo G_GNUC_UNUSED,
    const gchar *client_name G_GNUC_UNUSED,
    TpHandle handle G_GNUC_UNUSED,
    GError **error G_GNUC_UNUSED)
{
  return TRUE;
}

static gboolean
dynamic_client_release_handle (TpHandleRepoIface *repo G_GNUC_UNUSED,
    const gchar *client_name G_GNUC_UNUSED,
    TpHandle handle G_GNUC_UNUSED,
    GError **error G_GNUC_UNUSED)
{
  return TRUE;
}

static const char *
dynamic_inspect_handle (TpHandleRepoIface *irepo,
    TpHandle handle)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (irepo);
  TpHandlePriv *priv = handle_priv_lookup (self, handle);

  if (priv == NULL)
    return NULL;
  else
    return priv->string;
}

/**
 * tp_dynamic_handle_repo_lookup_exact:
 * @irepo: The handle repository
 * @id: The name to be looked up
 *
 * Look up a name in the repository, returning the corresponding handle if
 * it is present in the repository, without creating a new reference.
 *
 * Unlike tp_handle_lookup() this function does not perform any normalization;
 * it just looks for the literal string you requested. This can be useful to
 * call from normalization callbacks (for instance, Gabble's contacts
 * repository uses it to see whether we already know that a JID belongs
 * to a multi-user chat room member).
 *
 * Returns: the handle corresponding to the given ID, or 0 if not present
 */
TpHandle
tp_dynamic_handle_repo_lookup_exact (TpHandleRepoIface *irepo,
    const char *id)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (irepo);

  return GPOINTER_TO_UINT (g_hash_table_lookup (self->string_to_handle, id));
}

static TpHandle
dynamic_lookup_handle (TpHandleRepoIface *irepo,
    const char *id,
    gpointer context,
    GError **error)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (irepo);
  TpHandle handle;
  gchar *normal_id = NULL;

  if (context == NULL)
    context = self->default_normalize_context;

  if (self->normalize_function)
    {
      normal_id = (self->normalize_function) (irepo, id, context, error);
      if (normal_id == NULL)
        return 0;
      id = normal_id;
    }

  handle = GPOINTER_TO_UINT (g_hash_table_lookup (self->string_to_handle, id));

  if (handle == 0)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "no %s handle (type %u) currently exists for ID \"%s\"",
          tp_handle_type_to_string (self->handle_type),
          self->handle_type, id);
    }

  g_free (normal_id);
  return handle;
}

static TpHandle
ensure_handle_take_normalized_id (TpDynamicHandleRepo *self,
    gchar *normal_id)
{
  TpHandle handle;
  TpHandlePriv *priv;

  handle = GPOINTER_TO_UINT (g_hash_table_lookup (self->string_to_handle,
      normal_id));

  if (handle != 0)
    {
      g_free (normal_id);
      return handle;
    }

  handle = self->handle_to_priv->len;
  g_array_append_val (self->handle_to_priv, empty_priv);
  priv = &g_array_index (self->handle_to_priv, TpHandlePriv, handle);

  handle_priv_init_take_string (priv, normal_id);
  g_hash_table_insert (self->string_to_handle, priv->string,
      GUINT_TO_POINTER (handle));

  return handle;
}

static TpHandle
dynamic_ensure_handle (TpHandleRepoIface *irepo,
    const char *id,
    gpointer context,
    GError **error)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (irepo);
  gchar *normal_id;

  if (context == NULL)
    context = self->default_normalize_context;

  if (self->normalize_function)
    {
      normal_id = (self->normalize_function) (irepo, id, context, error);
      if (normal_id == NULL)
        return 0;
    }
  else
    {
      normal_id = g_strdup (id);
    }

  return ensure_handle_take_normalized_id (self, normal_id);
}

static void
normalize_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpDynamicHandleRepo *self = (TpDynamicHandleRepo *) source;
  TpHandleRepoIface *repo = (TpHandleRepoIface *) self;
  GSimpleAsyncResult *my_result = user_data;
  gchar *normal_id;
  GError *error = NULL;

  normal_id = self->normalize_finish (repo, result, &error);
  if (normal_id == NULL)
    {
      g_simple_async_result_take_error (my_result, error);
    }
  else
    {
      TpHandle handle;

      handle = ensure_handle_take_normalized_id (self, normal_id);
      g_simple_async_result_set_op_res_gpointer (my_result,
          GUINT_TO_POINTER (handle), NULL);
    }

  g_simple_async_result_complete (my_result);
  g_object_unref (my_result);
}

static void
dynamic_ensure_handle_async (TpHandleRepoIface *repo,
    TpBaseConnection *connection,
    const gchar *id,
    gpointer context,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (repo);
  GSimpleAsyncResult *result;

  if (self->normalize_async == NULL)
    {
      TpHandleRepoIfaceClass *klass;

      /* Fallback to default implementation */
      klass = g_type_default_interface_peek (TP_TYPE_HANDLE_REPO_IFACE);
      klass->ensure_handle_async (repo, connection, id,
          context, callback, user_data);
      return;
    }

  if (context == NULL)
    context = self->default_normalize_context;

  result = g_simple_async_result_new (G_OBJECT (repo), callback, user_data,
      dynamic_ensure_handle_async);

  self->normalize_async (repo, connection, id, context, normalize_cb, result);
}

static void
dynamic_set_qdata (TpHandleRepoIface *repo, TpHandle handle,
    GQuark key_id, gpointer data, GDestroyNotify destroy)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (repo);
  TpHandlePriv *priv = handle_priv_lookup (self, handle);

  g_return_if_fail (((void)"invalid handle", priv != NULL));

  g_datalist_id_set_data_full (&priv->datalist, key_id, data, destroy);
}

static gpointer
dynamic_get_qdata (TpHandleRepoIface *repo, TpHandle handle,
    GQuark key_id)
{
  TpDynamicHandleRepo *self = TP_DYNAMIC_HANDLE_REPO (repo);
  TpHandlePriv *priv = handle_priv_lookup (self, handle);

  g_return_val_if_fail (((void)"invalid handle", priv != NULL), NULL);

  return g_datalist_id_get_data (&priv->datalist, key_id);
}

static void
dynamic_repo_iface_init (gpointer g_iface,
    gpointer iface_data)
{
  TpHandleRepoIfaceClass *klass = (TpHandleRepoIfaceClass *) g_iface;

  klass->handle_is_valid = dynamic_handle_is_valid;
  klass->handles_are_valid = dynamic_handles_are_valid;
  klass->ref_handle = dynamic_ref_handle;
  klass->unref_handle = dynamic_unref_handle;
  klass->client_hold_handle = dynamic_client_hold_handle;
  klass->client_release_handle = dynamic_client_release_handle;
  klass->inspect_handle = dynamic_inspect_handle;
  klass->lookup_handle = dynamic_lookup_handle;
  klass->ensure_handle = dynamic_ensure_handle;
  klass->ensure_handle_async = dynamic_ensure_handle_async;
  klass->set_qdata = dynamic_set_qdata;
  klass->get_qdata = dynamic_get_qdata;
}

/*
 * _tp_dynamic_handle_repo_set_normalization_data:
 * @irepo: (type TelepathyGLib.DynamicHandleRepo): a #TpDynamicHandleRepo
 *
 * Get the normalization data set with
 * _tp_dynamic_handle_repo_set_normalization_data().
 *
 * Returns: (transfer none): the data
 */
gpointer
_tp_dynamic_handle_repo_get_normalization_data (
    TpHandleRepoIface *irepo)
{
  TpDynamicHandleRepo *self = (TpDynamicHandleRepo *) irepo;

  g_return_val_if_fail (TP_IS_DYNAMIC_HANDLE_REPO (self), NULL);

  return self->normalization_data;
}

/*
 * _tp_dynamic_handle_repo_set_normalization_data:
 * @irepo: (type TelepathyGLib.DynamicHandleRepo): a #TpDynamicHandleRepo
 * @data: (allow-none): data to use during normalization
 * @destroy: (allow-none): destructor for @data, or %NULL
 *
 * Attach extra data to a handle repository which can be used during
 * handle normalization. For instance, this could be a weak reference to
 * the #TpBaseConnection or a #TpChannelManager.
 *
 * The normalization function can retrieve that data using
 * _tp_dynamic_handle_repo_get_normalization_data().
 */
void
_tp_dynamic_handle_repo_set_normalization_data (TpHandleRepoIface *irepo,
    gpointer data,
    GDestroyNotify destroy)
{
  TpDynamicHandleRepo *self = (TpDynamicHandleRepo *) irepo;

  g_return_if_fail (TP_IS_DYNAMIC_HANDLE_REPO (self));

  if (self->free_normalization_data != NULL)
    self->free_normalization_data (self->normalization_data);

  self->normalization_data = data;
  self->free_normalization_data = destroy;
}

/**
 * tp_dynamic_handle_repo_set_normalize_async:
 * @self: A #TpDynamicHandleRepo
 * @normalize_async: a #TpDynamicHandleRepoNormalizeAsync
 * @normalize_finish: a #TpDynamicHandleRepoNormalizeFinish
 *
 * Set an asynchronous normalization function. This is to be used if handle
 * normalization requires a server round-trip. See tp_handle_ensure_async().
 *
 * Since: 0.19.2
 */
void
tp_dynamic_handle_repo_set_normalize_async (TpDynamicHandleRepo *self,
    TpDynamicHandleRepoNormalizeAsync normalize_async,
    TpDynamicHandleRepoNormalizeFinish normalize_finish)
{
  g_return_if_fail (TP_IS_DYNAMIC_HANDLE_REPO (self));
  g_return_if_fail (normalize_async != NULL);
  g_return_if_fail (normalize_finish != NULL);

  self->normalize_async = normalize_async;
  self->normalize_finish = normalize_finish;
}
