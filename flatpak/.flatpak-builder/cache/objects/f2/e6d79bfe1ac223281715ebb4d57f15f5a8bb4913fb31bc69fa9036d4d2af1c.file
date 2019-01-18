/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/* e-source-backend-summary-setup.c - Backend Summary Data Configuration.
 *
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

/**
 * SECTION: e-source-backend-summary-setup
 * @include: libebook-contacts/libebook-contacts.h
 * @short_description: #ESource extension to configure summary fields
 *
 * The #ESourceBackendSummarySetup extension configures which #EContactFields
 * should be in the summary and which of those fields should be optimized for
 * quicker search results.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libebook-contacts/libebook-contacts.h>
 *
 *   ESourceBackendSummarySetup *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP);
 * ]|
 *
 * <note><para>The summary configuration is expected to be setup in only one way for
 * a given #ESource at creation time. Any configurations made after creation of the
 * book in question will be ignored.</para></note>
 *
 **/

#include "e-source-backend-summary-setup.h"
#include "e-book-contacts-enumtypes.h"

#define E_SOURCE_BACKEND_SUMMARY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	 ((obj), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP, \
	  ESourceBackendSummarySetupPrivate))

struct _ESourceBackendSummarySetupPrivate {
	GMutex  property_lock;
	gchar  *summary_fields;
	gchar  *indexed_fields;
};

enum {
	PROP_0,
	PROP_SUMMARY_FIELDS,
	PROP_INDEXED_FIELDS
};

G_DEFINE_TYPE (
	ESourceBackendSummarySetup,
	e_source_backend_summary_setup,
	E_TYPE_SOURCE_EXTENSION)

static gchar *
source_backend_summary_setup_dup_literal_fields (ESourceBackendSummarySetup *extension,
                                                 gint which)
{
	gchar *duplicate = NULL;

	g_mutex_lock (&extension->priv->property_lock);

	switch (which) {
		case PROP_SUMMARY_FIELDS:
			duplicate = g_strdup (extension->priv->summary_fields);
			break;
		case PROP_INDEXED_FIELDS:
			duplicate = g_strdup (extension->priv->indexed_fields);
			break;
		default:
			g_return_val_if_reached (NULL);
			break;
	}

	g_mutex_unlock (&extension->priv->property_lock);

	return duplicate;
}

static void
source_backend_summary_setup_set_literal_fields (ESourceBackendSummarySetup *extension,
                                                 const gchar *literal_fields,
                                                 gint which)
{
	const gchar *property_name;
	gchar **target;

	switch (which) {
		case PROP_SUMMARY_FIELDS:
			target = &(extension->priv->summary_fields);
			property_name = "summary-fields";
			break;
		case PROP_INDEXED_FIELDS:
			target = &(extension->priv->indexed_fields);
			property_name = "indexed-fields";
			break;
		default:
			g_return_if_reached ();
			break;
	}

	g_mutex_lock (&extension->priv->property_lock);

	if (e_util_strcmp0 (*target, literal_fields) == 0) {
		g_mutex_unlock (&extension->priv->property_lock);
		return;
	}

	g_free (*target);
	*target = e_util_strdup_strip (literal_fields);

	g_mutex_unlock (&extension->priv->property_lock);

	g_object_notify (G_OBJECT (extension), property_name);
}

