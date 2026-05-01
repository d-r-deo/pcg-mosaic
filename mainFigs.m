%% mainFigs.m — Main figures for "A mosaic of whole-body representations on the human precentral gyrus"
%
% Reference:
%   Deo et al. (2026). A mosaic of whole-body representations on the
%   human precentral gyrus.
%
% Description:
%   Reproduces all main figures (Figures 1–5) reported in the paper.
%   Companion script: supplementalFigs.m (selected extended data figures).
%
% Workflow:
%   1. Load participant data and define analysis parameters.
%   2. Run core tuning analysis for each participant/array.
%   3. Generate Figures 1–5 from the resulting analysis outputs.
%
% Requirements:
%   - MATLAB R2025b or later.
%   - This repository, with all sub-folders on the MATLAB path
%     (the script calls `addpath(genpath('./'))`).
%   - Participant `.mat` files (downloaded separately from the data
%     repository) placed in `Data/`. See `Data/README.md` for the data
%     structure and `README.md` for setup instructions.
%
% Usage:
%   Set MATLAB's working directory to the top-level project folder
%   (the one containing this script), then run:
%       >> mainFigs
%   Outputs are written into `Data/MainFigs/`.
%
% Repository: https://github.com/d-r-deo/pcg-mosaic
%
% Author:  Darrel Deo
% Contact: ddeo@stanford.edu
% Last updated: 2026-04-27
%
warning('off', 'all');   % Suppress warnings
close all; clear all; clc;

%% ========== SETUP & PATHS ==========
AnalysisFolder = 'MainFigs';
data_dir = ['Data' filesep]; % location of data to analyze
save_dir = [data_dir AnalysisFolder filesep]; % top-level directory to store results

% Add current directory and subdirectories to path
addpath(genpath('./'));
colMap = 'viridis'; % set colormap to use for most heatmaps

%% ========== PARTICIPANT & ARRAY DEFINITIONS ==========
% Participant enumeration
datNames = {'T5','T12','T11','C1','C2', 'T15', 'T16', 'T17'};
[T5, T12, T11, C1, C2, T15, T16, T17] = deal(1, 2, 3, 4, 5, 6, 7, 8);

% Array definitions per participant
pDat = cell(numel(datNames), 1);
pDat{T5}.arrays =  {'T5-d1',  'T5-d2'};
pDat{T12}.arrays = {'T12-v1', 'T12-v2'};
pDat{T11}.arrays = {'T11-d1'};
pDat{C1}.arrays =  {'C1-d1',  'C1-d2'};
pDat{C2}.arrays =  {'C2-d2'};
pDat{T15}.arrays = {'T15-m1', 'T15-v1', 'T15-v2', 'T15-v3'};
pDat{T16}.arrays = {'T16-m1', 'T16-v1', 'T16-d2', 'T16-d1'};
pDat{T17}.arrays = {'T17-v2', 'T17-v1', 'T17-d2', 'T17-d1'};

% Flatten array order for quick lookup
pDat_order = {};
for p = 1:numel(pDat)
    pDat_order = [pDat_order pDat{p}.arrays];
end

% Define spatial ordering for visualizations
reorderNames = {'C2-d2', 'C1-d1', 'C1-d2','T17-d1', 'T5-d1',  'T5-d2','T17-d2', 'T16-d1',...
                'T16-d2','T11-d1','T15-m1','T16-m1','T15-v1','T12-v1', 'T15-v2', 'T17-v1',...
                'T12-v2', 'T15-v3', 'T17-v2','T16-v1'};

% Define movement set order for visualizations
reorderMoveSets = {'Speech', 'Face', 'Head', 'RightArm', 'RightLeg', 'LeftArm', 'LeftLeg'};

%% ========== ANALYSIS WINDOWS & MOVEMENT DEFINITIONS ==========
% Time windows (in 20ms bins) relative to trigger cue(s), matches order of arrays in pDat_order
cueName = 'GoCue'; % 'GoCue' or 'Delay' as trigger cue
goWindows = {   [15, 75-1], [15, 50-1], [15, 75-1], [15, 75-1], [15, 75-1], [15, 125-1], [15, 125-1], [15, 125-1]}; % whole go window after 300ms reaction time
delayWindows = {[-50, 0],   [-50 0],    [-50 0],    [-50, 0],   [-50, 0],   [-50, 0],    [-50, 0],    [-50, 0]};    % same delay window for each participant

% Movement condition codes (see README for full mapping)
movSetNames = {'DoNothing', 'Speech','Face','Head','LeftLeg','LeftArm','RightLeg','RightArm'};

% Define the movement sets corresponding to the set names above (note separate set for C1 to remove head noise conditions).
movSets_Regular = {[1], [42 43 44 45], [2 23 24 25 46], [3 4 5 6],...
                    [7 8 9 10 15 16 17 18], [11 12 13 14 19 20 21 22],...
                    [26 27 28 29 34 35 36 37], [30 31 32 33 38 39 40 41]};
movSets_C1 = {[1], [42 43 44 45], [2 23 24 25 46], [4 5],...
              [7 8 9 10 15 16 17 18], [11 12 13 14 19 20 21 22],...
              [26 27 28 29 34 35 36 37], [30 31 32 33 38 39 40 41]};

