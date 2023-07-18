% This file has the code for making Table F.1

% Results are in variable "estab" and "stab"

clear;clc;
addpath('aux_files');

%% Load data and create table

alldataeff = table2timetable(readtable('data\tabf1_data.csv'));
esdts = alldataeff.Time(logical(alldataeff.esdummy));

estab = alldataeff(esdts,{'mpu','monshk_daily','dSVENY05','dSVENY10','sp_daily','dvix','dollar_ret_pm'}); % dollar_ret_lead_broad  dollar_ret_pm
%estab = alldataeff(esdts,{'mpu','dSVENY02','dSVENY10','sp_daily','dvix'}); % dollar_ret_lead_broad  dollar_ret_pm
estab{:,[5 7]} = estab{:,[5 7]}.*100; % scale s&p and $ by 100
estab{:,7} = estab{:,7}.*-1

fomcdts = alldataeff.Time(logical(alldataeff.fomcdum));
stab = nanstd(alldataeff{fomcdts,{'mpu','monshk_daily','dSVENY05','dSVENY10','sp_daily','dvix','dollar_ret_pm'}}); % all FOMC days 'dollar_ret_pm'
stab([5 7]) = stab([5 7]).*100; % scale s&p and $ by 100
stab