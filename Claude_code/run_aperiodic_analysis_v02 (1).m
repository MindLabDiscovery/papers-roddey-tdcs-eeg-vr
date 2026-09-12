function run_aperiodic_analysis(protocolfolder, outPrefix)
% RUN_APERIODIC_ANALYSIS
%
% Tests whether the broadband stimulation-related power change reflects a
% shift in the APERIODIC (1/f) component of the EEG spectrum, rather than a
% change in any oscillatory band.
%
% WHY THIS TEST
%   Three independent analyses have now shown the 30-50 Hz change is not
%   band-specific: it tracks a 70-100 Hz control band per subject, at the
%   group level (+1.14 vs +1.16 dB), and across the scalp (map r = 0.95).
%   A broadband power change with no band specificity is the signature of an
%   aperiodic shift. That is a measurable, physiologically interpretable
%   phenomenon rather than a nuisance: the aperiodic exponent is widely
%   interpreted as an index of excitation/inhibition balance, which is what
%   anodal tDCS is hypothesised to modulate.
%
% WHAT IS FIT
%   In log-log space the spectrum is modelled as
%       log10(P) = offset - exponent * log10(f)
%   fit robustly, with oscillatory peaks iteratively down-weighted so they do
%   not drag the line (the specparam / FOOOF approach, implemented here
%   directly so no Python dependency is required).
%
%   OFFSET   shifts the whole spectrum up/down  -> broadband translation
%   EXPONENT changes the tilt                    -> spectral rotation
%
% THE DECISIVE COMPARISON
%   Once the aperiodic component is removed, is there ANY residual
%   stimulation-related change in low gamma? If flattened gamma shows no
%   effect while raw gamma does, the "gamma increase" is entirely an
%   aperiodic shift and there is no oscillatory gamma finding to report.
%
% ALL FOUR SUBGROUPS are analysed (CS stim/sham, HC stim/sham), which also
% addresses Reviewer 1's request for group-level reporting across subgroups.
%
% USAGE
%   run_aperiodic_analysis('D:\...\data_raw','C:\Users\ncr200\Downloads\aperiodic')
%
% OUTPUT
%   <outPrefix>_channels.csv  - per subject x block x phase x channel
%   <outPrefix>_summary.csv   - per subject, pre vs during stimulation
%   Console: exponent, offset, raw gamma and flattened gamma, by subgroup.
%
% REQUIRES: pwelch (Signal Processing Toolbox). No other toolbox.

if nargin < 2 || isempty(outPrefix), outPrefix = 'aperiodic'; end

% ---- fit configuration --------------------------------------------------
FIT_RANGE   = [3 45];      % avoids the 0.5 Hz high-pass rolloff and the notch
NOTCH_EXCL  = [48 72];     % 59-61 Hz notch plus filter skirts
GAMMA       = [30 50];
BETA        = [13 30];
ALPHA       = [8 12];
N_ITER      = 3;           % peak down-weighting iterations

roster = {
 'pro00087153_0003','CS','Stim','C3'; 'pro00087153_0004','CS','Stim','C3'
 'pro00087153_0005','CS','Stim','C4'; 'pro00087153_0042','CS','Stim','C4'
 'pro00087153_0043','CS','Stim','C3'
 'pro00087153_0013','CS','Sham','C4'; 'pro00087153_0015','CS','Sham','C3'
 'pro00087153_0017','CS','Sham','C4'; 'pro00087153_0018','CS','Sham','C4'
 'pro00087153_0021','CS','Sham','C4'
 'pro00087153_0022','HC','Stim','';   'pro00087153_0024','HC','Stim',''
 'pro00087153_0025','HC','Stim','';   'pro00087153_0026','HC','Stim',''
 'pro00087153_0029','HC','Stim',''
 'pro00087153_0020','HC','Sham','';   'pro00087153_0023','HC','Sham',''
 'pro00087153_0027','HC','Sham','';   'pro00087153_0028','HC','Sham',''
 'pro00087153_0036','HC','Sham',''
};
% NOTE: anode column filled for CS from Table 1 (right hand -> C3, left -> C4).
% HC left blank - supply if stimulation side was recorded for controls.

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
STIM_BLOCK  = [false true true false];

rows = {};

fprintf('Aperiodic parameterization, %d subjects\n', size(roster,1));
fprintf('  fit range %g-%g Hz, excluding %g-%g Hz (notch)\n\n', ...
        FIT_RANGE, NOTCH_EXCL);

