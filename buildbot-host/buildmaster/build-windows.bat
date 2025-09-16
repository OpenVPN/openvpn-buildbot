set VCPKG_ROOT_BAK=%VCPKG_ROOT%
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
set VCPKG_ROOT=%VCPKG_ROOT_BAK%
cmake --preset %1
cmake --build --preset %1 --parallel=4
