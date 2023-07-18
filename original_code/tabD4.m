% This file has the code for making Table D.4
% Results are in variable "sumstat_tab"

clear;clc;
addpath('aux_files');


%% Load the data

mpu_speech = table2timetable(readtable('data\mpu_speech.csv'));

var_names = {'ALL','GREENSPAN','BERNANKE','YELLEN'};
dum_list = [mpu_speech.allspeech_dum mpu_speech.greenspan_dum mpu_speech.bernanke_dum mpu_speech.yellen_dum];
nvars = length(var_names);

nanlength = @(x) sum(~isnan(x));
%sumstat_labels = {'Obs';'Mean';'tstat';'Median';'Std';'Skewness';'Kurtosis';'Min';'Max';'pval'};
sumstat_labels = {'Obs';'Mean';'tstat';'Std';'Cumulative change'};

%func_list = {nanlength,@nanmean,@rob_samplemean_tstat,@nanmedian,@nanstd,@skewness,@kurtosis,@nanmin,@nanmax};
func_list = {nanlength,@nanmean,@rob_samplemean_tstat,@nanstd,@nansum};

sumstat_tab = table(sumstat_labels,NaN(length(sumstat_labels),1));


for jj = 1:nvars
    tmpname = var_names{jj};
    tmpind = logical(mpu_speech{:,jj+4});
    tmpdta = mpu_speech.mpu(tmpind);
    
    tmpvals = NaN(length(func_list),1);
    for kk = 1:length(func_list)
        if ~isempty(tmpdta)
            tmpvals(kk) = func_list{kk}(tmpdta);
        else
            tmpvals(kk) = NaN;
        end
    end
    %[~,pval] = ttest(tmpdta);
    %tmpvals(kk+1) = pval;
    sumstat_tab.(tmpname) = tmpvals;    

end

sumstat_tab.Var2 = []
%sumtab = sumstat_tab{1:end-1,2:end};
%ptab = sumstat_tab{end,2:end};
%--------------------------------------------------------------------------