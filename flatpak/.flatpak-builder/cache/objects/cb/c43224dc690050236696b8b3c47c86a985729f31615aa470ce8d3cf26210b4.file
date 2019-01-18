/*
 * base-connection-manager.c - Source for TpBaseConnectionManager
 *
 * Copyright (C) 2007-2009 Collabora Ltd.
 * Copyright (C) 2007-2009 Nokia Corporation
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
 * SECTION:base-connection-manager
 * @title: TpBaseConnectionManager
 * @short_description: base class for #TpSvcConnectionManager implementations
 * @see_also: #TpBaseConnection, #TpSvcConnectionManager, #run
 *
 * This base class makes it easier to write #TpSvcConnectionManager
 * implementations by managing the D-Bus object path and bus name,
 * and maintaining a table of active connections. Subclasses should usually
 * only need to override the members of the class data structure.
 */

#include "config.h"

#include <telepathy-glib/base-connection-manager.h>

#include <string.h>

#include <dbus/dbus-protocol.h>

#include <telepathy-glib/telepathy-glib.h>

#define DEBUG_FLAG TP_DEBUG_PARAMS
#include "telepathy-glib/base-protocol-internal.h"
#include "telepathy-glib/debug-internal.h"

/**
 * TpCMProtocolSpec:
 * @name: The name which should be passed to RequestConnection for this
 *        protocol.
 * @parameters: An array of #TpCMParamSpec representing the valid parameters
 *              for this protocol, terminated by a #TpCMParamSpec whose name
 *              entry is NULL.
 * @params_new: A function which allocates an opaque data structure to store
 *              the parsed parameters for this protocol. The offset fields
 *              in the members of the @parameters array refer to offsets
 *              within this opaque structure.
 * @params_free: A function which deallocates the opaque data structure
 *               provided by #params_new, including deallocating its
 *               data members (currently, only strings) if necessary.
 * @set_param: A function which sets a parameter within the opaque data
 *             structure provided by #params_new. If %NULL,
 *             tp_cm_param_setter_offset() will be used. (New in 0.7.0 -
 *             previously, code equivalent to tp_cm_param_setter_offset() was
 *             always used.)
 *
 * Structure representing a connection manager protocol.
 *
 * In addition to the fields documented here, there are three gpointer fields
 * which must currently be %NULL. A meaning may be defined for these in a
 * future version of telepathy-glib.
 */

/*
 * _TpLegacyProtocol:
 *
 * A limited implementation of TpProtocol, in terms of the ConnectionManager
 * API from telepathy-spec 0.18.
 */
typedef struct {
    TpBaseProtocol parent;
    /* Really a TpBaseConnectionManager, but using that type with
     * g_object_add_weak_pointer violates strict aliasing */
    gpointer cm;
    const TpCMProtocolSpec *protocol_spec;
} _TpLegacyProtocol;

typedef struct {
    TpBaseProtocolClass parent;
} _TpLegacyProtocolClass;

#define _TP_TYPE_LEGACY_PROTOCOL (_tp_legacy_protocol_get_type ())
GType _tp_legacy_protocol_get_type (void) G_GNUC_CONST;

G_DEFINE_TYPE(_TpLegacyProtocol,
    _tp_legacy_protocol,
    TP_TYPE_BASE_PROTOCOL)

static const TpCMParamSpec *
_tp_legacy_protocol_get_parameters (TpBaseProtocol *protocol)
{
  _TpLegacyProtocol *self = (_TpLegacyProtocol *) protocol;

  return self->protocol_spec->parameters;
}

static gboolean parse_parameters (const TpCMParamSpec *paramspec,
    GHashTable *provided, TpIntset *params_present,
    const TpCMParamSetter set_param, void *params, GError **error);

static TpBaseConnection *
_tp_legacy_protocol_new_connection (TpBaseProtocol *protocol,
    GHashTable *asv,
    GError **error)
{
  _TpLegacyProtocol *self = (_TpLegacyProtocol *) protocol;
  const TpCMProtocolSpec *protospec = self->protocol_spec;
  TpBaseConnectionManagerClass *cls;
  TpBaseConnection *conn = NULL;
  void *params = NULL;
  TpIntset *params_present = NULL;
  TpCMParamSetter set_param;

  if (self->cm == NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Connection manager no longer available");
      return NULL;
    }

  g_object_ref (self->cm);

  g_assert (protospec->parameters != NULL);
  g_assert (protospec->params_new != NULL);
  g_assert (protospec->params_free != NULL);

  cls = TP_BASE_CONNECTION_MANAGER_GET_CLASS (self->cm);

  params_present = tp_intset_new ();
  params = protospec->params_new ();

  set_param = protospec->set_param;

  if (set_param == NULL)
    set_param = tp_cm_param_setter_offset;

  if (!parse_parameters (protospec->parameters, (GHashTable *) asv,
        params_present, set_param, params, error))
    {
      goto finally;
    }

  conn = (cls->new_connection) (self->cm, protospec->name, params_present,
      params, error);

finally:
  if (params_present != NULL)
    tp_intset_destroy (params_present);

  if (params != NULL)
    protospec->params_free (params);

  g_object_unref (self->cm);

  return conn;
}

