function [featureVals, featureAverages, trialNum, maxRep] = computeFeatureAverages(features, trialCodes, eventIdx, timeWindow, nFactors)

    N = size(features,2);   % number of features
    T = length(timeWindow(1):timeWindow(2));       % number of time steps in a trial
    
    [codeList,~,muxCodes] = unique(trialCodes, 'rows');
    maxRep = max(hist(muxCodes, max(muxCodes)));
    nCodes = size(codeList,1);
    nCons = zeros(nFactors, 1);
    for f=1:nFactors
        nCons(f) = length(unique(trialCodes(:,f)));
    end
    
    matrixSize_singleTrial = [N, nCons', T, maxRep];
    matrixSize_numTrials = [N, nCons'];
    
    featureVals = nan(matrixSize_singleTrial); 
    trialNum = nan(matrixSize_numTrials);

    for codeIdx = 1:nCodes
        trlIdx = find(muxCodes==codeIdx);
        indOp = '(:';
        for f=1:nFactors
            indOp = [indOp, ',' num2str(codeList(codeIdx,f))];
        end
        indOp = [indOp, ')'];
        eval(['trialNum' indOp ' = length(trlIdx);']);
        
        indOp_neural = '(:';
        for f=1:nFactors
            indOp_neural = [indOp_neural, ',' num2str(codeList(codeIdx,f))];
        end
        indOp_neural = [indOp_neural, ',:,e)'];
        
        for e = 1:length(trlIdx)
            loopIdx = (eventIdx(trlIdx(e))+timeWindow(1)):(eventIdx(trlIdx(e))+timeWindow(2));
            if loopIdx(end)>size(features,1) || loopIdx(1)<1
                eval(['trialNum' indOp ' = trialNum' indOp ' - 1;']);
                continue;
            end
            
            eval(['featureVals' indOp_neural ' = features(loopIdx,:)'';']);
        end
    end
    
    if ndims(featureVals)>3
        featureAverages = nanmean(featureVals, ndims(featureVals));
    else
        featureAverages = featureVals;
    end
end
