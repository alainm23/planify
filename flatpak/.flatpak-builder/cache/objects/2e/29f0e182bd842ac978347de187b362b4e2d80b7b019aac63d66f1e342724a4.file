/*
 * base-media-call-content.c - Source for TpBaseMediaCallContent
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
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
 * SECTION:base-media-call-content
 * @title: TpBaseMediaCallContent
 * @short_description: base class for #TpSvcCallContentInterfaceMedia
 *  implementations
 * @see_also: #TpSvcCallContentInterfaceMedia, #TpBaseCallChannel,
 *  #TpBaseCallContent and #TpBaseCallStream
 *
 * This base class makes it easier to write #TpSvcCallContentInterfaceMedia
 * implementations by implementing its properties and methods.
 *
 * Subclasses must still implement #TpBaseCallContent's virtual methods.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallContent:
 *
 * A base class for media call content implementations
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallContentClass:
 *
 * The class structure for #TpBaseMediaCallContent
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "base-media-call-content.h"

#include <string.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-call-channel.h"
#include "telepathy-glib/base-channel.h"
#include "telepathy-glib/base-connection.h"
#include "telepathy-glib/base-media-call-stream.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dtmf.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/util.h"
#include "telepathy-glib/util-internal.h"

#define DTMF_PAUSE_MS (3000)

static void call_content_media_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseMediaCallContent,
    tp_base_media_call_content, TP_TYPE_BASE_CALL_CONTENT,

    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA,
      call_content_media_iface_init)
    )

/* properties */
enum
{
  /* Call.Content.Interface.Media properties */

  PROP_REMOTE_MEDIA_DESCRIPTIONS = 1,
  PROP_LOCAL_MEDIA_DESCRIPTIONS,
  PROP_MEDIA_DESCRIPTION_OFFER,
  PROP_PACKETIZATION,
  PROP_CURRENT_DTMF_EVENT,
  PROP_CURRENT_DTMF_STATE,

  /* Call.Content.Interface.DTMF properties */

  PROP_CURRENTLY_SENDING_TONES,
  PROP_DEFERRED_TONES
};

enum /* signals */
{
  LOCAL_MEDIA_DESCRIPTION_UPDATED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

/* private structure */
struct _TpBaseMediaCallContentPrivate
{
  /* TpHandle -> reffed GHashTable */
  GHashTable *remote_media_descriptions;
  /* TpHandle -> reffed GHashTable */
  GHashTable *local_media_descriptions;
  TpCallContentMediaDescription *current_offer;
  TpCallContentPacketizationType packetization;
  TpDTMFEvent current_dtmf_event;
  TpSendingState current_dtmf_state;

  gchar *requested_tones;
  const gchar *currently_sending_tones;
  gchar *deferred_tones;
  gboolean multiple_tones;
  gboolean tones_cancelled;
  guint tones_pause_timeout_id;
  gulong channel_state_changed_id;

  /* GQueue of GSimpleAsyncResult with a TpCallContentMediaDescription
   * as op_res_gpointer */
  GQueue *outstanding_offers;
  GSimpleAsyncResult *current_offer_result;
  GCancellable *current_offer_cancellable;
};

static GPtrArray *tp_base_media_call_content_get_interfaces (
    TpBaseCallContent *bcc);

static gboolean tp_base_media_call_content_start_tone (TpBaseCallContent *self,
    TpDTMFEvent event,
    GError **error);
static gboolean tp_base_media_call_content_stop_tone (TpBaseCallContent *self,
    GError **error);
static gboolean tp_base_media_call_content_multiple_tones (
    TpBaseCallContent *self,
    const gchar *tones,
    GError **error);
static void tp_base_media_call_content_dtmf_next (TpBaseMediaCallContent *self);

static void
tp_base_media_call_content_init (TpBaseMediaCallContent *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_MEDIA_CALL_CONTENT, TpBaseMediaCallContentPrivate);

  self->priv->outstanding_offers = g_queue_new ();
  self->priv->local_media_descriptions = g_hash_table_new_full (NULL, NULL,
      NULL, (GDestroyNotify) g_hash_table_unref);
  self->priv->remote_media_descriptions = g_hash_table_new_full (NULL, NULL,
      NULL, (GDestroyNotify) g_hash_table_unref);
}

