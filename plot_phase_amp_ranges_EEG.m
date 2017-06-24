function [plv_matrix] = plot_phase_amp_ranges_EEG(dataset, start_time, end_time, ...
                                                  run_surrogate, varargin)

% Generate Fig. 1D from Canolty et al. (2006) for two electrodes.
%
%
%     dataset           - Name of dataset to analyze (e.g.,'MF_epoched_Attend_LVF_clean_sacc')
%
%     start_time        - start of time window in ms relative to event start
%
%     end_time          - end of time window in ms relative to event start
%
%     run_surrogate     - 0 = do not run surrogate analysis. 1 = run
%                         surrogate analysis
%
%     amp_f_array       - 40 frequencies to use for amplitude (optional)
%
%     phase_f_array     - 19 frequencies to use for phase (optional)
%
%
%     Based upon scripts by Ryan Canolty. Modified by Sara Szczepanski,
%     2/23/12, adapted for EEG analysis 2/24/15
%


numsurrogate  = 200; % or more; more is better if you have time to run it


if ~exist('plv_graphs/','dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir('plv_graphs/');
end

if ~exist(['plv_graphs/' dataset],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
    mkdir(['plv_graphs/' dataset]);
end


if run_surrogate %if we are creating a surrogate distribution
    if ~exist(['plv_graphs/' dataset '/cond_permute_rand_byfreq'],'dir') % checks if the appropriate subfolder for this study/block has been created in 'analysis'....
        mkdir(['plv_graphs/' dataset '/cond_permute_rand_byfreq']);
    end
    
end

% Read input, and set default values for unsupplied arguments.
for n=1:2:length(varargin)-1
    switch lower(varargin{n})
        case 'amp_f_array'
            amp_f_array = varargin{n+1};
        case 'phase_f_array'
            phase_f_array = varargin{n+1};
    end
end

if ~exist('amp_f_array', 'var')
    %amp_f_array = 5:6.282:250;
    amp_f_array = 5:1.13:50; %40 frequencies
end

if ~exist('phase_f_array', 'var')
    %phase_f_array = 2:2:20;
    phase_f_array = 1:1.055:20;%19 frequencies
    
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


%concatenate trials together to get n electrodes x n timepoints across all
%trials matrix
EEG_concat = reshape(EEG.data(:,:,:),[size(EEG.data,1), timepoints*num_trials]);


% get_signal_parameters, which returns the structure 'sp':
sp = get_signal_parameters('sampling_rate',EEG.srate,... % Hz
    'number_points_time_domain',length(EEG_concat));

n_amp_freqs = length(amp_f_array); %number of frequencies to analyze for amp data
n_phase_freqs = length(phase_f_array);%numer of frequencies to analyze for phase data
plv_matrix_real = nan(n_amp_freqs, n_phase_freqs);%initialize a matrix of plv values
plv_matrix_surr = nan(n_amp_freqs,n_phase_freqs,numsurrogate);%initialize a matrix of plv values- this matrix is as deep as the number of surrogates run.
pvalues_matrix = zeros(n_amp_freqs, n_phase_freqs);%initialize a matrix of p-values for each frequency pair


for e = 1:64 %for each head electrode
    
    e_signal = EEG_concat(e,:); %get raw data for each electrode
    
    for i_phase = 1:n_phase_freqs %for each frequency of the phase data
        
        phase_f = phase_f_array(i_phase); %the partiuclar frequency to filter lf signal
        
        g.center_frequency = phase_f;
        g.fractional_bandwidth = 0.25;
        g.chirp_rate = 0;
        g1 = make_chirplet('chirplet_structure', g, 'signal_parameters', sp);
        
        % filter raw signal at low frequency, extract phase:
        fs = filter_with_chirplet('raw_signal', e_signal, ...
            'signal_parameters', sp, ...
            'chirplet', g1);
        lf_phase = angle(fs.time_domain);
        clear g.center_frequency
        
        %    %code to filter using eegfilt.m and hilbert.m, rather than using
        %    wavelets. note: this takes two steps, rather than one.
        %
        %     % Filter in low frequency band
        %     lf_signal = eegfilt(e_signal,srate,2,5); %filter 2:5 hz (approximate delta range).
        %
        %     % Get complex-valued analytic signal (analytic amplitude and phase info)
        %     lf_analytic = hilbert(lf_signal);
        %
        %     % Returns the phase of the analytic time series.
        %     lf_phase = angle(lf_analytic);
        %
        
        for i_amp = 1:n_amp_freqs %for each frequency of the amplitude data
            
            amp_f = amp_f_array(i_amp); %the particular frquency to filter hf data
            
            g.center_frequency = amp_f;
            g2 = make_chirplet('chirplet_structure', g, 'signal_parameters', sp);
            
            % filter raw signal at high frequency, extract amplitude:
            fs = filter_with_chirplet('raw_signal', e_signal, ...
                'signal_parameters', sp, ...
                'chirplet', g2);
            hf_amp = abs(fs.time_domain);
            % filter high frequency amplitude time-series at low
            % frequency, extract phase:
            fs = filter_with_chirplet('raw_signal', hf_amp, ...
                'signal_parameters', sp, ...
                'chirplet', g1);%filter at low frequency
            hf_phase = angle(fs.time_domain); %extract phase of high frequency amplitude
            
            %     %code to filter using eegfilt.m and hilbert.m, rather than using
            %     wavelets. note: this takes two steps, rather than one.
            %
            %     % Filter in high frequency band
            %     hf_signal = eegfilt(e_signal,srate,70,200); %filter 70:200 hz (high gamma range).
            %
            %     % Get complex-valued analytic signal (analytic amplitude and phase info)
            %     hf_analytic = hilbert(hf_signal);
            %
            %     % Returns the amplitude of the analytic time series.
            %     hf_amp = abs(hf_analytic);
            %
            %     % Extract phase of HG analytic amplitude timeseries
            %     hf_phase  = angle(hilbert(hf_amp));
            %
            
            %   %this chunks out data for a particular condition AFTER*** filtering
            %   [chunked_low_phase chunked_high_phase] = get_session_data(lf_phase, hf_phase, ...
            %   cond_string, start_window,...
            %   end_window);
            
            %Chunk out data for a particular condition after filtering
            
            EEG_trials_lf_phase = reshape(lf_phase,[num_trials,timepoints]); %reshape into timepoints x trials array
            EEG_trials_hf_phase = reshape(hf_phase,[num_trials,timepoints]); %reshape into timepoints x trials array
            
            chunked_low_phase  = EEG_trials_lf_phase(:,tm_st:tm_en);
            chunked_high_phase = EEG_trials_hf_phase(:,tm_st:tm_en);
            
            
            %reshape into single continuous timeseries again
            
            chunked_low_phase_concat = reshape(chunked_low_phase(:,:),[1,size(chunked_low_phase,1)*size(chunked_low_phase,2)]);
            chunked_high_phase_concat= reshape(chunked_high_phase(:,:),[1,size(chunked_high_phase,1)*size(chunked_high_phase,2)]);
           
            
            % Compute cross-frequency phase locking value (PLV).
            %plv = abs(mean(exp(1i*(hf_phase - lf_phase))));
            plv = abs(mean(exp(1i*(chunked_high_phase_concat - chunked_low_phase_concat))));
            
            % Store PLV.
            plv_matrix_real(i_amp, i_phase) = plv;
            
            
            
            if run_surrogate %create surrogate distribution of PLV values for each pair of frequencies in the comodulogram
                
                % compute an ensemble of surrogate PLVs to compare to actual value to
                % establish statistical significance:
                % iteration = [num2str(i_amp) '_' num2str(i_phase)];
                % disp(iteration);
                
                for s = 1:numsurrogate
                    
                    shift = round(rand*sp.number_points_time_domain); %choose a random timepoint
                    surrogate_lf_phase = circshift(chunked_low_phase_concat,[0 shift]); %shift the timecourse of the low frequency phase data at the random cut point
                    %NOTE: is this what we want to shift?? won't the coupling stay
                    %high in this situation? the only thing that changes is where
                    %the high amp bursts are in relation to the phase of the low frequency signals??
                    
                    plv_matrix_surr(i_amp, i_phase, s) = abs(mean(exp(1i*(chunked_high_phase_concat - surrogate_lf_phase))));%surrogate plv value
                    %NOTE: should we do this a different way if we are analyzing by
                    %condition?  Shift within a trial somehow?
                    clear shift surrogate_lf_phase
                    
                end
                
                
                %             %calulate p value
                %             %ind = find(plv < surrogate_plv,1,'last'); %report index values where the surrogate is larger than the actual value
                %             ind = find(plv < surrogate_plv); %report index values where the surrogate is larger than the actual value
                %
                %             % figure;
                %             % plot(surrogate_plv,'.k');
                %             % hold on;
                %             % plot(repmat(plv,size(surrogate_plv)),'r');
                %             % hold off;
                %
                %             if isempty(ind)
                %                 pvalues_matrix(i_amp, i_phase) = 1/numsurrogate; %calculate p value
                %             else
                %                 pvalues_matrix(i_amp, i_phase) = length(ind)/numsurrogate; %calculate p value
                %             end
                %
                %             %normalize length using surrogate data (z-score)-- CANNOT
                %             %NORMALIZE this PLV distribution-- must fit data to gamma
                %             %distrubiton to get p-values!
                %
                %             %fit gaussian to surrogate data, uses normfit.m from MATLAB Statistics toolbox
                %             %[surrogate_mean,surrogate_std] = normfit(surrogate_plv);
                
                
            end %end if run_surrogate
            
        end %end hf amp for loop
        
    end%end lf phase for loop
    
    
    if run_surrogate %in case we need to use these for another analysis later
        %save(['plv_graphs/' dataset '/cond_permute_rand_byfreq/' 'plv_matrix_surr_' num2str(e)], 'plv_matrix_surr','plv_matrix_real');
    end
    
    %
    if run_surrogate
        
        % Calculate plv value significance thresholds based upon distribution of
        % plvs for each timepoint; define contour values based upon PLV
        % distribution
        %
        % Returns the PLV values that correspond to certain significance p-values, given a surrogate gamma distribution.
        % These values will then be used as the contour lines on the contourf plot of the real data below.
        %
        %[x_vals, x_vals_all] = pval_from_gamma_dist(surr_matrix)
        %
        [contours, x_vals_all] = pval_from_gamma_dist(plv_matrix_surr);
        
        %save([pth_anal 'plv_graphs/' cond_string '/cond_permute_rand_byfreq/' 'xvals_all_dist_' elec], 'x_vals_all','contours');
    end
    
    
    %
    % Plot the matrix of PLVs.
    
    % contourf(Z,n) draws a filled contour plot of matrix Z with n contour levels
    % contourf(Z,v) draws a filled contour plot of matrix Z with contour lines
    %       at the data values specified in the monotonically increasing vector v.
    %       The number of contour levels is equal to length(v).
    
    
    % Note: contourf flips the matrix upside-down, so that the highest
    % frequency for amplitude is the top row of the plot (even though
    % it's the bottom row of the matrix).
    
    if run_surrogate
        
        contourf(plv_matrix_real,[0 contours]); %draws plot with specified contour lines
    else
        contourf(plv_matrix_real);
    end
    
    % Set locations of ticks and their labels.
    set(gca, 'XTick', 1:2:19, 'XTickLabel', phase_f_array(1:2:end), ...
        'YTick', 5:5:40, 'YTickLabel', amp_f_array(5:5:end));
    title(['Electrode ' EEG.chanlocs(e).labels ' Phase vs. Electrode ' EEG.chanlocs(e).labels ' Amplitude']);
    xlabel('frequency for phase (Hz)');
    ylabel('frequency for amplitude (Hz)');
    h = colorbar;
    set(get(h, 'ylabel'), 'string', 'PLV');
    
    if run_surrogate
        
        print('-dpdf', ['plv_graphs/' dataset '/cond_permute_rand_byfreq/' 'PLV_rand_byfreq_hi_' EEG.chanlocs(e).labels '_lo_' EEG.chanlocs(e).labels]);
    else
        print('-dpdf', ['plv_graphs/' dataset '/PLV_hi_' EEG.chanlocs(e).labels '_lo_' EEG.chanlocs(e).labels]);
        
    end
    
    close all
    
end %end for loop through electrodes

close all
%end %end electrode for loop



