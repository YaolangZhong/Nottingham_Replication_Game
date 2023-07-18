function tStat = rob_samplemean_tstat(Y)
% tstat from standard errors robust to heteroskedasticity
% (White) for sample mean estimation 

try
[~,robse,coeff] = hac(ones(length(Y),1),Y,'type','HC','weights','HC0','display','off','intercept',false); % robse: robust std err,
ci = [coeff - 1.96*robse; coeff + 1.96*robse];
tStat = coeff/robse;
pValue = 2*tcdf(-abs(tStat),length(Y)-1);
catch
    robse = 0; coeff = 0; ci = [0 0]; tStat = 0;
end
