
/* vim:set shiftwidth=4 ts=8: */

/*************************************************************************
 * Copyright (c) 2011 AT&T Intellectual Property 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: See CVS logs. Details at http://www.graphviz.org/
 *************************************************************************/

/* Common header used by both clients and plugins */

#ifndef GVCEXT_H
#define GVCEXT_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Define an apis array of name strings using an enumerated api_t as index.
 * The enumerated type is defined here.  The apis array is
 * inititialized in gvplugin.c by redefining ELEM and reinvoking APIS.
 */
#define APIS ELEM(render) ELEM(layout) ELEM(textlayout) ELEM(device) ELEM(loadimage)

/*
 * Define api_t using names based on the plugin names with API_ prefixed.
 */
#define ELEM(x) API_##x,
    typedef enum { APIS _DUMMY_ELEM_=0 } api_t; /* API_render, API_layout, ... */
    			/* Stupid but true: The sole purpose of "_DUMMY_ELEM_=0"
			 * is to avoid a "," after the last element of the enum
			 * because some compilers when using "-pedantic"
			 * generate an error for about the dangling ","
			 * but only if this header is used from a .cpp file!
			 * Setting it to 0 makes sure that the enumeration
			 * does not define an extra value.  (It does however
			 * define _DUMMY_ELEM_ as an enumeration symbol,
			 * but its value duplicates that of the first
			 * symbol in the enumeration - in this case "render".)
			 */

    			/* One could wonder why trailing "," in:
			 * 	int nums[]={1,2,3,};
			 * is OK, but in:
			 * 	typedef enum {a,b,c,} abc_t; 
			 * is not!!!
			 */
#undef ELEM

    typedef struct GVJ_s GVJ_t;
    typedef struct GVG_s GVG_t;
    typedef struct GVC_s GVC_t;

    typedef struct {
	const char *name;
	void* address;
    } lt_symlist_t;

    typedef struct gvplugin_available_s gvplugin_available_t;

/*visual studio*/
#ifdef WIN32
#ifndef GVC_EXPORTS
__declspec(dllimport) lt_symlist_t lt_preloaded_symbols[];
#else
//__declspec(dllexport) lt_symlist_t lt_preloaded_symbols[];
#if !defined(LTDL_H)
lt_symlist_t lt_preloaded_symbols[];
#endif
#endif
#endif
/*end visual studio*/


#ifndef WIN32
#if defined(GVDLL)
	__declspec(dllexport) lt_symlist_t lt_preloaded_symbols[];
#else
#if !defined(LTDL_H)
	extern lt_symlist_t lt_preloaded_symbols[];
#endif
#endif
#endif


#ifdef __cplusplus
}
#endif



#endif
