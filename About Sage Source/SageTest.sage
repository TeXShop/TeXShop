import sys
sys.path.insert(0, '/Applications/sage')
import sagetex
sagetex.openout('SageTest')
try:
 sagetex.inline(0, 32^31)
except:
 sagetex.goboom(23)
try:
 sagetex.initplot('SageTest')
 sagetex.plot(0, plot(x * sin( 30 * x), -1, 1), format='notprovided', epsmagick=False)
except:
 sagetex.goboom(27)
try:
 sagetex.inline(1, integrate( (x^2 + x + 1) / ((x - 1)^3 * (x^2 + x + 2)) ))
except:
 sagetex.goboom(31)
try:
 sagetex.inline(2, matrix([[1, 2, 3], [4, 5, 6], [7, 8, 9]])^3)
except:
 sagetex.goboom(36)
try:
 sagetex.inline(3, Matrix([[1, 2], [3, 4]]))
except:
 sagetex.goboom(38)
try:
 sagetex.inline(4, Matrix([[5, 6], [6, 8]]))
except:
 sagetex.goboom(38)
try:
 sagetex.inline(5, Matrix([[1, 2], [3, 4]]) * Matrix([[5, 6], [6, 8]]))
except:
 sagetex.goboom(38)
try:
 sagetex.initplot('SageTest')
 sagetex.plot(1, plot(x * ln(x), 0, 2), format='notprovided', epsmagick=False)
except:
 sagetex.goboom(42)
try:
 sagetex.inline(6, pi * e)
except:
 sagetex.goboom(46)
try:
 sagetex.inline(7, N(pi * e))
except:
 sagetex.goboom(46)
sagetex.endofdoc()
