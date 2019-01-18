/*
 * base-call-channel.c - Source for TpBaseCallChannel
 * Copyright © 2009–2011 Collabora Ltd.
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
 * SECTION:base-call-channel
 * @title: TpBaseCallChannel
 * @short_description: base class for #TpSvcChannelTypeCall implementations
 * @see_also: #TpSvcChannelTypeCall, #TpBaseCallContent and #TpBaseCallStream
 *
 * This base class makes it easier to write #TpSvcChannelTypeCall
 * implementations by implementing its properties, and some of its methods.
 *
 * Subclasses should fill in #TpBaseCallChannelClass.accept,
 * #TpBaseCallChannelClass.add_content and #TpBaseCallChannelClass.hangup
 * virtual function.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallChannel:
 *
 * A base class for call channel implementations
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallChannelClass:
 * @set_ringing: Notify members that client is ringing.
 * @set_queued: Notify members that call is queued.
 * @accept: accept the call. Note that #TpBaseMediaCallChannel subclasses should
 *  not override this virtual method, but #TpBaseMediaCallChannelClass.accept
 *  instead.
 * @add_content: add content to the call. Implementation must call
 *  tp_base_call_channel_add_content(). Can be %NULL if
 *  #TpBaseCallChannel:mutable-contents is %FALSE.
 * @hangup: hangup the call.
 *
 * The class structure for #TpBaseCallChannel
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallChannelVoidFunc:
 * @self: a #TpBaseCallChannel
 *
 * Signature of an implementation of #TpBaseCallChannelClass.set_ringing,
 * #TpBaseCallChannelClass.set_queued and #TpBaseCallChannelClass.accept.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallChannelAddContentFunc:
 * @self: a #TpBaseCallChannel
 * @name: the name for the new content
 * @media: a #TpMediaStreamType
 * @initial_direction: the desired initial direction of streams in the new
 *  content
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallChannelClass.add_content.
 *
 * Returns: a borrowed #TpBaseCallContent.
 * Since: 0.17.5
 */

/**
 * TpBaseCallChannelHangupFunc:
 * @self: a #TpBaseCallChannel
 * @reason: the #TpCallStateChangeReason of the change
 * @detailed_reason: a more specific reason for the call hangup, if one is
 *  available, or an empty string otherwise.
 * @message: a human-readable message to be sent to the remote contact(s).
 *
 * Signature of an implementation of #TpBaseCallChannelClass.hangup.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "base-call-channel.h"

#define DEBUG_FLAG TP_DEBUG_CALL

#include "telepathy-glib/base-call-content.h"
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-media-call-stream.h"
#include "telepathy-glib/base-connection.h"
#include "telepathy-glib/channel-iface.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/enums.h"
#include "telepathy-glib/exportable-channel.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-channel.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/util.h"

static void call_iface_init (gpointer, gpointer);
static void dtmf_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseCallChannel, tp_base_call_channel,
  TP_TYPE_BASE_CHANNEL,

  G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_TYPE_CALL,
        call_iface_init)
  G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_DTMF,
        dtmf_iface_init)
  )

/* properties */
enum
{
  PROP_INITIAL_AUDIO = 1,
  PROP_INITIAL_VIDEO,
  PROP_INITIAL_AUDIO_NAME,
  PROP_INITIAL_VIDEO_NAME,
  PROP_INITIAL_TRANSPORT,
  PROP_MUTABLE_CONTENTS,
  PROP_HARDWARE_STREAMING,

  PROP_CONTENTS,

  PROP_CALL_STATE,
  PROP_CALL_FLAGS,
  PROP_CALL_STATE_DETAILS,
  PROP_CALL_STATE_REASON,

  PROP_CALL_MEMBERS,
  PROP_MEMBER_IDENTIFIERS,

  PROP_INITIAL_TONES,

  LAST_PROPERTY
};

/* private structure */
struct _TpBaseCallChannelPrivate
{
  /* GList of reffed TpBaseCallContent */
  GList *contents;
  gboolean mutable_contents;

  TpStreamTransportType initial_transport;
  gboolean initial_audio;
  gboolean initial_video;
  gchar *initial_audio_name;
  gchar *initial_video_name;
  gchar *initial_tones;

  gboolean locally_accepted;
  gboolean accepted;

  TpCallState state;
  TpCallFlags flags;
  GHashTable *details;
  GValueArray *reason;

  /* TpHandle => TpCallMemberFlags */
  GHashTable *call_members;
};

static void tp_base_call_channel_accept_real (TpBaseCallChannel *self);

GHashTable *
_tp_base_call_dup_member_identifiers (TpBaseConnection *conn,
    GHashTable *source)
{
  GHashTable *identifiers;
  TpHandleRepoIface *contact_repo;
  GHashTableIter iter;
  gpointer key;

  identifiers = g_hash_table_new (NULL, NULL);

  contact_repo = tp_base_connection_get_handles (conn, TP_HANDLE_TYPE_CONTACT);

  g_hash_table_iter_init (&iter, source);
  while (g_hash_table_iter_next (&iter, &key, NULL))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      const gchar *id = tp_handle_inspect (contact_repo, handle);

      g_hash_table_insert (identifiers, key, (gpointer) id);
    }

  return identifiers;
}

