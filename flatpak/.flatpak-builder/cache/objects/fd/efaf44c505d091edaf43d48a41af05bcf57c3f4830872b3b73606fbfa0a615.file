/*
 * e-source-uoa.c
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
 * SECTION: e-source-uoa
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for Ubuntu Online Accounts
 *
 * The #ESourceUoa extension associates an #ESource with an #AgAccount.
 * This extension is usually found in a top-level #ESource, with various
 * mail, calendar and address book data sources as children.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceUoa *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_UOA);
 * ]|
 **/

#include "e-source-uoa.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_UOA_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_UOA, ESourceUoaPrivate))

struct _ESourceUoaPrivate {
	guint account_id;
};

enum {
	PROP_0,
	PROP_ACCOUNT_ID
};

G_DEFINE_TYPE (
	ESourceUoa,
	e_source_uoa,
	E_TYPE_SOURCE_EXTENSION)

static void
source_uoa_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ACCOUNT_ID:
			e_source_uoa_set_account_id (
				E_SOURCE_UOA (object),
				g_value_get_uint (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_uoa_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ACCOUNT_ID:
			g_value_set_uint (
				value,
				e_source_uoa_get_account_id (
				E_SOURCE_UOA (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_source_uoa_class_init (ESourceUoaClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceUoaPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_uoa_set_property;
	object_class->get_property = source_uoa_get_property;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_UOA;

	g_object_class_install_property (
		object_class,
		PROP_ACCOUNT_ID,
		g_param_spec_uint (
			"account-id",
			"Account ID",
			"Ubuntu Online Account ID",
			0, G_MAXUINT, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_uoa_init (ESourceUoa *extension)
{
	extension->priv = E_SOURCE_UOA_GET_PRIVATE (extension);
}

/**
 * e_source_uoa_get_account_id:
 * @extension: an #ESourceUoa
 *
 * Returns the numeric identifier of the Ubuntu Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * Returns: the associated Ubuntu Online Account ID
 *
 * Since: 3.8
 **/
guint
e_source_uoa_get_account_id (ESourceUoa *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_UOA (extension), 0);

	return extension->priv->account_id;
}

/**
 * e_source_uoa_set_account_id:
 * @extension: an #ESourceUoa
 * @account_id: the associated Ubuntu Online Account ID
 *
 * Sets the numeric identifier of the Ubuntu Online Account associated
 * with the #ESource to which @extension belongs.
 *
 * Since: 3.8
 **/
void
e_source_uoa_set_account_id (ESourceUoa *extension,
                             guint account_id)
{
	g_return_if_fail (E_IS_SOURCE_UOA (extension));

	if (extension->priv->account_id == account_id)
		return;

	extension->priv->account_id = account_id;

	g_object_notify (G_OBJECT (extension), "account-id");
}

