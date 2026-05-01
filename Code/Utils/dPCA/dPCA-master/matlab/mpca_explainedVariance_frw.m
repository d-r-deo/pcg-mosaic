function explVar = mpca_explainedVariance_frw(Xfull, W, V, whichMarg, varargin)

% explVar = dpca_explainedVariance(X, W, V) computes various measures of
% explained variance and returns them in a structure explVar. X is the data
% matrix, W is the decoder matrix, V is the encoder matrix. Returned values:
%
%  * explVar.totalVar             - total variance
%  * explVar.totalMarginalizedVar - total variance in each marginalization
%  * explVar.componentVar         - variance of each component (%)
%  * explVar.margVar              - variance of each component in each marginalization (%)
%  * explVar.cumulativePCA        - cumulative variance of the PCA components (%)
%  * explVar.cumulativeDPCA       - cumulative variance of the dPCA components (%)
%
% [...] = dpca(..., 'PARAM1',val1, 'PARAM2',val2, ...) 
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
%  'X_trial'        - array of single trials. Has one extra dimension as 
%                     compared with X and stores individual single trial
%                     firing rates, as opposed to the trial average. If
%                     provided, "signal variance" will be computed:
%
%  * explVar.totalVar_signal             - total signal variance
%  * explVar.totalVar_noise              - total residual noise variance
%  * explVar.totalMarginalizedVar_signal - total signal variance in each marginalization
%  * explVar.cumulativePCA_signal        - cumulative signal variance of the PCA components (%)
%  * explVar.cumulativeDPCA_signal       - cumulative signal variance of the dPCA components (%)
%
%  'numOfTrials'    - must be provided together with X_trial. Has one
%                     dimension fewer than X and for each neuron and
%                     combination of parameters (without time) specifies
%                     the number of available trials in X_trial. All
%                     entries have to be larger than 1.
%
% 'Cnoise'          - Cnoise matrix, as obtained by
%                     dpca_getNoiseCovariance(). Can be provided INSTEAD of
%                     X_trial to compute the noise estimate via the new
%                     method. numOfTrials still needed.

% default input parameters
options = struct('combinedParams', [], ...   
                 'X_trial',        [], ...
                 'numOfTrials',    [], ...
                 'Cnoise',         []);

% read input parameters
optionNames = fieldnames(options);
if mod(length(varargin),2) == 1
	error('Please provide propertyName/propertyValue pairs')
end
for pair = reshape(varargin,2,[])    % pair is {propName; propValue}
	if any(strcmp(pair{1}, optionNames))
        options.(pair{1}) = pair{2};
    else
        error('%s is not a recognized parameter name', pair{1})
	end
end

% centering
X = Xfull(:,:);
Xfull = bsxfun(@minus, Xfull, nanmean(X,2));
X = bsxfun(@minus, X, nanmean(X,2));

% marginalizing
Xmargs = dpca_marginalize(Xfull, 'combinedParams', options.combinedParams, 'ifFlat', 'yes');

%don't include missing conditions
validColumns = find(all(~isnan(X)));
XValid = X(:,validColumns);
XmargsValid = Xmargs;
for x=1:length(XmargsValid)
    XmargsValid{x} = XmargsValid{x}(:,validColumns);
end
    
% total variance
explVar.totalVar = nansum(nansum(XValid.^2));

% total marginalized variance
for i=1:length(XmargsValid)
    explVar.totalMarginalizedVar(i) = nansum(XmargsValid{i}(:).^2);
end

% PCA explained variance
[~,S,~] = svd(XValid', 'econ');
S = diag(S);
S = S(1:min(size(W,2), length(S)));
explVar.cumulativePCA = cumsum(S.^2'/ explVar.totalVar * 100);

% mPCA explained variance
for i=1:size(W,2)
    explVar.componentVar(i) = 100 - sum(sum((XValid - V(:,i)*(W(:,i)'*XValid)).^2)) / explVar.totalVar * 100;    
   
    for j=1:length(XmargsValid)
        ZZ = XmargsValid{j} - V(:,i)*(W(:,i)'*XmargsValid{j});
        explVar.margVar(j,i) = (explVar.totalMarginalizedVar(j) - sum(ZZ(:).^2)) / explVar.totalVar * 100;    
    end
end

mVar = zeros(1,size(explVar.margVar,2));
for i=1:size(W,2)
    mVar(i) = explVar.margVar(whichMarg(i),i);
end

sortVar = sort(mVar,'descend');
explVar.cumulativeMPCA = cumsum(sortVar);

% OPTIONAL part : NEW APPROACH
if ~isempty(options.Cnoise) && ~isempty(options.numOfTrials)
    Ktilde = nanmean(reshape(options.numOfTrials, size(options.numOfTrials,1),[]),2);
    explVar.totalVar_noise = sum(diag(options.Cnoise)./Ktilde);
    explVar.totalVar_signal = explVar.totalVar - explVar.totalVar_noise;
end
