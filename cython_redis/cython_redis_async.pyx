# distutils: language = c++

from libcpp.string cimport string
from libcpp.vector cimport vector

import asyncio

from collections import deque

cdef bytes SYM_STAR = b'*'
cdef bytes SYM_DOLLAR = b'$'
cdef bytes SYM_CRLF = b'\r\n'


cdef class RedisError(Exception):
    pass

cdef inline bytes _encode_int(int value):
    return b'%d' % value


cdef class RedisProtocol:

    """
    Пример работы с Cython + Asyncio.Protocol
    """

    cdef:
        object _loop
        # Асинхронная обертка над буфером
        object _reader
        # Asyncio.Transport для работы с сетью
        object _transport
        # Очередь запросов. Ответы будут приходить в том же порядке
        object _queue

    def __init__(self, loop):
        self._loop = loop

        self._reader = None
        self._transport = None
        self._queue = deque()

    cpdef void connection_made(self, object transport):
        print('Connection with Redis established')
        self._transport = transport
        self._reader = asyncio.StreamReader(loop=self._loop)
        self._reader.set_transport(transport)

        asyncio.ensure_future(self._reader_coroutine())

    cpdef void data_received(self, bytes data):
        self._reader.feed_data(data)

    cdef void _send_command(self, vector[string] args):
        cdef list data = [SYM_STAR, _encode_int(len(args)), SYM_CRLF]

        for arg in args:
            data += [SYM_DOLLAR, _encode_int(len(arg)), SYM_CRLF, arg, SYM_CRLF]

        print(data)
        self._transport.write(b''.join(data))

    async def query(self, vector[string] args):
        cdef object result

        self._send_command(args)
        result = asyncio.Future()
        self._queue.append(result)

        return await result

    async def _reader_coroutine(self):
        """
        Корутина, которая читает входящие данные и сопоставляет их с запросами пользователя
        :return:
        """

        cdef object answer, result

        print('Start reader coroutine')

        while True:
            result = await self._handle_item()

            answer = self._queue.popleft()
            if isinstance(result, Exception):
                answer.set_exception(result)
            else:
                answer.set_result(result)

    async def _handle_item(self):
        cdef bytes c = await self._reader.readexactly(1)

        if c == b'+':
            return await self._handle_str()
        elif c == b'-':
            return await self._handle_error()
        elif c == b':':
            return await self._handle_int()
        elif c == b'$':
            return await self._handle_binary()
        elif c == b'*':
            return await self._handle_array()

    async def _handle_str(self):
        cdef bytes l = await self._reader.readline()
        return l.rstrip(b'\r\n')

    async def _handle_int(self):
        cdef bytes l = await self._handle_str()
        return int(l)

    async def _handle_error(self):
        cdef bytes l = await self._handle_str()
        return RedisError(l)

    async def _handle_binary(self):
        cdef int length = await self._handle_int()
        cdef bytes data

        if length == -1:
            return None
        else:
            data = await self._reader.readexactly(length)
            # skip trailing CRLF
            await self._reader.readline()
            return data.rstrip(b'\r\n')

    async def _handle_array(self):
        cdef int length = await self._handle_int()

        result = []
        for _ in range(length):
            result.append(await self._handle_item())

        return result

cdef class RedisConnection:

    cdef:
        str _host
        int _port
        object _loop
        RedisProtocol _protocol

    def __init__(self, str host = 'localhost', int port = 6379, object loop=None):
        self._host = host
        self._port = port
        self._loop = loop or asyncio.get_event_loop()

        self._protocol = RedisProtocol(loop=self._loop)

    async def connect(self):
        await self._loop.create_connection(lambda: self._protocol,
                                           host=self._host, port=self._port)

    async def ping(self):
        return await self._protocol.query([b'PING'])

    async def set(self, bytes k, bytes v):
        return await self._protocol.query([b'SET', k, v])

    async def mget(self, *keys):
        return await self._protocol.query([b'MGET'] + list(keys))
