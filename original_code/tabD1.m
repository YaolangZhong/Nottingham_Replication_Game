% This file has the code for making Table D.1
clear; clc;
addpath('aux_files');

% results are in "tab"

%%%% For 1st column in appendix table set
% sample = 8 (Jan 94 to Dec 17)
% excl_sample = 6, drop_unsched = 1

%%% For 2nd column in appendix table set
% sample = 15 (Lucca-Moench sample)
% excl_sample = 5, drop_unsched = 1

sample = 15;

excl_sample = 5;
% 1 for fin-crisis NS & 9/11, 2 for just 9/11, 3 for Hanson-Stein list,
% 4 for dropping 3 dates from "tight FOMC" sampl  5 for % none
% % 6 for dropping LIBOR-OIS crisis dates

drop_unsched = 1; % drop unscheduled FOMC meetings

%% Load the data

% fomc dates
tight = table2timetable(readtable('data\fomc_dates.csv'));

% mpu
mpu_tt = table2timetable(readtable('data\mpu.csv'));
mpu10 = mpu_tt.mpu10; 
mpu = [NaN; mpu10(2:end) - mpu10(1:end-1)]; % daily change
mpu_tt.mpu = mpu;
mpu_tt.mpu_level = mpu10;

% FOMC Drift
drift_tt =  table2timetable(readtable('data\2019-09-24 FOMC Drift FOMC Dates.csv'));
drift_tt.Properties.VariableNames = {'drift1','drift2','drift3','drift_total'};
tempind = isnat(drift_tt.Time);
drift_tt(tempind,:) = [];

alldata = synchronize(tight,mpu_tt,drift_tt);
alldata.Properties.DimensionNames{1} = 'Time';

%% Assign the sample
for fold_picksample = 1:1
    
    switch sample
        
        
        case 8
            strt_con = datetime(1994,1,1);
            last_con = datetime(2017,12,31);
        case 15
            strt_con = datetime(1994,2,1);
            last_con = datetime(2011,3,31);
    end
    
    nine11 = datetime(2001,9,17);
    switch excl_sample
        case 1
            % Exlude dates around financial crisis
            if last_con > datetime(2009,6,24)
                excl(1) = datetime(2008,8,5); %datenum('8\5\2008');
                excl(2) = datetime(2008,9,16); %(datenum('9\16\2008');
                excl(3) = datetime(2008,10,8); %datenum('10\8\2008');
                excl(4) = datetime(2008,10,29); %datenum('10\29\2008');
                excl(5) = datetime(2008,12,16); %datenum('12\16\2008');
                excl(6) = datetime(2009,1,28); %datenum('1\28\2009');
                excl(7) = datetime(2009,3,18); %datenum('3\18\2009');
                excl(8) = datetime(2009,4,29); %datenum('4\29\2009');
                excl(9) = datetime(2009,6,24); %datenum('6\24\2009');
            elseif strt_con < nine11 && last_con > nine11
                excl(1) = nine11; %datenum('9\17\2001');
            else
                excl = [];
            end
            
        case 2
            if strt_con < nine11 && last_con > nine11
                excl(1) = datetime(2001,9,17); % y,m,d format
            else
                excl=[];
            end
            
        case 3
            excl(1) = datetime(2009,3,18); %datenum('3\18\2009');
            excl(2) = datetime(2010,8,10);
            excl(3) = datetime(2010,9,21);
            excl(4) = datetime(2010,11,3);
            excl(5) = datetime(2011,9,21);
            excl(6) = datetime(2001,9,17); % y,m,d format
            excl(7) = datetime(2007,8,10);  % 10 August 2007
            excl(8) = datetime(2008,12,1);  % 1 December 2008
            
        case 4
            excl(1) = datetime(2007,8,10); %('8/10/2007');  % 10 August 2007
            excl(2) = datetime(2008,3,11); %('3/11/2008');  % 11 March 2008
            excl(3) = datetime(2008,12,1); %('12/1/2008');  % 1 December 2008
        case 5
            excl = [];
        case 6
            crisis_start = datetime(2007,7,1);
            crisis_last = datetime(2009,6,30);
            if last_con > crisis_start
                exclcrisissmpl = timerange(crisis_start,crisis_last,'closed');
                excl = alldata.Time(exclcrisissmpl);
                if strt_con < nine11 && last_con > nine11
                    excl(end+1) = nine11; %datenum('9\17\2001');
                end
                
            elseif strt_con < nine11 && last_con > nine11
                excl(1) = nine11; %datenum('9\17\2001');
            else
                excl = [];
            end
            
    end
end
%--------------------------------------------------------------------------

%% Construct the FOMC sample (excl unsched, fin crisis) & mon pol surprise:

allfomcdata = rmmissing(alldata,'DataVariables',{'MP1'});
% drop non-fomc dates

effsmpl = timerange(strt_con,last_con);
tmpdata = allfomcdata(effsmpl,:); % restrict to selected sample

if ~isempty(excl)
    if datenum(tmpdata.Time(1)) < datenum(excl(1)) || datenum(tmpdata.Time(end)) > datenum(excl(end))
        inremexcl = ismember(excl,tmpdata.Time);
        excl = excl(inremexcl);
        tmpdata(excl,:) = []; % drop any dates in excl list specified above
    end
end

if drop_unsched  % drop unscheduled fomc meetings
    % from fomc meetings used for calc mon pol surprise
    unschind = tmpdata.Unscheduled == 1; % index for unsched fomc
    tmpdata(unschind,:) = []; % drop them
end

fomcdataeff = tmpdata;
% effective sample for constr mon pol surprise & running regressions


%% MPU & FOMC Drift Regressions
for fold_regs = 1
    drift2p3 = fomcdataeff.drift2 + fomcdataeff.drift3;
    fomcdataeff.drift2p3 = drift2p3;
    drifts = fomcdataeff{:,{'drift1','drift2','drift3','drift2p3','drift_total'}};
    mpu = fomcdataeff.mpu;
    
    nn = 1;
    kk = 1;
    ss = 1;
    for jj = 5 %1:length(names)
        drift = drifts(:,jj)*100;
        [reg,~,~,pval,tstat] = olsrob_nodisp(table(drift,mpu));
        
        
        tab(nn,ss) = reg.Coefficients.Estimate(2);
        tab(nn+1,ss) = tstat(2);
        tab(nn+2,ss) = reg.Coefficients.Estimate(1);
        tab(nn+3,ss) = tstat(1);
        tab(nn+4,ss) = reg.Rsquared.Ordinary;
        nn = nn + 6;
                                
    end
    tab(6,ss) = reg.NumObservations;
end

tab