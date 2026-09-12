function recompute_coherence_comparison(protocolfolder, outPrefix, ftPath)
% RECOMPUTE_COHERENCE_COMPARISON
%
% Recomputes C3-C4 gamma coherence for every subject x block x phase using
% BOTH estimators and BOTH cell-inclusion rules, so the corrected analysis can
% be reported alongside the original rather than simply replacing it.
%
% ESTIMATORS
%   (A) PER-TRIAL  - the original implementation in EEGLAB_imaginarycoh.m:
%                    ft_connectivityanalysis called with cfg.trials = t, then
%                    averaged over trials. With 1 s windows and tapsmofrq = 1
%                    this yields K = 1 taper, so |coherency| = 1 identically
%                    and absimag reduces to |sin(phase difference)|.
%                    Retained here for direct comparison only.
%   (B) ENSEMBLE   - coherence computed across the full trial ensemble, the
%                    standard estimator. This is the corrected analysis.
%
% CELL-INCLUSION RULES
%   ALL   - every subject x block x phase cell
%   CLEAN - only cells in which BOTH C3 and C4 were physically measured
%           (neither reconstructed by spherical spline interpolation)
%
% USAGE
%   recompute_coherence_comparison('D:\...\data_raw','coh_comparison')
%   recompute_coherence_comparison(pf,'coh_comparison','C:\path\to\fieldtrip')
%
% OUTPUTS (written next to outPrefix)
%   <outPrefix>_cells.csv     - one row per subject x block x phase
%   <outPrefix>_holdprep.csv  - Hold-Prep contrast per subject x timepoint
%                               (the EEG side of the Figure 4D regression)
%   Console: Figure 4C-style group means computed three ways
%
% NOTE ON FIGURE 4D
%   This script produces the EEG side of that regression only. Join to the
%   kinematic variables (movementDuration, velocityPeaks, ...) afterwards; the
%   naming convention in build_supplementary_table.m is
%   <Band>_<kin>_c3c4_diff_<phasepair>_<dz>_<stim>_{eeg,kin}.

if nargin < 2 || isempty(outPrefix), outPrefix = 'coh_comparison'; end
if nargin < 3, ftPath = ''; end

% ---- FieldTrip ----------------------------------------------------------
if ~isempty(ftPath)
    assert(exist(ftPath,'dir')==7,'ftPath does not exist: %s',ftPath);
    addpath(ftPath); ft_defaults;
end
if exist('ft_freqanalysis','file')~=2 && exist('ft_defaults','file')==2
    ft_defaults;
end
assert(exist('ft_freqanalysis','file')==2, ...
    ['FieldTrip not on the path. Use:\n' ...
     '   addpath(''C:\\path\\to\\fieldtrip''); ft_defaults;\n' ...
     'or pass the folder as the 3rd argument. Do NOT use genpath().']);
fprintf('FieldTrip: %s\n\n', which('ft_freqanalysis'));

% ---- Configuration ------------------------------------------------------
GAMMA = [25 45];        % matches Figure 4B caption
TAPSMOFRQ = 1;          % original setting, retained for comparability

roster = {
 'pro00087153_0003','CS','Stim'; 'pro00087153_0004','CS','Stim'
 'pro00087153_0005','CS','Stim'; 'pro00087153_0042','CS','Stim'
 'pro00087153_0043','CS','Stim'
 'pro00087153_0013','CS','Sham'; 'pro00087153_0015','CS','Sham'
 'pro00087153_0017','CS','Sham'; 'pro00087153_0018','CS','Sham'
 'pro00087153_0021','CS','Sham'
 'pro00087153_0022','HC','Stim'; 'pro00087153_0024','HC','Stim'
 'pro00087153_0025','HC','Stim'; 'pro00087153_0026','HC','Stim'
 'pro00087153_0029','HC','Stim'
 'pro00087153_0020','HC','Sham'; 'pro00087153_0023','HC','Sham'
 'pro00087153_0027','HC','Sham'; 'pro00087153_0028','HC','Sham'
 'pro00087153_0036','HC','Sham'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
phaseNames  = {'Hold','Prep','Move'};

rows = {};

fprintf('Recomputing coherence for %d subjects (%d cells)...\n\n', ...
        size(roster,1), size(roster,1)*numel(blockNames)*numel(phaseNames));

for s = 1:size(roster,1)

    subject = roster{s,1};
    grp = roster{s,2};  cond = roster{s,3};

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  [%2d/%2d] %s : MISSING\n',s,size(roster,1),subject);
        continue
    end

    fprintf('  [%2d/%2d] %s (%s %s)\n',s,size(roster,1),subject,grp,cond);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else
            S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft;
        end
        clear S
    catch ME
        fprintf('        LOAD FAILED: %s\n',ME.message); continue
    end

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname)
                continue
            end

            try
                [aPT, aENS, magENS, nTr, c3i, c4i, K] = ...
                    cellCoherence(peeg, GAMMA, TAPSMOFRQ);
            catch ME
                fprintf('        %s/%s failed: %s\n', blockLabels{b}, phaseNames{p}, ME.message);
                continue
            end

            isClean = strcmp(c3i,'no') && strcmp(c4i,'no');

            rows(end+1,:) = { subject, grp, cond, blockLabels{b}, phaseNames{p}, ...
                              nTr, K, aPT, aENS, magENS, c3i, c4i, ...
                              ternary(isClean,'clean','interpolated') }; %#ok<AGROW>
        end
    end
    clear ev
