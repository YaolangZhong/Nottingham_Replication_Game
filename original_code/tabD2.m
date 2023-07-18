% This file has the code for making Table D.2
% Results are in variable "tbl"

clear; clc;
addpath('aux_files');

%% Load the data & run the regressions

fomc = table2timetable(readtable('data\gss_af.csv'));

mpu = fomc.mpu;
mps = fomc.monshk_daily;
tf_gss = fomc.tf;
pf_gss = fomc.pf;
tf_fa = fomc.tf_fa;
del = fomc.del;
ody = fomc.ody;

% Column 1
[reg1,~,~,~,opt1.tstat] = olsrob_nodisp(table(mps,mpu));

% Column 2
[reg2,~,~,~,opt2.tstat] = olsrob_nodisp(table(tf_gss,pf_gss,mpu));

% Coulmn 3
[reg3,~,~,~,opt3.tstat] = olsrob_nodisp(table(tf_fa,del,ody,mpu));
    

tbl([1:5 10:11],1) = outreg2(reg1,opt1);
tbl([1:7 10:11],2) = outreg2(reg2,opt2);
tbl(:,3) = outreg2(reg3,opt3)