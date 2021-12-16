---
layout: post
title: A personal retrospective on NeurIPS'21
date: 2021-12-15
categories: machine-learning events
---

# Introduction

[Neural Information Processing Systems (NeurIPS)](https://neurips.cc/) is nowadays one of the foremost conferences on machine learning, with thousands of attendees and accepted contributions (papers, talks, tutorials, social events, panels, demonstrations, challenges and so on). It's a wonderful event, powered by a loving and ever-growing community. The size of the event can also be somewhat overwhelming if you don't carefully allocate your time if you happen (like I do) to have an even passing interest in more than one presented topic.

It's hard to do justice to the whole conference in a few sentences. What we can notice from a great height is that machine learning has come of age, and new applications that act either as economic enablers or instruments of oppression appear on a daily basis. The NeurIPS community expanded to include many more voices than just the technical contributions, and that's a very good thing.

Personally, what I enjoyed the most falls roughly in two categories: AI as a social and economic enabler and the study of intelligence _per se_.

* Data programming, learning on relational data, federated learning all fall in this bin; on one hand they let us make sense of complex, real-world signals, and hopefully make better decisions. On the other they promise to empower smaller entities than the usual tech titans, by re-distributing the economic returns of data ownership.

* The study of intelligence for its own sake is as old as the field and we're nowhere close to even formulating a well-posed question for this. However generative, neuro-symbolic approaches like those advocated by Tenenbaum and collaborators are a source of great insight and better questions, which is ultimately what matters in science.

Here I collect some loose notes on my 2021 experience as an attendee and author, as well as all the links I could record on the fly. I could only attend a fraction of the live events, but fortunately all the talks are recorded for posterity.


---

# December 6

**[Tutorial : Pay Attention to What You Need: Do Structural Priors Still Matter in the Age of Billion Parameter Models?](https://neurips.cc/virtual/2021/tutorial/21891)**

The recent empirical success and theoretical systematization of graph learning is making us reflect on the role of structure (relationships, grammar, ontologies, syntax) in inference. The field of AI is also coming full-circle (once again) and re-assessing "symbolic" approaches, after their premature demise at the hand of connectionist methods in the late '90s.
This tutorial touches on a few fundamentals such as the connections between group theory and differential geometry (by Seb Racaniere), as well as giving perspective on their role towards better domain-specific inference models for dealing with point clouds, relational models, graphs and so on.

**Tutorial : Machine Learning and Statistics for Climate Science**

[slides](https://neurips.cc/media/neurips-2021/Slides/21893_0Ue6ONI.pdf)

Unfortunately I couldn't attend this workshop but it's very dear to my heart so I intend to return to it at a later time.

---

# December 7

**[Tutorial : Self-Supervised Learning: Self-Prediction and Contrastive Learning](https://neurips.cc/virtual/2021/tutorial/21895)**

[slides](https://neurips.cc/media/neurips-2021/Slides/21895.pdf)

Self-supervision is a very interesting family of techniques for producing data labels via a generative process : the dataset is "augmented" by distorting the data instances in various ways, e.g. rotating or blurring images, or masking parts of a sentence in the case of text. Classifiers are then trained on this augmented data, which has shown to improve performance in a number of downstream tasks.

How we can produce data augmentations that are meaningful to the data and task at hand is one of the open research questions.

**Joint Affinity poster session**

This was the first poster session of the conference; I will only say that while GatherTown is a nice platform for simulating spatially-distributed conversations like those that would happen in an in-person conference, it's _too_ accurate as a replica. You waste minutes just making your avatar walk around the venue, which is sadly mostly empty. I think navigation and visual summarization could still be improved.

**Keynote : How Duolingo Uses AI to Assess, Engage and Teach Better**

Luis von Ahn is one of the founders of Duolingo, a mobile app for learning language. He showed how the app makes heavy use of A/B testing and analyzes systematically all learning sessions to produce a comfortable yet challenging learning experience with spaced repetition, well-placed nudges etc. They have an ML team that made fundamental advances in active learning and multi-armed bandits.

---

# December 8

**[Social : BigScience](https://bigscience.huggingface.co/)**

BigScience is a year-long collaborative experiment on large multilingual models and datasets, aka the "LHC of NLP". I was not directly involved but find it a very meaningful initiative to activate academia and society towards understanding and improving natural language processing for everybody.

---

# December 9

**Keynote : Optimal Transport: Past, Present, and Future**

Optimal transport ("what is the optimal way to transport a distribution into another one?") is one of those topics that seemingly pops up everywhere from operations research to biology to high-dimensional learning. Alessio Figalli recently won a Fields medal on the subject, and he gave a good (albeit somewhat dry) overview on the history and application of the optimal transport problem.

---

# December 11

**[Generative modeling](https://neurips.cc/virtual/2021/session/44855)

* Rozen - Moser Flow: Divergence-based Generative Modeling on Manifolds

A recent breakthrough on a universal density approximator process for general manifolds (spheres, tori, etc.), demonastrated with examples from climate science.

---

# December 13 - Workshops 1

**[New Frontiers in Federated Learning: Privacy, Fairness, Robustness, Personalization and Data Ownership ](https://neurips.cc/virtual/2021/workshop/21829)**

* Pentland - Building a New Economy: Federated Learning and Beyond

    Data ownership, individual and collective. Value of individual data points vs data in aggregate

    Knowing flows (money, people) allows better planning

    Community-owned data (real-time census) : employment, disease control, public transit, economic growth
    
    NRECA : cooperatives (not companies or the state) built 56% of US electric grid
    
    [Atlas of opportunity](https://opportunity.mit.edu/)

**[Differentiable programming](https://neurips.cc/virtual/2021/workshop/21882)**

Automatic differentiation has become ubiquitous, many languages adopt it either as a library or a first-class primitive. As a result, complex physical models have become differentiable (in some sense), and the workshop showcased the effect of this on molecular dynamics, climate and weather prediction, etc.

---

# December 14 - Workshops 2


**[Data-centric AI](https://neurips.cc/virtual/2021/workshop/21860)**


* Ratner, Re - The future of data-centric AI

    I've been very intrigued by the Snorkel project and weak labeling/supervision in general since learning about them a few years back. Their approach (based on programmatic labeling functions) will likely prove popular and effective within the private sector and in particular among highly-regulated industries where data movement is either hard or impossible.


**[Advances in programming languages and neurosymbolic systems - AIPLANS'21](https://aiplans.github.io/)**

This workshop's ambitious program was to bring together researchers from the AI and programming languages communities, and create a dialogue around the interplay of domain-specific languages and mechanical reasoning. The talks spanned formal logic, machine learning techniques, theorem proving and more, showing what's possible when machines are made to collaborate with humans.

I submitted a short paper to AIPLANS ( [Staged compilation of tensor expressions](https://openreview.net/forum?id=5TCfWXk2waG) ), with an early experiment on applying meta-programming techniques to a tensor contraction DSL for Haskell.

* Weiss - Thinking like Transformers

    Gail introduced us to a programming language that reproduces the semantics of a transformer architecture. This comparison made everybody's brain gears spin very quickly and questions arose about the expressivity of this language and a possible Chomsky hierarchy of deep language models, to which Gail promptly replied with an ACL'20 article she co-wrote :

    [A Formal Hierarchy of RNN Architectures](https://aclanthology.org/2020.acl-main.43/)

* Tenenbaum - Building machines that learn and think like people by learning to write programs

    Prof Tenenbaum is an established scientist and gifted speaker, and gave one of his inspiring talks on his group's recent results. Namely, his research strives to replicate the flexibility of general intelligence (learning in babies, in fact) using generative models of the world (in this case mediated by programs).

    Title | 
--- | ---
[The child as hacker](http://colala.berkeley.edu/papers/rule2020child.pdf) | Trends in CogSci 
[Learning Task-General Representations with Generative Neuro-Symbolic Modeling](https://openreview.net/forum?id=qzBUIzq5XR2) | ICLR'21 
[Learning to learn generative programs with Memoised Wake-Sleep](http://proceedings.mlr.press/v124/hewitt20a.html) | UAI'20 
[DreamCoder : Growing generalizable, interpretable knowledge with wake-sleep Bayesian program learning](https://arxiv.org/abs/2006.08381 ) |
[Leveraging Language to Learn Program Abstractions and Search Heuristics](https://arxiv.org/abs/2106.11053) | ICML'21 
[Communicating Natural Programs to Humans and Machines](https://arxiv.org/abs/2106.07824) |
[LARC dataset](https://github.com/samacqua/LARC) | 

    Related links : 

    [The Abstraction and Reasoning Corpus (ARC)](https://github.com/fchollet/ARC)
    
    [Planning domain definition language (PDDL)](https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language)

* Duvenaud - Dex tutorial 

    [Dex](https://github.com/google-research/dex-lang) is an experimental array-based programming language  and David gave us a live-coding tutorial as well as his (very relatable) recollections as a scientific programmer and researchers (starting from buggy Matlab scripts and their consequences on research), to Python, to type-checked functional languages such as Dex and its underlying Haskell.

    Dex supports checked mutation using an effect system taken from [Koka](https://koka-lang.github.io/koka/doc/index.html).

* Rush - Differential inference

    Sasha gave an introduction to the use of automatic differentiation for doing Bayesian inference on networks of discrete random variables , based on the theory from Darwiche [A Differential Approach to Inference in Bayesian Networks](https://arxiv.org/abs/1301.3847).
