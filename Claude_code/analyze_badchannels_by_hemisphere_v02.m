%% analyze_badchannels_by_hemisphere_v02.m
%
% QUESTION
%   Does the increase in automated channel rejection during stimulation
%   occur specifically at the stimulated hemisphere, or across the montage?
%
%   The abstract previously stated that recording quality "degrades
%   specifically under active current in the lesioned hemisphere." That
%   claim is not established by either existing result:
%     - Figure 3D shows an overall spatial gradient, with electrodes nearer
%       the anode removed more often across the whole session. It does not
%       show that the INCREASE during stimulation is anode-specific.
%     - The channel-count finding (1.10 to 2.50 in CS active) is a
%       whole-montage total, not resolved by hemisphere.
%
%   Evidence also points the other way: in the nine-pair band analysis the
%   six smallest p-values were all delta at early and late stimulation and
%   appeared at BOTH hemispheres, with contralesional changes as large as
%   ipsilesional (contra Reach/LS +2.94 dB vs ipsi +2.18 dB). Low-frequency
%   artifact spreads by volume conduction, so bilateral involvement is the
%   expected result.
%
%   This script settles it by counting rejected channels per hemisphere,
%   per block, per group.
%
% WHAT IS COUNTED
%   peeg.badChannels.channels holds the indices rejected in that recording.
%   Each is assigned to the ipsilesional or contralesional hemisphere by
%   the participant's stimulation side, or to midline. Counts are
%   normalised by the number of electrodes available in each set, since the
%   hemispheres contain equal numbers but midline does not.
%
% INPUT
%   <protocolfolder>/<subject>/analysis/EEGlab/EEGlab_Total.mat
%   Same source as recompute_coherence_comparison.m.
%
% OUTPUT
%   badchannels_by_hemisphere.csv   one row per subject x block
%   console: the test of the anode-specificity claim
%
% USAGE
%   analyze_badchannels_by_hemisphere('D:\...\data_raw')
%   analyze_badchannels_by_hemisphere(pf,'badchannels','D:\...\subjectData.mat')
%
%   Stimulation side is read from subjectData.mat rather than from
%   eegevents_tfa, which does not reliably carry sessioninfo. Adjust the
%   third argument if subjectData.mat sits elsewhere.
%
% R2019b safe.

function analyze_badchannels_by_hemisphere(protocolfolder, outPrefix, matPath)

if nargin < 2 || isempty(outPrefix), outPrefix = 'badchannels'; end
if nargin < 3 || isempty(matPath)
    matPath = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
end

%% ---- Stimulation side ------------------------------------------------
% Read from subjectData.mat, which is authoritative and carries the
% corrected entries for 0042 and 0043. eegevents_tfa does not reliably
% include sessioninfo, so it is used only as a fallback.
latMap = containers.Map('KeyType','char','ValueType','char');
if isfile(matPath)
    SD = load(matPath,'subjectData');
    sdn = {SD.subjectData.SubjectName};
    for q = 1:numel(sdn)
        tok = regexp(sdn{q},'(\d{4})$','tokens','once');
        if isempty(tok), continue; end
        si = SD.subjectData(q).sessioninfo;
        if isstruct(si) && isfield(si,'stimlat') && ~isempty(si.stimlat)
            latMap(tok{1}) = upper(strtrim(char(string(si.stimlat))));
        end
    end
    clear SD
    fprintf('Stimulation side read from %s (%d subjects).\n', matPath, latMap.Count);
else
    warning(['subjectData.mat not found at %s. Falling back to ' ...
             'ev.sessioninfo, which is often absent.'], matPath);
end

%% ---- Electrode sets --------------------------------------------------
% Right- and left-hemisphere indices, nine homologous pairs.
% Midline (Fz=10, Cz=11, Pz=21) is counted separately.
elecR   = [12 13 17 20 14 18 15 19 16];   % Fp2 F8 F4 A2 T4 C4 T6 P4 O2
elecL   = [ 1  2  6  9  3  7  4  8  5];   % Fp1 F7 F3 A1 T3 C3 T5 P3 O1
elecMid = [10 11 21];                     % Fz Cz Pz

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};

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

rows = {};
fprintf('Counting rejected channels for %d subjects...\n\n', size(roster,1));

