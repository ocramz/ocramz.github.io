---
layout: post
title: Finding the Core corresponding to a Template Haskell annotation
date: 2021-06-22
categories: Haskell GHC metaprogramming
---

## Introduction

[GHC](https://www.haskell.org/ghc/) is a wonderful ~~compiler~~ platform for writing compilers and languages on. In addition to Haskell offering convenient syntactical abstractions for writing domain-specific languages with, the language itself and the internals of the compiler can be extended in many ways, letting users come up with mind-bending innovations in [scientific computing](http://conal.net/papers/compiling-to-categories/compiling-to-categories.pdf) and [code editing](https://haskellwingman.dev/), among many other examples.

The compiler offers a [plugin system](https://downloads.haskell.org/ghc/latest/docs/html/users_guide/extending_ghc.html#compiler-plugins) that lets users customize various aspect of the syntax analysis, typechecking and compilation to imperative code, without having to rebuild the compiler itself.

While writing a GHC plugin that lets the user pinpoint a given declaration whose Core will be analyzed and transformed, I found myself in need of a specific bit of machinery: how can the user _tell_ the compiler which expression to look for?

At the top level, we talk about binders (e.g. in `squared x = x * x` the function `\x -> x * x` is said to be _bound_ to the name `squared`), but the compiler uses a richer naming system internally.

It turns out `inspection-testing`
