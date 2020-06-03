import socket
import math
import random
import numpy as np

# More info about BO is here:
# https://github.com/fmfn/BayesianOptimization
from bayes_opt import BayesianOptimization

##### The function for optimization 
def optimize_function(motor_1, motor_2):
    global iteration_count
    global sample_times
    global penalty_rate

    # Send the parameters to processing 
    send_data = bytes([int(motor_1)])
    conn.sendall(send_data)
    send_data = bytes([int(motor_2)])
    conn.sendall(send_data)
    
    # We start collecting data sent from processing
    rec_count = 0
    received_all = []
    while(rec_count< sample_times):
        data = conn.recv(1024)
        if data: 
            received = round(float(data.decode("utf-8")) , 0)
            received_all.append(received)
            rec_count += 1
    received_all = np.array(received_all)
    # Calculate the recognition rate
    # (Just averaging all the correctness)
    rec_rate = np.sum(received_all) / sample_times

    # In the case user press 0 from processing GUI, the whole recognition rate will be 0
    # We should penalize this situation and give a very negative score (-1) 
    if (rec_rate == 0):
        final_value = -1
    # Otherwise (the case that the user provide normal responses 1 or 2)
    # we should add a resolution penalty
    else:
        resolution_penalty = motor_2 / 45 # devided by 45, so it's a ration between 0 - 1, so is the rec_rate
        final_value = rec_rate - penalty_rate * resolution_penalty # Then, times an arbitrary rate
    return final_value 


##### Main function start here
HOST = '' 
PORT = 50007              # Arbitrary non-privileged port

# Setup server
audio = []
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((HOST, PORT))
s.listen(1)
print ('Server starts, waiting for connection...')
conn, addr = s.accept()
# Now the connection is done
print('Connected by', addr)

# Every iteration will require 4 data from processing
sample_times = 8  
penalty_rate = 0.5
iteration_count = 0

### Setting parameter bounds
### motor_1 is the target degree of the first cue
### motor_2 is the difference between the first cue and the second cue 
### eg, if motor_1 = 90, motor_2 = 30, when the arduino generates different cues,
### the first cue will be 90 degress, and the second cue will be 60 (90 - 30).
pbounds = {'motor_1': (0, 100), 'motor_2': (1, 45)} 

### Setup the optimizer 
optimizer = BayesianOptimization(
    f=optimize_function,
    pbounds=pbounds,
    random_state=1,
)

### Optimizing...
### init_points <- How many random steps you want to do
### n_iter <- How many optimization steps you want to take
optimizer.maximize(
    init_points=20,
    n_iter=20,
)

### Print the best
print(optimizer.max)

### If you want to print all the iterations, uncomment below 2 lines
#for i, res in enumerate(optimizer.res):
#    print("Iteration {}: \n\t{}".format(i, res))

# Close the server
conn.close()