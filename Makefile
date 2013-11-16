CC      = gcc
CFLAGS  = -O2 -std=c89 -Wall -Wextra -Wpedantic \
          -Wswitch-enum -Wwrite-strings -Wcast-qual -Wc++-compat -Wshadow
LDFLAGS = -shared
LUA     = lua
MKDIR   = mkdir -p
INSTALL = install -p -m 0644
INSTALLX= install -p -m 0755
RM      = rm -f
PREFIX  = /usr/local
LUAVER  = 5.1
LUADIR  = $(PREFIX)/share/lua/$(LUAVER)
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)
DYNLIB  = cgumbo.so
PRINTF  = :

GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)
GUMBO_HEADER  = $(shell pkg-config --variable=includedir gumbo)/gumbo.h

all: $(DYNLIB)

$(DYNLIB): gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

gumbo/cdef.lua: $(GUMBO_HEADER) clean-header.sed
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[' > $@
	@sed -f clean-header.sed $(GUMBO_HEADER) | sed '/^$$/N;/^\n$$/D' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

tags: gumbo.c $(GUMBO_HEADER)
	ctags --c-kinds=+p $^

install: all | gumbo/cdef.lua gumbo/ffi.lua gumbo/init.lua
	$(MKDIR) '$(DESTDIR)$(LUACDIR)' '$(DESTDIR)$(LUADIR)/gumbo'
	$(INSTALLX) $(DYNLIB) '$(DESTDIR)$(LUACDIR)'
	$(INSTALL) $| '$(DESTDIR)$(LUADIR)/gumbo'

uninstall:
	$(RM) '$(DESTDIR)$(LUACDIR)/$(DYNLIB)'
	$(RM) -r '$(DESTDIR)$(LUADIR)/gumbo'

check: export LGUMBO_USE_FFI=0
check: all test.lua
	@$(PRINTF) '$@' 'LUA=$(LUA)  CC=$(CC)'
	@LUA_PATH='./?.lua' LUA_CPATH='./?.so;;' $(RUNVIA) $(LUA) test.lua

check-ffi: export LGUMBO_USE_FFI=1
check-ffi: clean test.lua
	@$(PRINTF) '$@' 'LUA=$(LUA) '
	@LUA_PATH='./?.lua' $(RUNVIA) $(LUA) test.lua

check-valgrind: RUNVIA = valgrind -q --leak-check=full --error-exitcode=1
check-valgrind: check

check-all: export LGUMBO_DEBUG=1
check-all: V = PRINTF="printf '%-10s %-25s'"
check-all:
	@$(MAKE) -s clean check CC=gcc $(V)
	@$(MAKE) -s clean check CC=clang $(V)
	@$(MAKE) -s clean check CC=tcc CFLAGS=-Wall $(V)
	@$(MAKE) -s clean check LUA=luajit $(V)
	@$(MAKE) -s check-ffi LUA=luajit $(V)
	@# Uses LuaFFI:
	@$(MAKE) -s check-ffi LUA=lua $(V)

clean:
	$(RM) $(DYNLIB) gumbo.o

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

.PHONY: all install uninstall check check-ffi check-valgrind check-all clean
.DELETE_ON_ERROR:
