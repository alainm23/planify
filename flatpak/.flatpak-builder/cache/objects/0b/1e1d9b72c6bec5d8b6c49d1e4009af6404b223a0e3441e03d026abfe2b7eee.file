/*
 * tls-certificate-rejection.h
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


#ifndef __TP_TLS_CERTIFICATE_REJECTION_H__
#define __TP_TLS_CERTIFICATE_REJECTION_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>

G_BEGIN_DECLS

typedef struct _TpTLSCertificateRejection TpTLSCertificateRejection;
typedef struct _TpTLSCertificateRejectionClass TpTLSCertificateRejectionClass;
typedef struct _TpTLSCertificateRejectionPriv TpTLSCertificateRejectionPriv;

struct _TpTLSCertificateRejectionClass {
  /*<private>*/
  GObjectClass parent_class;
};

struct _TpTLSCertificateRejection {
  /*<private>*/
  GObject parent;
  TpTLSCertificateRejectionPriv *priv;
};

_TP_AVAILABLE_IN_0_20
GType tp_tls_certificate_rejection_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_TLS_CERTIFICATE_REJECTION \
  (tp_tls_certificate_rejection_get_type ())
#define TP_TLS_CERTIFICATE_REJECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), \
    TP_TYPE_TLS_CERTIFICATE_REJECTION, \
    TpTLSCertificateRejection))
#define TP_TLS_CERTIFICATE_REJECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
    TP_TYPE_TLS_CERTIFICATE_REJECTION, \
    TpTLSCertificateRejectionClass))
#define TP_IS_TLS_CERTIFICATE_REJECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), \
    TP_TYPE_TLS_CERTIFICATE_REJECTION))
#define TP_IS_TLS_CERTIFICATE_REJECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), \
    TP_TYPE_TLS_CERTIFICATE_REJECTION))
#define TP_TLS_CERTIFICATE_REJECTION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
    TP_TYPE_TLS_CERTIFICATE_REJECTION, \
    TpTLSCertificateRejectionClass))

_TP_AVAILABLE_IN_0_20
const GError * tp_tls_certificate_rejection_get_error (
    TpTLSCertificateRejection *self);
_TP_AVAILABLE_IN_0_20
TpTLSCertificateRejectReason tp_tls_certificate_rejection_get_reason (
    TpTLSCertificateRejection *self);
_TP_AVAILABLE_IN_0_20
const gchar * tp_tls_certificate_rejection_get_dbus_error (
    TpTLSCertificateRejection *self);
_TP_AVAILABLE_IN_0_20
GVariant * tp_tls_certificate_rejection_get_details (
    TpTLSCertificateRejection *self);

_TP_AVAILABLE_IN_0_20
gboolean tp_tls_certificate_rejection_raise_error (
    TpTLSCertificateRejection *self,
    GError **error);

G_END_DECLS

#endif /* #ifndef __TP_TLS_CERTIFICATE_REJECTION_H__*/