[~, moveSetsReorder_inds] = ismember(reorderMoveSets, movSetNames); % to be used to re-order movement sets for classification matrix 

% Arm movement conditions for laterality analysis
Rarm = [38 39 40 41 30 31 32 33]; % Down Left Right Up Raise-left Raise-right Close Open
Larm = [19 21 20 22 12 11 13 14]; % Down Right Left Up Raise-right Raise-left Close Open

% PCG spatial locations of arrays 
% Inf = inferior-most limit, IFS = inferior frontal sulcus landmark, SFS = superior frontal sulcus landmark, Sup = superior-most limit)
Inf = 1; IFS = 2; SFS = 3; Sup = 4; 
participantID = [C2 C1 C1 T17 T5 T5 T17 T16 T16 T11 T15 T16 T15 T12 T15 T17 T12 T15 T17 T16];
arrayLoc = [SFS+0.4 SFS+0.35 SFS+0.2 SFS-0.1 SFS+0.2 SFS+0.1 SFS-0.2 SFS+0.1 SFS SFS-0.1...
            SFS-0.5 SFS-0.6 IFS+0.2 IFS IFS-0.2 IFS-0.25 IFS-0.5 IFS-0.5 IFS-0.4 IFS-0.7];

% Array groupings by PCG region
DorsalSet = {'T5-d1', 'T5-d2', 'T11-d1', 'C1-d1', 'C1-d2', 'C2-d2', 'T16-d2', 'T16-d1', 'T17-d2', 'T17-d1'};
MiddleSet = {'T15-m1', 'T16-m1'};
VentralSupSet = {'T15-v1', 'T12-v1', 'T17-v1'};
VentralInfSet = {'T15-v2', 'T15-v3', 'T12-v2', 'T16-v1', 'T17-v2'};

setInds = {find(ismember(pDat_order, DorsalSet)), ...
           find(ismember(pDat_order, MiddleSet)), ...
           find(ismember(pDat_order, VentralSupSet)), ...
           find(ismember(pDat_order, VentralInfSet))};

%% ========== FIGURE 1 PSTH SELECTION ==========
plotPSTHs_array = [T5 T12 T15 T16]; % participants to plot psths for
movSets_PSTH = {[42 46 4 10 13 27 32]};  % Selected movements for display

%% ========== CORE ANALYSIS LOOP: Process each participant/array ==========
fprintf('============ STARTING MAIN ANALYSIS LOOP ============\n');

for d = 1:numel(datNames) % iterate through each participant
    % Load data
    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;
    
    % Extract and normalize spike features
    tx = Dat.tx_blkMeanSub; % block-wise mean removed tx spike features
    msFeat_s = tx .* 50;  % Convert to seconds (20ms binned data)
    msFeat = (msFeat_s - nanmean(msFeat_s,1)) ./ nanstd(msFeat_s,1);  % Z-score
    
    % Remove NaN channels
    tmp = sum(isnan(msFeat),1);
    indsKeep = find(tmp ~= size(msFeat,1));
    
    % Setup save directory
    saveDir = [save_dir datNames{d}];
    mkdir(saveDir);
    
    % Initialize analysis structure
    sDat = struct();
    sDat.movementCodes = Dat.trialCue; % extract the movement cue per trial
    sDat.movementNames = Dat.cueList;  % extract the master cue list as a struct of strings
    sDat.movementSets = {movSets_Regular{2:end}}; % trim off the Do Nothing condition when defining movement sets
    sDat.movementSetNames = {movSetNames{2:end}}; % trim off the Do Nothing set
    sDat.doNothingCode = 1; % define the 'Do Nothing' cue number, which is 1
    
    % TOGGLE FLAGS (modify to enable/disable analyses)
    sDat.plotPSTHs = false; % will plot PSTHs for all movement sets
    sDat.fullDistanceMatrix = true; % will compute the euclidean distances between each pair of movement conditions
    sDat.withinGroupCorrelation = true; % will compute the correlations between each pair of movement conditions
    sDat.plotBarPlots = true; % will compute the modulation strength for each movement condition
    sDat.classifyAll = true; % will perform x-val naive bayes classification
    sDat.perform_mPCA = true;  % Laterality analysis
    
    % Define parameters
    sDat.goTimes = Dat.goCue; % define the time points upon which to trigger analyses
    sDat.plottingWindow = [-100, 150]; % time window relative to each go cue to plot for PSTHs
    sDat.binWidth = 0.02; % bin width in seconds for the data (20ms binned data)
    sDat.mPCA_smoothWidth = 4; % standard deviation (in samples) of the Gaussian smoothing kernel
    sDat.latMoveSet = [Rarm; Larm]; % set of movements for laterality analysis
    sDat.latMoveName = 'Arms'; % laterality analysis name
    
    % Iterate through trigger cues

    if strcmp(cueName, 'GoCue') % perform analyses relative to go cues
        sDat.analysisWindow = goWindows{d};
    else                                   % perform analyses relative to delay cues
        sDat.analysisWindow = delayWindows{d};
    end

    % Iterate through arrays
    for chanSetIdx = 1:numel(Dat.chanSets)
        % Skip arrays not in analysis list
        if ~ismember(Dat.chanSetNames{chanSetIdx}, pDat_order)
            continue;
        end

        fprintf('Processing: %s - %s (%s)\n', datNames{d}, Dat.chanSetNames{chanSetIdx}, cueName);

        % Extract channels for this array
        channels = Dat.chanSets{chanSetIdx};
        channels = channels(ismember(channels,indsKeep));

        % Run analysis
        sDat.chanSets = Dat.chanSets{chanSetIdx};
        sDat.saveDir = [saveDir filesep Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName];
        sDat.features = msFeat(:, channels);

        tuningAnalyses(sDat);  % Main analysis function
    end
    pause(1); close all; pause(1);
    
    % Plot PSTHs for selected participants
    if ismember(d, plotPSTHs_array)
        sDat_psth = sDat;
        sDat_psth.saveDir = [saveDir filesep 'PSTHs'];
        sDat_psth.analysisWindow = goWindows{d};
        sDat_psth.movementSets = movSets_PSTH;
        sDat_psth.movementSetNames = {'WholeBody'};
        sDat_psth.features = Dat.tx.* 50; % raw binned spikes
        plotPSTHs(sDat_psth);
    end
