% I would compare the # of removals/interpolations from pre to stim, b/c
% pre should strictly be from heartbeat or something else
%perhaps mean # of channels involved and summary plot with most frequent
%mean # between the 4 groups
%count instances where stimulated electrode did not get removed in pre but
%did during stim

%% this is to survey all subjects
sbj_num=['03';'04';'05';'42';'43';'13';'15';'17';'18';'21';'22';'24';'25';'26';'29';'30';'20';'23';'27';'28';'36'];
% for i=1:21
%     eval(['trials_',sbj_num(i,:),'=step_01_nr_ac_eeg_anal_ser_data_vis_03_win([''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbj_num(i,:),'''])'])
% end

%% this is for 15, 22
sbj_no='15'

fldr_nm=['pro00087153_00',sbj_no];
file_nm=['pro00087153_00',sbj_no,'_S1-VRdata_preprocessed.mat'];
load(['I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\',fldr_nm,...
    '\analysis\S1-VR_preproc\',file_nm])
figure; hold on
set(gcf,'Position',[882 -225 604 1049])
plot(trialData.eeg.data(:,7))
min_ch7=min(trialData.eeg.data(30000:52000,7));
max_ch18=max(trialData.eeg.data(:,18));
min_ch18=min(trialData.eeg.data(:,18));
plot(trialData.eeg.data(:,18)+min_ch7-max_ch18)
plot(trialData.eeg.sync(:,1)*1000+min_ch7-max_ch18+min_ch18)
max_ch42=max(trialData.eeg.data(:,42)*-1);
plot(trialData.eeg.data(:,42)*-1+min_ch7-max_ch18+min_ch18-max_ch42)
title([fldr_nm,' gen 03'])
legend('C3','C4','VR','current')

%% I copied Allen's script for the processing steps for sbj4

sbj_no='05'

fldr_nm=['pro00087153_00',sbj_no];
file_nm=['pro00087153_00',sbj_no,'_S1-VRdata_preprocessed.mat'];
%load(['I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw',fldr_nm,...
%    '\analysis\S1-VR_preproc\',file_nm])
load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_raw/',fldr_nm,...
    '/analysis/S1-VR_preproc/',file_nm])

figure
plot(trialData.eeg.data(2.5e6:4.5e6,7)*100)
set(gca,'ylim',[-0.5e6 0.5e6])

figure
plot(trialData.eeg.data(2.5e6:4.5e6,18)*100)
set(gca,'ylim',[-0.5e6 0.5e6])


load('/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/PreprocessingCheck/pipeline.mat')

subject='pro00087153_0004';
protocolfolder = 'I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\PreprocessingCheck\';

% Channel
channel=7;

for trial = 1 %this is for pre
    figure;
    sgtitle([subject,' - ',['trial ', num2str(trial)],' - Channel ',num2str(channel)],'Interpreter','none')

    % Plot import
    subplot(6,6,[1 2])
    event_idx = find(cellfun(@(x) x == trial*10+1,{processingData{1}.events.type}));
    event_idx = event_idx(1);
    eventtime = processingData{1}.events(event_idx).latency;
    fs = 1024;
    xdata=processingData{1}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{1}.details)
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(1)=subplot(6,6,3);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Downsample
    subplot(6,6,[7 8])
    fs=256;
    eventtime = processingData{2}.events(event_idx).latency;
    xdata=processingData{2}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{2}.details)
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(2)=subplot(6,6,9);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot High Pass Filter (0.5)
    subplot(6,6,[13 14])
    eventtime = processingData{3}.events(event_idx).latency;
    xdata=processingData{3}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{3}.details)
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(3)=subplot(6,6,15);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Notch Filter
    subplot(6,6,[19 20])
    eventtime = processingData{4}.events(event_idx).latency;
    xdata=processingData{4}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{4}.details)
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(4)=subplot(6,6,21);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Epoched
    subplot(6,6,[25 26])
    eventtime = processingData{5}.events{trial}(1).latency;
    xdata=processingData{5}.data{trial}(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{5}.details{trial})
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(5)=subplot(6,6,27);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot ICA removed
    subplot(6,6,[31 32])
    eventtime = processingData{6}.events{trial}(1).latency;
    xdata=processingData{6}.data{trial}(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{6}.details{trial})
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(6)=subplot(6,6,33);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot find bad channels and interpolate
    subplot(6,6,[4 5])
    eventtime = processingData{7}.events{trial}(1).latency;
    xdata=processingData{7}.data{trial}(channel,eventtime:eventtime+(1*fs),1);
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{7}.details{trial})
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(7)=subplot(6,6,6);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Artifact Subspace Reconstruction
    subplot(6,6,[10 11])
    eventtime = processingData{8}.events{trial}.latency;
    xdata=processingData{8}.data{trial}(channel,eventtime:eventtime+(1*fs),1);
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{8}.details{trial})
    xlim([0 ydata(end)])
    ylim([-40 40]);

    ph(8)=subplot(6,6,12);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])
end

