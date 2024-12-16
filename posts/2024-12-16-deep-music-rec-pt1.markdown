---
layout: post
title: Deep music recommendation - pt. 1
date: 2024-12-16
categories: machine-learning
---


# Introduction 


<!-- ![Preference graph](prefs_graph.png "Preference graph") -->

Can we learn a music recommendation model from raw audio samples and a preference graph?

<img src="/images/prefs_graph.png" width=400/>




# Dataset

The music preference graph and audio samples were constructed from public sources.


# Model

The embedding model is a variation of the <a href="https://sander.ai/2014/08/05/spotify-cnns.html">"Spotify CNN" introduced here back in 2014.</a>

The NN architecture can be broken down into these blocks:

* the audio samples are first transformed into mel-spectrograms (which bins frequencies according to a human perceptual model)
* the STFT representation is fed to two convolutional stages, i.e. `Conv1d` followed by a `ReLU` nonlinearity.
* lastly, there is a linear layer that projects to our embedding space.

The main change from the Spotify CNN is the loss function: here I use a <a href="https://pytorch.org/docs/stable/generated/torch.nn.TripletMarginLoss.html">triplet loss</a> based on the cosine distance:

$$
L = \sqrt{2 * 1 - (s_c)}
$$
