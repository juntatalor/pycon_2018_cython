def parse_resp(f):
    b = f.read(1)

    if b == b'*':
        data = f.readline()
        l = int(data[:-2])
        arr_res = []
        for i in range(l):
            arr_res.append(parse_resp(f))
        return arr_res

    if b == b'+':
        data = f.readline()
        return data[:-2]

    elif b == b'-':
        data = f.readline()
        raise Exception(data[:-2])

    elif b == b':':
        data = f.readline()
        return int(data[:-2])

    elif b == b'$':
        data = f.readline()
        l = int(data[:-2])
        data = f.read(l)
        f.readline()
        return data
