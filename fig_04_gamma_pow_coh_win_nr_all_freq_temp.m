%% Load Data
datestr='2022_11_09';
datafolder='I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_raw';
%gitpath='/home/rowlandn/nr_data_analysis/data_scripts/ac/Allen-EEG-analysis';
calc_icoh=true;
calc_kin=true;
calc_labpower=true;

% Detect subjects
sbj=dir(fullfile(datafolder,'pro000*'));
sbj={sbj.name}'; 

% % Load Gitpath - not needed for this analysis
% cd(gitpath)
% allengit_genpaths(gitpath,'EEG')

% Define parameters
TOI={'pre-stim (baseline)','intrastim (5 min)','intrastim (15 min)','post-stim (5 min)'};
TOI_mod1={'pre','i05','i15','pos'};
TOI_mod={'prestim','intra5','intra15','poststim5'};
FOI_label={'Delta','Theta','Alpha','Beta','Gamma'};%can add more if you want
FOI_freq={{1,4},{5,8},{8,12},{13,30},{30,50}};
% FOI_label={};%can add more if you want
% FOI_freq={};
norm=false;
phases={'Hold','Prep','Reach'};
DOI={'stroke','healthy'};
stimtypes=[0,2];
stimname={'Sham','Stim'};
savefigures=false;

subjectData=[];
parfor s=1:numel(sbj)
    % Analysis folder
    anfold=fullfile(datafolder,sbj{s},'analysis');
    
    % Subject number
    subjectData(s).SubjectName=sbj{s};
    
    % Load S1 data
    disp(['Loading S1 data for...',sbj{s}])
    s1dat=load(fullfile(anfold,'S1-VR_preproc',[sbj{s},'_S1-VRdata_preprocessed.mat']));
    subjectData(s).sessioninfo=s1dat.sessioninfo;
    
    if calc_icoh||calc_labpower
        eeglabDat=load(fullfile(anfold,'EEGlab','EEGlab_Total.mat'));
        trials=fieldnames(eeglabDat.eegevents_ft.trials);
        for t=1:numel(trials)
            trialdat=eeglabDat.eegevents_ft.trials.(trials{t});
            for p=1:size(trialdat,1)
                if calc_icoh
                    
                    icoh_freq=trialdat(p).ft_iCoh.freq;
                    icoh_label=trialdat(p).ft_iCoh.labelcmb;
                    icoh_dim={'Label','Frequency','Reaches','Phase','Trial'};
                    if t==1 && p==1
                        tempicoh=nan(size(icoh_label,1),size(icoh_freq,2),12,size(trialdat,1),numel(trials));
                    end
                    tempicoh(:,:,1:size(trialdat(p).ft_iCoh.cohspctrm,3),p,t)=trialdat(p).ft_iCoh.cohspctrm;
                end
                if calc_labpower
                    power_times=trialdat(p).power.times;
                    power_freqs=trialdat(p).power.freqs;
                    chans=trialdat(p).chanlocs;
                    power_dim={'Frequency','Time','Channels','Phase','Trial'};
                    if t==1 && p==1
                        temppower=[];
                    end
                    temppower(:,:,:,p,t)=trialdat(p).power.ersp;
                end
            end
        end
        
        if calc_icoh
            disp(['Calculating EEGLAB icoh for...',sbj{s}])
            subjectData(s).iCoh.data=tempicoh;
            subjectData(s).iCoh.freq=icoh_freq;
            subjectData(s).iCoh.label=icoh_label;
            subjectData(s).iCoh.dim=icoh_dim;
        end
        
        if calc_labpower
            disp(['Calculating EEGLAB Power for...',sbj{s}])
            subjectData(s).power.data=temppower;
            subjectData(s).power.freq=power_freqs;
            subjectData(s).power.times=power_times;
            subjectData(s).power.chans=chans;
            subjectData(s).power.dim=power_dim;
        end
    end
    
    if calc_kin
        disp(['Calculating Kinematics for...',sbj{s}])
        metricDat=load(fullfile(anfold,'S2-metrics',[sbj{s},'_S2-Metrics.mat']));
        kinData=metricDat.metricdatraw.data;
        kinLabel=metricDat.metricdat.label;
        
        subjectData(s).kinematics.data=kinData;
        subjectData(s).kinematics.label=kinLabel;
    end
end

load('subjectData.mat')
load('icoh_data_anal_2022_11_09.mat')



%% B This is coherence but not diff coherence
FOI_label={'Delta','Theta','Alpha','Beta','Gamma'}
load('I:\MIND\MIND manuscripts\NCR\Zobaer - eeg and tdcs\data analysis\data_scripts\final_04_win\icoh_data_anal_2022_11_09.mat')
for i=1:5
    figure
    subplot(2,2,1); hold on
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pre_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i05_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i15_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pos_hold])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pre_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i05_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i15_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pos_hold])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pre_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i05_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i15_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pos_prep])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pre_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i05_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.i15_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.stim.pos_reac])'])
    eval(['title(''stroke stim ',FOI_label{i},''')'])

    subplot(2,2,2); hold on
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pre_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i05_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i15_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pos_hold])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pre_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i05_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i15_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pos_prep])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pre_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i05_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.i15_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.stroke.sham.pos_reac])'])
    eval(['title(''stroke sham ',FOI_label{i},''')'])

    subplot(2,2,3); hold on
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pre_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i05_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i15_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pos_hold])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pre_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i05_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i15_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pos_prep])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pre_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i05_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.i15_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.stim.pos_reac])'])
    eval(['title(''healthy stim ',FOI_label{i},''')'])

    subplot(2,2,4); hold on
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pre_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i05_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i15_hold,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pos_hold])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pre_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i05_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i15_prep,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pos_prep])'])
    eval(['plot([icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pre_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i05_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.i15_reac,',...
        'icoh_data_anal_2022_11_09.mat.c3c4.mean.',FOI_label{i},'.healthy.sham.pos_reac])'])
    eval(['title(''healthy sham ',FOI_label{i},''')'])
end

%% C heat map

gamma_mat_diff_heatmap_pr=[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos]
figure
imagesc(gamma_mat_diff_heatmap_pr)
colormap
set(gca,'YTick',[1 2 3 4],'YTickLabel',['pre';'i05';'i15';'pos'],'XTick',[1 2],'XTickLabel',['health';'stroke'])
title('gamma prep-reach')
colorbar

gamma_mat_diff_heatmap_hp=[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Hold_Prep.Stim.pre,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.pre;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Hold_Prep.Stim.i05,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.i05;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Hold_Prep.Stim.i15,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.i15;
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Hold_Prep.Stim.pos,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.pos]
figure
imagesc(gamma_mat_diff_heatmap_hp)
colormap
set(gca,'YTick',[1 2 3 4],'YTickLabel',['pre';'i05';'i15';'pos'],'XTick',[1 2],'XTickLabel',['health';'stroke'])
title('gamma hold-prep')
colorbar
   
%% D gamma prep-reach bar plot

figure; hold on
bar([icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos])
errorbar([icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,0,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos],...
    [icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,0,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,0,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,0,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos,icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos],'.k')

[p1a,anovatab1a,stats1a]=anova1(icoh_data_anal_2022_11_09.mat_diff.c3c4.grps.all_times.Gamma.stroke.Prep_Reach.Stim)%p=0.9311
[p1b,anovatab1b,stats1b]=anova1(icoh_data_anal_2022_11_09.mat_diff.c3c4.grps.all_times.Gamma.healthy.Prep_Reach.Stim)%p=0.1820

[p2a,anovatab2a,stats2a]=friedman(icoh_data_anal_2022_11_09.mat_diff.c3c4.grps.all_times.Gamma.stroke.Prep_Reach.Stim)%p=0.8964
[p2b,anovatab2b,stats2b]=friedman(icoh_data_anal_2022_11_09.mat_diff.c3c4.grps.all_times.Gamma.healthy.Prep_Reach.Stim)%p=0.3340

figure; hold on
b(1)=bar([1,4,7,10],[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos],0.2)
errorbar([1,4,7,10],[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos],...
   [icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos],'.k')
b(2)=bar([2,5,8,11],[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos],0.2)
errorbar([2,5,8,11],[icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.mean.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos],...
   [icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15,...
    icoh_data_anal_2022_11_09.se.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos],'.k')
anovaInputb{1,1}=[squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos)];
anovaInputb{1,2}=[squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15),...
    squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos)];
[icoh_data_anal_2022_11_09.stats.mat_diff.c3c4.mixanova.Gamma.all_times.stroke.Prep_Reach.mc1,...
    icoh_data_anal_2022_11_09.stats.mat_diff.c3c4.mixanova.Gamma.all_times.stroke.Prep_Reach.mc2]=...
    mixANOVA(anovaInputb,b);%p=0.029261

                
              

%working with graphpad

gamma_diff_01(:,1)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.pre)
gamma_diff_01(:,2)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.i05)
gamma_diff_01(:,3)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.i15)
gamma_diff_01(:,4)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Stim.pos)

gamma_diff_02(:,1)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Sham.pre)
gamma_diff_02(:,2)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Sham.i05)
gamma_diff_02(:,3)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Sham.i15)
gamma_diff_02(:,4)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Hold_Prep.Sham.pos)

dlmwrite('gamma_diff_01.txt',gamma_diff_01)
dlmwrite('gamma_diff_02.txt',gamma_diff_02)

gamma_diff_03(:,1)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pre)
gamma_diff_03(:,2)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i05)
gamma_diff_03(:,3)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.i15)
gamma_diff_03(:,4)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.stroke.Prep_Reach.Stim.pos)

gamma_diff_04(:,1)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pre)
gamma_diff_04(:,2)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i05)
gamma_diff_04(:,3)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.i15)
gamma_diff_04(:,4)=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.Gamma.healthy.Prep_Reach.Stim.pos)

dlmwrite('gamma_diff_03.txt',gamma_diff_03)
dlmwrite('gamma_diff_04.txt',gamma_diff_04)






%% this is gamma coh diff vs kinematics - linear regressions
% for now will try linear regressions with the diff
load('/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/subjectData.mat')
load('/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/icoh_data_anal_2022_11_09.mat')

sbj_num=['03';'04';'05';'42';'43';'13';'15';'17';'18';'21';'22';'24';'25';'26';'29';'30';'20';'23';'27';'28';'36'];

dz={'stroke';'healthy'}
stim_status={'Stim';'Sham'}
kin_lbl={'movementDuration';'reactionTime';'handpathlength';'avgVelocity';'maxVelocity';'velocityPeaks';...
    'timetoMaxVel';'timetoMaxVeln';'avgAcceleration';'maxAcceleration';...
    'accuracy';'normalizedjerk';'IOC'};
FOI_label={'Delta','Theta','Alpha','Beta','Gamma'};
cs_stim=[1 2 3 20 21];
cs_sham=[4 5 6 7 9];
hc_stim=[10 12 13 14 17 18];
hc_sham=[8 11 15 16 19];


pvalues = []; % Initialize an empty array to collect p-values
groupNames = {}; % Collect group names
kinLabels = {}; % Collect kinematic labels
FOILabels = {}; % Collect FOI labels

%in the future put the above in 1 cell and then just call each cell,
%otherwise you will be stuck changing it for each iteration!!
count=0;
for f=1:5
    for k=1:2
        for l=1:2
            for kin_idx=1:13%:12%[1 6]
                count=count+1
                if k==1 & l==1% 
                    i1=cs_stim
                elseif k==1 & l==2
                    i1=cs_sham
                elseif k==2 & l==1
                    i1=hc_stim
                elseif k==2 & l==2
                    i1=hc_sham
                end
                %Hold-Prep
                for i=i1
                    for j=1:4
                        eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(',num2str(i),',',num2str(j),')=nanmean(subjectData(',num2str(i),').kinematics.data{1,',num2str(kin_idx),'}(:,',num2str(j),'))'])
                    end
                end
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin=',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(~all(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin==0,2),:)'])

                times_all={'pre';'i05';'i15';'pos'}
                for i=1:4
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,',num2str(i),')=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.',FOI_label{f},'.',dz{k},'.Hold_Prep.',stim_status{l},'.',times_all{i,:},')'])
                end

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,1),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,1),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,1))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,1))'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,2),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,2),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,2))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,2))'])

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,3),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,3),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,3))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,3))'])

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,4),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,4),1);'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,4))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,4))'])

%                 figure; set(gcf,'Position',[214 574 560 420])
%                 subplot(2,2,1); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,1),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p(2)']) < 0.05
%                     title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p(2)']))],'Color','r')
%                 else
%                     title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p(2)']))])
%                 end
% 
%                 subplot(2,2,2); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,2),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p(2)']) < 0.05
%                     title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p(2)']))],'Color','r')
%                 else
%                     title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p(2)']))])
%                 end
% 
%                 subplot(2,2,3); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,3),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p(2)']) <0.05
%                     title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p(2)']))],'Color','r')
%                 else
%                     title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p(2)']))])
%                 end
% 
%                 subplot(2,2,4); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_kin(:,4),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p(2)']) < 0.05
%                     title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p(2)']))],'Color','r')
%                 else
%                     title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p(2)']))])
%                 end
%                 sgtitle([FOI_label{f},' Hold Prep ',dz{k},' ',stim_status{l},' ',subjectData(1).kinematics.label{kin_idx}])

                %Prep-Reach
                for i=i1
                    for j=1:4
                        eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(',num2str(i),',',num2str(j),')=nanmean(subjectData(',num2str(i),').kinematics.data{1,',num2str(kin_idx),'}(:,',num2str(j),'))'])
                    end
                end
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin=',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(~all(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin==0,2),:)'])

                times_all={'pre';'i05';'i15';'pos'}
                for i=1:4
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,',num2str(i),')=squeeze(icoh_data_anal_2022_11_09.mat_diff.c3c4.',FOI_label{f},'.',dz{k},'.Prep_Reach.',stim_status{l},'.',times_all{i,:},')'])
                end

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,1),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,1))'])

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,2),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,2))'])

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,3),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,3))'])

                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_pf=polyfit(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,4),1)'])
                eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_pv=polyval(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_pf,',...
                    FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4))'])
                eval(['[',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_r,',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p]=',...
                    'corrcoef(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,4))'])

