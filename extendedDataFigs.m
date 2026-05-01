%% extendedDataFigs.m — Extended data figures for "A mosaic of whole-body representations on the human precentral gyrus"
%
% Reference:
%   Deo et al. (2026). A mosaic of whole-body representations on the
%   human precentral gyrus.
%
% Description:
%   Reproduces selected extended data figures (Ext. Data Figures 1-3, 7-10) reported in the paper.
%   Companion script: mainFigs.m (main data figures; must be run first).
%
% Workflow:
%   1. Load participant data and define analysis parameters.
%   2. Run analysis for each participant/array.
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
%       >> extendedDataFigs
%   Outputs are written into `Data/ExtDataFigs/`.
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
AnalysisFolder = 'ExtDataFigs';
MainFigsAnalysisFolder = 'MainFigs'; % Point to the main figs analysis folder to pull pre-computed analyses from 

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

% to be used to merge all sub-movements into same movement category
movSets_Regular = {[1], [42 43 44 45], [2 23 24 25 46],  [3 4 5 6], [7 8 9 10 15 16 17 18], ...
    [11 12 13 14 19 20 21 22], [26 27 28 29 34 35 36 37],[30 31 32 33 38 39 40 41]};

movSets_C1 = {[1], [42 43 44 45], [2 23 24 25 46], [4 5],...
              [7 8 9 10 15 16 17 18], [11 12 13 14 19 20 21 22],...
              [26 27 28 29 34 35 36 37], [30 31 32 33 38 39 40 41]};

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

% Array groupings by PCG region
DorsalSet = {'T5-d1', 'T5-d2', 'T11-d1', 'C1-d1', 'C1-d2', 'C2-d2', 'T16-d2', 'T16-d1', 'T17-d2', 'T17-d1'};
MiddleSet = {'T15-m1', 'T16-m1'};
VentralSupSet = {'T15-v1', 'T12-v1', 'T17-v1'};
VentralInfSet = {'T15-v2', 'T15-v3', 'T12-v2', 'T16-v1', 'T17-v2'};

setInds = {find(ismember(pDat_order, DorsalSet)), ...
           find(ismember(pDat_order, MiddleSet)), ...
           find(ismember(pDat_order, VentralSupSet)), ...
           find(ismember(pDat_order, VentralInfSet))};

%% Extended Data Figure 1 - Significantly tuned electrodes analysis code
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 1\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Extended Data Fig. 1a - Raster of significantly tuned channels\n');

% Count of tuned electrodes and monolithic spike raster structure
plotCellTxt = 1;

saveDir = [save_dir 'ExtDataFig1']; mkdir(saveDir);
tmpDir = [saveDir filesep 'TunedElectrodes']; mkdir(tmpDir);

% to be used to merge all sub-movements into same movement category
movSets_Regular_tunedElectrodes = {[1], [42 43 44 45], [2 23 24 25 46],  [3 4 5 6],  ...
    [30 31 32 33 38 39 40 41], [26 27 28 29 34 35 36 37], [11 12 13 14 19 20 21 22], [7 8 9 10 15 16 17 18],};
movSetNames_tunedElectrodes = {'DoNothing', 'Speech','Face','Head','RightArm','RightLeg','LeftArm','LeftLeg',};

for d = 1 : numel(datNames)

    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;

    tx = Dat.tx;
    msFeat = [tx.*50]; % T x Chans

    meanFeat = nanmean(msFeat,1); % in Hz
    indsKeep1 = find(meanFeat > 2);
    indsKeep2 = find(meanFeat < 200);

    indsKeep = intersect(indsKeep1, indsKeep2);
    indsThrow = setdiff([1:numel(meanFeat)], indsKeep);

    msFeat(:,indsThrow) = nan;
    indsKeep = [1:size(tx,2)];

    currSaveDir = [tmpDir filesep datNames{d} '/'];
    mkdir(currSaveDir);

    sDat.goTimes = Dat.goCue;
    sDat.movementCodes = Dat.trialCue; %
    sDat.movementNames = Dat.cueList; %
    sDat.movementSets = {movSets_Regular_tunedElectrodes{2:end}}; %
    sDat.movementSetNames = {movSetNames_tunedElectrodes{2:end}}; %

    sDat.doNothingCode = 1; %

    sDat.binWidth = 0.02;
    sDat.rasterMax = 100;

    sDat.do_ttest = true; %

    cueName = 'GoCue';
    sDat.plottingWindow = [-100, 150]; %
    sDat.analysisWindow = goWindows{d}; %

    fprintf('\n Currently Running Electrode Tuning Count for :\n');
    for chanSetIdx = 1:numel(Dat.chanSets)
        % Skip arrays not in analysis list
        if ~ismember(Dat.chanSetNames{chanSetIdx}, pDat_order)
            continue;
        end

         fprintf('%s\n' , Dat.chanSetNames{chanSetIdx});

        channels = Dat.chanSets{chanSetIdx};
        channels = channels(ismember(channels,indsKeep));

        sDat.chanSets = Dat.chanSets{chanSetIdx};
        sDat.saveDir = [currSaveDir Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName]; %

        sDat.features = msFeat(:,channels); %
        tuningAnalyses(sDat);

    end
    pause(1);
    close all;
    pause(1);
end

