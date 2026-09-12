function run_remae_gamma_test(protocolfolder, remaePath, outPrefix)
% RUN_REMAE_GAMMA_TEST
%
% Scripted muscle-artifact removal (ReMAE, CCA-BSS pipeline) applied
% identically to all five chronic stroke ACTIVE STIMULATION subjects, with the
% decisive comparison built in.
%
% THE QUESTION
%   Does the stimulation-related increase in low gamma (30-50 Hz) survive
%   removal of muscle artifact?
%
%   Low gamma is compared against a 70-100 Hz control band. Because scalp EEG
%   does not resolve neural activity above ~50 Hz, the 70-100 Hz band contains
%   essentially no neural signal and functions as a muscle/noise proxy.
%
%   INTERPRETATION
%     gamma increase SURVIVES ReMAE, high band collapses -> neural
%     gamma and high band BOTH collapse                  -> muscle artifact
%     neither changes                                    -> ReMAE ineffective;
%                                                           inspect components
%
% PIPELINE (fixed, single configuration - no method selection)
%   1. 21-channel data per subject x block x phase, epochs concatenated
%   2. myCCA          - canonical correlation BSS
%   3. CCA_threshold  - components with lag-1 autocorrelation in
%                       [AC_LO, AC_HI] are classified as muscle and zeroed
%   4. reconstruction is performed inside CCA_threshold
%   5. band power recomputed on cleaned data
%
%   CCA is the conventional choice for multichannel muscle removal
%   (Chen et al., IEEE TIM 2018). Only one pipeline is run, deliberately:
%   running eight variants and choosing one invites a forking-paths objection.
%
% USAGE
%   run_remae_gamma_test('D:\...\data_raw', 'D:\...\Data\ReMAE', 'remae_test')
%
% REQUIREMENTS
%   - ReMAE on the path (this script adds it via genpath, per the toolbox's
%     own Welcome_to_ReMAE.m).
%   - Signal Processing Toolbox (pwelch).
%   - ReMAE's myautocorrelation.m calls autocorr(), which lives in the
%     ECONOMETRICS TOOLBOX. If you do not have it, see autocorr_fallback.m
%     supplied alongside this script.
%
% OUTPUT
%   <outPrefix>_bandpower.csv  - per subject/block/phase/channel, before+after
%   <outPrefix>_components.csv - components rejected per cell (QC)
%   Console: the pre-vs-during comparison, before and after ReMAE

if nargin < 3 || isempty(outPrefix), outPrefix = 'remae_test'; end

% ---- ReMAE on path ------------------------------------------------------
assert(exist(remaePath,'dir')==7, 'ReMAE folder not found: %s', remaePath);
addpath(genpath(remaePath));
assert(exist('myCCA','file')==2,        'myCCA not found under %s', remaePath);
assert(exist('CCA_threshold','file')==2,'CCA_threshold not found under %s', remaePath);

if exist('autocorr','file') ~= 2
    warning(['autocorr() not found (Econometrics Toolbox). ReMAE''s ' ...
             'myautocorrelation.m requires it. Place autocorr_fallback.m ' ...
             'on the path renamed as autocorr.m, or this will error.']);
end
fprintf('ReMAE loaded from: %s\n\n', remaePath);

% ---- Configuration ------------------------------------------------------
GAMMA = [30 50];        % low gamma - the band of interest
HIGH  = [70 100];       % control band - muscle/noise proxy
BETA  = [13 30];        % reported for context
ALPHA = [8 12];

CCA_TLAG = 1;           % time lag for myCCA

% Component rejection: autocorrelation criterion ONLY, matching the
% "Autocorr 0-0.9" configuration used in the exploratory analysis.
% The remaining criteria are disabled by setting non-firing ranges
% (see myentropy/mykurtosis/myvariance - each zeroes a component only when
% its statistic falls strictly BETWEEN threshold1 and threshold2).
AC_LO = 0;    AC_HI = 0.9;      % ACTIVE: muscle has low lag-1 autocorrelation
EN_LO = 1e6;  EN_HI = 1e6+1;    % disabled
KU_LO = 1e6;  KU_HI = 1e6+1;    % disabled
VA_LO = 1e6;  VA_HI = 1e6+1;    % disabled

