---
layout: post
title: "Ergonomic abstractions for numerical computing: My story so far"
date: 2026-01-16
categories: numerical-programming functional-programming ergonomics ux dx
---

You know the feeling of encountering an idea that is so simple and pure as to be inescapable ?

For me, two such moments happened when I encountered the Matlab "backslash" operator and when I finally grokked `(lambda )` in Scheme.

The two ideas are sufficiently different (and alien, I suppose) to merit an origin story of how I encountered them and how they shaped my thinking as I grew as a researcher and practitioner. This backstory is also meant to motivate the three experiments on achieving "ergonomic" numerical interfaces I will show in the second part of the post. 

I should preface this by saying that here I use a very narrow meaning of "ergonomic": to qualify, surface code should mirror the mathematical notation it models. It's about considering modeling _intent_ on par with raw performance characteristics. 

Ultimately I think some of these lessons can help toward more reproducible computational science, which in turn shortens the distance between theory and practice of science writ large.


# Stumbling upon functional programming

I learned about functional programming by complete accident.

Back during my MSc I majored in Photonics for telecommunication (a branch of EE), which means that among other things we studied all possible special cases of the Maxwell equations (waveguides, tiny resonators, active media, you name it).

Numerical simulation played a large part, and in addition to some commercial solvers, I started using MEEP and MPB for scattering and mode computations respectively [1, 2].

## Aside: Some context on my CS journey

Up to that point, my programming experience had been quite limited to academic scripting and programming courses (C, Java, Verilog) in addition to lots of Matlab for all sorts of scripts and simulations. I could "code", even creatively so (animated Lorenz attractor, Mandelbrot renderer and all), but my CS fundamentals were patchy at best since that was not my major. Any data structures and algorithms were learned "in the field", and certainly we saw no programming language theory or compilers.

Imagine my surprise (more like bewilderment really) when I found out that the scripting language for MEEP and MPB simulations was a funny-looking contraption called Scheme. How do you make a loop? You "map" a ""lambda"" over an array ???  Anyway, eventually it clicked and I started making my little Scheme scripts, graduated, then fell into the Lisp and later Haskell rabbit hole.

To this day I'm a firm believer (and practitioner) in declarative programming, separation between pure and effectful computations and in total functions, and strive to enforce these as standards for correctness and maintainability even outside FP contexts.


# "Backslash"

Solving linear systems is the bread and butter of most science and engineering, so Matlab is centered around doing that really well: close to mathematical notation and supporting a wide variety of operand structures.

```
x = A \ b 
```

where

```
A x = b
```


In the example, matrix `A` and vector `b` can be anything: very large, sparse, structured etc. Backslash provides optimized implementations for most common cases so the user simply doesn't need to care: it's a great abstraction.


## Aside: Computational research in academia

My PhD project was heavily computational too: optimization algorithms, numerical PDEs/SDEs etc. 

