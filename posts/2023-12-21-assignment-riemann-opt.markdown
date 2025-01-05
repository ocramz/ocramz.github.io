---
layout: post
title: Minimum bipartite matching via Riemann optimization
date: 2023-12-21
categories: optimization
---

# Introduction

<img src="/images/assignment_riemann_tri.png"/>


Some time ago I ran into two separate instances of the same combinatorial optimization problem in the span of a few days, and decided to read up a little on the fundamentals. The two applications were object tracking in videos, and peaks alignment in chromatography data.

By chasing down some definitions, I learned about the Birkhoff theorem, which led me to wonder whether we can turn the original combinatorial problem ([minimum weight bipartite matching *aka* "assignment"](https://math.mit.edu/~goemans/18433S13/matching-notes.pdf) [0]) into a differentiable one. The other half of my investigation was about how to turn a constrained continuous optimization problem into an unconstrained one over an appropriate manifold.

In this post I document my experiments which started from a "what if?" and ended up connecting some interesting areas of mathematics and computer science (and an empirical confirmation to my starting intuition, I should add).

## Minimum bipartite matching

Given a bipartite graph between two sets $U$, $V$ of $n$ items each, and an edge cost matrix $C$ with positive entries, the assignment problem can be written as finding a permutation matrix $P$ that minimizes the total cost:

$$
P^{\star} = \underset{P \in \mathbb{P}}{\mathrm{argmin}} \left( P C \right)
$$

Recall that a permutation matrix has binary entries, and exactly one $1$ per row.

Finding the optimal permutation matrix $P^{\star}$ is a combinatorial optimization problem that has well known polynomial-time solution algorithms, e.g. Munkres that runs in $O(n^3)$ time.

The assignment problem is a special case of the larger family of *optimal transport* problems, which mathematicians started looking at in the 18th century.

# From discrete to continuous

The Birkhoff-von Neumann theorem states that, in dimension $n$, the set $\mathbb{B}$ of doubly stochastic matrices [1] is the convex hull of the set of $n \times n$ permutation matrices. Informally, there is a convex, continuous region of space "between" the permutation matrices of a given dimensionality. This convex set is called the Birkhoff polytope [2].

Can we perhaps use this result to solve the assignment problem with a convex, interior point approach?

We can rewrite the assignment problem such that the optimization variable ranges over the Birkhoff polytope; this rewritten form is equivalent to the original one since the cost function is linear in the argument $P$, so we expect the optimum to lie at a vertex of the admissible region $\mathbb{B}$ (i.e. to be a permutation matrix).

$$
P^{\star} = \underset{P \in \mathbb{B}}{\mathrm{argmin}} \left( P C \right)
$$

That implicit constraint under the $\mathrm{argmin}$ looks nasty. How to address it?

In the following we'll see how to turn this kind of constrained optimization problem into an unconstrained one over an appropriate *manifold*.

## Optimization on manifolds

Informally, a <i>manifold</i> is a version of Euclidean space $\mathbb{R}^n$ that is only locally flat (unlike regular Euclidean space which is uniformly flat everywhere).

In order to "make progress" towards a minimum cost region over a manifold, we must define notions of vector addition over curved spaces, in a way.

The main technical devices for moving between $\mathbb{R}^n$ and a [smooth manifold](https://en.wikipedia.org/wiki/Riemannian_manifold) $\mathbb{M}$ are the *orthogonal projection* from $\mathbb{M}$ to its tangent, and the *retraction* operation that assigns points on the tangent bundle $T\mathbb{M}$ to $\mathbb{M}$. 

For an introduction to the relevant definitions I found the book and online course ["An introduction to optimization on smooth manifolds"](https://www.nicolasboumal.net/book/#lectures) to be very accessible.

## The manifold of doubly stochastic matrices

Many interesting sets have manifold structure: the sphere, [the set of probability distributions](https://en.wikipedia.org/wiki/Statistical_manifold), the set of positive-definite matrices. You can construct manifolds from products of manifolds, too. With some furious handwaving on my part and by recognizing the similarities (e.g. positivity and unit norm constraint, but I'll try to dig out a reference) you can convince yourself that DS matrices have manifold structure in turn.

The numerical implementations of the projection and retraction operators are taken from the literature, i.e. a single paper on the topic [4].

As a side note, one of the internal operations to implement the retraction is the [Sinkhorn-Knopp iteration](https://en.wikipedia.org/wiki/Sinkhorn%27s_theorem) which has applications elsewhere too (e.g in optimal transport).


## First-order optimization on manifolds

My optimization code is based on `torch` with some code borrowed from `mctorch` [3], extended to implement the manifold of doubly-stochastic matrices. In the following I refer to Python modules and line numbers in my implementation at [this commit](https://github.com/ocramz/assignment-riemann-opt/tree/a6bf622b77160dac58dc72fdd1ddd036338d23f3) : 

Disregarding some implementation details (e.g. how Pytorch handles mutable objects), at every SGD step (`rsgd.py` line 57), the optimizer follows the textbook definition:

1. computes the Riemann gradient (`egrad2rgrad`, from `parameter.py` line 31) via an orthogonal projection of the Euclidean gradient of the cost function onto $T\mathbb{M}$
2. scales it by the negative learning rate
3. computes the retraction of the current point along the scaled Riemann gradient, thereby moving to a new point on $\mathbb{M}$.

The doubly-stochastic matrix manifold operations are implemented [here](https://github.com/ocramz/assignment-riemann-opt/blob/a6bf622b77160dac58dc72fdd1ddd036338d23f3/doublystochastic.py).


# Experiments

We start by generating a cost matrix of rank $n$, and computing the optimal assignment with the Munkres algorithm, which provides us with a cost lower bound ($y_{LB}$).
We then initialize the SGD optimizer at a random doubly stochastic matrix, with the elements sampled from the ["folded" normal distribution](https://en.wikipedia.org/wiki/Folded_normal_distribution)  $|\mathcal{N}(0, 1)|$.
The learning rate is set to 2e-2 (found empirically).



<img src="/images/assign_movie_iter-1000_n-10_lr-0.02_1735984842.gif" width=500/>

In the above animation we see the optimal assignment as dashed red edges, superimposed with the temporary solution in blue. As a visual cue, the thickness of the blue edges is proportional to the respective matrix coefficient, and we see the matrix "sparsifies" as it approaches the optimum at a vertex of the Birkhoff set.


<img src="/images/assign_opt_gap_iter-1000_n-10_lr-0.02_1735984842.png" width=400/>

As we can see above, the optimality gap between the current and the Munkres cost ($y - y_{LB}$) converges smoothly to 0 (from most starting points, in my experiments). I still have to characterize some rare cases in which the bound worsens for a while before improving again.


# Conclusions

I was quite surprised this approach works so well, to be honest. Besides usual academic concerns of performance, convergence bounds etc., it would be interesting to generalize this approach and look at the actual connections with optimal transport: what if we have two histograms or *distributions* rather than the sets $U$ and $V$?


## Code repo

All scripts can be found on my GitHub profile <a href="https://github.com/ocramz/assignment-riemann-opt">here</a>.


# References

0. Assignment problem <a href="https://en.wikipedia.org/wiki/Assignment_problem">wikipedia</a>
1. Doubly-stochastic matrix <a href="https://en.wikipedia.org/wiki/Doubly_stochastic_matrix">wikipedia</a>
2. Birkhoff polytope <a href="https://en.wikipedia.org/wiki/Birkhoff_polytope">wikipedia</a>
3. `mctorch` <a href="github">https://github.com/mctorch/mctorch</a>
4. Douik, A. and Hassibi, B., Manifold Optimization Over the Set of Doubly Stochastic Matrices: A Second-Order Geometry, 2018 <a href="https://arxiv.org/abs/1802.02628">arXiv</a>
5. Boumal, N. [An introduction to optimization on smooth manifolds](https://www.nicolasboumal.net/book/#lectures)
