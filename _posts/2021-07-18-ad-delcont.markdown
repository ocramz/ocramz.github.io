---
layout: post
title: Reverse-mode automatic differentiation with delimited continuations
date: 2021-06-22
categories: Haskell automatic-differentiation machine-learning
---

## Introduction

A few days ago I stumbled upon a recent line of research that applies an old idea from functional programming languages (continuation passing) to an old idea from numerical computing (automatic differentiation, AD). The result is an elegant algorithm, which remains close to the textbook treatment of reverse-mode AD ("backpropagation") and could rightly be considered as the "natural" implementation of this idea.

In this post I will briefly introduce the theory and present a library I've published that implements it, [ad-delcont](https://hackage.haskell.org/package/ad-delcont).

## Automatic differentiation

Since the dawn of digital computers to today's machine learning systems, finding the best allocation of resources or the parameters of a gigantic language model are fundamentally numerical optimization routines. Optimization is a vast and fascinating subject of applied mathematics, and there are many excellent introductory texts on it, which I recommend keeping at hand [1,2]

Many real-world optimization problems require iterative approximation of a set of continuous parameters (a "parameter vector"), and are tackled with some form of gradient descent. Computing the gradient of a cost function implemented as a computer program is a fundamental and ubiquitous task.

Automatic differentiation is a family of techniques that compute the parametric sensitivity of computer programs. 


<img src="https://ocramz.github.io/images/ad-delcont-multi-chain-rule.png" alt="Multivariate chain rule" width="400"/>


Image from [1] 


## Wang et al


## Delimited continuations


## ad-delcont


## References

[1] Nocedal, Wright - Numerical Optimization

[2] Boyd, Vanderberghe - Convex Optimization - https://web.stanford.edu/~boyd/cvxbook/

[3] Multivariate chain rule - G. Tesler - http://www.math.ucsd.edu/~gptesler/20c/slides/20c_chainrule_f18-handout.pdf
