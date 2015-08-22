---
layout: post
title: Introduction to functional programming with Haskell
date: 2015-08-21
categories: Haskell tutorials
---


*   [The interactive Haskell compiler](#overview)
*   [Notation for functional programs](#lambda)
*   [Defining new symbols, functions and modules](#io)
*   [Pattern matching](#pattern)
*   [Datatypes](#data)

<a id="overview" /> </a>
## The interactive Haskell compiler, GHCi  

In the following we will see an example interactive session with GHCi, to familiarize the reader with the notation and some fundamental concepts of the language. Some familiarity with programming concepts and mathematical notation is required, but the tutorial is intended to be as self-contained as possible (All feedback is very welcome!).

The `>`character at the start of a line indicates the interpreter prompt, whereas `:t` is the GHCi macro for requesting the _type_ of an expression.

If we input an expression that already has a value associated, GHCi computes and prints the expression value on the next line.
If, on the other hand, we ask for the type of an expression `x` with `:t x`, the interpreter outputs this after a double colon. 

N.B.: In function bodies, parentheses are used to group subexpressions that must be evaluated first (as per convention).

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

> If a type is an "instance" of a typeclass such as `Num`, the corresponding functions to operate "numerically", e.g. sum, product, absolute value etc., can be used on data objects belonging to it. Equivalently, by making it an instance of `Num`, we have "stapled" additional numerical functionality onto our type. More about this deep idea in the next sections.

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

> Why `Floating a` and not `Num a`, for instance? Because `Num` is the most general typeclass of numbers (i.e including fractionals, integers, floats etc.), but transcendental numbers (i.e. having infinite decimal digits) such as `pi` and `exp 1` live in a "smaller" set, that is, require a more specialized definition.


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


# Higher order functions, partial application, operator sections

A versatile list-digesting function is `filter`: 

{% highlight haskell %}

> :t filter
filter :: (a -> Bool) -> [a] -> [a]

> filter (> 2) [-1,3,0,10,9,-4]
[3,10,9]

> filter (/= 'x') "xxxjgxkjg" 
"jgkjg"
 
{% endhighlight %}

`filter` is our first example of _higher order function_; it requires as arguments a _function_ of type `a -> Bool` and a list of `a`s and returns the subset of the input list that verifies the filtering function.

In the previous code block, we also see the first examples of _operator section_:
`(> 2)` and `(/= 'x')`, passed as first argument to `filter`. 
The ordering relation `(>)` is a binary operator (since it compares two values and returns True or False), but `(> 2)` takes only one argument and returns a Boolean. Instead, `(/= 'x')` compares its only argument to the constant character `'x'`.


The following examples should clarify the idea:

{% highlight haskell %}
:t (+)
(+) :: Num a => a -> a -> a

> :t (==)
(==) :: Eq a => a -> a -> Bool
 
> :t (+ 1)
(+ 1) :: Num a => a -> a

> :t (== 2)
(== 2) :: (Num a, Eq a) => a -> Bool
 
{% endhighlight %}


The arithmetic sum `(+)` and equality comparison `(==)` functions require two parameters, but fixing the first one to e.g. a constant is equivalent to considering functions of the remaining number of arguments. This is an instance of _partial evaluation_, ubiquitous in Haskell and very powerful.


> Haskell functions are "curried" by default. This means that N-ary functions (functions of N arguments) can be considered as taking arguments in sequence, rather than all at once.

> This enables _partial evaluation_, i.e. creating new functions of fewer arguments by fixing some in the original function.

> This fundamental tool has many different uses, for example specializing a general function in a few different ways, by introducing very little additional syntax as we will see in the next sections.

Operator sections are just shorthand for partial application of infix operators; however the usual caveats for non-commutative functions such as arithmetic division `/` apply; as the following snippet shows for numbers, ".. over two" and "two over .." have clearly different meanings.

{% highlight haskell %}
> (/2) 3
1.5

> (2/) 3
0.6666666666666666
{% endhighlight %}



Other useful higher-order functions that operate on lists are `map` and `foldr`:


{% highlight haskell %}
> :t map
map :: (a -> b) -> [a] -> [b]

> :t foldr
foldr :: (a -> b -> b) -> b -> [a] -> b
 
{% endhighlight %}


`map` can be interpreted right from its signature: given a function from `a` to `b`, and a list of `a`s, it returns a list of `b`s, obtained by applying the function to every element of the input array.

`foldr` is a right-to-left `fold`; it requires a binary function say `f`, an initial element of type `b` (the "accumulator") and a list of `a`s, and recursively applies `f` to the accumulator and the current first element of the remaining list. For example:

{% highlight haskell %}
> foldr (+) 3 [1,4,10,24]
42
{% endhighlight %}

We will see the implementation of `map`, `foldr` and of a few other essential library functions in the following.

It is very instructive to have a look at the [Haskell Prelude](https://hackage.haskell.org/package/base-4.8.0.0/docs/src/GHC-Base.html), the core library of the language.



# Recap

Whew! In this introductory section we have alread seen quite a few new concepts: 

* types
* classes of types (a.k.a. _typeclasses_ `Num`, `Floating`, `Eq`, `Ord` ...)
* higher order functions
* partial application, operator sections

The aim with this tutorial is to develop a working knowledge of functional programming using Haskell as a vessel language; this (unfortunately) requires one to digest a certain number of new ideas, and to get acquainted with the terminology to describe them.

In the following sections we will expand on and give examples for all the terms introduced so far (and a few more ..), and in a few pages the reader will be able to produce her first working programs !

--------
--------
<a id="lambda" /></a>
## Notation for functional programs


> Anonymous expressions (often called "lambda" functions) let us define what a function _does_, and to separate this from what we choose to call it.

They often are used as single-use functions, if a certain functionality is too specific to be given a name; the pattern is `\ x -> f x`, in which what lies to the left of the arrow is the set of free variables (separated by spaces if more than one), and what lies to the right is an arbitrarily complex function of these and other variables (this might be read "for any given _x_, give me the result of function _f_ applied on _x_", or $$\forall x, f(x)$$

The actual syntax to be used in the free variable declaration is a backslash, but it is often pretty-printed (e.g. in Computer Science and Logic textbooks) as a Greek lambda character, as a reminder of its origins in Church's Lambda Calculus.

Two elementary examples of lambda expressions could be:

{% highlight haskell %}
> :t \ x -> 2 * x
\ x -> 2 * x :: Num a => a -> a

> :t \ x y -> x + y
\ x y -> x + y :: Num a => a -> a -> a
{% endhighlight %}

We should note that, in the snippet above, the Num constraint is introduced by `(*)` and `(+)`.

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

> As the first example above shows, __some function arguments are inferred to be functions by how they are used in the body__ of the (anonymous) function. 

> Functions as "first class values" (i.e. that can be used and passed around just like regular values) are one of the defining features of functional programming languages, and it is fundamental to absorb this concept early.

As an example, we can apply the ``squared'' function to an arbitrary value:

{% highlight haskell %}

> ($) (\ x -> x^2) 0.98
0.9603999999999999

{% endhighlight %}






# Function composition 

What does it mean to "compose functions"? If we think of a function as a machine on a factory floor, feeding the output of one (_g_, say)  into the input of the next (which we can call _f_) is a form of composition. This of course only works if the _f_ is designed to work on the outputs of _g_ (you wouldn't want to plug a grinder to an Easter egg packaging machine, for example).

The _composition_ of _f_ and _g_, written `f . g` in Haskell and  $$f \circ g$$ in mathematical literature, is itself a function, taking `g`'s input type and returning `f`'s result type. It's as if we welded the two machines together, and obtained a new, more complex machine as a result. 

Here is a nested function application pattern, and below it the type signature of the corresponding library function `(.)`:

{% highlight haskell %}
> :t \ f g x -> f (g x)
\ f g x-> f (g x) :: (b -> c) -> (a -> b) -> a -> c

> :t (.)
(.) :: (b -> c) -> (a -> b) -> a -> c
{% endhighlight %}

> In the example above `g x` is first evaluated, and its result is passed on to `f`, which explains the type signature: its first function argument `f` takes entities from set `b` and maps them onto the output set `c`, whereas `g` operates on the input domain `a` and ranges over `b`.

> Lambda expressions allow us to conveniently explore functional manipulation constructs. 

> The Haskell Prelude and the other built-in libraries come with a rich library of synonyms, such as `(.)` and `($)` shown above, and lets us define and use our own, as soon as the need for abstraction arises.







# Partial evaluation

When calling functions in Haskell, you don't have to "fill all the slots", i.e. supply all the arguments; this is called _partial evaluation_ (or _application_).

As explained briefly in the first section, the result of this is a new function, having a smaller number of arguments than the original one.

In the following we will see a few more examples of this from a slightly abstract point of view, in order not to lose sight of the pattern amid the implementation details.

{% highlight haskell %}

> let f1 = \ f g x y -> f (g x) (g y)

> :t f1
f1 :: (b -> b -> c) -> (a -> b) -> a -> a -> c

{% endhighlight %}

In the example above we first define a function `f1` of four arguments; in the next lines we specialize `f1` to use the sum or ordering relation `(<)` as "external" functions `f`. The "internal" function `g` is instead meant to be separately applied on the operands `x` and `y`:

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

(my parentheses on the right hand side). Both `f2` and the library function `flip` return the input binary function but with exchanged order of arguments:

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

> :t (2 *)
(2 *) :: Num a => a -> a
{% endhighlight %}



# Examples 

Let's try together a few of the things we've see so far: anonymous functions, partial application, the higher order function `map :: (a -> b) -> [a] -> [b]`, and operate on a list-of-lists for the first time:

{% highlight haskell %}
> let testData = [[1,2],[23452,24,515,0],[2351661]]

> let listShorterThan m = (\x -> length x < m)

> :t listShorterThan
f :: Int -> [a] -> Bool

> map (listShorterThan 4) testData
[True,False,True]
{% endhighlight %}



As an appetizer for more abstract things ,let us recall the right-fold function `foldr`, and see it partially applied to the function composition operator `(.)`:

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

and, since `map` is a binary function accepting a _function_ and a list, we can identify equal terms. In the line above, if we partially apply `(.) map` on `map`, `x` is identified with a function and `y` has to be a list, resulting in the initial type identity.


<a id="io"> </a>
## Defining new symbols, functions and modules

When in the interactive mode (or, equivalently, while we are working within the IO monad, more details in the following), we need the `let` construct, which behaves very much like its mathematical counterpart:


{% highlight haskell %}

> let a = pi / 2

> a
1.5707963267948966

> let f x = if x=='o' then 'i' else x

> :t f
f :: Char -> Char

> map f "potatoes"
"pitaties"
 
{% endhighlight %}

In bulk code, there is no need for `let` for declaring a new entity; if we write the following in a blank text file named, say, `TestModule.hs` :

{% highlight haskell %}
-- If the prompt is not present, we assume to be working in a `.hs` text file, 
-- to be loaded in GHCi.

{- 
The `--` token at the start of a line specifies a comment: 
the line as a whole is not interpreted as Haskell code. 
Multiple-line comments are enclosed in a `{-`,  `-}` pair.
-}
module TestModule where

f1 = (^2)

v = [2,3,4]

main = do
  putStrLn $ map f1 v
{% endhighlight %}

and load it with GHCi (from command line: `ghci TestModule.hs`), calling `main` will print `[4,9,16]` to screen.

> In the previous code snippet we start to see one of Haskell's strength points: a clean separation of input-output ("IO") and purely functional code. 
> The first line is a function, the second a piece of data, and the `main` function runs the example (in this case `map`ping the squaring function over the data) and displays on-screen the results as a newline-terminated string with `putStrLn`.

The `main` function effectively "coordinates" the execution of the purely functional parts; its body is a `do` block, to signify that it is to be executed top-to-bottom. However the intermediate results are only effectively computed when requested (this is the _non-strict_, or _lazy_ evaluation logic of Haskell). In the code above, `f1` is `map`ped over `v` only when `putStrLn` is run.

We will return on how to write `do` blocks (the "imperative" part of Haskell) shortly. At this point we still need to see a few general features of the language syntax.


<a id="pattern" /></a>
## Pattern matching
# Recursive functions

> Haskell allows multiple declarations of any function, that are applied according to the arguments; this of course can hold only if the type signatures match and the declarations are mutually exclusive and complementary.

As an example, this is the implementation of `map`:

{% highlight haskell %}
map f [] = []
map f (x:xs) = f x : map f xs
{% endhighlight %}

The above code recursively consumes the list supplied as second argument by applying `f` to its first element and appending the result (with `(:)`) to the output array. The first declaration is used if the supplied list is empty, which also holds at the base case of the recursion.

> A _fold_ operation is to obtain a "summary" value from a set of values.

The right-associative fold (`foldr`) is defined recursively as:

{% highlight haskell %}
foldr f z []     = z
foldr f z (x:xs) = f x (foldr f z xs)
{% endhighlight %}

One of the most famous examples of Haskell conciseness is this implementation of the QuickSort algorithm:

{% highlight haskell %}
qsort [] = []
qsort (x:xs) = qsort l ++ [x] ++ qsort r where
   l = filter (< x) xs
   r = filter (> x) xs
{% endhighlight %}

The first element of the unsorted list is chosen as pivot (This choice of pivoting means that this naive version of QuickSort will be suboptimal for partially sorted inputs.) and the remaining elements are filtered (cost _O (N)_) and passed to the next level of recursive call. 

> The three examples above all use _pattern matching on the constructor_ of the input data, i.e. if the input is the empty list, the base case is computed, otherwise (list with at least one element `x`) the algorithm takes the induction branch.

We can apply the same reasoning to user-made types (which will be explained in the following Section):

{% highlight haskell %}
data Pop a = Z | P a
data Pip a = W | Q a

woop Z = W
woop (P x) = Q r where
  r = 2 * x
{% endhighlight %}

and, after loading the above code in GHCi:

Above we have used two _algebraic, polymorphic types_ `Pop a` and `Pip a` and a function that pattern matches on each constructor of the input data type.

{% highlight haskell%}
> :t woop
woop :: Num a => Pop a -> Pip a
{% endhighlight %}

# Pattern guards 

One form of conditional branching statement is the _pattern guard_:

{% highlight haskell %}
oddness x
   | odd x = sx ++ " is odd"
   | otherwise = sx ++ " is even"
       where
         sx = show x

buzz x 
   | f || g  = 0             -- (||) is the logical OR operation
   | even x = 1
   | otherwise = 2 
       where
         f = x `mod` 7 == 0
         g = x < 20
{% endhighlight %}

The options (expressions after `|`) are evaluated in top-to-bottom order, and the last one is only evaluated if none of the previous ones evaluates to `True`.

Pattern guards are convenient syntax for deciding which conditional branch to take according to the _value_ contained in one or more of the input variables. Note that the functions acting as pattern guards (e.g. `odd x`, `f || g`) have to return a Boolean, and only after the `=` sign do we specify the return value for each branch.

> Quiz: what are the type signatures of `oddness` and `buzz` and why ? 

<a id="data"/> </a>
## Datatypes
# Record notation, constructor as a function

We can specify datatypes (which remind of structs in C) with the `data` keyword, as shown in the following examples.
(Also `newtype` can be used in the same fashion as `data`, for datastructures that have a single constuctor, but the difference between the two keywords is a bit technical and will not be discussed here.)

{% highlight haskell %}
> data TypeA = MakeA { unA :: Int } deriving Show

> :t MakeA
MakeA :: Int -> TypeA

> :t unA
unA :: TypeA -> Int
{% endhighlight %}

The constructor (`MakeA`, in this case) is a function; we build a data "object" by passing the appropriate arguments to it and whenever we need the values stored inside, we just call the appropriate accessor method (`unA`, in the example), using the data object as its argument :

{% highlight haskell %}
> let test1 = MakeA 597

> test1
MakeA {unA = 597}

> :t test1
test1 :: TypeA

> unA test1
597
{% endhighlight %}

Within the curly brackets we can specify a number of "records" to hold values; however these are not simple data fields but also declare the accessor functions to retrieve them.

> Haskell provides the machinery to augment our datatypes, by making them "instances" of standard classes such as `Show` above. 
If a datatype is an instance of one or more classes, it "inherits" the functionality of that class, so in the present example making `TypeA` an instance of `Show` lets us print `TypeA` objects on screen.

N.B.: if we hadn't made `TypeA` an instance of `Show`, the evaluation of `test1` would have returned a "No instance for (Show TypeA) ... " error, instead.

Let's declare a slightly larger datatype constructor and try out its accessor functions:


{% highlight haskell %}
> data Test = Tee { h1 :: [(Bool, String)], h2 :: Char }

> :t Tee
Tee :: [(Bool, String)] -> Char -> Test


> let test2 = Tee [(True, "boop")] 'x'

> (snd . head . h1) test2
"boop"

> h2 test2
'x'
{% endhighlight %}

In the above example, we have declared a `Test` datatype with constructor `Tee` and two records, the first of which is of a composite type, and created a `test2` object of this type.

Next, we access an internal field in a purely functional style, by composition of elementary functions. This idea of functional manipulation of "getter"/"setter" methods for nested datastructure is called _lensing_, and it is implemented (and greatly expanded) in a few packages such as [lens](https://hackage.haskell.org/package/lens), which however is beyond the scope of this tutorial.

> What happens if we supply an integer to the Tee constructor, instead of the expected list of `(Bool, String)` tuples? Our first type error! <3

{% highlight haskell %}
> :t Tee 2

<interactive>:1:5:
   No instance for (Num [(Bool, String)]) arising from the literal '2'
   In the first argument of 'Tee', namely '2'
   In the expression: Tee 2
{% endhighlight %}

> The second line, "In the first argument of 'Tee'", is the hint!

# Type synonyms

The keyword `type` is reserved to declare transparent type synonyms (i.e. that are internally re-written into their elementary types at compile time). Let's see a few examples: 

{% highlight haskell %}
> type Name = String

> type Address = (String, Int)

> type Contact = (Name, Address)

> type Directory = [Contact]
{% endhighlight %}

> Type synonyms let us describe the problem domain more accurately, and enforce consistency among the functions using them.

# A worked example

We now show a slightly longer example, a sketch of customer database application with query functions. The code captures the situation of having an array of structured data and having to take a decision based on some computation performed on each entry. Here we aim to display together a few of the syntactic elements shown so far, in a not-too-contrived setting.

{% highlight haskell %}
type NameStr = String
type AddrStr = String
type AddrN = Int
data Address = A {addressStr :: AddrStr,
                  houseNo :: AddrN} deriving (Show, Eq)
                                                   
data Name = N {nameStr :: NameStr} deriving (Show, Eq)

data Contact = C {name :: Name,
                  addr :: Address} deriving (Show, Eq)

houseNoContact = houseNo . addr
nameContact = nameStr . name
addressContact = addressStr . addr
{% endhighlight %}

A query method `deliver` : if the house number is within range, return `True`

{% highlight haskell %}
deliver nMax nMin c
  | inRange (houseNoContact c) = True
  | otherwise = False where
       inRange m = abs (nMax - nMin) > abs (m - nMin)
{% endhighlight %}

or, more concisely: 

{% highlight haskell %}
deliver' nMax nMin c = abs (nMax - nMin) > abs (houseNoContact c - nMin)
{% endhighlight %}

> Quiz: what is the type signature of `deliver'` and why?

Partial application of both `deliver` and `filter` : 

{% highlight haskell %}
todaysDeliveries n1 n2 = filter (deliver n1 n2)
{% endhighlight %}

We can now load the previous code snippet in GHCi and see the signature of today's delivery list, mapping from two house numbers and a list of contacts to the subset of the original contact list whose house number lies within the range.

{% highlight haskell %}
> :t todaysDeliveries
todaysDeliveries :: AddrN -> AddrN -> [Contact] -> [Contact]
{% endhighlight %}

> Haskell uses a _decidable_ type system (the Hindley-Milner system) which allows the type-checking algorithm to always terminate without the user having to supply type annotations; in the above example we see the utility of this: using partial application wisely, we can achieve the desired signature function very concisely.

> Concise code has very far-reaching implications, besides just "looking clever": it greatly simplifies reasoning, checking for correctness, refactoring and knowledge propagation. This is one of the many examples in which Haskell's theoretical foundations have very practical advantages.

For instance, imagine having one day to update the matching criterion, i.e. the function `deliver` in our case; it's a single line change, and as long as the types match, the whole code will still be correct.

An example data entry for the delivery example above:

{% highlight haskell %}
name1 = N "John Doe"
addr1 = A "Potato St." 42
contact1 = C name1 addr1

> :t contact1
contact1 :: Contact
{% endhighlight %}

# Algebraic types

We have already seen an instance of an algebraic datatype (ADT): `Bool` can have two mutually exclusive values.

{% highlight haskell %}
> data Bool = True | False

> data PS = Tri | Cir | Sqr | Crs
{% endhighlight %}


# Polymorphic types
Polymorphic types can be thought of as a labeled scaffolding for more elementary types; in the following example we show how the constructor `Pt a a` can be specialized to cater for various needs:

{% highlight haskell %}
> data Point a = Pt a a

> :t Pt 2 3 
Pt 2 3 :: Num a => Point a

> :t Pt 'c' 'd'
Pt 'c' 'd' :: Point Char

> let inside p1 p2 = let normP (Pt x y) = x^2 + y^2 in normP p1 < normP p2 

> :t inside
inside :: (Ord a, Num a) => Point a -> Point a -> Bool
{% endhighlight %}

A simple polymorphic datatype to represent a computation that can fail is `Maybe a`:

{% highlight haskell %}
> data Maybe a = Nothing | Just a
{% endhighlight %}

For example, we can implement a simple "safe division", as follows

{% highlight haskell %}
safeDiv a b
  | b /= 0 = Just ( a/b )
  | otherwise = Nothing 

> :t safeDiv
safeDiv :: (Eq a, Fractional a) => a -> a -> Maybe a
{% endhighlight %}

> The `Maybe a` type is a simple way to treat _errors as values_, and to perform further computation on them, rather than letting the program fail and stop. 

# Recursive types 

Next, we introduce a handy binary tree type `Tree a`, which can be either a "leaf" `L` carrying a type `a`, i.e. `L a`, or a "branch" `B` carrying two `Tree a`'s.

{% highlight haskell %}
> data Tree a = L a | B (Tree a) (Tree a) deriving Show

> :t L
L :: a -> Tree a

> :t B
B :: Tree a -> Tree a -> Tree a

> let leaf1 = L 15
 
> let leaf2 = L 27
 
> B leaf1 leaf2
B (L 15) (L 27)
{% endhighlight %}

Trees have very convenient asymptotic performance for search and sorting operations, and they are naturally suited to be traversed with recursive logic in Haskell.

{% highlight haskell %}
{% endhighlight %}