%                 figure; set(gcf,'Position',[805 572 560 420])
%                 subplot(2,2,1); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,1),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']) < 0.05
%                     title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']))],'Color','r')
%                 else
%                     title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']))])
%                 end
% 
%                 subplot(2,2,2); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,2),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']) < 0.05
%                     title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']))],'Color','r')
%                 else
%                     title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']))])
%                 end
% 
%                 subplot(2,2,3); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,3),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']) < 0.05
%                     title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)'])),'Color','r'])
%                 else
%                     title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']))])
%                 end
% 
%                 subplot(2,2,4); hold on
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,4),''.'')'])
%                 eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_pv,''r'')'])
%                 if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']) < 0.05
%                     title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']))],'Color','r')
%                 else
%                     title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']))])
%                 end
% 
%                 sgtitle([FOI_label{f},' Prep Reach ',dz{k},' ',stim_status{l},' ',subjectData(1).kinematics.label{kin_idx}])
%                 
%                 icoh_lin_reg_p_all(count,:)=[f,k,l,kin_idx,eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']),...
%                     eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)'])];
                    
                
                %p
                
                clear *_cc *_pf *_pv *_r
            end
        end
    end
end

dz={'stroke';'healthy'}
stim_status={'Stim';'Sham'}
time={'pre';'i05';'i15';'pos'}
phase={'hold_prep';'Prep_Reach'}
kin_lbl={'movementDuration';'reactionTime';'handpathlength';'avgVelocity';'maxVelocity';'velocityPeaks';...
    'timetoMaxVel';'timetoMaxVeln';'avgAcceleration';'maxAcceleration';...
    'accuracy';'normalizedjerk';'IOC'};
FOI_label={'Delta','Theta','Alpha','Beta','Gamma'};
cs_stim=[1 2 3 20 21];
cs_sham=[4 5 6 7 9];
hc_stim=[10 12 13 14 17 18];
hc_sham=[8 11 15 16 19];


count=0;
for f=1:5
    for k=1:2
        for l=1:2
            for p=1:2
                for t=1:4
                    for kin_idx=1:13%:12%[1 6]
                        count=count+1;
                        p_sum(count,:)=[f,kin_idx,p,k,l,t,eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_',phase{p},'_',dz{k},'_',stim_status{l},'_',time{t},'_p(2);'])];
                    end
                end
            end
        end
    end
end

%%

%[fdr_r]=mafdr(p_sum(1:50,7))
addpath('./data analysis/data_scripts/Allen-EEG-analysis/Functions');
[h, crit_p, ~, adj_p] = fdr_bh(p_sum(:,7), 0.05, 'pdep', 'no');
fprintf('Total tests: %d\n', size(p_sum,1));
fprintf('Raw p < 0.05: %d\n', sum(p_sum(:,7) < 0.05));
fprintf('Surviving BH-FDR: %d\n', sum(h));

%alpha accuracy, avg accel, avg veloc

% I imported these into graphpad
% str_stim_vp_eeg=gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)
% str_stim_vp_kin=gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)
% figure; plot(str_stim_vp_eeg,str_stim_vp_kin,'.')
% dlmwrite('file_str_stim_vp_eeg.txt',str_stim_vp_eeg)
% dlmwrite('file_str_stim_vp_kin.txt',str_stim_vp_kin)

%% btw as a control, I grabbed the power values from below so I can re-do the linear regressions
% YOU HAVE TO GO DOWN A FEW SECTIONS TO RUN THE CS_?_C3C4 CODE

%here are the relevant controls
%DECIDED
%1) WE SHOULD LEAVE ALL ELECTRODES FOR NEXT PAPER AND STICK TO C3C4 ONLY
%FOR THIS ONE
%2) EVERYTHING SHOULD BE RELATIVE TO stroke stim, esp at i15
%3) THROW OUT PRE ONLY SIG VALUES (IE WHEN NO OTHER TRIALS ARE SIG)
%4) I GUESS IT MAKES SENSE TO ONLY LOOK AT 15 MIN WHICH IS WHEN THE 
%KINEMATIC CHANGE HAPPENED
%%%%% WRITE CODE TO COLLECT ALL THE PVALUES THEN YOU CAN JUST SORT THEM FOR
%%%%% 15 MIN!!! 
%Okay after looking at everything, its pretty clear that gamma coherence
%oredoiminates for the hold-prep period at 15 min chronic stroke stim while
%alpha predominates during the prep-reach period at 15 min
%cs stim ipsi c3/c4 power vs hold-prep kinemativs does not predict mov dur or vel peaks
%cs stim contra c3/c4 power vs hold-prep kinemativs does not predict mov dur or vel peaks
%cs stim diff c3/c4 power vs hold-prep kinemativs does not predict mov dur or vel peaks
%cs stim norm diff c3/c4 power vs hold-prep kinemativs does not predict mov dur or vel peaks
%EXCEPT THERE IS A SIG VALUE FOR REACH PRE move duration BUT THERE'S ONLY 1 VALUE ON THE
%OTHER SIDE THAT LOOKS LIKE AN OUTLIER

%btw when you go back and write this section, make sure to look back at all
%your gamma lin regs for hold, prep and reach separately - you wnat to be
%able to state that there is something unique about c3c4, about coherehce
%rather than diff, about gamma rather than any other freq band, about
%hold-prep transition rather than individual periods


%using C3 and C4 power only instead of coherence
sbj_num=['03';'04';'05';'42';'43';'13';'15';'17';'18';'21';'22';'24';'25';'26';'29';'30';'20';'23';'27';'28';'36'];

dz={'stroke';'healthy'}
stim_status={'Stim';'Sham'}
% kin_lbl={'movementDuration';'reactionTime';'handpathlength';'avgVelocity';'maxVelocity';'velocityPeaks';...
%     'timetoMaxVelocity';'timetoMaxVelocitynorm';'avgAcceleration';'maxAcceleration';...
%     'accuracy';'normalizedjerk';'IOC'};
kin_lbl={'movementDuration';'reactionTime';'handpathlength';'avgVelocity';'maxVelocity';'velocityPeaks';...
    'timetoMaxVelocity';'avgAcceleration';'maxAcceleration';...
    'accuracy';'normalizedjerk';'IOC'};
cs_stim=[1 2 3 20 21];
cs_sham=[4 5 6 7 9];
hc_stim=[10 12 13 14 17 18];
hc_sham=[8 11 15 16 19];

%even for this one just give some thought and make sure you are okay with
%just mov dur and vel peaks, same for gamma vs other freq
for k=1%1:2
    for l=1%1:2
        for kin_idx=[1 6]%:12
            %Hold-Prep %Remember this does not change for Prep-Reach so
            %even though it's called Hold Prep it is interchangeable with
            %Prep Reach
            for i=[1 2 3 20 21]
                for j=1:4
                    eval(['gamma_',kin_lbl{kin_idx},'_c3c4_pow_Hold_Prep_',dz{k},'_',stim_status{l},'_kin(',num2str(i),',',num2str(j),')=nanmean(subjectData(',num2str(i),').kinematics.data{1,',num2str(kin_idx),'}(:,',num2str(j),'))'])
                end
            end
            eval(['gamma_',kin_lbl{kin_idx},'_c3c4_pow_Hold_Prep_',dz{k},'_',stim_status{l},'_kin=gamma_',kin_lbl{kin_idx},'_c3c4_pow_Hold_Prep_',dz{k},'_',stim_status{l},'_kin(~all(gamma_',kin_lbl{kin_idx},'_c3c4_pow_Hold_Prep_',dz{k},'_',stim_status{l},'_kin==0,2),:)'])
        
        end
    end
end

gamma_moveDur_c3c4_ipsi_pow_Hold_eeg=[cs_stim_c3c4.Gamma.ipsi.Hold.pre;cs_stim_c3c4.Gamma.ipsi.Hold.i05;cs_stim_c3c4.Gamma.ipsi.Hold.i15;cs_stim_c3c4.Gamma.ipsi.Hold.pos]'
gamma_moveDur_c3c4_ipsi_pow_Prep_eeg=[cs_stim_c3c4.Gamma.ipsi.Prep.pre;cs_stim_c3c4.Gamma.ipsi.Prep.i05;cs_stim_c3c4.Gamma.ipsi.Prep.i15;cs_stim_c3c4.Gamma.ipsi.Prep.pos]'
gamma_moveDur_c3c4_ipsi_pow_Reach_eeg=[cs_stim_c3c4.Gamma.ipsi.Reach.pre;cs_stim_c3c4.Gamma.ipsi.Reach.i05;cs_stim_c3c4.Gamma.ipsi.Reach.i15;cs_stim_c3c4.Gamma.ipsi.Reach.pos]'
gamma_moveDur_c3c4_contra_pow_Hold_eeg=[cs_stim_c3c4.Gamma.contra.Hold.pre;cs_stim_c3c4.Gamma.contra.Hold.i05;cs_stim_c3c4.Gamma.contra.Hold.i15;cs_stim_c3c4.Gamma.contra.Hold.pos]'
gamma_moveDur_c3c4_contra_pow_Prep_eeg=[cs_stim_c3c4.Gamma.contra.Prep.pre;cs_stim_c3c4.Gamma.contra.Prep.i05;cs_stim_c3c4.Gamma.contra.Prep.i15;cs_stim_c3c4.Gamma.contra.Prep.pos]'
gamma_moveDur_c3c4_contra_pow_Reach_eeg=[cs_stim_c3c4.Gamma.contra.Reach.pre;cs_stim_c3c4.Gamma.contra.Reach.i05;cs_stim_c3c4.Gamma.contra.Reach.i15;cs_stim_c3c4.Gamma.contra.Reach.pos]'

gamma_moveDur_c3c4_diff_pow_Hold_eeg=[gamma_moveDur_c3c4_ipsi_pow_Hold_eeg-gamma_moveDur_c3c4_contra_pow_Hold_eeg]
gamma_moveDur_c3c4_diff_pow_Prep_eeg=[gamma_moveDur_c3c4_ipsi_pow_Prep_eeg-gamma_moveDur_c3c4_contra_pow_Prep_eeg]
gamma_moveDur_c3c4_diff_pow_Reach_eeg=[gamma_moveDur_c3c4_ipsi_pow_Reach_eeg-gamma_moveDur_c3c4_contra_pow_Reach_eeg]

gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg=[(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg-gamma_moveDur_c3c4_contra_pow_Hold_eeg)./gamma_moveDur_c3c4_ipsi_pow_Hold_eeg]
gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg=[(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg-gamma_moveDur_c3c4_contra_pow_Prep_eeg)./gamma_moveDur_c3c4_ipsi_pow_Prep_eeg]
gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg=[(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg-gamma_moveDur_c3c4_contra_pow_Reach_eeg)./gamma_moveDur_c3c4_ipsi_pow_Reach_eeg]

