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

#include "camel-address.h"

struct _CamelAddressPrivate {
	guint dummy;
};

G_DEFINE_TYPE (CamelAddress, camel_address, G_TYPE_OBJECT)

static void
camel_address_class_init (CamelAddressClass *class)
{
	g_type_class_add_private (class, sizeof (CamelAddressPrivate));
}

static void
camel_address_init (CamelAddress *address)
{
	address->priv = G_TYPE_INSTANCE_GET_PRIVATE (address, CAMEL_TYPE_ADDRESS, CamelAddressPrivate);
}

/**
 * camel_address_new:
 *
 * Create a new #CamelAddress object.
 *
 * Returns: a new #CamelAddress object
 **/
CamelAddress *
camel_address_new (void)
{
	return g_object_new (CAMEL_TYPE_ADDRESS, NULL);
}

/**
 * camel_address_new_clone:
 * @addr: a #CamelAddress object
 *
 * Clone an existing address type.
 *
 * Returns: (transfer full): the cloned address
 **/
CamelAddress *
camel_address_new_clone (CamelAddress *addr)
{
	CamelAddress *new;

	new = g_object_new (G_OBJECT_TYPE (addr), NULL);
	camel_address_cat (new, addr);

	return new;
}

/**
 * camel_address_length:
 * @addr: a #CamelAddress object
 *
 * Get the number of addresses stored in the address @addr.
 *
 * Returns: the number of addresses contained in @addr
 **/
gint
camel_address_length (CamelAddress *addr)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (addr), -1);

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->length != NULL, -1);

	return class->length (addr);
}

/**
 * camel_address_decode:
 * @addr: a #CamelAddress object
 * @raw: raw address description
 *
 * Construct a new address from a raw address field.
 *
 * Returns: the number of addresses parsed or -1 on fail
 **/
gint
camel_address_decode (CamelAddress *addr,
                      const gchar *raw)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (addr), -1);

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->decode != NULL, -1);

	return class->decode (addr, raw);
}

/**
 * camel_address_encode:
 * @addr: a #CamelAddress object
 *
 * Encode an address in a format suitable for a raw header.
 *
 * Returns: the encoded address
 **/
gchar *
camel_address_encode (CamelAddress *addr)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (addr), NULL);

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->encode != NULL, NULL);

	return class->encode (addr);
}

/**
 * camel_address_unformat:
 * @addr: a #CamelAddress object
 * @raw: raw address description
 *
 * Attempt to convert a previously formatted and/or edited
 * address back into internal form.
 *
 * Returns: the number of addresses parsed or -1 on fail
 **/
gint
camel_address_unformat (CamelAddress *addr,
                        const gchar *raw)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (addr), -1);

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->unformat != NULL, -1);

	return class->unformat (addr, raw);
}

/**
 * camel_address_format:
 * @addr: a #CamelAddress object
 *
 * Format an address in a format suitable for display.
 *
 * Returns: a newly allocated string containing the formatted addresses
 **/
gchar *
camel_address_format (CamelAddress *addr)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (addr), NULL);

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->format != NULL, NULL);

	return class->format (addr);
}

/**
 * camel_address_cat:
 * @dest: destination #CamelAddress object
 * @source: source #CamelAddress object
 *
 * Concatenate one address onto another. The addresses must
 * be of the same type.
 *
 * Returns: the number of addresses concatenated
 **/
gint
camel_address_cat (CamelAddress *dest,
                   CamelAddress *source)
{
	CamelAddressClass *class;

	g_return_val_if_fail (CAMEL_IS_ADDRESS (dest), -1);
	g_return_val_if_fail (CAMEL_IS_ADDRESS (source), -1);

	class = CAMEL_ADDRESS_GET_CLASS (dest);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->cat != NULL, -1);

	return class->cat (dest, source);
}

/**
 * camel_address_copy:
 * @dest: destination #CamelAddress object
 * @source: source #CamelAddress object
 *
 * Copy the contents of one address into another.
 *
 * Returns: the number of addresses copied
 **/
gint
camel_address_copy (CamelAddress *dest,
                    CamelAddress *source)
{
	g_return_val_if_fail (CAMEL_IS_ADDRESS (dest), -1);
	g_return_val_if_fail (CAMEL_IS_ADDRESS (source), -1);

	camel_address_remove (dest, -1);
	return camel_address_cat (dest, source);
}

/**
 * camel_address_remove:
 * @addr: a #CamelAddress object
 * @index: The address to remove, use -1 to remove all address.
 *
 * Remove an address by index, or all addresses.
 **/
void
camel_address_remove (CamelAddress *addr,
		      gint index)
{
	CamelAddressClass *class;

	g_return_if_fail (CAMEL_IS_ADDRESS (addr));

	class = CAMEL_ADDRESS_GET_CLASS (addr);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remove != NULL);

	if (index == -1) {
		gint len = camel_address_length (addr);

		for (index = len - 1; index >= 0; index--) {
			class->remove (addr, index);
		}
	} else {
		class->remove (addr, index);
	}
}
