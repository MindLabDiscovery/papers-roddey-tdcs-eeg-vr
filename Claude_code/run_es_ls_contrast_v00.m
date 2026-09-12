function run_es_ls_contrast(protocolfolder, outPrefix, kinCsv)
% RUN_ES_LS_CONTRAST
%
% Contrasts EARLY stimulation (ES) against LATE stimulation (LS), rather than
% stimulation against rest.
%
% WHY THIS CONTRAST IS BETTER
%   The during-vs-rest comparison used everywhere else in this project is
%   confounded: stimulation-on and stimulation-off differ in the artifact
%   itself, so any spectral difference is uninterpretable. ES and LS both have
%   current flowing, so the gross stimulation artifact is present in both and
%   largely subtracts out.
%
%   It is also temporally matched to the behavioural effect: maximum
%   acceleration improved from ES to LS (p = 0.0095). Contrasting the EEG over
%   the same interval aligns the neural question to the behavioural one.
%
% THE ARTIFACT IS NOT ASSUMED CONSTANT
%   Impedance drifts as gel dries, electrode polarization evolves, and subject
%   state changes. So an ES-LS residual of exactly zero is NOT expected even
%   under a pure-artifact model, and a non-zero residual does not by itself
%   demonstrate a neural effect.
%
%   The informative question is whether the residual is BAND-LIMITED or
%   BROADBAND:
%       broadband residual              -> evolving artifact / aperiodic shift
%       peak confined to a band, above
%       the aperiodic fit               -> oscillatory change
%
% THE CONTROL
%   In sham, the ES and LS blocks are time-matched but carry no current. So
%       (ES->LS change in CS active) - (ES->LS change in CS sham)
%   is a difference-in-differences isolating stimulation-duration-dependent
%   change from session drift, practice and fatigue.
%
% USAGE
%   run_es_ls_contrast('D:\...\data_raw','C:\...\esls')
%   run_es_ls_contrast(pf,'C:\...\esls','C:\...\kinematics.csv')
%
% OPTIONAL KINEMATICS FILE (kinCsv)
%   A CSV with a 'subject' column (4-digit ID as text, e.g. 0003) plus EITHER
%       d_maxaccel                      (LS minus ES change), OR
%       maxaccel_ES  and  maxaccel_LS   (the script differences them)
%   Any additional numeric columns are correlated too. If omitted, the EEG
%   side is still written and can be joined later.
%
% OUTPUT
%   <outPrefix>_psd.csv       frequency-resolved ES, LS and difference
%   <outPrefix>_summary.csv   per subject: band changes, aperiodic params
%   <outPrefix>_curves.png    group mean difference curves + DiD
%   Console: band-wise DiD, and kinematic correlation with a
%            leave-one-out influence check.

if nargin < 2 || isempty(outPrefix), outPrefix = 'esls'; end
if nargin < 3, kinCsv = ''; end

[outDir,~,~] = fileparts(outPrefix);
if isempty(outDir), outDir = pwd; end
if ~exist(outDir,'dir'), mkdir(outDir); end

% ---- configuration ------------------------------------------------------
FIT_RANGE  = [7 40];      % starts at 7 Hz to clear tDCS low-frequency drift
NOTCH_EXCL = [48 72];
BANDS = {'delta',[1 4]; 'theta',[4 8]; 'alpha',[8 12]; ...
         'beta',[13 30]; 'lowgamma',[30 45]};
PLOT_FMAX = 45;

% CS only: the anode side is known for these subjects (Table 1).
roster = {
 'pro00087153_0003','Stim','C3'; 'pro00087153_0004','Stim','C3'
 'pro00087153_0005','Stim','C4'; 'pro00087153_0042','Stim','C4'
 'pro00087153_0043','Stim','C3'
 'pro00087153_0013','Sham','C4'; 'pro00087153_0015','Sham','C3'
 'pro00087153_0017','Sham','C4'; 'pro00087153_0018','Sham','C4'
 'pro00087153_0021','Sham','C4'
};

