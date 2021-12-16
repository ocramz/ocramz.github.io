---
layout: post
title: A personal retrospective on NeurIPS'21
date: 2021-12-15
categories: machine-learning events
---

# Introduction

Neural Information Processing Systems (NeurIPS) is nowadays one of the foremost conference on machine learning, with thousands of attendees and accepted contributions (papers, talks, tutorials, social events, panels, demonstrations, challenges and so on). It's a wonderful event, powered by a loving and ever-growing community. The size of the event can also be somewhat overwhelming if you don't carefully allocate your time if you happen (like I do) to have an even passing interest in more than one presented topic.

Here I collect some notes on my 2021 experience as an attendee and author, as well as all the links I could record on the fly. I could only attend a fraction of the talks I'm interested in, but fortunately all the talks are recorded for posterity.



# Dec 6

*Tutorial : Pay Attention to What You Need: Do Structural Priors Still Matter in the Age of Billion Parameter Models?*

https://neurips.cc/virtual/2021/tutorial/21891

The recent empirical success (and theoretical systematization) of graph learning is making us reflect on the role of structure (relationships, grammar, ontologies, syntax) in inference. The field of AI is also coming full-circle (once again) and re-assessing "symbolic" approaches, after their premature demise at the hand of connectionist methods in the late '90s.
This tutorial touches on a few fundamentals such as the connections between group theory and differential geometry (by Seb Racaniere), as well as giving perspective on their role towards better domain-specific inference models for dealing with point clouds, relational models, graphs and so on.

## Tutorial : Machine Learning and Statistics for Climate Science

slides - https://neurips.cc/media/neurips-2021/Slides/21893_0Ue6ONI.pdf

Unfortunately I couldn't attend this workshop but it's very dear to my heart so I intend to return to it at a later time.


# Dec 7

## Tutorial : Self-Supervised Learning: Self-Prediction and Contrastive Learning 

https://neurips.cc/virtual/2021/tutorial/21895

Self-supervision is a very interesting family of techniques for producing data labels via a generative process : the dataset is "augmented" by distorting the data instances in various ways, e.g. rotating or blurring images, or masking parts of a sentence in the case of text. Classifiers are then trained on this augmented data, which has shown to improve performance in a number of downstream tasks.

How we can produce data augmentations that are meaningful to the data and task at hand is one of the open research questions.

## Keynote : How Duolingo Uses AI to Assess, Engage and Teach Better

Luis von Ahn is one of the founders of Duolingo, a mobile app for learning language. He showed how the app makes heavy use of A/B testing and analyzes systematically all learning sessions to produce a comfortable yet challenging learning experience with spaced repetition, well-placed nudges etc. They have an ML team that made fundamental advances in active learning and multi-armed bandits.


# Dec 8

## Social : BigScience

https://bigscience.huggingface.co/

BigScience is a year-long collaborative experiment on large multilingual models and datasets, aka the "LHC of NLP". I was not directly involved but find it a very meaningful initiative to activate academia and society towards understanding and improving natural language processing for everybody.

# Dec 9

## Keynote : Optimal Transport: Past, Present, and Future

Optimal transport ("what is the optimal way to transport a distribution into another one?") is one of those topics that seemingly pops up everywhere from operations research to biology to high-dimensional learning.

## Dec 10 


# Dec 13 - Workshops 1



# Dec 14 - Workshops 2


## Data-centric AI 

https://neurips.cc/virtual/2021/workshop/21860

* Ratner, Re - The future of data-centric AI

I've been very intrigued by the Snorkel project and weak labeling/supervision in general since learning about them a few years back. Their approach (based on programmatic labeling functions) will likely prove popular and effective within the private sector and in particular among highly-regulated industries where data movement is either hard or impossible.


## Advances in programming languages and neurosymbolic systems - AIPLANS'21 

https://aiplans.github.io/

This workshop's ambitious program was to bring together researchers from the AI and programming languages communities, and create a dialogue around the interplay of domain-specific languages and mechanical reasoning. The talks spanned formal logic, machine learning techniques, theorem proving and more, showing what's possible when machines are made to collaborate with humans.

I submitted a short paper to AIPLANS (Staged compilation of tensor expressions - https://openreview.net/forum?id=5TCfWXk2waG), with an early experiment on applying meta-programming techniques to a tensor contraction DSL for Haskell.

* Weiss - Thinking like Transformers

| Title | Authors | Conference | Link |
|---|---|---|
|A Formal Hierarchy of RNN Architectures | | | https://aclanthology.org/2020.acl-main.43/ |

* Tenenbaum - Building machines that learn and think like people by learning to write programs

Prof Tenenbaum is an established scientist and gifted speaker, and gave one of his inspiring talks on his group's recent results. Namely, his research strives to replicate the flexibility of general intelligence using generative models of the world (in this case mediated by programs).

Title | Authors | Conference/Journal | Link
---|---|---
The child as hacker | Rule et al | Trends in CogSci | http://colala.berkeley.edu/papers/rule2020child.pdf
Learning Task-General Representations with Generative Neuro-Symbolic Modeling | | ICLR'21 | https://openreview.net/forum?id=qzBUIzq5XR2 
Learning to learn generative programs with Memoised Wake-Sleep | Hewitt et al | UAI'20 | http://proceedings.mlr.press/v124/hewitt20a.html
DreamCoder : Growing generalizable, interpretable knowledge with wake-sleep Bayesian program learning | | | https://arxiv.org/abs/2006.08381 
Leveraging Language to Learn Program Abstractions and Search Heuristics - Wong et al - ICML'21 https://arxiv.org/abs/2106.11053
Communicating Natural Programs to Humans and Machines | | |  https://arxiv.org/abs/2106.07824 (+ the associated LARC dataset https://github.com/samacqua/LARC  )

Related links : 

Title | Authors | Conference/Journal | Link
---|---|---
The Abstraction and Reasoning Corpus (ARC) | | | https://github.com/fchollet/ARC
Planning domain definition language (PDDL) | | | https://en.wikipedia.org/wiki/Planning_Domain_Definition_Language

* Duvenaud - Dex tutorial 

Dex is an experimental array-based programming language (https://github.com/google-research/dex-lang) and David gave us a live-coding tutorial as well as his (very relatable) recollections as a scientific programmer and researchers (starting from buggy Matlab scripts and their consequences on research), to Python, to type-checked functional languages such as Dex and its underlying Haskell.

Dex supports checked mutation using an effect system taken from Koka (https://koka-lang.github.io/koka/doc/index.html).

* Rush - Differential inference

Sasha gave an introduction to the use of automatic differentiation for doing Bayesian inference on networks of discrete random variables , based on the theory from Darwiche https://arxiv.org/abs/1301.3847