static void
call_content_deinit (TpBaseCallContent *base)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (base);

  g_queue_foreach (self->priv->outstanding_offers, (GFunc) g_object_unref, NULL);
  g_queue_clear (self->priv->outstanding_offers);

  if (self->priv->current_offer_cancellable != NULL)
    g_cancellable_cancel (self->priv->current_offer_cancellable);

  TP_BASE_CALL_CONTENT_CLASS (
      tp_base_media_call_content_parent_class)->deinit (base);
}

static void
tp_base_media_call_content_dispose (GObject *object)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (object);

  g_assert (self->priv->current_offer == NULL);
  g_assert (self->priv->current_offer_result == NULL);
  g_assert (g_queue_is_empty (self->priv->outstanding_offers));

  tp_clear_pointer (&self->priv->local_media_descriptions, g_hash_table_unref);
  tp_clear_pointer (&self->priv->remote_media_descriptions, g_hash_table_unref);

  if (self->priv->tones_pause_timeout_id != 0)
    g_source_remove (self->priv->tones_pause_timeout_id);
  self->priv->tones_pause_timeout_id = 0;

  if (self->priv->channel_state_changed_id != 0)
    {
      TpBaseCallChannel *channel = _tp_base_call_content_get_channel (
          TP_BASE_CALL_CONTENT (self));

      g_signal_handler_disconnect (channel,
          self->priv->channel_state_changed_id);
      self->priv->channel_state_changed_id = 0;
    }

  if (G_OBJECT_CLASS (tp_base_media_call_content_parent_class)->dispose)
    G_OBJECT_CLASS (tp_base_media_call_content_parent_class)->dispose (object);
}

static void
tp_base_media_call_content_finalize (GObject *object)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (object);

  g_queue_free (self->priv->outstanding_offers);

  g_free (self->priv->requested_tones);
  g_free (self->priv->deferred_tones);

  if (G_OBJECT_CLASS (tp_base_media_call_content_parent_class)->finalize)
    G_OBJECT_CLASS (tp_base_media_call_content_parent_class)->finalize (object);
}

