%% run_es_ls_psd_contrast.m
%
% CENTRAL QUESTION
%   Is the stimulation-related spectral change all artifact, or is some of
%   it not? ES and LS both have current flowing, so an apparatus-driven
%   signal should largely cancel in LS - ES.
%
%   IMPORTANT CAVEAT ON THAT LOGIC: the subtraction only cancels the
%   artifact if the artifact is STATIONARY across the stimulation period.
%   tDCS DC drift is inherently time-varying (electrode polarization, gel
%   drying, impedance change over 20 min), and the handoff documents
%   4 orders of magnitude of low-frequency growth from baseline to late
%   stim in 0043. So this script TESTS stationarity rather than assuming
%   it (Section D), and reports it before any gamma interpretation.
%
%   Equally: LS - ES ~ 0 does NOT prove "all artifact". It is also
%   consistent with a real effect that saturates early and plateaus.
%   Discrimination therefore rests on FOUR things, all reported here:
%     (1) does 30-50 Hz track the >70 Hz control band one-for-one?
%         (scalp EEG cannot resolve >50 Hz, so the control band is a
%          pure-artifact reference -- Whitham 2007)
%     (2) does the change survive removal of the 1/f aperiodic component?
%     (3) is the change PHASE-INVARIANT? tDCS current is constant across
%         hold/prep/move, so an apparatus artifact should look the same
%         in all three. A phase-dependent ES->LS change is hard for a
%         constant-current artifact to produce. (Caveat: movement itself
%         adds motion/EMG artifact, so within-phase ES vs LS is the
%         controlled comparison, not across-phase magnitude.)
%     (4) is there a spectral PEAK over the aperiodic fit, or only a
%         broadband shift?
%
% DATA STRUCTURE (from user)
%   subjectData(i).power.data : 5-D, dims = {Frequency, Time, Channels, Phase, Trial}
%   subjectData(i).power.freq : 1 x nFreq x nChan
%   subjectData(i).power.times: 1 x nTime x nChan
%   subjectData(i).power.chans: 1 x nChan struct
%   Trial : 1=BL, 2=ES, 3=LS, 4=Post
%   Phase : 1=hold, 2=prep, 3=move
%
% OUTPUTS
%   es_ls_psd_bands.csv        per-subject band changes, raw and flattened
%   es_ls_psd_phase.csv        per-subject band changes split by phase
%   fig_psd_<cell>.png         PSD: ES, LS, and LS-ES per design cell
%   fig_spec_<cell>.png        Spectrogram: ES, LS, LS-ES, matched scaling
%   fig_spec_subj_<id>.png     Per-subject spectrogram difference
%
% R2019b safe: no exportgraphics, no prctile, no Statistics Toolbox needed.
%
% STATUS: written against the described structure but NOT yet executed
% against the real file. Section A prints a full structural probe first --
% check that output before trusting anything downstream.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd, 'es_ls_psd_out');
if ~exist(OUT_DIR, 'dir'); mkdir(OUT_DIR); end

% ---- LATERALITY ----
% Read directly from sessioninfo.stimlat. The user corrected the transposed
% entries for 0042/0043, so stimlat is now authoritative.
%   stimlat 'L' -> anode C3      stimlat 'R' -> anode C4
% Sanity check only: verified hemisphere counts are C3 12 / C4 8 across the
% 20-subject roster. The script prints the counts; a mismatch means the fix
% did not propagate to this copy of the file.
EXPECTED_C3 = 12; EXPECTED_C4 = 8;

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };

% Design cells (condition from sessioninfo.stimamp; validated 20/20 vs CRF)
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

% Frequency bands. Control band is the artifact reference: scalp EEG cannot
% resolve neural activity here, so whatever appears is contamination.
bands = { ...
  'drift',   [1   4]; ...   % DC/delta -- stationarity probe
  'alpha',   [8  13]; ...
  'beta',    [13 30]; ...
  'gamma',   [30 50]; ...   % low gamma (Whitham 2007), NOT 30-200
  'control', [70 100] };    % pure-artifact reference band

% Aperiodic (1/f) fit range. Starts at 10 Hz deliberately: the handoff notes
% the first aperiodic fit started at 3 Hz and was contaminated by DC drift.
FIT_RANGE   = [10 100];
LINE_NOISE  = [58 62];    % excluded from the fit
PHASES      = {'hold','prep','move'};
PRIMARY_PHASE = 3;        % 'move' -- used for the headline PSD/spectrogram figures
TRIAL_BL = 1; TRIAL_ES = 2; TRIAL_LS = 3; TRIAL_POST = 4;

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH)
    error('run_es_ls_psd_contrast:noFile', 'Not found: %s', MAT_PATH);
