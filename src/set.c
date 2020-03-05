/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

#include "tmpfiles.h"

void ordered_set_init(ordered_set_t *set)
{
	set->reserved = 16;
	set->count = 0;
	set->elements = xmalloc(sizeof(*set->elements) * set->reserved);
}

void ordered_set_add(ordered_set_t *set, const char *element)
{
	if (set->count == set->reserved) {
		set->reserved *= 2;
		set->elements = xrealloc(set->elements, sizeof(*set->elements) * set->reserved);
	}

	set->elements[set->count] = xstrdup(element);
	set->count++;
}

bool ordered_set_exists(ordered_set_t *set, const char *element)
{
	for (size_t i = 0; i < set->count; ++i)
		if (strcmp(set->elements[i], element) == 0)
			return true;

	return false;
}

void ordered_set_free(ordered_set_t *set)
{
	for (size_t i = 0; i < set->count; ++i)
		free(set->elements[i]);

	free(set->elements);
	set->elements = NULL;
}