static void
tp_base_media_call_content_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (object);

  switch (property_id)
    {
      case PROP_REMOTE_MEDIA_DESCRIPTIONS:
        g_value_set_boxed (value, self->priv->remote_media_descriptions);
        break;
      case PROP_LOCAL_MEDIA_DESCRIPTIONS:
        g_value_set_boxed (value, self->priv->local_media_descriptions);
        break;
      case PROP_MEDIA_DESCRIPTION_OFFER:
        {
          const gchar *object_path = "/";
          GHashTable *properties;
          GValueArray *value_array;

          if (self->priv->current_offer != NULL)
            {
              object_path = tp_call_content_media_description_get_object_path (
                  self->priv->current_offer);
              properties = _tp_call_content_media_description_dup_properties (
                  self->priv->current_offer);
            }
          else
            {
              properties = g_hash_table_new (NULL, NULL);
            }

          value_array = tp_value_array_build (2,
              DBUS_TYPE_G_OBJECT_PATH, object_path,
              TP_HASH_TYPE_MEDIA_DESCRIPTION_PROPERTIES, properties,
              G_TYPE_INVALID);

          g_value_take_boxed (value, value_array);
          g_hash_table_unref (properties);
          break;
        }
      case PROP_PACKETIZATION:
        g_value_set_uint (value, self->priv->packetization);
        break;
      case PROP_CURRENT_DTMF_EVENT:
        g_value_set_uchar (value, self->priv->current_dtmf_event);
        break;
      case PROP_CURRENT_DTMF_STATE:
        g_value_set_uint (value, self->priv->current_dtmf_state);
        break;
      case PROP_CURRENTLY_SENDING_TONES:
        g_value_set_boolean (value,
            self->priv->currently_sending_tones != NULL);
        break;
      case PROP_DEFERRED_TONES:
        if (self->priv->deferred_tones == NULL)
          g_value_set_static_string (value, "");
        else
          g_value_set_string (value, self->priv->deferred_tones);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_media_call_content_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (object);

  switch (property_id)
    {
      case PROP_PACKETIZATION:
        self->priv->packetization = g_value_get_uint (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_media_call_content_class_init (TpBaseMediaCallContentClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  TpBaseCallContentClass *bcc_class = TP_BASE_CALL_CONTENT_CLASS (klass);
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl content_media_props[] = {
    { "RemoteMediaDescriptions", "remote-media-descriptions", NULL },
    { "LocalMediaDescriptions", "local-media-descriptions", NULL },
    { "MediaDescriptionOffer", "media-description-offer", NULL },
    { "Packetization", "packetization", NULL },
    { "CurrentDTMFEvent", "current-dtmf-event", NULL },
    { "CurrentDTMFState", "current-dtmf-state", NULL },
    { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpBaseMediaCallContentPrivate));

  object_class->get_property = tp_base_media_call_content_get_property;
  object_class->set_property = tp_base_media_call_content_set_property;
  object_class->dispose = tp_base_media_call_content_dispose;
  object_class->finalize = tp_base_media_call_content_finalize;

  bcc_class->deinit = call_content_deinit;
  bcc_class->get_interfaces = tp_base_media_call_content_get_interfaces;
  bcc_class->start_tone = tp_base_media_call_content_start_tone;
  bcc_class->stop_tone = tp_base_media_call_content_stop_tone;
  bcc_class->stop_tone = tp_base_media_call_content_stop_tone;
  bcc_class->multiple_tones = tp_base_media_call_content_multiple_tones;

  /**
   * TpBaseMediaCallContent:remote-media-descriptions:
   *
   * #GHashTable{contact #TpHandle, properties #GHashTable}
   * The map of contacts to remote media descriptions.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("remote-media-descriptions",
      "RemoteMediaDescriptions",
      "The map of contacts to remote media descriptions",
      TP_HASH_TYPE_CONTACT_MEDIA_DESCRIPTION_PROPERTIES_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_MEDIA_DESCRIPTIONS,
      param_spec);

  /**
   * TpBaseMediaCallContent:local-media-descriptions:
   *
   * #GHashTable{contact #TpHandle, properties #GHashTable}
   * The map of contacts to local media descriptions.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("local-media-descriptions",
      "LocalMediaDescriptions",
      "The map of contacts to local media descriptions",
      TP_HASH_TYPE_CONTACT_MEDIA_DESCRIPTION_PROPERTIES_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCAL_MEDIA_DESCRIPTIONS,
      param_spec);

  /**
   * TpBaseMediaCallContent:media-description-offer:
   *
   * #GValueArray{object-path, contact #TpHandle, properties #GHashTable}.
   * The current media description offer if any.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("media-description-offer",
      "MediaDescriptionOffer",
      "The current media description offer if any",
      TP_STRUCT_TYPE_MEDIA_DESCRIPTION_OFFER,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MEDIA_DESCRIPTION_OFFER,
      param_spec);

  /**
   * TpBaseMediaCallContent:packetization:
   *
   * The #TpCallContentPacketizationType of this content.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("packetization", "Packetization",
      "The Packetization of this content",
      0, G_MAXUINT, TP_CALL_CONTENT_PACKETIZATION_TYPE_RTP,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PACKETIZATION,
      param_spec);

  /**
   * TpBaseMediaCallContent:current-dtmf-event:
   *
   * The currently being played #TpDTMFEvent if any
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uchar ("current-dtmf-event",
      "CurrentDTMFEvent",
      "The currently being played dtmf event if any",
      0, TP_NUM_DTMF_EVENTS - 1, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CURRENT_DTMF_EVENT,
      param_spec);

  /**
   * TpBaseMediaCallContent:current-dtmf-state:
   *
   * The #TpSendingState of the dtmf events
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("current-dtmf-state",
      "CurrentDTMFState",
      "The sending state of the dtmf events",
      0, TP_NUM_SENDING_STATES - 1, TP_SENDING_STATE_NONE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CURRENT_DTMF_STATE,
      param_spec);

  g_object_class_override_property (object_class, PROP_CURRENTLY_SENDING_TONES,
      "currently-sending-tones");
  g_object_class_override_property (object_class, PROP_DEFERRED_TONES,
      "deferred-tones");

  /**
   * TpBaseMediaCallContent::local-media-description-updated:
   * @self: the #TpCallChannel
   * @contact: the remote contact
   * @properties: the new media description properties asv
   *
   * The ::local-media-description-changed signal is emitted whenever the local
   * media description changes for a remote contact.
   *
   * Since: 0.17.5
   */
  _signals[LOCAL_MEDIA_DESCRIPTION_UPDATED] = g_signal_new (
      "local-media-description-updated",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, G_TYPE_UINT, G_TYPE_HASH_TABLE);

  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_MEDIA,
      tp_dbus_properties_mixin_getter_gobject_properties,
      NULL,
      content_media_props);
}

static void
set_local_properties (TpBaseMediaCallContent *self,
    TpHandle contact,
    GHashTable *properties)
{
  DEBUG ("Set local properties for contact %u", contact);

  g_hash_table_insert (self->priv->local_media_descriptions,
      GUINT_TO_POINTER (contact),
      g_hash_table_ref (properties));

  g_signal_emit (self, _signals[LOCAL_MEDIA_DESCRIPTION_UPDATED], 0,
      contact, properties);

  tp_svc_call_content_interface_media_emit_local_media_description_changed (
      self, properties);
}

static void
set_remote_properties (TpBaseMediaCallContent *self,
    TpHandle contact,
    GHashTable *properties)
{
  GHashTable *update;

  DEBUG ("Set remote properties for contact %u", contact);

  g_hash_table_insert (self->priv->remote_media_descriptions,
      GUINT_TO_POINTER (contact),
      g_hash_table_ref (properties));

  update = g_hash_table_new (NULL, NULL);
  g_hash_table_insert (update,
      GUINT_TO_POINTER (contact),
      properties);

  tp_svc_call_content_interface_media_emit_remote_media_descriptions_changed (
      self, update);

  g_hash_table_unref (update);
}

static void next_offer (TpBaseMediaCallContent *self);

static void
offer_finished_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseMediaCallContent *self = user_data;
  TpCallContentMediaDescription *md = (TpCallContentMediaDescription *) source;
  GHashTable *local_properties = NULL;
  GHashTable *remote_properties = NULL;
  TpHandle contact;
  GError *error = NULL;

  g_assert (self->priv->current_offer == md);

  if (!_tp_call_content_media_description_offer_finish (md, result,
          &local_properties, &error))
    {
      DEBUG ("Offer failed: %s", error->message);
      g_simple_async_result_take_error (self->priv->current_offer_result,
          error);
      goto out;
    }

  DEBUG ("Accepted offer: %s",
      tp_call_content_media_description_get_object_path (md));

  /* Accepted, update local and remote MediaDescription */
  remote_properties = _tp_call_content_media_description_dup_properties (md);
  contact = tp_call_content_media_description_get_remote_contact (md);
  set_local_properties (self, contact, local_properties);
  set_remote_properties (self, contact, remote_properties);

out:
  g_simple_async_result_complete (self->priv->current_offer_result);
  g_clear_object (&self->priv->current_offer);
  g_clear_object (&self->priv->current_offer_result);
  g_clear_object (&self->priv->current_offer_cancellable);
  tp_svc_call_content_interface_media_emit_media_description_offer_done (self);

  next_offer (self);

  tp_clear_pointer (&local_properties, g_hash_table_unref);
  tp_clear_pointer (&remote_properties, g_hash_table_unref);
  g_object_unref (self);
}

static void
next_offer (TpBaseMediaCallContent *self)
{
  const gchar *object_path;
  GHashTable *properties;

  if (self->priv->current_offer_result != NULL)
    {
      DEBUG ("Waiting for the current offer to finish"
        " before starting the next one");
      return;
    }

  self->priv->current_offer_result = g_queue_pop_head (
      self->priv->outstanding_offers);
  if (self->priv->current_offer_result == NULL)
    {
      DEBUG ("No more offers outstanding");
      return;
    }

  g_assert (self->priv->current_offer == NULL);
  g_assert (self->priv->current_offer_cancellable == NULL);

  self->priv->current_offer = g_simple_async_result_get_op_res_gpointer (
      self->priv->current_offer_result);
  g_object_ref (self->priv->current_offer);
  self->priv->current_offer_cancellable = g_cancellable_new ();

  _tp_call_content_media_description_offer_async (self->priv->current_offer,
      self->priv->current_offer_cancellable,
      offer_finished_cb,
      g_object_ref (self));

  object_path = tp_call_content_media_description_get_object_path (
      self->priv->current_offer);
  properties = _tp_call_content_media_description_dup_properties (
      self->priv->current_offer);

  DEBUG ("emitting NewMediaDescriptionOffer: %s", object_path);
  tp_svc_call_content_interface_media_emit_new_media_description_offer (self,
      object_path, properties);
  g_hash_table_unref (properties);
}

/**
 * tp_base_media_call_content_get_local_media_description:
 * @self: a #TpBaseMediaCallContent
 * @contact: the contact
 *
 * Get the media description used to stream to @contact.
 *
 * Returns: borrowed #GHashTable mapping iface propery string to #GValue.
 * Since: 0.17.5
 */
GHashTable *
tp_base_media_call_content_get_local_media_description (
    TpBaseMediaCallContent *self,
    TpHandle contact)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_CONTENT (self), NULL);

  return g_hash_table_lookup (self->priv->local_media_descriptions,
      GUINT_TO_POINTER (contact));
}

