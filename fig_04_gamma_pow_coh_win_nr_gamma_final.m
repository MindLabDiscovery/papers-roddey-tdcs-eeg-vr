%% TO DO
% finish panels
% play with remae
% generate all raw data traces
% sign in to ref works

% add in nathan crone paps
% generate psd's for rest
% 
% figure
% plot(epochs_rest.rest2.t1.psd.freq,epochs_rest.rest2.t1.psd.saw(:,17,1))
% 
% sbj=['03';'05']
% for i=1:size(sbj,2)
% step_01_nr_eeg_anal_sum_01_data_vis_02_win(sbj(i,:))
% end

%% Fig 4A spectral power - all electrodes all frequencies all times plot

load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/subjectData.mat'])
TOI_mod1={'pre','i05','i15','pos'};
phases={'Hold','Prep','Reach'};

count=0; 
for s1=[4 5 6 7 9]
    count=count+1;
    %for f=1:5
        for p=1:3
            for t=1:4
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s1).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s2).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s3).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s4).SubjectName,'_sessioninfo.mat'])
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

figure; set(gcf,'Position',[36 -38 1391 796])
%cs sham
subplot(4,6,1); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Hold')

subplot(4,6,2); hold on 
for i=1:12
    plot(cs_sham_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Hold')

subplot(4,6,3); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Prep')

subplot(4,6,4); hold on 
for i=1:12
    plot(cs_sham_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Prep')

subplot(4,6,5); hold on 
for i=1:12
    plot(cs_sham_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs sham ipsi Reach')

subplot(4,6,6); hold on 
for i=1:12
    plot(cs_sham_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_sham_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs sham contra Reach')

%cs stim
subplot(4,6,7); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Hold')

subplot(4,6,8); hold on 
for i=1:12
    plot(cs_stim_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Hold')

subplot(4,6,9); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Prep')

subplot(4,6,10); hold on 
for i=1:12
    plot(cs_stim_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Prep')

subplot(4,6,11); hold on 
for i=1:12
    plot(cs_stim_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('cs stim ipsi Reach')

subplot(4,6,12); hold on 
for i=1:12
    plot(cs_stim_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(cs_stim_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('cs stim contra Reach')

%hc sham
subplot(4,6,13); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Hold')

subplot(4,6,14); hold on 
for i=1:12
    plot(hc_sham_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Hold')

subplot(4,6,15); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Prep')

subplot(4,6,16); hold on 
for i=1:12
    plot(hc_sham_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Prep')

subplot(4,6,17); hold on 
for i=1:12
    plot(hc_sham_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc sham ipsi Reach')

subplot(4,6,18); hold on 
for i=1:12
    plot(hc_sham_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_sham_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc sham contra Reach')

%hc stim
subplot(4,6,19); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.ipsi.Hold.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Hold')

subplot(4,6,20); hold on 
for i=1:12
    plot(hc_stim_all.contra.Hold.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.contra.Hold.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Hold')

subplot(4,6,21); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.ipsi.Prep.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Prep')

subplot(4,6,22); hold on 
for i=1:12
    plot(hc_stim_all.contra.Prep.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.contra.Prep.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Prep')

subplot(4,6,23); hold on 
for i=1:12
    plot(hc_stim_all.ipsi.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.ipsi.Reach.mean(:,i),'LineWidth',2,'Color','b')
    end
end
title('hc stim ipsi Reach')

subplot(4,6,24); hold on 
for i=1:12
    plot(hc_stim_all.contra.Reach.mean(:,i),'Color',[0.7 0.7 0.7])
    if i==7
        plot(hc_stim_all.contra.Reach.mean(:,i),'LineWidth',2,'Color','r')
    end
end
title('hc stim contra Reach')

% for i=1:24
%     subplot(4,6,i)
%     set(gca,'ylim',[5 20])
% end

%savefig('all_electrodes_allfreq_time.fig')


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

all_elec_pow_ipsi=[raw_diff_cs_sham_all_ipsi_Hold+raw_diff_cs_sham_all_ipsi_Prep+raw_diff_cs_sham_all_ipsi_Reach+...
    raw_diff_cs_stim_all_ipsi_Hold+raw_diff_cs_stim_all_ipsi_Prep+raw_diff_cs_stim_all_ipsi_Reach+...
    raw_diff_hc_sham_all_ipsi_Hold+raw_diff_hc_sham_all_ipsi_Prep+raw_diff_hc_sham_all_ipsi_Reach+...
    raw_diff_hc_stim_all_ipsi_Hold+raw_diff_hc_stim_all_ipsi_Prep+raw_diff_hc_stim_all_ipsi_Reach]
all_elec_pow_contra=[raw_diff_cs_sham_all_contra_Hold+raw_diff_cs_sham_all_contra_Prep+raw_diff_cs_sham_all_contra_Reach+...
    raw_diff_cs_stim_all_contra_Hold+raw_diff_cs_stim_all_contra_Prep+raw_diff_cs_stim_all_contra_Reach+...
    raw_diff_hc_sham_all_contra_Hold+raw_diff_hc_sham_all_contra_Prep+raw_diff_hc_sham_all_contra_Reach+...
    raw_diff_hc_stim_all_contra_Hold+raw_diff_hc_stim_all_contra_Prep+raw_diff_hc_stim_all_contra_Reach]


figure; bar(all_elec_pow_ipsi-all_elec_pow_contra)
all_elec_pow_ipsi_vs_contra=all_elec_pow_ipsi-all_elec_pow_contra;
[all_elec_pow_ipsi_vs_contra_sort,all_elec_pow_ipsi_vs_contra_sort_i]=sort(all_elec_pow_ipsi_vs_contra,'descend')
set(gca,'XTickLabel',{'Fp2';'F8';'F4';'Fz';'A2';'T4';'C4';'Cz';'T6';'P4';'Pz';'O2'})

figure; bar(all_elec_pow_ipsi_vs_contra_sort)
set(gca,'XTickLabel',{'C4';'P4';'T4';'A2';'F4';'T6';'O2';'F8';'Fz';'Cz';'Pz';'Fp2'})

%% Fig 4B polar histogram
% cs_stim=[1 2 3 20 21]
% cs_sham=[4 5 6 7 9]
% hc_stim=[10 12 13 14 17 18]
% hc_sham=[8 11 15 16 19];

load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/subjectData.mat'])


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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s1).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s2).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s3).SubjectName,'_sessioninfo.mat'])
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
                load(['/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/session_info/',subjectData(s4).SubjectName,'_sessioninfo.mat'])
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
h=polarhistogram('BinEdges',[0 1.2566 2.5133 3.7699 5.0265 6.2832],'BinCount',hc_stim_c3c4_all_freq_Reach_abs_min_min_norm_mean_round,'FaceColor',[0.5 0.5 0.5])%'red','EdgeColor','off');
set(gca,'ThetaTickLabel',[],'RTickLabel',[])
%set(gca,'ThetaTickLabel',[],'RTickLabel',[],'EdgeColor','off')

%% Fig 4C icoh line plots

FOI_label={'Delta','Theta','Alpha','Beta','Gamma'}
load('/Volumes/rowlandlab/MIND_manuscript/NCR/Zobaer - eeg and tdcs/data analysis/data_scripts/final_04_win/icoh_data_anal_2022_11_09.mat')
for i=5
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

%% Fig 4D heat map

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

%% Fig 4E gamma prep-reach bar plot

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






%% Fig 4F linear regressions
%this is gamma coh diff vs kinematics 

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
for f=2:5
    for k=1:2
        for l=1:2
            for kin_idx=[1 2 4 5 6 7 8 9 10]%1:13%:12%[1 6]
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

                figure; set(gcf,'Position',[805 572 560 420])
                subplot(2,2,1); hold on
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,1),''.'')'])
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,1),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_pv,''r'')'])
                if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']) < 0.05
                    title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']))],'Color','r')
                else
                    title(['pre ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']))])
                end

                subplot(2,2,2); hold on
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,2),''.'')'])
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,2),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_pv,''r'')'])
                if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']) < 0.05
                    title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']))],'Color','r')
                else
                    title(['i05 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']))])
                end

                subplot(2,2,3); hold on
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,3),''.'')'])
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,3),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_pv,''r'')'])
                if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']) < 0.05
                    title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)'])),'Color','r'])
                else
                    title(['i15 ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']))])
                end

                subplot(2,2,4); hold on
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_kin(:,4),''.'')'])
                eval(['plot(',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_eeg(:,4),',FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_pv,''r'')'])
                if eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']) < 0.05
                    title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']))],'Color','r')
                else
                    title(['pos ',num2str(eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)']))])
                end
                sgtitle([FOI_label{f},' Prep Reach ',dz{k},' ',stim_status{l},' ',subjectData(1).kinematics.label{kin_idx}])

                icoh_lin_reg_p_all(count,:)=[f,k,l,kin_idx,eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pre_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i05_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_i15_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_hold_prep_',dz{k},'_',stim_status{l},'_pos_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pre_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i05_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_i15_p(2)']),...
                    eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_Prep_Reach_',dz{k},'_',stim_status{l},'_pos_p(2)'])];


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
                    for kin_idx=[1 2 4 5 6 7 8 9 10]%1:13%:12%[1 6]
                        count=count+1;
                        p_sum(count,:)=[f,kin_idx,p,k,l,t,eval([FOI_label{f},'_',kin_lbl{kin_idx},'_c3c4_diff_',phase{p},'_',dz{k},'_',stim_status{l},'_',time{t},'_p(2);'])];
                    end
                end
            end
        end
    end
end

% [fdr_r]=mafdr(p_sum(1:50,7))tried fdr - very unstable, do not use



% I imported these into graphpad
% str_stim_vp_eeg=gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3)
% str_stim_vp_kin=gamma_velocityPeaks_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)
% figure; plot(str_stim_vp_eeg,str_stim_vp_kin,'.')
% dlmwrite('file_str_stim_vp_eeg.txt',str_stim_vp_eeg)
% dlmwrite('file_str_stim_vp_kin.txt',str_stim_vp_kin)



%% Fig 4G spider plot

figure; set(gcf,'Position',[1935 333 1050 611])
subplot(2,4,1); hold on
for i=1:size(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin,1)
    plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,:)/Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(i,1))
