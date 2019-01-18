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

#include "camel-internet-address.h"
#include "camel-mime-utils.h"
#include "camel-net-utils.h"

#define d(x)

struct _CamelInternetAddressPrivate {
	GPtrArray *addresses;
};

struct _address {
	gchar *name;
	gchar *address;
};

G_DEFINE_TYPE (CamelInternetAddress, camel_internet_address, CAMEL_TYPE_ADDRESS)

static gint
internet_address_length (CamelAddress *paddr)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (paddr);

	g_return_val_if_fail (inet_addr != NULL, -1);

	return inet_addr->priv->addresses->len;
}

static gint
internet_address_decode (CamelAddress *addr,
                         const gchar *raw)
{
	CamelHeaderAddress *ha, *n;
	gint count = camel_address_length (addr);

	/* Should probably use its own decoder or something */
	ha = camel_header_address_decode (raw, NULL);
	if (ha) {
		n = ha;
		while (n) {
			if (n->type == CAMEL_HEADER_ADDRESS_NAME) {
				camel_internet_address_add ((CamelInternetAddress *) addr, n->name, n->v.addr);
			} else if (n->type == CAMEL_HEADER_ADDRESS_GROUP) {
				CamelHeaderAddress *g = n->v.members;
				while (g) {
					if (g->type == CAMEL_HEADER_ADDRESS_NAME)
						camel_internet_address_add ((CamelInternetAddress *) addr, g->name, g->v.addr);
					/* otherwise, it's an error, infact */
					g = g->next;
				}
			}
			n = n->next;
		}
		camel_header_address_list_clear (&ha);
	}

	return camel_address_length (addr) - count;
}

static gchar *
internet_address_encode (CamelAddress *paddr)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (paddr);
	gint i;
	GString *out;
	gchar *ret;
	gint len = 6;		/* "From: ", assume longer of the address headers */

	if (inet_addr->priv->addresses->len == 0)
		return NULL;

	out = g_string_new ("");

	for (i = 0; i < inet_addr->priv->addresses->len; i++) {
		struct _address *addr = g_ptr_array_index (inet_addr->priv->addresses, i);
		gchar *enc;

		if (i != 0)
			g_string_append (out, ", ");

		enc = camel_internet_address_encode_address (&len, addr->name, addr->address);
		g_string_append (out, enc);
		g_free (enc);
	}

	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

static gint
internet_address_unformat (CamelAddress *paddr,
                           const gchar *raw)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (paddr);
	gchar *buffer, *p, *name, *addr;
	gint c;
	gint count = inet_addr->priv->addresses->len;

	if (raw == NULL)
		return 0;

	d (printf ("unformatting address: %s\n", raw));

	/* we copy, so we can modify as we go */
	buffer = g_strdup (raw);

	/* this can be simpler than decode, since there are much fewer rules */
	p = buffer;
	name = NULL;
	addr = p;
	do {
		c = (guchar) * p++;
		switch (c) {
			/* removes quotes, they should only be around the total name anyway */
		case '"':
			p[-1] = ' ';
			while (*p)
				if (*p == '"') {
					*p++ = ' ';
					break;
				} else {
					p++;
				}
			break;
		case '<':
			if (name == NULL)
				name = addr;
			addr = p;
			addr[-1] = 0;
			while (*p && *p != '>')
				p++;
			if (*p == 0)
				break;
			p++;
			/* falls through */
		case ',':
			p[-1] = 0;
			/* falls through */
		case 0:
			if (name)
				name = g_strstrip (name);
			addr = g_strstrip (addr);
			if (addr[0]) {
				d (printf ("found address: '%s' <%s>\n", name, addr));
				camel_internet_address_add (inet_addr, name, addr);
			}
			name = NULL;
			addr = p;
			break;
		}
	} while (c);

	g_free (buffer);

	return inet_addr->priv->addresses->len - count;
}

static gchar *
internet_address_format (CamelAddress *paddr)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (paddr);
	gint i;
	GString *out;
	gchar *ret;

	if (inet_addr->priv->addresses->len == 0)
		return NULL;

	out = g_string_new ("");

	for (i = 0; i < inet_addr->priv->addresses->len; i++) {
		struct _address *addr = g_ptr_array_index (inet_addr->priv->addresses, i);
		gchar *enc;

		if (i != 0)
			g_string_append (out, ", ");

		enc = camel_internet_address_format_address (addr->name, addr->address);
		g_string_append (out, enc);
		g_free (enc);
	}

	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

