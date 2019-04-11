data Value = VInt Int | VClos Closure deriving Show

data Binding = Binding { bname :: String, bvalue :: Value } deriving Show
type Env = [Binding]

data Closure = Closure
  { bindName :: String
  , bindExp :: SExp
  , closure :: Env
  } deriving Show

data SExp = SInt Int | SBind String | SExp [SExp] deriving Read

instance Show SExp where
  show (SInt x) = show x
  show (SBind x) = x
  show (SExp xs) = show xs


emptyEnv :: Env
emptyEnv = []

extEnv :: String -> Value -> Env -> Env
extEnv x v = (Binding x v :)

lookUp :: String -> Env -> Maybe Binding
lookUp _ [] = Nothing
lookUp x (b:bs) = if x == bname b then Just b else lookUp x bs


errNonCallable :: Value -> String
errNonCallable obj = "calling on non-callable object `" ++ show obj ++ "`"

builtInOps :: [String]
builtInOps = ["+", "-", "*", "/", "=", "!=", ">", "<", ">=", "<="]


interp :: SExp -> Env -> Value
-- 1
interp (SInt x) _ = VInt x
-- x
interp (SBind x) env = let b = lookUp x env in case b of
  Nothing -> error $ "failed to find binding '" ++ x ++ "'"
  (Just (Binding x v)) -> v
-- (1) | (x)
interp (SExp [x]) env = interp x env -- This rule does not apply when functions can have no parameter.
-- (let bn be exp)
interp (SExp [SBind "let" {-YOU CAN ONLY use constant here!!!! An identifier will be treated as a binding name-}
  , SBind bn, be, exp]) env =
  let bv = interp be env
  in interp exp (extEnv bn bv env)
-- (\ p exp)
interp (SExp [SBind "\\" {-YOU CAN ONLY use constant here!!!!-}, SBind p, exp]) env = VClos $ Closure p exp env
-- (e1 e2)
interp (SExp [e1, e2]) env =
  let v1 = interp e1 env
      v2 = interp e2 env
  in case v1 of
    (VClos (Closure p fe fenv)) -> interp fe $ extEnv p v2 fenv
    _ -> error $ errNonCallable v1
-- Function call
interp (SExp (fe:ps)) env = case fe of
  (SInt x) -> error $ errNonCallable $ VInt x
  (SBind op) -> if op `elem` builtInOps then
    let {- true, false: required import 'boolean' -}
        true = interp (SBind "#t") env
        false = interp (SBind "#f") env
        opf :: String -> Value -> Value -> Value
        opf "+" (VInt x) (VInt y) = VInt $ x + y
        opf "-" (VInt x) (VInt y) = VInt $ x - y
        opf "*" (VInt x) (VInt y) = VInt $ x * y
        opf "/" (VInt x) (VInt y) = VInt $ x `div` y
        opf "="  {- for lib 'boolean' -} (VInt x) (VInt y) = if x == y then true else false
        opf "!=" {- for lib 'boolean' -} (VInt x) (VInt y) = if x /= y then true else false
        opf ">"  {- for lib 'boolean' -} (VInt x) (VInt y) = if x > y then true else false
        opf "<"  {- for lib 'boolean' -} (VInt x) (VInt y) = if x < y then true else false
        opf "<=" {- for lib 'boolean' -} (VInt x) (VInt y) = if x <= y then true else false
        opf ">=" {- for lib 'boolean' -} (VInt x) (VInt y) = if x >= y then true else false
        opf o x y = error $ "applying operator " ++ op ++ " on improper values `" ++ show x ++ "` and `" ++ show y ++ "`"
        vs = map (`interp` env) ps
    in foldl1 (opf op) vs
    else interp (foldl (\ exp arg -> SExp [exp, arg]) fe ps) env
  _ -> interp (foldl (\ exp arg -> SExp [exp, arg]) fe ps) env
  {- foldl :: (b -> a -> b) -> b -> [a] -> b
    ps = [f, a0, a1, ...]
    res = interp (SExp [SExp [SExp [f, a0], a1], ...]) env
  -}
interp _ _ = error "invalid syntax"


-- TODO: This implementation does not allow recursion by directly invoking a bind name of the lambda function.
-- TODO: Should add a new method of defining recursive function, otherwise writing recurses will always require Y-combinator.

run :: SExp -> Int
run s = let v = interp s emptyEnv in case v of
  (VInt x) -> x
  (VClos x) -> error $ "expression yielding closure " ++ show x


main = do
  sexp <- getLine
  let x = run $ read sexp
  print x
