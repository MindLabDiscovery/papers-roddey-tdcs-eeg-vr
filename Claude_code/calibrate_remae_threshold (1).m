function calibrate_remae_threshold(protocolfolder, remaePath, outDir, subject, blockName, phaseIdx)
% CALIBRATE_REMAE_THRESHOLD
%
% Standalone. Loads the data itself - no variables required from
% run_remae_gamma_test.
%
% PURPOSE
%   The first ReMAE run rejected 91.8% of components (all 21 in 10 of 60
%   cells), which destroyed the signal and made the gamma comparison
%   uninterpretable. That happened because the autocorrelation window [0, 0.9]
%   carried over from earlier exploratory work does not transfer to these
%   256 Hz, 0.5 Hz high-passed recordings.
%
%   This script does NOT clean anything. It runs the CCA decomposition and
%   reports the distribution of lag-1 autocorrelation across the 21
%   components, so the threshold can be set from the data rather than guessed.
%
% WHAT TO LOOK FOR
%   - A clear GAP in the sorted values  -> set the upper bound in the gap;
%                                          a threshold rule is defensible.
%   - A smooth continuum, no gap        -> autocorrelation is not separating
%                                          muscle from neural here; switch to
%                                          a fixed-count rejection rule.
%
%   The script also reports, for each candidate threshold, how many
%   components would be rejected and how much gamma / high-band power would
%   be removed - so you can see the consequence before committing.
%
% USAGE
%   calibrate_remae_threshold('D:\...\data_raw', 'D:\...\Data\ReMAE', ...
%                             'C:\Users\ncr200\Downloads')
%   % defaults to subject 0003, block t3 (LS), phase 2 (Prep)
%
%   % or specify:
%   calibrate_remae_threshold(pf, rp, out, 'pro00087153_0043', 't3', 2)
%
% OUTPUT
%   Console report + <outDir>\remae_calibration_<subject>_<block>_<phase>.csv
%   plus a figure showing the sorted autocorrelation values.

if nargin < 3 || isempty(outDir),    outDir = pwd; end
if nargin < 4 || isempty(subject),   subject = 'pro00087153_0003'; end
if nargin < 5 || isempty(blockName), blockName = 't3'; end
if nargin < 6 || isempty(phaseIdx),  phaseIdx = 2; end

phaseNames  = {'Hold','Prep','Move'};
CCA_TLAG    = 1;
GAMMA = [30 50];
HIGH  = [70 100];

% ---- ReMAE on path ------------------------------------------------------
assert(exist(remaePath,'dir')==7,'ReMAE folder not found: %s',remaePath);
addpath(genpath(remaePath));
assert(exist('myCCA','file')==2,'myCCA not found under %s',remaePath);

if exist('autocorr','file') ~= 2
    error(['autocorr() not available. Save autocorr_fallback.m as ' ...
           'autocorr.m on the path first.']);
end

% ---- load the cell ------------------------------------------------------
totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
assert(exist(totalFile,'file')==2,'Not found: %s',totalFile);

fprintf('Loading %s ...\n', totalFile);
S = load(totalFile,'eegevents_tfa');
if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
clear S

assert(isfield(ev.trials,blockName),'Block %s absent',blockName);
wk   = ev.trials.(blockName);
peeg = wk(phaseIdx,:);
assert(~isempty(peeg.setname),'Block/phase empty for this subject');

srate = peeg.srate;
lbls  = {peeg.chanlocs.labels};
nch   = min(21,numel(lbls));
D     = double(peeg.data(1:nch,:,:));
Xc    = reshape(D, nch, []);          % nch x (T*epochs)
clear ev

fprintf('Subject %s | block %s | phase %s\n', subject, blockName, phaseNames{phaseIdx});
fprintf('  %d channels, %d samples (%d epochs x %d), %g Hz\n\n', ...
        nch, size(Xc,2), size(D,3), size(D,2), srate);

% ---- CCA decomposition --------------------------------------------------
fprintf('Running myCCA ...\n');
[Comp, B, WC] = myCCA(Xc, srate, CCA_TLAG); %#ok<ASGLU>
nComp = size(Comp,1);

% ---- lag-1 autocorrelation of every component ---------------------------
ac = nan(1,nComp);
for k = 1:nComp
    a = autocorr(real(Comp(k,:)));
    ac(k) = abs(a(1,2));            % ReMAE uses element (1,2) = lag 1
end

[acSorted, ord] = sort(ac,'ascend');

fprintf('\n==================================================================\n');
fprintf(' LAG-1 AUTOCORRELATION BY COMPONENT (sorted ascending)\n');
fprintf(' Muscle components should sit at the LOW end.\n');
fprintf('==================================================================\n');
fprintf('%6s %12s %14s %14s\n','rank','component','|autocorr|','gap to next');
for i = 1:nComp
    if i < nComp, gap = acSorted(i+1)-acSorted(i); gs = sprintf('%14.4f',gap);
    else,         gs = sprintf('%14s','-');
    end
    fprintf('%6d %12d %14.4f %s\n', i, ord(i), acSorted(i), gs);
end

gaps = diff(acSorted);
[maxGap, gi] = max(gaps);
fprintf('\n  largest gap: %.4f, between rank %d (%.4f) and rank %d (%.4f)\n', ...
        maxGap, gi, acSorted(gi), gi+1, acSorted(gi+1));
fprintf('  midpoint of that gap: %.4f\n', mean(acSorted(gi:gi+1)));
fprintf('  range: %.4f to %.4f\n', min(ac), max(ac));

if maxGap < 0.05
    fprintf('\n  >> NO CLEAR GAP (largest is %.4f). Autocorrelation is not\n', maxGap);
    fprintf('     separating two populations here. A fixed-count rejection\n');
    fprintf('     rule is more defensible than a threshold.\n');