end

hdr = {'subject','group','condition','block','phase','n_trials','n_tapers', ...
       'absimag_pertrial','absimag_ensemble','absmag_ensemble', ...
       'C3_interpolated','C4_interpolated','cell_status'};
T = cell2table(rows,'VariableNames',hdr);
cellsCsv = [outPrefix '_cells.csv'];
writetable(T,cellsCsv);
fprintf('\nPer-cell table written: %s (%d rows)\n', cellsCsv, height(T));

% =========================================================================
% Hold-Prep contrast per subject x timepoint (EEG side of Figure 4D)
% =========================================================================
hp = {};
subs = unique(T.subject,'stable');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    for b = 1:numel(blockLabels)
        h = ti(strcmp(ti.block,blockLabels{b}) & strcmp(ti.phase,'Hold'),:);
        r = ti(strcmp(ti.block,blockLabels{b}) & strcmp(ti.phase,'Prep'),:);
        if isempty(h) || isempty(r), continue; end

        dPT  = r.absimag_pertrial(1) - h.absimag_pertrial(1);
        dENS = r.absimag_ensemble(1) - h.absimag_ensemble(1);
        pctPT  = 100*dPT /h.absimag_pertrial(1);
        pctENS = 100*dENS/h.absimag_ensemble(1);

        bothClean = strcmp(h.cell_status{1},'clean') && strcmp(r.cell_status{1},'clean');

        hp(end+1,:) = { subs{i}, ti.group{1}, ti.condition{1}, blockLabels{b}, ...
                        h.absimag_pertrial(1), r.absimag_pertrial(1), dPT, pctPT, ...
                        h.absimag_ensemble(1), r.absimag_ensemble(1), dENS, pctENS, ...
                        ternary(bothClean,'clean','interpolated') }; %#ok<AGROW>
    end
end
hpHdr = {'subject','group','condition','block', ...
         'hold_pertrial','prep_pertrial','diff_pertrial','pctchange_pertrial', ...
         'hold_ensemble','prep_ensemble','diff_ensemble','pctchange_ensemble', ...
         'cell_status'};
H = cell2table(hp,'VariableNames',hpHdr);
hpCsv = [outPrefix '_holdprep.csv'];
writetable(H,hpCsv);
fprintf('Hold-Prep contrast written: %s (%d rows)\n\n', hpCsv, height(H));

% =========================================================================
% Console comparison - Figure 4C structure, three ways
% =========================================================================
fprintf('==========================================================\n');
fprintf(' FIGURE 4C COMPARISON: gamma C3-C4, mean by group/block/phase\n');
fprintf(' (A) per-trial, all cells   [original, degenerate]\n');
fprintf(' (B) ensemble,  all cells   [corrected]\n');
fprintf(' (C) ensemble,  clean cells [corrected + interpolation-restricted]\n');
fprintf('==========================================================\n');

groups = {'CS','Stim';'CS','Sham';'HC','Stim';'HC','Sham'};
for g = 1:size(groups,1)
    selG = strcmp(T.group,groups{g,1}) & strcmp(T.condition,groups{g,2});
    if ~any(selG), continue; end
    fprintf('\n--- %s %s ---\n', groups{g,1}, groups{g,2});
    fprintf('%-6s %-6s %10s %10s %10s %8s\n','block','phase','(A)pertrl','(B)ens','(C)ensCln','nClean');
    for b = 1:numel(blockLabels)
        for p = 1:numel(phaseNames)
            sel = selG & strcmp(T.block,blockLabels{b}) & strcmp(T.phase,phaseNames{p});
            if ~any(sel), continue; end
            tt = T(sel,:);
            cl = tt(strcmp(tt.cell_status,'clean'),:);
            fprintf('%-6s %-6s %10.4f %10.4f %10s %8d\n', ...
                blockLabels{b}, phaseNames{p}, ...
                mean(tt.absimag_pertrial,'omitnan'), ...
                mean(tt.absimag_ensemble,'omitnan'), ...
                ternary(isempty(cl),'   n/a', sprintf('%10.4f',mean(cl.absimag_ensemble,'omitnan'))), ...
                height(cl));
        end
    end
end

