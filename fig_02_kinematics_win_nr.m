%% will work on 3D plots

load('papers-roddey-tdcs-eeg-vr/pro00087153_0005_S1-VRdata_preprocessed.mat')


%sbj 5 pre
reach1=[500:2000];
reach2=[2000:2500];
reach8=[6600:7600];

reach3=[2500:3000];
reach4=[3000:4000];
reach12=[10600:10899];

reach5=[4000:4600];
reach7=[5600:6600];
reach9=[7600:8600];

reach6=[4600:5600];
reach10=[8600:9600];
reach11=[9600:10600];

figure; hold on
plot3(trialData.vr(1).tracker.p.left(reach1,1),trialData.vr(1).tracker.p.left(reach1,2),trialData.vr(1).tracker.p.left(reach1,3),'r','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach2,1),trialData.vr(1).tracker.p.left(reach2,2),trialData.vr(1).tracker.p.left(reach2,3),'r','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach3,1),trialData.vr(1).tracker.p.left(reach3,2),trialData.vr(1).tracker.p.left(reach3,3),'Color',[0.7 0.7 0.7],'Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach4,1),trialData.vr(1).tracker.p.left(reach4,2),trialData.vr(1).tracker.p.left(reach4,3),'Color',[0.7 0.7 0.7],'Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach5,1),trialData.vr(1).tracker.p.left(reach5,2),trialData.vr(1).tracker.p.left(reach5,3),'Color',[1 0.5 0.8],'Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach6,1),trialData.vr(1).tracker.p.left(reach6,2),trialData.vr(1).tracker.p.left(reach6,3),'b','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach7,1),trialData.vr(1).tracker.p.left(reach7,2),trialData.vr(1).tracker.p.left(reach7,3),'Color',[1 0.5 0.8],'Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach8,1),trialData.vr(1).tracker.p.left(reach8,2),trialData.vr(1).tracker.p.left(reach8,3),'r','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach9,1),trialData.vr(1).tracker.p.left(reach9,2),trialData.vr(1).tracker.p.left(reach9,3),'Color',[1 0.5 0.8],'Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach10,1),trialData.vr(1).tracker.p.left(reach10,2),trialData.vr(1).tracker.p.left(reach10,3),'b','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach11,1),trialData.vr(1).tracker.p.left(reach11,2),trialData.vr(1).tracker.p.left(reach11,3),'b','Linewidth',1)
plot3(trialData.vr(1).tracker.p.left(reach12,1),trialData.vr(1).tracker.p.left(reach12,2),trialData.vr(1).tracker.p.left(reach12,3),'Color',[0.7 0.7 0.7],'Linewidth',1)
xlabel('x')
ylabel('y')
zlabel('z')
set(gca,'View',[49.2496 58.3385],'visible','off')
grid on
title('pre')
%legend

%sbj 5 i15
reach1b=[700:1500];
reach2b=[1500:2500];
reach8b=[6000:6600];

reach3b=[2500:3200];
reach4b=[3200:4200];
reach12b=[9000:9680];

reach5b=[4200:4600];
reach7b=[5600:6000];
reach9b=[6600:7600];

reach6b=[4600:5600];
reach10b=[7600:8600];
reach11b=[8600:9000];

