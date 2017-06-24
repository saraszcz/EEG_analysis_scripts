function [] = step2_preprocess_trial_lock(subj_init)
%FUNCTION [] = STEP2_PREPROCESS_TRIAL_LOCK(SUBJ_INIT)
%
%This function does all of the processing of the EEG data (resampling,
%filtering, etc...)
%SUBJ_INIT = subjects initials. Ex- 'ss'
%
%modifed by SS on 2/15/10 from scripts originally provided by Ulrike
%Kraemer.
%moddifed by SS 8/1/2013- added remove DC shift, notch filter, and resample to 1000 Hz
%
%
%
%


%for i = 1:block %run for each block
% load file
EEG = pop_loadset('filename', [subj_init '.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);

% remove *real* channel mean (i.e., remove DC offset)
% Note: Converting to double is important. If there is significant drift or DC
% offset, the "mean" function (which sums across all points) can cause
% an overflow error, leading to inaccurate results.
for numChans = 1:size(EEG.data,1);
    EEG.data(numChans, :) = single(double(EEG.data(numChans, :)) - mean(double(EEG.data(numChans, :))));
end

% resample to 1000 Hz (from 1024 Hz recorded with Biosemi)
% NOTE: some of the first subjects were collected only at 256 HZ!
% Age-matched controls: S1, S2, S3, S4
EEG = pop_resample(EEG, 1000); % uses resample.m if available
EEG.setname=[subj_init '_rs1000'];
EEG = eeg_checkset(EEG);

%filter for highpass at 0.5Hz or 0.1Hz (lowest frequency). pop_eegfilt uses filtfilt.m
EEG = pop_eegfilt(EEG, 0.5, 0, [], 0);
EEG.setname=[subj_init '_rs1000_hp_0.5'];
EEG = eeg_checkset(EEG);

%%%%%%%%%%%%% FILTER OUT 60 Hz LINE NOISE%%%%%%%%%%%%%%%%%%%%%%

%Configure MATLAB to use the MDCS.
%HWNI=parallel.importProfile('/usr/local/matlab-tools/HWNI'); 
%parallel.defaultClusterProfile(HWNI);

%matlabpool

disp('Filtering')
tic

%written for parallel computing
%EEG.data = remove_line_noise_par(EEG.data',60,EEG.srate,1)';%funciton written by Leon in order to notch filter the data.
%written for consecutive analysis
EEG.data = remove_line_noise(EEG.data',60,EEG.srate,1)';%funciton written by Leon in order to notch filter the data.

done = toc;
disp(['Done filtering in ' num2str(done/60) ' minutes'])

%matlabpool close

EEG.setname=[subj_init '_rs1000_hp_0.5_notch'];
EEG = eeg_checkset(EEG);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%channel 65: external 1 (empty)
%channel 66: external 2 (right HEOG)
%channel 67: external 3 (left HEOG)
%channel 68: external 4 (right VEOG)
%channel 69: external 5 (left earlobe)
%channel 70: external 6 (right earlobe)
%channel 71: external 7 (empty)
%channel 72: external 8 (empty)

% edit channels
EEG.data(68,:)= EEG.data(68,:)- EEG.data(34,:); %VEOG. Reassign the right VEOG channel to be the difference between the VEOG channel and Fp2.
                                                %Fp2 is essentially being treated like a second VEOG above the eye 
EEG.data(66,:)= EEG.data(66,:)- EEG.data(67,:); %HEOG. Reassign right HEOG to be the difference between the right and left HEOG channels.

%look-up channel numbers for standard locations in the channel location file given as input.
EEG = pop_chanedit(EEG, 'lookup', ...
     '/home/knight/sszczepa/Desktop/eeglab9_0_0_1b/plugins/dipfit2.2/standard_BESA/standard-10-5-cap385.elp');

%EEG = pop_chanedit(EEG,  'changefield',{72, 'datachan',0}, 'changefield',{71, 'datachan',0});
%EEG = eeg_checkset(EEG);

%get rid of the following channels, since they will not be used from now on
%does this work correctly?
%throws out reference (channel 34), left HEOG (channel 67), right and left
%ears (channels 69 and 70), external channels 7 and 8 (channels 71 and 72).
%keeps channels 66 and 68.
EEG = pop_select(EEG, 'nochannel',{'ref', 'lEOG', 'rEAR', 'lEAR', 'EXG7', 'EXG8'});
EEG.setname = [subj_init '_rs1000_hp_0.5_notch_ch66'];
EEG = eeg_checkset(EEG);
%you should now have 66 EEG channels. 65= HEOG, 66= VEOG.  

%Remove events included by biosemi above 255. Biosemi start code = 254,
%Biosemi pause code = 255. anything above this is trash.
%Must always run this because biosemi introduces extremely large event
%codes randomly (we don't know why)
badEvents = [];
foo = 1;

for x = 1:length(EEG.event)
    if ~ischar(EEG.event(x).type)
        if EEG.event(x).type > 255
            badEvents(foo) = x;
            foo = foo + 1;
        end
    end
    
    if ischar(EEG.event(x).type)
        if str2num(EEG.event(x).type > 255)
            badEvents(foo) = x;
            foo = foo + 1;
        end
    end
end
clear x foo

EEG = pop_editeventvals(EEG, 'delete', badEvents);

%re-coding events
%NOTE: this would have been SO MUCH Easier if I had coded the Attend RVF
%and ATTEND LVF blocks separately!!  I will do this in the future-- just
%define start event = 21 for attend right and start event = 23 for attend
%left.

for e = 1:(size(EEG.event,2)-1) %for the number of events (-1)
    %reassigns codes so that you can differentiate ATTEND RVF vs. ATTEND
    %LVF. Designed so that when the analysis is done, the ERPs are time-locked
    %to the ***beginning of the trial. 
    
    %recode as Attend LVF-- correct HIT. 300s
    if (EEG.event(e).type == 111 && EEG.event(e+1).type == 200) % the stimulus was in the LVF and there was a hit
        EEG.event(e-1).type = 311;
        
    elseif (EEG.event(e).type == 112 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 312;
        
    elseif (EEG.event(e).type == 113 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 313;
        
    elseif (EEG.event(e).type == 114 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 314;
        
    elseif (EEG.event(e).type == 115 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 315;
        
    elseif (EEG.event(e).type == 116 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 316;
        
    elseif (EEG.event(e).type == 117 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 317;
        
    elseif (EEG.event(e).type == 121 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 321;  
   
    elseif (EEG.event(e).type == 122 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 322;
        
    elseif (EEG.event(e).type == 123 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 323;
        
    elseif (EEG.event(e).type == 124 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 324;
        
    elseif (EEG.event(e).type == 125 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 325;
        
    elseif (EEG.event(e).type == 126 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 326;
        
    elseif (EEG.event(e).type == 127 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 327;
        
    elseif (EEG.event(e).type == 131 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 331;  
   
    elseif (EEG.event(e).type == 132 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 332;
        
    elseif (EEG.event(e).type == 133 && EEG.event(e+1).type == 200) 
        EEG.event(e-1).type = 333;
        
    elseif (EEG.event(e).type == 134 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 334;
        
    elseif (EEG.event(e).type == 135 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 335;
        
    elseif (EEG.event(e).type == 136 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 336;
        
    elseif (EEG.event(e).type == 137 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 337;
        
    %recode as Attend RVF-- correct HIT. 400s
    elseif (EEG.event(e).type == 151 && EEG.event(e+1).type == 200) % the stimulus was in the RVF and there was a hit
        EEG.event(e-1).type = 451;
        
    elseif (EEG.event(e).type == 152 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 452;
        
    elseif (EEG.event(e).type == 153 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 453;
        
    elseif (EEG.event(e).type == 154 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 454;
        
    elseif (EEG.event(e).type == 155 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 455;
        
    elseif (EEG.event(e).type == 156 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 456;
        
    elseif (EEG.event(e).type == 157 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 457;
        
    elseif (EEG.event(e).type == 161 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 461;
        
    elseif (EEG.event(e).type == 162 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 462;
        
    elseif (EEG.event(e).type == 163 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 463;
        
    elseif (EEG.event(e).type == 164 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 464;
        
    elseif (EEG.event(e).type == 165 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 465;
        
    elseif (EEG.event(e).type == 166 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 466;
        
    elseif (EEG.event(e).type == 167 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 467;
        
    elseif (EEG.event(e).type == 171 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 471;
        
    elseif (EEG.event(e).type == 172 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 472;
        
    elseif (EEG.event(e).type == 173 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 473;
        
    elseif (EEG.event(e).type == 174 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 474;
        
    elseif (EEG.event(e).type == 175 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 475;
        
    elseif (EEG.event(e).type == 176 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 476;
        
    elseif (EEG.event(e).type == 177 && EEG.event(e+1).type == 200)
        EEG.event(e-1).type = 477;
       
    %recode as Unattend LVF-- correct rejection. 500s 
    elseif (EEG.event(e).type == 111 && EEG.event(e+1).type == 31) %the stimulus was in the LVF and there was a correct rejection
        EEG.event(e-1).type = 511;
        
    elseif (EEG.event(e).type == 112 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 512;
        
    elseif (EEG.event(e).type == 113 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 513;
        
    elseif (EEG.event(e).type == 114 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 514;
        
    elseif (EEG.event(e).type == 115 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 515;
        
    elseif (EEG.event(e).type == 116 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 516;
    
    elseif (EEG.event(e).type == 117 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 517;
        
    elseif (EEG.event(e).type == 121 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 521;  
   
    elseif (EEG.event(e).type == 122 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 522;
        
    elseif (EEG.event(e).type == 123 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 523;
        
    elseif (EEG.event(e).type == 124 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 524;
        
    elseif (EEG.event(e).type == 125 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 525;
        
    elseif (EEG.event(e).type == 126 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 526;
        
    elseif (EEG.event(e).type == 127 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 527;
        
    elseif (EEG.event(e).type == 131 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 531;  
   
    elseif (EEG.event(e).type == 132 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 532;
        
    elseif (EEG.event(e).type == 133 && EEG.event(e+1).type == 31) 
        EEG.event(e-1).type = 533;
        
    elseif (EEG.event(e).type == 134 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 534;
        
    elseif (EEG.event(e).type == 135 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 535;
        
    elseif (EEG.event(e).type == 136 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 536;
        
    elseif (EEG.event(e).type == 137 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 537;
        
    %recode as Unattend RVF-- correct rejection. 600s    
    elseif (EEG.event(e).type == 151 && EEG.event(e+1).type == 31) %the stimulus was in the RVF and there was a correct rejection
        EEG.event(e-1).type = 651;
        
    elseif (EEG.event(e).type == 152 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 652;
        
    elseif (EEG.event(e).type == 153 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 653;
        
    elseif (EEG.event(e).type == 154 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 654;
        
    elseif (EEG.event(e).type == 155 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 655;
        
    elseif (EEG.event(e).type == 156 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 656;
        
    elseif (EEG.event(e).type == 157 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 657;
        
    elseif (EEG.event(e).type == 161 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 661;
        
    elseif (EEG.event(e).type == 162 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 662;
        
    elseif (EEG.event(e).type == 163 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 663;
        
    elseif (EEG.event(e).type == 164 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 664;
        
    elseif (EEG.event(e).type == 165 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 665;
        
    elseif (EEG.event(e).type == 166 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 666;
        
    elseif (EEG.event(e).type == 167 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 667;
        
    elseif (EEG.event(e).type == 171 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 671;
        
    elseif (EEG.event(e).type == 172 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 672;
        
    elseif (EEG.event(e).type == 173 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 673;
        
    elseif (EEG.event(e).type == 174 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 674;
        
    elseif (EEG.event(e).type == 175 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 675;
        
    elseif (EEG.event(e).type == 176 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 676;
        
    elseif (EEG.event(e).type == 177 && EEG.event(e+1).type == 31)
        EEG.event(e-1).type = 677;
        
    %recode as MISS. 700s
    elseif (EEG.event(e).type == 111 && EEG.event(e+1).type == 30) % there was a miss
        EEG.event(e-1).type = 711;
        
    elseif (EEG.event(e).type == 112 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 712;
        
    elseif (EEG.event(e).type == 113 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 713;
        
    elseif (EEG.event(e).type == 114 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 714;
        
    elseif (EEG.event(e).type == 115 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 715;
        
    elseif (EEG.event(e).type == 116 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 716;
        
    elseif (EEG.event(e).type == 117 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 717;
        
    elseif (EEG.event(e).type == 121 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 721;  
   
    elseif (EEG.event(e).type == 122 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 722;
        
    elseif (EEG.event(e).type == 123 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 723;
        
    elseif (EEG.event(e).type == 124 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 724;
        
    elseif (EEG.event(e).type == 125 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 725;
        
    elseif (EEG.event(e).type == 126 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 726;
        
    elseif (EEG.event(e).type == 127 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 727;
        
    elseif (EEG.event(e).type == 131 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 731;  
   
    elseif (EEG.event(e).type == 132 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 732;
        
    elseif (EEG.event(e).type == 133 && EEG.event(e+1).type == 30) 
        EEG.event(e-1).type = 733;
        
    elseif (EEG.event(e).type == 134 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 734;
        
    elseif (EEG.event(e).type == 135 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 735;
        
    elseif (EEG.event(e).type == 136 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 736;
        
    elseif (EEG.event(e).type == 137 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 737;
        
    elseif (EEG.event(e).type == 151 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 751;
        
    elseif (EEG.event(e).type == 152 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 752;
        
    elseif (EEG.event(e).type == 153 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 753;
        
    elseif (EEG.event(e).type == 154 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 754;
        
    elseif (EEG.event(e).type == 155 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 755;
        
    elseif (EEG.event(e).type == 156 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 756;
        
    elseif (EEG.event(e).type == 157 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 757;
        
    elseif (EEG.event(e).type == 161 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 761;
        
    elseif (EEG.event(e).type == 162 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 762;
        
    elseif (EEG.event(e).type == 163 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 763;
        
    elseif (EEG.event(e).type == 164 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 764;
        
    elseif (EEG.event(e).type == 165 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 765;
        
    elseif (EEG.event(e).type == 166 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 766;
        
    elseif (EEG.event(e).type == 167 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 767;
        
    elseif (EEG.event(e).type == 171 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 771;
        
    elseif (EEG.event(e).type == 172 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 772;
        
    elseif (EEG.event(e).type == 173 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 773;
        
    elseif (EEG.event(e).type == 174 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 774;
        
    elseif (EEG.event(e).type == 175 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 775;
        
    elseif (EEG.event(e).type == 176 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 776;
        
    elseif (EEG.event(e).type == 177 && EEG.event(e+1).type == 30)
        EEG.event(e-1).type = 777;
        
    %recode as FALSE ALARM. 800s
    elseif (EEG.event(e).type == 111 && EEG.event(e+1).type == 202) %there was a false alarm, where the subject responded to the wrong (unattended) side.
        EEG.event(e-1).type = 811;
       
    elseif (EEG.event(e).type == 112 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 812;
        
    elseif (EEG.event(e).type == 113 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 813;
        
    elseif (EEG.event(e).type == 114 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 814;
        
    elseif (EEG.event(e).type == 115 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 815;
        
    elseif (EEG.event(e).type == 116 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 816;
        
    elseif (EEG.event(e).type == 117 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 817;
        
    elseif (EEG.event(e).type == 121 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 821;  
   
    elseif (EEG.event(e).type == 122 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 822;
        
    elseif (EEG.event(e).type == 123 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 823;
        
    elseif (EEG.event(e).type == 124 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 824;
        
    elseif (EEG.event(e).type == 125 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 825;
        
    elseif (EEG.event(e).type == 126 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 826;
        
    elseif (EEG.event(e).type == 127 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 827;
        
    elseif (EEG.event(e).type == 131 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 831;  
   
    elseif (EEG.event(e).type == 132 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 832;
        
    elseif (EEG.event(e).type == 133 && EEG.event(e+1).type == 202) 
        EEG.event(e-1).type = 833;
        
    elseif (EEG.event(e).type == 134 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 834;
        
    elseif (EEG.event(e).type == 135 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 835;
        
    elseif (EEG.event(e).type == 136 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 836;
        
    elseif (EEG.event(e).type == 137 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 837;
        
    elseif (EEG.event(e).type == 151 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 851;
        
    elseif (EEG.event(e).type == 152 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 852;
        
    elseif (EEG.event(e).type == 153 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 853;
        
    elseif (EEG.event(e).type == 154 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 854;
        
    elseif (EEG.event(e).type == 155 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 855;
        
    elseif (EEG.event(e).type == 156 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 856;
        
    elseif (EEG.event(e).type == 157 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 857;
        
    elseif (EEG.event(e).type == 161 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 861;
        
    elseif (EEG.event(e).type == 162 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 862;
        
    elseif (EEG.event(e).type == 163 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 863;
        
    elseif (EEG.event(e).type == 164 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 864;
        
    elseif (EEG.event(e).type == 165 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 865;
        
    elseif (EEG.event(e).type == 166 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 866;
        
    elseif (EEG.event(e).type == 167 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 867;
        
    elseif (EEG.event(e).type == 171 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 871;
        
    elseif (EEG.event(e).type == 172 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 872;
        
    elseif (EEG.event(e).type == 173 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 873;
        
    elseif (EEG.event(e).type == 174 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 874;
        
    elseif (EEG.event(e).type == 175 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 875;
        
    elseif (EEG.event(e).type == 176 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 876;
        
    elseif (EEG.event(e).type == 177 && EEG.event(e+1).type == 202)
        EEG.event(e-1).type = 877;
        
    end %end if
end %end for

EEG = pop_saveset(EEG, 'filename', [subj_init '_preproc_trialloc.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);


%end %end for