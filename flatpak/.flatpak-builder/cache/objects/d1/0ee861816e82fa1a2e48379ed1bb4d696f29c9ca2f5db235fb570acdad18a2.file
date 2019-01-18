/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
 * Copyright (C) 2015-2016 Richard Hughes <richard@hughsie.com>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "as-category.h"

#include "config.h"
#include <glib/gi18n.h>
#include <glib.h>

#include "as-component.h"

/**
 * SECTION:as-category
 * @short_description: Representation of a XDG category
 * @include: appstream.h
 *
 * This object represents an XDG category, as defined at:
 * http://standards.freedesktop.org/menu-spec/menu-spec-1.0.html#category-registry
 *
 * The #AsCategory object does not support all aspects of a menu. Its main purpose
 * is to be used in software-centers to group visual components (gui/web applications).
 *
 * You can use %as_get_default_categories() to get a set of supported default categories.
 *
 * See also: #AsComponent
 */

#ifdef __clang__
#pragma clang diagnostic ignored "-Wmissing-field-initializers"
#endif

typedef struct {
	const gchar	*id;
	const gchar	*name;
	const gchar	*fdo_cats[16];
} AsCategoryMap;

typedef struct {
	const gchar		*id;
	const AsCategoryMap	*mapping;
	const gchar		*name;
	const gchar		*icon;
} AsCategoryData;

/* AudioVideo */
static const AsCategoryMap map_audiovideo[] = {
	{ "featured",		NC_("Category of AudioVideo", "Featured"),
					{ "AudioVideo::Featured",
					  NULL} },
	{ "creation-editing",	NC_("Category of AudioVideo", "Audio Creation & Editing"),
					{ "AudioVideo::AudioVideoEditing",
					  "AudioVideo::Midi",
					  "AudioVideo::DiscBurning",
					  "AudioVideo::Sequencer",
					  NULL} },
	{ "music-players",	NC_("Category of AudioVideo", "Music Players"),
					{ "AudioVideo::Music",
					  "AudioVideo::Player",
					  NULL} },
	{ NULL }
};

/* Development */
static const AsCategoryMap map_developertools[] = {
	{ "featured",		NC_("Category of Development", "Featured"),
					{ "Development::Featured",
					  NULL} },
	{ "debuggers",		NC_("Category of Development", "Debuggers"),
					{ "Development:Debugger",
					  NULL} },
	{ "ide",		NC_("Category of Development", "IDEs"),
					{ "Development::IDE",
					  "Development::GUIDesigner",
					  NULL} },
	{ NULL }
};

/* Education */
static const AsCategoryMap map_education[] = {
	{ "featured",		NC_("Category of Education", "Featured"),
					{ "Education::Featured",
					  NULL} },
	{ "astronomy",		NC_("Category of Education", "Astronomy"),
					{ "Education::Astronomy",
					  NULL} },
	{ "chemistry",		NC_("Category of Education", "Chemistry"),
					{ "Education::Chemistry",
					  NULL} },
	{ "languages",		NC_("Category of Education", "Languages"),
					{ "Education::Languages",
					  "Education::Literature",
					  NULL} },
	{ "math",		NC_("Category of Education", "Math"),
					{ "Education::Math",
					  "Education::NumericalAnalysis",
					  NULL} },
	{ NULL }
};

