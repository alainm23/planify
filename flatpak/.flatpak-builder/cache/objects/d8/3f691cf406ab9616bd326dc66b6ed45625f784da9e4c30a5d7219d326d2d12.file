/*
 * simple-password-manager.h - Header for TpSimplePasswordManager
 * Copyright (C) 2010 Collabora Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_SIMPLE_PASSWORD_MANAGER_H__
#define __TP_SIMPLE_PASSWORD_MANAGER_H__

#include <gio/gio.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/base-password-channel.h>

G_BEGIN_DECLS

typedef struct _TpSimplePasswordManager TpSimplePasswordManager;
typedef struct _TpSimplePasswordManagerClass TpSimplePasswordManagerClass;
typedef struct _TpSimplePasswordManagerPrivate TpSimplePasswordManagerPrivate;

struct _TpSimplePasswordManagerClass {
  GObjectClass parent_class;
  /*<private>*/
};

struct _TpSimplePasswordManager {
  /*<private>*/
  GObject parent;
  TpSimplePasswordManagerPrivate *priv;
};

GType tp_simple_password_manager_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_SIMPLE_PASSWORD_MANAGER \
  (tp_simple_password_manager_get_type ())
#define TP_SIMPLE_PASSWORD_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SIMPLE_PASSWORD_MANAGER,\
                              TpSimplePasswordManager))
#define TP_SIMPLE_PASSWORD_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_SIMPLE_PASSWORD_MANAGER,\
                           TpSimplePasswordManagerClass))
#define TP_IS_SIMPLE_PASSWORD_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SIMPLE_PASSWORD_MANAGER))
#define TP_IS_SIMPLE_PASSWORD_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_SIMPLE_PASSWORD_MANAGER))
#define TP_SIMPLE_PASSWORD_MANAGER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_SIMPLE_PASSWORD_MANAGER,\
                              TpSimplePasswordManagerClass))

TpSimplePasswordManager * tp_simple_password_manager_new (
    TpBaseConnection *connection);

void tp_simple_password_manager_prompt_async (
    TpSimplePasswordManager *self,
    GAsyncReadyCallback callback, gpointer user_data);

const GString * tp_simple_password_manager_prompt_finish (
    TpSimplePasswordManager *self,
    GAsyncResult *result, GError **error);

void tp_simple_password_manager_prompt_for_channel_async (
    TpSimplePasswordManager *self,
    TpBasePasswordChannel *channel,
    GAsyncReadyCallback callback, gpointer user_data);

const GString * tp_simple_password_manager_prompt_for_channel_finish (
    TpSimplePasswordManager *self,
    GAsyncResult *result,
    TpBasePasswordChannel **channel,
    GError **error);


G_END_DECLS

#endif /* #ifndef __SIMPLE_PASSWORD_MANAGER_H__ */

