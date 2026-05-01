function ret = tuningAnalyses(sDat)
    mkdir(sDat.saveDir); % create the save directory
    ret = []; % initialize the return struct

    if isfield(sDat,'plotPSTHs')
        plotPSTHs = sDat.plotPSTHs;
    else
        plotPSTHs = false;
    end

    if isfield(sDat,'plotBarPlots')
        plotBarPlots = sDat.plotBarPlots;
    else
        plotBarPlots = false;
    end
    
    if isfield(sDat, 'perform_mPCA')
        perform_mPCA = sDat.perform_mPCA;
    else
        perform_mPCA = false;
    end

    if isfield(sDat,'plottingWindow')
        plottingWindow = sDat.plottingWindow;
        binWidth = sDat.binWidth;
    else
        plottingWindow = [-100 150];
        binWidth = 0.02;
    end
    
    if isfield(sDat,'analysisWindow')
        analysisWindow = sDat.analysisWindow;
    else
        analysisWindow = [10 65];
    end

    if isfield(sDat,'fullDistanceMatrix')
        fullDistanceMatrix = sDat.fullDistanceMatrix;
    else
        fullDistanceMatrix = false;
    end

    if isfield(sDat,'withinGroupCorrelation')
        withinGroupCorrelation = sDat.withinGroupCorrelation;
    else
        withinGroupCorrelation = false;
    end
    
    if isfield(sDat,'classifyAll')
        classifyAll = sDat.classifyAll;
    else
        classifyAll = false;
    end

    if isfield(sDat,'gaussSmoothWidth')
        gaussSmoothWidth = sDat.gaussSmoothWidth;
    else
        gaussSmoothWidth = 6;
    end

    if isfield(sDat,'distancePlot') % to supress neural distance plots
        distancePlot = sDat.distancePlot;
    else
        distancePlot = true;
    end

    sortedSetIdx = horzcat(sDat.movementSets{:});
    sortedSetIdx = [sortedSetIdx, sDat.doNothingCode];

    %% PSTHs
    if plotPSTHs
        fprintf('******* Computing PSTHs \n\n');

        smoothFeat = gaussSmooth_fast(sDat.features, gaussSmoothWidth); % smooth features
        for setIdx=1:length(sDat.movementSets) % iterate through each movement set
            mkdir([sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx}]); % create directory to store results from current movement set

            colors = jet(length(sDat.movementSets{setIdx}))*0.8; % colormap
            nPages = ceil(size(sDat.features,2)/64); % define number of pages to create to plot all channels in groups of 64
            featIdx = 1:64;
            for pageIdx=1:nPages
                figure('Units','Normalized','Position',[0    0.0463    1.0000    0.8667]);
                for f=1:length(featIdx)
                    if featIdx(f)>size(sDat.features,2)
                        continue;
                    end

                    subplot(8,8,f);
                    hold on;

                    ms = sDat.movementSets{setIdx};
                    for m=1:length(ms)
                        trlIdx = find(sDat.movementCodes==ms(m));
                        [ concatDat ] = triggeredAvg( smoothFeat(:,featIdx(f)), sDat.goTimes(trlIdx), plottingWindow );

                        timeAxis = (plottingWindow(1):plottingWindow(2))*binWidth;
                        plot(timeAxis, nanmean(concatDat),'Color',colors(m,:),'LineWidth',1);

                        [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                        fHandle = errorPatch( timeAxis', MUCI', colors(m,:), 0.2 );
                    end
                    xlim([timeAxis(1), timeAxis(end)]);
                    plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);

                    title(featIdx(f));
                    if f>=57
                        xlabel('Time (s)');
                    end
                    if mod(f-1,8)==0
                        ylabel('Rate (Hz)');
                    end
                end

                exportPNGFigure(gcf, [sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx} filesep 'psth_' num2str(pageIdx) '_' sDat.movementSetNames{setIdx}] );
                close all;

                featIdx = featIdx + length(featIdx);
            end

            %PSTH legend
            figure('Units','Normalized','Position',[0.3171    0.3833    0.1525    0.5094]);
            hold on;
            for m=1:length(ms)
                plot([0,1],[0,1],'-','Color',colors(m,:),'LineWidth',2);
            end
            xlim([2 3]); ylim([2 3]);
            axis off;
            legend(sDat.movementNames(sDat.movementSets{setIdx}));
            exportPNGFigure(gcf, [sDat.saveDir filesep 'psth_' sDat.movementSetNames{setIdx} filesep 'legend']);
        end
    end


