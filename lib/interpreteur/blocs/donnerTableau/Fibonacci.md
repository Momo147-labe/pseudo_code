fonction Fibonacci(n: entier) : entier
variables
  i, a, b, c : entier
Début
  si n = 0 alors
    Fibonacci <- 0
  sinon si n = 1 alors
    Fibonacci <- 1
  sinon
    a <- 0
    b <- 1
    pour i de 2 a n faire
      c <- a + b
      a <- b
      b <- c
    finPour
    Fibonacci <- b
  finSi
finfonction
