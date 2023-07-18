function tab = outreg2(model,options)
%OUTREG2 Format regression results similar to Stata's outreg2

% For no intercept, set options.const = 0

% Standard errors or tstats
if isfield(options,'se') || isfield(options,'rse')
    inference = options.se;
elseif isfield(options,'tstat')
    inference = options.tstat;
else
    error('No std errors or t-stats provided');
end
    
numrows = 3; % R^2 and Obs + 1 space

nxs = model.NumPredictors; % coeffs
numrows = numrows + 2*nxs;

if isfield(options,'const')
    hascon = options.const;
else % default option is that there is an intercept
    hascon = 1;
end

if hascon % intercept
    numrows = numrows + 2;
end

if isfield(options,'adjrsqr') % adj rsqr
    numrows = numrows + 1;
end

tab = NaN(numrows,1);

for nn = 1:nxs
    tab(2*nn-1) = model.Coefficients.Estimate(nn+hascon);
    tab(2*nn) = inference(nn+hascon);
end

if hascon
tab(2*nxs+1) =  model.Coefficients.Estimate(1);
tab(2*nxs+2) =  inference(1);
end

tab(2*nxs+4-2*~hascon) = model.NumObservations;
tab(2*nxs+5-2*~hascon) = model.Rsquared.Ordinary;

if isfield(options,'adjrsqr')
    tab(2*nxs+6-2*~hascon) = model.Rsquared.Adjusted;
end