else
    fprintf('\n  >> Candidate threshold: acthreshold2 = %.3f\n', mean(acSorted(gi:gi+1)));
    fprintf('     (rejects the %d lowest-autocorrelation components)\n', gi);
end

% ---- consequence of each candidate threshold ----------------------------
fprintf('\n==================================================================\n');
fprintf(' CONSEQUENCE OF EACH CANDIDATE THRESHOLD\n');
fprintf(' Power change measured on the anodal-side central channel.\n');
fprintf('==================================================================\n');

iC3 = find(strcmpi(lbls,'C3'),1);
iC4 = find(strcmpi(lbls,'C4'),1);
iRef = iC3; refName = 'C3';
if isempty(iRef), iRef = iC4; refName = 'C4'; end

g0 = bandpow(Xc(iRef,:), srate, GAMMA);
h0 = bandpow(Xc(iRef,:), srate, HIGH);
fprintf('  uncleaned %s: gamma %.2f dB, high %.2f dB\n\n', refName, g0, h0);

fprintf('%10s %10s %12s %12s %12s %12s\n', ...
        'threshold','n_reject','pct','gamma dB','high dB','g-h');
cand = [0.30 0.40 0.50 0.60 0.70 0.80 0.90];
if maxGap >= 0.05, cand = sort([cand mean(acSorted(gi:gi+1))]); end

rows = {};
for c = cand
    keep = ac >= c;                 % ReMAE zeroes components BELOW threshold2
    nRej = sum(~keep);
    if nRej == nComp
        fprintf('%10.3f %10d %11.0f%% %12s %12s %12s\n', c, nRej, 100, ...
                'ALL ZEROED','-','-');
        rows(end+1,:) = {c,nRej,100*nRej/nComp,NaN,NaN,NaN}; %#ok<AGROW>
        continue
    end
    Cz = Comp; Cz(~keep,:) = 0;
    Y  = real(inv(WC{1,1}') * inv(B(:,:,1)) * Cz);
    g  = bandpow(Y(iRef,:), srate, GAMMA);
    h  = bandpow(Y(iRef,:), srate, HIGH);
    fprintf('%10.3f %10d %11.0f%% %12.2f %12.2f %12.2f\n', ...
            c, nRej, 100*nRej/nComp, g, h, g-h);
    rows(end+1,:) = {c,nRej,100*nRej/nComp,g,h,g-h}; %#ok<AGROW>
end

fprintf('\n  A usable threshold rejects SOME but not all components and\n');
fprintf('  reduces the high band more than gamma (g-h becomes less negative).\n');

% ---- fixed-count alternative -------------------------------------------
fprintf('\n==================================================================\n');
fprintf(' FIXED-COUNT ALTERNATIVE (reject k lowest-autocorrelation comps)\n');
fprintf('==================================================================\n');
fprintf('%10s %12s %12s %12s\n','k','gamma dB','high dB','g-h');
for k = [2 3 4 5 6 8 10]
    if k >= nComp, continue; end
    Cz = Comp; Cz(ord(1:k),:) = 0;
    Y  = real(inv(WC{1,1}') * inv(B(:,:,1)) * Cz);
    g  = bandpow(Y(iRef,:), srate, GAMMA);
    h  = bandpow(Y(iRef,:), srate, HIGH);
    fprintf('%10d %12.2f %12.2f %12.2f\n', k, g, h, g-h);
end

% ---- save ---------------------------------------------------------------
if ~exist(outDir,'dir'), mkdir(outDir); end
T = cell2table(rows,'VariableNames', ...
    {'threshold','n_rejected','pct_rejected','gamma_dB','high_dB','gamma_minus_high'});
csvOut = fullfile(outDir, sprintf('remae_calibration_%s_%s_%s.csv', ...
                  subject(end-3:end), blockName, phaseNames{phaseIdx}));
writetable(T,csvOut);

Tac = table((1:nComp)', ord(:), acSorted(:), ...
            'VariableNames',{'rank','component','abs_autocorr_lag1'});
acOut = fullfile(outDir, sprintf('remae_components_%s_%s_%s.csv', ...
                 subject(end-3:end), blockName, phaseNames{phaseIdx}));
writetable(Tac,acOut);

fprintf('\nWritten:\n  %s\n  %s\n', csvOut, acOut);

% ---- figure -------------------------------------------------------------
fh = figure('Color','w','Position',[100 100 900 380],'Visible','off');
subplot(1,2,1);
stem(1:nComp, acSorted, 'filled'); grid on
xlabel('component (sorted)'); ylabel('|lag-1 autocorrelation|');
title(sprintf('%s %s %s', subject(end-3:end), blockName, phaseNames{phaseIdx}));
hold on
if maxGap >= 0.05
    yline_compat(mean(acSorted(gi:gi+1)));
end
hold off

subplot(1,2,2);
histogram(ac, max(5,round(nComp/3))); grid on
xlabel('|lag-1 autocorrelation|'); ylabel('count');
title('distribution (two clusters => threshold works)');

figOut = fullfile(outDir, sprintf('remae_calibration_%s_%s_%s.png', ...
                  subject(end-3:end), blockName, phaseNames{phaseIdx}));
savefig_compat(fh, figOut); close(fh);
fprintf('  %s\n', figOut);

end % main

% =========================================================================
function p = bandpow(x, fs, band)
x = double(x(:))' - mean(x);
[pxx,f] = pwelch(x, hamming(min(fs,numel(x))), [], [], fs);
p = 10*log10(mean(pxx(f>=band(1) & f<=band(2))) + eps);
end

function yline_compat(y)
xl = xlim;
plot(xl, [y y], 'r--', 'LineWidth', 1.5);
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
