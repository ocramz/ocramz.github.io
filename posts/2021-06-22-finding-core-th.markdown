---
layout: post
title: Finding the Core of an expression using Template Haskell and a custom GHC Core plugin
date: 2021-06-22
categories: Haskell GHC metaprogramming
---

## 2024 Summary

It's been a while since I used Haskell at this depth, so here's a high-level overview: the GHC compiler produces an intermediate program representation in a internal language called "Core"; this post documents a way to mark certain expressions in order to retrieve their "Core" representation later in the compilation pipeline.

<hr>

## Introduction

[GHC](https://www.haskell.org/ghc/) is a wonderful ~~compiler~~ platform for writing compilers and languages. In addition to Haskell offering convenient syntactic abstractions for creating domain-specific languages, the language itself and the internals of the compiler can be extended in many ways, which let users come up with mind-bending innovations in [scientific computing](http://conal.net/papers/compiling-to-categories/compiling-to-categories.pdf), [testing](https://hackage.haskell.org/package/inspection-testing) and [code editing](https://haskellwingman.dev/), among many other examples.

The compiler offers a [plugin system](https://downloads.haskell.org/ghc/latest/docs/html/users_guide/extending_ghc.html#compiler-plugins) that lets users customize various aspects of the syntax analysis, typechecking and compilation phases, without having to rebuild the compiler itself.

While writing a GHC plugin that lets the user analyze and transform the Core representation of certain Haskell expressions, I found myself in need of a specific bit of machinery: _how can the user tell the compiler which expression to look for?_ Moreover, how to map the names of user-defined terms to the internal representation used by the compiler?

It turns out the `inspection-testing` library provides this functionality as part of its user interface, and I will document it here both to consolidate its details in my head and so that others might learn from it in the future. 

This post will also introduce concepts from both the `ghc` and `template-haskell` libraries as needed, so it should be useful to those who, like me, had zero experience in compiler internals until the other day.

Note on reproducibility : here I'm referring to GHC 9.0.1, some modules changed paths since GHC series 8. I've only omitted a few easy imports and definitions from `base`, which you can fill in as an exercise ;)

So, let's dive into the compiler !

## Finding the `Name` of declarations with template Haskell

A template-haskell [`Name`](https://hackage.haskell.org/package/template-haskell-2.17.0.0/docs/Language-Haskell-TH.html#t:Name) represents .. the name of declarations, expressions etc. in the syntax tree.

Resolving a top-level declaration into its `Name` requires a little bit of metaprogramming, enabled by the `{-# LANGUAGE TemplateHaskell #-}` extension. With that, we can use the special syntax with a single or double quote to refer to values or types respectively (made famous by `lens` in [`makeLenses`](https://hackage.haskell.org/package/lens-5.0.1/docs/Control-Lens-Combinators.html#v:makeLenses) ''Foo).

## Passing `Name`s to later stages of the compilation pipeline

This is half of the trick: the `Name` we just found (and any other metadata that might be interesting to our plugin), is packed and serialized into a GHC [ANNotation](http://downloads.haskell.org/~ghc/latest/docs/html/users_guide/extending_ghc.html#source-annotations) via [`liftData`](https://hackage.haskell.org/package/template-haskell-2.17.0.0/docs/Language-Haskell-TH-Syntax.html#v:liftData), which is inserted as a new top-level declaration by a template Haskell action (i.e. a function that returns in the `Q` monad).

Annotations can also be attached by the user to declarations, types and modules, but this method does so programmatically.

The resulting function has a type signature similar to this : `Name -> Q [Dec]`, i.e. given a `Name` it will produce a list of new declarations `Dec` at compile time.

If we're only interested in attaching a `Name` to the annotation, we just need : 

```haskell
{-# language DeriveDataTypeable #-}
import Data.Data (Data)
import Language.Haskell.TH (Name, Loc, AnnTarget(..), Pragma(..), Dec(..), location, Q, Exp(..))
import Language.Haskell.TH.Syntax (liftData)

-- our annotation payload type
data Target = MkTarget { tgName :: Name } deriving (Data)

inspect :: Name -> Q [Dec]
inspect n = do
  annExpr <- liftData (MkTarget n)
  pure [PragmaD (AnnP ModuleAnnotation annExpr)]
```



## Picking out our annotation from within the plugin

The other half of the trick takes place within the plugin, so we'll need to import a bunch of modules from `ghc`-the-library :

```haskell
-- ghc
import GHC.Plugins (Plugin, defaultPlugin, CorePlugin, installCoreToDos, pluginRecompile, CommandLineOption, fromSerialized, deserializeWithData, ModGuts(..), Name, CoreExpr, Var, flattenBinds, getName, thNameToGhcName, PluginRecompile(..))
import GHC.Core.Opt.Monad (CoreToDo(..), CorePluginPass, bindsOnlyPass, CoreM, putMsgS, getDynFlags, errorMsg)
import GHC.Core (CoreProgram, CoreBind, Bind(..), Expr(..))
import GHC.Types.Annotations (Annotation(..), AnnTarget(..))
import GHC.Utils.Outputable (Outputable(..), SDoc, showSDoc, (<+>), ppr, text)
-- template-haskell
import qualified Language.Haskell.TH.Syntax as TH (Name)
```


First, we need a function that looks up all the annotations from the module internals (aptly named `ModGuts` in ghc) and attempts to decode them via their Data interface. Here we are using a custom `Target` type defined above, which could carry additional metadata.

```haskell
extractTargets :: ModGuts -> (ModGuts, [Target])
extractTargets guts = (guts', xs)
  where
    (anns_clean, xs) = partitionMaybe findTargetAnn (mg_anns guts)
    guts' = guts { mg_anns = anns_clean }
    findTargetAnn = \case 
      (Annotation _ payload) -> fromSerialized deserializeWithData payload
      _ -> Nothing
```

Next, we need to map `template-haskell` names to the internal GHC namespace, `thNameToGhcName` to the rescue. If the name can be resolved, `lookupTHName` will return the corresponding Core `Expr`ession (i.e. the abstract syntax tree corresponding to the name we picked in the beginning).

```haskell
-- Resolve the TH.Name into a GHC Name and look this up within the list of binders in the module guts
lookupTHName :: ModGuts -> TH.Name -> CoreM (Maybe (Var, CoreExpr))
lookupTHName guts thn = thNameToGhcName thn >>= \case
  Nothing -> do
    errorMsg $ text "Could not resolve TH name" <+> text (show thn)
    pure Nothing
  Just n -> pure $ lookupNameInGuts guts n
  where
    lookupNameInGuts :: ModGuts -> Name -> Maybe (Var, CoreExpr)
    lookupNameInGuts guts n = listToMaybe
                              [ (v,e)
                              | (v,e) <- flattenBinds (mg_binds guts)
                              , getName v == n
                              ]
```


## A custom GHC Core plugin

As noted above, a GHC plugin can customize many aspects of the compilation process. Here we are interested in the compiler phase that produces Core IR, so we'll only have to modify the `installCoreToDos` field of the `defaultPlugin` value provided by `ghc` by providing our own version :

```haskell
-- module MyPlugin

plugin :: Plugin
plugin = defaultPlugin {
  installCoreToDos = install -- will be defined below
  , pluginRecompile = \_ -> pure NoForceRecompile
                       }
```

As a minimal example, let's pretty-print the Core expression corresponding to the `Name` we just found:

```haskell
-- Print the Core representation of the expression that has the given Name
printCore :: ModGuts -> TH.Name -> CoreM ()
printCore guts thn = do
  mn <- lookupTHName guts thn
  case mn of
    Just (_, coreexpr) -> do
      dflags <- getDynFlags
      putMsgS $ showSDoc dflags (ppr coreexpr) -- GHC pretty printer
    Nothing -> do
      errorMsg $ text "Cannot find name" <+> text (show thn)
```


All that's left is to package `printCore` into our custom implementation of `installCoreToDos`:

```haskell
-- append a 'CoreDoPluginPass' at the _end_ of the 'CoreToDo' list
install :: [CommandLineOption] -> [CoreToDo] -> CoreM [CoreToDo]
install _ todos = pure (todos ++ [pass])
  where
    pass = CoreDoPluginPass pname $ \ guts -> do
      let (guts', targets) = extractTargets guts
      traverse_ (\ t -> printCore guts' (tgName t)) targets
      pure guts'
    pname = "MyPlugin"
```

Here it's important to stress that `install` _appends_ our plugin pass to the ones received as input from the upstream compilation pipeline. 

Another crucial detail : the name string of the plugin as specified in `CoreDoPluginPass` _must_ be the full module name where the `plugin` value is declared.


## Trying out our plugin

A GHC plugin can be imported as any other Haskell library in the `build-depends` section of the Cabal file. While developing a plugin, one should ensure that the test `hs-srcs-dirs` directory is distinct from that under which the plugin source is defined, so as not to form an import loop.

With this, we can declare a minimal module that imports the TH helper `inspect` and the plugin as well. Important to note that `MyPlugin` in the `-fplugin` option is the name of the Cabal _module_ in which GHC will look for the `plugin :: Plugin` value (the entry point to our plugin).

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fplugin=MyPlugin #-}
module PluginTest where

-- try building with either type signature for extra fun

f :: Double -> Double -> Double
-- f :: Floating a => a -> a -> a 
f = \x y -> sqrt x + y

inspect 'f
```

The output of our custom compiler pass will be interleaved with the rest of the GHC output as part of a clean recompile (e.g. `stack clean && stack build`):

```haskell
[1 of 2] Compiling Main
[2 of 2] Compiling PluginTest
\ (x [Dmd=<S,1*U(U)>] :: Double) (y [Dmd=<S,1*U(U)>] :: Double) ->
  case x of { D# x ->
  case y of { D# y -> D# (+## (sqrtDouble# x) y) }
  }
```

If you squint a bit, you can still see the structure of the original expression `\x y = sqrt x + y`, enriched with additional annotations.
For example: 

* the `Dmd=<...>` parts are strictness/demand annotations computed for each variable

* the `Double -> Double -> Double` expression has been made strict (the `case` branch expressions), and its parameters have been "unboxed" ([`D#`](https://hackage.haskell.org/package/base-4.15.0.0/docs/GHC-Exts.html#t:Double) stands for "unboxed double", i.e. containing the value itself, not a pointer to it)

* correspondingly, both the [addition](https://hackage.haskell.org/package/base-4.15.0.0/docs/GHC-Exts.html#v:-43--35--35-) and [square root](https://hackage.haskell.org/package/base-4.15.0.0/docs/GHC-Exts.html#v:sqrtDouble-35-) operators have been specialized to those operating on unboxed doubles.



That's it! We've customized the compiler (without breaking it !), how cool is that?



## Credits

First and foremost a big shout out to all the contributors to GHC who have built a truly remarkable piece of technology we can all enjoy, learn from and be productive with.

Of course, Joachim Breitner for `inspection-testing` [1]. I still remember the distinct feeling of my brain expanding against my skull after seeing his presentation on this at Zurihac 2017.

Next, I'd like to thank the good folks in the Haskell community for kindly giving exhaustive answers to my questions on r/haskell, the ZuriHac discord server and stackoverflow. Li-yao Xia, Matthew Pickering, Daniel Diaz, David Feuer and others. Matthew has also written a paper [2] and curated a list of references on GHC plugins , which I refer to extensively.

Mark Karpov deserves lots of credit too for writing an excellent reference on template Haskell [3] with lots of worked examples, go and check it out.


## References

0) [GHC annotations](https://gitlab.haskell.org/ghc/ghc/-/wikis/annotations)

1) J. Breitner, [`inspection-testing`](https://github.com/nomeata/inspection-testing)

2) M. Pickering et al, [Working with source plugins](https://mpickering.github.io/papers/working-with-source-plugins.pdf)

3) M. Karpov, [Template Haskell tutorial](https://markkarpov.com/tutorial/th.html)