/* Games */
static const AsCategoryMap map_games[] = {
	{ "featured",		NC_("Category of Games", "Featured"),
					{ "Game::Featured",
					  NULL} },
	{ "action",		NC_("Category of Games", "Action"),
					{ "Game::ActionGame",
					  NULL} },
	{ "adventure",		NC_("Category of Games", "Adventure"),
					{ "Game::AdventureGame",
					  NULL} },
	{ "arcade",		NC_("Category of Games", "Arcade"),
					{ "Game::ArcadeGame",
					  NULL} },
	{ "blocks",		NC_("Category of Games", "Blocks"),
					{ "Game::BlocksGame",
					  NULL} },
	{ "board",		NC_("Category of Games", "Board"),
					{ "Game::BoardGame",
					  NULL} },
	{ "card",		NC_("Category of Games", "Card"),
					{ "Game::CardGame",
					  NULL} },
	{ "emulator",		NC_("Category of Games", "Emulators"),
					{ "Game::Emulator",
					  NULL} },
	{ "kids",		NC_("Category of Games", "Kids"),
					{ "Game::KidsGame",
					  NULL} },
	{ "logic",		NC_("Category of Games", "Logic"),
					{ "Game::LogicGame",
					  NULL} },
	{ "role-playing",	NC_("Category of Games", "Role Playing"),
					{ "Game::RolePlaying",
					  NULL} },
	{ "sports",		NC_("Category of Games", "Sports"),
					{ "Game::SportsGame",
					  "Game::Simulation",
					  NULL} },
	{ "strategy",		NC_("Category of Games", "Strategy"),
					{ "Game::StrategyGame",
					  NULL} },
	{ NULL }
};

/* Graphics */
static const AsCategoryMap map_graphics[] = {
	{ "featured",		NC_("Category of Graphics", "Featured"),
					{ "Graphics::Featured",
					  NULL} },
	{ "3d",			NC_("Category of Graphics", "3D Graphics"),
					{ "Graphics::3DGraphics",
					  NULL} },
	{ "photography",	NC_("Category of Graphics", "Photography"),
					{ "Graphics::Photography",
					  NULL} },
	{ "scanning",		NC_("Category of Graphics", "Scanning"),
					{ "Graphics::Scanning",
					  NULL} },
	{ "vector",		NC_("Category of Graphics", "Vector Graphics"),
					{ "Graphics::VectorGraphics",
					  NULL} },
	{ "viewers",		NC_("Category of Graphics", "Viewers"),
					{ "Graphics::Viewer",
					  NULL} },
	{ NULL }
};

/* Office */
static const AsCategoryMap map_office[] = {
	{ "featured",		NC_("Category of Office", "Featured"),
					{ "Office::Featured",
					  NULL} },
	{ "calendar",		NC_("Category of Office", "Calendar"),
					{ "Office::Calendar",
					  "Office::ProjectManagement",
					  NULL} },
	{ "database",		NC_("Category of Office", "Database"),
					{ "Office::Database",
					  NULL} },
	{ "finance",		NC_("Category of Office", "Finance"),
					{ "Office::Finance",
					  "Office::Spreadsheet",
					  NULL} },
	{ "word-processor",	NC_("Category of Office", "Word Processor"),
					{ "Office::WordProcessor",
					  "Office::Dictionary",
					  NULL} },
	{ NULL }
};

/* Addons */
static const AsCategoryMap map_addons[] = {
	{ "fonts",		NC_("Category of Addons", "Fonts"),
					{ "Addons::Fonts",
					  NULL} },
	{ "codecs",		NC_("Category of Addons", "Codecs"),
					{ "Addons::Codecs",
					  NULL} },
	{ "input-sources",	NC_("Category of Addons", "Input Sources"),
					{ "Addons::InputSources",
					  NULL} },
	{ "language-packs",	NC_("Category of Addons", "Language Packs"),
					{ "Addons::LanguagePacks",
					  NULL} },
	{ "localization",	NC_("Category of Addons", "Localization"),
					{ "Addons::Localization",
					  NULL} },
	{ NULL }
};

/* Science */
static const AsCategoryMap map_science[] = {
	{ "featured",		NC_("Category of Science", "Featured"),
					{ "Science::Featured",
					  NULL} },
	{ "artificial-intelligence", NC_("Category of Science", "Artificial Intelligence"),
					{ "Science::ArtificialIntelligence",
					  NULL} },
	{ "astronomy",		NC_("Category of Science", "Astronomy"),
					{ "Science::Astronomy",
					  NULL} },
	{ "chemistry",		NC_("Category of Science", "Chemistry"),
					{ "Science::Chemistry",
					  NULL} },
	{ "math",		NC_("Category of Science", "Math"),
					{ "Science::Math",
					  "Science::Physics",
					  "Science::NumericalAnalysis",
					  NULL} },
	{ "robotics",		NC_("Category of Science", "Robotics"),
					{ "Science::Robotics",
					  NULL} },
	{ NULL }
};

