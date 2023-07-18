% This file has the code for making figures D.2
clear; clc; warning off;
%% Load the data

% fomc dates
tight = table2timetable(readtable('data\fomc_dates.csv'));

% mpu
mpu_tt = table2timetable(readtable('data\mpu.csv'));
mpu10 = mpu_tt.mpu10; 
mpu = [NaN; mpu10(2:end) - mpu10(1:end-1)]; % daily change
mpu_tt.mpu = mpu;
mpu_tt.mpu_level = mpu10;

% Load VIX 
% Data through 2003 is in vixarchive file
tmp1 = table2timetable(readtable('data\vixarchive.csv'));
vix1 = tmp1(:,'VIXClose');

% Data from 2004 is in vixcurrent
tmp2 = table2timetable(readtable('data\vixcurrent_oct2020.csv'));
vix2 = tmp2(:,'VIXClose');
vix_tt = [vix1;vix2];
vix_tt.dvix = [NaN; vix_tt{2:end,:} - vix_tt{1:end-1,:}];
vix_tt.Properties.VariableNames{1} = 'vix';

alldata = synchronize(tight,mpu_tt);
alldata.Properties.DimensionNames{1} = 'Time';

alldatavix = synchronize(tight,vix_tt);
alldatavix.Properties.DimensionNames{1} = 'Time';

alldatampu = synchronize(tight,mpu_tt);
alldatampu.Properties.DimensionNames{1} = 'Time';


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

effsmpl = timerange(strt_con,last_con,'closed');
alldataeff1vix = alldatavix(effsmpl,:);
alldataeff1mpu = alldatampu(effsmpl,:);
fomcdumvix = ~isnan(alldataeff1vix.MP1);
fomcdummpu = ~isnan(alldataeff1mpu.MP1);

% drop unscheduled FOMC meetings
unsched_ind = alldataeff1vix.Unscheduled;
unsched_ind(isnan(unsched_ind)) = 0;
unsched_dates = alldataeff1vix.Time(logical(unsched_ind));
excl = [excl; unsched_dates]; 


%% VIX Ramp-up   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for fold_vix = 1

vix_level = alldataeff1vix.vix;

standardize = 1;

% 4 nov 1999 is missing
%vix_level_table = array2timetable(vix_level,'RowTime',alldataeff1.Time,'VariableNames',{'mpu_level'});

Tall = length(alldataeff1vix.Time);
daysbeforefomcm1 = NaN(Tall,1);
daysafterfomcm1 = NaN(Tall,1);
chgafterfomcm1 = NaN(Tall,1); % t-1
chgbeforefomcm1 = NaN(Tall,1); % t-1

allfomc_daybefore = lagmatrix(fomcdumvix,-1);
allfomc_daybefore(end) = 0;
% index indicating a 1 for the day before the FOMC meetings in the sample

%ind_ns = find(alldataeff1vix.Time == excl) - 1; % -1 for day before FOMC meeting to be excluded
[~,ind_ns1] = ismember(excl,alldataeff1vix.Time);
ind_ns = ind_ns1 - 1;% -1 for day before FOMC meeting to be excluded

fomc_notin_sample_daybefore = zeros(size(alldataeff1vix.Time));
fomc_notin_sample_daybefore(ind_ns) = 1;
% index indicating a 1 for the day before the FOMC meetings to be excluded

%alldataeff1.fomc_notin_sample_daybefore = lagmatrix(alldataeff1.fomc_notin_sample,-1);
%alldataeff1.fomc_notin_sample_daybefore(end) = 0;

