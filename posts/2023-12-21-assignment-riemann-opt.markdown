---
layout: post
title: Minimum bipartite matching via Riemann optimization
date: 2023-12-21
categories: optimization
---

# Introduction




# Technical summary

We use the Birkhoff theorem to turn a combinatorial optimization problem (minimum bipartite matching aka assignment) into a continuous one, constrained on the manifold of doubly stochastic matrices.


# Minimum bipartite matching

Given a bipartite graph between two sets $U$, $V$ and an edge cost matrix $C$ with positive entries, the assignment problem can be written as finding an permutation matrix $P$ that solves the following problem:

$$
P^{\star} = \underset{P}{\mathrm{argmin}} P C
$$


# References

1. Doubly-stochastic matrix <a href="https://en.wikipedia.org/wiki/Doubly_stochastic_matrix">wikipedia</a>
2. Birkhoff polytope <a href="https://en.wikipedia.org/wiki/Birkhoff_polytope">wikipedia</a>
