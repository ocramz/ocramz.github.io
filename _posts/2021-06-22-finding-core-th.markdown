---
layout: post
title: Finding the Core of an expression using Template Haskell
date: 2021-06-22
categories: Haskell GHC metaprogramming
---

## Introduction

[GHC](https://www.haskell.org/ghc/) is a wonderful ~~compiler~~ platform for writing compilers and languages on. In addition to Haskell offering convenient syntactical abstractions for writing domain-specific languages with, the language itself and the internals of the compiler can be extended in many ways, letting users come up with mind-bending innovations in [scientific computing](http://conal.net/papers/compiling-to-categories/compiling-to-categories.pdf), [testing](https://hackage.haskell.org/package/inspection-testing) and [code editing](https://haskellwingman.dev/), among many other examples.

The compiler offers a [plugin system](https://downloads.haskell.org/ghc/latest/docs/html/users_guide/extending_ghc.html#compiler-plugins) that lets users customize various aspect of the syntax analysis, typechecking and compilation to imperative code, without having to rebuild the compiler itself.

While writing a GHC plugin that lets the user pinpoint a given declaration whose Core will be analyzed and transformed, I found myself in need of a specific bit of machinery: how can the user _tell_ the compiler which expression to look for?

At the top level, we talk about binders (e.g. in `squared x = x * x` the function `\x -> x * x` is said to be _bound_ to the name `squared`), but the compiler uses a richer naming system internally. How to map user-facing terms to the internal representation used by the compiler?

It turns out `inspection-testing` provides this functionality as part of its user interface, and I will document it here both not to forget it and so that others might learn from it in the future.


## Finding the `Name` of declarations with template Haskell

A template-haskell [`Name`](https://hackage.haskell.org/package/template-haskell-2.17.0.0/docs/Language-Haskell-TH.html#t:Name) represents .. the name of declarations, expressions etc. in the syntax tree.

Resolving a top-level declaration into its `Name` requires a little bit of metaprogramming, enabled by the `{-# LANGUAGE TemplateHaskell #-}` extension. With that, we can use the special syntax with a single or double quote to refer to values or types respectively (made famous by `lens` in [`makeLenses](https://hackage.haskell.org/package/lens-5.0.1/docs/Control-Lens-Combinators.html#v:makeLenses) ''Foo`).

## Passing `Name`s to later stages of the compilation pipeline

This is the trick: the `Name` we just found (and any other metadata that might be interesting to our plugin), is packed and serialized into a GHC [ANNotation](http://downloads.haskell.org/~ghc/latest/docs/html/users_guide/extending_ghc.html#source-annotations) via [`liftData`](https://hackage.haskell.org/package/template-haskell-2.17.0.0/docs/Language-Haskell-TH-Syntax.html#v:liftData), which is inserted as a new top-level declaration by a template Haskell action (i.e. a function that returns in the `Q` monad).

Annotations can also be attached by the user to declarations, types and modules, but this method does so programmatically.

## Picking out the annotation from within the plugin






## Credits

First and foremost a big shout out to all the contributors to GHC who have built a truly remarkable piece of technology we can all enjoy, learn from and be productive with.

Of course, Joachim Breitner for devising and implementing `inspection-testing` [1]. I still remember the distinct feeling of my brain expanding against my skull after seeing his presentation at Zurihac 2017.

Next, I'd like to thank the good folks in the Haskell community for being kind and responsive even to my rather pedestrian questions on r/haskell, the ZuriHac discord server and stackoverflow. Li-yao Xia, Matthew Pickering, Daniel Diaz, David Feuer and others, thank you so much. Matthew has also written a paper [2] and curated a list of references for studying and developing GHC plugins , which I refer to extensively.

Mark Karpov deserves lots of credit too for writing an excellent reference on template Haskell [3] with lots of worked examples, go and check it out.


## References

1) J. Breitner, `inspection-testing` https://github.com/nomeata/inspection-testing

2) M. Pickering et al, Working with source plugins - https://mpickering.github.io/papers/working-with-source-plugins.pdf

3) M. Karpov, Template Haskell tutorial - https://markkarpov.com/tutorial/th.html
