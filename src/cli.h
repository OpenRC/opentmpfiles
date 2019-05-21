/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

#ifndef TMPFILES_CLI_H
#define TMPFILES_CLI_H

#include "set.h"

#ifdef __cplusplus
extern "C" {
#endif

/* State variables for the program. */
extern bool verbose;
extern bool dryrun;
extern bool do_boot;
extern bool do_default;
extern bool do_create;
extern bool do_clean;
extern bool do_remove;
extern ordered_set_t cli_files;
extern ordered_set_t rules_prefix;
extern ordered_set_t rules_exclude_prefix;

/* Parse the command line arguments. */
extern void parseargs(int argc, char *argv[]);

/* Show usage details and exit. */
attribute_noreturn void usage(int status);

#ifdef __cplusplus
}
#endif

#endif
