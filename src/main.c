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

int main(int argc, char *argv[])
{
	int ret = execvp("tmpfiles.sh", argv);
	err(ret, "Could not execute tmpfiles.sh");
}
