provide *
provide-types *

import global as _
import base as _

data Tree:
  | mt
  | tree(n :: Number, l :: Tree, r :: Tree)
end
