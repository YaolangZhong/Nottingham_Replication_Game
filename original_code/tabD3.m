% This file has the code for making Table D.3
% Results are in variable "final_table"

clear; clc;
addpath('aux_files');

%% Load the data & run the regressions

news = table2timetable(readtable('data\news_reg_data.csv'));

[reg1,~,~,~,opt1.tstat] = olsrob_nodisp(table(news.sched_ind, news.empall_ind, news.cpiall_ind, news.ppiall_ind,news.retall_ind,news.gdpall_ind,news.ismall_ind, news.mpu));
[reg2,~,~,~,opt2.tstat] = olsrob_nodisp(table(news.sched_ind,news.empall_ind, news.cpiall_ind, news.ppiall_ind,news.retall_ind,news.gdpall_ind,news.ismall_ind, news.sched_surp,news.empall_surp,news.cpiall_surp, news.ppiall_surp,news.retall_surp,news.gdpall_surp,news.ismall_surp, news.mpu));
[reg3,~,~,~,opt3.tstat] = olsrob_nodisp(table(news.sched_ind,news.empall_ind, news.cpiall_ind, news.ppiall_ind,news.retall_ind,news.gdpall_ind,news.ismall_ind,abs(news.sched_surp),abs(news.empall_surp), abs(news.cpiall_surp), abs(news.ppiall_surp),abs(news.retall_surp),abs(news.gdpall_surp),abs(news.ismall_surp), news.mpu));

col1= outreg2(reg1,opt1);
col2= outreg2(reg2,opt2);
col3= outreg2(reg3,opt3);

final_table = [col1([1:16 18:19]) col2([15:30 32:33]) col3([15:30 32:33])] 