static void
internet_address_remove (CamelAddress *paddr,
                         gint index)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (paddr);
	struct _address *addr;

	if (index < 0 || index >= inet_addr->priv->addresses->len)
		return;

	addr = g_ptr_array_index (inet_addr->priv->addresses, index);
	g_free (addr->name);
	g_free (addr->address);
	g_free (addr);
	g_ptr_array_remove_index (inet_addr->priv->addresses, index);
}

static gint
internet_address_cat (CamelAddress *dest,
                      CamelAddress *source)
{
	CamelInternetAddress *dest_inet_addr;
	CamelInternetAddress *source_inet_addr;
	gint i;

	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (dest), -1);
	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (source), -1);

	dest_inet_addr = CAMEL_INTERNET_ADDRESS (dest);
	source_inet_addr = CAMEL_INTERNET_ADDRESS (source);

	for (i = 0; i < source_inet_addr->priv->addresses->len; i++) {
		struct _address *addr = g_ptr_array_index (source_inet_addr->priv->addresses, i);
		camel_internet_address_add (dest_inet_addr, addr->name, addr->address);
	}

	return i;
}

static void
internet_address_finalize (GObject *object)
{
	CamelInternetAddress *inet_addr = CAMEL_INTERNET_ADDRESS (object);

	camel_address_remove (CAMEL_ADDRESS (inet_addr), -1);
	g_ptr_array_free (inet_addr->priv->addresses, TRUE);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_internet_address_parent_class)->finalize (object);
}

static void
camel_internet_address_class_init (CamelInternetAddressClass *class)
{
	CamelAddressClass *address_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelInternetAddressPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = internet_address_finalize;

	address_class = CAMEL_ADDRESS_CLASS (class);
	address_class->length = internet_address_length;
	address_class->decode = internet_address_decode;
	address_class->encode = internet_address_encode;
	address_class->unformat = internet_address_unformat;
	address_class->format = internet_address_format;
	address_class->remove = internet_address_remove;
	address_class->cat = internet_address_cat;
}

static void
camel_internet_address_init (CamelInternetAddress *internet_address)
{
	internet_address->priv = G_TYPE_INSTANCE_GET_PRIVATE (internet_address, CAMEL_TYPE_INTERNET_ADDRESS, CamelInternetAddressPrivate);
	internet_address->priv->addresses = g_ptr_array_new ();
}

/**
 * camel_internet_address_new:
 *
 * Create a new #CamelInternetAddress object.
 *
 * Returns: a new #CamelInternetAddress object
 **/
CamelInternetAddress *
camel_internet_address_new (void)
{
	return g_object_new (CAMEL_TYPE_INTERNET_ADDRESS, NULL);
}

/**
 * camel_internet_address_add:
 * @addr: a #CamelInternetAddress object
 * @name: name associated with the new address
 * @address: routing address associated with the new address
 *
 * Add a new internet address to @addr.
 *
 * Returns: the index of added entry
 **/
gint
camel_internet_address_add (CamelInternetAddress *addr,
                            const gchar *name,
                            const gchar *address)
{
	struct _address *new;
	gint index;

	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (addr), -1);

	new = g_malloc (sizeof (*new));
	new->name = g_strdup (name);
	new->address = g_strdup (address);
	index = addr->priv->addresses->len;
	g_ptr_array_add (addr->priv->addresses, new);

	return index;
}

/**
 * camel_internet_address_get:
 * @addr: a #CamelInternetAddress object
 * @index: address's array index
 * @namep: (out) (nullable): holder for the returned name, or %NULL, if not required.
 * @addressp: (out) (nullable): holder for the returned address, or %NULL, if not required.
 *
 * Get the address at @index.
 *
 * Returns: %TRUE if such an address exists, or %FALSE otherwise
 **/