%% Extended Data Figure 1 - Significantly tuned channels (multiunit threshold crossing data)
    saveDir = [save_dir 'ExtDataFig1']; mkdir(saveDir);
    tmpDir = [saveDir filesep 'TunedElectrodes']; mkdir(tmpDir);

    plotCellTxt = 1;

    arrayOrder = reorderNames;

    C1_reject = {'HEAD - Turn Down','HEAD - Turn Up'};

        sigStruct = [];
        groups = [];
        ArrayChannelNums = [];
        sigStruct_candidate = [];
        for a = 1 : numel(arrayOrder)
            currParticipant = strtok(arrayOrder{a},'-');

            % load SigTuning.mat
            load([tmpDir filesep currParticipant '/' arrayOrder{a} 'Tuning_' cueName filesep 'Ttest_SigTuning.mat']);

            currVals = ttest_sig.significancePVals;
            if strcmp(currParticipant, 'C1')
                indsBuff = find(ismember(ttest_sig.movementNamesReordered_yaxis, C1_reject) == 1);
                currVals(:,indsBuff) = 0;
            end

            sigStruct{a} = currVals;
            sigStruct_candidate{a} = currVals(ttest_sig.indsKeep,:);

            groups{a} = ttest_sig.moveSetNum;

            ArrayChannelNums = [ArrayChannelNums; ttest_sig.numTotalChannelsInArray ttest_sig.numChannels_candidate];
        end

        % plot stacked significantly modulating channels
        compiled_sigTuning = figure('Name', 'Ext. Data Fig. 1a - Significantly tuned channels', 'Position',[75 894 1757 353]);

        groupsNumbers = unique(groups{1});

        cols = [...
            0.27          0.80          0.53;...
            0             0          0.80;...
            0.53          0.80          0.27;...
            0.80          0.27             0;...
            0.80          0.80             0;...
            0             0          0.53;...
            0          0.80          0.80;...
            0.80          0.53             0;...
            0.80             0             0;...
            0          0.27          0.80;...
            0          0.53          0.80];

        mvNames = {ttest_sig.cueList{ttest_sig.movementCode}};
        numChannelsTunedToMoveSet = [];
        numMoveSetsTunedTo= [];
        actualNumChannelsTunedToMoveSet = [];
        actualNumMoveSetsTunedTo_All = [];
        actualNumMoveSetsTunedTo_candidate = [];
        for sig = 1 : numel(sigStruct)
            subtightplot(1,numel(sigStruct),sig);
            vals = sigStruct{sig};
            vals_candidate = sigStruct_candidate{sig};

            MarkerFormat = struct();
            MarkerFormat.MarkerSize = 10;

            groupSig_stacked = [];
            groupSig_stacked_candidates = [];
            for groupNum = 1 : numel(groupsNumbers)
                currGroupNums = groups{sig};

                groupInds = find(currGroupNums == groupsNumbers(groupNum));
                MarkerFormat.MarkerFaceColor = cols(groupNum,:);
                MarkerFormat.MarkerEdgeColor = cols(groupNum,:);
                currVals = zeros(size(vals));
                currVals(:,groupInds) = vals(:,groupInds);

                plotSpikeRaster(logical(currVals'),'PlotType','scatter','MarkerFormat',MarkerFormat);

                groupSig_stacked = [groupSig_stacked sum(vals(:,groupInds),2)];
                groupSig_stacked_candidates = [groupSig_stacked_candidates sum(vals_candidate(:,groupInds),2)];
            end
            numChannelsTunedToMoveSet = [numChannelsTunedToMoveSet ; sum(logical(groupSig_stacked),1)./size(groupSig_stacked,1)];
            actualNumChannelsTunedToMoveSet = [actualNumChannelsTunedToMoveSet ; sum(logical(groupSig_stacked),1)];

            numMoveSetsTunedTo = [numMoveSetsTunedTo ; histcounts(sum(logical(groupSig_stacked),2),[0:1:size(groupSig_stacked,2)+1])./size(groupSig_stacked,1) ];
            actualNumMoveSetsTunedTo_All = [actualNumMoveSetsTunedTo_All ; histcounts(sum(logical(groupSig_stacked),2),[0:1:size(groupSig_stacked,2)+1]) ];
            actualNumMoveSetsTunedTo_candidate = [actualNumMoveSetsTunedTo_candidate ; histcounts(sum(logical(groupSig_stacked_candidates),2),[0:1:size(groupSig_stacked_candidates,2)+1]) ];

            
            if sig ~= 1
                yticks([]);
            end
            xticks([]);
            set(gca,'YDir','reverse');
            if sig == 1
                yticks([1:1:numel(mvNames)]);
                yticklabels(mvNames);
            end
            title(arrayOrder{sig});
            set(gca,'fontsize',7);
        end

        %save this figure
        exportPNGFigure(compiled_sigTuning, [saveDir filesep 'ExtDataFig1a_SignificantChannels_' cueName]);

        % Extended Data Figure 1b - Fraction of channels tuned to each movement category
        figure('Name','Ext. Data Fig. 1b,c - Fraction tuned to category');
        subplot(1,2,1);
        imagesc(numChannelsTunedToMoveSet, [0 1]);
        colormap(colMap);
        colorbar;
        xticks([1:numel(ttest_sig.moveSetNames)]);
        xticklabels(ttest_sig.moveSetNames);
        yticks([1:numel(arrayOrder)]);
        yticklabels(arrayOrder);
        axis square;
        title('Fraction of channels tuned to movement set');

        vals = numChannelsTunedToMoveSet;
        if plotCellTxt
            [R,C] = ndgrid(1:size(vals,1), 1:size(vals,2)); R = R(:); C = C(:);
            txtVals = round(vals(:),2);
            format bank;
            text(C'-0.25, R', string(txtVals),'FontSize', 7,'Color','w');
        end

        % Extended Data Figure 1c - Fraction of channels tuned to number of
        % movement sets
        subplot(1,2,2);
        imagesc(numMoveSetsTunedTo, [0 0.5]);
        colormap(colMap);
        colorbar;
        xticks([1:size(numMoveSetsTunedTo,2)]);
        xticklabels({'0','1','2','3','4','5','6','7'});
        xlabel('Number of movement sets');
        yticks([1:numel(arrayOrder)]);
        yticklabels(arrayOrder);
        axis square;
        title('Fraction of channels tuned to numbers of movement sets');

        vals = numMoveSetsTunedTo;
        if plotCellTxt
            [R,C] = ndgrid(1:size(vals,1), 1:size(vals,2)); R = R(:); C = C(:);
            txtVals = round(vals(:),2);
            format bank;
            text(C'-0.25, R', string(txtVals),'FontSize', 7,'Color','w');
        end
        exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig1bc_FractionTuned' cueName]);



%% Extended Data Figure 2 Analysis - Significantly tuned sorted units (spike sorted data)
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 2\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Extended Data Fig. 2a - Raster of significantly tuned units\n');

% Array definitions per participant
pDat_sorted = cell(numel(datNames), 1);
pDat_sorted{T5}.arrays =  {'T5-d1Sorted',  'T5-d2Sorted'};
pDat_sorted{T12}.arrays = {'T12-v1Sorted', 'T12-v2Sorted'};
pDat_sorted{T11}.arrays = {'T11-d1Sorted'};
pDat_sorted{C1}.arrays =  {'C1-d1Sorted',  'C1-d2Sorted'};
pDat_sorted{C2}.arrays =  {'C2-d2Sorted'};
pDat_sorted{T15}.arrays = {'T15-m1Sorted', 'T15-v1Sorted', 'T15-v2Sorted', 'T15-v3Sorted'};
pDat_sorted{T16}.arrays = {'T16-m1Sorted', 'T16-v1Sorted', 'T16-d2Sorted', 'T16-d1Sorted'};
pDat_sorted{T17}.arrays = {'T17-v2Sorted', 'T17-v1Sorted', 'T17-d2Sorted', 'T17-d1Sorted'};

% Flatten array order for quick lookup
pDat_order_sorted = {};
for p = 1:numel(pDat_sorted)
    pDat_order_sorted = [pDat_order_sorted pDat_sorted{p}.arrays];
end

% Count of tuned electrodes and monolithic spike raster structure
plotCellTxt = 1;

saveDir = [save_dir 'ExtDataFig2']; mkdir(saveDir);
tmpDir = [saveDir filesep 'TunedUnits']; mkdir(tmpDir);

% to be used to merge all sub-movements into same movement category
movSets_Regular_tunedElectrodes = {[1], [42 43 44 45], [2 23 24 25 46],  [3 4 5 6],  ...
    [30 31 32 33 38 39 40 41], [26 27 28 29 34 35 36 37], [11 12 13 14 19 20 21 22], [7 8 9 10 15 16 17 18],};
movSetNames_tunedElectrodes = {'DoNothing', 'Speech','Face','Head','RightArm','RightLeg','LeftArm','LeftLeg',};

for d = 1 : numel(datNames)

    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;

    tx = Dat.tx;
    msFeat = [tx.*50]; % T x Chans

    meanFeat = nanmean(msFeat,1); % in Hz
    indsKeep1 = find(meanFeat > 2);
    indsKeep2 = find(meanFeat < 200);

    indsKeep = intersect(indsKeep1, indsKeep2);
    indsThrow = setdiff([1:numel(meanFeat)], indsKeep);

    msFeat(:,indsThrow) = nan;
    indsKeep = [1:size(tx,2)];

    currSaveDir = [tmpDir filesep datNames{d} '/'];
    mkdir(currSaveDir);

    sDat.goTimes = Dat.goCue;
    sDat.movementCodes = Dat.trialCue; %
    sDat.movementNames = Dat.cueList; %
    sDat.movementSets = {movSets_Regular_tunedElectrodes{2:end}}; %
    sDat.movementSetNames = {movSetNames_tunedElectrodes{2:end}}; %

    sDat.doNothingCode = 1; %

    sDat.binWidth = 0.02;
    sDat.rasterMax = 100;

    sDat.do_ttest = true; %

    cueName = 'GoCue';
    sDat.plottingWindow = [-100, 150]; %
    sDat.analysisWindow = goWindows{d}; %

    fprintf('\n Currently Running Sorted Unit Tuning Count for\n');
    for chanSetIdx = 1:numel(Dat.chanSets)
        % Skip arrays not in analysis list
        if ~ismember(Dat.chanSetNames{chanSetIdx}, pDat_order_sorted)
            continue;
        end

        fprintf('%s\n' , Dat.chanSetNames{chanSetIdx});

        channels = Dat.chanSets{chanSetIdx};
        channels = channels(ismember(channels,indsKeep));

        sDat.chanSets = Dat.chanSets{chanSetIdx};
        sDat.saveDir = [currSaveDir Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName]; %

        sDat.features = msFeat(:,channels); %
        tuningAnalyses(sDat);

    end
    pause(1);
    close all;
    pause(1);
end

%% Extended Data Figure 2a,c,d - Significantly tuned units (sorted unit threshold crossing data)
    saveDir = [save_dir 'ExtDataFig2']; mkdir(saveDir);
    tmpDir = [saveDir filesep 'TunedUnits']; mkdir(tmpDir);

    plotCellTxt = 1;

    arrayOrder = {'C2-d2Sorted', 'C1-d1Sorted', 'C1-d2Sorted','T17-d1Sorted', 'T5-d1Sorted',  'T5-d2Sorted','T17-d2Sorted', 'T16-d1Sorted',...
                'T16-d2Sorted','T11-d1Sorted','T15-m1Sorted','T16-m1Sorted','T15-v1Sorted','T12-v1Sorted', 'T15-v2Sorted', 'T17-v1Sorted',...
                'T12-v2Sorted', 'T15-v3Sorted', 'T17-v2Sorted','T16-v1Sorted'};

    C1_reject = {'HEAD - Turn Down','HEAD - Turn Up'};

        sigStruct = [];
        groups = [];
        ArrayChannelNums = [];
        sigStruct_candidate = [];
        for a = 1 : numel(arrayOrder)
            currParticipant = strtok(arrayOrder{a},'-');

            % load SigTuning.mat
            load([tmpDir filesep currParticipant '/' arrayOrder{a} 'Tuning_' cueName filesep 'Ttest_SigTuning.mat']);

            currVals = ttest_sig.significancePVals;
            if strcmp(currParticipant, 'C1')
                indsBuff = find(ismember(ttest_sig.movementNamesReordered_yaxis, C1_reject) == 1);
                currVals(:,indsBuff) = 0;
            end

            sigStruct{a} = currVals;
            sigStruct_candidate{a} = currVals(ttest_sig.indsKeep,:);

            groups{a} = ttest_sig.moveSetNum;

            ArrayChannelNums = [ArrayChannelNums; ttest_sig.numTotalChannelsInArray ttest_sig.numChannels_candidate];
        end

        % plot stacked significantly modulating channels
        compiled_sigTuning = figure('Name', 'Ext. Data Fig. 2a - Significantly tuned sorted units', 'Position',[75 894 1757 353]);

        groupsNumbers = unique(groups{1});

        cols = [...
            0.27          0.80          0.53;...
            0             0          0.80;...
            0.53          0.80          0.27;...
            0.80          0.27             0;...
            0.80          0.80             0;...
            0             0          0.53;...
            0          0.80          0.80;...
            0.80          0.53             0;...
            0.80             0             0;...
            0          0.27          0.80;...
            0          0.53          0.80];

        mvNames = {ttest_sig.cueList{ttest_sig.movementCode}};
        numChannelsTunedToMoveSet = [];
        numMoveSetsTunedTo= [];
        actualNumChannelsTunedToMoveSet = [];
        actualNumMoveSetsTunedTo_All = [];
        actualNumMoveSetsTunedTo_candidate = [];

        for sig = 1 : numel(sigStruct)
            subtightplot(1,numel(sigStruct),sig);
            vals = sigStruct{sig};
            vals_candidate = sigStruct_candidate{sig};

            MarkerFormat = struct();
            MarkerFormat.MarkerSize = 10;

            groupSig_stacked = [];
            groupSig_stacked_candidates = [];
            for groupNum = 1 : numel(groupsNumbers)
                currGroupNums = groups{sig};

                groupInds = find(currGroupNums == groupsNumbers(groupNum));
                MarkerFormat.MarkerFaceColor = cols(groupNum,:);
                MarkerFormat.MarkerEdgeColor = cols(groupNum,:);
                currVals = zeros(size(vals));
                currVals(:,groupInds) = vals(:,groupInds);

                tmpVals = zeros(size(vals_candidate));
                tmpVals(:,groupInds) = vals_candidate(:,groupInds);

                plotSpikeRaster(logical(tmpVals'),'PlotType','scatter','MarkerFormat',MarkerFormat);

                groupSig_stacked = [groupSig_stacked sum(vals(:,groupInds),2)];
                groupSig_stacked_candidates = [groupSig_stacked_candidates sum(vals_candidate(:,groupInds),2)];
            end

            numChannelsTunedToMoveSet = [numChannelsTunedToMoveSet ; sum(logical(groupSig_stacked),1)./size(groupSig_stacked,1)];
            actualNumChannelsTunedToMoveSet = [actualNumChannelsTunedToMoveSet ; sum(logical(groupSig_stacked),1)];

            numMoveSetsTunedTo = [numMoveSetsTunedTo ; histcounts(sum(logical(groupSig_stacked),2),[0:1:size(groupSig_stacked,2)+1])./size(groupSig_stacked,1) ];
            actualNumMoveSetsTunedTo_All = [actualNumMoveSetsTunedTo_All ; histcounts(sum(logical(groupSig_stacked),2),[0:1:size(groupSig_stacked,2)+1]) ];
            actualNumMoveSetsTunedTo_candidate = [actualNumMoveSetsTunedTo_candidate ; histcounts(sum(logical(groupSig_stacked_candidates),2),[0:1:size(groupSig_stacked_candidates,2)+1]) ];

            
            if sig ~= 1
                yticks([]);
            end
            % xticks([]);
            % set xtick to end of candidate units
            numCandidateUnits = size(vals_candidate,1);
            xticks([numCandidateUnits]);
            xticklabels(num2str(numCandidateUnits));

            set(gca,'YDir','reverse');
            if sig == 1
                yticks([1:1:numel(mvNames)]);
                yticklabels(mvNames);
            end
            title(arrayOrder{sig});
            set(gca,'fontsize',7);
        end
        
        %save this figure
        exportPNGFigure(compiled_sigTuning, [saveDir filesep 'ExtDataFig2a_SignificantUnits_' cueName]);

        fracChannelsTunedToMoveSet_xAllElectrodes = [actualNumChannelsTunedToMoveSet./ArrayChannelNums(:,1) ArrayChannelNums(:,1)];
        fracChannelsTunedToMoveSet_xCandidateElectrodes = [actualNumChannelsTunedToMoveSet./ArrayChannelNums(:,2) ArrayChannelNums(:,2)];

        fracChannelsNumMoveSetsTunedTo_xAllElectrodes = [actualNumMoveSetsTunedTo_All./ArrayChannelNums(:,1) ArrayChannelNums(:,1)];
        fracChannelsNumMoveSetsTunedTo_xCandidateElectrodes = [actualNumMoveSetsTunedTo_candidate./ArrayChannelNums(:,2) ArrayChannelNums(:,2)];


        % Extended Data Figure 1b - Fraction of channels tuned to each movement category
        figure('Name','Ext. Data Fig. 2c,d - Fraction sorted units','Position',[1.00 1.00 1728.00 855.00]);
        subplot(1,2,1);
        imagesc(fracChannelsTunedToMoveSet_xCandidateElectrodes(:,1:7),[0 1]);
        colormap(colMap);
        colorbar;
        xlbls = ttest_sig.moveSetNames;
        xticks([1:numel(xlbls)]);
        xticklabels(xlbls);
        yticks([1:numel(arrayOrder)]);
        yticklabels(arrayOrder);
        axis square;
        title('Fraction of Candidate Units tuned to Move set');

        vals = fracChannelsTunedToMoveSet_xCandidateElectrodes;
        if plotCellTxt
            [R,C] = ndgrid(1:size(vals,1), 1:size(vals,2)); R = R(:); C = C(:);
            txtVals = round(vals(:),2);
            format bank;
            text(C'-0.25, R', string(txtVals),'FontSize', 7,'Color','w');
        end

        subplot(1,2,2);
        imagesc(fracChannelsNumMoveSetsTunedTo_xCandidateElectrodes(:,1:8),[0 0.5]);
        colormap(colMap);
        colorbar;
        xlbls = {'0','1','2','3','4','5','6','7'};
        xticks([1:numel(xlbls)]);
        xticklabels(xlbls);
        yticks([1:numel(arrayOrder)]);
        yticklabels(arrayOrder);
        axis square;
        title('Fraction of Candidate Units tuned to # Move Sets');

        vals = fracChannelsNumMoveSetsTunedTo_xCandidateElectrodes;
        if plotCellTxt
            [R,C] = ndgrid(1:size(vals,1), 1:size(vals,2)); R = R(:); C = C(:);
            txtVals = round(vals(:),2);
            format bank;
            text(C'-0.25, R', string(txtVals),'FontSize', 7,'Color','w');
        end

        exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig2cd_FractionUnits_' cueName]);



%% Extended Data Figure 2b - Canonical and non-canonical pairwise neural distances
fprintf('Performing pair-wise neural distances for non-canonical and canonical movements\n');

saveDir = [save_dir 'ExtDataFig2']; mkdir(saveDir);
tmpDir = [saveDir filesep 'NonCanonRatios']; mkdir(tmpDir);

toss_low_modulating_units = true;
commonGoWindow = [15 50-1]; 

% define non-canonical movements
dorsal_nonCanon = [42 43 44 45   2 23 24 25 46]; % speech, face
dorsal_canon = [30 31 32 33 38 39 40 41]; % R Arm
ventral_nonCanon = [7 8 9 10 15 16 17 18 11 12 13 14 19 20 21 22 26 27 28 29 34 35 36 37 30 31 32 33 38 39 40 41]; % left right arms legs
ventral_canon = [42 43 44 45 2 23 24 25 46]; % speech, face

featVals_dorsal = {};
featVals_dorsal_names = {};
featVals_ventral = {};
featVals_ventral_names = {};
dorsal_ind = 1;
ventral_ind = 1;

    for d = 1 : numel(datNames)
        Dat = load([data_dir datNames{d} '.mat']);
        Dat = Dat.DataMat;
        cueList = Dat.cueList;

        tx = Dat.tx_blkMeanSub;

        msFeat = [tx.*50]; % T x Chans

        if ~toss_low_modulating_units
            msFeat = (msFeat - nanmean(msFeat,1))./nanstd(msFeat,1); % z-score feats => TxChans
        end

        % throw NaN features
        tmp = sum(isnan(msFeat),1);
        indsThrow = find(tmp == size(msFeat,1));
        indsKeep = find(tmp ~= size(msFeat,1));

        % clip each trial to equal lengths relative to the go cue
        goCues = Dat.goCue;
        trlCues = Dat.trialCue;

        [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(msFeat, trlCues, goCues, commonGoWindow, commonGoWindow(1):commonGoWindow(2), 1);
        % Feature Vals is NxCxTxR
        featureVals = featureVals(:,1:46,:,:);

        % simple count of trialCues
        uniqueVals = unique(int16(trlCues));
        counts = histc(int16(trlCues), uniqueVals);
        uniqueCounts = unique(counts);

        minCount = min(uniqueCounts);
        featureVals = featureVals(:,:,:,1:minCount);

        fprintf('\nCurrently on:\n');
        for chanSetIdx = 1 : numel(Dat.chanSets)
            
            chanName = Dat.chanSetNames{chanSetIdx};
            channels = Dat.chanSets{chanSetIdx};
            channels = channels(ismember(channels,indsKeep));

            % skip this array if not in our desired list of
            if ~ismember(chanName, pDat_order_sorted)
                continue;
            end

            fprintf('%s\n' , Dat.chanSetNames{chanSetIdx});
            
            featVals = featureVals(channels,:,:,:);

            if contains(chanName, '-d') & contains(chanName, 'Sorted')% dorsal array
                featVals_dorsal{dorsal_ind} = featVals;
                featVals_dorsal_names{dorsal_ind} = chanName;
                dorsal_ind = dorsal_ind + 1;
            
            elseif contains(chanName, '-v') & contains(chanName, 'Sorted')% ventral
                featVals_ventral{ventral_ind} = featVals;
                featVals_ventral_names{ventral_ind} = chanName;
                ventral_ind = ventral_ind + 1;

            else
                continue;
            end


        end
    end

    sDat.movementSets = {movSets_Regular{2:end}};
    sDat.movementSetNames = {'Speech','Face','Head','LeftLeg','LeftArm','RightLeg','RightArm'};
    sDat.doNothingCode = 1;
    sDat.dPCA_smoothWidth = 4;
    sDat.binWidth = 0.02;
    sDat.rasterMax = 100;
    sDat.plotRasters = false;
    sDat.plotPSTHs = false;
    sDat.plotHeatMaps = false;
    sDat.fullDistanceMatrix = true;
    sDat.twoWayClassificationMatrix = false;
    sDat.withinGroupCorrelation = false;
    sDat.plotDPCA = false;
    sDat.plotMPCA = false;
    sDat.classifySubsets = false;
    sDat.classifyAll = false;
    sDat.plotBarPlots = false;
    sDat.barYlim = 1;
    sDat.barCISRemove = 0;
    sDat.analysisWindow = [0 35-1];
    sDat.distancePlot = false;

    dorsal_nonCanon_mvNames = {cueList{dorsal_nonCanon}};
    dorsal_canon_mvNames = {cueList{dorsal_canon}};
    ventral_nonCanon_mvNames = {cueList{ventral_nonCanon}};
    ventral_canon_mvNames = {cueList{ventral_canon}};

    % now trim all feature vals to the minimum number of reps for trials
    dorsalTrialReps = [];
    ventralTrialReps = [];
    for j = 1 : numel(featVals_dorsal)
        [N,C,T,R] = size(featVals_dorsal{j});
        dorsalTrialReps = [dorsalTrialReps R];
    end
    minDorsalTrialReps = min(dorsalTrialReps);

    for j = 1 : numel(featVals_ventral)
        [N,C,T,R] = size(featVals_ventral{j});
        ventralTrialReps = [ventralTrialReps R];
    end
    minVentralTrialReps = min(ventralTrialReps);

    % now randomly select the minimum number of trials from each featureval
    featVals_dorsal_trimmed = {};
    for j = 1 : numel(featVals_dorsal)
        currFeatVal = featVals_dorsal{j};
        permInds = randperm(size(currFeatVal,4));
        featVals_dorsal_trimmed{j} = currFeatVal(:,:,:,permInds(1:minDorsalTrialReps));
    end
    % concatenate across first dimension
    featVals_dorsal_cat = cat(1, featVals_dorsal_trimmed{:});

    % now randomly select the minimum number of trials from each featureval
    featVals_ventral_trimmed = {};
    for j = 1 : numel(featVals_ventral)
        currFeatVal = featVals_ventral{j};
        permInds = randperm(size(currFeatVal,4));
        featVals_ventral_trimmed{j} = currFeatVal(:,:,:,permInds(1:minVentralTrialReps));
    end
    % concatenate across first dimension
    featVals_ventral_cat = cat(1, featVals_ventral_trimmed{:});

    % now perform jacknife resampling (leave one out) and perform cross-val
    % neural distance computation, extract the relevant values from the
    % matrix, compute the mean pairwise canon, and mean pairwise non-canon,
    % divide the two to get a mod ratio for this fold
    
    % dorsal
        jackknifeStruct = struct('indices', cell(1, minDorsalTrialReps));
        fullIdx = 1:minDorsalTrialReps;
        for i = 1:minDorsalTrialReps
            jackknifeStruct(i).indices = fullIdx(fullIdx ~= i);
        end
    
        dorsal_modRatios = [];
        for iter = 1 : minDorsalTrialReps
            fprintf('\nIteration: %d of %d\n', iter, minDorsalTrialReps);
            X = featVals_dorsal_cat(:,:,:,jackknifeStruct(iter).indices);
            [N,C,T,R] = size(X);
    
            % 1) Permute so that dims are [N , T , R , C],
            %    i.e. inside each condition we have T×R blocks.
            Xperm = permute(X, [1 3 4 2]);  % now size = [N x T x R x C]
    
            % 2) Reshape to [N x (T*R*C)].
            Xflat = reshape(Xperm, N, []);
    
            % 3) Build goCues and conds
            nTrials = C * R;
            goCues = zeros(1, nTrials);
            conds  = zeros(1, nTrials);
    
            % Each trial block is length T, and trials are ordered
            % first by condition=1, all R reps; then cond=2, all R reps; etc.
            for c = 1:C
                for r = 1:R
                    idx = (c-1)*R + r;          % trial index 1..C*R
                    % starting column of this trial in Xflat:
                    goCues(idx) = (idx-1)*T + 1;
                    conds(idx)  = c;            % record which condition
                end
            end
            dorsal_feats = Xflat';
            % dorsal_goCues_tmp = [1:35:size(dorsal_feats,1)]';
            dorsal_goCues = goCues';
            dorsal_trialCues = conds';
    
            [row,col] = find(isnan(dorsal_feats));
            dorsal_feats(row,col) = 0;
    
            if toss_low_modulating_units
                % remove sorted units not above 2Hz mean firing rate
                meanRate_dorsal = mean(dorsal_feats,1);
                indsThrow_dorsal = find(meanRate_dorsal <2);
                dorsal_feats(:,indsThrow_dorsal) = [];
                dorsal_feats = (dorsal_feats - nanmean(dorsal_feats,1))./nanstd(dorsal_feats,1);
            end
  
        
            sDat.goTimes = dorsal_goCues;
            sDat.features = dorsal_feats;
            sDat.movementCodes = dorsal_trialCues';
            sDat.movementNames = cueList;
        
            sDat.saveDir = [tmpDir filesep 'Dorsal_NeuralDistances'];
            mkdir(sDat.saveDir);
        
            dorsal_ret = tuningAnalyses(sDat);
        
            sortedCues = dorsal_ret.distanceMatrix_sortedNames;
            distMatrix = dorsal_ret.distanceMatrix;
            inds_nonCanon = find(ismember(sortedCues, dorsal_nonCanon_mvNames)==1);
            inds_canon = find(ismember(sortedCues, dorsal_canon_mvNames)==1);
            
            [n,m] = size(distMatrix);
        
            nonCanon_vals = triu(distMatrix(inds_nonCanon, inds_nonCanon));
            canon_vals = triu(distMatrix(inds_canon, inds_canon));
        
            nonCanon_vals=nonCanon_vals(nonCanon_vals~=0);
            canon_vals=canon_vals(canon_vals~=0);

            dorsal_modRatios = [dorsal_modRatios mean(nonCanon_vals)/mean(canon_vals)];
        end


        % ventral
        jackknifeStruct = struct('indices', cell(1, minVentralTrialReps));
        fullIdx = 1:minVentralTrialReps;
        for i = 1:minVentralTrialReps
            jackknifeStruct(i).indices = fullIdx(fullIdx ~= i);
        end
    
        ventral_modRatios = [];
        for iter = 1 : minVentralTrialReps
            fprintf('\nIteration: %d of %d\n', iter, minVentralTrialReps);
            X = featVals_ventral_cat(:,:,:,jackknifeStruct(iter).indices);
            [N,C,T,R] = size(X);
    
            % 1) Permute so that dims are [N , T , R , C],
            %    i.e. inside each condition we have T×R blocks.
            Xperm = permute(X, [1 3 4 2]);  % now size = [N x T x R x C]
    
            % 2) Reshape to [N x (T*R*C)].
            Xflat = reshape(Xperm, N, []);
    
            % 3) Build goCues and conds
            nTrials = C * R;
            goCues = zeros(1, nTrials);
            conds  = zeros(1, nTrials);
    
            % Each trial block is length T, and trials are ordered
            % first by condition=1, all R reps; then cond=2, all R reps; etc.
            for c = 1:C
                for r = 1:R
                    idx = (c-1)*R + r;          % trial index 1..C*R
                    % starting column of this trial in Xflat:
                    goCues(idx) = (idx-1)*T + 1;
                    conds(idx)  = c;            % record which condition
                end
            end
            ventral_feats = Xflat';
            ventral_goCues = goCues';
            ventral_trialCues = conds';
    
            [row,col] = find(isnan(ventral_feats));
            ventral_feats(row,col) = 0;
    
            if toss_low_modulating_units
                % remove sorted units not above 2Hz mean firing rate
                meanRate_ventral = mean(ventral_feats,1);
                indsThrow_ventral = find(meanRate_ventral <2);
                ventral_feats(:,indsThrow_ventral) = [];
                ventral_feats = (ventral_feats - nanmean(ventral_feats,1))./nanstd(ventral_feats,1);
            end
  
            sDat.goTimes = ventral_goCues;
            sDat.features = ventral_feats;
            sDat.movementCodes = ventral_trialCues';
            sDat.movementNames = cueList;
        
            sDat.saveDir = [tmpDir filesep 'Ventral_NeuralDistances'];
            mkdir(sDat.saveDir);
        
            ventral_ret = tuningAnalyses(sDat);
        
            sortedCues = ventral_ret.distanceMatrix_sortedNames;
            distMatrix = ventral_ret.distanceMatrix;
            inds_nonCanon = find(ismember(sortedCues, ventral_nonCanon_mvNames)==1);
            inds_canon = find(ismember(sortedCues, ventral_canon_mvNames)==1);
            
            [n,m] = size(distMatrix);
        
            nonCanon_vals = triu(distMatrix(inds_nonCanon, inds_nonCanon));
            canon_vals = triu(distMatrix(inds_canon, inds_canon));
        
            nonCanon_vals=nonCanon_vals(nonCanon_vals~=0);
            canon_vals=canon_vals(canon_vals~=0);

            ventral_modRatios = [ventral_modRatios mean(nonCanon_vals)/mean(canon_vals)];
        end

        dorsal_ratios = dorsal_modRatios;
        ventral_ratios = ventral_modRatios;

    figure('Name','Ext. Data Fig. 2b - Non-canonical movement ratios');

    dat = dorsal_ratios;
    jitter = randn(length(dorsal_ratios),1)*0.05;
    a = bar(1, mean(dat),0.2, 'LineWidth',1,'FaceColor',[179 57 19]./255);
    hold on;
    X = dat;
    N = length(X);
    theta_jack = mean(X);
    se_jack = sqrt((N-1)/N * sum((X-theta_jack).^2));
    z = 1.96;
    ci_lower = theta_jack - z*se_jack;
    ci_upper = theta_jack + z*se_jack;
    errorbar(1 ,mean(dat), mean(dat)-ci_lower,ci_upper-mean(dat),'k','LineWidth',2);
    % plot scatter
    scatter(1+jitter, dat, 50,'filled','k');


    dat = ventral_ratios;
    jitter = randn(length(ventral_ratios),1)*0.05;
    b = bar(2, mean(dat),0.2, 'LineWidth',1,'FaceColor',[113 69 145]./255);
    hold on;
    X = dat;
    N = length(X);
    theta_jack = mean(X);
    se_jack = sqrt((N-1)/N * sum((X-theta_jack).^2));
    z = 1.96;
    ci_lower = theta_jack - z*se_jack;
    ci_upper = theta_jack + z*se_jack;
    errorbar(2 ,mean(dat), mean(dat)-ci_lower,ci_upper-mean(dat),'k','LineWidth',2);
    % plot scatter
    scatter(2+jitter, dat, 50,'filled','k');

    legend([a b], 'Dorsal ratio', 'Ventral ratio');
    xticks([1:2]);
    xticklabels({'Dorsal', 'Ventral'});
    fontsize(gcf,14,'points')
    ylim([0,1]);
    title('Non-canonical-Canonical Ratio');
    ylabel('Ratio between avg. pairwise neural distance');
    xlabel('Sorted Unit set');

    exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig2b_NonCanonRatios_' cueName]);