end
plot([1 2 3 4],[1 1 1 1],'k--')
title('stroke sham movedur')
subplot(2,4,2); hold on
plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg')
plot([1 2 3 4],[0 0 0 0],'k--')
title('icoh hold-prep')

subplot(2,4,3); hold on
for i=1:size(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin,1)
    plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,:)/Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(i,1))
end
plot([1 2 3 4],[1 1 1 1],'k--')
title('healthy sham movedur')
subplot(2,4,4); hold on
plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg')
plot([1 2 3 4],[0 0 0 0],'k--')
title('icoh hold-prep')

subplot(2,4,5); hold on
for i=1:size(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin,1)
    plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,:)/Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(i,1))
end
plot([1 2 3 4],[1 1 1 1],'k--')
title('stroke stim movedur')
subplot(2,4,6); hold on
plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg')
plot([1 2 3 4],[0 0 0 0],'k--')
title('icoh hold-prep')

subplot(2,4,7); hold on
for i=1:size(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin,1)
    plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,:)/Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(i,1))
end
plot([1 2 3 4],[1 1 1 1],'k--')
title('healthy stim movedur')
subplot(2,4,8); hold on
plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg')
plot([1 2 3 4],[0 0 0 0],'k--')
title('icoh hold-prep')



%% Fig 4H cluster plot