%Hold ipsi
gamma_moveDur_c3c4_ipsi_pow_Hold_pre_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_ipsi_pow_Hold_pre_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Hold_pre_pf,gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,1))
[gamma_moveDur_c3c4_ipsi_pow_Hold_pre_cc,gamma_moveDur_c3c4_ipsi_pow_Hold_pre_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_ipsi_pow_Hold_i05_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_ipsi_pow_Hold_i05_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Hold_i05_pf,gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,2))
[gamma_moveDur_c3c4_ipsi_pow_Hold_i05_cc,gamma_moveDur_c3c4_ipsi_pow_Hold_i05_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_ipsi_pow_Hold_i15_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_ipsi_pow_Hold_i15_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Hold_i15_pf,gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,3))
[gamma_moveDur_c3c4_ipsi_pow_Hold_i15_cc,gamma_moveDur_c3c4_ipsi_pow_Hold_i15_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_ipsi_pow_Hold_pos_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_ipsi_pow_Hold_pos_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Hold_pos_pf,gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,4))
[gamma_moveDur_c3c4_ipsi_pow_Hold_pos_cc,gamma_moveDur_c3c4_ipsi_pow_Hold_pos_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_moveDur_c3c4_ipsi_pow_Hold_pre_pv,'r')
title(['ipsi pow Hold pre (',num2str(gamma_moveDur_c3c4_ipsi_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_moveDur_c3c4_ipsi_pow_Hold_i05_pv,'r')
title(['ipsi pow Hold i05 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_moveDur_c3c4_ipsi_pow_Hold_i15_pv,'r')
title(['ipsi pow Hold i15 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_moveDur_c3c4_ipsi_pow_Hold_pos_pv,'r')
title(['ipsi pow Hold pos (',num2str(gamma_moveDur_c3c4_ipsi_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep ipsi
gamma_moveDur_c3c4_ipsi_pow_Prep_pre_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_ipsi_pow_Prep_pre_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Prep_pre_pf,gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,1))
[gamma_moveDur_c3c4_ipsi_pow_Prep_pre_cc,gamma_moveDur_c3c4_ipsi_pow_Prep_pre_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_ipsi_pow_Prep_i05_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_ipsi_pow_Prep_i05_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Prep_i05_pf,gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,2))
[gamma_moveDur_c3c4_ipsi_pow_Prep_i05_cc,gamma_moveDur_c3c4_ipsi_pow_Prep_i05_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_ipsi_pow_Prep_i15_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_ipsi_pow_Prep_i15_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Prep_i15_pf,gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,3))
[gamma_moveDur_c3c4_ipsi_pow_Prep_i15_cc,gamma_moveDur_c3c4_ipsi_pow_Prep_i15_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_ipsi_pow_Prep_pos_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_ipsi_pow_Prep_pos_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Prep_pos_pf,gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,4))
[gamma_moveDur_c3c4_ipsi_pow_Prep_pos_cc,gamma_moveDur_c3c4_ipsi_pow_Prep_pos_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_moveDur_c3c4_ipsi_pow_Prep_pre_pv,'r')
title(['ipsi pow Prep pre (',num2str(gamma_moveDur_c3c4_ipsi_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_moveDur_c3c4_ipsi_pow_Prep_i05_pv,'r')
title(['ipsi pow Prep i05 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_moveDur_c3c4_ipsi_pow_Prep_i15_pv,'r')
title(['ipsi pow Prep i15 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_moveDur_c3c4_ipsi_pow_Prep_pos_pv,'r')
title(['ipsi pow Prep pos (',num2str(gamma_moveDur_c3c4_ipsi_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%small check
gamma_moveDur_c3c4_diff_coh_Hold_Prep_i15_pf=polyfit(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_diff_coh_Hold_Prep_i15_pv=polyval(gamma_moveDur_c3c4_diff_coh_Hold_Prep_i15_pf,gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3))
[gamma_moveDur_c3c4_diff_coh_Hold_Prep_i15_cc,gamma_moveDur_c3c4_diff_coh_Hold_Prep_i15_p]=corrcoef(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))
%correct!

%Reach ipsi
gamma_moveDur_c3c4_ipsi_pow_Reach_pre_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_ipsi_pow_Reach_pre_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Reach_pre_pf,gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,1))
[gamma_moveDur_c3c4_ipsi_pow_Reach_pre_cc,gamma_moveDur_c3c4_ipsi_pow_Reach_pre_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_ipsi_pow_Reach_i05_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_ipsi_pow_Reach_i05_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Reach_i05_pf,gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,2))
[gamma_moveDur_c3c4_ipsi_pow_Reach_i05_cc,gamma_moveDur_c3c4_ipsi_pow_Reach_i05_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_ipsi_pow_Reach_i15_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_ipsi_pow_Reach_i15_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Reach_i15_pf,gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,3))
[gamma_moveDur_c3c4_ipsi_pow_Reach_i15_cc,gamma_moveDur_c3c4_ipsi_pow_Reach_i15_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_ipsi_pow_Reach_pos_pf=polyfit(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_ipsi_pow_Reach_pos_pv=polyval(gamma_moveDur_c3c4_ipsi_pow_Reach_pos_pf,gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,4))
[gamma_moveDur_c3c4_ipsi_pow_Reach_pos_cc,gamma_moveDur_c3c4_ipsi_pow_Reach_pos_p]=corrcoef(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_moveDur_c3c4_ipsi_pow_Reach_pre_pv,'r')
title(['ipsi pow Reach pre (',num2str(gamma_moveDur_c3c4_ipsi_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_moveDur_c3c4_ipsi_pow_Reach_i05_pv,'r')
title(['ipsi pow Reach i05 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_moveDur_c3c4_ipsi_pow_Reach_i15_pv,'r')
title(['ipsi pow Reach i15 (',num2str(gamma_moveDur_c3c4_ipsi_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_moveDur_c3c4_ipsi_pow_Reach_pos_pv,'r')
title(['ipsi pow Reach pos (',num2str(gamma_moveDur_c3c4_ipsi_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%Hold contra
gamma_moveDur_c3c4_contra_pow_Hold_pre_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_contra_pow_Hold_pre_pv=polyval(gamma_moveDur_c3c4_contra_pow_Hold_pre_pf,gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,1))
[gamma_moveDur_c3c4_contra_pow_Hold_pre_cc,gamma_moveDur_c3c4_contra_pow_Hold_pre_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_contra_pow_Hold_i05_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_contra_pow_Hold_i05_pv=polyval(gamma_moveDur_c3c4_contra_pow_Hold_i05_pf,gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,2))
[gamma_moveDur_c3c4_contra_pow_Hold_i05_cc,gamma_moveDur_c3c4_contra_pow_Hold_i05_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_contra_pow_Hold_i15_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_contra_pow_Hold_i15_pv=polyval(gamma_moveDur_c3c4_contra_pow_Hold_i15_pf,gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,3))
[gamma_moveDur_c3c4_contra_pow_Hold_i15_cc,gamma_moveDur_c3c4_contra_pow_Hold_i15_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_contra_pow_Hold_pos_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_contra_pow_Hold_pos_pv=polyval(gamma_moveDur_c3c4_contra_pow_Hold_pos_pf,gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,4))
[gamma_moveDur_c3c4_contra_pow_Hold_pos_cc,gamma_moveDur_c3c4_contra_pow_Hold_pos_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,1),gamma_moveDur_c3c4_contra_pow_Hold_pre_pv,'r')
title(['contra pow Hold pre (',num2str(gamma_moveDur_c3c4_contra_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,2),gamma_moveDur_c3c4_contra_pow_Hold_i05_pv,'r')
title(['contra pow Hold i05 (',num2str(gamma_moveDur_c3c4_contra_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,3),gamma_moveDur_c3c4_contra_pow_Hold_i15_pv,'r')
title(['contra pow Hold i15 (',num2str(gamma_moveDur_c3c4_contra_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Hold_eeg(:,4),gamma_moveDur_c3c4_contra_pow_Hold_pos_pv,'r')
title(['contra pow Hold pos (',num2str(gamma_moveDur_c3c4_contra_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep contra
gamma_moveDur_c3c4_contra_pow_Prep_pre_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_contra_pow_Prep_pre_pv=polyval(gamma_moveDur_c3c4_contra_pow_Prep_pre_pf,gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,1))
[gamma_moveDur_c3c4_contra_pow_Prep_pre_cc,gamma_moveDur_c3c4_contra_pow_Prep_pre_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_contra_pow_Prep_i05_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_contra_pow_Prep_i05_pv=polyval(gamma_moveDur_c3c4_contra_pow_Prep_i05_pf,gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,2))
[gamma_moveDur_c3c4_contra_pow_Prep_i05_cc,gamma_moveDur_c3c4_contra_pow_Prep_i05_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_contra_pow_Prep_i15_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_contra_pow_Prep_i15_pv=polyval(gamma_moveDur_c3c4_contra_pow_Prep_i15_pf,gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,3))
[gamma_moveDur_c3c4_contra_pow_Prep_i15_cc,gamma_moveDur_c3c4_contra_pow_Prep_i15_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_contra_pow_Prep_pos_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_contra_pow_Prep_pos_pv=polyval(gamma_moveDur_c3c4_contra_pow_Prep_pos_pf,gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,4))
[gamma_moveDur_c3c4_contra_pow_Prep_pos_cc,gamma_moveDur_c3c4_contra_pow_Prep_pos_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,1),gamma_moveDur_c3c4_contra_pow_Prep_pre_pv,'r')
title(['contra pow Prep pre (',num2str(gamma_moveDur_c3c4_contra_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,2),gamma_moveDur_c3c4_contra_pow_Prep_i05_pv,'r')
title(['contra pow Prep i05 (',num2str(gamma_moveDur_c3c4_contra_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,3),gamma_moveDur_c3c4_contra_pow_Prep_i15_pv,'r')
title(['contra pow Prep i15 (',num2str(gamma_moveDur_c3c4_contra_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Prep_eeg(:,4),gamma_moveDur_c3c4_contra_pow_Prep_pos_pv,'r')
title(['contra pow Prep pos (',num2str(gamma_moveDur_c3c4_contra_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach contra
gamma_moveDur_c3c4_contra_pow_Reach_pre_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_contra_pow_Reach_pre_pv=polyval(gamma_moveDur_c3c4_contra_pow_Reach_pre_pf,gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,1))
[gamma_moveDur_c3c4_contra_pow_Reach_pre_cc,gamma_moveDur_c3c4_contra_pow_Reach_pre_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_contra_pow_Reach_i05_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_contra_pow_Reach_i05_pv=polyval(gamma_moveDur_c3c4_contra_pow_Reach_i05_pf,gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,2))
[gamma_moveDur_c3c4_contra_pow_Reach_i05_cc,gamma_moveDur_c3c4_contra_pow_Reach_i05_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_contra_pow_Reach_i15_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_contra_pow_Reach_i15_pv=polyval(gamma_moveDur_c3c4_contra_pow_Reach_i15_pf,gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,3))
[gamma_moveDur_c3c4_contra_pow_Reach_i15_cc,gamma_moveDur_c3c4_contra_pow_Reach_i15_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_contra_pow_Reach_pos_pf=polyfit(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_contra_pow_Reach_pos_pv=polyval(gamma_moveDur_c3c4_contra_pow_Reach_pos_pf,gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,4))
[gamma_moveDur_c3c4_contra_pow_Reach_pos_cc,gamma_moveDur_c3c4_contra_pow_Reach_pos_p]=corrcoef(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,1),gamma_moveDur_c3c4_contra_pow_Reach_pre_pv,'r')
title(['contra pow Reach pre (',num2str(gamma_moveDur_c3c4_contra_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,2),gamma_moveDur_c3c4_contra_pow_Reach_i05_pv,'r')
title(['contra pow Reach i05 (',num2str(gamma_moveDur_c3c4_contra_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,3),gamma_moveDur_c3c4_contra_pow_Reach_i15_pv,'r')
title(['contra pow Reach i15 (',num2str(gamma_moveDur_c3c4_contra_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_contra_pow_Reach_eeg(:,4),gamma_moveDur_c3c4_contra_pow_Reach_pos_pv,'r')
title(['contra pow Reach pos (',num2str(gamma_moveDur_c3c4_contra_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%now lets do raw diff and we should be done
%Hold diff
gamma_moveDur_c3c4_diff_pow_Hold_pre_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_diff_pow_Hold_pre_pv=polyval(gamma_moveDur_c3c4_diff_pow_Hold_pre_pf,gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,1))
[gamma_moveDur_c3c4_diff_pow_Hold_pre_cc,gamma_moveDur_c3c4_diff_pow_Hold_pre_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_diff_pow_Hold_i05_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_diff_pow_Hold_i05_pv=polyval(gamma_moveDur_c3c4_diff_pow_Hold_i05_pf,gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,2))
[gamma_moveDur_c3c4_diff_pow_Hold_i05_cc,gamma_moveDur_c3c4_diff_pow_Hold_i05_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_diff_pow_Hold_i15_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_diff_pow_Hold_i15_pv=polyval(gamma_moveDur_c3c4_diff_pow_Hold_i15_pf,gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,3))
[gamma_moveDur_c3c4_diff_pow_Hold_i15_cc,gamma_moveDur_c3c4_diff_pow_Hold_i15_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_diff_pow_Hold_pos_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_diff_pow_Hold_pos_pv=polyval(gamma_moveDur_c3c4_diff_pow_Hold_pos_pf,gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,4))
[gamma_moveDur_c3c4_diff_pow_Hold_pos_cc,gamma_moveDur_c3c4_diff_pow_Hold_pos_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,1),gamma_moveDur_c3c4_diff_pow_Hold_pre_pv,'r')
title(['diff pow Hold pre (',num2str(gamma_moveDur_c3c4_diff_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,2),gamma_moveDur_c3c4_diff_pow_Hold_i05_pv,'r')
title(['diff pow Hold i05 (',num2str(gamma_moveDur_c3c4_diff_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,3),gamma_moveDur_c3c4_diff_pow_Hold_i15_pv,'r')
title(['diff pow Hold i15 (',num2str(gamma_moveDur_c3c4_diff_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Hold_eeg(:,4),gamma_moveDur_c3c4_diff_pow_Hold_pos_pv,'r')
title(['diff pow Hold pos (',num2str(gamma_moveDur_c3c4_diff_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%Prep diff
gamma_moveDur_c3c4_diff_pow_Prep_pre_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_diff_pow_Prep_pre_pv=polyval(gamma_moveDur_c3c4_diff_pow_Prep_pre_pf,gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,1))
[gamma_moveDur_c3c4_diff_pow_Prep_pre_cc,gamma_moveDur_c3c4_diff_pow_Prep_pre_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_diff_pow_Prep_i05_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_diff_pow_Prep_i05_pv=polyval(gamma_moveDur_c3c4_diff_pow_Prep_i05_pf,gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,2))
[gamma_moveDur_c3c4_diff_pow_Prep_i05_cc,gamma_moveDur_c3c4_diff_pow_Prep_i05_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_diff_pow_Prep_i15_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_diff_pow_Prep_i15_pv=polyval(gamma_moveDur_c3c4_diff_pow_Prep_i15_pf,gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,3))
[gamma_moveDur_c3c4_diff_pow_Prep_i15_cc,gamma_moveDur_c3c4_diff_pow_Prep_i15_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_diff_pow_Prep_pos_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_diff_pow_Prep_pos_pv=polyval(gamma_moveDur_c3c4_diff_pow_Prep_pos_pf,gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,4))
[gamma_moveDur_c3c4_diff_pow_Prep_pos_cc,gamma_moveDur_c3c4_diff_pow_Prep_pos_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,1),gamma_moveDur_c3c4_diff_pow_Prep_pre_pv,'r')
title(['diff pow Prep pre (',num2str(gamma_moveDur_c3c4_diff_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,2),gamma_moveDur_c3c4_diff_pow_Prep_i05_pv,'r')
title(['diff pow Prep i05 (',num2str(gamma_moveDur_c3c4_diff_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,3),gamma_moveDur_c3c4_diff_pow_Prep_i15_pv,'r')
title(['diff pow Prep i15 (',num2str(gamma_moveDur_c3c4_diff_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Prep_eeg(:,4),gamma_moveDur_c3c4_diff_pow_Prep_pos_pv,'r')
title(['diff pow Prep pos (',num2str(gamma_moveDur_c3c4_diff_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach diff
gamma_moveDur_c3c4_diff_pow_Reach_pre_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_diff_pow_Reach_pre_pv=polyval(gamma_moveDur_c3c4_diff_pow_Reach_pre_pf,gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,1))
[gamma_moveDur_c3c4_diff_pow_Reach_pre_cc,gamma_moveDur_c3c4_diff_pow_Reach_pre_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_diff_pow_Reach_i05_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_diff_pow_Reach_i05_pv=polyval(gamma_moveDur_c3c4_diff_pow_Reach_i05_pf,gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,2))
[gamma_moveDur_c3c4_diff_pow_Reach_i05_cc,gamma_moveDur_c3c4_diff_pow_Reach_i05_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_diff_pow_Reach_i15_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_diff_pow_Reach_i15_pv=polyval(gamma_moveDur_c3c4_diff_pow_Reach_i15_pf,gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,3))
[gamma_moveDur_c3c4_diff_pow_Reach_i15_cc,gamma_moveDur_c3c4_diff_pow_Reach_i15_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_diff_pow_Reach_pos_pf=polyfit(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_diff_pow_Reach_pos_pv=polyval(gamma_moveDur_c3c4_diff_pow_Reach_pos_pf,gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,4))
[gamma_moveDur_c3c4_diff_pow_Reach_pos_cc,gamma_moveDur_c3c4_diff_pow_Reach_pos_p]=corrcoef(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,1),gamma_moveDur_c3c4_diff_pow_Reach_pre_pv,'r')
title(['diff pow Reach pre (',num2str(gamma_moveDur_c3c4_diff_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,2),gamma_moveDur_c3c4_diff_pow_Reach_i05_pv,'r')
title(['diff pow Reach i05 (',num2str(gamma_moveDur_c3c4_diff_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,3),gamma_moveDur_c3c4_diff_pow_Reach_i15_pv,'r')
title(['diff pow Reach i15 (',num2str(gamma_moveDur_c3c4_diff_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
% plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_diff_pow_Reach_eeg(:,4),gamma_moveDur_c3c4_diff_pow_Reach_pos_pv,'r')
title(['diff pow Reach pos (',num2str(gamma_moveDur_c3c4_diff_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Hold norm diff
gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_pf,gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,1))
[gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_cc,gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_pf,gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,2))
[gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_cc,gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_pf,gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,3))
[gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_cc,gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_pf,gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,4))
[gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_cc,gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_pv,'r')
title(['norm diff pow Hold pre (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_pv,'r')
title(['norm diff pow Hold i05 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_pv,'r')
title(['norm diff pow Hold i15 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_pv,'r')
title(['norm diff pow Hold pos (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep norm diff
gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_pf,gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,1))
[gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_cc,gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_pf,gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,2))
[gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_cc,gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_pf,gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,3))
[gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_cc,gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_pf,gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,4))
[gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_cc,gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_pv,'r')
title(['norm diff pow Prep pre (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_pv,'r')
title(['norm diff pow Prep i05 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_pv,'r')
title(['norm diff pow Prep i15 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_pv,'r')
title(['norm diff pow Prep pos (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach norm diff
gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_pf,gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,1))
[gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_cc,gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_pf,gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,2))
[gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_cc,gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_pf,gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,3))
[gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_cc,gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_pf=polyfit(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_pv=polyval(gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_pf,gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,4))
[gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_cc,gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_p]=corrcoef(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_pv,'r')
title(['norm diff pow Reach pre (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_pv,'r')
title(['norm diff pow Reach i05 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_pv,'r')
title(['norm diff pow Reach i15 (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_moveDur_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_pv,'r')
title(['norm diff pow Reach pos (',num2str(gamma_moveDur_c3c4_norm_diff_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%nothing is significant at all with regard to C3/C4 power! next you have to
%do velocity peaks

gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg=[cs_stim_c3c4.Gamma.ipsi.Hold.pre;cs_stim_c3c4.Gamma.ipsi.Hold.i05;cs_stim_c3c4.Gamma.ipsi.Hold.i15;cs_stim_c3c4.Gamma.ipsi.Hold.pos]'
gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg=[cs_stim_c3c4.Gamma.ipsi.Prep.pre;cs_stim_c3c4.Gamma.ipsi.Prep.i05;cs_stim_c3c4.Gamma.ipsi.Prep.i15;cs_stim_c3c4.Gamma.ipsi.Prep.pos]'
gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg=[cs_stim_c3c4.Gamma.ipsi.Reach.pre;cs_stim_c3c4.Gamma.ipsi.Reach.i05;cs_stim_c3c4.Gamma.ipsi.Reach.i15;cs_stim_c3c4.Gamma.ipsi.Reach.pos]'
gamma_velpeaks_c3c4_contra_pow_Hold_eeg=[cs_stim_c3c4.Gamma.contra.Hold.pre;cs_stim_c3c4.Gamma.contra.Hold.i05;cs_stim_c3c4.Gamma.contra.Hold.i15;cs_stim_c3c4.Gamma.contra.Hold.pos]'
gamma_velpeaks_c3c4_contra_pow_Prep_eeg=[cs_stim_c3c4.Gamma.contra.Prep.pre;cs_stim_c3c4.Gamma.contra.Prep.i05;cs_stim_c3c4.Gamma.contra.Prep.i15;cs_stim_c3c4.Gamma.contra.Prep.pos]'
gamma_velpeaks_c3c4_contra_pow_Reach_eeg=[cs_stim_c3c4.Gamma.contra.Reach.pre;cs_stim_c3c4.Gamma.contra.Reach.i05;cs_stim_c3c4.Gamma.contra.Reach.i15;cs_stim_c3c4.Gamma.contra.Reach.pos]'

gamma_velpeaks_c3c4_diff_pow_Hold_eeg=[gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg-gamma_velpeaks_c3c4_contra_pow_Hold_eeg]
gamma_velpeaks_c3c4_diff_pow_Prep_eeg=[gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg-gamma_velpeaks_c3c4_contra_pow_Prep_eeg]
gamma_velpeaks_c3c4_diff_pow_Reach_eeg=[gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg-gamma_velpeaks_c3c4_contra_pow_Reach_eeg]

gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg=[(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg-gamma_velpeaks_c3c4_contra_pow_Hold_eeg)./gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg]
gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg=[(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg-gamma_velpeaks_c3c4_contra_pow_Prep_eeg)./gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg]
gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg=[(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg-gamma_velpeaks_c3c4_contra_pow_Reach_eeg)./gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg]

%Hold ipsi
gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_pf,gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,1))
[gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_cc,gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_pf,gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,2))
[gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_cc,gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_pf,gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,3))
[gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_cc,gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_pf,gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,4))
[gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_cc,gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,1),gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_pv,'r')
title(['ipsi pow Hold pre (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,2),gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_pv,'r')
title(['ipsi pow Hold i05 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,3),gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_pv,'r')
title(['ipsi pow Hold i15 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Hold_eeg(:,4),gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_pv,'r')
title(['ipsi pow Hold pos (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep ipsi
gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_pf,gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,1))
[gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_cc,gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_pf,gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,2))
[gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_cc,gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_pf,gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,3))
[gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_cc,gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_pf,gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,4))
[gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_cc,gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,1),gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_pv,'r')
title(['ipsi pow Prep pre (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,2),gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_pv,'r')
title(['ipsi pow Prep i05 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,3),gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_pv,'r')
title(['ipsi pow Prep i15 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Prep_eeg(:,4),gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_pv,'r')
title(['ipsi pow Prep pos (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%small check
gamma_velpeaks_c3c4_diff_coh_Hold_Prep_i15_pf=polyfit(gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_diff_coh_Hold_Prep_i15_pv=polyval(gamma_velpeaks_c3c4_diff_coh_Hold_Prep_i15_pf,gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3))
[gamma_velpeaks_c3c4_diff_coh_Hold_Prep_i15_cc,gamma_velpeaks_c3c4_diff_coh_Hold_Prep_i15_p]=corrcoef(gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))
%correct!

%Reach ipsi
gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_pf,gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,1))
[gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_cc,gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_pf,gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,2))
[gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_cc,gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_pf,gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,3))
[gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_cc,gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_pf=polyfit(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_pv=polyval(gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_pf,gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,4))
[gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_cc,gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_p]=corrcoef(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,1),gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_pv,'r')
title(['ipsi pow Reach pre (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,2),gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_pv,'r')
title(['ipsi pow Reach i05 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,3),gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_pv,'r')
title(['ipsi pow Reach i15 (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_ipsi_pow_Reach_eeg(:,4),gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_pv,'r')
title(['ipsi pow Reach pos (',num2str(gamma_velpeaks_c3c4_ipsi_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%Hold contra
gamma_velpeaks_c3c4_contra_pow_Hold_pre_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_contra_pow_Hold_pre_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Hold_pre_pf,gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,1))
[gamma_velpeaks_c3c4_contra_pow_Hold_pre_cc,gamma_velpeaks_c3c4_contra_pow_Hold_pre_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_contra_pow_Hold_i05_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_contra_pow_Hold_i05_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Hold_i05_pf,gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,2))
[gamma_velpeaks_c3c4_contra_pow_Hold_i05_cc,gamma_velpeaks_c3c4_contra_pow_Hold_i05_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_contra_pow_Hold_i15_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_contra_pow_Hold_i15_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Hold_i15_pf,gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,3))
[gamma_velpeaks_c3c4_contra_pow_Hold_i15_cc,gamma_velpeaks_c3c4_contra_pow_Hold_i15_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_contra_pow_Hold_pos_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_contra_pow_Hold_pos_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Hold_pos_pf,gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,4))
[gamma_velpeaks_c3c4_contra_pow_Hold_pos_cc,gamma_velpeaks_c3c4_contra_pow_Hold_pos_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,1),gamma_velpeaks_c3c4_contra_pow_Hold_pre_pv,'r')
title(['contra pow Hold pre (',num2str(gamma_velpeaks_c3c4_contra_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,2),gamma_velpeaks_c3c4_contra_pow_Hold_i05_pv,'r')
title(['contra pow Hold i05 (',num2str(gamma_velpeaks_c3c4_contra_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,3),gamma_velpeaks_c3c4_contra_pow_Hold_i15_pv,'r')
title(['contra pow Hold i15 (',num2str(gamma_velpeaks_c3c4_contra_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Hold_eeg(:,4),gamma_velpeaks_c3c4_contra_pow_Hold_pos_pv,'r')
title(['contra pow Hold pos (',num2str(gamma_velpeaks_c3c4_contra_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep contra
gamma_velpeaks_c3c4_contra_pow_Prep_pre_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_contra_pow_Prep_pre_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Prep_pre_pf,gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,1))
[gamma_velpeaks_c3c4_contra_pow_Prep_pre_cc,gamma_velpeaks_c3c4_contra_pow_Prep_pre_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_contra_pow_Prep_i05_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_contra_pow_Prep_i05_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Prep_i05_pf,gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,2))
[gamma_velpeaks_c3c4_contra_pow_Prep_i05_cc,gamma_velpeaks_c3c4_contra_pow_Prep_i05_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_contra_pow_Prep_i15_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_contra_pow_Prep_i15_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Prep_i15_pf,gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,3))
[gamma_velpeaks_c3c4_contra_pow_Prep_i15_cc,gamma_velpeaks_c3c4_contra_pow_Prep_i15_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_contra_pow_Prep_pos_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_contra_pow_Prep_pos_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Prep_pos_pf,gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,4))
[gamma_velpeaks_c3c4_contra_pow_Prep_pos_cc,gamma_velpeaks_c3c4_contra_pow_Prep_pos_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,1),gamma_velpeaks_c3c4_contra_pow_Prep_pre_pv,'r')
title(['contra pow Prep pre (',num2str(gamma_velpeaks_c3c4_contra_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,2),gamma_velpeaks_c3c4_contra_pow_Prep_i05_pv,'r')
title(['contra pow Prep i05 (',num2str(gamma_velpeaks_c3c4_contra_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,3),gamma_velpeaks_c3c4_contra_pow_Prep_i15_pv,'r')
title(['contra pow Prep i15 (',num2str(gamma_velpeaks_c3c4_contra_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Prep_eeg(:,4),gamma_velpeaks_c3c4_contra_pow_Prep_pos_pv,'r')
title(['contra pow Prep pos (',num2str(gamma_velpeaks_c3c4_contra_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach contra
gamma_velpeaks_c3c4_contra_pow_Reach_pre_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_contra_pow_Reach_pre_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Reach_pre_pf,gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,1))
[gamma_velpeaks_c3c4_contra_pow_Reach_pre_cc,gamma_velpeaks_c3c4_contra_pow_Reach_pre_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_contra_pow_Reach_i05_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_contra_pow_Reach_i05_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Reach_i05_pf,gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,2))
[gamma_velpeaks_c3c4_contra_pow_Reach_i05_cc,gamma_velpeaks_c3c4_contra_pow_Reach_i05_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_contra_pow_Reach_i15_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_contra_pow_Reach_i15_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Reach_i15_pf,gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,3))
[gamma_velpeaks_c3c4_contra_pow_Reach_i15_cc,gamma_velpeaks_c3c4_contra_pow_Reach_i15_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_contra_pow_Reach_pos_pf=polyfit(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_contra_pow_Reach_pos_pv=polyval(gamma_velpeaks_c3c4_contra_pow_Reach_pos_pf,gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,4))
[gamma_velpeaks_c3c4_contra_pow_Reach_pos_cc,gamma_velpeaks_c3c4_contra_pow_Reach_pos_p]=corrcoef(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,1),gamma_velpeaks_c3c4_contra_pow_Reach_pre_pv,'r')
title(['contra pow Reach pre (',num2str(gamma_velpeaks_c3c4_contra_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,2),gamma_velpeaks_c3c4_contra_pow_Reach_i05_pv,'r')
title(['contra pow Reach i05 (',num2str(gamma_velpeaks_c3c4_contra_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,3),gamma_velpeaks_c3c4_contra_pow_Reach_i15_pv,'r')
title(['contra pow Reach i15 (',num2str(gamma_velpeaks_c3c4_contra_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_contra_pow_Reach_eeg(:,4),gamma_velpeaks_c3c4_contra_pow_Reach_pos_pv,'r')
title(['contra pow Reach pos (',num2str(gamma_velpeaks_c3c4_contra_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%now lets do raw diff and we should be done
%Hold diff
gamma_velpeaks_c3c4_diff_pow_Hold_pre_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_diff_pow_Hold_pre_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Hold_pre_pf,gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,1))
[gamma_velpeaks_c3c4_diff_pow_Hold_pre_cc,gamma_velpeaks_c3c4_diff_pow_Hold_pre_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_diff_pow_Hold_i05_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_diff_pow_Hold_i05_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Hold_i05_pf,gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,2))
[gamma_velpeaks_c3c4_diff_pow_Hold_i05_cc,gamma_velpeaks_c3c4_diff_pow_Hold_i05_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_diff_pow_Hold_i15_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_diff_pow_Hold_i15_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Hold_i15_pf,gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,3))
[gamma_velpeaks_c3c4_diff_pow_Hold_i15_cc,gamma_velpeaks_c3c4_diff_pow_Hold_i15_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_diff_pow_Hold_pos_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_diff_pow_Hold_pos_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Hold_pos_pf,gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,4))
[gamma_velpeaks_c3c4_diff_pow_Hold_pos_cc,gamma_velpeaks_c3c4_diff_pow_Hold_pos_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,1),gamma_velpeaks_c3c4_diff_pow_Hold_pre_pv,'r')
title(['diff pow Hold pre (',num2str(gamma_velpeaks_c3c4_diff_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,2),gamma_velpeaks_c3c4_diff_pow_Hold_i05_pv,'r')
title(['diff pow Hold i05 (',num2str(gamma_velpeaks_c3c4_diff_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,3),gamma_velpeaks_c3c4_diff_pow_Hold_i15_pv,'r')
title(['diff pow Hold i15 (',num2str(gamma_velpeaks_c3c4_diff_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Hold_eeg(:,4),gamma_velpeaks_c3c4_diff_pow_Hold_pos_pv,'r')
title(['diff pow Hold pos (',num2str(gamma_velpeaks_c3c4_diff_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')


%Prep diff
gamma_velpeaks_c3c4_diff_pow_Prep_pre_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_diff_pow_Prep_pre_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Prep_pre_pf,gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,1))
[gamma_velpeaks_c3c4_diff_pow_Prep_pre_cc,gamma_velpeaks_c3c4_diff_pow_Prep_pre_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_diff_pow_Prep_i05_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_diff_pow_Prep_i05_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Prep_i05_pf,gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,2))
[gamma_velpeaks_c3c4_diff_pow_Prep_i05_cc,gamma_velpeaks_c3c4_diff_pow_Prep_i05_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_diff_pow_Prep_i15_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_diff_pow_Prep_i15_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Prep_i15_pf,gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,3))
[gamma_velpeaks_c3c4_diff_pow_Prep_i15_cc,gamma_velpeaks_c3c4_diff_pow_Prep_i15_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_diff_pow_Prep_pos_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_diff_pow_Prep_pos_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Prep_pos_pf,gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,4))
[gamma_velpeaks_c3c4_diff_pow_Prep_pos_cc,gamma_velpeaks_c3c4_diff_pow_Prep_pos_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,1),gamma_velpeaks_c3c4_diff_pow_Prep_pre_pv,'r')
title(['diff pow Prep pre (',num2str(gamma_velpeaks_c3c4_diff_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,2),gamma_velpeaks_c3c4_diff_pow_Prep_i05_pv,'r')
title(['diff pow Prep i05 (',num2str(gamma_velpeaks_c3c4_diff_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,3),gamma_velpeaks_c3c4_diff_pow_Prep_i15_pv,'r')
title(['diff pow Prep i15 (',num2str(gamma_velpeaks_c3c4_diff_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Prep_eeg(:,4),gamma_velpeaks_c3c4_diff_pow_Prep_pos_pv,'r')
title(['diff pow Prep pos (',num2str(gamma_velpeaks_c3c4_diff_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach diff
gamma_velpeaks_c3c4_diff_pow_Reach_pre_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_diff_pow_Reach_pre_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Reach_pre_pf,gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,1))
[gamma_velpeaks_c3c4_diff_pow_Reach_pre_cc,gamma_velpeaks_c3c4_diff_pow_Reach_pre_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_diff_pow_Reach_i05_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_diff_pow_Reach_i05_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Reach_i05_pf,gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,2))
[gamma_velpeaks_c3c4_diff_pow_Reach_i05_cc,gamma_velpeaks_c3c4_diff_pow_Reach_i05_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_diff_pow_Reach_i15_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_diff_pow_Reach_i15_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Reach_i15_pf,gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,3))
[gamma_velpeaks_c3c4_diff_pow_Reach_i15_cc,gamma_velpeaks_c3c4_diff_pow_Reach_i15_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_diff_pow_Reach_pos_pf=polyfit(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_diff_pow_Reach_pos_pv=polyval(gamma_velpeaks_c3c4_diff_pow_Reach_pos_pf,gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,4))
[gamma_velpeaks_c3c4_diff_pow_Reach_pos_cc,gamma_velpeaks_c3c4_diff_pow_Reach_pos_p]=corrcoef(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,1),gamma_velpeaks_c3c4_diff_pow_Reach_pre_pv,'r')
title(['diff pow Reach pre (',num2str(gamma_velpeaks_c3c4_diff_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,2),gamma_velpeaks_c3c4_diff_pow_Reach_i05_pv,'r')
title(['diff pow Reach i05 (',num2str(gamma_velpeaks_c3c4_diff_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,3),gamma_velpeaks_c3c4_diff_pow_Reach_i15_pv,'r')
title(['diff pow Reach i15 (',num2str(gamma_velpeaks_c3c4_diff_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
% plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_diff_pow_Reach_eeg(:,4),gamma_velpeaks_c3c4_diff_pow_Reach_pos_pv,'r')
title(['diff pow Reach pos (',num2str(gamma_velpeaks_c3c4_diff_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Hold norm diff
gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_pf,gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,1))
[gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_cc,gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_pf,gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,2))
[gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_cc,gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_pf,gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,3))
[gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_cc,gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_pf,gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,4))
[gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_cc,gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,1),gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_pv,'r')
title(['norm diff pow Hold pre (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Hold_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,2),gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_pv,'r')
title(['norm diff pow Hold i05 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Hold_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,3),gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_pv,'r')
title(['norm diff pow Hold i15 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Hold_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Hold_eeg(:,4),gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_pv,'r')
title(['norm diff pow Hold pos (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Hold_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Prep norm diff
gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_pf,gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,1))
[gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_cc,gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_pf,gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,2))
[gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_cc,gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_pf,gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,3))
[gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_cc,gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_pf,gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,4))
[gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_cc,gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,1),gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_pv,'r')
title(['norm diff pow Prep pre (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Prep_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,2),gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_pv,'r')
title(['norm diff pow Prep i05 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Prep_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,3),gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_pv,'r')
title(['norm diff pow Prep i15 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Prep_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Prep_eeg(:,4),gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_pv,'r')
title(['norm diff pow Prep pos (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Prep_pos_p(2)),')'])
sgtitle('chronic stroke stim')

%Reach norm diff
gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),1)
gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_pf,gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,1))
[gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_cc,gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))

gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),1)
gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_pf,gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,2))
[gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_cc,gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2))

gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),1)
gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_pf,gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,3))
[gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_cc,gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3))

gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_pf=polyfit(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),1)
gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_pv=polyval(gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_pf,gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,4))
[gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_cc,gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_p]=corrcoef(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4))

figure
subplot(2,2,1); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,1),gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_pv,'r')
title(['norm diff pow Reach pre (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Reach_pre_p(2)),')'])

subplot(2,2,2); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,2),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,2),gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_pv,'r')
title(['norm diff pow Reach i05 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Reach_i05_p(2)),')'])

subplot(2,2,3); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,3),gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_pv,'r')
title(['norm diff pow Reach i15 (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Reach_i15_p(2)),')'])

subplot(2,2,4); hold on
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,4),'k.')
plot(gamma_velpeaks_c3c4_norm_diff_pow_Reach_eeg(:,4),gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_pv,'r')
title(['norm diff pow Reach pos (',num2str(gamma_velpeaks_c3c4_norm_diff_pow_Reach_pos_p(2)),')'])
sgtitle('chronic stroke stim')
%% power - all electrodes all frequencies all times plot
count=0; 
for s1=[4 5 6 7 9]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['G:\Box Sync\MIND - Research\manuscripts\Chang - tdcs stroke VR eeg\data_analysis\data_scripts\final2',subjectData(s1).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                
                for e=1:12
                    eval(['cs_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['cs_sham_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['cs_sham_all.ipsi.',phases{p},'.mean(t,:)=mean(cs_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['cs_sham_all.contra.',phases{p},'.mean(t,:)=mean(cs_sham_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; %I went into the data_for_dlc files and manually changed stim lat for 42 and 43
for s2=[1 2 3 20 21]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s2).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
             
                for e=1:12
                    eval(['cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['cs_stim_all.ipsi.',phases{p},'.mean(t,:)=mean(cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['cs_stim_all.contra.',phases{p},'.mean(t,:)=mean(cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s3=[8 11 15 16 19]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s3).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                                
                for e=1:12
                    eval(['hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['hc_sham_all.ipsi.',phases{p},'.mean(t,:)=mean(hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['hc_sham_all.contra.',phases{p},'.mean(t,:)=mean(hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s4=[10 12 13 14 17 18]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s4).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                
                for e=1:12
                    eval(['hc_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['hc_stim_all.ipsi.',phases{p},'.mean(t,:)=mean(hc_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['hc_stim_all.contra.',phases{p},'.mean(t,:)=mean(hc_stim_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

%% power - all electrodes all frequencies all times plot
%I NEED TO REORDER THE ELECTRODES!!!
count=0; 
for s1=[4 5 6 7 9]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s1).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 13 17 10 20 14 18 11 15 19 21 16];
                        elec_cont=[1 2 6 10 9 3 7 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 3 7 11 4 8 21 5];
                        elec_cont=[12 13 17 10 20 14 18 11 15 19 21 16];
                end
                
                for e=1:12
                    eval(['cs_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['cs_sham_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['cs_sham_all.ipsi.',phases{p},'.mean(t,:)=mean(cs_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['cs_sham_all.contra.',phases{p},'.mean(t,:)=mean(cs_sham_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; %I went into the data_for_dlc files and manually changed stim lat for 42 and 43
for s2=[1 2 3 20 21]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s2).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 13 17 10 20 14 18 11 15 19 21 16];
                        elec_cont=[1 2 6 10 9 3 7 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 3 7 11 4 8 21 5];
                        elec_cont=[12 13 17 10 20 14 18 11 15 19 21 16];
                end
             
                for e=1:12
                    eval(['cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['cs_stim_all.ipsi.',phases{p},'.mean(t,:)=mean(cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['cs_stim_all.contra.',phases{p},'.mean(t,:)=mean(cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s3=[8 11 15 16 19]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s3).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 13 17 10 20 14 18 11 15 19 21 16];
                        elec_cont=[1 2 6 10 9 3 7 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 3 7 11 4 8 21 5];
                        elec_cont=[12 13 17 10 20 14 18 11 15 19 21 16];
                end
                                
                for e=1:12
                    eval(['hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['hc_sham_all.ipsi.',phases{p},'.mean(t,:)=mean(hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['hc_sham_all.contra.',phases{p},'.mean(t,:)=mean(hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s4=[10 12 13 14 17 18]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s4).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 13 17 10 20 14 18 11 15 19 21 16];
                        elec_cont=[1 2 6 10 9 3 7 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 3 7 11 4 8 21 5];
                        elec_cont=[12 13 17 10 20 14 18 11 15 19 21 16];
                end
                
                for e=1:12
                    eval(['hc_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['hc_stim_all.ipsi.',phases{p},'.mean(t,:)=mean(hc_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['hc_stim_all.contra.',phases{p},'.mean(t,:)=mean(hc_stim_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

%% here I want to look at the raw (not normalized) diff of each electrode during stim so I can
%evaluate if its truly the C3-4 electrodes I should be looking at

raw_diff_cs_sham_all_ipsi_Hold=max(cs_sham_all.ipsi.Hold.mean)-min(cs_sham_all.ipsi.Hold.mean)
raw_diff_cs_sham_all_ipsi_Prep=max(cs_sham_all.ipsi.Prep.mean)-min(cs_sham_all.ipsi.Prep.mean)
raw_diff_cs_sham_all_ipsi_Reach=max(cs_sham_all.ipsi.Reach.mean)-min(cs_sham_all.ipsi.Reach.mean)
raw_diff_cs_sham_all_contra_Hold=max(cs_sham_all.contra.Hold.mean)-min(cs_sham_all.contra.Hold.mean)
raw_diff_cs_sham_all_contra_Prep=max(cs_sham_all.contra.Prep.mean)-min(cs_sham_all.contra.Prep.mean)
raw_diff_cs_sham_all_contra_Reach=max(cs_sham_all.contra.Reach.mean)-min(cs_sham_all.contra.Reach.mean)

raw_diff_cs_stim_all_ipsi_Hold=max(cs_stim_all.ipsi.Hold.mean)-min(cs_stim_all.ipsi.Hold.mean)
raw_diff_cs_stim_all_ipsi_Prep=max(cs_stim_all.ipsi.Prep.mean)-min(cs_stim_all.ipsi.Prep.mean)
raw_diff_cs_stim_all_ipsi_Reach=max(cs_stim_all.ipsi.Reach.mean)-min(cs_stim_all.ipsi.Reach.mean)
raw_diff_cs_stim_all_contra_Hold=max(cs_stim_all.contra.Hold.mean)-min(cs_stim_all.contra.Hold.mean)
raw_diff_cs_stim_all_contra_Prep=max(cs_stim_all.contra.Prep.mean)-min(cs_stim_all.contra.Prep.mean)
raw_diff_cs_stim_all_contra_Reach=max(cs_stim_all.contra.Reach.mean)-min(cs_stim_all.contra.Reach.mean)

raw_diff_hc_sham_all_ipsi_Hold=max(hc_sham_all.ipsi.Hold.mean)-min(hc_sham_all.ipsi.Hold.mean)
raw_diff_hc_sham_all_ipsi_Prep=max(hc_sham_all.ipsi.Prep.mean)-min(hc_sham_all.ipsi.Prep.mean)
raw_diff_hc_sham_all_ipsi_Reach=max(hc_sham_all.ipsi.Reach.mean)-min(hc_sham_all.ipsi.Reach.mean)
raw_diff_hc_sham_all_contra_Hold=max(hc_sham_all.contra.Hold.mean)-min(hc_sham_all.contra.Hold.mean)
raw_diff_hc_sham_all_contra_Prep=max(hc_sham_all.contra.Prep.mean)-min(hc_sham_all.contra.Prep.mean)
raw_diff_hc_sham_all_contra_Reach=max(hc_sham_all.contra.Reach.mean)-min(hc_sham_all.contra.Reach.mean)

raw_diff_hc_stim_all_ipsi_Hold=max(hc_stim_all.ipsi.Hold.mean)-min(hc_stim_all.ipsi.Hold.mean)
raw_diff_hc_stim_all_ipsi_Prep=max(hc_stim_all.ipsi.Prep.mean)-min(hc_stim_all.ipsi.Prep.mean)
raw_diff_hc_stim_all_ipsi_Reach=max(hc_stim_all.ipsi.Reach.mean)-min(hc_stim_all.ipsi.Reach.mean)
raw_diff_hc_stim_all_contra_Hold=max(hc_stim_all.contra.Hold.mean)-min(hc_stim_all.contra.Hold.mean)
raw_diff_hc_stim_all_contra_Prep=max(hc_stim_all.contra.Prep.mean)-min(hc_stim_all.contra.Prep.mean)
raw_diff_hc_stim_all_contra_Reach=max(hc_stim_all.contra.Reach.mean)-min(hc_stim_all.contra.Reach.mean)

figure; 
subplot(4,6,1) 
bar(raw_diff_cs_sham_all_ipsi_Hold)
subplot(4,6,2)
bar(raw_diff_cs_sham_all_contra_Hold)
subplot(4,6,3)
bar(raw_diff_cs_sham_all_ipsi_Prep)
subplot(4,6,4)
bar(raw_diff_cs_sham_all_contra_Prep)
subplot(4,6,5)
bar(raw_diff_cs_sham_all_ipsi_Reach)
subplot(4,6,6)
bar(raw_diff_cs_sham_all_contra_Reach)

subplot(4,6,7) 
bar(raw_diff_cs_stim_all_ipsi_Hold)
subplot(4,6,8)
bar(raw_diff_cs_stim_all_contra_Hold)
subplot(4,6,9)
bar(raw_diff_cs_stim_all_ipsi_Prep)
subplot(4,6,10)
bar(raw_diff_cs_stim_all_contra_Prep)
subplot(4,6,11)
bar(raw_diff_cs_stim_all_ipsi_Reach)
subplot(4,6,12)
bar(raw_diff_cs_stim_all_contra_Reach)

subplot(4,6,13) 
bar(raw_diff_hc_sham_all_ipsi_Hold)
subplot(4,6,14)
bar(raw_diff_hc_sham_all_contra_Hold)
subplot(4,6,15)
bar(raw_diff_hc_sham_all_ipsi_Prep)
subplot(4,6,16)
bar(raw_diff_hc_sham_all_contra_Prep)
subplot(4,6,17)
bar(raw_diff_hc_sham_all_ipsi_Reach)
subplot(4,6,18)
bar(raw_diff_hc_sham_all_contra_Reach)

subplot(4,6,19) 
bar(raw_diff_hc_stim_all_ipsi_Hold)
subplot(4,6,20)
bar(raw_diff_hc_stim_all_contra_Hold)
subplot(4,6,21)
bar(raw_diff_hc_stim_all_ipsi_Prep)
subplot(4,6,22)
bar(raw_diff_hc_stim_all_contra_Prep)
subplot(4,6,23)
bar(raw_diff_hc_stim_all_ipsi_Reach)
subplot(4,6,24)
bar(raw_diff_hc_stim_all_contra_Reach)
%let's plot another way
all_elec_pow_ipsi=[raw_diff_cs_sham_all_ipsi_Hold+raw_diff_cs_sham_all_ipsi_Prep+raw_diff_cs_sham_all_ipsi_Reach+...
    raw_diff_cs_stim_all_ipsi_Hold+raw_diff_cs_stim_all_ipsi_Prep+raw_diff_cs_stim_all_ipsi_Reach+...
    raw_diff_hc_sham_all_ipsi_Hold+raw_diff_hc_sham_all_ipsi_Prep+raw_diff_hc_sham_all_ipsi_Reach+...
    raw_diff_hc_stim_all_ipsi_Hold+raw_diff_hc_stim_all_ipsi_Prep+raw_diff_hc_stim_all_ipsi_Reach]
all_elec_pow_contra=[raw_diff_cs_sham_all_contra_Hold+raw_diff_cs_sham_all_contra_Prep+raw_diff_cs_sham_all_contra_Reach+...
    raw_diff_cs_stim_all_contra_Hold+raw_diff_cs_stim_all_contra_Prep+raw_diff_cs_stim_all_contra_Reach+...
    raw_diff_hc_sham_all_contra_Hold+raw_diff_hc_sham_all_contra_Prep+raw_diff_hc_sham_all_contra_Reach+...
    raw_diff_hc_stim_all_contra_Hold+raw_diff_hc_stim_all_contra_Prep+raw_diff_hc_stim_all_contra_Reach]

figure; 
subplot(2,1,1)
bar(all_elec_pow_ipsi)
subplot(2,1,2)
bar(all_elec_pow_contra)
figure; bar(all_elec_pow_ipsi-all_elec_pow_contra)
all_elec_pow_ipsi_vs_contra=all_elec_pow_ipsi-all_elec_pow_contra

all_elec_pow_ipsi_vs_contra_cs_sham=[raw_diff_cs_sham_all_ipsi_Hold+raw_diff_cs_sham_all_ipsi_Prep+raw_diff_cs_sham_all_ipsi_Reach]-...
    [raw_diff_cs_sham_all_contra_Hold+raw_diff_cs_sham_all_contra_Prep+raw_diff_cs_sham_all_contra_Reach]
all_elec_pow_ipsi_vs_contra_cs_stim=[raw_diff_cs_stim_all_ipsi_Hold+raw_diff_cs_stim_all_ipsi_Prep+raw_diff_cs_stim_all_ipsi_Reach]-...
    [raw_diff_cs_stim_all_contra_Hold+raw_diff_cs_stim_all_contra_Prep+raw_diff_cs_stim_all_contra_Reach]
all_elec_pow_ipsi_vs_contra_hc_sham=[raw_diff_hc_sham_all_ipsi_Hold+raw_diff_hc_sham_all_ipsi_Prep+raw_diff_hc_sham_all_ipsi_Reach]-...
    [raw_diff_hc_sham_all_contra_Hold+raw_diff_hc_sham_all_contra_Prep+raw_diff_hc_sham_all_contra_Reach]
all_elec_pow_ipsi_vs_contra_hc_stim=[raw_diff_hc_stim_all_ipsi_Hold+raw_diff_hc_stim_all_ipsi_Prep+raw_diff_hc_stim_all_ipsi_Reach]-...
    [raw_diff_hc_stim_all_contra_Hold+raw_diff_hc_stim_all_contra_Prep+raw_diff_hc_stim_all_contra_Reach]

all_elec_pow_ipsi_vs_contra_all_groups=[all_elec_pow_ipsi_vs_contra_cs_sham+all_elec_pow_ipsi_vs_contra_cs_stim+...
    all_elec_pow_ipsi_vs_contra_hc_sham+all_elec_pow_ipsi_vs_contra_hc_stim]

all_elec_pow_ipsi_vs_contra_all_groups2=mean([all_elec_pow_ipsi_vs_contra_cs_sham;all_elec_pow_ipsi_vs_contra_cs_stim;...
    all_elec_pow_ipsi_vs_contra_hc_sham;all_elec_pow_ipsi_vs_contra_hc_stim])

anova1([all_elec_pow_ipsi_vs_contra_cs_sham;all_elec_pow_ipsi_vs_contra_cs_stim;...
    all_elec_pow_ipsi_vs_contra_hc_sham;all_elec_pow_ipsi_vs_contra_hc_stim])








%% think this can go away! power - ind electrodes all frequencies all times plot
count=0; 
for s1=[4 5 6 7 9]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s1).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                
                for e=1:12
                    eval(['cs_sham_ind.ipsi.',phases{p},'.',TOI_mod1{t},'.e',num2str(elec_ipsi(e)),'=mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),')))'])
                    eval(['cs_sham_ind.contra.',phases{p},'.',TOI_mod1{t},'.e',num2str(elec_contra(e)),'=mean(mean(subjectData(s1).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),')))'])
                end
            end
        end
    %end
end



count=0; %I went into the data_for_dlc files and manually changed stim lat for 42 and 43
for s2=[1 2 3 20 21]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s2).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
             
                for e=1:12
                    eval(['cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s2).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['cs_stim_all.ipsi.',phases{p},'.mean(t,:)=mean(cs_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['cs_stim_all.contra.',phases{p},'.mean(t,:)=mean(cs_stim_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s3=[8 11 15 16 19]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s3).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                                
                for e=1:12
                    eval(['hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s3).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end

for p=1:3
    for t=1:4
        eval(['hc_sham_all.ipsi.',phases{p},'.mean(t,:)=mean(hc_sham_all.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        eval(['hc_sham_all.contra.',phases{p},'.mean(t,:)=mean(hc_sham_all.contra.',phases{p},'.',TOI_mod1{t},')'])
    end
end

count=0; 
for s4=[10 12 13 14 17 18]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s4).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=[12 10 17 13 11 18 14 20 21 19 15 16];
                        elec_cont=[1 2 6 10 9 7 3 11 4 8 21 5];
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=[1 2 6 10 9 7 3 11 4 8 21 5];
                        elec_cont=[12 10 17 13 11 18 14 20 21 19 15 16];
                end
                
                for e=1:12
                    eval(['hc_stim_all.ipsi.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_ipsi(e)),',',num2str(p),',',num2str(t),'),3)))'])
                    eval(['hc_stim_all.contra.',phases{p},'.',TOI_mod1{t},'(count,e)=mean(mean(mean(subjectData(s4).power.data(1:50,9:60,',num2str(elec_cont(e)),',',num2str(p),',',num2str(t),'),3)))'])
                end
            end
        end
    %end
end


%% 
figure; set(gcf,'Position',[36 -38 1391 796])
%cs sham
subplot(4,6,1); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Hold')

subplot(4,6,2); hold on 
for i=1:12
    plot(cs_sham_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Hold')

subplot(4,6,3); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Prep')

subplot(4,6,4); hold on 
for i=1:12
    plot(cs_sham_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Prep')

subplot(4,6,5); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Reach')

subplot(4,6,6); hold on 
for i=1:12
    plot(cs_sham_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_sham_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Reach')

%cs stim
subplot(4,6,7); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Hold')

subplot(4,6,8); hold on 
for i=1:12
    plot(cs_stim_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Hold')

subplot(4,6,9); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Prep')

subplot(4,6,10); hold on 
for i=1:12
    plot(cs_stim_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Prep')

subplot(4,6,11); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Reach')

subplot(4,6,12); hold on 
for i=1:12
    plot(cs_stim_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(cs_stim_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Reach')

%hc sham
subplot(4,6,13); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Hold')

subplot(4,6,14); hold on 
for i=1:12
    plot(hc_sham_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Hold')

subplot(4,6,15); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Prep')

subplot(4,6,16); hold on 
for i=1:12
    plot(hc_sham_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Prep')

subplot(4,6,17); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Reach')

subplot(4,6,18); hold on 
for i=1:12
    plot(hc_sham_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_sham_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Reach')

%hc stim
subplot(4,6,19); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Hold')

subplot(4,6,20); hold on 
for i=1:12
    plot(hc_stim_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Hold')

subplot(4,6,21); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Prep')

subplot(4,6,22); hold on 
for i=1:12
    plot(hc_stim_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Prep')

subplot(4,6,23); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Reach')

subplot(4,6,24); hold on 
for i=1:12
    plot(hc_stim_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==6
        plot(hc_stim_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Reach')

for i=1:24
    subplot(4,6,i)
    set(gca,'ylim',[5 20])
end

savefig('all_electrodes_allfreq_time.fig')

%calculate percentage mean change!!!!

%% A Power calculations
% cs_stim=[1 2 3 20 21]
% cs_sham=[4 5 6 7 9]
% hc_stim=[10 12 13 14 17 18]
% hc_sham=[8 11 15 16 19];

TOI={'pre-stim (baseline)','intrastim (5 min)','intrastim (15 min)','post-stim (5 min)'};
TOI_mod1={'pre','i05','i15','pos'};
TOI_mod={'prestim','intra5','intra15','poststim5'};
FOI_label={'Delta','Theta','Alpha','Beta','Gamma'};
FOI_freq={'1:8','10:16','16:24','26:60','60:100'};

norm=false;
phases={'Hold','Prep','Reach'};
DOI={'stroke','healthy'};
stimtypes=[0,2];
stimname={'Sham','Stim'};
savefigures=false;

%c3c4 only
count=0;
for s1=[4 5 6 7 9]
    count=count+1;
    for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s1).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=18;
                        elec_cont=7;
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=7;
                        elec_cont=18;
                end
                eval(['cs_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s1).power.data(',FOI_freq{f},',9:60,',num2str(elec_ipsi),',',num2str(p),',',num2str(t),')))'])
                eval(['cs_sham_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s1).power.data(',FOI_freq{f},',9:60,',num2str(elec_cont),',',num2str(p),',',num2str(t),')))'])
            end
        end
    end
end

for f=1:5
    for p=1:3
        for t=1:4
            eval(['cs_sham_c3c4.',FOI_label{f},'.norm_diff.',phases{p},'.',TOI_mod1{t},'=(mean(cs_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')-mean(cs_sham_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'))/mean(cs_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        end
    end
end

for p=1:3
    eval(['cs_sham_c3c4_all_freq_',phases{p},'(1,:)=[cs_sham_c3c4.Delta.norm_diff.',phases{p},'.pre cs_sham_c3c4.Delta.norm_diff.',phases{p},'.i05 cs_sham_c3c4.Delta.norm_diff.',phases{p},'.i15 cs_sham_c3c4.Delta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'(2,:)=[cs_sham_c3c4.Theta.norm_diff.',phases{p},'.pre cs_sham_c3c4.Theta.norm_diff.',phases{p},'.i05 cs_sham_c3c4.Theta.norm_diff.',phases{p},'.i15 cs_sham_c3c4.Theta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'(3,:)=[cs_sham_c3c4.Alpha.norm_diff.',phases{p},'.pre cs_sham_c3c4.Alpha.norm_diff.',phases{p},'.i05 cs_sham_c3c4.Alpha.norm_diff.',phases{p},'.i15 cs_sham_c3c4.Alpha.norm_diff.',phases{p},'.pos];'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'(4,:)=[cs_sham_c3c4.Beta.norm_diff.',phases{p},'.pre cs_sham_c3c4.Beta.norm_diff.',phases{p},'.i05 cs_sham_c3c4.Beta.norm_diff.',phases{p},'.i15 cs_sham_c3c4.Beta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'(5,:)=[cs_sham_c3c4.Gamma.norm_diff.',phases{p},'.pre cs_sham_c3c4.Gamma.norm_diff.',phases{p},'.i05 cs_sham_c3c4.Gamma.norm_diff.',phases{p},'.i15 cs_sham_c3c4.Gamma.norm_diff.',phases{p},'.pos];'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'_abs=abs(cs_sham_c3c4_all_freq_',phases{p},');'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min=min(min(cs_sham_c3c4_all_freq_',phases{p},'_abs));'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm=cs_sham_c3c4_all_freq_',phases{p},'_abs/cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min;'])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean=mean(cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm,2);';])
    eval(['cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean_round=round(cs_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean)'])
end
    
count=0; %I went into the data_for_dlc files and manually changed stim lat for 42 and 43, so you don't need 
%to do anything special for them
for s2=[1 2 3 20 21]
    count=count+1;
    for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s2).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=18;
                        elec_cont=7;
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=7;
                        elec_cont=18;
                end
                eval(['cs_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s2).power.data(',FOI_freq{f},',9:60,',num2str(elec_ipsi),',',num2str(p),',',num2str(t),')))'])
                eval(['cs_stim_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s2).power.data(',FOI_freq{f},',9:60,',num2str(elec_cont),',',num2str(p),',',num2str(t),')))'])
            end
        end
    end
end

for f=1:5
    for p=1:3
        for t=1:4
            eval(['cs_stim_c3c4.',FOI_label{f},'.norm_diff.',phases{p},'.',TOI_mod1{t},'=(mean(cs_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')-mean(cs_stim_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'))/mean(cs_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        end
    end
end

for p=1:3
    eval(['cs_stim_c3c4_all_freq_',phases{p},'(1,:)=[cs_stim_c3c4.Delta.norm_diff.',phases{p},'.pre cs_stim_c3c4.Delta.norm_diff.',phases{p},'.i05 cs_stim_c3c4.Delta.norm_diff.',phases{p},'.i15 cs_stim_c3c4.Delta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'(2,:)=[cs_stim_c3c4.Theta.norm_diff.',phases{p},'.pre cs_stim_c3c4.Theta.norm_diff.',phases{p},'.i05 cs_stim_c3c4.Theta.norm_diff.',phases{p},'.i15 cs_stim_c3c4.Theta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'(3,:)=[cs_stim_c3c4.Alpha.norm_diff.',phases{p},'.pre cs_stim_c3c4.Alpha.norm_diff.',phases{p},'.i05 cs_stim_c3c4.Alpha.norm_diff.',phases{p},'.i15 cs_stim_c3c4.Alpha.norm_diff.',phases{p},'.pos];'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'(4,:)=[cs_stim_c3c4.Beta.norm_diff.',phases{p},'.pre cs_stim_c3c4.Beta.norm_diff.',phases{p},'.i05 cs_stim_c3c4.Beta.norm_diff.',phases{p},'.i15 cs_stim_c3c4.Beta.norm_diff.',phases{p},'.pos];'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'(5,:)=[cs_stim_c3c4.Gamma.norm_diff.',phases{p},'.pre cs_stim_c3c4.Gamma.norm_diff.',phases{p},'.i05 cs_stim_c3c4.Gamma.norm_diff.',phases{p},'.i15 cs_stim_c3c4.Gamma.norm_diff.',phases{p},'.pos];'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'_abs=abs(cs_stim_c3c4_all_freq_',phases{p},');'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min=min(min(cs_stim_c3c4_all_freq_',phases{p},'_abs));'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm=cs_stim_c3c4_all_freq_',phases{p},'_abs/cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min;'])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean=mean(cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm,2);';])
    eval(['cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean_round=round(cs_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean)'])
end

count=0;
for s3=[8 11 15 16 19]
    count=count+1;
    for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s3).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=18;
                        elec_cont=7;
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=7;
                        elec_cont=18;
                end
                eval(['hc_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s3).power.data(',FOI_freq{f},',9:60,',num2str(elec_ipsi),',',num2str(p),',',num2str(t),')))'])
                eval(['hc_sham_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s3).power.data(',FOI_freq{f},',9:60,',num2str(elec_cont),',',num2str(p),',',num2str(t),')))'])
            end
        end
    end
end

for f=1:5
    for p=1:3
        for t=1:4
            eval(['hc_sham_c3c4.',FOI_label{f},'.norm_diff.',phases{p},'.',TOI_mod1{t},'=(mean(hc_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')-mean(hc_sham_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'))/mean(hc_sham_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        end
    end
end

for p=1:3
    eval(['hc_sham_c3c4_all_freq_',phases{p},'(1,:)=[hc_sham_c3c4.Delta.norm_diff.',phases{p},'.pre hc_sham_c3c4.Delta.norm_diff.',phases{p},'.i05 hc_sham_c3c4.Delta.norm_diff.',phases{p},'.i15 hc_sham_c3c4.Delta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'(2,:)=[hc_sham_c3c4.Theta.norm_diff.',phases{p},'.pre hc_sham_c3c4.Theta.norm_diff.',phases{p},'.i05 hc_sham_c3c4.Theta.norm_diff.',phases{p},'.i15 hc_sham_c3c4.Theta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'(3,:)=[hc_sham_c3c4.Alpha.norm_diff.',phases{p},'.pre hc_sham_c3c4.Alpha.norm_diff.',phases{p},'.i05 hc_sham_c3c4.Alpha.norm_diff.',phases{p},'.i15 hc_sham_c3c4.Alpha.norm_diff.',phases{p},'.pos];'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'(4,:)=[hc_sham_c3c4.Beta.norm_diff.',phases{p},'.pre hc_sham_c3c4.Beta.norm_diff.',phases{p},'.i05 hc_sham_c3c4.Beta.norm_diff.',phases{p},'.i15 hc_sham_c3c4.Beta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'(5,:)=[hc_sham_c3c4.Gamma.norm_diff.',phases{p},'.pre hc_sham_c3c4.Gamma.norm_diff.',phases{p},'.i05 hc_sham_c3c4.Gamma.norm_diff.',phases{p},'.i15 hc_sham_c3c4.Gamma.norm_diff.',phases{p},'.pos];'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'_abs=abs(hc_sham_c3c4_all_freq_',phases{p},');'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min=min(min(hc_sham_c3c4_all_freq_',phases{p},'_abs));'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm=hc_sham_c3c4_all_freq_',phases{p},'_abs/hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min;'])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean=mean(hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm,2);';])
    eval(['hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean_round=round(hc_sham_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean)'])
end

count=0;
for s4=[10 12 13 14 17 18]
    count=count+1;
    for f=1:5
        for p=1:3
            for t=1:4
                load(['D:\Box Sync\allen_erp_data\data_for_dlc\',subjectData(s4).SubjectName,'_sessioninfo.mat'])
                if strcmp(sessioninfo.stimlat,'R')
                        elec_ipsi=18;
                        elec_cont=7;
                    elseif strcmp(sessioninfo.stimlat,'L')
                        elec_ipsi=7;
                        elec_cont=18;
                end
                eval(['hc_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s4).power.data(',FOI_freq{f},',9:60,',num2str(elec_ipsi),',',num2str(p),',',num2str(t),')))'])
                eval(['hc_stim_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'(count)=mean(mean(subjectData(s4).power.data(',FOI_freq{f},',9:60,',num2str(elec_cont),',',num2str(p),',',num2str(t),')))'])
            end
        end
    end
end

for f=1:5
    for p=1:3
        for t=1:4
            eval(['hc_stim_c3c4.',FOI_label{f},'.norm_diff.',phases{p},'.',TOI_mod1{t},'=(mean(hc_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')-mean(hc_stim_c3c4.',FOI_label{f},'.contra.',phases{p},'.',TOI_mod1{t},'))/mean(hc_stim_c3c4.',FOI_label{f},'.ipsi.',phases{p},'.',TOI_mod1{t},')'])
        end
    end
end

for p=1:3
    eval(['hc_stim_c3c4_all_freq_',phases{p},'(1,:)=[hc_stim_c3c4.Delta.norm_diff.',phases{p},'.pre hc_stim_c3c4.Delta.norm_diff.',phases{p},'.i05 hc_stim_c3c4.Delta.norm_diff.',phases{p},'.i15 hc_stim_c3c4.Delta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'(2,:)=[hc_stim_c3c4.Theta.norm_diff.',phases{p},'.pre hc_stim_c3c4.Theta.norm_diff.',phases{p},'.i05 hc_stim_c3c4.Theta.norm_diff.',phases{p},'.i15 hc_stim_c3c4.Theta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'(3,:)=[hc_stim_c3c4.Alpha.norm_diff.',phases{p},'.pre hc_stim_c3c4.Alpha.norm_diff.',phases{p},'.i05 hc_stim_c3c4.Alpha.norm_diff.',phases{p},'.i15 hc_stim_c3c4.Alpha.norm_diff.',phases{p},'.pos];'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'(4,:)=[hc_stim_c3c4.Beta.norm_diff.',phases{p},'.pre hc_stim_c3c4.Beta.norm_diff.',phases{p},'.i05 hc_stim_c3c4.Beta.norm_diff.',phases{p},'.i15 hc_stim_c3c4.Beta.norm_diff.',phases{p},'.pos];'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'(5,:)=[hc_stim_c3c4.Gamma.norm_diff.',phases{p},'.pre hc_stim_c3c4.Gamma.norm_diff.',phases{p},'.i05 hc_stim_c3c4.Gamma.norm_diff.',phases{p},'.i15 hc_stim_c3c4.Gamma.norm_diff.',phases{p},'.pos];'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'_abs=abs(hc_stim_c3c4_all_freq_',phases{p},');'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min=min(min(hc_stim_c3c4_all_freq_',phases{p},'_abs));'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm=hc_stim_c3c4_all_freq_',phases{p},'_abs/hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min;'])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean=mean(hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm,2);';])
    eval(['hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean_round=round(hc_stim_c3c4_all_freq_',phases{p},'_abs_min_min_norm_mean)'])
end

%normalized difference

%plot
figure; set(gcf,'Position',[36 -38 1391 796])
subplot(4,3,1)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_sham_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)

subplot(4,3,2)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_sham_c3c4_all_freq_Prep_abs_min_min_norm_mean_round)

subplot(4,3,3)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_sham_c3c4_all_freq_Reach_abs_min_min_norm_mean_round)

subplot(4,3,4)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)

subplot(4,3,5)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Prep_abs_min_min_norm_mean_round)

subplot(4,3,6)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Reach_abs_min_min_norm_mean_round)

subplot(4,3,7)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_sham_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)

subplot(4,3,8)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_sham_c3c4_all_freq_Prep_abs_min_min_norm_mean_round)

subplot(4,3,9)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_sham_c3c4_all_freq_Reach_abs_min_min_norm_mean_round)

subplot(4,3,10)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)

subplot(4,3,11)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Prep_abs_min_min_norm_mean_round)

subplot(4,3,12)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Reach_abs_min_min_norm_mean_round);

% next plot
figure;
subplot(2,3,1)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)
%ylabel('Chronic Stroke')
title('Hold')
set(gca,'ThetaTickLabel',[],'RTickLabel',[])

subplot(2,3,2)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Prep_abs_min_min_norm_mean_round,'FaceColor',[0.5 0.5 0.5])
title('Prep')
set(gca,'ThetaTickLabel',[],'RTickLabel',[])

subplot(2,3,3)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',cs_stim_c3c4_all_freq_Reach_abs_min_min_norm_mean_round,'FaceColor','red')
title('Reach')
set(gca,'ThetaTickLabel',[],'RTickLabel',[])

subplot(2,3,4)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Hold_abs_min_min_norm_mean_round)
%ylabel('Healthy Control')
set(gca,'ThetaTickLabel',[],'RTickLabel',[])

subplot(2,3,5)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Prep_abs_min_min_norm_mean_round,'FaceColor',[0.5 0.5 0.5])
set(gca,'ThetaTickLabel',[],'RTickLabel',[])

subplot(2,3,6)
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Reach_abs_min_min_norm_mean_round,'FaceColor','red','EdgeColor','off');
set(gca,'ThetaTickLabel',[],'RTickLabel',[],'EdgeColor','off')
%% 

figure
subplot(2,2,1)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin')
title('chronic stroke sham')

subplot(2,2,2)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin')
title('chronic stroke stim')

subplot(2,2,3)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin')
title('healthy control sham')

subplot(2,2,4)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin')
title('healthy control stim')

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin,1)
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin,1)
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin,1)
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin,1)
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)
end


figure
subplot(2,2,1)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm')
title('chronic stroke sham norm')

subplot(2,2,2)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin_norm')
title('chronic stroke stim norm')

subplot(2,2,3)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin_norm')
title('healthy control sham norm')

subplot(2,2,4)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin_norm')
title('healthy control stim norm')

% now normalize the eeg matrices
for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg,1)
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg,1)
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg,1)
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1)
end

for i=1:size(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg,1)
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg_norm(i,:)=...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,:)/...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1)
end

%now combine both sets of matrices

gamma_movementDuration_c3c4_diff_hold_prep_all_kin_norm=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin_norm]
 
gamma_movementDuration_c3c4_diff_hold_prep_all_eeg_norm=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg_norm]
    
gamma_movementDuration_c3c4_diff_hold_prep_all_kin_eeg_pf=polyfit(gamma_movementDuration_c3c4_diff_hold_prep_all_eeg_norm,...
    gamma_movementDuration_c3c4_diff_hold_prep_all_kin_norm,1)
gamma_movementDuration_c3c4_diff_hold_prep_all_kin_eeg_pv=polyval(gamma_movementDuration_c3c4_diff_hold_prep_all_kin_eeg_pf,...
    gamma_movementDuration_c3c4_diff_hold_prep_all_eeg_norm)
[gamma_movementDuration_c3c4_diff_hold_prep_all_kin_eeg_r,gamma_movementDuration_c3c4_diff_hold_prep_all_kin_eeg_p]=...
corrcoef(gamma_movementDuration_c3c4_diff_hold_prep_all_eeg_norm,gamma_movementDuration_c3c4_diff_hold_prep_all_kin_norm)
%ok not significant overall

%try just CS and HC stim
gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin_norm=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin_norm]
 
gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg_norm=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg_norm;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg_norm]

figure
plot(gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg_norm(:,4)',...
    gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin_norm(:,4)','.')




figure
subplot(2,2,1)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm(:,1)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm(:,1)','.')
title('chronic stroke sham pre')
subplot(2,2,2)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm(:,2)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm(:,2)','.')
title('chronic stroke sham i05')
subplot(2,2,3)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm(:,3)','.')
title('chronic stroke sham i15')
subplot(2,2,4)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg_norm(:,4)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin_norm(:,4)','.')
title('chronic stroke sham pos')


scatter(gamma_movementDuration_c3c4_diff_hold_prep_all_eeg_norm,gamma_movementDuration_c3c4_diff_hold_prep_all_kin_norm)
%possible there's an outlier problem, so I better look into this now

hp_hc_stim_lr_pf=polyfit(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],3),gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3),1)
hp_hc_stim_lr_pv=polyval(hp_hc_stim_lr_pf,gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3))
[cc_hp_hc_stim_lr_r,cc_hp_hc_stim_lr_p]=corrcoef(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],3),gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin([1 2 3 4 6],3))


gamma_movementDuration_c3c4_diff_hold_prep_all_kin=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin;...
     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin]
 
gamma_movementDuration_c3c4_diff_hold_prep_all_eeg=...
    [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg;...
     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg]

figure;hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)','b.')
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],3)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin([1 2 3 4 6],3)','r.')

gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin=...
     [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin([1 2 3 4 6],:)]
 
gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg=...
     [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg;...
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],:)]

[cc_r,cc_p]=corrcoef(gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,3),gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,3))

%ok this is significant so need to consider the outlier issue
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin)

isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin)
%this shows that there are a smattering of outliers here and there; some
%are obvious, others aren't
%I will now start plotting some combinations to look for really obvious
%ones


gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin=...
     [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin;...
      gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin([1 2 4 5],:);
      gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin([1 2 3 4 6],:);
      gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin]
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin)
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin)
 
gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg=...
     [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg;...
     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg([1 2 4 5],:);
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],:);
     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg]
isoutlier(gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg)
 
figure;hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg([1 2 4 5],3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin([1 2 4 5],3)','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg([1 2 3 4 6],3)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin([1 2 3 4 6],3)','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)','c.','MarkerSize',8)

figure
subplot(2,2,1);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1)','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)','c.','MarkerSize',8)
title('pre')
set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,2);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,2)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,2)','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,2)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2)','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,2)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,2)','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,2)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,2)','c.','MarkerSize',8)
title('i05')
set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,3);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)','c.','MarkerSize',8)
title('i15')
set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,4);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,4)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,4)','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,4)',gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4)','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,4)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,4)','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,4)',gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,4)','c.','MarkerSize',8)
title('pos')
set(gca,'xlim',[-10 15],'ylim',[0 5])
sgtitle('Nonnormalized')


figure
subplot(2,2,1);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('pre')
% %set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,2);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('i05')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,3);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('i15')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,4);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('pos')
%set(gca,'xlim',[-10 15],'ylim',[0 5])
sgtitle('Kinematic Normalized')

%%
%this is a really interesting plot, suggests there's something about time
%spent under the 0 line
figure
subplot(2,2,1); hold on
for i=1:5
plot([(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('chronic stroke sham kin')

subplot(2,2,2); hold on
for i=1:5
plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,2) ...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,4)])
end
plot([1 4],[0 0],'k')
title('chronic stroke sham eeg')

subplot(2,2,3); hold on
for i=1:5
plot([(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('chronic stroke stim kin')

subplot(2,2,4); hold on
for i=1:5
plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,2) ...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,4)])
end
title('chronic stroke stim eeg')
plot([1 4],[0 0],'k')


figure
subplot(2,2,1); hold on
for i=1:5
plot([(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('healthy sham kin')

subplot(2,2,2); hold on
for i=1:5
plot([gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,2) ...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,4)])
end
plot([1 4],[0 0],'k')
set(gca,'ylim',[-10 10])
title('healthy sham eeg')

subplot(2,2,3); hold on
for i=1:5
plot([(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('healthy stim kin')

subplot(2,2,4); hold on
for i=1:5
plot([gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,2) ...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,4)])
end
title('healthy stim eeg')
set(gca,'ylim',[-10 10])
plot([1 4],[0 0],'k')

%velocityPeaks
figure
subplot(2,2,1); hold on
for i=1:5
plot([(gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,2)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,3)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,4)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('chronic stroke sham kin')

subplot(2,2,2); hold on
for i=1:5
plot([gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1) gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_eeg(i,2) ...
    gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_eeg(i,3) gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Sham_eeg(i,4)])
end
plot([1 4],[0 0],'k')
title('chronic stroke sham eeg')

subplot(2,2,3); hold on
for i=1:5
plot([(gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,2)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,3)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,4)/gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('chronic stroke stim kin')

subplot(2,2,4); hold on
for i=1:5
plot([gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1) gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(i,2) ...
    gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(i,3) gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(i,4)])
end
title('chronic stroke stim eeg')
plot([1 4],[0 0],'k')


figure
subplot(2,2,1); hold on
for i=1:5
plot([(gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,2)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,3)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,4)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('healthy sham kin')

subplot(2,2,2); hold on
for i=1:5
plot([gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1) gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_eeg(i,2) ...
    gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_eeg(i,3) gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Sham_eeg(i,4)])
end
plot([1 4],[0 0],'k')
title('healthy sham eeg')

subplot(2,2,3); hold on
for i=1:5
plot([(gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,2)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,3)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
    (gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,4)/gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_kin(i,1))])
end
plot([1 4],[1 1],'k')
title('healthy stim kin')

subplot(2,2,4); hold on
for i=1:5
plot([gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1) gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_eeg(i,2) ...
    gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_eeg(i,3) gamma_velocityPeaks_c3c4_diff_hold_prep_healthy_Stim_eeg(i,4)])
end
title('healthy stim eeg')
plot([1 4],[0 0],'k')





%% now I will plot the above as a grid

figure; hold on
%subplot(2,2,1); hold on
%subplot(2,2,4); hold on
for i=1:5
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,2),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,3),...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'ko','MarkerSize',15)
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,4),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
end

for i=1:5
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,2),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,3),...
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'ro','MarkerSize',15)
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,4),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
end

for i=1:5
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,2),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,3),...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'co','MarkerSize',15)
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,4),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
end

for i=1:6
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,2),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,3),...
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'mo','MarkerSize',15)
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,4),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
end

plot([-10 10],[1 1],'k')
plot([0 0],[0 1.5],'k')

% k1(:,1)=gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)
% k1(:,2)=gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)
% k1(:,3)=gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)
% k1(:,4)=gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(1:5,3)
% dendrogram(k1')

% clusterdata(k1,1)
% %both kinematics and eeg normalized
% figure; hold on
% %subplot(2,2,1); hold on
% subplot(2,2,3); hold on
% for i=1:5
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,2),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'ro','MarkerSize',15)
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,4),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1),'k.')
% end
% 
% for i=1:5
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,2),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'go','MarkerSize',15)
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,4),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1),'r.')
% end
% 
% for i=1:5
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,2),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'co','MarkerSize',15)
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,4),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1),'c.')
% end
% 
% for i=1:5
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,2),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'mo','MarkerSize',15)
% % plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,4),...
% %     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1),'m.')
% end



