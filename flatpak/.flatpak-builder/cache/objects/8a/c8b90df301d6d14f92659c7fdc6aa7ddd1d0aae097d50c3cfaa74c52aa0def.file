/*
 * e-user-prompter-server.h
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

#ifndef E_USER_PROMPTER_SERVER_H
#define E_USER_PROMPTER_SERVER_H

#include <libedataserver/libedataserver.h>
#include <libebackend/e-dbus-server.h>

/* Standard GObject macros */
#define E_TYPE_USER_PROMPTER_SERVER \
	(e_user_prompter_server_get_type ())
#define E_USER_PROMPTER_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_USER_PROMPTER_SERVER, EUserPrompterServer))
#define E_USER_PROMPTER_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_USER_PROMPTER_SERVER, EUserPrompterServerClass))
#define E_IS_USER_PROMPTER_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_USER_PROMPTER_SERVER))
#define E_IS_USER_PROMPTER_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_USER_PROMPTER_SERVER))
#define E_USER_PROMPTER_SERVER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_USER_PROMPTER_SERVER, EUserPrompterServerClass))

/**
 * E_USER_PROMPTER_SERVER_OBJECT_PATH:
 *
 * D-Bus object path of the user prompter.
 *
 * Since: 3.8
 **/
#define E_USER_PROMPTER_SERVER_OBJECT_PATH \
	"/org/gnome/evolution/dataserver/UserPrompter"

G_BEGIN_DECLS

typedef struct _EUserPrompterServer EUserPrompterServer;
typedef struct _EUserPrompterServerClass EUserPrompterServerClass;
typedef struct _EUserPrompterServerPrivate EUserPrompterServerPrivate;

/**
 * EUserPrompterServer:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _EUserPrompterServer {
	/*< private >*/
	EDBusServer parent;
	EUserPrompterServerPrivate *priv;
};

struct _EUserPrompterServerClass {
	EDBusServerClass parent_class;

	/* signals */
	void		(*prompt)		(EUserPrompterServer *server,
						 gint id,
						 const gchar *type,
						 const gchar *title,
						 const gchar *primary_text,
						 const gchar *secondary_text,
						 gboolean use_markup,
						 const GSList *button_captions);
};

GType		e_user_prompter_server_get_type	(void) G_GNUC_CONST;
EDBusServer *	e_user_prompter_server_new	(void);
void		e_user_prompter_server_response	(EUserPrompterServer *server,
						 gint prompt_id,
						 gint response,
						 const ENamedParameters *extension_values);

gboolean	e_user_prompter_server_register	(EUserPrompterServer *server,
						 EExtension *extension,
						 const gchar *dialog_name);

G_END_DECLS

#endif /* E_USER_PROMPTER_SERVER_H */