%% MODULATION STRENGTH
    if plotBarPlots
        fprintf('******* Computing modulation strength \n\n');

        %bar plots
        codeList = unique(sDat.movementCodes);
        nCodes = length(codeList);

        timeWindow = analysisWindow;
        nothingTrlIdx = find(sDat.movementCodes==sDat.doNothingCode);
        doNothingModulation = triggeredAvg( sDat.features, sDat.goTimes(nothingTrlIdx), timeWindow );
        doNothingModulation = squeeze(mean(doNothingModulation,2));

        modulationMagnitude = zeros(nCodes, 3);
        for movIdx=1:nCodes
            classTrlIdx = find(sDat.movementCodes==codeList(movIdx));
            classModulation = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
            classModulation = squeeze(mean(classModulation,2));

            subtractMean = false;
            CImode = 'jackknife';
            [ euclideanDistance, squaredDistance, CI, CIDistribution ] = ...
                cvDistance( doNothingModulation, classModulation, subtractMean, CImode );

            modulationMagnitude(movIdx,:) = [euclideanDistance, CI(:,1)'];
        end

        %normalize by number of electrodes
        nChan = size(sDat.features,2);
        modulationMagnitude = modulationMagnitude / sqrt(nChan);

        %colored bar plot sorted by movement set
        sortedSetIdx = horzcat(sDat.movementSets{:});
        sortedSetIdx = [sortedSetIdx, sDat.doNothingCode];

        modMag_sorted = modulationMagnitude(sortedSetIdx(1:(end-1)),:);
        movLabels_sorted = sDat.movementNames(sortedSetIdx(1:(end-1)));

        colorIdx = [];
        for setIdx=1:length(sDat.movementSets)
            colorIdx = [colorIdx, zeros(1,length(sDat.movementSets{setIdx}))+setIdx];
        end

        boxColors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;
        boxColors = [boxColors; 0.8*[0.2667    0.8000    0.5333]; 0.8*[0    0.5333    0.8000]; lines(5)];

        figure('Units','normalized','Position',[0.0773    0.6213    0.6638    0.2809]);
        hold on;
        for m=1:size(modMag_sorted,1)
            bar(m,modMag_sorted(m,1),'FaceColor',boxColors(colorIdx(m),:));
            errorbar(m,modMag_sorted(m,1),modMag_sorted(m,1)-modMag_sorted(m,2), modMag_sorted(m,3)-modMag_sorted(m,1),'Color','k');
        end

        setInds = [];
        for setNum = 1 : numel(sDat.movementSets)
            setInds = [setInds setNum*ones(1,length(sDat.movementSets{setNum}))];
        end

        for setNum = 1: numel(sDat.movementSets)
            currInds = find(setInds == setNum);
            currVals = modMag_sorted(currInds,1);
            meanVal = mean(currVals);
            plot(currInds, meanVal*ones(size(currInds)),'-','LineWidth',3,'color',boxColors(colorIdx(currInds(1)),:));
        end

        ylabel('Modulation (Hz)');
        xlim([0,length(sDat.movementNames(sortedSetIdx))-0.3]);
        ylim([0 1]);
        set(gca,'XTick',1:length(sDat.movementNames(sortedSetIdx)),'XTickLabels',sDat.movementNames(sortedSetIdx),'XTickLabelRotation',45);

        exportPNGFigure(gcf, [sDat.saveDir filesep 'barPlot']);
        close(gcf);

        % save bar plot data
        save([sDat.saveDir filesep 'modMag_sorted'],'modMag_sorted','movLabels_sorted');

    end


%% PAIRWISE DISTANCES
    if fullDistanceMatrix
        fprintf('******* Computing pair-wise neural distances \n\n');
        nChan = size(sDat.features,2);
        timeWindow = analysisWindow;
        codeList = unique(sDat.movementCodes);
        nCodes = length(codeList);

        distanceMatrix = zeros(nCodes, nCodes);
        insignificanceMatrix = zeros(nCodes, nCodes);
        for c1=1:nCodes
            classTrlIdx = find(sDat.movementCodes==codeList(c1));
            classModulation1 = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
            classModulation1 = squeeze(mean(classModulation1,2));

            for c2=1:nCodes
                classTrlIdx = find(sDat.movementCodes==codeList(c2));
                classModulation2 = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
                classModulation2 = squeeze(mean(classModulation2,2));

                subtractMean = false;
                CImode = 'jackknife';
                [ euclideanDistance, squaredDistance, CI, CIDistribution ] = ...
                    cvDistance( classModulation1, classModulation2, subtractMean, CImode );

                distanceMatrix(c1, c2) = euclideanDistance/sqrt(nChan);
                if CI(1)<0
                    insignificanceMatrix(c1, c2) = 1;
                end
            end
        end

        distanceMatrix = distanceMatrix(sortedSetIdx, sortedSetIdx);
        insignificanceMatrix = insignificanceMatrix(sortedSetIdx, sortedSetIdx);

        if distancePlot
            figure('Units','normalized','Position',[0.3171    0.2354    0.5322    0.6573]);
            hold on;
            imagesc(distanceMatrix);
            colormap(flipud(cool));
            colorbar;

            boxColors = [173,150,61;
                119,122,205;
                91,169,101;
                197,90,159;
                202,94,74]/255;
            boxColors = [boxColors; 0.8*[0.2667    0.8000    0.5333]; 0.8*[0    0.5333    0.8000]; lines(5)];

            currentIdx = 0;
            currentColor = 1;
            for c=1:length(sDat.movementSets)
                newIdx = currentIdx + (1:length(sDat.movementSets{c}))';
                rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],...
                    'LineWidth',5,'EdgeColor',boxColors(currentColor,:));
                currentIdx = currentIdx + length(sDat.movementSets{c});
                currentColor = currentColor + 1;
            end

            for c1=1:size(distanceMatrix,1)
                for c2=1:size(distanceMatrix,2)
                    if insignificanceMatrix(c1, c2)
                        plot(c2, c1, 'kx', 'MarkerSize', 14);
                    end
                end
            end

            set(gca,'YDir','normal');
            set(gca,'XTick',1:length(sDat.movementNames(sortedSetIdx)),'XTickLabels',sDat.movementNames(sortedSetIdx),'XTickLabelRotation',45);
            set(gca,'YTick',1:length(sDat.movementNames(sortedSetIdx)),'YTickLabels',sDat.movementNames(sortedSetIdx));

            title('Pairwise Neural Distances');
            set(gca,'FontSize',7);

            exportPNGFigure(gcf, [sDat.saveDir filesep 'distanceMatrix']);
            close(gcf);
        end
        
        %SNR for each movement set
        sortedSetIdx = horzcat(sDat.movementSets{:});
        sortedSetIdx = [sortedSetIdx, sDat.doNothingCode];

        setwiseAvgDistances = zeros(length(sDat.movementSets),1);
        for setIdx=1:length(sDat.movementSets)
            [~,tmpIdx] = ismember(sDat.movementSets{setIdx}, sortedSetIdx);
            subMatrix = distanceMatrix(tmpIdx, tmpIdx);

            offDiagonalVals = [];
            for r=1:size(subMatrix,1)
                for c=(r+1):size(subMatrix,2)
                    offDiagonalVals = [offDiagonalVals, subMatrix(r,c)];
                end
            end
            setwiseAvgDistances(setIdx) = mean(offDiagonalVals);
        end

        sortedNames = sDat.movementNames(sortedSetIdx);
        setNames = sDat.movementSetNames;
        save([sDat.saveDir filesep 'neuralDistances'],'distanceMatrix','sortedNames','setwiseAvgDistances','setNames','insignificanceMatrix');

        ret.distanceMatrix = distanceMatrix;
        ret.distanceMatrix_sortedNames = sortedNames;
    end

