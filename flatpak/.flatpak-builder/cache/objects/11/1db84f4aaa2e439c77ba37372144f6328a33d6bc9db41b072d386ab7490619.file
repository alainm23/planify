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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_TEXT_ANALYZER_H
#define _HAVE_DEE_TEXT_ANALYZER_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>
#include <dee-term-list.h>
#include <dee-analyzer.h>

G_BEGIN_DECLS

#define DEE_TYPE_TEXT_ANALYZER (dee_text_analyzer_get_type ())

#define DEE_TEXT_ANALYZER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_TEXT_ANALYZER, DeeTextAnalyzer))

#define DEE_TEXT_ANALYZER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_TEXT_ANALYZER, DeeTextAnalyzerClass))

#define DEE_IS_TEXT_ANALYZER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_TEXT_ANALYZER))

#define DEE_IS_TEXT_ANALYZER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_TEXT_ANALYZER))

#define DEE_TEXT_ANALYZER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DEE_TYPE_TEXT_ANALYZER, DeeTextAnalyzerClass))

typedef struct _DeeTextAnalyzer DeeTextAnalyzer;
typedef struct _DeeTextAnalyzerClass DeeTextAnalyzerClass;
typedef struct _DeeTextAnalyzerPrivate DeeTextAnalyzerPrivate;

/**
 * DeeTextAnalyzer:
 *
 * All fields in the DeeTextAnalyzer structure are private and should never be
 * accessed directly
 */
struct _DeeTextAnalyzer
{
  /*< private >*/
  DeeAnalyzer             parent;

  DeeTextAnalyzerPrivate *priv;
};

struct _DeeTextAnalyzerClass
{
  /*< private >*/
  DeeAnalyzerClass parent_class;
};

/**
 * dee_text_analyzer_get_type:
 *
 * The GType of #DeeTextAnalyzer
 *
 * Return value: the #GType of #DeeTextAnalyzer
 **/
GType                 dee_text_analyzer_get_type        (void);

DeeTextAnalyzer*      dee_text_analyzer_new          (void);

G_END_DECLS

#endif /* _HAVE_DEE_TEXT_ANALYZER_H */
