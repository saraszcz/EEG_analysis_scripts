function [] = step7_reject_after_ICA(subj_init)
%FUNCTION [] = step7_reject_after_ICA(SUBJ_INIT)
%
%Lowpass filters the data after ICA.
%And then performs further artifact rejection after ICA components have been removed.
%Used to mark and reject the trials that have voltage changes that are are
%result from eye blinks, etc... This is generally run AFTER you run an ICA
%on the data and remove components that were not taken out by the ICA.
%NOTE: assumes that the data are epoched!!
%
%SUBJ_INIT = subjects initials ex- 'ss'
%
%modifed by SS on 3/15/10 from scripts originally provided by Ulrike
%Kraemer.
%

name{1}='Attend_LVF'; %300s. Correct hits.
name{2}='Attend_RVF'; %400s. Correct hits.
name{3}='Unattend_LVF'; %500s. Correct rejections.
name{4}='Unattend_RVF'; %600s. Correct rejections.
%name{5}='Misses'; %700s. Misses, not broken up by visual field.
%name{5}='False_Alarms'; %800s. False alarms, not broken up by visual field


for i=1:size(name,2)
    
    EEG = pop_loadset('filename', [subj_init '_epoched_' name{i} '.set'], 'filepath', pwd);
    
    %NOTE: should I also lowpass filter my data?? Ulrike does not. But there is
    %alot of 60 Hz line noise, since the EEG rooms are not shielded.
    %Note: Adeen suggests that I lowpass filter my data.
    
    % lowpass filter data AFTER ICA... lowpass at 50Hz
    %NOTE: what to lowpass at if you are doing time frequency analysis??
    EEG = pop_eegfilt(EEG, [], 30, [], [0]);
    EEG = eeg_checkset(EEG);
    
    % eegthresh: reject artifacts by detecting outlier values.  This has long been a standard method for selecting data to reject.
    % Applied either for electrode data or component activations.
    % (type of rejection (1 = raw data), electrode to take into consideration
    % for rejection (65 = HEOG), lower theshold for cutoff (-40 microvolts,
    % stdev), upper threshold for cutoff (40 microvolts stdev), rejection start
    % window in sec (300 ms before), rejection end window in sec (2000 ms after),
    %
    % superpose  - [0|1] 0=do not superpose rejection markings on previous
    % rejection marks stored in the dataset; 1=show both current and
    % previously marked rejections using different colors. {Default: 0}.
    %
    % reject     - [1|0] 0=do not actually reject the marked trials (but store the
    % marks); 1=immediately reject marked trials. {Default: 1}.
    %
    % This code marks where the saccades are in the data or other
    % irregularities not removed by ICA. Want to remove trials during which
    % subjects made saccades.
    
%     EEG = pop_eegthresh(EEG,1,[65],-40,40,-0.3,1.5,1,0); %doing this on the HEOG, since we are most interested in horz saccades.
%     %[NOTE: channel 65 = HEOG now because old empty channel 65 was removed]. 
%     
%    
%     % pop_rejepoch() - Reject pre-labeled trials in an EEG dataset.
%     % Ask for confirmation and accept the rejection.
%     % EEG, trialrej (Array of 0s and 1s depicting rejected trials),
%     % Display rejections and ask for confirmation. (0=no. 1=yes)
%     
%     EEG = pop_rejepoch(EEG,find([EEG.reject.rejthresh]),1);
%     EEG = eeg_checkset(EEG);
    
    %go through all of the rest of the electrodes and use the same rejection
    %process.
%     EEG = pop_eegthresh(EEG,1,[1:64],-100,100,-0.3,1.5,1,0); %may have to change some of these values, depending on individual dataset
%     
%     EEG = pop_rejepoch(EEG,find([EEG.reject.rejthresh]),1);
%     
%     
    EEG.setname=[subj_init '_hp0.5_ica_clean_epoched_' name{i} '_lp30_rej.set'];
    EEG = eeg_checkset(EEG);
    
    EEG = pop_saveset(EEG, 'filename', [subj_init '_epoched_' name{i} '_lp30_rej.set'], 'filepath', pwd);
    EEG = eeg_checkset(EEG);
    
end





