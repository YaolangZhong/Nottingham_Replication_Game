% Code written by Miquel and Cristina
clear;clc;
%addpath('C:/Users/lexmg15/Google_Drive/Nottingham/ReplicationGames/Paper_candidates/Bauer_Lakdawala_Mueller_MarketBasedMP/replication_package/aux_files');
addpath('/Users/cgriffa/My Drive/Nottingham/ReplicationGames/Paper_candidates/Bauer_Lakdawala_Mueller_MarketBasedMP/replication_package/aux_files');

%% Load the data
% run tab2.m to load the data

%% Analysis of trends around announcement dates
% create bandwidths of 5 and 10 days 
bandwidths=[5,10];
% set number of periods
[T,~]=size(alldata.allfomc);
% predefine the new variables (column 1 for bandwith 5 and column 2 for bw 10
alldata.T_pre=zeros(T,2); 
alldata.T_post=zeros(T,2);
alldata.T_preSche=zeros(T,2);
alldata.T_postSche=zeros(T,2);
alldata.T_postSkip1=zeros(T,2);

% Example for bw=5
% alldataT_pre(t,1) will take the value of:
%        0 if there isn't a meeting in the next 5 days
%       -1 if at t+1 there is an FOMC meeting (allfomc==1)
% alldata.T_post(t,1) will take the value of:
%       0 if there wasn't a meeting in the last 5 days
%       +1 if at t-1 there is an FOMC meeting
for band=1:2
    T_meet=0; % T_meet is the next meeting's time
    while T_meet<T
        T_meet=T_meet+1;
        % i) Find the next meeting
        while alldata.allfomc(T_meet)==0 && T_meet<T
            T_meet=T_meet+1;
        end 
        if T_meet==T
            break
        end    
        % ii) Around the previously found T_meet, assign the number of days
        % away from the T_meet
        for t=1:bandwidths(band)
            alldata.T_pre(T_meet-t,band)=-t;
            alldata.T_post(T_meet+t,band)=t;
        % same as in ii) but just accounting for the scheduled meetings 
            if alldata.Unscheduled(T_meet)==0
                alldata.T_preSche(T_meet-t,band)=-t;
                alldata.T_postSche(T_meet+t,band)=t;
                % skip the day after the meeting 
                if t>1
                    alldata.T_postSkip1(T_meet+t,band)=t;
                end
            end
        %}
        end

    end
    
%% Regressions: test the change in trend around the meeting date 
% Baseline case: x1 is a dummy (alldata.allfomc), x2 is T_pre and x3 is T_post 
X=[alldata.allfomc,alldata.T_pre(:,band),alldata.T_post(:,band)];
olsrob_nodisp(X,alldata.mpu)

plot([1:T],alldata.mpu)
sum(alldata.mpu)/T

% only for scheduled meetings
X=[alldata.allfomc,alldata.T_preSche(:,band),alldata.T_postSche(:,band)];
olsrob_nodisp(X,alldata.mpu)

% skipping day 1 after meeting
X=[alldata.allfomc,alldata.T_preSche(:,band),alldata.T_postSkip1(:,band)];
olsrob_nodisp(X,alldata.mpu)
end