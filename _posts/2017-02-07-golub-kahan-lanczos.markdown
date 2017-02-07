---
layout: post
title: The singular value decomposition, pt.1 - Golub-Kahan-Lanczos bidiagonalization
date: 2017-02-07
categories: mathematics tutorials
---

Many reference implementations of the singular value decomposition (SVD) use bidiagonalization as a fundamental preprocessing step. Like the [Arnoldi algorithm](https://ocramz.github.io/mathematics/tutorials/2016/11/09/arnoldi-alt.html), it is very closely related to the Gram-Schmidt orthogonalization process, since it multiplies the operand matrix with a series of projection matrices that zero out one or more of its components at each application.

In this blog post I will explain the Golub-Kahan-Lanczos bidiagonalization, which applies two projections, $$P \in \mathbb{R}^{m \times n}$$ and $$Q \in \mathbb{R}^{n \times n}$$, to the operand matrix $$A \in \mathbb{R}^{m \times n}$$ to produce a matrix $$B \mathbb{R}^{n \times n}$$ that is non-zero only on its main diagonal and first super-diagonal.

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
\label{eqn1}
$$

In the equation above we must find _two_ sets of orthonormal vectors, i.e. the columns of $$P$$ and $$Q$$. This means that there are effectively two sets of equations which we must solve iteratively to retrieve the factorization; these are obtained by applying $$P$$ to Eq.1 and respectively transposing it and applying $$Q$$:


$$
\begin{cases}
A Q = P B \\
A^\dagger P = Q B^\dagger
\end{cases}
$$


The first step requires choosing an arbitrary vector of unit norm and appropriate dimensions, $$\mathbf{q}_1$$, which is used to obtain $$\mathbf{p}_1$$, $$\mathbf{p}_2$$ and $$\mathbf{q}_2$$:

$$
\begin{cases}
A \mathbf{q}_1 = \alpha_1 \mathbf{p}_1 \\
A^\dagger \mathbf{p}_1 = \alpha_1 \mathbf{q}_1 + \beta_1 \mathbf{q}_2
\end{cases}
$$

Subsequent steps are only minimally different; at step $$j$$ :

$$
\begin{cases}
\mathbf{q}_j, \beta_{j-1}, \mathbf{p}_{j-1} & \mathrm{Input} \\

\mathbf{p}_{j} = (A \mathbf{q}_{j} - \beta_{j-1} \mathbf{p}_{j-1})/\alpha_j & \alpha_j =  \|A \mathbf{q}_{j} - \beta_{j-1} \mathbf{p}_{j-1}\|  \\

\mathbf{q}_{j+1} = (A^\dagger \mathbf{p}_{j} - \alpha_{j} \mathbf{q}_{j})/\beta_j & \beta_j =  \|A^\dagger \mathbf{p}_{j} - \alpha_{j} \mathbf{q}_{j}\|  \\

\mathbf{q}_{j+1}, \beta_{j}, \mathbf{p}_{j} & \mathrm{Output}
\end{cases}
$$





## References

Dongarra, Jack, et al. (eds.), [Templates for the Solution of Algebraic Eigenvalue Problems: a Practical Guide](http://www.netlib.org/utk/people/JackDongarra/etemplates/node198.html)

Golub, Gene H.; Van Loan, Charles F. (1996), Matrix Computations (3rd ed.), Johns Hopkins