static void
source_backend_summary_setup_set_property (GObject *object,
                                         guint property_id,
                                         const GValue *value,
                                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SUMMARY_FIELDS:
		case PROP_INDEXED_FIELDS:
			source_backend_summary_setup_set_literal_fields (
				E_SOURCE_BACKEND_SUMMARY_SETUP (object),
				g_value_get_string (value), property_id);
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_backend_summary_setup_get_property (GObject *object,
                                         guint property_id,
                                         GValue *value,
                                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SUMMARY_FIELDS:
		case PROP_INDEXED_FIELDS:
			g_value_take_string (
				value,
				source_backend_summary_setup_dup_literal_fields (
				E_SOURCE_BACKEND_SUMMARY_SETUP (object),
				property_id));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_backend_summary_setup_finalize (GObject *object)
{
	ESourceBackendSummarySetupPrivate *priv;

	priv = E_SOURCE_BACKEND_SUMMARY_GET_PRIVATE (object);

	g_mutex_clear (&priv->property_lock);
	g_free (priv->summary_fields);
	g_free (priv->indexed_fields);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_backend_summary_setup_parent_class)->
		finalize (object);
}

static void
e_source_backend_summary_setup_class_init (ESourceBackendSummarySetupClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (
		class, sizeof (ESourceBackendSummarySetupPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->get_property = source_backend_summary_setup_get_property;
	object_class->set_property = source_backend_summary_setup_set_property;
	object_class->finalize = source_backend_summary_setup_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP;

	g_object_class_install_property (
		object_class,
		PROP_SUMMARY_FIELDS,
		g_param_spec_string (
			"summary-fields",
			"Summary Fields",
			"The list of quick reference summary fields",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_INDEXED_FIELDS,
		g_param_spec_string (
			"indexed-fields",
			"Indexed Fields",
			"The list of summary fields which are to be "
			"given indexes in the underlying database",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_backend_summary_setup_init (ESourceBackendSummarySetup *extension)
{
	extension->priv = E_SOURCE_BACKEND_SUMMARY_GET_PRIVATE (extension);
	g_mutex_init (&extension->priv->property_lock);
}

static EContactField *
source_backend_summary_setup_get_fields_array (ESourceBackendSummarySetup *extension,
                                               gint *n_fields,
                                               gint which)
{
	EContactField field;
	EContactField *fields = NULL;
	gchar *literal_fields;
	gchar **split = NULL;
	gint n_ret_fields = 0, i;

	literal_fields = source_backend_summary_setup_dup_literal_fields (extension, which);

	if (literal_fields)
		split = g_strsplit (literal_fields, ":", 0);

	if (split) {
		n_ret_fields = g_strv_length (split);
		fields = g_new (EContactField, n_ret_fields);

		for (i = 0; i < n_ret_fields; i++) {
			field = e_contact_field_id (split[i]);

			if (field == 0)
				g_warning ("Unrecognized field '%s' in ESourceBackendSummarySetup fields", split[i]);

			fields[i] = field;
		}

		g_strfreev (split);
	}

	g_free (literal_fields);

	*n_fields = n_ret_fields;

	return fields;
}

static void
e_source_backend_summary_setup_set_fields_array (ESourceBackendSummarySetup *extension,
                                                 EContactField *fields,
                                                 gint n_fields,
                                                 gint which)
{
	gint i;
	GString *string;
	gboolean malformed = FALSE;

	string = g_string_new ("");

	for (i = 0; i < n_fields; i++) {
		const gchar *field_name = e_contact_field_name (fields[i]);

		if (field_name == NULL) {
			g_warning ("Invalid EContactField given to ESourceBackendSummarySetup");
			malformed = TRUE;
			break;
		}

		if (i > 0)
			g_string_append_c (string, ':');

		g_string_append (string, field_name);
	}

	if (malformed == FALSE)
		source_backend_summary_setup_set_literal_fields (extension, string->str, which);

	g_string_free (string, TRUE);
}

static void
e_source_backend_summary_setup_set_fields_va_list (ESourceBackendSummarySetup *extension,
                                                   va_list var_args,
                                                   gint which)
{
	GString *string;
	gboolean malformed = FALSE, first_field = TRUE;
	EContactField field;

	string = g_string_new ("");

	field = va_arg (var_args, EContactField);
	while (field > 0) {
		const gchar *field_name = e_contact_field_name (field);

		if (field_name == NULL) {
			g_warning ("Invalid EContactField given to ESourceBackendSummarySetup");
			malformed = TRUE;
			break;
		}

		if (!first_field)
			g_string_append_c (string, ':');
		else
			first_field = FALSE;

		g_string_append (string, field_name);

		field = va_arg (var_args, EContactField);
	}

	if (malformed == FALSE)
		source_backend_summary_setup_set_literal_fields (extension, string->str, which);

	g_string_free (string, TRUE);
}

/**
 * e_source_backend_summary_setup_get_summary_fields:
 * @extension: An #ESourceBackendSummarySetup
 * @n_fields: (out): A return location for the number of #EContactFields in the returned array.
 *
 * Fetches the #EContactFields which are configured to be a part of the summary.
 *
 * <note><para>If there are no configured summary fields, the default configuration is assumed</para></note>
 *
 * Returns: (transfer full): An array of #EContactFields @n_fields long, should be freed with g_free() when done.
 *
 * Since: 3.8
 */
EContactField *
e_source_backend_summary_setup_get_summary_fields (ESourceBackendSummarySetup *extension,
                                                   gint *n_fields)
{
	g_return_val_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension), NULL);
	g_return_val_if_fail (n_fields != NULL, NULL);

	return source_backend_summary_setup_get_fields_array (extension, n_fields, PROP_SUMMARY_FIELDS);
}

/**
 * e_source_backend_summary_setup_set_summary_fieldsv:
 * @extension: An #ESourceBackendSummarySetup
 * @fields: The array of #EContactFields to set as summary fields
 * @n_fields: The number of #EContactFields in @fields
 *
 * Sets the summary fields configured for the given addressbook.
 * 
 * The fields %E_CONTACT_UID and %E_CONTACT_REV are not optional,
 * they will be stored in the summary regardless of the configured summary.
 *
 * An empty summary configuration is assumed to be the default summary
 * configuration.
 *
 * <note><para>Only #EContactFields with the type #G_TYPE_STRING or #G_TYPE_BOOLEAN
 * are currently supported as summary fields.</para></note>
 *
 * Since: 3.8
 */
void
e_source_backend_summary_setup_set_summary_fieldsv (ESourceBackendSummarySetup *extension,
                                                    EContactField *fields,
                                                    gint n_fields)
{
	g_return_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension));
	g_return_if_fail (n_fields >= 0);

	e_source_backend_summary_setup_set_fields_array (extension, fields, n_fields, PROP_SUMMARY_FIELDS);
}

/**
 * e_source_backend_summary_setup_set_summary_fields:
 * @extension: An #ESourceBackendSummarySetup
 * @...: A 0 terminated list of #EContactFields to set as summary fields
 *
 * Like e_source_backend_summary_setup_set_summary_fieldsv(), but takes a literal
 * list of #EContactFields for convenience.
 *
 * To configure the address book summary fields with main phone nubmer fields:
 *
 * |[
 *   #include <libebook/libebook.h>
 *
 *   ESourceBackendSummarySetup *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP);
 *
 *   e_source_backend_summary_setup_set_summary_fields (extension, E_CONTACT_FULL_NAME, E_CONTACT_EMAIL, 0);
 * ]|
 *
 * Since: 3.8
 */
void
e_source_backend_summary_setup_set_summary_fields (ESourceBackendSummarySetup *extension,
                                                   ...)
{
	va_list var_args;

	g_return_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension));

	va_start (var_args, extension);
	e_source_backend_summary_setup_set_fields_va_list (extension, var_args, PROP_SUMMARY_FIELDS);
	va_end (var_args);
}

/**
 * e_source_backend_summary_setup_get_indexed_fields:
 * @extension: An #ESourceBackendSummarySetup
 * @types: (out) (transfer full): A return location for the set of #EBookIndexTypes corresponding
 *                                to each returned field,  should be freed with g_free() when no longer needed.
 * @n_fields: (out): The number of elements in the returned arrays.
 *
 * Fetches the #EContactFields configured to be indexed, with thier respective #EBookIndexTypes.
 *
 * Returns: (transfer full): The array of indexed #EContactFields.
 *
 * Since: 3.8
 */
EContactField  *
e_source_backend_summary_setup_get_indexed_fields (ESourceBackendSummarySetup *extension,
                                                   EBookIndexType **types,
                                                   gint *n_fields)
{
	EContactField *ret_fields;
	EBookIndexType *ret_types;
	gboolean malformed = FALSE;
	gchar **split, **index_split;
	gchar *literal_indexes;
	gint ret_n_fields;
	gint i;

	g_return_val_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension), NULL);
	g_return_val_if_fail (types != NULL, NULL);
	g_return_val_if_fail (n_fields != NULL, NULL);

	literal_indexes = source_backend_summary_setup_dup_literal_fields (extension, PROP_INDEXED_FIELDS);
	if (!literal_indexes) {
		*types = NULL;
		*n_fields = 0;
		return NULL;
	}

	split = g_strsplit (literal_indexes, ":", 0);
	ret_n_fields = g_strv_length (split);

	ret_fields = g_new0 (EContactField, ret_n_fields);
	ret_types = g_new0 (EBookIndexType, ret_n_fields);

	for (i = 0; i < ret_n_fields && malformed == FALSE; i++) {

		index_split = g_strsplit (split[i], ",", 2);

		if (index_split[0] && index_split[1]) {
			gint interpreted_enum = 0;

			ret_fields[i] = e_contact_field_id (index_split[0]);

			if (!e_enum_from_string (E_TYPE_BOOK_INDEX_TYPE,
						 index_split[1], &interpreted_enum)) {
				g_warning ("Unknown index type '%s' encountered in indexed fields", index_split[1]);
				malformed = TRUE;
			}

			if (ret_fields[i] <= 0 || ret_fields[i] >= E_CONTACT_FIELD_LAST) {
				g_warning ("Unknown contact field '%s' encountered in indexed fields", index_split[0]);
				malformed = TRUE;
			}

			ret_types[i] = interpreted_enum;
		} else {
			g_warning ("Malformed index definition '%s'", split[i]);
			malformed = TRUE;
		}

		g_strfreev (index_split);
	}

	if (malformed) {
		g_free (ret_fields);
		g_free (ret_types);

		ret_n_fields = 0;
		ret_fields = NULL;
		ret_types = NULL;
	}

	g_strfreev (split);
	g_free (literal_indexes);

	*n_fields = ret_n_fields;
	*types = ret_types;

	return ret_fields;
}

