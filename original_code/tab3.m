% This file has the code for making Table 3

% The top panel showing "Top 10 declines in monetary policy uncertainty"
% are stored in "mintable"

% The bottom panel showing "Top 5 increases in monetary policy uncertainty"
% are stored in "maxtable"

% The snippets in the last column are from FOMC statements which are
% available here:
% https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm

clear; clc;
%% Load the data

% fomc dates
tight = table2timetable(readtable('data/fomc_dates.csv'));

% mpu
mpu_tt = table2timetable(readtable('data/mpu.csv'));
mpu10 = mpu_tt.mpu10; 
mpu = [NaN; mpu10(2:end) - mpu10(1:end-1)]; % daily change
mpu_tt.mpu = mpu;
mpu_tt.mpu_level = mpu10;

% load mps
mps_tt = table2timetable(readtable('data/mps_incl_unsched_and_crisis.csv'));


alldata = synchronize(tight,mpu_tt,mps_tt);
alldata.Properties.DimensionNames{1} = 'Time';


%% Assign the sample

% Pick start and end dates
strt_con = datetime(1994,1,1);
last_con = datetime(2020,9,30);

allfomcdata = rmmissing(alldata,'DataVariables',{'MP1'});
% drop non-fomc dates

effsmpl = timerange(strt_con,last_con);
fomcdataeff = allfomcdata(effsmpl,:); % restrict to selected sample

alldataeff = alldata;
effsmpl = timerange(strt_con,last_con);
alldataeff = alldataeff(effsmpl,:); % restrict to selected sample


%% Table 3: FOMC announcements and the largest changes in monetary policy uncertainty
Kmax = 5;
Kmin = 10;
[maxKvals,maxKind] = maxk(fomcdataeff.mpu,Kmax);

[minKvals,minKind] = mink(fomcdataeff.mpu,Kmin);

maxtable = fomcdataeff(maxKind,{'mpu','monshk_daily'})
mintable = fomcdataeff(minKind,{'mpu','monshk_daily'})