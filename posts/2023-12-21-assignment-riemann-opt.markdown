---
layout: post
title: Minimum bipartite matching via Riemann optimization
date: 2023-12-21
categories: optimization
---

# Introduction

<img src="/images/assignment_riemann_tri.png"/>


Some time ago at work I noticed two separate instances of the same optimization problem, and decided to read up a little on the fundamentals. The two applications were object tracking in videos, and alignment of spectral peaks in chromatography data.

By chasing some definitions, I learned about the Birkhoff theorem. This allows to turn the initial combinatorial optimization problem ([minimum weight bipartite matching *aka* "assignment"](https://math.mit.edu/~goemans/18433S13/matching-notes.pdf) [0]) into a continuous one. The other half of my investigation is about how to turn a constrained continuous optimization problem into an unconstrained one on an appropriate manifold..

In this post I document an experiment which started from a "what if?" and ended up connecting some interesting areas of mathematics and computer science.

## Minimum bipartite matching

Given a bipartite graph between two sets $U$, $V$ of $n$ items each, and an edge cost matrix $C$ with positive entries, the assignment problem can be written as finding an permutation matrix $P$ that solves the following problem:

$$
P^{\star} = \underset{P \in \mathbb{P}}{\mathrm{argmin}} \left( P C \right)
$$

Recall that a permutation matrix has binary entries, and exactly one $1$ per row. The identity matrix can be seen as a trivial permutation that does nothing to its argument, when seen as an operator.

Finding the optimal permutation matrix $P^{\star}$ is a combinatorial optimization problem that has well known polynomial-time solution algorithms, e.g. Munkres that runs in $O(n^3)$ time.


# From discrete to continuous

The Birkhoff-von Neumann theorem states that, in dimension $n$, the convex polytope $\mathbb{B}$ of doubly convex matrices [1] is the convex hull of the set of $n \times n$ permutation matrices. Informally, there is a convex, continuous region of space "between" the permutation matrices of a given dimensionality. This convex set is called the Birkhoff polytope [2].

Can we perhaps use this result to solve the assignment problem with a convex, interior point approach?



We can rewrite the assignment problem such that the optimization variable ranges over the Birkhoff polytope; this rewritten form is equivalent to the original one since the cost function is linear in the argument $P$, so we expect the optimum to lie at a vertex of the admissible region $\mathbb{B}$ (i.e. to be a permutation matrix).

$$
P^{\star} = \underset{P \in \mathbb{B}}{\mathrm{argmin}} \left( P C \right)
$$

What is left to find out is how to turn a constrained optimization problem into an unconstrained one over an appropriate subspace.

## The manifold of doubly stochastic matrices

Informally, a <i>manifold</i> is a version of Euclidean space $\mathbb{R}^n$ that is only locally flat (unlike regular Euclidean space which is flat everywhere).

The main technical device for moving between $\mathbb{R}^n$ and a manifold $\mathbb{M}$ is an orthogonal projection. The gradient of our cost function over $\mathbb{M}$ is then expressed as the projection of its gradient computed over $\mathbb{R}^n$.




## First-order optimization on manifolds

We use a customized version of `mctorch` [3], extended to implement the manifold of doubly-stochastic matrices.

At every SGD step, the optimizer checks for 



# Experiments

We initialize the optimizer at a random doubly stochastic matrix, and use SGD with learning rate 2e-2.


<img src="/images/assign_movie_iter-1000_n-10_lr-0.02_1735984842.gif" width=500/>

In the above animation we see the optimal assignment as dashed red edges, superimposed with the temporary solution in blue. As a visual cue, the thickness of the blue edges is proportional to the respective edge coefficient, and we see it both "sparsifies" as it approaches the optimum.


<img src="/images/assign_opt_gap_iter-1000_n-10_lr-0.02_1735984842.png" width=400/>

As we can see above, the optimality gap $y - y_{Munkres}$ decreases smoothly (from most starting points, that is).


## Code repo

All scripts can be found on my GitHub profile <a href="https://github.com/ocramz/assignment-riemann-opt">here</a>.


# References

0. Assignment problem <a href="https://en.wikipedia.org/wiki/Assignment_problem">wikipedia</a>
1. Doubly-stochastic matrix <a href="https://en.wikipedia.org/wiki/Doubly_stochastic_matrix">wikipedia</a>
2. Birkhoff polytope <a href="https://en.wikipedia.org/wiki/Birkhoff_polytope">wikipedia</a>
3. `mctorch` <a href="github">https://github.com/mctorch/mctorch</a>
4. Douik, A. and Hassibi, B., Manifold Optimization Over the Set of Doubly Stochastic Matrices: A Second-Order Geometry <a href="https://arxiv.org/abs/1802.02628">arXiv</a>
