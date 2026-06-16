# Windows Lua Toolchain (MSYS2 UCRT64)
# Build root can live anywhere, default: C:\Lua

BUILD_ROOT    ?= /c/Lua
BUILD_ROOT_WIN := $(shell cygpath -m "$(BUILD_ROOT)")
SRC_DIR       := $(BUILD_ROOT)/src
LUA_VERSIONS  := 5.4.8
LUAROCKS_VER  := 3.13.0

all: download unpack build luarocks

verify:
	@echo "==> Verifying checksums"
	@cd "$(SRC_DIR)" && sha256sum -c $(CURDIR)/checksums.sha256

download:
	@echo "==> Downloading sources (if needed)"
	@./download.sh "$(SRC_DIR)"

define UNPACK_RULE
$(SRC_DIR)/lua-$(1)/src/lua.c: $(SRC_DIR)/lua-$(1).tar.gz
	@echo "==> Unpacking Lua $(1)"
	tar xf "$(SRC_DIR)/lua-$(1).tar.gz" --force-local -C "$(SRC_DIR)"
	touch $$@
endef

$(foreach v,$(LUA_VERSIONS),$(eval $(call UNPACK_RULE,$(v))))

unpack: $(foreach v,$(LUA_VERSIONS),$(SRC_DIR)/lua-$(v)/src/lua.c)

define BUILD_RULE
$(BUILD_ROOT)/$(1)/bin/lua.exe: $(SRC_DIR)/lua-$(1)/src/lua.c
	@echo "==> Building Lua $(1)"
	$$(MAKE) -C "$(SRC_DIR)/lua-$(1)" PLAT=mingw
	$$(MAKE) -C "$(SRC_DIR)/lua-$(1)" install INSTALL_TOP=$(BUILD_ROOT)/$(1)
	@for f in "$(SRC_DIR)/lua-$(1)/src"/lua5*.dll; do [ -f "$$$$f" ] && cp "$$$$f" "$(BUILD_ROOT)/$(1)/bin/"; done; true
	touch $$@
endef

$(foreach v,$(LUA_VERSIONS),$(eval $(call BUILD_RULE,$(v))))

build: $(foreach v,$(LUA_VERSIONS),$(BUILD_ROOT)/$(v)/bin/lua.exe)

$(BUILD_ROOT)/.luarocks-stamp: $(SRC_DIR)/luarocks-$(LUAROCKS_VER)-windows-64.zip
	@echo "==> Unpacking LuaRocks"
	unzip -o "$(SRC_DIR)/luarocks-$(LUAROCKS_VER)-windows-64.zip" -d "$(BUILD_ROOT)"
	@for v in $(LUA_VERSIONS); do \
		cp "$(BUILD_ROOT)/luarocks-$(LUAROCKS_VER)-windows-64/luarocks.exe" "$(BUILD_ROOT)/$$v/bin/"; \
		cp "$(BUILD_ROOT)/luarocks-$(LUAROCKS_VER)-windows-64/luarocks-admin.exe" "$(BUILD_ROOT)/$$v/bin/"; \
		vshort=$$(echo $$v | cut -d. -f1-2); \
		mkdir -p "$(BUILD_ROOT)/$$v/luarocks"; \
		echo "lua_version = \"$$vshort\"" > "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "lua_dir = \"$(BUILD_ROOT_WIN)/$$v\"" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "variables.LUA_BINDIR = \"$(BUILD_ROOT_WIN)/$$v/bin\"" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "variables.CC = \"$$(cygpath -m $$(which x86_64-w64-mingw32-gcc))\"" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "variables.LD = \"$$(cygpath -m $$(which x86_64-w64-mingw32-gcc))\"" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "variables.LDFLAGS = \"-lucrtbase\"" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		echo "rocks_trees = { \"$(BUILD_ROOT_WIN)/$$v\" }" >> "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua"; \
		mkdir -p "$(BUILD_ROOT)/$$v/lib/luarocks/rocks-$$vshort" "$(BUILD_ROOT)/$$v/share/lua/$$vshort"; \
		conf_dir=$$(cygpath -u "$$APPDATA")/luarocks; \
		mkdir -p "$$conf_dir"; \
		cp "$(BUILD_ROOT)/$$v/luarocks/config-$$vshort.lua" "$$conf_dir/"; \
	done
	rm -rf "$(BUILD_ROOT)/luarocks-$(LUAROCKS_VER)-windows-64"
	touch "$@"

luarocks: $(BUILD_ROOT)/.luarocks-stamp

clean:
	@for v in $(LUA_VERSIONS); do \
		test -d "$(SRC_DIR)/lua-$$v" && $(MAKE) -C "$(SRC_DIR)/lua-$$v" clean || true; \
	done

distclean:
	rm -rf $(foreach v,$(LUA_VERSIONS),"$(SRC_DIR)/lua-$(v)")

.PHONY: all download unpack build luarocks clean distclean verify
