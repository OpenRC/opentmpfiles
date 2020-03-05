/*
 * Copyright 2017-2019 Gentoo Foundation
 * Copyright 2017-2019 The Chromium OS Authors
 * Released under the 2-clause BSD license.
 */

#ifndef TMPFILES_XFUNCS_H
#define TMPFILES_XFUNCS_H

#ifdef __cplusplus
extern "C" {
#endif

#define xasprintf(...) \
	do { \
		if (asprintf(__VA_ARGS__) < 0) \
			err(1, "asprintf"); \
	} while (0)

static inline void *xmalloc(size_t size)
{
	void *ret = malloc(size);
	if (ret == NULL)
		err(1, "malloc");
	return ret;
}

static inline void *xrealloc(void *ptr, size_t size)
{
	void *ret = realloc(ptr, size);
	if (ret == NULL)
		err(1, "realloc");
	return ret;
}

static inline char *xstrdup(const char *str)
{
	char *ret = strdup(str);
	if (ret == NULL)
		err(1, "strdup");
	return ret;
}

#ifdef __cplusplus
}
#endif

#endif