/**
 * tp_base_media_call_content_offer_media_description_async:
 * @self: a #TpBaseMediaCallContent
 * @md: a #TpCallContentMediaDescription
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Offer @md for media description negociation.
 *
 * Since: 0.17.5
 */
void
tp_base_media_call_content_offer_media_description_async (
    TpBaseMediaCallContent *self,
    TpCallContentMediaDescription *md,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_BASE_MEDIA_CALL_CONTENT (self));
  g_return_if_fail (TP_IS_CALL_CONTENT_MEDIA_DESCRIPTION (md));

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_base_media_call_content_offer_media_description_async);

  g_simple_async_result_set_op_res_gpointer (result,
      g_object_ref (md), g_object_unref);

  g_queue_push_tail (self->priv->outstanding_offers, result);
  next_offer (self);
}

/**
 * tp_base_media_call_content_offer_media_description_finish:
 * @self: a #TpBaseMediaCallContent
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_base_media_call_content_offer_media_description_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_base_media_call_content_offer_media_description_finish (
    TpBaseMediaCallContent *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self,
      tp_base_media_call_content_offer_media_description_async);
}

static void
tp_base_media_call_content_update_local_media_description (
    TpSvcCallContentInterfaceMedia *iface,
    GHashTable *properties,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (iface);
  GHashTable *current_properties;
  GPtrArray *codecs;
  TpHandle contact;
  gboolean valid;

  contact = tp_asv_get_uint32 (properties,
      TP_PROP_CALL_CONTENT_MEDIA_DESCRIPTION_REMOTE_CONTACT, &valid);

  if (!valid)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "The media description is missing the RemoteContact key." };
      dbus_g_method_return_error (context, &error);
      return;
    }

  current_properties = g_hash_table_lookup (
      self->priv->local_media_descriptions,
      GUINT_TO_POINTER (contact));

  if (current_properties == NULL)
    {
      GError error = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "The initial MediaDescription object has not yet appeared" };
      dbus_g_method_return_error (context, &error);
      return;
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

  if (self->priv->current_offer != NULL &&
      tp_call_content_media_description_get_remote_contact (self->priv->current_offer) == contact)
    {
      GError error = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
                       "Can not update the media description while there is"
                       " an outstanding offer for this contact." };
      dbus_g_method_return_error (context, &error);
      return;
    }

  set_local_properties (self, contact, properties);

  tp_svc_call_content_interface_media_return_from_update_local_media_description
      (context);
}

static void
tp_base_media_call_content_fail (TpSvcCallContentInterfaceMedia *iface,
    const GValueArray *reason_array,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (iface);
  TpBaseCallContent *content = (TpBaseCallContent *) self;
  TpBaseCallChannel *channel;

  channel = _tp_base_call_content_get_channel (content);
  _tp_base_call_channel_remove_content_internal (channel, content,
      reason_array);

  tp_svc_call_content_interface_media_return_from_fail (context);
}

static void
tp_base_media_call_content_acknowledge_dtmf_change (
    TpSvcCallContentInterfaceMedia *iface,
    guchar in_Event,
    guint in_State,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (iface);

  if (self->priv->current_dtmf_event != in_Event)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "The acknoledgement is not for the right event"};
      dbus_g_method_return_error (context, &error);
      return;
    }

  if (in_State != TP_SENDING_STATE_SENDING &&
      in_State != TP_SENDING_STATE_NONE)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "The new sending state can not be a pending state"};
      dbus_g_method_return_error (context, &error);
      return;
    }

  if (in_State == self->priv->current_dtmf_state)
    goto out;

  if (self->priv->current_dtmf_state != TP_SENDING_STATE_PENDING_SEND &&
      self->priv->current_dtmf_state != TP_SENDING_STATE_PENDING_STOP_SENDING)
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Acknowledge rejected because we are not in a pending state"};
      dbus_g_method_return_error (context, &error);
      return;
    }

  if ((self->priv->current_dtmf_state == TP_SENDING_STATE_PENDING_SEND &&
          in_State != TP_SENDING_STATE_SENDING) ||
      (self->priv->current_dtmf_state ==
          TP_SENDING_STATE_PENDING_STOP_SENDING &&
          in_State != TP_SENDING_STATE_NONE))
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "The new sending state does not match the pending state"};
      dbus_g_method_return_error (context, &error);
      return;
    }

  /* Only tell the UI we are sending if we are actually sending */
  if (in_State == TP_SENDING_STATE_SENDING)
    tp_svc_call_content_interface_dtmf_emit_sending_tones (self,
        self->priv->currently_sending_tones);
  else if (in_State == TP_SENDING_STATE_NONE &&
      self->priv->currently_sending_tones &&
      self->priv->currently_sending_tones[0])
    self->priv->currently_sending_tones++;

  self->priv->current_dtmf_state = in_State;

  tp_base_media_call_content_dtmf_next (self);

