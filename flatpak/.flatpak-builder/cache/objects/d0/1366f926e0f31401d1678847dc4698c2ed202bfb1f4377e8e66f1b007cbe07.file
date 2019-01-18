/*
 * e-source-ldap.c
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

#include "e-source-authentication.h"
#include "e-source-security.h"
#include "e-source-enumtypes.h"

#include "e-source-ldap.h"

#define E_SOURCE_LDAP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_LDAP, ESourceLDAPPrivate))

struct _ESourceLDAPPrivate {
	gboolean can_browse;
	gchar *filter;
	guint limit;
	gchar *root_dn;
	ESourceLDAPScope scope;

	/* These are bound to other extensions. */
	ESourceLDAPAuthentication authentication;
	ESourceLDAPSecurity security;
};

enum {
	PROP_0,
	PROP_AUTHENTICATION,
	PROP_CAN_BROWSE,
	PROP_FILTER,
	PROP_LIMIT,
	PROP_ROOT_DN,
	PROP_SCOPE,
	PROP_SECURITY
};

G_DEFINE_TYPE (
	ESourceLDAP,
	e_source_ldap,
	E_TYPE_SOURCE_EXTENSION)

static struct ELDAPAuthMapping {
	ESourceLDAPAuthentication value;
	const gchar *nick;
} ldap_auth_mapping[] = {
	{ E_SOURCE_LDAP_AUTHENTICATION_NONE, "none" },
	{ E_SOURCE_LDAP_AUTHENTICATION_EMAIL, "ldap/simple-email" },
	{ E_SOURCE_LDAP_AUTHENTICATION_BINDDN, "ldap/simple-binddn" }
};