static void
_tp_legacy_protocol_class_init (_TpLegacyProtocolClass *cls)
{
  TpBaseProtocolClass *base_class = (TpBaseProtocolClass *) cls;

  base_class->is_stub = TRUE;
  base_class->get_parameters = _tp_legacy_protocol_get_parameters;
  base_class->new_connection = _tp_legacy_protocol_new_connection;
}

static void
_tp_legacy_protocol_init (_TpLegacyProtocol *self)
{
}

static TpBaseProtocol *
_tp_legacy_protocol_new (TpBaseConnectionManager *cm,
    const TpCMProtocolSpec *protocol_spec)
{
  _TpLegacyProtocol *self = g_object_new (_TP_TYPE_LEGACY_PROTOCOL,
      "name", protocol_spec->name,
      NULL);

  self->protocol_spec = protocol_spec;
  self->cm = cm;
  g_object_add_weak_pointer ((GObject *) cm, &(self->cm));
  return (TpBaseProtocol *) self;
}

/**
 * TpBaseConnectionManager:
 *
 * A base class for connection managers. There are no interesting public
 * fields in the instance structure.
 */

/**
 * TpBaseConnectionManagerClass:
 * @parent_class: The parent class
 * @cm_dbus_name: The name of this connection manager, as used to construct
 *  D-Bus object paths and bus names. Must contain only letters, digits
 *  and underscores, and may not start with a digit. Must be filled in by
 *  subclasses in their class_init function.
 * @get_interfaces: Returns a #GPtrArray of static strings of extra
 *  D-Bus interfaces implemented by instances of this class, which may be
 *  filled in by subclasses. The default is to list no additional interfaces.
 *  Implementations must first chainup on parent class implementation and then
 *  add extra interfaces to the #GPtrArray. Replaces @interfaces. Since:
 *  0.19.4
 *
 * The class structure for #TpBaseConnectionManager.
 *
 * In addition to the fields documented here, there are some gpointer fields
 * which must currently be %NULL (a meaning may be defined for these in a
 * future version of telepathy-glib).
 *
 * Changed in 0.7.1: it is a fatal error for @cm_dbus_name not to conform to
 * the specification.
 *
 * Changed in 0.11.11: protocol_params and new_connection may both be
 * %NULL. If so, this connection manager is assumed to use Protocol objects
 * instead. Since 0.19.2 those fields are deprecated and should not be
 * used anymore.
 */

/**
 * TpBaseConnectionManagerNewConnFunc:
 * @self: The connection manager implementation
 * @proto: The protocol name from the D-Bus request
 * @params_present: A set of integers representing the indexes into the
 *                  array of #TpCMParamSpec of those parameters that were
 *                  present in the request
 * @parsed_params: An opaque data structure as returned by the protocol's
 *                 params_new function, populated according to the
 *                 parameter specifications
 * @error: if not %NULL, used to indicate the error if %NULL is returned
 *
 * A function that will return a new connection according to the
 * parsed parameters; used to implement RequestConnection.
 *
 * The connection manager base class will register the bus name for the
 * new connection, and place a reference to it in its table of
 * connections until the connection's shutdown process finishes.
 *
 * Returns: the new connection object, or %NULL on error.
 */

/**
 * TpBaseConnectionManagerGetInterfacesFunc:
 * @self: a #TpBaseConnectionManager
 *
 * Signature of an implementation of
 * #TpBaseConnectionManagerClass.get_interfaces virtual function.
 *
 * Implementation must first chainup on parent class implementation and then
 * add extra interfaces into the #GPtrArray.
 *
 * |[
 * static GPtrArray *
 * my_connection_manager_get_interfaces (TpBaseConnectionManager *self)
 * {
 *   GPtrArray *interfaces;
 *
 *   interfaces = TP_BASE_CONNECTION_MANAGER_CLASS (
 *       my_connection_manager_parent_class)->get_interfaces (self);
 *
 *   g_ptr_array_add (interfaces, TP_IFACE_BADGERS);
 *
 *   return interfaces;
 * }
 * ]|
 *
 * Returns: (transfer container): a #GPtrArray of static strings for D-Bus
 *   interfaces implemented by this client.
 *
 * Since: 0.19.4
 */

