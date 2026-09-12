function run_aperiodic_analysis_v03(protocolfolder, outPrefix, qcSubjects)
% RUN_APERIODIC_ANALYSIS_V03
%
% Corrects three defects in the previous version:
%
%   (1) PSD ESTIMATION. v02 concatenated 1.25 s epochs into one continuous
%       series before calling pwelch. Every epoch boundary is a step
%       discontinuity that injects broadband power, flattening the 1/f slope.
%       That is almost certainly why the mean exponent came out at 0.87 when
%       scalp EEG normally sits between 1 and 3.
%       FIX: compute the PSD of each epoch separately and average the spectra
%       (Welch across epochs). No cross-epoch discontinuities.
%
%   (2) RUNAWAY PEAK EXCLUSION. v02 derived the keep-mask from the previous
%       iteration's surviving subset and recomputed the threshold from that
%       shrinking subset, so the fitted line walked downward toward the lower
%       envelope on each pass. That produces the negative R^2 values.
%       FIX: the mask is re-derived from ALL in-range points every iteration,
%       with a 2-SD threshold, so the fit cannot run away.
%
%   (3) MISLEADING FIT METRIC. v02 reported R^2 against the full spectrum
%       including oscillatory peaks, which caps a perfectly good aperiodic
%       fit at ~0.6 whenever a strong alpha peak is present.
%       FIX: both are reported - r2_aperiodic (on retained points, the number
%       that indicates whether the fit worked) and r2_full (on all points,
%       for reference).
%
%   Tables are now built from preallocated arrays, so the cell2table
%   VariableNames failure cannot recur.
%
% QC IS MANDATORY, NOT OPTIONAL
%   The script writes example fit figures. Look at them before interpreting
%   anything. A parameterization you have not seen plotted is not a result.
%
% USAGE
%   run_aperiodic_analysis_v03('D:\...\data_raw','C:\...\aperiodic')
%   run_aperiodic_analysis_v03(pf, out, {'0003','0043'})   % QC these subjects
%
% REQUIRES: pwelch (Signal Processing Toolbox). Nothing else.

if nargin < 2 || isempty(outPrefix), outPrefix = 'aperiodic'; end
if nargin < 3 || isempty(qcSubjects), qcSubjects = {'0003','0043','0013'}; end

[outDir,~,~] = fileparts(outPrefix);
if isempty(outDir), outDir = pwd; end
if ~exist(outDir,'dir'), mkdir(outDir); end

FIT_RANGE  = [3 45];
NOTCH_EXCL = [48 72];
GAMMA = [30 50]; BETA = [13 30]; ALPHA = [8 12];
N_ITER = 3; SD_K = 2.0;

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

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
STIM_BLOCK  = [false true true false];

% ---- preallocated accumulators (no cell literals) -----------------------
N = size(roster,1)*numel(blockNames)*21;
c_subject = cell(N,1); c_group = cell(N,1); c_cond = cell(N,1);
c_anode   = cell(N,1); c_block = cell(N,1); c_stim = cell(N,1);
c_chan    = cell(N,1);
v_exp = nan(N,1); v_off = nan(N,1); v_r2a = nan(N,1); v_r2f = nan(N,1);
v_rA = nan(N,1); v_rB = nan(N,1); v_rG = nan(N,1);
v_fA = nan(N,1); v_fB = nan(N,1); v_fG = nan(N,1);
k = 0;

