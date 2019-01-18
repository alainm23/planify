/*
 * Copyright (C) 2015 William Yu <williamyu@gnome.org>
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of version 2.1. of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "i-cal-object.h"

#define LOCK_PROPS(x) g_mutex_lock (&((x)->priv->props_lock))
#define UNLOCK_PROPS(x) g_mutex_unlock (&((x)->priv->props_lock))

struct _ICalObjectPrivate
{
    GMutex props_lock;  /* to guard all the below members */

    gpointer native;
    GDestroyNotify native_destroy_func;
    gboolean is_global_memory;
    GObject *owner;
    GSList *dependers;  /* referenced GObject-s */
};

G_DEFINE_ABSTRACT_TYPE(ICalObject, i_cal_object, G_TYPE_OBJECT)

enum
{
    PROP_0,
    PROP_NATIVE,
    PROP_NATIVE_DESTROY_FUNC,
    PROP_IS_GLOBAL_MEMORY,
    PROP_OWNER
};

static void i_cal_object_set_property(GObject *object, guint property_id,
                                      const GValue * value, GParamSpec * pspec)
{
    ICalObject *iobject;

    g_return_if_fail(I_CAL_IS_OBJECT(object));

    iobject = I_CAL_OBJECT(object);

    switch (property_id) {
    case PROP_NATIVE:
        /* no need for LOCK_PROPS() here, these can be set only during construction time */
        g_return_if_fail(iobject->priv->native == NULL);
        iobject->priv->native = g_value_get_pointer(value);
        return;

    case PROP_NATIVE_DESTROY_FUNC:
        i_cal_object_set_native_destroy_func(iobject, g_value_get_pointer(value));
        return;

    case PROP_IS_GLOBAL_MEMORY:
        /* no need for LOCK_PROPS() here, these can be set only during construction time */
        iobject->priv->is_global_memory = g_value_get_boolean(value);
        return;

    case PROP_OWNER:
        i_cal_object_set_owner(iobject, g_value_get_object(value));
        return;
    }

    G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
}

static void i_cal_object_get_property(GObject *object, guint property_id,
                                      GValue * value, GParamSpec * pspec)
{
    ICalObject *iobject;

    g_return_if_fail(I_CAL_IS_OBJECT(object));

    iobject = I_CAL_OBJECT(object);

    switch (property_id) {
    case PROP_NATIVE:
        g_value_set_pointer(value, i_cal_object_get_native(iobject));
        return;

    case PROP_NATIVE_DESTROY_FUNC:
        g_value_set_pointer(value, i_cal_object_get_native_destroy_func(iobject));
        return;

    case PROP_IS_GLOBAL_MEMORY:
        g_value_set_boolean(value, i_cal_object_get_is_global_memory(iobject));
        return;

    case PROP_OWNER:
        g_value_take_object(value, i_cal_object_ref_owner(iobject));
        return;
    }

    G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
}

static void i_cal_object_finalize(GObject *object)
{
    /* todo: Need to devise a way to check destroy_func and native */
    ICalObject *iobject = I_CAL_OBJECT(object);

    if (!iobject->priv->owner && !iobject->priv->is_global_memory) {
        iobject->priv->native_destroy_func(iobject->priv->native);
    }

    if (iobject->priv->owner) {
        g_object_unref(iobject->priv->owner);
    }

    g_slist_free_full(iobject->priv->dependers, g_object_unref);

    g_mutex_clear(&iobject->priv->props_lock);

    /* Chain up to parent's method. */
    G_OBJECT_CLASS(i_cal_object_parent_class)->finalize(object);
}

static void i_cal_object_class_init(ICalObjectClass * class)
{
    GObjectClass *object_class;

    g_type_class_add_private(class, sizeof(ICalObjectPrivate));

    object_class = G_OBJECT_CLASS(class);
    object_class->set_property = i_cal_object_set_property;
    object_class->get_property = i_cal_object_get_property;
    object_class->finalize = i_cal_object_finalize;

    /**
     * ICalObject:native:
     *
     * The native libical structure for this ICalObject.
     **/
    g_object_class_install_property(
        object_class,
        PROP_NATIVE,
        g_param_spec_pointer(
            "native",
            "Native",
            "Native libical structure",
            G_PARAM_READWRITE |
            G_PARAM_CONSTRUCT_ONLY |
            G_PARAM_STATIC_STRINGS));

    /**
     * ICalObject:native-destroy-func:
     *
     * GDestroyNotify function to use to destroy the native libical pointer.
     **/
    g_object_class_install_property(
        object_class,
        PROP_NATIVE_DESTROY_FUNC,
        g_param_spec_pointer(
            "native-destroy-func",
            "Native-Destroy-Func",
            "GDestroyNotify function to use to destroy the native libical structure",
            G_PARAM_READWRITE |
            G_PARAM_STATIC_STRINGS));

    /**
     * ICalObject:is-global-memory:
     *
     * Whether the native libical structure is from a global shared memory.
     * If TRUE, then it is not freed on #ICalObject's finalize.
     **/
    g_object_class_install_property(
        object_class,
        PROP_IS_GLOBAL_MEMORY,
        g_param_spec_boolean(
            "is-global-memory",
            "Is-Global-Memory",
            "Whether the native libical structure is from a global shared memory",
            FALSE,
            G_PARAM_READWRITE |
            G_PARAM_CONSTRUCT_ONLY |
            G_PARAM_STATIC_STRINGS));

    /**
     * ICalObject:owner:
     *
     * Owner of the native libical structure. If set, then it is
     * responsible for a free of the native libical structure.
     **/
    g_object_class_install_property(
        object_class,
        PROP_OWNER,
        g_param_spec_object(
            "owner",
            "Owner",
            "The native libical structure owner",
            G_TYPE_OBJECT,
            G_PARAM_READWRITE |
            G_PARAM_STATIC_STRINGS));
}

