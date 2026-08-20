# Course: Fault Tolerant Digital Systems
 
## **Fault Tolerant FIR filter**
- Fault tolerence techniques used: **N-Modular Redundancy , Pair-and-a-Spare** (more details in docs)
- Running the Project:

  Start Vivado.
  In the Tcl Console change the current working directory to the root directory of the project.
  Execute run.tcl script (command: source scripts/run.tcl). The script will automatically create and configure Vivado project.

- Adding Fault Scenarios to Simulation:

  source scripts/testX.tcl (X = 1,2,3)
  (after that run rm_forces_testX.tcl script)