static void service_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE(TpBaseConnectionManager,
    tp_base_connection_manager,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
      tp_dbus_properties_mixin_iface_init);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CONNECTION_MANAGER,
        service_iface_init))

struct _TpBaseConnectionManagerPrivate
{
  /* if TRUE, the object has gone away */
  gboolean dispose_has_run;
  /* used as a set: key is TpBaseConnection *, value is TRUE */
  GHashTable *connections;
  /* true after tp_base_connection_manager_register is called */
  gboolean registered;
   /* dup'd string => ref to TpBaseProtocol */
  GHashTable *protocols;

  TpDBusDaemon *dbus_daemon;
};

enum
{
    PROP_DBUS_DAEMON = 1,
    PROP_INTERFACES,
    PROP_PROTOCOLS,
    N_PROPS
};

enum
{
    NO_MORE_CONNECTIONS,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};

static void
tp_base_connection_manager_dispose (GObject *object)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (object);
  TpBaseConnectionManagerPrivate *priv = self->priv;
  GObjectFinalizeFunc dispose =
    G_OBJECT_CLASS (tp_base_connection_manager_parent_class)->dispose;

  if (priv->dispose_has_run)
    return;

  priv->dispose_has_run = TRUE;

  if (priv->dbus_daemon != NULL)
    {
      g_object_unref (priv->dbus_daemon);
      priv->dbus_daemon = NULL;
    }

  if (priv->protocols != NULL)
    {
      g_hash_table_unref (priv->protocols);
      priv->protocols = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
tp_base_connection_manager_finalize (GObject *object)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (object);
  TpBaseConnectionManagerPrivate *priv = self->priv;

  g_hash_table_unref (priv->connections);

  G_OBJECT_CLASS (tp_base_connection_manager_parent_class)->finalize (object);
}

static gboolean
tp_base_connection_manager_ensure_dbus (TpBaseConnectionManager *self,
    GError **error)
{
  if (self->priv->dbus_daemon == NULL)
    {
      self->priv->dbus_daemon = tp_dbus_daemon_dup (error);

      if (self->priv->dbus_daemon == NULL)
        return FALSE;
    }

  return TRUE;
}

static GObject *
tp_base_connection_manager_constructor (GType type,
                                        guint n_params,
                                        GObjectConstructParam *params)
{
  GObjectClass *object_class =
      (GObjectClass *) tp_base_connection_manager_parent_class;
  TpBaseConnectionManager *self =
      TP_BASE_CONNECTION_MANAGER (object_class->constructor (type, n_params,
            params));
  TpBaseConnectionManagerClass *cls =
      TP_BASE_CONNECTION_MANAGER_GET_CLASS (self);
  GError *error = NULL;

  g_assert (tp_connection_manager_check_valid_name (cls->cm_dbus_name, NULL));

  /* if one of these is NULL, the other must be too */
  g_assert (cls->new_connection == NULL || cls->protocol_params != NULL);
  g_assert (cls->protocol_params == NULL || cls->new_connection != NULL);

  if (!tp_base_connection_manager_ensure_dbus (self, &error))
    {
      WARNING ("%s", error->message);
      g_error_free (error);
    }

  return (GObject *) self;
}

static void
tp_base_connection_manager_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (object);
  TpBaseConnectionManagerClass *cls = TP_BASE_CONNECTION_MANAGER_GET_CLASS (
      object);

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
      g_value_set_object (value, self->priv->dbus_daemon);
      break;

    case PROP_INTERFACES:
      {
        GPtrArray *interfaces = cls->get_interfaces (self);

        /* make sure there's a terminating NULL */
        g_ptr_array_add (interfaces, NULL);
        g_value_set_boxed (value, interfaces->pdata);

        g_ptr_array_unref (interfaces);
      }
      break;

    case PROP_PROTOCOLS:
        {
          GHashTable *map = g_hash_table_new_full (g_str_hash, g_str_equal,
              g_free, (GDestroyNotify) g_hash_table_unref);
          GHashTableIter iter;
          gpointer name, protocol;

          g_hash_table_iter_init (&iter, self->priv->protocols);

          while (g_hash_table_iter_next (&iter, &name, &protocol))
            {
              GHashTable *props;

              g_object_get (protocol,
                  "immutable-properties", &props,
                  NULL);

              g_hash_table_insert (map, g_strdup (name), props);
            }

          g_value_take_boxed (value, map);
        }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
