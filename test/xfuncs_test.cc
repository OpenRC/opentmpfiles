/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

/* Tests for the xfuncs module. */

#include "test.h"

TEST(xfuncs, asprintf) {
	char *s;
	xasprintf(&s, "a %i %c %s", 12, 'f', "bar");
	ASSERT_STREQ(s, "a 12 f bar");
	free(s);
}

TEST(xfuncs, xmalloc) {
	char *s = static_cast<char*>(xmalloc(5));
	memset(s, 'a', 4);
	s[4] = '\0';
	ASSERT_STREQ(s, "aaaa");
	free(s);
}

TEST(xfuncs, xrealloc) {
	char *s = static_cast<char*>(xmalloc(1));
	s = static_cast<char*>(xrealloc(s, 5));
	memset(s, 'a', 4);
	s[4] = '\0';
	ASSERT_STREQ(s, "aaaa");
	free(s);
}

TEST(xfuncs, xstrdup) {
	char *s = xstrdup("foo");
	ASSERT_STREQ(s, "foo");
	free(s);
}
