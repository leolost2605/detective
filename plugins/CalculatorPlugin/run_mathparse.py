#!/usr/bin/env python

import sys
from mathparse import mathparse

result = mathparse.parse (sys.argv[1])
print (result)