tp_base_connection_manager_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (object);

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
        {
          TpDBusDaemon *dbus_daemon = g_value_get_object (value);

          g_assert (self->priv->dbus_daemon == NULL);     /* construct-only */

          if (dbus_daemon != NULL)
            self->priv->dbus_daemon = g_object_ref (dbus_daemon);
        }
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static GPtrArray *
tp_base_connection_manager_get_interfaces (TpBaseConnectionManager *self)
{
  GPtrArray *interfaces = g_ptr_array_new ();
  const char * const *ptr;

  /* copy the klass->interfaces property for backwards compatibility */
  for (ptr = TP_BASE_CONNECTION_MANAGER_GET_CLASS (self)->interfaces;
       ptr != NULL && *ptr != NULL;
       ptr++)
    {
      g_ptr_array_add (interfaces, (char *) *ptr);
    }

  return interfaces;
}

static void
tp_base_connection_manager_class_init (TpBaseConnectionManagerClass *klass)
{
  static TpDBusPropertiesMixinPropImpl cm_properties[] = {
      { "Protocols", "protocols", NULL },
      { "Interfaces", "interfaces", NULL },
      { NULL }
  };
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (TpBaseConnectionManagerPrivate));
  object_class->constructor = tp_base_connection_manager_constructor;
  object_class->get_property = tp_base_connection_manager_get_property;
  object_class->set_property = tp_base_connection_manager_set_property;
  object_class->dispose = tp_base_connection_manager_dispose;
  object_class->finalize = tp_base_connection_manager_finalize;

  klass->get_interfaces = tp_base_connection_manager_get_interfaces;

  /**
   * TpBaseConnectionManager:dbus-daemon:
   *
   * #TpDBusDaemon object encapsulating this object's connection to D-Bus.
   * Read-only except during construction.
   *
   * If this property is %NULL or omitted during construction, the object will
   * automatically attempt to connect to the starter or session bus with
   * tp_dbus_daemon_dup() just after it is constructed; if this fails, a
   * warning will be logged with g_warning(), and this property will remain
   * %NULL.
   *
   * Since: 0.11.3
   */
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON,
      g_param_spec_object ("dbus-daemon", "D-Bus daemon",
        "The D-Bus daemon used by this object", TP_TYPE_DBUS_DAEMON,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * TpBaseConnectionManager:interfaces:
   *
   * The set of D-Bus interfaces available on this ConnectionManager, other
   * than ConnectionManager itself.
   *
   * Since: 0.11.11
   */
  g_object_class_install_property (object_class, PROP_INTERFACES,
      g_param_spec_boxed ("interfaces",
        "ConnectionManager.Interfaces",
        "The set of D-Bus interfaces available on this ConnectionManager, "
        "other than ConnectionManager itself",
        G_TYPE_STRV, G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));

  /**
   * TpBaseConnectionManager:protocols:
   *
   * The Protocol objects available on this ConnectionManager.
   *
   * Since: 0.11.11
   */
  g_object_class_install_property (object_class, PROP_PROTOCOLS,
      g_param_spec_boxed ("protocols",
        "ConnectionManager.Protocols",
        "The set of protocols available on this Connection, other than "
        "ConnectionManager itself",
        TP_HASH_TYPE_PROTOCOL_PROPERTIES_MAP,
        G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));

  /**
   * TpBaseConnectionManager::no-more-connections:
   *
   * Emitted when the table of active connections becomes empty.
   * tp_run_connection_manager() uses this to detect when to shut down the
   * connection manager.
   */
  signals[NO_MORE_CONNECTIONS] =
    g_signal_new ("no-more-connections",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE, 0);

  tp_dbus_properties_mixin_class_init (object_class, 0);
  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CONNECTION_MANAGER,
      tp_dbus_properties_mixin_getter_gobject_properties, NULL,
      cm_properties);
}

static void
tp_base_connection_manager_init (TpBaseConnectionManager *self)
{
  TpBaseConnectionManagerPrivate *priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_CONNECTION_MANAGER, TpBaseConnectionManagerPrivate);

  self->priv = priv;

  priv->connections = g_hash_table_new (g_direct_hash, g_direct_equal);
  priv->protocols = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, g_object_unref);
}

