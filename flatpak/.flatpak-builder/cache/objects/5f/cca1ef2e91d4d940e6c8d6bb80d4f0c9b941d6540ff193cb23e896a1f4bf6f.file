/*
 * e-source-mail-account.c
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
 * SECTION: e-source-mail-account
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for an email account
 *
 * The #ESourceMailAccount extension identifies the #ESource as a
 * mail account and also links to a default "mail identity" to use.
 * See #ESourceMailIdentity for more information about identities.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMailAccount *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_ACCOUNT);
 * ]|
 **/

#include "e-source-mail-account.h"

#include <libedataserver/e-source-enumtypes.h>
#include <libedataserver/e-source-mail-identity.h>

#define E_SOURCE_MAIL_ACCOUNT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MAIL_ACCOUNT, ESourceMailAccountPrivate))

struct _ESourceMailAccountPrivate {
	gchar *identity_uid;
	gchar *archive_folder;
	gboolean needs_initial_setup;
	EThreeState mark_seen;
	gint mark_seen_timeout;
};

enum {
	PROP_0,
	PROP_IDENTITY_UID,
	PROP_ARCHIVE_FOLDER,
	PROP_NEEDS_INITIAL_SETUP,
	PROP_MARK_SEEN,
	PROP_MARK_SEEN_TIMEOUT
};

G_DEFINE_TYPE (
	ESourceMailAccount,
	e_source_mail_account,
	E_TYPE_SOURCE_BACKEND)

static void
source_mail_account_set_property (GObject *object,
                                  guint property_id,
                                  const GValue *value,
                                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_IDENTITY_UID:
			e_source_mail_account_set_identity_uid (
				E_SOURCE_MAIL_ACCOUNT (object),
				g_value_get_string (value));
			return;

		case PROP_ARCHIVE_FOLDER:
			e_source_mail_account_set_archive_folder (
				E_SOURCE_MAIL_ACCOUNT (object),
				g_value_get_string (value));
			return;

		case PROP_NEEDS_INITIAL_SETUP:
			e_source_mail_account_set_needs_initial_setup (
				E_SOURCE_MAIL_ACCOUNT (object),
				g_value_get_boolean (value));
			return;

		case PROP_MARK_SEEN:
			e_source_mail_account_set_mark_seen (
				E_SOURCE_MAIL_ACCOUNT (object),
				g_value_get_enum (value));
			return;

		case PROP_MARK_SEEN_TIMEOUT:
			e_source_mail_account_set_mark_seen_timeout (
				E_SOURCE_MAIL_ACCOUNT (object),
				g_value_get_int (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_account_get_property (GObject *object,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_IDENTITY_UID:
			g_value_take_string (
				value,
				e_source_mail_account_dup_identity_uid (
				E_SOURCE_MAIL_ACCOUNT (object)));
			return;

		case PROP_ARCHIVE_FOLDER:
			g_value_take_string (
				value,
				e_source_mail_account_dup_archive_folder (
				E_SOURCE_MAIL_ACCOUNT (object)));
			return;

		case PROP_NEEDS_INITIAL_SETUP:
			g_value_set_boolean (
				value,
				e_source_mail_account_get_needs_initial_setup (
				E_SOURCE_MAIL_ACCOUNT (object)));
			return;

		case PROP_MARK_SEEN:
			g_value_set_enum (
				value,
				e_source_mail_account_get_mark_seen (
				E_SOURCE_MAIL_ACCOUNT (object)));
			return;

		case PROP_MARK_SEEN_TIMEOUT:
			g_value_set_int (
				value,
				e_source_mail_account_get_mark_seen_timeout (
				E_SOURCE_MAIL_ACCOUNT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_account_finalize (GObject *object)
{
	ESourceMailAccountPrivate *priv;

	priv = E_SOURCE_MAIL_ACCOUNT_GET_PRIVATE (object);

	g_free (priv->identity_uid);
	g_free (priv->archive_folder);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_mail_account_parent_class)->finalize (object);
}

static void
e_source_mail_account_class_init (ESourceMailAccountClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceMailAccountPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_mail_account_set_property;
	object_class->get_property = source_mail_account_get_property;
	object_class->finalize = source_mail_account_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;

	g_object_class_install_property (
		object_class,
		PROP_IDENTITY_UID,
		g_param_spec_string (
			"identity-uid",
			"Identity UID",
			"ESource UID of a Mail Identity",
			"self",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ARCHIVE_FOLDER,
		g_param_spec_string (
			"archive-folder",
			"Archive Folder",
			"Folder to Archive messages in",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_NEEDS_INITIAL_SETUP,
		g_param_spec_boolean (
			"needs-initial-setup",
			"Needs Initial Setup",
			"Whether the account needs to do an initial setup",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_MARK_SEEN,
		g_param_spec_enum (
			"mark-seen",
			"Mark Seen",
			"Three-state option for Mark messages as read after N seconds",
			E_TYPE_THREE_STATE,
			E_THREE_STATE_INCONSISTENT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_MARK_SEEN_TIMEOUT,
		g_param_spec_int (
			"mark-seen-timeout",
			"Mark Seen Timeout",
			"Timeout in milliseconds for Mark messages as read after N seconds",
			0, G_MAXINT,
			1500,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_mail_account_init (ESourceMailAccount *extension)
{
	extension->priv = E_SOURCE_MAIL_ACCOUNT_GET_PRIVATE (extension);
}

/**
 * e_source_mail_account_get_identity_uid:
 * @extension: an #ESourceMailAccount
 *
 * Returns the #ESource:uid of the #ESource that describes the mail
 * identity to be used for this account.
 *
 * Returns: the mail identity #ESource:uid
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_account_get_identity_uid (ESourceMailAccount *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), NULL);

	return extension->priv->identity_uid;
}

/**
 * e_source_mail_account_dup_identity_uid:
 * @extension: an #ESourceMailAccount
 *
 * Thread-safe variation of e_source_mail_account_get_identity_uid().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailAccount:identity-uid
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_account_dup_identity_uid (ESourceMailAccount *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_account_get_identity_uid (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_account_set_identity_uid:
 * @extension: an #ESourceMailAccount
 * @identity_uid: (allow-none): the mail identity #ESource:uid, or %NULL
 *
 * Sets the #ESource:uid of the #ESource that describes the mail
 * identity to be used for this account.
 *
 * Since: 3.6
 **/
void
e_source_mail_account_set_identity_uid (ESourceMailAccount *extension,
                                        const gchar *identity_uid)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->identity_uid, identity_uid) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->identity_uid);
	extension->priv->identity_uid = g_strdup (identity_uid);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "identity-uid");
}

/**
 * e_source_mail_account_get_archive_folder:
 * @extension: an #ESourceMailAccount
 *
 * Returns a string identifying the archive folder.
 * The format of the identifier string is defined by the client application.
 *
 * Returns: an identifier of the archive folder
 *
 * Since: 3.16
 **/
const gchar *
e_source_mail_account_get_archive_folder (ESourceMailAccount *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), NULL);

	return extension->priv->archive_folder;
}

/**
 * e_source_mail_account_dup_archive_folder:
 * @extension: an #ESourceMailAccount
 *
 * Thread-safe variation of e_source_mail_account_get_archive_folder().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailAccount:archive-folder
 *
 * Since: 3.16
 **/
gchar *
e_source_mail_account_dup_archive_folder (ESourceMailAccount *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_account_get_archive_folder (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_account_set_archive_folder:
 * @extension: an #ESourceMailAccount
 * @archive_folder: (allow-none): an identifier for the archive folder, or %NULL
 *
 * Sets the folder for sent messages by an identifier string.
 * The format of the identifier string is defined by the client application.
 *
 * The internal copy of @archive_folder is automatically stripped of leading
 * and trailing whitespace. If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.16
 **/
void
e_source_mail_account_set_archive_folder (ESourceMailAccount *extension,
					  const gchar *archive_folder)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->archive_folder, archive_folder) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->archive_folder);
	extension->priv->archive_folder = g_strdup (archive_folder);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "archive-folder");
}

/**
 * e_source_mail_account_get_needs_initial_setup:
 * @extension: an #ESourceMailAccount
 *
 * Check whether the mail account needs to do its initial setup.
 *
 * Returns: %TRUE, when the account needs to run its initial setup
 *
 * Since: 3.20
 **/
gboolean
e_source_mail_account_get_needs_initial_setup (ESourceMailAccount *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), FALSE);

	return extension->priv->needs_initial_setup;
}

/**
 * e_source_mail_account_set_needs_initial_setup:
 * @extension: an #ESourceMailAccount
 * @needs_initial_setup: value to set
 *
 * Sets whether the account needs to run its initial setup.
 *
 * Since: 3.20
 **/
void
e_source_mail_account_set_needs_initial_setup (ESourceMailAccount *extension,
					       gboolean needs_initial_setup)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension));

	if ((extension->priv->needs_initial_setup ? 1 : 0) == (needs_initial_setup ? 1 : 0))
		return;

	extension->priv->needs_initial_setup = needs_initial_setup;

	g_object_notify (G_OBJECT (extension), "needs-initial-setup");
}

