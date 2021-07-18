---
layout: post
title: Reverse-mode automatic differentiation with delimited continuations
date: 2021-06-22
categories: Haskell automatic-differentiation machine-learning
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered its "natural" implementation.

In this post I will briefly introduce the theory and present a library I've published that implements it, [ad-delcont](https://hackage.haskell.org/package/ad-delcont).

## Automatic differentiation

From allocating wartime resources at the dawn of digital computing in the 1940s, to fitting the parameters of today's gigantic language models, numerical optimization is an ever-present computational challenge. Optimization is nowadays a vast and fascinating subject of applied mathematics and computer science, and there are many excellent introductory texts on it, which I recommend keeping at hand [1,2].

Many real-world optimization problems require iterative approximation of a set of continuous parameters (a "parameter vector"), and are tackled with some form of gradient descent. The _gradient_ is a vector in parameter space that points to the direction of fastest increase in the function at a given point. Computing the gradient of a cost function implemented as a computer program is then a fundamental and ubiquitous task.

Automatic differentiation is a family of techniques that compute the gradient of computer programs, given a program that computes the cost function of interest. This is achieved in two major ways, i.e. while the user program is compiled or as it runs. Source code transformation is an interesting approach that has yielded many successful implementations (from ADIFOR [3] to PyTorch [4]) but in this post I will focus on the latter formulation, for the sake of brevity.

## Differentiating computer programs

I emphasize "computer programs" because these contain control structures such as conditionals ("if .. then .. else"), loops ("while") and numerous other features which do not appear in mathematical notation and must be accounted for in a dedicated way.

A numerical program is usually built up using the syntactic rules of the host language from a library of elementary functional building blocks (e.g. implementations of the exponential or sine function, `exp()`, `sin()`, and so on). This means that computing the overall sensitivity of this program must involve applying the (multivariate) chain rule of differentiation, while accounting for the program's control flow as outlined above.

## The chain rule

Suppose we have a simple function $$z(x, y)$$, with $$x(u, v)$$ and $$y(u, v)$$

<img src="https://ocramz.github.io/images/ad-delcont-multi-chain-rule.png" alt="Multivariate chain rule" width="400"/>

Image from [these slides](http://www.math.ucsd.edu/~gptesler/20c/slides/20c_chainrule_f18-handout.pdf).





## Wang et al


## Delimited continuations


## ad-delcont


## References

[1] Nocedal, Wright - Numerical Optimization

[2] Boyd, Vanderberghe - Convex Optimization - https://web.stanford.edu/~boyd/cvxbook/

[3] ADIFOR - https://www.anl.gov/partnerships/adifor-automatic-differentiation-of-fortran-77

[4] PyTorch - https://pytorch.org/ 
