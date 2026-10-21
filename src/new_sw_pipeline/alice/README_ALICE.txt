RUNNING THE REFINED-ICA SW PIPELINE ON ALICE

One Slurm array task per .set file. Each task trains a fresh refined ICA
(refined_ica_mode = 'train'), runs SW detection and saves everything the
sw_to_behavior analyses need (SW results, taps/events, cleaned EEG).

Which files: every .set under SW_INPUT_DIR (searched recursively), except
files in folders whose name contains RW or DS (same rule as
gen_set_file_names.m). Same-day files are processed separately; merge their
results afterwards (see below).

1. Copy and unpack (from your own machine):
     scp alice_sw_pipeline.zip s3821013@<alice-login-node>:~
   on ALICE:
     unzip alice_sw_pipeline.zip -d ~/sw_pipeline_alice
     chmod +x ~/sw_pipeline_alice/alice/submit_sw_array.sh

2. Edit the paths at the top of alice/sw_pipeline_array.slurm:
     EEGLAB_DIR, CODE_DIR, SW_INPUT_DIR (root with participant folders),
     SW_OUTPUT_DIR

3. Test one dataset first:
     cd ~/sw_pipeline_alice/alice
     ./submit_sw_array.sh 1
   This writes SW_OUTPUT_DIR/dataset_list.txt (task number = line number).
   Check the list, logs/sw_refined_ica_<jobid>_1.out and `seff <jobid>_1` for
   run time and memory. Change --mem / --time / --partition if needed
   (cpu-short has a 4 h limit; use cpu-zen4 for longer runs).

4. Submit all datasets (max 20 running at once):
     ./submit_sw_array.sh
   Without arguments the list is rebuilt; with arguments the existing list
   is reused so task numbers stay the same.

5. Monitor:
     squeue -u $USER
     sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS

6. Rerun failed tasks only:
     ./submit_sw_array.sh 3,7,12
   Error details: logs/*.err and Outputs/<id>/refined/processing_error.mat

OUTPUTS (in SW_OUTPUT_DIR; <id> = relative path, e.g. AT08_12_57_07_05_18)
   dataset_list.txt                         task number -> .set file
   ICA_Cache/<id>_refined_ica.mat           full ICA decomposition + fit metadata
   Outputs/<id>/refined/wave_results.mat
       results                  all detected waves (old twa_results)
       top10_filtered_results   artifact-limited top 10% (old refilter)
       wave_pars, chanlocs, processing_info
       recording_info           native srate/pnts/xmin, event, urevent,
                                Aligned, Orignalchanlocs and tap_samples
                                (= find(Aligned.BS_to_tap.Phone == 1))
   Outputs/<id>/refined/cleaned_EEG.mat     ICA-cleaned, interpolated EEG at the
                                            256 Hz working rate (single), for
                                            SW waveform / ERP plots
   Outputs/<id>/refined/Topoplots/, Ocular_QC/
   batch_summaries/<id>.csv                 per-dataset status/timing

Disk: roughly 0.5 GB per dataset for cleaned_EEG.mat (check after the test).

SW positions (negzx, maxnegpk, wvend, ...) are native samples (ms at 1000 Hz),
as in the old pipeline. To use them with cleaned_EEG, convert to 256 Hz
samples (or use cleaned_EEG.source_time_mapping for boundary-exact mapping).

Merging same-day files (old pipeline used pop_mergeset): sort the files by the
time in their name and add the cumulative recording_info.pnts of the earlier
files to all positions, tap_samples and event latencies of the later ones.

Note: results have 62 channels (E63/E64 removed). Downstream code looping
over 1:64 must use numel(results.channels) and the saved chanlocs.

Merge the per-dataset summaries into one table:
   cd $SW_OUTPUT_DIR/batch_summaries
   awk 'FNR==1 && NR!=1 {next} {print}' *.csv > ../batch_summary_all.csv

Copy results back to your own machine:
   scp -r s3821013@<alice-login-node>:/data1/s3821013/sw_refined_ica_rerun .

LOCAL SERVER (no Slurm): local_server/run_sw_local.sh

Same wrapper, dataset_list.txt and outputs as on ALICE; runs N_PARALLEL
datasets at the same time with plain MATLAB.

1. Check the settings at the top of local_server/run_sw_local.sh:
     SW_INPUT_DIR, SW_OUTPUT_DIR (default: ZETA18 data / slow_waves paths),
     EEGLAB_DIR (empty = first eeglab.m found under /home/ruchella/imports),
     N_PARALLEL (default 4; needs about N_PARALLEL x 40 GB RAM),
     THREADS_PER_RUN (default 4)
2. Test one dataset:     ./run_sw_local.sh 1
   Log: SW_OUTPUT_DIR/logs/task_1.log
3. Run all, surviving logout:
     nohup ./run_sw_local.sh > run_sw_local.out 2>&1 &
4. Running it again skips datasets whose wave_results.mat and
   cleaned_EEG.mat exist; the end of the output lists failed task numbers:
     ./run_sw_local.sh 3 7 12        rerun only these
     FORCE=1 ./run_sw_local.sh 1     rerun even if outputs exist

EEGLAB 2020 + MATLAB R2024a or newer: "Error using warning ...
'Octave:abbreviated-property-match'" at eeglab line 202 means EEGLAB mistook
MATLAB for Octave (its check version(1) > '5' fails on version '24.x').
run_sw_local.sh detects this and prints the one-line fix:
   sed -i.bak "s/if v(1) > '5'/if exist('OCTAVE_VERSION','builtin') == 0/" <EEGLAB_DIR>/eeglab.m
