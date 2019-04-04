import os
import re
from sys import argv

def regexReplaceAll(regex: str, s: str, replaceFunc):
  pattern = re.compile(regex)
  return re.sub(pattern, replaceFunc, s)


def preprocess(s: str):
  # (import 'env' ...) => (let (***) ...)
  # `...` is syntax request
  if s.startswith('(import'):
    s.split(' ')[1]


def parse(s: str):
  # [ \t\n\r]+ => ','
  def ws2comma(matched) -> str:
    return ','
  # s = regexReplaceAll(r'(?P<iden>[A-Za-z_?!@#$%^&*\-+=/\\~][A-Za-z0-9_?!@#$%^&*\-+=/\\~]*)', s, iden2SBind)
  s = regexReplaceAll(r'(?P<ws>[ \t\n\r]+)', s, ws2comma)

  # [A-Za-z_][A-Za-z0-9_?!]* => SBind "..."
  def iden2SBind(matched) -> str:
    iden = matched.group("iden")
    return 'SBind "%s"' % iden
  # s = regexReplaceAll(r'(?P<iden>[A-Za-z_?!@#$%^&*\-+=/\\~][A-Za-z0-9_?!@#$%^&*\-+=/\\~]*)', s, iden2SBind)
  s = regexReplaceAll(r'(?P<iden>[A-Za-z_][A-Za-z0-9_]*)', s, iden2SBind)

  # [0-9]+ => SInt ...
  def int2SInt(matched) -> str:
    ints = matched.group("int")
    return 'SInt %s' % ints
  s = regexReplaceAll(r'(?P<int>\d+)', s, int2SInt)

  # ( => 'SExp [', ) => ']'
  s = s.replace('(', 'Exp [')
  s = s.replace(')', ']')

  return s


def repl():
  expr = input("rlsp> ")
  s = parse(expr)
  os.system('@echo "%s" > rumlsp.exe' % repr(s))


def foldl(f, acc, s: list):
  """`foldl :: (b -> a -> b) -> b -> [a] -> b`"""
  return acc if len(s) == 0 else foldl(f, f(acc, s[0]), s[1:])


def main():
  if len(argv) > 1:
    if argv[1] == 'i':
      print(parse(argv[2]))
    else:
      with open(argv[1], 'r') as f:
        content = foldl(lambda acc, s: acc + s, '', f.readlines())
        print(parse(content))
  else:
    repl()

if __name__ == "__main__":
  main()