static gboolean
source_ldap_transform_auth_enum_nick_to_value (GBinding *binding,
					       const GValue *source_value,
					       GValue *target_value,
					       gpointer not_used)
{
	GEnumClass *enum_class;
	const gchar *string;
	gboolean success = FALSE;
	gint ii;

	enum_class = g_type_class_peek (G_VALUE_TYPE (target_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	string = g_value_get_string (source_value);

	for (ii = 0; ii < G_N_ELEMENTS (ldap_auth_mapping); ii++) {
		if (g_strcmp0 (ldap_auth_mapping[ii].nick, string) == 0) {
			g_value_set_enum (target_value, ldap_auth_mapping[ii].value);
			success = TRUE;
			break;
		}
	}

	return success;
}

static gboolean
source_ldap_transform_auth_enum_value_to_nick (GBinding *binding,
					       const GValue *source_value,
					       GValue *target_value,
					       gpointer not_used)
{
	GEnumClass *enum_class;
	gint value;
	gboolean success = FALSE;
	gint ii;

	enum_class = g_type_class_peek (G_VALUE_TYPE (source_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	value = g_value_get_enum (source_value);

	for (ii = 0; ii < G_N_ELEMENTS (ldap_auth_mapping); ii++) {
		if (value == ldap_auth_mapping[ii].value) {
			g_value_set_string (target_value, ldap_auth_mapping[ii].nick);
			success = TRUE;
			break;
		}
	}

	return success;
}

static gboolean
source_ldap_transform_enum_nick_to_value (GBinding *binding,
                                          const GValue *source_value,
                                          GValue *target_value,
                                          gpointer not_used)
{
	GEnumClass *enum_class;
	GEnumValue *enum_value;
	const gchar *string;
	gboolean success = FALSE;

	enum_class = g_type_class_peek (G_VALUE_TYPE (target_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	string = g_value_get_string (source_value);
	enum_value = g_enum_get_value_by_nick (enum_class, string);
	if (enum_value != NULL) {
		g_value_set_enum (target_value, enum_value->value);
		success = TRUE;
	}

	return success;
}

static gboolean
source_ldap_transform_enum_value_to_nick (GBinding *binding,
                                          const GValue *source_value,
                                          GValue *target_value,
                                          gpointer not_used)
{
	GEnumClass *enum_class;
	GEnumValue *enum_value;
	gint value;
	gboolean success = FALSE;

	enum_class = g_type_class_peek (G_VALUE_TYPE (source_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	value = g_value_get_enum (source_value);
	enum_value = g_enum_get_value (enum_class, value);
	if (enum_value != NULL) {
		g_value_set_string (target_value, enum_value->value_nick);
		success = TRUE;
	}

	return success;
}

static void
source_ldap_set_property (GObject *object,
                          guint property_id,
                          const GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTHENTICATION:
			e_source_ldap_set_authentication (
				E_SOURCE_LDAP (object),
				g_value_get_enum (value));
			return;

		case PROP_CAN_BROWSE:
			e_source_ldap_set_can_browse (
				E_SOURCE_LDAP (object),
				g_value_get_boolean (value));
			return;

		case PROP_FILTER:
			e_source_ldap_set_filter (
				E_SOURCE_LDAP (object),
				g_value_get_string (value));
			return;

		case PROP_LIMIT:
			e_source_ldap_set_limit (
				E_SOURCE_LDAP (object),
				g_value_get_uint (value));
			return;

		case PROP_ROOT_DN:
			e_source_ldap_set_root_dn (
				E_SOURCE_LDAP (object),
				g_value_get_string (value));
			return;

		case PROP_SCOPE:
			e_source_ldap_set_scope (
				E_SOURCE_LDAP (object),
				g_value_get_enum (value));
			return;

		case PROP_SECURITY:
			e_source_ldap_set_security (
				E_SOURCE_LDAP (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_ldap_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTHENTICATION:
			g_value_set_enum (
				value,
				e_source_ldap_get_authentication (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_CAN_BROWSE:
			g_value_set_boolean (
				value,
				e_source_ldap_get_can_browse (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_FILTER:
			g_value_take_string (
				value,
				e_source_ldap_dup_filter (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_LIMIT:
			g_value_set_uint (
				value,
				e_source_ldap_get_limit (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_ROOT_DN:
			g_value_take_string (
				value,
				e_source_ldap_dup_root_dn (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_SCOPE:
			g_value_set_enum (
				value,
				e_source_ldap_get_scope (
				E_SOURCE_LDAP (object)));
			return;

		case PROP_SECURITY:
			g_value_set_enum (
				value,
				e_source_ldap_get_security (
				E_SOURCE_LDAP (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_ldap_finalize (GObject *object)
{
	ESourceLDAPPrivate *priv;

	priv = E_SOURCE_LDAP_GET_PRIVATE (object);

	g_free (priv->filter);
	g_free (priv->root_dn);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_ldap_parent_class)->finalize (object);
}

static void
source_ldap_constructed (GObject *object)
{
	ESource *source;
	ESourceExtension *this_extension;
	ESourceExtension *other_extension;
	const gchar *extension_name;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_ldap_parent_class)->constructed (object);

	this_extension = E_SOURCE_EXTENSION (object);
	source = e_source_extension_ref_source (this_extension);

	extension_name = E_SOURCE_EXTENSION_AUTHENTICATION;
	other_extension = e_source_get_extension (source, extension_name);

	e_binding_bind_property_full (
		other_extension, "method",
		this_extension, "authentication",
		G_BINDING_BIDIRECTIONAL |
		G_BINDING_SYNC_CREATE,
		source_ldap_transform_auth_enum_nick_to_value,
		source_ldap_transform_auth_enum_value_to_nick,
		NULL, (GDestroyNotify) NULL);

	extension_name = E_SOURCE_EXTENSION_SECURITY;
	other_extension = e_source_get_extension (source, extension_name);

	e_binding_bind_property_full (
		other_extension, "method",
		this_extension, "security",
		G_BINDING_BIDIRECTIONAL |
		G_BINDING_SYNC_CREATE,
		source_ldap_transform_enum_nick_to_value,
		source_ldap_transform_enum_value_to_nick,
		NULL, (GDestroyNotify) NULL);

	g_object_unref (source);
}

static void
e_source_ldap_class_init (ESourceLDAPClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceLDAPPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_ldap_set_property;
	object_class->get_property = source_ldap_get_property;
	object_class->finalize = source_ldap_finalize;
	object_class->constructed = source_ldap_constructed;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_LDAP_BACKEND;

	/* This is bound to the authentication extension.
	 * Do not use E_SOURCE_PARAM_SETTING here. */
	g_object_class_install_property (
		object_class,
		PROP_AUTHENTICATION,
		g_param_spec_enum (
			"authentication",
			"Authentication",
			"LDAP authentication method",
			E_TYPE_SOURCE_LDAP_AUTHENTICATION,
			E_SOURCE_LDAP_AUTHENTICATION_NONE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_CAN_BROWSE,
		g_param_spec_boolean (
			"can-browse",
			"Can Browse",
			"Allow browsing contacts",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_FILTER,
		g_param_spec_string (
			"filter",
			"Filter",
			"LDAP search filter",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_LIMIT,
		g_param_spec_uint (
			"limit",
			"Limit",
			"Download limit",
			0, G_MAXUINT, 100,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ROOT_DN,
		g_param_spec_string (
			"root-dn",
			"Root DN",
			"LDAP search base",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SCOPE,
		g_param_spec_enum (
			"scope",
			"Scope",
			"LDAP search scope",
			E_TYPE_SOURCE_LDAP_SCOPE,
			E_SOURCE_LDAP_SCOPE_ONELEVEL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	/* This is bound to the security extension.
	 * Do not use E_SOURCE_PARAM_SETTING here. */
	g_object_class_install_property (
		object_class,
		PROP_SECURITY,
		g_param_spec_enum (
			"security",
			"Security",
			"LDAP security method",
			E_TYPE_SOURCE_LDAP_SECURITY,
			E_SOURCE_LDAP_SECURITY_NONE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
e_source_ldap_init (ESourceLDAP *extension)
{
	extension->priv = E_SOURCE_LDAP_GET_PRIVATE (extension);
}

ESourceLDAPAuthentication
e_source_ldap_get_authentication (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), 0);

	return extension->priv->authentication;
}

void
e_source_ldap_set_authentication (ESourceLDAP *extension,
                                  ESourceLDAPAuthentication authentication)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	if (extension->priv->authentication == authentication)
		return;

	extension->priv->authentication = authentication;

	g_object_notify (G_OBJECT (extension), "authentication");
}

gboolean
e_source_ldap_get_can_browse (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), FALSE);

	return extension->priv->can_browse;
}

void
e_source_ldap_set_can_browse (ESourceLDAP *extension,
                              gboolean can_browse)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	if (extension->priv->can_browse == can_browse)
		return;

	extension->priv->can_browse = can_browse;

	g_object_notify (G_OBJECT (extension), "can-browse");
}

const gchar *
e_source_ldap_get_filter (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), NULL);

	return extension->priv->filter;
}

gchar *
e_source_ldap_dup_filter (ESourceLDAP *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_ldap_get_filter (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

void
e_source_ldap_set_filter (ESourceLDAP *extension,
                          const gchar *filter)
{
	gboolean needs_parens;
	gchar *new_filter;

	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	needs_parens =
		(filter != NULL) && (*filter != '\0') &&
		!g_str_has_prefix (filter, "(") &&
		!g_str_has_suffix (filter, ")");

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (needs_parens)
		new_filter = g_strdup_printf ("(%s)", filter);
	else
		new_filter = g_strdup (filter);

	if (g_strcmp0 (extension->priv->filter, new_filter) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		g_free (new_filter);
		return;
	}

	g_free (extension->priv->filter);
	extension->priv->filter = new_filter;

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "filter");
}

guint
e_source_ldap_get_limit (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), 0);

	return extension->priv->limit;
}

void
e_source_ldap_set_limit (ESourceLDAP *extension,
                         guint limit)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	if (extension->priv->limit == limit)
		return;

	extension->priv->limit = limit;

	g_object_notify (G_OBJECT (extension), "limit");
}

const gchar *
e_source_ldap_get_root_dn (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), NULL);

	return extension->priv->root_dn;
}

gchar *
e_source_ldap_dup_root_dn (ESourceLDAP *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_ldap_get_root_dn (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

void
e_source_ldap_set_root_dn (ESourceLDAP *extension,
                           const gchar *root_dn)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->root_dn, root_dn) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->root_dn);
	extension->priv->root_dn = e_util_strdup_strip (root_dn);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "root-dn");
}

ESourceLDAPScope
e_source_ldap_get_scope (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), 0);

	return extension->priv->scope;
}

void
e_source_ldap_set_scope (ESourceLDAP *extension,
                         ESourceLDAPScope scope)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	if (extension->priv->scope == scope)
		return;

	extension->priv->scope = scope;

	g_object_notify (G_OBJECT (extension), "scope");
}

ESourceLDAPSecurity
e_source_ldap_get_security (ESourceLDAP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LDAP (extension), 0);

	return extension->priv->security;
}

void
e_source_ldap_set_security (ESourceLDAP *extension,
                            ESourceLDAPSecurity security)
{
	g_return_if_fail (E_IS_SOURCE_LDAP (extension));

	if (extension->priv->security == security)
		return;

	extension->priv->security = security;

	g_object_notify (G_OBJECT (extension), "security");
}
