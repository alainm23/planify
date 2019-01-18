/* -*- mode: c; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecontextengine.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Gustavo Giráldez <gustavo.giraldez@gmx.net>
 * Copyright (C) 2005, 2006 - Marco Barisione, Emanuele Aina
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecontextengine.h"
#include <string.h>
#include <glib.h>
#include "gtksourceview-i18n.h"
#include "gtksourceregion.h"
#include "gtksourcelanguage.h"
#include "gtksourcelanguage-private.h"
#include "gtksourcebuffer.h"
#include "gtksourceregex.h"
#include "gtksourcestyle.h"
#include "gtksourcestylescheme.h"
#include "gtksourceview-utils.h"

#undef ENABLE_DEBUG
#undef ENABLE_PROFILE
#undef ENABLE_CHECK_TREE

#ifdef ENABLE_DEBUG
#define DEBUG(x) (x)
#else
#define DEBUG(x)
#endif

#ifdef ENABLE_PROFILE
#define PROFILE(x) (x)
#else
#define PROFILE(x)
#endif

#if defined (ENABLE_DEBUG) || defined (ENABLE_PROFILE) || \
    defined (ENABLE_CHECK_TREE)
#define NEED_DEBUG_ID
#endif

/* Priority of one-time idle which is installed after buffer is modified. */
#define FIRST_UPDATE_PRIORITY		G_PRIORITY_HIGH_IDLE

/* Maximal amount of time (in milliseconds) allowed to spend in the first idle.
 * Should be small enough, since in worst case we block ui for this time after
 * each keypress.
 */
#define FIRST_UPDATE_TIME_SLICE		10

/* Priority of long running idle which is used to analyze whole buffer, if
 * the engine wasn't quick enough to analyze it in one shot.
 */
/* FIXME this priority is low, since we don't want to block other gui stuff.
 * But, e.g. if we have a big file, and scroll down, we do want the engine
 * to analyze quickly. Perhaps we want to reinstall first_update in case
 * of expose events or something.
 */
#define INCREMENTAL_UPDATE_PRIORITY	G_PRIORITY_LOW

/* Maximal amount of time (in milliseconds) allowed to spend in one cycle of
 * background idle.
 */
#define INCREMENTAL_UPDATE_TIME_SLICE	30

/* Maximal amount of time (in milliseconds) allowed to spend highlihting a
 * single line. If it is not enough, then highlighting is disabled.
 */
#define MAX_TIME_FOR_ONE_LINE		2000

#define GTK_SOURCE_CONTEXT_ENGINE_ERROR (gtk_source_context_engine_error_quark ())

#define HAS_OPTION(def,opt) (((def)->flags & GTK_SOURCE_CONTEXT_##opt) != 0)

/* Can the context be terminated by ancestor? */
/* Root context can't be terminated; its child may not be terminated by it;
 * grandchildren look at the flag.
 */
#define ANCESTOR_CAN_END_CONTEXT(ctx) \
	((ctx)->parent != NULL && (ctx)->parent->parent != NULL && \
		(!HAS_OPTION ((ctx)->definition, EXTEND_PARENT) || !(ctx)->all_ancestors_extend))

/* Root context and its children have this TRUE; grandchildren use the flag. */
#define CONTEXT_EXTENDS_PARENT(ctx) \
	((ctx)->parent == NULL || (ctx)->parent->parent == NULL || \
		HAS_OPTION ((ctx)->definition, EXTEND_PARENT))

/* Root and its children have this FALSE; grandchildren use the flag. */
#define CONTEXT_ENDS_PARENT(ctx) \
	((ctx)->parent != NULL && (ctx)->parent->parent != NULL && \
		HAS_OPTION ((ctx)->definition, END_PARENT))
#define SEGMENT_ENDS_PARENT(s) CONTEXT_ENDS_PARENT ((s)->context)

/* Does the segment terminate at line end? */
/* Root segment doesn't, children look at the flag. */
#define CONTEXT_END_AT_LINE_END(ctx) \
	((ctx)->parent != NULL && HAS_OPTION ((ctx)->definition, END_AT_LINE_END))
#define SEGMENT_END_AT_LINE_END(s) CONTEXT_END_AT_LINE_END((s)->context)

#define CONTEXT_IS_SIMPLE(c) ((c)->definition->type == CONTEXT_TYPE_SIMPLE)
#define CONTEXT_IS_CONTAINER(c) ((c)->definition->type == CONTEXT_TYPE_CONTAINER)
#define SEGMENT_IS_INVALID(s) ((s)->context == NULL)
#define SEGMENT_IS_SIMPLE(s) CONTEXT_IS_SIMPLE ((s)->context)
#define SEGMENT_IS_CONTAINER(s) CONTEXT_IS_CONTAINER ((s)->context)

typedef struct _SubPatternDefinition SubPatternDefinition;
typedef struct _SubPattern SubPattern;
typedef struct _Segment Segment;
typedef struct _Context Context;
typedef struct _ContextPtr ContextPtr;
typedef struct _ContextDefinition ContextDefinition;
typedef struct _DefinitionChild DefinitionChild;
typedef struct _DefinitionsIter DefinitionsIter;
typedef struct _LineInfo LineInfo;
typedef struct _InvalidRegion InvalidRegion;
typedef struct _ContextClassTag ContextClassTag;

typedef enum _GtkSourceContextEngineError {
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_DUPLICATED_ID = 0,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_ARGS,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_PARENT,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_REF,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_WHERE,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_START_REF,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_STYLE,
	GTK_SOURCE_CONTEXT_ENGINE_ERROR_BAD_FILE
} GtkSourceContextEngineError;

typedef enum _ContextType {
	CONTEXT_TYPE_SIMPLE = 0,
	CONTEXT_TYPE_CONTAINER
} ContextType;

typedef enum _SubPatternWhere {
	SUB_PATTERN_WHERE_DEFAULT = 0,
	SUB_PATTERN_WHERE_START,
	SUB_PATTERN_WHERE_END
} SubPatternWhere;

struct _ContextDefinition
{
	gchar *id;

	ContextType type;
	union
	{
		GtkSourceRegex *match;
		struct {
			GtkSourceRegex *start;
			GtkSourceRegex *end;
		} start_end;
	} u;

	/* Name of the style used for contexts of this type. */
	gchar *default_style;

	/* List of DefinitionChild pointers. */
	GSList *children;

	/* Sub-patterns (list of SubPatternDefinition pointers). */
	GSList *sub_patterns;
	guint n_sub_patterns;

	/* List of class definitions. */
	GSList *context_classes;

	/* Union of every regular expression we can find from this context. */
	GtkSourceRegex *reg_all;

	guint flags : 8;
	guint ref_count : 24;
};

struct _SubPatternDefinition
{
#ifdef NEED_DEBUG_ID
	/* We need the id only for debugging. */
	gchar *id;
#endif
	gchar *style;
	SubPatternWhere where;

	/* List of class definitions */
	GSList *context_classes;

	/* index in the ContextDefinition's list */
	guint index;

	union
	{
		gint num;
		gchar *name;
	} u;
	guint is_named : 1;
};

struct _DefinitionChild
{
	union
	{
		/* Equal to definition->id, used when it's not resolved yet. */
		gchar *id;
		ContextDefinition *definition;
	} u;

	gchar *style;

	/* Whether this child is a reference to all child contexts of
	 * <definition>.
	 */
	guint is_ref_all : 1;

	/* Whether it is resolved, i.e. points to actual context definition. */
	guint resolved : 1;

	/* Whether style is overridden, i.e. use child->style instead of what
	 * definition says.
	 */
	guint override_style : 1;

	/* Whether style should be ignored for this and all child contexts. */
	guint override_style_deep : 1;
};

struct _DefinitionsIter
{
	GSList *children_stack;
};

struct _Context
{
	/* Definition for the context. */
	ContextDefinition *definition;

	Context *parent;
	ContextPtr *children;

	/* This is the regex returned by regex_resolve() called on
	 * definition->start_end.end.
	 */
	GtkSourceRegex *end;

	/* The regular expression containing every regular expression that could
	 * be matched in this context.
	 */
	GtkSourceRegex *reg_all;

	/* Either definition->default_style or child_def->style, not copied. */
	const gchar *style;
	GtkTextTag *tag;
	GtkTextTag **subpattern_tags;

	/* Cache for generated list of class tags */
	GSList *context_classes;

	/* Cache for generated list of subpattern class tags */
	GSList **subpattern_context_classes;

	guint ref_count;

	/* see context_freeze() */
	guint frozen : 1;

	/* Do all the ancestors extend their parent? */
	guint all_ancestors_extend : 1;

	/* Do not apply styles to children contexts */
	guint ignore_children_style : 1;
};

struct _ContextPtr
{
	ContextDefinition *definition;

	ContextPtr *next;

	union {
		Context *context;
		GHashTable *hash; /* char* -> Context* */
	} u;
	guint fixed : 1;
};

struct _GtkSourceContextReplace
{
	gchar *id;
	gchar *replace_with;
};

struct _Segment
{
	Segment *parent;
	Segment *next;
	Segment *prev;
	Segment *children;
	Segment *last_child;

	/* This is NULL if and only if it's a dummy segment which denotes
	 * inserted or deleted text.
	 */
	Context *context;

	/* Subpatterns found in this segment. */
	SubPattern *sub_patterns;

	/* The context is used in the interval [start_at; end_at). */
	gint start_at;
	gint end_at;

	/* In case of container contexts, start_len/end_len is length in chars
	 * of start/end match.
	 */
	gint start_len;
	gint end_len;

	/* Whether this segment is a whole good segment, or it's an end of
	 * a bigger one left after erase_segments() call.
	 */
	guint is_start : 1;
};

struct _SubPattern
{
	SubPatternDefinition *definition;
	gint start_at;
	gint end_at;
	SubPattern *next;
};

/* Line terminator characters (\n, \r, \r\n, or unicode paragraph separator)
 * are removed from the line text. The problem is that pcre does not understand
 * arbitrary line terminators, so $ in pcre means (?=\n) (not quite, it's also
 * end of matched string), while we really need "((?=\r\n)|(?=[\r\n])|(?=\xE2\x80\xA9)|$)".
 * It could be worked around by replacing line terminator in matched text with
 * \n, but it's a good source of errors, since offsets (not all, unfortunately) returned
 * from pcre need to be compared to line length, and adjusted when necessary.
 * Not using line terminator only means that \n can't be in patterns, it's not a
 * big deal: line end can't be highlighted anyway; if a rule needs to match it, it can
 * can use "$" as start and "^" as end (not in a single pattern of course, "$^" will
 * never match).
 *
 * UPDATE: the above isn't true anymore, pcre can do arbitrary line terminators.
 * BUT: how do we know whether we should get one/two/N lines to match? Single-line
 * case to highlight end of line is covered by above ($). I do not feel brave enough
 * to modify this now for no real benefit. (muntyan)
 */
#define NEXT_LINE_OFFSET(l_) ((l_)->start_at + (l_)->char_length + (l_)->eol_length)
struct _LineInfo
{
	/* Line text. */
	gchar *text;

	/* Character offset of the line in text buffer. */
	gint start_at;

	/* Character length of line terminator, or 0 if it's the last line in
	 * buffer.
	 */
	gint eol_length;

	/* Length of the line text not including line terminator. */
	gint char_length;
	gint byte_length;
};

struct _InvalidRegion
{
	gboolean empty;
	GtkTextMark *start;
	GtkTextMark *end;

	/* offset_at(end) - delta == original offset, i.e. offset in the tree. */
	gint delta;
};

struct _GtkSourceContextClass
{
	gchar *name;
	gboolean enabled;
};

struct _ContextClassTag
{
	GtkTextTag *tag;
	gboolean enabled;
};

struct _GtkSourceContextData
{
	guint ref_count;

	GtkSourceLanguage *lang;

	/* Contains every ContextDefinition indexed by its id. */
	GHashTable *definitions;
};

struct _GtkSourceContextEnginePrivate
{
	GtkSourceContextData *ctx_data;

	GtkTextBuffer *buffer;
	GtkSourceStyleScheme *style_scheme;

	/* All tags indexed by style name: values are GSList's of tags, ref()'ed. */
	GHashTable *tags;

	/* Number of all syntax tags created by the engine, needed to set
	 * correct tag priorities.
	 */
	guint n_tags;

	/* List of GtkTextTag* for context classes. */
	GSList *context_classes;

	/* Whether or not to actually highlight the buffer. */
	gboolean highlight;

	/* Whether syntax analysis was disabled because of errors. */
	gboolean disabled;

	/* Region covering the unhighlighted text. */
	GtkSourceRegion *refresh_region;

	/* Tree of contexts. */
	Context *root_context;
	Segment *root_segment;
	Segment *hint;
	Segment *hint2;

	/* list of Segment* */
	GSList *invalid;
	InvalidRegion invalid_region;

	guint first_update;
	guint incremental_update;
};

#ifdef ENABLE_CHECK_TREE
static void check_tree (GtkSourceContextEngine *ce);
static void check_segment_list (Segment *segment);
static void check_segment_children (Segment *segment);
#define CHECK_TREE check_tree
#define CHECK_SEGMENT_LIST check_segment_list
#define CHECK_SEGMENT_CHILDREN check_segment_children
#else
#define CHECK_TREE(ce)
#define CHECK_SEGMENT_LIST(s)
#define CHECK_SEGMENT_CHILDREN(s)
#endif

static GQuark		gtk_source_context_engine_error_quark (void) G_GNUC_CONST;

static Segment	       *create_segment		(GtkSourceContextEngine *ce,
						 Segment		*parent,
						 Context		*context,
						 gint			 start_at,
						 gint			 end_at,
						 gboolean		 is_start,
						 Segment		*hint);
static Segment	       *segment_new		(GtkSourceContextEngine *ce,
						 Segment		*parent,
						 Context		*context,
						 gint			 start_at,
						 gint			 end_at,
						 gboolean		 is_start);
static Context	       *context_new		(Context		*parent,
						 ContextDefinition	*definition,
						 const gchar		*line_text,
						 const gchar		*style,
						 gboolean                ignore_children_style);
static void		context_unref		(Context		*context);
static void		context_freeze		(Context		*context);
static void		context_thaw		(Context		*context);
static void		erase_segments		(GtkSourceContextEngine *ce,
						 gint                    start,
						 gint                    end,
						 Segment                *hint);
static void		segment_remove		(GtkSourceContextEngine *ce,
						 Segment                *segment);

static void		find_insertion_place	(Segment		*segment,
						 gint			 offset,
						 Segment	       **parent,
						 Segment	       **prev,
						 Segment	       **next,
						 Segment		*hint);
static void		segment_destroy		(GtkSourceContextEngine	*ce,
						 Segment		*segment);
static ContextDefinition *context_definition_ref(ContextDefinition	*definition);
static void		context_definition_unref(ContextDefinition	*definition);

static void		segment_extend		(Segment		*state,
						 gint			 end_at);
static Context	       *ancestor_context_ends_here (Context		*state,
						 LineInfo		*line,
						 gint			 pos);
static void		definition_iter_init	(DefinitionsIter	*iter,
						 ContextDefinition	*definition);
static DefinitionChild *definition_iter_next	(DefinitionsIter	*iter);
static void		definition_iter_destroy	(DefinitionsIter	*iter);

static void		update_syntax		(GtkSourceContextEngine	*ce,
						 const GtkTextIter	*end,
						 gint			 time);
static void		install_idle_worker	(GtkSourceContextEngine	*ce);
static void		install_first_update	(GtkSourceContextEngine	*ce);

static ContextDefinition *
gtk_source_context_data_lookup (GtkSourceContextData *ctx_data,
				const gchar          *id)
{
	return g_hash_table_lookup (ctx_data->definitions, id);
}

static ContextDefinition *
gtk_source_context_data_lookup_root (GtkSourceContextData *ctx_data)
{
	const gchar *lang_id;
	gchar *root_id;
	ContextDefinition *root_definition;

	lang_id = gtk_source_language_get_id (ctx_data->lang);
	root_id = g_strdup_printf ("%s:%s", lang_id, lang_id);
	root_definition = gtk_source_context_data_lookup (ctx_data, root_id);
	g_free (root_id);

	return root_definition;
}

/* TAGS AND STUFF -------------------------------------------------------------- */

GtkSourceContextClass *
gtk_source_context_class_new (gchar const *name,
                              gboolean     enabled)
{
	GtkSourceContextClass *def = g_slice_new (GtkSourceContextClass);

	def->name = g_strdup (name);
	def->enabled = enabled;

	return def;
}

static GtkSourceContextClass *
gtk_source_context_class_copy (GtkSourceContextClass *cclass)
{
	return gtk_source_context_class_new (cclass->name, cclass->enabled);
}

void
gtk_source_context_class_free (GtkSourceContextClass *cclass)
{
	g_free (cclass->name);
	g_slice_free (GtkSourceContextClass, cclass);
}

static ContextClassTag *
context_class_tag_new (GtkTextTag *tag,
		       gboolean    enabled)
{
	ContextClassTag *attrtag = g_slice_new (ContextClassTag);

	attrtag->tag = tag;
	attrtag->enabled = enabled;

	return attrtag;
}

static void
context_class_tag_free (ContextClassTag *attrtag)
{
	g_slice_free (ContextClassTag, attrtag);
}

struct BufAndIters {
	GtkTextBuffer *buffer;
	const GtkTextIter *start, *end;
};

static void
unhighlight_region_cb (G_GNUC_UNUSED gpointer  style,
		       GSList                 *tags,
		       gpointer                user_data)
{
	struct BufAndIters *data = user_data;

	while (tags != NULL)
	{
		gtk_text_buffer_remove_tag (data->buffer,
					    tags->data,
					    data->start,
					    data->end);
		tags = tags->next;
	}
}

static void
unhighlight_region (GtkSourceContextEngine *ce,
		    const GtkTextIter      *start,
		    const GtkTextIter      *end)
{
	struct BufAndIters data;

	data.buffer = ce->priv->buffer;
	data.start = start;
	data.end = end;

	if (gtk_text_iter_equal (start, end))
		return;

	g_hash_table_foreach (ce->priv->tags, (GHFunc) unhighlight_region_cb, &data);
}

#define MAX_STYLE_DEPENDENCY_DEPTH	50

static void
set_tag_style (GtkSourceContextEngine *ce,
	       GtkTextTag             *tag,
	       const gchar            *style_id)
{
	GtkSourceStyle *style;
	const char *map_to;
	int guard = 0;

	g_return_if_fail (GTK_IS_TEXT_TAG (tag));
	g_return_if_fail (style_id != NULL);

	gtk_source_style_apply (NULL, tag);

	if (ce->priv->style_scheme == NULL)
		return;

	map_to = style_id;
	style = gtk_source_style_scheme_get_style (ce->priv->style_scheme, style_id);

	while (style == NULL)
	{
		if (guard > MAX_STYLE_DEPENDENCY_DEPTH)
		{
			g_warning ("Potential circular dependency between styles detected for style '%s'", style_id);
			break;
		}

		++guard;

		/* FIXME Style references really must be fixed, both parser for
		 * sane use in lang files, and engine for safe use. */
		map_to = gtk_source_language_get_style_fallback (ce->priv->ctx_data->lang, map_to);
		if (map_to == NULL)
			break;

		style = gtk_source_style_scheme_get_style (ce->priv->style_scheme, map_to);
	}

	/* not having style is fine, since parser checks validity of every style reference,
	 * so we don't need to spit a warning here */
	if (style != NULL)
		gtk_source_style_apply (style, tag);
}

static GtkTextTag *
create_tag (GtkSourceContextEngine *ce,
	    const gchar            *style_id)
{
	GtkTextTag *new_tag;

	g_assert (style_id != NULL);

	new_tag = gtk_text_buffer_create_tag (ce->priv->buffer, NULL, NULL);
	/* It must have priority lower than user tags but still
	 * higher than highlighting tags created before */
	gtk_text_tag_set_priority (new_tag, ce->priv->n_tags);
	set_tag_style (ce, new_tag, style_id);
	ce->priv->n_tags += 1;

	return new_tag;
}

/* Find tag which has to be overridden. */
static GtkTextTag *
get_parent_tag (Context    *context,
		const char *style)
{
	while (context != NULL)
	{
		/* Lang files may repeat same style for nested contexts,
		 * ignore them. */
		if (context->style &&
		    strcmp (context->style, style) != 0)
		{
			g_assert (context->tag != NULL);
			return context->tag;
		}

		context = context->parent;
	}

	return NULL;
}

static GtkTextTag *
get_tag_for_parent (GtkSourceContextEngine *ce,
		    const char             *style,
		    Context                *parent)
{
	GSList *tags;
	GtkTextTag *parent_tag = NULL;
	GtkTextTag *tag;

	g_return_val_if_fail (style != NULL, NULL);

	parent_tag = get_parent_tag (parent, style);
	tags = g_hash_table_lookup (ce->priv->tags, style);

	if (tags && (!parent_tag ||
		gtk_text_tag_get_priority (tags->data) > gtk_text_tag_get_priority (parent_tag)))
	{
		GSList *link;

		tag = tags->data;

		/* Now get the tag with lowest priority, so that tag lists do not grow
		 * indefinitely. */
		for (link = tags->next; link != NULL; link = link->next)
		{
			if (parent_tag &&
			    gtk_text_tag_get_priority (link->data) < gtk_text_tag_get_priority (parent_tag))
				break;
			tag = link->data;
		}
	}
	else
	{
		tag = create_tag (ce, style);

		tags = g_slist_prepend (tags, g_object_ref (tag));
		g_hash_table_insert (ce->priv->tags, g_strdup (style), tags);

#ifdef ENABLE_DEBUG
		{
			GString *style_path = g_string_new (style);
			gint n;

			while (parent != NULL)
			{
				if (parent->style != NULL)
				{
					g_string_prepend (style_path, "/");
					g_string_prepend (style_path,
							  parent->style);
				}

				parent = parent->parent;
			}

			tags = g_hash_table_lookup (ce->priv->tags, style);
			n = g_slist_length (tags);
			g_print ("created %d tag for style %s: %s\n", n, style, style_path->str);
			g_string_free (style_path, TRUE);
		}
#endif
	}

	return tag;
}