%testing out clustering
% N = 300;  % Size of each cluster
% r1 = 2;   % Radius of first circle
% r2 = 4;   % Radius of second circle
% theta = linspace(0,2*pi,N)';
% X1 = r1*[cos(theta),sin(theta)]+ rand(N,1); 
% X2 = r2*[cos(theta),sin(theta)]+ rand(N,1);
% X = [X1;X2]; %
% idx=spectralcluster(X,2)


% gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1),'ko','MarkerSize',15)
% %
% X3=[gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)]
% idx=spectralcluster(X4,4)
% 
% X4=[gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg;gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg;
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
%         gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)]

X5=[gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)]
X6=[gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)]
%idx=spectralcluster(X6,3,'SimilarityGraph','knn')
%keep going
X7=[X5,X6]
[idx1,idx2,idx3,idx4,idx5,idx6]=kmedoids(X7,'Distance','correlation','Start','sample');

figure; %set(gcf,'Position',[2644 320 560 420])
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),idx1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')

% X8=[1;1;1;1;1;2;2;2;2;2;3;3;3;3;3;4;4;4;4;4;4]
% X9=[idx,X8]
% figure
% silhouette(X7,idx)
% x11=linkage(X7);
% figure; dendrogram(x11)
% y=inconsistent(idx)
% help spectralcluster

