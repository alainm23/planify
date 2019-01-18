/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * The Initial Developer of the Original Code is Netscape
 * Communications Corporation.  Portions created by Netscape are
 * Copyright (C) 1994-2000 Netscape Communications Corporation.  All
 * Rights Reserved.
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 *          Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#ifdef ENABLE_SMIME

#include "nss.h"
#include <cms.h>
#include <cert.h>
#include <certdb.h>
#include <pkcs11.h>
#include <smime.h>
#include <secerr.h>
#include <pkcs11t.h>
#include <pk11func.h>
#include <secoid.h>

#include <errno.h>

#include <glib/gi18n-lib.h>

#include "camel-data-wrapper.h"
#include "camel-mime-filter-basic.h"
#include "camel-mime-filter-canon.h"
#include "camel-mime-part.h"
#include "camel-multipart-signed.h"
#include "camel-operation.h"
#include "camel-session.h"
#include "camel-smime-context.h"
#include "camel-stream-filter.h"
#include "camel-stream-fs.h"
#include "camel-stream-mem.h"
#include "camel-string-utils.h"

#define d(x)

#define CAMEL_SMIME_CONTEXT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SMIME_CONTEXT, CamelSMIMEContextPrivate))

struct _CamelSMIMEContextPrivate {
	CERTCertDBHandle *certdb;

	gchar *encrypt_key;
	CamelSMIMESign sign_mode;

	gint password_tries;
	guint send_encrypt_key_prefs : 1;
};

G_DEFINE_TYPE (CamelSMIMEContext, camel_smime_context, CAMEL_TYPE_CIPHER_CONTEXT)

static void
smime_cert_data_free (gpointer cert_data)
{
	g_return_if_fail (cert_data != NULL);

	CERT_DestroyCertificate (cert_data);
}

static gpointer
smime_cert_data_clone (gpointer cert_data)
{
	g_return_val_if_fail (cert_data != NULL, NULL);

	return CERT_DupCertificate (cert_data);
}

/* used for decode content callback, for streaming decode */
static void
sm_write_stream (gpointer arg,
                 const gchar *buf,
                 gulong len)
{
	camel_stream_write ((CamelStream *) arg, buf, len, NULL, NULL);
}

static PK11SymKey *
sm_decrypt_key (gpointer arg,
                SECAlgorithmID *algid)
{
	printf ("Decrypt key called\n");
	return (PK11SymKey *) arg;
}

static const gchar *
nss_error_to_string (glong errorcode)
{
#define cs(a,b) case a: return b;

	switch (errorcode) {
	cs (SEC_ERROR_IO, "An I/O error occurred during security authorization.")
	cs (SEC_ERROR_LIBRARY_FAILURE, "security library failure.")
	cs (SEC_ERROR_BAD_DATA, "security library: received bad data.")
	cs (SEC_ERROR_OUTPUT_LEN, "security library: output length error.")
	cs (SEC_ERROR_INPUT_LEN, "security library has experienced an input length error.")
	cs (SEC_ERROR_INVALID_ARGS, "security library: invalid arguments.")
	cs (SEC_ERROR_INVALID_ALGORITHM, "security library: invalid algorithm.")
	cs (SEC_ERROR_INVALID_AVA, "security library: invalid AVA.")
	cs (SEC_ERROR_INVALID_TIME, "Improperly formatted time string.")
	cs (SEC_ERROR_BAD_DER, "security library: improperly formatted DER-encoded message.")
	cs (SEC_ERROR_BAD_SIGNATURE, "Peer's certificate has an invalid signature.")
	cs (SEC_ERROR_EXPIRED_CERTIFICATE, "Peer's Certificate has expired.")
	cs (SEC_ERROR_REVOKED_CERTIFICATE, "Peer's Certificate has been revoked.")
	cs (SEC_ERROR_UNKNOWN_ISSUER, "Peer's Certificate issuer is not recognized.")
	cs (SEC_ERROR_BAD_KEY, "Peer's public key is invalid.")
	cs (SEC_ERROR_BAD_PASSWORD, "The security password entered is incorrect.")
	cs (SEC_ERROR_RETRY_PASSWORD, "New password entered incorrectly.  Please try again.")
	cs (SEC_ERROR_NO_NODELOCK, "security library: no nodelock.")
	cs (SEC_ERROR_BAD_DATABASE, "security library: bad database.")
	cs (SEC_ERROR_NO_MEMORY, "security library: memory allocation failure.")
	cs (SEC_ERROR_UNTRUSTED_ISSUER, "Peer's certificate issuer has been marked as not trusted by the user.")
	cs (SEC_ERROR_UNTRUSTED_CERT, "Peer's certificate has been marked as not trusted by the user.")
	cs (SEC_ERROR_DUPLICATE_CERT, "Certificate already exists in your database.")
	cs (SEC_ERROR_DUPLICATE_CERT_NAME, "Downloaded certificate's name duplicates one already in your database.")
	cs (SEC_ERROR_ADDING_CERT, "Error adding certificate to database.")
	cs (SEC_ERROR_FILING_KEY, "Error refiling the key for this certificate.")
	cs (SEC_ERROR_NO_KEY, "The private key for this certificate cannot be found in key database")
	cs (SEC_ERROR_CERT_VALID, "This certificate is valid.")
	cs (SEC_ERROR_CERT_NOT_VALID, "This certificate is not valid.")
	cs (SEC_ERROR_CERT_NO_RESPONSE, "Cert Library: No Response")
	cs (SEC_ERROR_EXPIRED_ISSUER_CERTIFICATE, "The certificate issuer's certificate has expired.  Check your system date and time.")
	cs (SEC_ERROR_CRL_EXPIRED, "The CRL for the certificate's issuer has expired.  Update it or check your system date and time.")
	cs (SEC_ERROR_CRL_BAD_SIGNATURE, "The CRL for the certificate's issuer has an invalid signature.")
	cs (SEC_ERROR_CRL_INVALID, "New CRL has an invalid format.")
	cs (SEC_ERROR_EXTENSION_VALUE_INVALID, "Certificate extension value is invalid.")
	cs (SEC_ERROR_EXTENSION_NOT_FOUND, "Certificate extension not found.")
	cs (SEC_ERROR_CA_CERT_INVALID, "Issuer certificate is invalid.")
	cs (SEC_ERROR_PATH_LEN_CONSTRAINT_INVALID, "Certificate path length constraint is invalid.")
	cs (SEC_ERROR_CERT_USAGES_INVALID, "Certificate usages field is invalid.")
	cs (SEC_INTERNAL_ONLY, "**Internal ONLY module**")
	cs (SEC_ERROR_INVALID_KEY, "The key does not support the requested operation.")
	cs (SEC_ERROR_UNKNOWN_CRITICAL_EXTENSION, "Certificate contains unknown critical extension.")
	cs (SEC_ERROR_OLD_CRL, "New CRL is not later than the current one.")
	cs (SEC_ERROR_NO_EMAIL_CERT, "Not encrypted or signed: you do not yet have an email certificate.")
	cs (SEC_ERROR_NO_RECIPIENT_CERTS_QUERY, "Not encrypted: you do not have certificates for each of the recipients.")
	cs (SEC_ERROR_NOT_A_RECIPIENT, "Cannot decrypt: you are not a recipient, or matching certificate and private key not found.")
	cs (SEC_ERROR_PKCS7_KEYALG_MISMATCH, "Cannot decrypt: key encryption algorithm does not match your certificate.")
	cs (SEC_ERROR_PKCS7_BAD_SIGNATURE, "Signature verification failed: no signer found, too many signers found, or improper or corrupted data.")
	cs (SEC_ERROR_UNSUPPORTED_KEYALG, "Unsupported or unknown key algorithm.")
	cs (SEC_ERROR_DECRYPTION_DISALLOWED, "Cannot decrypt: encrypted using a disallowed algorithm or key size.")
	cs (XP_SEC_FORTEZZA_BAD_CARD, "Fortezza card has not been properly initialized.  Please remove it and return it to your issuer.")
	cs (XP_SEC_FORTEZZA_NO_CARD, "No Fortezza cards Found")
	cs (XP_SEC_FORTEZZA_NONE_SELECTED, "No Fortezza card selected")
	cs (XP_SEC_FORTEZZA_MORE_INFO, "Please select a personality to get more info on")
	cs (XP_SEC_FORTEZZA_PERSON_NOT_FOUND, "Personality not found")
	cs (XP_SEC_FORTEZZA_NO_MORE_INFO, "No more information on that Personality")
	cs (XP_SEC_FORTEZZA_BAD_PIN, "Invalid Pin")
	cs (XP_SEC_FORTEZZA_PERSON_ERROR, "Couldn't initialize Fortezza personalities.")
	cs (SEC_ERROR_NO_KRL, "No KRL for this site's certificate has been found.")
	cs (SEC_ERROR_KRL_EXPIRED, "The KRL for this site's certificate has expired.")
	cs (SEC_ERROR_KRL_BAD_SIGNATURE, "The KRL for this site's certificate has an invalid signature.")
	cs (SEC_ERROR_REVOKED_KEY, "The key for this site's certificate has been revoked.")
	cs (SEC_ERROR_KRL_INVALID, "New KRL has an invalid format.")
	cs (SEC_ERROR_NEED_RANDOM, "security library: need random data.")
	cs (SEC_ERROR_NO_MODULE, "security library: no security module can perform the requested operation.")
	cs (SEC_ERROR_NO_TOKEN, "The security card or token does not exist, needs to be initialized, or has been removed.")
	cs (SEC_ERROR_READ_ONLY, "security library: read-only database.")
	cs (SEC_ERROR_NO_SLOT_SELECTED, "No slot or token was selected.")
	cs (SEC_ERROR_CERT_NICKNAME_COLLISION, "A certificate with the same nickname already exists.")
	cs (SEC_ERROR_KEY_NICKNAME_COLLISION, "A key with the same nickname already exists.")
	cs (SEC_ERROR_SAFE_NOT_CREATED, "error while creating safe object")
	cs (SEC_ERROR_BAGGAGE_NOT_CREATED, "error while creating baggage object")
	cs (XP_JAVA_REMOVE_PRINCIPAL_ERROR, "Couldn't remove the principal")
	cs (XP_JAVA_DELETE_PRIVILEGE_ERROR, "Couldn't delete the privilege")
	cs (XP_JAVA_CERT_NOT_EXISTS_ERROR, "This principal doesn't have a certificate")
	cs (SEC_ERROR_BAD_EXPORT_ALGORITHM, "Required algorithm is not allowed.")
	cs (SEC_ERROR_EXPORTING_CERTIFICATES, "Error attempting to export certificates.")
	cs (SEC_ERROR_IMPORTING_CERTIFICATES, "Error attempting to import certificates.")
	cs (SEC_ERROR_PKCS12_DECODING_PFX, "Unable to import.  Decoding error.  File not valid.")
	cs (SEC_ERROR_PKCS12_INVALID_MAC, "Unable to import.  Invalid MAC.  Incorrect password or corrupt file.")
	cs (SEC_ERROR_PKCS12_UNSUPPORTED_MAC_ALGORITHM, "Unable to import.  MAC algorithm not supported.")
	cs (SEC_ERROR_PKCS12_UNSUPPORTED_TRANSPORT_MODE, "Unable to import.  Only password integrity and privacy modes supported.")
	cs (SEC_ERROR_PKCS12_CORRUPT_PFX_STRUCTURE, "Unable to import.  File structure is corrupt.")
	cs (SEC_ERROR_PKCS12_UNSUPPORTED_PBE_ALGORITHM, "Unable to import.  Encryption algorithm not supported.")
	cs (SEC_ERROR_PKCS12_UNSUPPORTED_VERSION, "Unable to import.  File version not supported.")
	cs (SEC_ERROR_PKCS12_PRIVACY_PASSWORD_INCORRECT, "Unable to import.  Incorrect privacy password.")
	cs (SEC_ERROR_PKCS12_CERT_COLLISION, "Unable to import.  Same nickname already exists in database.")
	cs (SEC_ERROR_USER_CANCELLED, "The user pressed cancel.")
	cs (SEC_ERROR_PKCS12_DUPLICATE_DATA, "Not imported, already in database.")
	cs (SEC_ERROR_MESSAGE_SEND_ABORTED, "Message not sent.")
	cs (SEC_ERROR_INADEQUATE_KEY_USAGE, "Certificate key usage inadequate for attempted operation.")
	cs (SEC_ERROR_INADEQUATE_CERT_TYPE, "Certificate type not approved for application.")
	cs (SEC_ERROR_CERT_ADDR_MISMATCH, "Address in signing certificate does not match address in message headers.")
	cs (SEC_ERROR_PKCS12_UNABLE_TO_IMPORT_KEY, "Unable to import.  Error attempting to import private key.")
	cs (SEC_ERROR_PKCS12_IMPORTING_CERT_CHAIN, "Unable to import.  Error attempting to import certificate chain.")
	cs (SEC_ERROR_PKCS12_UNABLE_TO_LOCATE_OBJECT_BY_NAME, "Unable to export.  Unable to locate certificate or key by nickname.")
	cs (SEC_ERROR_PKCS12_UNABLE_TO_EXPORT_KEY, "Unable to export.  Private Key could not be located and exported.")
	cs (SEC_ERROR_PKCS12_UNABLE_TO_WRITE, "Unable to export.  Unable to write the export file.")
	cs (SEC_ERROR_PKCS12_UNABLE_TO_READ, "Unable to import.  Unable to read the import file.")
	cs (SEC_ERROR_PKCS12_KEY_DATABASE_NOT_INITIALIZED, "Unable to export.  Key database corrupt or deleted.")
	cs (SEC_ERROR_KEYGEN_FAIL, "Unable to generate public/private key pair.")
	cs (SEC_ERROR_INVALID_PASSWORD, "Password entered is invalid.  Please pick a different one.")
	cs (SEC_ERROR_RETRY_OLD_PASSWORD, "Old password entered incorrectly.  Please try again.")
	cs (SEC_ERROR_BAD_NICKNAME, "Certificate nickname already in use.")
	cs (SEC_ERROR_NOT_FORTEZZA_ISSUER, "Peer FORTEZZA chain has a non-FORTEZZA Certificate.")
	cs (SEC_ERROR_CANNOT_MOVE_SENSITIVE_KEY, "A sensitive key cannot be moved to the slot where it is needed.")
	cs (SEC_ERROR_JS_INVALID_MODULE_NAME, "Invalid module name.")
	cs (SEC_ERROR_JS_INVALID_DLL, "Invalid module path/filename")
	cs (SEC_ERROR_JS_ADD_MOD_FAILURE, "Unable to add module")
	cs (SEC_ERROR_JS_DEL_MOD_FAILURE, "Unable to delete module")
	cs (SEC_ERROR_OLD_KRL, "New KRL is not later than the current one.")
	cs (SEC_ERROR_CKL_CONFLICT, "New CKL has different issuer than current CKL.  Delete current CKL.")
	cs (SEC_ERROR_CERT_NOT_IN_NAME_SPACE, "The Certifying Authority for this certificate is not permitted to issue a certificate with this name.")
	cs (SEC_ERROR_KRL_NOT_YET_VALID, "The key revocation list for this certificate is not yet valid.")
	cs (SEC_ERROR_CRL_NOT_YET_VALID, "The certificate revocation list for this certificate is not yet valid.")
	cs (SEC_ERROR_UNKNOWN_CERT, "The requested certificate could not be found.")
	cs (SEC_ERROR_UNKNOWN_SIGNER, "The signer's certificate could not be found.")
	cs (SEC_ERROR_CERT_BAD_ACCESS_LOCATION,	 "The location for the certificate status server has invalid format.")
	cs (SEC_ERROR_OCSP_UNKNOWN_RESPONSE_TYPE, "The OCSP response cannot be fully decoded; it is of an unknown type.")
	cs (SEC_ERROR_OCSP_BAD_HTTP_RESPONSE, "The OCSP server returned unexpected/invalid HTTP data.")
	cs (SEC_ERROR_OCSP_MALFORMED_REQUEST, "The OCSP server found the request to be corrupted or improperly formed.")
	cs (SEC_ERROR_OCSP_SERVER_ERROR, "The OCSP server experienced an internal error.")
	cs (SEC_ERROR_OCSP_TRY_SERVER_LATER, "The OCSP server suggests trying again later.")
	cs (SEC_ERROR_OCSP_REQUEST_NEEDS_SIG, "The OCSP server requires a signature on this request.")
	cs (SEC_ERROR_OCSP_UNAUTHORIZED_REQUEST, "The OCSP server has refused this request as unauthorized.")
	cs (SEC_ERROR_OCSP_UNKNOWN_RESPONSE_STATUS, "The OCSP server returned an unrecognizable status.")
	cs (SEC_ERROR_OCSP_UNKNOWN_CERT, "The OCSP server has no status for the certificate.")
	cs (SEC_ERROR_OCSP_NOT_ENABLED, "You must enable OCSP before performing this operation.")
	cs (SEC_ERROR_OCSP_NO_DEFAULT_RESPONDER, "You must set the OCSP default responder before performing this operation.")
	cs (SEC_ERROR_OCSP_MALFORMED_RESPONSE, "The response from the OCSP server was corrupted or improperly formed.")
	cs (SEC_ERROR_OCSP_UNAUTHORIZED_RESPONSE, "The signer of the OCSP response is not authorized to give status for this certificate.")
	cs (SEC_ERROR_OCSP_FUTURE_RESPONSE, "The OCSP response is not yet valid (contains a date in the future).")
	cs (SEC_ERROR_OCSP_OLD_RESPONSE, "The OCSP response contains out-of-date information.")
	cs (SEC_ERROR_DIGEST_NOT_FOUND, "The CMS or PKCS #7 Digest was not found in signed message.")
	cs (SEC_ERROR_UNSUPPORTED_MESSAGE_TYPE, "The CMS or PKCS #7 Message type is unsupported.")
	cs (SEC_ERROR_MODULE_STUCK, "PKCS #11 module could not be removed because it is still in use.")
	cs (SEC_ERROR_BAD_TEMPLATE, "Could not decode ASN.1 data. Specified template was invalid.")
	cs (SEC_ERROR_CRL_NOT_FOUND, "No matching CRL was found.")
	cs (SEC_ERROR_REUSED_ISSUER_AND_SERIAL, "You are attempting to import a cert with the same issuer/serial as an existing cert, but that is not the same cert.")
	cs (SEC_ERROR_BUSY, "NSS could not shutdown. Objects are still in use.")
	cs (SEC_ERROR_EXTRA_INPUT, "DER-encoded message contained extra unused data.")
	cs (SEC_ERROR_UNSUPPORTED_ELLIPTIC_CURVE, "Unsupported elliptic curve.")
	cs (SEC_ERROR_UNSUPPORTED_EC_POINT_FORM, "Unsupported elliptic curve point form.")
	cs (SEC_ERROR_UNRECOGNIZED_OID, "Unrecognized Object Identifier.")
	cs (SEC_ERROR_OCSP_INVALID_SIGNING_CERT, "Invalid OCSP signing certificate in OCSP response.")
	cs (SEC_ERROR_REVOKED_CERTIFICATE_CRL, "Certificate is revoked in issuer's certificate revocation list.")
	cs (SEC_ERROR_REVOKED_CERTIFICATE_OCSP, "Issuer's OCSP responder reports certificate is revoked.")
	cs (SEC_ERROR_CRL_INVALID_VERSION, "Issuer's Certificate Revocation List has an unknown version number.")
	cs (SEC_ERROR_CRL_V1_CRITICAL_EXTENSION, "Issuer's V1 Certificate Revocation List has a critical extension.")
	cs (SEC_ERROR_CRL_UNKNOWN_CRITICAL_EXTENSION, "Issuer's V2 Certificate Revocation List has an unknown critical extension.")
	cs (SEC_ERROR_UNKNOWN_OBJECT_TYPE, "Unknown object type specified.")
	cs (SEC_ERROR_INCOMPATIBLE_PKCS11, "PKCS #11 driver violates the spec in an incompatible way.")
	cs (SEC_ERROR_NO_EVENT, "No new slot event is available at this time.")
	cs (SEC_ERROR_CRL_ALREADY_EXISTS, "CRL already exists.")
	cs (SEC_ERROR_NOT_INITIALIZED, "NSS is not initialized.")
	cs (SEC_ERROR_TOKEN_NOT_LOGGED_IN, "The operation failed because the PKCS#11 token is not logged in.")
	cs (SEC_ERROR_OCSP_RESPONDER_CERT_INVALID, "Configured OCSP responder's certificate is invalid.")
	cs (SEC_ERROR_OCSP_BAD_SIGNATURE, "OCSP response has an invalid signature.")

	#if defined (NSS_VMAJOR) && defined (NSS_VMINOR) && defined (NSS_VPATCH) && (NSS_VMAJOR > 3 || (NSS_VMAJOR == 3 && NSS_VMINOR > 12) || (NSS_VMAJOR == 3 && NSS_VMINOR == 12 && NSS_VPATCH >= 2))
	cs (SEC_ERROR_OUT_OF_SEARCH_LIMITS, "Cert validation search is out of search limits")
	cs (SEC_ERROR_INVALID_POLICY_MAPPING, "Policy mapping contains anypolicy")
	cs (SEC_ERROR_POLICY_VALIDATION_FAILED, "Cert chain fails policy validation")
	cs (SEC_ERROR_UNKNOWN_AIA_LOCATION_TYPE, "Unknown location type in cert AIA extension")
	cs (SEC_ERROR_BAD_HTTP_RESPONSE, "Server returned bad HTTP response")
	cs (SEC_ERROR_BAD_LDAP_RESPONSE, "Server returned bad LDAP response")
	cs (SEC_ERROR_FAILED_TO_ENCODE_DATA, "Failed to encode data with ASN1 encoder")
	cs (SEC_ERROR_BAD_INFO_ACCESS_LOCATION, "Bad information access location in cert extension")
	cs (SEC_ERROR_LIBPKIX_INTERNAL, "Libpkix internal error occurred during cert validation.")
	cs (SEC_ERROR_PKCS11_GENERAL_ERROR, "A PKCS #11 module returned CKR_GENERAL_ERROR, indicating that an unrecoverable error has occurred.")
	cs (SEC_ERROR_PKCS11_FUNCTION_FAILED, "A PKCS #11 module returned CKR_FUNCTION_FAILED, indicating that the requested function could not be performed.  Trying the same operation again might succeed.")
	cs (SEC_ERROR_PKCS11_DEVICE_ERROR, "A PKCS #11 module returned CKR_DEVICE_ERROR, indicating that a problem has occurred with the token or slot.")
	#endif
	}

	#undef cs

	return NULL;
}

