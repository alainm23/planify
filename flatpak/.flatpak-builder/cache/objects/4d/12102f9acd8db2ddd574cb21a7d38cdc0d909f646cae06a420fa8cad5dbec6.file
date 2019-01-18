/* --------------------------------------------------
 *
 * An address parser, yielding fields as per RFC 2426.
 *
 * Copyright 2000, Ximian, Inc.
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
 * Authors: Jesse Pavel (jpavel@ximian.com)
 */

#include <ctype.h>
#include <string.h>

#include <libedataserver/libedataserver.h>

#include "e-address-western.h"

/* These are the keywords that will distinguish the start of an extended
 * address. */

static const gchar *extended_keywords[] = {
	"apt", "apartment", "suite", NULL
};

G_DEFINE_BOXED_TYPE (EAddressWestern, e_address_western, e_address_western_copy, e_address_western_free)

static gboolean
e_address_western_is_line_blank (gchar *line)
{
	gboolean blank = TRUE;
	gint cntr;

	/* A blank line consists of whitespace only, or a NULL line. */
	for (cntr = 0; line[cntr] != '\0'; cntr++ ) {
		if (!isspace (line[cntr])) {
			blank = FALSE;
			break;
		}
	}

	return blank;
}

/* In the array of lines, `lines', we will erase the line at line_num, and
 shift the remaining lines, up to line number num_lines, up one position. */

static void
e_address_western_shift_line (gchar *lines[],
                              gint line_num,
                              gint num_lines)
{
	gint cntr;

	if (line_num >= (num_lines - 1)) {
		/* It is the last line, so simply shift in a NULL. */
		lines[line_num] = NULL;
	}
	else {
		for (cntr = line_num; cntr < num_lines; cntr++)
			lines[cntr] = lines[cntr + 1];
	}
}

static void
e_address_western_remove_blank_lines (gchar *lines[], gint *linecntr)
{
	gint cntr;

	for (cntr = 0; cntr < *linecntr; cntr++) {
		if (e_address_western_is_line_blank (lines[cntr])) {
			/* Delete the blank line, and shift all subsequent lines up
			 * one spot to fill its old spot. */
			e_address_western_shift_line (lines, cntr, *linecntr);

			/* Since we must check the newly shifted line, let's
			  not advance the counter on this next pass. */
			cntr--;

			/* There is now one less line, total. */
			*linecntr -= 1;
		}
	}
}

static gboolean
e_address_western_is_po_box (gchar *line)
{
	gboolean retval = FALSE;

	/* In which phase of processing are we? */
	enum State { FIRSTCHAR, SECONDCHAR, WHITESPACE } state;

	/* If the first two letters of the line are `p' and `o', and these
	 are in turn followed by whitespace before another letter, then I
	 will deem the line a representation of a PO Box address. */

	gint cntr;

	state = FIRSTCHAR;
	for (cntr = 0; line[cntr] != '\0'; cntr++) {
		if (state == FIRSTCHAR)	{
			if (isalnum (line[cntr])) {
				if (tolower (line[cntr]) == 'p')
					state = SECONDCHAR;
				else {
					retval = FALSE;
					break;
				}
			}
		}
		else if (state == SECONDCHAR) {
			if (isalnum (line[cntr])) {
				if (tolower (line[cntr]) == 'o')
					state = WHITESPACE;
				else {
					retval = FALSE;
					break;
				}
			}
		}
		else if (state == WHITESPACE) {
			if (isspace (line[cntr])) {
				retval = TRUE;
				break;
			}
			else if (isalnum (line[cntr])) {
				retval = FALSE;
				break;
			}
		}
	}

	return retval;
}

/* A line that contains a comma followed eventually by a number is
 * deemed to be the line in the form of <town, region postal-code>. */

static gboolean
e_address_western_is_postal (gchar *line)
{
	gboolean retval;
	gint cntr;

	if (strchr (line, ',') == NULL)
		retval = FALSE;  /* No comma. */
	else {
		gint index;

		/* Ensure that the first character after the comma is
		 a letter. */
		index = strcspn (line, ",");
		index++;
		while (isspace (line[index]))
			index++;

		if (!isalpha (line[index]))
			return FALSE;   /* FIXME: ugly control flow. */

		cntr = strlen (line) - 1;

		/* Go to the character immediately following the last
		  whitespace character. */
		while (cntr >= 0 && isspace (line[cntr]))
			cntr--;

		while (cntr >= 0 && !isspace (line[cntr]))
			cntr--;

		if (cntr == 0)
			retval = FALSE;
		else {
			if (isdigit (line[cntr + 1]))
				retval = TRUE;
			else
				retval = FALSE;
		}
	}

	return retval;
}

static gchar *
e_address_western_extract_po_box (gchar *line)
{
	/* Return everything from the beginning of the line to
	 * the end of the first word that contains a number. */

	gint index;

	index = 0;
	while (!isdigit (line[index]))
		index++;

	while (isgraph (line[index]))
		index++;

	return g_strndup (line, index);
}

static gchar *
e_address_western_extract_locality (gchar *line)
{
	gint index;

	/* Everything before the comma is the locality. */
	index = strcspn (line, ",");

	if (index == 0)
		return NULL;
	else
		return g_strndup (line, index);
}

/* Whatever resides between the comma and the start of the
  postal code is deemed to be the region. */

static gchar *
e_address_western_extract_region (gchar *line)
{
	gint start, end, alt_end;

	start = strcspn (line, ",");
	start++;
	while (isspace (line[start]))
		start++;

	end = strlen (line) - 1;
	while (isspace (line[end]))
		end--;

	alt_end = end;

	while (!isspace (line[end]))
		end--;

	while (isspace (line[end]))
		end--;
	end++;

	if (end <= start)
		end = alt_end;
	if (end <= start)
		return g_strdup ("");

	/* Between start and end lie the string. */
	return g_strndup ( (line + start), end - start);
}

