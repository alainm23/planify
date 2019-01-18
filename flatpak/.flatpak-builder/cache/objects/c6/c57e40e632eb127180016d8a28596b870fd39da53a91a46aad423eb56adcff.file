/* DTMF utility functions
 *
 * Copyright © 2010 Collabora Ltd.
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

#include "config.h"

#include "telepathy-glib/dtmf.h"


#include <telepathy-glib/base-call-internal.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/util.h>


/**
 * SECTION:dtmf
 * @title: DTMF dialstring interpreter
 * @short_description: Converts a dialstring into a timed sequence of events
 *
 * Telepathy offers two APIs for DTMF events: user interfaces can either
 * call the StartTone and StopTone methods (appropriate if the user is
 * pressing hardware or on-screen buttons in real time), or call
 * MultipleTones or set InitialTones (appropriate if a stored dialstring
 * is in use).
 *
 * #TpDTMFPlayer provides common code for connection managers that need to
 * turn MultipleTones or InitialTones received from a UI into a sequence of
 * start and stop events for the underlying protocol.
 *
 * Since: 0.13.3
 */

/**
 * tp_dtmf_event_to_char:
 * @event: a TpDTMFEvent
 *
 * Return a printable ASCII character representing @event, or '?' if @event
 * was not understood.
 *
 * Returns: a printable ASCII character
 *
 * Since: 0.13.3
 */
gchar
tp_dtmf_event_to_char (TpDTMFEvent event)
{
  switch (event)
    {
      case TP_DTMF_EVENT_DIGIT_0:
      case TP_DTMF_EVENT_DIGIT_1:
      case TP_DTMF_EVENT_DIGIT_2:
      case TP_DTMF_EVENT_DIGIT_3:
      case TP_DTMF_EVENT_DIGIT_4:
      case TP_DTMF_EVENT_DIGIT_5:
      case TP_DTMF_EVENT_DIGIT_6:
      case TP_DTMF_EVENT_DIGIT_7:
      case TP_DTMF_EVENT_DIGIT_8:
      case TP_DTMF_EVENT_DIGIT_9:
        return '0' + (event - TP_DTMF_EVENT_DIGIT_0);

      case TP_DTMF_EVENT_ASTERISK:
        return '*';

      case TP_DTMF_EVENT_HASH:
        return '#';

      case TP_DTMF_EVENT_LETTER_A:
      case TP_DTMF_EVENT_LETTER_B:
      case TP_DTMF_EVENT_LETTER_C:
      case TP_DTMF_EVENT_LETTER_D:
        return 'A' + (event - TP_DTMF_EVENT_LETTER_A);

      default:
        return '?';
    }
}

#define INVALID_DTMF_EVENT ((TpDTMFEvent) 0xFF)

TpDTMFEvent
_tp_dtmf_char_to_event (gchar c)
{
  switch (c)
    {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        return TP_DTMF_EVENT_DIGIT_0 + (c - '0');

      case 'A':
      case 'B':
      case 'C':
      case 'D':
        return TP_DTMF_EVENT_LETTER_A + (c - 'A');

      /* not strictly valid but let's be nice to people */
      case 'a':
      case 'b':
      case 'c':
      case 'd':
        return TP_DTMF_EVENT_LETTER_A + (c - 'a');

      case '*':
        return TP_DTMF_EVENT_ASTERISK;

      case '#':
        return TP_DTMF_EVENT_HASH;

      default:
        return INVALID_DTMF_EVENT;
    }
}

DTMFCharClass
_tp_dtmf_char_classify (gchar c)
{
  switch (c)
    {
      case 'w':
      case 'W':
        return DTMF_CHAR_CLASS_WAIT_FOR_USER;

      case 'p':
      case 'P':
      case 'x':
      case 'X':
      case ',':
        return DTMF_CHAR_CLASS_PAUSE;

      default:
        if (_tp_dtmf_char_to_event (c) != INVALID_DTMF_EVENT)
          return DTMF_CHAR_CLASS_EVENT;
        else
          return DTMF_CHAR_CLASS_MEANINGLESS;
    }
}

