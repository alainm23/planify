/*
 * Copyright (C) 2012 Canonical, Ltd.
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

#include <unicode/utypes.h>
#include <unicode/localpointer.h>
#include <unicode/urep.h>
#include <unicode/parseerr.h>
#include <unicode/uenum.h>
#include <unicode/utrans.h>
#include <unicode/ustring.h>

#include <string.h>

#include "dee-icu.h"

/**
 * SECTION:dee-icu
 * @title: Dee ICU Extensions
 * @short_description: A suite of #DeeTermFilter<!-- -->s based on ICU
 * @include: dee-icu.h
 *
 * This module allows developers to easily construct powerful
 * #DeeTermFilter<!-- -->s with ease. The filters leverage the ICU
 * framework to provide world class transliteration features.
 *
 * The filters can be employed manually by calling dee_icu_term_filter_apply()
 * or installed in a #DeeAnalyzer by calling dee_analyzer_add_term_filter()
 * passing the term filter instance as the user data and
 * dee_icu_term_filter_destroy() as the #GDestroyNotify.
 */

struct _DeeICUTermFilter {
  UTransliterator *transliterator;
};

static UChar*
gchar2uchar (const gchar *string, int32_t *u_len)
{
  int32_t     len;
  UChar      *u_string;
  UErrorCode  u_error_code = U_ZERO_ERROR;

  if (string == NULL)
    {
      *u_len = -1;
      return NULL;
    }


  len = strlen (string) * 2;
  u_string = g_new(UChar, 2*len + 1);
  u_string[2*len] = '\0';

  u_strFromUTF8Lenient (u_string, len, u_len, string, -1, &u_error_code);

  if (U_FAILURE(u_error_code))
    {
      g_critical ("Failed to convert string '%s' into UTF-16: %s",
                  string, u_errorName(u_error_code));
      return NULL;
    }

  return u_string;
}

static gchar*
print_error (const gchar *system_id,
             const gchar   *rules,
             UParseError    *u_parse_error,
             UErrorCode      u_error_code)
{
  GString *str;
  gchar   *msg;

  str = g_string_new ("");

  g_string_append_printf (str, "[%s]: Error creating transliterator "
                          "for system id '%s' and rules '%s'.",
                          u_errorName (u_error_code), system_id, rules);

  if (u_parse_error->line >= 0)
    g_string_append_printf(str, " On line %i.", u_parse_error->line);

  if (u_parse_error->offset >= 0)
    g_string_append_printf(str, " Offset %i.", u_parse_error->offset);

  msg = str->str;
  g_string_free (str, FALSE);

  return msg;
}

static DeeICUError
get_error_code (UErrorCode u_error_code)
{
  /* The ICU error codes are quite tangled up,
   * so excuse the spaghetti logic please :-)
   */

  if ( ! (u_error_code > U_PARSE_ERROR_START &&
          u_error_code < U_PARSE_ERROR_LIMIT) &&
          u_error_code != U_ILLEGAL_ARGUMENT_ERROR)
    {
      return DEE_ICU_ERROR_UNKNOWN;
    }

  switch (u_error_code)
  {
    case U_INVALID_ID:
    case U_INVALID_FUNCTION:
      return DEE_ICU_ERROR_BAD_ID;
    case U_ILLEGAL_ARGUMENT_ERROR:
    default:
      return DEE_ICU_ERROR_BAD_RULE;
  }
}


/**
 * dee_icu_term_filter_new:
 * @system_id: A system id for the transliterator to use.
 *             See <link anchor="http://userguide.icu-project.org/transforms/general">userguide.icu-project.org/transforms/general</link>
 * @rules: (allow-none): A set of transliteration rules to use.
 *                       See <link anchor="http://userguide.icu-project.org/transforms/general/rules">userguide.icu-project.org/transforms/general/rules</link>
 * @error: (allow-none) (error-domains Dee.ICUError): A place to return a #GError, or %NULL to ignore errors
 *
 * Create a new #DeeICUTermFilter for a given ICU transliterator system id
 * and/or set of transliteration rules.
 *
 * Returns: (transfer full): A newly allocated #DeeICUTermFilter.
 *                           Free with dee_icu_term_filter_destroy().
 */
