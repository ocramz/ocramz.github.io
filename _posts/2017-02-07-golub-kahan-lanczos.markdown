---
layout: post
title: The singular value decomposition, pt.1 - Golub-Kahan-Lanczos bidiagonalization
date: 2017-02-07
categories: mathematics tutorials
---

Many reference implementations of the singular value decomposition (SVD) use bidiagonalization as a fundamental preprocessing step. Like the [Arnoldi algorithm](https://ocramz.github.io/mathematics/tutorials/2016/11/09/arnoldi-alt.html), it is very closely related to the Gram-Schmidt orthogonalization process, since it multiplies the operand matrix with a series of projection matrices that zero out one or more of its components at each application.

In this blog post I will explain the Golub-Kahan-Lanczos bidiagonalization, which applies two projections, $$P \in \mathbb{R}^{m \times n}$$ and $$Q \in \mathbb{R}^{n \times n}$$, to the operand matrix $$A \in \mathbb{R}^{m \times n}$$ to produce a matrix $$B \in \mathbb{R}^{n \times n}$$ that is non-zero only on its main diagonal and first super-diagonal.

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

The equation above requires us to find _two_ sets of orthonormal vectors in order be fulfilled, i.e. the columns of $$P$$ and $$Q$$. This means that there are effectively two sets of equations which we must solve iteratively to retrieve the factorization; these are obtained by applying $$P$$ to Eq.1 and respectively transposing it and applying $$Q$$ (and using the fact that $$(U V)^\dagger = V^\dagger U^\dagger$$):


$$
\begin{cases}
A Q = P B \\
A^\dagger P = Q B^\dagger
\end{cases}
$$

The algorithm directly follows by inspecting the two systems of equations written above in terms of their columns.

As first step we must choose an arbitrary vector of unit norm and appropriate dimensions, $$\mathbf{q}_1$$, which is used to obtain $$\mathbf{p}_1$$ and $$\alpha_1$$:

$$
A \mathbf{q}_1 = \alpha_1 \mathbf{p}_1
$$

whereas $$\mathbf{p}_2$$, $$\mathbf{q}_2$$ and $$\beta_1$$ are obtained from the second system of equations:

$$
A^\dagger \mathbf{p}_1 = \alpha_1 \mathbf{q}_1 + \beta_1 \mathbf{q}_2 
$$

(NB: the $$\alpha$$ and $$\beta$$ coefficients are obtained in turn by prescribing the $$\mathbf{p}$$ and $$\mathbf{q}$$ vectors to have unit norm).

Subsequent steps are only minimally different; at step $$j \in {2 .. n-1}$$ :

$$
\begin{array}{l l}
(\mathrm{input} : \mathbf{q}_j, \beta_{j-1}, \mathbf{p}_{j-1} ) &\\

\mathbf{p}_{j} = (A \mathbf{q}_{j} - \beta_{j-1} \mathbf{p}_{j-1})/\alpha_j &\alpha_j =  \|A \mathbf{q}_{j} - \beta_{j-1} \mathbf{p}_{j-1}\|  \\

\mathbf{q}_{j+1} = (A^\dagger \mathbf{p}_{j} - \alpha_{j} \mathbf{q}_{j})/\beta_j &\beta_j =  \|A^\dagger \mathbf{p}_{j} - \alpha_{j} \mathbf{q}_{j}\|  \\

(\mathrm{output} : \mathbf{q}_{j+1}, \beta_{j}, \mathbf{p}_{j} )&
\end{array}
$$

Note : of course also the coefficients $$\alpha_i$$ are "outputs" to the iteration, but of the elements of $$B$$ only $$\beta_i$$ is required to compute the results of iteration $$i+1$$.


The final step will be slightly different, again due to the structure of $$B$$:

$$
\begin{array}{l l}
A \mathbf{q}_n &= \alpha_n \mathbf{p}_n + \beta_{n-1} \mathbf{p}_{n-1} \\
A^\dagger \mathbf{p}_n &= \alpha_n \mathbf{q}_n
\end{array}
$$

After this, the $$\alpha$$ and $$\beta$$ coefficients and the $$\mathbf{p}_i$$ and $$\mathbf{q}_i$$ vectors can be packed into matrices and used in subsequent computations.

In [sparse-linear-algebra](https://hackage.haskell.org/package/sparse-linear-algebra) I implemented this control flow using the [State monad](https://hackage.haskell.org/package/mtl-2.2.1/docs/Control-Monad-State-Strict.html), which makes the partial datastructures produced during iteration invisible to the rest of the program, by construction.

As a functional programmer, I found this explanation of the Golub-Kahan-Lanczos algorithm to be easier to follow and implement than that found in Golub and Van Loan's textbook, which employs in-place mutation (i.e. matrices are overwritten at each iteration).

Stay tuned for part 2, in which we will complete the explanation of the singular value decomposition algorithm.



## References

Dongarra, Jack, et al. (eds.), [Templates for the Solution of Algebraic Eigenvalue Problems: a Practical Guide](http://www.netlib.org/utk/people/JackDongarra/etemplates/node198.html)

Golub, Gene H.; Van Loan, Charles F. (1996), Matrix Computations (3rd ed.), Johns Hopkins