/**
 * TpDTMFPlayer:
 *
 * An object to convert a string of characters representing DTMF tones
 * into timed start and stop events.
 *
 * Typically, a connection manager should instantiate one #TpDTMFPlayer
 * for each StreamedMedia or Call channel that supports DTMF.
 *
 * The #TpDTMFPlayer::started-tone and #TpDTMFPlayer::stopped-tone
 * signals should be connected to some way to play a tone, either directly
 * or by emitting signals from the StreamHandler interface.
 *
 * The #TpDTMFPlayer::tones-deferred signal should trigger emission of
 * TonesDeferred.
 *
 * The #TpDTMFPlayer::finished signal indicates that the current sequence
 * of tones has finished.
 *
 * Since: 0.13.3
 */

G_DEFINE_TYPE (TpDTMFPlayer, tp_dtmf_player, G_TYPE_OBJECT)

struct _TpDTMFPlayerPrivate
{
  /* owned, or NULL */
  gchar *dialstring;
  /* a pointer into dialstring, or NULL */
  const gchar *dialstring_remaining;
  guint timer_id;
  guint tone_ms;
  guint gap_ms;
  guint pause_ms;
  gboolean playing_tone;
  gboolean paused;
};

static guint sig_id_started_tone;
static guint sig_id_stopped_tone;
static guint sig_id_finished;
static guint sig_id_tones_deferred;

static void
tp_dtmf_player_emit_started_tone (TpDTMFPlayer *self,
    TpDTMFEvent tone)
{
  self->priv->playing_tone = TRUE;
  g_signal_emit (self, sig_id_started_tone, 0, tone);
}

static void
tp_dtmf_player_maybe_emit_stopped_tone (TpDTMFPlayer *self)
{
  self->priv->paused = FALSE;

  if (!self->priv->playing_tone)
    return;

  self->priv->playing_tone = FALSE;
  g_signal_emit (self, sig_id_stopped_tone, 0);
}

static void
tp_dtmf_player_emit_finished (TpDTMFPlayer *self,
    gboolean cancelled)
{
  g_signal_emit (self, sig_id_finished, 0, cancelled);
}

static void
tp_dtmf_player_emit_tones_deferred (TpDTMFPlayer *self,
    const gchar *remaining_tones)
{
  g_signal_emit (self, sig_id_tones_deferred, 0, remaining_tones);
}

/**
 * tp_dtmf_player_cancel:
 * @self: a DTMF interpreter
 *
 * If tones were being played, stop the current tone (if any),
 * stop playing subsequent tones, and emit #TpDTMFPlayer::finished.
 *
 * Otherwise, do nothing.
 *
 * Since: 0.13.3
 */
void
tp_dtmf_player_cancel (TpDTMFPlayer *self)
{
  g_return_if_fail (TP_IS_DTMF_PLAYER (self));

  if (self->priv->timer_id != 0)
    {
      tp_dtmf_player_maybe_emit_stopped_tone (self);
      tp_dtmf_player_emit_finished (self, TRUE);

      g_source_remove (self->priv->timer_id);
      self->priv->timer_id = 0;
    }

  tp_clear_pointer (&self->priv->dialstring, g_free);
}

