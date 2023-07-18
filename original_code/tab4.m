% This file has the code for making Table 4

% Results are in variable "tab_4a" and "tab_4b"

clear;clc;
addpath('aux_files');

%% Load the data

fomcdata = table2timetable(readtable('data/tab4data.csv'));


assetnames = {'dSVENY05','dSVENY10','dTIPSY10','sp_daily','dvix','dollar_ret_pm'};
scale_factor = [1 1 1  100 1 -100];

nassets = size(assetnames,2);
    
assets_unscaled = fomcdata{:,assetnames};
assets = assets_unscaled.*scale_factor;
mps = fomcdata.mps;
mpu = fomcdata.mpu;
mpu_level_lag = fomcdata.mpu_level_lag;
inter = mps.*mpu_level_lag;

tbl1 = NaN(7,nassets);
tbl2 = NaN(9,nassets);
tbl4 = NaN(13,nassets);

for jj = 1:nassets
    asset = assets(:,jj);
    [reg1 ,~,~,~,opt1.tstat ] = olsrob_nodisp(table(mps,asset));
    [reg2 ,~,~,~,opt2.tstat ] = olsrob_nodisp(table(mps,mpu,asset));
    [reg4 ,~,~,~,opt4.tstat ] = olsrob_nodisp(table(mps,mpu,mpu_level_lag,inter,asset));
       
    tbl1(:,jj) = outreg2(reg1,opt1);
    tbl2(:,jj) = outreg2(reg2,opt2);
    tbl4(:,jj) = outreg2(reg4,opt4);        
end

tab4a = NaN(10,9);
tab4b = NaN(10,9);

% col 1
tab4a([4 5 10],1:3:7) = tbl1([1 2 7],1:3);
tab4b([4 5 10],1:3:7) = tbl1([1 2 7],4:6);

% col 2
tab4a([4:7 10],2:3:8) = tbl2([1:4 9],1:3);
tab4b([4:7 10],2:3:8) = tbl2([1:4 9],4:6);

% col3
tab4a([4:9 10],3:3:9) = tbl4([1:4 7 8 13],1:3)
tab4b([4:9 10],3:3:9) = tbl4([1:4 7 8 13],4:6)
