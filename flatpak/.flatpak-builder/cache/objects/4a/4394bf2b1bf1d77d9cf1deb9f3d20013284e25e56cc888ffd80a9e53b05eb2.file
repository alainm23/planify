/*
 * prompt-user.h
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

#ifndef PROMPT_USER_H
#define PROMPT_USER_H

#include <libebackend/libebackend.h>

/* initialize the GUI subsystem */
void
prompt_user_init (gint *argc,
		  gchar ***argv);

/* This is called when a request is initiated. The callback should not block,
 * and when a user responds, the e_user_prompter_server_response() should be called.
 */

void
prompt_user_show (EUserPrompterServer *server,
		  gint id,
		  const gchar *type,
		  const gchar *title,
		  const gchar *primary_text,
		  const gchar *secondary_text,
		  gboolean use_markup,
		  const GSList *button_captions);

#endif /* PROMPT_USER_H */
