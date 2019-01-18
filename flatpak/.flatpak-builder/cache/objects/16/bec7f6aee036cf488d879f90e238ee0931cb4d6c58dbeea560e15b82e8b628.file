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



#ifndef _PATH_INCLUDE
#define _PATH_INCLUDE

#include "pathgeom.h"

#ifdef __cplusplus
extern "C" {
#endif


#if defined(_BLD_pathplan) && defined(__EXPORT__)
#   define extern __EXPORT__
#endif

/* find shortest euclidean path within a simple polygon */
    extern int Pshortestpath(Ppoly_t * boundary, Ppoint_t endpoints[2],
			     Ppolyline_t * output_route);

/* fit a spline to an input polyline, without touching barrier segments */
    extern int Proutespline(Pedge_t * barriers, int n_barriers,
			    Ppolyline_t input_route,
			    Pvector_t endpoint_slopes[2],
			    Ppolyline_t * output_route);

/* utility function to convert from a set of polygonal obstacles to barriers */
    extern int Ppolybarriers(Ppoly_t ** polys, int npolys,
			     Pedge_t ** barriers, int *n_barriers);

/* function to convert a polyline into a spline representation */
    extern void make_polyline(Ppolyline_t line, Ppolyline_t* sline);

#undef extern

#ifdef __cplusplus
}
#endif
#endif
