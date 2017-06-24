function [bad_elecs] = step3_process_bad_elecs(subj_init,elecs,Pos)
% 
% function [bad_elecs] = step3_process_bad_elecs(subj_init,<elecs,Pos>)
%   This function will display the data for each subject and prompt for bad
%   electrodes
%   Returns bad_elecs (cell array of bad electrodes for each subject) and saves
%   the item in the current directory. 
%   
%   subj_init        -   Subject initials (ex- 'ss')
%   elecs            -   Electrodes to view  (default [1:64])
%   Pos              -   Window position
%
%   Written by Sara Szczepanski 3/2/11, adapted from script by Adeen Flinker
%

if (nargin<1)
    error('Must specify the subject initials');
end

if (~exist('elecs'))
    elecs = 1:64;
end

%if (exist(fullfile(TASKdir,'bad_elecs.mat')))
%   load(fullfile(TASKdir,'bad_elecs.mat'));
%   bad_elecs_save = bad_elecs;
%   clear bad_elecs;
%end

curr_dir = pwd;
%dr = dir('*.mat');

%for i = 1:length(dr)
    close all
    %clear *data
    %SJ = str2num(dr(i).name(1:findstr(dr(i).name,'_')-1));
    
    EEG = pop_loadset('filename', [subj_init '_preproc_trialloc.set'], 'filepath', pwd);
    EEG = eeg_checkset(EEG);
    
    
    data_nums = [1:64];
    
    if elecs(end)>64       % showing non-eeg data, start normalization
        periph_nums = setxor(data_nums,elecs); %any electrodes that are not 1:64 are external electrodes, define these accordingly

        EEGnorm = mean(std(EEG.data(data_nums,:),[],2)); %computes the STDEV for each channel and then averages across the STDEVs
        
        for i = 1:length(periph_nums) 
            Pdata(i,:) = EEG.data(periph_nums(i),:)./std(EEG.data(periph_nums(i),:)).*EEGnorm; %%z scoring the data (multiplying by mean and dividing by STDEV)
        end
        Vdata = [EEG.data(data_nums,:); Pdata]; %append the normalized external electrode data under the 64 channel head data
        
    else %only the 64 head electrodes (or less) were specified 
       Vdata = EEG.data(elecs,:); 
    end
    
    if (exist('Pos'))
        eegplot(Vdata,'srate',EEG.srate,'position',Pos); %use this if you want to see the electrode numbers
        %eegplot(Vdata,'srate',EEG.srate,'position',Pos,'eloc_file',EEG.chanlocs(elecs)); %use this if you want to see the electrode names
        
    else
        eegplot(Vdata,'srate',EEG.srate); %use this if you want to see the electrode numbers
        %eegplot(Vdata,'srate',EEG.srate,'eloc_file',EEG.chanlocs(elecs)); %use this if you want to see the electrode names
    end
    
    if exist('bad_elecs_save') %if the file 'bad_elecs_save' already exists
        resp = input(sprintf('Enter an array of bad electrodes for subject')); %Expecting: [2 3 4], etc...list of bad electrodes
        if ~isempty(resp)
            bad_elecs = {resp};
        else
            bad_elecs = bad_elecs_save;
        end
    else
        bad_elecs = {input(sprintf('Enter an array of bad electrodes for subject'))}; %Expecting: [2 3 4], etc... list of bad electrodes
    end
    
    %if (i == 1)  % store current figure position
    %    Pos = get(gcf,'Position');
    %end
%end %end for

save bad_elecs.mat bad_elecs; %saves out a list of bad electrodes to a separate .mat file


close all
clear all