for trial = [1:2] %this is for intra5
    figure;
    sgtitle([subject,' - ',['trial ', num2str(trial)],' - Channel ',num2str(channel)],'Interpreter','none')

    % Plot import
    subplot(6,6,[1 2])
    event_idx = find(cellfun(@(x) x == trial*10+1,{processingData{1}.events.type}));
    event_idx = event_idx(1);
    eventtime = processingData{1}.events(event_idx).latency;
    fs = 1024;
    xdata=processingData{1}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{1}.details)
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(1)=subplot(6,6,3);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Downsample
    subplot(6,6,[7 8])
    fs=256;
    eventtime = processingData{2}.events(event_idx).latency;
    xdata=processingData{2}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{2}.details)
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(2)=subplot(6,6,9);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot High Pass Filter (0.5)
    subplot(6,6,[13 14])
    eventtime = processingData{3}.events(event_idx).latency;
    xdata=processingData{3}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{3}.details)
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(3)=subplot(6,6,15);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Notch Filter
    subplot(6,6,[19 20])
    eventtime = processingData{4}.events(event_idx).latency;
    xdata=processingData{4}.data(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{4}.details)
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(4)=subplot(6,6,21);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Epoched
    subplot(6,6,[25 26])
    eventtime = processingData{5}.events{trial}(1).latency;
    xdata=processingData{5}.data{trial}(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{5}.details{trial})
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(5)=subplot(6,6,27);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot ICA removed
    subplot(6,6,[31 32])
    eventtime = processingData{6}.events{trial}(1).latency;
    xdata=processingData{6}.data{trial}(channel,(eventtime):(eventtime)+(1*fs));
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{6}.details{trial})
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(6)=subplot(6,6,33);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot find bad channels and interpolate
    subplot(6,6,[4 5])
    eventtime = processingData{7}.events{trial}(1).latency;
    xdata=processingData{7}.data{trial}(channel,eventtime:eventtime+(1*fs),1);
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{7}.details{trial})
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(7)=subplot(6,6,6);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])

    % Plot Artifact Subspace Reconstruction
    subplot(6,6,[10 11])
    eventtime = processingData{8}.events{trial}.latency;
    xdata=processingData{8}.data{trial}(channel,eventtime:eventtime+(1*fs),1);
    ydata=(1:numel(xdata))/fs;
    plot(ydata,xdata)
    title(processingData{8}.details{trial})
    xlim([0 ydata(end)])
    ylim([-100 130]);

    ph(8)=subplot(6,6,12);
    [pxx,f]=pwelch(xdata,[],[],[],fs);
    plot(f,log10(pxx));
    xlim([0 100])
    ylim([-4 0.5])
end

%Create sections - pretty cool!
figure
subplot(5, 1, 1)
fs = 1024;
xdata=processingData{1}.data(channel,:);
ydata=(1:numel(xdata))/fs;
title(processingData{1}.details)
hold on
% for i = 1:4
%     rectangle('Position',[processingData{1}.vr(i,1)/fs,-200,(processingData{1}.vr(i,2)-processingData{1}.vr(i,1))/fs,400],'FaceColor','yellow')
% end
plot(ydata,xdata)
xlim([0 ydata(end)])
ylim([-200 200]);

for i = 1:4
    subplot(5,1,1+i)
    xdata=processingData{5}.data{i}(channel,:);
    ydata=(1:numel(xdata))/256;
    plot(ydata,xdata)
    hold on
    xdata=processingData{8}.data{i}(channel,:);
    ydata=(1:numel(xdata))/256;
    plot(ydata,xdata)
    title(['trial',num2str(i)])
    if i==1
        ylim([-20 20])
    else
        ylim([-200 200])
    end
end
hl = legend({'original','processed'});


%% here I am manually putting in values from the spreadsheet I made

chans_trials_01=[2,0,16,5,0,10,9,5,17,0,13,0,11,17,11,0,18,17,0,14,9]
chans_trials_02=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21]

[chans_trials_sort_01,n]=sort(chans_trials_01,'ascend')
chans_trials_sort_02=chans_trials_02(n)

chans_trials_sort_all=[chans_trials_sort_01;chans_trials_sort_02]

figure; barh(chans_trials_sort_01)



% cs_stm=[3(9),4(6),5(10),42(11),43(3)]39=22.5
% cs_non=[13(7),15(4),17(17),18(8),21(5)]41=23.7
% hc_stm=[22(1),24(19),25(5),26(5),29(5),30(6)]41=23.7
% hc_non=[20(8),23(9),27(14),28(9),36(12)]52=30.0

% isolated
1,1,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,6,6,6,6,6,9,9,9,9,9,9,11,11,14,14,14,14,14,14
15,15,17,17,17,17,17,17,17,17,17,17,18,18,18,18,18,20,20,20,21,

%stim-induced
6,7,7,7,7,7,7,7,7,7,8,8,8,8,8,9,9,9,11,11,11,13,13,13,14,14,14,15,15,15,15,15,
20,20,20,

%all bad
3,3,3,3,6,6,6,6,9,9,9,9,9,9,9,9,11,11,11,11,11,11,11,11,13,13,13,13,13,13,13,13
14,14,14,14,14,14,14,14,15,15,15,15,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,
18,18,18,18,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,

y=[2 0 0;0 0 0;5 1 4;0 0 0;6 3 8;12 0 4;0 9 0;2 3 8;5 0 0;0 5 0;1 0 8;0 0 0;0 0 0;
    0 0 0;0 0 0;10 0 8;0 3 8;2 3 8;5 0 12;6 3 8;3 3 8;1 0 8;0 0 0;2 5 4;0 0 0]
figure; bar(y,'stacked')






%bar plot of how many of these were in stim vs sham groups
%bar plot of how many were placed on C3 vs C4
%bar plot of many were changed due to stim (in other words were not
%interpolated in pre and/or post state) vs how many were interpolated
%throughout