Startup guide
=============

.. note:: In this documentation slow waves and sw are used interchangeably

Installation
------------


.. note:: The paths used in this project are all relative to the position in which this repository is cloned. It assumes you are inside the cloned repository. Change the paths when necessary.


Matlab startup
^^^^^^^^^^^^^^

Install Matlab `R2023b <https://nl.mathworks.com/products/new_products/release2023b.html>`__

Install the following toolboxes:

**Matlab external toolboxes**

- `EEGLAB 2020 <https://sccn.ucsd.edu/eeglab/ressources.php>`__
- `icablinkmetrics <https://github.com/mattpontifex/icablinkmetrics>`__
- `LIMO EEG <https://github.com/LIMO-EEG-Toolbox/limo_tools>`__
- `Spams-matlab <https://github.com/daming-lu/spams-matlab-v2.6-2>`__
- `NNMF pipeline <https://github.com/CODELABCODELIB/CODELAB_Master/tree/main/nnmf_pipeline/nnmf_pipeline_spams>`__

**Additional Matlab toolboxes**

- `Statistics Toolbox <https://nl.mathworks.com/products/statistics.html>`__
- `Curve Fitting Toolbox <https://nl.mathworks.com/products/curvefitting.html>`__
- `Signal Processing Toolbox <https://www.mathworks.com/products/signal.html>`__

Analysis
^^^^^^^^
The analysis is structured in a series of figures to recreate these figures:

1. Pre-process and identify slow waves in the data (check out the page <pre_processing>)
 
2. Identify slow waves characteristics during rest and how do these relate to sleep (check out the page <TODO>) 

3. Next identify slow waves characteristics across time while participants were engaged in smartphone behavior (check out the page <TODO>) 

4. Adress the dynamics of slow waves and their link to behavior (check out the page <sw_to_behavior>) 

All these steps are run from one main file: 'src/main_slow_waves.m'

Folder structure
----------------

::
   
	+-- docs --> documentation of the project
	¦   +-- _build
	¦       +-- doctrees
	¦       +-- html
	+-- local_sleep
	+-- data --> Project preprocessed datasets
	+-- figures --> Project figures 
	+-- src  --> code of the project
	    +-- microstates_functions  --> functions to calculate JIDs reused from microstates https://doi.org/10.1101/2024.07.22.604605 
	    +-- playground --> functions for exploratory anslysis
	    +-- plot --> plot functions
	    +-- preprocessing_sw --> preprocessing EEG data and functions to identify slow waves
	    +-- behavior_to_sw --> functions to map the relationship between slow waves features and behavioral dynamics (jid)
	    +-- sw_to_behavior --> functions to map the relationship between behaviors and slow waves dynamics (jid)
	    +-- utils --> utility functions
    