GValueArray *
_tp_base_call_state_reason_new (TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  return tp_value_array_build (4,
      G_TYPE_UINT, actor_handle,
      G_TYPE_UINT, reason,
      G_TYPE_STRING, dbus_reason != NULL ? dbus_reason : "",
      G_TYPE_STRING, message != NULL ? message : "",
      G_TYPE_INVALID);
}

static void
tp_base_call_channel_init (TpBaseCallChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_CALL_CHANNEL, TpBaseCallChannelPrivate);

  self->priv->reason = _tp_base_call_state_reason_new (0, 0, "", "");
  self->priv->details = tp_asv_new (NULL, NULL);
  self->priv->call_members = g_hash_table_new (g_direct_hash, g_direct_equal);
}

static void
tp_base_call_channel_constructed (GObject *obj)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (obj);
  TpBaseChannel *base = TP_BASE_CHANNEL (self);

  if (G_OBJECT_CLASS (tp_base_call_channel_parent_class)->constructed
      != NULL)
    G_OBJECT_CLASS (tp_base_call_channel_parent_class)->constructed (obj);

  if (tp_base_channel_is_requested (base))
    {
      tp_base_call_channel_set_state (self,
          TP_CALL_STATE_PENDING_INITIATOR, tp_base_channel_get_initiator (base),
          TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
          "User requested channel");
    }
  else
    {
      tp_base_call_channel_set_state (self,
          TP_CALL_STATE_INITIALISING, tp_base_channel_get_initiator (base),
          TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "",
          "Incoming call");
    }
}

static void
content_list_destroy (GList *contents)
{
  g_list_foreach (contents, (GFunc) _tp_base_call_content_deinit, NULL);
  g_list_free_full (contents, g_object_unref);
}

static void
tp_base_call_channel_dispose (GObject *object)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (object);

  tp_clear_pointer (&self->priv->contents, content_list_destroy);
  tp_clear_pointer (&self->priv->call_members, g_hash_table_unref);

  if (G_OBJECT_CLASS (tp_base_call_channel_parent_class)->dispose)
    G_OBJECT_CLASS (tp_base_call_channel_parent_class)->dispose (object);
}

static void
tp_base_call_channel_finalize (GObject *object)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (object);

  g_hash_table_unref (self->priv->details);
  tp_value_array_free (self->priv->reason);
  g_free (self->priv->initial_audio_name);
  g_free (self->priv->initial_video_name);
  g_free (self->priv->initial_tones);

  G_OBJECT_CLASS (tp_base_call_channel_parent_class)->finalize (object);
}

static void
tp_base_call_channel_close (TpBaseChannel *base)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (base);

  DEBUG ("Closing call channel %s", tp_base_channel_get_object_path (base));

  /* shutdown all our contents */
  tp_clear_pointer (&self->priv->contents, content_list_destroy);

  tp_base_channel_destroyed (base);
}

