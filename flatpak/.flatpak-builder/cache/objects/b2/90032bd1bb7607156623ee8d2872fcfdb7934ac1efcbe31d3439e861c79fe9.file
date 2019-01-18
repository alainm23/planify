/*
A library to communicate a menu object set accross DBus and
track updates and maintain consistency.

Copyright 2011 Canonical Ltd.

Authors:
    Ted Gould <ted@canonical.com>

This program is free software: you can redistribute it and/or modify it 
under the terms of either or both of the following licenses:

1) the GNU Lesser General Public License version 3, as published by the 
Free Software Foundation; and/or
2) the GNU Lesser General Public License version 2.1, as published by 
the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR 
PURPOSE.  See the applicable version of the GNU Lesser General Public 
License for more details.

You should have received a copy of both the GNU Lesser General Public 
License version 3 and version 2.1 along with this program.  If not, see 
<http://www.gnu.org/licenses/>
*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <glib/gi18n-lib.h>

#include "defaults.h"
#include "menuitem.h"
#include "client.h"

struct _DbusmenuDefaultsPrivate {
	GHashTable * types;
};

typedef struct _DefaultEntry DefaultEntry;
struct _DefaultEntry {
	GVariantType * type;
	GVariant * value;
};

#define DBUSMENU_DEFAULTS_GET_PRIVATE(o) \
(G_TYPE_INSTANCE_GET_PRIVATE ((o), DBUSMENU_TYPE_DEFAULTS, DbusmenuDefaultsPrivate))

static void dbusmenu_defaults_class_init (DbusmenuDefaultsClass *klass);
static void dbusmenu_defaults_init       (DbusmenuDefaults *self);
static void dbusmenu_defaults_dispose    (GObject *object);
static void dbusmenu_defaults_finalize   (GObject *object);

static DefaultEntry * entry_create (const GVariantType * type, GVariant * variant);
static void entry_destroy (gpointer entry);

G_DEFINE_TYPE (DbusmenuDefaults, dbusmenu_defaults, G_TYPE_OBJECT);

static void
dbusmenu_defaults_class_init (DbusmenuDefaultsClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (DbusmenuDefaultsPrivate));

	object_class->dispose = dbusmenu_defaults_dispose;
	object_class->finalize = dbusmenu_defaults_finalize;
	return;
}

static void
dbusmenu_defaults_init (DbusmenuDefaults *self)
{
	self->priv = DBUSMENU_DEFAULTS_GET_PRIVATE(self); 

	self->priv->types = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)g_hash_table_destroy);

	/* Standard defaults */
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_VISIBLE,        G_VARIANT_TYPE_BOOLEAN,   g_variant_new_boolean(TRUE)); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_ENABLED,        G_VARIANT_TYPE_BOOLEAN,   g_variant_new_boolean(TRUE)); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_LABEL,          G_VARIANT_TYPE_STRING,    g_variant_new_string(_("Label Empty")));
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_ICON_NAME,      G_VARIANT_TYPE_STRING,    NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_ICON_DATA,      G_VARIANT_TYPE("ay"),     NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE,    G_VARIANT_TYPE_STRING,    NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_TOGGLE_STATE,   G_VARIANT_TYPE_INT32,     NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_SHORTCUT,       G_VARIANT_TYPE("aas"),    NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY,  G_VARIANT_TYPE_STRING,    NULL); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_DISPOSITION,    G_VARIANT_TYPE_STRING,    g_variant_new_string(DBUSMENU_MENUITEM_DISPOSITION_NORMAL)); 
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_DEFAULT,    DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC,G_VARIANT_TYPE_STRING,    NULL);

	/* Separator defaults */
	dbusmenu_defaults_default_set(self,   DBUSMENU_CLIENT_TYPES_SEPARATOR,  DBUSMENU_MENUITEM_PROP_VISIBLE,        G_VARIANT_TYPE_BOOLEAN,   g_variant_new_boolean(TRUE)); 

	return;
}

static void
dbusmenu_defaults_dispose (GObject *object)
{
	DbusmenuDefaults * self = DBUSMENU_DEFAULTS(object);

	if (self->priv->types != NULL) {
		g_hash_table_destroy(self->priv->types);
		self->priv->types = NULL;
	}

	G_OBJECT_CLASS (dbusmenu_defaults_parent_class)->dispose (object);
	return;
}

static void
dbusmenu_defaults_finalize (GObject *object)
{

	G_OBJECT_CLASS (dbusmenu_defaults_parent_class)->finalize (object);
	return;
}

/* Create a new entry based on the info provided */
static DefaultEntry *
entry_create (const GVariantType * type, GVariant * variant)
{
	DefaultEntry * defentry = g_new0(DefaultEntry, 1);

	if (type != NULL) {
		defentry->type = g_variant_type_copy(type);
	}

	if (variant != NULL) {
		defentry->value = variant;
		g_variant_ref_sink(variant);
	}

	return defentry;
}