fprintf('\n==========================================================\n');
fprintf(' DATA LOSS FROM CLEAN-CELL RESTRICTION\n');
fprintf('==========================================================\n');
for g = 1:size(groups,1)
    selG = strcmp(T.group,groups{g,1}) & strcmp(T.condition,groups{g,2});
    tt = T(selG,:);
    if isempty(tt), continue; end
    nAll = height(tt); nCl = sum(strcmp(tt.cell_status,'clean'));
    subsAll = numel(unique(tt.subject));
    subsCl  = numel(unique(tt.subject(strcmp(tt.cell_status,'clean'))));
    fprintf('%s %-5s cells %3d -> %3d (%.0f%%)   subjects %d -> %d\n', ...
        groups{g,1}, groups{g,2}, nAll, nCl, 100*nCl/nAll, subsAll, subsCl);
end

% Subjects available for the Figure 4D regression (LS, Hold+Prep both clean)
fprintf('\nFigure 4D eligibility (LS timepoint, Hold AND Prep both clean):\n');
for g = 1:size(groups,1)
    sel = strcmp(H.group,groups{g,1}) & strcmp(H.condition,groups{g,2}) & strcmp(H.block,'LS');
    hh = H(sel,:);
    if isempty(hh), continue; end
    nEl = sum(strcmp(hh.cell_status,'clean'));
    fprintf('  %s %-5s : %d of %d subjects eligible\n', ...
        groups{g,1}, groups{g,2}, nEl, height(hh));
    if nEl < 5
        fprintf('      >> n = %d; regression not interpretable at this size.\n', nEl);
    end
end
fprintf('==========================================================\n');

end % main

% =========================================================================
function [absimagPT, absimagENS, magENS, nTrials, c3interp, c4interp, K] = ...
         cellCoherence(peeg, gammaBand, tapsmofrq)

timeidx    = peeg.times >= 0;
peeg.times = peeg.times(timeidx);
peeg.data  = peeg.data(:,timeidx,:);
nTrials    = size(peeg.data,3);

% interpolation status of C3 / C4
lbls = {peeg.chanlocs.labels};
badList = [];
if isfield(peeg,'badChannels') && isfield(peeg.badChannels,'channels')
    bc = peeg.badChannels.channels;
    if ~any(isnan(bc(:))), badList = bc(:)'; end
end
iC3 = find(strcmpi(lbls,'C3'),1);
iC4 = find(strcmpi(lbls,'C4'),1);
c3interp = ternary(~isempty(iC3) && ismember(iC3,badList),'YES','no');
c4interp = ternary(~isempty(iC4) && ismember(iC4,badList),'YES','no');

% build FieldTrip structure (identical to EEGLAB_imaginarycoh.m)
ft_EEG              = [];
ft_EEG.hdr.Fs       = peeg.srate;
ft_EEG.hdr.nChans   = peeg.nbchan;
ft_EEG.hdr.labels   = {peeg.chanlocs.labels}';
ft_EEG.hdr.nSamples = peeg.pnts;
ft_EEG.hdr.nTrials  = nTrials;
ft_EEG.label        = ft_EEG.hdr.labels;
ft_EEG.time         = repmat({peeg.times/1000},1,nTrials);
for t = 1:nTrials, ft_EEG.trial{t} = double(peeg.data(:,:,t)); end
ft_EEG.fsample = peeg.srate;

cfg            = [];
cfg.output     = 'powandcsd';
cfg.method     = 'mtmfft';
cfg.taper      = 'dpss';
cfg.pad        = 'maxperlen';
cfg.keeptrials = 'yes';
cfg.tapsmofrq  = tapsmofrq;
cfg.channel    = 1:21;
freq_csd       = ft_freqanalysis(cfg, ft_EEG);

K = NaN;
if isfield(freq_csd,'cumtapcnt'), K = freq_csd.cumtapcnt(1); end

% ---- (A) per-trial, original implementation --------------------------
vals = nan(nTrials,1);
for t = 1:nTrials
    c = []; c.method='coh'; c.complex='complex'; c.trials=t;
    conn = ft_connectivityanalysis(c, freq_csd);
    ip = findpair(conn.labelcmb,'C3','C4');
    if isempty(ip), error('C3-C4 pair not found'); end
    fi = conn.freq>=gammaBand(1) & conn.freq<=gammaBand(2);
    vals(t) = mean(abs(imag(conn.cohspctrm(ip,fi))));
end
absimagPT = mean(vals,'omitnan');

% ---- (B) ensemble across trials --------------------------------------
c = []; c.method='coh'; c.complex='complex';
connE = ft_connectivityanalysis(c, freq_csd);
ip = findpair(connE.labelcmb,'C3','C4');
fi = connE.freq>=gammaBand(1) & connE.freq<=gammaBand(2);
absimagENS = mean(abs(imag(connE.cohspctrm(ip,fi))));
magENS     = mean(abs(connE.cohspctrm(ip,fi)));

end

function ip = findpair(labelcmb,a,b)
ip = find( (strcmpi(labelcmb(:,1),a) & strcmpi(labelcmb(:,2),b)) | ...
           (strcmpi(labelcmb(:,1),b) & strcmpi(labelcmb(:,2),a)) );
if ~isempty(ip), ip = ip(1); end
end

function out = ternary(cond,a,b)
if cond, out = a; else, out = b; end
end