out:

  tp_svc_call_content_interface_media_return_from_acknowledge_dtmf_change (
      context);
}


static void
call_content_media_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcCallContentInterfaceMediaClass *klass =
    (TpSvcCallContentInterfaceMediaClass *) g_iface;

#define IMPLEMENT(x) tp_svc_call_content_interface_media_implement_##x (\
    klass, tp_base_media_call_content_##x)
  IMPLEMENT(update_local_media_description);
  IMPLEMENT(acknowledge_dtmf_change);
  IMPLEMENT(fail);
#undef IMPLEMENT
}

gboolean
_tp_base_media_call_content_ready_to_accept (TpBaseMediaCallContent *self)
{
  TpBaseCallContent *bcc = TP_BASE_CALL_CONTENT (self);
  GList *item;
  gboolean ret = TRUE;
  gboolean initial = tp_base_call_content_get_disposition (bcc) ==
      TP_CALL_CONTENT_DISPOSITION_INITIAL;

  for (item = tp_base_call_content_get_streams (bcc); item; item = item->next)
    {
      TpBaseMediaCallStream *stream = item->data;
      GHashTable *members = _tp_base_call_stream_get_remote_members (
          TP_BASE_CALL_STREAM (stream));
      GHashTableIter iter;
      gpointer key, value;
      TpStreamFlowState receiving_state =
          tp_base_media_call_stream_get_receiving_state (stream);

      /* On incoming calls, start streaming (sending) when we accept the call,
       * if that was what the other side proposed
       */
      if (initial && !tp_base_channel_is_requested (
              TP_BASE_CHANNEL (_tp_base_call_content_get_channel (bcc))) &&
          tp_base_call_stream_get_local_sending_state (
              TP_BASE_CALL_STREAM (stream)) == TP_SENDING_STATE_PENDING_SEND)
        {
          tp_base_media_call_stream_set_local_sending (stream, TRUE);
        }
      tp_base_media_call_stream_update_sending_state (stream);

      g_hash_table_iter_init (&iter, members);
      while (g_hash_table_iter_next (&iter, &key, &value))
        {
          TpSendingState member_state = GPOINTER_TO_INT (value);

          if (member_state == TP_SENDING_STATE_PENDING_SEND ||
              member_state == TP_SENDING_STATE_SENDING)
            {
              tp_base_media_call_stream_update_receiving_state (stream);
              if (receiving_state != TP_STREAM_FLOW_STATE_STARTED)
                {
                  if (initial)
                    ret = FALSE;
                }
            }
        }
    }

  return ret;
}

