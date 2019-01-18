#undef TRACEPOINT_PROVIDER
#define TRACEPOINT_PROVIDER libunity

#undef TRACEPOINT_INCLUDE
#define TRACEPOINT_INCLUDE "./lttng-component-provider.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#if !defined(_LIBUNITY_COMPONENT_PROVIDER_H) || defined(TRACEPOINT_HEADER_MULTI_READ)
#define _LIBUNITY_COMPONENT_PROVIDER_H

#include <lttng/tracepoint.h> 

TRACEPOINT_EVENT(
	libunity,
	message,
	TP_ARGS(char *, text),
	TP_FIELDS(
		ctf_string(message, text)
	)
)

TRACEPOINT_LOGLEVEL(
        libunity,
        message,
        TRACE_INFO)

#endif

#include <lttng/tracepoint-event.h>

#ifdef __cplusplus
}
#endif /* __cplusplus */