Y=pdist(X7)
Z=linkage(Y,'average')
[c,D]=cophenet(Z,Y)
[r,p]=corr(Y',D','type','spearman')

% [gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)]
%  figure      
% plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg',...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)]','.')
%      
%end
%set(gca,'xlim',[-10 10],'ylim',[0 1.5])
%plot([-10 10],[0 0])
% figure; hold on
% plot(-4.6984,1.1173,'.')
% plot(1.0997,0.9260,'.')

% figure; hold on
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(1,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1),'.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(2,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(2,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(2,1),'.')
% plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(1,1),gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)],'.')
% plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(1,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)],'.')
% plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(1,1),...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(1,1)],'.')
%      



% (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1))])
% end
% plot([1 4],[1 1],'k')
% title('chronic stroke sham kin')
% 
% subplot(2,2,2); hold on
% for i=1:5
% plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,2) ...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(i,4)])
% end
% plot([1 4],[0 0],'k')
% title('chronic stroke sham eeg')
% 
% subplot(2,2,3); hold on
% for i=1:5
% plot([(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1))])
% end
% plot([1 4],[1 1],'k')
% title('chronic stroke stim kin')
% 
% subplot(2,2,4); hold on
% for i=1:5
% plot([gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,2) ...
%     gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(i,4)])
% end
% title('chronic stroke stim eeg')
% plot([1 4],[0 0],'k')
% 
% 
% figure
% subplot(2,2,1); hold on
% for i=1:5
% plot([(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1))])
% end
% plot([1 4],[1 1],'k')
% title('healthy sham kin')
% 
% subplot(2,2,2); hold on
% for i=1:5
% plot([gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,2) ...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(i,4)])
% end
% plot([1 4],[0 0],'k')
% set(gca,'ylim',[-10 10])
% title('healthy sham eeg')
% 
% subplot(2,2,3); hold on
% for i=1:5
% plot([(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,2)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,3)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1)) ...
%     (gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,4)/gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1))])
% end
% plot([1 4],[1 1],'k')
% title('healthy stim kin')
% 
% subplot(2,2,4); hold on
% for i=1:5
% plot([gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,1) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,2) ...
%     gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,3) gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(i,4)])
% end
% title('healthy stim eeg')
% set(gca,'ylim',[-10 10])
% plot([1 4],[0 0],'k')