static GtkTextTag *
get_subpattern_tag (GtkSourceContextEngine *ce,
		    Context                *context,
		    SubPatternDefinition   *sp_def)
{
	if (sp_def->style == NULL)
		return NULL;

	g_assert (sp_def->index < context->definition->n_sub_patterns);

	if (context->subpattern_tags == NULL)
		context->subpattern_tags = g_new0 (GtkTextTag*, context->definition->n_sub_patterns);

	if (context->subpattern_tags[sp_def->index] == NULL)
		context->subpattern_tags[sp_def->index] = get_tag_for_parent (ce, sp_def->style, context);

	g_return_val_if_fail (context->subpattern_tags[sp_def->index] != NULL, NULL);
	return context->subpattern_tags[sp_def->index];
}

static GtkTextTag *
get_context_tag (GtkSourceContextEngine *ce,
		 Context                *context)
{
	if (context->style != NULL && context->tag == NULL)
		context->tag = get_tag_for_parent (ce,
						   context->style,
						   context->parent);
	return context->tag;
}

static void
apply_tags (GtkSourceContextEngine *ce,
	    Segment                *segment,
	    gint                    start_offset,
	    gint                    end_offset)
{
	GtkTextTag *tag;
	GtkTextIter start_iter, end_iter;
	GtkTextBuffer *buffer = ce->priv->buffer;
	SubPattern *sp;
	Segment *child;

	g_assert (segment != NULL);

	if (SEGMENT_IS_INVALID (segment))
		return;

	if (segment->start_at >= end_offset || segment->end_at <= start_offset)
		return;

	start_offset = MAX (start_offset, segment->start_at);
	end_offset = MIN (end_offset, segment->end_at);

	tag = get_context_tag (ce, segment->context);

	if (tag != NULL)
	{
		gint style_start_at, style_end_at;

		style_start_at = start_offset;
		style_end_at = end_offset;

		if (HAS_OPTION (segment->context->definition, STYLE_INSIDE))
		{
			style_start_at = MAX (segment->start_at + segment->start_len, start_offset);
			style_end_at = MIN (segment->end_at - segment->end_len, end_offset);
		}

		if (style_start_at > style_end_at)
		{
			g_critical ("%s: oops", G_STRLOC);
		}
		else
		{
			gtk_text_buffer_get_iter_at_offset (buffer, &start_iter, style_start_at);
			end_iter = start_iter;
			gtk_text_iter_forward_chars (&end_iter, style_end_at - style_start_at);
			gtk_text_buffer_apply_tag (ce->priv->buffer, tag, &start_iter, &end_iter);
		}
	}

	for (sp = segment->sub_patterns; sp != NULL; sp = sp->next)
	{
		if (sp->start_at >= start_offset && sp->end_at <= end_offset)
		{
			gint start = MAX (start_offset, sp->start_at);
			gint end = MIN (end_offset, sp->end_at);

			tag = get_subpattern_tag (ce, segment->context, sp->definition);

			if (tag != NULL)
			{
				gtk_text_buffer_get_iter_at_offset (buffer, &start_iter, start);
				end_iter = start_iter;
				gtk_text_iter_forward_chars (&end_iter, end - start);
				gtk_text_buffer_apply_tag (ce->priv->buffer, tag, &start_iter, &end_iter);
			}
		}
	}

	for (child = segment->children;
	     child != NULL && child->start_at < end_offset;
	     child = child->next)
	{
		if (child->end_at > start_offset)
			apply_tags (ce, child, start_offset, end_offset);
	}
}

static void
highlight_region (GtkSourceContextEngine *ce,
		  GtkTextIter            *start,
		  GtkTextIter            *end)
{
#ifdef ENABLE_PROFILE
	GTimer *timer;
#endif

	if (gtk_text_iter_starts_line (end))
		gtk_text_iter_backward_char (end);
	if (gtk_text_iter_compare (start, end) >= 0)
		return;

#ifdef ENABLE_PROFILE
	timer = g_timer_new ();
#endif

	/* First we need to delete tags in the regions. */
	unhighlight_region (ce, start, end);

	apply_tags (ce, ce->priv->root_segment,
		    gtk_text_iter_get_offset (start),
		    gtk_text_iter_get_offset (end));

#ifdef ENABLE_PROFILE
	g_print ("highlight (from %d to %d), %g ms elapsed\n",
		 gtk_text_iter_get_offset (start),
		 gtk_text_iter_get_offset (end),
		 g_timer_elapsed (timer, NULL) * 1000);
	g_timer_destroy (timer);
#endif
}

/**
 * ensure_highlighted:
 * @ce: a #GtkSourceContextEngine.
 * @start: the beginning of the region to highlight.
 * @end: the end of the region to highlight.
 *
 * Updates text tags in reanalyzed parts of given area.
 * It applies tags according to whatever is in the syntax
 * tree currently, so highlighting may not be correct
 * (gtk_source_context_engine_update_highlight is the method
 * that actually ensures correct highlighting).
 */
static void
ensure_highlighted (GtkSourceContextEngine *ce,
		    const GtkTextIter      *start,
		    const GtkTextIter      *end)
{
	GtkSourceRegion *region;
	GtkSourceRegionIter reg_iter;

	/* Get the subregions not yet highlighted. */
	region = gtk_source_region_intersect_subregion (ce->priv->refresh_region, start, end);

	if (region == NULL)
		return;

	gtk_source_region_get_start_region_iter (region, &reg_iter);

	/* Highlight all subregions from the intersection.
	 * hopefully this will only be one subregion. */
	while (!gtk_source_region_iter_is_end (&reg_iter))
	{
		GtkTextIter s, e;
		gtk_source_region_iter_get_subregion (&reg_iter, &s, &e);
		highlight_region (ce, &s, &e);
		gtk_source_region_iter_next (&reg_iter);
	}

	g_clear_object (&region);

	/* Remove the just highlighted region. */
	gtk_source_region_subtract_subregion (ce->priv->refresh_region, start, end);
}

static GtkTextTag *
get_context_class_tag (GtkSourceContextEngine *ce,
		       gchar const            *name)
{
	gchar *tag_name;
	GtkTextTagTable *tag_table;
	GtkTextTag *tag;

	tag_name = g_strdup_printf ("gtksourceview:context-classes:%s", name);

	tag_table = gtk_text_buffer_get_tag_table (ce->priv->buffer);
	tag = gtk_text_tag_table_lookup (tag_table, tag_name);

	if (tag == NULL)
	{
		tag = gtk_text_buffer_create_tag (ce->priv->buffer, tag_name, NULL);
		g_return_val_if_fail (tag != NULL, NULL);

		ce->priv->context_classes = g_slist_prepend (ce->priv->context_classes,
							     g_object_ref (tag));
	}

	g_free (tag_name);
	return tag;
}

static GSList *
extend_context_classes (GtkSourceContextEngine *ce,
			GSList                 *definitions)
{
	GSList *item;
	GSList *ret = NULL;

	for (item = definitions; item != NULL; item = g_slist_next (item))
	{
		GtkSourceContextClass *cclass = item->data;
		ContextClassTag *attrtag = context_class_tag_new (get_context_class_tag (ce, cclass->name),
		                                                  cclass->enabled);

		ret = g_slist_prepend (ret, attrtag);
	}

	return g_slist_reverse (ret);
}

static GSList *
get_subpattern_context_classes (GtkSourceContextEngine *ce,
				Context                *context,
				SubPatternDefinition   *sp_def)
{
	g_assert (sp_def->index < context->definition->n_sub_patterns);

	if (context->subpattern_context_classes == NULL)
		context->subpattern_context_classes = g_new0 (GSList *, context->definition->n_sub_patterns);

	if (context->subpattern_context_classes[sp_def->index] == NULL)
	{
		context->subpattern_context_classes[sp_def->index] =
				extend_context_classes (ce,
		                                        sp_def->context_classes);
	}

	return context->subpattern_context_classes[sp_def->index];
}

static GSList *
get_context_classes (GtkSourceContextEngine *ce,
		     Context                *context)
{
	if (context->context_classes == NULL)
	{
		context->context_classes =
				extend_context_classes (ce,
		                                        context->definition->context_classes);
	}

	return context->context_classes;
}

static void
apply_context_classes (GtkSourceContextEngine *ce,
		       GSList                 *context_classes,
		       gint                    start,
		       gint                    end)
{
	GtkTextIter start_iter;
	GtkTextIter end_iter;
	GSList *item;

	gtk_text_buffer_get_iter_at_offset (ce->priv->buffer, &start_iter, start);
	end_iter = start_iter;
	gtk_text_iter_forward_chars (&end_iter, end - start);

	for (item = context_classes; item != NULL; item = g_slist_next (item))
	{
		ContextClassTag *attrtag = item->data;

		if (attrtag->enabled)
		{
			gtk_text_buffer_apply_tag (ce->priv->buffer,
			                           attrtag->tag,
			                           &start_iter,
			                           &end_iter);
		}
		else
		{
			gtk_text_buffer_remove_tag (ce->priv->buffer,
			                            attrtag->tag,
			                            &start_iter,
			                            &end_iter);
		}
	}
}

static void
add_region_context_classes (GtkSourceContextEngine *ce,
			    Segment                *segment,
			    gint                    start_offset,
			    gint                    end_offset)
{
	SubPattern *sp;
	Segment *child;
	GSList *context_classes;

	g_assert (segment != NULL);

	if (SEGMENT_IS_INVALID (segment))
	{
		return;
	}

	if (segment->start_at >= end_offset || segment->end_at <= start_offset)
	{
		return;
	}

	start_offset = MAX (start_offset, segment->start_at);
	end_offset = MIN (end_offset, segment->end_at);

	context_classes = get_context_classes (ce, segment->context);

	if (context_classes != NULL)
	{
		apply_context_classes (ce,
		                       context_classes,
		                       start_offset,
		                       end_offset);
	}

	for (sp = segment->sub_patterns; sp != NULL; sp = sp->next)
	{
		if (sp->start_at >= start_offset && sp->end_at <= end_offset)
		{
			gint start = MAX (start_offset, sp->start_at);
			gint end = MIN (end_offset, sp->end_at);

			context_classes = get_subpattern_context_classes (ce,
			                                                  segment->context,
			                                                  sp->definition);

			if (context_classes != NULL)
			{
				apply_context_classes (ce,
				                       context_classes,
				                       start,
				                       end);
			}
		}
	}

	for (child = segment->children;
	     child != NULL && child->start_at < end_offset;
	     child = child->next)
	{
		if (child->end_at > start_offset)
		{
			add_region_context_classes (ce, child, start_offset, end_offset);
		}
	}
}

static void
remove_region_context_classes (GtkSourceContextEngine *ce,
			       const GtkTextIter      *start,
			       const GtkTextIter      *end)
{
	GSList *l;

	if (gtk_text_iter_equal (start, end))
	{
		return;
	}

	for (l = ce->priv->context_classes; l != NULL; l = l->next)
	{
		GtkTextTag *tag = l->data;

		gtk_text_buffer_remove_tag (ce->priv->buffer, tag, start, end);
	}
}

static void
refresh_context_classes (GtkSourceContextEngine *ce,
			 const GtkTextIter      *start,
			 const GtkTextIter      *end)
{
#ifdef ENABLE_PROFILE
	GTimer *timer;
#endif
	GtkTextIter realend = *end;

	if (gtk_text_iter_starts_line (&realend))
	{
		gtk_text_iter_backward_char (&realend);
	}

	if (gtk_text_iter_compare (start, &realend) >= 0)
	{
		return;
	}

#ifdef ENABLE_PROFILE
	timer = g_timer_new ();
#endif

	/* First we need to delete tags in the regions. */
	remove_region_context_classes (ce, start, &realend);

	add_region_context_classes (ce,
	                            ce->priv->root_segment,
	                            gtk_text_iter_get_offset (start),
	                            gtk_text_iter_get_offset (&realend));

#ifdef ENABLE_PROFILE
	g_print ("applied context classes (from %d to %d), %g ms elapsed\n",
		 gtk_text_iter_get_offset (start),
		 gtk_text_iter_get_offset (&realend),
		 g_timer_elapsed (timer, NULL) * 1000);
	g_timer_destroy (timer);
#endif
}

/*
 * refresh_range:
 * @ce: a #GtkSourceContextEngine.
 * @start: the beginning of updated area.
 * @end: the end of updated area.
 * @modify_refresh_region: whether updated area should be added to
 * refresh_region.
 *
 * Marks the area as updated and notifies view about it.
 */
static void
refresh_range (GtkSourceContextEngine *ce,
	       const GtkTextIter      *start,
	       const GtkTextIter      *end)
{
	GtkTextIter real_end;

	if (gtk_text_iter_equal (start, end))
		return;

	/* Refresh the contex classes here */
	refresh_context_classes (ce, start, end);

	/* Here we need to make sure we do not make it redraw next line */
	real_end = *end;
	if (gtk_text_iter_starts_line (&real_end))
	{
		/* I don't quite like this here, but at least it won't jump into
		 * the middle of \r\n  */
		gtk_text_iter_backward_cursor_position (&real_end);
	}

	g_signal_emit_by_name (ce->priv->buffer,
			       "highlight-updated",
			       start,
			       &real_end);
}


/* SEGMENT TREE ----------------------------------------------------------- */

/**
 * segment_cmp:
 * @s1: first segment.
 * @s2: second segment.
 *
 * Compares segments by their offset, used to sort list of invalid segments.
 *
 * Returns: an integer like strcmp() does.
 */
static gint
segment_cmp (Segment *s1,
	     Segment *s2)
{
	if (s1->start_at < s2->start_at)
		return -1;
	else if (s1->start_at > s2->start_at)
		return 1;
	/* one of them must be zero-length */
	g_assert (s1->start_at == s1->end_at || s2->start_at == s2->end_at);
#ifdef ENABLE_DEBUG
	/* A new zero-length segment should never be created if there is
	 * already an invalid segment. */
	g_assert_not_reached ();
#endif
	g_return_val_if_reached (s1->end_at < s2->end_at ? -1 :
                                 (s1->end_at > s2->end_at ? 1 : 0));
}

/**
 * add_invalid:
 * @ce: the engine.
 * @segment: segment.
 *
 * Inserts segment into the list of invalid segments.
 * Called whenever new invalid segment is created or when
 * a segment is marked invalid.
 */
static void
add_invalid (GtkSourceContextEngine *ce,
	     Segment                *segment)
{
#ifdef ENABLE_CHECK_TREE
	g_assert (!g_slist_find (ce->priv->invalid, segment));
#endif
	g_return_if_fail (SEGMENT_IS_INVALID (segment));

	ce->priv->invalid = g_slist_insert_sorted (ce->priv->invalid,
						   segment,
						   (GCompareFunc) segment_cmp);

	DEBUG (g_print ("%d invalid\n", g_slist_length (ce->priv->invalid)));
}

/**
 * remove_invalid:
 * @ce: the engine.
 * @segment: segment.
 *
 * Removes segment from the list of invalid segments;
 * Called when an invalid segment is destroyed (invalid
 * segments never become valid).
 */
static void
remove_invalid (GtkSourceContextEngine *ce,
		Segment                *segment)
{
#ifdef ENABLE_CHECK_TREE
	g_assert (g_slist_find (ce->priv->invalid, segment) != NULL);
#endif
	ce->priv->invalid = g_slist_remove (ce->priv->invalid, segment);
}

/**
 * fix_offsets_insert_:
 * @segment: segment.
 * @start: start offset.
 * @delta: length of inserted text.
 *
 * Recursively updates offsets after inserting text. To be called
 * only from insert_range().
 */
static void
fix_offsets_insert_ (Segment *segment,
		     gint     start,
		     gint     delta)
{
	Segment *child;
	SubPattern *sp;

	g_assert (segment->start_at >= start);

	if (delta == 0)
		return;

	segment->start_at += delta;
	segment->end_at += delta;

	for (child = segment->children; child != NULL; child = child->next)
		fix_offsets_insert_ (child, start, delta);

	for (sp = segment->sub_patterns; sp != NULL; sp = sp->next)
	{
		sp->start_at += delta;
		sp->end_at += delta;
	}
}

/**
 * find_insertion_place_forward_:
 * @segment: the (grand)parent segment the new one should be inserted into.
 * @offset: offset at which text is inserted.
 * @start: segment from which to start search (to avoid
 * walking whole tree).
 * @parent: initialized with the parent of new segment.
 * @prev: initialized with the previous sibling of new segment.
 * @next: initialized with the next sibling of new segment.
 *
 * Auxiliary function used in find_insertion_place().
 */
static void
find_insertion_place_forward_ (Segment  *segment,
			       gint      offset,
			       Segment  *start,
			       Segment **parent,
			       Segment **prev,
			       Segment **next)
{
	Segment *child;

	g_assert (start->end_at < offset);

	for (child = start; child != NULL; child = child->next)
	{
		if (child->start_at <= offset && child->end_at >= offset)
		{
			find_insertion_place (child, offset, parent, prev, next, NULL);
			return;
		}

		if (child->end_at == offset)
		{
			if (SEGMENT_IS_INVALID (child))
			{
				*parent = child;
				*prev = NULL;
				*next = NULL;
			}
			else
			{
				*prev = child;
				*next = child->next;
				*parent = segment;
			}

			return;
		}

		if (child->end_at < offset)
		{
			*prev = child;
			continue;
		}

		if (child->start_at > offset)
		{
			*next = child;
			break;
		}

		g_assert_not_reached ();
	}

	*parent = segment;
}

/**
 * find_insertion_place_backward_:
 * @segment: the (grand)parent segment the new one should be inserted into.
 * @offset: offset at which text is inserted.
 * @start: segment from which to start search (to avoid
 * walking whole tree).
 * @parent: initialized with the parent of new segment.
 * @prev: initialized with the previous sibling of new segment.
 * @next: initialized with the next sibling of new segment.
 *
 * Auxiliary function used in find_insertion_place().
 */
static void
find_insertion_place_backward_ (Segment  *segment,
				gint      offset,
				Segment  *start,
				Segment **parent,
				Segment **prev,
				Segment **next)
{
	Segment *child;

	g_assert (start->end_at >= offset);

	for (child = start; child != NULL; child = child->prev)
	{
		if (child->start_at <= offset && child->end_at >= offset)
		{
			find_insertion_place (child, offset, parent, prev, next, NULL);
			return;
		}

		if (child->end_at == offset)
		{
			if (SEGMENT_IS_INVALID (child))
			{
				*parent = child;
				*prev = NULL;
				*next = NULL;
			}
			else
			{
				*prev = child;
				*next = child->next;
				*parent = segment;
			}

			return;
		}

		if (child->end_at < offset)
		{
			*prev = child;
			*next = child->next;
			break;
		}

		if (child->start_at > offset)
		{
			*next = child;
			continue;
		}

		g_assert_not_reached ();
	}

	*parent = segment;
}

/**
 * find_insertion_place:
 * @segment: the (grand)parent segment the new one should be inserted into.
 * @offset: offset at which text is inserted.
 * @start: segment from which to start search (to avoid
 * walking whole tree).
 * @parent: initialized with the parent of new segment.
 * @prev: initialized with the previous sibling of new segment.
 * @hint: a segment somewhere near insertion place to optimize search.
 *
 * After text is inserted, a new invalid segment is created and inserted
 * into the tree. This function finds an appropriate position for the new
 * segment. To make it faster, it uses hint and calls
 * find_insertion_place_forward_ or find_insertion_place_backward_ depending
 * on position of offset relative to hint.
 * There is no return value, it always succeeds (or crashes).
 */
static void
find_insertion_place (Segment  *segment,
		      gint      offset,
		      Segment **parent,
		      Segment **prev,
		      Segment **next,
		      Segment  *hint)
{
	g_assert (segment->start_at <= offset && segment->end_at >= offset);

	*prev = NULL;
	*next = NULL;

	if (SEGMENT_IS_INVALID (segment) || segment->children == NULL)
	{
		*parent = segment;
		return;
	}

	if (segment->start_at == offset)
	{
#ifdef ENABLE_CHECK_TREE
		g_assert (!segment->children ||
			  !SEGMENT_IS_INVALID (segment->children) ||
			  segment->children->start_at > offset);
#endif

		*parent = segment;
		*next = segment->children;

		return;
	}

	if (hint != NULL)
		while (hint != NULL && hint->parent != segment)
			hint = hint->parent;

	if (hint == NULL)
		hint = segment->children;

	if (hint->end_at < offset)
		find_insertion_place_forward_ (segment, offset, hint, parent, prev, next);
	else
		find_insertion_place_backward_ (segment, offset, hint, parent, prev, next);
}

/**
 * get_invalid_at:
 * @ce: the engine.
 * @offset: the offset.
 *
 * Finds invalid segment adjacent to offset (i.e. such that start <= offset <= end),
 * if any.
 *
 * Returns: invalid segment or %NULL.
 */
static Segment *
get_invalid_at (GtkSourceContextEngine *ce,
		gint                    offset)
{
	GSList *link = ce->priv->invalid;

	while (link != NULL)
	{
		Segment *segment = link->data;

		link = link->next;

		if (segment->start_at > offset)
			break;

		if (segment->end_at < offset)
			continue;

		return segment;
	}

	return NULL;
}

/**
 * segment_add_subpattern:
 * @state: the segment.
 * @sp: subpattern.
 *
 * Prepends subpattern to subpatterns list in the segment.
 */
static void
segment_add_subpattern (Segment    *state,
			SubPattern *sp)
{
	sp->next = state->sub_patterns;
	state->sub_patterns = sp;
}

