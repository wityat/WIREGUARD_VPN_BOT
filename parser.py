import re
import sys

with open(sys.argv[1], "r") as f:
    s = f.read()
    res = re.findall(r"AllowedIPs = 10.0.0.(\d+)", s)

print(int(res[-1]) + 1)