figure; hold on
plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1),'ko','MarkerSize',10)
plot(Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1),'ro','MarkerSize',10)
plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1),'go','MarkerSize',10)
plot(Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3),Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1),'mo','MarkerSize',10)
axis([-10 12 0 1.5])
plot([0 0],[0 1.5],'k--')
plot([-10 12],[1 1],'k--')
legend('cs sham','cs stim','hc sham','hc stim')
ylabel('movement duration')
xlabel('c3c4 gamma coherence')

X5=[Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)];

X6=[Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);Gamma_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);Gamma_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)];

X7=[X5,X6]
[km_gamma1,km_gamma2,km_gamma3,km_gamma4,km_gamma5,km_gamma6]=kmedoids(X7,4,'Distance','correlation','Start','sample');
x=silhouette(X7,km_gamma1)
sum(x)

figure 
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),km_gamma1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')
 
%trying all other frequencies

X5=[Delta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Delta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Delta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Delta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    Delta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Delta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    Delta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Delta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)];

X6=[Delta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);Delta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    Delta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);Delta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)];

X7=[X5,X6]
[km_delta1,km_delta2,km_delta3,km_delta4,km_delta5,km_delta6]=kmedoids(X7,4,'Distance','correlation','Start','sample');
x=silhouette(X7,km_delta1)
sum(x)

figure 
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),km_delta1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')

X5=[Theta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Theta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Theta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Theta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    Theta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Theta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    Theta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Theta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)];

X6=[Theta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);Theta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    Theta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);Theta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)];

% X7=[X5,X6]
[km_theta1,km_theta2,km_theta3,km_theta4,km_theta5,km_theta6]=kmedoids(X7,4,'Distance','correlation','Start','sample');
x=silhouette(X7,km_theta1)
sum(x)

figure 
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),km_theta1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')

X5=[Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)];

X6=[Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);Alpha_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);Alpha_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)];

X7=[X5,X6]
[km_Alpha1,km_Alpha2,km_Alpha3,km_Alpha4,km_Alpha5,km_Alpha6]=kmedoids(X7,4,'Distance','correlation','Start','sample');
x=silhouette(X7,km_Alpha1)
sum(x)

figure 
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),km_Alpha1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')

X5=[Beta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,3)./Beta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_kin(:,1);
    Beta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,3)./Beta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_kin(:,1);
    Beta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,3)./Beta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_kin(:,1);
    Beta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,3)./Beta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_kin(:,1)];

X6=[Beta_movementDuration_c3c4_diff_hold_prep_stroke_Sham_eeg(:,3);Beta_movementDuration_c3c4_diff_hold_prep_stroke_Stim_eeg(:,3);
    Beta_movementDuration_c3c4_diff_hold_prep_healthy_Sham_eeg(:,3);Beta_movementDuration_c3c4_diff_hold_prep_healthy_Stim_eeg(:,3)];

X7=[X5,X6]
[km_Beta1,km_Beta2,km_Beta3,km_Beta4,km_Beta5,km_Beta6]=kmedoids(X7,4,'Distance','correlation','Start','sample');
x=silhouette(X7,km_Beta1)
sum(x)

figure 
subplot(2,2,1); hold on
gscatter(X7(:,2),X7(:,1),km_Beta1)
plot([-5 15],[1 1],'k')
plot([0 0],[0 1.54],'k')
 
 

 


