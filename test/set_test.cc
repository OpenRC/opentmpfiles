/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

/* Tests for the set module. */

#include "test.h"

/* Make sure we can reinit things. */
TEST(Set, Reinit) {
	ordered_set_t set;
	ordered_set_init(&set);
	ordered_set_free(&set);
	ordered_set_init(&set);
	ordered_set_free(&set);
	ordered_set_init(&set);
	ordered_set_free(&set);
}

/* Smoke test for the API. */
TEST(Set, Smoke) {
	ordered_set_t set;
	ordered_set_init(&set);
	ASSERT_FALSE(ordered_set_exists(&set, "foo"));
	ASSERT_FALSE(ordered_set_exists(&set, "bar"));
	ordered_set_add(&set, "foo");
	ASSERT_TRUE(ordered_set_exists(&set, "foo"));
	ASSERT_FALSE(ordered_set_exists(&set, "bar"));
	ordered_set_free(&set);
}