/* Communication */
static const AsCategoryMap map_communication[] = {
	{ "featured",		NC_("Category of Communication", "Featured"),
					{ "Network::Featured",
					  NULL} },
	{ "chat",		NC_("Category of Communication", "Chat"),
					{ "Network::Chat",
					  "Network::IRCClient",
					  "Network::Telephony",
					  "Network::VideoConference",
					  "Network::Email",
					  NULL} },
	{ "news",		NC_("Category of Communication", "News"),
					{ "Network::Feed",
					  "Network::News",
					  NULL} },
	{ "web-browsers",	NC_("Category of Communication", "Web Browsers"),
					{ "Network::WebBrowser",
					  NULL} },
	{ NULL }
};

/* Utility */
static const AsCategoryMap map_utilities[] = {
	{ "featured",		NC_("Category of Utility", "Featured"),
					{ "Utility::Featured",
					  NULL} },
	{ "text-editors",	NC_("Category of Utility", "Text Editors"),
					{ "Utility::TextEditor",
					  NULL} },
	{ "terminal-emulators",	NC_("Category of Utility", "Terminal Emulators"),
					{ "System::TerminalEmulator",
					  NULL} },
	{ "filesystem",		NC_("Category of Utility", "File System"),
					{ "System::Filesystem",
					  NULL} },
	{ "monitor",		NC_("Category of Utility", "System Monitoring"),
					{ "System::Monitor",
					  NULL} },
	{ "security",		NC_("Category of Utility", "Security"),
					{ "System::Security",
					  NULL} },
	{ NULL }
};

/* main categories */
static const AsCategoryData msdata[] = {
	/* TRANSLATORS: this is the menu spec main category for Audio & Video */
	{ "audio-video",	map_audiovideo,		N_("Audio & Video"),
				"applications-multimedia" },
	/* TRANSLATORS: this is the menu spec main category for Development */
	{ "developer-tools",	map_developertools,	N_("Developer Tools"),
				"applications-development" },
	/* TRANSLATORS: this is the menu spec main category for Education */
	{ "education",		map_education,		N_("Education"),
				"applications-education" },
	/* TRANSLATORS: this is the menu spec main category for Game */
	{ "games",		map_games,		N_("Games"),
				"applications-games" },
	/* TRANSLATORS: this is the menu spec main category for Graphics */
	{ "graphics",		map_graphics,		N_("Graphics & Photography"),
				"applications-graphics" },
	/* TRANSLATORS: this is the menu spec main category for Office */
	{ "office",		map_office,		N_("Office"),
				"applications-office" },
	/* TRANSLATORS: this is the main category for Add-ons */
	{ "addons",		map_addons,		N_("Add-ons"),
				"applications-other" },
	/* TRANSLATORS: this is the menu spec main category for Science */
	{ "science",		map_science,		N_("Science"),
				"applications-science" },
	/* TRANSLATORS: this is the menu spec main category for Communication */
	{ "communication",	map_communication,	N_("Communication & News"),
				"applications-internet" },
	/* TRANSLATORS: this is the menu spec main category for Utilities */
	{ "utilities",		map_utilities,		N_("Utilities"),
				"applications-utilities" },
	{ NULL }
};

typedef struct
{
	gchar *id;
	gchar *name;
	gchar *summary;
	gchar *icon;
	GPtrArray *children;
	GPtrArray *desktop_groups;

	GPtrArray *components;
} AsCategoryPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsCategory, as_category, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_category_get_instance_private (o))