static gboolean
tp_dtmf_player_timer_cb (gpointer data)
{
  TpDTMFPlayer *self = data;
  gboolean was_playing = self->priv->playing_tone;
  gboolean was_paused = self->priv->paused;

  self->priv->timer_id = 0;

  tp_dtmf_player_maybe_emit_stopped_tone (self);

  if ((was_playing || was_paused) &&
      !tp_str_empty (self->priv->dialstring_remaining))
    {
      /* We're at the end of a tone. Advance to the next tone. */
      self->priv->dialstring_remaining++;
    }

  if (tp_str_empty (self->priv->dialstring_remaining))
    {
      /* die of natural causes */
      tp_dtmf_player_emit_finished (self, FALSE);
      tp_dtmf_player_cancel (self);
      return FALSE;
    }

  switch (_tp_dtmf_char_classify (*self->priv->dialstring_remaining))
    {
      case DTMF_CHAR_CLASS_EVENT:
        if (was_playing)
          {
            /* Play a gap (short silence) before the next tone */
            self->priv->timer_id = g_timeout_add (self->priv->gap_ms,
                tp_dtmf_player_timer_cb, self);
          }
        else
          {
            /* We're at the end of a gap or pause, or in our initial state.
             * Play the tone straight away. */
            tp_dtmf_player_emit_started_tone (self,
                _tp_dtmf_char_to_event (*self->priv->dialstring_remaining));
            self->priv->timer_id = g_timeout_add (self->priv->tone_ms,
                tp_dtmf_player_timer_cb, self);
          }
        break;

      case DTMF_CHAR_CLASS_PAUSE:
        /* Pause, typically for 3 seconds. We don't need to have a gap
         * first. */
        self->priv->paused = TRUE;
        self->priv->timer_id = g_timeout_add (self->priv->pause_ms,
            tp_dtmf_player_timer_cb, self);
        break;

      case DTMF_CHAR_CLASS_WAIT_FOR_USER:
        /* Just tell the UI "I can't play these tones yet" and go back to
         * sleep (the UI is responsible for feeding them back to us whenever
         * appropriate), unless we're at the end of the string. Again, we
         * don't need a gap. */
        if (self->priv->dialstring_remaining[1] != '\0')
          tp_dtmf_player_emit_tones_deferred (self,
              self->priv->dialstring_remaining + 1);

        tp_dtmf_player_emit_finished (self, FALSE);
        tp_dtmf_player_cancel (self);
        break;

      default:
        g_assert_not_reached ();
    }

  return FALSE;
}

/**
 * tp_dtmf_player_play:
 * @self: a DTMF interpreter
 * @tones: a sequence of tones or other events
 * @tone_ms: length of a tone (0-9, A-D, # or *) in milliseconds,
 *  which must be positive; typically 250
 * @gap_ms: length of the gap between two tones, which must be positive;
 *  typically 100
 * @pause_ms: length of the pause produced by P, X or comma, which must be
 *  positive; typically 3000
 * @error: used to raise an error
 *
 * Start to play a sequence of tones, by emitting the
 * #TpDTMFPlayer::started-tone and #TpDTMFPlayer::stopped-tone signals.
 *
 * If tp_dtmf_player_is_active() would return %TRUE, this method raises
 * %TP_ERROR_SERVICE_BUSY and does not play anything, and the previous
 * sequence continues to play.
 *
 * The recognised characters are 0-9, A-D,
 * # and * (which play the corresponding DTMF event), P, X and comma (which
 * each pause for @pause_ms milliseconds), and W
 * (which stops interpretation of the string and emits
 * #TpDTMFPlayer::tones-deferred with the rest of the string). The
 * corresponding lower-case letters are also allowed.
 * If @tones contains any other characters, this method raises
 * %TP_ERROR_INVALID_ARGUMENT and does not play anything.
 *
 * Returns: %TRUE on success, %FALSE (setting @error) on failure
 *
 * Since: 0.13.3
 */
gboolean
tp_dtmf_player_play (TpDTMFPlayer *self,
    const gchar *tones,
    guint tone_ms,
    guint gap_ms,
    guint pause_ms,
    GError **error)
{
  guint i;

  g_return_val_if_fail (TP_IS_DTMF_PLAYER (self), FALSE);
  g_return_val_if_fail (tones != NULL, FALSE);
  g_return_val_if_fail (tone_ms > 0, FALSE);
  g_return_val_if_fail (gap_ms > 0, FALSE);
  g_return_val_if_fail (pause_ms > 0, FALSE);

  if (self->priv->dialstring != NULL)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_SERVICE_BUSY,
          "DTMF tones are already being played");
      return FALSE;
    }

  g_assert (self->priv->timer_id == 0);

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

  self->priv->dialstring = g_strdup (tones);
  self->priv->dialstring_remaining = self->priv->dialstring;
  self->priv->tone_ms = tone_ms;
  self->priv->gap_ms = gap_ms;
  self->priv->pause_ms = pause_ms;

  /* start off the process: conceptually, this is the end of the zero-length
   * gap before the first tone */
  self->priv->playing_tone = FALSE;
  tp_dtmf_player_timer_cb (self);
  return TRUE;
}

/**
 * tp_dtmf_player_is_active:
 * @self: a DTMF interpreter
 *
 * <!-- -->
 *
 * Returns: %TRUE if a sequence of tones is currently playing
 *
 * Since: 0.13.3
 */
