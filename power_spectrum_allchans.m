function [] = power_spectrum_allchans(subj_init)

% function [] = power_spectrum_allchans(subj_init)
% calculates the power spectrum of each EEG channel

if ~exist('power_spectrum_graphs/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('power_spectrum_graphs/');
end

%EEG = pop_loadset('filename', [subj_init '_ica_clean.set'], 'filepath', pwd);
%EEG = pop_loadset('filename', [subj_init '_epoched_Attend_LVF_rej_ica2.set'], 'filepath', pwd);

EEG_Attend_LVF = pop_loadset('filename', [subj_init '_epoched_Attend_LVF_rej_ica2.set'], 'filepath', pwd);
EEG_Attend_LVF = eeg_checkset(EEG_Attend_LVF);

EEG_Attend_RVF = pop_loadset('filename', [subj_init '_epoched_Attend_RVF_rej_ica2.set'], 'filepath', pwd);
EEG_Attend_RVF = eeg_checkset(EEG_Attend_RVF);

EEG_Unattend_LVF = pop_loadset('filename', [subj_init '_epoched_Unattend_LVF_rej_ica2.set'], 'filepath', pwd);
EEG_Unattend_LVF = eeg_checkset(EEG_Unattend_LVF);

EEG_Unattend_RVF = pop_loadset('filename', [subj_init '_epoched_Unattend_RVF_rej_ica2.set'], 'filepath', pwd);
EEG_Unattend_RVF = eeg_checkset(EEG_Unattend_RVF);

% EEG_Attend_LVF = pop_loadset('filename', [subj_init '_epoched_Attend_LVF_clean_sacc.set'], 'filepath', pwd);
% EEG_Attend_LVF = eeg_checkset(EEG_Attend_LVF);
% 
% EEG_Attend_RVF = pop_loadset('filename', [subj_init '_epoched_Attend_RVF_clean_sacc.set'], 'filepath', pwd);
% EEG_Attend_RVF = eeg_checkset(EEG_Attend_RVF);
% 
% EEG_Unattend_LVF = pop_loadset('filename', [subj_init '_epoched_Unattend_LVF_clean_sacc.set'], 'filepath', pwd);
% EEG_Unattend_LVF = eeg_checkset(EEG_Unattend_LVF);
% 
% EEG_Unattend_RVF = pop_loadset('filename', [subj_init '_epoched_Unattend_RVF_clean_sacc.set'], 'filepath', pwd);
% EEG_Unattend_RVF = eeg_checkset(EEG_Unattend_RVF);



for ch = 1:size(EEG_Attend_LVF.data,1)
    %figure;
    [Psignal_Attend_LVF, f_Attend_LVF] = pwelch(EEG_Attend_LVF.data(ch,:), EEG_Attend_LVF.srate*2, EEG_Attend_LVF.srate*1, EEG_Attend_LVF.srate*4, EEG_Attend_LVF.srate);
    
    [Psignal_Attend_RVF, f_Attend_RVF] = pwelch(EEG_Attend_RVF.data(ch,:), EEG_Attend_RVF.srate*2, EEG_Attend_RVF.srate*1, EEG_Attend_RVF.srate*4, EEG_Attend_RVF.srate);
    
    [Psignal_Unattend_LVF, f_Unattend_LVF] = pwelch(EEG_Unattend_LVF.data(ch,:), EEG_Unattend_LVF.srate*2, EEG_Unattend_LVF.srate*1, EEG_Unattend_LVF.srate*4, EEG_Unattend_LVF.srate);
    
    [Psignal_Unattend_RVF, f_Unattend_RVF] = pwelch(EEG_Unattend_RVF.data(ch,:), EEG_Unattend_RVF.srate*2, EEG_Unattend_RVF.srate*1, EEG_Unattend_RVF.srate*4, EEG_Unattend_RVF.srate);
    
    
    figure;
    
    plot(f_Attend_LVF(1:400), log10(Psignal_Attend_LVF(1:400)), 'k'); %plotting from 1 hz up to 100 Hz
    
    hold on
    
    plot(f_Attend_RVF(1:400), log10(Psignal_Attend_RVF(1:400)), 'r'); %plotting from 1 hz up to 100 Hz
    
    hold on
    
    plot(f_Unattend_LVF(1:400), log10(Psignal_Unattend_LVF(1:400)), '--k'); %plotting from 1 hz up to 100 Hz
    
    hold on
    
    plot(f_Unattend_RVF(1:400), log10(Psignal_Unattend_RVF(1:400)), '--r'); %plotting from 1 hz up to 100 Hz
    
    
    %legend('Noise', 'Noise D1', 'Signal');
    title(['Power Spectral Density Electrode ' num2str(EEG_Attend_LVF.chanlocs(ch).labels)]);
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
    
    
    print('-dpdf', ['power_spectrum_graphs/Power_spectrum_ch_' EEG_Attend_LVF.chanlocs(ch).labels]);
    
    close all
end

