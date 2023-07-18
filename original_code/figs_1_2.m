% This file has the code for making figures 1 and 2
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

alldata = synchronize(tight,mpu_tt);
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


%% Figure 1: Option-based estimate of short-rate uncertainty

zlb1_start = find(alldataeff.Time >= datetime(2008,12,16));
zlb1_last  = find(alldataeff.Time > datetime(2015,12,16));

zlb2_start = find(alldataeff.Time >= datetime(2020,3,16));
zlb2_last  = find(alldataeff.Time >= alldataeff.Time(end));

z1sind = zlb1_start(1);
z1lind = zlb1_last(1);

z2sind = zlb2_start(1);
z2lind = zlb2_last(1);

YY = [0 0 2 2];
figure;
fill(alldataeff.Time([z1sind z1lind z1lind z1sind]),YY,[.9 .9 .9],'LineStyle','none'); hold on;
fill(alldataeff.Time([z2sind z2lind z2lind z2sind]),YY,[.9 .9 .9],'LineStyle','none'); hold on;
plot(alldataeff.Time,alldataeff.mpu_level,'k','LineWidth',2); hold on;
ylabel('Percent','FontSize',12);
set(gca,'FontSize',12)
ax = gca; 
tt = alldataeff.Time;
tickloc = 1:round(length(tt)/9):length(tt);
ax.XAxis.TickValues = [tt(tickloc)];
ax.XAxis.TickLabelFormat = 'yyyy';
box off;

    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperSize', [7 4]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 7 4]);
    set(gcf, 'renderer', 'painters');
    print(gcf, '-dpdf', './output/figure_1.pdf');

%% Figure 2: Changes in monetary policy uncertainty around FOMC announcements

crisis_start = find(fomcdataeff.Time > datetime(2007,7,1));
crisis_last  = find(fomcdataeff.Time > datetime(2009,6,30));

csind = crisis_start(1);
clind = crisis_last(1);
XX = [csind clind clind csind];
YY = [-.15 -.15 .15 .15];

figure;
patch(XX,YY,[.9 .9 .9],'EdgeColor','white'); hold on;
set(gca, 'Layer', 'top')
b = bar(fomcdataeff.mpu,.95); hold on;
set(b,'EdgeColor','black');
date_vec = datevec(fomcdataeff.Time) ;
date_label = date_vec(1:25:length(date_vec),1);
set(gca,'XTick',1:24.65:length(date_vec),'XTickLabel',date_label,'FontSize',12);
ylabel('Percent','FontSize',12);
set(gca,'FontSize',12);
box off;

    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperSize', [7 4]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 7 4]);
    set(gcf, 'renderer', 'painters');
    print(gcf, '-dpdf', './output/figure_2.pdf');