void
_tp_base_media_call_content_remote_accepted (TpBaseMediaCallContent *self)
{
  TpBaseCallContent *bcc = TP_BASE_CALL_CONTENT (self);
  GList *l;

  if (tp_base_call_content_get_disposition (bcc) !=
      TP_CALL_CONTENT_DISPOSITION_INITIAL)
    return;

  for (l = tp_base_call_content_get_streams (bcc); l != NULL; l = l->next)
    {
      TpBaseMediaCallStream *stream = TP_BASE_MEDIA_CALL_STREAM (l->data);
      TpSendingState local = tp_base_call_stream_get_local_sending_state (
          TP_BASE_CALL_STREAM (stream));

      if (local == TP_SENDING_STATE_SENDING)
        tp_base_media_call_stream_set_local_sending (stream, TRUE);
      tp_base_media_call_stream_update_sending_state (stream);
    }
}

static gboolean
tp_base_media_call_content_start_tone (TpBaseCallContent *bcc,
    TpDTMFEvent event,
    GError **error)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (bcc);

  gchar buf[2] = { 0, 0 };

  if (tp_base_call_content_get_media_type (bcc) != TP_MEDIA_STREAM_TYPE_AUDIO)
    {
      g_set_error (error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
          "Method does not exist");
      return FALSE;
    }

  if (self->priv->currently_sending_tones != NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_SERVICE_BUSY,
          "Already sending a tone");
      return FALSE;
    }

  buf[0] = tp_dtmf_event_to_char (event);

  if (_tp_dtmf_char_classify (buf[0]) == DTMF_CHAR_CLASS_MEANINGLESS)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid DTMF event %s", buf);
      return FALSE;
    }

  self->priv->multiple_tones = FALSE;
  self->priv->requested_tones = g_strdup (buf);
  self->priv->currently_sending_tones = self->priv->requested_tones;

  g_free (self->priv->deferred_tones);
  self->priv->deferred_tones = NULL;

  tp_base_media_call_content_dtmf_next (self);

  return TRUE;
}

