/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionproviderwords.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
 * Copyright (C) 2013 - Sébastien Wilmet
 *
 * gtksourceview is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * gtksourceview is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * SECTION:completionwords
 * @title: GtkSourceCompletionWords
 * @short_description: A GtkSourceCompletionProvider for the completion of words
 *
 * The #GtkSourceCompletionWords is an example of an implementation of
 * the #GtkSourceCompletionProvider interface. The proposals are words
 * appearing in the registered #GtkTextBuffer<!-- -->s.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletionwords.h"
#include "gtksourcecompletionwordslibrary.h"
#include "gtksourcecompletionwordsbuffer.h"
#include "gtksourcecompletionwordsutils.h"
#include "gtksourceview/gtksource.h"
#include "gtksourceview/gtksourceview-enumtypes.h"
#include "gtksourceview/gtksourceview-i18n.h"

#include <string.h>

#define BUFFER_KEY "GtkSourceCompletionWordsBufferKey"

enum
{
	PROP_0,
	PROP_NAME,
	PROP_ICON,
	PROP_PROPOSALS_BATCH_SIZE,
	PROP_SCAN_BATCH_SIZE,
	PROP_MINIMUM_WORD_SIZE,
	PROP_INTERACTIVE_DELAY,
	PROP_PRIORITY,
	PROP_ACTIVATION,
	N_PROPERTIES
};

struct _GtkSourceCompletionWordsPrivate
{
	gchar *name;
	GdkPixbuf *icon;

	gchar *word;
	gint word_len;
	guint idle_id;

	GtkSourceCompletionContext *context;
	GSequenceIter *populate_iter;

	guint cancel_id;

	guint proposals_batch_size;
	guint scan_batch_size;
	guint minimum_word_size;

	GtkSourceCompletionWordsLibrary *library;
	GList *buffers;

	gint interactive_delay;
	gint priority;
	GtkSourceCompletionActivation activation;
};

typedef struct
{
	GtkSourceCompletionWords *words;
	GtkSourceCompletionWordsBuffer *buffer;
} BufferBinding;

static GParamSpec *properties[N_PROPERTIES];

static void gtk_source_completion_words_iface_init (GtkSourceCompletionProviderIface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceCompletionWords,
			 gtk_source_completion_words,
			 G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceCompletionWords)
			 G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_COMPLETION_PROVIDER,
				 		gtk_source_completion_words_iface_init))

static gchar *
gtk_source_completion_words_get_name (GtkSourceCompletionProvider *self)
{
	return g_strdup (GTK_SOURCE_COMPLETION_WORDS (self)->priv->name);
}

static GdkPixbuf *
gtk_source_completion_words_get_icon (GtkSourceCompletionProvider *self)
{
	return GTK_SOURCE_COMPLETION_WORDS (self)->priv->icon;
}

static void
population_finished (GtkSourceCompletionWords *words)
{
	if (words->priv->idle_id != 0)
	{
		g_source_remove (words->priv->idle_id);
		words->priv->idle_id = 0;
	}

	g_free (words->priv->word);
	words->priv->word = NULL;

	if (words->priv->context != NULL)
	{
		if (words->priv->cancel_id)
		{
			g_signal_handler_disconnect (words->priv->context,
			                             words->priv->cancel_id);
			words->priv->cancel_id = 0;
		}

		g_clear_object (&words->priv->context);
	}
}

static gboolean
add_in_idle (GtkSourceCompletionWords *words)
{
	guint idx = 0;
	GList *ret = NULL;
	gboolean finished;

	if (words->priv->populate_iter == NULL)
	{
		words->priv->populate_iter =
			gtk_source_completion_words_library_find_first (words->priv->library,
			                                                words->priv->word,
			                                                words->priv->word_len);
	}

	while (idx < words->priv->proposals_batch_size &&
	       words->priv->populate_iter)
	{
		GtkSourceCompletionWordsProposal *proposal =
				gtk_source_completion_words_library_get_proposal (words->priv->populate_iter);

		/* Only add non-exact matches */
		if (strcmp (gtk_source_completion_words_proposal_get_word (proposal),
		            words->priv->word) != 0)
		{
			ret = g_list_prepend (ret, proposal);
		}

		words->priv->populate_iter =
				gtk_source_completion_words_library_find_next (words->priv->populate_iter,
		                                                               words->priv->word,
		                                                               words->priv->word_len);
		++idx;
	}

	ret = g_list_reverse (ret);
	finished = words->priv->populate_iter == NULL;

	gtk_source_completion_context_add_proposals (words->priv->context,
	                                             GTK_SOURCE_COMPLETION_PROVIDER (words),
	                                             ret,
	                                             finished);

	g_list_free (ret);

	if (finished)
	{
		gtk_source_completion_words_library_unlock (words->priv->library);
		population_finished (words);
	}

	return !finished;
}

