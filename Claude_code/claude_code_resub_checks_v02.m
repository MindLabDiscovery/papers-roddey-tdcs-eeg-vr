check_coherence_estimation('C:\Users\ncr200\Downloads\','pro00087153_0003')

pf='C:\Users\ncr200\Downloads';
 
s1=load(fullfile(pf,'pro00087153_0003','analysis','S1-VR_preproc',...
    'pro00087153_0003_S1-VRdata_preprocessed.mat'));
s1.trialData.eeg.header.Fs

files = dir('C:\**\EEGLAB_preprocessing*.m');
for k = 1:numel(files)
    f = fullfile(files(k).folder, files(k).name);
    txt = fileread(f);
    fprintf('%s\n   resample active: %d | samplingrate: %d | Fs: %d | %s\n', ...
        f, ...
        ~isempty(regexp(txt,'^\s*EEG\s*=\s*pop_resample','lineanchors','once')), ...
        contains(txt,'header.samplingrate'), ...
        contains(txt,'header.Fs'), ...
        files(k).date);
end

export_epoch_retention('C:\Users\ncr200\Downloads\data_raw', 'epoch_retention.csv')

recompute_coherence_comparison('C:\Users\ncr200\Downloads\data_raw','coh_comparison')

plot_anodal_spectrograms_v02('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\spectrograms')

plot_anodal_vs_contra_spectrograms('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\spectrograms')

run_remae_gamma_test('C:\Users\ncr200\Downloads\data_raw', 'C:\Users\ncr200\Downloads\ReMAE', 'remae_test')

% % one cell, e.g. subject 0003, LS, Prep
% [Comp,B,WC] = myCCA(Xc, srate, 1);
% ac = arrayfun(@(k) abs(subsref(autocorr(Comp(k,:)), ...
%       struct('type','()','subs',{{1,2}}))), 1:size(Comp,1));
% sort(ac)

calibrate_remae_threshold('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\ReMAE','C:\Users\ncr200\Downloads', 'pro00087153_0043', 't3', 2)

run_gamma_topography_test('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\data_raw\topo')

run_aperiodic_analysis('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\data_raw\aperiodic')

run_aperiodic_analysis_v02('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\data_raw\aperiodic')

run_aperiodic_analysis_v03('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\data_raw\aperiodic')

run_es_ls_contrast('C:\Users\ncr200\Downloads\data_raw','C:\Users\ncr200\Downloads\data_raw\esls','C:\...\kinematics.csv')

diary('C:\Users\ncr200\Downloads\kin_structure.txt')
inspect_kinematics('C:\Users\ncr200\Downloads\data_raw\subjectData.mat')
diary off

extract_kinematics

extract_kinematics_v02

extract_kinematics_v03

run_es_ls_contrast_v01

run_es_ls_psd_contrast

run_es_ls_psd_contrast_v02

plot_cs_stim_anode_cathode

run_prestim_phase_validation

run_spectral_kinematic_regression

run_erd_timeresolved

recompute_coherence_comparison('C:\Users\ncr200\Downloads\data_raw','coh_comparison')

run_ensemble_icoh_regression %exclude_interpolated=false (61 hits)

run_ensemble_icoh_regression %exclude_interpolated=true (42 hits)

plot_fig4c_ensemble

plot_fig4c_ensemble_v02

plot_fig4c_ensemble_v03

plot_fig4c_ensemble_v04

plot_fig4c_ensemble_v05

plot_fig4c_ensemble_v05

plot_fig4c_ensemble_v06

plot_fig4c_ensemble_v07

plot_cs_stim_anode_cathode_v02

plot_drift_figure

regen_fig4a

test_hemisphere_hypothesis

recompute_coherence_multiband('C:\Users\ncr200\Downloads\data_raw','coh')

plot_fig4c_ensemble_v08

fig4b_bands_cs_stim_vs_sham_v02

regen_fig4a_v02

analyze_badchannels_by_hemisphere('C:\Users\ncr200\Downloads\data_raw')

analyze_badchannels_by_hemisphere_v02('C:\Users\ncr200\Downloads\data_raw')

make_supplementary_figures_v01

make_supplementary_tables

make_supplementary_figures_v03

run_kinematic_anova_table %run twice change target to CS or HC

make_supplementary_figures_v04

recompute_coherence_multiband_v02('C:\Users\ncr200\Downloads\data_raw','coh')

plot_coherogram

compute_coherogram
compute_coherogram_tf('C:\Users\ncr200\Downloads\data_raw','coh')

export_phase_timing('C:\Users\ncr200\Downloads\data_raw','phase_timing.csv')

S=load('C:\Users\ncr200\Downloads\data_raw\pro00087153_0003\analysis\EEGlab\EEGlab_Total.mat','eegevents_ft');
size(S.eegevents_ft.trials.t1(1,:).data)

plot_aperiodic_figure

plot_drift_figure_v02

plot_drift_contrast

S = load('C:\Users\ncr200\Downloads\data_raw\pro00087153_0003\analysis\S1-VR_preproc\pro00087153_0003_S1-VRdata_preprocessed.mat','trialData');
size(S.trialData.eeg.sync)        % long vector = recorded channel
S.trialData.vr(1).sync            % scalar/short = computed offset
whos -file '...' -regexp sync

export_cleaning_psd('C:\Users\ncr200\Downloads\data_raw','cleaning')

inspect_preprocessingdata
% the one that definitely has the stages
inspect_processingdata('C:\Users\ncr200\Downloads\PreprocessingCheck\pipeline.mat')

% the main analysis file for the same subject
inspect_processingdata_v02('C:\Users\ncr200\Downloads\data_raw\pro00087153_0004\analysis\EEGlab\EEGlab_Total.mat')

S = load('C:\Users\ncr200\Downloads\data_raw\pro00087153_0004\analysis\EEGlab\EEGlab_Total.mat','eegevents_icarem');
E = S.eegevents_icarem.trials.t1;
disp(class(E)); disp(size(E));
disp(fieldnames(E));

f = dir('C:\Users\ncr200\Downloads\data_raw\pro00087153_0004\analysis\EEGlab\EEGlab_Total.mat')
for i = 1:numel(f)
    fprintf('%-24s %s\n', f(i).folder(end-30:end), f(i).date);
end

make_supplementary_figures_v05

plot_drift_figure_v05