static gboolean
tp_base_media_call_content_stop_tone (TpBaseCallContent *bcc,
    GError **error)
{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (bcc);


  if (tp_base_call_content_get_media_type (bcc) != TP_MEDIA_STREAM_TYPE_AUDIO)
    {
      g_set_error (error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
          "Method does not exist");
      return FALSE;
    }

  if (self->priv->currently_sending_tones == NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "No tone is currently being played");
      return FALSE;
    }

  self->priv->currently_sending_tones = "";
  self->priv->tones_cancelled = TRUE;

  tp_base_media_call_content_dtmf_next (self);

  return TRUE;
}

static gboolean
tp_base_media_call_content_multiple_tones (TpBaseCallContent *bcc,
    const gchar *tones,
    GError **error)

{
  TpBaseMediaCallContent *self = TP_BASE_MEDIA_CALL_CONTENT (bcc);
  guint i;

  if (tp_base_call_content_get_media_type (bcc) != TP_MEDIA_STREAM_TYPE_AUDIO)
    {
      g_set_error (error, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD,
          "Method does not exist");
      return FALSE;
    }

  if (self->priv->currently_sending_tones != NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_SERVICE_BUSY,
          "Already sending a tone");
      return FALSE;
    }

  for (i = 0; tones[i] != '\0'; i++)
    {
      if (_tp_dtmf_char_classify (tones[i]) == DTMF_CHAR_CLASS_MEANINGLESS)
        {
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "Invalid character in DTMF string starting at %s",
              tones + i);
          return FALSE;
        }
    }

  self->priv->multiple_tones = TRUE;
  self->priv->requested_tones = g_strdup (tones);
  self->priv->currently_sending_tones = self->priv->requested_tones;
  g_free (self->priv->deferred_tones);
  self->priv->deferred_tones = NULL;

  tp_base_media_call_content_dtmf_next (self);

  return TRUE;
}

static gboolean
dtmf_pause_timeout_func (gpointer data)
{
  TpBaseMediaCallContent *self = data;

  self->priv->tones_pause_timeout_id = 0;

  tp_base_media_call_content_dtmf_next (self);

  return FALSE;
}

static void
channel_state_changed_cb (TpBaseCallChannel *channel, TpCallState state,
    TpCallFlags flags, gpointer reason, GHashTable *details,
    TpBaseMediaCallContent *self)
{
  if (state != TP_CALL_STATE_ACTIVE)
    return;

  if (self->priv->channel_state_changed_id != 0)
    {
      g_signal_handler_disconnect (self, self->priv->channel_state_changed_id);
      self->priv->channel_state_changed_id = 0;
    }

  tp_base_media_call_content_dtmf_next (self);
}

