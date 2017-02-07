---
layout: post
title: The singular value decomposition, pt.1 - Golub-Kahan-Lanczos bidiagonalization
date: 2017-02-07
categories: mathematics tutorials
---

Many reference implementations of the singular value decomposition (SVD) use bidiagonalization as a fundamental preprocessing step. Like the [Arnoldi algorithm](https://ocramz.github.io/mathematics/tutorials/2016/11/09/arnoldi-alt.html), it is very closely related to the Gram-Schmidt orthogonalization process, since it multiplies the operand matrix with a series of projection matrices that zero out one or more of its components at each application.

In this blog post I will explain the Golub-Kahan-Lanczos bidiagonalization, which applies two projections, $$P$$ and $$Q$$, to the operand matrix $$A$$ to produce a matrix $$B$$ that is non-zero only on its main diagonal and first super-diagonal.

$$
P^\dagger A Q = B =: \left[
\begin{array}{c c c c c}
 \alpha_1 & \beta_1  &         & & \\
          & \alpha_2 & \beta_2 & & \\
	  & & \ddots & \ddots    & \\
	  & & & \alpha_{n-1} & \beta_{n-1} \\
          & & & & \alpha_n \\
\end{array}
\right]
$$



## References

Dongarra, Jack, et al. (eds.), Templates for the Solution of Algebraic Eigenvalue Problems: a Practical Guide (http://www.netlib.org/utk/people/JackDongarra/etemplates/node198.html)

Golub, Gene H.; Van Loan, Charles F. (1996), Matrix Computations (3rd ed.), Johns Hopkins