ES_BLOCK = 't2'; LS_BLOCK = 't3';

% ---- accumulators -------------------------------------------------------
psdRows = {};   sumRows = {};
curveF = []; curveDiff = struct('Stim',[],'Sham',[]);

fprintf('ES -> LS contrast, %d chronic stroke subjects\n', size(roster,1));
fprintf('  anodal channel; aperiodic fit %g-%g Hz (starts above tDCS drift)\n\n', FIT_RANGE);

for s = 1:size(roster,1)

    subject = roster{s,1}; cond = roster{s,2}; anode = roster{s,3};
    contra  = ternary(strcmpi(anode,'C3'),'C4','C3');
    sid = subject(end-3:end);

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING -- skipped\n', subject); continue
    end
    fprintf('  %s (%s, anode %s) ... ', subject, cond, anode);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n', ME.message); continue
    end

    [pES, f, labels] = block_psd(ev, ES_BLOCK);
    [pLS, ~, ~]      = block_psd(ev, LS_BLOCK);
    clear ev

    if isempty(pES) || isempty(pLS)
        fprintf('missing ES or LS block\n'); continue
    end

    iA = find(strcmpi(labels,anode),1);
    iC = find(strcmpi(labels,contra),1);
    iZ = find(strcmpi(labels,'Cz'),1);
    if isempty(iA), fprintf('anode channel absent\n'); continue; end

    for whichCh = 1:3
        switch whichCh
            case 1, idx = iA; role = 'anodal';        nm = anode;
            case 2, idx = iC; role = 'contralateral'; nm = contra;
            case 3, idx = iZ; role = 'Cz';            nm = 'Cz';
        end
        if isempty(idx), continue; end

        es = pES(:,idx); ls = pLS(:,idx);
        esDb = 10*log10(es+eps); lsDb = 10*log10(ls+eps);
        dDb  = lsDb - esDb;

        % frequency-resolved rows (anodal only, to keep the file manageable)
        if whichCh == 1
            keepF = f <= PLOT_FMAX;
            ff = f(keepF); dd = dDb(keepF);
            for q = 1:numel(ff)
                psdRows(end+1,:) = {sid, cond, nm, ff(q), ...
                    esDb(find(keepF,1)+q-1), lsDb(find(keepF,1)+q-1), dd(q)}; %#ok<AGROW>
            end
            if isempty(curveF), curveF = ff; end
            if numel(dd) == numel(curveF)
                curveDiff.(cond) = [curveDiff.(cond), dd(:)];
            end
        end

        % band changes (raw)
        bandVals = nan(1,size(BANDS,1));
        for bnd = 1:size(BANDS,1)
            r = BANDS{bnd,2};
            bandVals(bnd) = mean(dDb(f>=r(1) & f<=r(2)));
        end

        % aperiodic decomposition at ES and LS
        [expES, offES, r2ES, flatES, fU] = fit_aperiodic(f, es, FIT_RANGE, NOTCH_EXCL);
        [expLS, offLS, r2LS, flatLS, ~ ] = fit_aperiodic(f, ls, FIT_RANGE, NOTCH_EXCL);

        % flattened (oscillatory-only) band changes
        flatVals = nan(1,size(BANDS,1));
        for bnd = 1:size(BANDS,1)
            r = BANDS{bnd,2};
            m = fU>=r(1) & fU<=r(2);
            if any(m), flatVals(bnd) = 10*(mean(flatLS(m)) - mean(flatES(m))); end
        end

        sumRows(end+1,:) = [{sid, cond, role, nm, ...
            expLS-expES, offLS-offES, min(r2ES,r2LS)}, ...
            num2cell(bandVals), num2cell(flatVals)]; %#ok<AGROW>
    end
    fprintf('done\n');
end

if isempty(sumRows), error('No subjects processed. Check protocolfolder: %s', protocolfolder); end

