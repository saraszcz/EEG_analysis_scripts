function [ICAweights, ICAsphere]= step8_compute_ica_2(subj_init, elecs)
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
    %elecs = 1:64;
    elecs = 1:68; %includes the eye movement channels
end

name{1}='Attend_LVF'; %300s. Correct hits.
name{2}='Attend_RVF'; %400s. Correct hits.
name{3}='Unattend_LVF'; %500s. Correct rejections.
name{4}='Unattend_RVF'; %600s. Correct rejections.
%name{5}='Misses'; %700s. Misses, not broken up by visual field.
name{5}='False_Alarms'; %800s. False alarms, not broken up by visual field


for i=1:size(name,2)
    
    EEG = pop_loadset('filename', [subj_init '_epoched_' name{i} '_rej.set'], 'filepath', pwd);
    EEG = eeg_checkset(EEG);
    
    ICAweights = zeros(length(elecs)-1,length(elecs));
    ICAsphere = zeros(length(elecs),length(elecs));
    
    %runs the ICA on the data + externals.
    %EEG = pop_runica(EEG, 'icatype', 'runica', 'dataset',1, 'chanind', elecs, 'options', {'extended',1});
    EEG = pop_runica(EEG, 'icatype', 'runica', 'dataset',1, 'chanind', elecs, 'pca', 67);%only compute 67 components, rather than 68, since component for eyeblink artifact has already been removed
    %Adeen's way: [weights,sphere] = runica(EEG.data(elecs,:));
    
    sphere = EEG.icasphere; %output from pop_runica
    weights = EEG.icaweights; %output from pop_runica
    
    
    %ICAweights(:,:) = weights*sphere; %this is used to reconstruct the data to examine each individual component
    %ICAsphere(:,:)  = sphere; %don't need to save this out?
    
    %save(['ICAweights_' name{i}] , 'ICAweights', 'ICAsphere'); %saves out ica weights in a separate .mat file
    EEG.setname = [subj_init '_hp0.5_ch66_epoched_rej_runica2'];
    
    EEG = pop_saveset(EEG, 'filename', [subj_init '_epoched_' name{i} '_rej_ica2.set'], 'filepath', pwd);
    EEG = eeg_checkset(EEG);
    
end