subjects = {
 'pro00087153_0003','C3'
 'pro00087153_0004','C3'
 'pro00087153_0005','C4'
 'pro00087153_0042','C4'
 'pro00087153_0043','C3'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
STIM_BLOCK  = [false true true false];
phaseNames  = {'Hold','Prep','Move'};

rows = {}; comprows = {};

fprintf('Running ReMAE on %d subjects x 4 blocks x 3 phases...\n\n', size(subjects,1));

for s = 1:size(subjects,1)

    subject   = subjects{s,1};
    anodeChan = subjects{s,2};
    contraChan = ternary(strcmpi(anodeChan,'C3'),'C4','C3');
    sid = subject(end-3:end);

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING -- skipped\n', subject); continue
    end
    fprintf('  %s (anode %s)\n', subject, anodeChan);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('     LOAD FAILED: %s\n', ME.message); continue
    end

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials, blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end

            srate = peeg.srate;
            lbls  = {peeg.chanlocs.labels};
            nch   = min(21, numel(lbls));

            % epochs -> continuous, 21 channels
            D  = double(peeg.data(1:nch,:,:));
            Xc = reshape(D, nch, []);          % nch x (T*epochs)

            iA = find(strcmpi(lbls,anodeChan),1);
            iC = find(strcmpi(lbls,contraChan),1);
            if isempty(iA) || isempty(iC), continue; end

            % interpolation status (reported, not used to exclude)
            bc = [];
            if isfield(peeg,'badChannels') && isfield(peeg.badChannels,'channels')
                tmp = peeg.badChannels.channels;
                if ~any(isnan(tmp(:))), bc = tmp(:)'; end
            end

            % ---- ReMAE: CCA decomposition + autocorrelation thresholding
            nRej = NaN;
            try
                [Comp_save, B, WC] = myCCA(Xc, srate, CCA_TLAG);

                % count components that will be rejected (QC)
                nRej = 0;
                for cv = 1:size(Comp_save,1)
                    if myautocorrelation(Comp_save(cv,:), AC_LO, AC_HI) < 1
                        nRej = nRej + 1;
                    end
                end

                Yc = CCA_threshold(Comp_save, B, WC, ...
                                   AC_LO, AC_HI, EN_LO, EN_HI, ...
                                   KU_LO, KU_HI, VA_LO, VA_HI);
                Yc = real(Yc);
            catch ME
                fprintf('     %s/%s ReMAE failed: %s\n', ...
                        blockLabels{b}, phaseNames{p}, ME.message);
                continue
            end

            comprows(end+1,:) = {sid, blockLabels{b}, phaseNames{p}, ...
                                 size(Comp_save,1), nRej, ...
                                 100*nRej/size(Comp_save,1)}; %#ok<AGROW>

            % ---- band power before and after, both central channels
            for whichCh = 1:2
                if whichCh==1, idx = iA; nm = anodeChan; role = 'anodal';
                else,          idx = iC; nm = contraChan; role = 'contralateral';
                end

                pre_g  = bandpow(Xc(idx,:), srate, GAMMA);
                pre_h  = bandpow(Xc(idx,:), srate, HIGH);
                pre_b  = bandpow(Xc(idx,:), srate, BETA);
                pre_a  = bandpow(Xc(idx,:), srate, ALPHA);

                post_g = bandpow(Yc(idx,:), srate, GAMMA);
                post_h = bandpow(Yc(idx,:), srate, HIGH);
                post_b = bandpow(Yc(idx,:), srate, BETA);
                post_a = bandpow(Yc(idx,:), srate, ALPHA);

                rows(end+1,:) = { sid, blockLabels{b}, phaseNames{p}, ...
                    ternary(STIM_BLOCK(b),'yes','no'), nm, role, ...
                    ternary(ismember(idx,bc),'YES','no'), ...
                    pre_a, post_a, pre_b, post_b, ...
                    pre_g, post_g, pre_h, post_h, ...
                    post_g - pre_g, post_h - pre_h }; %#ok<AGROW>
            end
        end
    end
    clear ev
end

% ---- write tables -------------------------------------------------------
hdr = {'subject','block','phase','during_stim','channel','role','interpolated', ...
       'alpha_pre','alpha_post','beta_pre','beta_post', ...
       'gamma_pre','gamma_post','high_pre','high_post', ...
       'gamma_removed_dB','high_removed_dB'};
T = cell2table(rows,'VariableNames',hdr);
f1 = [outPrefix '_bandpower.csv']; writetable(T,f1);

C = cell2table(comprows,'VariableNames', ...
    {'subject','block','phase','n_components','n_rejected','pct_rejected'});
f2 = [outPrefix '_components.csv']; writetable(C,f2);

fprintf('\nWritten: %s (%d rows)\n', f1, height(T));
fprintf('Written: %s (%d rows)\n\n', f2, height(C));

% =========================================================================
% THE DECISIVE COMPARISON
% =========================================================================
fprintf('==================================================================\n');
fprintf(' COMPONENT REJECTION (QC)\n');
fprintf('==================================================================\n');
fprintf('  mean components rejected: %.1f of %.0f (%.1f%%)\n', ...
    mean(C.n_rejected,'omitnan'), mean(C.n_components,'omitnan'), ...
    mean(C.pct_rejected,'omitnan'));
isS = strcmp(T.during_stim,'yes');
fprintf('  NOTE: if ~0%% or ~100%% rejected, the autocorrelation threshold\n');
fprintf('        is mis-set and the result below is uninformative.\n\n');

fprintf('==================================================================\n');
fprintf(' STIMULATION EFFECT, BEFORE vs AFTER ReMAE (anodal channel)\n');
fprintf(' Values are during-stim minus pre-stim, in dB.\n');
fprintf('==================================================================\n');
Ta = T(strcmp(T.role,'anodal'),:);
fprintf('%-8s %14s %14s %14s %14s\n','subject', ...
        'gamma BEFORE','gamma AFTER','high BEFORE','high AFTER');
subs = unique(Ta.subject,'stable');
for i = 1:numel(subs)
    ti = Ta(strcmp(Ta.subject,subs{i}),:);
    sS = strcmp(ti.during_stim,'yes');
    dg_pre  = mean(ti.gamma_pre(sS))  - mean(ti.gamma_pre(~sS));
    dg_post = mean(ti.gamma_post(sS)) - mean(ti.gamma_post(~sS));
    dh_pre  = mean(ti.high_pre(sS))   - mean(ti.high_pre(~sS));
    dh_post = mean(ti.high_post(sS))  - mean(ti.high_post(~sS));
    fprintf('%-8s %+14.2f %+14.2f %+14.2f %+14.2f\n', ...
            subs{i}, dg_pre, dg_post, dh_pre, dh_post);
end

sS = strcmp(Ta.during_stim,'yes');
G_before = mean(Ta.gamma_pre(sS))  - mean(Ta.gamma_pre(~sS));
G_after  = mean(Ta.gamma_post(sS)) - mean(Ta.gamma_post(~sS));
H_before = mean(Ta.high_pre(sS))   - mean(Ta.high_pre(~sS));
H_after  = mean(Ta.high_post(sS))  - mean(Ta.high_post(~sS));

fprintf('%-8s %+14.2f %+14.2f %+14.2f %+14.2f\n', 'GROUP', ...
        G_before, G_after, H_before, H_after);

fprintf('\n------------------------------------------------------------------\n');
fprintf(' READING THE RESULT\n');
fprintf('------------------------------------------------------------------\n');
fprintf(' gamma stimulation effect retained : %.0f%% (%.2f -> %.2f dB)\n', ...
        100*G_after/G_before, G_before, G_after);
fprintf(' high  stimulation effect retained : %.0f%% (%.2f -> %.2f dB)\n', ...
        100*H_after/H_before, H_before, H_after);
if abs(G_after) > 0.5*abs(G_before) && abs(H_after) < 0.5*abs(H_before)
    fprintf(' >> Gamma survives while the control band collapses.\n');
    fprintf('    Consistent with a NEURAL low-gamma effect.\n');
elseif abs(G_after) < 0.5*abs(G_before) && abs(H_after) < 0.5*abs(H_before)
    fprintf(' >> Gamma and control band collapse together.\n');
    fprintf('    Consistent with MUSCLE ARTIFACT, as the co-author suspected.\n');
else
    fprintf(' >> Mixed/ambiguous. Inspect the per-subject rows and the\n');
    fprintf('    component rejection rates before drawing a conclusion.\n');
end

fprintf('\n LATERALISATION CHECK (gamma effect, after ReMAE):\n');
Tc = T(strcmp(T.role,'contralateral'),:);
sC = strcmp(Tc.during_stim,'yes');
Gc_after = mean(Tc.gamma_post(sC)) - mean(Tc.gamma_post(~sC));
fprintf('   anodal %+.2f dB vs contralateral %+.2f dB (difference %+.2f)\n', ...
        G_after, Gc_after, G_after - Gc_after);
fprintf('   Near-zero difference => bilateral => not stimulation-specific.\n');
fprintf('==================================================================\n');

end % main

% =========================================================================
function p = bandpow(x, fs, band)
x = double(x(:))' - mean(x);
[pxx,f] = pwelch(x, hamming(min(fs,numel(x))), [], [], fs);
p = 10*log10(mean(pxx(f>=band(1) & f<=band(2))) + eps);
end

function out = ternary(c,a,b)
if c, out = a; else, out = b; end
end
