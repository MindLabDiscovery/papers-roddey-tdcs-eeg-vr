function [acf, lags, bounds] = autocorr_fallback(y, numLags, varargin)
% AUTOCORR_FALLBACK
%
% Minimal drop-in replacement for the Econometrics Toolbox autocorr(), for
% use with ReMAE's myautocorrelation.m if that toolbox is unavailable.
%
% ReMAE calls:   autocc = autocorr(X);   then uses   autocc(1,2)
% i.e. it only ever needs the lag-1 sample autocorrelation, returned as the
% second element of a row vector beginning with lag 0 (which is always 1).
%
% TO USE
%   Save this file as  autocorr.m  in a folder that is on the MATLAB path
%   BEFORE ReMAE, or simply in your working directory. Verify with:
%       which -all autocorr
%   Remove it afterwards if you later install the Econometrics Toolbox, so
%   the official implementation is not shadowed.
%
% This computes the standard biased sample autocorrelation, matching the
% Econometrics Toolbox default.

y = double(y(:));
N = numel(y);

if nargin < 2 || isempty(numLags)
    numLags = min(20, N-1);
end
numLags = min(numLags, N-1);

y = y - mean(y);
c0 = sum(y.^2) / N;

acf = zeros(1, numLags+1);
if c0 == 0
    acf(1) = 1;                 % degenerate (constant) series
else
    for k = 0:numLags
        acf(k+1) = (sum(y(1:N-k) .* y(k+1:N)) / N) / c0;
    end
end

lags = 0:numLags;

% approximate 95% white-noise confidence bounds
b = 1.96 / sqrt(N);
bounds = [b; -b];

end
