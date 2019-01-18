/*
 * e-user-prompter-server-extension.h
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

#ifndef E_USER_PROMPTER_SERVER_EXTENSION_H
#define E_USER_PROMPTER_SERVER_EXTENSION_H

#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_USER_PROMPTER_SERVER_EXTENSION \
	(e_user_prompter_server_extension_get_type ())
#define E_USER_PROMPTER_SERVER_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_USER_PROMPTER_SERVER_EXTENSION, EUserPrompterServerExtension))
#define E_USER_PROMPTER_SERVER_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_USER_PROMPTER_SERVER_EXTENSION, EUserPrompterServerExtensionClass))
#define E_IS_USER_PROMPTER_SERVER_EXTENSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_USER_PROMPTER_SERVER_EXTENSION))
#define E_IS_USER_PROMPTER_SERVER_EXTENSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_USER_PROMPTER_SERVER_EXTENSION))
#define E_USER_PROMPTER_SERVER_EXTENSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_USER_PROMPTER_SERVER_EXTENSION, EUserPrompterServerExtensionClass))

G_BEGIN_DECLS

typedef struct _EUserPrompterServerExtension EUserPrompterServerExtension;
typedef struct _EUserPrompterServerExtensionClass EUserPrompterServerExtensionClass;
typedef struct _EUserPrompterServerExtensionPrivate EUserPrompterServerExtensionPrivate;

/* Forward declaration for EUserPrompterServer object */
struct _EUserPrompterServer;

/**
 * EUserPrompterServerExtension:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _EUserPrompterServerExtension {
	/*< private >*/
	EExtension parent;
	EUserPrompterServerExtensionPrivate *priv;
};

struct _EUserPrompterServerExtensionClass {
	EExtensionClass parent_class;

	/* virtual methods */
	void		(*register_dialogs)
					(EExtension *extension,
					 struct _EUserPrompterServer *server);
	gboolean	(*prompt)	(EUserPrompterServerExtension *extension,
					 gint prompt_id,
					 const gchar *dialog_name,
					 const ENamedParameters *parameters);
};

GType		e_user_prompter_server_extension_get_type
					(void) G_GNUC_CONST;
gboolean	e_user_prompter_server_extension_prompt
					(EUserPrompterServerExtension *extension,
					 gint prompt_id,
					 const gchar *dialog_name,
					 const ENamedParameters *parameters);
void		e_user_prompter_server_extension_response
					(EUserPrompterServerExtension *extension,
					 gint prompt_id,
					 gint response,
					 const ENamedParameters *values);

G_END_DECLS

#endif /* E_USER_PROMPTER_SERVER_EXTENSION_H */
