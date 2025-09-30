####################################################################
Short Description of the Functions/Scripts on the Directory 'fig_S2'
####################################################################

############################################
Author: David Hof (last updated: 30-09-2025)
############################################


Functions:

– n/a


Other Scripts:

– extractsleepfromarchive_2024: Extracts all the sleep values for subjects identified by the
                                file 'subjects.xlxs' and saves them to the file 'compile.mat'.

– get_participantIDs: Extracts participant IDs from the 41 subjects processed so far and saves
                      them to the file 'participantIDs.mat'.

– extract_sleep_before_exp: Extracts sleep durations for the 7 days leading up to participants'
                            experiment(s) (experiment days and times are recorded in the file
                            'subjects.csv') for all subjects listed in 'participantIDs.mat' from
                            'compile.mat' and saves them to the file 'sleepBeforeExp.mat'.

– create_sleep_histograms: Creates histograms for 1) the median sleep duration across the 7 days
                           leading up to the experiment and 2) the sleep duration for the day
                           before the experiment using the file 'sleepBeforeExp.mat'. Since most
                           participants came in for two experiments on distinct days, sleep
                           durations for each day leading up to the experiment were averaged
                           across the two series of days leading up to the experiments before
                           calculating/extracting the values needed for the histograms.