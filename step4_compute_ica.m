function [ICAweights, ICAsphere]= step4_compute_ica(subj_init, elecs)
%
% [ICAweights, ICAsphere]= step4_compute_ica(subj_init, elecs)
%   This function will compute ICA weighting matrices for all subjects
%   using runica() from eeglab (logistic infomax ICA algorithm of Bell &
%   Sejnowski (1995)
%
%   subj_init        -   Subjects initials, ex: 'ss'  
%   elecs            -   Electrodes to view  (default [1:64])
%
%   returns matrices of Nelecs X Nelecs. The ICAweights matrix
%   holds the weights*sphere matrix returned by runica() for each subject.
%   The ICAsphere matrix holds the sphere matrix only.
%
% Written by Sara Szczepanski 2/24/11, adapted from script from Adeen Flinker
%

if (~exist('elecs'))
    elecs = 1:64;
end

EEG = pop_loadset('filename', [subj_init '_preproc_trialloc.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);


ICAweights = zeros(length(elecs),length(elecs));
ICAsphere = zeros(length(elecs),length(elecs));

%runs the ICA on the data. Note: default is to run on electrodes 1-64 (all head electrodes, not externals)
%EEG = pop_runica(EEG, 'icatype', 'runica', 'dataset',1, 'chanind', elecs, 'options', {'extended',1});
EEG = pop_runica(EEG, 'icatype', 'runica', 'dataset',1, 'chanind', elecs);
%Adeen's way: [weights,sphere] = runica(EEG.data(elecs,:)); 


sphere = EEG.icasphere; %output from pop_runica
weights = EEG.icaweights; %output from pop_runica

ICAweights(:,:) = weights*sphere; %this is used to reconstruct the data to examine each individual component
ICAsphere(:,:)  = sphere; %don't need to save this out?

save ICAweights.mat ICAweights ICAsphere; %saves out ica weights in a separate .mat file
EEG.setname = [subj_init '_hp0.5_ch66_runica'];
EEG = pop_saveset(EEG, 'filename', [subj_init '_ica.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);


