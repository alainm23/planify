/*<private_header>*/
/* A ContactList channel with handle type LIST or GROUP.
 *
 * Copyright © 2009-2010 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2009 Nokia Corporation
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

#ifndef __TP_CONTACT_LIST_CHANNEL_INTERNAL_H__
#define __TP_CONTACT_LIST_CHANNEL_INTERNAL_H__

#include <glib-object.h>

#include <telepathy-glib/base-channel.h>
#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/base-contact-list.h>
#include <telepathy-glib/group-mixin.h>

G_BEGIN_DECLS

typedef struct _TpBaseContactListChannel TpBaseContactListChannel;
typedef struct _TpBaseContactListChannelClass TpBaseContactListChannelClass;

/* the subclasses don't have, or need, their own structs */
typedef TpBaseContactListChannel TpContactListChannel;
typedef TpBaseContactListChannel TpContactGroupChannel;
typedef TpBaseContactListChannelClass TpContactListChannelClass;
typedef TpBaseContactListChannelClass TpContactGroupChannelClass;

GType _tp_base_contact_list_channel_get_type (void);

#define TP_TYPE_BASE_CONTACT_LIST_CHANNEL \
  (_tp_base_contact_list_channel_get_type ())
#define TP_BASE_CONTACT_LIST_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_BASE_CONTACT_LIST_CHANNEL, \
                               TpBaseContactListChannel))
#define TP_BASE_CONTACT_LIST_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_BASE_CONTACT_LIST_CHANNEL, \
                            TpBaseContactListChannelClass))
#define TP_IS_BASE_CONTACT_LIST_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_BASE_CONTACT_LIST_CHANNEL))
#define TP_IS_BASE_CONTACT_LIST_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_BASE_CONTACT_LIST_CHANNEL))
#define TP_BASE_CONTACT_LIST_CHANNEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_BASE_CONTACT_LIST_CHANNEL, \
                              TpBaseContactListChannelClass))

GType _tp_contact_list_channel_get_type (void);

#define TP_TYPE_CONTACT_LIST_CHANNEL \
  (_tp_contact_list_channel_get_type ())
#define TP_CONTACT_LIST_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CONTACT_LIST_CHANNEL, \
                               TpContactListChannel))
#define TP_CONTACT_LIST_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CONTACT_LIST_CHANNEL, \
                            TpContactListChannelClass))
#define TP_IS_CONTACT_LIST_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CONTACT_LIST_CHANNEL))
#define TP_IS_CONTACT_LIST_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CONTACT_LIST_CHANNEL))
#define TP_CONTACT_LIST_CHANNEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CONTACT_LIST_CHANNEL, \
                              TpContactListChannelClass))

GType _tp_contact_group_channel_get_type (void);

#define TP_TYPE_CONTACT_GROUP_CHANNEL \
  (_tp_contact_group_channel_get_type ())
#define TP_CONTACT_GROUP_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CONTACT_GROUP_CHANNEL, \
                               TpContactGroupChannel))
#define TP_CONTACT_GROUP_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CONTACT_GROUP_CHANNEL, \
                            TpContactGroupChannelClass))
#define TP_IS_CONTACT_GROUP_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CONTACT_GROUP_CHANNEL))
#define TP_IS_CONTACT_GROUP_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CONTACT_GROUP_CHANNEL))
#define TP_CONTACT_GROUP_CHANNEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CONTACT_GROUP_CHANNEL, \
                              TpContactGroupChannelClass))

struct _TpBaseContactListChannelClass
{
  TpBaseChannelClass parent_class;
  TpGroupMixinClass group_class;
};

struct _TpBaseContactListChannel
{
  TpBaseChannel parent;
  TpGroupMixin group;

  /*<private>*/
  /* these would be in priv if this was a public object */

  /* set to NULL after channel is closed */
  TpBaseContactList *manager;
};

void _tp_base_contact_list_channel_close (TpBaseContactListChannel *self);

G_END_DECLS

#endif
