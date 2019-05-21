/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

/*
 * We keep all the C library headers in this one place.  It might mean we
 * include more headers than we need to in some modules, but so be it.  The
 * overall build should still be "fast enough".
 */

#ifndef TMPFILES_HEADERS_H
#define TMPFILES_HEADERS_H

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Some compiler attributes we find useful. */
#define attribute_noreturn __attribute__((__noreturn__))

#endif