/**
 * connection_shutdown_finished_cb:
 * @conn: #TpBaseConnection
 * @data: data passed in callback
 *
 * Signal handler called when a connection object disconnects.
 * When they become disconnected, we can unref and discard
 * them, and they will disappear from the bus.
 */
static void
connection_shutdown_finished_cb (TpBaseConnection *conn,
                                 gpointer data)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (data);
  TpBaseConnectionManagerPrivate *priv = self->priv;

  /* temporary ref, because disconnecting this signal handler might release
   * the last ref */
  g_object_ref (self);

  g_assert (g_hash_table_lookup (priv->connections, conn));
  g_hash_table_remove (priv->connections, conn);

  DEBUG ("dereferenced connection");
  if (g_hash_table_size (priv->connections) == 0)
    {
      g_signal_emit (self, signals[NO_MORE_CONNECTIONS], 0);
    }

  g_signal_handlers_disconnect_by_func (conn,
      connection_shutdown_finished_cb, data);

  g_object_unref (conn);
  g_object_unref (self);
}

/* Parameter parsing */

static TpBaseProtocol *
tp_base_connection_manager_get_protocol (TpBaseConnectionManager *self,
    const gchar *protocol_name,
    GError **error)
{
  TpBaseProtocol *protocol = g_hash_table_lookup (self->priv->protocols,
      protocol_name);

  if (protocol != NULL)
    return protocol;

  g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
      "unknown protocol %s", protocol_name);

  return NULL;
}

/**
 * tp_cm_param_setter_offset:
 * @paramspec: A parameter specification with offset set to some
 *  meaningful value.
 * @value: The value for that parameter, either provided by the user or
 *  constructed from the parameter's default.
 * @params: An opaque data structure such that the address at (@params +
 *  @paramspec->offset) is a valid pointer to a variable of the
 *  appropriate type.
 *
 * A #TpCMParamSetter which sets parameters by dereferencing an offset
 * from @params.  If @paramspec->offset is G_MAXSIZE, the parameter is
 * deemed obsolete, and is accepted but ignored.
 *
 * Since: 0.7.0
 */
void
tp_cm_param_setter_offset (const TpCMParamSpec *paramspec,
                           const GValue *value,
                           gpointer params)
{
  char *params_mem = params;

  if (paramspec->offset == G_MAXSIZE)
    {
      /* quietly ignore any obsolete params provided */
      return;
    }

  switch (paramspec->dtype[0])
    {
      case DBUS_TYPE_STRING:
        {
          gchar **save_to = (gchar **) (params_mem + paramspec->offset);
          const gchar *str;

          g_assert (paramspec->gtype == G_TYPE_STRING);
          str = g_value_get_string (value);
          g_free (*save_to);
          if (str == NULL)
            {
              *save_to = g_strdup ("");
            }
          else
            {
              *save_to = g_value_dup_string (value);
            }
          if (DEBUGGING)
            {
              if (strstr (paramspec->name, "password") != NULL)
                DEBUG ("%s = <hidden>", paramspec->name);
              else
                DEBUG ("%s = \"%s\"", paramspec->name, *save_to);
            }
        }
        break;

      case DBUS_TYPE_INT16:
      case DBUS_TYPE_INT32:
        {
          gint *save_to = (gint *) (params_mem + paramspec->offset);
          gint i = g_value_get_int (value);

          g_assert (paramspec->gtype == G_TYPE_INT);
          *save_to = i;
          DEBUG ("%s = %d = 0x%x", paramspec->name, i, i);
        }
        break;

      case DBUS_TYPE_UINT16:
      case DBUS_TYPE_UINT32:
        {
          guint *save_to = (guint *) (params_mem + paramspec->offset);
          guint i = g_value_get_uint (value);

          g_assert (paramspec->gtype == G_TYPE_UINT);
          *save_to = i;
          DEBUG ("%s = %u = 0x%x", paramspec->name, i, i);
        }
        break;

      case DBUS_TYPE_INT64:
        {
          gint64 *save_to = (gint64 *) (params_mem + paramspec->offset);
          gint64 i = g_value_get_int64 (value);

          g_assert (paramspec->gtype == G_TYPE_INT64);
          *save_to = i;
          DEBUG ("%s = %" G_GINT64_FORMAT, paramspec->name, i);
        }
        break;

      case DBUS_TYPE_UINT64:
        {
          guint64 *save_to = (guint64 *) (params_mem + paramspec->offset);
          guint64 i = g_value_get_uint64 (value);

          g_assert (paramspec->gtype == G_TYPE_UINT64);
          *save_to = i;
          DEBUG ("%s = %" G_GUINT64_FORMAT, paramspec->name, i);
        }
        break;

      case DBUS_TYPE_DOUBLE:
        {
          gdouble *save_to = (gdouble *) (params_mem + paramspec->offset);
          gdouble i = g_value_get_double (value);

          g_assert (paramspec->gtype == G_TYPE_DOUBLE);
          *save_to = i;
          DEBUG ("%s = %f", paramspec->name, i);
        }
        break;

      case DBUS_TYPE_OBJECT_PATH:
        {
          gchar **save_to = (gchar **) (params_mem + paramspec->offset);

          g_assert (paramspec->gtype == DBUS_TYPE_G_OBJECT_PATH);
          g_free (*save_to);

          *save_to = g_value_dup_boxed (value);
          DEBUG ("%s = \"%s\"", paramspec->name, *save_to);
        }
        break;

      case DBUS_TYPE_BOOLEAN:
        {
          gboolean *save_to = (gboolean *) (params_mem + paramspec->offset);
          gboolean b = g_value_get_boolean (value);

          g_assert (paramspec->gtype == G_TYPE_BOOLEAN);
          g_assert (b == TRUE || b == FALSE);
          *save_to = b;
          DEBUG ("%s = %s", paramspec->name, b ? "TRUE" : "FALSE");
        }
        break;

      case DBUS_TYPE_ARRAY:
        switch (paramspec->dtype[1])
          {
            case DBUS_TYPE_STRING:
              {
                GStrv *save_to = (GStrv *) (params_mem + paramspec->offset);

                g_strfreev (*save_to);
                *save_to = g_value_dup_boxed (value);

                if (DEBUGGING)
                  {
                    gchar *joined = g_strjoinv (", ", *save_to);

                    DEBUG ("%s = [%s]", paramspec->name, joined);
                    g_free (joined);
                  }
              }
              break;

            case DBUS_TYPE_BYTE:
              {
                GArray **save_to = (GArray **) (params_mem + paramspec->offset);

                if (*save_to != NULL)
                  {
                    g_array_unref (*save_to);
                  }
                *save_to = g_value_dup_boxed (value);
                DEBUG ("%s = ...[%u]", paramspec->name, (*save_to)->len);
              }
              break;

            default:
              ERROR ("encountered unhandled D-Bus array type %s on "
                  "argument %s", paramspec->dtype, paramspec->name);
              g_assert_not_reached ();
          }
        break;

      default:
        ERROR ("encountered unhandled D-Bus type %s on argument %s",
            paramspec->dtype, paramspec->name);
        g_assert_not_reached ();
    }
}

