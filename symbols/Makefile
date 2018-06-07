LIBS = $(wildcard */)
SRCS = $(wildcard */*.src)
SYMS = $(SRCS:%.src=%.sym)

all: $(SYMS)

$(SYMS): %.sym: %.src
	tragesym $< $@
