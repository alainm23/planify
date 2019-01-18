/*
 * e-source-enums.h
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_ENUMS_H
#define E_SOURCE_ENUMS_H

/**
 * EMdnResponsePolicy:
 * @E_MDN_RESPONSE_POLICY_NEVER:
 *   Never respond to an MDN request.
 * @E_MDN_RESPONSE_POLICY_ALWAYS:
 *   Always respond to an MDN request.
 * @E_MDN_RESPONSE_POLICY_ASK:
 *   Ask the user before responding to an MDN request.
 *
 * Policy for responding to Message Disposition Notification requests
 * (i.e. a Disposition-Notification-To header) when receiving messages.
 * See RFC 2298 for more information about MDN requests.
 *
 * Since: 3.6
 **/
typedef enum {
	E_MDN_RESPONSE_POLICY_NEVER,
	E_MDN_RESPONSE_POLICY_ALWAYS,
	E_MDN_RESPONSE_POLICY_ASK
} EMdnResponsePolicy;

/**
 * EProxyMethod:
 * @E_PROXY_METHOD_DEFAULT:
 *   Use the default #GProxyResolver (see g_proxy_resolver_get_default()).
 * @E_PROXY_METHOD_MANUAL:
 *   Use the FTP/HTTP/HTTPS/SOCKS settings defined in #ESourceProxy.
 * @E_PROXY_METHOD_AUTO:
 *   Use the autoconfiguration URL defined in #ESourceProxy.
 * @E_PROXY_METHOD_NONE:
 *   Direct connection; do not use a network proxy.
 *
 * Network proxy configuration methods.
 *
 * Since: 3.12
 **/
typedef enum {
	E_PROXY_METHOD_DEFAULT,
	E_PROXY_METHOD_MANUAL,
	E_PROXY_METHOD_AUTO,
	E_PROXY_METHOD_NONE
} EProxyMethod;

/**
 * ESourceAuthenticationResult:
 * @E_SOURCE_AUTHENTICATION_UNKNOWN:
 *   Unknown error occurred while authenticating. Since: 3.26
 * @E_SOURCE_AUTHENTICATION_ERROR:
 *   An error occurred while authenticating.
 * @E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED:
 *   An SSL certificate check failed. Since: 3.16.
 * @E_SOURCE_AUTHENTICATION_ACCEPTED:
 *   Server requesting authentication accepted password.
 * @E_SOURCE_AUTHENTICATION_REJECTED:
 *   Server requesting authentication rejected password.
 * @E_SOURCE_AUTHENTICATION_REQUIRED:
 *   Server requesting authentication, but none was given.
 *
 * Status codes used by the #EBackend authentication wrapper.
 *
 * Since: 3.6
 **/
typedef enum {
	E_SOURCE_AUTHENTICATION_UNKNOWN = -1,
	E_SOURCE_AUTHENTICATION_ERROR,
	E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED,
	E_SOURCE_AUTHENTICATION_ACCEPTED,
	E_SOURCE_AUTHENTICATION_REJECTED,
	E_SOURCE_AUTHENTICATION_REQUIRED
} ESourceAuthenticationResult;

/**
 * ETrustPromptResponse:
 * @E_TRUST_PROMPT_RESPONSE_UNKNOWN: Unknown response, usually due to some error
 * @E_TRUST_PROMPT_RESPONSE_REJECT: Reject permanently
 * @E_TRUST_PROMPT_RESPONSE_ACCEPT: Accept permanently
 * @E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY: Accept temporarily
 * @E_TRUST_PROMPT_RESPONSE_REJECT_TEMPORARILY: Reject temporarily
 *
 * Response codes for the trust prompt.
 *
 * Since: 3.8
 **/
typedef enum {
	E_TRUST_PROMPT_RESPONSE_UNKNOWN = -1,
	E_TRUST_PROMPT_RESPONSE_REJECT = 0,
	E_TRUST_PROMPT_RESPONSE_ACCEPT = 1,
	E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY = 2,
	E_TRUST_PROMPT_RESPONSE_REJECT_TEMPORARILY = 3
} ETrustPromptResponse;

/**
 * ESourceConnectionStatus:
 * @E_SOURCE_CONNECTION_STATUS_DISCONNECTED:
 *   The source is currently disconnected from its (possibly remote) data store.
 * @E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS:
 *   The source asked for credentials with a 'credentials-required' signal and
 *   is currently awaiting for them.
 * @E_SOURCE_CONNECTION_STATUS_SSL_FAILED:
 *   A user rejected SSL certificate trust for the connection.
 * @E_SOURCE_CONNECTION_STATUS_CONNECTING:
 *   The source is currently connecting to its (possibly remote) data store.
 * @E_SOURCE_CONNECTION_STATUS_CONNECTED:
 *   The source is currently connected to its (possibly remote) data store.
 *
 * Connection status codes used by the #ESource to indicate its connection state.
 * This is used in combination with authentication of the ESource. For example,
 * if there are multiple clients asking for a password and a user enters the password
 * in one of them, then the status will change into 'connecting', which is a signal
 * do close the password prompt in the other client, because the credentials had
 * been already provided.
 *
 * Since: 3.16
 **/
typedef enum {
	E_SOURCE_CONNECTION_STATUS_DISCONNECTED,
	E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS,
	E_SOURCE_CONNECTION_STATUS_SSL_FAILED,
	E_SOURCE_CONNECTION_STATUS_CONNECTING,
	E_SOURCE_CONNECTION_STATUS_CONNECTED
} ESourceConnectionStatus;