/**
 * sub_pattern_new:
 * @segment: the segment.
 * @start_at: start offset of the subpattern.
 * @end_at: end offset of the subpattern.
 * @sp_def: the subppatern definition.
 *
 * Creates new subpattern and adds it to the segment's
 * subpatterns list.
 *
 * Returns: new subpattern.
 */
static SubPattern *
sub_pattern_new (Segment              *segment,
		 gint                  start_at,
		 gint                  end_at,
		 SubPatternDefinition *sp_def)
{
	SubPattern *sp;

	sp = g_slice_new (SubPattern);
	sp->start_at = start_at;
	sp->end_at = end_at;
	sp->definition = sp_def;

	segment_add_subpattern (segment, sp);

	return sp;
}

/**
 * sub_pattern_free:
 * @sp: subppatern.
 *
 * Calls g_free on subpattern, was useful for debugging.
 */
static inline void
sub_pattern_free (SubPattern *sp)
{
#ifdef ENABLE_DEBUG
	memset (sp, 1, sizeof (SubPattern));
#else
	g_slice_free (SubPattern, sp);
#endif
}

/**
 * segment_make_invalid_:
 * @ce: the engine.
 * @segment: segment to invalidate.
 *
 * Invalidates segment. Called only from insert_range().
 */
static void
segment_make_invalid_ (GtkSourceContextEngine *ce,
		       Segment                *segment)
{
	Context *ctx;
	SubPattern *sp;

	g_assert (!SEGMENT_IS_INVALID (segment));

	sp = segment->sub_patterns;
	segment->sub_patterns = NULL;

	while (sp != NULL)
	{
		SubPattern *next = sp->next;
		sub_pattern_free (sp);
		sp = next;
	}

	ctx = segment->context;
	segment->context = NULL;
	segment->is_start = FALSE;
	segment->start_len = 0;
	segment->end_len = 0;
	add_invalid (ce, segment);
	context_unref (ctx);
}

/**
 * simple_segment_split_:
 * @ce: the engine.
 * @segment: segment to split.
 * @offset: offset at which text insertion occurred.
 *
 * Creates a new invalid segment and inserts it in the middle
 * of the given one. Called from insert_range() to mark inserted
 * text.
 *
 * Returns: new invalid segment.
 */
static Segment *
simple_segment_split_ (GtkSourceContextEngine *ce,
		       Segment                *segment,
		       gint                    offset)
{
	SubPattern *sp;
	Segment *new_segment, *invalid;
	gint end_at = segment->end_at;

	g_assert (SEGMENT_IS_SIMPLE (segment));
	g_assert (segment->start_at < offset && offset < segment->end_at);

	sp = segment->sub_patterns;
	segment->sub_patterns = NULL;
	segment->end_at = offset;

	invalid = create_segment (ce, segment->parent, NULL, offset, offset, FALSE, segment);
	new_segment = create_segment (ce, segment->parent, segment->context, offset, end_at, FALSE, invalid);

	while (sp != NULL)
	{
		Segment *append_to = NULL;
		SubPattern *next = sp->next;

		if (sp->end_at <= offset)
		{
			append_to = segment;
		}
		else if (sp->start_at >= offset)
		{
			append_to = new_segment;
		}
		else
		{
			sub_pattern_new (new_segment,
					 offset,
					 sp->end_at,
					 sp->definition);
			sp->end_at = offset;
			append_to = segment;
		}

		segment_add_subpattern (append_to, sp);

		sp = next;
	}

	return invalid;
}

/**
 * invalidate_region:
 * @ce: a #GtkSourceContextEngine.
 * @offset: the start of invalidated area.
 * @length: the length of the area.
 *
 * Adds the area to the invalid region and queues highlighting.
 * @length may be negative which means deletion; positive
 * means insertion; 0 means "something happened here", it's
 * treated as zero-length insertion.
 */
static void
invalidate_region (GtkSourceContextEngine *ce,
		   gint                    offset,
		   gint                    length)
{
	InvalidRegion *region = &ce->priv->invalid_region;
	GtkTextBuffer *buffer = ce->priv->buffer;
	GtkTextIter iter;
	gint end_offset;

	end_offset = length >= 0 ? offset + length : offset;

	if (region->empty)
	{
		region->empty = FALSE;
		region->delta = length;

		gtk_text_buffer_get_iter_at_offset (buffer, &iter, offset);
		gtk_text_buffer_move_mark (buffer, region->start, &iter);

		gtk_text_iter_set_offset (&iter, end_offset);
		gtk_text_buffer_move_mark (buffer, region->end, &iter);
	}
	else
	{
		gtk_text_buffer_get_iter_at_mark (buffer, &iter, region->start);

		if (gtk_text_iter_get_offset (&iter) > offset)
		{
			gtk_text_iter_set_offset (&iter, offset);
			gtk_text_buffer_move_mark (buffer, region->start, &iter);
		}

		gtk_text_buffer_get_iter_at_mark (buffer, &iter, region->end);

		if (gtk_text_iter_get_offset (&iter) < end_offset)
		{
			gtk_text_iter_set_offset (&iter, end_offset);
			gtk_text_buffer_move_mark (buffer, region->end, &iter);
		}

		region->delta += length;
	}

	DEBUG (({
		gint start, end;
		gtk_text_buffer_get_iter_at_mark (buffer, &iter, region->start);
		start = gtk_text_iter_get_offset (&iter);
		gtk_text_buffer_get_iter_at_mark (buffer, &iter, region->end);
		end = gtk_text_iter_get_offset (&iter);
		g_assert (start <= end - region->delta);
	}));

	CHECK_TREE (ce);

	install_first_update (ce);
}

/**
 * insert_range:
 * @ce: a #GtkSourceContextEngine.
 * @offset: the start of new segment.
 * @length: the length of the segment.
 *
 * Updates segment tree after insertion: it updates tree
 * offsets as appropriate, and inserts a new invalid segment
 * or extends existing invalid segment as @offset, so
 * after the call segment [@offset, @offset + @length) is marked
 * invalid in the tree.
 * It may be safely called with length == 0 at any moment
 * to invalidate some offset (and it's used here and there).
 */
static void
insert_range (GtkSourceContextEngine *ce,
	      gint                    offset,
	      gint                    length)
{
	Segment *parent, *prev = NULL, *next = NULL, *new_segment;
	Segment *segment;

	/* If there is an invalid segment adjacent to offset, use it.
	 * Otherwise, find the deepest segment to split and insert
	 * dummy segment in there. */

	parent = get_invalid_at (ce, offset);

	if (parent == NULL)
		find_insertion_place (ce->priv->root_segment, offset,
				      &parent, &prev, &next,
				      ce->priv->hint);

	g_assert (parent->start_at <= offset);
	g_assert (parent->end_at >= offset);
	g_assert (!prev || prev->parent == parent);
	g_assert (!next || next->parent == parent);
	g_assert (!prev || prev->next == next);
	g_assert (!next || next->prev == prev);

	if (SEGMENT_IS_INVALID (parent))
	{
		/* If length is zero, and we already have an invalid segment there,
		 * do nothing. */
		if (length == 0)
			return;

		segment = parent;
	}
	else if (SEGMENT_IS_SIMPLE (parent))
	{
		/* If it's a simple context, then:
		 * if one of its ends is offset, then we just invalidate it;
		 * otherwise, we split it into two, and insert zero-lentgh
		 * invalid segment in the middle. */
		if (parent->start_at < offset && parent->end_at > offset)
		{
			segment = simple_segment_split_ (ce, parent, offset);
		}
		else
		{
			segment_make_invalid_ (ce, parent);
			segment = parent;
		}
	}
	else
	{
		/* Just insert new zero-length invalid segment. */

		new_segment = segment_new (ce, parent, NULL, offset, offset, FALSE);

		new_segment->next = next;
		new_segment->prev = prev;

		if (next != NULL)
			next->prev = new_segment;
		else
			parent->last_child = new_segment;

		if (prev != NULL)
			prev->next = new_segment;
		else
			parent->children = new_segment;

		segment = new_segment;
	}

	g_assert (!segment->children);

	if (length != 0)
	{
		/* now fix offsets in all the segments "to the right"
		 * of segment. */
		while (segment != NULL)
		{
			Segment *tmp;
			SubPattern *sp;

			for (tmp = segment->next; tmp != NULL; tmp = tmp->next)
				fix_offsets_insert_ (tmp, offset, length);

			segment->end_at += length;

			for (sp = segment->sub_patterns; sp != NULL; sp = sp->next)
			{
				if (sp->start_at > offset)
					sp->start_at += length;
				if (sp->end_at > offset)
					sp->end_at += length;
			}

			segment = segment->parent;
		}
	}

	CHECK_TREE (ce);
}

/**
 * gtk_source_context_engine_text_inserted:
 * @ce: a #GtkSourceContextEngine.
 * @start_offset: the start of inserted text.
 * @end_offset: the end of inserted text.
 *
 * Called from GtkTextBuffer::insert_text.
 */
static void
gtk_source_context_engine_text_inserted (GtkSourceEngine *engine,
					 gint             start_offset,
					 gint             end_offset)
{
	GtkTextIter iter;
	GtkSourceContextEngine *ce = GTK_SOURCE_CONTEXT_ENGINE (engine);

	if (!ce->priv->disabled)
	{
		g_return_if_fail (start_offset < end_offset);

		invalidate_region (ce, start_offset, end_offset - start_offset);

		/* If end_offset is at the start of a line (enter key pressed) then
		 * we need to invalidate the whole new line, otherwise it may not be
		 * highlighted because the engine analyzes the previous line, end
		 * context there is none, start context at this line is none too,
		 * and the engine stops. */
		gtk_text_buffer_get_iter_at_offset (ce->priv->buffer, &iter, end_offset);
		if (gtk_text_iter_starts_line (&iter) && !gtk_text_iter_ends_line (&iter))
		{
			gtk_text_iter_forward_to_line_end (&iter);
			invalidate_region (ce, gtk_text_iter_get_offset (&iter), 0);
		}
	}
}

/**
 * fix_offset_delete_one_:
 * @offset: segment.
 * @start: start of deleted text.
 * @length: length of deleted text.
 *
 * Returns: new offset depending on location of @offset
 * relative to deleted text.
 * Called only from fix_offsets_delete_().
 */
static inline gint
fix_offset_delete_one_ (gint offset,
			gint start,
			gint length)
{
	if (offset > start)
	{
		if (offset >= start + length)
			offset -= length;
		else
			offset = start;
	}

	return offset;
}

/**
 * fix_offsets_delete_:
 * @segment: segment.
 * @start: start offset.
 * @length: length of deleted text.
 * @hint: some segment somewhere near deleted text to optimize search.
 *
 * Recursively updates offsets after deleting text. To be called
 * only from delete_range_().
 */
static void
fix_offsets_delete_ (Segment *segment,
		     gint     offset,
		     gint     length,
		     Segment *hint)
{
	Segment *child;
	SubPattern *sp;

	g_return_if_fail (segment->end_at > offset);

	if (hint != NULL)
		while (hint != NULL && hint->parent != segment)
			hint = hint->parent;

	if (hint == NULL)
		hint = segment->children;

	for (child = hint; child != NULL; child = child->next)
	{
		if (child->end_at <= offset)
			continue;
		fix_offsets_delete_ (child, offset, length, NULL);
	}

	for (child = hint ? hint->prev : NULL; child != NULL; child = child->prev)
	{
		if (child->end_at <= offset)
			break;
		fix_offsets_delete_ (child, offset, length, NULL);
	}

	for (sp = segment->sub_patterns; sp != NULL; sp = sp->next)
	{
		sp->start_at = fix_offset_delete_one_ (sp->start_at, offset, length);
		sp->end_at = fix_offset_delete_one_ (sp->end_at, offset, length);
	}

	segment->start_at = fix_offset_delete_one_ (segment->start_at, offset, length);
	segment->end_at = fix_offset_delete_one_ (segment->end_at, offset, length);
}

/**
 * delete_range_:
 * @ce: a #GtkSourceContextEngine.
 * @start: the start of deleted area.
 * @end: the end of deleted area.
 *
 * Updates segment tree after deletion: removes segments at deleted
 * interval, updates tree offsets, etc.
 * It's called only from update_tree().
 */
static void
delete_range_ (GtkSourceContextEngine *ce,
	       gint                    start,
	       gint                    end)
{
	g_return_if_fail (start < end);

	/* FIXME adjacent invalid segments? */
	erase_segments (ce, start, end, NULL);
	fix_offsets_delete_ (ce->priv->root_segment, start, end - start, ce->priv->hint);

	/* no need to invalidate at start, update_tree will do it */

	CHECK_TREE (ce);
}

/**
 * gtk_source_context_engine_text_deleted:
 * @ce: a #GtkSourceContextEngine.
 * @offset: the start of deleted text.
 * @length: the length (in characters) of deleted text.
 *
 * Called from GtkTextBuffer::delete_range.
 */
static void
gtk_source_context_engine_text_deleted (GtkSourceEngine *engine,
					gint             offset,
					gint             length)
{
	GtkSourceContextEngine *ce = GTK_SOURCE_CONTEXT_ENGINE (engine);

	g_return_if_fail (length > 0);

	if (!ce->priv->disabled)
	{
		invalidate_region (ce, offset, - length);
	}
}

/**
 * get_invalid_segment:
 * @ce: a #GtkSourceContextEngine.
 *
 * Returns: first invalid segment, or %NULL.
 */
static Segment *
get_invalid_segment (GtkSourceContextEngine *ce)
{
	g_return_val_if_fail (ce->priv->invalid_region.empty, NULL);
	return ce->priv->invalid ? ce->priv->invalid->data : NULL;
}

/**
 * get_invalid_line:
 * @ce: a #GtkSourceContextEngine.
 *
 * Returns: first invalid line, or -1.
 */
static gint
get_invalid_line (GtkSourceContextEngine *ce)
{
	GtkTextIter iter;
	gint offset = G_MAXINT;

	if (!ce->priv->invalid_region.empty)
	{
		gint tmp;
		gtk_text_buffer_get_iter_at_mark (ce->priv->buffer,
						  &iter,
						  ce->priv->invalid_region.start);
		tmp = gtk_text_iter_get_offset (&iter);
		offset = MIN (offset, tmp);
	}

	if (ce->priv->invalid)
	{
		Segment *segment = ce->priv->invalid->data;
		offset = MIN (offset, segment->start_at);
	}

	if (offset == G_MAXINT)
		return -1;

	gtk_text_buffer_get_iter_at_offset (ce->priv->buffer, &iter, offset);
	return gtk_text_iter_get_line (&iter);
}

/**
 * update_tree:
 * @ce: a #GtkSourceContextEngine.
 *
 * Modifies syntax tree according to data in invalid_region.
 */
static void
update_tree (GtkSourceContextEngine *ce)
{
	InvalidRegion *region = &ce->priv->invalid_region;
	gint start, end, delta;
	gint erase_start, erase_end;
	GtkTextIter iter;

	if (region->empty)
		return;

	gtk_text_buffer_get_iter_at_mark (ce->priv->buffer, &iter, region->start);
	start = gtk_text_iter_get_offset (&iter);
	gtk_text_buffer_get_iter_at_mark (ce->priv->buffer, &iter, region->end);
	end = gtk_text_iter_get_offset (&iter);

	delta = region->delta;

	g_assert (start <= MIN (end, end - delta));

	/* Here start and end are actual offsets in the buffer (they do not match offsets
	 * in the tree if delta is not zero); delta is how much was inserted/removed.
	 * First, we insert/delete range from the tree, to make offsets in tree
	 * match offsets in the buffer. Then, create an invalid segment for the rest
	 * of the area if needed. */

	if (delta > 0)
		insert_range (ce, start, delta);
	else if (delta < 0)
		delete_range_ (ce, end, end - delta);

	if (delta <= 0)
	{
		erase_start = start;
		erase_end = end;
	}
	else
	{
		erase_start = start + delta;
		erase_end = end;
	}

	if (erase_start < erase_end)
	{
		erase_segments (ce, erase_start, erase_end, NULL);
		create_segment (ce, ce->priv->root_segment, NULL, erase_start, erase_end, FALSE, NULL);
	}
	else if (get_invalid_at (ce, start) == NULL)
	{
		insert_range (ce, start, 0);
	}

	region->empty = TRUE;

#ifdef ENABLE_CHECK_TREE
	g_assert (get_invalid_at (ce, start) != NULL);
	CHECK_TREE (ce);
#endif
}

/**
 * gtk_source_context_engine_update_highlight:
 * @ce: a #GtkSourceContextEngine.
 * @start: start of area to update.
 * @end: start of area to update.
 * @synchronous: whether it should block until everything
 * is analyzed/highlighted.
 *
 * GtkSourceEngine::update_highlight method.
 *
 * Makes sure the area is analyzed and highlighted. If @synchronous
 * is %FALSE, then it queues idle worker.
 */
static void
gtk_source_context_engine_update_highlight (GtkSourceEngine   *engine,
					    const GtkTextIter *start,
					    const GtkTextIter *end,
					    gboolean           synchronous)
{
	gint invalid_line;
	gint end_line;
	GtkSourceContextEngine *ce = GTK_SOURCE_CONTEXT_ENGINE (engine);

	if (!ce->priv->highlight || ce->priv->disabled)
		return;

	invalid_line = get_invalid_line (ce);
	end_line = gtk_text_iter_get_line (end);

	if (gtk_text_iter_starts_line (end) && end_line > 0)
		end_line -= 1;

	if (invalid_line < 0 || invalid_line > end_line)
	{
		ensure_highlighted (ce, start, end);
	}
	else if (synchronous)
	{
		/* analyze whole region */
		update_syntax (ce, end, 0);
		ensure_highlighted (ce, start, end);
	}
	else
	{
		if (gtk_text_iter_get_line (start) < invalid_line)
		{
			GtkTextIter valid_end = *start;

			gtk_text_iter_set_line (&valid_end, invalid_line);
			ensure_highlighted (ce, start, &valid_end);
		}

		install_first_update (ce);
	}
}

/**
 * enable_highlight:
 * @ce: a #GtkSourceContextEngine.
 * @enable: whether to enable highlighting.
 *
 * Whether to highlight (i.e. apply tags) analyzed area.
 * Note that this does not turn on/off the analyzis stuff,
 * it affects only text tags.
 */
static void
enable_highlight (GtkSourceContextEngine *ce,
		  gboolean                enable)
{
	GtkTextIter start, end;

	if (!enable == !ce->priv->highlight)
		return;

	ce->priv->highlight = enable != 0;
	gtk_text_buffer_get_bounds (GTK_TEXT_BUFFER (ce->priv->buffer),
				    &start, &end);

	if (enable)
	{
		gtk_source_region_add_subregion (ce->priv->refresh_region, &start, &end);

		refresh_range (ce, &start, &end);
	}
	else
	{
		unhighlight_region (ce, &start, &end);
	}
}

static void
buffer_notify_highlight_syntax_cb (GtkSourceContextEngine *ce)
{
	gboolean highlight;

	g_object_get (ce->priv->buffer, "highlight-syntax", &highlight, NULL);
	enable_highlight (ce, highlight);
}


/* IDLE WORKER CODE ------------------------------------------------------- */

/**
 * all_analyzed:
 * @ce: a #GtkSourceContextEngine.
 *
 * Returns: whether everything is analyzed (but it doesn't care about the tags).
 */
static gboolean
all_analyzed (GtkSourceContextEngine *ce)
{
	return ce->priv->invalid == NULL && ce->priv->invalid_region.empty;
}

/**
 * idle_worker:
 * @ce: #GtkSourceContextEngine.
 *
 * Analyzes a batch in idle. Stops when
 * whole buffer is analyzed.
 */
static gboolean
idle_worker (GtkSourceContextEngine *ce)
{
	gboolean retval = G_SOURCE_CONTINUE;

	g_return_val_if_fail (ce->priv->buffer != NULL, G_SOURCE_REMOVE);

	/* analyze batch of text */
	update_syntax (ce, NULL, INCREMENTAL_UPDATE_TIME_SLICE);
	CHECK_TREE (ce);

	if (all_analyzed (ce))
	{
		ce->priv->incremental_update = 0;
		retval = G_SOURCE_REMOVE;
	}

	return retval;
}

/**
 * first_update_callback:
 * @ce: a #GtkSourceContextEngine.
 *
 * Same as idle_worker, except: it runs once, and install idle_worker
 * if not everything was analyzed at once.
 */
static gboolean
first_update_callback (GtkSourceContextEngine *ce)
{
	g_return_val_if_fail (ce->priv->buffer != NULL, G_SOURCE_REMOVE);

	/* analyze batch of text */
	update_syntax (ce, NULL, FIRST_UPDATE_TIME_SLICE);
	CHECK_TREE (ce);

	ce->priv->first_update = 0;

	if (!all_analyzed (ce))
		install_idle_worker (ce);

	return G_SOURCE_REMOVE;
}

/**
 * install_idle_worker:
 * @ce: #GtkSourceContextEngine.
 *
 * Schedules reanalyzing buffer in idle.
 * Always safe to call.
 */
static void
install_idle_worker (GtkSourceContextEngine *ce)
{
	if (ce->priv->first_update == 0 && ce->priv->incremental_update == 0)
		ce->priv->incremental_update =
			gdk_threads_add_idle_full (INCREMENTAL_UPDATE_PRIORITY,
			                           (GSourceFunc) idle_worker, ce, NULL);
}

/**
 * install_first_update:
 * @ce: #GtkSourceContextEngine.
 *
 * Schedules first_update_callback call.
 * Always safe to call.
 */
static void
install_first_update (GtkSourceContextEngine *ce)
{
	if (ce->priv->first_update == 0)
	{
		if (ce->priv->incremental_update != 0)
		{
			g_source_remove (ce->priv->incremental_update);
			ce->priv->incremental_update = 0;
		}

		ce->priv->first_update =
			gdk_threads_add_idle_full (FIRST_UPDATE_PRIORITY,
			                           (GSourceFunc) first_update_callback,
			                           ce, NULL);
	}
}

