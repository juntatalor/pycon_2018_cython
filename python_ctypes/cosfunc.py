import ctypes

from ctypes.util import find_library

libm = ctypes.cdll.LoadLibrary(find_library('m'))

libm.cos.argtypes = [ctypes.c_double]
libm.cos.restype = ctypes.c_double


def cos_func(arg):
    return libm.cos(arg)
