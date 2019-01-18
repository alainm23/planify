/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 * gtksourcecompletioncontext.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom <jessevdk@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * SECTION:completioncontext
 * @title: GtkSourceCompletionContext
 * @short_description: The context of a completion
 *
 * Initially, the completion window is hidden. For a completion to occur, it has
 * to be activated. The different possible activations are listed in
 * #GtkSourceCompletionActivation. When an activation occurs, a
 * #GtkSourceCompletionContext object is created, and the eligible providers are
 * asked to add proposals with gtk_source_completion_context_add_proposals().
 *
 * If no proposals are added, the completion window remains hidden, and the
 * context is destroyed.
 *
 * On the other hand, if proposals are added, the completion window becomes
 * visible, and the user can choose a proposal. If the user is not happy with
 * the shown proposals, he or she can insert or delete characters, to modify the
 * completion context and therefore hoping to see the proposal he or she wants.
 * This means that when an insertion or deletion occurs in the #GtkTextBuffer
 * when the completion window is visible, the eligible providers are again asked
 * to add proposals. The #GtkSourceCompletionContext:activation remains the
 * same in this case.
 *
 * When the completion window is hidden, the interactive completion is triggered
 * only on insertion in the buffer, not on deletion. Once the completion window
 * is visible, then on each insertion or deletion, there is a new population and
 * the providers are asked to add proposals. If there are no more proposals, the
 * completion window disappears. So if you want to keep the completion window
 * visible, but there are no proposals, you can insert a dummy proposal named
 * "No proposals". For example, the user types progressively the name of
 * a function, and some proposals appear. The user types a bad character and
 * there are no proposals anymore. What the user wants is to delete the last
 * character, and see the previous proposals. If the completion window
 * disappears, the previous proposals will not reappear on the character
 * deletion.
 *
 * A #GtkTextIter is associated with the context, this is where the completion
 * takes place. With this #GtkTextIter, you can get the associated
 * #GtkTextBuffer with gtk_text_iter_get_buffer().
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletioncontext.h"
#include "gtksourceview-enumtypes.h"
#include "gtksourcecompletionprovider.h"
#include "gtksourceview-i18n.h"
#include "gtksourcecompletion.h"

struct _GtkSourceCompletionContextPrivate
{
	GtkSourceCompletion *completion;

	GtkTextMark *mark;
	GtkSourceCompletionActivation activation;
};

enum
{
	PROP_0,
	PROP_COMPLETION,
	PROP_ITER,
	PROP_ACTIVATION
};

enum
{
	CANCELLED,
	N_SIGNALS
};

static guint context_signals[N_SIGNALS];

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceCompletionContext, gtk_source_completion_context, G_TYPE_INITIALLY_UNOWNED)

static void
gtk_source_completion_context_dispose (GObject *object)
{
	GtkSourceCompletionContext *context = GTK_SOURCE_COMPLETION_CONTEXT (object);

	if (context->priv->mark != NULL)
	{
		GtkTextBuffer *buffer = gtk_text_mark_get_buffer (context->priv->mark);

		if (buffer != NULL)
		{
			gtk_text_buffer_delete_mark (buffer, context->priv->mark);
		}

		g_object_unref (context->priv->mark);
		context->priv->mark = NULL;
	}

	g_clear_object (&context->priv->completion);

	G_OBJECT_CLASS (gtk_source_completion_context_parent_class)->dispose (object);
}

static void
set_iter (GtkSourceCompletionContext *context,
	  GtkTextIter                *iter)
{
	GtkTextBuffer *buffer;

	buffer = gtk_text_iter_get_buffer (iter);

	if (context->priv->mark != NULL)
	{
		GtkTextBuffer *old_buffer;

		old_buffer = gtk_text_mark_get_buffer (context->priv->mark);

		if (old_buffer != buffer)
		{
			g_object_unref (context->priv->mark);
			context->priv->mark = NULL;
		}
	}

	if (context->priv->mark == NULL)
	{
		context->priv->mark = gtk_text_buffer_create_mark (buffer, NULL, iter, FALSE);
		g_object_ref (context->priv->mark);
	}
	else
	{
		gtk_text_buffer_move_mark (buffer, context->priv->mark, iter);
	}

	g_object_notify (G_OBJECT (context), "iter");
}

