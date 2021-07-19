---
layout: post
title: Reverse-mode automatic differentiation with delimited continuations
date: 2021-07-19
categories: Haskell automatic-differentiation machine-learning
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered its "natural" implementation.

In this post I will briefly introduce the theory and present a library I've published that implements it, [ad-delcont](https://hackage.haskell.org/package/ad-delcont).

## Automatic differentiation

From allocating wartime resources at the dawn of digital computing in the 1940s, to fitting the parameters of today's gigantic language models, numerical optimization is an ever-present computational challenge. Optimization is nowadays a vast and fascinating subject of applied mathematics and computer science, and there are many excellent introductory texts on it, which I recommend keeping at hand [1,2].

Many real-world optimization problems require iterative approximation of a set of continuous parameters (a "parameter vector"), and are tackled with some form of gradient descent. The _gradient_ is a vector in parameter space that points to the direction of fastest increase in the function at a given point. Computing the gradient of a cost function implemented as a computer program is then a fundamental and ubiquitous task.

Automatic differentiation is a family of techniques that compute the gradient of computer programs, given a program that computes the cost function of interest. This is achieved in two major ways, i.e. while the user program is compiled or as it runs. Source code transformation is an interesting approach that has yielded many successful implementations (from ADIFOR [3] to Jax [4]) but in this post I will focus on the latter formulation, for the sake of brevity. 

## Differentiating computer programs

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

## Forward vs. Reverse

Ignoring for the sake of exposition all AD approaches that rely on source code analysis and transformation, there remain essentially _two_ ways of computing the derivative of a composite function via "non-standard" evaluation (NSE). By NSE here we mean augmenting the expression variables with adjoint values (thus computing with "dual numbers" [6], i.e. a first-order Taylor approximation of the expression) and potentially modifying the program execution flow in order to accumulate these adjoints (the sensitivities we're interested in). This might sound esoteric but it's actually pretty straightforward as I hope I'll be able to show you.

*Forward-mode AD* is the more intuitive of the two approaches : in this case both the expression value(s) at any intermediate expression node $$v_j$$ and the adjoints $$\partial_{x_i} v_j$$ are computed in the natural reduction order of the expression: by applying function values to their input arguments. Reduction of functions of dual values follows the familiar rules of derivative calculus. The algorithm computes one partial derivative at a time, by setting the dual part of the variable of interest to 1 and all others to 0. Once the expression is fully reduced, $$\partial_{x_i} z$$ can be read off the dual part of the result. The computational cost of this algorithm is one full expression evaluation per input variable.

*Reverse-mode AD* achieves the same result by tracking the reduction order while reducing the expression ("forward"), initializing all duals to $$0$$, and accumulating the adjoints "backwards" from the output variable $$z$$, which is initialized with the trivial adjoint $$\partial_z z = 1$$. Each expression node represents a function, and it is augmented ("overloaded", in programming language terminology) with a "pullback" [7] that computes how input sensitivities change as a function of output sensitivities. Upon returning to a given expression node $$v_i$$, its adjoints are summed over (following the multivariate chain rule shown above).




## Wang et al


{% highlight scala %}
class NumR (val x: Double, var d: Double) {
  def + (that: NumR) = shift { (k: NumR => Unit) =>
    val y = new NumR(this.x + that.x, 0.0);
    k(y);
    this.d += y.d; 
    that.d += y.d
  }
{% endhighlight %}

## Delimited continuations


## ad-delcont


## References

[1] Nocedal, Wright - Numerical Optimization

[2] Boyd, Vanderberghe - Convex Optimization - https://web.stanford.edu/~boyd/cvxbook/

[3] ADIFOR - https://www.anl.gov/partnerships/adifor-automatic-differentiation-of-fortran-77

[4] Jax - https://github.com/google/jax

[5] Baydin, Pearlmutter - Automatic differentiation of machine learning algorithms - https://arxiv.org/abs/1404.7456

[6] Shan - Differentiating regions - http://conway.rutgers.edu/~ccshan/wiki/blog/posts/Differentiation/ 

[7] Innes - Don't unroll adjoint : Differentiating SSA-form programs - https://arxiv.org/abs/1810.07951 