/* GtkSourceContextEngine class ------------------------------------------- */

static void _gtk_source_engine_interface_init (GtkSourceEngineInterface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceContextEngine,
			 _gtk_source_context_engine,
			 G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceContextEngine)
			 G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_ENGINE,
						_gtk_source_engine_interface_init))

static GQuark
gtk_source_context_engine_error_quark (void)
{
	static GQuark err_q = 0;
	if (err_q == 0)
		err_q = g_quark_from_static_string ("gtk-source-context-engine-error-quark");
	return err_q;
}

static void
remove_tags_hash_cb (G_GNUC_UNUSED gpointer  style,
		     GSList                 *tags,
		     GtkTextTagTable        *table)
{
	GSList *l = tags;

	while (l != NULL)
	{
		gtk_text_tag_table_remove (table, l->data);
		g_object_unref (l->data);
		l = l->next;
	}

	g_slist_free (tags);
}

/**
 * destroy_tags_hash:
 * @ce: #GtkSourceContextEngine.
 *
 * Destroys syntax tags cache.
 */
static void
destroy_tags_hash (GtkSourceContextEngine *ce)
{
	g_hash_table_foreach (ce->priv->tags, (GHFunc) remove_tags_hash_cb,
                              gtk_text_buffer_get_tag_table (ce->priv->buffer));
	g_hash_table_destroy (ce->priv->tags);
	ce->priv->tags = NULL;
}

static void
destroy_context_classes_list (GtkSourceContextEngine *ce)
{
	GtkTextTagTable *table;
	GSList *l;

	table = gtk_text_buffer_get_tag_table (ce->priv->buffer);

	for (l = ce->priv->context_classes; l != NULL; l = l->next)
	{
		GtkTextTag *tag = l->data;

		gtk_text_tag_table_remove (table, tag);
		g_object_unref (tag);
	}

	g_slist_free (ce->priv->context_classes);
	ce->priv->context_classes = NULL;
}

/**
 * gtk_source_context_engine_attach_buffer:
 * @ce: #GtkSourceContextEngine.
 * @buffer: buffer.
 *
 * Detaches engine from previous buffer, and attaches to @buffer if
 * it's not %NULL.
 */
static void
gtk_source_context_engine_attach_buffer (GtkSourceEngine *engine,
					 GtkTextBuffer   *buffer)
{
	GtkSourceContextEngine *ce = GTK_SOURCE_CONTEXT_ENGINE (engine);

	g_return_if_fail (!buffer || GTK_IS_TEXT_BUFFER (buffer));

	if (ce->priv->buffer == buffer)
		return;

	/* Detach previous buffer if there is one. */
	if (ce->priv->buffer != NULL)
	{
		g_signal_handlers_disconnect_by_func (ce->priv->buffer,
						      (gpointer) buffer_notify_highlight_syntax_cb,
						      ce);

		if (ce->priv->first_update != 0)
			g_source_remove (ce->priv->first_update);
		if (ce->priv->incremental_update != 0)
			g_source_remove (ce->priv->incremental_update);
		ce->priv->first_update = 0;
		ce->priv->incremental_update = 0;

		if (ce->priv->root_segment != NULL)
			segment_destroy (ce, ce->priv->root_segment);
		if (ce->priv->root_context != NULL)
			context_unref (ce->priv->root_context);
		g_assert (!ce->priv->invalid);
		g_slist_free (ce->priv->invalid);
		ce->priv->root_segment = NULL;
		ce->priv->root_context = NULL;
		ce->priv->invalid = NULL;

		if (ce->priv->invalid_region.start != NULL)
			gtk_text_buffer_delete_mark (ce->priv->buffer,
						     ce->priv->invalid_region.start);
		if (ce->priv->invalid_region.end != NULL)
			gtk_text_buffer_delete_mark (ce->priv->buffer,
						     ce->priv->invalid_region.end);
		ce->priv->invalid_region.start = NULL;
		ce->priv->invalid_region.end = NULL;

		/* this deletes tags from the tag table, therefore there is no need
		 * in removing tags from the text (it may be very slow).
		 * FIXME: don't we want to just destroy and forget everything when
		 * the buffer is destroyed? Removing tags is still slower than doing
		 * nothing. Caveat: if tag table is shared with other buffer, we do
		 * need to remove tags. */
		destroy_tags_hash (ce);
		ce->priv->n_tags = 0;

		destroy_context_classes_list (ce);

		g_clear_object (&ce->priv->refresh_region);
	}

	ce->priv->buffer = buffer;

	if (buffer != NULL)
	{
		ContextDefinition *main_definition;
		GtkTextIter start, end;

		main_definition = gtk_source_context_data_lookup_root (ce->priv->ctx_data);

		/* If we don't abort here, we will crash later (#485661). But it should
		 * never happen, _gtk_source_context_data_finish_parse checks main context. */
		g_assert (main_definition != NULL);

		ce->priv->root_context = context_new (NULL, main_definition, NULL, NULL, FALSE);
		ce->priv->root_segment = create_segment (ce, NULL, ce->priv->root_context, 0, 0, TRUE, NULL);

		ce->priv->tags = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
		ce->priv->context_classes = NULL;

		gtk_text_buffer_get_bounds (buffer, &start, &end);
		ce->priv->invalid_region.start = gtk_text_buffer_create_mark (buffer, NULL,
									      &start, TRUE);
		ce->priv->invalid_region.end = gtk_text_buffer_create_mark (buffer, NULL,
									    &end, FALSE);

		if (gtk_text_buffer_get_char_count (buffer) != 0)
		{
			ce->priv->invalid_region.empty = FALSE;
			ce->priv->invalid_region.delta = gtk_text_buffer_get_char_count (buffer);
		}
		else
		{
			ce->priv->invalid_region.empty = TRUE;
			ce->priv->invalid_region.delta = 0;
		}

		g_object_get (buffer, "highlight-syntax", &ce->priv->highlight, NULL);
		ce->priv->refresh_region = gtk_source_region_new (buffer);

		g_signal_connect_swapped (buffer,
					  "notify::highlight-syntax",
					  G_CALLBACK (buffer_notify_highlight_syntax_cb),
					  ce);

		install_first_update (ce);
	}
}

/**
 * disable_syntax_analysis:
 * @ce: #GtkSourceContextEngine.
 *
 * Dsiables highlighting in case of errors (currently if highlighting
 * a single line took too long, so that highlighting doesn't freeze
 * text editor).
 */
static void
disable_syntax_analysis (GtkSourceContextEngine *ce)
{
	if (!ce->priv->disabled)
	{
		ce->priv->disabled = TRUE;
		gtk_source_context_engine_attach_buffer (GTK_SOURCE_ENGINE (ce), NULL);
		/* FIXME maybe emit some signal here? */
	}
}

static void
set_tag_style_hash_cb (const char             *style,
		       GSList                 *tags,
		       GtkSourceContextEngine *ce)
{
	while (tags != NULL)
	{
		set_tag_style (ce, tags->data, style);
		tags = tags->next;
	}
}

/**
 * gtk_source_context_engine_set_style_scheme:
 * @engine: #GtkSourceContextEngine.
 * @scheme: #GtkSourceStyleScheme to set.
 *
 * GtkSourceEngine::set_style_scheme method.
 * Sets current style scheme, updates tag styles and everything.
 */
static void
gtk_source_context_engine_set_style_scheme (GtkSourceEngine      *engine,
					    GtkSourceStyleScheme *scheme)
{
	GtkSourceContextEngine *ce;

	g_return_if_fail (GTK_SOURCE_IS_CONTEXT_ENGINE (engine));
	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME (scheme) || scheme == NULL);

	ce = GTK_SOURCE_CONTEXT_ENGINE (engine);

	if (g_set_object (&ce->priv->style_scheme, scheme))
	{
		g_hash_table_foreach (ce->priv->tags, (GHFunc) set_tag_style_hash_cb, ce);
	}
}

static void
gtk_source_context_engine_finalize (GObject *object)
{
	GtkSourceContextEngine *ce = GTK_SOURCE_CONTEXT_ENGINE (object);

	if (ce->priv->buffer != NULL)
	{
		g_critical ("finalizing engine with attached buffer");
		/* Disconnect the buffer (if there is one), which destroys almost
		 * everything. */
		gtk_source_context_engine_attach_buffer (GTK_SOURCE_ENGINE (ce), NULL);
	}

	g_assert (!ce->priv->tags);
	g_assert (!ce->priv->root_context);
	g_assert (!ce->priv->root_segment);

	if (ce->priv->first_update != 0)
	{
		g_source_remove (ce->priv->first_update);
		ce->priv->first_update = 0;
	}

	if (ce->priv->incremental_update != 0)
	{
		g_source_remove (ce->priv->incremental_update);
		ce->priv->incremental_update = 0;
	}

	_gtk_source_context_data_unref (ce->priv->ctx_data);

	if (ce->priv->style_scheme != NULL)
		g_object_unref (ce->priv->style_scheme);

	G_OBJECT_CLASS (_gtk_source_context_engine_parent_class)->finalize (object);
}

static void
_gtk_source_engine_interface_init (GtkSourceEngineInterface *iface)
{
	iface->attach_buffer = gtk_source_context_engine_attach_buffer;
	iface->text_inserted = gtk_source_context_engine_text_inserted;
	iface->text_deleted = gtk_source_context_engine_text_deleted;
	iface->update_highlight = gtk_source_context_engine_update_highlight;
	iface->set_style_scheme = gtk_source_context_engine_set_style_scheme;
}

static void
_gtk_source_context_engine_class_init (GtkSourceContextEngineClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->finalize = gtk_source_context_engine_finalize;
}

static void
_gtk_source_context_engine_init (GtkSourceContextEngine *ce)
{
	ce->priv = _gtk_source_context_engine_get_instance_private (ce);
}

GtkSourceContextEngine *
_gtk_source_context_engine_new (GtkSourceContextData *ctx_data)
{
	GtkSourceContextEngine *ce;

	g_return_val_if_fail (ctx_data != NULL, NULL);
	g_return_val_if_fail (ctx_data->lang != NULL, NULL);

	ce = g_object_new (GTK_SOURCE_TYPE_CONTEXT_ENGINE, NULL);
	ce->priv->ctx_data = _gtk_source_context_data_ref (ctx_data);

	return ce;
}

/**
 * _gtk_source_context_data_new:
 * @lang: #GtkSourceLanguage.
 *
 * Creates new context definition set. It does not set lang->priv->ctx_data,
 * that's lang business.
 */
GtkSourceContextData *
_gtk_source_context_data_new (GtkSourceLanguage *lang)
{
	GtkSourceContextData *ctx_data;

	g_return_val_if_fail (GTK_SOURCE_IS_LANGUAGE (lang), NULL);

	ctx_data = g_slice_new (GtkSourceContextData);
	ctx_data->ref_count = 1;
	ctx_data->lang = lang;
	ctx_data->definitions = g_hash_table_new_full (g_str_hash, g_str_equal, g_free,
						       (GDestroyNotify) context_definition_unref);

	return ctx_data;
}

GtkSourceContextData *
_gtk_source_context_data_ref (GtkSourceContextData *ctx_data)
{
	g_return_val_if_fail (ctx_data != NULL, NULL);
	ctx_data->ref_count++;
	return ctx_data;
}

/**
 * _gtk_source_context_data_unref:
 * @ctx_data: #GtkSourceContextData.
 *
 * Decreases reference count in ctx_data. When reference count
 * drops to zero, ctx_data is freed, and ctx_data->lang->priv->ctx_data
 * is unset.
 */
void
_gtk_source_context_data_unref (GtkSourceContextData *ctx_data)
{
	g_return_if_fail (ctx_data != NULL);

	if (--ctx_data->ref_count == 0)
	{
		if (ctx_data->lang != NULL && ctx_data->lang->priv != NULL &&
		    ctx_data->lang->priv->ctx_data == ctx_data)
			ctx_data->lang->priv->ctx_data = NULL;
		g_hash_table_destroy (ctx_data->definitions);
		g_slice_free (GtkSourceContextData, ctx_data);
	}
}

/* SYNTAX TREE ------------------------------------------------------------ */

/**
 * apply_sub_patterns:
 * @contextstate: a #Context.
 * @line_starts_at: beginning offset of the line.
 * @line: the line to analyze.
 * @line_pos: the position inside @line.
 * @line_length: the length of @line.
 * @regex: regex that matched.
 * @where: kind of sub patterns to apply.
 *
 * Applies sub patterns of kind @where to the matched text.
 */
static void
apply_sub_patterns (Segment         *state,
		    LineInfo        *line,
		    GtkSourceRegex  *regex,
		    SubPatternWhere  where)
{
	GSList *sub_pattern_list = state->context->definition->sub_patterns;

	if (SEGMENT_IS_CONTAINER (state))
	{
		gint start_pos;
		gint end_pos;

		_gtk_source_regex_fetch_pos (regex, line->text, 0, &start_pos, &end_pos);

		if (where == SUB_PATTERN_WHERE_START)
		{
			if (line->start_at + start_pos != state->start_at)
				g_critical ("%s: oops", G_STRLOC);
			else if (line->start_at + end_pos > state->end_at)
				g_critical ("%s: oops", G_STRLOC);
			else
				state->start_len = line->start_at + end_pos - state->start_at;
		}
		else
		{
			if (line->start_at + start_pos < state->start_at)
				g_critical ("%s: oops", G_STRLOC);
			else if (line->start_at + end_pos != state->end_at)
				g_critical ("%s: oops", G_STRLOC);
			else
				state->end_len = state->end_at - line->start_at - start_pos;
		}
	}

	while (sub_pattern_list != NULL)
	{
		SubPatternDefinition *sp_def = sub_pattern_list->data;

		if (sp_def->where == where)
		{
			gint start_pos;
			gint end_pos;

			if (sp_def->is_named)
			{
				_gtk_source_regex_fetch_named_pos (regex,
								   line->text,
								   sp_def->u.name,
								   &start_pos,
								   &end_pos);
			}
			else
			{
				_gtk_source_regex_fetch_pos (regex,
							     line->text,
							     sp_def->u.num,
							     &start_pos,
							     &end_pos);
			}

			if (start_pos >= 0 && start_pos != end_pos)
			{
				sub_pattern_new (state,
						 line->start_at + start_pos,
						 line->start_at + end_pos,
						 sp_def);
			}
		}

		sub_pattern_list = sub_pattern_list->next;
	}
}

/**
 * can_apply_match:
 * @state: the current state of the parser.
 * @line: the line to analyze.
 * @match_start: start position of match, bytes.
 * @match_end: where to put end of match, bytes.
 * @where: kind of sub patterns to apply.
 *
 * See apply_match(), this function is a helper function
 * called from where, it doesn't modify syntax tree.
 *
 * Returns: %TRUE if the match can be applied.
 */
static gboolean
can_apply_match (Context        *state,
		 LineInfo       *line,
		 gint            match_start,
		 gint           *match_end,
		 GtkSourceRegex *regex)
{
	gint end_match_pos;
	gboolean ancestor_ends;
	gint pos;

	ancestor_ends = FALSE;

	/* end_match_pos is the position of the end of the matched regex. */
	_gtk_source_regex_fetch_pos_bytes (regex, 0, NULL, &end_match_pos);

	g_assert (end_match_pos <= line->byte_length);

	/* Verify if an ancestor ends in the matched text. */
	if (ANCESTOR_CAN_END_CONTEXT (state) &&
	    /* there is no middle of zero-length match */
	    match_start < end_match_pos)
	{
		pos = match_start + 1;

		while (pos < end_match_pos)
		{
			if (ancestor_context_ends_here (state, line, pos))
			{
				ancestor_ends = TRUE;
				break;
			}

			pos = g_utf8_next_char (line->text + pos) - line->text;
		}
	}
	else
	{
		pos = end_match_pos;
	}

	if (ancestor_ends)
	{
		/* An ancestor ends in the middle of the match, we verify
		 * if the regex matches against the available string before
		 * the end of the ancestor.
		 * For instance in C a net-address context matches even if
		 * it contains the end of a multi-line comment. */
		if (!_gtk_source_regex_match (regex, line->text, pos, match_start))
		{
			/* This match is not valid, so we can try to match
			 * the next definition, so the position should not
			 * change. */
			return FALSE;
		}
	}

	*match_end = pos;
	return TRUE;
}

static gint
line_pos_to_offset (LineInfo *line,
		    gint      pos)
{
	if (line->char_length != line->byte_length)
		pos = g_utf8_pointer_to_offset (line->text, line->text + pos);
	return line->start_at + pos;
}

/**
 * apply_match:
 * @state: the current state of the parser.
 * @line: the line to analyze.
 * @line_pos: position in the line, bytes.
 * @regex: regex that matched.
 * @where: kind of sub patterns to apply.
 *
 * Moves @line_pos after the matched text. @line_pos is not
 * updated and the function returns %FALSE if the match cannot be
 * applied because an ancestor ends in the middle of the matched
 * text.
 *
 * If the match can be applied the function applies the appropriate
 * sub patterns.
 *
 * Returns: %TRUE if the match can be applied.
 */
static gboolean
apply_match (Segment         *state,
	     LineInfo        *line,
	     gint            *line_pos,
	     GtkSourceRegex  *regex,
	     SubPatternWhere  where)
{
	gint match_end;

	if (!can_apply_match (state->context, line, *line_pos, &match_end, regex))
		return FALSE;

	segment_extend (state, line_pos_to_offset (line, match_end));
	apply_sub_patterns (state, line, regex, where);
	*line_pos = match_end;

	return TRUE;
}

/**
 * create_reg_all:
 * @context: context.
 * @definition: context definition.
 *
 * Creates regular expression for all possible transitions: it
 * combines terminating regex, terminating regexes of parent
 * contexts if those can terminate this one, and start regexes
 * of child contexts.
 *
 * It takes as an argument actual context or a context definition. In
 * case when context end depends on start (\%{foo@start} references),
 * it must use the context, definition is not enough. If there are no
 * those references, then the reg_all is created right in the definition
 * when no contexts exist yet. This is why this function has its funny
 * arguments.
 *
 * Returns: resulting regex or %NULL when pcre failed to compile the regex.
 */
static GtkSourceRegex *
create_reg_all (Context           *context,
		ContextDefinition *definition)
{
	DefinitionsIter iter;
	DefinitionChild *child_def;
	GString *all;
	GtkSourceRegex *regex;
	GError *error = NULL;

	g_return_val_if_fail ((context == NULL && definition != NULL) ||
			      (context != NULL && definition == NULL), NULL);

	if (definition == NULL)
		definition = context->definition;

	all = g_string_new ("(");

	/* Closing regex. */
	if (definition->type == CONTEXT_TYPE_CONTAINER &&
	    definition->u.start_end.end != NULL)
	{
		GtkSourceRegex *end;

		if (_gtk_source_regex_is_resolved (definition->u.start_end.end))
		{
			end = definition->u.start_end.end;
		}
		else
		{
			g_return_val_if_fail (context && context->end, NULL);
			end = context->end;
		}

		g_string_append (all, _gtk_source_regex_get_pattern (end));
		g_string_append (all, "|");
	}

	/* Ancestors. */
	if (context != NULL)
	{
		Context *tmp = context;

		while (ANCESTOR_CAN_END_CONTEXT (tmp))
		{
			if (!CONTEXT_EXTENDS_PARENT (tmp))
			{
				gboolean append = TRUE;

				/* Code as it is seems to be right, and seems working right.
				 * Remove FIXME's below if everything is fine. */

				if (tmp->parent->end != NULL)
					g_string_append (all, _gtk_source_regex_get_pattern (tmp->parent->end));
				/* FIXME ?
				 * The old code insisted on having tmp->parent->end != NULL here,
				 * though e.g. in case line-comment -> email-address it's not the case.
				 * Apparently using $ fixes the problem. */
				else if (CONTEXT_END_AT_LINE_END (tmp->parent))
					g_string_append (all, "$");
				/* FIXME it's not clear whether it can happen, maybe we need assert here
				 * or parser need to check it */
				else
				{
					/* g_critical ("%s: oops", G_STRLOC); */
					append = FALSE;
				}

				if (append)
					g_string_append (all, "|");
			}

			tmp = tmp->parent;
		}
	}

	/* Children. */
	definition_iter_init (&iter, definition);
	while ((child_def = definition_iter_next (&iter)) != NULL)
	{
		GtkSourceRegex *child_regex = NULL;

		g_return_val_if_fail (child_def->resolved, NULL);

		switch (child_def->u.definition->type)
		{
			case CONTEXT_TYPE_CONTAINER:
				child_regex = child_def->u.definition->u.start_end.start;
				break;
			case CONTEXT_TYPE_SIMPLE:
				child_regex = child_def->u.definition->u.match;
				break;
			default:
				g_return_val_if_reached (NULL);
		}

		if (child_regex != NULL)
		{
			g_string_append (all, _gtk_source_regex_get_pattern (child_regex));
			g_string_append (all, "|");
		}
	}
	definition_iter_destroy (&iter);

	if (all->len > 1)
		g_string_truncate (all, all->len - 1);
	g_string_append (all, ")");

	regex = _gtk_source_regex_new (all->str, 0, &error);

	if (regex == NULL)
	{
		/* regex_new could fail, for instance if there are different
		 * named sub-patterns with the same name or if resulting regex is
		 * too long. In this case fixing lang file helps (e.g. renaming
		 * subpatterns, making huge keywords use bigger prefixes, etc.) */
		g_warning (_("Cannot create a regex for all the transitions, "
			     "the syntax highlighting process will be slower "
			     "than usual.\nThe error was: %s"), error->message);
		g_clear_error (&error);
	}

	g_string_free (all, TRUE);
	return regex;
}

static Context *
context_ref (Context *context)
{
	if (context != NULL)
		context->ref_count++;
	return context;
}

