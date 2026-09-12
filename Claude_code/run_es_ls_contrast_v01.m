%% run_es_ls_contrast_v01.m
%
% Purpose:
%   Contrasts EARLY (ES) vs LATE (LS) stimulation rather than stimulation
%   vs rest. Both periods have current flowing, so the gross tDCS artifact
%   largely subtracts out, and the contrast is temporally matched to the
%   behavioural effect (max acceleration improved ES->LS, p = 0.0095).
%
%   Uses SHAM as a difference-in-differences control: an ES->LS change that
%   appears in active but not sham is not explained by session drift or
%   task familiarization, both of which the handoff flags as live concerns
%   (aperiodic exponent changes were largest in HC and moved the same
%   direction in both sham groups -- i.e. drift, not stimulation).
%
%   Includes a leave-one-out influence check on any kinematic correlation,
%   directly answering Reviewer 1's minor point 7 (n=5 with high r^2).
%
% Scope of THIS file:
%   Kinematics only. The EEG band-power half (RAW vs FLATTENED gamma/beta/
%   alpha change, ES vs LS) is deliberately NOT implemented here -- see the
%   "EEG INPUT CONTRACT" section at the bottom. Wire that up once the
%   band-power source is confirmed; the DiD and leave-one-out machinery in
%   this file is written to be reused on it directly.
%
% Input:
%   kinematics_long.csv, produced by extract_kinematics.m.
%   Columns: SubjectID, Group, GroupSource, Block, BlockIdx, Reach,
%            Metric, MetricIdx, Value
%
% NaN handling (IMPORTANT):
%   Subject 0015 has one dropped reach (BL, reach 6) -- all 13 metrics NaN
%   for that cell. Every aggregation here uses 'omitnan' explicitly. A
%   plain mean() would propagate NaN and silently drop 0015 from the
%   contrast, which would be an especially bad failure mode given that the
%   leave-one-out check is about influence of individual subjects.
%   Per-cell reach counts are reported so any thinning is visible.
%
% Roster / condition assignment:
%   Explicit hardcoded roster (HANDOFF sec 7 policy). Condition (active vs
%   sham) is read preferentially from sessioninfo.stimamp when subjectData
%   is available (>0 mA = active, 0 mA = sham); otherwise falls back to the
%   CRF-derived split below WITH a warning. Group (CS/HC) is read from the
%   CSV, which extract_kinematics.m already sourced from sessioninfo.dx.
%
% Tested against: MATLAB R2019b. No toolboxes required.
%   (ttest/corr are Statistics Toolbox; fallbacks are provided so the
%    script runs without it -- see local functions.)

clear; clc;

%% ---- CONFIG ----
CSV_PATH  = fullfile(pwd, 'kinematics_long.csv');
MAT_PATH  = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';  % optional
OUT_DIR   = pwd;