/**
 * e_source_backend_summary_setup_set_indexed_fieldsv:
 * @extension: An #ESourceBackendSummarySetup
 * @fields: The array of #EContactFields to set indexes for
 * @types: The array of #EBookIndexTypes defining what types of indexes to create
 * @n_fields: The number elements in the passed @fields, @rule_types and @rules arrays.
 *
 * Defines indexes for quick reference for the given given #EContactFields in the addressbook.
 *
 * The same #EContactField may be specified multiple times to create multiple indexes
 * with different characteristics. If an #E_BOOK_INDEX_PREFIX index is created it will
 * be used for #E_BOOK_QUERY_BEGINS_WITH queries. A #E_BOOK_INDEX_SUFFIX index
 * will be constructed efficiently for suffix matching and will be used for
 * #E_BOOK_QUERY_ENDS_WITH queries. Similar a #E_BOOK_INDEX_PHONE index will optimize
 * #E_BOOK_QUERY_EQUALS_PHONE_NUMBER searches.
 *
 * <note><para>The specified indexed fields must also be a part of the summary, any indexed fields
 * specified that are not already a part of the summary will be ignored.</para></note>
 *
 * Since: 3.8
 */
void
e_source_backend_summary_setup_set_indexed_fieldsv (ESourceBackendSummarySetup *extension,
                                                    EContactField *fields,
                                                    EBookIndexType *types,
                                                    gint n_fields)
{
	GString *string;
	gboolean malformed = FALSE;
	gint i;

	g_return_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension));
	g_return_if_fail (types != NULL || n_fields <= 0);
	g_return_if_fail (fields != NULL || n_fields <= 0);

	if (n_fields <= 0) {
		source_backend_summary_setup_set_literal_fields (extension, NULL, PROP_INDEXED_FIELDS);
		return;
	}

	string = g_string_new (NULL);

	for (i = 0; i < n_fields && malformed == FALSE; i++) {
		const gchar *field;
		const gchar *type;

		field = e_contact_field_name (fields[i]);
		type = e_enum_to_string (E_TYPE_BOOK_INDEX_TYPE, types[i]);

		if (!field) {
			g_warning ("Invalid contact field specified in indexed fields");
			malformed = TRUE;
		} else if (!type) {
			g_warning ("Invalid index type specified in indexed fields");
			malformed = TRUE;
		} else {
			if (i > 0)
				g_string_append_c (string, ':');
			g_string_append_printf (string, "%s,%s", field, type);
		}
	}

	if (!malformed)
		source_backend_summary_setup_set_literal_fields (extension, string->str, PROP_INDEXED_FIELDS);

	g_string_free (string, TRUE);
}

