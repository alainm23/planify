/*
 * Copyright (C) 2011 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-text-analyzer
 * @short_description: Analyze UTF8 text
 * @include: dee.h
 *
 * A #DeeTextAnalyzer is a #DeeAnalyzer that tokenizes UTF-8 text into words,
 * lower cases it, and does rudimentary normalization. Collation keys for the
 * current locale are generated.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>

#include "dee-text-analyzer.h"

G_DEFINE_TYPE (DeeTextAnalyzer,
               dee_text_analyzer,
               DEE_TYPE_ANALYZER);

#define DEE_TEXT_ANALYZER_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_TEXT_ANALYZER, DeeTextAnalyzerPrivate))


/**
 * DeeAnalyzerPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeTextAnalyzerPrivate
{
  int foo;
};

enum
{
  PROP_0,
};

/*
 * DeeAnalyzer forward declarations
 */

static void           dee_text_analyzer_tokenize_real    (DeeAnalyzer   *self,
                                                          const gchar   *data,
                                                          DeeTermList   *terms_out);

static gchar*         dee_text_analyzer_collate_key_real      (DeeAnalyzer   *self,
                                                          const gchar   *data);


/* GObject stuff */
static void
dee_text_analyzer_finalize (GObject *object)
{
  G_OBJECT_CLASS (dee_text_analyzer_parent_class)->finalize (object);
}

static void
dee_text_analyzer_class_init (DeeTextAnalyzerClass *klass)
{
  GObjectClass     *obj_class = G_OBJECT_CLASS (klass);
  DeeAnalyzerClass *a_class = DEE_ANALYZER_CLASS (klass);

  obj_class->finalize     = dee_text_analyzer_finalize;

  a_class->tokenize = dee_text_analyzer_tokenize_real;
  a_class->collate_key = dee_text_analyzer_collate_key_real;

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeTextAnalyzerPrivate));
}

static void
dee_text_analyzer_init (DeeTextAnalyzer *self)
{
  self->priv = DEE_TEXT_ANALYZER_GET_PRIVATE (self);
}

/*
 * Implementations
 */

/* Default tokenization is a no-op */
static void
dee_text_analyzer_tokenize_real (DeeAnalyzer   *self,
                                 const gchar   *data,
                                 DeeTermList   *terms_out)
{
  GPtrArray   *term_array;
  const gchar *p, *last_term, *end;
  gchar       *term, *_term;
  gunichar     chr;
  gint         term_len_bytes, i;

  g_return_if_fail (DEE_IS_TEXT_ANALYZER (self));
  g_return_if_fail (data != NULL);
  g_return_if_fail (DEE_IS_TERM_LIST (terms_out));

  if (!g_utf8_validate (data, -1, &end))
    {
      g_warning ("Unable to analyze invalid UTF-8: %s", data);
      return;
    }

  term_array = g_ptr_array_new ();
  g_ptr_array_set_free_func (term_array, (GDestroyNotify) g_free);

  /* Split on non-alphanumeric characters
   * Watch out: "Clever" pointer arithmetic ahead... :-) */
  p = data;
  last_term = data;
  while (p != end)
    {
      chr = g_utf8_get_char (p);
      if (!g_unichar_isalnum(chr) || p == end)
        {
          term_len_bytes = p - last_term;
          term = g_strndup (last_term, term_len_bytes);
          g_ptr_array_add (term_array, term);

          while (!g_unichar_isalnum(chr) && p != end)
            {
              p = g_utf8_next_char (p);
              chr = g_utf8_get_char (p);
            }

          last_term = p;
          continue;
        }

      p = g_utf8_next_char (p);
    }

  if (last_term != p)
    {
      term_len_bytes = p - last_term;
      term = g_strndup (last_term, term_len_bytes);
      g_ptr_array_add (term_array, term);
    }

  /* Normalize terms , lowercase them, and add them to the term list */
  for (i = 0; i < term_array->len; i++)
    {
      term = g_ptr_array_index (term_array, i);
      term = g_utf8_normalize (term, -1, G_NORMALIZE_ALL_COMPOSE);
      _term = g_utf8_strdown (term, -1);

      dee_term_list_add_term (terms_out, _term);

      g_free (term);
      g_free (_term);
    }

  g_ptr_array_unref (term_array);
}

static gchar*
dee_text_analyzer_collate_key_real (DeeAnalyzer   *self,
                                    const gchar   *data)
{
  return g_utf8_collate_key (data, -1);
}

DeeTextAnalyzer*
dee_text_analyzer_new (void)
{
  return (DeeTextAnalyzer*) g_object_new (DEE_TYPE_TEXT_ANALYZER, NULL);
}