/**
 * e_source_mail_account_get_mark_seen:
 * @extension: an #ESourceMailAccount
 *
 * Returns: an #EThreeState, whether messages in this account
 *    should be marked as seen automatically.
 *
 * Since: 3.32
 **/
EThreeState
e_source_mail_account_get_mark_seen (ESourceMailAccount *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), E_THREE_STATE_INCONSISTENT);

	return extension->priv->mark_seen;
}

/**
 * e_source_mail_account_set_mark_seen:
 * @extension: an #ESourceMailAccount
 * @mark_seen: an #EThreeState as the value to set
 *
 * Sets whether the messages in this account should be marked
 * as seen automatically. An inconsistent state means to use
 * global option.
 *
 * Since: 3.32
 **/
void
e_source_mail_account_set_mark_seen (ESourceMailAccount *extension,
				     EThreeState mark_seen)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension));

	if (extension->priv->mark_seen == mark_seen)
		return;

	extension->priv->mark_seen = mark_seen;

	g_object_notify (G_OBJECT (extension), "mark-seen");
}

/**
 * e_source_mail_account_get_mark_seen_timeout:
 * @extension: an #ESourceMailAccount
 *
 * Returns: timeout in milliseconds for marking messages
 *    as seen in this account
 *
 * Since: 3.32
 **/
gint
e_source_mail_account_get_mark_seen_timeout (ESourceMailAccount *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension), -1);

	return extension->priv->mark_seen_timeout;
}

/**
 * e_source_mail_account_set_mark_seen_timeout:
 * @extension: an #ESourceMailAccount
 * @timeout: a timeout in milliseconds
 *
 * Sets the @timeout in milliseconds for marking messages
 * as seen in this account. Whether the timeout is used
 * depends on e_source_mail_account_get_mark_seen().
 *
 * Since: 3.32
 **/
void
e_source_mail_account_set_mark_seen_timeout (ESourceMailAccount *extension,
					     gint timeout)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_ACCOUNT (extension));

	if (extension->priv->mark_seen_timeout == timeout)
		return;

	extension->priv->mark_seen_timeout = timeout;

	g_object_notify (G_OBJECT (extension), "mark-seen-timeout");
}
