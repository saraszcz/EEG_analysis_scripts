function [] = plot_cross_coherence_EEG(dataset,start_time,end_time,max_freq)
%
%   function [] =
%   plot_cross_coherence(SUBID,meta_ID,elec1_num,elec1_raw,elec2_num,elec2_raw,start_time_window,end_time,cond1,max_freq)
%
%   calculates event-related coherence between two ECOG electrodes. can
%   choose whether you would like to calculate phase coeherence or spectral
%   coherence. 
%
%
%   dataset      -   name of dataset, ex: '001_epoched_Attend_RVF_clean_sacc'   
%
%   start_time   -   start time in ms, given in relation to time-locked
%                           event (ex - -200 ms)
%
%   end_time     -   end time in ms, given in relation to time-locked
%                         event (ex- 1000 ms)
%
%   max-freq     -   maximum frequency to be analyzed. (Min freq is either 1 or 2
%                         hz, depends on FFT). 
%
%   Created by Sara Szczepanski on 4/21/15
%


if ~exist('phase_coherence/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('phase_coherence/');
end

if ~exist(['phase_coherence/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['phase_coherence/' dataset]);
end

if ~exist('phase_coherence_erp/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('phase_coherence_erp/');
end

if ~exist(['phase_coherence_erp/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['phase_coherence_erp/' dataset]);
end

if ~exist('phase_coherence_baseline/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('phase_coherence_baseline/');
end

if ~exist(['phase_coherence_baseline/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['phase_coherence_baseline/' dataset]);
end


if ~exist('phase_coherence_baseline_p0.1/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('phase_coherence_baseline_p0.1/');
end

if ~exist(['phase_coherence_baseline_p0.1/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['phase_coherence_baseline_p0.1/' dataset]);
end


% tm_st  = round(start_time ./1000*srate); %in case srate is not exactly 1000 hz
% tm_en  = round(end_time ./1000*srate); %in case srate is not exactly 1000 hz


% for i = 1:length(onsets_cond1)
%     tm_stmps  = (onsets_cond1(i)+tm_st):(onsets_cond1(i)+tm_en);
%     elec1_events = [elec1_events elec1_raw(tm_stmps)];
%     elec2_events = [elec2_events elec2_raw(tm_stmps)];
%     clear tm_stmps;
% end


EEG = pop_loadset('filename', [dataset '.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);

%calculate frames per epoch- timepoints per epoch
%frames = end_time - start_time;
%frames = tm_en - tm_st+1;

frames = (end_time - start_time)*(EEG.srate/1000);

subj = dataset(1:2); %take first two letters/numbers to identify subject

chans_left_frontal  = [5 6 9 10]; %F3,F5,FC5,FC3
chans_right_frontal = [40 41 44 45];%F4,F6,FC4,FC6

chans_left_parietal  = [20 21 22 25 26]; %P1,P3,P5,PO7,PO3
chans_right_parietal = [57 58 59 62 63]; %P2,P4,P6,PO8,PO4


%%%%%%%
% [coh,mcoh,timesout,freqsout,cohboot,cohangles] ...
%          = newcrossf(X,Y,frames,tlimits,srate,cycles,'key1', 'val1', 'key2', val2' ...);
%%%%%%%

%calcuate cross coherence-- relative to baseline
%[coh,mcoh,timesout,freqsout,cohboot] = newcrossf(elec1_events,elec2_events,...
%  frames, [start_time end_time], srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'baseline', 0);


%calculate cross coherence-- not relative to baseline    
%[coh,mcoh,timesout,freqsout,cohboot] = newcrossf(elec1_events,elec2_events,...
%    frames, [start_time end_time], srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off');


%calculate cross coherence-- not relative to baseline. subtracts mean ERP from data before calculating coherence.
% [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(elec1_events,elec2_events,...
%    frames, [start_time end_time], srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'rmerp', 'on');


% newcrossf - NO erp or baseline removal
%left frontal with left parietal
for chans_lf = 1:length(chans_left_frontal)
    
    for chans_lp = 1:length(chans_left_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_left_frontal(chans_lf),:,:),EEG.data(chans_left_parietal(chans_lp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence/' dataset '/' subj '_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop

%right frontal with right parietal
for chans_rf = 1:length(chans_right_frontal)
    
    for chans_rp = 1:length(chans_right_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_right_frontal(chans_rf),:,:),EEG.data(chans_right_parietal(chans_rp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence/' dataset '/' subj '_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop


% newcrossf - WITH erp removal
%left frontal with left parietal
for chans_lf = 1:length(chans_left_frontal)
    
    for chans_lp = 1:length(chans_left_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_left_frontal(chans_lf),:,:),EEG.data(chans_left_parietal(chans_lp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05, 'rmerp', 'on');
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_erp/' dataset '/' subj '_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_erp/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop

%right frontal with right parietal
for chans_rf = 1:length(chans_right_frontal)
    
    for chans_rp = 1:length(chans_right_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_right_frontal(chans_rf),:,:),EEG.data(chans_right_parietal(chans_rp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05, 'rmerp', 'on');
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_erp/' dataset '/' subj '_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_erp/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop


% newcrossf - WITH erp and baseline removal
%left frontal with left parietal
for chans_lf = 1:length(chans_left_frontal)
    
    for chans_lp = 1:length(chans_left_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_left_frontal(chans_lf),:,:),EEG.data(chans_left_parietal(chans_lp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05, 'rmerp', 'on', 'baseline', 0);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_baseline/' dataset '/' subj '_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_baseline/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop

%right frontal with right parietal
for chans_rf = 1:length(chans_right_frontal)
    
    for chans_rp = 1:length(chans_right_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_right_frontal(chans_rf),:,:),EEG.data(chans_right_parietal(chans_rp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.05, 'rmerp', 'on', 'baseline', 0);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_baseline/' dataset '/' subj '_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_baseline/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop




% newcrossf - WITH erp and baseline removal
%left frontal with left parietal
for chans_lf = 1:length(chans_left_frontal)
    
    for chans_lp = 1:length(chans_left_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_left_frontal(chans_lf),:,:),EEG.data(chans_left_parietal(chans_lp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.10, 'rmerp', 'on', 'baseline', 0);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_baseline_p0.1/' dataset '/' subj '_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_baseline_p0.1/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_left_frontal(chans_lf)).labels '_' EEG.chanlocs(chans_left_parietal(chans_lp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop

%right frontal with right parietal
for chans_rf = 1:length(chans_right_frontal)
    
    for chans_rp = 1:length(chans_right_parietal)
        
        % %calculates cross coherence-- not realtive to baseline. subtracts mean ERP from data before calculating coherence. calculates cross coeherence that
        % %is significant realtive to a surrogate distribution of 200 iterations.
        % %'boottype' = 'shuffle' (shuffle trials and time), 'shufftrials' (shuffle just trials).
        [coh,mcoh,timesout,freqsout,cohboot] = newcrossf(EEG.data(chans_right_frontal(chans_rf),:,:),EEG.data(chans_right_parietal(chans_rp),:,:),...
            frames, [start_time end_time], EEG.srate, 0 , 'type', 'phasecoher', 'maxfreq', max_freq, 'plotphase', 'off', 'boottype', 'shufftrials', ...
            'baseboot', 0 , 'naccu', 200, 'alpha', 0.10, 'rmerp', 'on', 'baseline', 0);
        
        colormap(jet)
        
        print('-dpng',['phase_coherence_baseline_p0.1/' dataset '/' subj '_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq) '.png']);
            
        save (['phase_coherence_baseline_p0.1/' dataset '/' subj '_coh_vals_' EEG.chanlocs(chans_right_frontal(chans_rf)).labels '_' EEG.chanlocs(chans_right_parietal(chans_rp)).labels '_' num2str(max_freq)], ...
        'coh','mcoh','timesout','freqsout','cohboot');
        
        close
        
     end %end chans parietal loop
        
end %end chans frontal loop
       

       