% Primary metric for the headline contrast (the handoff's p = 0.0095 effect).
PRIMARY_METRIC = 'maxAcceleration';

% Blocks defining the contrast.
BLOCK_EARLY = 'ES';
BLOCK_LATE  = 'LS';
BLOCK_BASE  = 'BL';   % used only for the optional baseline-normalized view

% CRF-derived condition split (FALLBACK ONLY -- stimamp is preferred).
% Derived from the Amp / True Current fields on the case report forms:
% 0 mA = sham, 2 mA = active. Yields 5/5/5/5.
crf_active = {'0003','0004','0005','0042','0043', ...   % CS active
              '0022','0024','0025','0026','0029'};      % HC active
crf_sham   = {'0013','0015','0017','0018','0021', ...   % CS sham
              '0020','0023','0027','0028','0036'};      % HC sham

%% ---- LOAD KINEMATICS ----
if ~isfile(CSV_PATH)
    error('run_es_ls_contrast:noCSV', ...
        ['%s not found. Run extract_kinematics.m first.'], CSV_PATH);
end
T = readtable(CSV_PATH, 'Delimiter', ',');

% Force SubjectID to a cellstr of zero-padded chars (readtable may read
% '0003' as numeric 3 and destroy the padding).
if ~iscell(T.SubjectID)
    T.SubjectID = arrayfun(@(x) sprintf('%04d', x), T.SubjectID, ...
        'UniformOutput', false);
end
T.Group  = cellstr(string(T.Group));
T.Block  = cellstr(string(T.Block));
T.Metric = cellstr(string(T.Metric));

subjects = unique(T.SubjectID);
fprintf('Loaded %d rows, %d subjects.\n', height(T), numel(subjects));

%% ---- CONDITION (active/sham) ----
cond = containers.Map('KeyType','char','ValueType','char');
cond_source = containers.Map('KeyType','char','ValueType','char');

stimamp_available = false;
if isfile(MAT_PATH)
    S = load(MAT_PATH);
    if isfield(S, 'subjectData')
        sd = S.subjectData;
        sd_names = {sd.SubjectName};
        stimamp_available = true;
    end
end

for i = 1:numel(subjects)
    s = subjects{i};
    assigned = false;

    if stimamp_available
        mi = find(contains(sd_names, s), 1);   % match by NAME, never index
        if ~isempty(mi)
            sinfo = sd(mi).sessioninfo;
            if isstruct(sinfo) && isfield(sinfo,'stimamp') && ~isempty(sinfo.stimamp)
                amp = sinfo.stimamp;
                if ischar(amp) || isstring(amp)
                    amp = str2double(regexprep(char(amp), '[^0-9.]', ''));
                end
                if ~isnan(amp)
                    if amp > 0
                        cond(s) = 'active';
                    else
                        cond(s) = 'sham';
                    end
                    cond_source(s) = 'sessioninfo.stimamp';
                    assigned = true;
                end
            end
        end
    end

    if ~assigned
        if any(strcmp(s, crf_active))
            cond(s) = 'active';
        elseif any(strcmp(s, crf_sham))
            cond(s) = 'sham';
        else
            error('run_es_ls_contrast:noCondition', ...
                'Subject %s has no stimamp and is not in the CRF split.', s);
        end
        cond_source(s) = 'CRF-derived-VERIFY';
        warning('run_es_ls_contrast:condFallback', ...
            ['Subject %s: sessioninfo.stimamp unavailable -- using CRF-derived ' ...
             'condition "%s". VERIFY before trusting downstream.'], s, cond(s));
    end
end

% Group (CS/HC) straight from the CSV.
grp = containers.Map('KeyType','char','ValueType','char');
for i = 1:numel(subjects)
    s = subjects{i};
    g = T.Group(strcmp(T.SubjectID, s));
    grp(s) = g{1};
end

% Report the 2x2.
fprintf('\n=== Design cells ===\n');
cells = {'CS','active'; 'CS','sham'; 'HC','active'; 'HC','sham'};
for c = 1:size(cells,1)
    members = subjects(cellfun(@(s) strcmp(grp(s),cells{c,1}) && ...
                                    strcmp(cond(s),cells{c,2}), subjects));
    fprintf('  %s %-6s n=%d : %s\n', cells{c,1}, cells{c,2}, ...
        numel(members), strjoin(members', ', '));
end
src_fallback = subjects(cellfun(@(s) ~strcmp(cond_source(s),'sessioninfo.stimamp'), subjects));
if ~isempty(src_fallback)
    fprintf('  [!] condition from CRF fallback for: %s\n', strjoin(src_fallback', ', '));
end

%% ---- PER-SUBJECT BLOCK MEANS (all metrics) ----
% subjMean(subject, metric, block) = mean across reaches, omitnan.
metrics = unique(T.Metric, 'stable');
blocks  = {BLOCK_BASE, BLOCK_EARLY, BLOCK_LATE, 'Post'};

nS = numel(subjects); nM = numel(metrics); nB = numel(blocks);
subjMean = nan(nS, nM, nB);
subjN    = zeros(nS, nM, nB);   % reaches actually contributing

for i = 1:nS
    for m = 1:nM
        for b = 1:nB
            sel = strcmp(T.SubjectID, subjects{i}) & ...
                  strcmp(T.Metric,    metrics{m})  & ...
                  strcmp(T.Block,     blocks{b});
            v = T.Value(sel);
            subjMean(i,m,b) = mean(v, 'omitnan');
            subjN(i,m,b)    = sum(~isnan(v));
        end
    end
end

% Surface any cell that lost reaches -- keeps 0015's dropped reach visible.
thin = find(subjN(:) < 12);
if ~isempty(thin)
    fprintf('\n=== Cells with <12 contributing reaches ===\n');
    [ii,mm,bb] = ind2sub(size(subjN), thin);
    for k = 1:numel(thin)
        fprintf('  %s / %-20s / %-4s : n=%d\n', subjects{ii(k)}, ...
            metrics{mm(k)}, blocks{bb(k)}, subjN(thin(k)));
    end
end

%% ---- ES -> LS CONTRAST, PRIMARY METRIC ----
mi_primary = find(strcmp(metrics, PRIMARY_METRIC), 1);
if isempty(mi_primary)
    error('run_es_ls_contrast:noMetric', ...
        'PRIMARY_METRIC "%s" not found. Available: %s', ...
        PRIMARY_METRIC, strjoin(metrics', ', '));
end
bi_es = find(strcmp(blocks, BLOCK_EARLY), 1);
bi_ls = find(strcmp(blocks, BLOCK_LATE), 1);

delta = subjMean(:, mi_primary, bi_ls) - subjMean(:, mi_primary, bi_es);  % LS - ES

fprintf('\n=== ES -> LS change, %s ===\n', PRIMARY_METRIC);
results = struct('cell', {}, 'n', {}, 'mean', {}, 'sd', {}, 'p', {}, 'd', {});
for c = 1:size(cells,1)
    mask = cellfun(@(s) strcmp(grp(s),cells{c,1}) && strcmp(cond(s),cells{c,2}), subjects);
    d = delta(mask);
    d = d(~isnan(d));
    [p, tstat] = ttest1_safe(d);
    dz = mean(d,'omitnan') / std(d,'omitnan');
    fprintf('  %s %-6s n=%d : mean %+8.4f (SD %7.4f)  t=%+6.3f p=%.4f  dz=%+.3f\n', ...
        cells{c,1}, cells{c,2}, numel(d), mean(d,'omitnan'), std(d,'omitnan'), ...
        tstat, p, dz);
    results(end+1) = struct('cell', sprintf('%s_%s',cells{c,1},cells{c,2}), ...
        'n', numel(d), 'mean', mean(d,'omitnan'), 'sd', std(d,'omitnan'), ...
        'p', p, 'd', dz); %#ok<SAGROW>
end

%% ---- DIFFERENCE-IN-DIFFERENCES (active vs sham, within group) ----
fprintf('\n=== Difference-in-differences (active - sham) ===\n');
for g = {'CS','HC'}
    gname = g{1};
    ma = cellfun(@(s) strcmp(grp(s),gname) && strcmp(cond(s),'active'), subjects);
    ms = cellfun(@(s) strcmp(grp(s),gname) && strcmp(cond(s),'sham'),   subjects);
    da = delta(ma); da = da(~isnan(da));
    ds = delta(ms); ds = ds(~isnan(ds));
    [p, tstat] = ttest2_safe(da, ds);
    fprintf('  %s: active %+.4f (n=%d) vs sham %+.4f (n=%d)  DiD %+.4f  t=%+.3f p=%.4f\n', ...
        gname, mean(da,'omitnan'), numel(da), mean(ds,'omitnan'), numel(ds), ...
        mean(da,'omitnan') - mean(ds,'omitnan'), tstat, p);
end

%% ---- ALL-METRIC SWEEP (exploratory, uncorrected) ----
fprintf('\n=== ES -> LS by metric, CS active (uncorrected) ===\n');
mask_csa = cellfun(@(s) strcmp(grp(s),'CS') && strcmp(cond(s),'active'), subjects);
sweep = cell(nM, 4);
for m = 1:nM
    d = subjMean(mask_csa, m, bi_ls) - subjMean(mask_csa, m, bi_es);
    d = d(~isnan(d));
    [p, tstat] = ttest1_safe(d);
    fprintf('  %-22s n=%d  mean %+10.4f  t=%+6.3f  p=%.4f\n', ...
        metrics{m}, numel(d), mean(d,'omitnan'), tstat, p);
    sweep(m,:) = {metrics{m}, numel(d), mean(d,'omitnan'), p};
end
fprintf(['  NOTE: %d metrics, uncorrected. Treat as exploratory; the ' ...
         'pre-specified contrast is %s.\n'], nM, PRIMARY_METRIC);

%% ---- LEAVE-ONE-OUT INFLUENCE CHECK (Reviewer 1, minor point 7) ----
% Reusable: pass any per-subject predictor (e.g. an EEG band change) as x
% and a kinematic delta as y, restricted to whatever cell you're testing.
% Demonstrated here on CS active, ES->LS delta vs baseline level -- replace
% x with the EEG measure once the band-power source is wired up.

fprintf('\n=== Leave-one-out influence check (CS active) ===\n');
idx_csa = find(mask_csa);
x = subjMean(idx_csa, mi_primary, find(strcmp(blocks,BLOCK_BASE),1)); % placeholder predictor
y = delta(idx_csa);
subj_csa = subjects(idx_csa);

loo = leave_one_out_corr(x, y, subj_csa);
fprintf('  Full sample:  n=%d  r=%+.4f  r2=%.4f  p=%.4f\n', ...
    loo.n_full, loo.r_full, loo.r_full^2, loo.p_full);
for k = 1:numel(loo.dropped)
    fprintf('  drop %-6s  n=%d  r=%+.4f  r2=%.4f  p=%.4f   (dr=%+.4f)\n', ...
        loo.dropped{k}, loo.n(k), loo.r(k), loo.r(k)^2, loo.p(k), ...
        loo.r(k)-loo.r_full);
end
fprintf('  r range across LOO: [%+.4f, %+.4f]   sign stable: %s\n', ...
    min(loo.r), max(loo.r), mat2str(all(sign(loo.r)==sign(loo.r_full))));
fprintf(['  INTERPRETATION: with n=%d, a correlation whose r swings widely ' ...
         'or flips sign\n  under LOO should not be reported as a finding. ' ...
         'This is the check\n  Reviewer 1 minor point 7 asks for.\n'], loo.n_full);

%% ---- SAVE ----
outT = table(subjects, ...
    cellfun(@(s) grp(s),  subjects, 'UniformOutput', false), ...
    cellfun(@(s) cond(s), subjects, 'UniformOutput', false), ...
    cellfun(@(s) cond_source(s), subjects, 'UniformOutput', false), ...
    subjMean(:, mi_primary, bi_es), ...
    subjMean(:, mi_primary, bi_ls), ...
    delta, ...
    'VariableNames', {'SubjectID','Group','Condition','ConditionSource', ...
                      [PRIMARY_METRIC '_ES'], [PRIMARY_METRIC '_LS'], ...
                      [PRIMARY_METRIC '_LS_minus_ES']});
out_path = fullfile(OUT_DIR, 'es_ls_contrast_subject_level.csv');
writetable(outT, out_path);
fprintf('\nWrote %s\n', out_path);

%% =====================================================================
%  EEG INPUT CONTRACT -- NOT YET IMPLEMENTED
%  =====================================================================
%  To finish the EEG half, this script needs per-subject, per-block band
%  power in BOTH raw and flattened (aperiodic-removed) form:
%
%      bandPower(subject, band, block, form)
%        band  : gamma (30-50), control (70-100), beta, alpha
%        block : ES, LS   (BL/Post optional)
%        form  : 'raw' | 'flattened'
%        channel: anodal channel, selected by CRF-VERIFIED laterality
%                 (L -> C3, R -> C4) -- NOT sessioninfo.stimlat, which is
%                 transposed for 0042 and 0043.
%
%  Open questions before wiring this up:
%    1. Where does run_aperiodic_analysis_v03.m write its flattened output,
%       and in what structure? (It produced the "CS Stim raw +0.23 dB ->
%       flattened 0.00 dB" numbers, so the values exist somewhere.)
%    2. Are ES and LS already separable in that output, or does it only
%       hold a single pooled during-stim estimate? The whole point of this
%       contrast is ES vs LS, so if the aperiodic fits were computed on
%       pooled stim data they will need recomputing per sub-block.
%    3. Which S3-EEGanalysis file holds the per-channel PSDs, and is the
%       frequency axis stored alongside them?
%
%  Once those are answered, the reporting pattern mirrors the kinematics
%  above: ES->LS change per cell, active-vs-sham DiD, and -- critically --
%  raw AND flattened side by side, since the handoff's core finding is that
%  the gamma effect vanishes on flattening (+0.23 -> 0.00 dB). Reporting
%  only one form would misrepresent it.
%
%  The leave_one_out_corr() helper below takes any (x, y, labels) triple,
%  so an EEG-vs-kinematics correlation drops straight into it.
%% =====================================================================

%% ---- LOCAL FUNCTIONS ----

function [p, tstat] = ttest1_safe(d)
% One-sample t-test against 0. Uses Statistics Toolbox ttest if present,
% otherwise computes t and a normal approximation for p.
d = d(~isnan(d));
n = numel(d);
if n < 2
    p = NaN; tstat = NaN; return;
end
tstat = mean(d) / (std(d)/sqrt(n));
if exist('ttest','file') == 2
    [~, p] = ttest(d);
else
    p = 2 * (1 - normcdf_safe(abs(tstat)));
    warning('run_es_ls_contrast:noTtest', ...
        'Statistics Toolbox ttest unavailable -- p is a normal approximation, not exact.');
end
end

function [p, tstat] = ttest2_safe(a, b)
% Two-sample t-test (unequal variance). Falls back to normal approximation.
a = a(~isnan(a)); b = b(~isnan(b));
na = numel(a); nb = numel(b);
if na < 2 || nb < 2
    p = NaN; tstat = NaN; return;
end
se = sqrt(var(a)/na + var(b)/nb);
tstat = (mean(a) - mean(b)) / se;
if exist('ttest2','file') == 2
    [~, p] = ttest2(a, b, 'Vartype', 'unequal');
else
    p = 2 * (1 - normcdf_safe(abs(tstat)));
    warning('run_es_ls_contrast:noTtest2', ...
        'Statistics Toolbox ttest2 unavailable -- p is a normal approximation, not exact.');
end
end

function out = leave_one_out_corr(x, y, labels)
% LEAVE_ONE_OUT_CORR  Pearson r on the full sample and with each
% observation dropped in turn. Answers "is this correlation carried by one
% subject?" -- the question Reviewer 1's minor point 7 raises about n=5
% and high r^2.
%
% x, y    : column vectors, same length. NaN pairs are dropped.
% labels  : cellstr of subject IDs, same length as x/y.
ok = ~isnan(x) & ~isnan(y);
x = x(ok); y = y(ok); labels = labels(ok);
n = numel(x);

[out.r_full, out.p_full] = corr_safe(x, y);
out.n_full = n;
out.r = nan(n,1); out.p = nan(n,1); out.n = nan(n,1);
out.dropped = labels;

for k = 1:n
    keep = true(n,1); keep(k) = false;
    [out.r(k), out.p(k)] = corr_safe(x(keep), y(keep));
    out.n(k) = n - 1;
end
end

function [r, p] = corr_safe(x, y)
% Pearson correlation with p-value. Uses Statistics Toolbox corr if
% present; otherwise computes r directly and p via a t approximation.
n = numel(x);
if n < 3
    r = NaN; p = NaN; return;
end
if exist('corr','file') == 2
    [r, p] = corr(x, y);
else
    xc = x - mean(x); yc = y - mean(y);
    r = sum(xc.*yc) / sqrt(sum(xc.^2) * sum(yc.^2));
    t = r * sqrt((n-2)/(1-r^2));
    p = 2 * (1 - normcdf_safe(abs(t)));
end
end

function p = normcdf_safe(z)
% Standard normal CDF via erf -- avoids a Statistics Toolbox dependency.
p = 0.5 * (1 + erf(z / sqrt(2)));
end
