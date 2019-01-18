/*
 * e-source-mdn.c
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
 * SECTION: e-source-mdn
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for MDN settings
 *
 * The #ESourceMDN extension tracks Message Disposition Notification
 * settings for a mail account.  See RFC 2298 for more information about
 * Message Disposition Notification.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMDN *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MDN);
 * ]|
 **/

#include "e-source-mdn.h"

#include <libedataserver/e-source-enumtypes.h>

#define E_SOURCE_MDN_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MDN, ESourceMDNPrivate))

struct _ESourceMDNPrivate {
	EMdnResponsePolicy response_policy;
};

enum {
	PROP_0,
	PROP_RESPONSE_POLICY
};

G_DEFINE_TYPE (
	ESourceMDN,
	e_source_mdn,
	E_TYPE_SOURCE_EXTENSION)

static void
source_mdn_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_RESPONSE_POLICY:
			e_source_mdn_set_response_policy (
				E_SOURCE_MDN (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mdn_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_RESPONSE_POLICY:
			g_value_set_enum (
				value,
				e_source_mdn_get_response_policy (
				E_SOURCE_MDN (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_source_mdn_class_init (ESourceMDNClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceMDNPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_mdn_set_property;
	object_class->get_property = source_mdn_get_property;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MDN;

	g_object_class_install_property (
		object_class,
		PROP_RESPONSE_POLICY,
		g_param_spec_enum (
			"response-policy",
			"Response Policy",
			"Policy for responding to MDN requests",
			E_TYPE_MDN_RESPONSE_POLICY,
			E_MDN_RESPONSE_POLICY_ASK,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_mdn_init (ESourceMDN *extension)
{
	extension->priv = E_SOURCE_MDN_GET_PRIVATE (extension);
}

/**
 * e_source_mdn_get_response_policy:
 * @extension: an #ESourceMDN
 *
 * Returns the policy for this mail account on responding to Message
 * Disposition Notification requests when receiving mail messages.
 *
 * Returns: the #EMdnResponsePolicy for this account
 *
 * Since: 3.6
 **/
EMdnResponsePolicy
e_source_mdn_get_response_policy (ESourceMDN *extension)
{
	g_return_val_if_fail (
		E_IS_SOURCE_MDN (extension),
		E_MDN_RESPONSE_POLICY_NEVER);

	return extension->priv->response_policy;
}

/**
 * e_source_mdn_set_response_policy:
 * @extension: an #ESourceMDN
 * @response_policy: the #EMdnResponsePolicy
 *
 * Sets the policy for this mail account on responding to Message
 * Disposition Notification requests when receiving mail messages.
 *
 * Since: 3.6
 **/
void
e_source_mdn_set_response_policy (ESourceMDN *extension,
                                  EMdnResponsePolicy response_policy)
{
	g_return_if_fail (E_IS_SOURCE_MDN (extension));

	if (extension->priv->response_policy == response_policy)
		return;

	extension->priv->response_policy = response_policy;

	g_object_notify (G_OBJECT (extension), "response-policy");
}