static void
set_nss_error (GError **error,
               const gchar *def_error)
{
	glong err_code;

	g_return_if_fail (def_error != NULL);

	err_code = PORT_GetError ();

	if (!err_code) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			"%s", def_error);
	} else {
		const gchar *err_str;

		err_str = nss_error_to_string (err_code);
		if (!err_str)
			err_str = "Uknown error.";

		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			"%s (%d) - %s", err_str, (gint) err_code, def_error);
	}
}

static NSSCMSMessage *
sm_signing_cmsmessage (CamelSMIMEContext *context,
                       const gchar *nick,
                       SECOidTag *hash,
                       gint detached,
                       GError **error)
{
	CamelSMIMEContextPrivate *p = context->priv;
	NSSCMSMessage *cmsg = NULL;
	NSSCMSContentInfo *cinfo;
	NSSCMSSignedData *sigd;
	NSSCMSSignerInfo *signerinfo;
	CERTCertificate *cert= NULL, *ekpcert = NULL;

	g_return_val_if_fail (hash != NULL, NULL);

	if ((cert = CERT_FindUserCertByUsage (p->certdb,
					     (gchar *) nick,
					     certUsageEmailSigner,
					     PR_TRUE,
					     NULL)) == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot find certificate for “%s”"), nick);
		return NULL;
	}

	if (*hash == SEC_OID_UNKNOWN) {
		/* use signature algorithm from the certificate */
		switch (SECOID_GetAlgorithmTag (&cert->signature)) {
		case SEC_OID_PKCS1_SHA256_WITH_RSA_ENCRYPTION:
			*hash = SEC_OID_SHA256;
			break;
		case SEC_OID_PKCS1_SHA384_WITH_RSA_ENCRYPTION:
			*hash = SEC_OID_SHA384;
			break;
		case SEC_OID_PKCS1_SHA512_WITH_RSA_ENCRYPTION:
			*hash = SEC_OID_SHA512;
			break;
		case SEC_OID_PKCS1_MD5_WITH_RSA_ENCRYPTION:
			*hash = SEC_OID_MD5;
			break;
		case SEC_OID_PKCS1_SHA1_WITH_RSA_ENCRYPTION:
		default:
			*hash = SEC_OID_SHA1;
			break;
		}
	}

	cmsg = NSS_CMSMessage_Create (NULL); /* create a message on its own pool */
	if (cmsg == NULL) {
		set_nss_error (error, _("Cannot create CMS message"));
		goto fail;
	}

	if ((sigd = NSS_CMSSignedData_Create (cmsg)) == NULL) {
		set_nss_error (error, _("Cannot create CMS signed data"));
		goto fail;
	}

	cinfo = NSS_CMSMessage_GetContentInfo (cmsg);
	if (NSS_CMSContentInfo_SetContent_SignedData (cmsg, cinfo, sigd) != SECSuccess) {
		set_nss_error (error, _("Cannot attach CMS signed data"));
		goto fail;
	}

	/* if !detatched, the contentinfo will alloc a data item for us */
	cinfo = NSS_CMSSignedData_GetContentInfo (sigd);
	if (NSS_CMSContentInfo_SetContent_Data (cmsg, cinfo, NULL, detached) != SECSuccess) {
		set_nss_error (error, _("Cannot attach CMS data"));
		goto fail;
	}

	signerinfo = NSS_CMSSignerInfo_Create (cmsg, cert, *hash);
	if (signerinfo == NULL) {
		set_nss_error (error, _("Cannot create CMS Signer information"));
		goto fail;
	}

	/* we want the cert chain included for this one */
	if (NSS_CMSSignerInfo_IncludeCerts (signerinfo, NSSCMSCM_CertChain, certUsageEmailSigner) != SECSuccess) {
		set_nss_error (error, _("Cannot find certificate chain"));
		goto fail;
	}

	/* SMIME RFC says signing time should always be added */
	if (NSS_CMSSignerInfo_AddSigningTime (signerinfo, PR_Now ()) != SECSuccess) {
		set_nss_error (error, _("Cannot add CMS Signing time"));
		goto fail;
	}

#if 0
	/* this can but needn't be added.  not sure what general usage is */
	if (NSS_CMSSignerInfo_AddSMIMECaps (signerinfo) != SECSuccess) {
		fprintf (stderr, "ERROR: cannot add SMIMECaps attribute.\n");
		goto loser;
	}
#endif

	/* Check if we need to send along our return encrypt cert, rfc2633 2.5.3 */
	if (p->send_encrypt_key_prefs) {
		CERTCertificate *enccert = NULL;

		if (p->encrypt_key) {
			/* encrypt key has its own nick */
			if ((ekpcert = CERT_FindUserCertByUsage (
				     p->certdb,
				     p->encrypt_key,
				     certUsageEmailRecipient, PR_TRUE, NULL)) == NULL) {
				g_set_error (
					error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
					_("Encryption certificate for “%s” does not exist"),
					p->encrypt_key);
				goto fail;
			}
			enccert = ekpcert;
		} else if (CERT_CheckCertUsage (cert, certUsageEmailRecipient) == SECSuccess) {
			/* encrypt key is signing key */
			enccert = cert;
		} else {
			/* encrypt key uses same nick */
			if ((ekpcert = CERT_FindUserCertByUsage (
				     p->certdb, (gchar *) nick,
				     certUsageEmailRecipient, PR_TRUE, NULL)) == NULL) {
				g_set_error (
					error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
					_("Encryption certificate for “%s” does not exist"), nick);
				goto fail;
			}
			enccert = ekpcert;
		}

		if (NSS_CMSSignerInfo_AddSMIMEEncKeyPrefs (signerinfo, enccert, p->certdb) != SECSuccess) {
			set_nss_error (error, _("Cannot add SMIMEEncKeyPrefs attribute"));
			goto fail;
		}

		if (NSS_CMSSignerInfo_AddMSSMIMEEncKeyPrefs (signerinfo, enccert, p->certdb) != SECSuccess) {
			set_nss_error (error, _("Cannot add MS SMIMEEncKeyPrefs attribute"));
			goto fail;
		}

		if (ekpcert != NULL && NSS_CMSSignedData_AddCertificate (sigd, ekpcert) != SECSuccess) {
			set_nss_error (error, _("Cannot add encryption certificate"));
			goto fail;
		}
	}

	if (NSS_CMSSignedData_AddSignerInfo (sigd, signerinfo) != SECSuccess) {
		set_nss_error (error, _("Cannot add CMS Signer information"));
		goto fail;
	}

	if (ekpcert)
		CERT_DestroyCertificate (ekpcert);

	if (cert)
		CERT_DestroyCertificate (cert);

	return cmsg;
fail:
	if (ekpcert)
		CERT_DestroyCertificate (ekpcert);

	if (cert)
		CERT_DestroyCertificate (cert);

	NSS_CMSMessage_Destroy (cmsg);

	return NULL;
}

