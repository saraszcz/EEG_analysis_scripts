function [] = step1_readin(subj_init)
%FUNCTION [] = READIN(SUBJ_INIT)
%this function reads in the .bdf Biosemi file and puts it into EEGLAB
%format. 2/4/11- modified from Ulrike Kraemer's script.
%takes in one variable:
%subj_init: subject's initials. Example: 'SS'
%
%modifed by SS on 2/15/10 from scripts originally provided by Ulrike
%Kraemer.

% run for each block, if you collected your data in separate blocks
%for i = 1:block
    

%NOTE: there are 72 channels (64 head electrodes + 8 external channels) +
%the Bisemi code channel, which is considered #73. 
%channel 65: external 1 (empty)
%channel 66: external 2 (right HEOG)
%channel 67: external 3 (left HEOG)
%channel 68: external 4 (right VEOG
%channel 69: external 5 (left earlobe)
%channel 70: external 6 (right earlobe)
%channel 71: external 7 (empty)
%channel 72: external 8 (empty)
%channel 73: Biosemi event channel

%filename, range (channel numbers to import), event channel indexes [channel 73 = this is the channel with the Biosemi codes, reference
%channels (two earlobes).
EEG = pop_readbdf(['/home/knight/sszczepa/Desktop/EEG/Age_matched_controls/022_KD/hi_res_data/trial_locked/' subj_init '.bdf'], [] , 73 , [69 70] ); %cluster
%EEG = pop_readbdf(['/Volumes/HWNI_Cluster/sszczepa/Desktop/EEG/Age_matched_controls/009_JAB/hi_res_data/trial_locked/' subj_init '.bdf'], [] , 73 , [69 70] ); %desktop



%NOTE: pop_readbdf does NOT subtract the two external ear electrodes from
%the data!!  So you must remember to re-reference to the average of those two
%electrodes afterwards


EEG.setname = [subj_init];

EEG = eeg_checkset(EEG); %makes sure that the EEG structure is in the correct format, etc...  

EEG = pop_saveset(EEG, 'filename', [subj_init '.set'], 'filepath', pwd);
  
%end

