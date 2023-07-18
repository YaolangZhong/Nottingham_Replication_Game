function [mdel,robse,EstCov,pValue,tStat] = olsrob_nodisp(X,varargin)

mdel = fitlm(X,varargin{:});

[EstCov,robse,~] = hac(X,varargin{:},'type','HC','weights','HC0','display','off'); % robse: robust std err,


coeff = mdel.Coefficients;
coeff.SE = robse;
tStat = coeff.Estimate./coeff.SE;
coeff.tStat = tStat;
pValue = 2*tcdf(-abs(coeff.tStat),mdel.DFE);
coeff.pValue = pValue;


% fspec1 = '\nDep. Var: %s\n';
% fprintf(fspec1,mdel.ResponseName);
% disp(coeff)
% fspec2 = 'Number of obs: %d, R^2: %.2f, Adj. R^2: %.2f\n\n';
% fprintf(fspec2,mdel.NumObservations,mdel.Rsquared.Ordinary,mdel.Rsquared.Adjusted);

