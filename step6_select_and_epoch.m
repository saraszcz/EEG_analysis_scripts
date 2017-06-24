function [] = step6_select_and_epoch(subj_init)
%FUNCTION [] = STEP6_SELECT_AND_EPOCH(SUBJ_INIT)
%Defines and selects/"chunks out" the epochs in the dataset, based upon their Biosemi
%codes. Each condition is then saved into a separate .set, so that subjects
%may be averaged together for each condition. 
%NOTE: This is written to be used after the ICA is run on the continuous
%dataset. Assumes that data has not been epoched previously. 
%
%SUBJ_INIT = subjects initials ex- 'ss'
%
%modifed by Sara Szczepanski on 2/15/10 from scripts originally provided by Ulrike
%Kraemer.


% Biosemi Event Codes:
% startTrialCode=21                 target4-1=141
% startCatchTrialCode=22            target4-2=142
% missCode=30                       target4-3=143
% correctRejectionCode=31           target4-4=144
% hitCode=200                       target4-5=145
% FACode_premature=201              target4-6=146
% FACode_wrongside=202              target4-7=147
% FAonCatchTrialCode=204            target4-7=147
% FAafterTargetPeriod=150           target5-1=151
% FAafterTargetCode=203             target5-2=152
% target1-1=111 (row 1, column 1)   target5-3=153
% target1-2=112 (row 1, column 2)   target5-4=154
% target1-3=113                     target5-5=155
% target1-4=114                     target5-6=156
% target1-5=115                     target5-7=157
% target1-6=116                     target6-1=161
% target1-7=117                     target6-2=162
% target2-1=121                     target6-3=163
% target2-2=122                     target6-4=164
% target2-3=123                     target6-5=165
% target2-4=124                     target6-6=166
% target2-5=125                     target6-7=167
% target2-6=126                     target7-1=171
% target2-7=127                     target7-2=172
% target3-1=131                     target7-3=173
% target3-2=132                     target7-4=174
% target3-3=133                     target7-5=175
% target3-4=134                     target7-6=176
% target3-5=135                     target7-7=177
% target3-6=136
% target3-7=137


%CODES:
%assign names are that associated with certain codes
%NOTE: can be locked either to the beginning of the trial or to the appearance of the stimulus on the screen.
code{1}={'311' '312' '313' '314' '315' '316' '317' '321' '322' '323' '324' '325' '326' '327' '331' '332' '333' '334' '335' '336' '337'}; name{1}='Attend_LVF'; %300s. Correct hits.
code{2}={'451' '452' '453' '454' '455' '456' '457' '461' '462' '463' '464' '465' '466' '467' '471' '472' '473' '474' '475' '476' '477'}; name{2}='Attend_RVF'; %400s. Correct hits.
code{3}={'511' '512' '513' '514' '515' '516' '517' '521' '522' '523' '524' '525' '526' '527' '531' '532' '533' '534' '535' '536' '537'}; name{3}='Unattend_LVF'; %500s. Correct rejections.
code{4}={'651' '652' '653' '654' '655' '656' '657' '661' '662' '663' '664' '665' '666' '667' '671' '672' '673' '674' '675' '676' '677'}; name{4}='Unattend_RVF'; %600s. Correct rejections. 
code{5}={'711' '712' '713' '714' '715' '716' '717' '721' '722' '723' '724' '725' '726' '727' '731' '732' '733' '734' '735' '736' '737' ...
         '751' '752' '753' '754' '755' '756' '757' '761' '762' '763' '764' '765' '766' '767' '771' '772' '773' '774' '775' '776' '777'}; name{5}='Misses'; %700s. Misses, not broken up by visual field.
code{6}={'811' '812' '813' '814' '815' '816' '817' '821' '822' '823' '824' '825' '826' '827' '831' '832' '833' '834' '835' '836' '837' ...
         '851' '852' '853' '854' '855' '856' '857' '861' '862' '863' '864' '865' '866' '867' '871' '872' '873' '874' '875' '876' '877'}; name{6}='False_Alarms'; %800s. False alarms, not broken up by visual field. 

%Break up by eccentricity
%Define by near, middle, far?
%code{7}=[331 332 333 334 335 336 337];                              name{7}='Attend_LVF_near';
%code{8}=[311 312 313 314 315 316 317 321 322 323 324 325 326 327];  name{8}='Attend_LVF_far';
%code{9}=[451 452 453 454 455 456 457];                              name{9}='Attend_RVF_near';
%code{10}=[461 462 463 464 465 466 467 471 472 473 474 475 476 477]; name{10}='Attend_RVF_far';
%code{11}=[531 532 533 534 535 536 537];                             name{11}='Unattend_LVF_near';
%code{12}=[511 512 513 514 515 516 517 521 522 523 524 525 526 527]; name{12}='Unattend_LVF_far';
%code{13}=[651 652 653 654 655 656 657];                             name{13}='Unattend_RVF_near';
%code{14}=[661 662 663 664 665 666 667 671 672 673 674 675 676 677]; name{14}='Unattend_RVF_far';

%NOTE: how to return index values of a structure:
% x = find([EEG.event.type] == 200)

for i=1:size(code,2)
    
    EEG = pop_loadset('filename', [subj_init '_ica_clean.set'], 'filepath', pwd);
    EEG = eeg_checkset(EEG);
    
    misses = find([EEG.event.type] > 700 & [EEG.event.type] < 800); %find index numbers of misses (if there were any)
    false_alarms = find([EEG.event.type] > 800); %find index numbers of false alarms (if there were any)
    
    
    if (i == 5 & isempty(misses))
        %go back up to the top of the for loop
    
    elseif (i == 6 & isempty(false_alarms))
        %leave for loop
        return
    
    else
        % Epoch the data
        %
        % EEG - Input dataset.
        % typerange  - Cell array of event types to time lock to. 'eventindices' {default {} --> time lock epochs to any type of event}
        %                  (Note: An event field called 'type' must be defined in the 'EEG.event' structure. The command line argument is 'eventindices' below).
        % timelim    - Epoch latency limits [start end] in seconds relative to the time-locking event
        % newname  - [string] New dataset name
        % epochinfo - ['yes'|'no'] Propagate event information into the new epoch structure
        % NOTE: this redefines your timing in terms of the event codes that are specified. For example, '311' = time 0. This is important for using
        % pop_rmbase below.
        
        EEG = pop_epoch(EEG, code{i}, [-0.3 2], 'newname', [subj_init '_epoched_' name{i}], 'epochinfo', 'yes');
        EEG = eeg_checkset(EEG);
        
        % Remove channel baseline means from an epoched or continuous EEG
        % dataset. Must do this before averaging across subjects.
        %
        % timerange  - [min_ms max_ms] Baseline latency range in milliseconds. Empty or [] input -> Use whole epoch as baseline
        % NOTE: 0 = time of event specified in pop_epoch.
        EEG = pop_rmbase(EEG, [-100 0]); %normalizing to the first 100 ms before event (according to Ulrike, this is standard)
        EEG = eeg_checkset(EEG);
        
        EEG = pop_saveset(EEG, 'filename', [subj_init '_epoched_' name{i} '.set'], 'filepath', pwd);
        EEG = eeg_checkset(EEG);
    end %end if
    
end %end for