static gchar *
get_word_at_iter (GtkTextIter *iter)
{
	GtkTextBuffer *buffer;
	GtkTextIter start_line;
	gchar *line_text;
	gchar *word;

	buffer = gtk_text_iter_get_buffer (iter);
	start_line = *iter;
	gtk_text_iter_set_line_offset (&start_line, 0);

	line_text = gtk_text_buffer_get_text (buffer, &start_line, iter, FALSE);

	word = _gtk_source_completion_words_utils_get_end_word (line_text);

	g_free (line_text);
	return word;
}

static void
gtk_source_completion_words_populate (GtkSourceCompletionProvider *provider,
                                      GtkSourceCompletionContext  *context)
{
	GtkSourceCompletionWords *words = GTK_SOURCE_COMPLETION_WORDS (provider);
	GtkSourceCompletionActivation activation;
	GtkTextIter iter;
	gchar *word;

	if (!gtk_source_completion_context_get_iter (context, &iter))
	{
		gtk_source_completion_context_add_proposals (context, provider, NULL, TRUE);
		return;
	}

	g_free (words->priv->word);
	words->priv->word = NULL;

	word = get_word_at_iter (&iter);

	activation = gtk_source_completion_context_get_activation (context);

	if (word == NULL ||
	    (activation == GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE &&
	     g_utf8_strlen (word, -1) < (glong)words->priv->minimum_word_size))
	{
		g_free (word);
		gtk_source_completion_context_add_proposals (context, provider, NULL, TRUE);
		return;
	}

	words->priv->cancel_id =
		g_signal_connect_swapped (context,
			                  "cancelled",
			                  G_CALLBACK (population_finished),
			                  provider);

	words->priv->context = g_object_ref (context);

	words->priv->word = word;
	words->priv->word_len = strlen (word);

	/* Do first right now */
	if (add_in_idle (words))
	{
		gtk_source_completion_words_library_lock (words->priv->library);
		words->priv->idle_id = gdk_threads_add_idle ((GSourceFunc)add_in_idle,
		                                             words);
	}
}

static void
gtk_source_completion_words_dispose (GObject *object)
{
	GtkSourceCompletionWords *provider = GTK_SOURCE_COMPLETION_WORDS (object);

	population_finished (provider);

	while (provider->priv->buffers != NULL)
	{
		BufferBinding *binding = provider->priv->buffers->data;
		GtkTextBuffer *buffer = gtk_source_completion_words_buffer_get_buffer (binding->buffer);

		gtk_source_completion_words_unregister (provider, buffer);
	}

	g_free (provider->priv->name);
	provider->priv->name = NULL;

	g_clear_object (&provider->priv->icon);
	g_clear_object (&provider->priv->library);

	G_OBJECT_CLASS (gtk_source_completion_words_parent_class)->dispose (object);
}

static void
update_buffers_batch_size (GtkSourceCompletionWords *words)
{
	GList *item;

	for (item = words->priv->buffers; item != NULL; item = g_list_next (item))
	{
		BufferBinding *binding = item->data;
		gtk_source_completion_words_buffer_set_scan_batch_size (binding->buffer,
		                                                        words->priv->scan_batch_size);
	}
}

static void
update_buffers_minimum_word_size (GtkSourceCompletionWords *words)
{
	GList *item;

	for (item = words->priv->buffers; item != NULL; item = g_list_next (item))
	{
		BufferBinding *binding = (BufferBinding *)item->data;
		gtk_source_completion_words_buffer_set_minimum_word_size (binding->buffer,
		                                                          words->priv->minimum_word_size);
	}
}

