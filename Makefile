GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)

CC      = gcc
CFLAGS  = -O2 -Wall -Wextra -std=c99 -pedantic $(GUMBO_CFLAGS)
LDFLAGS = -shared $(GUMBO_LDFLAGS)
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

gumbo.so: gumbo.o
	$(CC) $(LDFLAGS) -o $@ $<

gumbo.o: gumbo.c compat.h

tags: gumbo.c compat.h $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

docs: config.ld gumbo.c README.md example.lua test.lua
	@ldoc -c $< -d $@ .
	@sed -ie 's|<a href="http://www.lua.org/manual/5.1/manual.html#pdf-type">type</a> :|<code>type</code>:|' docs/topics/README.md.html
	@touch $@

install: gumbo.so
	mkdir -p $(DESTDIR)$(LUACDIR)
	install -pm0755 gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	rm -f $(DESTDIR)$(LUACDIR)/gumbo.so

check: gumbo.so test.lua
	@lua test.lua

clean:
	rm -f gumbo.so gumbo.o tags
	rm -rf docs


.PHONY: install uninstall check clean