end
fprintf('Loading %s ...\n', MAT_PATH);
S = load(MAT_PATH);
sd = S.subjectData;
sd_names = {sd.SubjectName};

subjects = roster(:);
nS = numel(subjects);

% ---- Resolve anodal channel per subject from stimlat ----
anode_of = containers.Map('KeyType','char','ValueType','char');
n_c3 = 0; n_c4 = 0;
for i = 1:nS
    sid = subjects{i};
    mi = find(contains(sd_names, sid), 1);
    if isempty(mi)
        warning('Subject %s not in subjectData.', sid); continue;
    end
    sl = sd(mi).sessioninfo.stimlat;
    sl = upper(strtrim(char(string(sl))));
    switch sl
        case 'L'; anode_of(sid) = 'C3'; n_c3 = n_c3 + 1;
        case 'R'; anode_of(sid) = 'C4'; n_c4 = n_c4 + 1;
        otherwise
            warning('Subject %s: stimlat = "%s" is neither L nor R.', sid, sl);
    end
end
fprintf('Laterality from stimlat: C3 %d / C4 %d (expected %d / %d)\n', ...
    n_c3, n_c4, EXPECTED_C3, EXPECTED_C4);
if n_c3 ~= EXPECTED_C3 || n_c4 ~= EXPECTED_C4
    warning('run_es_ls_psd_contrast:latCountMismatch', ...
        ['Hemisphere counts do not match the verified 12/8. The 0042/0043 ' ...
         'correction may not have propagated to this file.']);
end

%% ================= A. STRUCTURAL PROBE (read this first) ========
fprintf('\n===== A. STRUCTURAL PROBE =====\n');
p1 = sd(1).power;
fprintf('power.data size: %s\n', mat2str(size(p1.data)));
fprintf('power.dim      : %s\n', strjoin(cellfun(@char, p1.dim, 'UniformOutput', false), ' | '));
fprintf('power.freq size: %s\n', mat2str(size(p1.freq)));
fprintf('power.times size: %s\n', mat2str(size(p1.times)));

f1 = squeeze(p1.freq(1,:,1));
t1 = squeeze(p1.times(1,:,1));
fprintf('freq  : %.2f to %.2f Hz, %d bins, spacing ~%.3f Hz\n', ...
    min(f1), max(f1), numel(f1), median(diff(f1)));
fprintf('times : %.3f to %.3f, %d bins\n', min(t1), max(t1), numel(t1));

% Are freq axes identical across channels? (freq is stored per-channel.)
freq_varies = false;
for c = 2:size(p1.freq,3)
    if ~isequal(squeeze(p1.freq(1,:,c)), f1); freq_varies = true; break; end
end
fprintf('freq axis identical across channels: %s\n', mat2str(~freq_varies));

% Channel labels
chanlabels = cell(1, numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');     chanlabels{c} = p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label');  chanlabels{c} = p1.chans(c).label;
    else;                                 chanlabels{c} = sprintf('ch%d', c);
    end
end
fprintf('channels (%d): %s\n', numel(chanlabels), strjoin(chanlabels, ' '));

% Units: negative values imply dB / already-normalized; positive-only implies linear power.
vals = p1.data(:);
vals = vals(isfinite(vals));
frac_neg = mean(vals < 0);
if frac_neg > 0.01
    IS_DB = true;
    fprintf('UNITS: %.1f%% negative values -> treating data as ALREADY dB.\n', 100*frac_neg);
else
    IS_DB = false;
    fprintf('UNITS: no negative values -> treating data as LINEAR power, will apply 10*log10.\n');
end
fprintf('value range: %.4g to %.4g\n', min(vals), max(vals));
if max(f1) < 100
    warning('run_es_ls_psd_contrast:freqCeiling', ...
        ['Max frequency is %.1f Hz, below the 70-100 Hz control band. ' ...
         'Control band will be truncated to available range.'], max(f1));
end
fprintf('===== end probe =====\n\n');