figure; hold on
plot3(trialData.vr(3).tracker.p.left(reach1b,1),trialData.vr(3).tracker.p.left(reach1b,2),trialData.vr(3).tracker.p.left(reach1b,3),'b','Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach2b,1),trialData.vr(3).tracker.p.left(reach2b,2),trialData.vr(3).tracker.p.left(reach2b,3),'Color',[0.7 0.7 0.7],'Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach3b,1),trialData.vr(3).tracker.p.left(reach3b,2),trialData.vr(3).tracker.p.left(reach3b,3),'Color',[0.7 0.7 0.7],'Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach4b,1),trialData.vr(3).tracker.p.left(reach4b,2),trialData.vr(3).tracker.p.left(reach4b,3),'Color',[1 0.5 0.8],'Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach5b,1),trialData.vr(3).tracker.p.left(reach5b,2),trialData.vr(3).tracker.p.left(reach5b,3),'r','Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach6b,1),trialData.vr(3).tracker.p.left(reach6b,2),trialData.vr(3).tracker.p.left(reach6b,3),'r','Linewidth',1)%
plot3(trialData.vr(3).tracker.p.left(reach7b,1),trialData.vr(3).tracker.p.left(reach7b,2),trialData.vr(3).tracker.p.left(reach7b,3),'r','Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach8b,1),trialData.vr(3).tracker.p.left(reach8b,2),trialData.vr(3).tracker.p.left(reach8b,3),'b','Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach9b,1),trialData.vr(3).tracker.p.left(reach9b,2),trialData.vr(3).tracker.p.left(reach9b,3),'Color',[0.7 0.7 0.7],'Linewidth',1)
plot3(trialData.vr(3).tracker.p.left(reach10b,1),trialData.vr(3).tracker.p.left(reach10b,2),trialData.vr(3).tracker.p.left(reach10b,3),'b','Linewidth',1)
plot3(trialData.vr(3).tracker.p.left(reach11b,1),trialData.vr(3).tracker.p.left(reach11b,2),trialData.vr(3).tracker.p.left(reach11b,3),'Color',[1 0.5 0.8],'Linewidth',1)%%%
plot3(trialData.vr(3).tracker.p.left(reach12b,1),trialData.vr(3).tracker.p.left(reach12b,2),trialData.vr(3).tracker.p.left(reach12b,3),'Color',[1 0.5 0.8],'Linewidth',1)%
xlabel('x')
ylabel('y')
zlabel('z')
set(gca,'View',[49.2496 58.3385],'zlim',[0.25 0.5],'xlim',[-0.15 0.15],'visible','off')
grid on
title('i15')
%legend

%% velocity curves - taken from Christian's calculateVRMetrics function

%fig on the left is sbj 5
%fig on the right is sbj 21
% downloaded these from Box/PreprocessedData_Rowland from individual sbject
% folders and then changed the transparency's in Illustrator
subjects(1).id   = 'pro00087153_0005';
subjects(1).name = 'Chronic Stroke Stim';
subjects(2).id   = 'pro00087153_0021';
subjects(2).name = 'Chronic Stroke Sham';

sessionNames  = {'pre stim','early stim (5 min)','late stim (15 min)','post stim'};
sessionColors = {[0 0 0], [1 0 0], [1 0 0], [0 0 0.8]};
sessionStyles = {'-','-','--','-'};
sessionIdx    = [1 2 3 4];

dataRoot = '/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_raw';

fh = figure('Name','Fig 2B velocity profiles','Position',[100 100 1100 380]);

for g = 1:numel(subjects)
    vrFile = fullfile(dataRoot, subjects(g).id, 'analysis', 'S1-VR_preproc', ...
        [subjects(g).id '_S1-VRdata_preprocessed.mat']);
    d = load(vrFile);

    subplot(1, numel(subjects), g); hold on
    lh = gobjects(numel(sessionNames),1);

    for s = 1:numel(sessionNames)
        tIdx        = sessionIdx(s);
        oneTrial    = d.trialData.vr(tIdx);
        envSettings = d.trialData.vr(tIdx).environment.settings.Settings;

        hFigs = [figure('Visible','off'), figure('Visible','off')];
        vrm = calculateVRMetrics(oneTrial, envSettings, hFigs, ...
            sessionColors{s}, sessionStyles{s}, 0);
        close(hFigs);

        Vmat = vrm.V_plot;
        mu  = mean(Vmat, 2, 'omitnan');
        sd = std(Vmat, 0, 2, 'omitnan');
        t   = vrm.t(:);

        patch([t; flipud(t)], [mu-sd; flipud(mu+sd)], sessionColors{s}, ...
              'FaceAlpha', 0.15, 'EdgeColor', 'none');

        lh(s) = plot(t, mu, 'Color', sessionColors{s}, ...
                     'LineStyle', sessionStyles{s}, 'LineWidth', 2);
    end

    title(subjects(g).name,'FontWeight','normal')
    xlabel('% Reach'); ylabel('Velocity (m/s)'); xlim([0 100])
    set(gca,'Box','off','TickDir','out')
    if g == 1
        legend(lh, sessionNames, 'Location','northeast','Box','off')
    end
end

axs = findall(fh,'Type','axes');
yls = cell2mat(get(axs,'YLim'));
for a = axs', ylim(a, [min(yls(:,1)) max(yls(:,2))]); end