fprintf('Aperiodic parameterization (v03), %d subjects\n', size(roster,1));
fprintf('  PSD: per-epoch, averaged.  Fit: %g-%g Hz, excluding %g-%g Hz.\n\n', ...
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

    nAdded = 0;
    for b = 1:numel(blockNames)
        if ~isfield(ev.trials, blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});

        % gather epochs (chan x time x epoch) across phases WITHOUT concatenating
        Ecat = []; labels = {}; srate = NaN;
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end
            srate = peeg.srate;
            if isempty(labels)
                nch = min(21,numel(peeg.chanlocs));
                labels = {peeg.chanlocs(1:nch).labels};
            end
            Ecat = cat(3, Ecat, double(peeg.data(1:numel(labels),:,:)));
        end
        if isempty(Ecat), continue; end

        for c = 1:numel(labels)
            % ---- average PSD across epochs (fix 1) ----------------------
            [pxx,f] = psd_across_epochs(squeeze(Ecat(c,:,:)), srate);

            [expo, offs, r2a, r2f, flatLog, fUse] = fit_aperiodic( ...
                f, pxx, FIT_RANGE, NOTCH_EXCL, N_ITER, SD_K);

            k = k + 1;
            c_subject{k}=sid; c_group{k}=grp; c_cond{k}=cond;
            c_anode{k}=anode; c_block{k}=blockLabels{b};
            c_stim{k}=ternary(STIM_BLOCK(b),'yes','no'); c_chan{k}=labels{c};
            v_exp(k)=expo; v_off(k)=offs; v_r2a(k)=r2a; v_r2f(k)=r2f;
            v_rA(k)=bandmean_db(pxx,f,ALPHA);
            v_rB(k)=bandmean_db(pxx,f,BETA);
            v_rG(k)=bandmean_db(pxx,f,GAMMA);
            v_fA(k)=10*mean(flatLog(fUse>=ALPHA(1) & fUse<=ALPHA(2)));
            v_fB(k)=10*mean(flatLog(fUse>=BETA(1)  & fUse<=BETA(2)));
            v_fG(k)=10*mean(flatLog(fUse>=GAMMA(1) & fUse<=GAMMA(2)));
            nAdded = nAdded + 1;

            % ---- QC figure for selected subjects, C3 at BL and LS -------
            if any(strcmp(sid,qcSubjects)) && strcmpi(labels{c},'C3') && ...
               (strcmp(blockLabels{b},'BL') || strcmp(blockLabels{b},'LS'))
                qc_plot(f, pxx, fUse, flatLog, expo, offs, r2a, ...
                    sprintf('%s  %s  C3   exponent=%.2f  R^2(aper)=%.3f', ...
                            sid, blockLabels{b}, expo, r2a), ...
                    fullfile(outDir, sprintf('qcfit_%s_%s_C3.png', sid, blockLabels{b})), ...
                    FIT_RANGE, NOTCH_EXCL);
            end
        end
    end
    clear ev
    fprintf('%d cells\n', nAdded);
end

if k == 0
    error(['No data loaded. protocolfolder was:\n   %s\n' ...
           'Check the per-subject messages above.'], protocolfolder);
end

idx = 1:k;
T = table(c_subject(idx), c_group(idx), c_cond(idx), c_anode(idx), ...
          c_block(idx), c_stim(idx), c_chan(idx), ...
          v_exp(idx), v_off(idx), v_r2a(idx), v_r2f(idx), ...
          v_rA(idx), v_rB(idx), v_rG(idx), v_fA(idx), v_fB(idx), v_fG(idx), ...
    'VariableNames', {'subject','group','condition','anode','block', ...
    'during_stim','channel','exponent','offset','r2_aperiodic','r2_full', ...
    'raw_alpha','raw_beta','raw_gamma','flat_alpha','flat_beta','flat_gamma'});

f1 = [outPrefix '_channels.csv']; writetable(T,f1);
fprintf('\nWritten: %s (%d rows)\n', f1, height(T));

% ---- QC GATE ------------------------------------------------------------
fprintf('\n==================================================================\n');
fprintf(' FIT QUALITY  (check this before reading anything else)\n');
fprintf('==================================================================\n');
fprintf('  R^2 aperiodic (retained pts) : mean %.3f, min %.3f, %.1f%% below 0.90\n', ...
    mean(T.r2_aperiodic,'omitnan'), min(T.r2_aperiodic), 100*mean(T.r2_aperiodic<0.90));
fprintf('  R^2 full spectrum            : mean %.3f  (lower is expected when\n', ...
    mean(T.r2_full,'omitnan'));
fprintf('                                  strong oscillatory peaks are present)\n');
fprintf('  exponent : mean %.2f, range %.2f to %.2f   (scalp EEG typically 1-3)\n', ...
    mean(T.exponent,'omitnan'), min(T.exponent), max(T.exponent));
fprintf('  negative R^2 aperiodic cells : %d  (should be 0)\n', sum(T.r2_aperiodic<0));
good = mean(T.r2_aperiodic,'omitnan') >= 0.90 && ...
       mean(T.exponent,'omitnan') >= 1.0 && sum(T.r2_aperiodic<0)==0;
