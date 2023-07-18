% This file has the code for making Table E.3

% Results are in variable "tptable" 

clear;clc;
addpath('aux_files');

%% Load data and run regressions

fomcdataeff = table2timetable(readtable('data\tabe3_data.csv'));


acmtbl = [];
acmtab_lim = [];    
    
assetnames = {'dACMTP05','dACMTP10'}; 
nassets = size(assetnames,2);
assets = fomcdataeff{:,assetnames};

mps = fomcdataeff.monshk_daily;
mpu = fomcdataeff.mpu;

tbl1 = NaN(7,nassets);
tbl2 = NaN(9,nassets);

nanlength = @(x) sum(~isnan(x));
sumstat_labels = {'Obs';'Mean';'Median';'Std';'Min';'Max'};
func_list = {nanlength,@nanmean,@nanmedian,@nanstd,@nanmin,@nanmax};
sumstat_tab = table(sumstat_labels,NaN(length(sumstat_labels),1));

for jj = 1:nassets
    asset = assets(:,jj);
    
    [reg1 ,~,~,~,opt1.tstat ] = olsrob_nodisp(table(mps,asset));
    [reg2 ,~,~,~,opt2.tstat ] = olsrob_nodisp(table(mps,mpu,asset));
    
    tbl1(:,jj) = outreg2(reg1,opt1);
    tbl2(:,jj) = outreg2(reg2,opt2);
    
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


% tbl3cols (3 columns for each asset)
tbl3cols = tbl;
tbl3cols(:,3:4:end) = [];
tbl3cols(5:6,:) = [];

acmtbl = [acmtbl; NaN(3,4*nassets); tbl]; %#ok<*AGROW>
acmtab_lim = [acmtab_lim; NaN(3,3*nassets); tbl3cols];


%%%%%%%%%%%%%%%%% Effect of uncertainty on KW term premium
    
kwtbl = [];
kwtab_lim = []; 

assetnames = {'dTHREEFYTP0500','dTHREEFYTP1000'}; 
nassets = size(assetnames,2);    
assets = fomcdataeff{:,assetnames};

tbl1 = NaN(7,nassets);
tbl2 = NaN(9,nassets);

nanlength = @(x) sum(~isnan(x));
sumstat_labels = {'Obs';'Mean';'Median';'Std';'Min';'Max'};
func_list = {nanlength,@nanmean,@nanmedian,@nanstd,@nanmin,@nanmax};
sumstat_tab = table(sumstat_labels,NaN(length(sumstat_labels),1));

for jj = 1:nassets
    asset = assets(:,jj);
    
    [reg1 ,~,cov1,~,opt1.tstat ] = olsrob_nodisp(table(mps,asset));
    [reg2 ,~,cov2,~,opt2.tstat ] = olsrob_nodisp(table(mps,mpu,asset));

    tbl1(:,jj) = outreg2(reg1,opt1);
    tbl2(:,jj) = outreg2(reg2,opt2);
    
end
sumstat_tab.Var2 = []; 

% tbl (4 columns for each asset)
tbl = NaN(9,4*nassets);
tbl(1:2,1:4:end-1) = tbl1(1:2,:);
tbl(end,1:4:end-1) = tbl1(end,:);
tbl(1:4,2:4:end-1) = tbl2(1:4,:);
tbl(end,2:4:end-1) = tbl2(end,:);

% tbl3cols (3 columns for each asset)
tbl3cols = tbl;
tbl3cols(:,3:4:end) = [];
tbl3cols(5:6,:) = [];


kwtbl = [kwtbl; NaN(3,4*nassets); tbl]; %#ok<*AGROW>
kwtab_lim = [kwtab_lim; NaN(3,3*nassets); tbl3cols];

tptable = [acmtab_lim(:,[1:2 4:5]) NaN(10,1) kwtab_lim(:,[1:2 4:5]) ];
tptable(8:9,:) = []
