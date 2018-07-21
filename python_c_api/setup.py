from distutils.core import setup, Extension

# Вызываем:
# python3 setup.py build_ext
# Затем нужно не забыть скопировать so-файл в место, где Питон сможет его импортировать
# Например: cp build/lib.macosx-10.13-x86_64-3.6/sin_module.cpython-36m-darwin.so .
# >>> import sin_module
# >>> sin_module.sin_func(3.1415)
# 9.265358966049024e-05

sin_module = Extension('sin_module', sources=['sinfunc.c'])

setup(ext_modules=[sin_module])
