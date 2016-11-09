---
layout: post
title: A simple derivation of the Arnoldi algorithm
date: 2016-11-09
categories: mathematics tutorials
---

The Arnoldi iteration is a numerically stable algorithm to produce an orthonormal basis for the Krylov subspace associated with a matrix $$A \in \mathbb{R}^{m \times m}$$ and a vector as $$b \in \mathbb{R}^m$$.
The Krylov subspace of order $$r \leq m$$ associated with $$A$$ and $$b$$ is defined as $$K_r := \lbrace b, Ab, A^b \cdots A^{r-1}b \rbrace$$. The elements of $$K_r$$ are not orthogonal; an orthonormal basis for $$K_r$$ can be produced via the Gram-Schmidt procedure or by the closely-related Arnoldi method.

The Arnoldi method starts from a normalized vector $$q_1$$ and iteratively produces the next basis vectors. This process eventually "breaks down" since the norm of the iterates $$q_i$$ decreases, at which point the algorithm is said to have converged.

The objective is to produce an upper Hessenberg matrix $$H_n$$ (i.e. that is zero below the first subdiagonal) and a matrix $$Q$$ having orthogonal columns such that $$A Q_{i - 1} = Q_i H_i$$.
With the subscripts we mean that at iteration $$i$$ there are $$i$$ columns of $$Q$$ available (we denote this as $$Q_{i}$$) and we must find the $$i+1$$th; 

Focusing for example on the second iteration, we have


$$
A
\left[
\begin{array}{c|c}
  q_1 & q_2
\end{array}
\right]
=
\left[
\begin{array}{c|c|c}
  q_1 & q_2 & q_3
\end{array}
\right]

\left[
\begin{array}{c|c|c}
 h_{11} & h_{12} & h_{13} &&
 0 & h_{22} & h_{23}
\end{array}
\right]



\tilde{H}_n = \begin{bmatrix}
   h_{1,1} & h_{1,2} & h_{1,3} & \cdots  & h_{1,n} \\
   h_{2,1} & h_{2,2} & h_{2,3} & \cdots  & h_{2,n} \\
   0       & h_{3,2} & h_{3,3} & \cdots  & h_{3,n} \\
   \vdots  & \ddots  & \ddots  & \ddots  & \vdots  \\
   \vdots  &         & 0       & h_{n,n-1} & h_{n,n} \\
   0       & \cdots  & \cdots  & 0       & h_{n+1,n}
\end{bmatrix}
$$

$$ 
f(a) = \frac{1}{2\pi\iota} \oint_\gamma \frac{f(z)}{z-a} dz
$$