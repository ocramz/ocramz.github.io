---
layout: post
title: Reverse-mode automatic differentiation with delimited continuations
date: 2021-07-19
categories: Haskell automatic-differentiation machine-learning Scala
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered its "natural" implementation.

I will first "read aloud" the reference Scala implementation from the original paper [1] and then present a Haskell library I've written that implements its ideas, [ad-delcont](https://hackage.haskell.org/package/ad-delcont).

In a [previous post](http://ocramz.github.io/automatic-differentiation/machine-learning/2021/07/18/ad.html) I illustrated the fundamentals of automatic differentiation, as implemented in most imperative programming languages. It turns out, a computational tape is not the only available option for inverting control flow, in sufficiently advanced programming languages. Read on !


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

3) A temporary variable `y` is declared, having 0 dual value. 

4) `k` is then applied to `y`, and the return value of `k` is discarded (?!). This must mean that `y` itself is mutated within the execution of `k`. 

5) Upon returning from `k`, the dual part of the mutated value of `y` is used to update by accumulation (see multivariate chain rule section above) the dual parts of the input variables `x` and `y`.

The other interesting snippet is where the adjoint accumulation process kicks off and the gradient is redurned:

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

## Delimited continuations with `shift`/`reset`

The `shift` and `reset` operators are one variant of a notion of ["delimited continuations"](https://en.wikipedia.org/wiki/Delimited_continuation), which originated in the Lisp community in the late 80s: the scope of a continuation is made explicit, thus control can "bounce back" at points specified by the programmer. More specifically, `shift` "captures" a continuation, and `reset` delimits it. 

I'm not a programming languages researcher so diving into the original publications didn't exactly help. Fortunately, a bit of tinkering can save us hours of poring over old papers.



## ad-delcont


## References

[1] Wang, Rompf - A Language and Compiler View on Differentiable Programming - ICLR 2018 [https://openreview.net/forum?id=SJxJtYkPG](https://openreview.net/forum?id=SJxJtYkPG)
