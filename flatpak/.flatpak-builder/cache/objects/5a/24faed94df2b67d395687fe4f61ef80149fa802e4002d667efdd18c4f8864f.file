#include "_gen/tp-svc-channel.h"

static const DBusGObjectInfo _tp_svc_channel_object_info;

struct _TpSvcChannelClass {
    GTypeInterface parent_class;
    tp_svc_channel_close_impl close_cb;
    tp_svc_channel_get_channel_type_impl get_channel_type_cb;
    tp_svc_channel_get_handle_impl get_handle_cb;
    tp_svc_channel_get_interfaces_impl get_interfaces_cb;
};

enum {
    SIGNAL_CHANNEL_Closed,
    N_CHANNEL_SIGNALS
};
static guint channel_signals[N_CHANNEL_SIGNALS] = {0};

static void tp_svc_channel_base_init (gpointer klass);

GType
tp_svc_channel_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelClass),
        tp_svc_channel_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannel", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_close (TpSvcChannel *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_close_impl impl = (TP_SVC_CHANNEL_GET_CLASS (self)->close_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_implement_close (TpSvcChannelClass *klass, tp_svc_channel_close_impl impl)
{
  klass->close_cb = impl;
}

static void
tp_svc_channel_get_channel_type (TpSvcChannel *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_get_channel_type_impl impl = (TP_SVC_CHANNEL_GET_CLASS (self)->get_channel_type_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_implement_get_channel_type (TpSvcChannelClass *klass, tp_svc_channel_get_channel_type_impl impl)
{
  klass->get_channel_type_cb = impl;
}

static void
tp_svc_channel_get_handle (TpSvcChannel *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_get_handle_impl impl = (TP_SVC_CHANNEL_GET_CLASS (self)->get_handle_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_implement_get_handle (TpSvcChannelClass *klass, tp_svc_channel_get_handle_impl impl)
{
  klass->get_handle_cb = impl;
}

static void
tp_svc_channel_get_interfaces (TpSvcChannel *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_get_interfaces_impl impl = (TP_SVC_CHANNEL_GET_CLASS (self)->get_interfaces_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_implement_get_interfaces (TpSvcChannelClass *klass, tp_svc_channel_get_interfaces_impl impl)
{
  klass->get_interfaces_cb = impl;
}

void
tp_svc_channel_emit_closed (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL));
  g_signal_emit (instance,
      channel_signals[SIGNAL_CHANNEL_Closed],
      0);
}

static inline void
tp_svc_channel_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[9] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ChannelType */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* TargetHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* TargetID */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* TargetHandleType */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Requested */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* InitiatorHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* InitiatorID */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_get_type (),
      &_tp_svc_channel_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel");
  properties[0].name = g_quark_from_static_string ("ChannelType");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("Interfaces");
  properties[1].type = G_TYPE_STRV;
  properties[2].name = g_quark_from_static_string ("TargetHandle");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("TargetID");
  properties[3].type = G_TYPE_STRING;
  properties[4].name = g_quark_from_static_string ("TargetHandleType");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("Requested");
  properties[5].type = G_TYPE_BOOLEAN;
  properties[6].name = g_quark_from_static_string ("InitiatorHandle");
  properties[6].type = G_TYPE_UINT;
  properties[7].name = g_quark_from_static_string ("InitiatorID");
  properties[7].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL, &interface);

  channel_signals[SIGNAL_CHANNEL_Closed] =
  g_signal_new ("closed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

}
static void
tp_svc_channel_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_methods[] = {
  { (GCallback) tp_svc_channel_close, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_get_channel_type, g_cclosure_marshal_generic, 43 },
  { (GCallback) tp_svc_channel_get_handle, g_cclosure_marshal_generic, 116 },
  { (GCallback) tp_svc_channel_get_interfaces, g_cclosure_marshal_generic, 212 },
};

static const DBusGObjectInfo _tp_svc_channel_object_info = {
  0,
  _tp_svc_channel_methods,
  4,
"org.freedesktop.Telepathy.Channel\0Close\0A\0\0org.freedesktop.Telepathy.Channel\0GetChannelType\0A\0Channel_Type\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel\0GetHandle\0A\0Target_Handle_Type\0O\0F\0N\0u\0Target_Handle\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel\0GetInterfaces\0A\0Interfaces\0O\0F\0N\0as\0\0\0",
"org.freedesktop.Telepathy.Channel\0Closed\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_anonymity_object_info;

struct _TpSvcChannelInterfaceAnonymityClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_interface_anonymity_base_init (gpointer klass);

GType
tp_svc_channel_interface_anonymity_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceAnonymityClass),
        tp_svc_channel_interface_anonymity_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceAnonymity", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_interface_anonymity_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* AnonymityModes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* AnonymityMandatory */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* AnonymousID */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_anonymity_get_type (),
      &_tp_svc_channel_interface_anonymity_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Anonymity");
  properties[0].name = g_quark_from_static_string ("AnonymityModes");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("AnonymityMandatory");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("AnonymousID");
  properties[2].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_ANONYMITY, &interface);

}
static void
tp_svc_channel_interface_anonymity_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_anonymity_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_anonymity_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_anonymity_object_info = {
  0,
  _tp_svc_channel_interface_anonymity_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_call_state_object_info;

struct _TpSvcChannelInterfaceCallStateClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_call_state_get_call_states_impl get_call_states_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_CALL_STATE_CallStateChanged,
    N_CHANNEL_INTERFACE_CALL_STATE_SIGNALS
};
static guint channel_interface_call_state_signals[N_CHANNEL_INTERFACE_CALL_STATE_SIGNALS] = {0};

static void tp_svc_channel_interface_call_state_base_init (gpointer klass);

GType
tp_svc_channel_interface_call_state_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceCallStateClass),
        tp_svc_channel_interface_call_state_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceCallState", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_call_state_get_call_states (TpSvcChannelInterfaceCallState *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_call_state_get_call_states_impl impl = (TP_SVC_CHANNEL_INTERFACE_CALL_STATE_GET_CLASS (self)->get_call_states_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_call_state_implement_get_call_states (TpSvcChannelInterfaceCallStateClass *klass, tp_svc_channel_interface_call_state_get_call_states_impl impl)
{
  klass->get_call_states_cb = impl;
}

void
tp_svc_channel_interface_call_state_emit_call_state_changed (gpointer instance,
    guint arg_Contact,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_CALL_STATE));
  g_signal_emit (instance,
      channel_interface_call_state_signals[SIGNAL_CHANNEL_INTERFACE_CALL_STATE_CallStateChanged],
      0,
      arg_Contact,
      arg_State);
}

static inline void
tp_svc_channel_interface_call_state_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_interface_call_state_get_type (),
      &_tp_svc_channel_interface_call_state_object_info);

  channel_interface_call_state_signals[SIGNAL_CHANNEL_INTERFACE_CALL_STATE_CallStateChanged] =
  g_signal_new ("call-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_interface_call_state_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_call_state_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_call_state_methods[] = {
  { (GCallback) tp_svc_channel_interface_call_state_get_call_states, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_call_state_object_info = {
  0,
  _tp_svc_channel_interface_call_state_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.CallState\0GetCallStates\0A\0States\0O\0F\0N\0a{uu}\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.CallState\0CallStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_captcha_authentication_object_info;

struct _TpSvcChannelInterfaceCaptchaAuthenticationClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_captcha_authentication_get_captchas_impl get_captchas_cb;
    tp_svc_channel_interface_captcha_authentication_get_captcha_data_impl get_captcha_data_cb;
    tp_svc_channel_interface_captcha_authentication_answer_captchas_impl answer_captchas_cb;
    tp_svc_channel_interface_captcha_authentication_cancel_captcha_impl cancel_captcha_cb;
};

static void tp_svc_channel_interface_captcha_authentication_base_init (gpointer klass);

GType
tp_svc_channel_interface_captcha_authentication_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceCaptchaAuthenticationClass),
        tp_svc_channel_interface_captcha_authentication_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceCaptchaAuthentication", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_captcha_authentication_get_captchas (TpSvcChannelInterfaceCaptchaAuthentication *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_captcha_authentication_get_captchas_impl impl = (TP_SVC_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION_GET_CLASS (self)->get_captchas_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_captcha_authentication_implement_get_captchas (TpSvcChannelInterfaceCaptchaAuthenticationClass *klass, tp_svc_channel_interface_captcha_authentication_get_captchas_impl impl)
{
  klass->get_captchas_cb = impl;
}

static void
tp_svc_channel_interface_captcha_authentication_get_captcha_data (TpSvcChannelInterfaceCaptchaAuthentication *self,
    guint in_ID,
    const gchar *in_Mime_Type,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_captcha_authentication_get_captcha_data_impl impl = (TP_SVC_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION_GET_CLASS (self)->get_captcha_data_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        in_Mime_Type,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_captcha_authentication_implement_get_captcha_data (TpSvcChannelInterfaceCaptchaAuthenticationClass *klass, tp_svc_channel_interface_captcha_authentication_get_captcha_data_impl impl)
{
  klass->get_captcha_data_cb = impl;
}

static void
tp_svc_channel_interface_captcha_authentication_answer_captchas (TpSvcChannelInterfaceCaptchaAuthentication *self,
    GHashTable *in_Answers,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_captcha_authentication_answer_captchas_impl impl = (TP_SVC_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION_GET_CLASS (self)->answer_captchas_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Answers,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_captcha_authentication_implement_answer_captchas (TpSvcChannelInterfaceCaptchaAuthenticationClass *klass, tp_svc_channel_interface_captcha_authentication_answer_captchas_impl impl)
{
  klass->answer_captchas_cb = impl;
}

static void
tp_svc_channel_interface_captcha_authentication_cancel_captcha (TpSvcChannelInterfaceCaptchaAuthentication *self,
    guint in_Reason,
    const gchar *in_Debug_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_captcha_authentication_cancel_captcha_impl impl = (TP_SVC_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION_GET_CLASS (self)->cancel_captcha_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        in_Debug_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_captcha_authentication_implement_cancel_captcha (TpSvcChannelInterfaceCaptchaAuthenticationClass *klass, tp_svc_channel_interface_captcha_authentication_cancel_captcha_impl impl)
{
  klass->cancel_captcha_cb = impl;
}

static inline void
tp_svc_channel_interface_captcha_authentication_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* CanRetryCaptcha */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "u", 0, NULL, NULL }, /* CaptchaStatus */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* CaptchaError */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "a{sv}", 0, NULL, NULL }, /* CaptchaErrorDetails */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_captcha_authentication_get_type (),
      &_tp_svc_channel_interface_captcha_authentication_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.CaptchaAuthentication1");
  properties[0].name = g_quark_from_static_string ("CanRetryCaptcha");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("CaptchaStatus");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("CaptchaError");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("CaptchaErrorDetails");
  properties[3].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_CAPTCHA_AUTHENTICATION, &interface);

}
static void
tp_svc_channel_interface_captcha_authentication_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_captcha_authentication_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_captcha_authentication_methods[] = {
  { (GCallback) tp_svc_channel_interface_captcha_authentication_get_captchas, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_captcha_authentication_get_captcha_data, g_cclosure_marshal_generic, 152 },
  { (GCallback) tp_svc_channel_interface_captcha_authentication_answer_captchas, g_cclosure_marshal_generic, 280 },
  { (GCallback) tp_svc_channel_interface_captcha_authentication_cancel_captcha, g_cclosure_marshal_generic, 381 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_captcha_authentication_object_info = {
  0,
  _tp_svc_channel_interface_captcha_authentication_methods,
  4,
"org.freedesktop.Telepathy.Channel.Interface.CaptchaAuthentication1\0GetCaptchas\0A\0Captcha_Info\0O\0F\0N\0a(ussuas)\0Number_Required\0O\0F\0N\0u\0Language\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel.Interface.CaptchaAuthentication1\0GetCaptchaData\0A\0ID\0I\0u\0Mime_Type\0I\0s\0Captcha_Data\0O\0F\0N\0ay\0\0org.freedesktop.Telepathy.Channel.Interface.CaptchaAuthentication1\0AnswerCaptchas\0A\0Answers\0I\0a{us}\0\0org.freedesktop.Telepathy.Channel.Interface.CaptchaAuthentication1\0CancelCaptcha\0A\0Reason\0I\0u\0Debug_Message\0I\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_chat_state_object_info;

struct _TpSvcChannelInterfaceChatStateClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_chat_state_set_chat_state_impl set_chat_state_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_CHAT_STATE_ChatStateChanged,
    N_CHANNEL_INTERFACE_CHAT_STATE_SIGNALS
};
static guint channel_interface_chat_state_signals[N_CHANNEL_INTERFACE_CHAT_STATE_SIGNALS] = {0};

static void tp_svc_channel_interface_chat_state_base_init (gpointer klass);

GType
tp_svc_channel_interface_chat_state_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceChatStateClass),
        tp_svc_channel_interface_chat_state_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceChatState", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_chat_state_set_chat_state (TpSvcChannelInterfaceChatState *self,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_chat_state_set_chat_state_impl impl = (TP_SVC_CHANNEL_INTERFACE_CHAT_STATE_GET_CLASS (self)->set_chat_state_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_chat_state_implement_set_chat_state (TpSvcChannelInterfaceChatStateClass *klass, tp_svc_channel_interface_chat_state_set_chat_state_impl impl)
{
  klass->set_chat_state_cb = impl;
}

void
tp_svc_channel_interface_chat_state_emit_chat_state_changed (gpointer instance,
    guint arg_Contact,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_CHAT_STATE));
  g_signal_emit (instance,
      channel_interface_chat_state_signals[SIGNAL_CHANNEL_INTERFACE_CHAT_STATE_ChatStateChanged],
      0,
      arg_Contact,
      arg_State);
}

static inline void
tp_svc_channel_interface_chat_state_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uu}", 0, NULL, NULL }, /* ChatStates */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_chat_state_get_type (),
      &_tp_svc_channel_interface_chat_state_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.ChatState");
  properties[0].name = g_quark_from_static_string ("ChatStates");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_CHAT_STATE, &interface);

  channel_interface_chat_state_signals[SIGNAL_CHANNEL_INTERFACE_CHAT_STATE_ChatStateChanged] =
  g_signal_new ("chat-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_interface_chat_state_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_chat_state_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_chat_state_methods[] = {
  { (GCallback) tp_svc_channel_interface_chat_state_set_chat_state, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_chat_state_object_info = {
  0,
  _tp_svc_channel_interface_chat_state_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.ChatState\0SetChatState\0A\0State\0I\0u\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.ChatState\0ChatStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_conference_object_info;

struct _TpSvcChannelInterfaceConferenceClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelMerged,
    SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelRemoved,
    N_CHANNEL_INTERFACE_CONFERENCE_SIGNALS
};
static guint channel_interface_conference_signals[N_CHANNEL_INTERFACE_CONFERENCE_SIGNALS] = {0};

static void tp_svc_channel_interface_conference_base_init (gpointer klass);

GType
tp_svc_channel_interface_conference_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceConferenceClass),
        tp_svc_channel_interface_conference_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceConference", &info, 0);
    }

  return type;
}

void
tp_svc_channel_interface_conference_emit_channel_merged (gpointer instance,
    const gchar *arg_Channel,
    guint arg_Channel_Specific_Handle,
    GHashTable *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_CONFERENCE));
  g_signal_emit (instance,
      channel_interface_conference_signals[SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelMerged],
      0,
      arg_Channel,
      arg_Channel_Specific_Handle,
      arg_Properties);
}

void
tp_svc_channel_interface_conference_emit_channel_removed (gpointer instance,
    const gchar *arg_Channel,
    GHashTable *arg_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_CONFERENCE));
  g_signal_emit (instance,
      channel_interface_conference_signals[SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelRemoved],
      0,
      arg_Channel,
      arg_Details);
}