static void i_cal_object_init(ICalObject *iobject)
{
    iobject->priv = G_TYPE_INSTANCE_GET_PRIVATE(iobject, I_CAL_TYPE_OBJECT, ICalObjectPrivate);

    g_mutex_init(&iobject->priv->props_lock);
}

/**
 * i_cal_object_construct:
 * @iobject: an #ICalObject
 * @native: a native libical structure
 * @native_destroy_func: a function to be called on @native when it should be freed
 * @is_global_memory: whether @native is a global shared memory structure
 * @owner: (allow-none): an owner of @native
 *
 * Initialize private members of #iobject at once. The descendants should
 * call this function in their _new() function, or use corresponding properties
 * during the construction time. This should not be mixed, either use
 * properties or this function.
 *
 * Since: 1.0
 **/
void
i_cal_object_construct(ICalObject *iobject,
                       gpointer native,
                       GDestroyNotify native_destroy_func,
                       gboolean is_global_memory, GObject *owner)
{
    g_return_if_fail(I_CAL_IS_OBJECT(iobject));
    g_return_if_fail(native != NULL);
    if (owner)
        g_return_if_fail(G_IS_OBJECT(owner));

    /* LOCK_PROPS (iobject); */

    g_warn_if_fail(iobject->priv->native == NULL);

    iobject->priv->native = native;
    iobject->priv->native_destroy_func = native_destroy_func;
    iobject->priv->is_global_memory = is_global_memory;
    i_cal_object_set_owner(iobject, owner);

    /* UNLOCK_PROPS (iobject); */
}

/**
 * i_cal_object_get_native: (skip)
 * @iobject: an #ICalObject
 *
 * Obtain native libical structure pointer associated with this @iobject.
 *
 * Returns: (transfer none): Native libical structure pointer associated with this @iobject.
 *
 * Since: 1.0
 **/
gpointer i_cal_object_get_native(ICalObject *iobject)
{
    gpointer native;

    g_return_val_if_fail(I_CAL_IS_OBJECT(iobject), NULL);

    LOCK_PROPS(iobject);

    native = iobject->priv->native;

    UNLOCK_PROPS(iobject);

    return native;
}

/**
 * i_cal_object_steal_native:
 * @iobject: an #ICalObject
 *
 * Obtain native libical structure pointer associated with this @iobject and sets the one
 * at @iobject to NULL, thus it's invalid since now on.
 *
 * Returns: (transfer full): Native libical structure pointer associated with this @iobject.
 *
 * Since: 1.0
 **/
gpointer i_cal_object_steal_native(ICalObject *iobject)
{
    gpointer native;

    g_return_val_if_fail(I_CAL_IS_OBJECT(iobject), NULL);

    LOCK_PROPS(iobject);

    native = iobject->priv->native;
    iobject->priv->native = NULL;

    UNLOCK_PROPS(iobject);

    return native;
}

/**
 * i_cal_object_get_native_destroy_func: (skip)
 * @iobject: an #ICalObject
 *
 * Obtain a pointer to a function responsible to free the libical native structure.
 *
 * Returns: (transfer none): Pointer to a function responsible to free
 * the libical native structure.
 *
 * Since: 1.0
 **/
GDestroyNotify i_cal_object_get_native_destroy_func(ICalObject *iobject)
{
    GDestroyNotify func;

    g_return_val_if_fail(I_CAL_IS_OBJECT(iobject), NULL);

    LOCK_PROPS(iobject);

    func = iobject->priv->native_destroy_func;

    UNLOCK_PROPS(iobject);

    return func;
}

/**
 * i_cal_object_set_native_destroy_func:
 * @iobject: an #ICalObject
 * @native_destroy_func: Function to be used to destroy the native libical structure
 *
 * Sets a function to be used to destroy the native libical structure.
 *
 * Since: 1.0
 **/
void i_cal_object_set_native_destroy_func(ICalObject *iobject, GDestroyNotify native_destroy_func)
{
    g_return_if_fail(I_CAL_IS_OBJECT(iobject));

    LOCK_PROPS(iobject);

    if (native_destroy_func == iobject->priv->native_destroy_func) {
        UNLOCK_PROPS(iobject);
        return;
    }

    iobject->priv->native_destroy_func = native_destroy_func;

    UNLOCK_PROPS(iobject);

    g_object_notify(G_OBJECT(iobject), "native-destroy-func");
}