static void
tp_base_call_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (object);

  switch (property_id)
    {
      case PROP_INITIAL_AUDIO:
        g_value_set_boolean (value, self->priv->initial_audio);
        break;
      case PROP_INITIAL_VIDEO:
        g_value_set_boolean (value, self->priv->initial_video);
        break;
      case PROP_INITIAL_AUDIO_NAME:
        g_value_set_string (value, self->priv->initial_audio_name);
        break;
      case PROP_INITIAL_VIDEO_NAME:
        g_value_set_string (value, self->priv->initial_video_name);
        break;
      case PROP_INITIAL_TRANSPORT:
        g_value_set_uint (value, self->priv->initial_transport);
        break;
      case PROP_MUTABLE_CONTENTS:
          g_value_set_boolean (value, self->priv->mutable_contents);
        break;
      case PROP_CONTENTS:
        {
          GPtrArray *arr = g_ptr_array_sized_new (2);
          GList *l;

          for (l = self->priv->contents; l != NULL; l = g_list_next (l))
            {
              TpBaseCallContent *c = TP_BASE_CALL_CONTENT (l->data);
              g_ptr_array_add (arr,
                  g_strdup (tp_base_call_content_get_object_path (c)));
            }

          g_value_take_boxed (value, arr);
          break;
        }
      case PROP_HARDWARE_STREAMING:
        g_value_set_boolean (value, FALSE);
        break;
      case PROP_CALL_STATE:
        g_value_set_uint (value, self->priv->state);
        break;
      case PROP_CALL_FLAGS:
        g_value_set_uint (value, self->priv->flags);
        break;
      case PROP_CALL_STATE_DETAILS:
        g_value_set_boxed (value, self->priv->details);
        break;
      case PROP_CALL_STATE_REASON:
        g_value_set_boxed (value, self->priv->reason);
        break;
      case PROP_CALL_MEMBERS:
        g_value_set_boxed (value, self->priv->call_members);
        break;
      case PROP_MEMBER_IDENTIFIERS:
        {
          GHashTable *identifiers;

          identifiers = _tp_base_call_dup_member_identifiers (
              tp_base_channel_get_connection ((TpBaseChannel *) self),
              self->priv->call_members);
          g_value_take_boxed (value, identifiers);
          break;
        }
      case PROP_INITIAL_TONES:
        g_value_set_string (value, self->priv->initial_tones);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_call_channel_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (object);

  switch (property_id)
    {
      case PROP_INITIAL_AUDIO:
        self->priv->initial_audio = g_value_get_boolean (value);
        break;
      case PROP_INITIAL_VIDEO:
        self->priv->initial_video = g_value_get_boolean (value);
        break;
      case PROP_INITIAL_AUDIO_NAME:
        self->priv->initial_audio_name = g_value_dup_string (value);
        break;
      case PROP_INITIAL_VIDEO_NAME:
        self->priv->initial_video_name = g_value_dup_string (value);
        break;
      case PROP_INITIAL_TRANSPORT:
        self->priv->initial_transport = g_value_get_uint (value);
        break;
      case PROP_MUTABLE_CONTENTS:
        self->priv->mutable_contents = g_value_get_boolean (value);
        break;
      case PROP_INITIAL_TONES:
        self->priv->initial_tones = g_value_dup_string (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_base_call_channel_fill_immutable_properties (
    TpBaseChannel *chan,
    GHashTable *properties)
{
  TP_BASE_CHANNEL_CLASS (tp_base_call_channel_parent_class)
      ->fill_immutable_properties (chan, properties);

  tp_dbus_properties_mixin_fill_properties_hash (
      G_OBJECT (chan), properties,
      TP_IFACE_CHANNEL_TYPE_CALL, "InitialTransport",
      TP_IFACE_CHANNEL_TYPE_CALL, "InitialAudio",
      TP_IFACE_CHANNEL_TYPE_CALL, "InitialVideo",
      TP_IFACE_CHANNEL_TYPE_CALL, "InitialAudioName",
      TP_IFACE_CHANNEL_TYPE_CALL, "InitialVideoName",
      TP_IFACE_CHANNEL_TYPE_CALL, "MutableContents",
      TP_IFACE_CHANNEL_TYPE_CALL, "HardwareStreaming",
      TP_IFACE_CHANNEL_INTERFACE_DTMF, "InitialTones",
      NULL);
}

static void
tp_base_call_channel_class_init (TpBaseCallChannelClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  TpBaseChannelClass *base_channel_class = TP_BASE_CHANNEL_CLASS (klass);
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl call_props[] = {
      { "Contents", "contents", NULL },
      { "CallStateDetails", "call-state-details", NULL },
      { "CallState", "call-state", NULL },
      { "CallFlags", "call-flags", NULL },
      { "CallStateReason",  "call-state-reason", NULL },
      { "HardwareStreaming", "hardware-streaming", NULL },
      { "CallMembers", "call-members", NULL },
      { "MemberIdentifiers", "member-identifiers", NULL },
      { "InitialTransport", "initial-transport", NULL },
      { "InitialAudio", "initial-audio", NULL },
      { "InitialVideo", "initial-video", NULL },
      { "InitialAudioName", "initial-audio-name", NULL },
      { "InitialVideoName", "initial-video-name", NULL },
      { "MutableContents", "mutable-contents", NULL },
      { NULL },
  };
  static TpDBusPropertiesMixinPropImpl dtmf_props[] = {
      { "InitialTones", "initial-tones", NULL },
      { NULL },
  };

  g_type_class_add_private (klass, sizeof (TpBaseCallChannelPrivate));

  object_class->constructed = tp_base_call_channel_constructed;

  object_class->get_property = tp_base_call_channel_get_property;
  object_class->set_property = tp_base_call_channel_set_property;

  object_class->dispose = tp_base_call_channel_dispose;
  object_class->finalize = tp_base_call_channel_finalize;

  base_channel_class->channel_type = TP_IFACE_CHANNEL_TYPE_CALL;
  base_channel_class->fill_immutable_properties =
      tp_base_call_channel_fill_immutable_properties;
  base_channel_class->close = tp_base_call_channel_close;

  klass->accept = tp_base_call_channel_accept_real;

  /**
   * TpBaseCallChannel:initial-audio:
   *
   * If set to %TRUE on a requested channel, subclass should immediately attempt
   * to establish an audio stream to the remote contact.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("initial-audio", "InitialAudio",
      "Whether the channel initially contained an audio stream",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_AUDIO,
      param_spec);

  /**
   * TpBaseCallChannel:initial-video:
   *
   * If set to %TRUE on a requested channel, subclass should immediately attempt
   * to establish a video stream to the remote contact.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("initial-video", "InitialVideo",
      "Whether the channel initially contained an video stream",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_VIDEO,
      param_spec);

  /**
   * TpBaseCallChannel:initial-audio-name:
   *
   * Name to use to create the audio #TpBaseCallContent if
   * #TpBaseCallChannel:initial-audio is set to %TRUE.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("initial-audio-name", "InitialAudioName",
      "Name for the initial audio content",
      "audio",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_AUDIO_NAME,
      param_spec);

  /**
   * TpBaseCallChannel:initial-video-name:
   *
   * Name to use to create the video #TpBaseCallContent if
   * #TpBaseCallChannel:initial-video is set to %TRUE.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("initial-video-name", "InitialVideoName",
      "Name for the initial video content",
      "video",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_VIDEO_NAME,
      param_spec);

  /**
   * TpBaseCallChannel:initial-transport:
   *
   * If set to %TRUE on a requested channel, this indicates the transport that
   * should be used for this call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("initial-transport", "InitialTransport",
      "The transport that should be used for this call",
      0, G_MAXUINT, TP_STREAM_TRANSPORT_TYPE_UNKNOWN,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_TRANSPORT,
      param_spec);

  /**
   * TpBaseCallChannel:mutable-contents:
   *
   * Indicate to clients whether or not they can add/remove contents.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("mutable-contents", "MutableContents",
      "Whether the set of streams on this channel are mutable once requested",
      FALSE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MUTABLE_CONTENTS,
      param_spec);

  /**
   * TpBaseCallChannel:contents:
   *
   * #GPtrArray of object-paths of the #TpBaseCallContent objects.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("contents", "Contents",
      "The contents of the channel",
      TP_ARRAY_TYPE_OBJECT_PATH_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTENTS,
      param_spec);

  /**
   * TpBaseCallChannel:hardware-streaming:
   *
   * Indicate to clients whether or not this Connection Manager has hardware
   * streaming.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("hardware-streaming", "HardwareStreaming",
      "True if all the streaming is done by hardware",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HARDWARE_STREAMING,
      param_spec);

  /**
   * TpBaseCallChannel:call-state:
   *
   * The state of this call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("call-state", "CallState",
      "The status of the call",
      0, G_MAXUINT, TP_CALL_STATE_UNKNOWN,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALL_STATE, param_spec);

  /**
   * TpBaseCallChannel:call-flags:
   *
   * The flags of this call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("call-flags", "CallFlags",
      "Flags representing the status of the call",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALL_FLAGS,
      param_spec);

  /**
   * TpBaseCallChannel:call-state-reason:
   *
   * The reason for last call state change.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("call-state-reason", "CallStateReason",
      "The reason why the call is in the current state",
      TP_STRUCT_TYPE_CALL_STATE_REASON,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALL_STATE_REASON,
      param_spec);

  /**
   * TpBaseCallChannel:call-state-details:
   *
   * Details on the call state.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("call-state-details", "CallStateDetails",
      "The reason why the call is in the current state",
      TP_HASH_TYPE_QUALIFIED_PROPERTY_VALUE_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALL_STATE_DETAILS,
      param_spec);

  /**
   * TpBaseCallChannel:call-members:
   *
   * #GHashTable mapping #TpHandle of each call member to their
   * #TpCallMemberFlags.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("call-members", "CallMembers",
      "The members",
      TP_HASH_TYPE_CALL_MEMBER_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALL_MEMBERS,
      param_spec);

  /**
   * TpBaseCallChannel:member-identifiers:
   *
   * #GHashTable mapping #TpHandle of each call member to their identifiers.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("member-identifiers",
      "MemberIdentifiers", "The members identifiers",
      TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MEMBER_IDENTIFIERS,
      param_spec);


  /**
   * TpBaseCallChannel:initial-tones:
   *
   * DTMF Tones to be played on the channel created.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("initial-tones",
      "InitialTones", "DTMF Tones to be played on the channel created"
      " by InitialAudio",
      "",
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INITIAL_TONES,
      param_spec);

  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CHANNEL_TYPE_CALL,
      tp_dbus_properties_mixin_getter_gobject_properties,
      NULL,
      call_props);

  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_DTMF,
      tp_dbus_properties_mixin_getter_gobject_properties,
      NULL,
      dtmf_props);
}

static const char *
call_state_to_string (TpCallState state)
{
  const char *state_str = "INEXISTANT";
  switch (state)
    {
    case TP_CALL_STATE_UNKNOWN:
      state_str = "UNKNOWN";
      break;
    case TP_CALL_STATE_PENDING_INITIATOR:
      state_str = "PENDING_INITIATOR";
      break;
    case TP_CALL_STATE_INITIALISING:
      state_str = "INITIALISING";
      break;
    case TP_CALL_STATE_INITIALISED:
      state_str = "INITIALISED";
      break;
    case TP_CALL_STATE_ACCEPTED:
      state_str = "ACCEPTED";
      break;
    case TP_CALL_STATE_ACTIVE:
      state_str = "ACTIVE";
      break;
    case TP_CALL_STATE_ENDED:
      state_str = "ENDED";
      break;
    }

  return state_str;
}

static void
tp_base_call_channel_flags_changed (TpBaseCallChannel *self,
    guint actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  tp_value_array_free (self->priv->reason);
  self->priv->reason = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  if (tp_base_channel_is_registered (TP_BASE_CHANNEL (self)))
    {
      tp_svc_channel_type_call_emit_call_state_changed (self,
          self->priv->state, self->priv->flags, self->priv->reason,
          self->priv->details);
    }
}

/**
 * tp_base_call_channel_set_state:
 * @self: a #TpBaseCallChannel
 * @state: the new #TpCallState
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Changes the call state and emit StateChanged signal with the new state.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_set_state (TpBaseCallChannel *self,
    TpCallState state,
    guint actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  TpCallState old_state;

  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (self));

  old_state = self->priv->state;

  self->priv->state = state;
  tp_value_array_free (self->priv->reason);
  self->priv->reason = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  if (old_state == state)
    return;

  if (self->priv->state != TP_CALL_STATE_INITIALISED)
    self->priv->flags &= ~TP_CALL_FLAG_LOCALLY_RINGING;

  if (self->priv->state != TP_CALL_STATE_INITIALISING &&
      self->priv->state != TP_CALL_STATE_INITIALISED)
    self->priv->flags &= ~TP_CALL_FLAG_LOCALLY_QUEUED;

  if (tp_base_channel_is_registered (TP_BASE_CHANNEL (self)))
    {
      tp_svc_channel_type_call_emit_call_state_changed (self, self->priv->state,
          self->priv->flags, self->priv->reason, self->priv->details);
    }

  DEBUG ("state changed from %s => %s",
      call_state_to_string (old_state),
      call_state_to_string (self->priv->state));

  /* Move from INITIALISING to INITIALISED if we are already connected */
  if (self->priv->state == TP_CALL_STATE_INITIALISING &&
      _tp_base_call_channel_is_connected (self))
    {
      self->priv->state = TP_CALL_STATE_INITIALISED;
      if (tp_base_channel_is_registered (TP_BASE_CHANNEL (self)))
        {
          tp_svc_channel_type_call_emit_call_state_changed (self,
              self->priv->state, self->priv->flags, self->priv->reason,
              self->priv->details);
        }

      DEBUG ("state changed from %s => %s (bumped)",
          call_state_to_string (TP_CALL_STATE_INITIALISING),
          call_state_to_string (self->priv->state));
    }

  /* Move from ACCEPTED to ACTIVE if we are already connected */
  if (self->priv->state == TP_CALL_STATE_ACCEPTED &&
      _tp_base_call_channel_is_connected (self))
    {
      self->priv->state = TP_CALL_STATE_ACTIVE;
      if (tp_base_channel_is_registered (TP_BASE_CHANNEL (self)))
        {
          tp_svc_channel_type_call_emit_call_state_changed (self,
              self->priv->state, self->priv->flags, self->priv->reason,
              self->priv->details);
        }

      DEBUG ("state changed from %s => %s (bumped)",
          call_state_to_string (TP_CALL_STATE_ACCEPTED),
          call_state_to_string (self->priv->state));
    }
}

/**
 * tp_base_call_channel_get_state:
 * @self: a #TpBaseCallChannel
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallChannel:call-state
 * Since: 0.17.5
 */
TpCallState
tp_base_call_channel_get_state (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), TP_CALL_STATE_UNKNOWN);

  return self->priv->state;
}

/**
 * tp_base_call_channel_has_initial_audio:
 * @self: a #TpBaseCallChannel
 * @initial_audio_name: (out) (allow-none) (transfer none): a place to set the
 *  value of #TpBaseCallChannel:initial-audio-name
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallChannel:initial-audio
 * Since: 0.17.5
 */
gboolean
tp_base_call_channel_has_initial_audio (TpBaseCallChannel *self,
    const gchar **initial_audio_name)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), FALSE);

  if (initial_audio_name != NULL)
    *initial_audio_name = self->priv->initial_audio_name;

  return self->priv->initial_audio;
}