/**
 * ESourceCredentialsReason:
 * @E_SOURCE_CREDENTIALS_REASON_UNKNOWN:
 *   A return value when there was no 'credentials-required' signal emitted yet,
 *   or a pair 'authenticate' signal had been received. This value should not
 *   be used in the call of 'credentials-required'.
 * @E_SOURCE_CREDENTIALS_REASON_REQUIRED:
 *   This is the first attempt to get credentials for the source. It's usually
 *   used right after the source is opened and the authentication continues with
 *   a stored credentials, if any.
 * @E_SOURCE_CREDENTIALS_REASON_REJECTED:
 *   The previously used credentials had been rejected by the server. That
 *   usually means that the user should be asked to provide/correct the credentials.
 * @E_SOURCE_CREDENTIALS_REASON_SSL_FAILED:
 *   A secured connection failed due to some server-side certificate issues.
 * @E_SOURCE_CREDENTIALS_REASON_ERROR:
 *   The server returned an error. It is not possible to connect to it
 *   at the moment usually.
 *
 * An ESource's authentication reason, used by an ESource::CredentialsRequired method.
 *
 * Since: 3.16
 **/
typedef enum {
	E_SOURCE_CREDENTIALS_REASON_UNKNOWN,
	E_SOURCE_CREDENTIALS_REASON_REQUIRED,
	E_SOURCE_CREDENTIALS_REASON_REJECTED,
	E_SOURCE_CREDENTIALS_REASON_SSL_FAILED,
	E_SOURCE_CREDENTIALS_REASON_ERROR
} ESourceCredentialsReason;

/**
 * ESourceLDAPAuthentication:
 * @E_SOURCE_LDAP_AUTHENTICATION_NONE:
 *   Use none authentication type.
 * @E_SOURCE_LDAP_AUTHENTICATION_EMAIL:
 *   Use an email address for authentication.
 * @E_SOURCE_LDAP_AUTHENTICATION_BINDDN:
 *   Use a bind DN for authentication.
 *
 * Defines authentication types for LDAP sources.
 *
 * Since: 3.18
 **/
typedef enum {
	E_SOURCE_LDAP_AUTHENTICATION_NONE,
	E_SOURCE_LDAP_AUTHENTICATION_EMAIL,
	E_SOURCE_LDAP_AUTHENTICATION_BINDDN
} ESourceLDAPAuthentication;

/**
 * ESourceLDAPScope:
 * @E_SOURCE_LDAP_SCOPE_ONELEVEL:
 *   One level search scope.
 * @E_SOURCE_LDAP_SCOPE_SUBTREE:
 *   Sub-tree search scope.
 *
 * Defines search scope for LDAP sources.
 *
 * Since: 3.18
 **/
typedef enum {
	E_SOURCE_LDAP_SCOPE_ONELEVEL,
	E_SOURCE_LDAP_SCOPE_SUBTREE
} ESourceLDAPScope;

/**
 * ESourceLDAPSecurity:
 * @E_SOURCE_LDAP_SECURITY_NONE:
 *   Connect insecurely.
 * @E_SOURCE_LDAP_SECURITY_LDAPS:
 *   Connect using secure LDAP (LDAPS).
 * @E_SOURCE_LDAP_SECURITY_STARTTLS:
 *   Connect using STARTTLS.
 *
 * Defines what connection security should be used for LDAP sources.
 *
 * Since: 3.18
 **/
typedef enum {
	E_SOURCE_LDAP_SECURITY_NONE,
	E_SOURCE_LDAP_SECURITY_LDAPS,
	E_SOURCE_LDAP_SECURITY_STARTTLS
} ESourceLDAPSecurity;

/**
 * ESourceWeatherUnits:
 * @E_SOURCE_WEATHER_UNITS_FAHRENHEIT:
 *   Fahrenheit units
 * @E_SOURCE_WEATHER_UNITS_CENTIGRADE:
 *   Centigrade units
 * @E_SOURCE_WEATHER_UNITS_KELVIN:
 *   Kelvin units
 *
 * Units to be used in an #ESourceWeather extension.
 *
 * Since: 3.18
 **/
typedef enum {
	E_SOURCE_WEATHER_UNITS_FAHRENHEIT = 0,
	E_SOURCE_WEATHER_UNITS_CENTIGRADE,
	E_SOURCE_WEATHER_UNITS_KELVIN
} ESourceWeatherUnits;

/**
 * ESourceMailCompositionReplyStyle:
 * @E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_DEFAULT:
 *   Use default reply style.
 * @E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_QUOTED:
 *   Use quoted reply style.
 * @E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_DO_NOT_QUOTE:
 *   Do not quote anything in replies.
 * @E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_ATTACH:
 *   Attach original message in replies.
 * @E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_OUTLOOK:
 *  Use Outlook reply style.
 *
 * Set of preferred reply styles for an #ESourceMailComposition extension.
 *
 * Since: 3.20
 **/
typedef enum {
	E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_DEFAULT = 0,
	E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_QUOTED,
	E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_DO_NOT_QUOTE,
	E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_ATTACH,
	E_SOURCE_MAIL_COMPOSITION_REPLY_STYLE_OUTLOOK
} ESourceMailCompositionReplyStyle;

/**
 * EThreeState:
 * @E_THREE_STATE_OFF: the three-state value is Off
 * @E_THREE_STATE_ON: the three-state value is On
 * @E_THREE_STATE_INCONSISTENT: the three-state value is neither On, nor Off
 *
 * Describes a three-state value, which can be either Off, On or Inconsistent.
 *
 * Since: 3.26
 **/
typedef enum {
	E_THREE_STATE_OFF = 0,
	E_THREE_STATE_ON,
	E_THREE_STATE_INCONSISTENT
} EThreeState;

#endif /* E_SOURCE_ENUMS_H */
