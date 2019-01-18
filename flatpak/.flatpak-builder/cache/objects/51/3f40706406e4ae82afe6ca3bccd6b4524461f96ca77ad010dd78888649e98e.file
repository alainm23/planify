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

/* geometric types and macros (e.g. points and boxes) with application to, but
 * no specific dependance on graphs */

#ifndef GV_GEOM_H
#define GV_GEOM_H

#include "arith.h"

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct { int x, y; } point;

typedef struct pointf_s { double x, y; } pointf;

/* tell pathplan/pathgeom.h */
#define HAVE_POINTF_S

typedef struct { point LL, UR; } box;

typedef struct { pointf LL, UR; } boxf;


/* true if point p is inside box b */
#define INSIDE(p,b)	(BETWEEN((b).LL.x,(p).x,(b).UR.x) && BETWEEN((b).LL.y,(p).y,(b).UR.y))

/* true if boxes b0 and b1 overlap */
#define OVERLAP(b0,b1)	(((b0).UR.x >= (b1).LL.x) && ((b1).UR.x >= (b0).LL.x) && ((b0).UR.y >= (b1).LL.y) && ((b1).UR.y >= (b0).LL.y))

/* true if box b0 completely contains b1*/
#define CONTAINS(b0,b1)	(((b0).UR.x >= (b1).UR.x) && ((b0).UR.y >= (b1).UR.y) && ((b0).LL.x <= (b1).LL.x) && ((b0).LL.y <= (b1).LL.y))

/* expand box b as needed to enclose point p */
#define EXPANDBP(b, p)	((b).LL.x = MIN((b).LL.x, (p).x), (b).LL.y = MIN((b).LL.y, (p).y), (b).UR.x = MAX((b).UR.x, (p).x), (b).UR.y = MAX((b).UR.y, (p).y))

/* expand box b0 as needed to enclose box b1 */
#define EXPANDBB(b0, b1) ((b0).LL.x = MIN((b0).LL.x, (b1).LL.x), (b0).LL.y = MIN((b0).LL.y, (b1).LL.y), (b0).UR.x = MAX((b0).UR.x, (b1).UR.x), (b0).UR.y = MAX((b0).UR.y, (b1).UR.y))

/* clip box b0 to fit box b1 */
#define CLIPBB(b0, b1) ((b0).LL.x = MAX((b0).LL.x, (b1).LL.x), (b0).LL.y = MAX((b0).LL.y, (b1).LL.y), (b0).UR.x = MIN((b0).UR.x, (b1).UR.x), (b0).UR.y = MIN((b0).UR.y, (b1).UR.y))

#define LEN2(a,b)		(SQR(a) + SQR(b))
#define LEN(a,b)		(sqrt(LEN2((a),(b))))

#define DIST2(p,q)		(LEN2(((p).x - (q).x),((p).y - (q).y)))
#define DIST(p,q)		(sqrt(DIST2((p),(q))))

#define POINTS_PER_INCH	72
#define POINTS_PER_PC		((double)POINTS_PER_INCH / 6)
#define POINTS_PER_CM		((double)POINTS_PER_INCH * 0.393700787)
#define POINTS_PER_MM		((double)POINTS_PER_INCH * 0.0393700787)

#define POINTS(a_inches)	(ROUND((a_inches)*POINTS_PER_INCH))
#define INCH2PS(a_inches)	((a_inches)*(double)POINTS_PER_INCH)
#define PS2INCH(a_points)	((a_points)/(double)POINTS_PER_INCH)

#define P2PF(p,pf)		((pf).x = (p).x,(pf).y = (p).y)
#define PF2P(pf,p)		((p).x = ROUND((pf).x),(p).y = ROUND((pf).y))

#define B2BF(b,bf)		(P2PF((b).LL,(bf).LL),P2PF((b).UR,(bf).UR))
#define BF2B(bf,b)		(PF2P((bf).LL,(b).LL),PF2P((bf).UR,(b).UR))

#define APPROXEQ(a,b,tol)	(ABS((a) - (b)) < (tol))
#define APPROXEQPT(p,q,tol)	(DIST2((p),(q)) < SQR(tol))

/* some common tolerance values */
#define MILLIPOINT .001
#define MICROPOINT .000001

#ifdef __cplusplus
}
#endif

#endif