/**
 * tp_base_call_channel_has_initial_video:
 * @self: a #TpBaseCallChannel
 * @initial_video_name: (out) (allow-none) (transfer none): a place to set the
 *  value of #TpBaseCallChannel:initial-video-name
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallChannel:initial-video
 * Since: 0.17.5
 */
gboolean
tp_base_call_channel_has_initial_video (TpBaseCallChannel *self,
    const gchar **initial_video_name)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), FALSE);

  if (initial_video_name != NULL)
    *initial_video_name = self->priv->initial_video_name;

  return self->priv->initial_video;
}

/**
 * tp_base_call_channel_has_mutable_contents:
 * @self: a #TpBaseCallChannel
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallChannel:mutable-contents
 * Since: 0.17.5
 */
gboolean
tp_base_call_channel_has_mutable_contents (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), FALSE);

  return self->priv->mutable_contents;
}

/**
 * tp_base_call_channel_get_contents:
 * @self: a #TpBaseCallChannel
 *
 * Get the contents of this call. The #GList and its elements must not be freed
 * and should be copied before doing any modification.
 *
 * Returns: a #GList of #TpBaseCallContent
 * Since: 0.17.5
 */
GList *
tp_base_call_channel_get_contents (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), NULL);

  return self->priv->contents;
}

