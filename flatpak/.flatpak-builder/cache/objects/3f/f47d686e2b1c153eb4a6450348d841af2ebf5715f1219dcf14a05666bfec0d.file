/* $Id$ $Revision$ */
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

#ifndef			GVC_H
#define			GVC_H

#include "types.h"
#include "gvplugin.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef GVDLL
#define extern __declspec(dllexport)
#else
#define extern
#endif

/*visual studio*/
#ifdef WIN32
#ifndef GVC_EXPORTS
#undef extern
#define extern __declspec(dllimport)
#endif
#endif
/*end visual studio*/
	
#define LAYOUT_DONE(g) (agbindrec(g, "Agraphinfo_t", 0, TRUE) && GD_drawing(g))

/* misc */
/* FIXME - this needs eliminating or renaming */
extern void gvToggle(int);

/* set up a graphviz context */
extern GVC_t *gvNEWcontext(const lt_symlist_t *builtins, int demand_loading);

/*  set up a graphviz context - and init graph - retaining old API */
extern GVC_t *gvContext(void);
/*  set up a graphviz context - and init graph - with builtins */
extern GVC_t *gvContextPlugins(const lt_symlist_t *builtins, int demand_loading);

/* get information associated with a graphviz context */
extern char **gvcInfo(GVC_t*);
extern char *gvcVersion(GVC_t*);
extern char *gvcBuildDate(GVC_t*);

/* parse command line args - minimally argv[0] sets layout engine */
extern int gvParseArgs(GVC_t *gvc, int argc, char **argv);
extern graph_t *gvNextInputGraph(GVC_t *gvc);
extern graph_t *gvPluginsGraph(GVC_t *gvc);

/* Compute a layout using a specified engine */
extern int gvLayout(GVC_t *gvc, graph_t *g, const char *engine);

/* Compute a layout using layout engine from command line args */
extern int gvLayoutJobs(GVC_t *gvc, graph_t *g);

/* Render layout into string attributes of the graph */
extern void attach_attrs(graph_t *g);

/* Render layout in a specified format to an open FILE */
extern int gvRender(GVC_t *gvc, graph_t *g, const char *format, FILE *out);

/* Render layout in a specified format to a file with the given name */
extern int gvRenderFilename(GVC_t *gvc, graph_t *g, const char *format, const char *filename);

/* Render layout in a specified format to an external context */
extern int gvRenderContext(GVC_t *gvc, graph_t *g, const char *format, void *context);

/* Render layout in a specified format to a malloc'ed string */
extern int gvRenderData(GVC_t *gvc, graph_t *g, const char *format, char **result, unsigned int *length);

/* Free memory allocated and pointed to by *result in gvRenderData */
extern void gvFreeRenderData (char* data);

/* Render layout according to -T and -o options found by gvParseArgs */
extern int gvRenderJobs(GVC_t *gvc, graph_t *g);

/* Clean up layout data structures - layouts are not nestable (yet) */
extern int gvFreeLayout(GVC_t *gvc, graph_t *g);

/* Clean up graphviz context */
extern void gvFinalize(GVC_t *gvc);
extern int gvFreeContext(GVC_t *gvc);

/* Return list of plugins of type kind.
 * kind would normally be "render" "layout" "textlayout" "device" "loadimage"
 * The size of the list is stored in sz.
 * The caller is responsible for freeing the storage. This involves
 * freeing each item, then the list.
 * Returns NULL on error, or if there are no plugins.
 * In the former case, sz is unchanged; in the latter, sz = 0.
 *
 * At present, the str argument is unused, but may be used to modify
 * the search as in gvplugin_list above.
 */
extern char** gvPluginList (GVC_t *gvc, const char* kind, int* sz, char*);

/** Add a library from your user application
 * @param gvc Graphviz context to add library to
 * @param lib library to add
 */
extern void gvAddLibrary(GVC_t *gvc, gvplugin_library_t *lib);

/** Perform a Transitive Reduction on a graph
 * @param g  graph to be transformed.
 */
extern int gvToolTred(graph_t *g);

#undef extern

#ifdef __cplusplus
}
#endif

#endif			/* GVC_H */
