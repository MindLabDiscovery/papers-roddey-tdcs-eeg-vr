function recompute_coherence_multiband(protocolfolder, outPrefix, ftPath)
% RECOMPUTE_COHERENCE_MULTIBAND
%
% Extends recompute_coherence_comparison.m to multiple frequency bands.
%
% WHY
%   The original computed only GAMMA = [30 50]. Two questions were left
%   unanswered:
%     1. Is the coherence effect specific to low gamma, or present in other
%        bands? Delta, theta, alpha and beta were never tested.
%     2. Is the 30-50 Hz result influenced by the edge of the frequency
%        axis? The spectral analyses showed FlatPeak_Hz pinned at exactly
%        50.0 for three of five subjects, which is the signature of a
%        taper rolloff rather than a spectral feature. Comparing 30-50
%        against 25-45 tests whether the effect moves when the band is
%        shifted away from the ceiling.
%
% EFFICIENCY
%   ft_freqanalysis and ft_connectivityanalysis are run ONCE per cell and
%   the resulting coherence spectrum is averaged over every band. The
%   multi-band version therefore costs essentially the same as the
%   single-band original.
%
%   The per-trial (degenerate) estimator is OFF by default: it required a
%   separate ft_connectivityanalysis per trial and its degeneracy is
%   already established (mean 0.6195 vs 2/pi = 0.6366; r = 0.231 against
%   the ensemble estimator). Set DO_PERTRIAL = true to reproduce it.
%
% OUTPUT
%   <outPrefix>_multiband_cells.csv
%       one row per subject x block x phase, one column per band.
%       Also writes absimag_ensemble = the PRIMARY_BAND value, so the
%       existing plot_fig4c_ensemble.m reads this file unchanged.
%   Console: CS stim vs CS sham at every band, block and phase.
%
% USAGE
%   recompute_coherence_multiband('D:\...\data_raw','coh')
%   recompute_coherence_multiband(pf,'coh','C:\path\to\fieldtrip')

if nargin < 2 || isempty(outPrefix), outPrefix = 'coh'; end
if nargin < 3, ftPath = ''; end

%% ---- Configuration ----------------------------------------------------
BANDS = { 'delta',   [1  4]; ...
          'theta',   [4  8]; ...
          'alpha',   [8 13]; ...
          'beta',    [13 30]; ...
          'gamma',   [30 50]; ...    % as originally computed
          'gamma2545',[25 45] };     % shifted away from the 50 Hz ceiling
PRIMARY_BAND = 'gamma';       % written to the absimag_ensemble column
TAPSMOFRQ    = 1;             % original setting, retained
DO_PERTRIAL  = false;         % true reproduces the degenerate estimator

%% ---- FieldTrip --------------------------------------------------------
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
fprintf('FieldTrip: %s\n', which('ft_freqanalysis'));
fprintf('Bands: ');
for b = 1:size(BANDS,1)
    fprintf('%s(%g-%g) ', BANDS{b,1}, BANDS{b,2}(1), BANDS{b,2}(2));
end
fprintf('\nPer-trial estimator: %s\n\n', tern(DO_PERTRIAL,'ON','off'));

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
nB = size(BANDS,1);

rows = {};
fprintf('Recomputing for %d subjects (%d cells)...\n\n', ...
        size(roster,1), size(roster,1)*numel(blockNames)*numel(phaseNames));

