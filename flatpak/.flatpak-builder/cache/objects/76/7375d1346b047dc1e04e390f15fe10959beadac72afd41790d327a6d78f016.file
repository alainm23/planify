/*
 * contact-search-result.c - a result for a contact search
 *
 * Copyright (C) 2010-2011 Collabora Ltd.
 *
 * The code contained in this file is free software; you can redistribute
 * it and/or modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this code; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "config.h"

#include "telepathy-glib/contact-search-result.h"
#include "telepathy-glib/contact-search-internal.h"

#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CHANNEL
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/util-internal.h"

#include "_gen/telepathy-interfaces.h"

/**
 * SECTION:contact-search-result
 * @title: TpContactSearchResult
 * @short_description: a result of a contact search
 * @see_also: #TpContactSearch
 *
 * #TpContactSearchResult objects represent results for
 * #TpContactSearch.
 *
 * Since: 0.13.11
 */

/**
 * TpContactSearchResultClass:
 *
 * The class of a #TpContactSearchResult.
 *
 * Since: 0.13.11
 */

/**
 * TpContactSearchResult:
 *
 * An object representing the results of a Telepathy contact
 * search channel.
 * There are no interesting public struct fields.
 *
 * Since: 0.13.11
 */

G_DEFINE_TYPE (TpContactSearchResult,
    tp_contact_search_result,
    G_TYPE_OBJECT);

struct _TpContactSearchResultPrivate
{
  gchar *identifier;
  /* List of TpContactInfoField. The list and its contents are owned by us. */
  GList *fields;
};

enum /* properties */
{
  PROP_0,
  PROP_IDENTIFIER,
};

static gint
find_tp_contact_info_field (gconstpointer f,
    gconstpointer n)
{
  TpContactInfoField *field = (TpContactInfoField *) f;

  return g_strcmp0 (field->field_name, n);
}

static void
tp_contact_search_result_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpContactSearchResult *self = TP_CONTACT_SEARCH_RESULT (object);

  switch (prop_id)
    {
      case PROP_IDENTIFIER:
        g_assert (self->priv->identifier == NULL);  /* construct-only */
        self->priv->identifier = g_value_dup_string (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (self, prop_id, pspec);
        break;
    }
}

static void
tp_contact_search_result_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpContactSearchResult *self = TP_CONTACT_SEARCH_RESULT (object);

  switch (prop_id)
    {
      case PROP_IDENTIFIER:
        g_value_set_string (value, self->priv->identifier);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
        break;
    }
}

static void
tp_contact_search_result_dispose (GObject *object)
{
  TpContactSearchResult *self = TP_CONTACT_SEARCH_RESULT (object);

  tp_clear_pointer (&self->priv->identifier, g_free);

  tp_clear_pointer (&self->priv->fields, tp_contact_info_list_free);

  G_OBJECT_CLASS (tp_contact_search_result_parent_class)->dispose (object);
}

static void
tp_contact_search_result_class_init (TpContactSearchResultClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->set_property = tp_contact_search_result_set_property;
  gobject_class->get_property = tp_contact_search_result_get_property;
  gobject_class->dispose = tp_contact_search_result_dispose;

  /**
   * TpContactSearch:identifier:
   *
   * The contact identifier.
   *
   * Since: 0.13.11
   */
  g_object_class_install_property (gobject_class,
      PROP_IDENTIFIER,
      g_param_spec_string ("identifier",
        "Identifier",
        "The contact identifier",
        NULL,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  g_type_class_add_private (gobject_class,
      sizeof (TpContactSearchResultPrivate));
}

static void
tp_contact_search_result_init (TpContactSearchResult *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_CONTACT_SEARCH_RESULT,
      TpContactSearchResultPrivate);
}

TpContactSearchResult *
_tp_contact_search_result_new (const gchar *identifier)
{
  g_return_val_if_fail (identifier != NULL, NULL);

  return g_object_new (TP_TYPE_CONTACT_SEARCH_RESULT,
      "identifier", identifier,
      NULL);
}

void
_tp_contact_search_result_insert_field (TpContactSearchResult *self,
    TpContactInfoField *field)
{
  g_return_if_fail (TP_IS_CONTACT_SEARCH_RESULT (self));

  self->priv->fields = g_list_append (self->priv->fields, field);
}

/**
 * tp_contact_search_result_get_identifier:
 * @self: a #TpContactSearchResult
 *
 * <!-- -->
 *
 * Returns: the contact identifier.
 *
 * Since: 0.13.11
 */
const gchar *
tp_contact_search_result_get_identifier (TpContactSearchResult *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH_RESULT (self), NULL);

  return self->priv->identifier;
}

/**
 * tp_contact_search_result_get_field:
 * @self: a #TpContactSearchResult
 * @field: the name of the field
 *
 * <!-- -->
 *
 * Returns: (transfer none): the specified field, or %NULL if the
 * result doesn't have it.
 *
 * Since: 0.13.11
 */
TpContactInfoField *
tp_contact_search_result_get_field (TpContactSearchResult *self,
    const gchar *field)
{
  GList *l;

  g_return_val_if_fail (TP_IS_CONTACT_SEARCH_RESULT (self), NULL);

  l = g_list_find_custom (self->priv->fields,
      field,
      find_tp_contact_info_field);

  return (l ? l->data : NULL);
}

/**
 * tp_contact_search_result_get_fields:
 * @self: a search result
 *
 * <!-- -->
 *
 * Returns: (transfer container) (element-type TelepathyGLib.ContactInfoField):
 *  a #GList of #TpContactInfoField for the specified contact. You should free
 *  it when you're done with g_list_free().
 * Deprecated: Since 0.19.9. New code should use
 *  tp_contact_search_result_dup_fields() instead.
 */
GList *
tp_contact_search_result_get_fields (TpContactSearchResult *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH_RESULT (self), NULL);

  return g_list_copy (self->priv->fields);
}

/**
 * tp_contact_search_result_dup_fields:
 * @self: a search result
 *
 * <!-- -->
 *
 * Returns: (transfer full) (element-type TelepathyGLib.ContactInfoField):
 *  a #GList of #TpContactInfoField for the specified contact. You should free
 *  it when you're done with tp_contact_info_list_free().
 * Since: 0.19.9
 */
GList *
tp_contact_search_result_dup_fields (TpContactSearchResult *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH_RESULT (self), NULL);

  return _tp_g_list_copy_deep (self->priv->fields,
      (GCopyFunc) tp_contact_info_field_copy, NULL);
}