static const gchar *
sm_status_description (NSSCMSVerificationStatus status)
{
	/* could use this but then we can't control i18n? */
	/*NSS_CMSUtil_VerificationStatusToString (status));*/

	switch (status) {
	case NSSCMSVS_Unverified:
	default:
		/* Translators: A fallback message when couldn't verify an SMIME signature */
		return _("Unverified");
	case NSSCMSVS_GoodSignature:
		return _("Good signature");
	case NSSCMSVS_BadSignature:
		return _("Bad signature");
	case NSSCMSVS_DigestMismatch:
		return _("Content tampered with or altered in transit");
	case NSSCMSVS_SigningCertNotFound:
		return _("Signing certificate not found");
	case NSSCMSVS_SigningCertNotTrusted:
		return _("Signing certificate not trusted");
	case NSSCMSVS_SignatureAlgorithmUnknown:
		return _("Signature algorithm unknown");
	case NSSCMSVS_SignatureAlgorithmUnsupported:
		return _("Signature algorithm unsupported");
	case NSSCMSVS_MalformedSignature:
		return _("Malformed signature");
	case NSSCMSVS_ProcessingError:
		return _("Processing error");
	}
}

static CamelCipherValidity *
sm_verify_cmsg (CamelCipherContext *context,
                NSSCMSMessage *cmsg,
                CamelStream *extstream,
                GCancellable *cancellable,
                GError **error)
{
	CamelSMIMEContextPrivate *p = ((CamelSMIMEContext *) context)->priv;
	NSSCMSSignedData *sigd = NULL;
#if 0
	NSSCMSEnvelopedData *envd;
	NSSCMSEncryptedData *encd;
#endif
	SECAlgorithmID **digestalgs;
	NSSCMSDigestContext *digcx;
	gint count, i, nsigners, j;
	SECItem **digests;
	PLArenaPool *poolp = NULL;
	CamelStream *mem;
	NSSCMSVerificationStatus status;
	CamelCipherValidity *valid;
	GString *description;

	description = g_string_new ("");
	valid = camel_cipher_validity_new ();
	camel_cipher_validity_set_valid (valid, TRUE);
	status = NSSCMSVS_Unverified;

	/* NB: this probably needs to go into a decoding routine that can be used for processing
	 * enveloped data too */
	count = NSS_CMSMessage_ContentLevelCount (cmsg);
	for (i = 0; i < count; i++) {
		NSSCMSContentInfo *cinfo = NSS_CMSMessage_ContentLevel (cmsg, i);
		SECOidTag typetag = NSS_CMSContentInfo_GetContentTypeTag (cinfo);
		GByteArray *buffer;
		gint which_digest;

		switch (typetag) {
		case SEC_OID_PKCS7_SIGNED_DATA:
			sigd = (NSSCMSSignedData *) NSS_CMSContentInfo_GetContent (cinfo);
			if (sigd == NULL) {
				set_nss_error (error, _("No signed data in signature"));
				goto fail;
			}

			if (extstream == NULL) {
				set_nss_error (error, _("Digests missing from enveloped data"));
				goto fail;
			}

			if ((poolp = PORT_NewArena (1024)) == NULL) {
				set_nss_error (error, g_strerror (ENOMEM));
				goto fail;
			}

			digestalgs = NSS_CMSSignedData_GetDigestAlgs (sigd);

			digcx = NSS_CMSDigestContext_StartMultiple (digestalgs);
			if (digcx == NULL) {
				set_nss_error (error, _("Cannot calculate digests"));
				goto fail;
			}

			buffer = g_byte_array_new ();
			mem = camel_stream_mem_new_with_byte_array (buffer);
			camel_stream_write_to_stream (extstream, mem, cancellable, NULL);
			NSS_CMSDigestContext_Update (digcx, buffer->data, buffer->len);
			g_object_unref (mem);

			if (NSS_CMSDigestContext_FinishMultiple (digcx, poolp, &digests) != SECSuccess) {
				set_nss_error (error, _("Cannot calculate digests"));
				goto fail;
			}

			for (which_digest = 0; digests[which_digest] != NULL; which_digest++) {
				SECOidData *digest_alg = SECOID_FindOID (&digestalgs[which_digest]->algorithm);
				if (digest_alg == NULL) {
					set_nss_error (error, _("Cannot set message digests"));
					goto fail;
				}
				if (NSS_CMSSignedData_SetDigestValue (sigd, digest_alg->offset, digests[which_digest]) != SECSuccess) {
					set_nss_error (error, _("Cannot set message digests"));
					goto fail;
				}
			}

			PORT_FreeArena (poolp, PR_FALSE);
			poolp = NULL;

			/* import all certificates present */
			if (NSS_CMSSignedData_ImportCerts (sigd, p->certdb, certUsageEmailSigner, PR_TRUE) != SECSuccess) {
				set_nss_error (error, _("Certificate import failed"));
				goto fail;
			}

			if (NSS_CMSSignedData_ImportCerts (sigd, p->certdb, certUsageEmailRecipient, PR_TRUE) != SECSuccess) {
				set_nss_error (error, _("Certificate import failed"));
				goto fail;
			}

			/* check for certs-only message */
			nsigners = NSS_CMSSignedData_SignerInfoCount (sigd);
			if (nsigners == 0) {

				/* already imported certs above, not sure what usage we should use here or if this isn't handled above */
				if (NSS_CMSSignedData_VerifyCertsOnly (sigd, p->certdb, certUsageEmailSigner) != SECSuccess) {
					g_string_printf (description, _("Certificate is the only message, cannot verify certificates"));
				} else {
					status = NSSCMSVS_GoodSignature;
					g_string_printf (description, _("Certificate is the only message, certificates imported and verified"));
				}
			} else {
				if (!NSS_CMSSignedData_HasDigests (sigd)) {
					set_nss_error (error, _("Cannot find signature digests"));
					goto fail;
				}

				for (j = 0; j < nsigners; j++) {
					CERTCertificate *cert;
					NSSCMSSignerInfo *si;
					gchar *cn, *em;
					gint idx;

					si = NSS_CMSSignedData_GetSignerInfo (sigd, j);
					NSS_CMSSignedData_VerifySignerInfo (sigd, j, p->certdb, certUsageEmailSigner);

					status = NSS_CMSSignerInfo_GetVerificationStatus (si);

					cn = NSS_CMSSignerInfo_GetSignerCommonName (si);
					em = NSS_CMSSignerInfo_GetSignerEmailAddress (si);

					g_string_append_printf (
						description, _("Signer: %s <%s>: %s\n"),
						cn ? cn:"<unknown>", em ? em:"<unknown>",
						sm_status_description (status));

					cert = NSS_CMSSignerInfo_GetSigningCertificate (si, p->certdb);

					idx = camel_cipher_validity_add_certinfo_ex (
						valid, CAMEL_CIPHER_VALIDITY_SIGN, cn, em,
						cert ? smime_cert_data_clone (cert) : NULL,
						cert ? smime_cert_data_free : NULL, cert ? smime_cert_data_clone : NULL);

					if (cert && idx >= 0) {
						CamelInternetAddress *addrs = NULL;
						const gchar *cert_email;

						for (cert_email = CERT_GetFirstEmailAddress (cert);
						     cert_email;
						     cert_email = CERT_GetNextEmailAddress (cert, cert_email)) {
							if (!*cert_email)
								continue;

							if (!addrs)
								addrs = camel_internet_address_new ();

							camel_internet_address_add (addrs, NULL, cert_email);
						}

						if (addrs) {
							gchar *addresses = camel_address_format (CAMEL_ADDRESS (addrs));

							camel_cipher_validity_set_certinfo_property (valid, CAMEL_CIPHER_VALIDITY_SIGN, idx,
								CAMEL_CIPHER_CERT_INFO_PROPERTY_SIGNERS_ALT_EMAILS, addresses,
								g_free, (CamelCipherCloneFunc) g_strdup);

							g_object_unref (addrs);
						}
					}

					if (cn)
						PORT_Free (cn);
					if (em)
						PORT_Free (em);

					if (status != NSSCMSVS_GoodSignature)
						camel_cipher_validity_set_valid (valid, FALSE);
				}
			}
			break;
		case SEC_OID_PKCS7_ENVELOPED_DATA:
			/* FIXME Do something with this? */
			/*envd = (NSSCMSEnvelopedData *)NSS_CMSContentInfo_GetContent (cinfo);*/
			break;
		case SEC_OID_PKCS7_ENCRYPTED_DATA:
			/* FIXME Do something with this? */
			/*encd = (NSSCMSEncryptedData *)NSS_CMSContentInfo_GetContent (cinfo);*/
			break;
		case SEC_OID_PKCS7_DATA:
			break;
		default:
			break;
		}
	}

	camel_cipher_validity_set_valid (valid, camel_cipher_validity_get_valid (valid) && status == NSSCMSVS_GoodSignature);
	camel_cipher_validity_set_description (valid, description->str);
	g_string_free (description, TRUE);

	return valid;

fail:
	camel_cipher_validity_free (valid);
	g_string_free (description, TRUE);

	return NULL;
}

