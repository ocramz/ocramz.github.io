---
layout: post
title: A simple derivation of the Arnoldi algorithm
date: 2016-11-09
categories: mathematics tutorials
---

The Arnoldi iteration is a numerically stable algorithm to produce an orthonormal basis for the Krylov subspace associated with a matrix $$A \in \mathbb{R}^{m \times m}$$ and a vector as $$b \in \mathbb{R}^m$$.
The Krylov subspace of order $$r \leq m$$ associated with $$A$$ and $$b$$ is defined as $$K_r := \lbrace b, Ab, A^b \cdots A^{r-1}b \rbrace$$. The elements of $$K_r$$ are not orthogonal; an orthonormal basis for $$K_r$$ can be produced via the Gram-Schmidt procedure or by the closely-related Arnoldi method.

The Arnoldi method starts from a normalized vector $$q_0$$ and iteratively produces the next basis vectors. This process eventually "breaks down" since the norm of the iterates $$q_i$$ decreases, at which point the algorithm is said to have converged.

The objective is to produce an upper Hessenberg matrix $$H$$ (i.e. being zero below the first subdiagonal) and a matrix $$Q$$ having orthogonal columns. At iteration $$i$$ there are $$i+1$$ columns of $$Q$$ available (we denote this as $$Q_{i-1}$$)

$$ 
f(a) = \frac{1}{2\pi\iota} \oint_\gamma \frac{f(z)}{z-a} dz
$$