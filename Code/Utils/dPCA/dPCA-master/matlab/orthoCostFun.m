function [ cost ] = orthoCostFun( x, XMarg, X, S )
    t0 = S*x;
    cost = trace((XMarg-t0*t0'*X)*(XMarg-t0*t0'*X)');
end