kk = 1;
date_day_before_vix = NaT(length(alldataeff1vix.Time(fomcdumvix))- length(excl),1);
date_2days_after_vix = NaT(length(alldataeff1vix.Time(fomcdumvix))- length(excl),1);
% This loop assigns each date a "daysbeforefomc" and "daysafterfomc"
% number. Similarly for "m1" (i.e. minus 1 or when baseline is day before
% FOMC). It also calculates the change for each day relative to closest
% fomc meeting (both before and after it).
for j = 1:Tall
    
    % find the index of next and previous fomc meeting (relative to
    % "current" day j), so this is finding distance
    indfomc_beforem1 = find(allfomc_daybefore(j:end),1);
    indfomc_afterm1 = find(allfomc_daybefore(j:-1:1,1),1);
    
    if ~isempty(indfomc_beforem1) % to take care of first few obs which are not after any FOMC meetings, because the most recent FOMC meeting is not in the effective sample
        if ~fomc_notin_sample_daybefore(j+indfomc_beforem1-1) % if the next FOMC meeting is not part of excluded fomc meetings
            daysbeforefomcm1(j) = indfomc_beforem1-1;
            chgbeforefomcm1(j) = vix_level(j) - vix_level(j+indfomc_beforem1-1);
        else
            2; % do nothing here means that if the next FOMC meeting is part of excluded sample then set the daysbefore to NaN, i.e. drop
        end
    end
    
    if ~isempty(indfomc_afterm1) % to take care of last few obs which are not before any FOMC meetings, because the next FOMC meeting is not in the effective sample
        if ~fomc_notin_sample_daybefore(j-indfomc_afterm1+1) % % if the previous FOMC meeting is not part of excluded fomc meetings
            daysafterfomcm1(j) = indfomc_afterm1-1;
            chgafterfomcm1(j) = vix_level(j) - vix_level(j-indfomc_afterm1+1);
        else
            2;  % do nothing here means that if the previous FOMC meeting is part of excluded sample then set the daysafter to NaN, i.e. drop
        end
    end
    
    if daysafterfomcm1(j) == 2
        date_day_before_vix(kk) = alldataeff1vix.Time(j-indfomc_afterm1+1);
        date_2days_after_vix(kk) = alldataeff1vix.Time(j);
        kk = kk + 1;
    end
    
end % end for loop


numd = max(unique(daysbeforefomcm1))-2;
% T x numd matrix where each column is a dummy corresponding to j days
% after "day before fomc meeting"
indbeforem1 = daysbeforefomcm1 == 0:numd;
indafterm1 = daysafterfomcm1 == 0:numd;
% Note j starts from 0,1,2,...

% Calculate average for each day before/after FOMC meeting
meancumchgafterm1 = NaN(numd+1,1);
meancumchgbeforem1 = NaN(numd+1,1);
ciscumafterm1 = NaN(numd+1,2);
ciscumbeforem1 = NaN(numd+1,2);
nobscumchgafterm1  = NaN(numd+1,1);
nobscumchgbeforem1 = NaN(numd+1,1);

for jj = 1:numd+1
    
    if standardize
        meancumchgafterm1(jj) = nanmean(chgafterfomcm1(indafterm1(:,jj)))./nanstd(alldataeff1vix.dvix);
        ciscumafterm1(jj,:) = rob_samplemean(chgafterfomcm1(indafterm1(:,jj))./nanstd(alldataeff1vix.dvix));
        meancumchgbeforem1(jj) = nanmean(chgbeforefomcm1(indbeforem1(:,jj)))./nanstd(alldataeff1vix.dvix);
        ciscumbeforem1(jj,:) = rob_samplemean(chgbeforefomcm1(indbeforem1(:,jj))./nanstd(alldataeff1vix.dvix));
    else
        meancumchgafterm1(jj) = nanmean(chgafterfomcm1(indafterm1(:,jj)));
        ciscumafterm1(jj,:) = rob_samplemean(chgafterfomcm1(indafterm1(:,jj)));
        meancumchgbeforem1(jj) = nanmean(chgbeforefomcm1(indbeforem1(:,jj)));
        ciscumbeforem1(jj,:) = rob_samplemean(chgbeforefomcm1(indbeforem1(:,jj)));
    end
        
    nobscumchgafterm1(jj) = sum(~isnan(chgafterfomcm1(indafterm1(:,jj))));
    nobscumchgbeforem1(jj) = sum(~isnan(chgbeforefomcm1(indbeforem1(:,jj))));
    
    
end

