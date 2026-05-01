function [ costGrad ] = orthoCostGrad( x, XMarg, X, S )
    t0 = S*x;
    t1 = t0'*X;
    costGrad = -2*t1*(XMarg'-X'*t0*t0')*S - 2*t0'*(XMarg-t0*t1)*X'*S;
    costGrad = costGrad';
end