static gchar *
e_address_western_extract_postal_code (gchar *line)
{
	gint start, end;

	end = strlen (line) - 1;
	while (isspace (line[end]))
		end--;

	start = end;
	end++;

	while (!isspace (line[start]))
		start--;
	start++;

	/* Between start and end lie the string. */
	return g_strndup ( (line + start), end - start);
}

static void
e_address_western_extract_street (gchar *line,
                                  gchar **street,
                                  gchar **extended)
{
	const gchar *split = NULL;
	gint cntr;

	for (cntr = 0; extended_keywords[cntr] != NULL; cntr++) {
		split = e_util_strstrcase (line, extended_keywords[cntr]);
		if (split != NULL)
			break;
	}

	if (split != NULL) {
		*street = g_strndup (line, (split - line));
		*extended = g_strdup (split);
	}
	else {
		*street = g_strdup (line);
		*extended = NULL;
	}

}

/**
 * e_address_western_parse:
 * @in_address: a string representing a mailing address
 *
 * Parses a string representing a mailing address into a
 * structure of type #EAddressWestern.
 *
 * Returns: A new #EAddressWestern structure, or %NULL if the parsing failed.
 **/
EAddressWestern *
e_address_western_parse (const gchar *in_address)
{
	gchar **lines;
	gint linecntr, lineindex;
	gchar *address;
	gint cntr;
	gboolean found_postal;

	EAddressWestern *eaw;

	if (in_address == NULL)
		return NULL;

	eaw = g_new0 (EAddressWestern, 1);

	address = g_strndup (in_address, 2047);

	/* The first thing I'll do is divide the multiline input string
	into lines. */

	/* ... count the lines. */
	linecntr = 1;
	lineindex = 0;
	while (address[lineindex] != '\0') {
		if (address[lineindex] == '\n')
			linecntr++;

		lineindex++;
	}

	/* ... tally them. */
	lines = (gchar **) g_malloc (sizeof (gchar *) * (linecntr + 3));
	lineindex = 0;
	lines[0] = &address[0];
	linecntr = 1;
	while (address[lineindex] != '\0') {
		if (address[lineindex] == '\n') {
			lines[linecntr] = &address[lineindex + 1];
			linecntr++;
		}

		lineindex++;
	}

	lines[linecntr] = NULL;

	/* Convert the newlines at the end of each line (except the last,
	 because it is already NULL terminated) to NULLs. */
	for (cntr = 0; cntr < (linecntr - 1); cntr++) {
		gchar *p;
		p = strchr (lines[cntr], '\n');
		if (p)
			*p = '\0';
	}

	e_address_western_remove_blank_lines (lines, &linecntr);

	/* Let's just test these functions. */
	found_postal = FALSE;

	for (cntr = 0; cntr < linecntr; cntr++)  {
		if (e_address_western_is_po_box (lines[cntr])) {
			if (eaw->po_box == NULL)
				eaw->po_box = e_address_western_extract_po_box (lines[cntr]);
		}
		else if (e_address_western_is_postal (lines[cntr])) {
			if (eaw->locality == NULL)
				eaw->locality = e_address_western_extract_locality (lines[cntr]);
			if (eaw->region == NULL)
				eaw->region = e_address_western_extract_region (lines[cntr]);
			if (eaw->postal_code == NULL)
				eaw->postal_code = e_address_western_extract_postal_code (lines[cntr]);
			found_postal = TRUE;
		}
		else {
			if (found_postal) {
				if (eaw->country == NULL)
					eaw->country = g_strdup (lines[cntr]);
				else {
					gchar *temp;
					temp = g_strconcat (eaw->country, "\n", lines[cntr], NULL);
					g_free (eaw->country);
					eaw->country = temp;
				}
			}
			else {
				if (eaw->street == NULL) {
					e_address_western_extract_street (
						lines[cntr], &eaw->street,
						&eaw->extended );
				}
				else {
					gchar *temp;
					temp = g_strdup_printf (
						"%s\n%s",
						eaw->extended ? eaw->extended: "",
						lines[cntr]);
					g_free (eaw->extended);
					eaw->extended = temp;
				}
			}
		}
	}

	g_free (lines);
	g_free (address);

	return eaw;
}

/**
 * e_address_western_free:
 * @eaw: an #EAddressWestern
 *
 * Frees @eaw and its contents.
 **/
void
e_address_western_free (EAddressWestern *eaw)
{
	if (!eaw)
		return;

	g_free (eaw->po_box);
	g_free (eaw->extended);
	g_free (eaw->street);
	g_free (eaw->locality);
	g_free (eaw->region);
	g_free (eaw->postal_code);
	g_free (eaw->country);
	g_free (eaw);
}

/**
 * e_address_western_copy:
 * @eaw: an #EAddressWestern
 *
 * Creates a copy of @eaw.
 *
 * Returns: (transfer full): A new #EAddressWestern struct identical to @eaw.
 *
 * Since: 3.24
 **/
EAddressWestern *
e_address_western_copy (EAddressWestern *eaw)
{
	EAddressWestern *waddress;

	if (!eaw)
		return NULL;

	waddress = g_new0 (EAddressWestern, 1);
	waddress->po_box = g_strdup (eaw->po_box);
	waddress->extended = g_strdup (eaw->extended);
	waddress->street = g_strdup (eaw->street);
	waddress->locality = g_strdup (eaw->locality);
	waddress->region = g_strdup (eaw->region);
	waddress->postal_code = g_strdup (eaw->postal_code);
	waddress->country = g_strdup (eaw->country);

	return waddress;
}