static inline void
tp_svc_channel_interface_conference_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[7] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* Channels */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* InitialChannels */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* InitialInviteeHandles */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* InitialInviteeIDs */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* InvitationMessage */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uo}", 0, NULL, NULL }, /* OriginalChannels */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_conference_get_type (),
      &_tp_svc_channel_interface_conference_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Conference");
  properties[0].name = g_quark_from_static_string ("Channels");
  properties[0].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[1].name = g_quark_from_static_string ("InitialChannels");
  properties[1].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[2].name = g_quark_from_static_string ("InitialInviteeHandles");
  properties[2].type = DBUS_TYPE_G_UINT_ARRAY;
  properties[3].name = g_quark_from_static_string ("InitialInviteeIDs");
  properties[3].type = G_TYPE_STRV;
  properties[4].name = g_quark_from_static_string ("InvitationMessage");
  properties[4].type = G_TYPE_STRING;
  properties[5].name = g_quark_from_static_string ("OriginalChannels");
  properties[5].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_OBJECT_PATH));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_CONFERENCE, &interface);

  channel_interface_conference_signals[SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelMerged] =
  g_signal_new ("channel-merged",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  channel_interface_conference_signals[SIGNAL_CHANNEL_INTERFACE_CONFERENCE_ChannelRemoved] =
  g_signal_new ("channel-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

}
static void
tp_svc_channel_interface_conference_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_conference_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_conference_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_conference_object_info = {
  0,
  _tp_svc_channel_interface_conference_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Channel.Interface.Conference\0ChannelMerged\0org.freedesktop.Telepathy.Channel.Interface.Conference\0ChannelRemoved\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_dtmf_object_info;

struct _TpSvcChannelInterfaceDTMFClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_dtmf_start_tone_impl start_tone_cb;
    tp_svc_channel_interface_dtmf_stop_tone_impl stop_tone_cb;
    tp_svc_channel_interface_dtmf_multiple_tones_impl multiple_tones_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_DTMF_TonesDeferred,
    SIGNAL_CHANNEL_INTERFACE_DTMF_SendingTones,
    SIGNAL_CHANNEL_INTERFACE_DTMF_StoppedTones,
    N_CHANNEL_INTERFACE_DTMF_SIGNALS
};
static guint channel_interface_dtmf_signals[N_CHANNEL_INTERFACE_DTMF_SIGNALS] = {0};

static void tp_svc_channel_interface_dtmf_base_init (gpointer klass);

GType
tp_svc_channel_interface_dtmf_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceDTMFClass),
        tp_svc_channel_interface_dtmf_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceDTMF", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_dtmf_start_tone (TpSvcChannelInterfaceDTMF *self,
    guint in_Stream_ID,
    guchar in_Event,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_dtmf_start_tone_impl impl = (TP_SVC_CHANNEL_INTERFACE_DTMF_GET_CLASS (self)->start_tone_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Stream_ID,
        in_Event,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_dtmf_implement_start_tone (TpSvcChannelInterfaceDTMFClass *klass, tp_svc_channel_interface_dtmf_start_tone_impl impl)
{
  klass->start_tone_cb = impl;
}

static void
tp_svc_channel_interface_dtmf_stop_tone (TpSvcChannelInterfaceDTMF *self,
    guint in_Stream_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_dtmf_stop_tone_impl impl = (TP_SVC_CHANNEL_INTERFACE_DTMF_GET_CLASS (self)->stop_tone_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Stream_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_dtmf_implement_stop_tone (TpSvcChannelInterfaceDTMFClass *klass, tp_svc_channel_interface_dtmf_stop_tone_impl impl)
{
  klass->stop_tone_cb = impl;
}

static void
tp_svc_channel_interface_dtmf_multiple_tones (TpSvcChannelInterfaceDTMF *self,
    const gchar *in_Tones,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_dtmf_multiple_tones_impl impl = (TP_SVC_CHANNEL_INTERFACE_DTMF_GET_CLASS (self)->multiple_tones_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Tones,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_dtmf_implement_multiple_tones (TpSvcChannelInterfaceDTMFClass *klass, tp_svc_channel_interface_dtmf_multiple_tones_impl impl)
{
  klass->multiple_tones_cb = impl;
}

void
tp_svc_channel_interface_dtmf_emit_tones_deferred (gpointer instance,
    const gchar *arg_Tones)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_DTMF));
  g_signal_emit (instance,
      channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_TonesDeferred],
      0,
      arg_Tones);
}

void
tp_svc_channel_interface_dtmf_emit_sending_tones (gpointer instance,
    const gchar *arg_Tones)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_DTMF));
  g_signal_emit (instance,
      channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_SendingTones],
      0,
      arg_Tones);
}

void
tp_svc_channel_interface_dtmf_emit_stopped_tones (gpointer instance,
    gboolean arg_Cancelled)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_DTMF));
  g_signal_emit (instance,
      channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_StoppedTones],
      0,
      arg_Cancelled);
}

static inline void
tp_svc_channel_interface_dtmf_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CurrentlySendingTones */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* InitialTones */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* DeferredTones */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_dtmf_get_type (),
      &_tp_svc_channel_interface_dtmf_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.DTMF");
  properties[0].name = g_quark_from_static_string ("CurrentlySendingTones");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("InitialTones");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("DeferredTones");
  properties[2].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_DTMF, &interface);

  channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_TonesDeferred] =
  g_signal_new ("tones-deferred",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

  channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_SendingTones] =
  g_signal_new ("sending-tones",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

  channel_interface_dtmf_signals[SIGNAL_CHANNEL_INTERFACE_DTMF_StoppedTones] =
  g_signal_new ("stopped-tones",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_channel_interface_dtmf_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_dtmf_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_dtmf_methods[] = {
  { (GCallback) tp_svc_channel_interface_dtmf_start_tone, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_dtmf_stop_tone, g_cclosure_marshal_generic, 86 },
  { (GCallback) tp_svc_channel_interface_dtmf_multiple_tones, g_cclosure_marshal_generic, 161 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_dtmf_object_info = {
  0,
  _tp_svc_channel_interface_dtmf_methods,
  3,
"org.freedesktop.Telepathy.Channel.Interface.DTMF\0StartTone\0A\0Stream_ID\0I\0u\0Event\0I\0y\0\0org.freedesktop.Telepathy.Channel.Interface.DTMF\0StopTone\0A\0Stream_ID\0I\0u\0\0org.freedesktop.Telepathy.Channel.Interface.DTMF\0MultipleTones\0A\0Tones\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.DTMF\0TonesDeferred\0org.freedesktop.Telepathy.Channel.Interface.DTMF\0SendingTones\0org.freedesktop.Telepathy.Channel.Interface.DTMF\0StoppedTones\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_destroyable_object_info;

struct _TpSvcChannelInterfaceDestroyableClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_destroyable_destroy_impl destroy_cb;
};

static void tp_svc_channel_interface_destroyable_base_init (gpointer klass);

GType
tp_svc_channel_interface_destroyable_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceDestroyableClass),
        tp_svc_channel_interface_destroyable_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceDestroyable", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_destroyable_destroy (TpSvcChannelInterfaceDestroyable *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_destroyable_destroy_impl impl = (TP_SVC_CHANNEL_INTERFACE_DESTROYABLE_GET_CLASS (self)->destroy_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_destroyable_implement_destroy (TpSvcChannelInterfaceDestroyableClass *klass, tp_svc_channel_interface_destroyable_destroy_impl impl)
{
  klass->destroy_cb = impl;
}

static inline void
tp_svc_channel_interface_destroyable_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_interface_destroyable_get_type (),
      &_tp_svc_channel_interface_destroyable_object_info);

}
static void
tp_svc_channel_interface_destroyable_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_destroyable_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_destroyable_methods[] = {
  { (GCallback) tp_svc_channel_interface_destroyable_destroy, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_destroyable_object_info = {
  0,
  _tp_svc_channel_interface_destroyable_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.Destroyable\0Destroy\0A\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_file_transfer_metadata_object_info;

struct _TpSvcChannelInterfaceFileTransferMetadataClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_interface_file_transfer_metadata_base_init (gpointer klass);

GType
tp_svc_channel_interface_file_transfer_metadata_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceFileTransferMetadataClass),
        tp_svc_channel_interface_file_transfer_metadata_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceFileTransferMetadata", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_interface_file_transfer_metadata_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* ServiceName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "a{sas}", 0, NULL, NULL }, /* Metadata */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_file_transfer_metadata_get_type (),
      &_tp_svc_channel_interface_file_transfer_metadata_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.FileTransfer.Metadata");
  properties[0].name = g_quark_from_static_string ("ServiceName");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("Metadata");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_STRV));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_FILE_TRANSFER_METADATA, &interface);

}
static void
tp_svc_channel_interface_file_transfer_metadata_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_file_transfer_metadata_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_file_transfer_metadata_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_file_transfer_metadata_object_info = {
  0,
  _tp_svc_channel_interface_file_transfer_metadata_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_group_object_info;

struct _TpSvcChannelInterfaceGroupClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_group_add_members_impl add_members_cb;
    tp_svc_channel_interface_group_get_all_members_impl get_all_members_cb;
    tp_svc_channel_interface_group_get_group_flags_impl get_group_flags_cb;
    tp_svc_channel_interface_group_get_handle_owners_impl get_handle_owners_cb;
    tp_svc_channel_interface_group_get_local_pending_members_impl get_local_pending_members_cb;
    tp_svc_channel_interface_group_get_local_pending_members_with_info_impl get_local_pending_members_with_info_cb;
    tp_svc_channel_interface_group_get_members_impl get_members_cb;
    tp_svc_channel_interface_group_get_remote_pending_members_impl get_remote_pending_members_cb;
    tp_svc_channel_interface_group_get_self_handle_impl get_self_handle_cb;
    tp_svc_channel_interface_group_remove_members_impl remove_members_cb;
    tp_svc_channel_interface_group_remove_members_with_reason_impl remove_members_with_reason_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChanged,
    SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChangedDetailed,
    SIGNAL_CHANNEL_INTERFACE_GROUP_SelfHandleChanged,
    SIGNAL_CHANNEL_INTERFACE_GROUP_SelfContactChanged,
    SIGNAL_CHANNEL_INTERFACE_GROUP_GroupFlagsChanged,
    SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChanged,
    SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChangedDetailed,
    N_CHANNEL_INTERFACE_GROUP_SIGNALS
};
static guint channel_interface_group_signals[N_CHANNEL_INTERFACE_GROUP_SIGNALS] = {0};

static void tp_svc_channel_interface_group_base_init (gpointer klass);

GType
tp_svc_channel_interface_group_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceGroupClass),
        tp_svc_channel_interface_group_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceGroup", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_group_add_members (TpSvcChannelInterfaceGroup *self,
    const GArray *in_Contacts,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_add_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->add_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_add_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_add_members_impl impl)
{
  klass->add_members_cb = impl;
}

static void
tp_svc_channel_interface_group_get_all_members (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_all_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_all_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_all_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_all_members_impl impl)
{
  klass->get_all_members_cb = impl;
}

static void
tp_svc_channel_interface_group_get_group_flags (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_group_flags_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_group_flags_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_group_flags (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_group_flags_impl impl)
{
  klass->get_group_flags_cb = impl;
}

static void
tp_svc_channel_interface_group_get_handle_owners (TpSvcChannelInterfaceGroup *self,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_handle_owners_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_handle_owners_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_handle_owners (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_handle_owners_impl impl)
{
  klass->get_handle_owners_cb = impl;
}

static void
tp_svc_channel_interface_group_get_local_pending_members (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_local_pending_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_local_pending_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_local_pending_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_local_pending_members_impl impl)
{
  klass->get_local_pending_members_cb = impl;
}

static void
tp_svc_channel_interface_group_get_local_pending_members_with_info (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_local_pending_members_with_info_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_local_pending_members_with_info_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_local_pending_members_with_info (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_local_pending_members_with_info_impl impl)
{
  klass->get_local_pending_members_with_info_cb = impl;
}

static void
tp_svc_channel_interface_group_get_members (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_members_impl impl)
{
  klass->get_members_cb = impl;
}

static void
tp_svc_channel_interface_group_get_remote_pending_members (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_remote_pending_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_remote_pending_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_remote_pending_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_remote_pending_members_impl impl)
{
  klass->get_remote_pending_members_cb = impl;
}

static void
tp_svc_channel_interface_group_get_self_handle (TpSvcChannelInterfaceGroup *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_get_self_handle_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->get_self_handle_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_get_self_handle (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_get_self_handle_impl impl)
{
  klass->get_self_handle_cb = impl;
}

static void
tp_svc_channel_interface_group_remove_members (TpSvcChannelInterfaceGroup *self,
    const GArray *in_Contacts,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_remove_members_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->remove_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_remove_members (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_remove_members_impl impl)
{
  klass->remove_members_cb = impl;
}

static void
tp_svc_channel_interface_group_remove_members_with_reason (TpSvcChannelInterfaceGroup *self,
    const GArray *in_Contacts,
    const gchar *in_Message,
    guint in_Reason,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_group_remove_members_with_reason_impl impl = (TP_SVC_CHANNEL_INTERFACE_GROUP_GET_CLASS (self)->remove_members_with_reason_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        in_Message,
        in_Reason,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_group_implement_remove_members_with_reason (TpSvcChannelInterfaceGroupClass *klass, tp_svc_channel_interface_group_remove_members_with_reason_impl impl)
{
  klass->remove_members_with_reason_cb = impl;
}

void
tp_svc_channel_interface_group_emit_handle_owners_changed (gpointer instance,
    GHashTable *arg_Added,
    const GArray *arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChanged],
      0,
      arg_Added,
      arg_Removed);
}

void
tp_svc_channel_interface_group_emit_handle_owners_changed_detailed (gpointer instance,
    GHashTable *arg_Added,
    const GArray *arg_Removed,
    GHashTable *arg_Identifiers)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChangedDetailed],
      0,
      arg_Added,
      arg_Removed,
      arg_Identifiers);
}

void
tp_svc_channel_interface_group_emit_self_handle_changed (gpointer instance,
    guint arg_Self_Handle)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_SelfHandleChanged],
      0,
      arg_Self_Handle);
}

void
tp_svc_channel_interface_group_emit_self_contact_changed (gpointer instance,
    guint arg_Self_Handle,
    const gchar *arg_Self_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_SelfContactChanged],
      0,
      arg_Self_Handle,
      arg_Self_ID);
}

void
tp_svc_channel_interface_group_emit_group_flags_changed (gpointer instance,
    guint arg_Added,
    guint arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_GroupFlagsChanged],
      0,
      arg_Added,
      arg_Removed);
}

void
tp_svc_channel_interface_group_emit_members_changed (gpointer instance,
    const gchar *arg_Message,
    const GArray *arg_Added,
    const GArray *arg_Removed,
    const GArray *arg_Local_Pending,
    const GArray *arg_Remote_Pending,
    guint arg_Actor,
    guint arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChanged],
      0,
      arg_Message,
      arg_Added,
      arg_Removed,
      arg_Local_Pending,
      arg_Remote_Pending,
      arg_Actor,
      arg_Reason);
}

void
tp_svc_channel_interface_group_emit_members_changed_detailed (gpointer instance,
    const GArray *arg_Added,
    const GArray *arg_Removed,
    const GArray *arg_Local_Pending,
    const GArray *arg_Remote_Pending,
    GHashTable *arg_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP));
  g_signal_emit (instance,
      channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChangedDetailed],
      0,
      arg_Added,
      arg_Removed,
      arg_Local_Pending,
      arg_Remote_Pending,
      arg_Details);
}

