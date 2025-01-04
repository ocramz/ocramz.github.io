---
layout: post
title: Minimum bipartite matching via Riemann optimization
date: 2023-12-21
categories: optimization
---

# Introduction


We use the Birkhoff theorem to turn a combinatorial optimization problem (minimum bipartite matching aka assignment) into a continuous one, constrained on the manifold of doubly stochastic matrices.


## Minimum bipartite matching

Given a bipartite graph between two sets $U$, $V$ of $n$ items each, and an edge cost matrix $C$ with positive entries, the assignment problem can be written as finding an permutation matrix $P$ that solves the following problem:

$$
P^{\star} = \underset{P}{\mathrm{argmin}} \left( P C \right)
$$

Finding the optimal permutation matrix $P^{\star}$ is a combinatorial optimization problem that has well known polynomial-time solution algorithms, e.g. Munkres that runs in $O(n^3)$ time.


# From discrete to continuous

The Birkhoff-von Neumann theorem states that, in dimension $n$, the convex polytope $B$ of doubly convex matrices [1] is the convex hull of the set of $n \times n$ permutation matrices. This polytope is called the Birkhoff polytope [2].

Can we use this fact to solve the assignment problem with a convex, interior point approach?


## The manifold of doubly stochastic matrices


# Experiments

We initialize at a random doubly stochastic matrix. 

<img src="assign_opt_gap-iter-1000_n-10_lr-0.02_1735984842.png"/>

The optimality gap $y - y_{Munkres}$ decreases smoothly

<img src="assign_movie_iter-1000_n-10_lr-0.02_1735984842.gif"/>

In the above animation we see the optimal assignment as dashed red edges, superimposed with the temporary solution in blue. As a visual cue, the thickness of the blue edges is proportional to the respective edge coefficient, and we see it both "sparsifies" as it approaches 


# References

1. Doubly-stochastic matrix <a href="https://en.wikipedia.org/wiki/Doubly_stochastic_matrix">wikipedia</a>
2. Birkhoff polytope <a href="https://en.wikipedia.org/wiki/Birkhoff_polytope">wikipedia</a>