/* does not copy style */
static Context *
context_new (Context           *parent,
	     ContextDefinition *definition,
	     const gchar       *line_text,
	     const gchar       *style,
	     gboolean           ignore_children_style)
{
	Context *context;

	context = g_slice_new0 (Context);
	context->ref_count = 1;
	context->definition = definition;
	context->parent = parent;

	context->style = style;
	context->ignore_children_style = ignore_children_style;

	if (parent != NULL && parent->ignore_children_style)
	{
		context->ignore_children_style = TRUE;
		context->style = NULL;
	}

	if (!parent || (parent->all_ancestors_extend && CONTEXT_EXTENDS_PARENT (parent)))
	{
		context->all_ancestors_extend = TRUE;
	}

	if (line_text &&
	    definition->type == CONTEXT_TYPE_CONTAINER &&
	    definition->u.start_end.end)
	{
		context->end = _gtk_source_regex_resolve (definition->u.start_end.end,
							  definition->u.start_end.start,
							  line_text);
	}

	/* Create reg_all. If it is possibile we share the same reg_all
	 * for more contexts storing it in the definition. */
	if (ANCESTOR_CAN_END_CONTEXT (context) ||
	    (definition->type == CONTEXT_TYPE_CONTAINER &&
	     definition->u.start_end.end != NULL &&
	     !_gtk_source_regex_is_resolved (definition->u.start_end.end)))
	{
		context->reg_all = create_reg_all (context, NULL);
	}
	else
	{
		if (!definition->reg_all)
			definition->reg_all = create_reg_all (NULL, definition);
		context->reg_all = _gtk_source_regex_ref (definition->reg_all);
	}

#ifdef ENABLE_DEBUG
	{
		GString *str = g_string_new (definition->id);
		Context *tmp = context->parent;
		while (tmp != NULL)
		{
			g_string_prepend (str, "/");
			g_string_prepend (str, tmp->definition->id);
			tmp = tmp->parent;
		}
		g_print ("created context %s: %s\n", definition->id, str->str);
		g_string_free (str, TRUE);
	}
#endif

	return context;
}

static void
context_unref_hash_cb (G_GNUC_UNUSED gpointer  text,
		       Context                *context)
{
	context->parent = NULL;
	context_unref (context);
}

static gboolean
remove_context_cb (G_GNUC_UNUSED gpointer  text,
		   Context                *context,
		   Context                *target)
{
	return context == target;
}

static void
context_remove_child (Context *parent,
		      Context *context)
{
	ContextPtr *ptr, *prev = NULL;
	gboolean delete = TRUE;

	g_assert (context->parent == parent);

	for (ptr = parent->children; ptr; ptr = ptr->next)
	{
		if (ptr->definition == context->definition)
			break;
		prev = ptr;
	}

	g_assert (ptr != NULL);

	if (!ptr->fixed)
	{
		g_hash_table_foreach_remove (ptr->u.hash,
					     (GHRFunc) remove_context_cb,
					     context);

		if (g_hash_table_size (ptr->u.hash) != 0)
			delete = FALSE;
	}

	if (delete)
	{
		if (prev != NULL)
			prev->next = ptr->next;
		else
			parent->children = ptr->next;

		if (!ptr->fixed)
			g_hash_table_destroy (ptr->u.hash);

#ifdef ENABLE_DEBUG
		memset (ptr, 1, sizeof (ContextPtr));
#else
		g_slice_free (ContextPtr, ptr);
#endif
	}
}

/**
 * context_unref:
 * @context: the context.
 *
 * Decreases reference count and removes @context
 * from the tree when it drops to zero.
 */
static void
context_unref (Context *context)
{
	ContextPtr *children;
	guint i;

	if (context == NULL || --context->ref_count != 0)
		return;

	DEBUG (g_print ("destroying context %s\n", context->definition->id));

	children = context->children;
	context->children = NULL;

	while (children != NULL)
	{
		ContextPtr *ptr = children;

		children = children->next;

		if (ptr->fixed)
		{
			ptr->u.context->parent = NULL;
			context_unref (ptr->u.context);
		}
		else
		{
			g_hash_table_foreach (ptr->u.hash,
					      (GHFunc) context_unref_hash_cb,
					      NULL);
			g_hash_table_destroy (ptr->u.hash);
		}

#ifdef ENABLE_DEBUG
		memset (ptr, 1, sizeof (ContextPtr));
#else
		g_slice_free (ContextPtr, ptr);
#endif
	}

	if (context->parent != NULL)
		context_remove_child (context->parent, context);

	_gtk_source_regex_unref (context->end);
	_gtk_source_regex_unref (context->reg_all);

	if (context->subpattern_context_classes != NULL)
	{
		for (i = 0; i < context->definition->n_sub_patterns; ++i)
		{
			g_slist_free_full (context->subpattern_context_classes[i],
			                   (GDestroyNotify)context_class_tag_free);
		}
	}

	g_slist_free_full (context->context_classes, (GDestroyNotify)context_class_tag_free);

	g_free (context->subpattern_context_classes);
	g_free (context->subpattern_tags);

	g_slice_free (Context, context);
}

static void
context_freeze_hash_cb (G_GNUC_UNUSED gpointer  text,
		        Context                *context)
{
	context_freeze (context);
}

/**
 * context_freeze:
 * @context: the context.
 *
 * Recursively increments reference count in context and its children,
 * and marks them, so context_thaw is able to correctly decrement
 * reference count.
 * This function is for update_syntax: we want to preserve existing
 * contexts when possible, and update_syntax erases contexts from
 * reanalyzed lines; so to avoid destructing and recreating contexts
 * every time, we need to increment reference count on existing contexts,
 * and decrement it when we are done with analysis, so no more needed
 * contexts go away. Keeping a list of referenced contexts is painful
 * or slow, so we just reference all contexts present at the moment.
 *
 * Note this is not reentrant, context_freeze()/context_thaw() pair is called
 * only from update_syntax().
 */
static void
context_freeze (Context *ctx)
{
	ContextPtr *ptr;

	g_assert (!ctx->frozen);
	ctx->frozen = TRUE;
	context_ref (ctx);

	for (ptr = ctx->children; ptr != NULL; ptr = ptr->next)
	{
		if (ptr->fixed)
		{
			context_freeze (ptr->u.context);
		}
		else
		{
			g_hash_table_foreach (ptr->u.hash,
					      (GHFunc) context_freeze_hash_cb,
					      NULL);
		}
	}
}

static void
get_child_contexts_hash_cb (G_GNUC_UNUSED gpointer   text,
			    Context                 *context,
			    GSList                 **list)
{
	*list = g_slist_prepend (*list, context);
}

/**
 * context_thaw:
 * @context: the context.
 *
 * Recursively decrements reference count in context and its children,
 * if it was incremented by context_freeze().
 */
static void
context_thaw (Context *ctx)
{
	ContextPtr *ptr;

	if (!ctx->frozen)
		return;

	for (ptr = ctx->children; ptr != NULL; )
	{
		ContextPtr *next = ptr->next;

		if (ptr->fixed)
		{
			context_thaw (ptr->u.context);
		}
		else
		{
			GSList *children = NULL;

			g_hash_table_foreach (ptr->u.hash,
					      (GHFunc) get_child_contexts_hash_cb,
					      &children);

			g_slist_foreach (children, (GFunc) context_thaw, NULL);
			g_slist_free (children);
		}

		ptr = next;
	}

	ctx->frozen = FALSE;
	context_unref (ctx);
}

static Context *
create_child_context (Context         *parent,
		      DefinitionChild *child_def,
		      const gchar     *line_text)
{
	Context *context;
	ContextPtr *ptr;
	gchar *match = NULL;
	ContextDefinition *definition = child_def->u.definition;

	g_return_val_if_fail (parent != NULL, NULL);

	for (ptr = parent->children;
	     ptr != NULL && ptr->definition != definition;
	     ptr = ptr->next) ;

	if (ptr == NULL)
	{
		ptr = g_slice_new0 (ContextPtr);
		ptr->next = parent->children;
		parent->children = ptr;
		ptr->definition = definition;

		if (definition->type != CONTEXT_TYPE_CONTAINER ||
		    !definition->u.start_end.end ||
		    _gtk_source_regex_is_resolved (definition->u.start_end.end))
		{
			ptr->fixed = TRUE;
		}

		if (!ptr->fixed)
			ptr->u.hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
	}

	if (ptr->fixed)
	{
		context = ptr->u.context;
	}
	else
	{
		match = _gtk_source_regex_fetch (definition->u.start_end.start, 0);
		g_return_val_if_fail (match != NULL, NULL);
		context = g_hash_table_lookup (ptr->u.hash, match);
	}

	if (context != NULL)
	{
		g_free (match);
		return context_ref (context);
	}

	context = context_new (parent,
			       definition,
			       line_text,
			       child_def->override_style ? child_def->style :
					child_def->u.definition->default_style,
			       child_def->override_style ? child_def->override_style_deep : FALSE);
	g_return_val_if_fail (context != NULL, NULL);

	if (ptr->fixed)
		ptr->u.context = context;
	else
		g_hash_table_insert (ptr->u.hash, match, context);

	return context;
}

/**
 * segment_new:
 * @ce: the engine.
 * @parent: parent segment (%NULL for the root segment).
 * @context: context for this segment (%NULL for invalid segments).
 * @start_at: start offset in the buffer, characters.
 * @end_at: end offset in the buffer, characters.
 * @is_start: is_start flag.
 *
 * Creates a new segment structure. It doesn't take care about
 * parent or siblings, create_segment() is the function to
 * create new segments in the tree.
 *
 * Returns: newly created segment.
 */
static Segment *
segment_new (GtkSourceContextEngine *ce,
	     Segment                *parent,
	     Context                *context,
	     gint                    start_at,
	     gint                    end_at,
	     gboolean                is_start)
{
	Segment *segment;

#ifdef ENABLE_CHECK_TREE
	g_assert (!is_start || context != NULL);
#endif

	segment = g_slice_new0 (Segment);
	segment->parent = parent;
	segment->context = context_ref (context);
	segment->start_at = start_at;
	segment->end_at = end_at;
	segment->is_start = is_start;

	if (context == NULL)
		add_invalid (ce, segment);

	return segment;
}

static void
find_segment_position_forward_ (Segment  *segment,
				gint      start_at,
				gint      end_at,
				Segment **prev,
				Segment **next)
{
	g_assert (segment->start_at <= start_at);

	while (segment != NULL)
	{
		if (segment->end_at == start_at)
		{
			while (segment->next != NULL && segment->next->start_at == start_at)
				segment = segment->next;

			*prev = segment;
			*next = segment->next;

			break;
		}

		if (segment->start_at == end_at)
		{
			*next = segment;
			*prev = segment->prev;
			break;
		}

		if (segment->start_at > end_at)
		{
			*next = segment;
			break;
		}

		if (segment->end_at < start_at)
			*prev = segment;

		segment = segment->next;
	}
}

static void
find_segment_position_backward_ (Segment  *segment,
				 gint      start_at,
				 gint      end_at,
				 Segment **prev,
				 Segment **next)
{
	g_assert (start_at < segment->end_at);

	while (segment != NULL)
	{
		if (segment->end_at <= start_at)
		{
			*prev = segment;
			break;
		}

		g_assert (segment->start_at >= end_at);

		*next = segment;
		segment = segment->prev;
	}
}

/**
 * find_segment_position:
 * @parent: parent segment (not %NULL).
 * @hint: segment somewhere near new segment position.
 * @start_at: start offset.
 * @end_at: end offset.
 * @prev: location to return previous sibling.
 * @next: location to return next sibling.
 *
 * Finds siblings of a new segment to be created at interval
 * (start_at, end_at). It uses hint to avoid walking whole
 * parent->children list.
 */
static void
find_segment_position (Segment  *parent,
		       Segment  *hint,
		       gint      start_at,
		       gint      end_at,
		       Segment **prev,
		       Segment **next)
{
	Segment *tmp;

	g_assert (parent->start_at <= start_at && end_at <= parent->end_at);
	g_assert (!hint || hint->parent == parent);

	*prev = *next = NULL;

	if (parent->children == NULL)
		return;

	if (parent->children->next == NULL)
	{
		tmp = parent->children;

		if (start_at >= tmp->end_at)
			*prev = tmp;
		else
			*next = tmp;

		return;
	}

	if (hint == NULL)
		hint = parent->children;

	if (hint->end_at <= start_at)
		find_segment_position_forward_ (hint, start_at, end_at, prev, next);
	else
		find_segment_position_backward_ (hint, start_at, end_at, prev, next);
}

/**
 * create_segment:
 * @ce: the engine.
 * @parent: parent segment (%NULL for the root segment).
 * @context: context for this segment (%NULL for invalid segments).
 * @start_at: start offset, characters.
 * @end_at: end offset, characters.
 * @is_start: is_start flag.
 * @hint: a segment somewhere near new one, to omtimize search.
 *
 * Creates a new segment and inserts it into the tree.
 *
 * Returns: newly created segment.
 */
static Segment *
create_segment (GtkSourceContextEngine *ce,
		Segment                *parent,
		Context                *context,
		gint                    start_at,
		gint                    end_at,
		gboolean                is_start,
		Segment                *hint)
{
	Segment *segment;

	g_assert (!parent || (parent->start_at <= start_at && end_at <= parent->end_at));

	segment = segment_new (ce, parent, context, start_at, end_at, is_start);

	if (parent != NULL)
	{
		Segment *prev, *next;

		if (hint == NULL)
		{
			hint = ce->priv->hint;
			while (hint != NULL && hint->parent != parent)
				hint = hint->parent;
		}

		find_segment_position (parent, hint,
				       start_at, end_at,
				       &prev, &next);

		g_assert ((!parent->children && !prev && !next) ||
			  (parent->children && (prev || next)));
		g_assert (!prev || prev->next == next);
		g_assert (!next || next->prev == prev);

		segment->next = next;
		segment->prev = prev;

		if (next != NULL)
			next->prev = segment;
		else
			parent->last_child = segment;

		if (prev != NULL)
			prev->next = segment;
		else
			parent->children = segment;

		CHECK_SEGMENT_LIST (parent);
		CHECK_TREE (ce);
	}

	return segment;
}

/**
 * segment_extend:
 * @state: the semgent.
 * @end_at: new end offset, characters.
 *
 * Updates end offset in the segment and its ancestors.
 */
static void
segment_extend (Segment *state,
		gint     end_at)
{
	while (state != NULL && state->end_at < end_at)
	{
		state->end_at = end_at;
		state = state->parent;
	}
	CHECK_SEGMENT_LIST (state->parent);
}

static void
segment_destroy_children (GtkSourceContextEngine *ce,
			  Segment                *segment)
{
	Segment *child;
	SubPattern *sp;

	g_return_if_fail (segment != NULL);

	child = segment->children;
	segment->children = NULL;
	segment->last_child = NULL;

	while (child != NULL)
	{
		Segment *next = child->next;
		segment_destroy (ce, child);
		child = next;
	}

	sp = segment->sub_patterns;
	segment->sub_patterns = NULL;

	while (sp != NULL)
	{
		SubPattern *next = sp->next;
		sub_pattern_free (sp);
		sp = next;
	}
}

/**
 * segment_destroy:
 * @ce: the engine.
 * @context: the segment to destroy.
 *
 * Recursively frees given segment. It removes the segment
 * from ce structure, but it doesn't update parent and
 * siblings. segment_remove() is the function that takes
 * care of everything.
 */
static void
segment_destroy (GtkSourceContextEngine *ce,
		 Segment                *segment)
{
	g_return_if_fail (segment != NULL);

	segment_destroy_children (ce, segment);

	/* segment neighbours and parent may be invalid here,
	 * so we only can unset the hint */
	if (ce->priv->hint == segment)
		ce->priv->hint = NULL;
        if (ce->priv->hint2 == segment)
                ce->priv->hint2 = NULL;

	if (SEGMENT_IS_INVALID (segment))
		remove_invalid (ce, segment);

	context_unref (segment->context);

#ifdef ENABLE_DEBUG
	g_assert (!g_slist_find (ce->priv->invalid, segment));
	memset (segment, 1, sizeof (Segment));
#else
	g_slice_free (Segment, segment);
#endif
}

/**
 * container_context_starts_here:
 *
 * See child_starts_here().
 */
static gboolean
container_context_starts_here (GtkSourceContextEngine  *ce,
			       Segment                 *state,
			       DefinitionChild         *child_def,
			       LineInfo                *line,
			       gint                    *line_pos, /* bytes */
			       Segment                **new_state)
{
	Context *new_context;
	Segment *new_segment;
	gint match_end;
	ContextDefinition *definition = child_def->u.definition;

	g_assert (*line_pos <= line->byte_length);

	/* We can have a container context definition (i.e. the main
	 * language definition) without start_end.start. */
	if (definition->u.start_end.start == NULL)
		return FALSE;

	if (!_gtk_source_regex_match (definition->u.start_end.start,
				      line->text, line->byte_length, *line_pos))
	{
		return FALSE;
	}

	new_context = create_child_context (state->context, child_def, line->text);
	g_return_val_if_fail (new_context != NULL, FALSE);

	if (!can_apply_match (new_context, line, *line_pos, &match_end,
			      definition->u.start_end.start))
	{
		context_unref (new_context);
		return FALSE;
	}

	g_assert (match_end <= line->byte_length);

        segment_extend (state, line_pos_to_offset (line, match_end));
        new_segment = create_segment (ce, state, new_context,
				      line_pos_to_offset (line, *line_pos),
				      line_pos_to_offset (line, match_end),
				      TRUE,
				      ce->priv->hint2);

	/* This new context could end at the same position (i.e. have zero length),
	 * and then we get an infinite loop. We can't possibly know about it at this point
	 * (since we need to know that the context indeed *ends* here, and that's
	 * discovered only later) so we look at the previous sibling: if it's the same,
	 * and has zero length then we remove the segment. We do it this way instead of
	 * checking before creating the segment because it's more convenient. */
	if (*line_pos == match_end &&
	    new_segment->prev != NULL &&
	    new_segment->prev->context == new_segment->context &&
	    new_segment->prev->start_at == new_segment->prev->end_at &&
	    new_segment->prev->start_at == line_pos_to_offset (line, *line_pos))
	{
		segment_remove (ce, new_segment);
		return FALSE;
	}

	apply_sub_patterns (new_segment, line,
			    definition->u.start_end.start,
			    SUB_PATTERN_WHERE_START);
	*line_pos = match_end;
	*new_state = new_segment;
	ce->priv->hint2 = NULL;
	context_unref (new_context);
	return TRUE;
}

/**
 * simple_context_starts_here:
 *
 * See child_starts_here().
 */
static gboolean
simple_context_starts_here (GtkSourceContextEngine *ce,
			    Segment                *state,
			    DefinitionChild        *child_def,
			    LineInfo               *line,
			    gint                   *line_pos, /* bytes */
			    Segment               **new_state)
{
	gint match_end;
	Context *new_context;
	ContextDefinition *definition = child_def->u.definition;

	g_return_val_if_fail (definition->u.match != NULL, FALSE);

	g_assert (*line_pos <= line->byte_length);

	if (!_gtk_source_regex_match (definition->u.match,
				      line->text,
				      line->byte_length,
				      *line_pos))
	{
		return FALSE;
	}

	new_context = create_child_context (state->context, child_def, line->text);
	g_return_val_if_fail (new_context != NULL, FALSE);

	if (!can_apply_match (new_context, line, *line_pos, &match_end, definition->u.match))
	{
		context_unref (new_context);
		return FALSE;
	}

	/* If length of the match is zero, then we get zero-length segment and return to
	 * the same state, so it's an infinite loop. But, if this child ends parent, we
	 * do want to terminate parent. Still, if match is at the beginning of the parent
	 * then we get an infinite loop again, so we check that (NOTE it really should destroy
	 * parent context then, but then we again can get parent context be recreated here and
	 * so on). */
	if (*line_pos == match_end &&
	    (!CONTEXT_ENDS_PARENT (new_context) ||
		line_pos_to_offset (line, *line_pos) == state->start_at))
	{
		context_unref (new_context);
		return FALSE;
	}

	g_assert (match_end <= line->byte_length);
	segment_extend (state, line_pos_to_offset (line, match_end));

	if (*line_pos != match_end)
	{
		/* Normal non-zero-length match, create a child segment */
		Segment *new_segment;
		new_segment = create_segment (ce, state, new_context,
					      line_pos_to_offset (line, *line_pos),
					      line_pos_to_offset (line, match_end),
					      TRUE,
					      ce->priv->hint2);
		apply_sub_patterns (new_segment, line, definition->u.match, SUB_PATTERN_WHERE_DEFAULT);
		ce->priv->hint2 = new_segment;
	}

	/* Terminate parent if needed */
	if (CONTEXT_ENDS_PARENT (new_context))
	{
		do
		{
			ce->priv->hint2 = state;
			state = state->parent;
		}
		while (SEGMENT_ENDS_PARENT (state));
	}

	*line_pos = match_end;
	*new_state = state;
	context_unref (new_context);
	return TRUE;
}

/**
 * child_starts_here:
 * @ce: the engine.
 * @state: current state.
 * @child_def: the child.
 * @line: line to analyze.
 * @line_pos: the position inside @line, bytes.
 * @new_state: where to store the new state.
 *
 * Verifies if a context of the type in @curr_definition starts at
 * @line_pos in @line. If the contexts start here @new_state and
 * @line_pos are updated.
 *
 * Returns: %TRUE if the context starts here.
 */
