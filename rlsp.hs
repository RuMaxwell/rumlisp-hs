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
lookUp x (b:bs) = if x == b then b else lookUp x bs

kwLambda = "\\"
kwLet = "let"

interp :: SExp -> Env -> Value
interp (SInt x) _ = VInt x
interp (SBind x) env = let b = lookUp x env in case b of
  (Just (Binding x v)) -> v
interp (SExp [SBind kwLambda, SBind p, exp]) = VClos $ Closure p env exp
interp (SExp [SBind kwLet, SExp [SBind bn, be], exp]) =
  let bv = interp be env
  in interp exp (extEnv bn bv env)
interp (SExp [e1, e2]) =
  let v1 = interp e1 env
      v2 = interp e2 env
  in case v1 of
    (VClos (Closure p fe fenv)) -> interp fe $ extEnv p v2 fenv
    _ -> error "calling to non-callable object " ++ show v1
interp (SExp [SBind op, e1, e2]) =
  let v1 = interp e1 env
      v2 = interp e2 env
  in case (v1, v2) of
    (VInt x, VInt y) -> case op of
      "+" -> VInt $ x + y
      "-" -> VInt $ x - y
      "*" -> VInt $ x * y
      "/" -> VInt $ x `div` y
      "=" {- Required import 'boolean' -} -> if x == y then true else false
        where true = interp (SBind "#t") env
              false = interp (SBind "#f") env
    _ -> error "applying operator " ++ op ++ " on improper values"

run :: SExp -> Int
run s = let v = interp s emptyEnv in case v of
  (VInt x) -> x
  (VClos x) -> error "expression yielding closure " ++ x


main = do
  sexp <- getLine
  let (VInt x) = run sexp
  print x
