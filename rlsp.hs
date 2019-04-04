data Value = VInt Int | VClos Closure deriving Show

data Binding = Binding { bname :: String, bvalue :: Value } deriving Show
type Env = [Binding]

data Closure = Closure
  { bindName :: String
  , bindExp :: SExp
  , closure :: Env
  } deriving Show

data SExp = SInt Int | SBind String | SExp [SExp] deriving (Read, Show)

-- instance Show SExp where
--   show (SInt x) = show x
--   show (SBind x) = x
--   show (SExp xs) = show xs


emptyEnv :: Env
emptyEnv = []

extEnv :: String -> Value -> Env -> Env
extEnv x v = (Binding x v :)

lookUp :: String -> Env -> Maybe Binding
lookUp _ [] = Nothing
lookUp x (b:bs) = if x == bname b then Just b else lookUp x bs

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
    _ -> error $ "calling to non-callable object " ++ show v1
-- (op e1 e2)
interp (SExp [SBind op, e1, e2]) env =
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
      _ -> error $ "undefined operator " ++ op
    _ -> error $ "applying operator " ++ op ++ " on improper values"
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
