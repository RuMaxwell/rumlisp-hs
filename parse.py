import os
import re
from sys import argv

sourcePath = ''


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
  # `...` is syntax request.
  # Subdirectory is allowed.
  pat = re.compile(r'\(import\s+(?P<envname>[A-Za-z0-9_!@#$%^&\-=~][A-Za-z0-9_!@#$%^&\-=~/]*)')
  matches = re.findall(pat, s)
  if len(matches) > 0:
    # for match in matches: # `match` is a `str` here
    i = 0
    while i < len(matches):
      match = matches[i]
      fname = '%s/%s.rlib' % (sourcePath, match)
      content = ''
      try:
        content = readFile(fname).strip()
      except FileNotFoundError as _:
        print('IMPORT: no such file: %s' % fname)
        exit(1)
        return s
      hpt = content.partition('...')
      s = re.sub(pat, hpt[0], s, 1).strip()
      # Complement parentheses
      s += re.findall(re.compile(r'(\)+)'), hpt[2])[-1][1:]
      i += 1
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
    # Because re.sub matches non-overlapping patterns, so in case that the substituted string is:
    #   '(op,1,2)'
    # one substitution will just yield
    #   '(op,.1,2)'
    # The latter number is neglected because ',1,' is overlapped with ',2)'.
    # So we should use ', ' instead of ',' to generate non-overlapping matches.
    return ', '
  s = regexReplaceAll(r'(?P<ws>\s+)', s, ws2comma)

  # Fore-convertion of numbers
  # Use a non-identifier character to prefix numbers.
  # This is to prevent identifiers containing digits be converted to such like "xSInt 1".
  def prefixNum(matched) -> str:
    number = matched.group('number')
    return number[0] + '.%s' % number[1:]
  s = regexReplaceAll(r'(?P<number>[(\s,]\-?\d+[\s),])', s, prefixNum)

  # [A-Za-z_][A-Za-z0-9_?!]* => SBind "..."
  def iden2SBind(matched) -> str:
    iden = matched.group('iden')
    return iden[0] + 'SBind "%s"' % iden[1:-1] + iden[-1]
  s = regexReplaceAll(r'(?P<iden>[(\s,][A-Za-z_?!@#$%^&*\-+=<>/\\~:|][A-Za-z0-9_?!@#$%^&*\-+=<>/\\~:|]*[\s),])', s, iden2SBind)

  # ( => 'SExp [', ) => ']'
  s = s.replace('(', 'SExp [')
  s = s.replace(')', ']')

  # [0-9]+ => SInt ...
  def int2SInt(matched) -> str:
    ints = matched.group('int')
    return 'SInt (%s)' % ints[1:]
  s = regexReplaceAll(r'(?P<int>\.\-?\d+)', s, int2SInt)

  return s


def repl():
  expr = ''
  while True:
    expr = input("rlsp> ")
    if expr == '(quit)':
      break
    s = parse(expr)
    os.system('@echo %s | rlsp.exe' % repr(s)[1:-1])


def foldl(f, acc, s: list):
  """`foldl :: (b -> a -> b) -> b -> [a] -> b`"""
  return acc if len(s) == 0 else foldl(f, f(acc, s[0]), s[1:])


def main():
  global sourcePath
  sourcePath = os.path.dirname(__file__)
  if len(argv) > 1:
    if argv[1] == 'i':
      print(repr(parse(argv[2]))[1:-1])
    else:
      content = readFile(argv[1])
      sourcePath = os.path.dirname(argv[1])
      if content is not None:
        print(repr(parse(content))[1:-1])
  else:
    repl()

if __name__ == "__main__":
  main()