%% Extended Data Figure 2e - PSTHs of sorted units
fprintf('******* Generating Extended Data Figure 2e - Sorted Unit PSTHs\n\n');

saveDir = [save_dir 'ExtDataFig2']; mkdir(saveDir);
tmpDir = [saveDir filesep 'PSTHs']; mkdir(tmpDir);

datNames = {'T5', 'T12'};
chanSetNames = {'T5-d1Sorted','T12-v1Sorted'};
ylims = {[-5 40], [-5 25]};

cueName = 'GoCue';
goWindow=[15, 75-1];

for d = 1 : numel(datNames)
    % Load data
    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;

    currChanSet = find(strcmp(Dat.chanSetNames,chanSetNames{d}));
    currChanInds = Dat.chanSets{currChanSet};

    msFeat = Dat.tx.*50;
    msFeat = msFeat(:,currChanInds);
    
    currSaveDir = [tmpDir filesep datNames{d} filesep];
    mkdir(currSaveDir);

    sDat = struct();
    sDat.features = msFeat;
    sDat.saveDir = currSaveDir;
    sDat.analysisWindow = goWindow;
    sDat.movementCodes = Dat.trialCue; % extract the movement cue per trial
    sDat.movementNames = Dat.cueList;  % extract the master cue list as a struct of strings
    sDat.goTimes = Dat.goCue;
    sDat.movementSets = {movSets_Regular{2:end}}; % trim off the Do Nothing condition when defining movement sets
    sDat.movementSetNames = {movSetNames{2:end}}; % trim off the Do Nothing set
    sDat.doNothingCode = 1; % define the 'Do Nothing' cue number, which is 1
    sDat.ylims = ylims{d};
    plotPSTHs(sDat); 