for s = 1:size(roster,1)
    subject = roster{s,1}; grp = roster{s,2}; cond = roster{s,3};
    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  [%2d/%2d] %s : MISSING\n',s,size(roster,1),subject); continue
    end
    fprintf('  [%2d/%2d] %s (%s %s)\n',s,size(roster,1),subject,grp,cond);
    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
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
                [ensV, ptV, nTr, c3i, c4i, K] = ...
                    cellCoherenceMB(peeg, BANDS, TAPSMOFRQ, DO_PERTRIAL);
            catch ME
                fprintf('        %s/%s failed: %s\n', blockLabels{b}, phaseNames{p}, ME.message);
                continue
            end
            isClean = strcmp(c3i,'no') && strcmp(c4i,'no');
            r = { subject, grp, cond, blockLabels{b}, phaseNames{p}, ...
                  nTr, K, c3i, c4i, ternary(isClean,'clean','interpolated') };
            r = [r, num2cell(ensV(:)')]; %#ok<AGROW>
            r = [r, num2cell(ptV(:)')];  %#ok<AGROW>
            rows(end+1,:) = r; %#ok<AGROW>
        end
    end
    clear ev
end

hdr = {'subject','group','condition','block','phase','n_trials','n_tapers', ...
       'C3_interpolated','C4_interpolated','cell_status'};
for b = 1:nB, hdr{end+1} = ['ens_' BANDS{b,1}]; end %#ok<AGROW>
for b = 1:nB, hdr{end+1} = ['pt_'  BANDS{b,1}]; end %#ok<AGROW>
T = cell2table(rows,'VariableNames',hdr);

% backward-compatible column so plot_fig4c_ensemble.m runs unchanged
T.absimag_ensemble = T.(['ens_' PRIMARY_BAND]);
T.absimag_pertrial = T.(['pt_'  PRIMARY_BAND]);

csvOut = [outPrefix '_multiband_cells.csv'];
writetable(T,csvOut);
fprintf('\nWritten: %s (%d rows)\n', csvOut, height(T));
fprintf('absimag_ensemble = %s band, for compatibility with plot_fig4c_ensemble.m\n\n', ...
    PRIMARY_BAND);

%% ---- CS stim vs CS sham, every band ----------------------------------
fprintf('==========================================================\n');
fprintf(' CHRONIC STROKE: ACTIVE vs SHAM, ensemble coherence\n');
fprintf('==========================================================\n');
fprintf('Compare gamma (30-50) against gamma2545 (25-45). If the result\n');
fprintf('is an edge effect it should weaken markedly when the band is\n');
fprintf('moved away from the 50 Hz ceiling.\n\n');

nHit = zeros(1,nB);
for b = 1:nB
    bn = BANDS{b,1};
    fprintf('--- %s (%g-%g Hz) ---\n', bn, BANDS{b,2}(1), BANDS{b,2}(2));
    fprintf('%-6s %-6s %10s %10s %11s %9s\n','phase','block','stim','sham','stim-sham','p');
    for p = 1:numel(phaseNames)
        for k = 1:numel(blockLabels)
            selA = strcmp(T.group,'CS') & strcmp(T.condition,'Stim') & ...
                   strcmp(T.phase,phaseNames{p}) & strcmp(T.block,blockLabels{k});
            selS = strcmp(T.group,'CS') & strcmp(T.condition,'Sham') & ...
                   strcmp(T.phase,phaseNames{p}) & strcmp(T.block,blockLabels{k});
            a = T.(['ens_' bn])(selA); a = a(isfinite(a));
            h = T.(['ens_' bn])(selS); h = h(isfinite(h));
            [d,pv] = tt2(a,h);
            if isfinite(pv) && pv < 0.05, nHit(b) = nHit(b)+1; end
            fprintf('%-6s %-6s %10.4f %10.4f %+11.4f %9.4f%s\n', ...
                phaseNames{p}, blockLabels{k}, mean(a), mean(h), d, pv, ...
                tern(isfinite(pv) && pv<0.05,' *',''));
        end
    end
    fprintf('\n');
end

fprintf('==========================================================\n');
fprintf(' HIT COUNTS (p<.05), 12 tests per band, chance ~0.6\n');
fprintf('==========================================================\n');
for b = 1:nB
    fprintf('  %-11s (%2g-%2g Hz) : %d\n', BANDS{b,1}, ...
        BANDS{b,2}(1), BANDS{b,2}(2), nHit(b));
end
fprintf(['\nIf hits appear only in gamma/gamma2545, the effect is band-\n' ...
         'specific. If they appear across every band, it is broadband and\n' ...
         'more likely a shared nuisance factor. If gamma survives but\n' ...
         'gamma2545 does not, suspect the frequency-axis edge.\n']);
fprintf('==========================================================\n');

end % main

% =========================================================================
function [ensV, ptV, nTrials, c3interp, c4interp, K] = ...
         cellCoherenceMB(peeg, BANDS, tapsmofrq, doPerTrial)

nB = size(BANDS,1);
ensV = nan(1,nB); ptV = nan(1,nB);

timeidx    = peeg.times >= 0;
peeg.times = peeg.times(timeidx);
peeg.data  = peeg.data(:,timeidx,:);
nTrials    = size(peeg.data,3);

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

% ---- ensemble estimator: ONE call, averaged over every band ----
c = []; c.method='coh'; c.complex='complex';
connE = ft_connectivityanalysis(c, freq_csd);
ip = findpair(connE.labelcmb,'C3','C4');
if isempty(ip), error('C3-C4 pair not found'); end
for b = 1:nB
    fi = connE.freq>=BANDS{b,2}(1) & connE.freq<=BANDS{b,2}(2);
    ensV(b) = mean(abs(imag(connE.cohspctrm(ip,fi))));
end

% ---- per-trial (degenerate) estimator, optional ----
if doPerTrial
    acc = nan(nTrials,nB);
    for t = 1:nTrials
        c = []; c.method='coh'; c.complex='complex'; c.trials=t;
        conn = ft_connectivityanalysis(c, freq_csd);
        ipt = findpair(conn.labelcmb,'C3','C4');
        for b = 1:nB
            fi = conn.freq>=BANDS{b,2}(1) & conn.freq<=BANDS{b,2}(2);
            acc(t,b) = mean(abs(imag(conn.cohspctrm(ipt,fi))));
        end
    end
    ptV = mean(acc,1,'omitnan');
end
end

function ip = findpair(labelcmb,a,b)
ip = find( (strcmpi(labelcmb(:,1),a) & strcmpi(labelcmb(:,2),b)) | ...
           (strcmpi(labelcmb(:,1),b) & strcmpi(labelcmb(:,2),a)) );
if ~isempty(ip), ip = ip(1); end
end

function [d,p] = tt2(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
d = mean(a)-mean(b);
if numel(a)<2||numel(b)<2, p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0, p=NaN; return; end
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    t = d/se; p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function out = ternary(cond,a,b)
if cond, out = a; else, out = b; end
end

function out = tern(cond,a,b)
if cond, out = a; else, out = b; end
end
