%% Event Markers: ERP-Core, N400 Dataset
% Author: Jessica M. Alexander
% This script labels the validity, relatedness, and accuracy for pre-, intra-, and post-trial event markers for the ERP CORE N400 dataset.
% It includes additional labels (PostREL, PriorACC, and PostACC) not subsequently used merely for the sake of practice in building complex labeling.
%
% This script is based, in part, on a sample script (for the ERP CORE ERN Dataset) created by George Buzzell
% for the NDCLab EEG Training Workshop in 2021 (https://github.com/NDCLab/lab-training/tree/main/eeg-analysis).

					
%% Event Codes
% Stimulus Event Codes

% Word Type	hundreds place	Word Pair Type	tens place	Word List	ones place	Event Code
% Prime	    1	            Related	        1	        List 1	    1	        111
% Prime	    1	            Related	        1	        List 2	    2	        112
% Prime	    1	            Unrelated	    2	        List 1	    1	        121
% Prime	    1	            Unrelated	    2	        List 2	    2	        122
% Target 	2	            Related	        1	        List 1	    1	        211
% Target 	2	            Related	        1	        List 2	    2	        212
% Target 	2	            Unrelated	    2	        List 1	    1	        221
% Target 	2	            Unrelated	    2	        List 2	    2	        222	


% Response Event Codes

% Accuracy	Event Code
% correct	    201
% incorrect	    202

% Create separate arrays for prime markers, stimulus markers, and response markers
primeMarkers = {'111', '112', '121', '122'};
stimMarkers = {'211', '212', '221', '222'};
respMarkers = {'201', '202'};

%%
% Add labels to the event structure for:
% Group | Numerical value assigned to each set of prime + stimulus (+ response, if participant responded)
% PrimPlusStim | 1 when prime + stim are confirmed to have appeared together (0 for erroneous stragglers, if any)
% Responded | 1 when participant responded on the trial (0 indicates no response)
% Related | 1 when stimulus was semantically related to the prime (0 indicates unrelated pair)
% ValidRT | 1 when participant response was later than 150 ms after stimulus presentation (0 indicates too fast)
% Accuracy | 1 when participant response was correct (0 indicates incorrect response)
% PriorREL | 1 when stimulus on preceding trial was semantically related to its prime (0 indicates prior trial was an unrelated pair)
% PostREL | 1 when stimulus on following trial was semantically related to its prime (0 indicates next trial was an unrelated pair)
% PriorACC | 1 when participant response to prior trial was correct (0 indicates prior trial was an error)
% PostACC | 1 when participant response to next trial was correct (0 indicates next trial was an error)

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'Group','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'PrimPlusStim','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'Responded','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'Related','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'ValidRT','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'Accuracy','NaN');
EEG = eeg_checkset( EEG );

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'PriorREL','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'PostREL','NaN');
EEG = eeg_checkset(EEG);

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'PriorACC','NaN');
EEG = eeg_checkset( EEG );

EEG = pop_editeventfield(EEG, 'indices', strcat('1:', int2str(length(EEG.event))), 'PostACC','NaN');
EEG = eeg_checkset( EEG );

%%
% Add 'Group' for prime+stimulus pairs
groupNo = 1;
for k = 1:length(EEG.event)
    if ismember(EEG.event(k).type, primeMarkers) && ismember(EEG.event(k+1).type, stimMarkers)
        EEG.event(k).Group=groupNo;
        EEG.event(k+1).Group=groupNo;
        groupNo = groupNo + 1;
    else
        continue
    end
end

%%
% Loop through all prime markers in order to label each (and its associated stimulus and response)
for i = 1:length(primeMarkers)
    primes = find(strcmp({EEG.event.type}, primeMarkers{i}));
    for j = primes
        
        % Identify valid triplets (prim + stim + response), label 'PrimPlusStim' and 'Responded', add 'Group' to response marker
        if ismember(EEG.event(j+1).type, stimMarkers) && ismember(EEG.event(j+2).type, respMarkers)
                EEG.event(j).PrimPlusStim = 1;
                EEG.event(j+1).PrimPlusStim = 1;
                EEG.event(j+2).PrimPlusStim = 1;    
                EEG.event(j).Responded = 1;
                EEG.event(j+1).Responded = 1;
                EEG.event(j+2).Responded = 1;
                EEG.event(j+2).Group = EEG.event(j).Group;
        
            % Label 'Related'
            % Prime marker and stimulus are related for prime markers 111 and 112 (not 121 and 122)
            if ismember(EEG.event(j).type, {'111', '112'})
                EEG.event(j).Related = 1;
                EEG.event(j+1).Related = 1;
                EEG.event(j+2).Related = 1;
            else
                EEG.event(j).Related = 0;
                EEG.event(j+1).Related = 0;
                EEG.event(j+2).Related = 0;
            end

            % Label 'ValidRT'
            % Participant response greater than 150 ms after stimulus presentation is deemed 'valid'
            if (EEG.event(j+2).latency - EEG.event(j+1).latency) * 1000/EEG.srate > 150
                EEG.event(j).ValidRT = 1;
                EEG.event(j+1).ValidRT = 1;
                EEG.event(j+2).ValidRT = 1;
            else
                EEG.event(j).ValidRT = 0;
                EEG.event(j+1).ValidRT = 0;
                EEG.event(j+2).ValidRT = 0;
            end

            % Label 'Accuracy'
            % Participant response is accurate for response marker 201 (not 202)
            if EEG.event(j+2).type=="201"
                EEG.event(j).Accuracy = 1;
                EEG.event(j+1).Accuracy = 1;
                EEG.event(j+2).Accuracy = 1;
            elseif EEG.event(j+2).type=="202"
                EEG.event(j).Accuracy = 0;
                EEG.event(j+1).Accuracy = 0;
                EEG.event(j+2).Accuracy = 0;
            end

        elseif ismember(EEG.event(j+1).type, stimMarkers) && ~ismember(EEG.event(j+2).type, respMarkers) % Prime and stim are not followed by response
            EEG.event(j).PrimPlusStim = 1;
            EEG.event(j+1).PrimPlusStim = 1;
            EEG.event(j).Responded = 0;
            EEG.event(j+1).Responded = 0;

            % Label 'Related' for prime and stimulus in response-less pair
            if ismember(EEG.event(j).type, {'111', '112'})
                EEG.event(j).Related = 1;
                EEG.event(j+1).Related = 1;
            else
                EEG.event(j).Related = 0;
                EEG.event(j+1).Related = 0;
            end
        
        else % Prime marker is not part of a valid prime + stimulus pair
            continue
        
        end
    
    end

