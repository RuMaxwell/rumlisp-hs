function y(gen) {
  return (function(g) {
    return g(g)
  })(function(f) {
    return function(args){
      return gen(f(f))(args)
    }
  })
}

var fact = y(function (fac) {
  return function (n) {
    return n <= 0 ? 1 : n * fac(n - 1)
  }
})

console.log(fact(6))