void
_tp_base_call_channel_remove_content_internal (TpBaseCallChannel *self,
    TpBaseCallContent *content,
    const GValueArray *reason_array)
{
  GList *l;
  const gchar *path;

  l = g_list_find (self->priv->contents, content);
  g_return_if_fail (l != NULL);

  self->priv->contents = g_list_delete_link (self->priv->contents, l);
  g_object_notify (G_OBJECT (self), "contents");

  path = tp_base_call_content_get_object_path (
      TP_BASE_CALL_CONTENT (content));
  tp_svc_channel_type_call_emit_content_removed (self, path, reason_array);

  _tp_base_call_content_deinit (TP_BASE_CALL_CONTENT (content));
  g_object_unref (content);
}

/**
 * tp_base_call_channel_remove_content:
 * @self: a #TpBaseCallChannel
 * @content: a #TpBaseCallContent to remove
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Remove @content from @self.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_remove_content (TpBaseCallChannel *self,
    TpBaseCallContent *content,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  GValueArray *reason_array;

  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (self));
  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (content));

  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  _tp_base_call_channel_remove_content_internal (self, content, reason_array);

  tp_value_array_free (reason_array);
}

/**
 * tp_base_call_channel_add_content:
 * @self: a #TpBaseCallChannel
 * @content: a #TpBaseCallContent to add
 *
 * Add @content to @self. If @content's #TpBaseCallContent:disposition is
 * %TP_CALL_CONTENT_DISPOSITION_INITIAL, also set
 * #TpBaseCallChannel:initial-audio and #TpBaseCallChannel:initial-audio-name
 * properties (or #TpBaseCallChannel:initial-video and
 * #TpBaseCallChannel:initial-video-name).
 * Note that it is not allowed to add INITIAL contents after having registered
 * @self on the bus.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_add_content (TpBaseCallChannel *self,
    TpBaseCallContent *content)
{
  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (self));
  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (content));
  g_return_if_fail (tp_base_call_content_get_connection (content) ==
      tp_base_channel_get_connection ((TpBaseChannel *) self));
  g_return_if_fail (g_list_find (self->priv->contents, content) == NULL);

  self->priv->contents = g_list_prepend (self->priv->contents,
      g_object_ref (content));
  _tp_base_call_content_set_channel (content, self);
  g_object_notify (G_OBJECT (self), "contents");

  if (tp_base_call_content_get_disposition (content) ==
      TP_CALL_CONTENT_DISPOSITION_INITIAL)
    {
      if (tp_base_channel_is_registered ((TpBaseChannel *) self))
        {
          WARNING ("Adding a content with TP_CALL_CONTENT_DISPOSITION_INITIAL "
              "after channel has been registered on the bus is not allowed."
              "Initial contents are supposed immutable");
        }
      else if (tp_base_call_content_get_media_type (content) ==
          TP_MEDIA_STREAM_TYPE_AUDIO)
        {
          self->priv->initial_audio = TRUE;
          g_free (self->priv->initial_audio_name);
          self->priv->initial_audio_name = g_strdup (
              tp_base_call_content_get_name (content));
        }
      else if (tp_base_call_content_get_media_type (content) ==
          TP_MEDIA_STREAM_TYPE_VIDEO)
        {
          self->priv->initial_video = TRUE;
          g_free (self->priv->initial_video_name);
          self->priv->initial_video_name = g_strdup (
              tp_base_call_content_get_name (content));
        }
    }

  tp_svc_channel_type_call_emit_content_added (self,
     tp_base_call_content_get_object_path (content));
}

/**
 * tp_base_call_channel_update_member_flags:
 * @self: a #TpBaseCallChannel
 * @contact: the contact to update
 * @new_flags: the new #TpCallMemberFlags of @contact
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Add or update @contact call member with @flags flags.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_update_member_flags (TpBaseCallChannel *self,
    TpHandle contact,
    TpCallMemberFlags new_flags,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  gpointer flags_p;
  gboolean exists;
  GHashTable *updates;
  GHashTable *identifiers;
  GArray *empty_array;
  GValueArray *reason_array;

  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (self));

  exists = g_hash_table_lookup_extended (self->priv->call_members,
      GUINT_TO_POINTER (contact), NULL, &flags_p);

  if (exists && GPOINTER_TO_UINT (flags_p) == new_flags)
    return;

  DEBUG ("Member %d (flags: %d) updated", contact, new_flags);

  g_hash_table_insert (self->priv->call_members,
      GUINT_TO_POINTER (contact),
      GUINT_TO_POINTER (new_flags));

  updates = g_hash_table_new (NULL, NULL);
  g_hash_table_insert (updates,
      GUINT_TO_POINTER (contact),
      GUINT_TO_POINTER (new_flags));
  identifiers = _tp_base_call_dup_member_identifiers (
      tp_base_channel_get_connection ((TpBaseChannel *) self),
      updates);
  empty_array = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  tp_svc_channel_type_call_emit_call_members_changed (self,
      updates, identifiers, empty_array, reason_array);

  g_hash_table_unref (updates);
  g_hash_table_unref (identifiers);
  g_array_unref (empty_array);
  tp_value_array_free (reason_array);
}

/**
 * tp_base_call_channel_remove_member:
 * @self: a #TpBaseCallChannel
 * @contact: the contact to remove
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Remove @contact from call members.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_remove_member (TpBaseCallChannel *self,
    TpHandle contact,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  GHashTable *empty_table;
  GArray *removed;
  GValueArray *reason_array;

  g_return_if_fail (TP_IS_BASE_CALL_CHANNEL (self));

  if (!g_hash_table_remove (self->priv->call_members,
          GUINT_TO_POINTER (contact)))
    return;

  DEBUG ("Member %d removed", contact);

  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);
  empty_table = g_hash_table_new (NULL, NULL);
  removed = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  g_array_append_val (removed, contact);

  tp_svc_channel_type_call_emit_call_members_changed (self,
      empty_table, empty_table, removed, reason_array);

  g_hash_table_unref (empty_table);
  g_array_unref (removed);
  tp_value_array_free (reason_array);
}

/**
 * tp_base_call_channel_get_call_members:
 * @self: a #TpBaseCallChannel
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallChannel:call-members.
 * Since: 0.17.5
 */
