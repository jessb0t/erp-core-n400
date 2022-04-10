%% ERPs, Topo Plots, and Mean Amplitudes: ERP-Core, N400 Dataset
% Author: Jessica M. Alexander
% This script postprocesses the N400 data from the ERP CORE, including:
% Section 1: setting up variables
% Section 2: establishing file paths
% Section 3: getting trial counts for specific conditions
% Section 4: creating a .mat file with all participant data (subjects x conditions x channels x sample points)
% Section 5: correcting the baseline for subsequent plotting (ERPs, topos) and extraction of mean amplitudes
% Section 6: plotting ERPs (individual and grand average)
% Section 7: plotting individual topos
% Section 8: extraction of mean component amplitudes
%
% This script is based on a sample script (for the ERP CORE ERN Dataset) created by George Buzzell
% for the NDCLab EEG Training Workshop in 2022 (https://github.com/NDCLab/lab-training/tree/main/eeg-analysis).
% It uses parts of the setup structure from the MADE preprocessing pipeline (https://github.com/ChildDevLab/MADE-EEG-preprocessing-pipeline).


%% SECTION 1: Setup
% Markers (copied from event labeling script)
primeMarkers = {'111', '112', '121', '122'};
stimMarkers = {'211', '212', '221', '222'};
respMarkers = {'201', '202'};

% Establish size of multidimensional array for participant data
nbChannels = 28;
nbSamplePoints = 3072;
nbConditions = 6;

% Select channels to plot
chansToCluster = [14, 15, 22];

% Select baseline window
baselineStartTime = -100;       %(in ms)
baselineStopTime = 0 ;          %(in ms)
% Handy Reminders for Baseline Windows
%%% stimulus-locked: [-200 0]
%%% response-locked: [-400 -200]

% Select plot window for ERPs (x-axis)
erpPlotStartTime = -100;        %(in ms)
erpPlotEndTime = 500;           %(in ms)

% Select window for component of interest (topos and mean amplitude)
compStartTime = 250;            %(in ms)
compEndTime = 500;              %(in ms)

% Define ERP plot colors
black = [0 0 0];
purple = '#440154';
green = '#349d38';
grey = '#c9c9c9';
lightGrey = '#ebebeb';


%% SECTION 2: Filepaths
main_dir = '/Users/jalexand/github/erp-core-n400';
addpath(genpath([main_dir filesep 'code' filesep 'made-and-eeglab']));
addpath(genpath([main_dir filesep 'code' filesep 'made-and-eeglab' filesep 'eeglab13_4_4b']));
rmpath([main_dir filesep 'code' filesep 'made-and-eeglab' filesep 'eeglab13_4_4b' filesep 'functions' filesep 'octavefunc' filesep 'signal']) %remove octave

% File Locations
data_location = [main_dir filesep 'data' filesep 'processed-eeg' filesep 'processed_data'];
output_location = [main_dir filesep 'results'];
channel_locations = [main_dir filesep 'code' filesep 'standard-10-5-cap385.elp'];

% Files to Analyze
datafile_names=dir([data_location filesep '*_N400_ica_data_processed.set']);
datafile_names=datafile_names(~ismember({datafile_names.name},{'.', '..', '.DS_Store'}));
datafile_names={datafile_names.name};
[filepath,name,ext] = fileparts(char(datafile_names{1}));

% Check that EEGLAB is available.
if exist('eeglab','file')==0
    error('Please make sure EEGLAB is on your MATLAB path.');
end

% Switch to Output Directory
cd(output_location);

%% SECTION 3: Count Trials

% Gather trial counts for each subject
for subject=1:length(datafile_names)
    EEG=[]; 
    fprintf('\n\n\n*** Processing subject %d (%s) ***\n\n\n', subject, datafile_names{subject});
    
    % Load in raw data (.set format) and access subject ID
    EEG = pop_loadset( 'filename', datafile_names{subject}, 'filepath', data_location);
    EEG = eeg_checkset(EEG);
    id(subject) = EEG.subject;

    % Count event type combos
    stimUnrelCorr(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 0) & ([EEG.event.Accuracy] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)  ));                   
    stimRelCorr(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 1) & ([EEG.event.Accuracy] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)  ));                   
    
    stimRelCorr_priorRel(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 1) & ([EEG.event.Accuracy] == 1) & ([EEG.event.PriorREL] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    stimRelCorr_priorUnrel(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 1) & ([EEG.event.Accuracy] == 1) & ([EEG.event.PriorREL] == 0) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    stimUnrelCorr_priorRel(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 0) & ([EEG.event.Accuracy] == 1) & ([EEG.event.PriorREL] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    stimUnrelCorr_priorUnrel(subject) = length(find(ismember({EEG.event.type}, stimMarkers) & ([EEG.event.Related] == 0) & ([EEG.event.Accuracy] == 1) & ([EEG.event.PriorREL] == 0) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));

    respRelErr(subject) = length(find(ismember({EEG.event.type}, respMarkers) & ([EEG.event.Related] == 1) & ([EEG.event.Accuracy] == 0) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    respUnrelErr(subject) = length(find(ismember({EEG.event.type}, respMarkers) & ([EEG.event.Related] == 0) & ([EEG.event.Accuracy] == 0) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    respRelCorr(subject) = length(find(ismember({EEG.event.type}, respMarkers) & ([EEG.event.Related] == 1) & ([EEG.event.Accuracy] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
    respUnrelCorr(subject) = length(find(ismember({EEG.event.type}, respMarkers) & ([EEG.event.Related] == 0) & ([EEG.event.Accuracy] == 1) & ([EEG.event.Responded] == 1) & ([EEG.event.ValidRT] == 1)));
end

% Create output report and write the report to disk
trialCountsReport = table(id', stimUnrelCorr', stimRelCorr', ...
    stimRelCorr_priorRel', stimRelCorr_priorUnrel', stimUnrelCorr_priorRel', stimUnrelCorr_priorUnrel', ...
    respRelErr', respUnrelErr', respRelCorr', respUnrelCorr');
trialCountsReport.Properties.VariableNames = {'id', 'stimUnrelCorr', 'stimRelCorr', ...
    'stimRelCorr_priorRel', 'stimRelCorr_priorUnrel', 'stimUnrelCorr_priorRel', 'stimUnrelCorr_priorUnrel', ...
    'respRelErr', 'respUnrelErr', 'respRelCorr', 'respUnrelCorr'};
trialCountsReport = sortrows(trialCountsReport);
writetable(trialCountsReport, ['n400_trialCounts_', datestr(now,'yyyymmdd'), '.csv']);

% Write report to Command Window to manually identify any participants who should not continue with plotting
trialCountsReport


%% SECTION 4: Create .mat File with ERP Data

% Following manual review of the trialCounts report, select subjects with adequate data for ERP plotting
subjects = [1:39];

% Create empty array for ERP data (participants x conditions x channels x sample points)
n400_erpDat = zeros(length(subjects), nbConditions, nbChannels, nbSamplePoints);

% Loop through each subject
pIdx = 1;
for i = subjects    
    % Load processed data
    EEG = pop_loadset('filename', [num2str(i), '_N400_ica_data_processed.set'], 'filepath', data_location);
    EEG = eeg_checkset(EEG);
    
    % Select only the epochs with valid responses
    EEG = pop_selectevent(EEG, 'Responded', 1, 'ValidRT', 1, 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
    EEG = eeg_checkset(EEG);

    % Loop through first set of conditions: Related v Unrelated with correct response
    condset1 = [{'stimUnrelCorr'}, {'stimRelCorr'}];
    cond = [1, 2];
    related = [0, 1];
    accuracy = [1, 1];
    for a = 1:length(condset1)
        EEG_n = pop_selectevent(EEG, 'type', stimMarkers, 'Related', related(a), 'Accuracy', accuracy(a), 'deleteevents','on','deleteepochs','on','invertepochs','off');
        EEG_n = eeg_checkset(EEG_n);

        % Average across the epoch dimension and store data in the array
        epochMeans = mean(EEG_n.data, 3);
        n400_erpDat(pIdx,cond(a),:,:)= epochMeans;
    end

    % Loop through second set of conditions: Related v Unrelated with correct response x whether prior trial was a Related or Unrelated pair
    condset2 = [{'stimRelCorr_priorRel'}, {'stimRelCorr_priorUnrel'}, {'stimUnrelCorr_priorRel'}, {'stimUnrelCorr_priorUnrel'}];
    cond = [3, 4, 5, 6];
    related = [1, 1, 0, 0];
    accuracy = [1, 1, 1, 1];
    priorrel = [1, 0, 1, 0];
    for b = 1:length(condset2)
        EEG_n = pop_selectevent(EEG, 'type', stimMarkers, 'Related', related(b), 'Accuracy', accuracy(b), 'PriorREL', priorrel(b), 'deleteevents', 'on', 'deleteepochs', 'on', 'invertepochs', 'off');
        EEG_n = eeg_checkset(EEG_n);

        % Average across the epoch dimension and store data in the array
        epochMeans = mean(EEG_n.data, 3);
        n400_erpDat(pIdx,cond(b),:,:)= epochMeans;
    end
    
    pIdx = pIdx + 1;
end

% Save data
output_name = ['n400_erpDat_', datestr(now,'yyyymmdd'), '.mat'];
save(output_name,'n400_erpDat', 'subjects')

%% SECTION 5: Correct Baseline

% Load the data of all subjects
data_date = '20220409';
load(['n400_erpDat_', data_date, '.mat'])
allData = n400_erpDat;

% Load in one of the participants' EEGLAB-formatted data for one subject to load parameters needed for plotting (sampling rate, chanlocs, etc).
EEG = pop_loadset('filename', datafile_names{1}, 'filepath', data_location);
EEG = eeg_checkset(EEG);

% Correct baseline
[startTimepoint,startIdx] = min(abs(EEG.times-baselineStartTime));
[stopTimepoint,stopIdx] = min(abs(EEG.times-baselineStopTime));

allBase = mean(allData(:,:,:,(startIdx:stopIdx)),4);

for i=1:size(allData,4)
    baselineCorrDat(:,:,:,i) = allData(:,:,:,i) - allBase;
end

%% SECTION 6: Plot ERPs

% Filter data down to specific channels to plot
baseCorrSpecChans = baselineCorrDat(:,:,chansToCluster,:);
baseCorrSpecChans = mean(baseCorrSpecChans,3);

% Create variables with data for conditions of interest
stimUnrelCorrDat = baseCorrSpecChans(:,1,:,:);
stimRelCorrDat = baseCorrSpecChans(:,2,:,:);
UnrelMinusRelDat = stimUnrelCorrDat - stimRelCorrDat;

% Average across participants and reduce to one-dimensional vector
stimUnrelCorrDatAvg = squeeze(mean(stimUnrelCorrDat,1));
stimRelCorrDatAvg = squeeze(mean(stimRelCorrDat,1));
UnrelMinusRelAvg = stimUnrelCorrDatAvg - stimRelCorrDatAvg;

% Round EEG.times for x-axis
EEG.times = round(EEG.times);

% Plot individual delta ERPs against grand average
t = tiledlayout(5, 8, 'TileSpacing', 'Compact');
for i = subjects
    nexttile
    plot(EEG.times, squeeze(UnrelMinusRelDat(i,:,:,:)), 'color', grey, 'LineWidth', 1.5)
    hold on
    plot(EEG.times, UnrelMinusRelAvg, 'color', black, 'LineWidth', 1.5);
    title(strcat('Sub ', num2str(subjects(i))))
    xlim([erpPlotStartTime erpPlotEndTime])
    ylim([-4 4])
    hold off
end
title(t, {'N400 from ERP CORE', 'Individual ERPs: Unrelated Minus Related', ''}, 'FontSize', 16)
xlabel(t, 'Time Relative to Stimulus (ms)')
ylabel(t, 'Amplitude in  \muV')
leg = legend('Individual Participant', 'Grand Average (same across plots)');
leg.Layout.Tile = 'north';
set(gcf, 'Position', [0 0 2000 1500]);
print(['n400_erpAll_', datestr(now,'yyyymmdd')], '-djpeg95', '-r300')

% Plot grand average related, unrelated, and delta (against delta of each participant)
figure;
hold on
for i = subjects
    plot(EEG.times, squeeze(UnrelMinusRelDat(i,:,:,:)), 'color', lightGrey, 'LineWidth', 1.5);
end
plot(EEG.times, stimUnrelCorrDatAvg, 'color', purple, 'LineWidth', 1.5);
plot(EEG.times, stimRelCorrDatAvg, 'color', green, 'LineWidth', 1.5);
plot(EEG.times, UnrelMinusRelAvg, 'color', black, 'LineWidth', 2);
xline(0)
title(sprintf('N400 from ERP CORE: Grand Averages'), 'FontSize', 25);
hold off;
set(gcf, 'Color', [1 1 1], 'Position', [0 400 600 400]);
set(gca, 'Box', 'off', 'FontSize', 12);
set(gca, 'YLim', [-4 8]);
set(gca, 'XLim', [erpPlotStartTime erpPlotEndTime]);
set(get(gca, 'YLabel'), 'String', 'Amplitude in \muV', 'FontSize', 12);
set(get(gca, 'XLabel'), 'String', 'Time Relative to Stimulus (ms)', 'FontSize', 12);
p=get(gca, 'Children');
legend([p(4), p(3), p(2)],'Unrelated Condition','Related Condition', 'Unrelated Minus Related');

print(['n400_erpAvg_', datestr(now,'yyyymmdd')], '-djpeg95', '-r300')

%% SECTION 7: Plot Topos

% Calculate time range for component of interest
[compStartTimepoint,compStartIdx] = min(abs(EEG.times-compStartTime));
[compEndTimepoint,compEndIdx] = min(abs(EEG.times-compEndTime));

compRange = compStartIdx:compEndIdx;

% Create variables with data filtered for conditions of interest and time range for component of interest
stimUnrelCorrSpecCompDat = baselineCorrDat(:,1,:,compRange);
stimRelCorrSpecCompDat = baselineCorrDat(:,2,:,compRange);

% Average over time range for component of interest
stimUnrelCorrSpecCompDatTimeAvg = mean(stimUnrelCorrSpecCompDat,4);
stimRelCorrSpecCompDatTimeAvg = mean(stimRelCorrSpecCompDat,4);
UnrelMinusRelCorrSpecCompDatTimeAvg = squeeze(stimUnrelCorrSpecCompDatTimeAvg - stimRelCorrSpecCompDatTimeAvg);

% Average across participants and reduce to one-dimensional vector
stimUnrelCorrSpecCompDatTimeSubAvg = squeeze(mean(stimUnrelCorrSpecCompDatTimeAvg,1));
stimRelCorrSpecCompDatTimeSubAvg = squeeze(mean(stimRelCorrSpecCompDatTimeAvg,1));

% Compute delta between conditions
TopoUnrelMinusRel = stimUnrelCorrSpecCompDatTimeSubAvg - stimRelCorrSpecCompDatTimeSubAvg;

% Plot topographical maps for cross-participant averages
figure
subplot(1,3,1)
topoplot(stimUnrelCorrSpecCompDatTimeSubAvg, EEG.chanlocs, 'maplimits', [-6 6], 'electrodes', 'on', 'gridscale', 300)
title('Unrelated Condition', 'Position', [0, -0.65, 1])

subplot(1,3,2)
topoplot(stimRelCorrSpecCompDatTimeSubAvg, EEG.chanlocs, 'maplimits', [-6 6], 'electrodes', 'on', 'gridscale', 300)
title('Related Condition', 'Position', [0, -0.65, 1])

subplot(1,3,3)
topoplot(TopoUnrelMinusRel, EEG.chanlocs, 'maplimits', [-6 6], 'electrodes', 'on', 'gridscale', 300)
title('Unrelated Minus Related', 'Position', [0, -0.65, 1])
sgtitle('N400 from ERP CORE, Unrelated Minus Related, 250-500 ms');
set(gcf, 'Position', [0 500 600 200]);
print(['n400_topoAvg_', datestr(now,'yyyymmdd')], '-djpeg95', '-r300')

% Plot topographical maps for each participant
figure
for i = subjects
    dataToPlot = UnrelMinusRelCorrSpecCompDatTimeAvg(i,:);
    subplot(5,8,i)
    topoplot(dataToPlot, EEG.chanlocs, 'maplimits', [-6 6], 'electrodes', 'on', 'gridscale', 300)
    title(strcat('Sub ', num2str(subjects((i)))))
end
sgtitle({'N400 from ERP CORE, Unrelated Minus Related, 250-500 ms, Individual Topo Plots', ''})
set(gcf, 'Position', [0 0 2000 1500]);
print(['n400_topoAll_', datestr(now,'yyyymmdd')], '-djpeg95', '-r300')

%% SECTION 8: Extract Mean Component Amplitudes

% Calculate time range for component of interest
[compStartTimepoint,compStartIdx] = min(abs(EEG.times-compStartTime));
[compEndTimepoint,compEndIdx] = min(abs(EEG.times-compEndTime));

compRange = compStartIdx:compEndIdx;

% Create variables with data filtered for conditions of interest, plus channels and time range for component of interest
stimUnrelCorrSpecCompSpecChansSpecTimeDat = baselineCorrDat(:,1,chansToCluster,compRange);
stimRelCorrSpecCompSpecChansSpecTimeDat = baselineCorrDat(:,2,chansToCluster,compRange);

% Average over time range for component of interest
stimUnrelCorrSpecCompSpecChansTimeAvg = mean(stimUnrelCorrSpecCompSpecChansSpecTimeDat,4);
stimRelCorrSpecCompSpecChansTimeAvg = mean(stimRelCorrSpecCompSpecChansSpecTimeDat,4);

% Average over cluster of channels for component of interest
stimUnrelCorrSpecCompTimeAvgChansAvg = mean(stimUnrelCorrSpecCompSpecChansTimeAvg,3);
stimRelCorrSpecCompTimeAvgChansAvg = mean(stimRelCorrSpecCompSpecChansTimeAvg,3);

% Compute delta between conditions
amplitudesUnrelMinusRel = stimUnrelCorrSpecCompTimeAvgChansAvg - stimRelCorrSpecCompTimeAvgChansAvg;

% Create amplitudes report and write the report to disk
amplitudesReport = table(subjects', stimUnrelCorrSpecCompTimeAvgChansAvg, stimRelCorrSpecCompTimeAvgChansAvg, amplitudesUnrelMinusRel);
amplitudesReport.Properties.VariableNames = {'id', 'stimUnrelCorrSpecCompTimeAvgChansAvg', 'stimRelCorrSpecCompTimeAvgChansAvg', 'amplitudesUnrelMinusRel'};
amplitudesReport = sortrows(amplitudesReport);
writetable(amplitudesReport, ['n400_meanAmplitudes_', datestr(now,'yyyymmdd'), '.csv']);

% Write report to Command Window for visual inspection
amplitudesReport