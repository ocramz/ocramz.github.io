---
layout: post
title: Purely-functional reverse-mode automatic differentiation with delimited continuations
date: 2021-07-19
categories: Haskell automatic-differentiation machine-learning Scala
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered its "natural" implementation.

I will first "read aloud" the reference Scala implementation from the original paper [1], and then do the same for the corresponding parts of a Haskell library I've written that implements its ideas, [ad-delcont](https://hackage.haskell.org/package/ad-delcont). In the Haskell version all effects are made explicit and tracked at the type level without relying on any compiler plugin.

Along the way I'll also walk through an elementary example that helped me understand how delimited continuations operate.

In a [previous post](http://ocramz.github.io/automatic-differentiation/machine-learning/2021/07/18/ad.html) I illustrated the fundamentals of automatic differentiation, as implemented in most imperative programming languages. It turns out, a computational tape is not the only available option for inverting control flow, in sufficiently advanced programming languages. How can we implement reverse-mode automatic differentiation in a purely-functional setting? Read on!


## Staring at higher-order Scala code

Here are two short code snippets that originally appeared in [1]. 

{% highlight scala %}
class NumR (val x: Double, var d: Double) {
  def + (that: NumR) = shift { (k: NumR => Unit) =>
    val y = new NumR(this.x + that.x, 0.0);
    k(y);
    this.d += y.d; 
    that.d += y.d
  }
{% endhighlight %}

This is a Scala implementation of a "plus" function that sums dual numbers. It relies on delimited continuations to achieve non-local control flow and specify what to do when a continuation returns. My Scala is pretty rusty so this has been a head scratcher for a while. I'll first document how my train of thought went while reading this code, and then try to break it down more formally.

1) First we declare a dual number type `NumR`, which has fields `.x` and `.d` for the primal and adjoint respectively. 

2) The implementation of the `+` method is bracketed within a mysterious `shift` higher-order function, which declares a continuation `k`, to be used later. 

3) A temporary variable `y` is declared, having 0 dual value and primal value set to the function result. 

4) `k` is then applied to `y`, and the return value of `k` is discarded (?!). This must mean that `y` itself is mutated within the execution of `k`. 

5) Upon returning from `k`, the dual part of the mutated value of `y` is used to update by accumulation the dual parts of the input variables `x` and `y`.

The other interesting snippet is where all the work happens : the function value is computed, the adjoint accumulation process kicks off (in the "backwards" sweep) and the gradient is returned:

{% highlight scala %}
def grad(f: NumR => NumR @cps[Unit] )(x: Double) = {
  val z = new NumR(x, 0.0)
  reset  { 
    f(z).d = 1.0 }
  z.d
  }
{% endhighlight %}

1) `grad` is a higher-order function that takes the function to be differentiated as a parameter (`f: NumR => NumR`, overloaded to act upon dual numbers `NumR`), and an evaluation point `x`.

2) A temporary variable `z` is declared, having 0 adjoint part and primal part corresponding to the point of interest `x`. `z` will accumulate the partial derivative of `f` with respect to `x`.

3) Within another mysterious bracket called `reset`, the function `f` is evaluated at `z`, then its adjoint part is set to 1.

4) Upon exiting from the `reset` block, the adjoint part of `z` is returned : the partial derivative $$\partial_x f$$ we are interested in.

## Delimited continuations in Haskell with `shift`/`reset`

The `shift` and `reset` operators are one variant of a notion of ["delimited continuations"](https://en.wikipedia.org/wiki/Delimited_continuation), which originated in the Lisp community in the late 80s: the scope of a continuation is made explicit, thus control can "bounce back" at points specified by the programmer. More specifically, `shift` "captures" a continuation, and `reset` delimits it. 

I'm not a programming languages researcher so diving into the original publications didn't exactly help. Fortunately, a bit of tinkering can save us hours of poring over old papers.

`shift`/`reset` are readily available in the [`transformers`](https://hackage.haskell.org/package/transformers) Haskell library, within module `Control.Monad.Trans.Cont`.

Here's a minimal snippet to use both `shift` and `reset`, composed with variable "mutation" in the `State` monad. To be precise we will use the continuation _monad transformer_ `ContT`, and its corresponding operators `shiftT` and `resetT`, to compose other "effects" together with continuations:

{% highlight haskell %}
t1 :: ContT Int (State [Int]) Int
t1 = resetT $ do
  let
    x = 1 -- input
    cons w = lift $ modify (w :)
  r <- shiftT $ \k -> do
    cons x
    let y = x + 1
    z <- lift $ k y -- 1)
    cons z -- 4)
    pure y -- 5)
  cons 0 -- 2)
  pure r -- 3)
{% endhighlight %}