static gboolean
set_param_from_value (const TpCMParamSpec *paramspec,
                      GValue *value,
                      const TpCMParamSetter set_param,
                      void *params,
                      GError **error)
{
  if (G_VALUE_TYPE (value) != paramspec->gtype)
    {
      DEBUG ("expected type %s for parameter %s, got %s",
               g_type_name (paramspec->gtype), paramspec->name,
               G_VALUE_TYPE_NAME (value));
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "expected type %s for account parameter %s, got %s",
          g_type_name (paramspec->gtype), paramspec->name,
          G_VALUE_TYPE_NAME (value));
      return FALSE;
    }

  set_param (paramspec, value, params);

  return TRUE;
}

static gboolean
parse_parameters (const TpCMParamSpec *paramspec,
                  GHashTable *provided,
                  TpIntset *params_present,
                  const TpCMParamSetter set_param,
                  void *params,
                  GError **error)
{
  int i;
  GValue *value;

  for (i = 0; paramspec[i].name; i++)
    {
      value = g_hash_table_lookup (provided, paramspec[i].name);

      if (value != NULL)
        {
          if (!set_param_from_value (&paramspec[i], value, set_param, params,
                error))
            {
              return FALSE;
            }

          tp_intset_add (params_present, i);

          g_hash_table_remove (provided, paramspec[i].name);
        }
    }

  return TRUE;
}


/*
 * tp_base_connection_manager_get_parameters:
 *
 * Implements D-Bus method GetParameters
 * on interface org.freedesktop.Telepathy.ConnectionManager
 */
