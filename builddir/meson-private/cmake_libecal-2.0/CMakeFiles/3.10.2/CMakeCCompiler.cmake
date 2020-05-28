# Fake CMake file to skip the boring and slow stuff
set(CMAKE_C_COMPILER "/usr/bin/cc") # Should be a valid compiler for try_compile, etc.
set(CMAKE_C_COMPILER_LAUNCHER "") # The compiler launcher (if presentt)
set(CMAKE_C_COMPILER_ID "GNU") # Pretend we have found GCC
set(CMAKE_COMPILER_IS_GNUCC 1)
set(CMAKE_C_COMPILER_LOADED 1)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_C_ABI_COMPILED TRUE)
set(CMAKE_C_SOURCE_FILE_EXTENSIONS c;m)
set(CMAKE_C_IGNORE_EXTENSIONS h;H;o;O;obj;OBJ;def;DEF;rc;RC)
set(CMAKE_SIZEOF_VOID_P "8")