Running the example above elucidates how the _order_ of variable mutation is affected :

{% highlight haskell %}
λ> flip runState [] $ evalContT t1
(2,[2,0,1])
{% endhighlight %}

1) As soon as the continuation `k` is invoked (applied to value `y = 2`), control _exits_ from the `shiftT` block,

2) continues at the next line (in this case appending a `0` to the list used as state variable),

3) and when the "boundary" defined by the lexical scope enclosed by `resetT` is encountered, control _returns_ to the next line after the one that called `k`.

4) At this point (within `shiftT`) `z` is bound to whatever was returned by the `resetT` block, which in turn is the value `k` was applied to, i.e. `y = 2`. This is why the next appended value is a 2.

5) Since `k` was resolved by a matching `resetT`, there's nothing else to do and execution terminates.

Pretty mind-bending the first time I saw it.

## Introducing `ad-delcont`

As it turns out, this non-local control flow (i.e. delegating to a continuation, doing something and returning to the starting point with the results) is well suited to implementing the forward-backward computation needed in reverse-mode automatic differentiation.

In order to convince myself of this, I've implemented the ideas of [1] in a [Haskell library](https://hackage.haskell.org/package/ad-delcont). Overall, I find the result pretty satisfying both from a theoretical and ergonomic standpoint.


{% highlight haskell %}
op1 :: (Num da, Num db) =>
       (a -> (b, db -> da)) -- ^ returns : (function result, pullback)
    -> ContT x (ST s) (DVar s a da)
    -> ContT x (ST s) (DVar s a db)  
op1 f ioa = do
  ra <- ioa
  (D xa _) <- lift $ readSTRef ra
  let (xb, g) = f xa -- 1)
  shiftT $ \ k -> lift $ do
    rb <- var xb 0 -- 2)
    ry <- k rb -- 3)
    (D _ yd) <- readSTRef rb -- 4)
    modifySTRef' ra (withD (\rda0 -> rda0 + g yd)) -- 5)
    pure ry
{% endhighlight %}

The above is a pretty faithful port of the Scala version (for a unary function such as $$\sqrt{ \cdot }$$ to reduce clutter), in which the major differences are the explicit tracking of the effects (mutation and continuation) at the type level. How does this work ?

1) Compute the function result and bind the function inputs to the adjoint updating function (the "pullback")

2) Allocate a fresh STRef `rb` with the function result and 0 adjoint part

3) `rb` is passed downstream as an argument to the continuation `k`, with the expectation that the STRef will be mutated

4) Upon returning from the `k` (bouncing from the boundary of `resetT`), the mutated STRef is read back in

5) The adjoint part of the input variable is updated using `rb` (accumulating the adjoints by summing them together, as this variable might be used in more than one program branch) and the result of the continuation is returned.

In the Haskell case, we pass mutable references to dual variables within the `ST` monad (introduced in [2] and readily available in the Haskell standard library at `Control.Monad.ST`)

The code computing the gradient is correspondingly succint :

{% highlight haskell %}
rad1 :: (Num a, Num b) =>
        (forall s . AD' s a -> AD' s b) -- ^ function to be differentiated
     -> a -- ^ function argument
     -> (b, a) -- ^ (result, adjoint)
rad1 f x = runST $ do
  xr <- var x 0
  zr' <- evalContT $
    resetT $ do
      let
        z = f (AD (pure xr))
      zr <- unAD z
      lift $ modifySTRef' zr (withD (const 1))
      pure zr
  (D z _) <- readSTRef zr'
  (D _ x_bar) <- readSTRef xr
  pure (z, x_bar)
{% endhighlight %}

`AD` is just a newtype wrapper around `ContT .. (ST s) .. `, in which the return variables are `STRef`s containing our dual variables.


## References

[1] Wang, Rompf - A Language and Compiler View on Differentiable Programming - ICLR 2018 [https://openreview.net/forum?id=SJxJtYkPG](https://openreview.net/forum?id=SJxJtYkPG)

[2] Launchbury, Peyton Jones - Lazy Functional State Threads - PLDI 1994 [https://www.microsoft.com/en-us/research/wp-content/uploads/1994/06/lazy-functional-state-threads.pdf](https://www.microsoft.com/en-us/research/wp-content/uploads/1994/06/lazy-functional-state-threads.pdf)
