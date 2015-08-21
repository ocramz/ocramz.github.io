---
layout: post
title: Introduction to functional programming with Haskell
date: 2015-08-21
categories: Haskell, tutorials
---

## The interactive Haskell interpreter, GHCi

In the following we show an example interactive session with GHCi, to familiarize the reader with the notation and some fundamental concepts of the language. Only a minimal familiarity with programming concepts and mathematical notation is required.

The `>`character at the start of a line indicates the interpreter prompt, whereas `:t` is the GHCi macro for requesting the type of an expression.

If the prompt is not present, we assume to be working in a `.hs` text file, to be loaded in GHCi.

The `--` token at the start of a line specifies a comment: the line as a whole is not interpreted as Haskell code. Longer comments are enclosed in `{-  -}`


If we input an expression that already has a value associated, GHCi computes and prints the expression value on the next line.
If, on the other hand, we ask for the type of an expression `x` with `:t x`, the interpreter outputs this after a double colon. 


Each example builds on the previous one, starting from self-explanatory concepts; 
the reader is encouraged to install the latest version of the [Glasgow Haskell Compiler suite](http://www.haskell.org/ghc) suite and try/modify the examples, in the given order; it's much more fun and instructive than just reading through!


For those in a hurry, [ghc.io](http://ghc.io) provides a "safe" Haskell prompt to e.g. try out one-liners. Longer code can be developed (after a free signup) on [FPComplete Haskell Center](https://www.fpcomplete.com/business/fp-haskell-center/).

--------
# First steps with GHCi

Starting from the very basics : 

{% highlight haskell %}
> 1 + 2
3

> :t 1
1 :: Num a => a

{% endhighlight %}

The two interactions above show an _evaluation_ and a _type query_, respectively. The former, being a constant expression, evaluates directly to its result (no surprises here), whereas the latter could be understood as "What is the type of `1`?" "The type of `1` is `a`, such that `a` is an instance of a numerical type (i.e. a number)."

The actual letter indicating a type in a signature, like `a` in the previous example, does not matter; distinct letters correspond to different types. 

> Why is the type signature of something as simple as a number so verbose? 
> Because many things have number-like properties (can be counted, added, subtracted etc.): potatoes, firemen, structs containing arrays of CSV files, etc. 

> Making a new type an instance of a class such as `Num` hints the programmer to provide the corresponding functions to operate "numerically" on it.

Let's interact some more with the interpreter and see what happens:

{% highlight haskell %}
> :t pi
pi :: Floating a => a

> pi
3.141592653589793

> exp 1
2.718281828459045

> :t exp
exp :: Floating a => a -> a
{% endhighlight %}


The exponential `exp` is a function of a single parameter (a real number, here represented as a `Floating` point value): $$y(x) = e ^ x,\; x,y \in \mathbb{R}$$ 



# Text characters, strings and lists


{% highlight haskell %}
> :t 'a'
'a' :: Char

> :t "potato"
"potato" :: [Char]
{% endhighlight %}

Single characters are to be enclosed in single forward quotes whereas text strings require double quotes. Internally, strings are represented as arrays of characters, so the above example becomes `['p','o','t','a','t','o']`.

Lists can contain any valid type of data, making them a very versatile tool:

{% highlight haskell %}
> :t [1,2,3]
[1,2,3] :: Num t => [t]

> :t [1 ..]
[1 ..] :: (Num t, Enum t) => [t]

{% endhighlight %}

> Lists can be infinite in length (thus it is more appropriate to describe them as _streams_). Among the many other library functions, e.g. `take`, `drop` and `filter` let us query or pick out elements from streams.

N.B.: if you actually decide to evaluate an infinite stream such as `[1 ..]`, be prepared to interrupt it! (Control-C terminates the execution of a command in Unix-like systems).

The `take` function, as the name implies, takes a few sequential elements from an array (i.e. outputs the first _n_ elements of the array, where _n_ is an integer number):

{% highlight haskell %}
> :t take
take :: Int -> [a] -> [a]

> take 7 [5 ..]
[5,6,7,8,9,10,11]

{% endhighlight %}

> Function application such as `exp 1` and `take 7 [5..]` is so fundamental that Haskell uses a space to denote it, i.e. considering `f x y z`, `f` is the function and `x`, `y` and `z` are its arguments.

Let us now look at `filter`: 

{% highlight haskell %}

> :t filter
filter :: (a -> Bool) -> [a] -> [a]

> filter (>2) [-1,3,0,10,9,-4]
[3,10,9]

> filter (/= 'x') "xxxjgxkjg" 
"jgkjg"
 
{% endhighlight %}

`filter` is our first example of {\itshape higher order function}; it requires as arguments a _function_ of type `a -> Bool` and a list of `a`s and returns the subset of the input list that verifies the filtering function.

In the previous code block, we also see the first example of _operator section_:
`(> 2) :: (Ord a, Num a) => a -> Bool`, passed as first argument to `filter`. 
The ordering relation `(>)` is a binary operator (since it compares two values and returns True or False), but `(> 2)` takes only one argument and returns a Boolean.

The following examples should clarify the idea:

{% highlight haskell %}
:t (+)
(+) :: Num a => a -> a -> a

> :t (==)
(==) :: Eq a => a -> a -> Bool
 
> :t (+ 1)
(+1) :: Num a => a -> a

> :t (== 2)
(== 2) :: (Num a, Eq a) => a -> Bool
 
{% endhighlight %}


The arithmetic sum `(+)` and equality comparison `(==)` functions require two parameters, but fixing the first one to e.g. a constant is equivalent to considering functions of the remaining number of arguments. This is an instance of _partial evaluation_, ubiquitous in Haskell and very powerful.


> Haskell functions are "curried" by default. This means that N-ary functions (functions of N arguments) can be considered as taking arguments in sequence.

> This enables _partial evaluation_, i.e. creating new functions of fewer arguments by fixing some in the original function.

> This fundamental tool has many different uses, for example specializing a general function in a few different ways, by introducing very little additional syntax as we will see in the next sections.


Other useful higher-order functions that operate on lists are `map` and `foldr`:


{% highlight haskell %}
> :t map
map :: (a -> b) -> [a] -> [b]

> :t foldr
foldr :: (a -> b -> b) -> b -> [a] -> b
 
{% endhighlight %}


`map` can be interpreted right from its signature: given a function from `a` to `b`, and a list of `a`s, it returns a list of `b`s, obtained by applying the function to every element of the input array.\\
`foldr` is a right-to-left `fold`; it requires a binary function say `f`, an initial element of type `b` (the "accumulator") and a list of `a`s, and recursively applies `f` to the accumulator and the current first element of the remaining list. For example:

{% highlight haskell %}
> foldr (+) 3 [1,4,10,24]
42
{% endhighlight %}

We will see the implementation of `map`, `foldr` and other functions in the following

It is very instructive to have a look at the [Haskell Prelude](https://hackage.haskell.org/package/base-4.8.0.0/docs/src/GHC-Base.html), the core library of the language.




--------
--------
## Notation for functional programs

> Anonymous expressions (often called "lambda" expressions) let us define what a function _does_, and to separate this from what we choose to call it.

They often are used as single-use functions, if a certain functionality is too specific to be given a name; the pattern is `\ x -> f x`, in which what lies to the left of the arrow is the set of free variables (separated by spaces if more than one), and what lies to the right is an arbitrarily complex function of these and other variables (this might be read "for any given _x_, give me the result of function _f_ applied on _x_", or $$\forall x, f(x)$$

The actual syntax to be used in the free variable declaration is a backslash, but it is often pretty-printed (e.g. in Computer Science and Logic textbooks) as a Greek lambda character, as a reminder of its origins in Church's Lambda Calculus.

Two elementary examples of lambda expressions could be:

{% highlight haskell %}
> :t \ x -> 2 * x
\ x -> 2 * x :: Num a => a -> a

> :t \ x y -> x + y
\ x y -> x + y :: Num a => a -> a -> a
{% endhighlight %}

We should note that, in the snippet above, the Num constraint is introduced by `(*2)` and `(+)`.

In the following, we will implement a few useful functions using only lambda expressions, to demonstrate their versatility and to introduce some key concepts.

# The Identity function

This one is pretty self explanatory:

{% highlight haskell %}

> :t \ x -> x
\ x -> x :: a -> a

> :t id
id :: a -> a
 
{% endhighlight %}


# Function application
If the body of the lambda expression contains function application syntax, we can easily re-create _higher order functions_, as shown below:

{% highlight haskell %}

> :t \ f x -> f x
\ f x -> f x :: (a -> b) -> a -> b

> :t ($)
($) :: (a -> b) -> a -> b
 
{% endhighlight %}
The library function `($)` captures the function application pattern shown in the definition above it.

> As the first example above shows, some function arguments are _inferred to be functions_ by how they are used in the body of the lambda expression. 

> Functions as "first class values" (i.e. that can be used and passed around just like regular values) are one of the defining features of functional programming languages, and it is fundamental to absorb this concept early.

As an example, we can apply the ``squared'' function to an arbitrary value:

{% highlight haskell %}

> ($) (\ x -> x^2) 0.98
0.9603999999999999

{% endhighlight %}






# Function composition 

Here is a nested function application pattern, and below it the type signature of the corresponding library function:

{% highlight haskell %}
> :t \ f g x -> f (g x)
\ f g x-> f (g x) :: (b -> c) -> (a -> b) -> a -> c

> :t (.)
(.) :: (b -> c) -> (a -> b) -> a -> c
{% endhighlight %}

> Parentheses are used to group subexpressions that must be evaluated first.

> In the example above `g x` is first evaluated, and its result is passed on to `f`, which explains the type signature of `(.)`: its first function argument `f` takes entities from set `b` and maps them onto the output set `c`, whereas `g` operates on the input domain `a` and ranges over `b`.

> Lambda expressions allow us to conveniently explore functional manipulation constructs. 

> The Haskell Prelude and the other built-in libraries come with a rich library of synonyms, such as `(.)` and `($)` shown above, and lets us define and use our own, as soon as the need for abstraction arises.







# Partial evaluation

{% highlight haskell %}

> let f1 = \ f g x y -> f (g x) (g y)

> :t f1
f1 :: (b -> b -> c) -> (a -> b) -> a -> a -> c

{% endhighlight %}

In the example above we first define a function `f1` of four arguments; in the next line we specialize `f1` to use the sum or ordering relation `(<)` as "external" functions `f`. The "internal" function `g` is instead meant to be separately applied on the operands `x` and `y`:

{% highlight haskell %}
> :t f1 (+)
f1 (+) :: Num b => (a -> b) -> a -> a -> b

> :t f1 (+) (^2) 
f1 (+) (^2) :: Num a => a -> a -> a

> :t f1 (<)
f1 (<) :: Ord b => (a -> b) -> a -> a -> Bool

> :t f1 (<) exp
f1 (<) exp :: (Ord a, Floating a) => a -> a -> Bool
{% endhighlight %}

The expressions `f1 (+)`, `f1 (<)` and `f1 (<) exp` are examples of _partial application_; the resulting expression is itself a function with a reduced number of arguments than the original one.

The higher-order function `f2` accepts three arguments, the first of which is a binary function; however if we just supply one argument, the result will be itself a binary function: 

{% highlight haskell %}
> :t \f2 x y -> f2 y x
\f2 x y -> f2 y x :: (a -> b -> c) -> b -> a -> c
 
> :t flip
flip :: (a -> b -> c) -> (b -> a -> c)
{% endhighlight %}

(my parentheses on the rhs). Both `f2` and the library function `flip` return the input binary function but with exchanged order of arguments:

{% highlight haskell %}
> let pow = (^)

> :t pow
pow :: (Num a, Integral b) => b -> a -> a
 
> pow 2 3
9

> let wop = flip pow

> :t wop
wop :: (Num a, Integral b) => a -> b -> a
 
> wop 2 3
8

{% endhighlight %}






# Eta-conversion

Dropping or adding an abstraction over a variable to an expression are termed "eta-reduction" and "eta-abstraction", respectively.
The following two expressions are identical, in this sense; the latter being the eta-reduced version of the former.

{% highlight haskell %}
> :t \ x -> 2 * x
\ x -> 2 * x :: Num a => a -> a

> :t (*2)
(*2) :: Num a => a -> a
{% endhighlight %}



# Examples 

Let us recall the right-fold function `foldr`, and see it partially applied to the function composition operator `(.)`:

{% highlight haskell %}
> :t foldr
foldr :: (a -> b -> b) -> b -> [a] -> b

> :t foldr (.)
foldr (.) :: (a -> b) -> [b -> b] -> a -> b

> :t foldr (.) id
foldr (.) id :: [a -> a] -> a -> a
{% endhighlight %}

The last example above shows a very intuitive way to represent an arbitrary chain of function compositions: starting from the identity function `id` and using `(.)` as cumulating operator, `foldr (.) id` requires an arbitrary _list of functions_ and an initial input value, at which point it can compute the result of the composite function. It is also useful to note that introducing `id` makes the input and output types coincide.

Another interesting little example is the following:

{% highlight haskell %}
> :t map . map
map . map :: (a -> b) -> [[a]] -> [[b]] 
{% endhighlight %}

A composition of `map`s is equivalent to _lifting_ an `(a -> b)` function to work onto lists of lists. Neat! We can easily prove this, by considering the composition operator `(.)` in infix position and plugging in the definitions;

{% highlight haskell %}
> :t (.) map
(.) map :: (x -> y -> z) -> x -> [y] -> [z]
{% endhighlight %}

and, since `map` is a binary function accepting a _function_ and a list, we can identify equal terms. In the line above, if we partially apply `(.) map` on `map`, `x` is identified with a function and `y` has to be a list, resulting in the initial identity.

{% highlight haskell %}

{% endhighlight %}