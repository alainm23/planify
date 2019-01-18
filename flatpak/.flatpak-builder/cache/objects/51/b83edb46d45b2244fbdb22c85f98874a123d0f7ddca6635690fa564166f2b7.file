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

#ifndef GVDEVICE_PLUGIN_H
#define GVDEVICE_PLUGIN_H

#include "types.h"
#include "gvplugin.h"
#include "gvcjob.h"

#ifdef __cplusplus
extern "C" {
#endif

    struct gvdevice_engine_s {
	void (*initialize) (GVJ_t * firstjob);
	void (*format) (GVJ_t * firstjob);
	void (*finalize) (GVJ_t * firstjob);
    };

#ifdef __cplusplus
}
#endif
#endif				/* GVDEVICE_PLUGIN_H */