enum  {
	AS_CATEGORY_DUMMY,
	AS_CATEGORY_ID,
	AS_CATEGORY_NAME,
	AS_CATEGORY_SUMMARY,
	AS_CATEGORY_ICON,
	AS_CATEGORY_CHILDREN
};

/**
 * as_category_init:
 **/
static void
as_category_init (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	priv->children = g_ptr_array_new_with_free_func (g_object_unref);
	priv->desktop_groups = g_ptr_array_new_with_free_func (g_free);
	priv->components = g_ptr_array_new_with_free_func (g_object_unref);
}

/**
 * as_category_finalize:
 */
static void
as_category_finalize (GObject *object)
{
	AsCategory *category = AS_CATEGORY (object);
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	g_free (priv->id);
	g_free (priv->name);
	g_free (priv->summary);
	g_free (priv->icon);
	g_ptr_array_unref (priv->children);
	g_ptr_array_unref (priv->desktop_groups);
	g_ptr_array_unref (priv->components);

	G_OBJECT_CLASS (as_category_parent_class)->finalize (object);
}

/**
 * as_category_get_id:
 * @category: An instance of #AsCategory.
 *
 * Get the ID of this category.
 */
const gchar*
as_category_get_id (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->id;
}

/**
 * as_category_set_id:
 * @category: An instance of #AsCategory.
 *
 * Set the ID of this category.
 */
void
as_category_set_id (AsCategory *category, const gchar *id)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	g_free (priv->id);
	priv->id = g_strdup (id);
	g_object_notify (G_OBJECT (category), "id");
}

/**
 * as_category_get_name:
 * @category: An instance of #AsCategory.
 *
 * Get the name of this category.
 */
const gchar*
as_category_get_name (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->name;
}

/**
 * as_category_set_name:
 * @category: An instance of #AsCategory.
 *
 * Set the name of this category.
 */
void
as_category_set_name (AsCategory *category, const gchar *value)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	g_free (priv->name);
	priv->name = g_strdup (value);
	g_object_notify (G_OBJECT (category), "name");
}

/**
 * as_category_get_children:
 * @category: An instance of #AsCategory.
 *
 * Returns: (element-type AsCategory) (transfer none): A list of subcategories.
 */
GPtrArray*
as_category_get_children (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->children;
}

/**
 * as_category_add_child:
 * @category: An instance of #AsCategory.
 * @subcat: A subcategory to add.
 *
 * Add a subcategory to this category.
 */
void
as_category_add_child (AsCategory *category, AsCategory *subcat)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	g_ptr_array_add (priv->children, g_object_ref (subcat));
}

/**
 * as_category_remove_child:
 * @category: An instance of #AsCategory.
 * @subcat: A subcategory to remove.
 *
 * Drop a subcategory from this #AsCategory.
 */
void
as_category_remove_child (AsCategory *category, AsCategory *subcat)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	g_ptr_array_remove (priv->children, subcat);
}

/**
 * as_category_has_children:
 * @category: An instance of #AsCategory.
 *
 * Test for sub-categories.
 *
 * Returns: %TRUE if this category has any subcategory
 */
gboolean
as_category_has_children (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->children->len > 0;
}

/**
 * as_category_get_summary:
 * @category: An instance of #AsCategory.
 *
 * Get the summary (short description) of this category.
 */
const gchar*
as_category_get_summary (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->summary;
}

/**
 * as_category_set_summary:
 * @category: An instance of #AsCategory.
 * @value: A new short summary of this category.
 *
 * Get the summary (short description) of this category.
 */
void
as_category_set_summary (AsCategory *category, const gchar *value)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	g_free (priv->summary);
	priv->summary = g_strdup (value);
	g_object_notify (G_OBJECT (category), "summary");
}

/**
 * as_category_get_icon:
 * @category: An instance of #AsCategory.
 *
 * Get the stock icon name for this category.
 */
const gchar*
as_category_get_icon (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->icon;
}

/**
 * as_category_set_icon:
 * @category: An instance of #AsCategory.
 *
 * Set the stock icon name for this category.
 */