if ~good
    fprintf('\n  >> FITS STILL PROBLEMATIC. Inspect the qcfit_*.png figures in\n');
    fprintf('     %s\n', outDir);
    fprintf('     Do not interpret the group results below until they look right.\n');
else
    fprintf('\n  >> Fits look sound. Proceed.\n');
end

% ---- per-subject summary (arrays, not cells) ---------------------------
subs = unique(T.subject,'stable');
n = numel(subs);
s_sub = cell(n,1); s_grp = cell(n,1); s_cond = cell(n,1);
d_exp = nan(n,1); d_off = nan(n,1);
d_rG = nan(n,1); d_fG = nan(n,1); d_rB = nan(n,1); d_fB = nan(n,1); d_fA = nan(n,1);
for i = 1:n
    ti = T(strcmp(T.subject,subs{i}),:);
    sS = strcmp(ti.during_stim,'yes');
    s_sub{i}=subs{i}; s_grp{i}=ti.group{1}; s_cond{i}=ti.condition{1};
    d_exp(i)=dmean(ti.exponent,sS);   d_off(i)=dmean(ti.offset,sS);
    d_rG(i)=dmean(ti.raw_gamma,sS);   d_fG(i)=dmean(ti.flat_gamma,sS);
    d_rB(i)=dmean(ti.raw_beta,sS);    d_fB(i)=dmean(ti.flat_beta,sS);
    d_fA(i)=dmean(ti.flat_alpha,sS);
end
S2 = table(s_sub,s_grp,s_cond,d_exp,d_off,d_rG,d_fG,d_rB,d_fB,d_fA, ...
    'VariableNames',{'subject','group','condition','d_exponent','d_offset', ...
    'd_raw_gamma','d_flat_gamma','d_raw_beta','d_flat_beta','d_flat_alpha'});
f2 = [outPrefix '_summary.csv']; writetable(S2,f2);
fprintf('Written: %s\n', f2);

% ---- results ------------------------------------------------------------
fprintf('\n==================================================================\n');
fprintf(' STIMULATION EFFECT BY SUBGROUP (during minus pre)\n');
fprintf('==================================================================\n');
fprintf('%-12s %11s %11s %13s %13s\n','group','d exponent','d offset','d raw gamma','d FLAT gamma');
groups = {'CS','Stim';'CS','Sham';'HC','Stim';'HC','Sham'};
for g = 1:size(groups,1)
    sel = strcmp(S2.group,groups{g,1}) & strcmp(S2.condition,groups{g,2});
    if ~any(sel), continue; end
    gg = S2(sel,:);
    fprintf('%-12s %+11.3f %+11.3f %+13.2f %+13.2f\n', ...
        [groups{g,1} ' ' groups{g,2}], mean(gg.d_exponent,'omitnan'), ...
        mean(gg.d_offset,'omitnan'), mean(gg.d_raw_gamma,'omitnan'), ...
        mean(gg.d_flat_gamma,'omitnan'));
end

fprintf('\n  Per subject, CS active stimulation:\n');
fprintf('%-8s %11s %11s %13s %13s\n','subject','d exponent','d offset','d raw gamma','d FLAT gamma');
gg = S2(strcmp(S2.group,'CS') & strcmp(S2.condition,'Stim'),:);
for i = 1:height(gg)
    fprintf('%-8s %+11.3f %+11.3f %+13.2f %+13.2f\n', gg.subject{i}, ...
        gg.d_exponent(i), gg.d_offset(i), gg.d_raw_gamma(i), gg.d_flat_gamma(i));
end

if good
    rg = mean(gg.d_raw_gamma,'omitnan'); fg = mean(gg.d_flat_gamma,'omitnan');
    fprintf('\n------------------------------------------------------------------\n');
    fprintf(' CS active: raw gamma %+.2f dB -> flattened gamma %+.2f dB\n', rg, fg);
    if abs(fg) < 0.5*abs(rg)
        fprintf(' >> The gamma change is largely an APERIODIC shift; little or no\n');
        fprintf('    oscillatory gamma effect remains.\n');
    else
        fprintf(' >> A residual oscillatory gamma change survives.\n');
    end
    fprintf(' Compare against CS Sham: an effect in both is not stimulation-specific.\n');