static inline void
tp_svc_channel_interface_group_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[8] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* GroupFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uu}", 0, NULL, NULL }, /* HandleOwners */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(uuus)", 0, NULL, NULL }, /* LocalPendingMembers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* Members */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* RemotePendingMembers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SelfHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{us}", 0, NULL, NULL }, /* MemberIdentifiers */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_group_get_type (),
      &_tp_svc_channel_interface_group_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Group");
  properties[0].name = g_quark_from_static_string ("GroupFlags");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("HandleOwners");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT));
  properties[2].name = g_quark_from_static_string ("LocalPendingMembers");
  properties[2].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID))));
  properties[3].name = g_quark_from_static_string ("Members");
  properties[3].type = DBUS_TYPE_G_UINT_ARRAY;
  properties[4].name = g_quark_from_static_string ("RemotePendingMembers");
  properties[4].type = DBUS_TYPE_G_UINT_ARRAY;
  properties[5].name = g_quark_from_static_string ("SelfHandle");
  properties[5].type = G_TYPE_UINT;
  properties[6].name = g_quark_from_static_string ("MemberIdentifiers");
  properties[6].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP, &interface);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChanged] =
  g_signal_new ("handle-owners-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_HandleOwnersChangedDetailed] =
  g_signal_new ("handle-owners-changed-detailed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_SelfHandleChanged] =
  g_signal_new ("self-handle-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_SelfContactChanged] =
  g_signal_new ("self-contact-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_STRING);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_GroupFlagsChanged] =
  g_signal_new ("group-flags-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChanged] =
  g_signal_new ("members-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      7,
      G_TYPE_STRING,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_interface_group_signals[SIGNAL_CHANNEL_INTERFACE_GROUP_MembersChangedDetailed] =
  g_signal_new ("members-changed-detailed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      5,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

}
static void
tp_svc_channel_interface_group_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_group_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_group_methods[] = {
  { (GCallback) tp_svc_channel_interface_group_add_members, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_group_get_all_members, g_cclosure_marshal_generic, 90 },
  { (GCallback) tp_svc_channel_interface_group_get_group_flags, g_cclosure_marshal_generic, 221 },
  { (GCallback) tp_svc_channel_interface_group_get_handle_owners, g_cclosure_marshal_generic, 308 },
  { (GCallback) tp_svc_channel_interface_group_get_local_pending_members, g_cclosure_marshal_generic, 406 },
  { (GCallback) tp_svc_channel_interface_group_get_local_pending_members_with_info, g_cclosure_marshal_generic, 499 },
  { (GCallback) tp_svc_channel_interface_group_get_members, g_cclosure_marshal_generic, 602 },
  { (GCallback) tp_svc_channel_interface_group_get_remote_pending_members, g_cclosure_marshal_generic, 683 },
  { (GCallback) tp_svc_channel_interface_group_get_self_handle, g_cclosure_marshal_generic, 777 },
  { (GCallback) tp_svc_channel_interface_group_remove_members, g_cclosure_marshal_generic, 864 },
  { (GCallback) tp_svc_channel_interface_group_remove_members_with_reason, g_cclosure_marshal_generic, 957 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_group_object_info = {
  0,
  _tp_svc_channel_interface_group_methods,
  11,
"org.freedesktop.Telepathy.Channel.Interface.Group\0AddMembers\0A\0Contacts\0I\0au\0Message\0I\0s\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetAllMembers\0A\0Members\0O\0F\0N\0au\0Local_Pending\0O\0F\0N\0au\0Remote_Pending\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetGroupFlags\0A\0Group_Flags\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetHandleOwners\0A\0Handles\0I\0au\0Owners\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetLocalPendingMembers\0A\0Handles\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetLocalPendingMembersWithInfo\0A\0Info\0O\0F\0N\0a(uuus)\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetMembers\0A\0Handles\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetRemotePendingMembers\0A\0Handles\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0GetSelfHandle\0A\0Self_Handle\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0RemoveMembers\0A\0Contacts\0I\0au\0Message\0I\0s\0\0org.freedesktop.Telepathy.Channel.Interface.Group\0RemoveMembersWithReason\0A\0Contacts\0I\0au\0Message\0I\0s\0Reason\0I\0u\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.Group\0HandleOwnersChanged\0org.freedesktop.Telepathy.Channel.Interface.Group\0HandleOwnersChangedDetailed\0org.freedesktop.Telepathy.Channel.Interface.Group\0SelfHandleChanged\0org.freedesktop.Telepathy.Channel.Interface.Group\0SelfContactChanged\0org.freedesktop.Telepathy.Channel.Interface.Group\0GroupFlagsChanged\0org.freedesktop.Telepathy.Channel.Interface.Group\0MembersChanged\0org.freedesktop.Telepathy.Channel.Interface.Group\0MembersChangedDetailed\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_hold_object_info;

struct _TpSvcChannelInterfaceHoldClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_hold_get_hold_state_impl get_hold_state_cb;
    tp_svc_channel_interface_hold_request_hold_impl request_hold_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_HOLD_HoldStateChanged,
    N_CHANNEL_INTERFACE_HOLD_SIGNALS
};
static guint channel_interface_hold_signals[N_CHANNEL_INTERFACE_HOLD_SIGNALS] = {0};

static void tp_svc_channel_interface_hold_base_init (gpointer klass);

GType
tp_svc_channel_interface_hold_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceHoldClass),
        tp_svc_channel_interface_hold_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceHold", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_hold_get_hold_state (TpSvcChannelInterfaceHold *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_hold_get_hold_state_impl impl = (TP_SVC_CHANNEL_INTERFACE_HOLD_GET_CLASS (self)->get_hold_state_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_hold_implement_get_hold_state (TpSvcChannelInterfaceHoldClass *klass, tp_svc_channel_interface_hold_get_hold_state_impl impl)
{
  klass->get_hold_state_cb = impl;
}

static void
tp_svc_channel_interface_hold_request_hold (TpSvcChannelInterfaceHold *self,
    gboolean in_Hold,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_hold_request_hold_impl impl = (TP_SVC_CHANNEL_INTERFACE_HOLD_GET_CLASS (self)->request_hold_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Hold,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_hold_implement_request_hold (TpSvcChannelInterfaceHoldClass *klass, tp_svc_channel_interface_hold_request_hold_impl impl)
{
  klass->request_hold_cb = impl;
}

void
tp_svc_channel_interface_hold_emit_hold_state_changed (gpointer instance,
    guint arg_HoldState,
    guint arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_HOLD));
  g_signal_emit (instance,
      channel_interface_hold_signals[SIGNAL_CHANNEL_INTERFACE_HOLD_HoldStateChanged],
      0,
      arg_HoldState,
      arg_Reason);
}

static inline void
tp_svc_channel_interface_hold_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_interface_hold_get_type (),
      &_tp_svc_channel_interface_hold_object_info);

  channel_interface_hold_signals[SIGNAL_CHANNEL_INTERFACE_HOLD_HoldStateChanged] =
  g_signal_new ("hold-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_interface_hold_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_hold_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_hold_methods[] = {
  { (GCallback) tp_svc_channel_interface_hold_get_hold_state, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_hold_request_hold, g_cclosure_marshal_generic, 98 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_hold_object_info = {
  0,
  _tp_svc_channel_interface_hold_methods,
  2,
"org.freedesktop.Telepathy.Channel.Interface.Hold\0GetHoldState\0A\0HoldState\0O\0F\0N\0u\0Reason\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Interface.Hold\0RequestHold\0A\0Hold\0I\0b\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.Hold\0HoldStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_media_signalling_object_info;

struct _TpSvcChannelInterfaceMediaSignallingClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_media_signalling_get_session_handlers_impl get_session_handlers_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_MEDIA_SIGNALLING_NewSessionHandler,
    N_CHANNEL_INTERFACE_MEDIA_SIGNALLING_SIGNALS
};
static guint channel_interface_media_signalling_signals[N_CHANNEL_INTERFACE_MEDIA_SIGNALLING_SIGNALS] = {0};

static void tp_svc_channel_interface_media_signalling_base_init (gpointer klass);

GType
tp_svc_channel_interface_media_signalling_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceMediaSignallingClass),
        tp_svc_channel_interface_media_signalling_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceMediaSignalling", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_media_signalling_get_session_handlers (TpSvcChannelInterfaceMediaSignalling *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_media_signalling_get_session_handlers_impl impl = (TP_SVC_CHANNEL_INTERFACE_MEDIA_SIGNALLING_GET_CLASS (self)->get_session_handlers_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_media_signalling_implement_get_session_handlers (TpSvcChannelInterfaceMediaSignallingClass *klass, tp_svc_channel_interface_media_signalling_get_session_handlers_impl impl)
{
  klass->get_session_handlers_cb = impl;
}

void
tp_svc_channel_interface_media_signalling_emit_new_session_handler (gpointer instance,
    const gchar *arg_Session_Handler,
    const gchar *arg_Session_Type)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_MEDIA_SIGNALLING));
  g_signal_emit (instance,
      channel_interface_media_signalling_signals[SIGNAL_CHANNEL_INTERFACE_MEDIA_SIGNALLING_NewSessionHandler],
      0,
      arg_Session_Handler,
      arg_Session_Type);
}

static inline void
tp_svc_channel_interface_media_signalling_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_interface_media_signalling_get_type (),
      &_tp_svc_channel_interface_media_signalling_object_info);

  channel_interface_media_signalling_signals[SIGNAL_CHANNEL_INTERFACE_MEDIA_SIGNALLING_NewSessionHandler] =
  g_signal_new ("new-session-handler",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING);

}
static void
tp_svc_channel_interface_media_signalling_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_media_signalling_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_media_signalling_methods[] = {
  { (GCallback) tp_svc_channel_interface_media_signalling_get_session_handlers, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_media_signalling_object_info = {
  0,
  _tp_svc_channel_interface_media_signalling_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.MediaSignalling\0GetSessionHandlers\0A\0Session_Handlers\0O\0F\0N\0a(os)\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.MediaSignalling\0NewSessionHandler\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_messages_object_info;

struct _TpSvcChannelInterfaceMessagesClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_messages_send_message_impl send_message_cb;
    tp_svc_channel_interface_messages_get_pending_message_content_impl get_pending_message_content_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageSent,
    SIGNAL_CHANNEL_INTERFACE_MESSAGES_PendingMessagesRemoved,
    SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageReceived,
    N_CHANNEL_INTERFACE_MESSAGES_SIGNALS
};
static guint channel_interface_messages_signals[N_CHANNEL_INTERFACE_MESSAGES_SIGNALS] = {0};

static void tp_svc_channel_interface_messages_base_init (gpointer klass);

GType
tp_svc_channel_interface_messages_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceMessagesClass),
        tp_svc_channel_interface_messages_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceMessages", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_messages_send_message (TpSvcChannelInterfaceMessages *self,
    const GPtrArray *in_Message,
    guint in_Flags,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_messages_send_message_impl impl = (TP_SVC_CHANNEL_INTERFACE_MESSAGES_GET_CLASS (self)->send_message_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Message,
        in_Flags,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_messages_implement_send_message (TpSvcChannelInterfaceMessagesClass *klass, tp_svc_channel_interface_messages_send_message_impl impl)
{
  klass->send_message_cb = impl;
}

static void
tp_svc_channel_interface_messages_get_pending_message_content (TpSvcChannelInterfaceMessages *self,
    guint in_Message_ID,
    const GArray *in_Parts,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_messages_get_pending_message_content_impl impl = (TP_SVC_CHANNEL_INTERFACE_MESSAGES_GET_CLASS (self)->get_pending_message_content_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Message_ID,
        in_Parts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_messages_implement_get_pending_message_content (TpSvcChannelInterfaceMessagesClass *klass, tp_svc_channel_interface_messages_get_pending_message_content_impl impl)
{
  klass->get_pending_message_content_cb = impl;
}

void
tp_svc_channel_interface_messages_emit_message_sent (gpointer instance,
    const GPtrArray *arg_Content,
    guint arg_Flags,
    const gchar *arg_Message_Token)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_MESSAGES));
  g_signal_emit (instance,
      channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageSent],
      0,
      arg_Content,
      arg_Flags,
      arg_Message_Token);
}

void
tp_svc_channel_interface_messages_emit_pending_messages_removed (gpointer instance,
    const GArray *arg_Message_IDs)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_MESSAGES));
  g_signal_emit (instance,
      channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_PendingMessagesRemoved],
      0,
      arg_Message_IDs);
}

void
tp_svc_channel_interface_messages_emit_message_received (gpointer instance,
    const GPtrArray *arg_Message)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_MESSAGES));
  g_signal_emit (instance,
      channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageReceived],
      0,
      arg_Message);
}

static inline void
tp_svc_channel_interface_messages_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* SupportedContentTypes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* MessageTypes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MessagePartSupportFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aaa{sv}", 0, NULL, NULL }, /* PendingMessages */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* DeliveryReportingSupport */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_messages_get_type (),
      &_tp_svc_channel_interface_messages_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Messages");
  properties[0].name = g_quark_from_static_string ("SupportedContentTypes");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("MessageTypes");
  properties[1].type = DBUS_TYPE_G_UINT_ARRAY;
  properties[2].name = g_quark_from_static_string ("MessagePartSupportFlags");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("PendingMessages");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))))));
  properties[4].name = g_quark_from_static_string ("DeliveryReportingSupport");
  properties[4].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_MESSAGES, &interface);

  channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageSent] =
  g_signal_new ("message-sent",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_UINT,
      G_TYPE_STRING);

  channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_PendingMessagesRemoved] =
  g_signal_new ("pending-messages-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      DBUS_TYPE_G_UINT_ARRAY);

  channel_interface_messages_signals[SIGNAL_CHANNEL_INTERFACE_MESSAGES_MessageReceived] =
  g_signal_new ("message-received",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));

}
static void
tp_svc_channel_interface_messages_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_messages_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_messages_methods[] = {
  { (GCallback) tp_svc_channel_interface_messages_send_message, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_messages_get_pending_message_content, g_cclosure_marshal_generic, 109 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_messages_object_info = {
  0,
  _tp_svc_channel_interface_messages_methods,
  2,
"org.freedesktop.Telepathy.Channel.Interface.Messages\0SendMessage\0A\0Message\0I\0aa{sv}\0Flags\0I\0u\0Token\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel.Interface.Messages\0GetPendingMessageContent\0A\0Message_ID\0I\0u\0Parts\0I\0au\0Content\0O\0F\0N\0a{uv}\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.Messages\0MessageSent\0org.freedesktop.Telepathy.Channel.Interface.Messages\0PendingMessagesRemoved\0org.freedesktop.Telepathy.Channel.Interface.Messages\0MessageReceived\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_password_object_info;

struct _TpSvcChannelInterfacePasswordClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_password_get_password_flags_impl get_password_flags_cb;
    tp_svc_channel_interface_password_provide_password_impl provide_password_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_PASSWORD_PasswordFlagsChanged,
    N_CHANNEL_INTERFACE_PASSWORD_SIGNALS
};
static guint channel_interface_password_signals[N_CHANNEL_INTERFACE_PASSWORD_SIGNALS] = {0};

static void tp_svc_channel_interface_password_base_init (gpointer klass);

GType
tp_svc_channel_interface_password_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfacePasswordClass),
        tp_svc_channel_interface_password_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfacePassword", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_password_get_password_flags (TpSvcChannelInterfacePassword *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_password_get_password_flags_impl impl = (TP_SVC_CHANNEL_INTERFACE_PASSWORD_GET_CLASS (self)->get_password_flags_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_password_implement_get_password_flags (TpSvcChannelInterfacePasswordClass *klass, tp_svc_channel_interface_password_get_password_flags_impl impl)
{
  klass->get_password_flags_cb = impl;
}

static void
tp_svc_channel_interface_password_provide_password (TpSvcChannelInterfacePassword *self,
    const gchar *in_Password,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_password_provide_password_impl impl = (TP_SVC_CHANNEL_INTERFACE_PASSWORD_GET_CLASS (self)->provide_password_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Password,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_password_implement_provide_password (TpSvcChannelInterfacePasswordClass *klass, tp_svc_channel_interface_password_provide_password_impl impl)
{
  klass->provide_password_cb = impl;
}

void
tp_svc_channel_interface_password_emit_password_flags_changed (gpointer instance,
    guint arg_Added,
    guint arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_PASSWORD));
  g_signal_emit (instance,
      channel_interface_password_signals[SIGNAL_CHANNEL_INTERFACE_PASSWORD_PasswordFlagsChanged],
      0,
      arg_Added,
      arg_Removed);
}

static inline void
tp_svc_channel_interface_password_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_interface_password_get_type (),
      &_tp_svc_channel_interface_password_object_info);

  channel_interface_password_signals[SIGNAL_CHANNEL_INTERFACE_PASSWORD_PasswordFlagsChanged] =
  g_signal_new ("password-flags-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_interface_password_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_password_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_password_methods[] = {
  { (GCallback) tp_svc_channel_interface_password_get_password_flags, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_password_provide_password, g_cclosure_marshal_generic, 96 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_password_object_info = {
  0,
  _tp_svc_channel_interface_password_methods,
  2,
"org.freedesktop.Telepathy.Channel.Interface.Password\0GetPasswordFlags\0A\0Password_Flags\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Interface.Password\0ProvidePassword\0A\0Password\0I\0s\0Correct\0O\0F\0N\0b\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.Password\0PasswordFlagsChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_room_object_info;

struct _TpSvcChannelInterfaceRoomClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_interface_room_base_init (gpointer klass);

GType
tp_svc_channel_interface_room_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceRoomClass),
        tp_svc_channel_interface_room_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceRoom", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_interface_room_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* RoomName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Server */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Creator */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* CreatorHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "x", 0, NULL, NULL }, /* CreationTimestamp */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_room_get_type (),
      &_tp_svc_channel_interface_room_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Room2");
  properties[0].name = g_quark_from_static_string ("RoomName");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("Server");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("Creator");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("CreatorHandle");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("CreationTimestamp");
  properties[4].type = G_TYPE_INT64;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_ROOM, &interface);

}
static void
tp_svc_channel_interface_room_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_room_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_room_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_room_object_info = {
  0,
  _tp_svc_channel_interface_room_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_room_config_object_info;

struct _TpSvcChannelInterfaceRoomConfigClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_room_config_update_configuration_impl update_configuration_cb;
};

