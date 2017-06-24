function [] = create_ERSP_EEG(subj_dataset,start_time, end_time)
%FUNCTION [] = CREATE_ERSP_EEG(SUBJ_DATASET, START_TIME, END_TIME)

EEG = pop_loadset('filename', [subj_dataset '.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);

if ~exist([pwd '/ERSPs/'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pwd '/ERSPs/']);
end

if ~exist([pwd '/ERSPs/' subj_dataset '/'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir([pwd '/ERSPs/' subj_dataset '/']);
end

%calculate frames per epoch- timepoints per epoch
frames = (end_time - start_time)*(EEG.srate/1000);

ersp_all_elecs = nan(51,200,64); %assume 50 frequency bins x 200 time bins x 64 electrodes. Note: this may change with different datasets
itc_all_elecs  = nan(51,200,64);

subj = subj_dataset(1:2); %take first two letters/numbers to identify subject

for chan = 1:64 %for each head electrode
    
    % [ersp,itc,powbase,times,freqs,erspboot,itcboot] = ...
    %               newtimef(data, frames, tlimits, srate, cycles, 'key1',value1, 'key2',value2, ... );
    
    [ersp,itc,powbase,times,freqs,erspboot,itcboot] = newtimef(EEG.data(chan,:), frames, [start_time end_time], EEG.srate, 0, 'scale', 'abs'); 
    
    ersp_all_elecs(:,:,chan) = ersp(:,:);
    
    itc_all_elecs(:,:,chan)  = itc(:,:); 
    
    %save the plot
    print('-dpdf',[pwd '/ERSPs/' subj_dataset '/' 'ERSP_' num2str(chan) '.pdf']);
    %print('-dpdf',['ERSP_' num2str(chan) '.pdf']);
    
    %keyboard
    
    clear ersp itc 
    close all
    
end


save([pwd '/ERSPs/' subj_dataset '/' 'ERSP_vals'],'ersp_all_elecs','itc_all_elecs','powbase','times','freqs','erspboot','itcboot');

clear all

end


