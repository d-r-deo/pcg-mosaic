function [ss_array, mean_cumsum, stds_cumsum] = cvPCA_analysis(X, numIterations)
    % Cross-validated PCA analysis
    % X: NxCxTxR (neurons x conditions x timesteps x repetitions)
    
    ss_array = [];
    for iter = 1:numIterations
        N = size(X, 1); C = size(X, 2); T = size(X, 3); R = size(X, 4);
        X_avg = nanmean(X, 3); % NxCxR
        
        % Mean center
        X_flat = reshape(X_avg, N, C*R);
        mu = nanmean(X_flat, 2);
        X_mc = X_avg - mu(:, ones(C, 1), ones(R, 1));
        
        % Split trials
        R_inds = randperm(R);
        half = floor(R/2);
        X1 = X_mc(:, :, R_inds(1:half));
        X2 = X_mc(:, :, R_inds((half+1):(2*half)));
        
        X1_avg = nanmean(X1, 3); % NxC
        X2_avg = nanmean(X2, 3); % NxC
        
        % CV-PCA
        [~, ~, V] = svd(X1_avg'); % C x N -> V is N x C
        sv = sqrt(sum(V.^2, 1));
        U_norm = V(:, 1:min(length(sv), 100)) ./ sv(1:min(length(sv), 100));
        
        cproj0 = X1_avg' * U_norm;
        cproj1 = X2_avg' * U_norm;
        ss = sum(cproj0 .* cproj1, 1);
        
        ss_array = [ss_array; ss];
    end
    
    mean_cumsum = nanmean(ss_array, 1);
    stds_cumsum = nanstd(ss_array, [], 1);
end