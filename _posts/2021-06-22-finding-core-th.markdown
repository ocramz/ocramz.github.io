---
layout: post
title: Finding the Core corresponding to a Template Haskell annotation
date: 2021-06-22
categories: Haskell GHC metaprogramming
---

## Introduction

GHC Haskell is a wonderful ~~compiler~~ platform for writing compilers and languages on. Both the surface language and the internals of the compiler can be interfaced and extended in many ways, letting users come up with mind-bending innovations in [scientific computing](http://conal.net/papers/compiling-to-categories/compiling-to-categories.pdf) and [code editing](https://haskellwingman.dev/), among many other examples.

The compiler

While writing a [GHC plugin](https://downloads.haskell.org/ghc/latest/docs/html/users_guide/extending_ghc.html#compiler-plugins) that lets the user pinpoint a given declaration whose Core will be analyzed and transformed, I found myself in need of a specific bit of machinery
