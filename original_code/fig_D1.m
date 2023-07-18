% This file has the code for making Figure D.1

clear; clc;
addpath('aux_files');

%% Load the data

% fomc dates
tight = table2timetable(readtable('data\fomc_dates.csv'));

% mpu
mpu_tt = table2timetable(readtable('data\mpu.csv'));
mpu10 = mpu_tt.mpu10; 
mpu = [NaN; mpu10(2:end) - mpu10(1:end-1)];
mpu_tt.mpu = mpu;
mpu_tt.mpu_level = mpu10;

% mps
mps_tt = table2timetable(readtable('data\mps_incl_unsched_and_crisis.csv'));

alldata = synchronize(tight,mpu_tt,mps_tt);
alldata.Properties.DimensionNames{1} = 'Time';

%% Assign the sample

% Pick start and end dates
strt_con = datetime(1994,1,1);
last_con = datetime(2020,9,30);

%allfomcdata = rmmissing(alldata,'DataVariables',{'MP1_tight'});
allfomcdata = rmmissing(alldata,'DataVariables',{'MP1'});
% drop non-fomc dates

effsmpl = timerange(strt_con,last_con);
fomcdataeff = allfomcdata(effsmpl,:); % restrict to selected sample

alldataeff = alldata;
effsmpl = timerange(strt_con,last_con);
alldataeff = alldataeff(effsmpl,:); % restrict to selected sample

%% Figure: Scatter plot of MPU and MP surprise %%%%%%%%%%%%%%%%%%%%%%%%%%%%

mpu = fomcdataeff.mpu;
monshk_daily = fomcdataeff.monshk_daily;

% Dummy for pre,crisis & post
pre_crisis = timerange(strt_con,datetime(2007,6,30)); %(2007,6,30);
fomcdataeff.dum_precrisis = zeros(length(fomcdataeff.Time),1);
fomcdataeff.dum_precrisis(fomcdataeff.Time(pre_crisis)) = 1;

crisis = timerange(datetime(2007,6,30),datetime(2009,6,30));
fomcdataeff.dum_crisis = zeros(length(fomcdataeff.Time),1);
fomcdataeff.dum_crisis(fomcdataeff.Time(crisis)) = 1;

post_crisis = timerange(datetime(2009,7,1),last_con); %(2007,6,30);
fomcdataeff.dum_postcrisis = zeros(length(fomcdataeff.Time),1);
fomcdataeff.dum_postcrisis(fomcdataeff.Time(post_crisis)) = 1;

fomcdataeff.dum_noncrisis = ones(length(fomcdataeff.Time),1);
fomcdataeff.dum_noncrisis(fomcdataeff.Time(crisis)) = 0;

fomcdataeff.dum_baseline = ones(length(fomcdataeff.Time),1);
fomcdataeff.dum_baseline(fomcdataeff.Time(crisis)) = 0;
%fomcdataeff.dum_baseline(logical(fomcdataeff.Unscheduled_tight)) = 0;
fomcdataeff.dum_baseline(logical(fomcdataeff.Unscheduled)) = 0;


figure;
p1 = scatter(monshk_daily(logical(fomcdataeff.dum_baseline)),mpu(logical(fomcdataeff.dum_baseline)),50,'.k'); hold on;
%hh = lsline;
p2 = scatter(monshk_daily(logical(fomcdataeff.dum_crisis)),mpu(logical(fomcdataeff.dum_crisis)),'rx'); hold on;
%p3 = scatter(monshk_daily(logical(fomcdataeff.Unscheduled_tight)),mpu(logical(fomcdataeff.Unscheduled_tight)),'b'); hold on;
p3 = scatter(monshk_daily(logical(fomcdataeff.Unscheduled)),mpu(logical(fomcdataeff.Unscheduled)),'b'); hold on;

yl = ylim;
xl = xlim;
%ylin = line([0,0],ylim); ylin.LineStyle = ':';
ylin = line([0,0],[-.2 .15]); ylin.LineStyle = ':';
hlin = line(xlim,[0,0]); hlin.LineStyle = ':';
ylim(yl);
ylim([-.2 .15]);
xlim(xl);
a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'Fontsize',11);
a = get(gca,'YTickLabel');
set(gca,'YTickLabel',a,'Fontsize',11);
xlabel('Policy surprise','FontSize',11);
ylabel('Change in uncertainty','FontSize',11);

[mdl,robse,EstCov,pValue,tStat] = olsrob(table(monshk_daily(logical(fomcdataeff.dum_baseline)),mpu(logical(fomcdataeff.dum_baseline))));
        
intercept = mdl.Coefficients.Estimate(1);
slope = mdl.Coefficients.Estimate(2);
rfln = refline(slope,intercept);
rfln.Color = 'k';

l = legend([p1 p2 p3],'Baseline sample','Crisis period','Unscheduled','Location','southeast');
l.FontSize = 11;

% %% Table 3: FOMC announcements and the largest changes in monetary policy uncertainty
% Kmax = 5;
% Kmin = 10;
% [maxKvals,maxKind] = maxk(fomcdataeff.mpu,Kmax);
% %[maxKvals,maxKind] = maxk(alldataeff.pctmfiv_level,K);
% 
% [minKvals,minKind] = mink(fomcdataeff.mpu,Kmin);
% %[minKvals,minKind] = mink(alldataeff.pctmfiv_level,K);
% 
% maxtable = fomcdataeff(maxKind,{'mpu','monshk_daily'});
% mintable = fomcdataeff(minKind,{'mpu','monshk_daily'});