/**
 * e_source_backend_summary_setup_set_indexed_fields:
 * @extension: An #ESourceBackendSummarySetup
 * @...: A list of #EContactFields, #EBookIndexType pairs terminated by 0.
 *
 * Like e_source_backend_summary_setup_set_indexed_fieldsv(), but takes a literal list of
 * of indexes.
 *
 * To give the 'fullname' field an index for prefix and suffix searches:
 *
 * |[
 *   #include <libebook/libebook.h>
 *
 *   ESourceBackendSummarySetup *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP);
 *
 *   e_source_backend_summary_setup_set_indexed_fields (extension,
 *                                                      E_CONTACT_FULL_NAME, E_BOOK_INDEX_PREFIX,
 *                                                      E_CONTACT_FULL_NAME, E_BOOK_INDEX_SUFFIX,
 *                                                      0);
 * ]|
 *
 * Since: 3.8
 */
void
e_source_backend_summary_setup_set_indexed_fields (ESourceBackendSummarySetup *extension,
                                                   ...)
{
	GString *string;
	gboolean malformed = FALSE, first = TRUE;
	va_list var_args;
	EContactField field_in;
	EBookIndexType type_in;

	g_return_if_fail (E_IS_SOURCE_BACKEND_SUMMARY_SETUP (extension));

	string = g_string_new (NULL);

	va_start (var_args, extension);

	field_in = va_arg (var_args, EContactField);
	while (field_in > 0 && malformed == FALSE) {
		const gchar *field;
		const gchar *type;

		field = e_contact_field_name (field_in);
		if (field == NULL) {
			g_warning ("Invalid contact field specified in "
				"e_source_backend_summary_setup_set_indexed_fields()");
			malformed = TRUE;
			break;
		}

		type_in = va_arg (var_args, EBookIndexType);
		type = e_enum_to_string (E_TYPE_BOOK_INDEX_TYPE, type_in);
		if (type == NULL) {
			g_warning ("Invalid index type "
				"e_source_backend_summary_setup_set_indexed_fields()");
			malformed = TRUE;
			break;
		}

		if (!first)
			g_string_append_c (string, ':');
		else
			first = FALSE;

		g_string_append_printf (string, "%s,%s", field, type);

		/* Continue loop until first 0 found... */
		field_in = va_arg (var_args, EContactField);
	}
	va_end (var_args);

	if (!malformed)
		source_backend_summary_setup_set_literal_fields (extension, string->str, PROP_INDEXED_FIELDS);

	g_string_free (string, TRUE);
}
