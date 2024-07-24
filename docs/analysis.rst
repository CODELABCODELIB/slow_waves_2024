Methods
=======
This code identifies slow waves in EEG data while participants are engaged in smartphone behavior. The relationship between the slow waves and behavior is explored.

Pre-processing EEG
------------------
1. Loaded the EEG struct and included participants that met the following criterias:

 - Had EEG data
 - Contains smartphone data
 - Has been Aligned to Smartphone data
 - If the participant was a curfew participant, we only included the first measurement file
 - Attys is false
 - Measurement did not contain a saving error

2. Cleaned the EEG data by running gettechnicallcleanEEG

 - Removed blinks according to ICA
 - Interpolated missing channels
 - Re-referenced data to the average channel
 - Highpass filter up to 45 Hz
 - Lowpass filter from 0.5 Hz

Joint probability interval distribution (JID-state)
===================================================
1. Assign each touchscreen interaction to nearest 'bin/pixel'. 

