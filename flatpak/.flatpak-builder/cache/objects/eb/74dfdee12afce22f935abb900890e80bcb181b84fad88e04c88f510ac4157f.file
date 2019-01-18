/*
 * call-content-media-description.c - Source for TpyCallContentMediaDescription
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.com>
 * @author Olivier Crete <olivier.crete@collabora.com>
 * @author Xavier Claessens <xavier.claessens@collabora.co.uk>
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
 * SECTION:call-content-media-description
 * @title: TpCallContentMediaDescription
 * @short_description: implementation of #TpSvcCallContentMediaDescription
 * @see_also: #TpBaseMediaCallContent
 *
 * This class is used to negociate the media description used with a remote
 * contact. To be used with #TpBaseMediaCallContent implementations.
 *
 * Since: 0.17.5
 */

/**
 * TpCallContentMediaDescription:
 *
 * A class for media content description
 *
 * Since: 0.17.5
 */

/**
 * TpCallContentMediaDescriptionClass:
 *
 * The class structure for #TpCallContentMediaDescription
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "call-content-media-description.h"

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/handle.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/util.h"
#include "telepathy-glib/util-internal.h"

static void call_content_media_description_iface_init (gpointer iface,
    gpointer data);
static void call_content_media_description_extra_iface_init (gpointer iface,
    gpointer data);

G_DEFINE_TYPE_WITH_CODE(TpCallContentMediaDescription,
    tp_call_content_media_description,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION,
        call_content_media_description_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
        tp_dbus_properties_mixin_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTP_HEADER_EXTENSIONS,
        call_content_media_description_extra_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK,
        call_content_media_description_extra_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_EXTENDED_REPORTS,
        call_content_media_description_extra_iface_init);
  );

/* properties */
enum
{
  PROP_OBJECT_PATH = 1,
  PROP_DBUS_DAEMON,

  PROP_INTERFACES,
  PROP_FURTHER_NEGOTIATION_REQUIRED,
  PROP_HAS_REMOTE_INFORMATION,
  PROP_CODECS,
  PROP_REMOTE_CONTACT,
  PROP_SSRCS,

  PROP_HEADER_EXTENSIONS,

  PROP_FEEDBACK_MESSAGES,
  PROP_DOES_AVPF,

  PROP_LOSS_RLE_MAX_SIZE,
  PROP_DUPLICATE_RLE_MAX_SIZE,
  PROP_PACKET_RECEIPT_TIMES_MAX_SIZE,
  PROP_DLRR_MAX_SIZE,
  PROP_RTT_MODE,
  PROP_STATISTICS_FLAGS,
  PROP_ENABLE_METRICS,
};

/* private structure */
struct _TpCallContentMediaDescriptionPrivate
{
  TpDBusDaemon *dbus_daemon;
  gchar *object_path;

  /* GPtrArray of static strings, NULL-terminated */
  GPtrArray *interfaces;
  gboolean further_negotiation_required;
  gboolean has_remote_information;
  /* GPtrArray of owned GValueArray */
  GPtrArray *codecs;
  TpHandle remote_contact;
  /* TpHandle -> reffed GArray<uint> */
  GHashTable *ssrcs;

  /* GPtrArray of owned GValueArray (dbus-struct) */
  GPtrArray *header_extensions;
  GHashTable *feedback_messages;
  gboolean does_avpf;
  guint loss_rle_max_size;
  guint duplicate_rle_max_size;
  guint packet_receipt_times_max_size;
  guint dlrr_max_size;
  TpRCPTXRRTTMode rtt_mode;
  TpRTCPXRStatisticsFlags statistics_flags;
  gboolean enable_metrics;

  GSimpleAsyncResult *result;
  GCancellable *cancellable;
  guint handler_id;
};

static void
tp_call_content_media_description_init (TpCallContentMediaDescription *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_CALL_CONTENT_MEDIA_DESCRIPTION,
      TpCallContentMediaDescriptionPrivate);

  self->priv->interfaces = g_ptr_array_new ();
  g_ptr_array_add (self->priv->interfaces, NULL);

  self->priv->ssrcs = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify) g_array_unref);
  self->priv->codecs = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);

  self->priv->header_extensions = g_ptr_array_new_with_free_func (
      (GDestroyNotify) tp_value_array_free);
  self->priv->feedback_messages = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify) tp_value_array_free);
}

static void
tp_call_content_media_description_dispose (GObject *object)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) object;

  g_assert (self->priv->result == NULL);

  tp_clear_pointer (&self->priv->codecs, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->ssrcs, g_hash_table_unref);
  g_clear_object (&self->priv->dbus_daemon);

  tp_clear_pointer (&self->priv->header_extensions, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->feedback_messages, g_hash_table_unref);

  /* release any references held by the object here */
  if (G_OBJECT_CLASS (tp_call_content_media_description_parent_class)->dispose)
    G_OBJECT_CLASS (tp_call_content_media_description_parent_class)->dispose (
        object);
}

static void
tp_call_content_media_description_finalize (GObject *object)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) object;

  g_free (self->priv->object_path);
  g_ptr_array_unref (self->priv->interfaces);

  G_OBJECT_CLASS (tp_call_content_media_description_parent_class)->finalize (
      object);
}

static void
tp_call_content_media_description_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) object;

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        g_value_set_string (value, self->priv->object_path);
        break;
      case PROP_DBUS_DAEMON:
        g_value_set_object (value, self->priv->dbus_daemon);
        break;
      case PROP_INTERFACES:
        g_value_set_boxed (value, self->priv->interfaces->pdata);
        break;
      case PROP_FURTHER_NEGOTIATION_REQUIRED:
        g_value_set_boolean (value, self->priv->further_negotiation_required);
        break;
      case PROP_HAS_REMOTE_INFORMATION:
        g_value_set_boolean (value, self->priv->has_remote_information);
        break;
      case PROP_CODECS:
        g_value_set_boxed (value, self->priv->codecs);
        break;
      case PROP_REMOTE_CONTACT:
        g_value_set_uint (value, self->priv->remote_contact);
        break;
      case PROP_SSRCS:
        g_value_set_boxed (value, self->priv->ssrcs);
        break;
      case PROP_HEADER_EXTENSIONS:
        g_value_set_boxed (value, self->priv->header_extensions);
        break;
      case PROP_FEEDBACK_MESSAGES:
        g_value_set_boxed (value, self->priv->feedback_messages);
        break;
      case PROP_DOES_AVPF:
        g_value_set_boolean (value, self->priv->does_avpf);
        break;
      case PROP_LOSS_RLE_MAX_SIZE:
        g_value_set_uint (value, self->priv->loss_rle_max_size);
        break;
      case PROP_DUPLICATE_RLE_MAX_SIZE:
        g_value_set_uint (value, self->priv->duplicate_rle_max_size);
        break;
      case PROP_PACKET_RECEIPT_TIMES_MAX_SIZE:
        g_value_set_uint (value, self->priv->packet_receipt_times_max_size);
        break;
      case PROP_DLRR_MAX_SIZE:
        g_value_set_uint (value, self->priv->dlrr_max_size);
        break;
      case PROP_RTT_MODE:
        g_value_set_uint (value, self->priv->rtt_mode);
        break;
      case PROP_STATISTICS_FLAGS:
        g_value_set_uint (value, self->priv->statistics_flags);
        break;
      case PROP_ENABLE_METRICS:
        g_value_set_boolean (value, self->priv->enable_metrics);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_content_media_description_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) object;

  switch (property_id)
    {
      case PROP_OBJECT_PATH:
        g_assert (self->priv->object_path == NULL); /* construct-only */
        self->priv->object_path = g_value_dup_string (value);
        break;
      case PROP_DBUS_DAEMON:
        g_assert (self->priv->dbus_daemon == NULL); /* construct-only */
        self->priv->dbus_daemon = g_value_dup_object (value);
        break;
      case PROP_FURTHER_NEGOTIATION_REQUIRED:
        self->priv->further_negotiation_required = g_value_get_boolean (value);
        break;
      case PROP_HAS_REMOTE_INFORMATION:
        self->priv->has_remote_information = g_value_get_boolean (value);
        break;
      case PROP_REMOTE_CONTACT:
        self->priv->remote_contact = g_value_get_uint (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_content_media_description_class_init (
    TpCallContentMediaDescriptionClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *spec;
  static TpDBusPropertiesMixinPropImpl media_description_props[] = {
    { "Interfaces", "interfaces", NULL },
    { "FurtherNegotiationRequired", "further-negotiation-required", NULL },
    { "HasRemoteInformation", "has-remote-information", NULL},
    { "Codecs", "codecs", NULL },
    { "RemoteContact", "remote-contact", NULL },
    { "SSRCs", "ssrcs", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinPropImpl rtp_header_extensions_props[] = {
    { "HeaderExtensions", "header-extensions", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinPropImpl rtcp_feedback_props[] = {
    { "FeedbackMessages", "feedback-messages", NULL },
    { "DoesAVPF", "does-avpf", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinPropImpl rtcp_extended_reports_props[] = {
    { "LossRLEMaxSize", "loss-rle-max-size", NULL },
    { "DuplicateRLEMaxSize", "duplicate-rle-max-size", NULL },
    { "PacketReceiptTimesMaxSize", "packet-receipt-times-max-size", NULL },
    { "DLRRMaxSize", "dlrr-max-size", NULL },
    { "RTTMode", "rtt-mode", NULL },
    { "StatisticsFlags", "statistics-flags", NULL },
    { "EnableMetrics", "enable-metrics", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_interfaces[] = {
      { TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        media_description_props,
      },
      { TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTP_HEADER_EXTENSIONS,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        rtp_header_extensions_props,
      },
      { TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        rtcp_feedback_props,
      },
      { TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_EXTENDED_REPORTS,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        rtcp_extended_reports_props,
      },
      { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpCallContentMediaDescriptionPrivate));

  object_class->get_property = tp_call_content_media_description_get_property;
  object_class->set_property = tp_call_content_media_description_set_property;
  object_class->dispose = tp_call_content_media_description_dispose;
  object_class->finalize = tp_call_content_media_description_finalize;

  /**
   * TpCallContentMediaDescription:object-path:
   *
   * The D-Bus object path used for this object on the bus.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_string ("object-path", "D-Bus object path",
      "The D-Bus object path used for this "
      "object on the bus.",
      NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_OBJECT_PATH, spec);

  /**
   * TpCallContentMediaDescription:dbus-daemon:
   *
   * The connection to the DBus daemon owning the CM.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_object ("dbus-daemon",
      "The DBus daemon connection",
      "The connection to the DBus daemon owning the CM",
      TP_TYPE_DBUS_DAEMON,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON, spec);

  /**
   * TpCallContentMediaDescription:interfaces:
   *
   * Additional interfaces implemented by this object.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_boxed ("interfaces",
      "Interfaces",
      "Extra interfaces provided by this media description",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INTERFACES,
      spec);

  /**
   * TpCallContentMediaDescription:further-negotiation-required:
   *
   * %TRUE if more negotiation is required after MediaDescription is processed.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_boolean ("further-negotiation-required",
      "FurtherNegotiationRequired",
      "More negotiation is required after MediaDescription is processed",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_FURTHER_NEGOTIATION_REQUIRED,
      spec);

  /**
   * TpCallContentMediaDescription:further-negotiation-required:
   *
   * %TRUE if the MediaDescription contains remote information.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_boolean ("has-remote-information",
      "HasRemoteInformation",
      "True if the MediaDescription contains remote information",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_HAS_REMOTE_INFORMATION,
      spec);

  /**
   * TpCallContentMediaDescription:codecs:
   *
   * #GPtrArray{codecs #GValueArray}.
   * A list of codecs the remote contact supports.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_boxed ("codecs",
      "Codecs",
      "A list of codecs the remote contact supports",
      TP_ARRAY_TYPE_CODEC_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CODECS,
      spec);

  /**
   * TpCallContentMediaDescription:remote-contact:
   *
   * The contact #TpHandle that this media description applies to.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_uint ("remote-contact",
      "RemoteContact",
      "The contact handle that this media description applies to",
      0, G_MAXUINT, 0,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_CONTACT,
      spec);

  /**
   * TpCallContentMediaDescription:ssrcs:
   *
   * #GHashTable{contact #TpHandle, #GArray{uint}}
   * A map of contacts to SSRCs.
   *
   * Since: 0.17.5
   */
  spec = g_param_spec_boxed ("ssrcs",
      "SSRCs",
      "A map of handles to SSRCs",
      TP_HASH_TYPE_CONTACT_SSRCS_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SSRCS, spec);

  /**
   * TpCallContentMediaDescription:header-extensions:
   *
   * A list of remote header extensions which are supported.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_boxed ("header-extensions", "Header Extentions",
      "A list of remote header extensions which are supported.",
      TP_ARRAY_TYPE_RTP_HEADER_EXTENSIONS_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HEADER_EXTENSIONS, spec);

  /**
   * TpCallContentMediaDescription:feedback-messages:
   *
   * A map of remote feedback codec properties that are supported.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_boxed ("feedback-messages", "Feedback Messages",
      "A map of remote feedback codec properties that are supported.",
      TP_HASH_TYPE_RTCP_FEEDBACK_MESSAGE_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_FEEDBACK_MESSAGES, spec);

  /**
   * TpCallContentMediaDescription:does-avpf:
   *
   * %TRUE if the remote contact supports Audio-Visual Profile Feedback (AVPF),
   * otherwise %FALSE.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_boolean ("does-avpf", "Does AVPF",
      "True if the remote contact supports Audio-Visual Profile Feedback "
      "(AVPF), otherwise False.",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DOES_AVPF, spec);

  /**
   * TpCallContentMediaDescription:loss-rle-max-size:
   *
   * If non-zero, enable Loss Run Length Encoded Report Blocks. The value of
   * this integer represents the max-size of report blocks, as specified in
   * RFC 3611 section 5.1. MAXUINT32 is used to indicate that there is no limit.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("loss-rle-max-size", "Loss RLE max size",
      "If non-zero, enable Loss Run Length Encoded Report Blocks.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOSS_RLE_MAX_SIZE, spec);

  /**
   * TpCallContentMediaDescription:duplicate-rle-max-size:
   *
   * If non-zero, enable Duplicate Run-Length-Encoded Report Blocks. The value
   * of this integer represents the max-size of report blocks, as specified in
   * RFC 3611 section 5.1. MAXUINT32 is used to indicate that there is no limit.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("duplicate-rle-max-size",
      "Duplicate Run-Length-Encoded max size",
      "If non-zero, enable Duplicate Run-Length-Encoded Report Blocks.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DUPLICATE_RLE_MAX_SIZE,
      spec);

  /**
   * TpCallContentMediaDescription:packet-receipt-times-max-size:
   *
   * If non-zero, enable Packet Receipt Times Report Blocks. The value of this
   * integer represents the max-size of report blocks, as specified in RFC 3611
   * section 5.1. MAXUINT32 is used to indicate that there is no limit.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("packet-receipt-times-max-size",
      "Packet Receipt Times max size",
      "If non-zero, enable Packet Receipt Times Report Blocks.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_PACKET_RECEIPT_TIMES_MAX_SIZE, spec);

  /**
   * TpCallContentMediaDescription:dlrr-max-size:
   *
   * If non-zero, enable Receiver Reference Time and Delay since Last Receiver
   * Report Blocks (for estimating Round Trip Times between non-senders and
   * other parties in the call. The value of this integer represents the
   * max-size of report blocks, as specified in RFC 3611 section 5.1. MAXUINT32
   * is used to indicate that there is no limit.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("dlrr-max-size",
      "Receiver Reference Time and Delay since Last Receiver max size",
      "If non-zero, enable Receiver Reference Time and Delay since Last "
      "Receiver Report Blocks.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DLRR_MAX_SIZE, spec);

  /**
   * TpCallContentMediaDescription:rtt-mode:
   *
   * Who is allowed to send Delay since Last Receiver Reports. Value from
   * #TpRCPTXRRTTMode.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("rtt-mode", "RTT Mode",
      "Who is allowed to send Delay since Last Receiver Reports.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_RTT_MODE, spec);

  /**
   * TpCallContentMediaDescription:statistics-flags:
   *
   * Which fields SHOULD be included in the statistics summary report blocks
   * that are sent, and whether to send VoIP Metrics Report Blocks. There can
   * be zero or more flags set. Value from #TpRTCPXRStatisticsFlags.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_uint ("statistics-flags", "Statistics Flags",
      "Which fields SHOULD be included in the statistics summary report blocks "
      "that are sent, and whether to send VoIP Metrics Report Blocks.",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STATISTICS_FLAGS, spec);

  /**
   * TpCallContentMediaDescription:enable-metrics:
   *
   * Whether to enable VoIP Metrics Report Blocks. These blocks are of a fixed
   * size.
   *
   * Since: 0.17.6
   */
  spec = g_param_spec_boolean ("enable-metrics", "Enable Metrics",
      "Whether to enable VoIP Metrics Report Blocks. These blocks are of a "
      "fixed size.",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ENABLE_METRICS, spec);

  klass->dbus_props_class.interfaces = prop_interfaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpCallContentMediaDescriptionClass, dbus_props_class));
}

/**
 * tp_call_content_media_description_new:
 * @dbus_daemon: value of #TpCallContentMediaDescription:dbus-daemon property
 * @object_path: value of #TpCallContentMediaDescription:object-path property
 * @remote_contact: value of
 *  #TpCallContentMediaDescription:remote-contact property
 * @has_remote_information: value of
 *  #TpCallContentMediaDescription:has_remote_information property
 * @further_negotiation_required: value of
 *  #TpCallContentMediaDescription:further_negotiation_required property
 *
 * Create a new #TpCallContentMediaDescription object. More information can be
 * added after construction using
 * tp_call_content_media_description_append_codec() and
 * tp_call_content_media_description_add_ssrc().
 *
 * Once all information has been filled, the media description can be offered
 * using tp_base_media_call_content_offer_media_description_async().
 *
 * Returns: a new #TpCallContentMediaDescription.
 * Since: 0.17.5
 */
TpCallContentMediaDescription *
tp_call_content_media_description_new (TpDBusDaemon *dbus_daemon,
    const gchar *object_path,
    TpHandle remote_contact,
    gboolean has_remote_information,
    gboolean further_negotiation_required)
{
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  return g_object_new (TP_TYPE_CALL_CONTENT_MEDIA_DESCRIPTION,
      "dbus-daemon", dbus_daemon,
      "object-path", object_path,
      "further-negotiation-required", further_negotiation_required,
      "has-remote-information", has_remote_information,
      "remote-contact", remote_contact,
      NULL);
}

/**
 * tp_call_content_media_description_get_object_path:
 * @self: a #TpCallContentMediaDescription
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallContentMediaDescription:object-path
 * Since: 0.17.5
 */
const gchar *
tp_call_content_media_description_get_object_path (
    TpCallContentMediaDescription *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self), NULL);

  return self->priv->object_path;
}

/**
 * tp_call_content_media_description_get_remote_contact:
 * @self: a #TpCallContentMediaDescription
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallContentMediaDescription:remote-contact
 * Since: 0.17.5
 */
TpHandle
tp_call_content_media_description_get_remote_contact (
    TpCallContentMediaDescription *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self), 0);

  return self->priv->remote_contact;
}

/**
 * tp_call_content_media_description_add_ssrc:
 * @self: a #TpCallContentMediaDescription
 * @contact: The #TpHandle of a contact that is part of the call
 * @ssrc: A SSRC that this contact may send from
 *
 * Add an SSRC to the list of SSRCs that a contact will send from. A SSRC
 * is a synchronization source in RTP, it is the identifier for a continuous
 * stream of packets following the same timeline.
 *
 * Since: 0.17.5
 */
void
tp_call_content_media_description_add_ssrc (TpCallContentMediaDescription *self,
    TpHandle contact,
    guint ssrc)
{
  GArray *array;
  guint i;

  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  array = g_hash_table_lookup (self->priv->ssrcs,
      GUINT_TO_POINTER (contact));

  if (array == NULL)
    {
      array = g_array_new (FALSE, FALSE, sizeof (guint));
      g_hash_table_insert (self->priv->ssrcs,
          GUINT_TO_POINTER (contact),
          array);
    }

  for (i = 0; i < array->len; i++)
    {
      if (g_array_index (array, guint, i) == ssrc)
        return;
    }
  g_array_append_val (array, ssrc);
}

/**
 * tp_call_content_media_description_append_codec:
 * @self: a #TpCallContentMediaDescription
 * @identifier: Numeric identifier for the codec. This will be used as the PT
 *    in the SDP or content description.
 * @name: The name of the codec.
 * @clock_rate: The clock rate of the codec.
 * @channels: Number of channels of the codec if applicable, otherwise 0.
 * @updated: %TRUE if this codec was updated since the last Media Description
 * @parameters: a #GHashTable of string->string containing optional parameters
 *
 * Add description for a supported codec.
 *
 * Since: 0.17.5
 */
void
tp_call_content_media_description_append_codec (
    TpCallContentMediaDescription *self,
    guint identifier,
    const gchar *name,
    guint clock_rate,
    guint channels,
    gboolean updated,
    GHashTable *parameters)
{
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  if (parameters == NULL)
    parameters = g_hash_table_new (g_str_hash, g_str_equal);

  g_ptr_array_add (self->priv->codecs, tp_value_array_build (6,
      G_TYPE_UINT, identifier,
      G_TYPE_STRING, name,
      G_TYPE_UINT, clock_rate,
      G_TYPE_UINT, channels,
      G_TYPE_BOOLEAN, updated,
      TP_HASH_TYPE_STRING_STRING_MAP, parameters,
      G_TYPE_INVALID));
}

static void
add_interface (TpCallContentMediaDescription *self,
    const gchar *interface)
{
  if (tp_g_ptr_array_contains (self->priv->interfaces, (gchar *) interface))
    return;

  /* Remove terminating NULL, add interface, then add the NULL back */
  g_ptr_array_remove_index_fast (self->priv->interfaces,
      self->priv->interfaces->len - 1);
  g_ptr_array_add (self->priv->interfaces, (gchar *) interface);
  g_ptr_array_add (self->priv->interfaces, NULL);
}

/**
 * tp_call_content_media_description_add_rtp_header_extensions_interface:
 * @self: a #TpCallContentMediaDescription
 *
 * Adds the RTPHeaderExtensions interface to the list of supported interfaces
 *
 * Since: 0.17.6
 */

void
tp_call_content_media_description_add_rtp_header_extensions_interface (
    TpCallContentMediaDescription *self)
{
  add_interface (self,
      TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTP_HEADER_EXTENSIONS);
}


/**
 * tp_call_content_media_description_add_rtcp_feedback_interface:
 * @self: a #TpCallContentMediaDescription
 *
 * Adds the RTCPFeedback interface to the list of supported interfaces
 *
 * Since: 0.17.6
 */

void
tp_call_content_media_description_add_rtcp_feedback_interface (
    TpCallContentMediaDescription *self)
{
  add_interface (self,
      TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK);
}


/**
 * tp_call_content_media_description_add_rtcp_extended_reports_interface:
 * @self: a #TpCallContentMediaDescription
 *
 * Adds the RTCPExtendedReports interface to the list of supported interfaces
 *
 * Since: 0.17.6
 */

void
tp_call_content_media_description_add_rtcp_extended_reports_interface (
    TpCallContentMediaDescription *self)
{
  add_interface (self,
      TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_EXTENDED_REPORTS);
}


/**
 * tp_call_content_media_description_add_rtp_header_extension:
 * @self: a #TpCallContentMediaDescription
 * @id: identifier to be negotiated.
 * @direction: a #TpMediaStreamDirection in which the Header Extension is
 *  negotiated.
 * @uri: URI defining the extension.
 * @parameters: Feedback parameters as a string. Format is defined in the
 *  relevant RFC.
 *
 * Add an element to the #TpCallContentMediaDescription:header-extensions
 * property.
 *
 * Implement
 * %TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTP_HEADER_EXTENSIONS
 * interface.
 *
 * Since: 0.17.6
 */
void
tp_call_content_media_description_add_rtp_header_extension (
    TpCallContentMediaDescription *self,
    guint id,
    TpMediaStreamDirection direction,
    const gchar *uri,
    const gchar *parameters)
{
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  g_ptr_array_add (self->priv->header_extensions, tp_value_array_build (4,
      G_TYPE_UINT, id,
      G_TYPE_UINT, direction,
      G_TYPE_STRING, uri,
      G_TYPE_STRING, parameters,
      G_TYPE_INVALID));

  tp_call_content_media_description_add_rtp_header_extensions_interface (self);
}

static GValueArray *
ensure_rtcp_feedback_properties (TpCallContentMediaDescription *self,
    guint codec_identifier)
{
  GValueArray *properties;
  GPtrArray *messages_array;

  properties = g_hash_table_lookup (self->priv->feedback_messages,
      GUINT_TO_POINTER (codec_identifier));

  if (properties == NULL)
    {
      messages_array = g_ptr_array_new_with_free_func (
          (GDestroyNotify) tp_value_array_free);
      properties = tp_value_array_build (2,
          G_TYPE_UINT, G_MAXUINT,
          G_TYPE_PTR_ARRAY, messages_array,
          G_TYPE_INVALID);

      g_hash_table_insert (self->priv->feedback_messages,
          GUINT_TO_POINTER (codec_identifier), properties);

      g_ptr_array_unref (messages_array);
    }

  return properties;
}

/**
 * tp_call_content_media_description_add_rtcp_feedback_message:
 * @self: a #TpCallContentMediaDescription
 * @codec_identifier: Numeric identifier for the codec. This will be used as the
 *  PT in the SDP or content description.
 * @type: feedback type, for example "ack", "nack", or "ccm".
 * @subtype: feedback subtype, according to the Type, can be an empty string
 *  (""), if there is no subtype. For example, generic nack is Type="nack"
 *  Subtype="".
 * @parameters: feedback parameters as a string. Format is defined in the
 *  relevant RFC.
 *
 * Add a message for a given codec. This ensures @codec_identifier is
 * in the #TpCallContentMediaDescription:feedback-messages map. The
 * rtcp-minimum-interval is set to %G_MAXUINT and can then be changed using
 * tp_call_content_media_description_set_rtcp_feedback_minimum_interval().
 *
 * Implement
 * %TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK
 * interface.
 *
 * Since: 0.17.6
 */
void
tp_call_content_media_description_add_rtcp_feedback_message (
    TpCallContentMediaDescription *self,
    guint codec_identifier,
    const gchar *type,
    const gchar *subtype,
    const gchar *parameters)
{
  GValueArray *properties;
  GValue *value;
  GPtrArray *messages_array;

  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  properties = ensure_rtcp_feedback_properties (self, codec_identifier);
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  value = g_value_array_get_nth (properties, 1);
  G_GNUC_END_IGNORE_DEPRECATIONS
  messages_array = g_value_get_boxed (value);

  g_ptr_array_add (messages_array, tp_value_array_build (3,
      G_TYPE_STRING, type,
      G_TYPE_STRING, subtype,
      G_TYPE_STRING, parameters,
      G_TYPE_INVALID));

  tp_call_content_media_description_add_rtcp_feedback_interface (self);
}

/**
 * tp_call_content_media_description_set_rtcp_feedback_minimum_interval:
 * @self: a #TpCallContentMediaDescription
 * @codec_identifier: Numeric identifier for the codec. This will be used as the
 *  PT in the SDP or content description.
 * @rtcp_minimum_interval: The minimum interval between two regular RTCP packets
 *  in milliseconds for this content. If no special value is desired, one should
 *  put MAXUINT (0xFFFFFFFF). Implementors and users of Call's RTCPFeedback
 *  should not use the MAXUINT default. Instead, in RTP/AVP, the default should
 *  be 5000 (5 seconds). If using the RTP/AVPF profile, it can be set to a lower
 *  value, the default being 0.
 *
 * Set the minimum interval for a given codec. This ensures @codec_identifier is
 * in the #TpCallContentMediaDescription:feedback-messages map. The messages
 * can then be added using
 * tp_call_content_media_description_add_rtcp_feedback_message().
 *
 * Implement
 * %TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK
 * interface.
 *
 * Since: 0.17.6
 */
void
tp_call_content_media_description_set_rtcp_feedback_minimum_interval (
    TpCallContentMediaDescription *self,
    guint codec_identifier,
    guint rtcp_minimum_interval)
{
  GValueArray *properties;
  GValue *value;

  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  properties = ensure_rtcp_feedback_properties (self, codec_identifier);
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  value = g_value_array_get_nth (properties, 0);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_value_set_uint (value, rtcp_minimum_interval);

  tp_call_content_media_description_add_rtcp_feedback_interface (self);
}

/**
 * tp_call_content_media_description_set_does_avpf:
 * @self: a #TpCallContentMediaDescription
 * @does_avpf: the value for
 *  #TpCallContentMediaDescription:does-avpf property.
 *
 * Implement properties for
 * %TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK
 * interface
 *
 * Since: 0.17.6
 */
void
tp_call_content_media_description_set_does_avpf (
    TpCallContentMediaDescription *self,
    gboolean does_avpf)
{
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  self->priv->does_avpf = does_avpf;

  tp_call_content_media_description_add_rtcp_feedback_interface (self);
}

/**
 * tp_call_content_media_description_set_rtcp_extended_reports:
 * @self: a #TpCallContentMediaDescription
 * @loss_rle_max_size: the value for
 *  #TpCallContentMediaDescription:loss-rle-max-size property.
 * @duplicate_rle_max_size: the value for
 *  #TpCallContentMediaDescription:duplicate-rle-max-size property.
 * @packet_receipt_times_max_size: the value for
 *  #TpCallContentMediaDescription:packet-receipt-times-max-size property.
 * @dlrr_max_size: the value for
 *  #TpCallContentMediaDescription:dlrr-max-size property.
 * @rtt_mode: the value for
 *  #TpCallContentMediaDescription:rtt-mode property.
 * @statistics_flags: the value for
 *  #TpCallContentMediaDescription:statistics-flags property.
 * @enable_metrics: the value for
 *  #TpCallContentMediaDescription:enable-metrics property.
 *
 * Implement
 * %TP_IFACE_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_EXTENDED_REPORTS
 * interface.
 *
 * Since: 0.17.6
 */
void
tp_call_content_media_description_set_rtcp_extended_reports (
    TpCallContentMediaDescription *self,
    guint loss_rle_max_size,
    guint duplicate_rle_max_size,
    guint packet_receipt_times_max_size,
    guint dlrr_max_size,
    TpRCPTXRRTTMode rtt_mode,
    TpRTCPXRStatisticsFlags statistics_flags,
    gboolean enable_metrics)
{
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));

  self->priv->loss_rle_max_size = loss_rle_max_size;
  self->priv->duplicate_rle_max_size = duplicate_rle_max_size;
  self->priv->packet_receipt_times_max_size = packet_receipt_times_max_size;
  self->priv->dlrr_max_size = dlrr_max_size;
  self->priv->rtt_mode = rtt_mode;
  self->priv->statistics_flags = statistics_flags;
  self->priv->enable_metrics = enable_metrics;

  tp_call_content_media_description_add_rtcp_extended_reports_interface (self);
}

static void
cancelled_cb (GCancellable *cancellable,
    gpointer user_data)
{
  TpCallContentMediaDescription *self = user_data;

  tp_dbus_daemon_unregister_object (self->priv->dbus_daemon, G_OBJECT (self));

  g_simple_async_result_set_error (self->priv->result,
      G_IO_ERROR, G_IO_ERROR_CANCELLED,
      "Media Description cancelled");
  g_simple_async_result_complete_in_idle (self->priv->result);

  g_clear_object (&self->priv->cancellable);
  g_clear_object (&self->priv->result);
  self->priv->handler_id = 0;
}

void
_tp_call_content_media_description_offer_async (
    TpCallContentMediaDescription *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self));
  g_return_if_fail (self->priv->result == NULL);

  self->priv->result = g_simple_async_result_new (G_OBJECT (self),
    callback, user_data, _tp_call_content_media_description_offer_async);

  if (cancellable != NULL)
    {
      self->priv->cancellable = g_object_ref (cancellable);
      self->priv->handler_id = g_cancellable_connect (
          cancellable, G_CALLBACK (cancelled_cb), self, NULL);
    }

  /* register object on the bus */
  DEBUG ("Registering %s", self->priv->object_path);
  tp_dbus_daemon_register_object (self->priv->dbus_daemon,
      self->priv->object_path, G_OBJECT (self));
}