%% line and bar plots

%% individual line plots - all kinematics

sbjs_cs=['03';'04';'05';'42';'43';'13';'15';'17';'18';'21'];
figure
set(gcf,'Position',[35 230 1285 715])
for i=1:10
    eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_cs(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''MATLAB Drive/papers-roddey-tdcs-eeg-vr/pro00087153_00',sbjs_cs(i,:),'/S2-metrics\pro00087153_00',sbjs_cs(i,:),'_S2-Metrics.mat'')'])

    for j=2:13
        subplot(2,6,j-1); hold on
        plot(metricdat.data{1,j}(1:4),'Marker','o','MarkerSize',10,'LineWidth',2)
        set(gca,'XTick',[1:4],'XTickLabel',['BL';'ES';'LS';'PS'])
        title(metricdat.label{1,j})
    end
    if i==10
        legend('03','04','05','42','43','13','15','17','18','21')
    end
end
sgtitle('chronic stroke')

sbjs_hc=['22';'24';'25';'26';'29';'30';'20';'23';'27';'28';'36'];
figure
set(gcf,'Position',[35 230 1285 715])
for i=1:11
    eval(['load(''MATLAB Drive/papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_hc(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_hc(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_hc(i,:),'_S2-Metrics.mat'')'])
    for j=2:13
        subplot(2,6,j-1); hold on
        plot(metricdat.data{1,j}(1:4),'Marker','o','MarkerSize',10,'LineWidth',2)
        set(gca,'XTick',[1:4],'XTickLabel',['BL';'ES';'LS';'PS'])
        title(metricdat.label{1,j})
    end
    if i==11
        legend('22','24','25','26','29','30','20','23','27','28','36')
    end
end
sgtitle('healthy control')

%% group line plots - all kinematics

sbjs_cs_stm=['03';'04';'05';'42';'43'];
for i=1:5
    eval(['load(''MATLAB Drive/papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_cs_stm(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_cs_stm(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_cs_stm(i,:),'_S2-Metrics.mat'')'])
    for j=1:13
        for k=1:4
            eval(['cs_stm_kin',num2str(j),'(i,k)=metricdat.data{1,j}(k);'])
        end
    end
    clear t* s2* move* metric*
end

sbjs_cs_non=['13';'15';'17';'18';'21'];
for i=1:5
    eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_cs_non(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_cs_non(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_cs_non(i,:),'_S2-Metrics.mat'')'])
    for j=1:13
        for k=1:4
            eval(['cs_non_kin',num2str(j),'(i,k)=metricdat.data{1,j}(k);'])
        end
    end
    clear t* s2* move* metric*
end

sbjs_hc_stm=['22';'24';'25';'26';'29';'30'];
for i=1:6
    eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_hc_stm(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_hc_stm(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_hc_stm(i,:),'_S2-Metrics.mat'')'])
    for j=1:13
        for k=1:4
            eval(['hc_stm_kin',num2str(j),'(i,k)=metricdat.data{1,j}(k);'])
        end
    end
    clear t* s2* move* metric*
end

sbjs_hc_non=['20';'23';'27';'28';'36'];
for i=1:5
    eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_hc_non(i,:),'_S2-Metrics.mat'')'])
    %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_hc_non(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_hc_non(i,:),'_S2-Metrics.mat'')'])
    for j=1:13
        for k=1:4
            eval(['hc_non_kin',num2str(j),'(i,k)=metricdat.data{1,j}(k);'])
        end
    end
    clear t* s2* move* metric*
end
        
for i=1:13
    eval(['mean_kin',num2str(i),'_cs_stm=mean(cs_stm_kin',num2str(i),');'])
    eval(['se_kin',num2str(i),'_cs_stm=std(cs_stm_kin',num2str(i),')/sqrt(5);'])
    
    eval(['mean_kin',num2str(i),'_cs_non=mean(cs_non_kin',num2str(i),');'])
    eval(['se_kin',num2str(i),'_cs_non=std(cs_non_kin',num2str(i),')/sqrt(5);'])
    
    eval(['mean_kin',num2str(i),'_hc_stm=mean(hc_stm_kin',num2str(i),');'])
    eval(['se_kin',num2str(i),'_hc_stm=std(hc_stm_kin',num2str(i),')/sqrt(6);'])
    
    eval(['mean_kin',num2str(i),'_hc_non=mean(hc_non_kin',num2str(i),');'])
    eval(['se_kin',num2str(i),'_hc_non=std(hc_non_kin',num2str(i),')/sqrt(5);'])