static const gchar *
smime_context_hash_to_id (CamelCipherContext *context,
                          CamelCipherHash hash)
{
	switch (hash) {
		/* Support registered IANA hash function textual names.
		 * http://www.iana.org/assignments/hash-function-text-names */
		case CAMEL_CIPHER_HASH_MD5:
			return "md5";
		case CAMEL_CIPHER_HASH_SHA1:
		case CAMEL_CIPHER_HASH_DEFAULT:
			return "sha-1";
		case CAMEL_CIPHER_HASH_SHA256:
			return "sha-256";
		case CAMEL_CIPHER_HASH_SHA384:
			return "sha-384";
		case CAMEL_CIPHER_HASH_SHA512:
			return "sha-512";
		default:
			return NULL;
	}
}

static CamelCipherHash
smime_context_id_to_hash (CamelCipherContext *context,
                          const gchar *id)
{
	if (id != NULL) {
		/* Support registered IANA hash function textual names.
		 * http://www.iana.org/assignments/hash-function-text-names */
		if (g_str_equal (id, "md5"))
			return CAMEL_CIPHER_HASH_MD5;
		if (g_str_equal (id, "sha-1"))
			return CAMEL_CIPHER_HASH_SHA1;
		if (g_str_equal (id, "sha-256"))
			return CAMEL_CIPHER_HASH_SHA256;
		if (g_str_equal (id, "sha-384"))
			return CAMEL_CIPHER_HASH_SHA384;
		if (g_str_equal (id, "sha-512"))
			return CAMEL_CIPHER_HASH_SHA512;

		/* Non-standard names. */
		if (g_str_equal (id, "sha1"))
			return CAMEL_CIPHER_HASH_SHA1;
		if (g_str_equal (id, "sha256"))
			return CAMEL_CIPHER_HASH_SHA256;
		if (g_str_equal (id, "sha384"))
			return CAMEL_CIPHER_HASH_SHA384;
		if (g_str_equal (id, "sha512"))
			return CAMEL_CIPHER_HASH_SHA512;
	}

	return CAMEL_CIPHER_HASH_DEFAULT;
}

static CamelCipherHash
get_hash_from_oid (SECOidTag oidTag)
{
	switch (oidTag) {
	case SEC_OID_SHA1:
		return CAMEL_CIPHER_HASH_SHA1;
	case SEC_OID_SHA256:
		return CAMEL_CIPHER_HASH_SHA256;
	case SEC_OID_SHA384:
		return CAMEL_CIPHER_HASH_SHA384;
	case SEC_OID_SHA512:
		return CAMEL_CIPHER_HASH_SHA512;
	case SEC_OID_MD5:
		return CAMEL_CIPHER_HASH_MD5;
	default:
		break;
	}

	return CAMEL_CIPHER_HASH_DEFAULT;
}

static gboolean
smime_context_sign_sync (CamelCipherContext *context,
                         const gchar *userid,
                         CamelCipherHash hash,
                         CamelMimePart *ipart,
                         CamelMimePart *opart,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelCipherContextClass *class;
	NSSCMSMessage *cmsg;
	CamelStream *ostream, *istream;
	GByteArray *buffer;
	SECOidTag sechash;
	NSSCMSEncoderContext *enc;
	CamelDataWrapper *dw;
	CamelContentType *ct;
	gboolean success = FALSE;

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	switch (hash) {
	case CAMEL_CIPHER_HASH_DEFAULT:
	default:
		sechash = SEC_OID_UNKNOWN;
		break;
	case CAMEL_CIPHER_HASH_SHA1:
		sechash = SEC_OID_SHA1;
		break;
	case CAMEL_CIPHER_HASH_SHA256:
		sechash = SEC_OID_SHA256;
		break;
	case CAMEL_CIPHER_HASH_SHA384:
		sechash = SEC_OID_SHA384;
		break;
	case CAMEL_CIPHER_HASH_SHA512:
		sechash = SEC_OID_SHA512;
		break;
	case CAMEL_CIPHER_HASH_MD5:
		sechash = SEC_OID_MD5;
		break;
	}

	cmsg = sm_signing_cmsmessage (
		(CamelSMIMEContext *) context, userid, &sechash,
		((CamelSMIMEContext *) context)->priv->sign_mode == CAMEL_SMIME_SIGN_CLEARSIGN, error);
	if (cmsg == NULL)
		return FALSE;

	ostream = camel_stream_mem_new ();

	/* FIXME: stream this, we stream output at least */
	buffer = g_byte_array_new ();
	istream = camel_stream_mem_new_with_byte_array (buffer);

	if (camel_cipher_canonical_to_stream (
		ipart, CAMEL_MIME_FILTER_CANON_STRIP |
		CAMEL_MIME_FILTER_CANON_CRLF |
		CAMEL_MIME_FILTER_CANON_FROM,
		istream, cancellable, error) == -1) {
		g_prefix_error (
			error, _("Could not generate signing data: "));
		goto fail;
	}

	enc = NSS_CMSEncoder_Start (
		cmsg,
		sm_write_stream, ostream, /* DER output callback  */
		NULL, NULL,     /* destination storage  */
		NULL, NULL,	   /* password callback    */
		NULL, NULL,     /* decrypt key callback */
		NULL, NULL );   /* detached digests    */
	if (!enc) {
		set_nss_error (error, _("Cannot create encoder context"));
		goto fail;
	}

	if (NSS_CMSEncoder_Update (enc, (gchar *) buffer->data, buffer->len) != SECSuccess) {
		NSS_CMSEncoder_Cancel (enc);
		set_nss_error (error, _("Failed to add data to CMS encoder"));
		goto fail;
	}

	if (NSS_CMSEncoder_Finish (enc) != SECSuccess) {
		set_nss_error (error, _("Failed to encode data"));
		goto fail;
	}

	success = TRUE;

	dw = camel_data_wrapper_new ();
	g_seekable_seek (G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);
	camel_data_wrapper_construct_from_stream_sync (
		dw, ostream, cancellable, NULL);
	camel_data_wrapper_set_encoding (dw, CAMEL_TRANSFER_ENCODING_BINARY);

	if (((CamelSMIMEContext *) context)->priv->sign_mode == CAMEL_SMIME_SIGN_CLEARSIGN) {
		CamelMultipartSigned *mps;
		CamelMimePart *sigpart;

		sigpart = camel_mime_part_new ();
		ct = camel_content_type_new ("application", "x-pkcs7-signature");
		camel_content_type_set_param (ct, "name", "smime.p7s");
		camel_data_wrapper_set_mime_type_field (dw, ct);
		camel_content_type_unref (ct);

		camel_medium_set_content ((CamelMedium *) sigpart, dw);

		camel_mime_part_set_filename (sigpart, "smime.p7s");
		camel_mime_part_set_disposition (sigpart, "attachment");
		camel_mime_part_set_encoding (sigpart, CAMEL_TRANSFER_ENCODING_BASE64);

		mps = camel_multipart_signed_new ();
		ct = camel_content_type_new ("multipart", "signed");
		camel_content_type_set_param (ct, "micalg", camel_cipher_context_hash_to_id (context, get_hash_from_oid (sechash)));
		camel_content_type_set_param (ct, "protocol", class->sign_protocol);
		camel_data_wrapper_set_mime_type_field ((CamelDataWrapper *) mps, ct);
		camel_content_type_unref (ct);
		camel_multipart_set_boundary ((CamelMultipart *) mps, NULL);

		camel_multipart_signed_set_signature (mps, sigpart);
		camel_multipart_signed_set_content_stream (mps, istream);

		g_object_unref (sigpart);

		g_seekable_seek (
			G_SEEKABLE (istream), 0,
			G_SEEK_SET, NULL, NULL);

		camel_medium_set_content ((CamelMedium *) opart, (CamelDataWrapper *) mps);
	} else {
		ct = camel_content_type_new ("application", "x-pkcs7-mime");
		camel_content_type_set_param (ct, "name", "smime.p7m");
		camel_content_type_set_param (ct, "smime-type", "signed-data");
		camel_data_wrapper_set_mime_type_field (dw, ct);
		camel_content_type_unref (ct);

		camel_medium_set_content ((CamelMedium *) opart, dw);

		camel_mime_part_set_filename (opart, "smime.p7m");
		camel_mime_part_set_description (opart, "S/MIME Signed Message");
		camel_mime_part_set_disposition (opart, "attachment");
		camel_mime_part_set_encoding (opart, CAMEL_TRANSFER_ENCODING_BASE64);
	}

	g_object_unref (dw);
fail:
	g_object_unref (ostream);
	g_object_unref (istream);

	return success;
}