GHashTable *
tp_base_call_channel_get_call_members (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), NULL);

  return self->priv->call_members;
}

/**
 * tp_base_call_channel_remote_accept:
 * @self: a #TpBaseCallChannel
 *
 * Must be called when the remote contact accepted the call.
 * #TpBaseCallChannel:call-state must be either %TP_CALL_STATE_INITIALISED or
 * %TP_CALL_STATE_INITIALISING and will then change to %TP_CALL_STATE_ACCEPTED.
 *
 * Must be used only for outgoing calls.
 *
 * Since: 0.17.5
 */
void
tp_base_call_channel_remote_accept (TpBaseCallChannel *self)
{
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);

  g_return_if_fail (tp_base_channel_is_requested (TP_BASE_CHANNEL (self)));

  if (self->priv->accepted)
    return;

  g_return_if_fail (self->priv->state == TP_CALL_STATE_INITIALISED ||
      self->priv->state == TP_CALL_STATE_INITIALISING);

  self->priv->accepted = TRUE;

  tp_base_call_channel_set_state (self,
      TP_CALL_STATE_ACCEPTED,
      tp_base_channel_get_target_handle (TP_BASE_CHANNEL (self)),
      TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "", "");

  if (klass->remote_accept)
    klass->remote_accept (self);
}