static void
tp_base_connection_manager_get_parameters (TpSvcConnectionManager *iface,
                                           const gchar *proto,
                                           DBusGMethodInvocation *context)
{
  GPtrArray *ret;
  GError *error = NULL;
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (iface);
  guint i;
  TpBaseProtocol *protocol;
  const TpCMParamSpec *parameters;

  g_assert (TP_IS_BASE_CONNECTION_MANAGER (iface));
  /* a D-Bus method shouldn't be happening til we're on D-Bus */
  g_assert (self->priv->registered);

  protocol = tp_base_connection_manager_get_protocol (self, proto, &error);

  if (protocol == NULL)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  parameters = tp_base_protocol_get_parameters (protocol);
  g_assert (parameters != NULL);

  ret = g_ptr_array_new ();

  for (i = 0; parameters[i].name != NULL; i++)
    {
      g_ptr_array_add (ret,
          _tp_cm_param_spec_to_dbus (parameters + i));
    }

  tp_svc_connection_manager_return_from_get_parameters (context, ret);

  for (i = 0; i < ret->len; i++)
    {
      tp_value_array_free (g_ptr_array_index (ret, i));
    }

  g_ptr_array_unref (ret);
}


/*
 * tp_base_connection_manager_list_protocols:
 *
 * Implements D-Bus method ListProtocols
 * on interface org.freedesktop.Telepathy.ConnectionManager
 */
static void
tp_base_connection_manager_list_protocols (TpSvcConnectionManager *iface,
                                           DBusGMethodInvocation *context)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (iface);
  GPtrArray *protocols;
  GHashTableIter iter;
  gpointer name;

  /* a D-Bus method shouldn't be happening til we're on D-Bus */
  g_assert (self->priv->registered);

  protocols = g_ptr_array_sized_new (
      g_hash_table_size (self->priv->protocols) + 1);

  g_hash_table_iter_init (&iter, self->priv->protocols);

  while (g_hash_table_iter_next (&iter, &name, NULL))
    {
      g_ptr_array_add (protocols, name);
    }

  g_ptr_array_add (protocols, NULL);

  tp_svc_connection_manager_return_from_list_protocols (
      context, (const gchar **) protocols->pdata);
  g_ptr_array_unref (protocols);
}


/*
 * tp_base_connection_manager_request_connection:
 *
 * Implements D-Bus method RequestConnection
 * on interface org.freedesktop.Telepathy.ConnectionManager
 *
 * @error: Used to return a pointer to a GError detailing any error
 *         that occurred, D-Bus will throw the error only if this
 *         function returns FALSE.
 *
 * Returns: TRUE if successful, FALSE if an error was thrown.
 */
