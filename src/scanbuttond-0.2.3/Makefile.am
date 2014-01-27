SUBDIRS = contrib interface backends scripts .

pkgsysconfdir = $(sysconfdir)/$(PACKAGE)

bin_PROGRAMS = scanbuttond
scanbuttond_SOURCES = scanbuttond.c lib/loader.c include/scanbuttond/backend.h include/scanbuttond/scanbuttond.h include/scanbuttond/common.h
scanbuttond_LDFLAGS = -ldl

INCLUDES = $(all_includes) -I$(top_builddir)/include -I.