plot_ramp = 1;
if plot_ramp
    %%%%%%%%%%%%%%% Plot the ramp-up for vix for (t-1) %%%%%%%%%%%%%%%%%
    calim = 15; % # days after fomc
    xsca = 0:calim-1;
    
    cblim = 15; % # days before fomc
    xscb = -1*(0:1:cblim-1);
    
    Xscum = [fliplr(xscb(2:end)) xsca];
    meancumaroundm1 = [flipud(meancumchgbeforem1(2:cblim)); meancumchgafterm1(1:calim)];
    nobscumaround = [flipud(nobscumchgbeforem1(2:cblim)); nobscumchgafterm1(1:calim)];
    cihim1 = [fliplr(ciscumbeforem1(2:cblim,1)') ciscumafterm1(1:calim,1)'];
    cilowm1 = [fliplr(ciscumbeforem1(2:cblim,2)') ciscumafterm1(1:calim,2)'];
    
    subplot(2,1,2);
    %figure;
    patch([Xscum  fliplr(Xscum )], [cilowm1 fliplr(cihim1)],[.9 .9 .9],'EdgeColor','white'); hold on;
    plot(Xscum,meancumaroundm1);
    hline = refline(0,0); hline.Color = 'k';
    %vline(0,'--r');
    %title('(d)');
    %ylabel('Percent'); % 'FontSize',12
    xlabel('Trading days around the day before FOMC meeting') %,'FontSize',12);
    xlim([-15 15])
    ylim([-1.2 0.6])
    title('VIX');
    line([0,0],[-1.2 0.6],'Color','red','LineStyle','--');
    %title('Change in vix relative to FOMC meeting day "eve"');
    
    
%     set(gcf, 'PaperUnits', 'inches');
%     set(gcf, 'PaperSize', [7 5]);
%     set(gcf, 'PaperPositionMode', 'manual');
%     set(gcf, 'PaperPosition', [0 0 7 5]);
%     set(gcf, 'renderer', 'painters');
    %print(gcf, '-dpdf', '../Figures/vixrampup1.pdf');
end

rampup_tab = [Xscum; meancumaroundm1'; nobscumaround'];

end
%-------------------------------------------------------------------------

%% MPU Ramp-up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for fold_mpurampup = 1
mpu_level = alldataeff1mpu.mpu_level;

standardize = 1;


% 4 nov 1999 is missing
mpu_level_table = array2timetable(mpu_level,'RowTime',alldataeff1mpu.Time,'VariableNames',{'mpu_level'});

Tall = length(alldataeff1mpu.Time);
daysbeforefomcm1 = NaN(Tall,1);
daysafterfomcm1 = NaN(Tall,1);
chgafterfomcm1 = NaN(Tall,1); % t-1
chgbeforefomcm1 = NaN(Tall,1); % t-1

allfomc_daybefore = lagmatrix(fomcdummpu,-1);
allfomc_daybefore(end) = 0;
% index indicating a 1 for the day before the FOMC meetings in the sample

%ind_ns = find(alldataeff1mpu.Time == excl) - 1; % -1 for day before FOMC meeting to be excluded
[~,ind_ns1] = ismember(excl,alldataeff1mpu.Time);
ind_ns = ind_ns1 - 1;% -1 for day before FOMC meeting to be excluded
fomc_notin_sample_daybefore = zeros(size(alldataeff1mpu.Time));
fomc_notin_sample_daybefore(ind_ns) = 1;
% index indicating a 1 for the day before the FOMC meetings to be excluded

%alldataeff1mpu.fomc_notin_sample_daybefore = lagmatrix(alldataeff1mpu.fomc_notin_sample,-1);
%alldataeff1mpu.fomc_notin_sample_daybefore(end) = 0;

kk = 1;
date_day_before_mpu = NaT(length(alldataeff1mpu.Time(fomcdummpu))- length(excl),1);
date_2days_after_mpu = NaT(length(alldataeff1mpu.Time(fomcdummpu))- length(excl),1);
% This loop assigns each date a "daysbeforefomc" and "daysafterfomc"
% number. Similarly for "m1" (i.e. minus 1 or when baseline is day before
% FOMC). It also calculates the change for each day relative to closest
% fomc meeting (both before and after it).
for j = 1:Tall
    
    % find the index of next and previous fomc meeting (relative to
    % "current" day j), so this is finding distance
    indfomc_beforem1 = find(allfomc_daybefore(j:end),1);
    indfomc_afterm1 = find(allfomc_daybefore(j:-1:1,1),1);
    
    if ~isempty(indfomc_beforem1) % to take care of first few obs which are not after any FOMC meetings, because the most recent FOMC meeting is not in the effective sample
        if ~fomc_notin_sample_daybefore(j+indfomc_beforem1-1) % if the next FOMC meeting is not part of excluded fomc meetings
            daysbeforefomcm1(j) = indfomc_beforem1-1;
            chgbeforefomcm1(j) = mpu_level(j) - mpu_level(j+indfomc_beforem1-1);
        else
            2; % do nothing here means that if the next FOMC meeting is part of excluded sample then set the daysbefore to NaN, i.e. drop
        end
    end
    
    if ~isempty(indfomc_afterm1) % to take care of last few obs which are not before any FOMC meetings, because the next FOMC meeting is not in the effective sample
        if ~fomc_notin_sample_daybefore(j-indfomc_afterm1+1) % % if the previous FOMC meeting is not part of excluded fomc meetings
            daysafterfomcm1(j) = indfomc_afterm1-1;
            chgafterfomcm1(j) = mpu_level(j) - mpu_level(j-indfomc_afterm1+1);
        else
            2;  % do nothing here means that if the previous FOMC meeting is part of excluded sample then set the daysafter to NaN, i.e. drop
        end
    end
    
    if daysafterfomcm1(j) == 2
        date_day_before_mpu(kk) = alldataeff1mpu.Time(j-indfomc_afterm1+1);
        date_2days_after_mpu(kk) = alldataeff1mpu.Time(j);
        kk = kk + 1;
    end
    
end % end for loop

numd = max(unique(daysbeforefomcm1))-2;
% T x numd matrix where each column is a dummy corresponding to j days
% after "day before fomc meeting"
indbeforem1 = daysbeforefomcm1 == 0:numd;
indafterm1 = daysafterfomcm1 == 0:numd;
% Note j starts from 0,1,2,...

% Calculate average for each day before/after FOMC meeting
meancumchgafterm1 = NaN(numd+1,1);
meancumchgbeforem1 = NaN(numd+1,1);
ciscumafterm1 = NaN(numd+1,2);
ciscumbeforem1 = NaN(numd+1,2);
nobscumchgafterm1  = NaN(numd+1,1);
nobscumchgbeforem1 = NaN(numd+1,1);

for jj = 1:numd+1
    
    if standardize
        meancumchgafterm1(jj) = nanmean(chgafterfomcm1(indafterm1(:,jj)))./nanstd(alldataeff1mpu.mpu);
        ciscumafterm1(jj,:) = rob_samplemean(chgafterfomcm1(indafterm1(:,jj))./nanstd(alldataeff1mpu.mpu));
        meancumchgbeforem1(jj) = nanmean(chgbeforefomcm1(indbeforem1(:,jj)))./nanstd(alldataeff1mpu.mpu);
        ciscumbeforem1(jj,:) = rob_samplemean(chgbeforefomcm1(indbeforem1(:,jj))./nanstd(alldataeff1mpu.mpu));        
        
    else
        meancumchgafterm1(jj) = nanmean(chgafterfomcm1(indafterm1(:,jj)));
        ciscumafterm1(jj,:) = rob_samplemean(chgafterfomcm1(indafterm1(:,jj)));
        meancumchgbeforem1(jj) = nanmean(chgbeforefomcm1(indbeforem1(:,jj)));
        ciscumbeforem1(jj,:) = rob_samplemean(chgbeforefomcm1(indbeforem1(:,jj)));
    end
    
    nobscumchgafterm1(jj) = sum(~isnan(chgafterfomcm1(indafterm1(:,jj))));
    nobscumchgbeforem1(jj) = sum(~isnan(chgbeforefomcm1(indbeforem1(:,jj))));
end

plot_ramp = 1;
if plot_ramp
    %%%%%%%%%%%%%%% Plot the ramp-up for MPU for (t-1) %%%%%%%%%%%%%%%%%
    calim = 15; % # days after fomc
    xsca = 0:calim-1;
    
    cblim = 15; % # days before fomc
    xscb = -1*(0:1:cblim-1);
    
    Xscum = [fliplr(xscb(2:end)) xsca];
    meancumaroundm1 = [flipud(meancumchgbeforem1(2:cblim)); meancumchgafterm1(1:calim)];
    nobscumaround = [flipud(nobscumchgbeforem1(2:cblim)); nobscumchgafterm1(1:calim)];
    cihim1 = [fliplr(ciscumbeforem1(2:cblim,1)') ciscumafterm1(1:calim,1)'];
    cilowm1 = [fliplr(ciscumbeforem1(2:cblim,2)') ciscumafterm1(1:calim,2)'];
    
    subplot(2,1,1);
    %figure;
    patch([Xscum  fliplr(Xscum )], [cilowm1 fliplr(cihim1)],[.9 .9 .9],'EdgeColor','white'); hold on;
    plot(Xscum,meancumaroundm1);
    hline = refline(0,0); hline.Color = 'k';
    %vline(0,'--r');
    %title('(d)');
    %ylabel('Percent'); % 'FontSize',12
    xlabel('Trading days around the day before FOMC meeting') %,'FontSize',12);
    xlim([-15 15])
    ylim([-1.2 0.6])
    %title('Change in MPU relative to FOMC meeting day "eve"');
    line([0,0],[-1.2 0.6],'Color','red','LineStyle','--');
    title('Monetary Policy Uncertainty');
    title('Short-Rate Uncertainty');
    
   
    
    
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperSize', [7 4]);
    set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 7 4]);
    set(gcf, 'renderer', 'painters');
    %print(gcf, '-dpdf', '../Figures/mpu_vix_rampup.pdf');
end

rampup_tab = [Xscum; meancumaroundm1'; nobscumaround'];

end
%----------------------------d---------------------------------------------