static void tp_svc_channel_interface_room_config_base_init (gpointer klass);

GType
tp_svc_channel_interface_room_config_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceRoomConfigClass),
        tp_svc_channel_interface_room_config_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceRoomConfig", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_room_config_update_configuration (TpSvcChannelInterfaceRoomConfig *self,
    GHashTable *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_room_config_update_configuration_impl impl = (TP_SVC_CHANNEL_INTERFACE_ROOM_CONFIG_GET_CLASS (self)->update_configuration_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_room_config_implement_update_configuration (TpSvcChannelInterfaceRoomConfigClass *klass, tp_svc_channel_interface_room_config_update_configuration_impl impl)
{
  klass->update_configuration_cb = impl;
}

static inline void
tp_svc_channel_interface_room_config_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[15] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* Anonymous */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* InviteOnly */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "u", 0, NULL, NULL }, /* Limit */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* Moderated */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* Title */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* Description */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* Persistent */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* Private */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* PasswordProtected */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* Password */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* PasswordHint */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* CanUpdateConfiguration */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "as", 0, NULL, NULL }, /* MutableProperties */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* ConfigurationRetrieved */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_room_config_get_type (),
      &_tp_svc_channel_interface_room_config_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.RoomConfig1");
  properties[0].name = g_quark_from_static_string ("Anonymous");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("InviteOnly");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("Limit");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("Moderated");
  properties[3].type = G_TYPE_BOOLEAN;
  properties[4].name = g_quark_from_static_string ("Title");
  properties[4].type = G_TYPE_STRING;
  properties[5].name = g_quark_from_static_string ("Description");
  properties[5].type = G_TYPE_STRING;
  properties[6].name = g_quark_from_static_string ("Persistent");
  properties[6].type = G_TYPE_BOOLEAN;
  properties[7].name = g_quark_from_static_string ("Private");
  properties[7].type = G_TYPE_BOOLEAN;
  properties[8].name = g_quark_from_static_string ("PasswordProtected");
  properties[8].type = G_TYPE_BOOLEAN;
  properties[9].name = g_quark_from_static_string ("Password");
  properties[9].type = G_TYPE_STRING;
  properties[10].name = g_quark_from_static_string ("PasswordHint");
  properties[10].type = G_TYPE_STRING;
  properties[11].name = g_quark_from_static_string ("CanUpdateConfiguration");
  properties[11].type = G_TYPE_BOOLEAN;
  properties[12].name = g_quark_from_static_string ("MutableProperties");
  properties[12].type = G_TYPE_STRV;
  properties[13].name = g_quark_from_static_string ("ConfigurationRetrieved");
  properties[13].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_ROOM_CONFIG, &interface);

}
static void
tp_svc_channel_interface_room_config_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_room_config_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_room_config_methods[] = {
  { (GCallback) tp_svc_channel_interface_room_config_update_configuration, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_room_config_object_info = {
  0,
  _tp_svc_channel_interface_room_config_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.RoomConfig1\0UpdateConfiguration\0A\0Properties\0I\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_sasl_authentication_object_info;

struct _TpSvcChannelInterfaceSASLAuthenticationClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_sasl_authentication_start_mechanism_impl start_mechanism_cb;
    tp_svc_channel_interface_sasl_authentication_start_mechanism_with_data_impl start_mechanism_with_data_cb;
    tp_svc_channel_interface_sasl_authentication_respond_impl respond_cb;
    tp_svc_channel_interface_sasl_authentication_accept_sasl_impl accept_sasl_cb;
    tp_svc_channel_interface_sasl_authentication_abort_sasl_impl abort_sasl_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_SASLStatusChanged,
    SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_NewChallenge,
    N_CHANNEL_INTERFACE_SASL_AUTHENTICATION_SIGNALS
};
static guint channel_interface_sasl_authentication_signals[N_CHANNEL_INTERFACE_SASL_AUTHENTICATION_SIGNALS] = {0};

static void tp_svc_channel_interface_sasl_authentication_base_init (gpointer klass);

GType
tp_svc_channel_interface_sasl_authentication_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceSASLAuthenticationClass),
        tp_svc_channel_interface_sasl_authentication_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceSASLAuthentication", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_sasl_authentication_start_mechanism (TpSvcChannelInterfaceSASLAuthentication *self,
    const gchar *in_Mechanism,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sasl_authentication_start_mechanism_impl impl = (TP_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION_GET_CLASS (self)->start_mechanism_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Mechanism,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sasl_authentication_implement_start_mechanism (TpSvcChannelInterfaceSASLAuthenticationClass *klass, tp_svc_channel_interface_sasl_authentication_start_mechanism_impl impl)
{
  klass->start_mechanism_cb = impl;
}

static void
tp_svc_channel_interface_sasl_authentication_start_mechanism_with_data (TpSvcChannelInterfaceSASLAuthentication *self,
    const gchar *in_Mechanism,
    const GArray *in_Initial_Data,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sasl_authentication_start_mechanism_with_data_impl impl = (TP_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION_GET_CLASS (self)->start_mechanism_with_data_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Mechanism,
        in_Initial_Data,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sasl_authentication_implement_start_mechanism_with_data (TpSvcChannelInterfaceSASLAuthenticationClass *klass, tp_svc_channel_interface_sasl_authentication_start_mechanism_with_data_impl impl)
{
  klass->start_mechanism_with_data_cb = impl;
}

static void
tp_svc_channel_interface_sasl_authentication_respond (TpSvcChannelInterfaceSASLAuthentication *self,
    const GArray *in_Response_Data,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sasl_authentication_respond_impl impl = (TP_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION_GET_CLASS (self)->respond_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Response_Data,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sasl_authentication_implement_respond (TpSvcChannelInterfaceSASLAuthenticationClass *klass, tp_svc_channel_interface_sasl_authentication_respond_impl impl)
{
  klass->respond_cb = impl;
}

static void
tp_svc_channel_interface_sasl_authentication_accept_sasl (TpSvcChannelInterfaceSASLAuthentication *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sasl_authentication_accept_sasl_impl impl = (TP_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION_GET_CLASS (self)->accept_sasl_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sasl_authentication_implement_accept_sasl (TpSvcChannelInterfaceSASLAuthenticationClass *klass, tp_svc_channel_interface_sasl_authentication_accept_sasl_impl impl)
{
  klass->accept_sasl_cb = impl;
}

static void
tp_svc_channel_interface_sasl_authentication_abort_sasl (TpSvcChannelInterfaceSASLAuthentication *self,
    guint in_Reason,
    const gchar *in_Debug_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sasl_authentication_abort_sasl_impl impl = (TP_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION_GET_CLASS (self)->abort_sasl_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        in_Debug_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sasl_authentication_implement_abort_sasl (TpSvcChannelInterfaceSASLAuthenticationClass *klass, tp_svc_channel_interface_sasl_authentication_abort_sasl_impl impl)
{
  klass->abort_sasl_cb = impl;
}

void
tp_svc_channel_interface_sasl_authentication_emit_sasl_status_changed (gpointer instance,
    guint arg_Status,
    const gchar *arg_Reason,
    GHashTable *arg_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION));
  g_signal_emit (instance,
      channel_interface_sasl_authentication_signals[SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_SASLStatusChanged],
      0,
      arg_Status,
      arg_Reason,
      arg_Details);
}

void
tp_svc_channel_interface_sasl_authentication_emit_new_challenge (gpointer instance,
    const GArray *arg_Challenge_Data)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION));
  g_signal_emit (instance,
      channel_interface_sasl_authentication_signals[SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_NewChallenge],
      0,
      arg_Challenge_Data);
}

static inline void
tp_svc_channel_interface_sasl_authentication_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[11] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* AvailableMechanisms */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HasInitialData */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CanTryAgain */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SASLStatus */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* SASLError */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* SASLErrorDetails */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* AuthorizationIdentity */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* DefaultUsername */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* DefaultRealm */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* MaySaveResponse */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_sasl_authentication_get_type (),
      &_tp_svc_channel_interface_sasl_authentication_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication");
  properties[0].name = g_quark_from_static_string ("AvailableMechanisms");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("HasInitialData");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("CanTryAgain");
  properties[2].type = G_TYPE_BOOLEAN;
  properties[3].name = g_quark_from_static_string ("SASLStatus");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("SASLError");
  properties[4].type = G_TYPE_STRING;
  properties[5].name = g_quark_from_static_string ("SASLErrorDetails");
  properties[5].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[6].name = g_quark_from_static_string ("AuthorizationIdentity");
  properties[6].type = G_TYPE_STRING;
  properties[7].name = g_quark_from_static_string ("DefaultUsername");
  properties[7].type = G_TYPE_STRING;
  properties[8].name = g_quark_from_static_string ("DefaultRealm");
  properties[8].type = G_TYPE_STRING;
  properties[9].name = g_quark_from_static_string ("MaySaveResponse");
  properties[9].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_SASL_AUTHENTICATION, &interface);

  channel_interface_sasl_authentication_signals[SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_SASLStatusChanged] =
  g_signal_new ("s-as-lstatus-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  channel_interface_sasl_authentication_signals[SIGNAL_CHANNEL_INTERFACE_SASL_AUTHENTICATION_NewChallenge] =
  g_signal_new ("new-challenge",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR));

}
static void
tp_svc_channel_interface_sasl_authentication_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_sasl_authentication_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_sasl_authentication_methods[] = {
  { (GCallback) tp_svc_channel_interface_sasl_authentication_start_mechanism, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_interface_sasl_authentication_start_mechanism_with_data, g_cclosure_marshal_generic, 95 },
  { (GCallback) tp_svc_channel_interface_sasl_authentication_respond, g_cclosure_marshal_generic, 216 },
  { (GCallback) tp_svc_channel_interface_sasl_authentication_accept_sasl, g_cclosure_marshal_generic, 309 },
  { (GCallback) tp_svc_channel_interface_sasl_authentication_abort_sasl, g_cclosure_marshal_generic, 386 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_sasl_authentication_object_info = {
  0,
  _tp_svc_channel_interface_sasl_authentication_methods,
  5,
"org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0StartMechanism\0A\0Mechanism\0I\0s\0\0org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0StartMechanismWithData\0A\0Mechanism\0I\0s\0Initial_Data\0I\0ay\0\0org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0Respond\0A\0Response_Data\0I\0ay\0\0org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0AcceptSASL\0A\0\0org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0AbortSASL\0A\0Reason\0I\0u\0Debug_Message\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0SASLStatusChanged\0org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication\0NewChallenge\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_sms_object_info;

struct _TpSvcChannelInterfaceSMSClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_sms_get_sms_length_impl get_sms_length_cb;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_SMS_SMSChannelChanged,
    N_CHANNEL_INTERFACE_SMS_SIGNALS
};
static guint channel_interface_sms_signals[N_CHANNEL_INTERFACE_SMS_SIGNALS] = {0};

static void tp_svc_channel_interface_sms_base_init (gpointer klass);

GType
tp_svc_channel_interface_sms_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceSMSClass),
        tp_svc_channel_interface_sms_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceSMS", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_sms_get_sms_length (TpSvcChannelInterfaceSMS *self,
    const GPtrArray *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_sms_get_sms_length_impl impl = (TP_SVC_CHANNEL_INTERFACE_SMS_GET_CLASS (self)->get_sms_length_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_sms_implement_get_sms_length (TpSvcChannelInterfaceSMSClass *klass, tp_svc_channel_interface_sms_get_sms_length_impl impl)
{
  klass->get_sms_length_cb = impl;
}

void
tp_svc_channel_interface_sms_emit_sms_channel_changed (gpointer instance,
    gboolean arg_SMSChannel)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_SMS));
  g_signal_emit (instance,
      channel_interface_sms_signals[SIGNAL_CHANNEL_INTERFACE_SMS_SMSChannelChanged],
      0,
      arg_SMSChannel);
}

static inline void
tp_svc_channel_interface_sms_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Flash */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* SMSChannel */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_sms_get_type (),
      &_tp_svc_channel_interface_sms_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.SMS");
  properties[0].name = g_quark_from_static_string ("Flash");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("SMSChannel");
  properties[1].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_SMS, &interface);

  channel_interface_sms_signals[SIGNAL_CHANNEL_INTERFACE_SMS_SMSChannelChanged] =
  g_signal_new ("s-ms-channel-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_channel_interface_sms_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_sms_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_sms_methods[] = {
  { (GCallback) tp_svc_channel_interface_sms_get_sms_length, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_sms_object_info = {
  0,
  _tp_svc_channel_interface_sms_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.SMS\0GetSMSLength\0A\0Message\0I\0aa{sv}\0Chunks_Required\0O\0F\0N\0u\0Remaining_Characters\0O\0F\0N\0i\0Estimated_Cost\0O\0F\0N\0i\0\0\0",
"org.freedesktop.Telepathy.Channel.Interface.SMS\0SMSChannelChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_securable_object_info;

struct _TpSvcChannelInterfaceSecurableClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_interface_securable_base_init (gpointer klass);

GType
tp_svc_channel_interface_securable_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceSecurableClass),
        tp_svc_channel_interface_securable_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceSecurable", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_interface_securable_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Encrypted */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Verified */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_securable_get_type (),
      &_tp_svc_channel_interface_securable_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Securable");
  properties[0].name = g_quark_from_static_string ("Encrypted");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("Verified");
  properties[1].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_SECURABLE, &interface);

}
static void
tp_svc_channel_interface_securable_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_securable_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_securable_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_securable_object_info = {
  0,
  _tp_svc_channel_interface_securable_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_service_point_object_info;

struct _TpSvcChannelInterfaceServicePointClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_SERVICE_POINT_ServicePointChanged,
    N_CHANNEL_INTERFACE_SERVICE_POINT_SIGNALS
};
static guint channel_interface_service_point_signals[N_CHANNEL_INTERFACE_SERVICE_POINT_SIGNALS] = {0};

static void tp_svc_channel_interface_service_point_base_init (gpointer klass);

GType
tp_svc_channel_interface_service_point_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceServicePointClass),
        tp_svc_channel_interface_service_point_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceServicePoint", &info, 0);
    }

  return type;
}

void
tp_svc_channel_interface_service_point_emit_service_point_changed (gpointer instance,
    const GValueArray *arg_Service_Point)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_SERVICE_POINT));
  g_signal_emit (instance,
      channel_interface_service_point_signals[SIGNAL_CHANNEL_INTERFACE_SERVICE_POINT_ServicePointChanged],
      0,
      arg_Service_Point);
}

