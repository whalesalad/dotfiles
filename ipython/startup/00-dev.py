import os
import sys

py3 = sys.version_info[:3] > (3, 0)
path_to_dev = os.environ.get('DEV_MODULE', 'service.dev')


print(path_to_dev)

if py3:
    import importlib

    try:
        dev = importlib.import_module(path_to_dev)
        globals().update(vars(dev))
    except ModuleNotFoundError as e:
        print(f'Exception while loading DEV_MODULE: {e!r}')
        pass

# Python 2
else:
    # this is a hack
    parts = path_to_dev.split('.')
    module = __import__(path_to_dev, globals=globals(), fromlist=parts[0])
    globals().update(vars(module))