end
fprintf('==================================================================\n');

end % main

% =========================================================================
function [pxx,f] = psd_across_epochs(D, fs)
% D: time x epochs. PSD of each epoch, averaged. Avoids the discontinuities
% created by concatenating epochs end to end.
if isvector(D), D = D(:); end
nfft = 2^nextpow2(size(D,1));
win  = hamming(size(D,1));
acc = []; f = [];
for e = 1:size(D,2)
    x = D(:,e) - mean(D(:,e));
    [p,f] = pwelch(x, win, 0, nfft, fs);
    if isempty(acc), acc = zeros(numel(p),1); end
    acc = acc + p;
end
pxx = acc / size(D,2);
end

function [expo, offs, r2a, r2f, flatLog, fUse] = ...
         fit_aperiodic(f, pxx, fitRange, notchExcl, nIter, sdK)
f = f(:); pxx = pxx(:);
use = f >= fitRange(1) & f <= fitRange(2) & ...
      ~(f >= notchExcl(1) & f <= notchExcl(2)) & pxx > 0;
fUse = f(use); lf = log10(fUse); lp = log10(pxx(use));

if numel(lf) < 10
    expo=NaN; offs=NaN; r2a=NaN; r2f=NaN; flatLog=nan(size(lp)); return
end

b = polyfit(lf, lp, 1);
keep = true(size(lf));
for it = 1:nIter
    resid = lp - polyval(b, lf);
    % re-derived from ALL points each pass, so the fit cannot run away
    keep = resid < sdK*std(resid);
    if sum(keep) < 10, keep = true(size(lf)); end
    b = polyfit(lf(keep), lp(keep), 1);
end

expo = -b(1); offs = b(2);
fit = polyval(b, lf);
flatLog = lp - fit;

r2a = rsq(lp(keep), fit(keep));   % on aperiodic (retained) points
r2f = rsq(lp, fit);               % on the whole spectrum
end

function r = rsq(y, yhat)
ss_res = sum((y-yhat).^2); ss_tot = sum((y-mean(y)).^2);
if ss_tot == 0, r = NaN; else, r = 1 - ss_res/ss_tot; end
end

function v = bandmean_db(pxx, f, band)
v = 10*log10(mean(pxx(f>=band(1) & f<=band(2))) + eps);
end

function d = dmean(x, sel)
d = mean(x(sel),'omitnan') - mean(x(~sel),'omitnan');
end

function out = ternary(c,a,b)
if c, out = a; else, out = b; end
end

function qc_plot(f, pxx, fUse, flatLog, expo, offs, r2a, ttl, outFile, fitRange, notchExcl)
fh = figure('Color','w','Position',[100 100 900 380],'Visible','off');
subplot(1,2,1);
loglog(f, pxx, 'Color',[.6 .6 .6]); hold on
fitLine = 10.^(offs - expo*log10(fUse));
loglog(fUse, fitLine, 'r-', 'LineWidth', 2);
xlim([1 120]); grid on
xlabel('Frequency (Hz)'); ylabel('PSD');
legend({'spectrum','aperiodic fit'},'Location','southwest','Box','off');
title(sprintf('fit range %g-%g Hz (notch %g-%g excluded)', fitRange, notchExcl), ...
      'FontSize',9,'FontWeight','normal');
hold off

subplot(1,2,2);
semilogx(fUse, 10*flatLog, 'b-', 'LineWidth', 1.3); hold on
plot(xlim,[0 0],'k--'); grid on
xlabel('Frequency (Hz)'); ylabel('flattened power (dB)');
title('after aperiodic removal — peaks are oscillations','FontSize',9,'FontWeight','normal');
hold off

annotation(fh,'textbox',[0 0.94 1 0.06],'String',ttl, ...
    'HorizontalAlignment','center','EdgeColor','none','FontSize',12,'FontWeight','bold');
savefig_compat(fh,outFile); close(fh);
end

function savefig_compat(fh, outFile)
try
    if exist('exportgraphics','file')==2 || exist('exportgraphics','builtin')==5
        exportgraphics(fh, outFile, 'Resolution', 150);
    else
        error('no exportgraphics');
    end
catch
    set(fh,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    print(fh, outFile, '-dpng','-r150');
end
end