for s = 1:size(roster,1)

    subject = roster{s,1}; grp = roster{s,2};
    cond = roster{s,3};    anode = roster{s,4};
    sid = subject(end-3:end);

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING -- skipped\n', subject); continue
    end
    fprintf('  [%2d/%2d] %s (%s %s) ... ', s, size(roster,1), subject, grp, cond);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n', ME.message); continue
    end

    nCells = 0;
    for b = 1:numel(blockNames)
        if ~isfield(ev.trials, blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        % concatenate phases within block for a stable spectral estimate
        blk = []; labels = {}; srate = NaN;
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end
            srate = peeg.srate;
            if isempty(labels)
                nch = min(21,numel(peeg.chanlocs));
                labels = {peeg.chanlocs(1:nch).labels};
            end
            D = double(peeg.data(1:numel(labels),:,:));
            blk = cat(2, blk, reshape(D, numel(labels), []));
        end
        if isempty(blk), continue; end

        for c = 1:numel(labels)
            x = blk(c,:) - mean(blk(c,:));
            [pxx,f] = pwelch(x, hamming(min(srate*2,numel(x))), [], [], srate);

            [expo, offs, r2, flatLog, fAll] = fit_aperiodic( ...
                f, pxx, FIT_RANGE, NOTCH_EXCL, N_ITER);

            % raw band power (dB)
            rawG = 10*log10(mean(pxx(f>=GAMMA(1) & f<=GAMMA(2)))+eps);
            rawB = 10*log10(mean(pxx(f>=BETA(1)  & f<=BETA(2)))+eps);
            rawA = 10*log10(mean(pxx(f>=ALPHA(1) & f<=ALPHA(2)))+eps);

            % flattened (periodic-only) band power: residual above the fit,
            % in dB (flatLog is log10 units, so x10)
            flatG = 10*mean(flatLog(fAll>=GAMMA(1) & fAll<=GAMMA(2)));
            flatB = 10*mean(flatLog(fAll>=BETA(1)  & fAll<=BETA(2)));
            flatA = 10*mean(flatLog(fAll>=ALPHA(1) & fAll<=ALPHA(2)));

            rows(end+1,:) = {sid, grp, cond, anode, blockLabels{b}, ...
                ternary(STIM_BLOCK(b),'yes','no'), labels{c}, ...
                expo, offs, r2, rawA, rawB, rawG, flatA, flatB, flatG}; %#ok<AGROW>
            nCells = nCells + 1;
        end
    end
    clear ev
    fprintf('%d cells\n', nCells);
end

if isempty(rows)
    error(['run_aperiodic_analysis: no data was loaded from any subject.\n' ...
           'Nothing was computed, so the output table cannot be built.\n\n' ...
           'protocolfolder was:\n   %s\n\n' ...
           'Check the console messages above:\n' ...
           '  "MISSING -- skipped"  -> wrong protocolfolder, or that subject\n' ...
           '                           folder is not present. This folder must\n' ...
           '                           contain all 20 pro00087153_XXXX folders,\n' ...
           '                           not a single-subject copy.\n' ...
           '  "LOAD FAILED"         -> EEGlab_Total.mat exists but could not be\n' ...
           '                           read.\n' ...
           '  "0 cells"             -> file loaded but contained neither\n' ...
           '                           eegevents_tfa nor eegevents_ft, or the\n' ...
           '                           trials/chanlocs fields were empty.\n\n' ...
           'Verify with:\n' ...
           '   dir(fullfile(''%s'',''pro00087153_*''))\n' ...
           '   whos(''-file'', fullfile(''%s'', ...\n' ...
           '        ''pro00087153_0003'',''analysis'',''EEGlab'',''EEGlab_Total.mat''))'], ...
           protocolfolder, protocolfolder, protocolfolder);
end

hdr = {'subject','group','condition','anode','block','during_stim','channel', ...
       'exponent','offset','fit_r2', ...
       'raw_alpha','raw_beta','raw_gamma', ...
       'flat_alpha','flat_beta','flat_gamma'};
T = cell2table(rows,'VariableNames',hdr);
f1 = [outPrefix '_channels.csv']; writetable(T,f1);
fprintf('\nWritten: %s (%d rows)\n', f1, height(T));

% ---- fit quality gate ---------------------------------------------------
fprintf('\n==================================================================\n');
fprintf(' FIT QUALITY\n');
fprintf('==================================================================\n');
fprintf('  mean R^2 = %.3f   (min %.3f, %.1f%% of fits below 0.90)\n', ...
    mean(T.fit_r2,'omitnan'), min(T.fit_r2), 100*mean(T.fit_r2<0.90));
fprintf('  mean exponent = %.2f   (typical scalp EEG: 1-3)\n', mean(T.exponent,'omitnan'));
if mean(T.fit_r2,'omitnan') < 0.90
    fprintf('  >> WARNING: poor fits. Inspect before interpreting anything below.\n');
end

% ---- per-subject pre vs during -----------------------------------------
sumRows = {};
subs = unique(T.subject,'stable');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    sS = strcmp(ti.during_stim,'yes');
    sumRows(end+1,:) = { subs{i}, ti.group{1}, ti.condition{1}, ...
        mean(ti.exponent(sS))-mean(ti.exponent(~sS)), ...
        mean(ti.offset(sS))  -mean(ti.offset(~sS)), ...
        mean(ti.raw_gamma(sS))-mean(ti.raw_gamma(~sS)), ...
        mean(ti.flat_gamma(sS))-mean(ti.flat_gamma(~sS)), ...
        mean(ti.raw_beta(sS)) -mean(ti.raw_beta(~sS)), ...
        mean(ti.flat_beta(sS))-mean(ti.flat_beta(~sS)), ...
        mean(ti.flat_alpha(sS))-mean(ti.flat_alpha(~sS)) }; %#ok<AGROW>
end
if isempty(sumRows)
    error('No per-subject summaries could be built (the channel table had no usable rows).');
end
S2 = cell2table(sumRows,'VariableNames', ...
    {'subject','group','condition','d_exponent','d_offset', ...
     'd_raw_gamma','d_flat_gamma','d_raw_beta','d_flat_beta','d_flat_alpha'});
f2 = [outPrefix '_summary.csv']; writetable(S2,f2);
fprintf('Written: %s\n', f2);

% =========================================================================
fprintf('\n==================================================================\n');
fprintf(' STIMULATION EFFECT BY SUBGROUP (during minus pre)\n');
fprintf('==================================================================\n');
fprintf('%-12s %11s %11s %13s %13s\n', ...
        'group','d exponent','d offset','d raw gamma','d FLAT gamma');
groups = {'CS','Stim';'CS','Sham';'HC','Stim';'HC','Sham'};
for g = 1:size(groups,1)
    sel = strcmp(S2.group,groups{g,1}) & strcmp(S2.condition,groups{g,2});
    if ~any(sel), continue; end
    gg = S2(sel,:);
    fprintf('%-12s %+11.3f %+11.3f %+13.2f %+13.2f\n', ...
        [groups{g,1} ' ' groups{g,2}], ...
        mean(gg.d_exponent), mean(gg.d_offset), ...
        mean(gg.d_raw_gamma), mean(gg.d_flat_gamma));
end

fprintf('\n  Per subject, CS active stimulation:\n');
fprintf('%-8s %11s %11s %13s %13s\n','subject','d exponent','d offset','d raw gamma','d FLAT gamma');
sel = strcmp(S2.group,'CS') & strcmp(S2.condition,'Stim');
gg = S2(sel,:);
for i = 1:height(gg)
    fprintf('%-8s %+11.3f %+11.3f %+13.2f %+13.2f\n', gg.subject{i}, ...
        gg.d_exponent(i), gg.d_offset(i), gg.d_raw_gamma(i), gg.d_flat_gamma(i));
end

fprintf('\n------------------------------------------------------------------\n');
fprintf(' READING THE RESULT\n');
fprintf('------------------------------------------------------------------\n');
rg = mean(gg.d_raw_gamma); fg = mean(gg.d_flat_gamma);
de = mean(gg.d_exponent);  do_ = mean(gg.d_offset);
fprintf(' CS active: raw gamma %+.2f dB -> flattened gamma %+.2f dB\n', rg, fg);
if abs(fg) < 0.5*abs(rg)
    fprintf(' >> The gamma change largely DISAPPEARS after removing the\n');
    fprintf('    aperiodic component. There is no oscillatory gamma effect;\n');
    fprintf('    the finding is an aperiodic shift.\n');
else
    fprintf(' >> A residual gamma change survives aperiodic removal.\n');
    fprintf('    An oscillatory component may be present.\n');
end
if abs(do_) > abs(de)
    fprintf(' >> Offset moves more than exponent: broadband TRANSLATION.\n');
else
    fprintf(' >> Exponent moves more than offset: spectral ROTATION,\n');
    fprintf('    the pattern associated with a shift in E/I balance.\n');
end
fprintf('\n Compare against CS Sham above. An effect present in both is not\n');
fprintf(' stimulation-specific.\n');
fprintf('==================================================================\n');
fprintf('\nNEXT STEP: join <outPrefix>_summary.csv to the kinematic change\n');
fprintf('scores (max acceleration Pre->LS) to test whether the aperiodic\n');
fprintf('shift tracks the movement speed effect.\n');

end % main

% =========================================================================
function [expo, offs, r2, flatLog, fUse] = fit_aperiodic(f, pxx, fitRange, notchExcl, nIter)
% Robust log-log linear fit with iterative peak down-weighting.
f = f(:); pxx = pxx(:);
inRange = f >= fitRange(1) & f <= fitRange(2);
notNotch = ~(f >= notchExcl(1) & f <= notchExcl(2));
use = inRange & notNotch & pxx > 0;

fUse = f(use);
lf = log10(fUse);
lp = log10(pxx(use));

if numel(lf) < 10
    expo = NaN; offs = NaN; r2 = NaN; flatLog = nan(size(lp)); return
end

keep = true(size(lf));
b = [0 0];
for it = 1:max(1,nIter)
    b = polyfit(lf(keep), lp(keep), 1);
    resid = lp - polyval(b, lf);
    % peaks sit ABOVE the aperiodic floor; exclude strong positive residuals
    thr = std(resid(keep));
    keep = resid < 1.0*thr;
    if sum(keep) < 10, keep = true(size(lf)); break; end
end

expo = -b(1);
offs = b(2);

fit = polyval(b, lf);
flatLog = lp - fit;                      % log10 units

ss_res = sum((lp - fit).^2);
ss_tot = sum((lp - mean(lp)).^2);
if ss_tot == 0, r2 = NaN; else, r2 = 1 - ss_res/ss_tot; end
end

function out = ternary(c,a,b)
if c, out = a; else, out = b; end
end
