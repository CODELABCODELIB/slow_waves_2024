Slow waves parameters across behavioral joint-interval distributions (JIDs) (Deprecated)
========================================================================================

A. Create JID-parameters (e.g. JID-amplitudes)
----------------------------------------------

1. Select the slow waves co-ocurring with the phone data. The slow waves detection was performed on all the data which includes movie watching and phone use which is why it needs to be seperated.

2. Assign each touchscreen interaction to nearest 'bin/pixel'. 

3. For each triad select the co-occurring slow waves.

4. Calculate the slow wave parameter for the slow waves per triad. This can be the slow wave density, amplitude or slopes.


5. Assign the slow wave parameter (from step 4) to the bin where the triad was assigned (step 2). This creates a JID per parameter.

	
	- Multiple events in one bin are pooled by calculating the median among the events.
	

B. Prepare data for Non-negative matrix factorization (NNMF) 
------------------------------------------------------------

1. Reshape the bins (50x50xelectrodes) to 2500 bins x electrodes

2. Remove empty bins

3. Shift the data if necessary to make it non-negative but adding the absolute minimum value 
	
4. If a value in the data is 0 then pad it with 0.0000000000001. 

5. The bins with less than 25 percentile of events are removed. NNMF is sensitive to high variance and will simply seperate these events out if not removed.
	
6. The parameters may be z-score normalized this may be relevant for the amplitudes

7. The parameters may be log normalized, if the distributions are skewed
	
	
C. Cross-validation for Non-negative matrix factorization (NNMF)
----------------------------------------------------------------
To select the best number of ranks per participant cross-validation was used. The following steps were performed for each participant:

 1. Randomly remove 20% of the data points (masking)
 
 3. Perform NNMF 50 times with randomly initialized values. Every repetition results in 2 matrices. The first matrix summarizes the jid-parameter (meta-jid-parameter, Shape: [bins x rank]). The second matrix (meta-location) summarizes the likelihood that the jid-parameter is represented in that location (Shape: [rank x electrodes]).
 
 4. Z normalized each meta-trial and meta-ERP
 
 5. Reconstructed the data and calculated the training and testing error for each repetition
 
 6. Repeated steps 2 to 6 for rank [2 to 10]
 
 7. Selected the best rank by averaging the test error across all the repetitions for each rank and selecting the rank with the smallest error.

D. Reproducible Non-negative matrix factorization (NNMF)
--------------------------------------------------------
Since NNMF is a non-convex problem, the solution is dependent on the initialization. Therefore we employed the reproducible NNMF technique as explained in (:ref:`https://doi.org/10.1101/2022.08.25.505261`). We repeated the above mentioned steps 1 to 4, with the exception that NNMF was performed for 100 repetitions with the selected rank. Followed by the reproducible NNMF technique selecting the most stable and reproducible decompositions per participant.

E. Clustering NNMF decompositions
---------------------------------
To identify population wide relationships we clustered the meta-locations using modified k-means. Then compared to JID-parameters per cluster. 

E.1 Selecting the optimal number of clusters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To select the optimal number of clusters for k-means the 

E.2 Stable k-means
^^^^^^^^^^^^^^^^^^
As the solution for k-means is not unique we want to select the most stable clusters. Towards this, we repeated k-means, with the optimal number of clusters, 1000 times. For each repetition, the sum of squared distance was calculated. Finally, the repetition with the smallest sum of squared distance was selected.


Folder structure
----------------

::

	+-- sw_jid_nnmf
	¦   +-- jid_waves_main.m  --> main function perform nnmf for jid-parameters calls all subfunctions and saves the data (A to D)
	¦   +-- sw_per_triad.m --> get the slow waves per triad (A step 3)
	¦   +-- jid_per_param.m --> Get the slow wave parameter per triad and map them to the JID (A step 4 - 5)
	¦   +-- calculate_density.m --> calculates the slow wave density (A step 4)
	¦   +-- calculate_density_per_dur.m --> calculates the slow wave density (A step 4)
	¦   +-- calculate_p2p_amplitude.m --> calculates the slow wave peak to peak amplitudes (A step 4)
	¦   +-- calculate_slope.m --> calculates the slow wave upwards or downward slopes (A step 4)
	¦   +-- prepare_sw_data_for_nnmf.m --> prepare slow wave data for nnmf (B)
	¦   +-- perform_sw_param_nnmf.m  --> perform the nnmf on the slow waves data (C to D)
	¦   +-- jid_delay_nnmf_main.m  --> main function perform nnmf for time-lagged jid-parameters 
	¦   +-- jid_param_before_during_after.m --> get time-lagged jid-parameters
	+-- microstates_functions
	¦   +-- find_gaps_in_taps.m --> find indexes in the phone data where there is activity and seperate these from areas with no activity (gaps) (A step 1)
	¦   +-- find_taps.m --> find tap indexes (A step 1)
	¦   +-- assign_tap2bin.m --> Assign triads to nearest JID bins (A step 2)
	¦   +-- calculate_ITI_K_ITI_K1.m --> calculate the inter-touch-intervals K and K+1 for the taps  (A step 2)
	¦   +-- cluster.m --> Cluster the NNMF results (E)
	¦   +-- assign_input_to_bin.m 
	¦   +-- find_duplicates.m --> find triads that are in the same bin
	¦   +-- pool_duplicates.m --> pool duplicate events in bin using various central tendencies
	¦   +-- prepare_EEG_w_taps_only.m --> select only the phone data portion from the EEG


Code
----


.. mat:automodule:: behavior_to_sw
   :members:
   
.. mat:automodule:: microstates_functions
   :members:

