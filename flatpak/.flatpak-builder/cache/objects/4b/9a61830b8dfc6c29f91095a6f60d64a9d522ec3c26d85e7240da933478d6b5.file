/*
 * e-free-form-exp.h
 *
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_FREE_FORM_EXP_H
#define E_FREE_FORM_EXP_H

#include <glib.h>

G_BEGIN_DECLS

typedef gchar * (*EFreeFormExpBuildSexpFunc)	(const gchar *word,
						 const gchar *options,
						 const gchar *hint);

typedef struct _EFreeFormExpSymbol {
	const gchar *names; /* names (alternative separated by a colon (':')); use an empty string for a default sexp builder */
	const gchar *hint; /* passed into build_sexp */
	EFreeFormExpBuildSexpFunc build_sexp;
} EFreeFormExpSymbol;

gchar *		e_free_form_exp_to_sexp		(const gchar *free_form_exp,
						 const EFreeFormExpSymbol *symbols);

G_END_DECLS

#endif /* E_FREE_FORM_EXP_H */