%%







figure
subplot(2,2,1);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1)','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)','c.','MarkerSize',8)
title('pre')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,2);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,2)','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2)','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,2)','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,2)','c.','MarkerSize',8)
title('i05')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,3);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)','c.','MarkerSize',8)
title('i15')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,4);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,4)','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4)','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,4)','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,4)','c.','MarkerSize',8)
title('pos')
%set(gca,'xlim',[-10 15],'ylim',[0 5])
sgtitle('EEG normalized')

%Combined
figure
subplot(2,2,1);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
title('pre')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,2);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,2)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,2)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,2)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,2)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
title('i05')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,3);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
title('i15')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,4);hold on
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,4)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,4)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot((Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,4)-Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1))',...
    (Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,4)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
title('pos')
%set(gca,'xlim',[-10 15],'ylim',[0 5])
sgtitle('Combined EEG and kinematic normalized')


%Now I will do regressions on 2 groups - chronic stim+ sham and
%chronic+healthy stim

figure
subplot(2,2,1);hold on

Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg=[Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg;Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg]
Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin=[Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)]

[cc_r1,cc_p1]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg(:,1),Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin(:,1))
[cc_r2,cc_p2]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg(:,2),Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin(:,2))
[~,cc_p3]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin(:,3))
[cc_r4,~]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_eeg(:,4),Gamma_movementDuration_c3c4_diff_hold_prep_all_stroke_kin(:,4))

Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg=[Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg;Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg]
Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin=[Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)]