void
as_category_set_icon (AsCategory *category, const gchar *value)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);

	g_free (priv->icon);
	priv->icon = g_strdup (value);
	g_object_notify (G_OBJECT (category), "icon");
}

/**
 * as_category_get_desktop_groups:
 * @category: An instance of #AsCategory.
 *
 * Returns: (transfer none) (element-type utf8): A list of desktop-file categories.
 */
GPtrArray*
as_category_get_desktop_groups (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->desktop_groups;
}

/**
 * as_category_add_desktop_group:
 * @category: An instance of #AsCategory.
 * @group_name: A subcategory to add.
 *
 * Add a desktop-file category to this #AsCategory.
 */
void
as_category_add_desktop_group (AsCategory *category, const gchar *group_name)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	g_ptr_array_add (priv->desktop_groups,
			 g_strdup (group_name));
}

/**
 * as_category_get_components:
 * @category: An instance of #AsCategory.
 *
 * Get list of components which have been sorted into this category.
 *
 * Returns: (transfer none) (element-type AsComponent): List of #AsCategory
 */
GPtrArray*
as_category_get_components (AsCategory *category)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	return priv->components;
}

/**
 * as_category_add_component:
 * @category: An instance of #AsCategory.
 * @cpt: The #AsComponent to add.
 *
 * Add a component to this category.
 */
void
as_category_add_component (AsCategory *category, AsComponent *cpt)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	g_ptr_array_add (priv->components,
			 g_object_ref (cpt));
}

/**
 * as_category_has_component:
 * @category: An instance of #AsCategory.
 * @cpt: The #AsComponent to look for.
 *
 * Check if the exact #AsComponent @cpt is a member of this
 * category already.
 *
 * returns: %TRUE if the component is present.
 */
gboolean
as_category_has_component (AsCategory *category, AsComponent *cpt)
{
	AsCategoryPrivate *priv = GET_PRIVATE (category);
	guint i;

	for (i = 0; i < priv->components->len; i++) {
		AsComponent *ecpt = AS_COMPONENT (g_ptr_array_index (priv->components, i));
		if (ecpt == cpt)
			return TRUE;
	}

	return FALSE;
}

/**
 * as_category_get_property:
 */
static void
as_category_get_property (GObject *object, guint property_id, GValue *value, GParamSpec *pspec)
{
	AsCategory  *category;
	category = G_TYPE_CHECK_INSTANCE_CAST (object, AS_TYPE_CATEGORY, AsCategory);
	switch (property_id) {
		case AS_CATEGORY_ID:
			g_value_set_string (value, as_category_get_id (category));
			break;
		case AS_CATEGORY_NAME:
			g_value_set_string (value, as_category_get_name (category));
			break;
		case AS_CATEGORY_SUMMARY:
			g_value_set_string (value, as_category_get_summary (category));
			break;
		case AS_CATEGORY_ICON:
			g_value_set_string (value, as_category_get_icon (category));
			break;
		case AS_CATEGORY_CHILDREN:
			g_value_set_pointer (value, as_category_get_children (category));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
			break;
	}
}

/**
 * as_category_set_property:
 */
static void
as_category_set_property (GObject *object, guint property_id, const GValue *value, GParamSpec *pspec)
{
	AsCategory  *category;
	category = G_TYPE_CHECK_INSTANCE_CAST (object, AS_TYPE_CATEGORY, AsCategory);
	switch (property_id) {
		case AS_CATEGORY_ID:
			as_category_set_id (category, g_value_get_string (value));
			break;
		case AS_CATEGORY_NAME:
			as_category_set_name (category, g_value_get_string (value));
			break;
		case AS_CATEGORY_SUMMARY:
			as_category_set_summary (category, g_value_get_string (value));
			break;
		case AS_CATEGORY_ICON:
			as_category_set_icon (category, g_value_get_string (value));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
			break;
	}
}

/**
 * as_category_class_init:
 */
