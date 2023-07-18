% This file has the code for making Table 2
clear; clc; warning off;
addpath('aux_files');

% ******** Table: Summary statistics:
% For full sample, results are in "sumtab"
% For Press Conf sample, results are in "sumtab_pc"

%% Load the data

% fomc dates
tight = table2timetable(readtable('data\fomc_dates.csv'));

% mpu
mpu_tt = table2timetable(readtable('data\mpu.csv'));
mpu10 = mpu_tt.mpu10; 
mpu = [NaN; mpu10(2:end) - mpu10(1:end-1)]; % daily change
mpu_tt.mpu = mpu;
mpu_tt.mpu_level = mpu10;

alldata = synchronize(tight,mpu_tt);
alldata.Properties.DimensionNames{1} = 'Time';


% load sep dates
[datafomcactions,dtsfomcactions] = xlsread('data\fomc_actions_clean.csv');
% {'Press Conference','Scheduled FOMC','Unscheduled FOMC','SEP','Dotplot','Monetary Policy Report','Minutes Released'}

tmp = readtable('data\fomc_actions_clean.csv');
datafomcactions = tmp{:,3:end};
fomcactiondts = tmp{:,1};


%% Assign the sample

% Pick start and end dates
strt_con = datetime(1994,1,1);
last_con = datetime(2020,9,30);

% Drop crisis period
crisis_start = datetime(2007,7,1);
crisis_last = datetime(2009,6,30);
exclcrisissmpl = timerange(crisis_start,crisis_last,'closed');
excl = alldata.Time(exclcrisissmpl);
excl(end+1) = datetime(2001,9,17); %datenum('9\17\2001');

allfomcdata = rmmissing(alldata,'DataVariables',{'MP1'});
% drop non-fomc dates

effsmpl = timerange(strt_con,last_con);
tmpdata = allfomcdata(effsmpl,:); % restrict to selected sample
inremexcl = ismember(excl,tmpdata.Time);
excl = excl(inremexcl);
tmpdata(excl,:) = []; % drop any dates in excl list specified above

unschind = tmpdata.Unscheduled == 1; % index for unsched fomc
tmpdata(unschind,:) = []; % drop them

fomcdataeff = tmpdata;
% effective sample for constr mon pol surprise & running regressions

fomcdataeff.fomcdum = ones(size(fomcdataeff.Time));

alldata = synchronize(alldata,fomcdataeff(:,'fomcdum'));
alldata{isnan(alldata.fomcdum),'fomcdum'} = 0;

allfomcind = ~isnan(alldata.MP1);
alldata.fomc_notin_sample = allfomcind & ~alldata.fomcdum;
% FOMC meetings not in effective sample

alldata.allfomc = allfomcind;

alldataeff = alldata;
unschind1 = alldataeff.Unscheduled == 1;
alldataeff(unschind1,:) = [];

effsmpl = timerange(strt_con,last_con);
alldataeff = alldataeff(effsmpl,:); % restrict to selected sample

alldataeff1 = alldata(effsmpl,:);
% same as alldataeff but keep the unscheduled/excluded FOMC meetings



%% Table: Summary Statistics (baseline sample) %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For fomc dates in sample
mpufomcinsample = fomcdataeff.mpu;
obs = sum(~isnan (mpufomcinsample ))';
mean = nanmean(mpufomcinsample)';
[~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
med = nanmedian(mpufomcinsample)';
skew = skewness(mpufomcinsample);
cchg = sum(mpufomcinsample);
kurt = kurtosis(mpufomcinsample);
min = nanmin(mpufomcinsample)';
max = nanmax(mpufomcinsample)';
stdev = std(mpufomcinsample,'omitnan')';
%colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtabfomc = table(colfomc,'RowNames',rownm,'VariableNames',{'mpu_fomc'});
clear mean min max

% For non-fomc data
alldataeff1(exclcrisissmpl,:) = [];

allnonfomcdata = alldataeff1(~logical(alldataeff1.fomcdum) & ~logical(alldataeff1.fomc_notin_sample) ,:);
mpunotfomc = allnonfomcdata.mpu;
obs = sum(~isnan (mpunotfomc ))';
mean = nanmean(mpunotfomc)';
[~,~,~,pvalmean_nonfomc,tstat_nonfomc] = rob_samplemean(mpunotfomc);
med = nanmedian(mpunotfomc)';
skew = skewness(mpunotfomc);
cchg = sum(mpunotfomc);
kurt = kurtosis(mpunotfomc);
min = nanmin(mpunotfomc)';
max = nanmax(mpunotfomc)';
stdev = std(mpunotfomc,'omitnan')';
%colnonfomc = [obs,mean,tstat_nonfomc,med,stdev,skew,kurt,min,max]';
colnonfomc = [obs,mean,tstat_nonfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtabnonfomc = table(colnonfomc,'RowNames',rownm,'VariableNames',{'mpu_nonfomc'});
clear mean min max

% test of different from zero
[~,~,~,pfomc] = rob_samplemean(mpufomcinsample);
[~,~,~,pnfomc] = rob_samplemean(mpunotfomc);
% test of difference in means
[~,pfnf] = ttest2(mpufomcinsample, mpunotfomc,'Vartype','unequal');
ptab_ss = [pfomc;pnfomc;pfnf];

%sumtab = [sumtab NaN(6,1) colfomc colnonfomc];
%sumtab = [colfomc colnonfomc];
sumtab = [sumtabfomc sumtabnonfomc]

%--------------------------------------------------------------------------

%% Table: Summary Statistics (SEP vs no SEP) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% convert dates to datetime format
%fomcactiondts = datetime(dtsfomcactions(2:end,1));

% Scheduled FOMC
schedfomcdum = datafomcactions(:,2);

% SEP (start with 10/31/2007 FOMC meeting)
sepdum = datafomcactions(:,4);

% Press Conference
confdum = datafomcactions(:,1);

% Scheduled FOMC meetings with Press Conference
schedfomcconf_dum = schedfomcdum & confdum;

% Scheduled FOMC meetings without Press Conference
schedfomcnoconf_dum = schedfomcdum & ~confdum;

% Scheduled FOMC meetings without SEP
schedfomcnosep_dum = schedfomcdum & ~sepdum;

% Create a timetable
var_names = {'SEP','SchedFOMC_noSEP','PC',   'SchedFOMC_noPC',     'SchedFOMC_pc'};
dum_list = [sepdum schedfomcnosep_dum confdum schedfomcnoconf_dum   schedfomcconf_dum  ];
nvars = length(var_names);
factions_tt = array2timetable(dum_list,'RowTimes',fomcactiondts,'VariableNames',var_names);
trange = timerange(strt_con,last_con);
fomcactions_tt = factions_tt(trange,:);

% Merge with uncertainty data
mpu_vars = fomcdataeff(:,{'mpu','fomcdum'});
mpu_fomcactions = synchronize(mpu_vars,fomcactions_tt);

% remove non-fomc days
nfomcind = isnan(mpu_fomcactions.fomcdum);
mpu_fomcactions(nfomcind,:) = [];

sep_start_ind = find(mpu_fomcactions.Time >= datetime(2012,1,1));
%sep_end   = datetime(2017,12,31);

fomc_sep = mpu_fomcactions(sep_start_ind(1):end,:);
fomc_sep.noSEP = fomc_sep.SchedFOMC_noSEP; %~fomc_sep.SEP;
fomc_sep.noPC = fomc_sep.SchedFOMC_noPC;   %~fomc_sep.PC;

sep_sample = 1;
switch sep_sample
    case 1
        start_date = datetime(2012,1,1);
        end_date = datetime(2018,12,31);
    case 2
        start_date = datetime(2012,1,1);
        end_date = datetime(2020,9,30);
end
sepsample = timerange(start_date,end_date,'closed');

fomc_sep = fomc_sep(sepsample,:);

% For all fomc dates in sample
mpufomcinsample = fomc_sep.mpu;
obs = sum(~isnan (mpufomcinsample ))';
mean = nanmean(mpufomcinsample)';
[~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
med = nanmedian(mpufomcinsample)';
skew = skewness(mpufomcinsample);
cchg = sum(mpufomcinsample);
kurt = kurtosis(mpufomcinsample);
min = nanmin(mpufomcinsample)';
max = nanmax(mpufomcinsample)';
stdev = std(mpufomcinsample,'omitnan')';
%colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtaballfomc = table(colfomc,'RowNames',rownm,'VariableNames',{'mpuall'});

% For SEP fomc dates in sample
mpufomcinsample = fomc_sep.mpu(logical(fomc_sep.SEP));
obs = sum(~isnan (mpufomcinsample ))';
mean = nanmean(mpufomcinsample)';
[~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
med = nanmedian(mpufomcinsample)';
skew = skewness(mpufomcinsample);
cchg = sum(mpufomcinsample);
kurt = kurtosis(mpufomcinsample);
min = nanmin(mpufomcinsample)';
max = nanmax(mpufomcinsample)';
stdev = std(mpufomcinsample,'omitnan')';
%colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtabsep = table(colfomc,'RowNames',rownm,'VariableNames',{'mpusep'});

%For press conference dates in sample
mpufomcinsample = fomc_sep.mpu(logical(fomc_sep.PC));
obs = sum(~isnan (mpufomcinsample ))';
mean = nanmean(mpufomcinsample)';
[~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
med = nanmedian(mpufomcinsample)';
skew = skewness(mpufomcinsample);
cchg = sum(mpufomcinsample);
kurt = kurtosis(mpufomcinsample);
min = nanmin(mpufomcinsample)';
max = nanmax(mpufomcinsample)';
stdev = std(mpufomcinsample,'omitnan')';
%colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtabpc = table(colfomc,'RowNames',rownm,'VariableNames',{'mpupc'});

try
    % For non Press Conference dates in sample
    mpufomcinsample = fomc_sep.mpu(logical(fomc_sep.noPC));
    obs = sum(~isnan (mpufomcinsample ))';
    mean = nanmean(mpufomcinsample)';
    [~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
    med = nanmedian(mpufomcinsample)';
    skew = skewness(mpufomcinsample);
    cchg = sum(mpufomcinsample);
    kurt = kurtosis(mpufomcinsample);
    min = nanmin(mpufomcinsample)';
    max = nanmax(mpufomcinsample)';
    stdev = std(mpufomcinsample,'omitnan')';
    %colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
    colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
    %rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
    rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
    sumtabnopc = table(colfomc,'RowNames',rownm,'VariableNames',{'mpunopc'});
catch
    sumtabnooc = table(NaN(size(sumtabpc)));
end

% For non SEP fomc dates in sample
mpufomcinsample = fomc_sep.mpu(logical(fomc_sep.noSEP));
obs = sum(~isnan (mpufomcinsample ))';
mean = nanmean(mpufomcinsample)';
[~,~,~,pvalmeanfomc,tstatfomc] = rob_samplemean(mpufomcinsample); % test of different from zero
med = nanmedian(mpufomcinsample)';
skew = skewness(mpufomcinsample);
cchg = sum(mpufomcinsample);
kurt = kurtosis(mpufomcinsample);
min = nanmin(mpufomcinsample)';
max = nanmax(mpufomcinsample)';
stdev = std(mpufomcinsample,'omitnan')';
%colfomc = [obs,mean,tstatfomc,med,stdev,skew,kurt,min,max]';
colfomc = [obs,mean,tstatfomc,stdev,skew,cchg]';
%rownm = {'Obs','Mean','tstat_mean', 'Median','Std. Dev.','Skewness','Kurtosis','Min.','Max.' }';%
rownm = {'Obs','Mean','tstat_mean','Std. Dev.','Skewness','Cumulative change'}';%
sumtabnosep = table(colfomc,'RowNames',rownm,'VariableNames',{'mpunosep'});

%subtab_sepsample = [sumtaballfomc sumtabsep sumtabnosep sumtabpc sumtabnopc];
sumtab_pc = [sumtaballfomc sumtabpc sumtabnopc]

%--------------------------------------------------------------------------

