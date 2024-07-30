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

**Additional Matlab toolboxes**

- `Statistics Toolbox <https://nl.mathworks.com/products/statistics.html>`__
- `Curve Fitting Toolbox <https://nl.mathworks.com/products/curvefitting.html>`__
- `Signal Processing Toolbox <https://www.mathworks.com/products/signal.html>`__

Folder structure
----------------
```
. 
+-- docs --> documentation of the project
¦   +-- _build
¦       +-- doctrees
¦       +-- html
+-- local_sleep
+-- src  --> code of the project
    +-- microstates_functions  --> functions to calculate JIDs reused from microstates https://doi.org/10.1101/2024.07.22.604605 
    +-- playground --> functions for exploratory anslysis
    +-- plot --> plot functions
    +-- preprocessing_sw --> preprocessing EEG data and functions to identify slow waves
    +-- sw_jid_nnmf --> functions to map the relationship between slow waves and jid
    +-- utils --> utility functions
 ```