end

% compile sorted units into single figure
chanNums = [9, 2];
effector = {'Speech', 'RightArm', 'LeftArm', 'Face', 'RightLeg', 'LeftLeg','Head'};

for d = 1 : numel(chanNums)
    fig_target = figure('Name', ['Ext. Data Fig. 2e PSTHs - ' chanSetNames{d}], 'Position',[1.00 59.00 1728.00 969.00]); % create a new figure

    for eff = 1:numel(effector)
        psth_loc = [tmpDir filesep datNames{d} filesep 'psth_' effector{eff} filesep 'psth_1_' effector{eff} '.fig'];
        fig_tmp = openfig(psth_loc);
        
        figure(fig_target);
        subplot(3,3,eff);
        axesHandles = flip(findall(fig_tmp, 'Type', 'axes'));
        sourceAx = axesHandles(chanNums(d));

        newAx = copyobj(sourceAx, fig_target);
        subplotPos = get(gca, 'Position');
        set(newAx, 'Position', subplotPos);
        delete(gca);

        figure(fig_target);
        subplot(3,3,eff);
        ylim(ylims{d});
        title( sprintf('%s %s unit %s', effector{eff}, chanSetNames{d},num2str(chanNums(d))) );

        if eff == numel(effector)
            xlabel('Time (s)');
            ylabel('Firing rate (Hz)');
        end
    end

    exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig2e_PSTHs_' chanSetNames{d} '_' cueName]);
