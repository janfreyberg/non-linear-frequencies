# Equivalent non-linear responses to steady-state stimulation in autism

This is the github repo for an experiment on non-linear (ie. harmonic/subharmonic) frequencies in autism.

It adapts the Labecki et al. 2016 neural mass model to python and runs it with various inhibitory gain terms. This can be found in [01-neural-mass-model.ipnyb](01-neural-mass-model.ipynb)

It also has an experimental script to present SSVEPs: [monocular_ssvep.m](monocular_ssvep.m)

You can then analyse EEG data recorded during these sessions with this notebook: [02-nonlinear-eeg-analysis.ipynb](02-nonlinear-eeg-analysis.ipynb)

You will need to pip install:

- autoreject
- ssvepy
- mne
- tqdm
- ipywidgets

and all the other standard scientific tools.
