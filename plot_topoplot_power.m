function [] = plot_topoplot_power(dataset,low_freq, high_freq, start_time, end_time)
%FUNCTION [] = PLOT_TOPOPLOT_POWER(DATASET,LOW_FREQ,HIGH_FREQ,START_TIME,END_TIME)
%
% plots out a topography plot of power across electrodes for a given
% frequency band and a given subject
%
%

if ~exist('scalp_topography_plots/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('scalp_topography_plots/');
end

if ~exist(['scalp_topography_plots/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['scalp_topography_plots/' dataset]);
end


if low_freq >= 70
    FilePrefix = 'Mean_Power_High_Gamma';
elseif low_freq >= 30 && (high_freq <= 70)
    FilePrefix = 'Mean_Power_Low_Gamma';
elseif (low_freq >= 13) && (high_freq <= 30)
    FilePrefix = 'Mean_Power_Beta';
elseif (low_freq >= 8) && (high_freq <= 13)
    FilePrefix ='Mean_Power_Alpha';
elseif (low_freq >= 4) && (high_freq <= 8)
    FilePrefix = 'Mean_Power_Theta';
elseif (low_freq >= 1) && (high_freq <= 5)
    FilePrefix = 'Mean_Power_Delta';
else
    error('Your frequency is not in the correct range')
end


%load data
EEG = pop_loadset('filename', [dataset '.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);

srate = EEG.srate;

timepoints = size(EEG.data,2);
num_trials = size(EEG.data,3);

baseline_timepoints = 300; %note: number of timepoints that are included in the baseline.
%This is generally 300 ms for EEG data. 

%convert timepoints
start_time  = round(start_time ./1000*srate); %time of trial start start
end_time  = round(end_time ./1000*srate); %time of trial end
baseline_timepoints = round(baseline_timepoints ./1000*srate);

tm_st = baseline_timepoints + start_time;
tm_en = baseline_timepoints + end_time;

%concatenate trials together
EEG_concat = reshape(EEG.data(:,:,:),[size(EEG.data,1), timepoints*num_trials]);

EEG_concat_power = [];


% filter signals in frequency band of interest and calculate power for each
% electrode
for chan = 1:64 %for each head channel (ignoring peripheral channels)
    
    raw_signal = EEG_concat(chan,:);

    signal_power = abs(my_hilbert(raw_signal,srate,low_freq,high_freq)).^2; %take the analytical amplitude
    
    %signal_power_baseline = (signal_power - mean(signal_power(1:baseline_timepoints))); %normalizing to the mean of its baseline
    %EEG_concat_power = [EEG_concat_power; signal_power_baseline];
    
    signal_power_norm = signal_power ./mean(signal_power); %normalizing each point to the mean of the power timeseries
    
    EEG_concat_power = [EEG_concat_power; signal_power_norm];
    
end


% calculate average power in a given frequency band across all timepoints of
% interest for each electrode

EEG_trials_power = reshape(EEG_concat_power,[64,timepoints,num_trials]); %reshape into channels x timepoints x trials array

EEG_power_avg_across_trials = squeeze(mean(EEG_trials_power(:,:,:),3)); %average across trials

EEG_power_avg_per_elec = mean(EEG_power_avg_across_trials(:,tm_st:tm_en),2);%average across timepoints of interest. 64 x 1 vector of average power values


save([pwd '/scalp_topography_plots/' dataset '/EEG_Vals_' FilePrefix], 'EEG_trials_power', 'EEG_power_avg_per_elec');

% plot out average power for each electrode using topoplot.m
% topoplot.m takes in a single data vector that is N electrodes (64) x 1 of
% average power values/electrode 

fig_power = figure;

topoplot(EEG_power_avg_per_elec, EEG.chanlocs(1:64), 'style', 'map');
colorbar('EastOutside');

caxis auto; 
%caxis([0 150]);


name_power = strcat(dataset, '_', FilePrefix);
print (fig_power, '-dpng', [pwd '/scalp_topography_plots/' dataset '/' name_power]); %save it out


close all

end