/**
 * i_cal_object_get_is_global_memory:
 * @iobject: an #ICalObject
 *
 * Obtains whether the native libical structure is a global shared memory,
 * thus should not be destroyed. This can be set only during contruction time.
 *
 * Returns: Whether the native libical structure is a global shared memory.
 *
 * Since: 1.0
 **/
gboolean i_cal_object_get_is_global_memory(ICalObject *iobject)
{
    gboolean is_global_memory;

    g_return_val_if_fail(I_CAL_IS_OBJECT(iobject), FALSE);

    LOCK_PROPS(iobject);

    is_global_memory = iobject->priv->is_global_memory;

    UNLOCK_PROPS(iobject);

    return is_global_memory;
}

/**
 * i_cal_object_set_owner:
 * @iobject: an #ICalObject
 * @owner: Owner of the native libical structure
 *
 * Sets an owner of the native libical structure, that is an object responsible
 * for a destroy of the native libical structure.
 *
 * Since: 1.0
 **/
void i_cal_object_set_owner(ICalObject *iobject, GObject *owner)
{
    g_return_if_fail(I_CAL_IS_OBJECT(iobject));
    if (owner)
        g_return_if_fail(G_IS_OBJECT(owner));

    LOCK_PROPS(iobject);

    if (owner == iobject->priv->owner) {
        UNLOCK_PROPS(iobject);
        return;
    }

    if (owner) {
        g_object_ref(owner);
    }
    g_clear_object(&iobject->priv->owner);
    iobject->priv->owner = owner;

    UNLOCK_PROPS(iobject);

    g_object_notify(G_OBJECT(iobject), "owner");
}

/**
 * i_cal_object_ref_owner:
 * @iobject: an #ICalObject
 *
 * Obtain current owner of the native libical structure. The returned pointer,
 * if not NULL, is referenced for thread safety. Unref it with g_object_unref
 * when done with it.
 *
 * Returns: (transfer full) (allow-none): Current owner of the libical
 *    native structure. returns NULL, when there is no owner.
 *
 * Since: 1.0
 **/
GObject *i_cal_object_ref_owner(ICalObject *iobject)
{
    GObject *owner;

    g_return_val_if_fail(I_CAL_IS_OBJECT(iobject), NULL);

    LOCK_PROPS(iobject);

    owner = iobject->priv->owner;
    if (owner)
        g_object_ref(owner);

    UNLOCK_PROPS(iobject);

    return owner;
}

/**
 * i_cal_object_remove_owner:
 * @iobject: an #ICalObject
 *
 * Unref and remove the owner.
 *
 * Since: 1.0
 **/
void i_cal_object_remove_owner(ICalObject *iobject)
{
    GObject *owner;

    g_return_if_fail(I_CAL_IS_OBJECT(iobject));

    LOCK_PROPS(iobject);

    owner = iobject->priv->owner;
    if (owner) {
        g_object_unref(owner);
        iobject->priv->owner = NULL;
    }

    UNLOCK_PROPS(iobject);
}

/**
 * i_cal_object_add_depender:
 * @iobject: an #ICalObject
 * @depender: a #GObject depender
 *
 * Adds a @depender into the list of objects which should not be destroyed before
 * this @iobject. It's usually used for cases where the @iobject uses native libical
 * structure from the @depender. The @depender is referenced. It's illegal to try
 * to add one @depender multiple times.
 *
 * Since: 1.0
 **/
void i_cal_object_add_depender(ICalObject *iobject, GObject *depender)
{
    g_return_if_fail(I_CAL_IS_OBJECT(iobject));
    g_return_if_fail(G_IS_OBJECT(depender));

    LOCK_PROPS(iobject);

    if (g_slist_find(iobject->priv->dependers, depender)) {
        g_warn_if_reached();
        UNLOCK_PROPS(iobject);
        return;
    }

    iobject->priv->dependers = g_slist_prepend(iobject->priv->dependers, g_object_ref(depender));

    UNLOCK_PROPS(iobject);
}

/**
 * i_cal_object_remove_depender:
 * @iobject: an #ICalObject
 * @depender: a #GObject depender
 *
 * Removes a @depender from the list of objects which should not be destroyed before
 * this @iobject, previously added with i_cal_object_add_depender(). It's illegal to try
 * to remove the @depender which is not in the internal list.
 *
 * Since: 1.0
 **/
void i_cal_object_remove_depender(ICalObject *iobject, GObject *depender)
{
    g_return_if_fail(I_CAL_IS_OBJECT(iobject));
    g_return_if_fail(G_IS_OBJECT(depender));

    LOCK_PROPS(iobject);

    if (!g_slist_find(iobject->priv->dependers, depender)) {
        g_warn_if_reached();
        UNLOCK_PROPS(iobject);
        return;
    }

    iobject->priv->dependers = g_slist_remove(iobject->priv->dependers, depender);
    g_object_unref(depender);

    UNLOCK_PROPS(iobject);
}