%% ================= helper: per-subject extraction ================
% Returns spectrogram [nFreq x nTime] for a given trial & phase at the
% anodal channel, in dB.
    function sg = get_spec(sidx, ch_idx, phase, trial)
        raw = squeeze(sd(sidx).power.data(:, :, ch_idx, phase, trial));
        if IS_DB
            sg = raw;
        else
            sg = 10*log10(raw);
        end
    end

%% ================= B. PER-SUBJECT BAND CHANGES ==================
nB = size(bands,1);
res = struct();
rows_band  = {};
rows_phase = {};

for i = 1:nS
    sid = subjects{i};
    mi  = find(contains(sd_names, sid), 1);      % match by NAME, never index
    if isempty(mi)
        warning('Subject %s not found -- skipping.', sid); continue;
    end

    if ~isKey(anode_of, sid); continue; end
    anode = anode_of(sid);
    ch_idx = find(strcmpi(chanlabels, anode), 1);
    if isempty(ch_idx)
        warning('Subject %s: channel %s not found -- skipping.', sid, anode); continue;
    end

    cond = 'sham';
    if any(strcmp(sid, crf_active)); cond = 'active'; end
    grp = 'HC';
    sinfo = sd(mi).sessioninfo;
    if isstruct(sinfo) && isfield(sinfo,'dx') && ~isempty(sinfo.dx)
        if strcmpi(strtrim(char(string(sinfo.dx))), 'stroke'); grp = 'CS'; end
    end

    f = squeeze(sd(mi).power.freq(1,:,ch_idx));

    % --- PSD per trial: average spectrogram over time (in dB) ---
    psd_bl = mean(get_spec(mi, ch_idx, PRIMARY_PHASE, TRIAL_BL), 2, 'omitnan');
    psd_es = mean(get_spec(mi, ch_idx, PRIMARY_PHASE, TRIAL_ES), 2, 'omitnan');
    psd_ls = mean(get_spec(mi, ch_idx, PRIMARY_PHASE, TRIAL_LS), 2, 'omitnan');

    res(i).sid = sid; res(i).grp = grp; res(i).cond = cond;
    res(i).anode = anode; res(i).f = f;
    res(i).psd_bl = psd_bl; res(i).psd_es = psd_es; res(i).psd_ls = psd_ls;
    res(i).psd_diff = psd_ls - psd_es;

    % --- Flattened (aperiodic-removed) PSDs ---
    [psd_es_flat, ap_es] = flatten_psd(f, psd_es, FIT_RANGE, LINE_NOISE);
    [psd_ls_flat, ap_ls] = flatten_psd(f, psd_ls, FIT_RANGE, LINE_NOISE);
    res(i).psd_es_flat = psd_es_flat;
    res(i).psd_ls_flat = psd_ls_flat;
    res(i).exp_es = ap_es.slope; res(i).exp_ls = ap_ls.slope;
    res(i).off_es = ap_es.intercept; res(i).off_ls = ap_ls.intercept;

    % --- Narrowband peak in the flattened spectrum (Reato-type signature) ---
    % A genuine oscillatory gamma effect appears as a positive residual PEAK
    % over the aperiodic fit in 25-50 Hz. A broadband shift does not.
    pk = f >= 25 & f <= 50;
    res(i).peak_es = max(psd_es_flat(pk));
    res(i).peak_ls = max(psd_ls_flat(pk));
    [~, pk_i] = max(psd_ls_flat(pk)); fpk = f(pk);
    res(i).peak_ls_hz = fpk(pk_i);

    % --- Additive noise floor vs proportional gain ---
    % Additive linear-power noise -> bigger dB change where baseline dB is
    % LOWER  => negative correlation between (LS-ES) and ES level.
    % Proportional gain -> flat dB offset => correlation ~ 0.
    mfit = f >= FIT_RANGE(1) & f <= FIT_RANGE(2) & ...
           ~(f >= LINE_NOISE(1) & f <= LINE_NOISE(2));
    dd = psd_ls(mfit) - psd_es(mfit); ee = psd_es(mfit);
    ok2 = isfinite(dd) & isfinite(ee);
    if sum(ok2) > 5
        ddc = dd(ok2)-mean(dd(ok2)); eec = ee(ok2)-mean(ee(ok2));
        res(i).r_additive = sum(ddc.*eec)/sqrt(sum(ddc.^2)*sum(eec.^2));
    else
        res(i).r_additive = NaN;
    end

    % --- Band means, raw and flattened ---
    brow = {sid, grp, cond, anode};
    for b = 1:nB
        m = f >= bands{b,2}(1) & f <= bands{b,2}(2);
        if ~any(m)
            brow = [brow, {NaN, NaN, NaN, NaN}]; %#ok<AGROW>
            continue;
        end
        raw_d  = mean(psd_ls(m),'omitnan')      - mean(psd_es(m),'omitnan');
        flat_d = mean(psd_ls_flat(m),'omitnan') - mean(psd_es_flat(m),'omitnan');
        brow = [brow, {mean(psd_es(m),'omitnan'), mean(psd_ls(m),'omitnan'), ...
                       raw_d, flat_d}]; %#ok<AGROW>
    end
    brow = [brow, {ap_es.slope, ap_ls.slope, ap_ls.slope - ap_es.slope, ...
                   ap_es.intercept, ap_ls.intercept, ap_ls.intercept - ap_es.intercept, ...
                   res(i).peak_es, res(i).peak_ls, res(i).peak_ls - res(i).peak_es, ...
                   res(i).peak_ls_hz, res(i).r_additive}];
    rows_band(end+1,:) = brow; %#ok<AGROW>

    % --- Phase-resolved band changes (discriminator 3) ---
    for ph = 1:numel(PHASES)
        pe = mean(get_spec(mi, ch_idx, ph, TRIAL_ES), 2, 'omitnan');
        pl = mean(get_spec(mi, ch_idx, ph, TRIAL_LS), 2, 'omitnan');
        prow = {sid, grp, cond, PHASES{ph}};
        for b = 1:nB
            m = f >= bands{b,2}(1) & f <= bands{b,2}(2);
            if ~any(m); prow = [prow, {NaN}]; continue; end %#ok<AGROW>
            prow = [prow, {mean(pl(m),'omitnan') - mean(pe(m),'omitnan')}]; %#ok<AGROW>
        end
        rows_phase(end+1,:) = prow; %#ok<AGROW>
    end