for s = 1:size(roster,1)
    subject = roster{s,1}; grp = roster{s,2}; cond = roster{s,3};
    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  [%2d] %s : MISSING\n',s,subject); continue
    end
    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('  [%2d] %s LOAD FAILED: %s\n',s,subject,ME.message); continue
    end

    % stimulation side determines which set is ipsilesional
    stimlat = '';
    tok = regexp(subject,'(\d{4})$','tokens','once');
    if ~isempty(tok) && isKey(latMap, tok{1})
        stimlat = latMap(tok{1});                       % authoritative
    elseif isfield(ev,'sessioninfo') && isfield(ev.sessioninfo,'stimlat')
        stimlat = upper(strtrim(char(string(ev.sessioninfo.stimlat))));
    end
    if ~ismember(stimlat,{'L','R'})
        warning(['%s: stimulation side unavailable (got "%s"). Skipping. ' ...
                 'Check sessioninfo.stimlat in subjectData.mat.'], subject, stimlat);
        continue
    end
    if strcmp(stimlat,'R'), eIpsi = elecR; eCont = elecL;
    else,                   eIpsi = elecL; eCont = elecR; end

    fprintf('  [%2d] %s (%s %s, anode %s)\n', s, subject, grp, cond, ...
        ternary(strcmp(stimlat,'R'),'C4','C3'));

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        % badChannels is per recording; take the first available phase,
        % since rejection is applied at the block level
        bad = [];
        got = false;
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'badChannels'), continue; end
            if ~isfield(peeg.badChannels,'channels'), continue; end
            bc = peeg.badChannels.channels;
            if any(isnan(bc(:))), continue; end
            bad = bc(:)'; got = true; break
        end
        if ~got
            rows(end+1,:) = {subject,grp,cond,blockLabels{b},stimlat, ...
                NaN,NaN,NaN,NaN,NaN,NaN}; %#ok<AGROW>
            continue
        end

        nI = sum(ismember(bad, eIpsi));
        nC = sum(ismember(bad, eCont));
        nM = sum(ismember(bad, elecMid));
        rows(end+1,:) = {subject,grp,cond,blockLabels{b},stimlat, ...
            numel(bad), nI, nC, nM, ...
            100*nI/numel(eIpsi), 100*nC/numel(eCont)}; %#ok<AGROW>
    end
    clear ev
end

T = cell2table(rows,'VariableNames', ...
    {'subject','group','condition','block','stimlat','n_bad_total', ...
     'n_bad_ipsi','n_bad_contra','n_bad_midline', ...
     'pct_ipsi','pct_contra'});
csvOut = [outPrefix '_by_hemisphere.csv'];
writetable(T,csvOut);
fprintf('\nWritten: %s (%d rows)\n\n', csvOut, height(T));

%% ---- The test --------------------------------------------------------
fprintf('================================================================\n');
fprintf('  REJECTED CHANNELS BY HEMISPHERE AND BLOCK\n');
fprintf('================================================================\n');
fprintf('The claim under test: the increase during stimulation is specific\n');
fprintf('to the stimulated (ipsilesional) hemisphere.\n\n');

groups = {'CS','Stim';'CS','Sham';'HC','Stim';'HC','Sham'};
for g = 1:size(groups,1)
    sel = strcmp(T.group,groups{g,1}) & strcmp(T.condition,groups{g,2});
    if ~any(sel), continue; end
    fprintf('--- %s %s ---\n', groups{g,1}, groups{g,2});
    fprintf('%-6s %10s %10s %10s %10s\n', ...
        'block','total','ipsi','contra','ipsi-contra');
    for b = 1:numel(blockLabels)
        m = sel & strcmp(T.block,blockLabels{b});
        if ~any(m), continue; end
        fprintf('%-6s %10.2f %10.2f %10.2f %+10.2f\n', blockLabels{b}, ...
            mean(T.n_bad_total(m),'omitnan'), ...
            mean(T.n_bad_ipsi(m),'omitnan'), ...
            mean(T.n_bad_contra(m),'omitnan'), ...
            mean(T.n_bad_ipsi(m),'omitnan') - mean(T.n_bad_contra(m),'omitnan'));
    end
    fprintf('\n');
end