end

fprintf('============ ANALYSIS LOOP COMPLETE ============\n');

%% ========== FIGURE GENERATION: Load pre-computed results and visualize ==========

%% FIGURE 1c: PSTHs
fprintf('\n\n*******************************************************************************\n');
fprintf('                                   FIGURE 1\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Figure 1c - PSTHs\n');

T5_psth_loc = [save_dir 'T5' filesep 'PSTHs' filesep 'psth_WholeBody' filesep 'psth_3_WholeBody.fig'];
T15_psth_loc = [save_dir 'T15' filesep 'PSTHs' filesep 'psth_WholeBody' filesep 'psth_4_WholeBody.fig'];
T12_psth_loc = [save_dir 'T12' filesep 'PSTHs' filesep 'psth_WholeBody' filesep 'psth_1_WholeBody.fig'];
T16_psth_loc = [save_dir 'T16' filesep 'PSTHs' filesep 'psth_WholeBody' filesep 'psth_2_WholeBody.fig'];

% Open the source .fig files
fig1 = openfig(T5_psth_loc);
fig2 = openfig(T15_psth_loc);
fig3 = openfig(T12_psth_loc);
fig4 = openfig(T16_psth_loc);

% Open the source .fig files
fig_specs = struct('fig_handle', {fig1, fig2, fig3, fig4}, ...
                    'electrode_idx', {25, 45, 47, 61});

fig1 = figure('Name', 'Figure 1c - PSTHs', 'Position',[2 546 1679 302]); % create a new figure

for p = 1: numel(fig_specs)
    subplot(1,4,p);  
    axesHandles = flip(findall(fig_specs(p).fig_handle, 'Type', 'axes'));  
    sourceAx = axesHandles(fig_specs(p).electrode_idx);
    newAx = copyobj(sourceAx, fig1);
    subplotPos = get(gca, 'Position');
    set(newAx, 'Position', subplotPos);
    delete(gca);
end

% save Figure 1
figure(fig1);
saveDir = [save_dir 'Fig1' filesep];
mkdir(saveDir);
saveName =  [saveDir 'Fig1c_PSTHs'];
exportPNGFigure(gcf, saveName);

%% FIGURE 2a: Tuning Strength Heatmap
fprintf('\n\n*******************************************************************************\n');
fprintf('                                   FIGURE 2\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Figure 2a - Tuning Strength Heatmap\n');

ModMagHeatMap = []; % initialize matrix to hold results
ModMagHeatMap_Labels = {};

% Accumulate modulation strength across all arrays
for p = 1:numel(pDat)
    for d = 1:numel(pDat{p}.arrays)
        % load current array's modulation strength matrix
        cDat = load([save_dir datNames{p} filesep pDat{p}.arrays{d} ...
                    'Tuning_' cueName filesep 'modMag_sorted.mat']);
        means = cDat.modMag_sorted(:,1)'; % extract 1xM vector of avg. mod strength for each individual movement condition 
        non_sig = (cDat.modMag_sorted(:,2) < 0)'; % any lower CI bound below 0 is non-significant
        means(non_sig) = NaN;
        
        % Special handling for C1 (head noise)
        if p == C1
            means([10 13]) = NaN;
        end
        
        % stack the modulation array
        ModMagHeatMap = [ModMagHeatMap; means];
        ModMagHeatMap_Labels = [ModMagHeatMap_Labels pDat{p}.arrays{d}];
        moveNames = cDat.movLabels_sorted;
    end
end

