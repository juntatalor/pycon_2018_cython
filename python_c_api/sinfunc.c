
#include <Python.h>
#include <math.h>

static PyObject* sin_func(PyObject* self, PyObject* args)
{
    double value;
    double answer;

    if (!PyArg_ParseTuple(args, "d", &value))
        return NULL;

    answer = sin(value);

    return Py_BuildValue("f", answer);
}

static PyMethodDef SinMethods[] =
{
     {"sin_func", sin_func, METH_VARARGS, "sin evaluation"},
     {NULL, NULL, 0, NULL}
};


static struct PyModuleDef cModPyDem =
{
    PyModuleDef_HEAD_INIT,
    "sin_module", "Some documentation",
    -1,
    SinMethods
};

PyMODINIT_FUNC
PyInit_sin_module(void)
{
    return PyModule_Create(&cModPyDem);
}
