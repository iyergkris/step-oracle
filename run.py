#!/usr/bin/env python
"""
Created to Collect Real-time step count from an iPhone, which in turn collects it from an Apple Watch.
Authors: Gopal Iyer, Vikas Iyer Github: @iyergkris, @vikasiyer
For: Numenta HTM Challenge Hackathon
11/3/2015: 14:05
Cleanup:
"""

import sys
import importlib
import datetime
import csv
import nupic_anomaly_output
import socket

from optparse import OptionParser
from nupic.data.inference_shifter import InferenceShifter
from nupic.frameworks.opf.modelfactory import ModelFactory

DEFAULT_PLOT = False
DATETIME_FIELDNAME = 'datetime'
# Format in Input file: 2015/08/19 12:00:00
DATE_FORMAT = "%Y/%m/%d %H:%M:%S"
INPUT_FILE_NAME = "step-count-data"
DATA_DIR = "."
SERVER_ADDRESS = "192.168.210.166"
SERVER_PORT = 8888

# Options parsing.
parser = OptionParser(
  usage="%prog [options]"
)
parser.add_option(
  "-p",
  "--plot",
  action="store_true",
  default=DEFAULT_PLOT,
  dest="plot",
  help="Plot results in matplotlib instead of writing to file "
       "(requires matplotlib).")
parser.add_option(
  "-l",
  "--log",
  action="store_true",
  default=False,
  dest="log",
  help="Compute the log of anomaly likelihood "
       "(this is more useful for plotting)")

def getModelParamsFromName(inputdataName):
   importName = "model_params.%s_model_params" % (
     inputdataName.replace(" ", "_").replace("-", "_")
   )
   print "Importing model params from %s" % importName
   try:
     importedModelParams = importlib.import_module(importName).MODEL_PARAMS
   except ImportError:
     raise Exception("No model params exist for '%s'. Run swarm first!"
                     % inputdataName)
   return importedModelParams


def createModel(modelParams):
  model = ModelFactory.create(modelParams)
  model.enableInference({"predictedField": "steps"})
  return model

"""
This is the main function to push data into the HTM and get prediction and anomalyScore data
Data source is being replaced with the Step count coming from an iPhone and Apple Watch real time data source
11/3/15: 14:05
Cleanup:
"""
def runModel(inputData, model, plot, logLikelihood):

  inputFile = open(inputData, "rb")
  csvReader = csv.reader(inputFile)
  # skip header rows
  csvReader.next()

  shifter = InferenceShifter()
  if plot:
    output = nupic_anomaly_output.NuPICPlotOutput([INPUT_FILE_NAME], logLikelihood)
  else:
    output = nupic_anomaly_output.NuPICFileOutput([INPUT_FILE_NAME], logLikelihood)

  for row in csvReader:
    timestamp = datetime.datetime.strptime(row[0], DATE_FORMAT)
    value = float(row[1])
    if value is not None:
      result = model.run({
        "timestamp": timestamp,
        "steps": value
      })
      if plot:
        result = shifter.shift(result)
      prediction = result.inferences["multiStepBestPredictions"][1]
      anomalyScore = result.inferences["anomalyScore"]
    #   print "Anomaly score %s" % anomalyScore
      output.write(timestamp, value, prediction, anomalyScore)
  inputFile.close()
  """
  Below starts the code for Opening a UDP socket on port 8888 and waiting for message from client.
  On receiving message from client (iPhone), it is fed into the HTM model (no data format checks for now >> hackathon)
  Model returns prediction and anomaly data. Only prediction data is sent back to the Client (iPhone)
  11/3/2015: 14:32:
  Cleanup
  """
  # Create a TCP/IP socket
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  # Bind the socket to the port
  server_address = (SERVER_ADDRESS, SERVER_PORT)
  print >>sys.stderr, 'starting up on %s port %s' % server_address
  sock.bind(server_address)
  while True:
    print >>sys.stderr, '\nwaiting to receive message'
    data, address = sock.recvfrom(4096)
    print >>sys.stderr, 'received %s bytes from %s' % (len(data), address)
    print >>sys.stderr, data
    # code to feed into NuPIC HTM Neural machine
    watch_time, watch_steps = data.split(",")
    timestamp = datetime.datetime.strptime(watch_time, DATE_FORMAT)
    consumption = float(watch_steps)
    result = model.run({
      "timestamp": timestamp,
      "steps": value
    })
    # result.metrics = metricsManager.update(result)
    # print ("Prediction=%f" % (result.metrics["multiStepBestPredictions:multiStep:"
    #                        "errorMetric='altMAPE':steps=1:window=1000:"
    #                        "field=kw_energy_consumption"]))
    # predictForString = result.metrics["multiStepBestPredictions:multiStep:"
    #                        "errorMetric='altMAPE':steps=1:window=1000:"
    #                        "field=kw_energy_consumption"]
    if plot:
      result = shifter.shift(result)

    prediction = result.inferences["multiStepBestPredictions"][1]
    print "Prediction: %s" % prediction
    anomalyScore = result.inferences["anomalyScore"]
    output.write(timestamp, value, prediction, anomalyScore)

    if prediction:
        sent = sock.sendto(str(prediction), address)
        print >>sys.stderr, 'sent %s bytes back to %s' % (sent, address)

  output.close()



if __name__ == "__main__":
  (options, args) = parser.parse_args(sys.argv[1:])

  plot = options.plot

  # data = fetchData(url, river, stream, aggregate,
  #                  {'limit': options.dataLimit})
  # (min, max) = getMinMax(data, field)

  modelParams = getModelParamsFromName(INPUT_FILE_NAME)
  model = createModel(modelParams)
  inputfilepath = "%s/%s.csv" % (DATA_DIR,INPUT_FILE_NAME.replace(" ","_"))
  runModel(inputfilepath, model, plot, options.log)