static CamelCipherValidity *
smime_context_verify_sync (CamelCipherContext *context,
                           CamelMimePart *ipart,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelCipherContextClass *class;
	NSSCMSDecoderContext *dec;
	NSSCMSMessage *cmsg;
	CamelStream *mem;
	CamelStream *constream = NULL;
	CamelCipherValidity *valid = NULL;
	CamelContentType *ct;
	const gchar *tmp;
	CamelMimePart *sigpart;
	CamelDataWrapper *dw;
	GByteArray *buffer;

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	dw = camel_medium_get_content ((CamelMedium *) ipart);
	ct = camel_data_wrapper_get_mime_type_field (dw);

	/* FIXME: we should stream this to the decoder */
	buffer = g_byte_array_new ();
	mem = camel_stream_mem_new_with_byte_array (buffer);

	if (camel_content_type_is (ct, "multipart", "signed")) {
		CamelMultipart *mps = (CamelMultipart *) dw;

		tmp = camel_content_type_param (ct, "protocol");
		if (!CAMEL_IS_MULTIPART_SIGNED (mps)
		    || tmp == NULL
		    || (g_ascii_strcasecmp (tmp, class->sign_protocol) != 0
			&& g_ascii_strcasecmp (tmp, "application/pkcs7-signature") != 0)) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot verify message signature: "
				"Incorrect message format"));
			goto fail;
		}

		constream = camel_multipart_signed_get_content_stream (
			(CamelMultipartSigned *) mps, error);
		if (constream == NULL)
			goto fail;

		sigpart = camel_multipart_get_part (mps, CAMEL_MULTIPART_SIGNED_SIGNATURE);
		if (sigpart == NULL) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot verify message signature: "
				"Incorrect message format"));
			goto fail;
		}
	} else if (camel_content_type_is (ct, "application", "x-pkcs7-mime")) {
		sigpart = ipart;
	} else {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot verify message signature: "
			"Incorrect message format"));
		goto fail;
	}

	dec = NSS_CMSDecoder_Start (
		NULL,
		NULL, NULL, /* content callback     */
		NULL, NULL,	/* password callback    */
		NULL, NULL); /* decrypt key callback */

	camel_data_wrapper_decode_to_stream_sync (
		camel_medium_get_content (
			CAMEL_MEDIUM (sigpart)), mem, cancellable, NULL);
	if (NSS_CMSDecoder_Update (dec, (gchar *) buffer->data, buffer->len) != SECSuccess) {
		g_warning ("%s: Failed to call NSS_CMSDecoder_Update", G_STRFUNC);
	}
	cmsg = NSS_CMSDecoder_Finish (dec);
	if (cmsg == NULL) {
		set_nss_error (error, _("Decoder failed"));
		goto fail;
	}

	valid = sm_verify_cmsg (context, cmsg, constream, cancellable, error);

	NSS_CMSMessage_Destroy (cmsg);
fail:
	g_object_unref (mem);
	if (constream)
		g_object_unref (constream);

	return valid;
}

static gboolean
camel_smime_first_certificate_is_better (CERTCertificate *cert1,
					 CERTCertificate *cert2,
					 PRTime now)
{
	PRTime notBefore1, notAfter1, notBefore2, notAfter2;
	CERTCertTrust trust;
	gboolean cert1_trusted, cert2_trusted;

	if (!cert1)
		return FALSE;

	if (!cert2)
		return cert1 != NULL;

	/* Both certificates are valid at the time, it's ensured with CERT_CheckCertValidTimes()
	   in camel_smime_find_recipients_certs() */

	if (SECSuccess == CERT_GetCertTrust (cert1, &trust))
		cert1_trusted = (trust.emailFlags & CERTDB_TRUSTED) != 0;
	else
		cert1_trusted = FALSE;

	if (SECSuccess == CERT_GetCertTrust (cert2, &trust))
		cert2_trusted = (trust.emailFlags & CERTDB_TRUSTED) != 0;
	else
		cert2_trusted = FALSE;

	if (cert1_trusted && !cert2_trusted)
		return TRUE;

	if (!cert1_trusted && cert2_trusted)
		return FALSE;

	/* Both are trusted or untrusted, then get the newer */
	if (CERT_GetCertTimes (cert1, &notBefore1, &notAfter1) != SECSuccess)
		return FALSE;

	if (CERT_GetCertTimes (cert2, &notBefore2, &notAfter2) != SECSuccess)
		return TRUE;

	/* cert1 is valid after cert2, thus it is newer */
	return notBefore1 > notBefore2;
}

typedef struct FindRecipientsData {
	GHashTable *recipients_table;
	guint certs_missing;
	PRTime now;
} FindRecipientsData;

static SECStatus
camel_smime_find_recipients_certs (CERTCertificate *cert,
				   SECItem *item,
				   gpointer user_data)
{
	FindRecipientsData *frd = user_data;
	const gchar *cert_email = NULL;
	CERTCertificate **hash_value = NULL;

	/* Cannot short-circuit when frd->certs_missing is 0, because there can be better certificates */
	if (!frd->recipients_table ||
	    CERT_CheckCertValidTimes (cert, frd->now, PR_FALSE) != secCertTimeValid) {
		return SECFailure;
	}

	/* Loop over all cert's email addresses */
	for (cert_email = CERT_GetFirstEmailAddress (cert);
	     cert_email;
	     cert_email = CERT_GetNextEmailAddress (cert, cert_email)) {
		hash_value = g_hash_table_lookup (frd->recipients_table, cert_email);

		if (hash_value && !*hash_value) {
			/* Cannot break now, because there can be multiple addresses for this certificate */
			*hash_value = CERT_DupCertificate (cert);
			frd->certs_missing--;
		} else if (hash_value && !camel_smime_first_certificate_is_better (*hash_value, cert, frd->now)) {
			CERT_DestroyCertificate (*hash_value);
			*hash_value = CERT_DupCertificate (cert);
		}
	}

	/* Is the sender referenced by nickname rather than its email address? */
	if (cert->nickname) {
		hash_value = g_hash_table_lookup (frd->recipients_table, cert->nickname);

		if (hash_value && !*hash_value) {
			*hash_value = CERT_DupCertificate (cert);
			frd->certs_missing--;
		} else if (hash_value && !camel_smime_first_certificate_is_better (*hash_value, cert, frd->now)) {
			CERT_DestroyCertificate (*hash_value);
			*hash_value = CERT_DupCertificate (cert);
		}
	}

	return SECFailure;
}

static guint
camel_smime_cert_hash (gconstpointer ptr)
{
	const CERTCertificate *cert = ptr;
	guint hashval = 0, ii;

	if (!cert)
		return 0;

	if (cert->serialNumber.len && cert->serialNumber.data) {
		for (ii = 0; ii < cert->serialNumber.len; ii += 4) {
			guint num = cert->serialNumber.data[ii];

			if (ii + 1 < cert->serialNumber.len)
				num = num | (cert->serialNumber.data[ii + 1] << 8);
			if (ii + 2 < cert->serialNumber.len)
				num = num | (cert->serialNumber.data[ii + 2] << 16);
			if (ii + 3 < cert->serialNumber.len)
				num = num | (cert->serialNumber.data[ii + 3] << 24);

			hashval = hashval ^ num;
		}
	}

	return hashval;
}

