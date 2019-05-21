/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

#ifndef TMPFILES_SET_H
#define TMPFILES_SET_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	char **elements;
	size_t reserved;
	size_t count;
} ordered_set_t;

/* Initialize a set.  Its storage should be declared already. */
extern void ordered_set_init(ordered_set_t *set);

/* Add a string to the set.  The string is duplicated. */
extern void ordered_set_add(ordered_set_t *set, const char *element);

/* Test whether the string is in the set. */
extern bool ordered_set_exists(ordered_set_t *set, const char *element);

/* Clear a set. Must call ordered_set_init before using again. */
extern void ordered_set_free(ordered_set_t *set);

#ifdef __cplusplus
}
#endif

#endif
