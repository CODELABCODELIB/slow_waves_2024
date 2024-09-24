######################################################################
Short Description of the Functions/Scripts on the Directory 'Figure 1'
######################################################################

############################################
Author: David Hof (last updated: 23-09-2024)
############################################


Functions:

– sw_pars_per_participant_v2: Computes the SW parameters per participant and condition (movie/
                              phone/overall), and (optionally) visualizes them in the form of
                              topographical plots. The detection and interpolation of SW
                              parameter outliers is another feature of the function that is
                              still being worked on. Status: Function works with the optional
                              argument 'interpolate_outliers' set to false/0 (default).

– compute_wave_pars_new_v2: Helper function for 'sw_pars_per_participant_v2'.

– aggregate_sw_pars_v2: Pools the SW parameters per channel and condition (movie/phone/overall)
                        across participants using a preferred aggregation function (e.g., mean,
                        median) and (optionally) visualizes the pooled SW parameters in the form
                        of topographical plots.

– condition_contrast_v2: Performs a paired t-test per SW parameter and per channel to compare
                         the movie and phone conditions. Subsequently performs a cluster-based
                         permutation test to determine significance. (Optionally) visualizes the
                         results in the form of topographical plots.

– visualize_wave_pars_new_v2: Helper function for 'sw_pars_per_participant_v2',
                              'aggregate_sw_pars_v2', and 'condition_contrast_v2'.


Other Scripts:

– LS_sw_pars_v2.slurm: Batch script for the entire data analysis pipeline for figure 1c).