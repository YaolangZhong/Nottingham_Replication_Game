% This file has the code for making Table E.1

% Results are in variable "hstab_lim" 

clear;clc;
addpath('aux_files');

%% Load data and run regressions

alldataeff = table2timetable(readtable('data\tabe1_data.csv'));

varnames = {'SVENY02','mpu_level','SVENF05','SVENF10','TIPSF05','TIPSF10'};


% construct two day change around FOMC announc.
allvars = fillmissing(alldataeff{:,varnames},'previous');


window = 2;
% choose lead length
nlead = -1;  % -1 for 2 day chg   
nlag = 1; 

% Construct leads and lags
allvars_lead = lagmatrix(allvars,nlead);
allvars_lag = lagmatrix(allvars,nlag);

% 2 day change: for all days
allvars_ndaychg = allvars_lead - allvars_lag;

% 2 day change: Day after FOMC relative to day before     
fomcdum = logical(alldataeff.fomcdum);   
vars_ndaychg = allvars_ndaychg(fomcdum,:);

% level of mpu on t-1 relative to FOMC day
allmpu_level_lag2 = lagmatrix(allvars(:,2),1);
mpu_level_lag2 = allmpu_level_lag2(fomcdum);

%mps = fomcdataeff.monshk_daily; % 
mps = vars_ndaychg(:,1);
mpu = vars_ndaychg(:,2);

inter = mps.*mpu_level_lag2;

% Nominal forwards
assets = vars_ndaychg(:,3:length(varnames));
assetnames = varnames(3:length(varnames));
nassets = length(varnames) - 2;

tbl1 = NaN(7,nassets);
tbl2 = NaN(9,nassets);
tbl3 = NaN(11,nassets);
tbl4 = NaN(13,nassets);

nanlength = @(x) sum(~isnan(x));
sumstat_labels = {'Obs';'Mean';'Median';'Std';'Min';'Max'};
func_list = {nanlength,@nanmean,@nanmedian,@nanstd,@nanmin,@nanmax};
sumstat_tab = table(sumstat_labels,NaN(length(sumstat_labels),1));


for jj = 1:nassets
    asset = assets(:,jj);
    
    [reg1 ,~,~,~,opt1.tstat ] = olsrob_nodisp(table(mps,asset));
    [reg2 ,~,~,~,opt2.tstat ] = olsrob_nodisp(table(mps,mpu,asset));
    [reg3 ,~,~,~,opt3.tstat ] = olsrob_nodisp(table(mps,mpu_level_lag2,inter,asset));
    [reg4 ,~,~,~,opt4.tstat ] = olsrob_nodisp(table(mps,mpu,mpu_level_lag2,inter,asset));
    
    tbl1(:,jj) = outreg2(reg1,opt1);
    tbl2(:,jj) = outreg2(reg2,opt2);
    tbl3(:,jj) = outreg2(reg3,opt3);
    tbl4(:,jj) = outreg2(reg4,opt4);    
    
    tmpvals = NaN(length(func_list),1);
    for kk = 1:length(func_list)
        tmpvals(kk) = func_list{kk}(asset);
    end    
    sumstat_tab.(assetnames{jj}) = tmpvals;
      
    
end
sumstat_tab.Var2 = []; 

% tbl (4 columns for each asset)
tbl = NaN(9,4*nassets);
tbl(1:2,1:4:end-1) = tbl1(1:2,:);
tbl(end,1:4:end-1) = tbl1(end,:);
tbl(1:4,2:4:end-1) = tbl2(1:4,:);
tbl(end,2:4:end-1) = tbl2(end,:);
tbl([1:2 5:8],3:4:end-1) = tbl3(1:6,:);
tbl(end,3:4:end-1) = tbl3(end,:);
tbl(1:8,4:4:end) = tbl4(1:8,:);
tbl(end,4:4:end) = tbl4(end,:);

% tbl2cols (2 columns for each asset)
tbl2cols = tbl;
tbl2cols(:,[2 3 6 7 10 11 14 15]) = [];
tbl2cols(5:6,:) = [];

%hstab = [hstab; NaN(3,4*nassets); tbl];
hstab_lim = tbl2cols