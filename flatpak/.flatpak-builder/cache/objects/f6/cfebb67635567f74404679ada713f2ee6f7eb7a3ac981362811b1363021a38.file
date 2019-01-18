/*
 * e-source-contacts.c
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

#include "evolution-data-server-config.h"

#include "e-source-address-book.h"

#include "e-source-contacts.h"

#define E_SOURCE_CONTACTS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_CONTACTS, ESourceContactsPrivate))

struct _ESourceContactsPrivate {
	gboolean include_me;
};

enum {
	PROP_0,
	PROP_INCLUDE_ME
};

G_DEFINE_TYPE (
	ESourceContacts,
	e_source_contacts,
	E_TYPE_SOURCE_EXTENSION)

static void
source_contacts_set_property (GObject *object,
                              guint property_id,
                              const GValue *value,
                              GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			e_source_contacts_set_include_me (
				E_SOURCE_CONTACTS (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_contacts_get_property (GObject *object,
                              guint property_id,
                              GValue *value,
                              GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			g_value_set_boolean (
				value,
				e_source_contacts_get_include_me (
				E_SOURCE_CONTACTS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_contacts_constructed (GObject *object)
{
	ESource *source;
	ESourceExtension *extension;
	ESourceBackend *backend_extension;
	ESourceContacts *contacts_extension;
	const gchar *backend_name;
	const gchar *extension_name;
	gboolean include_me;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_source_contacts_parent_class)->constructed (object);

	extension = E_SOURCE_EXTENSION (object);
	source = e_source_extension_ref_source (extension);

	extension_name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
	backend_extension = e_source_get_extension (source, extension_name);
	backend_name = e_source_backend_get_backend_name (backend_extension);

	/* Only include local address books by default. */
	include_me = (g_strcmp0 (backend_name, "local") == 0);

	contacts_extension = E_SOURCE_CONTACTS (extension);
	e_source_contacts_set_include_me (contacts_extension, include_me);

	g_object_unref (source);
}

static void
e_source_contacts_class_init (ESourceContactsClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceContactsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_contacts_set_property;
	object_class->get_property = source_contacts_get_property;
	object_class->constructed = source_contacts_constructed;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_CONTACTS_BACKEND;

	g_object_class_install_property (
		object_class,
		PROP_INCLUDE_ME,
		g_param_spec_boolean (
			"include-me",
			"Include Me",
			"Include this address book in the contacts calendar",
			FALSE,  /* see constructed () */
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_contacts_init (ESourceContacts *extension)
{
	extension->priv = E_SOURCE_CONTACTS_GET_PRIVATE (extension);
}

gboolean
e_source_contacts_get_include_me (ESourceContacts *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_CONTACTS (extension), FALSE);

	return extension->priv->include_me;
}

void
e_source_contacts_set_include_me (ESourceContacts *extension,
                                  gboolean include_me)
{
	g_return_if_fail (E_IS_SOURCE_CONTACTS (extension));

	if (extension->priv->include_me == include_me)
		return;

	extension->priv->include_me = include_me;

	g_object_notify (G_OBJECT (extension), "include-me");
}