end

%%
% Remove any stragglers who are not part of a valid prime+stimulus pair (with or without response)
EEG = pop_selectevent(EEG, 'PrimPlusStim', 1, 'deleteevents', 'on');
EEG = eeg_checkset(EEG);

%%
% Loop through all groups, labeling following group events with 'PriorACC' and preceding group events with 'PostACC' based on the current group details
groups = 1:max(cell2mat({EEG.event.Group}'));
for a = groups
    current_group = find(cell2mat({EEG.event.Group}')==a);
    prior_group = find(cell2mat({EEG.event.Group}')==(a-1));
    next_group = find(cell2mat({EEG.event.Group}')==(a+1));
    if a==1
        EEG.event(next_group(1)).PriorACC = EEG.event(current_group(1)).Accuracy;
        EEG.event(next_group(2)).PriorACC = EEG.event(current_group(1)).Accuracy;
        if length(next_group)==3
            EEG.event(next_group(3)).PriorACC = EEG.event(current_group(1)).Accuracy;
        end
    elseif a==max(groups)
        EEG.event(prior_group(1)).PostACC = EEG.event(current_group(1)).Accuracy;
        EEG.event(prior_group(2)).PostACC = EEG.event(current_group(1)).Accuracy;
        if length(prior_group)==3
            EEG.event(prior_group(3)).PostACC = EEG.event(current_group(1)).Accuracy;
        end
    else
        EEG.event(next_group(1)).PriorACC = EEG.event(current_group(1)).Accuracy;
        EEG.event(next_group(2)).PriorACC = EEG.event(current_group(1)).Accuracy;
        if length(next_group)==3
            EEG.event(next_group(3)).PriorACC = EEG.event(current_group(1)).Accuracy;
        end
        
        EEG.event(prior_group(1)).PostACC = EEG.event(current_group(1)).Accuracy;
        EEG.event(prior_group(2)).PostACC = EEG.event(current_group(1)).Accuracy;
        if length(prior_group)==3
            EEG.event(prior_group(3)).PostACC = EEG.event(current_group(1)).Accuracy;
        end
    end
end

%%
% Loop through all groups, labeling following group events with 'PriorREL' and preceding group events with 'PostREL' based on the current group details
for a = groups
    current_group = find(cell2mat({EEG.event.Group}')==a);
    prior_group = find(cell2mat({EEG.event.Group}')==(a-1));
    next_group = find(cell2mat({EEG.event.Group}')==(a+1));
    if a==1
        EEG.event(next_group(1)).PriorREL = EEG.event(current_group(1)).Related;
        EEG.event(next_group(2)).PriorREL = EEG.event(current_group(1)).Related;
        if length(next_group)==3
            EEG.event(next_group(3)).PriorREL = EEG.event(current_group(1)).Related;
        end
    elseif a==max(groups)
        EEG.event(prior_group(1)).PostREL = EEG.event(current_group(1)).Related;
        EEG.event(prior_group(2)).PostREL = EEG.event(current_group(1)).Related;
        if length(prior_group)==3
            EEG.event(prior_group(3)).PostREL = EEG.event(current_group(1)).Related;
        end
    else
        EEG.event(next_group(1)).PriorREL = EEG.event(current_group(1)).Related;
        EEG.event(next_group(2)).PriorREL = EEG.event(current_group(1)).Related;
        if length(next_group)==3
            EEG.event(next_group(3)).PriorREL = EEG.event(current_group(1)).Related;
        end
        
        EEG.event(prior_group(1)).PostREL = EEG.event(current_group(1)).Related;
        EEG.event(prior_group(2)).PostREL = EEG.event(current_group(1)).Related;
        if length(prior_group)==3
            EEG.event(prior_group(3)).PostREL = EEG.event(current_group(1)).Related;
        end
    end
end

%%
% Useful code for searching through event details
%cell2mat({EEG.event.Accuracy}')
%find(cell2mat({EEG.event.Related}')==0)