end

%% ================= C. WRITE TABLES ==============================
bandvars = {'SubjectID','Group','Condition','AnodalChan'};
for b = 1:nB
    nm = bands{b,1};
    bandvars = [bandvars, {[nm '_ES'], [nm '_LS'], [nm '_dRaw'], [nm '_dFlat']}]; %#ok<AGROW>
end
bandvars = [bandvars, {'ApExp_ES','ApExp_LS','ApExp_delta', ...
    'ApOffset_ES','ApOffset_LS','ApOffset_delta', ...
    'FlatPeak_ES','FlatPeak_LS','FlatPeak_delta','FlatPeak_LS_Hz','r_additive'}];
Tb = cell2table(rows_band, 'VariableNames', bandvars);
writetable(Tb, fullfile(OUT_DIR,'es_ls_psd_bands.csv'));

phasevars = [{'SubjectID','Group','Condition','Phase'}, ...
             cellfun(@(x) [x '_dRaw'], bands(:,1)', 'UniformOutput', false)];
Tp = cell2table(rows_phase, 'VariableNames', phasevars);
writetable(Tp, fullfile(OUT_DIR,'es_ls_psd_phase.csv'));
fprintf('Wrote band and phase tables to %s\n', OUT_DIR);

%% ================= D. STATIONARITY CHECK ========================
% Does the artifact itself change from ES to LS? If drift-band power moves
% substantially, the "artifact cancels in subtraction" premise is weakened
% and any gamma residual may be drift rather than neural.
fprintf('\n===== D. ARTIFACT STATIONARITY (drift band %g-%g Hz) =====\n', ...
    bands{1,2}(1), bands{1,2}(2));
fprintf('If |drift dRaw| is large, ES-LS does NOT cancel the artifact.\n');
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
for c = 1:size(cells,1)
    m = strcmp(Tb.Group,cells{c,1}) & strcmp(Tb.Condition,cells{c,2});
    v = Tb.drift_dRaw(m);
    fprintf('  %s %-6s n=%d  drift LS-ES = %+7.3f dB (SD %6.3f)  range [%+.2f %+.2f]\n', ...
        cells{c,1}, cells{c,2}, sum(m), mean(v,'omitnan'), std(v,'omitnan'), ...
        min(v), max(v));
end

%% ================= E. GAMMA vs CONTROL TRACKING =================
% The core artifact test. If low gamma tracks the >70 Hz control band
% one-for-one, the gamma change is broadband contamination.
fprintf('\n===== E. GAMMA vs CONTROL-BAND TRACKING (ES->LS) =====\n');
fprintf('Ratio ~1 and tight correlation => broadband/artifact, not oscillatory.\n');
for c = 1:size(cells,1)
    m = strcmp(Tb.Group,cells{c,1}) & strcmp(Tb.Condition,cells{c,2});
    g = Tb.gamma_dRaw(m); k = Tb.control_dRaw(m);
    gf = Tb.gamma_dFlat(m);
    ok = isfinite(g) & isfinite(k);
    r = NaN;
    if sum(ok) >= 3
        gc = g(ok)-mean(g(ok)); kc = k(ok)-mean(k(ok));
        r = sum(gc.*kc)/sqrt(sum(gc.^2)*sum(kc.^2));
    end
    fprintf('  %s %-6s  gamma %+6.3f | control %+6.3f | ratio %5.2f | r(g,c)=%+.3f | gamma FLAT %+6.3f\n', ...
        cells{c,1}, cells{c,2}, mean(g,'omitnan'), mean(k,'omitnan'), ...
        mean(g,'omitnan')/mean(k,'omitnan'), r, mean(gf,'omitnan'));
end
fprintf(['\nINTERPRETATION: gamma ~ control and gamma_FLAT ~ 0 means the ES->LS\n' ...
         'change is broadband and aperiodic -- i.e. apparatus artifact.\n' ...
         'A gamma change that SURVIVES flattening and EXCEEDS control is the\n' ...
         'only pattern here that would indicate something oscillatory.\n']);


%% ================= E2. MECHANISM DISCRIMINATION =================
% Two candidate NEURAL signatures behave oppositely under flattening.
%   Reato-type (oscillatory low gamma, DC-modulated; Reato 2010 J Neurosci):
%       narrowband PEAK 25-50 Hz, SURVIVES flattening, does NOT track control.
%       Scalp-detectable, since it is below 50 Hz.
%   Broadband spiking (Ray 2008; high gamma ~ firing rate):
%       aperiodic OFFSET shift, TRACKS control band, deleted by flattening.
%       NOT scalp-detectable above ~50 Hz, and indistinguishable from
%       apparatus broadband noise by band power alone.
fprintf('\n===== E2. MECHANISM DISCRIMINATION (ES->LS) =====\n');
fprintf('%-12s %10s %10s %10s %10s %10s\n', ...
    'cell','dOffset','dExp','dFlatPeak','peakHz','r_additive');
for c = 1:size(cells,1)
    m = strcmp(Tb.Group,cells{c,1}) & strcmp(Tb.Condition,cells{c,2});
    fprintf('%-12s %+10.3f %+10.3f %+10.3f %10.1f %+10.3f\n', ...
        [cells{c,1} ' ' cells{c,2}], ...
        mean(Tb.ApOffset_delta(m),'omitnan'), mean(Tb.ApExp_delta(m),'omitnan'), ...
        mean(Tb.FlatPeak_delta(m),'omitnan'), mean(Tb.FlatPeak_LS_Hz(m),'omitnan'), ...
        mean(Tb.r_additive(m),'omitnan'));
end
fprintf(['\nREADING THIS TABLE:\n' ...
 '  dFlatPeak > 0 in active but not sham, with gamma NOT tracking control\n' ...
 '    => oscillatory low-gamma modulation (Reato mechanism). The only\n' ...
 '       neural account this montage can actually support.\n' ...
 '  dOffset > 0 with gamma tracking control and dFlatPeak ~ 0\n' ...
 '    => broadband shift. Could be spiking OR apparatus noise; scalp EEG\n' ...
 '       cannot separate them. Do NOT claim spiking from this alone.\n' ...
 '  r_additive strongly NEGATIVE => additive noise floor (something was\n' ...
 '    ADDED to the recording, i.e. artifact).\n' ...
 '  r_additive ~ 0 with dOffset > 0 => proportional gain (signal SCALED),\n' ...
 '    which additive instrument noise does not produce.\n']);

%% ================= F. PHASE INVARIANCE ==========================
% Constant tDCS current => apparatus artifact should be phase-flat.
fprintf('\n===== F. PHASE DEPENDENCE OF THE ES->LS CHANGE =====\n');
fprintf('Phase-flat => consistent with constant-current artifact.\n');
fprintf('Phase-dependent => hard for constant-current artifact to explain.\n');
for c = 1:size(cells,1)
    fprintf('  %s %s:\n', cells{c,1}, cells{c,2});
    for ph = 1:numel(PHASES)
        m = strcmp(Tp.Group,cells{c,1}) & strcmp(Tp.Condition,cells{c,2}) & ...
            strcmp(Tp.Phase,PHASES{ph});
        fprintf('    %-5s  gamma %+6.3f  control %+6.3f  beta %+6.3f  alpha %+6.3f\n', ...
            PHASES{ph}, mean(Tp.gamma_dRaw(m),'omitnan'), ...
            mean(Tp.control_dRaw(m),'omitnan'), ...
            mean(Tp.beta_dRaw(m),'omitnan'), mean(Tp.alpha_dRaw(m),'omitnan'));
    end
end

%% ================= G. FIGURES ===================================
% PSD triptych per design cell: ES, LS, and LS-ES.
for c = 1:size(cells,1)
    idx = find(arrayfun(@(k) ~isempty(res(k).sid) && ...
        strcmp(res(k).grp,cells{c,1}) && strcmp(res(k).cond,cells{c,2}), 1:numel(res)));
    if isempty(idx); continue; end
    f = res(idx(1)).f;
    ES = cell2mat(arrayfun(@(k) res(k).psd_es(:), idx, 'UniformOutput', false));
    LS = cell2mat(arrayfun(@(k) res(k).psd_ls(:), idx, 'UniformOutput', false));
    mES = mean(ES,2,'omitnan'); mLS = mean(LS,2,'omitnan'); mD = mLS - mES;

    fh = figure('Position',[100 100 1200 380],'Visible','off');

    subplot(1,3,1); plot(f,mES,'k','LineWidth',1.2); hold on;
    plot(f,mLS,'r','LineWidth',1.2); grid on;
    xlabel('Hz'); ylabel('dB'); legend('ES','LS','Location','best');
    title(sprintf('%s %s  PSD (n=%d)', cells{c,1}, cells{c,2}, numel(idx)));
    xlim([0 max(f)]);

    % Difference on the SAME y-span as the originals, per your request.
    span = range([mES; mLS]);
    subplot(1,3,2); plot(f,mD,'b','LineWidth',1.2); hold on;
    yline_compat(0);
    grid on; xlabel('Hz'); ylabel('dB'); xlim([0 max(f)]);
    ylim([-span/2 span/2]);
    title('LS - ES  (matched scale)');

    % Zoomed difference, so small residuals are readable.
    subplot(1,3,3); plot(f,mD,'b','LineWidth',1.2); hold on;
    yline_compat(0);
    shade_band(bands{4,2}, [0.9 0.9 0.5]);   % gamma
    shade_band(bands{5,2}, [0.6 0.85 1.0]);  % control
    grid on; xlabel('Hz'); ylabel('dB'); xlim([0 max(f)]);
    title('LS - ES  (zoomed; gamma / control shaded)');

    print(fh, fullfile(OUT_DIR, sprintf('fig_psd_%s_%s.png', cells{c,1}, cells{c,2})), ...
        '-dpng','-r150');
    close(fh);
end

% Spectrogram triptych per cell, matched color scaling.
for c = 1:size(cells,1)
    idx = find(arrayfun(@(k) ~isempty(res(k).sid) && ...
        strcmp(res(k).grp,cells{c,1}) && strcmp(res(k).cond,cells{c,2}), 1:numel(res)));
    if isempty(idx); continue; end

    mi1 = find(contains(sd_names, res(idx(1)).sid),1);
    f = squeeze(sd(mi1).power.freq(1,:,1));
    t = squeeze(sd(mi1).power.times(1,:,1));

    accES = []; accLS = [];
    for k = idx
        mi = find(contains(sd_names, res(k).sid),1);
        ch = find(strcmpi(chanlabels, res(k).anode),1);
        e = get_spec(mi, ch, PRIMARY_PHASE, TRIAL_ES);
        l = get_spec(mi, ch, PRIMARY_PHASE, TRIAL_LS);
        if isempty(accES); accES = e; accLS = l;
        else; accES = accES + e; accLS = accLS + l; end
    end
    accES = accES / numel(idx); accLS = accLS / numel(idx);
    D = accLS - accES;

    clim_orig = [min([accES(:);accLS(:)]) max([accES(:);accLS(:)])];

    fh = figure('Position',[100 100 1400 380],'Visible','off');
    subplot(1,4,1); imagesc(t,f,accES); axis xy; caxis(clim_orig);
    xlabel('time'); ylabel('Hz'); title(sprintf('%s %s ES', cells{c,1},cells{c,2})); colorbar;
    subplot(1,4,2); imagesc(t,f,accLS); axis xy; caxis(clim_orig);
    xlabel('time'); title('LS'); colorbar;
    subplot(1,4,3); imagesc(t,f,D); axis xy; caxis(clim_orig);
    xlabel('time'); title('LS - ES (ORIGINAL scale)'); colorbar;
    subplot(1,4,4); imagesc(t,f,D); axis xy;
    a = max(abs(D(:))); if a==0 || ~isfinite(a); a=1; end
    caxis([-a a]);
    xlabel('time'); title('LS - ES (symmetric)'); colorbar;

    print(fh, fullfile(OUT_DIR, sprintf('fig_spec_%s_%s.png', cells{c,1},cells{c,2})), ...
        '-dpng','-r150');
    close(fh);
end

% Per-subject difference spectrograms -- individual variability matters at n=5.
for k = 1:numel(res)
    if isempty(res(k).sid); continue; end
    mi = find(contains(sd_names, res(k).sid),1);
    ch = find(strcmpi(chanlabels, res(k).anode),1);
    f = squeeze(sd(mi).power.freq(1,:,ch));
    t = squeeze(sd(mi).power.times(1,:,ch));
    e = get_spec(mi, ch, PRIMARY_PHASE, TRIAL_ES);
    l = get_spec(mi, ch, PRIMARY_PHASE, TRIAL_LS);
    D = l - e;
    clim_orig = [min([e(:);l(:)]) max([e(:);l(:)])];

    fh = figure('Position',[100 100 1100 320],'Visible','off');
    subplot(1,3,1); imagesc(t,f,e); axis xy; caxis(clim_orig); ylabel('Hz');
    title(sprintf('%s (%s %s, %s) ES', res(k).sid, res(k).grp, res(k).cond, res(k).anode));
    colorbar;
    subplot(1,3,2); imagesc(t,f,l); axis xy; caxis(clim_orig); title('LS'); colorbar;
    subplot(1,3,3); imagesc(t,f,D); axis xy; caxis(clim_orig);
    title('LS - ES (matched)'); colorbar;
    print(fh, fullfile(OUT_DIR, sprintf('fig_spec_subj_%s.png', res(k).sid)), '-dpng','-r150');
    close(fh);
end

fprintf('\nFigures written to %s\n', OUT_DIR);
fprintf('\nLaterality source: sessioninfo.stimlat (C3 %d / C4 %d).\n', n_c3, n_c4);

%% ================= LOCAL FUNCTIONS ==============================
function [flat, ap] = flatten_psd(f, psd, fit_range, line_noise)
% Robust 1/f removal: linear fit of dB power vs log10(frequency) over
% fit_range, excluding line noise. Returns residual (flattened) spectrum.
% A genuine oscillation appears as a positive residual peak; a broadband
% shift does not survive.
f = f(:); psd = psd(:);
m = f >= fit_range(1) & f <= fit_range(2) & isfinite(psd) & f > 0;
m = m & ~(f >= line_noise(1) & f <= line_noise(2));
ap = struct('slope',NaN,'intercept',NaN,'r2',NaN);
if sum(m) < 5
    flat = nan(size(psd)); return;
end
X = [ones(sum(m),1), log10(f(m))];
b = X \ psd(m);
ap.intercept = b(1); ap.slope = b(2);
pred_in = X*b;
ss_res = sum((psd(m)-pred_in).^2);
ss_tot = sum((psd(m)-mean(psd(m))).^2);
ap.r2 = 1 - ss_res/ss_tot;
pred_all = nan(size(psd));
valid = f > 0;
pred_all(valid) = b(1) + b(2)*log10(f(valid));
flat = psd - pred_all;
end

function yline_compat(y)
% yline() is R2018b+ but behaves inconsistently in subplots on some
% R2019b builds; plot an explicit reference line instead.
xl = xlim;
plot(xl, [y y], 'k--', 'LineWidth', 0.8, 'HandleVisibility','off');
end

function shade_band(rng, col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)], [yl(1) yl(1) yl(2) yl(2)], col, ...
    'FaceAlpha', 0.25, 'EdgeColor','none','HandleVisibility','off');
end
