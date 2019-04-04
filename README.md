# rumlisp-hs
A Lisp dialect, with Haskell-interpreter and Python-preprocessor. Features expanding.

### Features
```
[+] Types
    [+] Numeric types
        Int
        -- Integer, Float [, Char]
    [ ] Basic functional types
        -- String [, Enum, Tuple], List [, Array]
    [ ] Combined types
        -- Union type and intersection type
    [ ] User-defined data types
        -- Object, arithmetic data type, record type
[+] Typing system
    [+] Dynamic, strong
        [*] Runtime simple type-checking
        [ ] Type inference
        [ ] Type synonym
[+] Functions
    [*] One-argument lambda function
    [ ] Multiple-argument lambda function (can be implemented by macros)
    [ ] Named-function
        [ ] Self-recursive function
    [*] Closure (enabling lexical-scoping)
    [*] Function as data
        [*] First-order function
        [*] Function passed as value
    [*] Types of a function
        [*] Dynamic argument types (Int or Lambda)
        [*] Dynamic evaluation type (Int or Lambda)
        [*] Dynamic function
[+] Macros
    [*] Environment import
        Simple model substitution mechanism, which enables importing environment (`let` bindings) from multiple files.
    [ ] User-defined syntax
        -- Powerful code generator. Produce endless fun and flexibility.
[*] Characteristics
    [*] Immutable data
    [*] Functional programming
```