/**
 * tp_base_call_channel_is_accepted:
 * @self: a #TpBaseCallChannel
 *
 * <!-- -->
 *
 * Returns: Whether or not the call has been remotely accepted.
 * Since: 0.17.5
 */
gboolean
tp_base_call_channel_is_accepted (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), FALSE);

  return self->priv->accepted;
}

/* DBus method implementation */

static void
tp_base_call_channel_set_ringing (TpSvcChannelTypeCall *iface,
    DBusGMethodInvocation *context)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (iface);
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);
  TpBaseChannel *tp_base = TP_BASE_CHANNEL (self);

  if (tp_base_channel_is_requested (tp_base))
    {
      GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Call was requested. Ringing doesn't make sense." };
      dbus_g_method_return_error (context, &e);
    }
  else if (self->priv->state != TP_CALL_STATE_INITIALISED)
    {
      GError e = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Call is not in the right state for Ringing." };
      dbus_g_method_return_error (context, &e);
    }
  else
    {
      if ((self->priv->flags & TP_CALL_FLAG_LOCALLY_RINGING) == 0)
        {
          DEBUG ("Client is ringing");

          if (klass->set_ringing != NULL)
            klass->set_ringing (self);

          self->priv->flags |= TP_CALL_FLAG_LOCALLY_RINGING;
          self->priv->flags &= ~TP_CALL_FLAG_LOCALLY_QUEUED;
          tp_base_call_channel_flags_changed (self,
              tp_base_channel_get_self_handle ((TpBaseChannel *) self),
              TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "",
              "Local client has started ringing");
        }

      tp_svc_channel_type_call_return_from_set_ringing (context);
    }
}

static void
tp_base_call_channel_set_queued (TpSvcChannelTypeCall *iface,
    DBusGMethodInvocation *context)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (iface);
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);
  TpBaseChannel *tp_base = TP_BASE_CHANNEL (self);

  if (tp_base_channel_is_requested (tp_base))
    {
      GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Call was requested. Queued doesn't make sense." };
      dbus_g_method_return_error (context, &e);
    }
  else if (self->priv->state != TP_CALL_STATE_INITIALISING &&
           self->priv->state != TP_CALL_STATE_INITIALISED)
    {
      GError e = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Call is not in the right state for Queuing." };
      dbus_g_method_return_error (context, &e);
    }
  else
    {
      if ((self->priv->flags & TP_CALL_FLAG_LOCALLY_QUEUED) == 0)
        {
          DEBUG ("Call is queued");

          if (klass->set_queued != NULL)
            klass->set_queued (self);

          self->priv->flags |= TP_CALL_FLAG_LOCALLY_QUEUED;
          tp_base_call_channel_flags_changed (self,
              tp_base_channel_get_self_handle ((TpBaseChannel *) self),
              TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "",
              "Local client has queued the call");
        }

      tp_svc_channel_type_call_return_from_set_queued (context);
    }
}

static void
raise_accept_state_error (TpBaseCallChannel *self,
    TpCallState expected,
    DBusGMethodInvocation *context)
{
  GError *e = NULL;

  e = g_error_new (TP_ERROR, TP_ERROR_NOT_AVAILABLE,
      "Invalid state for Accept (expected: %s, current: %s)",
      call_state_to_string (expected),
      call_state_to_string (self->priv->state));

  dbus_g_method_return_error (context, e);
  g_error_free (e);
}

