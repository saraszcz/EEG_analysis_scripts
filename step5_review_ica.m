function [] = step5_review_ica(subj_init,remICAcomp,interactive,ICAcomp,elecs,Pos,subjects)
% 
%   function [] = step5_review_ica(subj_init,remICAcomp,interactive,ICAcomp,elecs,Pos,subjects)
%   This function reviews ICA components and original data
%   
%   subj_init        -   Subject's initials. Ex - 'ss'
%   remICAcomp       -   ICA components to remove               (default [1]) NOTE: it is better not to use the default here.
%   interactive      -   Promopt for components and view data   (defualt 1 (on, 0 for off))
%   ICAcomp          -   Number of ICA components to view       (default [1:30])
%   elecs            -   Electrodes to view                     (default [1:64])
%   Pos              -   Window position (do not have to put in a value)
%   
%
%
% Modified by Sara Szczepanski (2/28/11) from original script by Adeen Flinker
%

if (nargin<1)
    error('must input subject initials');
end
if (~exist('remICAcomp'))
   remICAcomp = 1; 
end
if (~exist('interactive'))
    interactive = 1;
end
if (~exist('ICAcomp'))
   ICAcomp = 1:30; 
end
if (~exist('elecs'))
    elecs = 1:64;
end
if (~exist('subjects'))
     subjects = [];
end


EEG = pop_loadset('filename', [subj_init '_ica.set'], 'filepath', pwd);
EEG = eeg_checkset(EEG);