static inline void
tp_svc_channel_interface_service_point_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(us)", 0, NULL, NULL }, /* InitialServicePoint */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(us)", 0, NULL, NULL }, /* CurrentServicePoint */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_service_point_get_type (),
      &_tp_svc_channel_interface_service_point_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.ServicePoint");
  properties[0].name = g_quark_from_static_string ("InitialServicePoint");
  properties[0].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID));
  properties[1].name = g_quark_from_static_string ("CurrentServicePoint");
  properties[1].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_SERVICE_POINT, &interface);

  channel_interface_service_point_signals[SIGNAL_CHANNEL_INTERFACE_SERVICE_POINT_ServicePointChanged] =
  g_signal_new ("service-point-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)));

}
static void
tp_svc_channel_interface_service_point_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_service_point_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_service_point_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_service_point_object_info = {
  0,
  _tp_svc_channel_interface_service_point_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Channel.Interface.ServicePoint\0ServicePointChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_subject_object_info;

struct _TpSvcChannelInterfaceSubjectClass {
    GTypeInterface parent_class;
    tp_svc_channel_interface_subject_set_subject_impl set_subject_cb;
};

static void tp_svc_channel_interface_subject_base_init (gpointer klass);

GType
tp_svc_channel_interface_subject_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceSubjectClass),
        tp_svc_channel_interface_subject_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceSubject", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_interface_subject_set_subject (TpSvcChannelInterfaceSubject *self,
    const gchar *in_Subject,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_interface_subject_set_subject_impl impl = (TP_SVC_CHANNEL_INTERFACE_SUBJECT_GET_CLASS (self)->set_subject_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Subject,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_interface_subject_implement_set_subject (TpSvcChannelInterfaceSubjectClass *klass, tp_svc_channel_interface_subject_set_subject_impl impl)
{
  klass->set_subject_cb = impl;
}

static inline void
tp_svc_channel_interface_subject_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* Subject */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "s", 0, NULL, NULL }, /* Actor */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "u", 0, NULL, NULL }, /* ActorHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "x", 0, NULL, NULL }, /* Timestamp */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "b", 0, NULL, NULL }, /* CanSet */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_subject_get_type (),
      &_tp_svc_channel_interface_subject_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Subject2");
  properties[0].name = g_quark_from_static_string ("Subject");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("Actor");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("ActorHandle");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("Timestamp");
  properties[3].type = G_TYPE_INT64;
  properties[4].name = g_quark_from_static_string ("CanSet");
  properties[4].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_SUBJECT, &interface);

}
static void
tp_svc_channel_interface_subject_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_subject_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_subject_methods[] = {
  { (GCallback) tp_svc_channel_interface_subject_set_subject, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_interface_subject_object_info = {
  0,
  _tp_svc_channel_interface_subject_methods,
  1,
"org.freedesktop.Telepathy.Channel.Interface.Subject2\0SetSubject\0A\0Subject\0I\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_interface_tube_object_info;

struct _TpSvcChannelInterfaceTubeClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CHANNEL_INTERFACE_TUBE_TubeChannelStateChanged,
    N_CHANNEL_INTERFACE_TUBE_SIGNALS
};
static guint channel_interface_tube_signals[N_CHANNEL_INTERFACE_TUBE_SIGNALS] = {0};

static void tp_svc_channel_interface_tube_base_init (gpointer klass);

GType
tp_svc_channel_interface_tube_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelInterfaceTubeClass),
        tp_svc_channel_interface_tube_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelInterfaceTube", &info, 0);
    }

  return type;
}

void
tp_svc_channel_interface_tube_emit_tube_channel_state_changed (gpointer instance,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_INTERFACE_TUBE));
  g_signal_emit (instance,
      channel_interface_tube_signals[SIGNAL_CHANNEL_INTERFACE_TUBE_TubeChannelStateChanged],
      0,
      arg_State);
}

static inline void
tp_svc_channel_interface_tube_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* Parameters */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* State */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_interface_tube_get_type (),
      &_tp_svc_channel_interface_tube_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Interface.Tube");
  properties[0].name = g_quark_from_static_string ("Parameters");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[1].name = g_quark_from_static_string ("State");
  properties[1].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_INTERFACE_TUBE, &interface);

  channel_interface_tube_signals[SIGNAL_CHANNEL_INTERFACE_TUBE_TubeChannelStateChanged] =
  g_signal_new ("tube-channel-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

}
static void
tp_svc_channel_interface_tube_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_interface_tube_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_interface_tube_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_interface_tube_object_info = {
  0,
  _tp_svc_channel_interface_tube_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Channel.Interface.Tube\0TubeChannelStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_call_object_info;

struct _TpSvcChannelTypeCallClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_call_set_ringing_impl set_ringing_cb;
    tp_svc_channel_type_call_set_queued_impl set_queued_cb;
    tp_svc_channel_type_call_accept_impl accept_cb;
    tp_svc_channel_type_call_hangup_impl hangup_cb;
    tp_svc_channel_type_call_add_content_impl add_content_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_CALL_ContentAdded,
    SIGNAL_CHANNEL_TYPE_CALL_ContentRemoved,
    SIGNAL_CHANNEL_TYPE_CALL_CallStateChanged,
    SIGNAL_CHANNEL_TYPE_CALL_CallMembersChanged,
    N_CHANNEL_TYPE_CALL_SIGNALS
};
static guint channel_type_call_signals[N_CHANNEL_TYPE_CALL_SIGNALS] = {0};

static void tp_svc_channel_type_call_base_init (gpointer klass);

GType
tp_svc_channel_type_call_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeCallClass),
        tp_svc_channel_type_call_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeCall", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_call_set_ringing (TpSvcChannelTypeCall *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_call_set_ringing_impl impl = (TP_SVC_CHANNEL_TYPE_CALL_GET_CLASS (self)->set_ringing_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_call_implement_set_ringing (TpSvcChannelTypeCallClass *klass, tp_svc_channel_type_call_set_ringing_impl impl)
{
  klass->set_ringing_cb = impl;
}

static void
tp_svc_channel_type_call_set_queued (TpSvcChannelTypeCall *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_call_set_queued_impl impl = (TP_SVC_CHANNEL_TYPE_CALL_GET_CLASS (self)->set_queued_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_call_implement_set_queued (TpSvcChannelTypeCallClass *klass, tp_svc_channel_type_call_set_queued_impl impl)
{
  klass->set_queued_cb = impl;
}

static void
tp_svc_channel_type_call_accept (TpSvcChannelTypeCall *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_call_accept_impl impl = (TP_SVC_CHANNEL_TYPE_CALL_GET_CLASS (self)->accept_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_call_implement_accept (TpSvcChannelTypeCallClass *klass, tp_svc_channel_type_call_accept_impl impl)
{
  klass->accept_cb = impl;
}

static void
tp_svc_channel_type_call_hangup (TpSvcChannelTypeCall *self,
    guint in_Reason,
    const gchar *in_Detailed_Hangup_Reason,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_call_hangup_impl impl = (TP_SVC_CHANNEL_TYPE_CALL_GET_CLASS (self)->hangup_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        in_Detailed_Hangup_Reason,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_call_implement_hangup (TpSvcChannelTypeCallClass *klass, tp_svc_channel_type_call_hangup_impl impl)
{
  klass->hangup_cb = impl;
}

static void
tp_svc_channel_type_call_add_content (TpSvcChannelTypeCall *self,
    const gchar *in_Content_Name,
    guint in_Content_Type,
    guint in_InitialDirection,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_call_add_content_impl impl = (TP_SVC_CHANNEL_TYPE_CALL_GET_CLASS (self)->add_content_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Content_Name,
        in_Content_Type,
        in_InitialDirection,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_call_implement_add_content (TpSvcChannelTypeCallClass *klass, tp_svc_channel_type_call_add_content_impl impl)
{
  klass->add_content_cb = impl;
}

void
tp_svc_channel_type_call_emit_content_added (gpointer instance,
    const gchar *arg_Content)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CALL));
  g_signal_emit (instance,
      channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_ContentAdded],
      0,
      arg_Content);
}

void
tp_svc_channel_type_call_emit_content_removed (gpointer instance,
    const gchar *arg_Content,
    const GValueArray *arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CALL));
  g_signal_emit (instance,
      channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_ContentRemoved],
      0,
      arg_Content,
      arg_Reason);
}

void
tp_svc_channel_type_call_emit_call_state_changed (gpointer instance,
    guint arg_Call_State,
    guint arg_Call_Flags,
    const GValueArray *arg_Call_State_Reason,
    GHashTable *arg_Call_State_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CALL));
  g_signal_emit (instance,
      channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_CallStateChanged],
      0,
      arg_Call_State,
      arg_Call_Flags,
      arg_Call_State_Reason,
      arg_Call_State_Details);
}

void
tp_svc_channel_type_call_emit_call_members_changed (gpointer instance,
    GHashTable *arg_Flags_Changed,
    GHashTable *arg_Identifiers,
    const GArray *arg_Removed,
    const GValueArray *arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CALL));
  g_signal_emit (instance,
      channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_CallMembersChanged],
      0,
      arg_Flags_Changed,
      arg_Identifiers,
      arg_Removed,
      arg_Reason);
}

static inline void
tp_svc_channel_type_call_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[15] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* Contents */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* CallStateDetails */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* CallState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* CallFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(uuss)", 0, NULL, NULL }, /* CallStateReason */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HardwareStreaming */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uu}", 0, NULL, NULL }, /* CallMembers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{us}", 0, NULL, NULL }, /* MemberIdentifiers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* InitialTransport */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* InitialAudio */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* InitialVideo */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* InitialAudioName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* InitialVideoName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* MutableContents */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_call_get_type (),
      &_tp_svc_channel_type_call_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.Call1");
  properties[0].name = g_quark_from_static_string ("Contents");
  properties[0].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  properties[1].name = g_quark_from_static_string ("CallStateDetails");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[2].name = g_quark_from_static_string ("CallState");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("CallFlags");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("CallStateReason");
  properties[4].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[5].name = g_quark_from_static_string ("HardwareStreaming");
  properties[5].type = G_TYPE_BOOLEAN;
  properties[6].name = g_quark_from_static_string ("CallMembers");
  properties[6].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT));
  properties[7].name = g_quark_from_static_string ("MemberIdentifiers");
  properties[7].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING));
  properties[8].name = g_quark_from_static_string ("InitialTransport");
  properties[8].type = G_TYPE_UINT;
  properties[9].name = g_quark_from_static_string ("InitialAudio");
  properties[9].type = G_TYPE_BOOLEAN;
  properties[10].name = g_quark_from_static_string ("InitialVideo");
  properties[10].type = G_TYPE_BOOLEAN;
  properties[11].name = g_quark_from_static_string ("InitialAudioName");
  properties[11].type = G_TYPE_STRING;
  properties[12].name = g_quark_from_static_string ("InitialVideoName");
  properties[12].type = G_TYPE_STRING;
  properties[13].name = g_quark_from_static_string ("MutableContents");
  properties[13].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_CALL, &interface);

  channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_ContentAdded] =
  g_signal_new ("content-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      DBUS_TYPE_G_OBJECT_PATH);

  channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_ContentRemoved] =
  g_signal_new ("content-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));

  channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_CallStateChanged] =
  g_signal_new ("call-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      G_TYPE_UINT,
      G_TYPE_UINT,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  channel_type_call_signals[SIGNAL_CHANNEL_TYPE_CALL_CallMembersChanged] =
  g_signal_new ("call-members-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_UINT)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));

}
static void
tp_svc_channel_type_call_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_call_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_call_methods[] = {
  { (GCallback) tp_svc_channel_type_call_set_ringing, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_call_set_queued, g_cclosure_marshal_generic, 59 },
  { (GCallback) tp_svc_channel_type_call_accept, g_cclosure_marshal_generic, 117 },
  { (GCallback) tp_svc_channel_type_call_hangup, g_cclosure_marshal_generic, 172 },
  { (GCallback) tp_svc_channel_type_call_add_content, g_cclosure_marshal_generic, 277 },
};

static const DBusGObjectInfo _tp_svc_channel_type_call_object_info = {
  0,
  _tp_svc_channel_type_call_methods,
  5,
"org.freedesktop.Telepathy.Channel.Type.Call1\0SetRinging\0A\0\0org.freedesktop.Telepathy.Channel.Type.Call1\0SetQueued\0A\0\0org.freedesktop.Telepathy.Channel.Type.Call1\0Accept\0A\0\0org.freedesktop.Telepathy.Channel.Type.Call1\0Hangup\0A\0Reason\0I\0u\0Detailed_Hangup_Reason\0I\0s\0Message\0I\0s\0\0org.freedesktop.Telepathy.Channel.Type.Call1\0AddContent\0A\0Content_Name\0I\0s\0Content_Type\0I\0u\0InitialDirection\0I\0u\0Content\0O\0F\0N\0o\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.Call1\0ContentAdded\0org.freedesktop.Telepathy.Channel.Type.Call1\0ContentRemoved\0org.freedesktop.Telepathy.Channel.Type.Call1\0CallStateChanged\0org.freedesktop.Telepathy.Channel.Type.Call1\0CallMembersChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_contact_list_object_info;

struct _TpSvcChannelTypeContactListClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_type_contact_list_base_init (gpointer klass);

GType
tp_svc_channel_type_contact_list_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeContactListClass),
        tp_svc_channel_type_contact_list_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeContactList", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_type_contact_list_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_type_contact_list_get_type (),
      &_tp_svc_channel_type_contact_list_object_info);

}
static void
tp_svc_channel_type_contact_list_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_contact_list_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_contact_list_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_type_contact_list_object_info = {
  0,
  _tp_svc_channel_type_contact_list_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_contact_search_object_info;

struct _TpSvcChannelTypeContactSearchClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_contact_search_search_impl search_cb;
    tp_svc_channel_type_contact_search_more_impl more_cb;
    tp_svc_channel_type_contact_search_stop_impl stop_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchStateChanged,
    SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchResultReceived,
    N_CHANNEL_TYPE_CONTACT_SEARCH_SIGNALS
};
static guint channel_type_contact_search_signals[N_CHANNEL_TYPE_CONTACT_SEARCH_SIGNALS] = {0};

static void tp_svc_channel_type_contact_search_base_init (gpointer klass);

GType
tp_svc_channel_type_contact_search_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeContactSearchClass),
        tp_svc_channel_type_contact_search_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeContactSearch", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_contact_search_search (TpSvcChannelTypeContactSearch *self,
    GHashTable *in_Terms,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_contact_search_search_impl impl = (TP_SVC_CHANNEL_TYPE_CONTACT_SEARCH_GET_CLASS (self)->search_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Terms,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_contact_search_implement_search (TpSvcChannelTypeContactSearchClass *klass, tp_svc_channel_type_contact_search_search_impl impl)
{
  klass->search_cb = impl;
}

static void
tp_svc_channel_type_contact_search_more (TpSvcChannelTypeContactSearch *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_contact_search_more_impl impl = (TP_SVC_CHANNEL_TYPE_CONTACT_SEARCH_GET_CLASS (self)->more_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_contact_search_implement_more (TpSvcChannelTypeContactSearchClass *klass, tp_svc_channel_type_contact_search_more_impl impl)
{
  klass->more_cb = impl;
}

static void
tp_svc_channel_type_contact_search_stop (TpSvcChannelTypeContactSearch *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_contact_search_stop_impl impl = (TP_SVC_CHANNEL_TYPE_CONTACT_SEARCH_GET_CLASS (self)->stop_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_contact_search_implement_stop (TpSvcChannelTypeContactSearchClass *klass, tp_svc_channel_type_contact_search_stop_impl impl)
{
  klass->stop_cb = impl;
}

void
tp_svc_channel_type_contact_search_emit_search_state_changed (gpointer instance,
    guint arg_State,
    const gchar *arg_Error,
    GHashTable *arg_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CONTACT_SEARCH));
  g_signal_emit (instance,
      channel_type_contact_search_signals[SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchStateChanged],
      0,
      arg_State,
      arg_Error,
      arg_Details);
}

void
tp_svc_channel_type_contact_search_emit_search_result_received (gpointer instance,
    GHashTable *arg_Result)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_CONTACT_SEARCH));
  g_signal_emit (instance,
      channel_type_contact_search_signals[SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchResultReceived],
      0,
      arg_Result);
}