end
    
figure % this is for cs group - looks exact same as allen's
set(gcf,'Position',[35 230 1285 715])
load('papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_0003_S2-Metrics.mat','metricdat')
%load('I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_0003\analysis\S2-metrics\pro00087153_0003_S2-Metrics.mat','metricdat')
for j=2:13
    subplot(2,6,j-1); hold on
    eval(['plot(mean_kin',num2str(j),'_cs_stm,''g'')'])
    eval(['errorbar(mean_kin',num2str(j),'_cs_stm,se_kin',num2str(j),'_cs_stm,''g'')'])
    eval(['plot(mean_kin',num2str(j),'_cs_non,''r'')'])
    eval(['errorbar(mean_kin',num2str(j),'_cs_non,se_kin',num2str(j),'_cs_non,''r'')'])
    %plot(metricdat.data{1,j}(1:4),'Marker','o','MarkerSize',10,'LineWidth',2)
    set(gca,'XTick',[1:4],'XTickLabel',['BL';'ES';'LS';'PS'])
    title(metricdat.label{1,j})
    if j==7
        legend('stim','','sham')
    end
end
sgtitle('chronic stroke')

figure%compared to allen's healthy group and looks exactly same
set(gcf,'Position',[35 230 1285 715])
for j=2:13
    subplot(2,6,j-1); hold on
    eval(['plot(mean_kin',num2str(j),'_hc_stm,''g'')'])
    eval(['errorbar(mean_kin',num2str(j),'_hc_stm,se_kin',num2str(j),'_hc_stm,''g'')'])
    eval(['plot(mean_kin',num2str(j),'_hc_non,''r'')'])
    eval(['errorbar(mean_kin',num2str(j),'_hc_non,se_kin',num2str(j),'_hc_non,''r'')'])
    %plot(metricdat.data{1,j}(1:4),'Marker','o','MarkerSize',10,'LineWidth',2)
    set(gca,'XTick',[1:4],'XTickLabel',['BL';'ES';'LS';'PS'])
    title(metricdat.label{1,j})
    if j==7
        legend('stim','','sham')
    end
end
sgtitle('healthy control')

%% group bar plots - anova1

grp_var_5x4_01=[linspace(1,1,12)',linspace(2,2,12)',linspace(3,3,12)',linspace(4,4,12)'];
grp_var_5x4_02=[linspace(1,1,5)',linspace(2,2,5)',linspace(3,3,5)',linspace(4,4,5)'];

kin_lbl={'movementDuration';'reactionTime';'handpathlength';'avgVelocity';'maxVelocity';'velocityPeaks';...
    'timetoMaxVelocity';'timetoMaxVelocitynorm';'avgAcceleration';'maxAcceleration';...
    'accuracy';'normalizedjerk';'IOC'};
%kin_idx=10;