static gboolean
camel_smime_cert_equal (gconstpointer ptr1,
			gconstpointer ptr2)
{
	const CERTCertificate *cert1 = ptr1, *cert2 = ptr2;

	if (!cert1 || !cert2)
		return cert1 == cert2;

	if (cert1 == cert2)
		return TRUE;

	if (cert1->derCert.len != cert2->derCert.len ||
	    !cert1->derCert.data || !cert2->derCert.data) {
		return FALSE;
	}

	return memcmp (cert1->derCert.data, cert2->derCert.data, cert1->derCert.len) == 0;
}

static gboolean
smime_context_encrypt_sync (CamelCipherContext *context,
                            const gchar *userid,
                            GPtrArray *recipients,
                            CamelMimePart *ipart,
                            CamelMimePart *opart,
                            GCancellable *cancellable,
                            GError **error)
{
	/*NSSCMSRecipientInfo **recipient_infos;*/
	CERTCertificate **recipient_certs = NULL;
	FindRecipientsData frd;
	NSSCMSContentInfo *cinfo;
	PK11SymKey *bulkkey = NULL;
	SECOidTag bulkalgtag;
	gint bulkkeysize, i;
	CK_MECHANISM_TYPE type;
	PK11SlotInfo *slot;
	PLArenaPool *poolp;
	NSSCMSMessage *cmsg = NULL;
	NSSCMSEnvelopedData *envd;
	NSSCMSEncoderContext *enc = NULL;
	CamelStream *mem;
	CamelStream *ostream = NULL;
	CamelDataWrapper *dw;
	CamelContentType *ct;
	GByteArray *buffer;
	GSList *gathered_certificates = NULL, *link;

	if (!camel_session_get_recipient_certificates_sync (camel_cipher_context_get_session (context),
		CAMEL_RECIPIENT_CERTIFICATE_SMIME, recipients, &gathered_certificates, cancellable, error))
		return FALSE;

	poolp = PORT_NewArena (1024);
	if (poolp == NULL) {
		set_nss_error (error, g_strerror (ENOMEM));
		g_slist_free_full (gathered_certificates, g_free);
		return FALSE;
	}

	/* Lookup all recipients certs, for later working */
	recipient_certs = (CERTCertificate **) PORT_ArenaZAlloc (poolp, sizeof (recipient_certs[0]) * (recipients->len + 1));
	if (recipient_certs == NULL) {
		set_nss_error (error, g_strerror (ENOMEM));
		g_slist_free_full (gathered_certificates, g_free);
		goto fail;
	}

	frd.recipients_table = g_hash_table_new (camel_strcase_hash, camel_strcase_equal);
	for (i = 0; i < recipients->len; i++) {
		g_hash_table_insert (
				frd.recipients_table,
				recipients->pdata[i],
				&recipient_certs[i]);
	}
	frd.certs_missing = g_hash_table_size (frd.recipients_table);
	frd.now = PR_Now();

	for (link = gathered_certificates; link; link = g_slist_next (link)) {
		const gchar *certstr = link->data;

		if (certstr && *certstr) {
			CERTCertificate *cert = NULL;
			gsize len = 0;
			guchar *data;

			data = g_base64_decode (certstr, &len);

			if (data && len)
				cert = CERT_DecodeCertFromPackage ((gchar *) data, len);

			g_free (data);

			if (cert) {
				camel_smime_find_recipients_certs (cert, NULL, &frd);
				CERT_DestroyCertificate (cert);
			}
		}
	}

	g_slist_free_full (gathered_certificates, g_free);

	/* Just ignore the return value */
	(void) PK11_TraverseSlotCerts (camel_smime_find_recipients_certs, &frd, NULL);

	if (frd.certs_missing) {
		i = 0;
		while (i < recipients->len) {
			CERTCertificate **hash_value = g_hash_table_lookup (frd.recipients_table, recipients->pdata[i]);
			if (!hash_value || !*hash_value) {
				g_set_error (
					error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
					_("No valid or appropriate certificate for “%s” was found"),
					(gchar *) recipients->pdata[i]);
				g_hash_table_destroy (frd.recipients_table);
				goto fail;
			}
			i++;
		}
	} else {
		/* Addresses and certificates can be duplicated, thus update the recipient_certs array */
		GHashTable *final_certs;
		GHashTableIter iter;
		gpointer key;

		final_certs = g_hash_table_new_full (camel_smime_cert_hash, camel_smime_cert_equal,
			(GDestroyNotify) CERT_DestroyCertificate, NULL);

		for (i = 0; i < recipients->len; i++) {
			if (recipient_certs[i]) {
				/* Passes ownership to final_certs */
				g_hash_table_insert (final_certs, recipient_certs[i], NULL);
				recipient_certs[i] = NULL;
			}
		}

		i = 0;
		g_hash_table_iter_init (&iter, final_certs);
		while (g_hash_table_iter_next (&iter, &key, NULL)) {
			CERTCertificate *cert = key;

			recipient_certs[i] = CERT_DupCertificate (cert);
			i++;
		}

		g_hash_table_destroy (final_certs);
	}

	g_hash_table_destroy (frd.recipients_table);

	/* Find a common algorithm, probably 3DES anyway ... */
	if (NSS_SMIMEUtil_FindBulkAlgForRecipients (recipient_certs, &bulkalgtag, &bulkkeysize) != SECSuccess) {
		set_nss_error (error, _("Cannot find common bulk encryption algorithm"));
		goto fail;
	}

	/* Generate a new bulk key based on the common algorithm - expensive */
	type = PK11_AlgtagToMechanism (bulkalgtag);
	slot = PK11_GetBestSlot (type, context);
	if (slot == NULL) {
		set_nss_error (error, _("Cannot allocate slot for encryption bulk key"));
		goto fail;
	}

	bulkkey = PK11_KeyGen (slot, type, NULL, bulkkeysize / 8, context);
	PK11_FreeSlot (slot);

	/* Now we can start building the message */
	/* msg->envelopedData->data */
	cmsg = NSS_CMSMessage_Create (NULL);
	if (cmsg == NULL) {
		set_nss_error (error, _("Cannot create CMS Message"));
		goto fail;
	}

	envd = NSS_CMSEnvelopedData_Create (cmsg, bulkalgtag, bulkkeysize);
	if (envd == NULL) {
		set_nss_error (error, _("Cannot create CMS Enveloped data"));
		goto fail;
	}

	cinfo = NSS_CMSMessage_GetContentInfo (cmsg);
	if (NSS_CMSContentInfo_SetContent_EnvelopedData (cmsg, cinfo, envd) != SECSuccess) {
		set_nss_error (error, _("Cannot attach CMS Enveloped data"));
		goto fail;
	}

	cinfo = NSS_CMSEnvelopedData_GetContentInfo (envd);
	if (NSS_CMSContentInfo_SetContent_Data (cmsg, cinfo, NULL, PR_FALSE) != SECSuccess) {
		set_nss_error (error, _("Cannot attach CMS data object"));
		goto fail;
	}

	/* add recipient certs */
	for (i = 0; recipient_certs[i]; i++) {
		NSSCMSRecipientInfo *ri = NSS_CMSRecipientInfo_Create (cmsg, recipient_certs[i]);

		if (ri == NULL) {
			set_nss_error (error, _("Cannot create CMS Recipient information"));
			goto fail;
		}

		if (NSS_CMSEnvelopedData_AddRecipient (envd, ri) != SECSuccess) {
			set_nss_error (error, _("Cannot add CMS Recipient information"));
			goto fail;
		}
	}

	/* dump it out */
	ostream = camel_stream_mem_new ();
	enc = NSS_CMSEncoder_Start (
		cmsg,
		sm_write_stream, ostream,
		NULL, NULL,
		NULL, NULL,
		sm_decrypt_key, bulkkey,
		NULL, NULL);
	if (enc == NULL) {
		set_nss_error (error, _("Cannot create encoder context"));
		goto fail;
	}

	/* FIXME: Stream the input */
	buffer = g_byte_array_new ();
	mem = camel_stream_mem_new_with_byte_array (buffer);
	camel_cipher_canonical_to_stream (ipart, CAMEL_MIME_FILTER_CANON_CRLF, mem, NULL, NULL);
	if (NSS_CMSEncoder_Update (enc, (gchar *) buffer->data, buffer->len) != SECSuccess) {
		NSS_CMSEncoder_Cancel (enc);
		g_object_unref (mem);
		set_nss_error (error, _("Failed to add data to encoder"));
		goto fail;
	}
	g_object_unref (mem);

	if (NSS_CMSEncoder_Finish (enc) != SECSuccess) {
		set_nss_error (error, _("Failed to encode data"));
		goto fail;
	}

	PK11_FreeSymKey (bulkkey);
	NSS_CMSMessage_Destroy (cmsg);
	for (i = 0; i < recipients->len; i++) {
		if (recipient_certs[i])
			CERT_DestroyCertificate (recipient_certs[i]);
	}
	PORT_FreeArena (poolp, PR_FALSE);

	dw = camel_data_wrapper_new ();
	camel_data_wrapper_construct_from_stream_sync (
		dw, ostream, NULL, NULL);
	g_object_unref (ostream);
	camel_data_wrapper_set_encoding (dw, CAMEL_TRANSFER_ENCODING_BINARY);

	ct = camel_content_type_new ("application", "x-pkcs7-mime");
	camel_content_type_set_param (ct, "name", "smime.p7m");
	camel_content_type_set_param (ct, "smime-type", "enveloped-data");
	camel_data_wrapper_set_mime_type_field (dw, ct);
	camel_content_type_unref (ct);

	camel_medium_set_content ((CamelMedium *) opart, dw);
	g_object_unref (dw);

	camel_mime_part_set_disposition (opart, "attachment");
	camel_mime_part_set_filename (opart, "smime.p7m");
	camel_mime_part_set_description (opart, "S/MIME Encrypted Message");
	camel_mime_part_set_encoding (opart, CAMEL_TRANSFER_ENCODING_BASE64);

	return TRUE;

fail:
	if (ostream)
		g_object_unref (ostream);
	if (cmsg)
		NSS_CMSMessage_Destroy (cmsg);
	if (bulkkey)
		PK11_FreeSymKey (bulkkey);

	if (recipient_certs) {
		for (i = 0; i < recipients->len; i++) {
			if (recipient_certs[i])
				CERT_DestroyCertificate (recipient_certs[i]);
		}
	}

	PORT_FreeArena (poolp, PR_FALSE);

	return FALSE;
}

