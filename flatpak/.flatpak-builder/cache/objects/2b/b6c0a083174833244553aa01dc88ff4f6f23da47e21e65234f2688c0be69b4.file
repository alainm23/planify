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



#ifndef _PACK_H
#define _PACK_H 1

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

/* Type indicating granularity and method 
 *  l_undef    - unspecified
 *  l_node     - polyomino using nodes and edges
 *  l_clust    - polyomino using nodes and edges and top-level clusters
 *               (assumes ND_clust(n) unused by application)
 *  l_graph    - polyomino using computer graph bounding box
 *  l_array    - array based on graph bounding boxes
 *  l_aspect   - tiling based on graph bounding boxes preserving aspect ratio
 *  l_hull     - polyomino using convex hull (unimplemented)
 *  l_tile     - tiling using graph bounding box (unimplemented)
 *  l_bisect   - alternate bisection using graph bounding box (unimplemented)
 */
    typedef enum { l_undef, l_clust, l_node, l_graph, l_array, l_aspect } pack_mode;

#define PK_COL_MAJOR   (1 << 0)
#define PK_USER_VALS   (1 << 1)
#define PK_LEFT_ALIGN  (1 << 2)
#define PK_RIGHT_ALIGN (1 << 3)
#define PK_TOP_ALIGN   (1 << 4)
#define PK_BOT_ALIGN   (1 << 5)
#define PK_INPUT_ORDER (1 << 6)

typedef unsigned int packval_t;

    typedef struct {
	float aspect;		/* desired aspect ratio */
	int sz;			/* row/column size size */
	unsigned int margin;	/* margin left around objects, in points */
	int doSplines;		/* use splines in constructing graph shape */
	pack_mode mode;		/* granularity and method */
	boolean *fixed;		/* fixed[i] == true implies g[i] should not be moved */
	packval_t* vals;	/* for arrays, sort numbers */
	int flags;       
    } pack_info;

/*visual studio*/
#ifdef WIN32
#ifndef GVC_EXPORTS
#define extern __declspec(dllimport)
#endif
#endif
/*end visual studio*/

    extern point *putRects(int ng, boxf* bbs, pack_info* pinfo);
    extern int packRects(int ng, boxf* bbs, pack_info* pinfo);

    extern point *putGraphs(int, Agraph_t **, Agraph_t *, pack_info *);
    extern int packGraphs(int, Agraph_t **, Agraph_t *, pack_info *);
    extern int packSubgraphs(int, Agraph_t **, Agraph_t *, pack_info *);
    extern int pack_graph(int ng, Agraph_t** gs, Agraph_t* root, boolean* fixed);

    extern int shiftGraphs(int, Agraph_t**, point*, Agraph_t*, int);

    extern pack_mode getPackMode(Agraph_t * g, pack_mode dflt);
    extern int getPack(Agraph_t *, int not_def, int dflt);
    extern pack_mode getPackInfo(Agraph_t * g, pack_mode dflt, int dfltMargin, pack_info*);
    extern pack_mode getPackModeInfo(Agraph_t * g, pack_mode dflt, pack_info*);
    extern pack_mode parsePackModeInfo(char* p, pack_mode dflt, pack_info* pinfo);

    extern int isConnected(Agraph_t *);
    extern Agraph_t **ccomps(Agraph_t *, int *, char *);
    extern Agraph_t **cccomps(Agraph_t *, int *, char *);
    extern Agraph_t **pccomps(Agraph_t *, int *, char *, boolean *);
    extern int nodeInduce(Agraph_t *);
    extern Agraph_t *mapClust(Agraph_t *);
#undef extern
#ifdef __cplusplus
}
#endif
#endif