end




%% Extended Data Figure 3a - Spatial dimensionality
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 3A\n');
fprintf('See /Code/Utils/Python/WholeBody_cvPCA.ipynb to generate Extended Data Figure 3a\n');
fprintf('*******************************************************************************\n\n');

datNames = {'T5','T12','T11','C1','C2', 'T15', 'T16', 'T17'};
%% Extended Data Figure 3b - Non-canonical/Canonical Ratios
fprintf('******* Generating Extended Data Figure 3b - Non-canonical/Canonical Ratios \n\n');

saveDir = [save_dir 'ExtDataFig3']; mkdir(saveDir);

% define non-canonical movements
    dorsal_nonCanon = [42 43 44 45   2 23 24 25 46]; % speech, face
    dorsal_canon = [30 31 32 33 38 39 40 41]; % R Arm
    ventral_nonCanon = [7 8 9 10 15 16 17 18 11 12 13 14 19 20 21 22 26 27 28 29 34 35 36 37 30 31 32 33 38 39 40 41]; % left right arms legs
    ventral_canon = [42 43 44 45 2 23 24 25 46]; % speech, face

% iterate through each array in order, pull the neural distances matrix,
% get the non-canonical movements and store
canonStruct = {};
k = 1;
arrNames = {};
    for d = 1 : numel(datNames)
        Dat = load([data_dir datNames{d} '.mat']);
        Dat = Dat.DataMat;
        cueList = Dat.cueList;

        dorsal_nonCanon_mvNames = {cueList{dorsal_nonCanon}};
        dorsal_canon_mvNames = {cueList{dorsal_canon}};
        ventral_nonCanon_mvNames = {cueList{ventral_nonCanon}};
        ventral_canon_mvNames = {cueList{ventral_canon}};

        fprintf('\nCurrently Running Non-Canonical Distance Analysis\n');
            for chanSetIdx = 1:numel(Dat.chanSets)
                % Skip arrays not in analysis list
                if ~ismember(Dat.chanSetNames{chanSetIdx}, pDat_order)
                    continue;
                end

                fprintf('%s\n' , Dat.chanSetNames{chanSetIdx});

                matLoc = [data_dir filesep MainFigsAnalysisFolder filesep datNames{d} filesep Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName filesep 'neuralDistances.mat'];
                neuralDistStrct = load(matLoc); 
                sortedCues = neuralDistStrct.sortedNames;

                % check if dorsal or ventral
                if contains(Dat.chanSetNames{chanSetIdx}, '-d')
                    inds_nonCanon = find(ismember(sortedCues, dorsal_nonCanon_mvNames)==1);
                    inds_canon = find(ismember(sortedCues, dorsal_canon_mvNames)==1);
                elseif contains(Dat.chanSetNames{chanSetIdx}, '-v')
                    inds_nonCanon = find(ismember(sortedCues, ventral_nonCanon_mvNames)==1);
                    inds_canon = find(ismember(sortedCues, ventral_canon_mvNames)==1);
                else
                    continue;
                end
                arrNames{k} = Dat.chanSetNames{chanSetIdx};

                % extract non-canonical values, and canonical values
                distMatrix = neuralDistStrct.distanceMatrix;
                [n,m] = size(distMatrix);

                nonCanon_vals = triu(distMatrix(inds_nonCanon, inds_nonCanon));
                canon_vals = triu(distMatrix(inds_canon, inds_canon));

                nonCanon_vals=nonCanon_vals(nonCanon_vals~=0);
                canon_vals=canon_vals(canon_vals~=0);

                canonStruct{k}.name = Dat.chanSetNames{chanSetIdx};
                canonStruct{k}.nonCanon.vals = nonCanon_vals;
                canonStruct{k}.canon.vals = canon_vals;

                [CI, stats] = bootci(1000, {@(x)[mean(x) std(x)], nonCanon_vals}, 'type','norm');
                canonStruct{k}.nonCanon.meanCI = [mean(nonCanon_vals); CI(:,1)];

                [CI, stats] = bootci(1000, {@(x)[mean(x) std(x)], canon_vals}, 'type','norm');
                canonStruct{k}.canon.meanCI = [mean(canon_vals); CI(:,1)];
                k = k+1;
            end
    end
   
    % plot canon vs. nonCanon pairwise distances - Dorsal
    canonVals = [];
    nonCanonVals = [];
    pltNames = {}; 
    j = 1;
    for name = 1 : length(reorderNames)
        currInd = find(ismember(arrNames,reorderNames{name})==1);
        if contains(reorderNames{name},'-v') || contains(reorderNames{name},'-m')
            continue
        end
        nonCanonVals = [nonCanonVals canonStruct{currInd}.nonCanon.meanCI(1)];
        canonVals = [canonVals canonStruct{currInd}.canon.meanCI(1)];
        pltNames{j} = reorderNames{name}; 
        j = j+1;
    end

    % non-canonical to canonical ratio:
    ratios_dorsal = nonCanonVals./canonVals;
    names_dorsal = pltNames;


    % plot canon vs. nonCanon pairwise distances - Ventral
    canonVals = [];
    nonCanonVals = [];
    pltNames = {};
    j = 1;
    for name = 1 : length(reorderNames)
        currInd = find(ismember(arrNames,reorderNames{name})==1);
        if contains(reorderNames{name},'-d') || contains(reorderNames{name},'-m')
            continue
        end
        nonCanonVals = [nonCanonVals canonStruct{currInd}.nonCanon.meanCI(1)];
        canonVals = [canonVals canonStruct{currInd}.canon.meanCI(1)];
        pltNames{j} = reorderNames{name}; 
        j = j+1;
    end

    % non-canonical to canonical ratio:
    ratios_ventral = nonCanonVals./canonVals;
    names_ventral = pltNames;


    figure('Name','Ext. Data Fig. 3b - Noncanon ratios barplot', 'Position', [2 59 704 969]);
    jitter = randn(length(ratios_dorsal),1)*0.15;
    plot([0.75 1.25],ones(1,2)*mean(ratios_dorsal), 'r-', linewidth=3);
    hold on;
    x = jitter+1;
    plot(x, ratios_dorsal,'r.',markersize=30 );
    for itor = 1 : numel(names_dorsal)
        text(x(itor), ratios_dorsal(itor), names_dorsal{itor})
    end

    jitter = randn(length(ratios_ventral),1)*0.15;
    plot([1.75 2.25],ones(1,2)*mean(ratios_ventral), 'm-', linewidth=3);
    hold on;
    x = jitter+2;
    plot(x, ratios_ventral,'m.',markersize=30 );
    for itor = 1 : numel(names_ventral)
        text(x(itor), ratios_ventral(itor), names_ventral{itor})
    end

    xticks([1:2]);
    xticklabels({'Dorsal', 'Ventral'});
    fontsize(gcf,14,'points')
    ylim([0,1]);
    ylabel('Ratio between avg. pairwise neural distance');
    xlabel('Array set');
    exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig3b_NonCanonRatio_barplot_' cueName]);