static inline void
tp_svc_channel_type_contact_search_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SearchState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Limit */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* AvailableSearchKeys */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Server */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_contact_search_get_type (),
      &_tp_svc_channel_type_contact_search_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.ContactSearch");
  properties[0].name = g_quark_from_static_string ("SearchState");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("Limit");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("AvailableSearchKeys");
  properties[2].type = G_TYPE_STRV;
  properties[3].name = g_quark_from_static_string ("Server");
  properties[3].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_CONTACT_SEARCH, &interface);

  channel_type_contact_search_signals[SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchStateChanged] =
  g_signal_new ("search-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  channel_type_contact_search_signals[SIGNAL_CHANNEL_TYPE_CONTACT_SEARCH_SearchResultReceived] =
  g_signal_new ("search-result-received",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))))));

}
static void
tp_svc_channel_type_contact_search_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_contact_search_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_contact_search_methods[] = {
  { (GCallback) tp_svc_channel_type_contact_search_search, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_contact_search_more, g_cclosure_marshal_generic, 77 },
  { (GCallback) tp_svc_channel_type_contact_search_stop, g_cclosure_marshal_generic, 138 },
};

static const DBusGObjectInfo _tp_svc_channel_type_contact_search_object_info = {
  0,
  _tp_svc_channel_type_contact_search_methods,
  3,
"org.freedesktop.Telepathy.Channel.Type.ContactSearch\0Search\0A\0Terms\0I\0a{ss}\0\0org.freedesktop.Telepathy.Channel.Type.ContactSearch\0More\0A\0\0org.freedesktop.Telepathy.Channel.Type.ContactSearch\0Stop\0A\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.ContactSearch\0SearchStateChanged\0org.freedesktop.Telepathy.Channel.Type.ContactSearch\0SearchResultReceived\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_dbus_tube_object_info;

struct _TpSvcChannelTypeDBusTubeClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_dbus_tube_offer_impl offer_cb;
    tp_svc_channel_type_dbus_tube_accept_impl accept_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_DBUS_TUBE_DBusNamesChanged,
    N_CHANNEL_TYPE_DBUS_TUBE_SIGNALS
};
static guint channel_type_dbus_tube_signals[N_CHANNEL_TYPE_DBUS_TUBE_SIGNALS] = {0};

static void tp_svc_channel_type_dbus_tube_base_init (gpointer klass);

GType
tp_svc_channel_type_dbus_tube_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeDBusTubeClass),
        tp_svc_channel_type_dbus_tube_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeDBusTube", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_dbus_tube_offer (TpSvcChannelTypeDBusTube *self,
    GHashTable *in_parameters,
    guint in_access_control,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_dbus_tube_offer_impl impl = (TP_SVC_CHANNEL_TYPE_DBUS_TUBE_GET_CLASS (self)->offer_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_parameters,
        in_access_control,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_dbus_tube_implement_offer (TpSvcChannelTypeDBusTubeClass *klass, tp_svc_channel_type_dbus_tube_offer_impl impl)
{
  klass->offer_cb = impl;
}

static void
tp_svc_channel_type_dbus_tube_accept (TpSvcChannelTypeDBusTube *self,
    guint in_access_control,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_dbus_tube_accept_impl impl = (TP_SVC_CHANNEL_TYPE_DBUS_TUBE_GET_CLASS (self)->accept_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_access_control,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_dbus_tube_implement_accept (TpSvcChannelTypeDBusTubeClass *klass, tp_svc_channel_type_dbus_tube_accept_impl impl)
{
  klass->accept_cb = impl;
}

void
tp_svc_channel_type_dbus_tube_emit_dbus_names_changed (gpointer instance,
    GHashTable *arg_Added,
    const GArray *arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_DBUS_TUBE));
  g_signal_emit (instance,
      channel_type_dbus_tube_signals[SIGNAL_CHANNEL_TYPE_DBUS_TUBE_DBusNamesChanged],
      0,
      arg_Added,
      arg_Removed);
}

static inline void
tp_svc_channel_type_dbus_tube_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ServiceName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{us}", 0, NULL, NULL }, /* DBusNames */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* SupportedAccessControls */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_dbus_tube_get_type (),
      &_tp_svc_channel_type_dbus_tube_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.DBusTube");
  properties[0].name = g_quark_from_static_string ("ServiceName");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("DBusNames");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING));
  properties[2].name = g_quark_from_static_string ("SupportedAccessControls");
  properties[2].type = DBUS_TYPE_G_UINT_ARRAY;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_DBUS_TUBE, &interface);

  channel_type_dbus_tube_signals[SIGNAL_CHANNEL_TYPE_DBUS_TUBE_DBusNamesChanged] =
  g_signal_new ("d-bus-names-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      DBUS_TYPE_G_UINT_ARRAY);

}
static void
tp_svc_channel_type_dbus_tube_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_dbus_tube_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_dbus_tube_methods[] = {
  { (GCallback) tp_svc_channel_type_dbus_tube_offer, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_dbus_tube_accept, g_cclosure_marshal_generic, 111 },
};

static const DBusGObjectInfo _tp_svc_channel_type_dbus_tube_object_info = {
  0,
  _tp_svc_channel_type_dbus_tube_methods,
  2,
"org.freedesktop.Telepathy.Channel.Type.DBusTube\0Offer\0A\0parameters\0I\0a{sv}\0access_control\0I\0u\0address\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel.Type.DBusTube\0Accept\0A\0access_control\0I\0u\0address\0O\0F\0N\0s\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.DBusTube\0DBusNamesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_file_transfer_object_info;

struct _TpSvcChannelTypeFileTransferClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_file_transfer_accept_file_impl accept_file_cb;
    tp_svc_channel_type_file_transfer_provide_file_impl provide_file_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_FileTransferStateChanged,
    SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_TransferredBytesChanged,
    SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_InitialOffsetDefined,
    SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_URIDefined,
    N_CHANNEL_TYPE_FILE_TRANSFER_SIGNALS
};
static guint channel_type_file_transfer_signals[N_CHANNEL_TYPE_FILE_TRANSFER_SIGNALS] = {0};

static void tp_svc_channel_type_file_transfer_base_init (gpointer klass);

GType
tp_svc_channel_type_file_transfer_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeFileTransferClass),
        tp_svc_channel_type_file_transfer_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeFileTransfer", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_file_transfer_accept_file (TpSvcChannelTypeFileTransfer *self,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    guint64 in_Offset,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_file_transfer_accept_file_impl impl = (TP_SVC_CHANNEL_TYPE_FILE_TRANSFER_GET_CLASS (self)->accept_file_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Address_Type,
        in_Access_Control,
        in_Access_Control_Param,
        in_Offset,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_file_transfer_implement_accept_file (TpSvcChannelTypeFileTransferClass *klass, tp_svc_channel_type_file_transfer_accept_file_impl impl)
{
  klass->accept_file_cb = impl;
}

static void
tp_svc_channel_type_file_transfer_provide_file (TpSvcChannelTypeFileTransfer *self,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_file_transfer_provide_file_impl impl = (TP_SVC_CHANNEL_TYPE_FILE_TRANSFER_GET_CLASS (self)->provide_file_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Address_Type,
        in_Access_Control,
        in_Access_Control_Param,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_file_transfer_implement_provide_file (TpSvcChannelTypeFileTransferClass *klass, tp_svc_channel_type_file_transfer_provide_file_impl impl)
{
  klass->provide_file_cb = impl;
}

void
tp_svc_channel_type_file_transfer_emit_file_transfer_state_changed (gpointer instance,
    guint arg_State,
    guint arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_FILE_TRANSFER));
  g_signal_emit (instance,
      channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_FileTransferStateChanged],
      0,
      arg_State,
      arg_Reason);
}

void
tp_svc_channel_type_file_transfer_emit_transferred_bytes_changed (gpointer instance,
    guint64 arg_Count)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_FILE_TRANSFER));
  g_signal_emit (instance,
      channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_TransferredBytesChanged],
      0,
      arg_Count);
}

void
tp_svc_channel_type_file_transfer_emit_initial_offset_defined (gpointer instance,
    guint64 arg_InitialOffset)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_FILE_TRANSFER));
  g_signal_emit (instance,
      channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_InitialOffsetDefined],
      0,
      arg_InitialOffset);
}

void
tp_svc_channel_type_file_transfer_emit_uri_defined (gpointer instance,
    const gchar *arg_URI)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_FILE_TRANSFER));
  g_signal_emit (instance,
      channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_URIDefined],
      0,
      arg_URI);
}

static inline void
tp_svc_channel_type_file_transfer_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[14] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* State */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ContentType */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Filename */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "t", 0, NULL, NULL }, /* Size */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ContentHashType */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ContentHash */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Description */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "x", 0, NULL, NULL }, /* Date */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uau}", 0, NULL, NULL }, /* AvailableSocketTypes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "t", 0, NULL, NULL }, /* TransferredBytes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "t", 0, NULL, NULL }, /* InitialOffset */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* URI */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* FileCollection */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_file_transfer_get_type (),
      &_tp_svc_channel_type_file_transfer_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.FileTransfer");
  properties[0].name = g_quark_from_static_string ("State");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("ContentType");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("Filename");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("Size");
  properties[3].type = G_TYPE_UINT64;
  properties[4].name = g_quark_from_static_string ("ContentHashType");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("ContentHash");
  properties[5].type = G_TYPE_STRING;
  properties[6].name = g_quark_from_static_string ("Description");
  properties[6].type = G_TYPE_STRING;
  properties[7].name = g_quark_from_static_string ("Date");
  properties[7].type = G_TYPE_INT64;
  properties[8].name = g_quark_from_static_string ("AvailableSocketTypes");
  properties[8].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_UINT_ARRAY));
  properties[9].name = g_quark_from_static_string ("TransferredBytes");
  properties[9].type = G_TYPE_UINT64;
  properties[10].name = g_quark_from_static_string ("InitialOffset");
  properties[10].type = G_TYPE_UINT64;
  properties[11].name = g_quark_from_static_string ("URI");
  properties[11].type = G_TYPE_STRING;
  properties[12].name = g_quark_from_static_string ("FileCollection");
  properties[12].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_FILE_TRANSFER, &interface);

  channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_FileTransferStateChanged] =
  g_signal_new ("file-transfer-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_TransferredBytesChanged] =
  g_signal_new ("transferred-bytes-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT64);

  channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_InitialOffsetDefined] =
  g_signal_new ("initial-offset-defined",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT64);

  channel_type_file_transfer_signals[SIGNAL_CHANNEL_TYPE_FILE_TRANSFER_URIDefined] =
  g_signal_new ("u-ri-defined",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

}
static void
tp_svc_channel_type_file_transfer_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_file_transfer_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_file_transfer_methods[] = {
  { (GCallback) tp_svc_channel_type_file_transfer_accept_file, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_file_transfer_provide_file, g_cclosure_marshal_generic, 154 },
};

static const DBusGObjectInfo _tp_svc_channel_type_file_transfer_object_info = {
  0,
  _tp_svc_channel_type_file_transfer_methods,
  2,
"org.freedesktop.Telepathy.Channel.Type.FileTransfer\0AcceptFile\0A\0Address_Type\0I\0u\0Access_Control\0I\0u\0Access_Control_Param\0I\0v\0Offset\0I\0t\0Address\0O\0F\0N\0v\0\0org.freedesktop.Telepathy.Channel.Type.FileTransfer\0ProvideFile\0A\0Address_Type\0I\0u\0Access_Control\0I\0u\0Access_Control_Param\0I\0v\0Address\0O\0F\0N\0v\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.FileTransfer\0FileTransferStateChanged\0org.freedesktop.Telepathy.Channel.Type.FileTransfer\0TransferredBytesChanged\0org.freedesktop.Telepathy.Channel.Type.FileTransfer\0InitialOffsetDefined\0org.freedesktop.Telepathy.Channel.Type.FileTransfer\0URIDefined\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_room_list_object_info;

struct _TpSvcChannelTypeRoomListClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_room_list_get_listing_rooms_impl get_listing_rooms_cb;
    tp_svc_channel_type_room_list_list_rooms_impl list_rooms_cb;
    tp_svc_channel_type_room_list_stop_listing_impl stop_listing_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_ROOM_LIST_GotRooms,
    SIGNAL_CHANNEL_TYPE_ROOM_LIST_ListingRooms,
    N_CHANNEL_TYPE_ROOM_LIST_SIGNALS
};
static guint channel_type_room_list_signals[N_CHANNEL_TYPE_ROOM_LIST_SIGNALS] = {0};

static void tp_svc_channel_type_room_list_base_init (gpointer klass);

GType
tp_svc_channel_type_room_list_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeRoomListClass),
        tp_svc_channel_type_room_list_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeRoomList", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_room_list_get_listing_rooms (TpSvcChannelTypeRoomList *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_room_list_get_listing_rooms_impl impl = (TP_SVC_CHANNEL_TYPE_ROOM_LIST_GET_CLASS (self)->get_listing_rooms_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_room_list_implement_get_listing_rooms (TpSvcChannelTypeRoomListClass *klass, tp_svc_channel_type_room_list_get_listing_rooms_impl impl)
{
  klass->get_listing_rooms_cb = impl;
}

static void
tp_svc_channel_type_room_list_list_rooms (TpSvcChannelTypeRoomList *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_room_list_list_rooms_impl impl = (TP_SVC_CHANNEL_TYPE_ROOM_LIST_GET_CLASS (self)->list_rooms_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_room_list_implement_list_rooms (TpSvcChannelTypeRoomListClass *klass, tp_svc_channel_type_room_list_list_rooms_impl impl)
{
  klass->list_rooms_cb = impl;
}

static void
tp_svc_channel_type_room_list_stop_listing (TpSvcChannelTypeRoomList *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_room_list_stop_listing_impl impl = (TP_SVC_CHANNEL_TYPE_ROOM_LIST_GET_CLASS (self)->stop_listing_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_room_list_implement_stop_listing (TpSvcChannelTypeRoomListClass *klass, tp_svc_channel_type_room_list_stop_listing_impl impl)
{
  klass->stop_listing_cb = impl;
}

void
tp_svc_channel_type_room_list_emit_got_rooms (gpointer instance,
    const GPtrArray *arg_Rooms)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_ROOM_LIST));
  g_signal_emit (instance,
      channel_type_room_list_signals[SIGNAL_CHANNEL_TYPE_ROOM_LIST_GotRooms],
      0,
      arg_Rooms);
}

void
tp_svc_channel_type_room_list_emit_listing_rooms (gpointer instance,
    gboolean arg_Listing)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_ROOM_LIST));
  g_signal_emit (instance,
      channel_type_room_list_signals[SIGNAL_CHANNEL_TYPE_ROOM_LIST_ListingRooms],
      0,
      arg_Listing);
}

