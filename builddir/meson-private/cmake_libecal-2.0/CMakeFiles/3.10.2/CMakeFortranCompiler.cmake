# Fake CMake file to skip the boring and slow stuff
set(CMAKE_Fortran_COMPILER "/home/alain/.local/lib/python3.6/site-packages/mesonbuild/cmake/executor.py") # Should be a valid compiler for try_compile, etc.
set(CMAKE_Fortran_COMPILER_LAUNCHER "") # The compiler launcher (if presentt)
set(CMAKE_Fortran_COMPILER_ID "GNU") # Pretend we have found GCC
set(CMAKE_COMPILER_IS_GNUG77 1)
set(CMAKE_Fortran_COMPILER_LOADED 1)
set(CMAKE_Fortran_COMPILER_WORKS TRUE)
set(CMAKE_Fortran_ABI_COMPILED TRUE)
set(CMAKE_Fortran_IGNORE_EXTENSIONS h;H;o;O;obj;OBJ;def;DEF;rc;RC)
set(CMAKE_Fortran_SOURCE_FILE_EXTENSIONS f;F;fpp;FPP;f77;F77;f90;F90;for;For;FOR;f95;F95)
set(CMAKE_SIZEOF_VOID_P "8")
