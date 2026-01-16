---
layout: post
title: Overhauling a ML project for long-term maintenance and production
date: 2025-10-10
categories: Python Pytorch MLOps
og-image: /images/renovations.png
---

## Introduction

Recently I had some side-project time, so I picked up a ML system I had to put on hold months ago for various reasons.

So I sat in front of it, and realized in a mild panic that I didn't remember how it works!

While prototyping, the project had accumulated a bunch of scripts, model checkpoints, logs, database tables, data directories, Jupyter notebooks, so reconstructing a "known-good" state was not straightforward.

So I started what I realized is the same set of activities as reviving any other "brown-field" project: tests, docs, automation.






## Tests

### Unit tests

### Property/Metric tests

## Documentation

## CLI flags

ML code usually depends on a bunch of hyper-parameters, so it's useful to break these out.

Dataset construction and training take some time and resources, so CLI flags that can set various parameters to small values for unit testing and CI will be useful, e.g. dataset size, number of epochs.

## Continuous Integration

```yaml
name: python-CI
on: [push]

jobs:
  python-tests:
    runs-on: ubuntu-latest
    steps:
      - name: checkout 
        uses: actions/checkout@v5
      - uses: actions/setup-python@v4
        with:
          python-version: '3.12'
          cache: 'pip'
      - name: Install system and Python deps
        run: |
          sudo apt-get update && sudo apt-get install -y ...
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      - name: prepare data
        run: |
          python -m data_prep
      - name: pytest
        run: |
          pytest -v tests_ci.py

caching python deps esp NVidia drivers
```