static inline void
tp_svc_channel_type_room_list_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Server */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_room_list_get_type (),
      &_tp_svc_channel_type_room_list_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.RoomList");
  properties[0].name = g_quark_from_static_string ("Server");
  properties[0].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_ROOM_LIST, &interface);

  channel_type_room_list_signals[SIGNAL_CHANNEL_TYPE_ROOM_LIST_GotRooms] =
  g_signal_new ("got-rooms",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));

  channel_type_room_list_signals[SIGNAL_CHANNEL_TYPE_ROOM_LIST_ListingRooms] =
  g_signal_new ("listing-rooms",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_channel_type_room_list_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_room_list_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_room_list_methods[] = {
  { (GCallback) tp_svc_channel_type_room_list_get_listing_rooms, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_room_list_list_rooms, g_cclosure_marshal_generic, 87 },
  { (GCallback) tp_svc_channel_type_room_list_stop_listing, g_cclosure_marshal_generic, 148 },
};

static const DBusGObjectInfo _tp_svc_channel_type_room_list_object_info = {
  0,
  _tp_svc_channel_type_room_list_methods,
  3,
"org.freedesktop.Telepathy.Channel.Type.RoomList\0GetListingRooms\0A\0In_Progress\0O\0F\0N\0b\0\0org.freedesktop.Telepathy.Channel.Type.RoomList\0ListRooms\0A\0\0org.freedesktop.Telepathy.Channel.Type.RoomList\0StopListing\0A\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.RoomList\0GotRooms\0org.freedesktop.Telepathy.Channel.Type.RoomList\0ListingRooms\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_server_authentication_object_info;

struct _TpSvcChannelTypeServerAuthenticationClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_type_server_authentication_base_init (gpointer klass);

GType
tp_svc_channel_type_server_authentication_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeServerAuthenticationClass),
        tp_svc_channel_type_server_authentication_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeServerAuthentication", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_type_server_authentication_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* AuthenticationMethod */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_server_authentication_get_type (),
      &_tp_svc_channel_type_server_authentication_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.ServerAuthentication");
  properties[0].name = g_quark_from_static_string ("AuthenticationMethod");
  properties[0].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_SERVER_AUTHENTICATION, &interface);

}
static void
tp_svc_channel_type_server_authentication_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_server_authentication_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_server_authentication_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_type_server_authentication_object_info = {
  0,
  _tp_svc_channel_type_server_authentication_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_server_tls_connection_object_info;

struct _TpSvcChannelTypeServerTLSConnectionClass {
    GTypeInterface parent_class;
};

static void tp_svc_channel_type_server_tls_connection_base_init (gpointer klass);

GType
tp_svc_channel_type_server_tls_connection_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeServerTLSConnectionClass),
        tp_svc_channel_type_server_tls_connection_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeServerTLSConnection", &info, 0);
    }

  return type;
}

static inline void
tp_svc_channel_type_server_tls_connection_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "o", 0, NULL, NULL }, /* ServerCertificate */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Hostname */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* ReferenceIdentities */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_server_tls_connection_get_type (),
      &_tp_svc_channel_type_server_tls_connection_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.ServerTLSConnection");
  properties[0].name = g_quark_from_static_string ("ServerCertificate");
  properties[0].type = DBUS_TYPE_G_OBJECT_PATH;
  properties[1].name = g_quark_from_static_string ("Hostname");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("ReferenceIdentities");
  properties[2].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_SERVER_TLS_CONNECTION, &interface);

}
static void
tp_svc_channel_type_server_tls_connection_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_server_tls_connection_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_server_tls_connection_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_type_server_tls_connection_object_info = {
  0,
  _tp_svc_channel_type_server_tls_connection_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_stream_tube_object_info;

struct _TpSvcChannelTypeStreamTubeClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_stream_tube_offer_impl offer_cb;
    tp_svc_channel_type_stream_tube_accept_impl accept_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewRemoteConnection,
    SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewLocalConnection,
    SIGNAL_CHANNEL_TYPE_STREAM_TUBE_ConnectionClosed,
    N_CHANNEL_TYPE_STREAM_TUBE_SIGNALS
};
static guint channel_type_stream_tube_signals[N_CHANNEL_TYPE_STREAM_TUBE_SIGNALS] = {0};

static void tp_svc_channel_type_stream_tube_base_init (gpointer klass);

GType
tp_svc_channel_type_stream_tube_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeStreamTubeClass),
        tp_svc_channel_type_stream_tube_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeStreamTube", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_stream_tube_offer (TpSvcChannelTypeStreamTube *self,
    guint in_address_type,
    const GValue *in_address,
    guint in_access_control,
    GHashTable *in_parameters,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_stream_tube_offer_impl impl = (TP_SVC_CHANNEL_TYPE_STREAM_TUBE_GET_CLASS (self)->offer_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_address_type,
        in_address,
        in_access_control,
        in_parameters,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_stream_tube_implement_offer (TpSvcChannelTypeStreamTubeClass *klass, tp_svc_channel_type_stream_tube_offer_impl impl)
{
  klass->offer_cb = impl;
}

static void
tp_svc_channel_type_stream_tube_accept (TpSvcChannelTypeStreamTube *self,
    guint in_address_type,
    guint in_access_control,
    const GValue *in_access_control_param,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_stream_tube_accept_impl impl = (TP_SVC_CHANNEL_TYPE_STREAM_TUBE_GET_CLASS (self)->accept_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_address_type,
        in_access_control,
        in_access_control_param,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_stream_tube_implement_accept (TpSvcChannelTypeStreamTubeClass *klass, tp_svc_channel_type_stream_tube_accept_impl impl)
{
  klass->accept_cb = impl;
}

void
tp_svc_channel_type_stream_tube_emit_new_remote_connection (gpointer instance,
    guint arg_Handle,
    const GValue *arg_Connection_Param,
    guint arg_Connection_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAM_TUBE));
  g_signal_emit (instance,
      channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewRemoteConnection],
      0,
      arg_Handle,
      arg_Connection_Param,
      arg_Connection_ID);
}

void
tp_svc_channel_type_stream_tube_emit_new_local_connection (gpointer instance,
    guint arg_Connection_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAM_TUBE));
  g_signal_emit (instance,
      channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewLocalConnection],
      0,
      arg_Connection_ID);
}

void
tp_svc_channel_type_stream_tube_emit_connection_closed (gpointer instance,
    guint arg_Connection_ID,
    const gchar *arg_Error,
    const gchar *arg_Message)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAM_TUBE));
  g_signal_emit (instance,
      channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_ConnectionClosed],
      0,
      arg_Connection_ID,
      arg_Error,
      arg_Message);
}

static inline void
tp_svc_channel_type_stream_tube_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Service */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uau}", 0, NULL, NULL }, /* SupportedSocketTypes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_stream_tube_get_type (),
      &_tp_svc_channel_type_stream_tube_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.StreamTube");
  properties[0].name = g_quark_from_static_string ("Service");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("SupportedSocketTypes");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_UINT_ARRAY));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_STREAM_TUBE, &interface);

  channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewRemoteConnection] =
  g_signal_new ("new-remote-connection",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_VALUE,
      G_TYPE_UINT);

  channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_NewLocalConnection] =
  g_signal_new ("new-local-connection",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  channel_type_stream_tube_signals[SIGNAL_CHANNEL_TYPE_STREAM_TUBE_ConnectionClosed] =
  g_signal_new ("connection-closed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_STRING);

}
static void
tp_svc_channel_type_stream_tube_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_stream_tube_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_stream_tube_methods[] = {
  { (GCallback) tp_svc_channel_type_stream_tube_offer, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_stream_tube_accept, g_cclosure_marshal_generic, 126 },
};

static const DBusGObjectInfo _tp_svc_channel_type_stream_tube_object_info = {
  0,
  _tp_svc_channel_type_stream_tube_methods,
  2,
"org.freedesktop.Telepathy.Channel.Type.StreamTube\0Offer\0A\0address_type\0I\0u\0address\0I\0v\0access_control\0I\0u\0parameters\0I\0a{sv}\0\0org.freedesktop.Telepathy.Channel.Type.StreamTube\0Accept\0A\0address_type\0I\0u\0access_control\0I\0u\0access_control_param\0I\0v\0address\0O\0F\0N\0v\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.StreamTube\0NewRemoteConnection\0org.freedesktop.Telepathy.Channel.Type.StreamTube\0NewLocalConnection\0org.freedesktop.Telepathy.Channel.Type.StreamTube\0ConnectionClosed\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_streamed_media_object_info;

struct _TpSvcChannelTypeStreamedMediaClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_streamed_media_list_streams_impl list_streams_cb;
    tp_svc_channel_type_streamed_media_remove_streams_impl remove_streams_cb;
    tp_svc_channel_type_streamed_media_request_stream_direction_impl request_stream_direction_cb;
    tp_svc_channel_type_streamed_media_request_streams_impl request_streams_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamAdded,
    SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamDirectionChanged,
    SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamError,
    SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamRemoved,
    SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamStateChanged,
    N_CHANNEL_TYPE_STREAMED_MEDIA_SIGNALS
};
static guint channel_type_streamed_media_signals[N_CHANNEL_TYPE_STREAMED_MEDIA_SIGNALS] = {0};

static void tp_svc_channel_type_streamed_media_base_init (gpointer klass);

GType
tp_svc_channel_type_streamed_media_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeStreamedMediaClass),
        tp_svc_channel_type_streamed_media_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeStreamedMedia", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_streamed_media_list_streams (TpSvcChannelTypeStreamedMedia *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_streamed_media_list_streams_impl impl = (TP_SVC_CHANNEL_TYPE_STREAMED_MEDIA_GET_CLASS (self)->list_streams_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_streamed_media_implement_list_streams (TpSvcChannelTypeStreamedMediaClass *klass, tp_svc_channel_type_streamed_media_list_streams_impl impl)
{
  klass->list_streams_cb = impl;
}

static void
tp_svc_channel_type_streamed_media_remove_streams (TpSvcChannelTypeStreamedMedia *self,
    const GArray *in_Streams,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_streamed_media_remove_streams_impl impl = (TP_SVC_CHANNEL_TYPE_STREAMED_MEDIA_GET_CLASS (self)->remove_streams_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Streams,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_streamed_media_implement_remove_streams (TpSvcChannelTypeStreamedMediaClass *klass, tp_svc_channel_type_streamed_media_remove_streams_impl impl)
{
  klass->remove_streams_cb = impl;
}

static void
tp_svc_channel_type_streamed_media_request_stream_direction (TpSvcChannelTypeStreamedMedia *self,
    guint in_Stream_ID,
    guint in_Stream_Direction,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_streamed_media_request_stream_direction_impl impl = (TP_SVC_CHANNEL_TYPE_STREAMED_MEDIA_GET_CLASS (self)->request_stream_direction_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Stream_ID,
        in_Stream_Direction,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_streamed_media_implement_request_stream_direction (TpSvcChannelTypeStreamedMediaClass *klass, tp_svc_channel_type_streamed_media_request_stream_direction_impl impl)
{
  klass->request_stream_direction_cb = impl;
}

static void
tp_svc_channel_type_streamed_media_request_streams (TpSvcChannelTypeStreamedMedia *self,
    guint in_Contact_Handle,
    const GArray *in_Types,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_streamed_media_request_streams_impl impl = (TP_SVC_CHANNEL_TYPE_STREAMED_MEDIA_GET_CLASS (self)->request_streams_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact_Handle,
        in_Types,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_streamed_media_implement_request_streams (TpSvcChannelTypeStreamedMediaClass *klass, tp_svc_channel_type_streamed_media_request_streams_impl impl)
{
  klass->request_streams_cb = impl;
}

void
tp_svc_channel_type_streamed_media_emit_stream_added (gpointer instance,
    guint arg_Stream_ID,
    guint arg_Contact_Handle,
    guint arg_Stream_Type)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA));
  g_signal_emit (instance,
      channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamAdded],
      0,
      arg_Stream_ID,
      arg_Contact_Handle,
      arg_Stream_Type);
}

void
tp_svc_channel_type_streamed_media_emit_stream_direction_changed (gpointer instance,
    guint arg_Stream_ID,
    guint arg_Stream_Direction,
    guint arg_Pending_Flags)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA));
  g_signal_emit (instance,
      channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamDirectionChanged],
      0,
      arg_Stream_ID,
      arg_Stream_Direction,
      arg_Pending_Flags);
}

void
tp_svc_channel_type_streamed_media_emit_stream_error (gpointer instance,
    guint arg_Stream_ID,
    guint arg_Error_Code,
    const gchar *arg_Message)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA));
  g_signal_emit (instance,
      channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamError],
      0,
      arg_Stream_ID,
      arg_Error_Code,
      arg_Message);
}

void
tp_svc_channel_type_streamed_media_emit_stream_removed (gpointer instance,
    guint arg_Stream_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA));
  g_signal_emit (instance,
      channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamRemoved],
      0,
      arg_Stream_ID);
}

void
tp_svc_channel_type_streamed_media_emit_stream_state_changed (gpointer instance,
    guint arg_Stream_ID,
    guint arg_Stream_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA));
  g_signal_emit (instance,
      channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamStateChanged],
      0,
      arg_Stream_ID,
      arg_Stream_State);
}

static inline void
tp_svc_channel_type_streamed_media_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* InitialAudio */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* InitialVideo */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* ImmutableStreams */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_type_streamed_media_get_type (),
      &_tp_svc_channel_type_streamed_media_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Channel.Type.StreamedMedia");
  properties[0].name = g_quark_from_static_string ("InitialAudio");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("InitialVideo");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("ImmutableStreams");
  properties[2].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_TYPE_STREAMED_MEDIA, &interface);

  channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamAdded] =
  g_signal_new ("stream-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamDirectionChanged] =
  g_signal_new ("stream-direction-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamError] =
  g_signal_new ("stream-error",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING);

  channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamRemoved] =
  g_signal_new ("stream-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  channel_type_streamed_media_signals[SIGNAL_CHANNEL_TYPE_STREAMED_MEDIA_StreamStateChanged] =
  g_signal_new ("stream-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_type_streamed_media_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_streamed_media_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_streamed_media_methods[] = {
  { (GCallback) tp_svc_channel_type_streamed_media_list_streams, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_streamed_media_remove_streams, g_cclosure_marshal_generic, 92 },
  { (GCallback) tp_svc_channel_type_streamed_media_request_stream_direction, g_cclosure_marshal_generic, 175 },
  { (GCallback) tp_svc_channel_type_streamed_media_request_streams, g_cclosure_marshal_generic, 289 },
};

static const DBusGObjectInfo _tp_svc_channel_type_streamed_media_object_info = {
  0,
  _tp_svc_channel_type_streamed_media_methods,
  4,
"org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0ListStreams\0A\0Streams\0O\0F\0N\0a(uuuuuu)\0\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0RemoveStreams\0A\0Streams\0I\0au\0\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0RequestStreamDirection\0A\0Stream_ID\0I\0u\0Stream_Direction\0I\0u\0\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0RequestStreams\0A\0Contact_Handle\0I\0u\0Types\0I\0au\0Streams\0O\0F\0N\0a(uuuuuu)\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0StreamAdded\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0StreamDirectionChanged\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0StreamError\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0StreamRemoved\0org.freedesktop.Telepathy.Channel.Type.StreamedMedia\0StreamStateChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_text_object_info;

struct _TpSvcChannelTypeTextClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_text_acknowledge_pending_messages_impl acknowledge_pending_messages_cb;
    tp_svc_channel_type_text_get_message_types_impl get_message_types_cb;
    tp_svc_channel_type_text_list_pending_messages_impl list_pending_messages_cb;
    tp_svc_channel_type_text_send_impl send_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_TEXT_LostMessage,
    SIGNAL_CHANNEL_TYPE_TEXT_Received,
    SIGNAL_CHANNEL_TYPE_TEXT_SendError,
    SIGNAL_CHANNEL_TYPE_TEXT_Sent,
    N_CHANNEL_TYPE_TEXT_SIGNALS
};
static guint channel_type_text_signals[N_CHANNEL_TYPE_TEXT_SIGNALS] = {0};

static void tp_svc_channel_type_text_base_init (gpointer klass);

GType
tp_svc_channel_type_text_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeTextClass),
        tp_svc_channel_type_text_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeText", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_text_acknowledge_pending_messages (TpSvcChannelTypeText *self,
    const GArray *in_IDs,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_text_acknowledge_pending_messages_impl impl = (TP_SVC_CHANNEL_TYPE_TEXT_GET_CLASS (self)->acknowledge_pending_messages_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_IDs,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_text_implement_acknowledge_pending_messages (TpSvcChannelTypeTextClass *klass, tp_svc_channel_type_text_acknowledge_pending_messages_impl impl)
{
  klass->acknowledge_pending_messages_cb = impl;
}

static void
tp_svc_channel_type_text_get_message_types (TpSvcChannelTypeText *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_text_get_message_types_impl impl = (TP_SVC_CHANNEL_TYPE_TEXT_GET_CLASS (self)->get_message_types_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_text_implement_get_message_types (TpSvcChannelTypeTextClass *klass, tp_svc_channel_type_text_get_message_types_impl impl)
{
  klass->get_message_types_cb = impl;
}

static void
tp_svc_channel_type_text_list_pending_messages (TpSvcChannelTypeText *self,
    gboolean in_Clear,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_text_list_pending_messages_impl impl = (TP_SVC_CHANNEL_TYPE_TEXT_GET_CLASS (self)->list_pending_messages_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Clear,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_text_implement_list_pending_messages (TpSvcChannelTypeTextClass *klass, tp_svc_channel_type_text_list_pending_messages_impl impl)
{
  klass->list_pending_messages_cb = impl;
}

static void
tp_svc_channel_type_text_send (TpSvcChannelTypeText *self,
    guint in_Type,
    const gchar *in_Text,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_text_send_impl impl = (TP_SVC_CHANNEL_TYPE_TEXT_GET_CLASS (self)->send_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Type,
        in_Text,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_text_implement_send (TpSvcChannelTypeTextClass *klass, tp_svc_channel_type_text_send_impl impl)
{
  klass->send_cb = impl;
}

void
tp_svc_channel_type_text_emit_lost_message (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TEXT));
  g_signal_emit (instance,
      channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_LostMessage],
      0);
}

void
tp_svc_channel_type_text_emit_received (gpointer instance,
    guint arg_ID,
    guint arg_Timestamp,
    guint arg_Sender,
    guint arg_Type,
    guint arg_Flags,
    const gchar *arg_Text)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TEXT));
  g_signal_emit (instance,
      channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_Received],
      0,
      arg_ID,
      arg_Timestamp,
      arg_Sender,
      arg_Type,
      arg_Flags,
      arg_Text);
}

void
tp_svc_channel_type_text_emit_send_error (gpointer instance,
    guint arg_Error,
    guint arg_Timestamp,
    guint arg_Type,
    const gchar *arg_Text)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TEXT));
  g_signal_emit (instance,
      channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_SendError],
      0,
      arg_Error,
      arg_Timestamp,
      arg_Type,
      arg_Text);
}