static void
tp_base_call_channel_accept (TpSvcChannelTypeCall *iface,
    DBusGMethodInvocation *context)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (iface);
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);
  TpBaseChannel *tp_base = TP_BASE_CHANNEL (self);

  DEBUG ("Client accepted the call");

  self->priv->locally_accepted = TRUE;

  if (tp_base_channel_is_requested (tp_base))
    {
      if (self->priv->state == TP_CALL_STATE_PENDING_INITIATOR)
        {
          tp_base_call_channel_set_state (self,
              TP_CALL_STATE_INITIALISING,
              tp_base_channel_get_self_handle ((TpBaseChannel *) self),
              TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
              "User has accepted to start the call");
        }
      else
        {
          raise_accept_state_error (self, TP_CALL_STATE_PENDING_INITIATOR,
              context);
          return;
        }
    }
  else
    {
      if (self->priv->state == TP_CALL_STATE_INITIALISED)
        {
          tp_base_call_channel_set_state (self,
              TP_CALL_STATE_ACCEPTED,
              tp_base_channel_get_self_handle ((TpBaseChannel *) self),
              TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
              "User has accepted call");
        }
      else
        {
          raise_accept_state_error (self, TP_CALL_STATE_INITIALISED,
              context);
          return;
        }
      self->priv->accepted = TRUE;
    }

  klass->accept (self);

  tp_svc_channel_type_call_return_from_accept (context);
}

static void
tp_base_call_channel_accept_real (TpBaseCallChannel *self)
{
  g_list_foreach (self->priv->contents,
      (GFunc) _tp_base_call_content_accepted, NULL);
}

static void
tp_base_call_channel_hangup (TpSvcChannelTypeCall *iface,
  guint reason,
  const gchar *detailed_reason,
  const gchar *message,
  DBusGMethodInvocation *context)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (iface);
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);
  TpBaseChannel *tp_base = TP_BASE_CHANNEL (self);

  if (self->priv->state == TP_CALL_STATE_ENDED)
    {
      GError e = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "This call has already ended" };
      dbus_g_method_return_error (context, &e);
      return;
    }

  if (klass->hangup != NULL)
    klass->hangup (self, reason, detailed_reason, message);

  tp_base_call_channel_set_state (self, TP_CALL_STATE_ENDED,
      tp_base_channel_get_self_handle (tp_base),
      reason, detailed_reason, message);

  tp_svc_channel_type_call_return_from_hangup (context);
}

static void
tp_base_call_channel_add_content_dbus (TpSvcChannelTypeCall *iface,
  const gchar *name,
  TpMediaStreamType mtype,
  TpMediaStreamDirection initial_direction,
  DBusGMethodInvocation *context)
{
  TpBaseCallChannel *self = TP_BASE_CALL_CHANNEL (iface);
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);
  TpBaseCallContent *content;
  GError *error = NULL;

  if (self->priv->state == TP_CALL_STATE_ENDED)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "No contents can be added. The call has already ended.");
      goto error;
    }

  if (mtype >= TP_NUM_MEDIA_STREAM_TYPES)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Unknown content type");
      goto error;
    }

  if (initial_direction >= TP_NUM_MEDIA_STREAM_DIRECTIONS)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Invalid initial direction");
      goto error;
    }

  if (!self->priv->mutable_contents || klass->add_content == NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_CAPABLE,
          "Contents are not mutable");
      goto error;
    }

  content = klass->add_content (self, name, mtype, initial_direction, &error);

  if (content == NULL)
    goto error;

  if (g_list_find (self->priv->contents, content) == NULL)
    {
      WARNING ("TpBaseCallChannel::add_content() virtual method implementation "
          "should have called tp_base_call_channel_add_content()");
    }

  tp_svc_channel_type_call_return_from_add_content (context,
      tp_base_call_content_get_object_path (content));
  return;

error:
  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

static void
call_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcChannelTypeCallClass *klass =
    (TpSvcChannelTypeCallClass *) g_iface;

#define IMPLEMENT(x, suffix) tp_svc_channel_type_call_implement_##x (\
    klass, tp_base_call_channel_##x##suffix)
  IMPLEMENT(set_ringing,);
  IMPLEMENT(set_queued,);
  IMPLEMENT(accept,);
  IMPLEMENT(hangup,);
  IMPLEMENT(add_content, _dbus);
#undef IMPLEMENT
}

/* Interface has no methods, only has a requestable property */
static void
dtmf_iface_init (gpointer g_iface, gpointer iface_data)
{
}

/* Internal functions */

gboolean
_tp_base_call_channel_is_locally_accepted (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), FALSE);

  return self->priv->locally_accepted;
}

gboolean
_tp_base_call_channel_is_connected (TpBaseCallChannel *self)
{
  TpBaseCallChannelClass *klass = TP_BASE_CALL_CHANNEL_GET_CLASS (self);

  if (klass->is_connected)
    return klass->is_connected (self);
  else
    return TRUE;
}

const gchar *
_tp_base_call_channel_get_initial_tones (TpBaseCallChannel *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_CHANNEL (self), "");

  return self->priv->initial_tones;
}
