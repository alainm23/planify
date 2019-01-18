/*
 * e-user-prompter-server-extension.c
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

/**
 * SECTION: e-user-prompter-server-extension
 * @short_description: Extension for a server-side user prompter
 *
 * The #EUserPrompterServerExtension is a base struct for extension
 * of EUserPrompterServer, to provide customized or specialized dialog
 * prompts.
 *
 * A descendant defines two virtual functions,
 * the EUserPrompterServerExtensionClass::register_dialogs which is used as
 * a convenient function, where the descendant registers all the dialogs it
 * provides on the server with e_user_prompter_server_register().
 *
 * The next function is EUserPrompterServerExtensionClass::prompt, which is
 * used to initiate user prompt. The implementor should not block main thread
 * with this function, because this is treated fully asynchronously.
 * User's response is passed to the server with
 * e_user_prompter_server_extension_response() call.
 **/

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-user-prompter-server.h"
#include "e-user-prompter-server-extension.h"

#define E_USER_PROMPTER_SERVER_EXTENSION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_USER_PROMPTER_SERVER_EXTENSION, EUserPrompterServerExtensionPrivate))

struct _EUserPrompterServerExtensionPrivate {
	gint dummy; /* not used */
};

G_DEFINE_ABSTRACT_TYPE (EUserPrompterServerExtension, e_user_prompter_server_extension, E_TYPE_EXTENSION)

static void
user_prompter_server_extension_constructed (GObject *object)
{
	EExtensible *extensible;
	EUserPrompterServer *server;
	EExtension *extension;
	EUserPrompterServerExtensionClass *klass;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_user_prompter_server_extension_parent_class)->constructed (object);

	g_return_if_fail (E_IS_USER_PROMPTER_SERVER_EXTENSION (object));

	extension = E_EXTENSION (object);
	g_return_if_fail (extension != NULL);

	extensible = e_extension_get_extensible (extension);
	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (extensible));

	server = E_USER_PROMPTER_SERVER (extensible);

	klass = E_USER_PROMPTER_SERVER_EXTENSION_GET_CLASS (extension);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->register_dialogs != NULL);

	klass->register_dialogs (extension, server);
}

static void
e_user_prompter_server_extension_class_init (EUserPrompterServerExtensionClass *class)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (EUserPrompterServerExtensionPrivate));

	class->register_dialogs = NULL;
	class->prompt = NULL;

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = user_prompter_server_extension_constructed;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_USER_PROMPTER_SERVER;
}

static void
e_user_prompter_server_extension_init (EUserPrompterServerExtension *extension)
{
	extension->priv = E_USER_PROMPTER_SERVER_EXTENSION_GET_PRIVATE (extension);
}

/**
 * e_user_prompter_server_extension_prompt:
 * @extension: an #EUserPrompterServerExtension
 * @prompt_id: Prompt identificator, which is used in call to e_user_prompter_server_extension_response()
 * @dialog_name: Name of a dialog to run
 * @parameters: (allow-none): Optional extension parameters for the dialog, as passed by a caller
 *
 * Instructs extension to show dialog @dialog_name. If it cannot be found,
 * or any error, then return %FALSE. The caller can pass optional @parameters,
 * if @extension uses any. Meaning of @parameters is known only to the caller
 * and to the dialog implementor, it's not interpretted nor checked for correctness
 * in any way in #EUserPrompterServer. The only limitation of @parameters is that
 * the array elements are strings.
 *
 * The @prompt_id is used as an identificator of the prompt itself,
 * and is used in e_user_prompter_server_extension_response() call,
 * which finishes the prompt.
 *
 * Note: The function call should not block main loop, it should
 * just show dialog and return.
 *
 * Returns: Whether dialog was found and shown.
 *
 * Since: 3.8
 **/
gboolean
e_user_prompter_server_extension_prompt (EUserPrompterServerExtension *extension,
                                         gint prompt_id,
                                         const gchar *dialog_name,
                                         const ENamedParameters *parameters)
{
	EUserPrompterServerExtensionClass *klass;

	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER_EXTENSION (extension), FALSE);

	klass = E_USER_PROMPTER_SERVER_EXTENSION_GET_CLASS (extension);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->prompt != NULL, FALSE);

	return klass->prompt (extension, prompt_id, dialog_name, parameters);
}

/**
 * e_user_prompter_server_extension_response:
 * @extension: an #EUserPrompterServerExtension
 * @prompt_id: Prompt identificator
 * @response: Response of the prompt
 * @values: (allow-none): Additional response values, if extension defines any
 *
 * A conveniente wrapper function around e_user_prompter_server_response(),
 * which ends previous call of e_user_prompter_server_extension_prompt().
 * The @response and @values is known only to the caller and to the dialog implementor,
 * it's not interpretted nor checked for correctness in any way in #EUserPrompterServer.
 * The only limitation of @values is that the array elements are strings.
 *
 * Since: 3.8
 **/
void
e_user_prompter_server_extension_response (EUserPrompterServerExtension *extension,
                                           gint prompt_id,
                                           gint response,
                                           const ENamedParameters *values)
{
	EExtensible *extensible;
	EUserPrompterServer *server;

	g_return_if_fail (E_IS_USER_PROMPTER_SERVER_EXTENSION (extension));

	extensible = e_extension_get_extensible (E_EXTENSION (extension));
	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (extensible));

	server = E_USER_PROMPTER_SERVER (extensible);

	e_user_prompter_server_response (server, prompt_id, response, values);
}
