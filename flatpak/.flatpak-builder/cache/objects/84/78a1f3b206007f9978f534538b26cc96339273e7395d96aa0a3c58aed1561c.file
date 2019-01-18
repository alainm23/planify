/*
A menuitem subclass that has the ability to do lots of different
things depending on its settings.

Copyright 2009 Canonical Ltd.

Authors:
    Ted Gould <ted@canonical.com>

This program is free software: you can redistribute it and/or modify it 
under the terms of either or both of the following licenses:

1) the GNU Lesser General Public License version 3, as published by the 
Free Software Foundation; and/or
2) the GNU Lesser General Public License version 2.1, as published by 
the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR 
PURPOSE.  See the applicable version of the GNU Lesser General Public 
License for more details.

You should have received a copy of both the GNU Lesser General Public 
License version 3 and version 2.1 along with this program.  If not, see 
<http://www.gnu.org/licenses/>
*/

#ifndef __GENERICMENUITEM_H__
#define __GENERICMENUITEM_H__

#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define GENERICMENUITEM_TYPE            (genericmenuitem_get_type ())
#define GENERICMENUITEM(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), GENERICMENUITEM_TYPE, Genericmenuitem))
#define GENERICMENUITEM_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), GENERICMENUITEM_TYPE, GenericmenuitemClass))
#define IS_GENERICMENUITEM(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GENERICMENUITEM_TYPE))
#define IS_GENERICMENUITEM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), GENERICMENUITEM_TYPE))
#define GENERICMENUITEM_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), GENERICMENUITEM_TYPE, GenericmenuitemClass))

typedef struct _Genericmenuitem              Genericmenuitem;
typedef struct _GenericmenuitemClass         GenericmenuitemClass;
typedef struct _GenericmenuitemPrivate       GenericmenuitemPrivate;

/*
	GenericmenuitemClass:
	@parent_class: Our parent #GtkCheckMenuItemClass
*/
struct _GenericmenuitemClass {
	GtkCheckMenuItemClass parent_class;
};

/*
	Genericmenuitem:
	@parent: Our parent #GtkCheckMenuItem
*/
struct _Genericmenuitem {
	GtkCheckMenuItem parent;
	GenericmenuitemPrivate * priv;
};

/**
 * GenericmenuitemCheckType:
 * @GENERICMENUITEM_CHECK_TYPE_NONE: No check
 * @GENERICMENUITEM_CHECK_TYPE_CHECKBOX: Nice little check
 * @GENERICMENUITEM_CHECK_TYPE_RADIO: Radio button
 *
 * Tracks what type of checkmark should be shown on the item
 */
typedef enum { /*< prefix=GENERICMENUITEM_CHECK_TYPE >*/
	GENERICMENUITEM_CHECK_TYPE_NONE,
	GENERICMENUITEM_CHECK_TYPE_CHECKBOX,
	GENERICMENUITEM_CHECK_TYPE_RADIO
} GenericmenuitemCheckType;

/**
 * GenericmenuitemState:
 * @GENERICMENUITEM_STATE_UNCHECKED: No check visisble
 * @GENERICMENUITEM_STATE_CHECKED: Check visible
 * @GENERICMENUITEM_STATE_INDETERMINATE: We have no clue
 *
 * What the state of the check mark on the item is
 */
typedef enum { /*< prefix=GENERICMENUITEM_STATE >*/
	GENERICMENUITEM_STATE_UNCHECKED,
	GENERICMENUITEM_STATE_CHECKED,
	GENERICMENUITEM_STATE_INDETERMINATE
} GenericmenuitemState;

/**
 * GenericmenuitemDisposition:
 * @GENERICMENUITEM_DISPOSITION_NORMAL: Normal state
 * @GENERICMENUITEM_DISPOSITION_INFORMATIONAL: Item is informational
 * @GENERICMENUITEM_DISPOSITION_WARNING: Oh, you should watch out for this one
 * @GENERICMENUITEM_DISPOSITION_ALERT: Boom!
 *
 * What the disposition of the menu item is
 */
typedef enum { /*< prefix=GENERICMENUITEM_DISPOSITION >*/
	GENERICMENUITEM_DISPOSITION_NORMAL,
	GENERICMENUITEM_DISPOSITION_INFORMATIONAL,
	GENERICMENUITEM_DISPOSITION_WARNING,
	GENERICMENUITEM_DISPOSITION_ALERT
} GenericmenuitemDisposition;

GType                        genericmenuitem_get_type        (void);
void                         genericmenuitem_set_check_type  (Genericmenuitem *           item,
                                                              GenericmenuitemCheckType    check_type);
void                         genericmenuitem_set_state       (Genericmenuitem *           item,
                                                              GenericmenuitemState        state);
void                         genericmenuitem_set_image       (Genericmenuitem *           item,
                                                              GtkWidget *                 image);
GtkWidget *                  genericmenuitem_get_image       (Genericmenuitem *           item);
void                         genericmenuitem_set_disposition (Genericmenuitem *           item,
                                                              GenericmenuitemDisposition  disposition);
GenericmenuitemDisposition   genericmenuitem_get_disposition (Genericmenuitem *           item);

G_END_DECLS

#endif
