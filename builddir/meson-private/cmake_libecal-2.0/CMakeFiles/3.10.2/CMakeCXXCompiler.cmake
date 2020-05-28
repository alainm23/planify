# Fake CMake file to skip the boring and slow stuff
set(CMAKE_CXX_COMPILER "/usr/bin/c++") # Should be a valid compiler for try_compile, etc.
set(CMAKE_CXX_COMPILER_LAUNCHER "") # The compiler launcher (if presentt)
set(CMAKE_CXX_COMPILER_ID "GNU") # Pretend we have found GCC
set(CMAKE_COMPILER_IS_GNUCXX 1)
set(CMAKE_CXX_COMPILER_LOADED 1)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_CXX_ABI_COMPILED TRUE)
set(CMAKE_CXX_IGNORE_EXTENSIONS inl;h;hpp;HPP;H;o;O;obj;OBJ;def;DEF;rc;RC)
set(CMAKE_CXX_SOURCE_FILE_EXTENSIONS C;M;c++;cc;cpp;cxx;mm;CPP)
set(CMAKE_SIZEOF_VOID_P "8")
