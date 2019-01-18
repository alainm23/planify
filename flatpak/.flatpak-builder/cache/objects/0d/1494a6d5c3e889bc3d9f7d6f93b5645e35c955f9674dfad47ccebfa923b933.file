/*
 * tls-certificate-rejection.c
 *
 * Copyright (C) 2012 Collabora Ltd. <http://www.collabora.co.uk/>
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


#include "config.h"

#include "tls-certificate-rejection.h"
#include "tls-certificate-rejection-internal.h"

/**
 * SECTION: tls-certificate-rejection
 * @title: TpTLSCertificateRejection
 * @short_description: a certificate rejection
 *
 * TpTLSCertificateRejection is a small object used by
 * #TpTLSCertificate to represent the rejection of a
 * certificate.
 */

/**
 * TpTLSCertificateRejection:
 *
 * Data structure representing a #TpTLSCertificateRejection.
 *
 * Since: 0.19.0
 */

/**
 * TpTLSCertificateRejectionClass:
 *
 * The class of a #TpTLSCertificateRejection.
 *
 * Since: 0.19.0
 */

G_DEFINE_TYPE (TpTLSCertificateRejection, tp_tls_certificate_rejection,
    G_TYPE_OBJECT)

enum
{
  PROP_REASON = 1,
  PROP_DBUS_ERROR,
  PROP_DETAILS,
  PROP_ERROR,
  N_PROPS
};

struct _TpTLSCertificateRejectionPriv {
  TpTLSCertificateRejectReason reason;
  gchar *dbus_error;
  GVariant *details;
  GError *error;
};