gboolean
camel_internet_address_get (CamelInternetAddress *addr,
                            gint index,
                            const gchar **namep,
                            const gchar **addressp)
{
	struct _address *a;

	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (addr), FALSE);

	if (index < 0 || index >= addr->priv->addresses->len)
		return FALSE;

	a = g_ptr_array_index (addr->priv->addresses, index);
	if (namep)
		*namep = a->name;
	if (addressp)
		*addressp = a->address;
	return TRUE;
}

/**
 * camel_internet_address_find_name:
 * @addr: a #CamelInternetAddress object
 * @name: name to lookup
 * @addressp: (out) (nullable): holder for address part, or %NULL, if not required.
 *
 * Find address by real name.
 *
 * Returns: the index of the address matching the name, or -1 if no
 * match was found
 **/
gint
camel_internet_address_find_name (CamelInternetAddress *addr,
                                  const gchar *name,
                                  const gchar **addressp)
{
	struct _address *a;
	gboolean name_is_utf8_valid;
	gint i, len;

	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (addr), -1);

	if (!name)
		return -1;

	name_is_utf8_valid = g_utf8_validate (name, -1, NULL);

	len = addr->priv->addresses->len;
	for (i = 0; i < len; i++) {
		gboolean match;

		a = g_ptr_array_index (addr->priv->addresses, i);

		if (!a->name)
			continue;

		if (name_is_utf8_valid && g_utf8_validate (a->name, -1, NULL))
			match = !g_utf8_collate (a->name, name);
		else
			match = !g_ascii_strcasecmp (a->name, name);

		if (match) {
			if (addressp)
				*addressp = a->address;
			return i;
		}
	}
	return -1;
}

static gboolean
domain_contains_only_ascii (const gchar *address,
			    gint *at_pos)
{
	gint pos;
	gboolean all_ascii = TRUE;

	g_return_val_if_fail (address != NULL, TRUE);
	g_return_val_if_fail (at_pos != NULL, TRUE);

	*at_pos = -1;
	for (pos = 0; address[pos]; pos++) {
		all_ascii = all_ascii && address[pos] > 0;
		if (*at_pos == -1 && address[pos] == '@') {
			*at_pos = pos;
			all_ascii = TRUE;
		}
	}

	/* Do not change anything when there is no domain part
	   of the email address */
	return all_ascii || *at_pos == -1;
}

/**
 * camel_internet_address_ensure_ascii_domains:
 * @addr: a #CamelInternetAddress
 *
 * Ensures that all email address' domains will be ASCII encoded,
 * which means that any non-ASCII letters will be properly encoded.
 * This includes IDN (Internationalized Domain Names).
 *
 * Since: 3.16
 **/
void
camel_internet_address_ensure_ascii_domains (CamelInternetAddress *addr)
{
	struct _address *a;
	gint i, len;

	g_return_if_fail (CAMEL_IS_INTERNET_ADDRESS (addr));

	len = addr->priv->addresses->len;
	for (i = 0; i < len; i++) {
		gint at_pos = -1;
		a = g_ptr_array_index (addr->priv->addresses, i);
		if (a->address && !domain_contains_only_ascii (a->address, &at_pos)) {
			gchar *address, *domain;

			domain = camel_host_idna_to_ascii (a->address + at_pos + 1);
			if (at_pos >= 0) {
				gchar *name = g_strndup (a->address, at_pos);
				address = g_strconcat (name, "@", domain, NULL);
			} else {
				address = domain;
				domain = NULL;
			}

			g_free (domain);
			g_free (a->address);
			a->address = address;
		}
	}
}

/**
 * camel_internet_address_find_address:
 * @addr: a #CamelInternetAddress object
 * @address: address to lookup
 * @namep: (out) (nullable): holder for the matching name, or %NULL, if not required.
 *
 * Find an address by address.
 *
 * Returns: the index of the address, or -1 if not found
 **/
gint
camel_internet_address_find_address (CamelInternetAddress *addr,
                                     const gchar *address,
                                     const gchar **namep)
{
	struct _address *a;
	gint i, len;

	g_return_val_if_fail (CAMEL_IS_INTERNET_ADDRESS (addr), -1);

	len = addr->priv->addresses->len;
	for (i = 0; i < len; i++) {
		a = g_ptr_array_index (addr->priv->addresses, i);
		if (a->address && address && !g_ascii_strcasecmp (a->address, address)) {
			if (namep)
				*namep = a->name;
			return i;
		}
	}
	return -1;
}