sbjs_cs_stm=['03';'04';'05';'42';'43'];
for k=1:13
    for i=1:5
        eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_cs_stm(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        eval(['mean_kin_',num2str(k),'_',sbjs_cs_stm(i,:),'=metricdat.data{1,k}(:,1:4);'])
    %     eval(['se_kin_',sbjs_cs_stm(i,:),'=std(metricdat.data{1,kin_idx}(:,1:4))/sqrt(5);'])
    %     eval(['[a1_kin_',sbjs_cs_stm(i,:),'_p,a1_kin_',sbjs_cs_stm(i,:),'_anovatab,a1_kin_',sbjs_cs_stm(i,:),'_stats]=',...
    %         'anova1(metricdat.data{1,kin_idx}(:,1:4),[],''off'');'])
    %     
    end
end
% mean_mean_kin_cs_stm=mean([mean_kin_03;mean_kin_04;mean_kin_05;mean_kin_42;mean_kin_43]);
% se_mean_kin_cs_stm=std([mean_kin_03;mean_kin_04;mean_kin_05;mean_kin_42;mean_kin_43])/sqrt(5);
% [a1_mean_mean_kin_cs_stm_p,a1_mean_mean_kin_cs_stm_anovatab,a1_mean_mean_kin_cs_stm_stats]=...
%     anova1([mean_kin_03;mean_kin_04;mean_kin_05;mean_kin_42;mean_kin_43],[],'off');

% for k=1:13
%     eval(['gp_anova2_cs_stm_',kin_lbl{k},'_mat=[mean_kin_',num2str(k),'_03'',mean_kin_',num2str(k),'_04'',mean_kin_',num2str(k),'_05'',mean_kin_',num2str(k),'_42'',mean_kin_',num2str(k),'_43'']']) 
%     eval(['dlmwrite(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\stats\metrics\gp_anova2_cs_stm_',kin_lbl{k},'.txt'',gp_anova2_cs_stm_',kin_lbl{k},'_mat)'])
% end

sbjs_cs_non=['13';'15';'17';'18';'21'];
for k=1:13
    for i=1:5
        eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_cs_non(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_cs_non(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_cs_non(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        eval(['mean_kin_',num2str(k),'_',sbjs_cs_non(i,:),'=metricdat.data{1,k}(:,1:4);'])
    %     eval(['se_kin_',sbjs_cs_non(i,:),'=nanstd(metricdat.data{1,kin_idx}(:,1:4))/sqrt(5);'])
    %     eval(['[a1_kin_',sbjs_cs_non(i,:),'_p,a1_kin_',sbjs_cs_non(i,:),'_anovatab,a1_kin_',sbjs_cs_non(i,:),'_stats]=',...
    %         'anova1(metricdat.data{1,kin_idx}(:,1:4),[],''off'');'])
    end
end
% mean_mean_kin_cs_non=mean([mean_kin_13;mean_kin_15;mean_kin_17;mean_kin_18;mean_kin_21]);
% se_mean_kin_cs_non=std([mean_kin_13;mean_kin_15;mean_kin_17;mean_kin_18;mean_kin_21])/sqrt(5);
% [a1_mean_mean_kin_cs_non_p,a1_mean_mean_kin_cs_non_anovatab,a1_mean_mean_kin_cs_non_stats]=...
%     anova1([mean_kin_13;mean_kin_15;mean_kin_17;mean_kin_18;mean_kin_21],[],'off');

% for k=1:13
%     eval(['gp_anova2_cs_non_',kin_lbl{k},'_mat=[mean_kin_',num2str(k),'_13'',mean_kin_',num2str(k),'_15'',mean_kin_',num2str(k),'_17'',mean_kin_',num2str(k),'_18'',mean_kin_',num2str(k),'_21'']'])
%     eval(['dlmwrite(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\stats\metrics\gp_anova2_cs_non_',kin_lbl{k},'.txt'',gp_anova2_cs_non_',kin_lbl{k},'_mat)'])
% end

sbjs_hc_stm=['22';'24';'25';'26';'29';'30'];
for k=1:13
    for i=1:6
        eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_hc_stm(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_hc_stm(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_hc_stm(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        eval(['mean_kin_',num2str(k),'_',sbjs_hc_stm(i,:),'=metricdat.data{1,k}(:,1:4);'])
    %     eval(['se_kin_',sbjs_hc_stm(i,:),'=std(metricdat.data{1,kin_idx}(:,1:4))/sqrt(6);'])
    %     eval(['[a1_kin_',sbjs_hc_stm(i,:),'_p,a1_kin_',sbjs_hc_stm(i,:),'_anovatab,a1_kin_',sbjs_hc_stm(i,:),'_stats]=',...
    %         'anova1(metricdat.data{1,kin_idx}(:,1:4),[],''off'');'])
    end
end
% mean_mean_kin_hc_stm=mean([mean_kin_22;mean_kin_24;mean_kin_25;mean_kin_26;mean_kin_29;mean_kin_30]);
% se_mean_kin_hc_stm=std([mean_kin_22;mean_kin_24;mean_kin_25;mean_kin_26;mean_kin_29;mean_kin_30])/sqrt(6);
% [a1_mean_mean_kin_hc_stm_p,a1_mean_mean_kin_hc_stm_anovatab,a1_mean_mean_kin_hc_stm_stats]=...
%     anova1([mean_kin_22;mean_kin_24;mean_kin_25;mean_kin_26;mean_kin_29;mean_kin_30],[],'off');

% for k=1:13
%     eval(['gp_anova2_hc_stm_',kin_lbl{k},'_mat=[mean_kin_',num2str(k),'_22'',mean_kin_',num2str(k),'_24'',mean_kin_',num2str(k),'_25'',mean_kin_',num2str(k),'_26'',mean_kin_',num2str(k),'_29'',mean_kin_',num2str(k),'_30'']'])
%     eval(['dlmwrite(''I:/MIND/MIND manuscripts/NCR/Zobaer - eeg and tdcs/stats/metrics/gp_anova2_hc_stm_',kin_lbl{k},'.txt'',gp_anova2_hc_stm_',kin_lbl{k},'_mat)'])
% end

sbjs_hc_non=['20';'23';'27';'28';'36'];
for k=1:13
    for i=1:5
        eval(['load(''papers-roddey-tdcs-eeg-vr/S2-metrics/pro00087153_00',sbjs_hc_non(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        %eval(['load(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw\pro00087153_00',sbjs_hc_non(i,:),'\analysis\S2-metrics\pro00087153_00',sbjs_hc_non(i,:),'_S2-Metrics.mat'',''metricdat'')'])
        eval(['mean_kin_',num2str(k),'_',sbjs_hc_non(i,:),'=metricdat.data{1,k}(:,1:4);'])
    %     eval(['se_kin_',sbjs_hc_non(i,:),'=std(metricdat.data{1,kin_idx}(:,1:4))/sqrt(5);'])
    %     eval(['[a1_kin_',sbjs_hc_non(i,:),'_p,a1_kin_',sbjs_hc_non(i,:),'_anovatab,a1_kin_',sbjs_hc_non(i,:),'_stats]=',...
    %         'anova1(metricdat.data{1,kin_idx}(:,1:4),[],''off'');'])
    end
end
% mean_mean_kin_hc_non=mean([mean_kin_20;mean_kin_23;mean_kin_27;mean_kin_28;mean_kin_36]);
% se_mean_kin_hc_non=std([mean_kin_20;mean_kin_23;mean_kin_27;mean_kin_28;mean_kin_36])/sqrt(5);
% [a1_mean_mean_kin_hc_non_p,a1_mean_mean_kin_hc_non_anovatab,a1_mean_mean_kin_hc_non_stats]=...
%     anova1([mean_kin_20;mean_kin_23;mean_kin_27;mean_kin_28;mean_kin_36],[],'off');

% for k=1:13
%     eval(['gp_anova2_hc_non_',kin_lbl{k},'_mat=[mean_kin_',num2str(k),'_20'',mean_kin_',num2str(k),'_23'',mean_kin_',num2str(k),'_27'',mean_kin_',num2str(k),'_28'',mean_kin_',num2str(k),'_36'']'])
%     eval(['dlmwrite(''I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\stats\metrics\gp_anova2_hc_non_',kin_lbl{k},'.txt'',gp_anova2_hc_non_',kin_lbl{k},'_mat)'])
% end

figure
% set(gcf,'Position',[128 573 640 786])
% for i=1:5
%     subplot(3,2,i); hold on
%     eval(['bar(mean_kin_',sbjs_cs_stm(i,:),')'])
%     eval(['errorbar(mean_kin_',sbjs_cs_stm(i,:),',se_kin_',sbjs_cs_stm(i,:),',''k.'')'])
%     set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
%     ylabel(kin_lbl{kin_idx})
%     title([sbjs_cs_stm(i,:),' (',eval(['num2str(a1_kin_',sbjs_cs_stm(i,:),'_p)']),')'])
% end
subplot(2,2,1); hold on
bar(mean_kin5_cs_stm)
errorbar(mean_kin5_cs_stm,mean_kin5_cs_stm,'k.')
set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
%ylabel(kin_lbl{kin_idx})
%title(['cs stm (',num2str(a1_mean_mean_kin5_cs_stm_p),')'])
%sgtitle(['cs stm ',kin_lbl{kin_idx}])

% figure
% set(gcf,'Position',[128 573 640 786])
% for i=1:5
%     subplot(3,2,i); hold on
%     eval(['bar(mean_kin_',sbjs_cs_non(i,:),')'])
%     eval(['errorbar(mean_kin_',sbjs_cs_non(i,:),',se_kin_',sbjs_cs_non(i,:),',''k.'')'])
%     set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
%     ylabel(kin_lbl{kin_idx})
%     title([sbjs_cs_non(i,:),' (',eval(['num2str(a1_kin_',sbjs_cs_non(i,:),'_p)']),')'])
% end
subplot(2,2,2); hold on
bar(mean_kin5_cs_non)
errorbar(mean_kin5_cs_non,mean_kin5_cs_non,'k.')
set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
% ylabel(kin_lbl{kin_idx})
% title(['cs non (',num2str(a1_mean_mean_kin_cs_non_p),')'])
%sgtitle(['cs non ',kin_lbl{kin_idx}])

% figure
% set(gcf,'Position',[128 573 640 786])
% for i=1:5
%     subplot(3,2,i); hold on
%     eval(['bar(mean_kin_',sbjs_hc_stm(i,:),')'])
%     eval(['errorbar(mean_kin_',sbjs_hc_stm(i,:),',se_kin_',sbjs_hc_stm(i,:),',''k.'')'])
%     set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
%     ylabel(kin_lbl{kin_idx})
%     title([sbjs_hc_stm(i,:),' (',eval(['num2str(a1_kin_',sbjs_hc_stm(i,:),'_p)']),')'])
% end
subplot(2,2,3); hold on
bar(mean_kin5_hc_stm)
errorbar(mean_kin_hc_stm,mean_kin5_hc_stm,'k.')
set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
% ylabel(kin_lbl{kin_idx})
% title(['hc stm (',num2str(a1_mean_mean_kin_hc_stm_p),')'])
%sgtitle(['hc stm ',kin_lbl{kin_idx}])

% figure
% set(gcf,'Position',[128 573 640 786])
% for i=1:5
%     subplot(3,2,i); hold on
%     eval(['bar(mean_kin_',sbjs_hc_non(i,:),')'])
%     eval(['errorbar(mean_kin_',sbjs_hc_non(i,:),',se_kin_',sbjs_hc_non(i,:),',''k.'')'])
%     set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
%     ylabel(kin_lbl{kin_idx})
%     title([sbjs_hc_non(i,:),' (',eval(['num2str(a1_kin_',sbjs_hc_non(i,:),'_p)']),')'])
% end
subplot(2,2,4); hold on
bar(mean_kin5_hc_non)
errorbar(mean_kin5_hc_non,mean_kin5_hc_non,'k.')
% set(gca,'XTick',[1:4],'XTickLabel',{'pre';'i05';'i15';'pos'})
% ylabel(kin_lbl{kin_idx})
% title(['hc non (',num2str(a1_mean_mean_kin_hc_non_p),')'])
%sgtitle(['hc non ',kin_lbl{kin_idx}])


%results
%there are isolated sig p-values but none for the 'All' condition
%interestingly for cs stm 4/5 were significant for inc maxacceleration
%not true hc non had sig decreased in reaction time

%% anova2

%difficult to replicate with graphpad bc it runs a repeated measures 2-way
%anova which I'm not sure matlab can do

%while I'm thinkking about it, these are the figures so far:
% fig 1 - methods
% fig 2 - kinematics - a?, b accel curves superimposed, c line plots, d bar
% plots
% fig 3- raw data with epochs
% fig 4 bar plots + linear regressions
% specgtrograms and topoplots

%%%% using graphpad
% accuracy - hc only
% avg velocity - cs + hc
% max accel - cs only
% max velocity - cs only
% reaction time - hc only



   


% dat=[mean_kin_03',mean_kin_04'];mean_kin_05';mean_kin_42';mean_kin_43';mean_kin_13';mean_kin_15';mean_kin_17';mean_kin_18';mean_kin_21']
% sbj=[linspace(1,1,4)';linspace(2,2,4)';linspace(3,3,4)';linspace(4,4,4)';linspace(5,5,4)';linspace(6,6,4)';...
%     linspace(7,7,4)';linspace(8,8,4)';linspace(9,9,4)';linspace(10,10,4)']
% f1_grp=[1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2]
% f2_grp=[1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4;1;2;3;4]
% stats=rm_anova2(dat,sbj,f1_grp,f2_grp,{'stim';'phase'})
% 