gboolean
tp_dtmf_player_is_active (TpDTMFPlayer *self)
{
  g_return_val_if_fail (TP_IS_DTMF_PLAYER (self), FALSE);

  return (self->priv->dialstring != NULL);
}

#define MY_PARENT_CLASS (tp_dtmf_player_parent_class)

static void
tp_dtmf_player_init (TpDTMFPlayer *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_DTMF_PLAYER,
      TpDTMFPlayerPrivate);

  self->priv->dialstring = NULL;
  self->priv->dialstring_remaining = NULL;
  self->priv->playing_tone = FALSE;
  self->priv->timer_id = 0;
}

static void
tp_dtmf_player_dispose (GObject *object)
{
  TpDTMFPlayer *self = (TpDTMFPlayer *) object;
  void (*dispose) (GObject *) = G_OBJECT_CLASS (MY_PARENT_CLASS)->dispose;

  tp_dtmf_player_cancel (self);

  if (dispose != NULL)
    dispose (object);
}

static void
tp_dtmf_player_class_init (TpDTMFPlayerClass *cls)
{
  GObjectClass *object_class = (GObjectClass *) cls;

  g_type_class_add_private (cls, sizeof (TpDTMFPlayerPrivate));

  object_class->dispose = tp_dtmf_player_dispose;

  /**
   * TpDTMFPlayer::started-tone:
   * @self: the #TpDTMFPlayer
   * @event: a %G_TYPE_UINT representing the tone being played
   *
   * Emitted at the beginning of each tone.
   */
  sig_id_started_tone =  g_signal_new ("started-tone",
      G_OBJECT_CLASS_TYPE (cls), G_SIGNAL_RUN_LAST, 0, NULL, NULL,
      NULL, G_TYPE_NONE, 1, G_TYPE_UINT);

  /**
   * TpDTMFPlayer::stopped-tone:
   * @self: the #TpDTMFPlayer
   *
   * Emitted at the end of each tone.
   *
   * Since: 0.13.3
   */
  sig_id_stopped_tone =  g_signal_new ("stopped-tone",
      G_OBJECT_CLASS_TYPE (cls), G_SIGNAL_RUN_LAST, 0, NULL, NULL,
      NULL, G_TYPE_NONE, 0);

  /**
   * TpDTMFPlayer::finished:
   * @self: the #TpDTMFPlayer
   * @cancelled: %TRUE if playback was cancelled with tp_dtmf_player_cancel()
   *
   * Emitted when playback stops, either because the end of the
   * sequence was reached, tp_dtmf_player_cancel() was called, or a 'W'
   * or 'w' character was encountered.
   *
   * Since: 0.13.3
   */
  sig_id_finished =  g_signal_new ("finished",
      G_OBJECT_CLASS_TYPE (cls), G_SIGNAL_RUN_LAST, 0, NULL, NULL,
      NULL, G_TYPE_NONE, 1, G_TYPE_BOOLEAN);

  /**
   * TpDTMFPlayer::tones-deferred:
   * @self: the #TpDTMFPlayer
   * @tones: the remaining tones, starting from just after the 'W' or 'w'
   *
   * Emitted just before #TpDTMFPlayer::finished if a 'W' or 'w' character
   * is encountered before the end of a dial string. The connection
   * manager is expected to wait for the user to confirm, then call
   * tp_dtmf_player_play() again, using this signal's argument as the new
   * dial string.
   *
   * Since: 0.13.3
   */
  sig_id_tones_deferred =  g_signal_new ("tones-deferred",
      G_OBJECT_CLASS_TYPE (cls), G_SIGNAL_RUN_LAST, 0, NULL, NULL,
      NULL, G_TYPE_NONE, 1, G_TYPE_STRING);
}

/**
 * tp_dtmf_player_new:
 *
 * <!-- -->
 *
 * Returns: (transfer full): a new DTMF interpreter
 *
 * Since: 0.13.3
 */
TpDTMFPlayer *
tp_dtmf_player_new (void)
{
  return g_object_new (TP_TYPE_DTMF_PLAYER,
      NULL);
}
