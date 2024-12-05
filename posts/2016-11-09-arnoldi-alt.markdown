---
layout: post
title: A simple derivation of the Arnoldi algorithm
date: 2016-11-09
categories: mathematics tutorials
---

The Arnoldi iteration is a numerically stable algorithm to produce an orthonormal basis for the Krylov subspace associated with a matrix $$A \in \mathbb{R}^{m \times m}$$ and a vector as $$b \in \mathbb{R}^m$$.
The Krylov subspace of order $$r \leq m$$ associated with $$A$$ and $$b$$ is defined as $$K_r := span \lbrace b, Ab, A^b \cdots A^{r-1}b \rbrace$$. The spanning vectors of $$K_r$$ are not orthogonal.

The algorithm is related to the Gram-Schmidt orthogonalization procedure and it produces an upper Hessenberg matrix $$H_n$$ (i.e. that is zero below the first subdiagonal) and a matrix $$Q$$ having orthonormal columns such that $$A Q_{i - 1} = Q_i H_i$$.
With the subscripts we signify that at iteration $$i$$ there are $$i$$ columns of $$Q$$ available (we denote this as $$Q_{i-1}$$) and we must find the $$i+1$$th.

The method starts from a normalized vector $$\mathbf{q}_1$$ and iteratively produces the next basis vectors. This process eventually "breaks down" since the norm of the iterates $$\mathbf{q}_i$$ decreases, at which point the algorithm is said to have converged.



If we consider for example the second iteration, we have

$$
A \underbrace{\left[
  \begin{array}{c|c}
  \mathbf{q}_1 & \mathbf{q}_2 
  \end{array} 
  \right] }_{Q_1} = \underbrace{\left[
    \begin{array}{c|c|c}  
    \mathbf{q}_1 & \mathbf{q}_2 & \mathbf{q}_3
    \end{array}\right] }_{Q_2}

\left[ \begin{array}{c c}
 h_{1, 1} & h_{1, 2} \\
 h_{2, 1} & h_{2, 2}  \\
 0 & h_{3, 2} 
\end{array} \right]

=

\left[ 
  \begin{array}{c | c} 
  h_{1, 1} \mathbf{q}_1 + h_{2, 1} \mathbf{q}_2 &  h_{1, 2} \mathbf{q}_1 + h_{2, 2} \mathbf{q}_2 + h_{3, 2} \mathbf{q}_3
\end{array}
\right]
$$

which yields the recursion:

\[
  \mathbf{q}_3 = \frac{A \mathbf{q}_2 - \sum\limits_{i=1}^2 h_{i, 2} \mathbf{q}_i}{h_{3, 2}}.
  \]



In the previous equation the entries of the $$H$$ matrix are obtained by exploiting the orthonormality of the $$\mathbf{q}$$ vectors, i.e. 

$$
\langle \mathbf{q}_i, \mathbf{q}_j \rangle = \delta_{i, j} =
     \begin{cases} 1 & i = j\\
                   0 & \mathrm{otherwise}
     \end{cases}
$$

that is, we project the last equation above onto the basis vectors obtained so far, in order:

$$
\langle \mathbf{q}_1, \mathbf{q}_3 \rangle = \frac{\langle \mathbf{q}_1, A \mathbf{q}_2 \rangle - \left[ h_{1, 2} \langle \mathbf{q}_1, \mathbf{q}_1 \rangle  + h_{2, 2} \langle \mathbf{q}_1, \mathbf{q}_2 \rangle \right] }{h_{3, 2}}
$$

thus obtaining $$h_{1,2} = \langle \mathbf{q}_1, A \mathbf{q}_2 \rangle $$ (and analogously for $$h_{2, 2}$$), whereas $$h_{3, 2}$$ is obtained by the normalization condition $$\| \mathbf{q_3} \| = 1$$.
At this point, it is straightforward to justify the usual [nested-loop representation of the algorithm](https://en.wikipedia.org/wiki/Arnoldi_iteration#The_Arnoldi_iteration).
The normalizing coefficient is also used as a breakdown test, i.e. when $$h_{i+1, i} \leq \epsilon$$ e.g. $$10^{-12}$$ in double precision floating point arithmetic, the algorithm terminates.