static CamelCipherValidity *
smime_context_decrypt_sync (CamelCipherContext *context,
                            CamelMimePart *ipart,
                            CamelMimePart *opart,
                            GCancellable *cancellable,
                            GError **error)
{
	NSSCMSDecoderContext *dec;
	NSSCMSMessage *cmsg;
	CamelStream *istream;
	CamelStream *ostream;
	CamelCipherValidity *valid = NULL;
	GByteArray *buffer;

	/* FIXME: This assumes the content is only encrypted.  Perhaps its ok for
	 * this api to do this ... */

	ostream = camel_stream_mem_new ();
	camel_stream_mem_set_secure (CAMEL_STREAM_MEM (ostream));

	/* FIXME: stream this to the decoder incrementally */
	buffer = g_byte_array_new ();
	istream = camel_stream_mem_new_with_byte_array (buffer);
	if (!camel_data_wrapper_decode_to_stream_sync (
		camel_medium_get_content (CAMEL_MEDIUM (ipart)),
		istream, cancellable, error)) {
		g_object_unref (istream);
		goto fail;
	}

	g_seekable_seek (G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);

	dec = NSS_CMSDecoder_Start (
		NULL,
		sm_write_stream, ostream, /* content callback     */
		NULL, NULL,
		NULL, NULL); /* decrypt key callback */

	if (NSS_CMSDecoder_Update (dec, (gchar *) buffer->data, buffer->len) != SECSuccess) {
		cmsg = NULL;
	} else {
		cmsg = NSS_CMSDecoder_Finish (dec);
	}

	g_object_unref (istream);

	if (cmsg == NULL) {
		set_nss_error (error, _("Decoder failed"));
		goto fail;
	}

#if 0
	/* not sure if we really care about this? */
	if (!NSS_CMSMessage_IsEncrypted (cmsg)) {
		set_nss_error (ex, _("S/MIME Decrypt: No encrypted content found"));
		NSS_CMSMessage_Destroy (cmsg);
		goto fail;
	}
#endif

	g_seekable_seek (G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);

	camel_data_wrapper_construct_from_stream_sync (
		CAMEL_DATA_WRAPPER (opart), ostream, NULL, NULL);

	if (NSS_CMSMessage_IsSigned (cmsg)) {
		g_seekable_seek (
			G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);
		valid = sm_verify_cmsg (
			context, cmsg, ostream, cancellable, error);
	} else {
		valid = camel_cipher_validity_new ();
		valid->encrypt.description = g_strdup (_("Encrypted content"));
		valid->encrypt.status = CAMEL_CIPHER_VALIDITY_ENCRYPT_ENCRYPTED;
	}

	NSS_CMSMessage_Destroy (cmsg);
fail:
	g_object_unref (ostream);

	return valid;
}

static void
camel_smime_context_finalize (GObject *object)
{
	CamelSMIMEContext *smime = CAMEL_SMIME_CONTEXT (object);

	g_free (smime->priv->encrypt_key);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_smime_context_parent_class)->finalize (object);
}

static void
camel_smime_context_class_init (CamelSMIMEContextClass *class)
{
	CamelCipherContextClass *cipher_context_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSMIMEContextPrivate));

	cipher_context_class = CAMEL_CIPHER_CONTEXT_CLASS (class);
	cipher_context_class->sign_protocol = "application/x-pkcs7-signature";
	cipher_context_class->encrypt_protocol = "application/x-pkcs7-mime";
	cipher_context_class->key_protocol = "application/x-pkcs7-signature";
	cipher_context_class->hash_to_id = smime_context_hash_to_id;
	cipher_context_class->id_to_hash = smime_context_id_to_hash;
	cipher_context_class->sign_sync = smime_context_sign_sync;
	cipher_context_class->verify_sync = smime_context_verify_sync;
	cipher_context_class->encrypt_sync = smime_context_encrypt_sync;
	cipher_context_class->decrypt_sync = smime_context_decrypt_sync;

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = camel_smime_context_finalize;
}

static void
camel_smime_context_init (CamelSMIMEContext *smime_context)
{
	smime_context->priv = CAMEL_SMIME_CONTEXT_GET_PRIVATE (smime_context);
	smime_context->priv->certdb = CERT_GetDefaultCertDB ();
	smime_context->priv->sign_mode = CAMEL_SMIME_SIGN_CLEARSIGN;
	smime_context->priv->password_tries = 0;
}

/**
 * camel_smime_context_new:
 * @session: session
 *
 * Creates a new sm cipher context object.
 *
 * Returns: a new sm cipher context object.
 **/
CamelCipherContext *
camel_smime_context_new (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return g_object_new (
		CAMEL_TYPE_SMIME_CONTEXT,
		"session", session, NULL);
}

void
camel_smime_context_set_encrypt_key (CamelSMIMEContext *context,
                                     gboolean use,
                                     const gchar *key)
{
	context->priv->send_encrypt_key_prefs = use;
	g_free (context->priv->encrypt_key);
	context->priv->encrypt_key = g_strdup (key);
}

/* set signing mode, clearsigned multipart/signed or enveloped */
void
camel_smime_context_set_sign_mode (CamelSMIMEContext *context,
                                   CamelSMIMESign type)
{
	context->priv->sign_mode = type;
}

/* TODO: This is suboptimal, but the only other solution is to pass around NSSCMSMessages */
guint32
camel_smime_context_describe_part (CamelSMIMEContext *context,
                                   CamelMimePart *part)
{
	CamelCipherContextClass *class;
	guint32 flags = 0;
	CamelContentType *ct;
	const gchar *tmp;

	if (!part)
		return flags;

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	ct = camel_mime_part_get_content_type (part);

	if (camel_content_type_is (ct, "multipart", "signed")) {
		tmp = camel_content_type_param (ct, "protocol");
		if (tmp &&
		    (g_ascii_strcasecmp (tmp, class->sign_protocol) == 0
		     || g_ascii_strcasecmp (tmp, "application/pkcs7-signature") == 0))
			flags = CAMEL_SMIME_SIGNED;
	} else if (camel_content_type_is (ct, "application", "x-pkcs7-mime")) {
		CamelStream *istream;
		NSSCMSMessage *cmsg;
		NSSCMSDecoderContext *dec;
		GByteArray *buffer;

		/* FIXME: stream this to the decoder incrementally */
		buffer = g_byte_array_new ();
		istream = camel_stream_mem_new_with_byte_array (buffer);

		/* FIXME Pass a GCancellable and GError here. */
		camel_data_wrapper_decode_to_stream_sync (
			camel_medium_get_content ((CamelMedium *) part),
			istream, NULL, NULL);

		g_seekable_seek (
			G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);

		dec = NSS_CMSDecoder_Start (
			NULL,
			NULL, NULL,
			NULL, NULL,	/* password callback    */
			NULL, NULL); /* decrypt key callback */

		NSS_CMSDecoder_Update (dec, (gchar *) buffer->data, buffer->len);
		g_object_unref (istream);

		cmsg = NSS_CMSDecoder_Finish (dec);
		if (cmsg) {
			if (NSS_CMSMessage_IsSigned (cmsg)) {
				printf ("message is signed\n");
				flags |= CAMEL_SMIME_SIGNED;
			}

			if (NSS_CMSMessage_IsEncrypted (cmsg)) {
				printf ("message is encrypted\n");
				flags |= CAMEL_SMIME_ENCRYPTED;
			}
#if 0
			if (NSS_CMSMessage_ContainsCertsOrCrls (cmsg)) {
				printf ("message contains certs or crls\n");
				flags |= CAMEL_SMIME_CERTS;
			}
#endif
			NSS_CMSMessage_Destroy (cmsg);
		} else {
			printf ("Message could not be parsed\n");
		}
	}

	return flags;
}

#endif /* ENABLE_SMIME */