/* Destroy an entry */
static void
entry_destroy (gpointer entry)
{
	DefaultEntry * defentry = (DefaultEntry *)entry;

	if (defentry->type != NULL) {
		g_variant_type_free(defentry->type);
		defentry->type = NULL;
	}

	if (defentry->value != NULL) {
		g_variant_unref(defentry->value);
		defentry->value = NULL;
	}

	g_free(defentry);
	return;
}

static DbusmenuDefaults * default_defaults = NULL;

/*
 * dbusmenu_defaults_ref_default:
 *
 * Get a reference to the default instance.  If it doesn't exist this
 * function will create it.
 *
 * Return value: (transfer full): A reference to the defaults
 */
DbusmenuDefaults *
dbusmenu_defaults_ref_default (void)
{
	if (default_defaults == NULL) {
		default_defaults = DBUSMENU_DEFAULTS(g_object_new(DBUSMENU_TYPE_DEFAULTS, NULL));
		g_object_add_weak_pointer(G_OBJECT(default_defaults), (gpointer *)&default_defaults);
	} else {
		g_object_ref(default_defaults);
	}

	return default_defaults;
}

/*
 * dbusmenu_defaults_default_set:
 * @defaults: The #DbusmenuDefaults object to add to
 * @type: (allow-none): The #DbusmenuMenuitem type for this default if #NULL will default to #DBUSMENU_CLIENT_TYPE_DEFAULT
 * @property: Property name for the default
 * @prop_type: (allow-none): Type of the property for runtime checking.  To disable checking set to #NULL.
 * @value: (allow-none): Default value for @property.  #NULL if by default it is unset, but you want type checking from @prop_type.
 *
 * Sets up an entry in the defaults database for a given @property
 * and menuitem type @type.  @prop_type and @value can both be #NULL
 * but both of them can not.
 */
void
dbusmenu_defaults_default_set (DbusmenuDefaults * defaults, const gchar * type, const gchar * property, const GVariantType * prop_type, GVariant * value)
{
	g_return_if_fail(DBUSMENU_IS_DEFAULTS(defaults));
	g_return_if_fail(property != NULL);
	g_return_if_fail(prop_type != NULL || value != NULL);

	if (type == NULL) {
		type = DBUSMENU_CLIENT_TYPES_DEFAULT;
	}

	GHashTable * prop_table = (GHashTable *)g_hash_table_lookup(defaults->priv->types, type);

	/* We've never had a default for this type, so we need
	   to create a table for it. */
	if (prop_table == NULL) {
		prop_table = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, entry_destroy);

		g_hash_table_insert(prop_table, g_strdup(property), entry_create(prop_type, value));
		g_hash_table_insert(defaults->priv->types, g_strdup(type), prop_table);
	} else {
		g_hash_table_replace(prop_table, g_strdup(property), entry_create(prop_type, value));
	}

	return;
}

/*
 * dbusmenu_defaults_default_get:
 * @defaults: The default database to use
 * @type: (allow-none): The #DbusmenuMenuitem type for this default if #NULL will default to #DBUSMENU_CLIENT_TYPE_DEFAULT
 * @property: Property name to lookup
 *
 * Gets an entry in the database for a give @property and @type.
 *
 * Return value: (transfer none): Returns a variant that does not
 * have its ref count increased.  If you want to keep it, you should
 * do that.
 */
GVariant *
dbusmenu_defaults_default_get (DbusmenuDefaults * defaults, const gchar * type, const gchar * property)
{
	g_return_val_if_fail(DBUSMENU_IS_DEFAULTS(defaults), NULL);
	g_return_val_if_fail(property != NULL, NULL);

	if (type == NULL) {
		type = DBUSMENU_CLIENT_TYPES_DEFAULT;
	}

	GHashTable * prop_table = (GHashTable *)g_hash_table_lookup(defaults->priv->types, type);

	if (prop_table == NULL) {
		return NULL;
	}

	DefaultEntry * entry = (DefaultEntry *)g_hash_table_lookup(prop_table, property);

	if (entry == NULL) {
		return NULL;
	}

	return entry->value;
}

/*
 * dbusmenu_defaults_default_get_type:
 * @defaults: The default database to use
 * @type: (allow-none): The #DbusmenuMenuitem type for this default if #NULL will default to #DBUSMENU_CLIENT_TYPE_DEFAULT
 * @property: Property name to lookup
 *
 * Gets the type for an entry in the database for a give @property and @type.
 *
 * Return value: (transfer none): Returns a type for the given
 * @property value.
 */
GVariantType *
dbusmenu_defaults_default_get_type (DbusmenuDefaults * defaults, const gchar * type, const gchar * property)
{
	g_return_val_if_fail(DBUSMENU_IS_DEFAULTS(defaults), NULL);
	g_return_val_if_fail(property != NULL, NULL);

	if (type == NULL) {
		type = DBUSMENU_CLIENT_TYPES_DEFAULT;
	}

	GHashTable * prop_table = (GHashTable *)g_hash_table_lookup(defaults->priv->types, type);

	if (prop_table == NULL) {
		return NULL;
	}

	DefaultEntry * entry = (DefaultEntry *)g_hash_table_lookup(prop_table, property);

	if (entry == NULL) {
		return NULL;
	}

	return entry->type;
}