static void
as_category_class_init (AsCategoryClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->get_property = as_category_get_property;
	object_class->set_property = as_category_set_property;
	object_class->finalize = as_category_finalize;

	g_object_class_install_property (object_class,
					AS_CATEGORY_ID,
					g_param_spec_string ("id", "id", "id", NULL, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
	g_object_class_install_property (object_class,
					AS_CATEGORY_NAME,
					g_param_spec_string ("name", "name", "name", NULL, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
	g_object_class_install_property (object_class,
					AS_CATEGORY_SUMMARY,
					g_param_spec_string ("summary", "summary", "summary", NULL, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE));
	g_object_class_install_property (object_class,
					AS_CATEGORY_ICON,
					g_param_spec_string ("icon", "icon", "icon", NULL, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
	g_object_class_install_property (object_class,
					AS_CATEGORY_CHILDREN,
					g_param_spec_pointer ("children", "children", "children", G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE));
}

/**
 * as_category_new:
 *
 * Creates a new #AsCategory.
 *
 * Returns: (transfer full): a new #AsCategory
 **/
AsCategory*
as_category_new (void)
{
	AsCategory *category;
	category = g_object_new (AS_TYPE_CATEGORY, NULL);
	return AS_CATEGORY (category);
}

/**
 * as_get_default_categories:
 * @with_special: Include special categories (e.g. "addons", and "all"/"featured" in submenus)
 *
 * Get a list of the default Freedesktop and AppStream categories
 * that software components (especially GUI applications) can be sorted
 * into in software centers.
 *
 * Returns: (transfer container) (element-type AsCategory): a list of #AsCategory
 */
GPtrArray*
as_get_default_categories (gboolean with_special)
{
	guint i;
	gchar msgctxt[100];
	GPtrArray *main_cats;

	main_cats = g_ptr_array_new_with_free_func (g_object_unref);
	for (i = 0; msdata[i].id != NULL; i++) {
		guint j;
		AsCategory *category;
		GHashTableIter iter;
		gpointer key;
		g_autoptr(GHashTable) root_fdocats = NULL;

		if ((!with_special) && (g_strcmp0 (msdata[i].id, "addons") == 0))
			continue;

		category = as_category_new ();
		as_category_set_id (category, msdata[i].id);

		as_category_set_name (category, gettext (msdata[i].name));
		as_category_set_icon (category, msdata[i].icon);

		g_ptr_array_add (main_cats, category);
		g_snprintf (msgctxt, sizeof(msgctxt),
			    "Subcategory of %s", msdata[i].name);

		root_fdocats = g_hash_table_new_full (g_str_hash,
						      g_str_equal,
						      g_free,
						      NULL);

		/* add subcategories */
		for (j = 0; msdata[i].mapping[j].id != NULL; j++) {
			guint k;
			const AsCategoryMap *map = &msdata[i].mapping[j];
			g_autoptr(AsCategory) sub = NULL;

			if (!with_special) {
			    if (g_strcmp0 (msdata[i].id, "featured") == 0)
				continue;
			}

			sub = as_category_new ();
			as_category_set_id (sub, map->id);

			for (k = 0; map->fdo_cats[k] != NULL; k++) {
				g_auto(GStrv) split = g_strsplit (map->fdo_cats[k], "::", -1);
				as_category_add_desktop_group (sub, map->fdo_cats[k]);

				g_hash_table_add (root_fdocats, g_strdup (split[0]));
			}
			as_category_set_name (sub, g_dpgettext2 (GETTEXT_PACKAGE,
								 msgctxt,
								 map->name));
			as_category_add_child (category, sub);
		}

		/* ensure the root category has the right XDG group names set, which match the subcategories */
		g_hash_table_iter_init (&iter, root_fdocats);
		while (g_hash_table_iter_next (&iter, &key, NULL)) {
			const gchar *desktop_group = (const gchar*) key;
			as_category_add_desktop_group (category, desktop_group);
		}
	}

	return main_cats;
}