fprintf('================================================================\n');
fprintf('  CHANGE FROM BASELINE, BY HEMISPHERE\n');
fprintf('================================================================\n');
fprintf('If rejection increases only at the stimulated hemisphere, the\n');
fprintf('ipsi column should rise during ES and LS and the contra column\n');
fprintf('should not. If both rise, the degradation is montage-wide.\n\n');
fprintf('%-14s %-6s %12s %12s %14s\n', ...
    'cell','block','ipsi-BL','contra-BL','difference');
for g = 1:size(groups,1)
    sel = strcmp(T.group,groups{g,1}) & strcmp(T.condition,groups{g,2});
    if ~any(sel), continue; end
    subs = unique(T.subject(sel),'stable');
    base = nan(numel(subs),2);
    for k = 1:numel(subs)
        m = sel & strcmp(T.subject,subs{k}) & strcmp(T.block,'BL');
        if any(m)
            base(k,1) = T.n_bad_ipsi(find(m,1));
            base(k,2) = T.n_bad_contra(find(m,1));
        end
    end
    for b = 2:numel(blockLabels)
        dI = nan(numel(subs),1); dC = dI;
        for k = 1:numel(subs)
            m = sel & strcmp(T.subject,subs{k}) & strcmp(T.block,blockLabels{b});
            if any(m)
                dI(k) = T.n_bad_ipsi(find(m,1))   - base(k,1);
                dC(k) = T.n_bad_contra(find(m,1)) - base(k,2);
            end
        end
        [~,pv] = tt_paired(dI,dC);
        fprintf('%-14s %-6s %+12.2f %+12.2f %+9.2f (p=%.3f)\n', ...
            [groups{g,1} ' ' groups{g,2}], blockLabels{b}, ...
            mean(dI,'omitnan'), mean(dC,'omitnan'), ...
            mean(dI,'omitnan')-mean(dC,'omitnan'), pv);
    end
end

fprintf('\n================================================================\n');
fprintf('  VERDICT\n');
fprintf('================================================================\n');
selA = strcmp(T.group,'CS') & strcmp(T.condition,'Stim');
dI_all = []; dC_all = [];
subs = unique(T.subject(selA),'stable');
for k = 1:numel(subs)
    mb = selA & strcmp(T.subject,subs{k}) & strcmp(T.block,'BL');
    if ~any(mb), continue; end
    bI = T.n_bad_ipsi(find(mb,1)); bC = T.n_bad_contra(find(mb,1));
    for b = 2:3   % ES and LS
        m = selA & strcmp(T.subject,subs{k}) & strcmp(T.block,blockLabels{b});
        if any(m)
            dI_all(end+1) = T.n_bad_ipsi(find(m,1))   - bI; %#ok<AGROW>
            dC_all(end+1) = T.n_bad_contra(find(m,1)) - bC; %#ok<AGROW>
        end
    end
end
[~,pv] = tt_paired(dI_all(:), dC_all(:));
fprintf('CS active, during stimulation (ES and LS pooled):\n');
fprintf('  ipsilesional   %+.2f channels vs baseline\n', mean(dI_all,'omitnan'));
fprintf('  contralesional %+.2f channels vs baseline\n', mean(dC_all,'omitnan'));
fprintf('  difference     %+.2f, p = %.4f\n\n', ...
    mean(dI_all,'omitnan')-mean(dC_all,'omitnan'), pv);
if isfinite(pv) && pv < 0.05
    fprintf('  >> Hemisphere-specific. The abstract may state that the\n');
    fprintf('     degradation occurs at the stimulated hemisphere.\n');
else
    fprintf('  >> NOT hemisphere-specific at this sample size. The abstract\n');
    fprintf('     should say recording quality degrades under active current,\n');
    fprintf('     without attributing it to a hemisphere.\n');
end
fprintf('================================================================\n');

end

% =========================================================================
function [d,p] = tt_paired(a,b)
ok = isfinite(a) & isfinite(b);
a = a(ok); b = b(ok);
d = mean(a-b);
if numel(a) < 2, p = NaN; return; end
if std(a-b) == 0, p = NaN; return; end
if exist('ttest','file')==2
    [~,p] = ttest(a,b);
else
    t = d/(std(a-b)/sqrt(numel(a)));
    p = 2*(1 - 0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function out = ternary(cond,a,b)
if cond, out = a; else, out = b; end
end