static void
tp_base_media_call_content_dtmf_next (TpBaseMediaCallContent *self)
{
  g_assert (self->priv->currently_sending_tones != NULL);

  switch (self->priv->current_dtmf_state)
    {
    case TP_SENDING_STATE_PENDING_SEND:
      if (self->priv->tones_cancelled)
        {
          self->priv->current_dtmf_state =
              TP_SENDING_STATE_PENDING_STOP_SENDING;
          tp_svc_call_content_interface_media_emit_dtmf_change_requested (self,
              self->priv->current_dtmf_event,
              self->priv->current_dtmf_state);
          return;
        }
      break;
    case TP_SENDING_STATE_PENDING_STOP_SENDING:
      /* Waiting on streaming implementation, do nothing */
      break;
    case TP_SENDING_STATE_SENDING:
      if (self->priv->tones_cancelled || self->priv->multiple_tones)
        {
          self->priv->current_dtmf_state =
              TP_SENDING_STATE_PENDING_STOP_SENDING;

          tp_svc_call_content_interface_media_emit_dtmf_change_requested (self,
              self->priv->current_dtmf_event,
              self->priv->current_dtmf_state);
        }
      break;
    case TP_SENDING_STATE_NONE:
      {
        gchar next;
        TpBaseCallChannel *channel = _tp_base_call_content_get_channel (
            TP_BASE_CALL_CONTENT (self));

        /* Waiting for timeout */
        if (self->priv->tones_pause_timeout_id != 0)
          return;

        if (channel &&
            tp_base_call_channel_get_state (channel) != TP_CALL_STATE_ACTIVE)
          {
            if (self->priv->channel_state_changed_id == 0)
              self->priv->channel_state_changed_id =
                  g_signal_connect (channel, "call-state-changed",
                      G_CALLBACK (channel_state_changed_cb), self);
            return;
          }

        next = self->priv->currently_sending_tones[0];

        if (next)
          {
            switch (_tp_dtmf_char_classify (next))
              {
              case DTMF_CHAR_CLASS_EVENT:
                self->priv->current_dtmf_event = _tp_dtmf_char_to_event (next);
                self->priv->current_dtmf_state = TP_SENDING_STATE_PENDING_SEND;

                tp_svc_call_content_interface_media_emit_dtmf_change_requested (
                    self, self->priv->current_dtmf_event,
                    self->priv->current_dtmf_state);
                break;
              case DTMF_CHAR_CLASS_PAUSE:
                self->priv->tones_pause_timeout_id = g_timeout_add (
                    DTMF_PAUSE_MS, dtmf_pause_timeout_func, self);
                tp_svc_call_content_interface_dtmf_emit_sending_tones (self,
                    self->priv->currently_sending_tones);
                break;
              case DTMF_CHAR_CLASS_WAIT_FOR_USER:
                self->priv->deferred_tones =
                    g_strdup (self->priv->currently_sending_tones + 1);
                self->priv->currently_sending_tones = "";
                tp_svc_call_content_interface_dtmf_emit_tones_deferred (self,
                    self->priv->deferred_tones);

                /* Let's stop here ! */
                goto done;
                break;
              default:
                g_assert_not_reached ();
              }
          }
        else
          {
          done:
            tp_svc_call_content_interface_dtmf_emit_stopped_tones (self,
                self->priv->tones_cancelled && self->priv->multiple_tones);
            self->priv->tones_cancelled = FALSE;
            g_free (self->priv->requested_tones);
            self->priv->requested_tones = NULL;
            self->priv->currently_sending_tones = NULL;
          }
      }
      break;
    default:
      g_assert_not_reached ();
    }
}

static GPtrArray *
tp_base_media_call_content_get_interfaces (TpBaseCallContent *bcc)
{
  GPtrArray *interfaces;

  interfaces = TP_BASE_CALL_CONTENT_CLASS (
      tp_base_media_call_content_parent_class)->get_interfaces (bcc);

  g_ptr_array_add (interfaces, TP_IFACE_CALL_CONTENT_INTERFACE_MEDIA);

  if (tp_base_call_content_get_media_type (bcc) == TP_MEDIA_STREAM_TYPE_AUDIO)
    g_ptr_array_add (interfaces, TP_IFACE_CALL_CONTENT_INTERFACE_DTMF);

  return interfaces;
}