static gboolean
child_starts_here (GtkSourceContextEngine  *ce,
		   Segment                 *state,
		   DefinitionChild         *child_def,
		   LineInfo                *line,
		   gint                    *line_pos,
		   Segment                **new_state)
{
	g_return_val_if_fail (child_def->resolved, FALSE);

	switch (child_def->u.definition->type)
	{
		case CONTEXT_TYPE_SIMPLE:
			return simple_context_starts_here (ce,
							   state,
							   child_def,
							   line,
							   line_pos,
							   new_state);
		case CONTEXT_TYPE_CONTAINER:
			return container_context_starts_here (ce,
							      state,
							      child_def,
							      line,
							      line_pos,
							      new_state);
		default:
			g_return_val_if_reached (FALSE);
	}
}

/**
 * segment_ends_here:
 * @state: the segment.
 * @line: analyzed line.
 * @pos: the position inside @line, bytes.
 *
 * Checks whether given segment ends at pos. Unlike
 * child_starts_here() it doesn't modify tree, it merely
 * calls regex_match() for the end regex.
 */
static gboolean
segment_ends_here (Segment  *state,
		   LineInfo *line,
		   gint      pos)
{
	g_assert (SEGMENT_IS_CONTAINER (state));

	return state->context->definition->u.start_end.end &&
		_gtk_source_regex_match (state->context->end,
					 line->text,
					 line->byte_length,
					 pos);
}

/**
 * ancestor_context_ends_here:
 * @state: current context.
 * @line: the line to analyze.
 * @line_pos: the position inside @line, bytes.
 *
 * Verifies if some ancestor context ends at the current position.
 * This function only checks conetxts and does not modify the tree,
 * it's used by ancestor_ends_here().
 *
 * Returns: the ancestor context that terminates here or %NULL.
 */
static Context *
ancestor_context_ends_here (Context  *state,
			    LineInfo *line,
			    gint      line_pos)
{
	Context *current_context;
	GSList *current_context_list;
	GSList *check_ancestors;
	Context *terminating_context;

	/* A context can be terminated by the parent if extend_parent is
	 * FALSE, so we need to verify the end of all the parents of
	 * not-extending contexts. The list is ordered by ascending
	 * depth. */
	check_ancestors = NULL;
	current_context = state;
	while (ANCESTOR_CAN_END_CONTEXT (current_context))
	{
		if (!CONTEXT_EXTENDS_PARENT (current_context))
			check_ancestors = g_slist_prepend (check_ancestors,
							   current_context->parent);
		current_context = current_context->parent;
	}

	/* The first context that ends here terminates its descendants. */
	terminating_context = NULL;
	current_context_list = check_ancestors;
	while (current_context_list != NULL)
	{
		current_context = current_context_list->data;

		if (current_context->end &&
		    _gtk_source_regex_is_resolved (current_context->end) &&
		    _gtk_source_regex_match (current_context->end,
					     line->text,
					     line->byte_length,
					     line_pos))
		{
			terminating_context = current_context;
			break;
		}

		current_context_list = current_context_list->next;
	}
	g_slist_free (check_ancestors);

	return terminating_context;
}

/**
 * ancestor_ends_here:
 * @state: current state.
 * @line: the line to analyze.
 * @line_pos: the position inside @line, bytes.
 * @new_state: where to store the new state.
 *
 * Verifies if some ancestor context ends at given position. If
 * state changed and @new_state is not %NULL, then the new state is stored
 * in @new_state, and descendants of @new_state are closed, so the
 * terminating segment becomes current state.
 *
 * Returns: %TRUE if an ancestor ends at the given position.
 */
static gboolean
ancestor_ends_here (Segment   *state,
		    LineInfo  *line,
		    gint       line_pos,
		    Segment  **new_state)
{
	Context *terminating_context;

	terminating_context = ancestor_context_ends_here (state->context, line, line_pos);

	if (new_state != NULL && terminating_context != NULL)
	{
		/* We have found a context that ends here, so we close
		 * all the descendants. terminating_segment will be
		 * closed by next next_segment() call from analyze_line. */
		Segment *current_segment = state;

		while (current_segment->context != terminating_context)
			current_segment = current_segment->parent;

		*new_state = current_segment;
		g_assert (*new_state != NULL);
	}

	return terminating_context != NULL;
}

/**
 * next_segment:
 * @ce: #GtkSourceContextEngine.
 * @state: current state.
 * @line: analyzed line.
 * @line_pos: position inside @line, bytes.
 * @new_state: where to store the new state.
 * @hint: child of @state used to optimize tree operations.
 *
 * Verifies if a context starts or ends in @line at @line_pos of after it.
 * If the contexts starts or ends here @new_state and @line_pos are updated.
 *
 * Returns: %FALSE is there are no more contexts in @line.
 */
static gboolean
next_segment (GtkSourceContextEngine  *ce,
	      Segment                 *state,
	      LineInfo                *line,
	      gint                    *line_pos,
	      Segment                **new_state)
{
	gint pos = *line_pos;

	g_assert (!ce->priv->hint2 || ce->priv->hint2->parent == state);
	g_assert (pos <= line->byte_length);

	while (pos <= line->byte_length)
	{
		DefinitionsIter def_iter;
		gboolean context_end_found;
		DefinitionChild *child_def;

		if (state->context->reg_all)
		{
			if (!_gtk_source_regex_match (state->context->reg_all,
						      line->text,
						      line->byte_length,
						      pos))
			{
				return FALSE;
			}

			_gtk_source_regex_fetch_pos_bytes (state->context->reg_all,
							   0, &pos, NULL);
		}

		/* Does an ancestor end here? */
		if (ANCESTOR_CAN_END_CONTEXT (state->context) &&
		    ancestor_ends_here (state, line, pos, new_state))
		{
			g_assert (pos <= line->byte_length);
			segment_extend (state, line_pos_to_offset (line, pos));
			*line_pos = pos;
			return TRUE;
		}

		/* Does the current context end here? */
		context_end_found = segment_ends_here (state, line, pos);

		/* Iter over the definitions we can find in the current
		 * context. */
		definition_iter_init (&def_iter, state->context->definition);
		while ((child_def = definition_iter_next (&def_iter)) != NULL)
		{
			gboolean try_this = TRUE;

			g_return_val_if_fail (child_def->resolved, FALSE);

			/* If the child definition does not extend the parent
			 * and the current context could end here we do not
			 * need to examine this child. */
			if (!HAS_OPTION (child_def->u.definition, EXTEND_PARENT) && context_end_found)
				try_this = FALSE;

			if (HAS_OPTION (child_def->u.definition, FIRST_LINE_ONLY) && line->start_at != 0)
				try_this = FALSE;

			if (HAS_OPTION (child_def->u.definition, ONCE_ONLY))
			{
				Segment *prev;

				for (prev = state->children; prev != NULL; prev = prev->next)
				{
					if (prev->context != NULL &&
					    prev->context->definition == child_def->u.definition)
					{
						try_this = FALSE;
						break;
					}
				}
			}

			if (try_this)
			{
				/* Does this child definition start a new
				 * context at the current position? */
				if (child_starts_here (ce, state, child_def,
						       line, &pos, new_state))
				{
					g_assert (pos <= line->byte_length);
					*line_pos = pos;
					definition_iter_destroy (&def_iter);
					return TRUE;
				}
			}

			/* This child does not start here, so we analyze
			 * another definition. */
		}
		definition_iter_destroy (&def_iter);

		if (context_end_found)
		{
			/* We have found that the current context could end
			 * here and that it cannot be extended by a child.
			 * Still, it may happen that parent context ends in
			 * the middle of the end regex match, apply_match()
			 * checks this. */
			if (apply_match (state, line, &pos, state->context->end, SUB_PATTERN_WHERE_END))
			{
				g_assert (pos <= line->byte_length);

				while (SEGMENT_ENDS_PARENT (state))
					state = state->parent;

				*new_state = state->parent;
				ce->priv->hint2 = state;
				*line_pos = pos;
				return TRUE;
			}
		}

		/* Nothing new at this position, go to next char. */
		pos = g_utf8_next_char (line->text + pos) - line->text;
	}

	return FALSE;
}

/**
 * check_line_end:
 * @state: current state.
 * @hint: child of @state used in analyze_line() and next_segment().
 *
 * Closes the contexts that cannot contain end of lines if needed.
 * Updates hint if new state is different from @state.
 *
 * Returns: the new state.
 */
static Segment *
check_line_end (GtkSourceContextEngine *ce,
		Segment                *state)
{
	Segment *current_segment;
	Segment *terminating_segment;

	g_assert (!ce->priv->hint2 || ce->priv->hint2->parent == state);

	/* A context can be terminated by the parent if extend_parent is
	 * FALSE, so we need to verify the end of all the parents of
	 * not-extending contexts. */
	terminating_segment = NULL;
	current_segment = state;

	while (current_segment != NULL)
	{
		if (SEGMENT_END_AT_LINE_END (current_segment))
			terminating_segment = current_segment;
		else if (!ANCESTOR_CAN_END_CONTEXT(current_segment->context))
			break;
		current_segment = current_segment->parent;
	}

	if (terminating_segment != NULL)
	{
		ce->priv->hint2 = terminating_segment;
		return terminating_segment->parent;
	}
	else
	{
		return state;
	}
}

static void
delete_zero_length_segments (GtkSourceContextEngine *ce,
			     GList                  *list)
{
	while (list != NULL)
	{
		Segment *s = list->data;

		if (s->start_at == s->end_at)
		{
			GList *l;

			for (l = list->next; l != NULL; )
			{
				GList *next = l->next;
				Segment *s2 = l->data;
				gboolean child = FALSE;

				while (s2 != NULL)
				{
					if (s2 == s)
					{
						child = TRUE;
						break;
					}

					s2 = s2->parent;
				}

				if (child)
					list = g_list_delete_link (list, l);

				l = next;
			}

			if (ce->priv->hint2 != NULL)
			{
				Segment *s2 = ce->priv->hint2;
				gboolean child = FALSE;

				while (s2 != NULL)
				{
					if (s2 == s)
					{
						child = TRUE;
						break;
					}

					s2 = s2->parent;
				}

				if (child)
					ce->priv->hint2 = s->parent;
			}

			segment_remove (ce, s);
		}

		list = g_list_delete_link (list, list);
	}
}

/**
 * analyze_line:
 * @ce: #GtkSourceContextEngine.
 * @state: the state at the beginning of line.
 * @line: the line.
 * @hint: a child of @state around start of line, to make it faster.
 *
 * Finds contexts at the line and updates the syntax tree on it.
 *
 * Returns: starting state at the next line.
 */
static Segment *
analyze_line (GtkSourceContextEngine *ce,
	      Segment                *state,
	      LineInfo               *line)
{
	gint line_pos = 0;
	GList *end_segments = NULL;
	GTimer *timer;

	g_assert (SEGMENT_IS_CONTAINER (state));

        if (ce->priv->hint2 == NULL || ce->priv->hint2->parent != state)
                ce->priv->hint2 = state->last_child;
        g_assert (!ce->priv->hint2 || ce->priv->hint2->parent == state);

	timer = g_timer_new ();

	/* Find the contexts in the line. */
	while (line_pos <= line->byte_length)
	{
		Segment *new_state = NULL;

		if (!next_segment (ce, state, line, &line_pos, &new_state))
			break;

		if (g_timer_elapsed (timer, NULL) * 1000 > MAX_TIME_FOR_ONE_LINE)
		{
			g_critical ("%s",
			            _("Highlighting a single line took too much time, "
				      "syntax highlighting will be disabled"));
			disable_syntax_analysis (ce);
			break;
		}

		g_assert (new_state != NULL);
		g_assert (SEGMENT_IS_CONTAINER (new_state));

		state = new_state;

                if (ce->priv->hint2 == NULL || ce->priv->hint2->parent != state)
                        ce->priv->hint2 = state->last_child;
                g_assert (!ce->priv->hint2 || ce->priv->hint2->parent == state);

		/* XXX this a temporary workaround for zero-length segments in the end
		 * of line. there are no zero-length segments in the middle because it goes
		 * into infinite loop in that case. */
		/* state may be extended later, so not all elements of new_segments
		 * really have zero length */
		if (state->start_at == line->char_length)
			end_segments = g_list_prepend (end_segments, state);
	}

	g_timer_destroy (timer);
	if (ce->priv->disabled)
		return NULL;

	/* Extend current state to the end of line. */
	segment_extend (state, line->start_at + line->char_length);
	g_assert (line_pos <= line->byte_length);

	/* Verify if we need to close the context because we are at
	 * the end of the line. */
	if (ANCESTOR_CAN_END_CONTEXT (state->context) ||
	    SEGMENT_END_AT_LINE_END (state))
	{
		state = check_line_end (ce, state);
	}

	/* Extend the segment to the beginning of next line. */
	g_assert (SEGMENT_IS_CONTAINER (state));
	segment_extend (state, NEXT_LINE_OFFSET (line));

	/* if it's the last line, don't bother with zero length segments */
	if (!line->eol_length)
		g_list_free (end_segments);
	else
		delete_zero_length_segments (ce, end_segments);

	CHECK_TREE (ce);

	return state;
}

/**
 * get_line_info:
 * @buffer: #GtkTextBuffer.
 * @line_start: iterator pointing to the beginning of line.
 * @line_end: iterator pointing to the beginning of next line or to the end
 * of this line if it's the last line in @buffer.
 * @line: #LineInfo structure to be filled.
 *
 * Retrieves line text from the buffer, finds line terminator and fills
 * @line structure.
 */
static void
get_line_info (GtkTextBuffer     *buffer,
	       const GtkTextIter *line_start,
	       const GtkTextIter *line_end,
	       LineInfo          *line)
{
	g_assert (!gtk_text_iter_equal (line_start, line_end));

	line->text = gtk_text_buffer_get_slice (buffer, line_start, line_end, TRUE);
	line->start_at = gtk_text_iter_get_offset (line_start);

	if (!gtk_text_iter_starts_line (line_end))
	{
		line->eol_length = 0;
		line->char_length = g_utf8_strlen (line->text, -1);
		line->byte_length = strlen (line->text);
	}
	else
	{
		gint eol_index, next_line_index;

		pango_find_paragraph_boundary (line->text, -1,
					       &eol_index,
					       &next_line_index);

		g_assert (eol_index < next_line_index);

		line->char_length = g_utf8_strlen (line->text, eol_index);
		line->eol_length = g_utf8_strlen (line->text + eol_index, -1);
		line->byte_length = eol_index;
	}

	g_assert (gtk_text_iter_get_offset (line_end) ==
			line->start_at + line->char_length + line->eol_length);
}

/**
 * line_info_destroy:
 * @line: #LineInfo.
 *
 * Destroys data allocated by get_line_info().
 */
static void
line_info_destroy (LineInfo *line)
{
	g_free (line->text);
}

/**
 * segment_tree_zero_len:
 * @ce: #GtkSoucreContextEngine.
 *
 * Erases syntax tree and sets root segment length to zero.
 * It's a shortcut for case when all the text is deleted from
 * the buffer.
 */
static void
segment_tree_zero_len (GtkSourceContextEngine *ce)
{
	Segment *root = ce->priv->root_segment;
	segment_destroy_children (ce, root);
	root->start_at = root->end_at = 0;
	CHECK_TREE (ce);
}

#ifdef ENABLE_CHECK_TREE
static Segment *
get_segment_at_offset_slow_ (Segment *segment,
			     gint     offset)
{
	Segment *child;

start:
	if (segment->parent == NULL && offset == segment->end_at)
		return segment;

	if (segment->start_at > offset)
	{
		g_assert (segment->parent != NULL);
		segment = segment->parent;
		goto start;
	}

	if (segment->start_at == offset)
	{
		if (segment->children != NULL && segment->children->start_at == offset)
		{
			segment = segment->children;
			goto start;
		}

		return segment;
	}

        if (segment->end_at <= offset && segment->parent != NULL)
	{
		if (segment->next != NULL)
		{
			if (segment->next->start_at > offset)
				return segment->parent;

			segment = segment->next;
		}
		else
		{
			segment = segment->parent;
		}

		goto start;
	}

	for (child = segment->children; child != NULL; child = child->next)
	{
		if (child->start_at == offset)
		{
			segment = child;
			goto start;
		}

		if (child->end_at <= offset)
			continue;

		if (child->start_at > offset)
			break;

		segment = child;
		goto start;
	}

	return segment;
}
#endif /* ENABLE_CHECK_TREE */

#define SEGMENT_IS_ZERO_LEN_AT(s,o) ((s)->start_at == (o) && (s)->end_at == (o))
#define SEGMENT_CONTAINS(s,o) ((s)->start_at <= (o) && (s)->end_at > (o))
#define SEGMENT_DISTANCE(s,o) (MIN (ABS ((s)->start_at - (o)), ABS ((s)->end_at - (o))))
static Segment *
get_segment_in_ (Segment *segment,
		 gint     offset)
{
	Segment *child;

	g_assert (segment->start_at <= offset && segment->end_at > offset);

	if (segment->children == NULL)
		return segment;

	if (segment->children == segment->last_child)
	{
		if (SEGMENT_IS_ZERO_LEN_AT (segment->children, offset))
			return segment->children;

		if (SEGMENT_CONTAINS (segment->children, offset))
			return get_segment_in_ (segment->children, offset);

		return segment;
	}

	if (segment->children->start_at > offset || segment->last_child->end_at < offset)
		return segment;

	if (SEGMENT_DISTANCE (segment->children, offset) >= SEGMENT_DISTANCE (segment->last_child, offset))
	{
		for (child = segment->children; child; child = child->next)
		{
			if (child->start_at > offset)
				return segment;

			if (SEGMENT_IS_ZERO_LEN_AT (child, offset))
				return child;

			if (SEGMENT_CONTAINS (child, offset))
				return get_segment_in_ (child, offset);
		}
	}
	else
	{
		for (child = segment->last_child; child; child = child->prev)
		{
			if (SEGMENT_IS_ZERO_LEN_AT (child, offset))
			{
				while (child->prev != NULL && SEGMENT_IS_ZERO_LEN_AT (child->prev, offset))
					child = child->prev;
				return child;
			}

			if (child->end_at <= offset)
				return segment;

			if (SEGMENT_CONTAINS (child, offset))
				return get_segment_in_ (child, offset);
		}
	}

	return segment;
}

/* assumes zero-length segments can't have children */
static Segment *
get_segment_ (Segment *segment,
	      gint     offset)
{
	if (segment->parent != NULL)
	{
		if (!SEGMENT_CONTAINS (segment->parent, offset))
			return get_segment_ (segment->parent, offset);
	}
	else
	{
		g_assert (offset >= segment->start_at);
		g_assert (offset <= segment->end_at);
	}

	if (SEGMENT_CONTAINS (segment, offset))
		return get_segment_in_ (segment, offset);

	if (SEGMENT_IS_ZERO_LEN_AT (segment, offset))
	{
		while (segment->prev != NULL && SEGMENT_IS_ZERO_LEN_AT (segment->prev, offset))
			segment = segment->prev;
		return segment;
	}

	if (offset < segment->start_at)
	{
		while (segment->prev != NULL && segment->prev->start_at > offset)
			segment = segment->prev;

		g_assert (!segment->prev || segment->prev->start_at <= offset);

		if (segment->prev == NULL)
			return segment->parent;

		if (segment->prev->end_at > offset)
			return get_segment_in_ (segment->prev, offset);

		if (segment->prev->end_at == offset)
		{
			if (SEGMENT_IS_ZERO_LEN_AT (segment->prev, offset))
			{
				segment = segment->prev;
				while (segment->prev != NULL && SEGMENT_IS_ZERO_LEN_AT (segment->prev, offset))
					segment = segment->prev;
				return segment;
			}

			return segment->parent;
		}

		/* segment->prev->end_at < offset */
		return segment->parent;
	}

	/* offset >= segment->end_at, not zero-length */

	while (segment->next != NULL)
	{
		if (SEGMENT_IS_ZERO_LEN_AT (segment->next, offset))
			return segment->next;

		if (segment->next->end_at > offset)
		{
			if (segment->next->start_at <= offset)
				return get_segment_in_ (segment->next, offset);
			else
				return segment->parent;
		}

		segment = segment->next;
	}

	return segment->parent;
}
#undef SEGMENT_IS_ZERO_LEN_AT
#undef SEGMENT_CONTAINS
#undef SEGMENT_DISTANCE

/**
 * get_segment_at_offset:
 * @ce: #GtkSoucreContextEngine.
 * @hint: segment to start search from or %NULL.
 * @offset: the offset, characters.
 *
 * Finds the deepest segment "at @offset".
 * More precisely, it returns toplevel segment if
 * @offset is equal to length of buffer; or non-zero-length
 * segment which contains character at @offset; or zero-length
 * segment at @offset. In case when there are several zero-length
 * segments, it returns the first one.
 */
static Segment *
get_segment_at_offset (GtkSourceContextEngine *ce,
		       Segment                *hint,
		       gint                    offset)
{
	Segment *result;

	if (offset == ce->priv->root_segment->end_at)
		return ce->priv->root_segment;

#ifdef ENABLE_DEBUG
	/* if you see this message (often), then something is
	 * wrong with the hints business, i.e. optimizations
	 * do not work quite like they should */
	if (hint == NULL || hint == ce->priv->root_segment)
	{
		static int c;
		g_print ("searching from root %d\n", ++c);
	}
#endif

	result = get_segment_ (hint ? hint : ce->priv->root_segment, offset);

#ifdef ENABLE_CHECK_TREE
	g_assert (result == get_segment_at_offset_slow_ (hint, offset));
#endif

	return result;
}

/**
 * segment_remove:
 * @ce: #GtkSoucreContextEngine.
 * @segment: segment to remove.
 *
 * Removes the segment from syntax tree and frees it.
 * It correctly updates parent's children list, not
 * like segment_destroy() where caller has to take care
 * of tree integrity.
 */