[cc_r1,cc_p1]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,1),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,1))
[cc_r2,cc_p2]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,2),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,2))
[cc_r3,cc_p3]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,3))
[cc_r4,cc_p4]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,4),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,4))
% the pos is sign at 0.048, which is not enough to show in a paper, plus
% it's reversed!! it's the opposite relationship, which shows me you have
% to normalize both eeg and kinematics I believe

Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg=[Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)]
Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin=[Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)]

[cc_r1,cc_p1]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,1),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,1))
[cc_r2,cc_p2]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,2),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,2))
[cc_r3,cc_p3]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,3))
[cc_r4,cc_p4]=corrcoef(Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_eeg(:,4),Gamma_movementDuration_c3c4_diff_hold_prep_all_stim_kin(:,4))







plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,1)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('pre')
% %set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,2);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,2)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,2)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('i05')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,3);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('i15')
%set(gca,'xlim',[-10 15],'ylim',[0 5])

subplot(2,2,4);hold on
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1))','b.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1))','r.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1))','g.','MarkerSize',8)
plot(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,4)',(gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,4)./gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1))','c.','MarkerSize',8)
plot([-10 15],[1 1],'k')
title('pos')
%set(gca,'xlim',[-10 15],'ylim',[0 5])
sgtitle('Kinematic Normalized')


