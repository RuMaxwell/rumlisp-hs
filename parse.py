import os
import re
from sys import argv

def regexReplaceAll(regex: str, s: str, replaceFunc):
  pattern = re.compile(regex)
  return re.sub(pattern, replaceFunc, s)


def readFile(fn):
  content = None
  with open(fn, 'r') as f:
    content = foldl(lambda acc, s: acc + s, '', f.readlines())
  return content


def preprocess(s: str):
  # (import 'env' ...) => (let (***) ...)
  # `...` is syntax request
  pat = re.compile(r'\(import\s+(?P<envname>[A-Za-z0-9_!@#$%^&\-=~][A-Za-z0-9_!@#$%^&\-=~]*)')
  matches = re.findall(pat, s)
  if len(matches) > 0:
    for match in matches: # `match` is a `str` here
      fname = match + '.rlib'
      content = readFile(fname)
      hpt = content.partition('...')
      s = re.sub(pat, hpt[0], s)
      # Complement parentheses
      s += re.findall(re.compile(r'(\)+)'), hpt[2])[-1][1:]
      return preprocess(s) # Recursively resolve imports
  return s


def parse(s: str):
  s = preprocess(s)

  # remove comments
  def remcmts(matched) -> str:
    return ''
  s = regexReplaceAll(r'(\{.*\})', s, remcmts)

  s = s.strip()

  # [ \t\n\r]+ => ','
  def ws2comma(matched) -> str:
    return ','
  s = regexReplaceAll(r'(?P<ws>[ \t\n\r]+)', s, ws2comma)

  # [A-Za-z_][A-Za-z0-9_?!]* => SBind "..."
  def iden2SBind(matched) -> str:
    iden = matched.group("iden")
    return 'SBind "%s"' % iden
  s = regexReplaceAll(r'(?P<iden>[A-Za-z_?!@#$%^&*\-+=/\\~:|][A-Za-z0-9_?!@#$%^&*\-+=/\\~:|]*)', s, iden2SBind)
  # s = regexReplaceAll(r'(?P<iden>[A-Za-z_][A-Za-z0-9_]*)', s, iden2SBind)

  # [0-9]+ => SInt ...
  def int2SInt(matched) -> str:
    ints = matched.group("int")
    return 'SInt %s' % ints
  s = regexReplaceAll(r'(?P<int>\d+)', s, int2SInt)

  # ( => 'SExp [', ) => ']'
  s = s.replace('(', 'SExp [')
  s = s.replace(')', ']')

  return s


def repl():
  expr = input("rlsp> ")
  s = parse(expr)
  os.system('@echo %s | rlsp.exe' % repr(s)[1:-1])


def foldl(f, acc, s: list):
  """`foldl :: (b -> a -> b) -> b -> [a] -> b`"""
  return acc if len(s) == 0 else foldl(f, f(acc, s[0]), s[1:])


def main():
  if len(argv) > 1:
    if argv[1] == 'i':
      print(repr(parse(argv[2]))[1:-1])
    else:
      content = readFile(argv[1])
      if content is not None:
        print(repr(parse(content))[1:-1])
  else:
    repl()

if __name__ == "__main__":
  main()