static void
segment_remove (GtkSourceContextEngine *ce,
		Segment                *segment)
{
	if (segment->next != NULL)
		segment->next->prev = segment->prev;
	else
		segment->parent->last_child = segment->prev;

	if (segment->prev != NULL)
		segment->prev->next = segment->next;
	else
		segment->parent->children = segment->next;

	/* if ce->priv->hint is being deleted, set it to some
	 * neighbour segment */
	if (ce->priv->hint == segment)
	{
		if (segment->next != NULL)
			ce->priv->hint = segment->next;
		else if (segment->prev != NULL)
			ce->priv->hint = segment->prev;
		else
			ce->priv->hint = segment->parent;
	}

        /* if ce->priv->hint2 is being deleted, set it to some
         * neighbour segment */
        if (ce->priv->hint2 == segment)
        {
                if (segment->next != NULL)
                        ce->priv->hint2 = segment->next;
                else if (segment->prev != NULL)
                        ce->priv->hint2 = segment->prev;
                else
                        ce->priv->hint2 = segment->parent;
        }

	segment_destroy (ce, segment);
}

static void
segment_erase_middle_ (GtkSourceContextEngine *ce,
		       Segment                *segment,
		       gint                    start,
		       gint                    end)
{
	Segment *new_segment, *child;
	SubPattern *sp;

	new_segment = segment_new (ce,
				   segment->parent,
				   segment->context,
				   end,
				   segment->end_at,
				   FALSE);
	segment->end_at = start;

	new_segment->next = segment->next;
	segment->next = new_segment;
	new_segment->prev = segment;

	if (new_segment->next != NULL)
		new_segment->next->prev = new_segment;
	else
		new_segment->parent->last_child = new_segment;

	child = segment->children;
	segment->children = NULL;
	segment->last_child = NULL;

	while (child != NULL)
	{
		Segment *append_to;
		Segment *next = child->next;

		if (child->start_at < start)
		{
			g_assert (child->end_at <= start);
			append_to = segment;
		}
		else
		{
			g_assert (child->start_at >= end);
			append_to = new_segment;
		}

		child->parent = append_to;

		if (append_to->last_child != NULL)
		{
			append_to->last_child->next = child;
			child->prev = append_to->last_child;
			child->next = NULL;
			append_to->last_child = child;
		}
		else
		{
			child->next = child->prev = NULL;
			append_to->last_child = child;
			append_to->children = child;
		}

		child = next;
	}

	sp = segment->sub_patterns;
	segment->sub_patterns = NULL;

	while (sp != NULL)
	{
		SubPattern *next = sp->next;
		Segment *append_to;

		if (sp->start_at < start)
		{
			sp->end_at = MIN (sp->end_at, start);
			append_to = segment;
		}
		else
		{
			g_assert (sp->end_at > end);
			sp->start_at = MAX (sp->start_at, end);
			append_to = new_segment;
		}

		sp->next = append_to->sub_patterns;
		append_to->sub_patterns = sp;

		sp = next;
	}

	CHECK_SEGMENT_CHILDREN (segment);
	CHECK_SEGMENT_CHILDREN (new_segment);
}

/**
 * segment_erase_range_:
 * @ce: #GtkSourceContextEngine.
 * @segment: the segment.
 * @start: start offset of range to erase, characters.
 * @end: end offset of range to erase, characters.
 *
 * Recurisvely removes segments from [@start, @end] interval
 * starting from @segment. If @segment belongs to the range,
 * or it's a zero-length segment at @end offset, and it's not
 * the toplevel segment, then it's removed from the tree.
 * If @segment intersects with the range (unless it's the toplevel
 * segment), then its ends are adjusted appropriately, and it's
 * split into two if it completely contains the range.
 */
static void
segment_erase_range_ (GtkSourceContextEngine *ce,
		      Segment                *segment,
		      gint                    start,
		      gint                    end)
{
	g_assert (start < end);

	if (segment->start_at == segment->end_at)
	{
		if (segment->start_at >= start && segment->start_at <= end)
			segment_remove (ce, segment);
		return;
	}

	if (segment->start_at > end || segment->end_at < start)
		return;

	if (segment->start_at >= start && segment->end_at <= end && segment->parent)
	{
		segment_remove (ce, segment);
		return;
	}

	if (segment->start_at == end)
	{
		Segment *child = segment->children;

		while (child != NULL && child->start_at == end)
		{
			Segment *next = child->next;
			segment_erase_range_ (ce, child, start, end);
			child = next;
		}
	}
	else if (segment->end_at == start)
	{
		Segment *child = segment->last_child;

		while (child != NULL && child->end_at == start)
		{
			Segment *prev = child->prev;
			segment_erase_range_ (ce, child, start, end);
			child = prev;
		}
	}
	else
	{
		Segment *child = segment->children;

		while (child != NULL)
		{
			Segment *next = child->next;
			segment_erase_range_ (ce, child, start, end);
			child = next;
		}
	}

	if (segment->sub_patterns != NULL)
	{
		SubPattern *sp;

		sp = segment->sub_patterns;
		segment->sub_patterns = NULL;

		while (sp != NULL)
		{
			SubPattern *next = sp->next;

			if (sp->start_at >= start && sp->end_at <= end)
				sub_pattern_free (sp);
			else
				segment_add_subpattern (segment, sp);

			sp = next;
		}
	}

	if (segment->parent != NULL)
	{
		/* Now all children and subpatterns are cleaned up,
		 * so we only need to split segment properly if its middle
		 * was erased. Otherwise, only ends need to be adjusted. */
		if (segment->start_at < start && segment->end_at > end)
		{
			segment_erase_middle_ (ce, segment, start, end);
		}
		else
		{
			g_assert ((segment->start_at >= start && segment->end_at > end) ||
				  (segment->start_at < start && segment->end_at <= end));

			if (segment->end_at > end)
			{
				/* If we erase the beginning, we need to clear
				 * is_start flag. */
				segment->start_at = end;
				segment->is_start = FALSE;
			}
			else
			{
				segment->end_at = start;
			}
		}
	}
}

/**
 * segment_merge:
 * @ce: #GtkSourceContextEngine.
 * @first: first segment.
 * @second: second segment.
 *
 * Merges adjacent segments @first and @second given
 * their contexts are equal.
 */
static void
segment_merge (GtkSourceContextEngine *ce,
	       Segment                *first,
	       Segment                *second)
{
	Segment *parent;

	if (first == second)
		return;

	g_assert (!SEGMENT_IS_INVALID (first));
	g_assert (first->context == second->context);
	g_assert (first->end_at == second->start_at);

	if (first->parent != second->parent)
		segment_merge (ce, first->parent, second->parent);

	parent = first->parent;

	g_assert (first->next == second);
	g_assert (first->parent == second->parent);
	g_assert (second != parent->children);

	if (second == parent->last_child)
		parent->last_child = first;
	first->next = second->next;
	if (second->next != NULL)
		second->next->prev = first;

	first->end_at = second->end_at;

	if (second->children != NULL)
	{
		Segment *child;

		for (child = second->children; child != NULL; child = child->next)
			child->parent = first;

		if (first->children == NULL)
		{
			g_assert (!first->last_child);
			first->children = second->children;
			first->last_child = second->last_child;
		}
		else
		{
			first->last_child->next = second->children;
			second->children->prev = first->last_child;
			first->last_child = second->last_child;
		}
	}

	if (second->sub_patterns != NULL)
	{
		if (first->sub_patterns == NULL)
		{
			first->sub_patterns = second->sub_patterns;
		}
		else
		{
			while (second->sub_patterns != NULL)
			{
				SubPattern *sp = second->sub_patterns;
				second->sub_patterns = sp->next;
				sp->next = first->sub_patterns;
				first->sub_patterns = sp;
			}
		}
	}

	second->children = NULL;
	second->last_child = NULL;
	second->sub_patterns = NULL;

	segment_destroy (ce, second);
}

/**
 * erase_segments:
 * @ce: #GtkSourceContextEngine.
 * @start: start offset of region to erase, characters.
 * @end: end offset of region to erase, characters.
 * @hint: segment around @start to make it faster.
 *
 * Erases all non-toplevel segments in the interval
 * [@start, @end]. Its action on the tree is roughly
 * equivalent to segment_erase_range_(ce->priv->root_segment, start, end)
 * (but that does not accept toplevel segment).
 */
static void
erase_segments (GtkSourceContextEngine *ce,
		gint                    start,
		gint                    end,
		Segment                *hint)
{
	Segment *root = ce->priv->root_segment;
	Segment *child, *hint_prev;

	if (root->children == NULL)
		return;

	if (hint == NULL)
		hint = ce->priv->hint;

	if (hint != NULL)
		while (hint != NULL && hint->parent != ce->priv->root_segment)
			hint = hint->parent;

	if (hint == NULL)
		hint = root->children;

	hint_prev = hint->prev;

	child = hint;
	while (child != NULL)
	{
		Segment *next = child->next;

		if (child->end_at < start)
		{
			child = next;

			if (next != NULL)
				ce->priv->hint = next;

			continue;
		}

		if (child->start_at > end)
		{
			ce->priv->hint = child;
			break;
		}

		segment_erase_range_ (ce, child, start, end);
		child = next;
	}

	child = hint_prev;
	while (child != NULL)
	{
		Segment *prev = child->prev;

		if (ce->priv->hint == NULL)
			ce->priv->hint = child;

		if (child->start_at > end)
		{
			child = prev;
			continue;
		}

		if (child->end_at < start)
		{
			break;
		}

		segment_erase_range_ (ce, child, start, end);
		child = prev;
	}

	CHECK_TREE (ce);
}

#define IS_BOM(c) (c == 0xFEFF)

/**
 * update_syntax:
 * @ce: #GtkSourceContextEngine.
 * @end: desired end of region to analyze or %NULL.
 * @time: maximal amount of time in milliseconds allowed to spend here
 * or 0 for 'unlimited'.
 *
 * Updates syntax tree. If @end is not %NULL, then it analyzes
 * (reanalyzes invalid areas in) region from start of buffer
 * to @end. Otherwise, it analyzes batch of text starting at
 * first invalid line.
 * In order to avoid blocking ui it uses a timer and stops
 * when time elapsed is greater than @time, so analyzed region is
 * not necessarily what's requested (unless @time is 0).
 */
/* TODO it must be refactored. */
static void
update_syntax (GtkSourceContextEngine *ce,
	       const GtkTextIter      *end,
	       gint                    time)
{
	GtkTextBuffer *buffer;
	GtkTextIter start_iter, end_iter;
	GtkTextIter line_start, line_end;
	Segment *state;
	Segment *invalid;
	gint start_offset, end_offset;
	gint line_start_offset, line_end_offset;
	gint analyzed_end;
	gboolean first_line = FALSE;
	GTimer *timer;

	buffer = ce->priv->buffer;
	state = ce->priv->root_segment;

	context_freeze (ce->priv->root_context);
	update_tree (ce);

	if (!gtk_text_buffer_get_char_count (buffer))
	{
		segment_tree_zero_len (ce);
		goto out;
	}

	invalid = get_invalid_segment (ce);

	if (invalid == NULL)
		goto out;

	if (end != NULL && invalid->start_at >= gtk_text_iter_get_offset (end))
		goto out;

	if (end != NULL)
	{
		end_offset = gtk_text_iter_get_offset (end);
		start_offset = MIN (end_offset, invalid->start_at);
	}
	else
	{
		start_offset = invalid->start_at;
		end_offset = gtk_text_buffer_get_char_count (buffer);
	}

	gtk_text_buffer_get_iter_at_offset (buffer, &start_iter, start_offset);
	gtk_text_buffer_get_iter_at_offset (buffer, &end_iter, end_offset);

	if (!gtk_text_iter_starts_line (&start_iter))
	{
		gtk_text_iter_set_line_offset (&start_iter, 0);
		start_offset = gtk_text_iter_get_offset (&start_iter);
	}

	if (!gtk_text_iter_starts_line (&end_iter))
	{
		gtk_text_iter_forward_line (&end_iter);
		end_offset = gtk_text_iter_get_offset (&end_iter);
	}

	if (0 == start_offset)
	{
		gunichar c;

		first_line = TRUE;

		/* If it is the first line and it starts with BOM, skip it
		 * since regexes in lang files do not take it into account */
		c = gtk_text_iter_get_char (&start_iter);
		if (IS_BOM (c))
		{
			gtk_text_iter_forward_char (&start_iter);
			start_offset = gtk_text_iter_get_offset (&start_iter);
		}
	}

	/* This happens after deleting all text on last line. */
	if (start_offset == end_offset)
	{
		g_assert (end_offset == gtk_text_buffer_get_char_count (buffer));
		g_assert (g_slist_length (ce->priv->invalid) == 1);
		segment_remove (ce, invalid);
		CHECK_TREE (ce);
		goto out;
	}


	/* Main loop */

	line_start = start_iter;
	line_start_offset = start_offset;
	line_end = line_start;
	gtk_text_iter_forward_line (&line_end);
	line_end_offset = gtk_text_iter_get_offset (&line_end);
	analyzed_end = line_end_offset;

	timer = g_timer_new ();

	while (TRUE)
	{
		LineInfo line;
		gboolean next_line_invalid = FALSE;
		gboolean need_invalidate_next = FALSE;

		/* Last buffer line. */
		if (line_start_offset == line_end_offset)
		{
			g_assert (line_start_offset == gtk_text_buffer_get_char_count (buffer));
			break;
		}

		/* Analyze the line */
		erase_segments (ce, line_start_offset, line_end_offset, ce->priv->hint);
		get_line_info (buffer, &line_start, &line_end, &line);

#ifdef ENABLE_CHECK_TREE
		{
			Segment *inv = get_invalid_segment (ce);
			g_assert (inv == NULL || inv->start_at >= line_end_offset);
		}
#endif

		if (first_line)
		{
			state = ce->priv->root_segment;
		}
		else
		{
			state = get_segment_at_offset (ce,
						       ce->priv->hint ? ce->priv->hint : state,
						       line_start_offset - 1);
		}

		g_assert (state->context != NULL);

		ce->priv->hint2 = ce->priv->hint;

		if (ce->priv->hint2 != NULL && ce->priv->hint2->parent != state)
			ce->priv->hint2 = NULL;

		state = analyze_line (ce, state, &line);

		/* At this point analyze_line() could have disabled highlighting */
		if (ce->priv->disabled)
			return;

#ifdef ENABLE_CHECK_TREE
		{
			Segment *inv = get_invalid_segment (ce);
			g_assert (inv == NULL || inv->start_at >= line_end_offset);
		}
#endif

		/* XXX this is wrong */
		/* I don't know anymore why it's wrong, I guess it means
		 * "may be inefficient" */
		if (ce->priv->hint2 != NULL)
			ce->priv->hint = ce->priv->hint2;
		else
			ce->priv->hint = state;

		line_info_destroy (&line);

		gtk_source_region_add_subregion (ce->priv->refresh_region, &line_start, &line_end);
		analyzed_end = line_end_offset;
		invalid = get_invalid_segment (ce);

		if (invalid != NULL)
		{
			GtkTextIter iter;

			gtk_text_buffer_get_iter_at_offset (buffer, &iter, invalid->start_at);
			gtk_text_iter_set_line_offset (&iter, 0);

			if (gtk_text_iter_get_offset (&iter) == line_end_offset)
				next_line_invalid = TRUE;
		}

		if (!next_line_invalid)
		{
			Segment *old_state, *hint;

			hint = ce->priv->hint ? ce->priv->hint : state;
			old_state = get_segment_at_offset (ce, hint, line_end_offset);

			/* We can merge old and new stuff if: contexts are the same,
			 * and the segment on the next line is continuation of the
			 * segment from previous line. */
			if (old_state != state &&
			    (old_state->context != state->context || state->is_start))
			{
				need_invalidate_next = TRUE;
				next_line_invalid = TRUE;
			}
			else
			{
				segment_merge (ce, state, old_state);
				CHECK_TREE (ce);
			}
		}

		if ((time != 0 && g_timer_elapsed (timer, NULL) * 1000 > time) ||
		    line_end_offset >= end_offset ||
		    (invalid == NULL && !next_line_invalid))
		{
			if (need_invalidate_next)
				insert_range (ce, line_end_offset, 0);
			break;
		}

		if (next_line_invalid)
		{
			line_start_offset = line_end_offset;
			line_start = line_end;
			gtk_text_iter_forward_line (&line_end);
			line_end_offset = gtk_text_iter_get_offset (&line_end);
		}
		else
		{
			gtk_text_buffer_get_iter_at_offset (buffer, &line_start, invalid->start_at);
			gtk_text_iter_set_line_offset (&line_start, 0);
			line_start_offset = gtk_text_iter_get_offset (&line_start);
			line_end = line_start;
			gtk_text_iter_forward_line (&line_end);
			line_end_offset = gtk_text_iter_get_offset (&line_end);
		}

		first_line = (0 == line_start_offset);
	}

	if (analyzed_end == gtk_text_buffer_get_char_count (buffer))
	{
		g_assert (g_slist_length (ce->priv->invalid) <= 1);

		if (ce->priv->invalid != NULL)
		{
			invalid = get_invalid_segment (ce);
			segment_remove (ce, invalid);
			CHECK_TREE (ce);
		}
	}

	if (!all_analyzed (ce))
		install_idle_worker (ce);

	gtk_text_iter_set_offset (&end_iter, analyzed_end);

	refresh_range (ce, &start_iter, &end_iter);

	PROFILE (g_print ("analyzed %d chars from %d to %d in %fms\n",
			  analyzed_end - start_offset, start_offset, analyzed_end,
			  g_timer_elapsed (timer, NULL) * 1000));

	g_timer_destroy (timer);

out:
	/* must call context_thaw, so this is the only return point */
	context_thaw (ce->priv->root_context);
}


/* DEFINITIONS MANAGEMENT ------------------------------------------------- */

static DefinitionChild *
definition_child_new (ContextDefinition *definition,
		      const gchar       *child_id,
		      const gchar       *style,
		      gboolean           override_style,
		      gboolean           is_ref_all,
		      gboolean           original_ref)
{
	DefinitionChild *ch;

	g_return_val_if_fail (child_id != NULL, NULL);

	ch = g_slice_new (DefinitionChild);

	if (original_ref)
		ch->u.id = g_strdup_printf ("@%s", child_id);
	else
		ch->u.id = g_strdup (child_id);

	ch->style = g_strdup (style);
	ch->is_ref_all = is_ref_all;
	ch->resolved = FALSE;
	ch->override_style = override_style;
	ch->override_style_deep = (override_style && style == NULL);

	definition->children = g_slist_append (definition->children, ch);

	return ch;
}

static void
definition_child_free (DefinitionChild *ch)
{
	if (!ch->resolved)
		g_free (ch->u.id);
	g_free (ch->style);

#ifdef ENABLE_DEBUG
	memset (ch, 1, sizeof (DefinitionChild));
#else
	g_slice_free (DefinitionChild, ch);
#endif
}

static GSList *
copy_context_classes (GSList *context_classes)
{
	GSList *ret = NULL;

	while (context_classes)
	{
		ret = g_slist_prepend (ret, gtk_source_context_class_copy (context_classes->data));
		context_classes = g_slist_next (context_classes);
	}

	return g_slist_reverse (ret);
}

static ContextDefinition *
context_definition_new (const gchar            *id,
			ContextType             type,
			const gchar            *match,
			const gchar            *start,
			const gchar            *end,
			const gchar            *style,
			GSList                 *context_classes,
			GtkSourceContextFlags   flags,
			GError                **error)
{
	ContextDefinition *definition;
	gboolean regex_error = FALSE;
	gboolean unresolved_error = FALSE;

	g_return_val_if_fail (id != NULL, NULL);

	switch (type)
	{
		case CONTEXT_TYPE_SIMPLE:
			g_return_val_if_fail (match != NULL, NULL);
			g_return_val_if_fail (!end && !start, NULL);
			break;
		case CONTEXT_TYPE_CONTAINER:
			g_return_val_if_fail (!match, NULL);
			g_return_val_if_fail (!end || start, NULL);
			break;
		default:
			g_assert_not_reached ();
	}

	definition = g_slice_new0 (ContextDefinition);

	if (match != NULL)
	{
		definition->u.match = _gtk_source_regex_new (match, G_REGEX_ANCHORED, error);

		if (definition->u.match == NULL)
		{
			regex_error = TRUE;
		}
		else if (!_gtk_source_regex_is_resolved (definition->u.match))
		{
			regex_error = TRUE;
			unresolved_error = TRUE;
			_gtk_source_regex_unref (definition->u.match);
			definition->u.match = NULL;
		}
	}

	if (start != NULL)
	{
		definition->u.start_end.start = _gtk_source_regex_new (start, G_REGEX_ANCHORED, error);

		if (definition->u.start_end.start == NULL)
		{
			regex_error = TRUE;
		}
		else if (!_gtk_source_regex_is_resolved (definition->u.start_end.start))
		{
			regex_error = TRUE;
			unresolved_error = TRUE;
			_gtk_source_regex_unref (definition->u.start_end.start);
			definition->u.start_end.start = NULL;
		}
	}

	if (end != NULL && !regex_error)
	{
		definition->u.start_end.end = _gtk_source_regex_new (end, G_REGEX_ANCHORED, error);

		if (definition->u.start_end.end == NULL)
			regex_error = TRUE;
	}

	if (unresolved_error)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_START_REF,
			     _("context “%s” cannot contain a \\%%{...@start} command"),
			     id);
		regex_error = TRUE;
	}

	if (regex_error)
	{
		g_slice_free (ContextDefinition, definition);
		return NULL;
	}

	definition->ref_count = 1;
	definition->id = g_strdup (id);
	definition->default_style = g_strdup (style);
	definition->type = type;
	definition->flags = flags;
	definition->children = NULL;
	definition->sub_patterns = NULL;
	definition->n_sub_patterns = 0;

	definition->context_classes = copy_context_classes (context_classes);

	return definition;
}

static ContextDefinition *
context_definition_ref (ContextDefinition *definition)
{
	g_return_val_if_fail (definition != NULL, NULL);
	definition->ref_count += 1;
	return definition;
}