static void
gtk_source_completion_words_set_property (GObject      *object,
                                          guint         prop_id,
                                          const GValue *value,
                                          GParamSpec   *pspec)
{
	GtkSourceCompletionWords *self = GTK_SOURCE_COMPLETION_WORDS (object);

	switch (prop_id)
	{
		case PROP_NAME:
			g_free (self->priv->name);
			self->priv->name = g_value_dup_string (value);

			if (self->priv->name == NULL)
			{
				self->priv->name = g_strdup (_("Document Words"));
			}
			break;

		case PROP_ICON:
			g_clear_object (&self->priv->icon);
			self->priv->icon = g_value_dup_object (value);
			break;

		case PROP_PROPOSALS_BATCH_SIZE:
			self->priv->proposals_batch_size = g_value_get_uint (value);
			break;

		case PROP_SCAN_BATCH_SIZE:
			self->priv->scan_batch_size = g_value_get_uint (value);
			update_buffers_batch_size (self);
			break;

		case PROP_MINIMUM_WORD_SIZE:
			self->priv->minimum_word_size = g_value_get_uint (value);
			update_buffers_minimum_word_size (self);
			break;

		case PROP_INTERACTIVE_DELAY:
			self->priv->interactive_delay = g_value_get_int (value);
			break;

		case PROP_PRIORITY:
			self->priv->priority = g_value_get_int (value);
			break;

		case PROP_ACTIVATION:
			self->priv->activation = g_value_get_flags (value);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_completion_words_get_property (GObject    *object,
                                          guint       prop_id,
                                          GValue     *value,
                                          GParamSpec *pspec)
{
	GtkSourceCompletionWords *self = GTK_SOURCE_COMPLETION_WORDS (object);

	switch (prop_id)
	{
		case PROP_NAME:
			g_value_set_string (value, self->priv->name);
			break;

		case PROP_ICON:
			g_value_set_object (value, self->priv->icon);
			break;

		case PROP_PROPOSALS_BATCH_SIZE:
			g_value_set_uint (value, self->priv->proposals_batch_size);
			break;

		case PROP_SCAN_BATCH_SIZE:
			g_value_set_uint (value, self->priv->scan_batch_size);
			break;

		case PROP_MINIMUM_WORD_SIZE:
			g_value_set_uint (value, self->priv->minimum_word_size);
			break;

		case PROP_INTERACTIVE_DELAY:
			g_value_set_int (value, self->priv->interactive_delay);
			break;

		case PROP_PRIORITY:
			g_value_set_int (value, self->priv->priority);
			break;

		case PROP_ACTIVATION:
			g_value_set_flags (value, self->priv->activation);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_completion_words_class_init (GtkSourceCompletionWordsClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->get_property = gtk_source_completion_words_get_property;
	object_class->set_property = gtk_source_completion_words_set_property;
	object_class->dispose = gtk_source_completion_words_dispose;

	properties[PROP_NAME] =
		g_param_spec_string ("name",
				     "Name",
				     "The provider name",
				     NULL,
				     G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_ICON] =
		g_param_spec_object ("icon",
				     "Icon",
				     "The provider icon",
				     GDK_TYPE_PIXBUF,
				     G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_PROPOSALS_BATCH_SIZE] =
		g_param_spec_uint ("proposals-batch-size",
				   "Proposals Batch Size",
				   "Number of proposals added in one batch",
				   1,
				   G_MAXUINT,
				   300,
				   G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_SCAN_BATCH_SIZE] =
		g_param_spec_uint ("scan-batch-size",
				   "Scan Batch Size",
				   "Number of lines scanned in one batch",
				   1,
				   G_MAXUINT,
				   50,
				   G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_MINIMUM_WORD_SIZE] =
		g_param_spec_uint ("minimum-word-size",
				   "Minimum Word Size",
				   "The minimum word size to complete",
				   2,
				   G_MAXUINT,
				   2,
				   G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_INTERACTIVE_DELAY] =
		g_param_spec_int ("interactive-delay",
				  "Interactive Delay",
				  "The delay before initiating interactive completion",
				  -1,
				  G_MAXINT,
				  50,
				  G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	properties[PROP_PRIORITY] =
		g_param_spec_int ("priority",
				  "Priority",
				  "Provider priority",
				  G_MININT,
				  G_MAXINT,
				  0,
				  G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	/**
	 * GtkSourceCompletionWords:activation:
	 *
	 * The type of activation.
	 *
	 * Since: 3.10
	 */
	properties[PROP_ACTIVATION] =
		g_param_spec_flags ("activation",
				    "Activation",
				    "The type of activation",
				    GTK_SOURCE_TYPE_COMPLETION_ACTIVATION,
				    GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE |
				    GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED,
				    G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);

	g_object_class_install_properties (object_class, N_PROPERTIES, properties);
}

static gboolean
gtk_source_completion_words_get_start_iter (GtkSourceCompletionProvider *provider,
                                            GtkSourceCompletionContext  *context,
                                            GtkSourceCompletionProposal *proposal,
                                            GtkTextIter                 *iter)
{
	gchar *word;
	glong nb_chars;

	if (!gtk_source_completion_context_get_iter (context, iter))
	{
		return FALSE;
	}

	word = get_word_at_iter (iter);
	g_return_val_if_fail (word != NULL, FALSE);

	nb_chars = g_utf8_strlen (word, -1);
	gtk_text_iter_backward_chars (iter, nb_chars);

	g_free (word);
	return TRUE;
}

static gint
gtk_source_completion_words_get_interactive_delay (GtkSourceCompletionProvider *provider)
{
	return GTK_SOURCE_COMPLETION_WORDS (provider)->priv->interactive_delay;
}

static gint
gtk_source_completion_words_get_priority (GtkSourceCompletionProvider *provider)
{
	return GTK_SOURCE_COMPLETION_WORDS (provider)->priv->priority;
}

static GtkSourceCompletionActivation
gtk_source_completion_words_get_activation (GtkSourceCompletionProvider *provider)
{
	return GTK_SOURCE_COMPLETION_WORDS (provider)->priv->activation;
}

static void
gtk_source_completion_words_iface_init (GtkSourceCompletionProviderIface *iface)
{
	iface->get_name = gtk_source_completion_words_get_name;
	iface->get_icon = gtk_source_completion_words_get_icon;
	iface->populate = gtk_source_completion_words_populate;
	iface->get_start_iter = gtk_source_completion_words_get_start_iter;
	iface->get_interactive_delay = gtk_source_completion_words_get_interactive_delay;
	iface->get_priority = gtk_source_completion_words_get_priority;
	iface->get_activation = gtk_source_completion_words_get_activation;
}

static void
gtk_source_completion_words_init (GtkSourceCompletionWords *self)
{
	self->priv = gtk_source_completion_words_get_instance_private (self);

	self->priv->library = gtk_source_completion_words_library_new ();
}

/**
 * gtk_source_completion_words_new:
 * @name: (nullable): The name for the provider, or %NULL.
 * @icon: (nullable): A specific icon for the provider, or %NULL.
 *
 * Returns: a new #GtkSourceCompletionWords provider
 */
GtkSourceCompletionWords *
gtk_source_completion_words_new (const gchar *name,
                                 GdkPixbuf   *icon)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_WORDS,
	                     "name", name,
	                     "icon", icon,
	                     NULL);
}

static void
buffer_destroyed (BufferBinding *binding)
{
	binding->words->priv->buffers = g_list_remove (binding->words->priv->buffers,
	                                               binding);
	g_object_unref (binding->buffer);
	g_slice_free (BufferBinding, binding);
}

/**
 * gtk_source_completion_words_register:
 * @words: a #GtkSourceCompletionWords
 * @buffer: a #GtkTextBuffer
 *
 * Registers @buffer in the @words provider.
 */
void
gtk_source_completion_words_register (GtkSourceCompletionWords *words,
                                      GtkTextBuffer            *buffer)
{
	GtkSourceCompletionWordsBuffer *buf;
	BufferBinding *binding;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS (words));
	g_return_if_fail (GTK_IS_TEXT_BUFFER (buffer));

	binding = g_object_get_data (G_OBJECT (buffer), BUFFER_KEY);

	if (binding != NULL)
	{
		return;
	}

	buf = gtk_source_completion_words_buffer_new (words->priv->library,
	                                              buffer);

	gtk_source_completion_words_buffer_set_scan_batch_size (buf,
	                                                        words->priv->scan_batch_size);

	gtk_source_completion_words_buffer_set_minimum_word_size (buf,
	                                                          words->priv->minimum_word_size);

	binding = g_slice_new (BufferBinding);
	binding->words = words;
	binding->buffer = buf;

	g_object_set_data_full (G_OBJECT (buffer),
	                        BUFFER_KEY,
	                        binding,
	                        (GDestroyNotify)buffer_destroyed);

	words->priv->buffers = g_list_prepend (words->priv->buffers,
	                                       binding);
}

/**
 * gtk_source_completion_words_unregister:
 * @words: a #GtkSourceCompletionWords
 * @buffer: a #GtkTextBuffer
 *
 * Unregisters @buffer from the @words provider.
 */
void
gtk_source_completion_words_unregister (GtkSourceCompletionWords *words,
                                        GtkTextBuffer            *buffer)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS (words));
	g_return_if_fail (GTK_IS_TEXT_BUFFER (buffer));

	g_object_set_data (G_OBJECT (buffer), BUFFER_KEY, NULL);
}