static void
cia_encode_addrspec (GString *out,
                     const gchar *addr)
{
	const gchar *at, *p;

	at = strchr (addr, '@');
	if (at == NULL)
		goto append;

	p = addr;
	while (p < at) {
		gchar c = *p++;

		/* strictly by rfc, we should split local parts on dots.
		 * however i think 2822 changes this, and not many clients grok it, so
		 * just quote the whole local part if need be */
		if (!(camel_mime_is_atom (c) || c == '.')) {
			g_string_append_c (out, '"');

			p = addr;
			while (p < at) {
				c = *p++;
				if (c == '"' || c == '\\')
					g_string_append_c (out, '\\');
				g_string_append_c (out, c);
			}
			g_string_append_c (out, '"');
			g_string_append (out, p);

			return;
		}
	}

append:
	g_string_append (out, addr);
}

/**
 * camel_internet_address_encode_address:
 * @len: the length of the line the address is being appended to
 * @name: the unencoded real name associated with the address
 * @addr: the routing address
 *
 * Encode a single address ready for internet usage.  Header folding
 * as per rfc822 is also performed, based on the length *@len.  If @len
 * is %NULL, then no folding will occur.
 *
 * Note: The value at *@in will be updated based on any linewrapping done
 *
 * Returns: the encoded address
 **/
gchar *
camel_internet_address_encode_address (gint *inlen,
                                       const gchar *real,
                                       const gchar *addr)
{
	gchar *name;
	gchar *ret = NULL;
	gint len = 0;
	GString *out;

	g_return_val_if_fail (addr, NULL);

	name = camel_header_encode_phrase ((const guchar *) real);
	out = g_string_new ("");

	if (inlen != NULL)
		len = *inlen;

	if (name && name[0]) {
		if (inlen != NULL && (strlen (name) + len) > CAMEL_FOLD_SIZE) {
			gchar *folded = camel_header_address_fold (name, len);
			gchar *last;
			g_string_append (out, folded);
			g_free (folded);
			last = strrchr (out->str, '\n');
			if (last)
				len = last - (out->str + out->len);
			else
				len = out->len;
		} else {
			g_string_append (out, name);
			len += strlen (name);
		}
	}

	/* NOTE: Strictly speaking, we could and should split the
	 * internal address up if we need to, on atom or specials
	 * boundaries - however, to aid interoperability with mailers
	 * that will probably not handle this case, we will just move
	 * the whole address to its own line. */
	if (inlen != NULL && (strlen (addr) + len) > CAMEL_FOLD_SIZE) {
		g_string_append (out, "\n\t");
		len = 1;
	}

	len -= out->len;

	if (name && name[0])
		g_string_append (out, " <");
	cia_encode_addrspec (out, addr);
	if (name && name[0])
		g_string_append (out, ">");

	len += out->len;

	if (inlen != NULL)
		*inlen = len;

	g_free (name);

	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

/**
 * camel_internet_address_format_address:
 * @name: a name, quotes may be stripped from it
 * @addr: an rfc822 routing address
 *
 * Function to format a single address, suitable for display.
 *
 * Returns: a nicely formatted string containing the rfc822 address
 **/
gchar *
camel_internet_address_format_address (const gchar *name,
                                       const gchar *addr)
{
	gchar *ret = NULL;

	g_return_val_if_fail (addr, NULL);

	if (name && name[0]) {
		const gchar *p = name;
		gchar *o, c;

		while ((c = *p++)) {
			if (c == ',' || c == ';' || c == '\"' || c == '<' || c == '>') {
				o = ret = g_malloc (strlen (name) + 3 + strlen (addr) + 3 + 1);
				p = name;
				*o++ = '\"';
				while ((c = *p++))
					if (c != '\"')
						*o++ = c;
				*o++ = '\"';
				sprintf (o, " <%s>", addr);
				d (printf ("encoded '%s' => '%s'\n", name, ret));
				return ret;
			}
		}
		ret = g_strdup_printf ("%s <%s>", name, addr);
	} else
		ret = g_strdup (addr);

	return ret;
}
