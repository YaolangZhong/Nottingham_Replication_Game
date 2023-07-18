% This file has the code for making Table E.2

% Results are in variable "tfpf" 

clear;clc;
addpath('aux_files');

%% Load data and run regressions

fomcdataeff = table2timetable(readtable('data\tabe2_data.csv'));

assetnames = {'dSVENY05','dSVENY10','sp_daily','dvix','dollar_ret_pm'};
nassets = size(assetnames,2);   
%scale_factor = [ 1 1 100 1 -100];
%fomcdum = logical(alldataeff.fomcdum);    

   
assets = fomcdataeff{:,assetnames}; 

tf = fomcdataeff.tf;
pf = fomcdataeff.pf;
mpu = fomcdataeff.mpu;
%mps = fomcdataeff.mps;
%del = fomcdataeff_fa.del;
%ody = fomcdataeff_fa.ody;
mpu_level_lag = fomcdataeff.mpu_level_lag;

intertf = tf.*mpu_level_lag;
interpf = pf.*mpu_level_lag;

for jj = 1:nassets
    asset = assets(:,jj);
    [reg3 ,~,~,~,opt3.tstat ] = olsrob_nodisp(table(tf,pf,mpu,intertf,interpf,mpu_level_lag,asset));
    tbl3(:,jj) = outreg2(reg3,opt3);
end

tfpf = tbl3;
tfpf(11:16,:) = []

