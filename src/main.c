/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

/*
 * This module should only contain the main function, and even that should be
 * fairly small.  Anything in this file is unable to be unittested.
 */

#include "tmpfiles.h"

static const char *flatten_set(ordered_set_t *set)
{
	char *ret = NULL;
	size_t i;
	size_t len = 0;

	for (i = 0; i < set->count; ++i)
		len += strlen(set->elements[i]) + 1;

	if (len == 0)
		return "";

	char *p = ret = xmalloc(len);
	for (i = 0; i < set->count; ++i) {
		char *ele = set->elements[i];
		size_t len = strlen(ele);
		memcpy(p, ele, len);
		p[len] = ' ';
		p += len + 1;
	}
	ret[len - 1] = '\0';
	return ret;
}

static void reset_env(void)
{
	setenv("BOOT", do_boot ? "1" : "0", 1);
	setenv("CLEAN", do_clean ? "1" : "0", 1);
	setenv("CREATE", do_create ? "1" : "0", 1);
	setenv("DRYRUN", dryrun ? "1" : "0", 1);
	setenv("REMOVE", do_remove ? "1" : "0", 1);
	setenv("VERBOSE", verbose ? "1" : "0", 1);
	setenv("EXCLUDE", flatten_set(&rules_exclude_prefix), 1);
	setenv("PREFIX", flatten_set(&rules_prefix), 1);
	setenv("FILES", flatten_set(&cli_files), 1);
}

int main(int argc, char *argv[])
{
	parseargs(argc, argv);

	if (do_clean)
		errx(1, "--clean is not yet implemented");

	if (do_create && do_remove)
		errx(1, "--create and --remove are mutually exclusive");

	/* Clear out env vars the shell script expects. */
	reset_env();

	int ret = execlp("tmpfiles.sh", "tmpfiles.sh", "--run-by-tmpfiles-wrapper", NULL);
	err(ret, "Could not execute tmpfiles.sh");
}