static void
context_definition_unref (ContextDefinition *definition)
{
	GSList *sub_pattern_list;

	if (definition == NULL || --definition->ref_count != 0)
		return;

	switch (definition->type)
	{
		case CONTEXT_TYPE_SIMPLE:
			_gtk_source_regex_unref (definition->u.match);
			break;
		case CONTEXT_TYPE_CONTAINER:
			_gtk_source_regex_unref (definition->u.start_end.start);
			_gtk_source_regex_unref (definition->u.start_end.end);
			break;
		default:
			g_assert_not_reached ();
	}

	sub_pattern_list = definition->sub_patterns;
	while (sub_pattern_list != NULL)
	{
		SubPatternDefinition *sp_def = sub_pattern_list->data;
#ifdef NEED_DEBUG_ID
		g_free (sp_def->id);
#endif
		g_free (sp_def->style);
		if (sp_def->is_named)
			g_free (sp_def->u.name);

		g_slist_free_full (sp_def->context_classes,
		                   (GDestroyNotify)gtk_source_context_class_free);

		g_slice_free (SubPatternDefinition, sp_def);
		sub_pattern_list = sub_pattern_list->next;
	}
	g_slist_free (definition->sub_patterns);

	g_free (definition->id);
	g_free (definition->default_style);
	_gtk_source_regex_unref (definition->reg_all);

	g_slist_free_full (definition->context_classes,
	                   (GDestroyNotify)gtk_source_context_class_free);

	g_slist_free_full (definition->children, (GDestroyNotify)definition_child_free);
	g_slice_free (ContextDefinition, definition);
}

static void
definition_iter_init (DefinitionsIter   *iter,
		      ContextDefinition *definition)
{
	iter->children_stack = g_slist_prepend (NULL, definition->children);
}

static void
definition_iter_destroy (DefinitionsIter *iter)
{
	g_slist_free (iter->children_stack);
}

static DefinitionChild *
definition_iter_next (DefinitionsIter *iter)
{
	GSList *children_list;

	if (iter->children_stack == NULL)
		return NULL;

	children_list = iter->children_stack->data;
	if (children_list == NULL)
	{
		iter->children_stack = g_slist_delete_link (iter->children_stack,
							    iter->children_stack);
		return definition_iter_next (iter);
	}
	else
	{
		DefinitionChild *curr_child = children_list->data;
		ContextDefinition *definition = curr_child->u.definition;

		g_return_val_if_fail (curr_child->resolved, NULL);

		children_list = g_slist_next (children_list);
		iter->children_stack->data = children_list;

		if (curr_child->is_ref_all)
		{
			iter->children_stack = g_slist_prepend (iter->children_stack,
								definition->children);
			return definition_iter_next (iter);
		}
		else
		{
			return curr_child;
		}
	}
}

gboolean
_gtk_source_context_data_define_context (GtkSourceContextData   *ctx_data,
					 const gchar            *id,
					 const gchar            *parent_id,
					 const gchar            *match_regex,
					 const gchar            *start_regex,
					 const gchar            *end_regex,
					 const gchar            *style,
					 GSList                 *context_classes,
					 GtkSourceContextFlags   flags,
					 GError                **error)
{
	ContextDefinition *definition, *parent = NULL;
	ContextType type;
	gchar *original_id;
	gboolean wrong_args = FALSE;

	g_return_val_if_fail (ctx_data != NULL, FALSE);
	g_return_val_if_fail (id != NULL, FALSE);

	/* If the id is already present in the hashtable it is a duplicate,
	 * so we report the error (probably there is a duplicate id in the
	 * XML lang file) */
	if (gtk_source_context_data_lookup (ctx_data, id) != NULL)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_DUPLICATED_ID,
			     _("duplicated context id “%s”"), id);
		return FALSE;
	}

	if (match_regex != NULL)
		type = CONTEXT_TYPE_SIMPLE;
	else
		type = CONTEXT_TYPE_CONTAINER;

	/* Check if the arguments passed are exactly what we expect, no more, no less. */
	switch (type)
	{
		case CONTEXT_TYPE_SIMPLE:
			if (start_regex != NULL || end_regex != NULL)
				wrong_args = TRUE;
			break;
		case CONTEXT_TYPE_CONTAINER:
			g_assert (match_regex == NULL);
			break;
		default:
			g_assert_not_reached ();
	}

	if (wrong_args)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_ARGS,
			     /* do not translate, parser should take care of this */
			     "insufficient or redundant arguments creating "
			     "the context '%s'", id);
		return FALSE;
	}

	if (parent_id == NULL)
	{
		parent = NULL;
	}
	else
	{
		parent = gtk_source_context_data_lookup (ctx_data, parent_id);
		g_return_val_if_fail (parent != NULL, FALSE);
	}

	definition = context_definition_new (id, type, match_regex,
					     start_regex, end_regex, style,
					     context_classes,
					     flags, error);
	if (definition == NULL)
		return FALSE;

	g_hash_table_insert (ctx_data->definitions, g_strdup (id), definition);
	original_id = g_strdup_printf ("@%s", id);
	g_hash_table_insert (ctx_data->definitions, original_id,
			     context_definition_ref (definition));

	if (parent != NULL)
		definition_child_new (parent, id, NULL, FALSE, FALSE, FALSE);

	return TRUE;
}

gboolean
_gtk_source_context_data_add_sub_pattern (GtkSourceContextData  *ctx_data,
					  const gchar           *id,
					  const gchar           *parent_id,
					  const gchar           *name,
					  const gchar           *where,
					  const gchar           *style,
					  GSList                *context_classes,
					  GError               **error)
{
	ContextDefinition *parent;
	SubPatternDefinition *sp_def;
	SubPatternWhere where_num;
	gint number;

	g_return_val_if_fail (ctx_data != NULL, FALSE);
	g_return_val_if_fail (id != NULL, FALSE);
	g_return_val_if_fail (parent_id != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	/* If the id is already present in the hashtable it is a duplicate,
	 * so we report the error (probably there is a duplicate id in the
	 * XML lang file) */
	if (gtk_source_context_data_lookup (ctx_data, id) != NULL)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_DUPLICATED_ID,
			     _("duplicated context id “%s”"), id);
		return FALSE;
	}

	parent = gtk_source_context_data_lookup (ctx_data, parent_id);
	g_return_val_if_fail (parent != NULL, FALSE);

	if (!where || !where[0] || !strcmp (where, "default"))
		where_num = SUB_PATTERN_WHERE_DEFAULT;
	else if (!strcmp (where, "start"))
		where_num = SUB_PATTERN_WHERE_START;
	else if (!strcmp (where, "end"))
		where_num = SUB_PATTERN_WHERE_END;
	else
		where_num = (SubPatternWhere) -1;

	if ((parent->type == CONTEXT_TYPE_SIMPLE && where_num != SUB_PATTERN_WHERE_DEFAULT) ||
	    (parent->type == CONTEXT_TYPE_CONTAINER && where_num == SUB_PATTERN_WHERE_DEFAULT))
	{
		where_num = (SubPatternWhere) -1;
	}

	if (where_num == (SubPatternWhere) -1)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_WHERE,
			     /* do not translate, parent takes care of this */
			     "invalid location ('%s') for sub pattern '%s'",
			     where, id);
		return FALSE;
	}

	sp_def = g_slice_new (SubPatternDefinition);
#ifdef NEED_DEBUG_ID
	sp_def->id = g_strdup (id);
#endif
	sp_def->style = g_strdup (style);
	sp_def->where = where_num;
	number = _gtk_source_string_to_int (name);

	if (number < 0)
	{
		sp_def->is_named = TRUE;
		sp_def->u.name = g_strdup (name);
	}
	else
	{
		sp_def->is_named = FALSE;
		sp_def->u.num = number;
	}

	parent->sub_patterns = g_slist_append (parent->sub_patterns, sp_def);
	sp_def->index = parent->n_sub_patterns++;

	sp_def->context_classes = copy_context_classes (context_classes);

	return TRUE;
}

/**
 * context_is_pure_container:
 * @def: context definition.
 *
 * Checks whether context is a container with no start regex.
 * References to such contexts are implicitly translated to
 * wildcard references (context_id:*).
 */
static gboolean
context_is_pure_container (ContextDefinition *def)
{
	return def->type == CONTEXT_TYPE_CONTAINER &&
		def->u.start_end.start == NULL;
}

gboolean
_gtk_source_context_data_add_ref (GtkSourceContextData        *ctx_data,
				  const gchar                 *parent_id,
				  const gchar                 *ref_id,
				  GtkSourceContextRefOptions   options,
				  const gchar                 *style,
				  gboolean                     all,
				  GError                     **error)
{
	ContextDefinition *parent;
	ContextDefinition *ref;
	gboolean override_style = FALSE;

	g_return_val_if_fail (parent_id != NULL, FALSE);
	g_return_val_if_fail (ref_id != NULL, FALSE);
	g_return_val_if_fail (ctx_data != NULL, FALSE);

	ref = gtk_source_context_data_lookup (ctx_data, ref_id);
	parent = gtk_source_context_data_lookup (ctx_data, parent_id);
	g_return_val_if_fail (parent != NULL, FALSE);

	if (parent->type != CONTEXT_TYPE_CONTAINER)
	{
		g_set_error (error,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_PARENT,
			     /* do not translate, parent takes care of this */
			     "invalid parent type for the context '%s'",
			     ref_id);
		return FALSE;
	}

	if (ref != NULL && context_is_pure_container (ref))
		all = TRUE;

	if (all && (options & (GTK_SOURCE_CONTEXT_IGNORE_STYLE | GTK_SOURCE_CONTEXT_OVERRIDE_STYLE)))
	{
		g_set_error (error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_STYLE,
			     _("style override used with wildcard context reference"
			       " in language “%s” in ref “%s”"),
			     ctx_data->lang->priv->id, ref_id);
		return FALSE;
	}

	if (options & (GTK_SOURCE_CONTEXT_IGNORE_STYLE | GTK_SOURCE_CONTEXT_OVERRIDE_STYLE))
		override_style = TRUE;

	definition_child_new (parent, ref_id, style, override_style, all,
			      (options & GTK_SOURCE_CONTEXT_REF_ORIGINAL) != 0);

	return TRUE;
}

/**
 * resolve_reference:
 *
 * Checks whether all children of a context definition refer to valid
 * contexts. Called from _gtk_source_context_data_finish_parse.
 */
struct ResolveRefData {
	GtkSourceContextData *ctx_data;
	GError *error;
};

static void
resolve_reference (G_GNUC_UNUSED const gchar *id,
		   ContextDefinition         *definition,
		   gpointer                   user_data)
{
	GSList *l;

	struct ResolveRefData *data = user_data;

	if (data->error != NULL)
		return;

	for (l = definition->children; l != NULL && data->error == NULL; l = l->next)
	{
		ContextDefinition *ref;
		DefinitionChild *child_def = l->data;

		if (child_def->resolved)
			continue;

		ref = gtk_source_context_data_lookup (data->ctx_data, child_def->u.id);

		if (ref != NULL)
		{
			g_free (child_def->u.id);
			child_def->u.definition = ref;
			child_def->resolved = TRUE;

			if (context_is_pure_container (ref))
			{
				if (child_def->override_style)
				{
					g_set_error (&data->error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
						     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_STYLE,
						     _("style override used with wildcard context reference"
						       " in language “%s” in ref “%s”"),
						     data->ctx_data->lang->priv->id, ref->id);
				}
				else
				{
					child_def->is_ref_all = TRUE;
				}
			}
		}
		else
		{
			g_set_error (&data->error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
				     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_REF,
				     _("invalid context reference “%s”"), child_def->u.id);
		}
	}
}

static gboolean
process_replace (GtkSourceContextData  *ctx_data,
		 const gchar           *id,
		 const gchar           *replace_with,
		 GError               **error)
{
	ContextDefinition *to_replace, *new;

	to_replace = gtk_source_context_data_lookup (ctx_data, id);

	if (to_replace == NULL)
	{
		g_set_error (error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_REF,
			     _("unknown context “%s”"), id);
		return FALSE;
	}

	new = gtk_source_context_data_lookup (ctx_data, replace_with);

	if (new == NULL)
	{
		g_set_error (error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_INVALID_REF,
			     _("unknown context “%s”"), replace_with);
		return FALSE;
	}

	g_hash_table_insert (ctx_data->definitions, g_strdup (id), context_definition_ref (new));

	return TRUE;
}

GtkSourceContextReplace *
_gtk_source_context_replace_new	(const gchar *to_replace_id,
				 const gchar *replace_with_id)
{
	GtkSourceContextReplace *repl;

	g_return_val_if_fail (to_replace_id != NULL, NULL);
	g_return_val_if_fail (replace_with_id != NULL, NULL);

	repl = g_slice_new (GtkSourceContextReplace);
	repl->id = g_strdup (to_replace_id);
	repl->replace_with = g_strdup (replace_with_id);

	return repl;
}

void
_gtk_source_context_replace_free (GtkSourceContextReplace *repl)
{
	if (repl != NULL)
	{
		g_free (repl->id);
		g_free (repl->replace_with);
		g_slice_free (GtkSourceContextReplace, repl);
	}
}

/**
 * _gtk_source_context_data_finish_parse:
 * @ctx_data: #GtkSourceContextData.
 * @overrides: list of #GtkSourceContextOverride objects.
 * @error: error structure to be filled in when failed.
 *
 * Checks all context references and applies overrides. Lang file may
 * use cross-references between contexts, e.g. context A may include
 * context B, and context B in turn include context A. Hence during
 * parsing it just records referenced context id, and then it needs to
 * check the references and replace them with actual context definitions
 * (which in turn may be overridden using <override> or <replace> tags).
 * May be called any number of times, must be called after parsing is
 * done.
 *
 * Returns: %TRUE on success, %FALSE if there were unresolved
 * references.
 */
gboolean
_gtk_source_context_data_finish_parse (GtkSourceContextData  *ctx_data,
				       GList                 *overrides,
				       GError               **error)
{
	struct ResolveRefData data;
	gchar *root_id;
	ContextDefinition *main_definition;

	g_return_val_if_fail (ctx_data != NULL, FALSE);
	g_return_val_if_fail (ctx_data->lang != NULL, FALSE);
	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	while (overrides != NULL)
	{
		GtkSourceContextReplace *repl = overrides->data;

		g_return_val_if_fail (repl != NULL, FALSE);

		if (!process_replace (ctx_data, repl->id, repl->replace_with, error))
			return FALSE;

		overrides = overrides->next;
	}

	data.ctx_data = ctx_data;
	data.error = NULL;

	g_hash_table_foreach (ctx_data->definitions, (GHFunc) resolve_reference, &data);

	if (data.error != NULL)
	{
		g_propagate_error (error, data.error);
		return FALSE;
	}

	/* Sanity check: user may have screwed up the files by now (#485661) */
	root_id = g_strdup_printf ("%s:%s", ctx_data->lang->priv->id, ctx_data->lang->priv->id);
	main_definition = gtk_source_context_data_lookup (ctx_data, root_id);
	g_free (root_id);

	if (main_definition == NULL)
	{
		g_set_error (error, GTK_SOURCE_CONTEXT_ENGINE_ERROR,
			     GTK_SOURCE_CONTEXT_ENGINE_ERROR_BAD_FILE,
			     _("Missing main language "
			       "definition (id = \"%s\".)"),
			     ctx_data->lang->priv->id);
		return FALSE;
	}

	return TRUE;
}

static void
add_escape_ref (ContextDefinition    *definition,
		GtkSourceContextData *ctx_data)
{
	GError *error = NULL;

	if (definition->type != CONTEXT_TYPE_CONTAINER)
		return;

	_gtk_source_context_data_add_ref (ctx_data, definition->id,
					  "gtk-source-context-engine-escape",
					  0, NULL, FALSE, &error);

	if (error)
		goto out;

	_gtk_source_context_data_add_ref (ctx_data, definition->id,
					  "gtk-source-context-engine-line-escape",
					  0, NULL, FALSE, &error);

out:
	if (error)
	{
		g_warning ("%s", error->message);
		g_clear_error (&error);
	}
}

static void
prepend_definition (G_GNUC_UNUSED gchar  *id,
		    ContextDefinition    *definition,
		    GSList              **list)
{
	*list = g_slist_prepend (*list, definition);
}

/* Only for lang files version 1, do not use it */
/* It's called after lang file is parsed. It creates two special contexts
   contexts and puts them into every container context defined. These contexts
   are 'x.' and 'x$', where 'x' is the escape char. In this way, patterns from
   lang files are matched only if match doesn't start with escaped char, and
   escaped char in the end of line means that the current contexts extends to the
   next line. */
void
_gtk_source_context_data_set_escape_char (GtkSourceContextData *ctx_data,
					  gunichar              escape_char)
{
	GError *error = NULL;
	char buf[10];
	gint len;
	char *escaped, *pattern;
	GSList *definitions = NULL;

	g_return_if_fail (ctx_data != NULL);
	g_return_if_fail (escape_char != 0);

	len = g_unichar_to_utf8 (escape_char, buf);
	g_return_if_fail (len > 0);

	escaped = g_regex_escape_string (buf, 1);
	pattern = g_strdup_printf ("%s.", escaped);

	g_hash_table_foreach (ctx_data->definitions, (GHFunc) prepend_definition, &definitions);
	definitions = g_slist_reverse (definitions);

	if (!_gtk_source_context_data_define_context (ctx_data, "gtk-source-context-engine-escape",
						      NULL, pattern, NULL, NULL, NULL, NULL,
						      GTK_SOURCE_CONTEXT_EXTEND_PARENT,
						      &error))
		goto out;

	g_free (pattern);
	pattern = g_strdup_printf ("%s$", escaped);

	if (!_gtk_source_context_data_define_context (ctx_data, "gtk-source-context-engine-line-escape",
						      NULL, NULL, pattern, "^", NULL, NULL,
						      GTK_SOURCE_CONTEXT_EXTEND_PARENT,
						      &error))
		goto out;

	g_slist_foreach (definitions, (GFunc) add_escape_ref, ctx_data);

out:
	if (error)
	{
		g_warning ("%s", error->message);
		g_clear_error (&error);
	}

	g_free (pattern);
	g_free (escaped);
	g_slist_free (definitions);
}


/* DEBUG CODE ------------------------------------------------------------- */

#ifdef ENABLE_CHECK_TREE
static void
check_segment (GtkSourceContextEngine *ce,
	       Segment                *segment)
{
	Segment *child;

	g_assert (segment != NULL);
	g_assert (segment->start_at <= segment->end_at);
	g_assert (!segment->next || segment->next->start_at >= segment->end_at);

	if (SEGMENT_IS_INVALID (segment))
		g_assert (g_slist_find (ce->priv->invalid, segment) != NULL);
	else
		g_assert (g_slist_find (ce->priv->invalid, segment) == NULL);

	if (segment->children != NULL)
		g_assert (!SEGMENT_IS_INVALID (segment) && SEGMENT_IS_CONTAINER (segment));

	for (child = segment->children; child != NULL; child = child->next)
	{
		g_assert (child->parent == segment);
		g_assert (child->start_at >= segment->start_at);
		g_assert (child->end_at <= segment->end_at);
		g_assert (child->prev || child == segment->children);
		g_assert (child->next || child == segment->last_child);
		check_segment (ce, child);
	}
}

struct CheckContextData {
	Context *parent;
	ContextDefinition *definition;
};

static void
check_context_hash_cb (const char *text,
		       Context    *context,
		       gpointer    user_data)
{
	struct CheckContextData *data = user_data;

	g_assert (text != NULL);
	g_assert (context != NULL);
	g_assert (context->definition == data->definition);
	g_assert (context->parent == data->parent);
}

static void
check_context (Context *context)
{
	ContextPtr *ptr;

	for (ptr = context->children; ptr != NULL; ptr = ptr->next)
	{
		if (ptr->fixed)
		{
			g_assert (ptr->u.context->parent == context);
			g_assert (ptr->u.context->definition == ptr->definition);
			check_context (ptr->u.context);
		}
		else
		{
			struct CheckContextData data;
			data.parent = context;
			data.definition = ptr->definition;
			g_hash_table_foreach (ptr->u.hash,
					      (GHFunc) check_context_hash_cb,
					      &data);
		}
	}
}

static void
check_tree (GtkSourceContextEngine *ce)
{
	Segment *root = ce->priv->root_segment;

	check_regex ();

	g_assert (root->start_at == 0);

	if (ce->priv->invalid_region.empty)
		g_assert (root->end_at == gtk_text_buffer_get_char_count (ce->priv->buffer));

	g_assert (!root->parent);
	check_segment (ce, root);

	g_assert (!ce->priv->root_context->parent);
	g_assert (root->context == ce->priv->root_context);
	check_context (ce->priv->root_context);
}

static void
check_segment_children (Segment *segment)
{
	Segment *ch;

	g_assert (segment != NULL);
	check_segment_list (segment->parent);

	for (ch = segment->children; ch != NULL; ch = ch->next)
	{
		g_assert (ch->parent == segment);
		g_assert (ch->start_at <= ch->end_at);
		g_assert (!ch->next || ch->next->start_at >= ch->end_at);
		g_assert (ch->start_at >= segment->start_at);
		g_assert (ch->end_at <= segment->end_at);
		g_assert (ch->prev || ch == segment->children);
		g_assert (ch->next || ch == segment->last_child);
	}
}

static void
check_segment_list (Segment *segment)
{
	Segment *ch;

	if (segment == NULL)
		return;

	for (ch = segment->children; ch != NULL; ch = ch->next)
	{
		g_assert (ch->parent == segment);
		g_assert (ch->start_at <= ch->end_at);
		g_assert (!ch->next || ch->next->start_at >= ch->end_at);
		g_assert (ch->prev || ch == segment->children);
		g_assert (ch->next || ch == segment->last_child);
	}
}

#endif /* ENABLE_CHECK_TREE */
