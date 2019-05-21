/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

#include "tmpfiles.h"

bool verbose = false;
bool dryrun = false;
bool do_default = true;
bool do_boot = false;
bool do_clean = false;
bool do_create = false;
bool do_remove = false;

ordered_set_t cli_files = {};
ordered_set_t rules_prefix = {};
ordered_set_t rules_exclude_prefix = {};

/* Order here doesn't matter.  All must have a value of 256+ though. */
typedef enum {
	OPT_BOOT = 0x100,
	OPT_CLEAN,
	OPT_CREATE,
	OPT_DRY_RUN,
	OPT_EXCLUDE_PREFIX,
	OPT_PREFIX,
	OPT_REMOVE,
	OPT_VERBOSE,
	OPT_VERSION,
} options;

/*
 * Order here reflects output order in --help output, so things are loosely
 * grouped by relationship.  Otherwise, it doesn't matter.
 */
#define PARSE_FLAGS "h"
#define a_argument required_argument
static struct option const opts[] = {
	{"boot",           no_argument, NULL, OPT_BOOT},
	{"create",         no_argument, NULL, OPT_CREATE},
	{"clean",          no_argument, NULL, OPT_CLEAN},
	{"remove",         no_argument, NULL, OPT_REMOVE},
	{"prefix",          a_argument, NULL, OPT_PREFIX},
	{"exclude-prefix",  a_argument, NULL, OPT_EXCLUDE_PREFIX},
	{"dry-run",        no_argument, NULL, OPT_DRY_RUN},
	{"dryrun",         no_argument, NULL, OPT_DRY_RUN},
	{"verbose",        no_argument, NULL, OPT_VERBOSE},
	{"help",           no_argument, NULL, 'h'},
	{"version",        no_argument, NULL, OPT_VERSION},
	{NULL,             no_argument, NULL, 0x0}
};

/* Order here must match opts array above. */
static const char * const opts_help[] = {
	"Process all boot entries (have a ! in the command)",
	"Process all f, F, w, d, D, v, p, L, c, b, m and z, Z, t, T, a, A commands",
	"All paths with an age setting will be cleaned",
	"Remove directories marked with D or R, and paths marked with r or R",
	"Only process entries that match the specified paths",
	"Ignore all entries that match the specified paths",
	"Don't make any changes; just show what would be done",
	"Alias to --dry-run",
	"Run in verbose mode",
	"Print this help and exit",
	"Print version and exit",
	NULL,
};

attribute_noreturn
void usage(int status)
{
	/* Increase this if a new --longer-option is added. */
	const int padding = 25;
	size_t i;
	int ret;
	FILE *fp = status == 0 ? stdout : stderr;

	fprintf(fp,
		"Usage: tmpfiles [options] [files]\n"
		"\n"
		"If [files] are specified, only those will be processed.\n"
		"Basenames are searched, while non-basenames are read directly.\n"
		"\n"
		"Options:\n"
	);

	for (i = 0; opts[i].name; ++i) {
		if (opts[i].val > '~' || opts[i].val < ' ')
			fprintf(fp, "      ");
		else
			fprintf(fp, "  -%c, ", opts[i].val);

		ret = fprintf(fp, "--%s ", opts[i].name);
		fprintf(fp, "%-*s", padding - ret,
			opts[i].has_arg == no_argument ? "" : "<arg>");
		fprintf(fp, " %s\n", opts_help[i]);
	}

	exit(status);
}

#ifndef VERSION
#define VERSION "git"
#endif
attribute_noreturn
static void version(void)
{
	printf("opentmpfiles %s\n", VERSION);
	exit(0);
}

void parseargs(int argc, char *argv[])
{
	int i;

	ordered_set_init(&cli_files);
	ordered_set_init(&rules_prefix);
	ordered_set_init(&rules_exclude_prefix);

	while ((i = getopt_long(argc, argv, PARSE_FLAGS, opts, NULL)) != -1) {
		switch (i) {
		case OPT_BOOT:
			do_default = false;
			do_boot = true;
			break;
		case OPT_CLEAN:
			do_default = false;
			do_clean = true;
			break;
		case OPT_CREATE:
			do_default = false;
			do_create = true;
			break;
		case OPT_REMOVE:
			do_default = false;
			do_remove = true;
			break;

		case OPT_EXCLUDE_PREFIX:
			ordered_set_add(&rules_exclude_prefix, optarg);
			break;
		case OPT_PREFIX:
			ordered_set_add(&rules_prefix, optarg);
			break;

		case OPT_DRY_RUN:
			dryrun = true;
			break;
		case OPT_VERBOSE:
			verbose = true;
			break;
		case OPT_VERSION:
			version();
			break;
		case 'h':
			usage(0);
		default:
			usage(1);
		}
	}

	for (i = optind; i < argc; ++i)
		ordered_set_add(&cli_files, argv[i]);
}