DeeICUTermFilter*
dee_icu_term_filter_new (const gchar *system_id,
                         const gchar  *rules,
                         GError      **error)
{
  DeeICUTermFilter *self;
  UChar            *u_rules, *u_id;
  int32_t           u_rules_len, u_id_len;
  UErrorCode        u_error_code = 0;
  UParseError       u_parse_error = { 0 };
  
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  self = g_new0 (DeeICUTermFilter, 1);
  u_id = gchar2uchar (system_id, &u_id_len);
  u_rules = gchar2uchar (rules, &u_rules_len);

  self->transliterator = utrans_openU (u_id, u_id_len,
                                       UTRANS_FORWARD,
                                       u_rules, u_rules_len,
                                       &u_parse_error, &u_error_code);

  if (U_FAILURE(u_error_code))
    {
      DeeICUError error_code;
      gchar *msg;

      error_code = get_error_code (u_error_code);
      msg = print_error (system_id, rules, &u_parse_error, u_error_code);

      g_set_error_literal (error, DEE_ICU_ERROR, error_code, msg);
      g_free (msg);

      return NULL;
    }
  
  g_free (u_rules);
  g_free (u_id);

  return self;
}

/**
 * dee_icu_term_filter_new_ascii_folder:
 *
 * Construct a term filter that folds any UTF-8 string into ASCII.
 *
 * Returns: (transfer full): A newly allocated #DeeICUTermFilter. Free with
 *                           dee_icu_term_filter_destroy().
 */
DeeICUTermFilter*
dee_icu_term_filter_new_ascii_folder ()
{
  return dee_icu_term_filter_new ("Latin; Latin-ASCII;", NULL, NULL);
}

/**
 * dee_icu_term_filter_apply:
 * @self: The filter to apply
 * @text: The text to apply the filter on
 *
 * Apply a #DeeICUTermFilter on a piece of UTF-8 text.
 *
 * Returns: (transfer full): A newly allocated string. Free with g_free().
 */
gchar*
dee_icu_term_filter_apply (DeeICUTermFilter *self,
                           const gchar *text)
{
  UChar      *u_text;
  int32_t     u_cap, u_len, u_limit;
  UErrorCode  u_error_code = U_ZERO_ERROR;
  gchar      *result;

  g_return_val_if_fail (self != NULL, NULL);
  g_return_val_if_fail (text != NULL, NULL);

  u_cap = strlen (text) * 4 + 1;
  u_text = g_new (UChar, u_cap);
  u_text[u_cap - 1] = '\0';

  u_strFromUTF8Lenient (u_text, u_cap, &u_len, text, -1, &u_error_code);

  if (U_FAILURE(u_error_code))
    {
      g_critical ("Failed to convert string '%s' into UTF-16: %s",
                  text, u_errorName(u_error_code));
      return NULL;
    }

  u_limit = u_len;
  utrans_transUChars (self->transliterator,
                      u_text, &u_len, u_cap,
                      0, &u_limit,
                      &u_error_code);

  if (U_FAILURE(u_error_code))
    {
      g_critical ("Failed to transliterate '%s': %s",
                  text, u_errorName(u_error_code));
      g_free (u_text);
      return NULL;
    }

  result = g_utf16_to_utf8(u_text, u_len, NULL, NULL, NULL);

  g_free (u_text);
  return result;
}

/**
 * dee_icu_term_filter_destroy:
 * @filter: The filter to free
 *
 * Free all resources allocated by a #DeeICUTermFilter.
 */
void
dee_icu_term_filter_destroy (DeeICUTermFilter *filter)
{
  g_return_if_fail (filter != NULL);

  utrans_close (filter->transliterator);

  g_free (filter);
}

GQuark
dee_icu_error_quark (void)
{
  return g_quark_from_static_string ("dee-icu-error-quark");
}
