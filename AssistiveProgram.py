def range_greater_than_grid_diam (D) :
        topology = open ("topology.txt",'w') # Write to file

        for i in range (D*D):
                for j in range (D*D):
                       if (i != j):
                               line = str(i)  + " " +  str(j) + " 0"
                               line = str(j)  + " " +  str(i) + " 0"
                               topology.write(line)
                               topology.write("\n")
        topology.close()

import math

# Input values

D = int(input ("Enter grid dimension: "))
R = float(input ("Enter range: "))


while True:
	if ((D<1) | (D>8)) :
		print ("D out of bounds!")
		D = int(input ("Enter grid dimension: "))
	else :
		break


while True:
	if (R<=0) :
		print ("R out of bounds!")
		R = float(input ("Enter range: "))
	else :
		break

# Write NumberOfSensors to an external file for mySimaltion to Read

NumberOfSensors = D*D
id = 0

NumofSensors = open ("NumofSensors.txt",'w') # Write to file
NumofSensors.write(str(NumberOfSensors-1))
NumofSensors.close()

# Create the Grid Matrix

grid = [[0 for i in range (D)] for j in range (D)]

for i in range (D):
	for j in range (D):
		grid [i][j] = id
		id = id + 1

#Start generating topology file

distance = 1
diag_distance = math.sqrt(2)
max_diag_distance = 0
count = 0
new_distance = 0
new_count = 0

topology = open ("topology.txt",'w')

if (R >= distance):
    if (math.sqrt(2*(D*D)) <= R) : range_greater_than_grid_diam(D) # Every node can reach every node
    else :

            # Find max diagonal distance
            while max_diag_distance <= R :
                    count += 1
                    max_diag_distance = count*diag_distance

            new_count = count
            new_distance = max_diag_distance
            while ((new_distance >= R) & (new_count > 0)):
                    new_count += -1
                    new_distance = math.sqrt(count*count + new_count*new_count)

            if new_count == 0 :
                if (R < count):
                    new_count = -1

            # Write all certain pairs (which belong to a row or column same as or less that max reachable diagonal element)

            for i in range (D):
                    for j in range (D):
                            for new_i in range (i - count + 1 , i + count):
                                    for new_j in range (j - count + 1, j + count):
                                            if ((new_j >= 0) & (new_i >= 0) & (new_j< D) & (new_i<D) & (((new_i != i) | (new_j != j)))):
                                                    line = str(grid [i][j])  + " " +  str(grid [new_i][new_j]) + " 0"
                                                    topology.write(line)
                                                    topology.write("\n")

                            if new_count > 0 :

                                # Check column after the max reachable diagonal element's and add the right pairs to file
                                for new_j in range (j - new_count, j + new_count +1 ):
                                        if ((new_j >=0) & (new_j < D) & (i +count <D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i+count][new_j]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")
                                        if ((i -count >= 0) & (new_j>= 0) & (new_j < D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i-count][new_j]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")

                                # Check row after the max reachable diagonal element's and add the right pairs to file
                                for new_i in range (i - new_count , i + new_count + 1):
                                        if ((new_i>= 0) & (new_i< D) & (j + count<D)):
                                                line = str(grid [i][j])  + " " +  str(grid [new_i][j+count]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")
                                        if ((j - count >= 0) & (new_i>= 0) & (new_i< D)):
                                                line = str(grid [i][j])  + " " +  str(grid [new_i][j-count]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")
                            else :
                                if (new_count == 0) :
                                        if ((j < D) & (i + count < D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i+count][j]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")
                                        if ((i -count >= 0) & (j < D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i-count][j]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")

                                        if ((i< D) & (j + count<D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i][j+count]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")
                                        if ((j - count >= 0) & (i< D)):
                                                line = str(grid [i][j])  + " " +  str(grid [i][j-count]) + " 0"
                                                topology.write(line)
                                                topology.write("\n")

else: topology.close()

#print (str(count) + " " +str(new_count))
print ("Topology file is generated!")