load ICAweights.mat;
%s =1;
%while (s <=length(dr))
    close all
    %clear *data
    
    %SJ = str2num(dr(s).name(1:findstr(dr(s).name,'_')-1));
    %if isempty(intersect(SJ,subjects))
    %    fprintf('Skipping subject %d\n',SJ);
    %    s = s+1;
    %    continue;
    %else
    %    subjects = setxor(subjects,SJ);
    %end
    %fprintf('Subject %d, ',SJ);
    %load(dr(s).name);
    
    % compute ICA components using zero-meaned data
    mn = mean(EEG.data(1:64,:),2);  %computes the mean of each channel across all timepoints for that channel                 
    activations = ICAweights(:,:) * (EEG.data(1:64,:) - repmat(mn,1,size(EEG.data,2))); %subtracting the mean from the data and then
    %multiplying the data by the ICA weights. this is the independent component data.
    
    if (interactive) %if you want to see the data and the components
        data_nums = intersect(elecs,1:64);
        if elecs(end) > 64 % showing non-eeg (external electrode) data, start normalization
            periph_nums = setxor(data_nums,elecs);%finds the electrodes that are not in the first 64 electrodes and assigns them as
            %external electrodes.
            
            EEGnorm = mean(max(EEG.data(data_nums,:),[],2)); %finds the max number for each channel and then averages them together?
            
            for i = 1:length(periph_nums)
                Pdata(i,:) = EEG.data(periph_nums(i),:)./std(EEG.data(periph_nums(i),:)).*EEGnorm; %z scoring the data (multiplying by mean and dividing by STDEV)
            end
            Vdata = [Pdata; EEG.data(data_nums,:)]; %putting external electrodes back in the data matrix after being z-scored
            chanlocs_new = [EEG.chanlocs(periph_nums) EEG.chanlocs(data_nums)]; %redefining where channel locations are
        else
            Vdata = EEG.data(data_nums,:);
            chanlocs_new = EEG.chanlocs(data_nums);
        end
        
        % add ICA components to eegplot view
        EEGnorm = mean(std(EEG.data(data_nums,:),[],2)); %computes the STDEV for each channel and then averages across the STDEVs?
        
        for i = 1:length(ICAcomp) %for the number of ICA components that you want to see
            Idata(i,:) = activations(ICAcomp(i),:)./std(activations(ICAcomp(i),:)).*EEGnorm; %normalizing the independant component data (dividing by stdev and multiplying by mean of stdevs)
            %%NOTE: do i have to add these below?
           
            Ilocs(i).labels = ['ICA' num2str(ICAcomp(i))];
            Ilocs(i).theta      = 0;
            Ilocs(i).radius     = 0;
            Ilocs(i).X          = 0;
            Ilocs(i).Y          = 0;
            Ilocs(i).Z          = 0;
            Ilocs(i).sph_theta  = 0;
            Ilocs(i).sph_phi    = 0;
            Ilocs(i).sph_radius = 0;
            Ilocs(i).type       = [''];
            Ilocs(i).urchan     = [1:ICAcomp];
            Ilocs(i).ref        = [''];
            
        end
        
        Vdata = [Idata; Vdata]; %appends the independent components to the actual electrode data (as well as the external electrode data, if that
        %was provided). independant components will be shown at the TOP of the GUI.
        
        %keyboard
        
        chanlocs_new = [Ilocs chanlocs_new];
        
        %plots data out.
        if (exist('Pos'))
            eegplot(Vdata,'srate',EEG.srate,'position',Pos,'eloc_file',chanlocs_new);
        else
            eegplot(Vdata,'srate',EEG.srate,'eloc_file',chanlocs_new);
        end
        rem = input(sprintf('Remove ICA component (default is %d)? ',remICAcomp)); %lets you choose which ICA component to remove, after examining the data
        if isempty(rem), rem = remICAcomp; end
    else
        rem = remICAcomp; %this option is if you do not want to inspect the components by eye and you already know the component # to remove.
    end
    
    % remove ICA components from the data
    activations(rem,:) = 0; % remove ICA components. sets the specified component to zero.
    projection = inv(ICAweights(:,:)) * activations; % reconstruct data with component removed.
    %projection = EEG.data with specified ICA compoenent removed?
    
    if (interactive)
        close all
        chanlocs_new = [chanlocs_new EEG.chanlocs(data_nums)];
        if (exist('Pos'))
            eegplot([Vdata;projection(data_nums,:)],'srate',EEG.srate,'position',Pos,'eloc_file',chanlocs_new);
        else
            eegplot([Vdata;projection(data_nums,:)],'srate',EEG.srate,'eloc_file',chanlocs_new); %plots data with ICA component(s) removed (underneath old data)
        end
        resp = input('save data? (y or n)','s'); 
    else
        resp = 'y'; 
    end
    if resp == 'y' %|| resp == 'yes') %if you said yes to saving the data
        EEG = pop_loadset('filename', [subj_init '_ica.set'], 'filepath', pwd); %reloads data from scratch
        EEG = eeg_checkset(EEG);
        
        %EEG.data_ICArem = [projection; EEG.data(65:end,:)]; %replaces old data with new data that has component removed. does not touch external electrodes
        %Note: Should I reassign EEG.data instead?? For example:
        EEG.data = [projection; EEG.data(65:end,:)];
        EEG.history = [EEG.history sprintf('\nRemoved ICA components %s from %s',num2str(rem),'data')];
        
        %EEG.weightsICA = ICAweights(:,:); %I don't think we need to save this,
        %since it was saved by the previous script (if you are using EEGLAB structure).
        
        disp('');
        disp('Saving data file');
        disp('');
        
        EEG.setname = [subj_init '_hp0.5_ch66_ica_clean'];
        EEG = pop_saveset(EEG, 'filename', [subj_init '_ica_clean.set'], 'filepath', pwd);
        EEG = eeg_checkset(EEG);
    else
        resp=input(sprintf('Rerun Subject? '));
        if resp=='y' || strcmp(resp,'yes')
            %s = s-1; 
            %return to beginning?
        else
            return
        end
        %subjects = union(subjects,SJ);
    end
    %if (interactive && i ==1)  % store current figure position
    %    Pos = get(gcf,'Position');
    %end
    %s = s+1;
%end %end while

%cd(curr_dir);


