/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include <stdio.h>
#include <string.h>

#include "camel-mime-utils.h"
#include "camel-nntp-address.h"

#define d(x)

struct _CamelNNTPAddressPrivate {
	GPtrArray *addresses;
};

G_DEFINE_TYPE (CamelNNTPAddress, camel_nntp_address, CAMEL_TYPE_ADDRESS)

static gint
nntp_address_length (CamelAddress *paddr)
{
	CamelNNTPAddress *nntp_addr = CAMEL_NNTP_ADDRESS (paddr);

	g_return_val_if_fail (nntp_addr != NULL, -1);

	return nntp_addr->priv->addresses->len;
}

/* since newsgropus are 7bit ascii, decode/unformat are the same */
static gint
nntp_address_decode (CamelAddress *address,
                     const gchar *raw)
{
	CamelNNTPAddress *nntp_addr = CAMEL_NNTP_ADDRESS (address);
	GSList *ha, *n;
	gint count = nntp_addr->priv->addresses->len;

	ha = camel_header_newsgroups_decode (raw);
	for (n = ha; n != NULL; n = n->next) {
		camel_nntp_address_add (CAMEL_NNTP_ADDRESS (address), n->data);
	}

	g_slist_free_full (ha, g_free);
	return nntp_addr->priv->addresses->len - count;
}

/* since newsgropus are 7bit ascii, encode/format are the same */
static gchar *
nntp_address_encode (CamelAddress *address)
{
	CamelNNTPAddress *nntp_addr = CAMEL_NNTP_ADDRESS (address);
	gint i;
	GString *out;
	gchar *ret;

	if (nntp_addr->priv->addresses->len == 0)
		return NULL;

	out = g_string_new ("");

	for (i = 0; i < nntp_addr->priv->addresses->len; i++) {
		if (i != 0)
			g_string_append (out, ", ");

		g_string_append (out, g_ptr_array_index (nntp_addr->priv->addresses, i));
	}

	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

static gint
nntp_address_cat (CamelAddress *dest,
                  CamelAddress *source)
{
	CamelNNTPAddress *dest_nntp_addr;
	CamelNNTPAddress *source_nntp_addr;
	gint ii;

	g_return_val_if_fail (CAMEL_IS_NNTP_ADDRESS (dest), -1);
	g_return_val_if_fail (CAMEL_IS_NNTP_ADDRESS (source), -1);

	dest_nntp_addr = CAMEL_NNTP_ADDRESS (dest);
	source_nntp_addr = CAMEL_NNTP_ADDRESS (source);

	for (ii = 0; ii < source_nntp_addr->priv->addresses->len; ii++) {
		camel_nntp_address_add (dest_nntp_addr, g_ptr_array_index (source_nntp_addr->priv->addresses, ii));
	}

	return ii;
}

static void
nntp_address_remove (CamelAddress *address,
                     gint index)
{
	CamelNNTPAddress *nntp_addr = CAMEL_NNTP_ADDRESS (address);

	if (index < 0 || index >= nntp_addr->priv->addresses->len)
		return;

	g_free (g_ptr_array_index (nntp_addr->priv->addresses, index));
	g_ptr_array_remove_index (nntp_addr->priv->addresses, index);
}


static void
nntp_address_finalize (GObject *object)
{
	CamelNNTPAddress *nntp_addr = CAMEL_NNTP_ADDRESS (object);

	camel_address_remove (CAMEL_ADDRESS (nntp_addr), -1);
	g_ptr_array_free (nntp_addr->priv->addresses, TRUE);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_nntp_address_parent_class)->finalize (object);
}

static void
camel_nntp_address_class_init (CamelNNTPAddressClass *class)
{
	CamelAddressClass *address_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelNNTPAddressPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = nntp_address_finalize;

	address_class = CAMEL_ADDRESS_CLASS (class);
	address_class->length = nntp_address_length;
	address_class->decode = nntp_address_decode;
	address_class->encode = nntp_address_encode;
	address_class->unformat = nntp_address_decode;
	address_class->format = nntp_address_encode;
	address_class->remove = nntp_address_remove;
	address_class->cat = nntp_address_cat;
}

static void
camel_nntp_address_init (CamelNNTPAddress *nntp_address)
{
	nntp_address->priv = G_TYPE_INSTANCE_GET_PRIVATE (nntp_address, CAMEL_TYPE_NNTP_ADDRESS, CamelNNTPAddressPrivate);
	nntp_address->priv->addresses = g_ptr_array_new ();
}

/**
 * camel_nntp_address_new:
 *
 * Create a new CamelNNTPAddress object.
 *
 * Returns: A new CamelNNTPAddress object.
 **/
CamelNNTPAddress *
camel_nntp_address_new (void)
{
	return g_object_new (CAMEL_TYPE_NNTP_ADDRESS, NULL);
}

/**
 * camel_nntp_address_add:
 * @addr: nntp address object
 * @name: a new NNTP address to add
 *
 * Add a new nntp address to the address object.  Duplicates are not added twice.
 *
 * Returns: Index of added entry, or existing matching entry.
 **/
gint
camel_nntp_address_add (CamelNNTPAddress *addr,
                        const gchar *name)
{
	gint index, i;

	g_return_val_if_fail (CAMEL_IS_NNTP_ADDRESS (addr), -1);

	index = addr->priv->addresses->len;
	for (i = 0; i < index; i++)
		if (!strcmp (g_ptr_array_index (addr->priv->addresses, i), name))
			return i;

	g_ptr_array_add (addr->priv->addresses, g_strdup (name));

	return index;
}

/**
 * camel_nntp_address_get:
 * @addr: nntp address object
 * @index: address's array index
 * @namep: Holder for the returned address, or NULL, if not required.
 *
 * Get the address at @index.
 *
 * Returns: TRUE if such an address exists, or FALSE otherwise.
 **/
gboolean
camel_nntp_address_get (CamelNNTPAddress *addr,
                        gint index,
                        const gchar **namep)
{
	g_return_val_if_fail (CAMEL_IS_NNTP_ADDRESS (addr), FALSE);

	if (index < 0 || index >= addr->priv->addresses->len)
		return FALSE;

	if (namep)
		*namep = g_ptr_array_index (addr->priv->addresses, index);

	return TRUE;
}