% Normalize rows and resort array order
ModMagHeatMap_RowWiseNorm = ModMagHeatMap ./ max(ModMagHeatMap')';
resortedInds = sort_by_reference(ModMagHeatMap_Labels, reorderNames);
vals = ModMagHeatMap_RowWiseNorm(resortedInds, :);
array_labels = ModMagHeatMap_Labels(resortedInds);

% Resort movements by category
Speech = 1:4; Orofacial = 5:9; Head = 10:13;
LeftLeg = 14:21; RightLeg = 30:37; LeftArm = 22:29; RightArm = 38:45;
movementInds_resorted = [Speech Orofacial Head RightArm RightLeg LeftArm LeftLeg];
vals = vals(:, movementInds_resorted);
labels = moveNames(movementInds_resorted);

% Plot
figure('Name','Figure 2a','Units','pixels','Position',[2 520 1422 450]);
imagesc(vals, [0 1]); colormap(colMap); colorbar;
yticks(1:numel(array_labels)); yticklabels(array_labels);
xticks(1:numel(labels)); xticklabels(labels);
title('Normalized Modulation Strength'); set(gca,'FontSize',12);

% Mark non-significant cells
for i = 1:size(vals,1)
    for j = 1:size(vals,2)
        if isnan(vals(i,j))
            text(j,i,'X','Color',[1 1 1],'FontSize',12,'HorizontalAlignment','center');
        end
    end
end

% Save figure
saveDir = [save_dir 'Fig2' filesep];
mkdir(saveDir);
exportPNGFigure(gcf, [saveDir 'Fig2a_TuningStrength_Heatmap']);

%% FIGURE 2b: PCG Layout with Set-Wise Modulation
fprintf('Generating Figure 2b - PCG Layout\n');

% Load pre-computed set-wise modulation data
dataName = ['ModMag_' cueName '.mat'];
datLoc = [save_dir 'TuningStrength' filesep dataName];

% Define movement indices for set-wise extraction
movInds_reg = {[1:4], [5:9], [10:13], [14:21], [22:29], [30:37], [38:45]};
movInds_C1 = {[1:4], [5:9], [11:12], [14:21], [22:29], [30:37], [38:45]};

% Compile set-wise modulation strengths across all participants and arrays
for p = 1:numel(pDat)
    arrays = pDat{p}.arrays;
    meanArray = [];
    for d = 1:numel(arrays)
        cDat = load([save_dir datNames{p} filesep arrays{d} 'Tuning_' cueName filesep 'modMag_sorted.mat']);
        means = cDat.modMag_sorted(:,1)';

        means_tmp = zeros(1, numel(movInds_reg));
        for movSet_idx = 1:numel(movInds_reg)
            inds = movInds_reg{movSet_idx};
            if p == C1
                inds = movInds_C1{movSet_idx};
            end
            means_tmp(movSet_idx) = nanmean(means(inds));
        end
        meanArray = [meanArray; means_tmp];
    end
    pDat{p}.ModMag.(cueName) = meanArray;
end

% Stack in order of array location to match PCG layout
stackedMean = [];
stackedMean_labels = {};
for p = 1:numel(pDat)
    stackedMean = [stackedMean; pDat{p}.ModMag.(cueName)];
    stackedMean_labels = [stackedMean_labels pDat{p}.arrays];
end

% Re-shuffle array indices to match spatial PCG ordering
currOrder = stackedMean_labels;
resortedInds = [];
for itor = 1:numel(reorderNames)
    resortedInds = [resortedInds find(strcmp(currOrder, reorderNames{itor}) == 1)];
end

vals = stackedMean(resortedInds, :);
array = stackedMean_labels(resortedInds);
colLabels = {'Speech','Face','Head','LeftLeg','LeftArm','RightLeg','RightArm'};

% Resort columns to display order: arms and legs grouped together
col_resort = [];
for itor = 1:numel(reorderMoveSets)
    col_resort = [col_resort find(strcmp(colLabels, reorderMoveSets{itor}) == 1)];
end
vals = vals(:, col_resort);
movSet = colLabels(col_resort);

% Normalize each row by its maximum
vals = vals ./ max(vals')';

% Save ModMag data for later use (e.g., Figure 4)
tuningStrengthDir = [save_dir 'TuningStrength' filesep];
mkdir(tuningStrengthDir);
DatMat = [];
DatMat.vals_normalized = vals;
DatMat.xlabels = movSet;
DatMat.ylabels = array;
save([tuningStrengthDir 'ModMag_' cueName], 'DatMat');

% Plot on PCG layout
figure('Name','Figure 2b - PCG Layout','Position',[5 373 1127 655]);
for m = 1:numel(movSet)
    subplot(1, numel(movSet), m);
    currVals = vals(:, m);
    scatter(participantID, arrayLoc, 400, currVals, 'filled', 'square');
    title(movSet{m}); ylim([1 4]); clim([0 1]);
    if m == 1
        yticks(1:4); yticklabels({'Inferior', 'IFS', 'SFS', 'Superior'});
        ylabel('Precentral gyrus');
    else
        yticks(1:4); yticklabels({});
    end
    xticks(1:numel(datNames)); xticklabels(datNames);
    set(gca,'FontSize',7); set(gca,'color','none'); grid on; colormap(colMap);
end
exportPNGFigure(gcf, [save_dir 'Fig2' filesep 'Fig2b_PCGLayout_' cueName]);

%% FIGURE 3a [Alternative]: Naive Bayes Decoding 
fprintf('\n\n*******************************************************************************\n');
fprintf('                                   FIGURE 3\n');
fprintf('*******************************************************************************\n\n');

% Please note that the figure in the manuscript was generated using an
% RNN in Python. A simplified Naive Bayes classifier was used for this section
fprintf('Generating Figure 3a Alternative - Naive Bayes Decoding Accuracy\n');

saveLoc = [save_dir 'Fig3' filesep];
mkdir(saveLoc);

Accuracy = [];
sig = [];

% Accumulate per-array decoding accuracies
for a = 1:numel(reorderNames)
    currParticipant = strtok(reorderNames{a}, '-');
    Cmat = load([save_dir currParticipant filesep reorderNames{a} 'Tuning_' cueName filesep 'ClassificationMatrix.mat']);
    Cmat_subsets = load([save_dir currParticipant filesep reorderNames{a} 'Tuning_' cueName filesep 'ClassificationMatrix_Subsets.mat']);
    Cmat_subsets = Cmat_subsets.SubsetClassification;
    
    % Stack overall + per-movement-set accuracies
    currAcc = Cmat.decodingAccuracy;
    binoCI = Cmat.binoCI;
    chanceLevel = 1 / size(Cmat.classMat, 1);
    
    for subset = 1:numel(Cmat_subsets)
        binoCI = [binoCI; Cmat_subsets{subset}.binoCI];
        chanceLevel = [chanceLevel; 1 / numel(Cmat_subsets{subset}.moveSet)];
        currAcc = [currAcc Cmat_subsets{subset}.decodingAccuracy];
    end
    
    % Check significance
    currSig = (binoCI(:,1) > chanceLevel)';
    sig = [sig; currSig];
    Accuracy = [Accuracy; currAcc];
end

% Prepend chance level row
Accuracy = [chanceLevel'; Accuracy];
sig = [ones(numel(chanceLevel), 1)'; sig];
arrayLabels = ['Chance'; reorderNames'];

% Resort movement labels by category
movLabels = {'All'};
for i = 1:numel(Cmat_subsets)
    movLabels = [movLabels; Cmat_subsets{i}.moveSetName];
end
if exist('lbls', 'var'), movLabels = lbls; end

% Plot accuracy matrix
figure('Name', 'Figure 3a - Naive Bayes', 'Position',[560 528 560 420]);
imagesc(Accuracy, [0.2 1]); colormap(colMap); colorbar;
xticks(1:size(Accuracy,2)); xticklabels(movLabels);
yticks(1:size(Accuracy,1)); yticklabels(arrayLabels);
title(sprintf('Naive Bayes Decoding - %s', cueName)); set(gca,'FontSize',12);
% plot text in cells
[R,C] = ndgrid(1:size(Accuracy,1), 1:size(Accuracy,2));
text(C(:)'-0.25, R(:)', string(round(Accuracy(:),2)),'FontSize',12,'Color',[1 1 1]);

% Mark non-significant cells
for i = 1:size(sig,1)
    for j = 1:size(sig,2)
        if sig(i,j) == 0
            text(j, i, 'X', 'Color',[1 0 0], 'FontSize',10, 'HorizontalAlignment','right');
        end
    end
end
exportPNGFigure(gcf, [saveLoc 'Fig3a_NaiveBayes_' cueName]);

%% FIGURE 3a [Manuscript]: Decoding Accuracy (RNN)
fprintf('Generating Figure 3a - RNN Decoding Accuracy\n');

saveLoc = [save_dir 'Fig3' filesep];
mkdir(saveLoc);

rnn = createRnnClassificationAccuracyMat_fromPaper(); % hardcoded from actual paper results
Accuracy = [rnn.chanceLevels ; rnn.classificationAccuracy];

figure('Name', 'Figure 3a - RNN', 'Position',[560 528 560 420]);
imagesc(Accuracy); colormap(colMap); clim([0.2 1]);
xticks(1:numel(rnn.movementSetLabels)); xticklabels(rnn.movementSetLabels);
yticks(1:size(Accuracy,1));
yticklabels(['Chance'; cellstr(rnn.arrayOrder)]);
title('RNN Decoding Accuracy'); colorbar;
[R,C] = ndgrid(1:size(Accuracy,1), 1:size(Accuracy,2)); % plot text in cells
text(C(:)'-0.25, R(:)', string(round(Accuracy(:),2)),'FontSize',12,'Color',[1 1 1]);
exportPNGFigure(gcf, [saveLoc 'Fig3a_RNN_' cueName]);

%% FIGURE 3b [Alternative]: Naive Bayes Classifier
% Please note that the figure in the manuscript was generated using an
% RNN in Python. A simplified Naive Bayes classifier was used for this section
fprintf('Generating Figure 3b Alternative - Naive Bayes T12 Confusion Matrix \n');

saveLoc = [save_dir 'Fig3' filesep];
mkdir(saveLoc);

T12_v1_dir = [save_dir 'T12' filesep 'T12-v1Tuning_GoCue' filesep 'allMovementsClassification.fig'];
openfig(T12_v1_dir);
axis square;
set(gca, 'FontSize', 8);

% save into Figure 3 folder
exportPNGFigure(gcf, [saveLoc 'Fig3b_NaiveBayes_ConfMat' cueName]);

%% FIGURE 4a: PCA of Modulation + RNN Accuracies
fprintf('\n\n*******************************************************************************\n');
fprintf('                                   FIGURE 4\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Figure 4a - PCA Analysis\n');

saveLoc = [save_dir 'Fig4' filesep];
mkdir(saveLoc);
addpath(genpath('./'));

% Load modulation strengths and RNN decoding accuracies
modDat = load([save_dir 'TuningStrength' filesep 'ModMag_' cueName '.mat']);
rnn = createRnnClassificationAccuracyMat_fromPaper(); % hardcoded from actual paper results

% Stack features
vals = [modDat.DatMat.vals_normalized, rnn.classificationAccuracy(:,2:end)];
arrayNames = modDat.DatMat.ylabels;

% Run PCA
[COEFF, SCORES, LATENT, ~, EXPLAINED] = pca(vals);
arrSets = {1:10,11:12,13:20};

% Plot PCA projections
figure('Name', 'Figure 4a - PCA', 'Position', [2 276 865 752]);
hold on;
colList = [];
for x=1:size(SCORES,1)
    if ismember(x,arrSets{1})
        cIdx = 1;
    elseif ismember(x,arrSets{2})
        cIdx = 2;
    else
        cIdx = 3;
    end

    uv = SCORES(x,1:2);

    rotAngle = 0;
    rotMat = [[cosd(rotAngle); sind(rotAngle);],[cosd(rotAngle+90); sind(rotAngle+90)]];
    uv = rotMat*uv';

    radius = sqrt(sum(uv.^2));
    angle = (atan2(uv(2), uv(1))+pi)/(2*pi);
    radius = radius * 1;
    radius(radius>1)=1;
    thisColor = hsv2rgb(angle, radius, 0.85);
    colList = [colList; squeeze(thisColor)'];

    plot(SCORES(x,1),SCORES(x,2),'o','MarkerFaceColor',thisColor,'Color',thisColor);
    text(SCORES(x,1),SCORES(x,2)+0.025,arrayNames{x},'Color',thisColor);
end
    
xlabel('PC1');
ylabel('PC2');

axis equal;
xlim([-1.2,1.2]);
ylim([-1,1]);

plot(get(gca,'XLim'),[0,0],'--k');
plot([0,0],get(gca,'YLim'),'--k');

exportPNGFigure(gcf, [saveLoc 'Fig4a_PCA_' cueName]);

% Create the color legend
% create grid of PC1 / PC2 values
N = 201; % resolution of the square
[PC1, PC2] = meshgrid(linspace(-1,1,N));

% apply same rotation and color mapping
uv = [PC1(:) PC2(:)].';
rotMat = [[cosd(rotAngle);     sind(rotAngle)], ...
    [cosd(rotAngle+90);  sind(rotAngle+90)]];
uv = rotMat * uv;

radius = sqrt(sum(uv.^2,1));
angle  = (atan2(uv(2,:), uv(1,:)) + pi) / (2*pi);   % 0..1
radius(radius>1) = 1;                               % clamp to 1

HSV = [angle(:) radius(:) 0.85*ones(numel(angle),1)];
RGB = hsv2rgb(HSV);

% reshape back to image
R = reshape(RGB(:,1), N, N);
G = reshape(RGB(:,2), N, N);
B = reshape(RGB(:,3), N, N);
legendImg = cat(3,R,G,B);

% show legend
figure('Name','PCA color legend', 'Position', [2 854 234 174]);
image(linspace(-1,1,N), linspace(-1,1,N), legendImg);
set(gca,'YDir','normal');
axis square tight;
xlabel('PC1'); ylabel('PC2');
exportPNGFigure(gcf, [saveLoc 'Fig4a_PCA_Legend']);


%% FIGURE 4b: PCA Coefficients
fprintf('Generating Figure 4b - PCA Coefficients\n');

cueSetNames = {'Speech','Face','Head','RArm','RLeg','LArm','LLeg',...
               'Speech','Face','Head','RArm','RLeg','LArm','LLeg'};

figure('Name', 'Figure 4b - PCA Coefficients', 'Position', [2 674 866 354]);
hold on;
% Plot modulation strength coefficients (solid)
plot(COEFF(1:7,1), '-o', 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
plot(COEFF(1:7,2), '-o', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
% Plot RNN accuracy coefficients (dashed)
plot(COEFF(8:end,1), '--o', 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
plot(COEFF(8:end,2), '--o', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
plot(get(gca,'XLim'), [0 0], '--k');
set(gca, 'XTick', 1:14, 'XTickLabel', cueSetNames, 'XTickLabelRotation', 45);
legend({'PC1','PC2'}); ylabel('Coefficient');
exportPNGFigure(gcf, [saveLoc 'Fig4b_PCA_Coefficients_' cueName]);

%% FIGURE 4c: PCA on PCG Layout
fprintf('Generating Figure 4c - PCA PCG Layout\n');

figure('Name','Figure 4c - PCA PCG layout','Position',[1 1 272 1005]);
scatter(participantID, arrayLoc, 400, colList, 'filled','square');
yticks(1:4); yticklabels({'Inferior', 'IFS', 'SFS', 'Superior'});
ylabel('Precentral gyrus');
xticks(1:numel(datNames)); xticklabels(datNames);
set(gca,'FontSize',12); set(gca,'color','none'); grid on;

exportPNGFigure(gcf, [saveLoc 'Fig4c_PCA_PCGLayout_' cueName]);

%% FIGURE 5a: Group-Averaged Correlation Matrices
fprintf('\n\n*******************************************************************************\n');
fprintf('                                   FIGURE 5\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Figure 5a - Group-Averaged Correlations\n');
saveLoc = [save_dir 'Fig5' filesep];
mkdir(saveLoc);

% Define movement condition sets for each limb pair
Corr_resortedInds = {[38:45 22:29], [30:37 14:21], [38:45 34:37 30:33], [22:29 18:21 14:17]};
Corr_resortedNames = {'R-L-Arms', 'R-L-Legs', 'R-Arm-Leg', 'L-Arm-Leg'};

% Reordering indices for homologous movements
subCorrMat_resortInds = {[1:8; 2 1 3 4 5 7 6 8], [1:8; 1 3 2 4 6 5 7 8], [1:8; 1:8], [1:8; 1:8]};

shuff = {};
stacked_diag_meanCorrs = [];
stacked_arrayIDs = {};
corrStack = zeros(46, 46, 20);
sigArray = zeros(20, 4);
itor = 1;

% Iterate through each dataset
for d = 1:numel(datNames)
    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;
    
    % Iterate through each array for the current participant
    for chanSetIdx = 1:numel(Dat.chanSets)
        if ~ismember(Dat.chanSetNames{chanSetIdx}, pDat_order)
            continue;
        end
        
        % Load full correlation matrix
        c = load([save_dir datNames{d} '/' Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName filesep 'Correlation.mat']);
        corrStack(:,:,itor) = c.corrMat;
        
        % Process each limb pair
        corr_data = {};
        mean_diag_vals = [];
        mean_offdiag_vals = [];
        
        for sub_corr = 1:numel(Corr_resortedInds)
            subset = Corr_resortedInds{sub_corr};
            cMat = c.corrMat(subset, subset);
            
            % Extract off-diagonal sub-matrix
            indsTake_Y = ((length(subset)/2)+1):length(subset);
            indsTake_X = 1:(length(subset)/2);
            subMat = cMat(indsTake_X, indsTake_Y);
            
            % Reorder for laterality alignment
            currReorderInds_X = subCorrMat_resortInds{sub_corr}(1,:);
            currReorderInds_Y = subCorrMat_resortInds{sub_corr}(2,:);
            subMat_reorder = subMat(currReorderInds_X, currReorderInds_Y);
            
            % Store correlation data
            corr_data{sub_corr,1} = diag(subMat_reorder);
            corr_data{sub_corr,3} = subMat_reorder;
            
            % Calculate mean values
            mean_diag_vals(sub_corr) = mean(corr_data{sub_corr,1});
            off_diag_mask = ones(size(subMat_reorder));
            for m = 1:length(subMat_reorder)
                off_diag_mask(m,m) = 0;
            end
            corr_data{sub_corr,2} = subMat_reorder(find(off_diag_mask == 1));
            mean_offdiag_vals(sub_corr) = mean(corr_data{sub_corr,2});
            
            % Shuffle test for significance
            [n,m] = size(subMat_reorder);
            shuffSamples = zeros(1,10000);
            for nrand = 1:10000
                shuffMat = subMat_reorder(randperm(n), randperm(m));
                shuffSamples(nrand) = mean(diag(shuffMat));
            end
            stdInt = [prctile(shuffSamples,2.5) prctile(shuffSamples,97.5)];
            testVal = mean_diag_vals(sub_corr);
            sigArray(itor, sub_corr) = (testVal < stdInt(1)) || (stdInt(2) < testVal);
            stacked_diag_meanCorrs(itor, sub_corr) = testVal;
        end
        
        stacked_arrayIDs{itor} = Dat.chanSetNames{chanSetIdx};
        save([save_dir datNames{d} '/' Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName filesep 'SubCorrelations'], 'corr_data', 'mean_diag_vals', 'mean_offdiag_vals', 'Corr_resortedNames');
        itor = itor + 1;
    end
end

% Reorder by array location
currOrder = stacked_arrayIDs;
resortedInds = [];
for itor = 1:numel(reorderNames)
    resortedInds = [resortedInds find(strcmp(currOrder, reorderNames{itor}) == 1)];
end

vals = stacked_diag_meanCorrs(resortedInds, :);
labels = {stacked_arrayIDs{resortedInds}};
sigs = sigArray(resortedInds, :);

% Plot representational similarity summary
figure('Name','Fig5b - Summary of Representational Similarity', 'Position',[1 65 1728 963]);
[R,C] = ndgrid(1:size(sigs,1), 1:size(sigs,2));
sig_vals = sigs(:);
ind_NotSig = find(sig_vals == 0);
imagesc(vals, [-1 1]);
colormap(flipud(redblue));
colorbar;
yticks(1:numel(labels)); yticklabels(labels); set(gca, 'FontSize', 18);
xticks(1:4); xticklabels(Corr_resortedNames); xtickangle(45);
text(C(ind_NotSig), R(ind_NotSig), 'X', 'FontSize', 16);
axis equal;
exportPNGFigure(gcf, [saveLoc 'Fig5b_RepresentationalSimilarity_' cueName]);

% Build set indices
setInds_corr = {find(ismember(stacked_arrayIDs, DorsalSet)), ...
                find(ismember(stacked_arrayIDs, MiddleSet)), ...
                find(ismember(stacked_arrayIDs, VentralSupSet)), ...
                find(ismember(stacked_arrayIDs, VentralInfSet))};

% Plot group-averaged correlation matrices
figure('Name','Fig5a - Avg. Correlations', 'Units','pixels', 'Position',[1 65 1728 963]);
setIndsToPlot = [1 3];
setNames = {'Dorsal PCG', 'Superior-Ventral PCG'};
plot_itor = 1;

for sets = 1:numel(setIndsToPlot)
    i = setIndsToPlot(sets);
    currMat = corrStack(:, :, setInds_corr{i});
    currMat(currMat < -1) = -1;
    currMat(currMat > 1) = 1;
    cMat = mean(currMat, 3);
    
    % Extract R Arm x Leg sub-matrix
    sub_corr = 3;
    subset = Corr_resortedInds{sub_corr};
    subplot(1, numel(setIndsToPlot), plot_itor);
    
    sMat = cMat(subset, subset);
    indsTake_Y = ((length(subset)/2)+1):length(subset);
    indsTake_X = 1:(length(subset)/2);
    subMat = sMat(indsTake_X, indsTake_Y);
    
    currReorderInds_X = subCorrMat_resortInds{sub_corr}(1,:);
    currReorderInds_Y = subCorrMat_resortInds{sub_corr}(2,:);
    subMat_reorder = subMat(currReorderInds_X, currReorderInds_Y);
    mvNames = c.mvNames(subset);
    lbl_x = {mvNames{currReorderInds_X}};
    lbl_y = {mvNames{currReorderInds_Y + numel(lbl_x)}};
    
    imagesc(subMat_reorder, [-1 1]);
    axis square;
    colormap(flipud(redblue));
    colorbar;
    set(gca, 'XTick', 1:length(lbl_y), 'XTickLabels', lbl_y, 'XTickLabelRotation', 45);
    set(gca, 'YTick', 1:length(lbl_x), 'YTickLabels', lbl_x);
    set(gca, 'YDir', 'normal');
    title(setNames{sets});
    
    plot_itor = plot_itor + 1;
end

exportPNGFigure(gcf, [saveLoc 'Fig5a_AvgCorrelations_' cueName]);


%% Figure 5c & 5d - Laterality Analysis and Marginalized Variance
fprintf('Generating Figure 5c/5d - Laterality Analysis\n');

latSetName = 'Arms';
plotScatter = {'T5-d2', 'C2-d2', 'T15-m1', 'T16-v1'};
Marginalized_variance = [];

scatter_projections = figure('Name','Fig5c - Single Trial Projections', 'Position',[1 65 1728 963]);

% Iterate through each array
for array = 1:numel(reorderNames)
    participant = strtok(reorderNames{array}, '-');
    
    % Load mPCA output for this array
    mPCA_out_dir = [save_dir participant filesep reorderNames{array} 'Tuning_' cueName filesep 'Laterality_' latSetName filesep 'mPCA_out.mat'];
    load(mPCA_out_dir);
    
    % Compute marginalized variance
    cmv = mPCA_out.explVar.totalMarginalizedVar;
    cmv = cmv ./ sum(cmv, 2);
    Marginalized_variance = [Marginalized_variance; cmv];
    
    % Plot for selected arrays
    if ismember(reorderNames{array}, plotScatter)
        % Extract and process features
        featVals = mPCA_out.featureVals;
        featVals_avgWind = squeeze(nanmean(featVals, 4));
        stackedFeats = [];
        trialfactor = [];
        
        for lat = 1:size(featVals_avgWind, 2)
            for mv = 1:size(featVals_avgWind, 3)
                currVals = squeeze(featVals_avgWind(:, lat, mv, :));
                currVals = zscore(currVals);
                stackedFeats = [stackedFeats currVals];
                trialfactor = [trialfactor repmat([lat; mv], 1, size(currVals, 2))];
            end
        end
        
        % PCA projection
        [COEFF, SCORE, latent, tsquared, explained, mu] = pca(stackedFeats');
        proj = stackedFeats' * COEFF;
        indsR = find(trialfactor(1,:) == 1);
        indsL = find(trialfactor(1,:) == 2);
        
        % Plot on scatter figure
        figure(scatter_projections);
        subplot(1, numel(plotScatter), find(strcmp(plotScatter, reorderNames{array}) == 1));
        hold on;
        scatter(proj(indsR,1), proj(indsR,2), 50, 'r', 'filled');
        scatter(proj(indsL,1), proj(indsL,2), 50, 'b', 'filled');
        legend('Right arm', 'Left arm');
        title(sprintf('%s', strrep([reorderNames{array} '-' latSetName], '_', '-')));
        axis([-10 10 -10 10]);
        axis square;
    end
end

figure(scatter_projections);
exportPNGFigure(gcf, [saveLoc 'Fig5c_PCA_Projections_' cueName]);

% Plot marginalized variances
figure('Name', 'Fig5d - Marginalized Variance from mPCA', 'Position',[1 258 339 769]);
imagesc(Marginalized_variance, [0 0.75]);
colormap(colMap);
colorbar;
yticks(1:numel(reorderNames)); yticklabels(reorderNames); set(gca, 'FontSize', 16);
xticks(1:4); xticklabels({'Laterality', 'Movement', 'L x M', 'Time'});
title('Marginalized Variance');
exportPNGFigure(gcf, [saveLoc 'Fig5d_MargVar_' cueName]);

fprintf('============ ALL FIGURES COMPLETE ============\n');