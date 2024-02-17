% This file has the code for making Table 4

% Results are in variable "tab_4a" and "tab_4b"

clear;clc;
addpath('aux_files');

%% Load the data

fomcdata = table2timetable(readtable('data\tab4data.csv'));


assetnames = {'dSVENY05','dSVENY10','dTIPSY10','sp_daily','dvix','dollar_ret_pm','Gold_Ret','Ftse_Ret','Dax_Ret','Btc_Ret', 'CHF_Port_Ret','CHF_Spot_Ret'};
scale_factor = [1 1 1  100 1 -100 100 100 100 100 -100 100];


nassets = size(assetnames,2);
    
assets_unscaled = fomcdata{:,assetnames};
assets = assets_unscaled.*scale_factor;
mps = fomcdata.mps;
mpu = fomcdata.mpu;
std_mpu = std(mpu);
mpu_level_lag = fomcdata.mpu_level_lag;
inter = mps.*mpu_level_lag;

tbl1 = NaN(7,nassets);
tbl2 = NaN(9,nassets);
tbl4 = NaN(13,nassets);

for jj = 1:nassets
    asset = assets(:,jj);
    [reg1 ,~,~,~,opt1.tstat ] = olsrob(table(mps,asset));
    [reg2 ,~,~,~,opt2.tstat ] = olsrob(table(mps,mpu,asset));
    [reg4 ,~,~,~,opt4.tstat ] = olsrob(table(mps,mpu,mpu_level_lag,inter,asset));
       
    tbl1(:,jj) = outreg2(reg1,opt1);
    tbl2(:,jj) = outreg2(reg2,opt2);
    tbl4(:,jj) = outreg2(reg4,opt4);        
end

tab4a = NaN(10,9);
tab4b = NaN(10,9);
tab4c = NaN(10,18);

% col 1
tab4a([4 5 10],1:3:7) = tbl1([1 2 7],1:3);
tab4b([4 5 10],1:3:7) = tbl1([1 2 7],4:6);
tab4c([4 5 10],1:3:16) = tbl1([1 2 7],7:12);

% col 2
tab4a([4:7 10],2:3:8) = tbl2([1:4 9],1:3);
tab4b([4:7 10],2:3:8) = tbl2([1:4 9],4:6);
tab4c([4:7 10],2:3:17) = tbl2([1:4 9],7:12);

% col3
tab4a([4:9 10],3:3:9) = tbl4([1:4 7 8 13],1:3);
tab4b([4:9 10],3:3:9) = tbl4([1:4 7 8 13],4:6);
tab4c([4:9 10],3:3:18) = tbl4([1:4 7 8 13],7:12);

colindab = 3:3:9;
colindc = 3:3:18;
tab4a3r = tab4a(:,colindab);
tab4b3r = tab4b(:,colindab);
tab4c3r = tab4c(:,colindc);

%tab43r = join(tab4a3r,tab4b3r);

disp('Table 4a, relevant numbers for MPU')
fprintf('%.2f\n', (tab4a3r(6,:)*std_mpu))

disp('Table 4b, relevant numbers for MPU')
fprintf('%.1f\n', (tab4b(6,:)*std_mpu))

disp('Table 4b, relevant numbers for MPU')
fprintf('%.1f\n', (tab4b3r(6,:)*std_mpu))
disp('Specifically the Dollar Index')
fprintf('%.3f\n', (tab4b3r(6,3)*std_mpu))

disp('Table 4c, relevant numbers for MPU')
fprintf('%.2f\n', (tab4c3r(6,:)*std_mpu))