At that time, scientific open source was nascent (yep I'm that old), including the surrounding discourse on reproducibility and stewardship of computational methods.

Back then, most labs including the one I was in were secretive with their methods, and most research code was born and died with each grad student project. In some cases you had to email some professor to ask for a copy of their code, with a nice cover letter. How quaint.

In this milieu I started wondering about long-term sustainability of research artifacts: why is it so hard to turn algorithms into code, and back ? why does everyone use different abstractions? why is reuse nonexistant? _Why is the code that explains the results not reviewed as the research artifact_?

"Backslash" felt like an island of sanity in a sea of terrible grad student scripts, and I set out to understand it by replicating it (cue Feynman's quote on building as a way of knowing).



# Three experiments in ergonomic numerical computing

## `sparse-linear-algebra`

Here it is, in all its hacky glory : https://github.com/ocramz/sparse-linear-algebra . The git log tells me that I first committed code almost 10 years ago !

In this project I tried to replicate the "backslash" experience, somewhat succesfully:

```haskell
class LinearVectorSpace v => LinearSystem v where
  -- | Solve a linear system; uses GMRES internally as default method
  (<\>) :: (MonadThrow m, MonadWriter w m) =>
           MatrixType v   -- ^ System matrix
        -> v              -- ^ Right-hand side
        -> m v            -- ^ Result
```

The type parameters model the relationship between matrix and vector types (and in turn constrain the underlying numerical types), and the fact that the solver can log iterations (for debugging) and potentially fail (e.g. if it does not converge).

This was also my first experiment in building a numerical library out of academia, so naturally I made all the mistakes of an academic programmer :

* a tower of typeclass abstractions on top of each other, causing lots of churn when something needs to change
* building around an intuitive but very inefficient internal design (nested immutable hash maps)
* unstructured workflow: loose or nonexisting ticket/PR/review scopes
* committing straight to `master`
* uploading a half-baked project to a write-only package index : https://hackage.haskell.org/package/sparse-linear-algebra

This was a nice learning exercise, and I'm thankful that at some point this library got some "traction" (I'm aware of at least one industrial user!) and OSS collaborators.  I should also acknowledge that while attempting to fix its many and branching shortcomings I got severely burnt out, and had to stop its development.

Recently I picked it up again and made some Copilot-based fixes (great tool when you're out of mental energies for pushing a fix btw), but making it broadly useful like another LAPACK would require a level of committment that I cannot provide long-term.


## `sde`

Link : https://github.com/ocramz/sde 

Stochastic differential equations are a generalization of PDEs that admit randomness in some terms; they are very popular in finance and advanced control systems literature.

Here I implemented a `Transition` type for threading together random generation and "state" updates in order to implement Wiener/Brownian processes. In the example below we can compose a stochastic volatility process from simpler building blocks:

```haskell
data SV1 = SV1 {sv1x :: Double, sv1y :: Double} deriving (Eq, Show)

stochVolatility1 :: PrimMonad m => Double -> Double -> Double -> Double -> Transition m SV1
stochVolatility1 a b sig alpha = transition randf f where
  randf = (,) <$> normal 0 1
              <*> alphaStable100 alpha
  f (SV1 x _) (ut, vt) = let xt = b * x + sig * ut
                             yt = a * exp (xt / 2) * vt
                         in SV1 xt yt
```

One problem is that accurate integration of SDEs is quite tricky as I was kindly made aware of : https://github.com/ocramz/sde/issues/2 , so anything beyond textbook examples would require significant rework.


## `ad-delcont`

This library ( https://hackage.haskell.org/package/ad-delcont ) implements reverse-mode automatic differentiation using a certain control primitive ("delimited continuations"), rather than the more common "tape" data structure.

I already wrote about this project with explanation and examples: http://ocramz.github.io/posts/2021-07-18-ad-delcont.html , but here I want to highlight how I find the final result quite "ergonomic":

It's ergonomic to _library authors_ because you can extend it safely and without knowing how its internals work; here `op1` turns a unary operator and its adjoint into a component that can be plugged into bigger AD-enabled functions. The type constraints on the first argument of `op1` are basic numbers.


```haskell
op1 :: (Num da, Num db) =>
       (a -> (b, db -> da)) -- ^ returns : (function result, pullback)
    -> ContT x (ST s) (DVar s a da)
    -> ContT x (ST s) (DVar s a db)  
```

On the other hand, it's comfortable to _users_ , because running one such computation (the `AD -> AD` function) results in a plain numerical function which can be reused in any context:

```haskell
rad1 :: (Num a, Num b) =>
        (forall s . AD' s a -> AD' s b) -- ^ function to be differentiated
     -> a -- ^ function argument
     -> (b, a) -- ^ (result, adjoint)
```


# Conclusion

If you read this far, thank you, I think we might be kindred spirits.

Respecting modeling intent in scientific libraries can play one small but significant part in helping reproducibility and ultimately accelerating science, which is why I find it a worthy topic of exploration.



# References

[1] MEEP : https://meep.readthedocs.io/en/master/

[2] MPB : https://mpb.readthedocs.io/en/latest/