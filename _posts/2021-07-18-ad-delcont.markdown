---
layout: post
title: Reverse-mode automatic differentiation with delimited continuations
date: 2021-07-19
categories: Haskell automatic-differentiation machine-learning
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered its "natural" implementation.

In this post I will give an informal but thorough account of the theory and present a library I've published that implements it, [ad-delcont](https://hackage.haskell.org/package/ad-delcont).

## Optimization

From allocating wartime resources at the dawn of digital computing in the 1940s, to fitting the parameters of today's gigantic language models, numerical optimization is an ever-present computational challenge. Optimization is nowadays a vast and fascinating subject of applied mathematics and computer science, and there are many excellent introductory texts on it, which I recommend keeping at hand [1,2].

<img src="https://ocramz.github.io/images/ad-delcont-gd.png" alt="Gradient descent"/>

Many real-world optimization problems require iterative improvement of a set of continuous parameters (a "parameter vector") with respect to a chosen cost function, and are tackled with some form of gradient descent. The _gradient_ is a vector in parameter space that points to the direction of fastest increase in the function at a given point. The picture above shows a two-parameter cost function $$J(\theta_0, \theta_1)$$ evaluated at a fine grid of points and a possible evolution of the gradient descent algorithm. It's worth stressing that many practical cost functions are very costly to evaluate, and often have many more parameters, making full visualization impossible in all but toy examples such as the one above. Computing the gradient of a cost function implemented as a computer program is then a fundamental and ubiquitous task.

## Differentiating computer programs

Automatic differentiation is a family of techniques that compute the gradient of computer programs, given a program that computes the cost function of interest. This is achieved in two major ways, i.e. while the user program is compiled or as it runs. Source code transformation is an interesting approach that has yielded many successful implementations (from ADIFOR [3] to Jax [4]) but in this post I will focus on the latter formulation, for the sake of brevity. 

I emphasize "computer programs" because these contain control structures such as conditionals (`if` .. `then` .. `else`), loops (`while`) and numerous other features which do not appear in mathematical notation and must be accounted for in a dedicated way.

A numerical program is usually built up using the syntactic rules of the host language from a library of elementary functional building blocks (e.g. implementations of the exponential or sine function, `exp()`, `sin()`, and so on). This means that computing the overall sensitivity of this program must involve applying the (multivariate) chain rule of differentiation, while accounting for the program's control flow as outlined above.

At this point, a practitioner is faced with multiple implementation details, summarised in this diagram (from [5]) :

<img src="https://ocramz.github.io/images/ad-delcont-overview.png" alt="Differentiation of mathematical code"/>

Interested readers might want to read [5] for a thorough overview of the design choices that go into an AD system (symbolic vs. numerical vs. algorithmic, forward vs. reverse, etc.).

## The chain rule

Suppose we have a composite function $$z(x, y)$$, with $$x(u, v)$$ and $$y(u, v)$$, in which all components are differentiable at least once. The dependencies between these variables can be drawn as a directed acyclic graph :

<img src="https://ocramz.github.io/images/ad-delcont-multi-chain-rule.png" alt="Multivariate chain rule" width="400"/>

Image from [these slides](http://www.math.ucsd.edu/~gptesler/20c/slides/20c_chainrule_f18-handout.pdf).

The sensitivity of output variable $$z$$ to input variable $$v$$ must account for all the possible paths taken while "traversing" from $$v$$ to $$z$$, i.e. while applying the functions at the intermediate tree nodes to their arguments. The multivariate chain rule tells us to sum these contributions : $$\partial_v z = \partial_v x \cdot \partial_x z + \partial_v y \cdot \partial_y z $$. 

## Forward and Reverse

Ignoring for the sake of exposition all AD approaches that rely on source code analysis and transformation, there remain essentially _two_ ways of computing the derivative of a composite function via "non-standard" evaluation (NSE). By NSE here we mean augmenting the expression variables with adjoint values (thus computing with "dual numbers" [6], i.e. a first-order Taylor approximation of the expression) and potentially modifying the program execution flow in order to accumulate these adjoints (the sensitivities we're interested in). This might sound esoteric but it's actually pretty straightforward as I hope I'll be able to show you.

*Forward-mode AD* is the more intuitive of the two approaches : in this case both the expression value(s) at any intermediate expression node $$v_j$$ and the adjoints $$\partial_{x_i} v_j$$ are computed in the natural reduction order of the expression: by applying function values to their input arguments. Reduction of functions of dual values follows the familiar rules of derivative calculus. The algorithm computes one partial derivative at a time, by setting the dual part of the variable of interest to 1 and all others to 0. Once the expression is fully reduced, $$\partial_{x_i} z$$ can be read off the dual part of the result. The computational cost of this algorithm is one full expression evaluation per input variable.

*Reverse-mode AD* achieves the same result by tracking the reduction order while reducing the expression ("forward"), initializing all duals to $$0$$, and accumulating the adjoints "backwards" from the output variable $$z$$, which is initialized with the trivial adjoint $$\partial_z z = 1$$. Each expression node represents a function, and it is augmented ("overloaded", in programming language terminology) with a "pullback" [7] that computes how input sensitivities change as a function of output sensitivities. Upon returning to a given expression node $$v_i$$, its adjoints are summed over (following the multivariate chain rule shown above). In this case, all parameter sensitivities are computed at once at the end of the backwards sweep. The cost of reverse-mode AD is two full expression evaluations per _output_ variable, which might save a lot of work when applied to expressions with many more input variables, as often happens in optimization and machine learning.

Both AD modes have a long history of successful implementations. Many implementations of reverse-mode AD "reify" the user function into a data structure that tracks the execution history and the functional dependencies (a "Wengert tape"), in order to play the program backwards when accumulating the adjoints.

It turns out, a computational tape is not the only available option for inverting control flow, in sufficiently advanced programming languages. Read on !


## Reverse-mode AD with delimited continuations

The long introduction was meant to set the stage for two short code snippet that originally appeared in [8]. 

{% highlight scala %}
class NumR (val x: Double, var d: Double) {
  def + (that: NumR) = shift { (k: NumR => Unit) =>
    val y = new NumR(this.x + that.x, 0.0);
    k(y);
    this.d += y.d; 
    that.d += y.d
  }
{% endhighlight %}

This is a Scala implementation of an "overloaded" summing function over dual numbers that relies on delimited continuations to achieve non-local control flow and specify what to do when a continuation returns. My Scala is pretty rusty so this has been a head scratcher for a while. I'll first document how my train of thought went while reading this code, and then try to break it down more formally.

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

2) A temporary variable `z` is declared, having 0 adjoint part and primal part corresponding to the point of interest `x`.

3) Within another mysterious bracket `reset`, the function `f` is evaluated at `z`



## Delimited continuations


## ad-delcont


## References

[1] Nocedal, Wright - Numerical Optimization

[2] Boyd, Vanderberghe - Convex Optimization - [https://web.stanford.edu/~boyd/cvxbook/](https://web.stanford.edu/~boyd/cvxbook/)

[3] ADIFOR - [https://www.anl.gov/partnerships/adifor-automatic-differentiation-of-fortran-77](https://www.anl.gov/partnerships/adifor-automatic-differentiation-of-fortran-77)

[4] Jax - [https://github.com/google/jax](https://github.com/google/jax)

[5] Baydin, Pearlmutter - Automatic differentiation of machine learning algorithms - [https://arxiv.org/abs/1404.7456](https://arxiv.org/abs/1404.7456)

[6] Shan - Differentiating regions - [http://conway.rutgers.edu/~ccshan/wiki/blog/posts/Differentiation/](http://conway.rutgers.edu/~ccshan/wiki/blog/posts/Differentiation/) 

[7] Innes - Don't unroll adjoint : Differentiating SSA-form programs - [https://arxiv.org/abs/1810.07951](https://arxiv.org/abs/1810.07951 )

[8] Wang, Rompf - A Language and Compiler View on Differentiable Programming - ICLR 2018 [https://openreview.net/forum?id=SJxJtYkPG](https://openreview.net/forum?id=SJxJtYkPG)