static void
gtk_source_completion_context_set_property (GObject      *object,
                                            guint         prop_id,
                                            const GValue *value,
                                            GParamSpec   *pspec)
{
	GtkSourceCompletionContext *context = GTK_SOURCE_COMPLETION_CONTEXT (object);

	switch (prop_id)
	{
		case PROP_COMPLETION:
			context->priv->completion = g_value_dup_object (value);
			break;

		case PROP_ITER:
			set_iter (context, g_value_get_boxed (value));
			break;

		case PROP_ACTIVATION:
			context->priv->activation = g_value_get_flags (value);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_source_completion_context_get_property (GObject    *object,
                                            guint       prop_id,
                                            GValue     *value,
                                            GParamSpec *pspec)
{
	GtkSourceCompletionContext *context = GTK_SOURCE_COMPLETION_CONTEXT (object);

	switch (prop_id)
	{
		case PROP_COMPLETION:
			g_value_set_object (value, context->priv->completion);
			break;

		case PROP_ITER:
			{
				GtkTextIter iter;

				if (gtk_source_completion_context_get_iter (context, &iter))
				{
					g_value_set_boxed (value, &iter);
				}
			}
			break;

		case PROP_ACTIVATION:
			g_value_set_flags (value, context->priv->activation);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_source_completion_context_class_init (GtkSourceCompletionContextClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->set_property = gtk_source_completion_context_set_property;
	object_class->get_property = gtk_source_completion_context_get_property;
	object_class->dispose = gtk_source_completion_context_dispose;

	/**
	 * GtkSourceCompletionContext::cancelled:
	 *
	 * Emitted when the current population of proposals has been cancelled.
	 * Providers adding proposals asynchronously should connect to this signal
	 * to know when to cancel running proposal queries.
	 **/
	context_signals[CANCELLED] =
		g_signal_new ("cancelled",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		              G_STRUCT_OFFSET (GtkSourceCompletionContextClass, cancelled),
		              NULL, NULL, NULL,
		              G_TYPE_NONE, 0);

	/**
	 * GtkSourceCompletionContext:completion:
	 *
	 * The #GtkSourceCompletion associated with the context.
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_COMPLETION,
	                                 g_param_spec_object ("completion",
	                                                      "Completion",
	                                                      "The completion object to which the context belongs",
	                                                      GTK_SOURCE_TYPE_COMPLETION,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionContext:iter:
	 *
	 * The #GtkTextIter at which the completion is invoked.
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_ITER,
					 g_param_spec_boxed ("iter",
							     "Iterator",
							     "The GtkTextIter at which the completion was invoked",
							     GTK_TYPE_TEXT_ITER,
							     G_PARAM_READWRITE |
							     G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionContext:activation:
	 *
	 * The completion activation
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_ACTIVATION,
	                                 g_param_spec_flags ("activation",
	                                                     "Activation",
	                                                     "The type of activation",
	                                                     GTK_SOURCE_TYPE_COMPLETION_ACTIVATION,
	                                                     GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED,
	                                                     G_PARAM_READWRITE |
							     G_PARAM_CONSTRUCT |
							     G_PARAM_STATIC_STRINGS));
}

static void
gtk_source_completion_context_init (GtkSourceCompletionContext *context)
{
	context->priv = gtk_source_completion_context_get_instance_private (context);
}

/**
 * gtk_source_completion_context_add_proposals:
 * @context: a #GtkSourceCompletionContext.
 * @provider: a #GtkSourceCompletionProvider.
 * @proposals: (nullable) (element-type GtkSource.CompletionProposal): The list of proposals to add.
 * @finished: Whether the provider is finished adding proposals.
 *
 * Providers can use this function to add proposals to the completion. They
 * can do so asynchronously by means of the @finished argument. Providers must
 * ensure that they always call this function with @finished set to %TRUE
 * once each population (even if no proposals need to be added).
 * Population occurs when the gtk_source_completion_provider_populate()
 * function is called.
 **/
void
gtk_source_completion_context_add_proposals (GtkSourceCompletionContext  *context,
                                             GtkSourceCompletionProvider *provider,
                                             GList                       *proposals,
                                             gboolean                     finished)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider));

	_gtk_source_completion_add_proposals (context->priv->completion,
	                                      context,
	                                      provider,
	                                      proposals,
	                                      finished);
}

/**
 * gtk_source_completion_context_get_iter:
 * @context: a #GtkSourceCompletionContext.
 * @iter: (out): a #GtkTextIter.
 *
 * Get the iter at which the completion was invoked. Providers can use this
 * to determine how and if to match proposals.
 *
 * Returns: %TRUE if @iter is correctly set, %FALSE otherwise.
 **/
gboolean
gtk_source_completion_context_get_iter (GtkSourceCompletionContext *context,
                                        GtkTextIter                *iter)
{
	GtkTextBuffer *mark_buffer;
	GtkSourceView *view;
	GtkTextBuffer *completion_buffer;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context), FALSE);

	if (context->priv->mark == NULL)
	{
		/* This should never happen: context should be always be created
		   providing a position iter */
		g_warning ("Completion context without mark");
		return FALSE;
	}

	mark_buffer = gtk_text_mark_get_buffer (context->priv->mark);

	if (mark_buffer == NULL)
	{
		return FALSE;
	}

	view = gtk_source_completion_get_view (context->priv->completion);
	if (view == NULL)
	{
		return FALSE;
	}

	completion_buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (completion_buffer != mark_buffer)
	{
		return FALSE;
	}

	gtk_text_buffer_get_iter_at_mark (mark_buffer, iter, context->priv->mark);
	return TRUE;
}

/**
 * gtk_source_completion_context_get_activation:
 * @context: a #GtkSourceCompletionContext.
 *
 * Get the context activation.
 *
 * Returns: The context activation.
 */
GtkSourceCompletionActivation
gtk_source_completion_context_get_activation (GtkSourceCompletionContext *context)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context),
			      GTK_SOURCE_COMPLETION_ACTIVATION_NONE);

	return context->priv->activation;
}

void
_gtk_source_completion_context_cancel (GtkSourceCompletionContext *context)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context));

	g_signal_emit (context, context_signals[CANCELLED], 0);
}

GtkSourceCompletionContext *
_gtk_source_completion_context_new (GtkSourceCompletion *completion,
				    GtkTextIter         *position)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), NULL);
	g_return_val_if_fail (position != NULL, NULL);

	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_CONTEXT,
	                     "completion", completion,
	                     "iter", position,
	                      NULL);
}