gboolean
_tp_call_content_media_description_offer_finish (
    TpCallContentMediaDescription *self,
    GAsyncResult *result,
    GHashTable **properties,
    GError **error)
{
  _tp_implement_finish_copy_pointer (self,
      _tp_call_content_media_description_offer_async,
      g_hash_table_ref, properties);
}

GHashTable *
_tp_call_content_media_description_dup_properties (
    TpCallContentMediaDescription *self)
{
  g_return_val_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (self), NULL);

  return tp_asv_new (
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACES,
          G_TYPE_STRV, self->priv->interfaces->pdata,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_FURTHER_NEGOTIATION_REQUIRED,
          G_TYPE_BOOLEAN, self->priv->further_negotiation_required,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_HAS_REMOTE_INFORMATION,
          G_TYPE_BOOLEAN, self->priv->has_remote_information,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_CODECS,
          TP_ARRAY_TYPE_CODEC_LIST, self->priv->codecs,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_REMOTE_CONTACT,
          G_TYPE_UINT, self->priv->remote_contact,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_SSRCS,
          TP_HASH_TYPE_CONTACT_SSRCS_MAP, self->priv->ssrcs,
      NULL);
}

static void
tp_call_content_media_description_accept (TpSvcCallContentMediaDescription *iface,
    GHashTable *properties,
    DBusGMethodInvocation *context)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) iface;
  GPtrArray *codecs;
  gboolean valid;
  TpHandle remote_contact;

  DEBUG ("%s was accepted", self->priv->object_path);

  if (self->priv->cancellable != NULL)
    {
      g_cancellable_disconnect (self->priv->cancellable, self->priv->handler_id);
      g_clear_object (&self->priv->cancellable);
      self->priv->handler_id = 0;
    }

  codecs = tp_asv_get_boxed (properties,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_CODECS,
      TP_ARRAY_TYPE_CODEC_LIST);
  if (!codecs || codecs->len == 0)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
                       "Codecs can not be empty" };
      dbus_g_method_return_error (context, &error);
      return;
    }

  remote_contact = tp_asv_get_uint32 (properties,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_REMOTE_CONTACT,
      &valid);
  if (valid && remote_contact != self->priv->remote_contact)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
                       "Remote contact must the same as in request." };
      dbus_g_method_return_error (context, &error);
      return;
    }

  g_simple_async_result_set_op_res_gpointer (self->priv->result,
      g_hash_table_ref (properties), (GDestroyNotify) g_hash_table_unref);
  g_simple_async_result_complete (self->priv->result);
  g_clear_object (&self->priv->result);

  tp_svc_call_content_media_description_return_from_accept (context);

  tp_dbus_daemon_unregister_object (self->priv->dbus_daemon, G_OBJECT (self));
}

