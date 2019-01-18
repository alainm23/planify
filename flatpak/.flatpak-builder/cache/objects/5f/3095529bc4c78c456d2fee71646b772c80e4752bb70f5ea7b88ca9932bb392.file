/*
 * e-source-goa.c
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
 * SECTION: e-source-goa
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for GNOME Online Accounts
 *
 * The #ESourceGoa extension associates an #ESource with a #GoaAccount.
 * This extension is usually found in a top-level #ESource, with various
 * mail, calendar and address book data sources as children.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceGoa *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_GOA);
 * ]|
 **/

#include "e-source-goa.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_GOA_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_GOA, ESourceGoaPrivate))

struct _ESourceGoaPrivate {
	gchar *account_id;
	gchar *calendar_url;
	gchar *contacts_url;
	gchar *name;
	gchar *address;
};

enum {
	PROP_0,
	PROP_ACCOUNT_ID,
	PROP_CALENDAR_URL,
	PROP_CONTACTS_URL,
	PROP_NAME,
	PROP_ADDRESS
};

G_DEFINE_TYPE (
	ESourceGoa,
	e_source_goa,
	E_TYPE_SOURCE_EXTENSION)

static void
source_goa_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ACCOUNT_ID:
			e_source_goa_set_account_id (
				E_SOURCE_GOA (object),
				g_value_get_string (value));
			return;

		case PROP_CALENDAR_URL:
			e_source_goa_set_calendar_url (
				E_SOURCE_GOA (object),
				g_value_get_string (value));
			return;

		case PROP_CONTACTS_URL:
			e_source_goa_set_contacts_url (
				E_SOURCE_GOA (object),
				g_value_get_string (value));
			return;

		case PROP_NAME:
			e_source_goa_set_name (
				E_SOURCE_GOA (object),
				g_value_get_string (value));
			return;

		case PROP_ADDRESS:
			e_source_goa_set_address (
				E_SOURCE_GOA (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_goa_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ACCOUNT_ID:
			g_value_take_string (
				value,
				e_source_goa_dup_account_id (
				E_SOURCE_GOA (object)));
			return;

		case PROP_CALENDAR_URL:
			g_value_take_string (
				value,
				e_source_goa_dup_calendar_url (
				E_SOURCE_GOA (object)));
			return;

		case PROP_CONTACTS_URL:
			g_value_take_string (
				value,
				e_source_goa_dup_contacts_url (
				E_SOURCE_GOA (object)));
			return;

		case PROP_NAME:
			g_value_take_string (
				value,
				e_source_goa_dup_name (
				E_SOURCE_GOA (object)));
			return;

		case PROP_ADDRESS:
			g_value_take_string (
				value,
				e_source_goa_dup_address (
				E_SOURCE_GOA (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_goa_finalize (GObject *object)
{
	ESourceGoaPrivate *priv;

	priv = E_SOURCE_GOA_GET_PRIVATE (object);

	g_free (priv->account_id);
	g_free (priv->calendar_url);
	g_free (priv->contacts_url);
	g_free (priv->name);
	g_free (priv->address);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_goa_parent_class)->finalize (object);
}

static void
e_source_goa_class_init (ESourceGoaClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceGoaPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_goa_set_property;
	object_class->get_property = source_goa_get_property;
	object_class->finalize = source_goa_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_GOA;

	g_object_class_install_property (
		object_class,
		PROP_ACCOUNT_ID,
		g_param_spec_string (
			"account-id",
			"Account ID",
			"GNOME Online Account ID",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_CALENDAR_URL,
		g_param_spec_string (
			"calendar-url",
			"Calendar URL",
			"GNOME Online Calendar URL",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_CONTACTS_URL,
		g_param_spec_string (
			"contacts-url",
			"Contacts URL",
			"GNOME Online Contacts URL",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_NAME,
		g_param_spec_string (
			"name",
			"Name",
			"GNOME Online Account's original Name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ADDRESS,
		g_param_spec_string (
			"address",
			"Address",
			"GNOME Online Account's original Address",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_goa_init (ESourceGoa *extension)
{
	extension->priv = E_SOURCE_GOA_GET_PRIVATE (extension);
}

/**
 * e_source_goa_get_account_id:
 * @extension: an #ESourceGoa
 *
 * Returns the identifier string of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * Returns: the associated GNOME Online Account ID
 *
 * Since: 3.6
 **/
const gchar *
e_source_goa_get_account_id (ESourceGoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	return extension->priv->account_id;
}

/**
 * e_source_goa_dup_account_id:
 * @extension: an #ESourceGoa
 *
 * Thread-safe variation of e_source_goa_get_account_id().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceGoa:account-id
 *
 * Since: 3.6
 **/
gchar *
e_source_goa_dup_account_id (ESourceGoa *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_goa_get_account_id (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_goa_set_account_id:
 * @extension: an #ESourceGoa
 * @account_id: (allow-none): the associated GNOME Online Account ID, or %NULL
 *
 * Sets the identifier string of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * The internal copy of @account_id is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_goa_set_account_id (ESourceGoa *extension,
                             const gchar *account_id)
{
	g_return_if_fail (E_IS_SOURCE_GOA (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->account_id, account_id) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->account_id);
	extension->priv->account_id = e_util_strdup_strip (account_id);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "account-id");
}

/**
 * e_source_goa_get_calendar_url:
 * @extension: an #ESourceGoa
 *
 * Returns the calendar URL string of the GNOME Online Account associated
 * with the #ESource to which @extension belongs. Can be %NULL or an empty
 * string for accounts not supporting this property.
 *
 * Returns: the associated GNOME Online Account calendar URL
 *
 * Since: 3.8
 **/
const gchar *
e_source_goa_get_calendar_url (ESourceGoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	return extension->priv->calendar_url;
}

/**
 * e_source_goa_dup_calendar_url:
 * @extension: an #ESourceGoa
 *
 * Thread-safe variation of e_source_goa_get_calendar_url().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceGoa:calendar-url
 *
 * Since: 3.8
 **/
gchar *
e_source_goa_dup_calendar_url (ESourceGoa *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_goa_get_calendar_url (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_goa_set_calendar_url:
 * @extension: an #ESourceGoa
 * @calendar_url: (allow-none): the associated GNOME Online Account
 *                calendar URL, or %NULL
 *
 * Sets the calendar URL of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * The internal copy of @calendar_url is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.8
 **/
void
e_source_goa_set_calendar_url (ESourceGoa *extension,
                               const gchar *calendar_url)
{
	g_return_if_fail (E_IS_SOURCE_GOA (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->calendar_url, calendar_url) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->calendar_url);
	extension->priv->calendar_url = e_util_strdup_strip (calendar_url);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "calendar-url");
}

/**
 * e_source_goa_get_contacts_url:
 * @extension: an #ESourceGoa
 *
 * Returns the contacts URL string of the GNOME Online Account associated
 * with the #ESource to which @extension belongs. Can be %NULL or an empty
 * string for accounts not supporting this property.
 *
 * Returns: the associated GNOME Online Account contacts URL
 *
 * Since: 3.8
 **/
const gchar *
e_source_goa_get_contacts_url (ESourceGoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	return extension->priv->contacts_url;
}

/**
 * e_source_goa_dup_contacts_url:
 * @extension: an #ESourceGoa
 *
 * Thread-safe variation of e_source_goa_get_contacts_url().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceGoa:contacts-url
 *
 * Since: 3.8
 **/
gchar *
e_source_goa_dup_contacts_url (ESourceGoa *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_goa_get_contacts_url (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_goa_set_contacts_url:
 * @extension: an #ESourceGoa
 * @contacts_url: (allow-none): the associated GNOME Online Account
 *                contacts URL, or %NULL
 *
 * Sets the contacts URL of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * The internal copy of @contacts_url is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.8
 **/
void
e_source_goa_set_contacts_url (ESourceGoa *extension,
                               const gchar *contacts_url)
{
	g_return_if_fail (E_IS_SOURCE_GOA (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->contacts_url, contacts_url) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->contacts_url);
	extension->priv->contacts_url = e_util_strdup_strip (contacts_url);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "contacts-url");
}

/**
 * e_source_goa_get_name:
 * @extension: an #ESourceGoa
 *
 * Returns the original Name of the GNOME Online Account associated
 * with the #ESource to which @extension belongs. Can be %NULL or an empty
 * string when not filled.
 *
 * Returns: the associated GNOME Online Account's Name
 *
 * Since: 3.24
 **/
const gchar *
e_source_goa_get_name (ESourceGoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	return extension->priv->name;
}

/**
 * e_source_goa_dup_name:
 * @extension: an #ESourceGoa
 *
 * Thread-safe variation of e_source_goa_get_name().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceGoa:name
 *
 * Since: 3.24
 **/
gchar *
e_source_goa_dup_name (ESourceGoa *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_goa_get_name (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_goa_set_name:
 * @extension: an #ESourceGoa
 * @name: (nullable): the associated GNOME Online Account's Name, or %NULL
 *
 * Sets the Name of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * The internal copy of @name is automatically stripped of leading
 * and trailing whitespace. If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.24
 **/
void
e_source_goa_set_name (ESourceGoa *extension,
		       const gchar *name)
{
	g_return_if_fail (E_IS_SOURCE_GOA (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->name, name) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->name);
	extension->priv->name = e_util_strdup_strip (name);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "name");
}

/**
 * e_source_goa_get_address:
 * @extension: an #ESourceGoa
 *
 * Returns the original Address of the GNOME Online Account associated
 * with the #ESource to which @extension belongs. Can be %NULL or an empty
 * string when not filled.
 *
 * Returns: the associated GNOME Online Account's Address
 *
 * Since: 3.24
 **/
const gchar *
e_source_goa_get_address (ESourceGoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	return extension->priv->address;
}

/**
 * e_source_goa_dup_address:
 * @extension: an #ESourceGoa
 *
 * Thread-safe variation of e_source_goa_get_address().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceGoa:address
 *
 * Since: 3.24
 **/
gchar *
e_source_goa_dup_address (ESourceGoa *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_GOA (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_goa_get_address (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_goa_set_address:
 * @extension: an #ESourceGoa
 * @address: (nullable): the associated GNOME Online Account's Address, or %NULL
 *
 * Sets the Address of the GNOME Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * The internal copy of @address is automatically stripped of leading
 * and trailing whitespace. If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.24
 **/
void
e_source_goa_set_address (ESourceGoa *extension,
			  const gchar *address)
{
	g_return_if_fail (E_IS_SOURCE_GOA (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->address, address) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->address);
	extension->priv->address = e_util_strdup_strip (address);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "address");
}
