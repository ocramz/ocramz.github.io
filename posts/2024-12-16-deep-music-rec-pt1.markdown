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

This project started from this question, and the curiosity to combine together a few topics I've been curious about recently: audio processing, contrastive learning and graphs.

# Technical summary

This is an audio embedding model, trained to produce embeddings that are close if their respective graph distances are small. In other words, I used the preference graph as supervision labels for the audio embeddings: in a contrastive setting, we consider an "anchor" sample, a positive and a negative one, which are here distinguished by their graph distance.

It becomes a (context-free, static, non-personalized) recommendation model by:

* embedding a music collection
* storing it into an index (here I used SQLite)
* embedding a query (a new music track) with the same model and looking up the most similar ones from the index.

# Dataset

In order to limit the size of the dataset I only considered music samples having the largest <a href="https://en.wikipedia.org/wiki/Centrality#Degree_centrality">degree centrality</a>, i.e. the largest numnber of inbound edges (recommendations). In simpler words, these are the most recommended albums in the dataset.

The music preference graph and audio samples were constructed from public sources.


# Model, take 1

I initially experimented with a <a href="https://pytorch-geometric.readthedocs.io/en/latest/generated/torch_geometric.nn.conv.GCNConv.html#torch_geometric.nn.conv.GCNConv">graph convolutional network</a>. The idea behind this was to:

* Embed the most central audio samples
* Diffuse the embeddings out to all the remaining nodes with the GCN.

I dropped this approach because even with 1 or 2 GCN layers it required an awful amount of memory, and is clearly wasteful because we need to begin with random or zero embeddings for all the nodes that don't have audio attached.

# Model, take 2

The embedding model is closely related to the <a href="https://sander.ai/2014/08/05/spotify-cnns.html">"Spotify CNN" introduced here back in 2014.</a>

The NN architecture can be broken down as follows:

* the audio samples are first transformed into mel-spectrograms (which bins frequencies according to a human perceptual model);
* the STFT representation is fed to 3 convolutional stages, i.e. `Conv1d` interleaved with a max-pooling operation (window size 4). Both the convolutions and the pooling are done over the time axis only.
* After the last 1D convolution there is an average pooling operation over the whole time axis. The result of this is a vector having size `n_mels` for each sample.
* Next, there is a `Linear` layer that projects the frequency bins to our embedding space,
* followed by a $L_2$ normalization step.

The main change from the Spotify CNN is the loss function: here I use a <a href="https://pytorch.org/docs/stable/generated/torch.nn.TripletMarginLoss.html">triplet loss</a> based on the <a href="https://en.wikipedia.org/wiki/Cosine_similarity#Cosine_distance">cosine "distance"</a>, defined as:

$$
d(x_1, x_2) := \sqrt{2 ( 1 - (x_1 \cdot x_2)) }
$$

(NB: the definition above assumes unit-norm vectors $x_1$ and $x_2$).
