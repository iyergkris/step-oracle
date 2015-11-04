# htm-challenge

This is a submission to the Numenta HTM Challenge 2015

# Requires

- matplotlib (if you want to use the `--plot` option) [recommended]
- [NuPIC](https://github.com/numenta/nupic)

## Run it
### On a Server
    ./run.py

With no options, this script will produce an output file for the existing Apple Watch Steps data and wait for new data from a client.

## Plot it

Use the --plot option to plot the Prediction data and Anomaly scores.

## Options

Options:
  -h, --help  show this help message and exit
  -p, --plot  Plot results in matplotlib instead of writing to file (requires
              matplotlib).
  -l, --log   Compute the log of anomaly likelihood (this is more useful for
              plotting)
```
# What it does

Server collects real-time Step count data from an Apple Watch with an iPhone app as a client. The server takes the input, feeds it through the HTM learning algorithm responds with a predicted step count data back to the iPhone.

# iPhone app
