/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

/*
 * Include all the project & dependent headers in this one place.  It might mean
 * we include more headers than we need to in some modules, but so be it.  The
 * overall build should still be "fast enough".
 *
 * This should be the only header that tmpfiles modules need to include.
 */

#ifndef TMPFILES_TMPFILES_H
#define TMPFILES_TMPFILES_H

/* This needs to come first as it provides C library & compiler details. */
#include "headers.h"

#include "xfuncs.h"
#include "set.h"
#include "cli.h"

#endif
