/*
 * e-source-mail-submission.c
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * SECTION: e-source-mail-submission
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for submitting emails
 *
 * The #ESourceMailSubmission extension tracks settings to be applied
 * when submitting a mail message for delivery.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMailSubmission *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_SUBMISSION);
 * ]|
 **/

#include "e-source-mail-submission.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_MAIL_SUBMISSION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MAIL_SUBMISSION, ESourceMailSubmissionPrivate))

struct _ESourceMailSubmissionPrivate {
	gchar *sent_folder;
	gchar *transport_uid;
	gboolean replies_to_origin_folder;
	gboolean use_sent_folder;
};

enum {
	PROP_0,
	PROP_SENT_FOLDER,
	PROP_TRANSPORT_UID,
	PROP_REPLIES_TO_ORIGIN_FOLDER,
	PROP_USE_SENT_FOLDER
};

G_DEFINE_TYPE (
	ESourceMailSubmission,
	e_source_mail_submission,
	E_TYPE_SOURCE_EXTENSION)

static void
source_mail_submission_set_property (GObject *object,
                                     guint property_id,
                                     const GValue *value,
                                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SENT_FOLDER:
			e_source_mail_submission_set_sent_folder (
				E_SOURCE_MAIL_SUBMISSION (object),
				g_value_get_string (value));
			return;

		case PROP_TRANSPORT_UID:
			e_source_mail_submission_set_transport_uid (
				E_SOURCE_MAIL_SUBMISSION (object),
				g_value_get_string (value));
			return;

		case PROP_REPLIES_TO_ORIGIN_FOLDER:
			e_source_mail_submission_set_replies_to_origin_folder (
				E_SOURCE_MAIL_SUBMISSION (object),
				g_value_get_boolean (value));
			return;

		case PROP_USE_SENT_FOLDER:
			e_source_mail_submission_set_use_sent_folder (
				E_SOURCE_MAIL_SUBMISSION (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_submission_get_property (GObject *object,
                                     guint property_id,
                                     GValue *value,
                                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SENT_FOLDER:
			g_value_take_string (
				value,
				e_source_mail_submission_dup_sent_folder (
				E_SOURCE_MAIL_SUBMISSION (object)));
			return;

		case PROP_TRANSPORT_UID:
			g_value_take_string (
				value,
				e_source_mail_submission_dup_transport_uid (
				E_SOURCE_MAIL_SUBMISSION (object)));
			return;

		case PROP_REPLIES_TO_ORIGIN_FOLDER:
			g_value_set_boolean (
				value,
				e_source_mail_submission_get_replies_to_origin_folder (
				E_SOURCE_MAIL_SUBMISSION (object)));
			return;

		case PROP_USE_SENT_FOLDER:
			g_value_set_boolean (
				value,
				e_source_mail_submission_get_use_sent_folder (
				E_SOURCE_MAIL_SUBMISSION (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_submission_finalize (GObject *object)
{
	ESourceMailSubmissionPrivate *priv;

	priv = E_SOURCE_MAIL_SUBMISSION_GET_PRIVATE (object);

	g_free (priv->sent_folder);
	g_free (priv->transport_uid);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_mail_submission_parent_class)->
		finalize (object);
}

static void
e_source_mail_submission_class_init (ESourceMailSubmissionClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (
		class, sizeof (ESourceMailSubmissionPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_mail_submission_set_property;
	object_class->get_property = source_mail_submission_get_property;
	object_class->finalize = source_mail_submission_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MAIL_SUBMISSION;

	g_object_class_install_property (
		object_class,
		PROP_SENT_FOLDER,
		g_param_spec_string (
			"sent-folder",
			"Sent Folder",
			"Preferred folder for sent messages",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_USE_SENT_FOLDER,
		g_param_spec_boolean (
			"use-sent-folder",
			"Use Sent Folder",
			"Whether to save sent messages to sent-folder",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_TRANSPORT_UID,
		g_param_spec_string (
			"transport-uid",
			"Transport UID",
			"ESource UID of a Mail Transport",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_REPLIES_TO_ORIGIN_FOLDER,
		g_param_spec_boolean (
			"replies-to-origin-folder",
			"Replies to origin folder",
			"Whether to save replies to folder of the message "
			"being replied to, instead of the Sent folder",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_mail_submission_init (ESourceMailSubmission *extension)
{
	extension->priv = E_SOURCE_MAIL_SUBMISSION_GET_PRIVATE (extension);
}

/**
 * e_source_mail_submission_get_sent_folder:
 * @extension: an #ESourceMailSubmission
 *
 * Returns a string identifying the preferred folder for sent messages.
 * The format of the identifier string is defined by the client application.
 *
 * Returns: an identifier for the preferred sent folder
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_submission_get_sent_folder (ESourceMailSubmission *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), NULL);

	return extension->priv->sent_folder;
}

/**
 * e_source_mail_submission_dup_sent_folder:
 * @extension: an #ESourceMailSubmission
 *
 * Thread-safe variation of e_source_mail_submission_get_sent_folder().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailSubmission:sent-folder
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_submission_dup_sent_folder (ESourceMailSubmission *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_submission_get_sent_folder (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_submission_set_sent_folder:
 * @extension: an #ESourceMailSubmission
 * @sent_folder: (allow-none): an identifier for the preferred sent folder,
 *               or %NULL
 *
 * Sets the preferred folder for sent messages by an identifier string.
 * The format of the identifier string is defined by the client application.
 *
 * The internal copy of @sent_folder is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_mail_submission_set_sent_folder (ESourceMailSubmission *extension,
                                          const gchar *sent_folder)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->sent_folder, sent_folder) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->sent_folder);
	extension->priv->sent_folder = e_util_strdup_strip (sent_folder);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "sent-folder");
}

/**
 * e_source_mail_submission_get_use_sent_folder:
 * @extension: an #ESourceMailSubmission
 *
 * Returns: whether save messages to the sent folder at all
 *
 * Since: 3.26
 **/
gboolean
e_source_mail_submission_get_use_sent_folder (ESourceMailSubmission *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), FALSE);

	return extension->priv->use_sent_folder;
}

/**
 * e_source_mail_submission_set_use_sent_folder:
 * @extension: an #ESourceMailSubmission
 * @use_sent_folder: the value to set
 *
 * Sets whether save messages to the sent folder at all.
 *
 * Since: 3.26
 **/
void
e_source_mail_submission_set_use_sent_folder (ESourceMailSubmission *extension,
					      gboolean use_sent_folder)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension));

	if ((extension->priv->use_sent_folder ? 1 : 0) == (use_sent_folder ? 1 : 0))
		return;

	extension->priv->use_sent_folder = use_sent_folder;

	g_object_notify (G_OBJECT (extension), "use-sent-folder");
}

/**
 * e_source_mail_submission_get_transport_uid:
 * @extension: an #ESourceMailSubmission
 *
 * Returns the #ESource:uid of the #ESource that describes the mail
 * transport to be used for outgoing messages.
 *
 * Returns: the mail transport #ESource:uid
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_submission_get_transport_uid (ESourceMailSubmission *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), NULL);

	return extension->priv->transport_uid;
}

/**
 * e_source_mail_submission_dup_transport_uid:
 * @extension: an #ESourceMailSubmission
 *
 * Thread-safe variation of e_source_mail_submission_get_transport_uid().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailSubmission:transport-uid
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_submission_dup_transport_uid (ESourceMailSubmission *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_submission_get_transport_uid (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_submission_set_transport_uid:
 * @extension: an #ESourceMailSubmission
 * @transport_uid: (allow-none): the mail transport #ESource:uid, or %NULL
 *
 * Sets the #ESource:uid of the #ESource that describes the mail
 * transport to be used for outgoing messages.
 *
 * Since: 3.6
 **/
void
e_source_mail_submission_set_transport_uid (ESourceMailSubmission *extension,
                                            const gchar *transport_uid)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->transport_uid, transport_uid) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->transport_uid);
	extension->priv->transport_uid = g_strdup (transport_uid);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "transport-uid");
}

/**
 * e_source_mail_submission_get_replies_to_origin_folder:
 * @extension: an #ESourceMailSubmission
 *
 * Returns whether save replies in the folder of the message
 * being replied to, instead of the Sent folder.
 *
 * Returns: whether save replies in the folder of the message being replied to
 *
 * Since: 3.8
 **/
gboolean
e_source_mail_submission_get_replies_to_origin_folder (ESourceMailSubmission *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension), FALSE);

	return extension->priv->replies_to_origin_folder;
}

/**
 * e_source_mail_submission_set_replies_to_origin_folder:
 * @extension: an #ESourceMailSubmission
 * @replies_to_origin_folder: new value
 *
 * Sets whether save replies in the folder of the message
 * being replied to, instead of the Sent folder.
 *
 * Since: 3.8
 **/
void
e_source_mail_submission_set_replies_to_origin_folder (ESourceMailSubmission *extension,
                                                       gboolean replies_to_origin_folder)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_SUBMISSION (extension));

	if (extension->priv->replies_to_origin_folder == replies_to_origin_folder)
		return;

	extension->priv->replies_to_origin_folder = replies_to_origin_folder;

	g_object_notify (G_OBJECT (extension), "replies-to-origin-folder");
}
