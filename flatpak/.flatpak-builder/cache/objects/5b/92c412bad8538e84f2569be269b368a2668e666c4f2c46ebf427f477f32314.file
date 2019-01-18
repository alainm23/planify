/*
 * TpTLSCertificate - a TpProxy for TLS certificates
 * Copyright © 2010 Collabora Ltd.
 *
 * Based on EmpathyTLSCertificate:
 * @author Cosimo Cecchi <cosimo.cecchi@collabora.co.uk>
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

#ifndef __TP_TLS_CERTIFICATE_H__
#define __TP_TLS_CERTIFICATE_H__

#include <glib-object.h>
#include <gio/gio.h>

#include <telepathy-glib/channel.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/proxy.h>
#include <telepathy-glib/tls-certificate-rejection.h>

G_BEGIN_DECLS

typedef struct _TpTLSCertificate TpTLSCertificate;
typedef struct _TpTLSCertificateClass TpTLSCertificateClass;
typedef struct _TpTLSCertificatePrivate TpTLSCertificatePrivate;
typedef struct _TpTLSCertificateClassPrivate TpTLSCertificateClassPrivate;

struct _TpTLSCertificateClass {
    /*<private>*/
    TpProxyClass parent_class;
    GCallback _future[3];
    TpTLSCertificateClassPrivate *priv;
};

struct _TpTLSCertificate {
    /*<private>*/
    TpProxy parent;
    TpTLSCertificatePrivate *priv;
};

_TP_AVAILABLE_IN_0_20
GType tp_tls_certificate_get_type (void);

#define TP_TYPE_TLS_CERTIFICATE \
  (tp_tls_certificate_get_type ())
#define TP_TLS_CERTIFICATE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_TLS_CERTIFICATE, \
                               TpTLSCertificate))
#define TP_TLS_CERTIFICATE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_TLS_CERTIFICATE, \
                            TpTLSCertificateClass))
#define TP_IS_TLS_CERTIFICATE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_TLS_CERTIFICATE))
#define TP_IS_TLS_CERTIFICATE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_TLS_CERTIFICATE))
#define TP_TLS_CERTIFICATE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_TLS_CERTIFICATE, \
                              TpTLSCertificateClass))

_TP_AVAILABLE_IN_0_20
GQuark tp_tls_certificate_get_feature_quark_core (void);
#define TP_TLS_CERTIFICATE_FEATURE_CORE \
  (tp_tls_certificate_get_feature_quark_core ())

_TP_AVAILABLE_IN_0_20
TpTLSCertificate *tp_tls_certificate_new (TpProxy *conn_or_chan,
    const gchar *object_path,
    GError **error);

_TP_AVAILABLE_IN_0_20
TpTLSCertificateRejection *tp_tls_certificate_get_rejection (
    TpTLSCertificate *self);

_TP_AVAILABLE_IN_0_20
TpTLSCertificateRejection *tp_tls_certificate_get_nth_rejection (
    TpTLSCertificate *self,
    guint n);

_TP_AVAILABLE_IN_0_20
void tp_tls_certificate_accept_async (TpTLSCertificate *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_20
gboolean tp_tls_certificate_accept_finish (TpTLSCertificate *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_20
void tp_tls_certificate_add_rejection (TpTLSCertificate *self,
    TpTLSCertificateRejectReason reason,
    const gchar *dbus_error,
    GVariant *details);
_TP_AVAILABLE_IN_0_20
void tp_tls_certificate_reject_async (TpTLSCertificate *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_20
gboolean tp_tls_certificate_reject_finish (TpTLSCertificate *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_20
void tp_tls_certificate_init_known_interfaces (void);

_TP_AVAILABLE_IN_0_20
const gchar * tp_tls_certificate_get_cert_type (TpTLSCertificate *self);
_TP_AVAILABLE_IN_0_20
GPtrArray * tp_tls_certificate_get_cert_data (TpTLSCertificate *self);
_TP_AVAILABLE_IN_0_20
TpTLSCertificateState tp_tls_certificate_get_state (TpTLSCertificate *self);

G_END_DECLS

#endif /* multiple-inclusion guard */
