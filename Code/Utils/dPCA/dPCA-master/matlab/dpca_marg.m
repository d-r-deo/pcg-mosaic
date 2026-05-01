function [W, V, whichMarg] = dpca_marg(Xfull, ncompsPerMarg, varargin)
    % [W, V, whichMarg] = dpca(X, numComp, ...) performs dPCA on the data in X
    % and returns decoder matrix W and encoder matrix V. X is a multi-dimensional
    % array of dimensionality D+1, where first dimension corresponds to N neurons 
    % and the rest D dimensions -- to various parameters. numComp specifies
    % the number of dPCA components to be extracted (can be either one number
    % of a list of numbers for each marginalization). whichMarg is an array of
    % integers providing the 'type' of each component (which marginalization it
    % describes). If the total number of required components is S=sum(numComp),
    % then W and V are of NxS size, and whichMarg has length S.
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
    %  'lambda'         - regularization parameter. It's going to be multiplied
    %                     by the total variance of Xfull. Default value is
    %                     zero. To use different lambdas for different
    %                     marginalizations, provide an array instead of one
    %                     number.
    %
    %  'order'          - can be 'yes' (default) or 'no' and specifies whether
    %                     the components should be ordered by decreasing 
    %                     variance. If length(numComp)==1, components will
    %                     always be sorted.
    %
    %  'timeSplits'     - an array of K integer numbers specifying time splits
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
    %
    % 'scale'           - if 'yes', decoder of each component will be scaled to
    %                     have an optimal length (leading to the minimal
    %                     reconstruction error). Default is 'no'.
    %
    % 'Cnoise'          - if provided, will be used in a cost function to
    %                     penalize captured noise variance
    % default input parameters
    options = struct('combinedParams', [],       ...   
                     'timeEvents',     [],       ...
                     'time',           [], ...   
                     'marginalizationNames', [], ...
                     'timeSplits',     [],       ...
                     'timeParameter',  [],       ...
                     'notToSplit',     [], ...
                     'lambda', [], ...
                     'Cnoise',[]);

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
    X = bsxfun(@minus, X, nanmean(X,2));
    XfullCen = reshape(X, size(Xfull));

    % total variance
    totalVar = nansum(X(:).^2);

    % marginalize
    [Xmargs, margNums] = dpca_marginalize_frw(XfullCen, 'combinedParams', options.combinedParams, ...
                        'timeSplits', options.timeSplits, ...
                        'timeParameter', options.timeParameter, ...
                        'notToSplit', options.notToSplit, ...
                        'ifFlat', 'yes');

    validCols = find(all(~isnan(X)));
    Xmargs_valid = Xmargs;
    for x=1:length(Xmargs_valid)
        Xmargs_valid{x} = Xmargs{x}(:,validCols);
    end

    margVar = zeros(length(Xmargs),1);

    EXPLAINED = cell(length(Xmargs),1);
    whichMarg = [];
    axVar = [];
    W = [];

    size_X = size(Xfull);
    Z = zeros([ncompsPerMarg*length(Xmargs), size_X(2:end)]);

    currentIdx = 1:ncompsPerMarg;
    for m=1:length(Xmargs)
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED{m}, MU] = pca(Xmargs_valid{m}');
        margVar(m) = nansum(Xmargs_valid{m}(:).^2)/totalVar*100;

        whichMarg = [whichMarg; repmat(m,ncompsPerMarg,1)];
        axVar = [axVar; margVar(m)*EXPLAINED{m}(1:ncompsPerMarg)/100];

        indexOp = ['(currentIdx(n)'];
        for dimIdx=1:(length(size_X)-1)
            indexOp = [indexOp, ',:'];
        end
        indexOp = [indexOp,')'];

        for n=1:ncompsPerMarg
            tmp = reshape(COEFF(:,n)'*Xmargs{m}, size_X(2:end));
            eval(['Z' indexOp ' = tmp;']);
        end

        W = [W, COEFF(:,1:ncompsPerMarg)];
        currentIdx = currentIdx + ncompsPerMarg;
    end

    %sort axes by variance explained
    [~,sortIdx] = sort(axVar,'descend');

    whichMarg = whichMarg(sortIdx)';
    axVar = axVar(sortIdx);
    W = W(:,sortIdx);
    V = W;
    
    sortOp = ['(sortIdx'];
    for dimIdx=1:(length(size_X)-1)
        sortOp = [sortOp, ',:'];
    end
    sortOp = [sortOp,')'];
    eval(['Z = Z' sortOp ';']);
end