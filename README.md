# windows-lua-build

Build Lua (5.4) from source under MSYS2 UCRT64, with LuaRocks. Works from plain cmd.exe after build.

## Build

```cmd
scoop install msys2
git clone https://github.com/scillidan/windows-lua-build
cd windows-lua-build
"%SCOOP%\apps\msys2\current\msys2_shell.cmd" -ucrt64 -defterm -here -no-start
```

```sh
# Requirements
pacman -Sy mingw-w64-ucrt-x86_64-gcc make unzip

# Build
mkdir -p /c/Lua
make all BUILD_ROOT=/c/Lua
# Custom build root
make all BUILD_ROOT=/d/Lua
```

It will download Lua and LuaRocks, compiles, and generates `config-$version.lua`.

```sh
exit
```

## Post-install

Add the following into PATH:

```
C:\Lua\5.4.8
C:\Lua\5.4.8\bin
```

Open a new cmd window, run `luarocks path --bin`, then use `setx` with each value from the output:

```cmd
setx LUA_PATH "C:\Lua\5.4.8\share\lua\5.4\?.lua;C:\Lua\5.4.8\share\lua\5.4\?\init.lua;..."
setx LUA_CPATH "C:\Lua\5.4.8\lib\lua\5.4\?.dll;..."
```

Open another new cmd window:

```cmd
lua -v
luarocks --version
lua -e "print('ok')"
```

## LuaRocks C modules

Installing rocks with native C code needs the MSYS2 GCC. Create a `.cmd` wrapper in a directory already in your `PATH`:

```cmd
@echo off
set "BASE=%SCOOP%\apps\msys2\current\ucrt64"
set "PATH=%BASE%\bin;%PATH%"
set "LIBRARY_PATH=%BASE%\lib;%BASE%\x86_64-w64-mingw32\lib"
set "C_INCLUDE_PATH=%BASE%\include"
"C:\Lua\5.4.8\bin\luarocks.exe" %*
```

Verify:

```cmd
luarocks.cmd install luasocket
rem set "TEMP=C:\Temp" && set "TMP=C:\Temp" && luarocks.cmd install luasocket
luarocks list
```