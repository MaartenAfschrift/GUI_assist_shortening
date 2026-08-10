# Questions arvid

**When changing a constant. Do I have to add _Value_ to the name**

for example

`app.writeMap.MinimalTorque = app.tcClient.CreateVariableHandle('jlo_assist_short_explicit_clean_Lonit.ModelParameters.MinimalTorque');`

or 

`app.writeMap.MinimalTorque = app.tcClient.CreateVariableHandle('jlo_assist_short_explicit_clean_Lonit.ModelParameters.MinimalTorque.Value');`



**Output data in simulink model ?**

sourceHandleName = 'Exosoft_Controller.Output.gui_out' in the example suggests that you have a specific output block in your simulink model for signals that are accesible in the GUI. How does this work ?



## Things to adapt in simulink controller

#### high level controller

- adapt experimenter input based on GUI logic
  
  - switch between controllers
  
  - apply assistance
  
  - minimal torque

- export muscle state per muscle (visualisation GUI)

- output both perc assistance and assist shortening controllers (visualisation GUI)