static void
tp_base_connection_manager_request_connection (TpSvcConnectionManager *iface,
                                               const gchar *proto,
                                               GHashTable *parameters,
                                               DBusGMethodInvocation *context)
{
  TpBaseConnectionManager *self = TP_BASE_CONNECTION_MANAGER (iface);
  TpBaseConnectionManagerClass *cls =
    TP_BASE_CONNECTION_MANAGER_GET_CLASS (self);
  TpBaseConnectionManagerPrivate *priv = self->priv;
  TpBaseConnection *conn;
  gchar *bus_name;
  gchar *object_path;
  GError *error = NULL;
  TpBaseProtocol *protocol;

  g_assert (TP_IS_BASE_CONNECTION_MANAGER (iface));

  /* a D-Bus method shouldn't be happening til we're on D-Bus */
  g_assert (self->priv->registered);

  if (!tp_connection_manager_check_valid_protocol_name (proto, &error))
    goto ERROR;

  protocol = tp_base_connection_manager_get_protocol (self, proto, &error);

  if (protocol == NULL)
    goto ERROR;

  conn = tp_base_protocol_new_connection (protocol, parameters, &error);

  if (conn == NULL)
    goto ERROR;

  /* register on bus and save bus name and object path */
  if (!tp_base_connection_register (conn, cls->cm_dbus_name,
        &bus_name, &object_path, &error))
    {
      DEBUG ("failed: %s", error->message);

      g_object_unref (G_OBJECT (conn));
      goto ERROR;
    }

  /* bind to status change signals from the connection object */
  g_signal_connect_data (conn, "shutdown-finished",
      G_CALLBACK (connection_shutdown_finished_cb),
      g_object_ref (self), (GClosureNotify) g_object_unref, 0);

  /* store the connection, using a hash table as a set */
  g_hash_table_insert (priv->connections, conn, GINT_TO_POINTER(TRUE));

  /* emit the new connection signal */
  tp_svc_connection_manager_emit_new_connection (
      self, bus_name, object_path, proto);

  tp_svc_connection_manager_return_from_request_connection (
      context, bus_name, object_path);

  g_free (bus_name);
  g_free (object_path);
  return;

ERROR:
  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

/**
 * tp_base_connection_manager_register:
 * @self: The connection manager implementation
 *
 * Register the connection manager with an appropriate object path as
 * determined from its @cm_dbus_name, and register the appropriate well-known
 * bus name.
 *
 * Returns: %TRUE on success, %FALSE (having emitted a warning to stderr)
 *          on failure
 */

gboolean
tp_base_connection_manager_register (TpBaseConnectionManager *self)
{
  GError *error = NULL;
  TpBaseConnectionManagerClass *cls;
  GString *string = NULL;
  guint i;
  GHashTableIter iter;
  gpointer name, protocol;

  g_assert (TP_IS_BASE_CONNECTION_MANAGER (self));
  cls = TP_BASE_CONNECTION_MANAGER_GET_CLASS (self);

  if (!tp_base_connection_manager_ensure_dbus (self, &error))
    goto except;

  if (cls->protocol_params != NULL)
    {
      for (i = 0; cls->protocol_params[i].name != NULL; i++)
        {
          TpBaseProtocol *p = _tp_legacy_protocol_new (self,
              cls->protocol_params + i);

          tp_base_connection_manager_add_protocol (self, p);
          g_object_unref (p);
        }
    }

  g_assert (self->priv->dbus_daemon != NULL);

  string = g_string_new (TP_CM_BUS_NAME_BASE);
  g_string_append (string, cls->cm_dbus_name);

  if (!tp_dbus_daemon_request_name (self->priv->dbus_daemon, string->str,
        TRUE, &error))
    goto except;

  g_string_assign (string, TP_CM_OBJECT_PATH_BASE);
  g_string_append (string, cls->cm_dbus_name);
  tp_dbus_daemon_register_object (self->priv->dbus_daemon, string->str, self);

  g_hash_table_iter_init (&iter, self->priv->protocols);

  while (g_hash_table_iter_next (&iter, &name, &protocol))
    {
      TpBaseProtocolClass *protocol_class =
        TP_BASE_PROTOCOL_GET_CLASS (protocol);

      if (!tp_connection_manager_check_valid_protocol_name (name, &error))
        {
          g_critical ("%s", error->message);
          goto except;
        }

      /* don't export uninformative "stub" protocol objects on D-Bus */
      if (protocol_class->is_stub)
        continue;

      g_string_assign (string, TP_CM_OBJECT_PATH_BASE);
      g_string_append (string, cls->cm_dbus_name);
      g_string_append_c (string, '/');
      g_string_append (string, name);

      g_strdelimit (string->str, "-", '_');

      tp_dbus_daemon_register_object (self->priv->dbus_daemon, string->str,
          protocol);
    }

  g_string_free (string, TRUE);

  self->priv->registered = TRUE;

  return TRUE;

except:
  WARNING ("Couldn't claim bus name. If you are trying to debug this "
      "connection manager, disable all accounts and kill any running "
      "copies of this CM, then try again. %s", error->message);
  g_error_free (error);

  if (string != NULL)
    g_string_free (string, TRUE);

  return FALSE;
}

static void
service_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcConnectionManagerClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_connection_manager_implement_##x (klass, \
    tp_base_connection_manager_##x)
  IMPLEMENT(get_parameters);
  IMPLEMENT(list_protocols);
  IMPLEMENT(request_connection);
#undef IMPLEMENT
}

/**
 * tp_base_connection_manager_get_dbus_daemon:
 * @self: the connection manager
 *
 * <!-- -->
 *
 * Returns: (transfer none): the value of the
 *  #TpBaseConnectionManager:dbus-daemon property. The caller must reference
 *  the returned object with g_object_ref() if it will be kept.
 *
 * Since: 0.11.3
 */
TpDBusDaemon *
tp_base_connection_manager_get_dbus_daemon (TpBaseConnectionManager *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION_MANAGER (self), NULL);

  return self->priv->dbus_daemon;
}

/**
 * tp_base_connection_manager_add_protocol:
 * @self: a connection manager object which has not yet registered on D-Bus
 *  (i.e. tp_base_connection_manager_register() must not have been called)
 * @protocol: a protocol object, which must not have the same protocol name as
 *  any that has already been added
 *
 * Add a protocol object to the set of supported protocols.
 */
void
tp_base_connection_manager_add_protocol (TpBaseConnectionManager *self,
    TpBaseProtocol *protocol)
{
  g_return_if_fail (TP_IS_BASE_CONNECTION_MANAGER (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (TP_IS_BASE_PROTOCOL (protocol));

  g_hash_table_insert (self->priv->protocols,
      g_strdup (tp_base_protocol_get_name (protocol)),
      g_object_ref (protocol));
}