void
tp_svc_channel_type_text_emit_sent (gpointer instance,
    guint arg_Timestamp,
    guint arg_Type,
    const gchar *arg_Text)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TEXT));
  g_signal_emit (instance,
      channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_Sent],
      0,
      arg_Timestamp,
      arg_Type,
      arg_Text);
}

static inline void
tp_svc_channel_type_text_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_type_text_get_type (),
      &_tp_svc_channel_type_text_object_info);

  channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_LostMessage] =
  g_signal_new ("lost-message",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_Received] =
  g_signal_new ("received",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      6,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING);

  channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_SendError] =
  g_signal_new ("send-error",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING);

  channel_type_text_signals[SIGNAL_CHANNEL_TYPE_TEXT_Sent] =
  g_signal_new ("sent",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING);

}
static void
tp_svc_channel_type_text_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_text_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_text_methods[] = {
  { (GCallback) tp_svc_channel_type_text_acknowledge_pending_messages, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_text_get_message_types, g_cclosure_marshal_generic, 83 },
  { (GCallback) tp_svc_channel_type_text_list_pending_messages, g_cclosure_marshal_generic, 171 },
  { (GCallback) tp_svc_channel_type_text_send, g_cclosure_marshal_generic, 281 },
};

static const DBusGObjectInfo _tp_svc_channel_type_text_object_info = {
  0,
  _tp_svc_channel_type_text_methods,
  4,
"org.freedesktop.Telepathy.Channel.Type.Text\0AcknowledgePendingMessages\0A\0IDs\0I\0au\0\0org.freedesktop.Telepathy.Channel.Type.Text\0GetMessageTypes\0A\0Available_Types\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Type.Text\0ListPendingMessages\0A\0Clear\0I\0b\0Pending_Messages\0O\0F\0N\0a(uuuuus)\0\0org.freedesktop.Telepathy.Channel.Type.Text\0Send\0A\0Type\0I\0u\0Text\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.Text\0LostMessage\0org.freedesktop.Telepathy.Channel.Type.Text\0Received\0org.freedesktop.Telepathy.Channel.Type.Text\0SendError\0org.freedesktop.Telepathy.Channel.Type.Text\0Sent\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_type_tubes_object_info;

struct _TpSvcChannelTypeTubesClass {
    GTypeInterface parent_class;
    tp_svc_channel_type_tubes_get_available_stream_tube_types_impl get_available_stream_tube_types_cb;
    tp_svc_channel_type_tubes_get_available_tube_types_impl get_available_tube_types_cb;
    tp_svc_channel_type_tubes_list_tubes_impl list_tubes_cb;
    tp_svc_channel_type_tubes_offer_d_bus_tube_impl offer_d_bus_tube_cb;
    tp_svc_channel_type_tubes_offer_stream_tube_impl offer_stream_tube_cb;
    tp_svc_channel_type_tubes_accept_d_bus_tube_impl accept_d_bus_tube_cb;
    tp_svc_channel_type_tubes_accept_stream_tube_impl accept_stream_tube_cb;
    tp_svc_channel_type_tubes_close_tube_impl close_tube_cb;
    tp_svc_channel_type_tubes_get_d_bus_tube_address_impl get_d_bus_tube_address_cb;
    tp_svc_channel_type_tubes_get_d_bus_names_impl get_d_bus_names_cb;
    tp_svc_channel_type_tubes_get_stream_tube_socket_address_impl get_stream_tube_socket_address_cb;
};

enum {
    SIGNAL_CHANNEL_TYPE_TUBES_NewTube,
    SIGNAL_CHANNEL_TYPE_TUBES_TubeStateChanged,
    SIGNAL_CHANNEL_TYPE_TUBES_TubeClosed,
    SIGNAL_CHANNEL_TYPE_TUBES_DBusNamesChanged,
    SIGNAL_CHANNEL_TYPE_TUBES_StreamTubeNewConnection,
    N_CHANNEL_TYPE_TUBES_SIGNALS
};
static guint channel_type_tubes_signals[N_CHANNEL_TYPE_TUBES_SIGNALS] = {0};

static void tp_svc_channel_type_tubes_base_init (gpointer klass);

GType
tp_svc_channel_type_tubes_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelTypeTubesClass),
        tp_svc_channel_type_tubes_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelTypeTubes", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_type_tubes_get_available_stream_tube_types (TpSvcChannelTypeTubes *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_get_available_stream_tube_types_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->get_available_stream_tube_types_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_get_available_stream_tube_types (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_get_available_stream_tube_types_impl impl)
{
  klass->get_available_stream_tube_types_cb = impl;
}

static void
tp_svc_channel_type_tubes_get_available_tube_types (TpSvcChannelTypeTubes *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_get_available_tube_types_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->get_available_tube_types_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_get_available_tube_types (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_get_available_tube_types_impl impl)
{
  klass->get_available_tube_types_cb = impl;
}

static void
tp_svc_channel_type_tubes_list_tubes (TpSvcChannelTypeTubes *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_list_tubes_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->list_tubes_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_list_tubes (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_list_tubes_impl impl)
{
  klass->list_tubes_cb = impl;
}

static void
tp_svc_channel_type_tubes_offer_d_bus_tube (TpSvcChannelTypeTubes *self,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_offer_d_bus_tube_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->offer_d_bus_tube_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Service,
        in_Parameters,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_offer_d_bus_tube (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_offer_d_bus_tube_impl impl)
{
  klass->offer_d_bus_tube_cb = impl;
}

static void
tp_svc_channel_type_tubes_offer_stream_tube (TpSvcChannelTypeTubes *self,
    const gchar *in_Service,
    GHashTable *in_Parameters,
    guint in_Address_Type,
    const GValue *in_Address,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_offer_stream_tube_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->offer_stream_tube_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Service,
        in_Parameters,
        in_Address_Type,
        in_Address,
        in_Access_Control,
        in_Access_Control_Param,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_offer_stream_tube (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_offer_stream_tube_impl impl)
{
  klass->offer_stream_tube_cb = impl;
}

static void
tp_svc_channel_type_tubes_accept_d_bus_tube (TpSvcChannelTypeTubes *self,
    guint in_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_accept_d_bus_tube_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->accept_d_bus_tube_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_accept_d_bus_tube (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_accept_d_bus_tube_impl impl)
{
  klass->accept_d_bus_tube_cb = impl;
}

static void
tp_svc_channel_type_tubes_accept_stream_tube (TpSvcChannelTypeTubes *self,
    guint in_ID,
    guint in_Address_Type,
    guint in_Access_Control,
    const GValue *in_Access_Control_Param,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_accept_stream_tube_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->accept_stream_tube_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        in_Address_Type,
        in_Access_Control,
        in_Access_Control_Param,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_accept_stream_tube (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_accept_stream_tube_impl impl)
{
  klass->accept_stream_tube_cb = impl;
}

static void
tp_svc_channel_type_tubes_close_tube (TpSvcChannelTypeTubes *self,
    guint in_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_close_tube_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->close_tube_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_close_tube (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_close_tube_impl impl)
{
  klass->close_tube_cb = impl;
}

static void
tp_svc_channel_type_tubes_get_d_bus_tube_address (TpSvcChannelTypeTubes *self,
    guint in_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_get_d_bus_tube_address_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->get_d_bus_tube_address_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_get_d_bus_tube_address (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_get_d_bus_tube_address_impl impl)
{
  klass->get_d_bus_tube_address_cb = impl;
}

static void
tp_svc_channel_type_tubes_get_d_bus_names (TpSvcChannelTypeTubes *self,
    guint in_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_get_d_bus_names_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->get_d_bus_names_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_get_d_bus_names (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_get_d_bus_names_impl impl)
{
  klass->get_d_bus_names_cb = impl;
}

static void
tp_svc_channel_type_tubes_get_stream_tube_socket_address (TpSvcChannelTypeTubes *self,
    guint in_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_type_tubes_get_stream_tube_socket_address_impl impl = (TP_SVC_CHANNEL_TYPE_TUBES_GET_CLASS (self)->get_stream_tube_socket_address_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_type_tubes_implement_get_stream_tube_socket_address (TpSvcChannelTypeTubesClass *klass, tp_svc_channel_type_tubes_get_stream_tube_socket_address_impl impl)
{
  klass->get_stream_tube_socket_address_cb = impl;
}

void
tp_svc_channel_type_tubes_emit_new_tube (gpointer instance,
    guint arg_ID,
    guint arg_Initiator,
    guint arg_Type,
    const gchar *arg_Service,
    GHashTable *arg_Parameters,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TUBES));
  g_signal_emit (instance,
      channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_NewTube],
      0,
      arg_ID,
      arg_Initiator,
      arg_Type,
      arg_Service,
      arg_Parameters,
      arg_State);
}

void
tp_svc_channel_type_tubes_emit_tube_state_changed (gpointer instance,
    guint arg_ID,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TUBES));
  g_signal_emit (instance,
      channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_TubeStateChanged],
      0,
      arg_ID,
      arg_State);
}

void
tp_svc_channel_type_tubes_emit_tube_closed (gpointer instance,
    guint arg_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TUBES));
  g_signal_emit (instance,
      channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_TubeClosed],
      0,
      arg_ID);
}

void
tp_svc_channel_type_tubes_emit_d_bus_names_changed (gpointer instance,
    guint arg_ID,
    const GPtrArray *arg_Added,
    const GArray *arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TUBES));
  g_signal_emit (instance,
      channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_DBusNamesChanged],
      0,
      arg_ID,
      arg_Added,
      arg_Removed);
}

void
tp_svc_channel_type_tubes_emit_stream_tube_new_connection (gpointer instance,
    guint arg_ID,
    guint arg_Handle)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_TYPE_TUBES));
  g_signal_emit (instance,
      channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_StreamTubeNewConnection],
      0,
      arg_ID,
      arg_Handle);
}

static inline void
tp_svc_channel_type_tubes_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_type_tubes_get_type (),
      &_tp_svc_channel_type_tubes_object_info);

  channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_NewTube] =
  g_signal_new ("new-tube",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      6,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_UINT);

  channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_TubeStateChanged] =
  g_signal_new ("tube-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

  channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_TubeClosed] =
  g_signal_new ("tube-closed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_DBusNamesChanged] =
  g_signal_new ("d-bus-names-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY);

  channel_type_tubes_signals[SIGNAL_CHANNEL_TYPE_TUBES_StreamTubeNewConnection] =
  g_signal_new ("stream-tube-new-connection",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_channel_type_tubes_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_type_tubes_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_type_tubes_methods[] = {
  { (GCallback) tp_svc_channel_type_tubes_get_available_stream_tube_types, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_type_tubes_get_available_tube_types, g_cclosure_marshal_generic, 117 },
  { (GCallback) tp_svc_channel_type_tubes_list_tubes, g_cclosure_marshal_generic, 217 },
  { (GCallback) tp_svc_channel_type_tubes_offer_d_bus_tube, g_cclosure_marshal_generic, 301 },
  { (GCallback) tp_svc_channel_type_tubes_offer_stream_tube, g_cclosure_marshal_generic, 410 },
  { (GCallback) tp_svc_channel_type_tubes_accept_d_bus_tube, g_cclosure_marshal_generic, 594 },
  { (GCallback) tp_svc_channel_type_tubes_accept_stream_tube, g_cclosure_marshal_generic, 680 },
  { (GCallback) tp_svc_channel_type_tubes_close_tube, g_cclosure_marshal_generic, 829 },
  { (GCallback) tp_svc_channel_type_tubes_get_d_bus_tube_address, g_cclosure_marshal_generic, 894 },
  { (GCallback) tp_svc_channel_type_tubes_get_d_bus_names, g_cclosure_marshal_generic, 984 },
  { (GCallback) tp_svc_channel_type_tubes_get_stream_tube_socket_address, g_cclosure_marshal_generic, 1075 },
};

static const DBusGObjectInfo _tp_svc_channel_type_tubes_object_info = {
  0,
  _tp_svc_channel_type_tubes_methods,
  11,
"org.freedesktop.Telepathy.Channel.Type.Tubes\0GetAvailableStreamTubeTypes\0A\0Available_Stream_Tube_Types\0O\0F\0N\0a{uau}\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0GetAvailableTubeTypes\0A\0Available_Tube_Types\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0ListTubes\0A\0Tubes\0O\0F\0N\0a(uuusa{sv}u)\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0OfferDBusTube\0A\0Service\0I\0s\0Parameters\0I\0a{sv}\0Tube_ID\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0OfferStreamTube\0A\0Service\0I\0s\0Parameters\0I\0a{sv}\0Address_Type\0I\0u\0Address\0I\0v\0Access_Control\0I\0u\0Access_Control_Param\0I\0v\0Tube_ID\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0AcceptDBusTube\0A\0ID\0I\0u\0Address\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0AcceptStreamTube\0A\0ID\0I\0u\0Address_Type\0I\0u\0Access_Control\0I\0u\0Access_Control_Param\0I\0v\0Address\0O\0F\0N\0v\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0CloseTube\0A\0ID\0I\0u\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0GetDBusTubeAddress\0A\0ID\0I\0u\0Address\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0GetDBusNames\0A\0ID\0I\0u\0DBus_Names\0O\0F\0N\0a(us)\0\0org.freedesktop.Telepathy.Channel.Type.Tubes\0GetStreamTubeSocketAddress\0A\0ID\0I\0u\0Address_Type\0O\0F\0N\0u\0Address\0O\0F\0N\0v\0\0\0",
"org.freedesktop.Telepathy.Channel.Type.Tubes\0NewTube\0org.freedesktop.Telepathy.Channel.Type.Tubes\0TubeStateChanged\0org.freedesktop.Telepathy.Channel.Type.Tubes\0TubeClosed\0org.freedesktop.Telepathy.Channel.Type.Tubes\0DBusNamesChanged\0org.freedesktop.Telepathy.Channel.Type.Tubes\0StreamTubeNewConnection\0\0",
"\0\0",
};


