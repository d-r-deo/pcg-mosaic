function [readoutAxes, readoutCov, readout_Z, readoutCov_unc] = mpca_readouts(pca_result, Cnoise, Cnoise_obsWeighted, XAvg, readoutMode)

% dpca_perMarginalization(X, plotFunction, ...) performs PCA in each
% marginalization of X and plots the components using plotFunction, a
% pointer to the function that plots one component (see dpca_plot_default() for
% the template).

% dpca_perMarginalization(..., 'PARAM1',val1, 'PARAM2',val2, ...) 
% specifies optional parameter name/value pairs:
%
%  'combinedParams' - cell array of cell arrays specifying 
%                     which marginalizations should be added up together,
%                     e.g. for the three-parameter case with parameters
%                           1: stimulus
%                           2: decision
%                           3: time
%                     one could use the following value:
%                     {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}}.
%
% 'timeEvents'      - time-points that should be marked on each subplot
%  'marginalizationNames'   - names of each marginalization
%  'time'                   - time axis
%
% 'timeSplits'      - an array of K integer numbers specifying time splits
%                     for time period splitting. All marginalizations will
%                     be additionally split into K+1 marginalizations,
%                     apart from the one corresponding to the last
%                     parameter (which is assumed to be time).
%
% 'timeParameter'   - is only used together with 'timeSplits', and must be
%                     provided. Specifies the time parameter. In the
%                     example above it is equal to 3.
%
% 'notToSplit'      - is only used together with 'timeSplits'. A cell array
%                     of cell arrays specifying which marginalizations
%                     should NOT be split. If not provided, all
%                     marginalizations will be split.

%for each component, find a neural readout and estimate its noise
options = optimoptions('quadprog','Display','off');

readoutAxes = zeros(size(pca_result.W));
readoutCov = zeros(size(pca_result.W,2),1);
readout_Z = zeros(size(pca_result.Z));

readoutCov_unc = zeros(size(pca_result.W,2),1);

for compIdx = 1:length(pca_result.whichMarg)
    if strcmp(readoutMode, 'parametric')
        %parametrically constrained readout
        Aeq = pca_result.W';
        beq = zeros(size(pca_result.W,2),1);
        beq(compIdx) = 1;
        X = quadprog(Cnoise,zeros(1,size(pca_result.W,1)),[],[],Aeq,beq,[],[],[],options);
    elseif strcmp(readoutMode, 'singleTrial')
        %single trial readout
        psthUnroll = XAvg(:,:);
        validCols = find(~any(isnan(psthUnroll),1));
        
        X = (psthUnroll(:,validCols)*psthUnroll(:,validCols)' + Cnoise_obsWeighted) \ (psthUnroll(:,validCols)*pca_result.Z(compIdx,validCols)');
        %X = X/norm(X);
    elseif strcmp(readoutMode, 'lsq')
        %least squares best readout
        psthUnroll = XAvg(:,:);
        validCols = find(~any(isnan(psthUnroll),1));
        
        X = psthUnroll(:,validCols)' \ pca_result.Z(compIdx,validCols)';
    elseif strcmp(readoutMode, 'pcaAxes')
        X = pca_result.W(:,compIdx);
    end
    
    readoutAxes(:,compIdx) = X;
    readoutCov(compIdx) = X'*Cnoise*X;
    readout_Z(compIdx,:) = X'*XAvg(:,:);
    
    %compare the noise of an unconstrained readout
    Aeq = pca_result.W(:,compIdx)';
    beq = 1;
    X = quadprog(Cnoise,zeros(1,size(pca_result.W,1)),[],[],Aeq,beq,[],[],[],options);
    readoutCov_unc(compIdx) = X'*Cnoise*X;
end