%% CORRELATIONS
    %within-group correlation
    if withinGroupCorrelation
        fprintf('******* Computing pair-wise neural correlations \n\n');
        timeWindow = analysisWindow;
        codeList = unique(sDat.movementCodes);
        nCodes = length(codeList);

        mSetMeans = zeros(length(sDat.movementSets), size(sDat.features,2));
        for m=1:length(sDat.movementSets)
            classTrlIdx = find(ismember(sDat.movementCodes, sDat.movementSets{m}));
            classModulation1 = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
            classModulation1 = squeeze(mean(classModulation1,2));
            mSetMeans(m,:) = mean(classModulation1,1);
        end

        mSetIdx = zeros(length(codeList),1);
        for c=1:length(codeList)
            for m=1:length(sDat.movementSets)
                if ismember(c, sDat.movementSets{m})
                    mSetIdx(c) = m;
                    break;
                end
            end
        end

        corrMat = zeros(nCodes, nCodes);
        for c1=1:nCodes
            classTrlIdx = find(sDat.movementCodes==codeList(c1));
            classModulation1 = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
            classModulation1 = squeeze(mean(classModulation1,2));
            if mSetIdx(c1)>0
                classModulation1 = classModulation1 - mSetMeans(mSetIdx(c1),:);
            end

            for c2=1:nCodes
                classTrlIdx = find(sDat.movementCodes==codeList(c2));
                classModulation2 = triggeredAvg( sDat.features, sDat.goTimes(classTrlIdx), timeWindow );
                classModulation2 = squeeze(mean(classModulation2,2));
                if mSetIdx(c2)>0
                    classModulation2 = classModulation2 - mSetMeans(mSetIdx(c2),:);
                end

                CImode = 'none';
                [ cvCorrEst, CI ] = cvCorr( classModulation1, classModulation2, CImode );
                corrMat(c1, c2) = cvCorrEst;
            end
        end

        corrMat = corrMat(sortedSetIdx, sortedSetIdx);

        figure('Units','normalized','Position',[0.3171    0.2354    0.5322    0.6573]);
        hold on;
        imagesc(corrMat,[-1 1]);
        colormap(flipud(redblue));
        colorbar;

        boxColors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;
        boxColors = [boxColors; 0.8*[0.2667    0.8000    0.5333]; 0.8*[0    0.5333    0.8000]; lines(5)];

        currentIdx = 0;
        currentColor = 1;
        for c=1:length(sDat.movementSets)
            newIdx = currentIdx + (1:length(sDat.movementSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],...
                'LineWidth',5,'EdgeColor',boxColors(currentColor,:));
            currentIdx = currentIdx + length(sDat.movementSets{c});
            currentColor = currentColor + 1;
        end

        set(gca,'YDir','normal');
        set(gca,'XTick',1:length(sDat.movementNames(sortedSetIdx)),'XTickLabels',sDat.movementNames(sortedSetIdx),'XTickLabelRotation',45);
        set(gca,'YTick',1:length(sDat.movementNames(sortedSetIdx)),'YTickLabels',sDat.movementNames(sortedSetIdx));

        title('Pairwise Neural Correlations');
        if size(corrMat,1)>80
            set(gca,'FontSize',5);
        elseif size(corrMat,1)>60
            set(gca,'FontSize',7);
        end

        exportPNGFigure(gcf, [sDat.saveDir filesep 'corrMatrix']);
        close(gcf);

        % save correlation matrix 
        mvNames = sDat.movementNames(sortedSetIdx);
        save([sDat.saveDir filesep 'Correlation'],'corrMat','mvNames');
    end
    
    %% LINEAR CLASSIFIER
    %classification across all classes
    if classifyAll
        fprintf('******* Performing classification (Naive Bayes)\n\n');

        % DRD EDIT - Trim trials that go over the limit
        windowWidth = analysisWindow(2)-analysisWindow(1) + 1;
        mvCodes = sDat.movementCodes;
        windowStart = sDat.goTimes+sDat.analysisWindow(1);
        indsNoGo = find(windowStart < 1);

        indsNoGo_2 = find(windowStart+windowWidth > size(sDat.features,1));
        indsNoGo = [indsNoGo indsNoGo_2];

        windowStart(indsNoGo) = [];
        mvCodes(indsNoGo) = [];

        [ C, L, ~, binoCI ] = simpleClassify( sDat.features, mvCodes, windowStart, sDat.movementNames, ...
            analysisWindow(2)-analysisWindow(1), 1, 1, true,sortedSetIdx  );

        boxColors = [173,150,61;
            119,122,205;
            91,169,101;
            197,90,159;
            202,94,74]/255;
        boxColors = [boxColors; 0.8*[0.2667    0.8000    0.5333]; 0.8*[0    0.5333    0.8000]; lines(5)];

        currentIdx = 0;
        currentColor = 1;
        for c=1:length(sDat.movementSets)
            newIdx = currentIdx + (1:length(sDat.movementSets{c}))';
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],...
                'LineWidth',5,'EdgeColor',boxColors(currentColor,:));
            currentIdx = currentIdx + length(sDat.movementSets{c});
            currentColor = currentColor + 1;
        end

        set(gcf,'Units','normalized','Position',[0.3171    0.0458    0.6847    0.8469]);
        if size(C,1)>80
            set(gca,'FontSize',5);
        elseif size(C,1)>60
            set(gca,'FontSize',7);
        end

        exportPNGFigure(gcf, [sDat.saveDir filesep 'allMovementsClassification']);
        close(gcf);

        % save classification matrices for all movements
        decodingAccuracy = (1-L);
        classMat_labels = sDat.movementNames(sortedSetIdx);
        classMat = C;
        save([sDat.saveDir filesep 'ClassificationMatrix'],'classMat','decodingAccuracy','classMat_labels','binoCI');

        % classification across the subset of classes specified
        SubsetClassification = [];
        for setIdx=1:length(sDat.movementSets)
            sDatNew = sDat;
            sortedSetIdx = sDat.movementSets{setIdx};
            %sortedSetIdx = [sortedSetIdx, sDat.doNothingCode];
            useTrl = ismember(sDat.movementCodes, sortedSetIdx);
            sDatNew.movementCodes = sDatNew.movementCodes(useTrl);
            [originalIdxs,~,sDatNew.movementCodes] = unique(sDatNew.movementCodes);
            sDatNew.movementNames = sDat.movementNames(originalIdxs);
            [~,~,sortedSetIdx] = unique(sortedSetIdx);
            sDatNew.goTimes = sDatNew.goTimes(useTrl);

            % DRD EDIT - Trim trials that go over the limit
            windowWidth = analysisWindow(2)-analysisWindow(1) + 1;
            mvCodes = sDatNew.movementCodes;
            windowStart = sDatNew.goTimes+sDat.analysisWindow(1);
            indsNoGo = find(windowStart < 1);

            indsNoGo_2 = find(windowStart+windowWidth > size(sDatNew.features,1));
            indsNoGo = [indsNoGo indsNoGo_2];

            windowStart(indsNoGo) = [];
            mvCodes(indsNoGo) = [];

            [ C, L , ~, binoCI] = simpleClassify(sDatNew.features, mvCodes, windowStart, sDatNew.movementNames, analysisWindow(2)-analysisWindow(1), 1, 1, true, sortedSetIdx);

            boxColors = [173,150,61;
                119,122,205;
                91,169,101;
                197,90,159;
                202,94,74]/255;
            boxColors = [boxColors; 0.8*[0.2667    0.8000    0.5333]; 0.8*[0    0.5333    0.8000]; lines(5)];

            set(gcf,'Units','normalized','Position',[0.3171    0.0458    0.6847    0.8469]);
            if size(C,1)>80
                set(gca,'FontSize',5);
            elseif size(C,1)>60
                set(gca,'FontSize',7);
            end

            exportPNGFigure(gcf,[sDat.saveDir filesep append('subset-',sDat.movementSetNames{setIdx})]);

            SubsetClassification{setIdx}.decodingAccuracy = (1-L);
            SubsetClassification{setIdx}.classMat_labels = sDatNew.movementNames;
            SubsetClassification{setIdx}.classMat = C;
            SubsetClassification{setIdx}.binoCI = binoCI;
            SubsetClassification{setIdx}.moveSetName = sDat.movementSetNames{setIdx};
            SubsetClassification{setIdx}.moveSet = sDatNew.movementSets{setIdx};
        end
        % save classification matrices for subset of movements
        save([sDat.saveDir filesep 'ClassificationMatrix_Subsets'],'SubsetClassification');
    end



    %% Marginalized PCA for Laterality
    if perform_mPCA
        fprintf('******* Performing marginalized PCA \n\n');

        smoothFeat = gaussSmooth_fast(sDat.features, sDat.mPCA_smoothWidth); % smooth features for marginalized PCA
        
        trlIdx = find(ismember(sDat.movementCodes, sDat.latMoveSet));% get trial codes for Arm movements
        lat_goCues = sDat.goTimes(trlIdx); % go cues for the above arm movement trials
        
        trlCodes_2Fact = []; % initialize matrix for 2 factor trial coding
        for trial = 1 : numel(lat_goCues)
            currCode = sDat.movementCodes(trlIdx(trial));
            mv = 0;
            lat = 0;
            if ismember(currCode, sDat.latMoveSet(1,:)) % right lat
                lat = 1;
                mv = find(sDat.latMoveSet(1,:) == currCode);
            elseif ismember(currCode, sDat.latMoveSet(2,:)) % left lat
                lat = 2;
                mv = find(sDat.latMoveSet(2,:) == currCode);
            end
            trlCodes_2Fact(trial,:) = [lat mv];
        end
    
        % mPCA options
        opts_m.nCompsPerMarg = 5;
        opts_m.makePlots = false;
        opts_m.nFolds = 10;
        opts_m.margNames = {'Laterality','Movement','L x M','Time'};
        opts_m.margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2], [1 2 3]}, {3}};
        opts_m.forceAxes = [-4 4];
        opts_m.readoutMode = 'parametric';
        opts_m.alignMode = 'rotation';
        opts_m.xValVariance = true;
        opts_m.plotCI = true;
    
        opts_m.saveDir = [sDat.saveDir filesep 'Laterality_' sDat.latMoveName];
        mkdir(opts_m.saveDir);
    
        mPCA_out = apply_mPCA_general(smoothFeat, lat_goCues, trlCodes_2Fact, sDat.analysisWindow, sDat.binWidth, opts_m);
        
        % save mPCA_out
        save([opts_m.saveDir filesep 'mPCA_out'], 'mPCA_out');

        ret.mPCA_out = mPCA_out;
    
    end



    %% t-test of every movement against do nothing
    if isfield(sDat,'do_ttest')
        if sDat.do_ttest
            %ttest plots
            sig_saveDirName = 'SignificantMovements';
            mkdir([sDat.saveDir filesep sig_saveDirName]);
            timeWindow = analysisWindow;

            pValThresh = 0.00001;

            % get list of all movements and the do
            sortedSetIdx = horzcat(sDat.movementSets{:});
            doNothingCode = sDat.doNothingCode;

            pVals = zeros(size(sDat.features,2), length(sortedSetIdx));
            significancePVals = pVals;

            groupNums = [];
            for movIdx = 1 : numel(sortedSetIdx)

                mvCodesTake = [sortedSetIdx(movIdx) doNothingCode];

                for group = 1 : numel(sDat.movementSets)
                    if ismember(sortedSetIdx(movIdx), sDat.movementSets{group})
                        groupNums = [groupNums group];
                    end
                end

                trlIdx = find(ismember(sDat.movementCodes, mvCodesTake));
                eventIdx = sDat.goTimes(trlIdx);
                movementCodes = sDat.movementCodes(trlIdx);

                [uniqueMoveCodes_Raw, reOrderedCodes, movementCodes_reOrdered] = unique(movementCodes);
                groupLabels = {sDat.movementNames{uniqueMoveCodes_Raw}};

                [featureVals, featureAverages, trialNum, maxRep] = computeFeatureAverages(sDat.features, movementCodes_reOrdered, eventIdx, timeWindow, 1);
                % featureAverages is NxDxT , N is channel, D is condition, T is
                % trialNum

                for neuron = 1 : size(featureAverages,1)
                    x = squeeze(featureAverages(neuron,1,:));
                    y = squeeze(featureAverages(neuron,2,:));

                    [h,p,ci,stats] = ttest2(x,y);

                    pVals(neuron,movIdx) = p;

                    if p <= pValThresh
                        significancePVals(neuron,movIdx) = 1;
                    end
                end
            end

            currTX = sDat.features;
            currTX = nanmean(currTX,1);
            indsThrow = find(isnan(currTX) == 1);
            numThrow = numel(indsThrow);
            indsKeep = find(~isnan(currTX) == 1);
            numKeep = numel(indsKeep);

            % save ttest_significance
            ttest_sig = [];
            ttest_sig.significancePVals = significancePVals; % N x movement, 1 if significantly tuned, 2 if not
            ttest_sig.numTotalChannelsInArray = size(sDat.features,2);
            ttest_sig.numChannels_candidate = numKeep;
            ttest_sig.numChannels_nonCandidate = numThrow;
            ttest_sig.indsThrow = indsThrow;
            ttest_sig.indsKeep = indsKeep;
            ttest_sig.movementCode = sortedSetIdx;
            ttest_sig.cueList = sDat.movementNames;
            ttest_sig.movementNamesReordered_yaxis = {sDat.movementNames{sortedSetIdx}}; % these are the labels for the y axis
            ttest_sig.moveSetNames = sDat.movementSetNames;
            ttest_sig.moveSetNum = groupNums;
            save([sDat.saveDir filesep 'Ttest_SigTuning'],'ttest_sig');

            % plot the heatmap
            figure();
            imagesc(significancePVals);
            xticks([1:1:numel(sDat.movementNames)]);
            xticklabels({sDat.movementNames{sortedSetIdx}});
            ylabel('Electrode');
            xlabel('Movement');
            set(gca,'YDir','normal');
            exportPNGFigure(gcf, [sDat.saveDir filesep 'Ttest_SigTuning']);
        end
    end

end