static void
tp_call_content_media_description_reject (TpSvcCallContentMediaDescription *iface,
    const GValueArray *reason_array,
    DBusGMethodInvocation *context)
{
  TpCallContentMediaDescription *self = (TpCallContentMediaDescription *) iface;

  DEBUG ("%s was rejected", self->priv->object_path);

  if (!self->priv->has_remote_information)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
                       "Can not reject an empty Media Description" };
      dbus_g_method_return_error (context, &error);
      return;
    }

  if (self->priv->cancellable != NULL)
    {
      g_cancellable_disconnect (self->priv->cancellable,
          self->priv->handler_id);
      g_clear_object (&self->priv->cancellable);
      self->priv->handler_id = 0;
    }

  g_simple_async_result_set_error (self->priv->result,
      TP_ERROR, TP_ERROR_MEDIA_CODECS_INCOMPATIBLE,
      "Media description was rejected");
  g_simple_async_result_complete (self->priv->result);
  g_clear_object (&self->priv->result);

  tp_svc_call_content_media_description_return_from_reject (context);

  tp_dbus_daemon_unregister_object (self->priv->dbus_daemon, G_OBJECT (self));
}

static void
call_content_media_description_iface_init (gpointer iface, gpointer data)
{
  TpSvcCallContentMediaDescriptionClass *klass =
      (TpSvcCallContentMediaDescriptionClass *) iface;

#define IMPLEMENT(x) tp_svc_call_content_media_description_implement_##x (\
    klass, tp_call_content_media_description_##x)
  IMPLEMENT(accept);
  IMPLEMENT(reject);
#undef IMPLEMENT
}

static void
call_content_media_description_extra_iface_init (gpointer iface, gpointer data)
{
}