static void
tp_tls_certificate_rejection_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpTLSCertificateRejection *self = TP_TLS_CERTIFICATE_REJECTION (object);

  switch (property_id)
    {
      case PROP_REASON:
        g_value_set_uint (value, self->priv->reason);
        break;
      case PROP_DBUS_ERROR:
        g_value_set_string (value, self->priv->dbus_error);
        break;
      case PROP_DETAILS:
        g_value_set_variant (value, self->priv->details);
        break;
      case PROP_ERROR:
        g_value_set_boxed (value, self->priv->error);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_tls_certificate_rejection_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpTLSCertificateRejection *self = TP_TLS_CERTIFICATE_REJECTION (object);

  switch (property_id)
    {
      case PROP_REASON:
        self->priv->reason = g_value_get_uint (value);
        break;
      case PROP_DBUS_ERROR:
        g_assert (self->priv->dbus_error == NULL); /* construct only */
        self->priv->dbus_error = g_value_dup_string (value);
        break;
      case PROP_DETAILS:
        self->priv->details = g_value_dup_variant (value);
        break;
      case PROP_ERROR:
        self->priv->error = g_value_dup_boxed (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_tls_certificate_rejection_dispose (GObject *object)
{
  TpTLSCertificateRejection *self = TP_TLS_CERTIFICATE_REJECTION (object);
  void (*chain_up) (GObject *) =
      ((GObjectClass *) tp_tls_certificate_rejection_parent_class)->dispose;

  g_variant_unref (self->priv->details);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_tls_certificate_rejection_finalize (GObject *object)
{
  TpTLSCertificateRejection *self = TP_TLS_CERTIFICATE_REJECTION (object);
  void (*chain_up) (GObject *) =
      ((GObjectClass *) tp_tls_certificate_rejection_parent_class)->finalize;

  g_free (self->priv->dbus_error);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_tls_certificate_rejection_class_init (
    TpTLSCertificateRejectionClass *klass)
{
  GObjectClass *oclass = G_OBJECT_CLASS (klass);
  GParamSpec *spec;

  oclass->get_property = tp_tls_certificate_rejection_get_property;
  oclass->set_property = tp_tls_certificate_rejection_set_property;
  oclass->dispose = tp_tls_certificate_rejection_dispose;
  oclass->finalize = tp_tls_certificate_rejection_finalize;

  /**
   * TpTLSCertificateRejection:reason:
   *
   * #TpTLSCertificateRejectReason representing the reason of the rejection
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_uint ("reason", "reason",
      "TpTLSCertificateRejectReason",
      TP_TLS_CERTIFICATE_REJECT_REASON_UNKNOWN,
      TP_NUM_TLS_CERTIFICATE_REJECT_REASONS,
      TP_TLS_CERTIFICATE_REJECT_REASON_UNKNOWN,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_REASON, spec);

  /**
   * TpTLSCertificateRejection:dbus-error:
   *
   * The D-Bus error name of the rejection
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_string ("dbus-error", "dbus-error",
      "DBus error",
      NULL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_DBUS_ERROR, spec);

  /**
   * TpTLSCertificateRejection:details:
   *
   * A #G_VARIANT_TYPE_VARDICT containing the details of the rejection
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_variant ("details", "details",
      "GVariant",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_DETAILS, spec);

  /**
   * TpTLSCertificateRejection:error:
   *
   * a #GError (likely to be in the %TP_ERROR domain) indicating the reason
   * of the rejection
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_boxed ("error", "error",
      "GError",
      G_TYPE_ERROR,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_ERROR, spec);

  g_type_class_add_private (klass, sizeof (TpTLSCertificateRejectionPriv));
}

static void
tp_tls_certificate_rejection_init (TpTLSCertificateRejection *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_TLS_CERTIFICATE_REJECTION, TpTLSCertificateRejectionPriv);
}

/* @details is sinked if it's a floating reference */
TpTLSCertificateRejection *
_tp_tls_certificate_rejection_new (
    GError *error,
    TpTLSCertificateRejectReason reason,
    const gchar *dbus_error,
    GVariant *details)
{
  TpTLSCertificateRejection *ret;

  g_variant_ref_sink (details);

  ret =  g_object_new (TP_TYPE_TLS_CERTIFICATE_REJECTION,
      "error", error,
      "reason", reason,
      "dbus-error", dbus_error,
      "details", details,
      NULL);

  g_variant_unref (details);
  return ret;
}

/**
 * tp_tls_certificate_rejection_get_error:
 * @self: a #TpTLSCertificateRejection
 *
 * Return the #TpTLSCertificateRejection:error property
 *
 * Returns: the value of #TpTLSCertificateRejection:error property
 *
 * Since: 0.19.0
 */
const GError *
tp_tls_certificate_rejection_get_error (TpTLSCertificateRejection *self)
{
  return self->priv->error;
}

/**
 * tp_tls_certificate_rejection_get_reason:
 * @self: a #TpTLSCertificateRejection
 *
 * Return the #TpTLSCertificateRejection:reason property
 *
 * Returns: the value of #TpTLSCertificateRejection:reason property
 *
 * Since: 0.19.0
 */
TpTLSCertificateRejectReason
tp_tls_certificate_rejection_get_reason (TpTLSCertificateRejection *self)
{
  return self->priv->reason;
}

/**
 * tp_tls_certificate_rejection_get_dbus_error:
 * @self: a #TpTLSCertificateRejection
 *
 * Return the #TpTLSCertificateRejection:dbus-error property
 *
 * Returns: the value of #TpTLSCertificateRejection:dbus-error property
 *
 * Since: 0.19.0
 */
const gchar *
tp_tls_certificate_rejection_get_dbus_error (TpTLSCertificateRejection *self)
{
  return self->priv->dbus_error;
}

/**
 * tp_tls_certificate_rejection_get_details:
 * @self: a #TpTLSCertificateRejection
 *
 * Return the #TpTLSCertificateRejection:details property
 *
 * Returns: the value of #TpTLSCertificateRejection:details property
 *
 * Since: 0.19.0
 */
GVariant *
tp_tls_certificate_rejection_get_details (TpTLSCertificateRejection *self)
{
  return self->priv->details;
}

/**
 * tp_tls_certificate_rejection_raise_error:
 * @self: a #TpTLSCertificateRejection
 * @error: (out) (allow-none) (transfer full): a #GError to fill
 *
 * Convenient function to raise the #TpTLSCertificateRejection:error
 * property in language binding supporting this feature.
 *
 * Returns: %FALSE
 *
 * Since: 0.19.0
 */
gboolean
tp_tls_certificate_rejection_raise_error (TpTLSCertificateRejection *self,
    GError **error)
{
  if (error != NULL)
    *error = g_error_copy (self->priv->error);

  return FALSE;
}
