% This file has the code for making Table F.1

% Results are in variable "estab" and "stab"

clear;clc;
addpath('aux_files');

%% Load data and create table

alldataeff = table2timetable(readtable('data\tabf1_data.csv')); % creates timetable from csv.
esdts = alldataeff.Time(logical(alldataeff.esdummy)); % creates list of dates.

estab = alldataeff(esdts,{'mpu','monshk_daily','dSVENY05','dSVENY10','sp_daily','dvix','dollar_ret_pm','Gold_Ret','Ftse_Ret','Dax_Ret','CHF_Port_Ret','CHF_Spot_Ret','BTC_Ret'}); 
% dollar_ret_lead_broad  dollar_ret_pm
%estab = alldataeff(esdts,{'mpu','dSVENY02','dSVENY10','sp_daily','dvix'}); % dollar_ret_lead_broad  dollar_ret_pm
estab{:,[5 7 8 9 10 11 12 13]} = estab{:,[5 7 8 9 10 11 12 13]}.*100; % scale s&p and $ by 100 - Additionally, scale added values by 100
estab{:,[7 11]} = estab{:,[7 11]}.*-1


fomcdts = alldataeff.Time(logical(alldataeff.fomcdum));
stab = nanstd(alldataeff{fomcdts,{'mpu','monshk_daily','dSVENY05','dSVENY10','sp_daily','dvix','dollar_ret_pm','Gold_Ret','Ftse_Ret','Dax_Ret','CHF_Port_Ret','CHF_Spot_Ret','BTC_Ret'}}); % all FOMC days 'dollar_ret_pm'
stab([5 7 8 9 10 12 13]) = stab([5 7 8 9 10 12 13]).*100; % scale s&p and $ by 100 - Additionally scale added values by 100


% Formatting the output to display three decimal places
formatted_estab = arrayfun(@(x) sprintf('%.3f', x), estab.Variables, 'UniformOutput', false);
formatted_stab = sprintf('%.3f ', stab);

disp(formatted_estab);
disp(formatted_stab);
 