%% Extended Data Figure 7 - Avg. Correlations per PCG region 
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 7\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Extended Data Figure 7 - Group-Averaged Correlations\n\n');

saveLoc = [save_dir 'ExtDataFig7' filesep];
mkdir(saveLoc);

% Define movement condition sets for each limb pair
Corr_resortedInds = {[38:45 22:29], [38:45 34:37 30:33], [22:29 18:21 14:17], [30:37 14:21],  };
Corr_resortedNames = {'R-L-Arms',       'R-Arm-Leg',        'L-Arm-Leg',        'R-L-Legs'};

% Reordering indices for homologous movements
subCorrMat_resortInds = {[1:8; 2 1 3 4 5 7 6 8], [1:8; 1:8], [1:8; 1:8], [1:8; 1 3 2 4 6 5 7 8]};

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
        c = load([data_dir MainFigsAnalysisFolder filesep datNames{d} filesep Dat.chanSetNames{chanSetIdx} 'Tuning_' cueName filesep 'Correlation.mat']);
        corrStack(:,:,itor) = c.corrMat;
        
        stacked_arrayIDs{itor} = Dat.chanSetNames{chanSetIdx};
        itor = itor + 1;
    end
end


setInds_corr = {find(ismember(stacked_arrayIDs, DorsalSet)), ...
                find(ismember(stacked_arrayIDs, MiddleSet)), ...
                find(ismember(stacked_arrayIDs, VentralSupSet)), ...
                find(ismember(stacked_arrayIDs, VentralInfSet))};

% Plot group-averaged correlation matrices
figure('Name','ExtDataFig7 - Avg. Correlations', 'Units','pixels', 'Position',[1 65 1728 963]);
setIndsToPlot = [1:4];
setNames = {'Dorsal PCG', 'Middle PCG', 'Superior-Ventral PCG', 'Inferior-Ventral PCG'};
plot_itor = 1;

for sets = 1:numel(setIndsToPlot) % iterate through each PCG region
    i = setIndsToPlot(sets);
    currMat = corrStack(:, :, setInds_corr{i});
    currMat(currMat < -1) = -1;
    currMat(currMat > 1) = 1;
    cMat = mean(currMat, 3);
    
    for sub_corr = 1 : numel(Corr_resortedNames) % iterate through 'R-L-Arms', 'R-L-Legs', 'R-Arm-Leg', 'L-Arm-Leg'

        subset = Corr_resortedInds{sub_corr};
        subplot(4,4, plot_itor);
        
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

        if ismember(plot_itor, [1, 5, 9, 13])
            ylabel(setNames{sets});
        end

        if ismember(plot_itor,[13:16])
            set(gca, 'XTick', 1:length(lbl_y), 'XTickLabels', lbl_y, 'XTickLabelRotation', 45, 'FontSize', 7);
            set(gca, 'YTick', 1:length(lbl_x), 'YTickLabels', lbl_x, 'FontSize', 7);
        else
            set(gca, 'XTick', []);
            set(gca, 'YTick', []);
        end
        set(gca, 'YDir', 'normal'); 

        if ismember(plot_itor, [1:4])
            title(Corr_resortedNames{sub_corr});
        end

        plot_itor = plot_itor + 1;
    end
end

exportPNGFigure(gcf, [saveLoc 'ExtDataFig7_AvgCorrelations_' cueName]);




%% Extended Data Figure 8a - Correlation Matrix
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 8\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Extended Data Fig. 8a - T12 control dataset correlation matrix\n\n');

optFlow_datLoc = [data_dir 'T12_control.mat']; % load control dataset for T12
T12_control = load(optFlow_datLoc); T12_control = T12_control.DataMat.neural;
% T12_control = load('/Users/Darrel/Documents/NPTL/Data/t12.2025.02.25/RedisMat/T12_2025_02_25_nspAligned/T12_opticalFlow_neural_trialState2.mat');
% T12_control = T12_control.DataMat;

saveDir = [save_dir 'ExtDataFig8']; mkdir(saveDir);
tmpDir = [saveDir filesep 'T12_control']; mkdir(tmpDir);

% {'Do Nothing             '} 1
% {'LEFT ANKLE - Down      '} 2
% {'LEFT ANKLE - Left      '} 3
% {'LEFT ANKLE - Right     '} 4
% {'LEFT ANKLE - Up        '} 5
% {'LEFT ARM - Raise Left  '} 6
% {'LEFT ARM - Raise Right '} 7
% {'LEFT HAND - Close      '} 8
% {'LEFT HAND - Open       '} 9
% {'LEFT LEG - Raise Left  '} 10
% {'LEFT LEG - Raise Right '} 11
% {'LEFT TOES - Curl       '} 12
% {'LEFT TOES - Open       '} 13
% {'LEFT WRIST - Down      '} 14
% {'LEFT WRIST - Left      '} 15
% {'LEFT WRIST - Right     '} 16
% {'LEFT WRIST - Up        '} 17
% {'RIGHT ANKLE - Down     '} 18
% {'RIGHT ANKLE - Left     '} 19
% {'RIGHT ANKLE - Right    '} 20
% {'RIGHT ANKLE - Up       '} 21
% {'RIGHT ARM - Raise Left '} 22
% {'RIGHT ARM - Raise Right'} 23
% {'RIGHT HAND - Close     '} 24
% {'RIGHT HAND - Open      '} 25
% {'RIGHT LEG - Raise Left '} 26
% {'RIGHT LEG - Raise Right'} 27
% {'RIGHT TOES - Curl      '} 28
% {'RIGHT TOES - Open      '} 29
% {'RIGHT WRIST - Down     '} 30
% {'RIGHT WRIST - Left     '} 31
% {'RIGHT WRIST - Right    '} 32
% {'RIGHT WRIST - Up       '} 33

% Initialize analysis structure
sDat = struct();
sDat.movementCodes = T12_control.trialCue; % the trial code for each trial needs to be accompanied by a goCue
sDat.movementNames = T12_control.cueList;
sDat.movementSets = {[22:25 30:33], [18:21 26:29],   [6:9 14:17],    [2:5 10:13]};
sDat.movementSetNames = {'R Arm',          'R Leg',       'L Arm',         'L Leg'};
sDat.doNothingCode = 1;

% TOGGLE FLAGS (modify to enable/disable analyses)
sDat.plotPSTHs = false; % will plot PSTHs for all movement sets
sDat.fullDistanceMatrix = false; % will compute the euclidean distances between each pair of movement conditions
sDat.withinGroupCorrelation = true; % will compute the correlations between each pair of movement conditions
sDat.plotBarPlots = false; % will compute the modulation strength for each movement condition
sDat.classifyAll = false; % will perform x-val naive bayes classification
sDat.perform_mPCA = false;  % Laterality analysis
sDat.mPCA_smoothWidth = 4;

% Define parameters
sDat.goTimes = T12_control.goCue; 
sDat.analysisWindow = [15, 50-1];
sDat.plottingWindow = [-50, 100];
sDat.binWidth = 0.02;

msFeat = T12_control.tx_blkMeanSub;

chanSet =     T12_control.chanSets{1};
chanSetName = T12_control.chanSetNames{1};
cueName = 'GoCue';

sDat.features = zscore(msFeat(:,chanSet));
sDat.saveDir = [tmpDir filesep chanSetName 'Tuning_' cueName];
sDat.chanSets = chanSet;
tuningAnalyses(sDat);

c = load([sDat.saveDir filesep 'Correlation.mat']);

% re-arrange condition order
Corr_resortedInds = {[1:8 17:24],                [9:16 25:32],                  [1:8 13:16 9:12 18 17 19:21 23 22 24 30 29 31 32 25 27 26 28]};
Corr_resortedNames = {'R-L-Arms',                'R-L-Legs',                    'Arm-Legs'};
subCorrMat_resortInds = {[1:8; 2 1 3 4 5 7 6 8], [5:8 1:4; 6 5 7 8 1 3 2 4],     [1:16; 1:16]};

RA = [1:8];
RL = [9:16];
LA = [17:24];
LL = [25:32];
Arm_leg_vals_inds = [RA LA RA LA;...
                     RL LL LL RL];