% ---- write tables -------------------------------------------------------
P = cell2table(psdRows,'VariableNames', ...
    {'subject','condition','channel','freq','ES_dB','LS_dB','diff_dB'});
writetable(P,[outPrefix '_psd.csv']);

rawNames  = strcat('d_',BANDS(:,1)');
flatNames = strcat('dflat_',BANDS(:,1)');
S2 = cell2table(sumRows,'VariableNames', ...
    [{'subject','condition','role','channel','d_exponent','d_offset','min_r2'}, ...
      rawNames, flatNames]);
writetable(S2,[outPrefix '_summary.csv']);

fprintf('\nWritten: %s_psd.csv (%d rows)\n', outPrefix, height(P));
fprintf('Written: %s_summary.csv (%d rows)\n', outPrefix, height(S2));

A = S2(strcmp(S2.role,'anodal'),:);

% ---- fit quality --------------------------------------------------------
fprintf('\n==================================================================\n');
fprintf(' FIT QUALITY (aperiodic, %g-%g Hz)\n', FIT_RANGE);
fprintf('==================================================================\n');
fprintf('  min R^2 across ES/LS fits: mean %.3f, worst %.3f\n', ...
    mean(A.min_r2,'omitnan'), min(A.min_r2));
if mean(A.min_r2,'omitnan') < 0.90
    fprintf('  >> Fits still imperfect; treat the aperiodic columns as provisional.\n');
end

% ---- band-wise difference in differences --------------------------------
fprintf('\n==================================================================\n');
fprintf(' ES -> LS CHANGE, ANODAL CHANNEL (dB)\n');
fprintf(' DiD = active minus sham. Positive = larger change under stimulation.\n');
fprintf('==================================================================\n');
fprintf('%-10s %10s %10s %10s   %10s %10s %10s\n', ...
        'band','RAW act','RAW sham','RAW DiD','FLAT act','FLAT sham','FLAT DiD');
for bnd = 1:size(BANDS,1)
    rn = rawNames{bnd}; fn = flatNames{bnd};
    ra = mean(A.(rn)(strcmp(A.condition,'Stim')),'omitnan');
    rs = mean(A.(rn)(strcmp(A.condition,'Sham')),'omitnan');
    fa = mean(A.(fn)(strcmp(A.condition,'Stim')),'omitnan');
    fs = mean(A.(fn)(strcmp(A.condition,'Sham')),'omitnan');
    fprintf('%-10s %+10.2f %+10.2f %+10.2f   %+10.2f %+10.2f %+10.2f\n', ...
        BANDS{bnd,1}, ra, rs, ra-rs, fa, fs, fa-fs);
end
fprintf('\n  RAW includes the aperiodic component; FLAT is oscillatory only.\n');
fprintf('  A DiD present in RAW but absent in FLAT is a broadband/aperiodic\n');
fprintf('  change, not an oscillatory one.\n');

fprintf('\n  Aperiodic: d_exponent  active %+.3f, sham %+.3f  (DiD %+.3f)\n', ...
    mean(A.d_exponent(strcmp(A.condition,'Stim')),'omitnan'), ...
    mean(A.d_exponent(strcmp(A.condition,'Sham')),'omitnan'), ...
    mean(A.d_exponent(strcmp(A.condition,'Stim')),'omitnan') - ...
    mean(A.d_exponent(strcmp(A.condition,'Sham')),'omitnan'));
fprintf('             d_offset    active %+.3f, sham %+.3f  (DiD %+.3f)\n', ...
    mean(A.d_offset(strcmp(A.condition,'Stim')),'omitnan'), ...
    mean(A.d_offset(strcmp(A.condition,'Sham')),'omitnan'), ...
    mean(A.d_offset(strcmp(A.condition,'Stim')),'omitnan') - ...
    mean(A.d_offset(strcmp(A.condition,'Sham')),'omitnan'));

% ---- per-subject table --------------------------------------------------
fprintf('\n  Per subject (anodal channel), ES -> LS:\n');
fprintf('%-8s %-6s %10s %10s %12s %12s\n','subject','cond','d_beta','d_lowgamma','dflat_beta','dflat_lgamma');
for i = 1:height(A)
    fprintf('%-8s %-6s %+10.2f %+10.2f %+12.2f %+12.2f\n', ...
        A.subject{i}, A.condition{i}, A.d_beta(i), A.d_lowgamma(i), ...
        A.dflat_beta(i), A.dflat_lowgamma(i));
end

% ---- figure -------------------------------------------------------------
try
    plot_curves(curveF, curveDiff, outDir, outPrefix, BANDS);
    fprintf('\nWritten: %s_curves.png\n', outPrefix);
catch ME
    fprintf('\n(figure skipped: %s)\n', ME.message);
end

% ---- kinematic correlation ---------------------------------------------
if ~isempty(kinCsv) && exist(kinCsv,'file')==2
    fprintf('\n==================================================================\n');
    fprintf(' EEG - KINEMATIC RELATIONSHIP (ES -> LS, active stimulation)\n');
    fprintf('==================================================================\n');
    K = readtable(kinCsv);
    K.subject = pad_ids(K.subject);

    if ismember('d_maxaccel', K.Properties.VariableNames)
        kin = K.d_maxaccel; kinName = 'd_maxaccel';
    elseif all(ismember({'maxaccel_ES','maxaccel_LS'}, K.Properties.VariableNames))
        kin = K.maxaccel_LS - K.maxaccel_ES; kinName = 'maxaccel LS-ES';
    else
        kin = []; kinName = '';
        fprintf('  Could not find d_maxaccel or maxaccel_ES/maxaccel_LS.\n');
    end

    if ~isempty(kin)
        act = A(strcmp(A.condition,'Stim'),:);
        eegVars = [rawNames flatNames {'d_exponent','d_offset'}];
        fprintf('%-18s %8s %10s %28s\n','EEG measure','r','n','leave-one-out r range');
        for v = 1:numel(eegVars)
            x = []; y = [];
            for i = 1:height(act)
                j = find(strcmp(K.subject, act.subject{i}),1);
                if isempty(j), continue; end
                x(end+1) = act.(eegVars{v})(i); %#ok<AGROW>
                y(end+1) = kin(j);              %#ok<AGROW>
            end
            if numel(x) < 4, continue; end
            r = corr_simple(x,y);
            loo = nan(1,numel(x));
            for d = 1:numel(x)
                m = true(1,numel(x)); m(d) = false;
                loo(d) = corr_simple(x(m), y(m));
            end
            fprintf('%-18s %+8.3f %10d %13.3f to %+8.3f\n', ...
                eegVars{v}, r, numel(x), min(loo), max(loo));
        end
        fprintf('\n  Kinematic variable: %s\n', kinName);
        fprintf('  The leave-one-out range is the important column. With n=5 a\n');
        fprintf('  correlation whose sign flips when one subject is dropped is\n');
        fprintf('  not a finding. This is the check Reviewer 1 asked for.\n');
    end
else
    fprintf('\n(no kinematics file supplied - EEG side written for later joining)\n');
    fprintf(' Expected format: a CSV with a subject column (0003, 0004, ...) and\n');
    fprintf(' either d_maxaccel, or maxaccel_ES and maxaccel_LS.\n');
end
fprintf('==================================================================\n');

end % main

% =========================================================================
function [P, f, labels] = block_psd(ev, blockName)
P = []; f = []; labels = {};
if ~isfield(ev.trials, blockName), return; end
wk = ev.trials.(blockName);
Ecat = []; srate = NaN;
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
if isempty(Ecat), return; end
for c = 1:numel(labels)
    [pxx,f] = psd_across_epochs(squeeze(Ecat(c,:,:)), srate);
    if isempty(P), P = nan(numel(pxx), numel(labels)); end
    P(:,c) = pxx;
end
end

function [pxx,f] = psd_across_epochs(D, fs)
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

function [expo, offs, r2, flatLog, fUse] = fit_aperiodic(f, pxx, fitRange, notchExcl)
f = f(:); pxx = pxx(:);
use = f>=fitRange(1) & f<=fitRange(2) & ~(f>=notchExcl(1) & f<=notchExcl(2)) & pxx>0;
fUse = f(use); lf = log10(fUse); lp = log10(pxx(use));
if numel(lf) < 8
    expo=NaN; offs=NaN; r2=NaN; flatLog=nan(size(lp)); return
end
b = polyfit(lf,lp,1); keep = true(size(lf));
for it = 1:3
    resid = lp - polyval(b,lf);
    keep = resid < 2.0*std(resid);          % re-derived from all points
    if sum(keep) < 8, keep = true(size(lf)); end
    b = polyfit(lf(keep),lp(keep),1);
end
expo = -b(1); offs = b(2);
fit = polyval(b,lf); flatLog = lp - fit;
ss_res = sum((lp(keep)-fit(keep)).^2); ss_tot = sum((lp(keep)-mean(lp(keep))).^2);
if ss_tot==0, r2 = NaN; else, r2 = 1 - ss_res/ss_tot; end
end

function plot_curves(f, D, outDir, outPrefix, BANDS) %#ok<INUSD>
fh = figure('Color','w','Position',[100 100 1050 420],'Visible','off');

subplot(1,2,1); hold on
cols = struct('Stim',[0.85 0.20 0.20],'Sham',[0.30 0.30 0.75]);
h = []; nm = {};
for c = {'Stim','Sham'}
    M = D.(c{1});
    if isempty(M), continue; end
    mu = mean(M,2); se = std(M,0,2)/sqrt(size(M,2));
    fill([f(:); flipud(f(:))],[mu-se; flipud(mu+se)], cols.(c{1}), ...
         'FaceAlpha',0.15,'EdgeColor','none');
    hh = plot(f, mu, 'Color', cols.(c{1}), 'LineWidth', 1.8);
    h(end+1) = hh; nm{end+1} = sprintf('CS %s (n=%d)', c{1}, size(M,2)); %#ok<AGROW>
end
plot(xlim,[0 0],'k--'); grid on
xlabel('Frequency (Hz)'); ylabel('LS - ES (dB)');
title('ES \rightarrow LS spectral change, anodal channel');
if ~isempty(h), legend(h, nm, 'Location','best','Box','off'); end
hold off

subplot(1,2,2); hold on
if ~isempty(D.Stim) && ~isempty(D.Sham)
    did = mean(D.Stim,2) - mean(D.Sham,2);
    plot(f, did, 'k-', 'LineWidth', 2);
    plot(xlim,[0 0],'k--');
end
grid on; xlabel('Frequency (Hz)'); ylabel('DiD (dB)');
title('Difference in differences: active - sham');
hold off

savefig_compat(fh, fullfile(outDir, [gettail(outPrefix) '_curves.png']));
close(fh);
end

function t = gettail(p)
[~,n,~] = fileparts(p); t = n;
end

function ids = pad_ids(x)
if isnumeric(x)
    ids = arrayfun(@(v) sprintf('%04d',v), x, 'UniformOutput', false);
elseif iscell(x)
    ids = cellfun(@(v) sprintf('%04d', str2double(regexprep(num2str(v),'\D',''))), ...
                  x, 'UniformOutput', false);
else
    ids = cellstr(x);
end
end

function r = corr_simple(x,y)
x = double(x(:)); y = double(y(:));
ok = ~isnan(x) & ~isnan(y); x = x(ok); y = y(ok);
if numel(x) < 3, r = NaN; return; end
x = x - mean(x); y = y - mean(y);
d = sqrt(sum(x.^2)*sum(y.^2));
if d==0, r = NaN; else, r = sum(x.*y)/d; end
end

function out = ternary(c,a,b)
if c, out = a; else, out = b; end
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