corr_data = {};
sigArray = [];
pArray = [];
for sub_corr = 1 : numel(Corr_resortedInds)
    subset = Corr_resortedInds{sub_corr};
    cMat = c.corrMat(subset,subset);

    % plot whole confusion matrix
    currMat = figure('Name', 'Ext. Data Fig. 8a - Correlation matrix', 'Units','normalized','Position',[0.3171    0.2354    0.5322    0.6573]);
    imagesc(cMat,[-1,1]);
    axis square;
    colormap(flipud(redblue));
    colorbar;
    set(gca,'XTick',1:length(c.mvNames(subset)),'XTickLabels',c.mvNames(subset),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(c.mvNames(subset)),'YTickLabels',c.mvNames(subset));
    set(gca,'YDir','normal');

    % Now sub-correlations
    % take sub-correlation matrix
    indsTake_Y = ((length(subset)/2)+1):1:length(subset);
    indsTake_X = 1:(length(subset)/2);
    subMat = cMat(indsTake_X,indsTake_Y);

    % re-order indicies to account for laterality of the body
    % (e.g., align right-wrist right to left-wrist left
    currReorderInds_X = subCorrMat_resortInds{sub_corr}(1,:);
    currReorderInds_Y = subCorrMat_resortInds{sub_corr}(2,:);

    subMat_reorder = subMat(currReorderInds_X, currReorderInds_Y);
    mvNames = c.mvNames(subset);
    lbl_x = {mvNames{currReorderInds_X}};
    lbl_y = {mvNames{currReorderInds_Y + numel(lbl_x)}};

    figure('Units','normalized','Position',[0.3171    0.2354    0.5322    0.6573]);
    imagesc(subMat_reorder,[-1,1]);
    axis square;
    colormap(flipud(redblue));
    colorbar;

    set(gca,'XTick',1:length(lbl_y),'XTickLabels',lbl_y,'XTickLabelRotation',45);
    set(gca,'YTick',1:length(lbl_x),'YTickLabels',lbl_x);
    set(gca,'YDir','normal');

    exportPNGFigure(gcf, [tmpDir filesep 'CorrSubSetReordered_' Corr_resortedNames{sub_corr}]);

    % get diag values and off-diag values
    subMat = subMat_reorder;
    diag_vals = diag(subMat);

    if sub_corr == 3
        subMat = cMat;
        diag_vals = [];
        for z = 1 : size(Arm_leg_vals_inds,2)
            diag_vals = [diag_vals cMat(Arm_leg_vals_inds(1,z),Arm_leg_vals_inds(2,z))];
        end
    end

    corr_data{sub_corr,1} = diag_vals;

    [h, p] = ttest(diag_vals);
    isSig = h;
    pArray = [pArray p];

    sigArray = [sigArray isSig];
    fprintf('Significant = %d, p_val = %f\n', isSig, p);
end

figure(currMat);
title('T12-V1');
colbar = colorbar;
colbar.Label.String = 'Correlation';
exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig8a_CorrelationMatrix']);


figure('Units','normalized','Position',[0 0.61 0.18 0.32]);
barCols = parula(3);             
p = [];
for k = 1 : size(corr_data,1)
    xInd = k;
    
        for j = 1 : 1
            dat = corr_data{k,j};

            [CI, stats] = bootci(1000, {@(x)[mean(x) std(x)], dat}, 'type','norm');
            jitter = rand(length(dat),1)*0.1;
            p(j) = bar(xInd(j), mean(dat),0.8, 'LineWidth',1,'FaceColor',barCols(k,:));
            hold on;
            plot(xInd(j)+jitter, dat,'ko','MarkerSize',10);
        end
end
xticks([1:3]);
xticklabels(Corr_resortedNames);
xtickangle(45);
ylabel('Correlation');

exportPNGFigure(gcf, [saveDir filesep 'ExtDataFig8b_CorrelationBarPlots' '_GoCue']);



%% Extended Data Figure 8c - Optical Flow Movement Analysis for T12
optFlow_datLoc = [data_dir 'T12_control.mat']; % load control dataset for T12
load(optFlow_datLoc);

goCues = DataMat.opticalFlow.goCue;
trialCues = DataMat.opticalFlow.trialCue;
opticalFlow = DataMat.opticalFlow.opticalFlow;

numTrials = length(goCues);
mean_rh_per_trial = zeros(1, numTrials);
mean_lh_per_trial = zeros(1, numTrials);
mean_rl_per_trial = zeros(1, numTrials);
mean_ll_per_trial = zeros(1, numTrials);

for i = 1:numTrials
    if i < numTrials
        % Define the window for all trials except the last one
        start_idx = round((goCues(i) + goCues(i+1)) / 2); % Midpoint
        end_idx = round(goCues(i+1)); % End at next beep
    else
        % Define the window for the last trial (extends to end of data)
        start_idx = round((goCues(i-1) + goCues(i)) / 2); % Midpoint of last transition
        end_idx = length(opticalFlow(:,1)); % Until end
    end
    
    % Ensure indices are within bounds
    start_idx = max(start_idx, 1);
    end_idx = min(end_idx, length(opticalFlow(:,1)));
    
    % Compute peak optical flow within the window
    mean_rh_per_trial(i) = mean(opticalFlow(start_idx:end_idx, 1));
    mean_lh_per_trial(i) = mean(opticalFlow(start_idx:end_idx, 2));
    mean_rl_per_trial(i) = mean(opticalFlow(start_idx:end_idx, 3));
    mean_ll_per_trial(i) = mean(opticalFlow(start_idx:end_idx, 4));
end

meanOptFlowMat = [mean_rh_per_trial; mean_lh_per_trial; mean_rl_per_trial; mean_ll_per_trial]';

% ========== CREATE BAR PLOTS ==========
% Define movement conditions
RH = [30:33]; % Right wrist movement conditions
LH = [14:17]; % left wrist movement conditions
RL = [18:21]; % right ankle movement conditions
LL = [2:5]; % left ankle movement conditions
Nothing = 1; % rest movement condition
effectors = {RH, LH, RL, LL, Nothing};
effectorNames = {'Right Wrist', 'Left Wrist', 'Right Ankle', 'Left Ankle', 'Do Nothing'};

barDat = {};

optFlowFig = figure('Name', 'Ext. Data Fig. 8c - Avg. Optical Flow', 'Position',[280.00 634.00 289.00 313.00]);
barCols = parula(5);

for eff = 1 : 4 % for each effector
    
    cDat = {};
    CI_mat = [];
    p = [];
    
    subplot(2, 2, eff);
    ylims_plotting = [2.5 2 2 1.25];
    for compare_eff = 1 : numel(effectors) % for each movement set
        curr_inds = find(ismember(trialCues, effectors{compare_eff}) == 1); % trial inds of the current effector compare group
        currDat = meanOptFlowMat(curr_inds, eff); % get the corresponding trials for eff
        cDat{compare_eff} = currDat;
        
        % compute the mean and CIs for each bar
        [CI, stats] = bootci(100000, {@(x)[mean(x)], currDat}, 'type', 'norm');
        CI_mat = [CI_mat [CI(1) mean(currDat) CI(2)]'];
        
        % plot current bar
        dat = currDat;
        p = bar(compare_eff, mean(dat), 0.8, 'LineWidth', 1, 'FaceColor', barCols(compare_eff, :), 'FaceAlpha', 0.8);
        p.EdgeColor = 'none';

        hold on;

        % plot scatter
        jitter = randn(length(dat),1)*0.1;
        scatter(jitter+compare_eff, dat,1.5,[1 1 1]*0.4,'filled');

        errorbar(compare_eff, mean(dat), CI(1,1) - mean(dat), CI(2,1) - mean(dat), 'k', 'LineWidth', 1);
        ylim([0 ylims_plotting(eff)]);
    end
    title([effectorNames{eff} ' movement']);
    xticks([1:5]);
    xticklabels(effectorNames);
    
    barDat{eff}.vals = cDat;
    barDat{eff}.CIs = CI_mat;
end
subplot(2,2,1); ylabel('Avg. Optical Flow (a.u.)');

% save figure
saveDir = [save_dir 'ExtDataFig8' filesep];
mkdir(saveDir);
exportPNGFigure(gcf, [saveDir 'ExtDataFig8c_AvgOptFlow']);



%% Extended Data Figure 9 - Single Trial PCA projections for right and left arm movements
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 9\n');
fprintf('*******************************************************************************\n\n');

fprintf('Generating Extended Data Figure 9 - Laterality Projections\n');

latSetName = 'Arms';
plotScatter = {'T5-d1',  'C1-d1',  'T16-d1', 'C2-d2',  'T17-d1', ...
               'T5-d2',  'C1-d2',  'T16-d2', 'T11-d1', 'T17-d2',...
               'T15-v1', 'T15-v2', 'T15-v3', 'T16-v1', 'T15-m1',...
               'T12-v1', 'T12-v2', 'T17-v1', 'T17-v2', 'T16-m1'};

scatter_projections = figure('Name','ExtDataFig9 - Single Trial Projections of Right/Left Arm Movements', 'Position',[1 65 1728 963]);
plot_itor = 1;

% Iterate through each array
for array = 1:numel(plotScatter)
    participant = strtok(plotScatter{array}, '-');
    
    % Load mPCA output for this array
    mPCA_out_dir = [data_dir MainFigsAnalysisFolder filesep participant filesep plotScatter{array} 'Tuning_' cueName filesep 'Laterality_' latSetName filesep 'mPCA_out.mat'];
    load(mPCA_out_dir);
    
    % Compute marginalized variance
    cmv = mPCA_out.explVar.totalMarginalizedVar;
    cmv = cmv ./ sum(cmv, 2);
    
    % Plot for selected arrays
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
    subplot(4, 5, plot_itor); 
    hold on;
    scatter(proj(indsR,1), proj(indsR,2), 30, [208 55 56]./255, 'filled');
    scatter(proj(indsL,1), proj(indsL,2), 30, [37 33 117]./255, 'filled');
    if plot_itor == 20
        legend('Right arm', 'Left arm');
        xlabel('PC1');
        ylabel('PC2');
    end
    title(plotScatter{array});
    axis([-8 8 -8 8]);
    axis square;
    plot_itor = plot_itor + 1;
end

saveDir = [save_dir 'ExtDataFig9' filesep];
mkdir(saveDir);

exportPNGFigure(gcf, [saveDir 'ExtDataFig9_PCA_Projections_' cueName]);


%% Extended Data Figure 10 - Neural decoder sweeps Analysis
fprintf('\n\n*******************************************************************************\n');
fprintf('                           EXTENDED DATA FIGURE 10\n');
fprintf('*******************************************************************************\n\n');

fprintf('Performing Decoder Sweep for Extended Data Figure 10\n');

saveLoc = [save_dir 'ExtDataFig10' filesep 'DecoderSweeps/']; mkdir(saveLoc);

participantWindowWidths = {{[-0.5 1.5], [-0.5 3], [0 0.2]},... %T5
                           {[-0.5 2],   [-0.5 2.5],   [0 0.2]}, ... % T12
                           {[-0.5 2],   [-0.5 3], [0 0.2]}, ... % T11
                           {[-0.5 3],   [-0.5 4.5], [0 0.2]}, ... % C1
                           {[-0.5 2],   [-0.5 4.5], [0 0.2]}, ... % C2
                           {[-0.5 1.5], [-0.5 5.5], [0 0.2]}, ... % T15
                           {[-0.5 2],   [-0.5 4], [0 0.2]},... % T16
                           {[-0.5 2.5], [-0.5 4.5], [0 0.2]}}; % T17

slidingWindow = [0 4]; % 100 ms window for 20-ms binned data
windowWidth = slidingWindow(2)-slidingWindow(1) + 1;
for event = 1 : 3
    for d = 1 : numel(datNames)
        currP_Windows = participantWindowWidths{d};

        Dat = load([data_dir datNames{d} '.mat']);
        Dat = Dat.DataMat;

        out = getEventCueIndices(Dat.state, datNames{d});

        tx = Dat.tx_blkMeanSub;
        msFeat = [tx.*50]; % T x Chans
        msFeat = (msFeat - nanmean(msFeat,1))./nanstd(msFeat,1); % z-score feats

        % throw NaN features
        tmp = sum(isnan(msFeat),1);
        indsThrow = find(tmp == size(msFeat,1));
        indsKeep = find(tmp ~= size(msFeat,1));

        movSets = movSets_Regular;
        if d == C1
            movSets = movSets_C1;
        end

        trialCues = Dat.trialCue;

        movementSets = {movSets{2:end}};
        cueList = Dat.cueList;

        sDat.movementCodes = trialCues;
        sDat.movementNames = cueList;
        sDat.movementSets = movementSets;
        sDat.movementSetNames = {'Speech','Face','Head','LeftLeg','LeftArm','RightLeg','RightArm'};
        sDat.doNothingCode = 1;

        sDat.binWidth = 0.02;

        for chanSetIdx = 1:numel(Dat.chanSets)
            % Skip arrays not in analysis list
            if contains(Dat.chanSetNames{chanSetIdx}, 'Sorted')
                continue;
            end
            
            fprintf('\n Currently Running Decoder Sweep for : %s   %s  \n' , datNames{d}, Dat.chanSetNames{chanSetIdx});

            channels = Dat.chanSets{chanSetIdx};
            channels = channels(ismember(channels,indsKeep));

            sDat.chanSets = Dat.chanSets{chanSetIdx};
            sDat.saveDir = [saveLoc Dat.chanSetNames{chanSetIdx}];

            msFeat_curr = msFeat(:,channels);

            sDat.features = msFeat_curr;

            %classification across all classes
            sortedSetIdx = horzcat(sDat.movementSets{:});
            sortedSetIdx = [sortedSetIdx, sDat.doNothingCode];

            window = currP_Windows{event};

            eventCues = [];
            eventCueName = '';
            if event == 1
                fprintf('On presentCue\n');
                eventCueName = 'presentCue';
                eventCues = out.presentCue;
                currMvCodes = trialCues;
                currMvCodes(out.indsThrowTrlCodes_forPresent) = [];
                sDat.movementCodes = currMvCodes;
                eventCues(out.indsThrowTrlCodes_forPresent) = [];
            elseif event == 2
                fprintf('On goCue\n');
                eventCueName = 'goCue';
                eventCues = out.goCue;
                currMvCodes = trialCues;
                currMvCodes(out.indsThrowTrlCodes_forGo) = [];
                sDat.movementCodes = currMvCodes;
                eventCues(out.indsThrowTrlCodes_forGo) = [];
            else
                fprintf('On returnCue\n');
                eventCueName = 'returnCue';
                eventCues = out.returnCue;
                currMvCodes = trialCues;
                currMvCodes(out.indsThrowTrlCodes_forReturn) = [];
                sDat.movementCodes = currMvCodes;
                eventCues(out.indsThrowTrlCodes_forReturn) = [];

                if strcmp(datNames{d},'T17')
                    currMvCodes = trialCues;
                    currMvCodes(out.indsThrowTrlCodes_forPresent) = [];
                    sDat.movementCodes = currMvCodes;
                end
            end

            sDat.goTimes = eventCues;

            DecodingAccuracy = [];
            DecodingCI = [];

            window = window/0.02;
            window = window(1):2:window(2);

            for windowInd = 1 : numel(window)
                % fprintf('Window %d of %d\n', windowInd, numel(window));

                sDat.analysisWindow =  slidingWindow + window(windowInd);
                mvCodes = sDat.movementCodes;
                windowStart = sDat.goTimes+sDat.analysisWindow(1);

                indsNoGo = find(windowStart < 1);

                indsNoGo_2 = find(windowStart+windowWidth > size(sDat.features,1));
                indsNoGo = [indsNoGo indsNoGo_2];

                windowStart(indsNoGo) = [];
                mvCodes(indsNoGo) = [];

                [ C, L, ~, binoCI ] = simpleClassify_BinSweeps( sDat.features, mvCodes, windowStart, sDat.movementNames, ...
                    sDat.analysisWindow(2)-sDat.analysisWindow(1), 1, 1, false,sortedSetIdx  );

                DecodingAccuracy(windowInd) = (1-L);
                DecodingCI(windowInd,:) = binoCI';
            end

            timeWindowStart_s = window*0.02;
            % save Decoding Accuracy sweep for this array
            mkdir(sDat.saveDir);
            save([sDat.saveDir filesep 'DecodingAccuracy_sweep_' eventCueName], 'DecodingAccuracy','timeWindowStart_s', 'DecodingCI');
        end
    end
end

%% Extended Data Figure 10 - Decoder Sweep Plots
fprintf('Generating Extended Data Figure 10 - Decoder Sweeps\n');

topDir = [save_dir 'ExtDataFig10' filesep 'DecoderSweeps/'];

matNamesTake = {'DecodingAccuracy_sweep_presentCue', 'DecodingAccuracy_sweep_goCue','DecodingAccuracy_sweep_returnCue'};
cols = parula(6)*0.7;

% arrayNames = {'C1-d1','C1-d2','C2-d1','C2-d2','T5-d1','T5-d2','T11-d1','T11-d2','T16-d1','T16-d2','T16-m1','T16-v1','T15-m1','T15-v1','T15-v2','T15-v3','T12-v1','T12-v2'};
M = numel(datNames);
N = 3;

ylims = {[0 0.5], [0 0.45], [0 0.3], [0 0.35], [0 0.2], [0 0.35], [0 0.25], [0 0.2]};
blackBars = {{[0],[0 1.5],[0]},...
             {[0],[0 1],  [0]},...
             {[0],[0 1.5],[0]},...
             {[0],[0 1.5],[0]},...
             {[0],[0 1.5],[0]},...
             {[0],[0 2.5],[0]},...
             {[0],[0 2.5],[0]},...
             {[0],[0 2.5],[0]}};

eventWindows = {[-0.5 3],[-0.5 5.5],[0 0.2]};

figure('Position',[0 56 865 972]);    
for d = 1 : numel(datNames)

    Dat = load([data_dir datNames{d} '.mat']);
    Dat = Dat.DataMat;

    currBlkBars = blackBars{d};
    for event = 1 : 2

        blkBars = currBlkBars{event};

        subplot(M,N,event + 3*(d-1))

        lgnd = []; 
        names = {};
        for chanSetIdx = 1:numel(Dat.chanSets)
            % Skip arrays not in analysis list
            if contains(Dat.chanSetNames{chanSetIdx}, 'Sorted')
                continue;
            end

            names{chanSetIdx} = Dat.chanSetNames{chanSetIdx};

            dirTake = [topDir Dat.chanSetNames{chanSetIdx} filesep];

            tmpDat = load([dirTake matNamesTake{event} '.mat']);

            vals = tmpDat.DecodingAccuracy; % Nx1
            valsbottom = tmpDat.DecodingCI(:,1); % Nx1
            valstop = tmpDat.DecodingCI(:,2); % Nx1

            % plot
            time = tmpDat.timeWindowStart_s;
            currCI = [valsbottom' ; valstop'];

            lgnd(chanSetIdx) = plot(time, vals, '-','Color',cols(chanSetIdx,:),'MarkerFaceColor',cols(chanSetIdx,:),'LineWidth',1);
            hold on;
            fhandle = errorPatch(time', currCI', cols(chanSetIdx,:),0.2);
            dashTime = eventWindows{event};
            dashTime = dashTime(1):0.5:dashTime(2);
            plot(dashTime, (1/46)*ones(size(dashTime)),'k--','LineWidth',1);

            ylim([0 0.5]);
            if event == 1
                ylabel(datNames{d});
            end
            set(gca,'FontSize',7);
            xlim(eventWindows{event});

            for b = 1 : numel(blkBars)
                ys = linspace(0,0.5,100);
                plot(blkBars(b)*ones(size(ys)), ys,'k-','LineWidth',2);
            end

            if event ~= 1
                yticks([]);
            end

            if d ~= numel(datNames)
                xticks([]);
            end

            if event == 3
                axis off;
            end

        end
        
        if event == 1
                legend(lgnd,names,'FontSize',7,'Location','best', 'Box', 'off');
        end

        if (d==1) & (event==1)
            title('Present Cue');
        elseif (d==1) & (event==2)
            title('Go and Return Cues');
        end

        if d==numel(datNames)
            xlabel('Time (s)');
        end

    end

end

saveDir = [save_dir 'ExtDataFig10' filesep];
mkdir(saveDir);

exportPNGFigure(gcf, [saveDir 'ExtDataFig10_DecoderSweeps_' cueName]);
