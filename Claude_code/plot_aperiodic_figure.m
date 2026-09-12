%% plot_aperiodic_figure.m
%
% PURPOSE
%   Show, visually, that the stimulation-related change in gamma-range power
%   is a shift in the aperiodic component rather than a narrowband
%   oscillation.
%
%   Three panels per group:
%     (1) raw power spectra with the fitted aperiodic component overlaid
%     (2) the flattened spectra, i.e. observed minus fitted
%     (3) the stimulation-related change, raw and flattened, side by side
%
%   A genuine oscillation survives flattening as a positive residual peak.
%   A broadband shift does not. Panel 3 is the one that carries the claim.
%
% CONTRASTS
%   Set CONTRAST below.
%     'BLvsSTIM' - baseline against stimulation (ES and LS pooled). This is
%                  the contrast the manuscript's aperiodic claim refers to.
%     'ESvsLS'   - early against late stimulation, the artifact-controlled
%                  contrast used elsewhere.
%
% FIT
%   Least squares of power (dB) on log10(frequency) over FIT_RANGE,
%   excluding line noise. Lower bound is 10 Hz: direct-current drift
%   dominates below that during stimulation and biases the slope.
%
% OUTPUT
%   fig_aperiodic_<contrast>.png / .svg
%   aperiodic_values.csv   per subject: exponent, offset, flattened peak
%                          and its frequency, raw and flattened band change
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'aperiodic_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

CONTRAST   = 'BLvsSTIM';    % 'BLvsSTIM' | 'ESvsLS'
PRIMARY_PHASE = 3;          % 1 hold, 2 prep, 3 move
FIT_RANGE  = [10 50];
LINE_NOISE = [58 62];
GAMMA      = [30 50];
PEAK_RANGE = [25 50];
TIME_BINS  = 9:60;

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','stim';'CS','sham';'HC','stim';'HC','sham'};

C1 = [0.20 0.20 0.20];   % condition A (baseline / ES)
C2 = [0.80 0.20 0.20];   % condition B (stimulation / LS)
CF = [0.15 0.35 0.75];   % fitted aperiodic

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};
p1 = sd(1).power; fvec = squeeze(p1.freq(1,:,1));
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;
fprintf('freq %.2f-%.2f Hz | units %s | contrast %s\n\n', ...
    min(fvec), max(fvec), tern(IS_DB,'dB','linear->dB'), CONTRAST);

chanlabels = cell(1,numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');    chanlabels{c}=p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label'); chanlabels{c}=p1.chans(c).label;
    else;                                chanlabels{c}=sprintf('ch%d',c); end
end

switch CONTRAST
    case 'BLvsSTIM', blkA = 1;   blkB = [2 3]; labA = 'baseline'; labB = 'stimulation';
    case 'ESvsLS',   blkA = 2;   blkB = 3;     labA = 'early stim'; labB = 'late stim';
    otherwise, error('CONTRAST must be BLvsSTIM or ESvsLS');
end

%% ==================== EXTRACT + FIT ============================
R = struct(); n = 0; rows = {};
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    si = sd(mi).sessioninfo;
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='stim'; end
    grp = 'HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    anode = tern(strcmp(sl,'L'),'C3','C4');
    ci = find(strcmpi(chanlabels,anode),1);
    if isempty(ci); continue; end

    A = zeros(numel(fvec),1); B = A;
    for t = blkA
        x = sd(mi).power.data(:,TIME_BINS,ci,PRIMARY_PHASE,t);
        if ~IS_DB; x = 10*log10(x); end
        A = A + mean(x,2,'omitnan');
    end
    A = A/numel(blkA);
    for t = blkB
        x = sd(mi).power.data(:,TIME_BINS,ci,PRIMARY_PHASE,t);
        if ~IS_DB; x = 10*log10(x); end
        B = B + mean(x,2,'omitnan');
    end
    B = B/numel(blkB);

    [Af, apA] = flatten_psd(fvec, A, FIT_RANGE, LINE_NOISE);
    [Bf, apB] = flatten_psd(fvec, B, FIT_RANGE, LINE_NOISE);

    n = n+1;
    R(n).sid=sid; R(n).grp=grp; R(n).cond=cond; R(n).anode=anode;
    R(n).A=A; R(n).B=B; R(n).Af=Af; R(n).Bf=Bf;
    R(n).fitA=apA.pred; R(n).fitB=apB.pred;

    gm = fvec>=GAMMA(1) & fvec<=GAMMA(2);
    pk = fvec>=PEAK_RANGE(1) & fvec<=PEAK_RANGE(2);
    dflat = Bf - Af;
    [pv,pi_] = max(dflat(pk)); fpk = fvec(pk);
    rows(end+1,:) = { sid, grp, cond, anode, ...
        apA.slope, apB.slope, apB.slope-apA.slope, ...
        apA.intercept, apB.intercept, apB.intercept-apA.intercept, ...
        mean(B(gm),'omitnan')-mean(A(gm),'omitnan'), ...
        mean(dflat(gm),'omitnan'), pv, fpk(pi_) }; %#ok<AGROW>
end
R = R(1:n);

T = cell2table(rows,'VariableNames', ...
    {'SubjectID','Group','Condition','Anode','ApExp_A','ApExp_B','ApExp_delta', ...
     'ApOffset_A','ApOffset_B','ApOffset_delta', ...
     'gamma_raw_change','gamma_flat_change','FlatPeak_value','FlatPeak_Hz'});
writetable(T, fullfile(OUT_DIR,'aperiodic_values.csv'));

%% ==================== CONSOLE =================================
fprintf('=== Gamma-range change (%s minus %s), anodal electrode ===\n', labB, labA);
fprintf('%-14s %6s %12s %12s %12s %10s\n', ...
    'cell','n','raw (dB)','flattened','d offset','peak Hz');
for c = 1:size(cells,1)
    m = strcmp(T.Group,cells{c,1}) & strcmp(T.Condition,cells{c,2});
    if ~any(m); continue; end
    fprintf('%-14s %6d %+12.3f %+12.3f %+12.3f %10.1f\n', ...
        [cells{c,1} ' ' cells{c,2}], sum(m), ...
        mean(T.gamma_raw_change(m)), mean(T.gamma_flat_change(m)), ...
        mean(T.ApOffset_delta(m)), mean(T.FlatPeak_Hz(m)));
end
nEdge = sum(abs(T.FlatPeak_Hz - max(fvec)) < 0.51);
fprintf(['\n%d of %d participants had the maximum of the flattened spectrum at\n' ...
         'the upper limit of the frequency axis (%.0f Hz) rather than at a\n' ...
         'spectral feature -- the signature of no narrowband peak.\n'], ...
         nEdge, height(T), max(fvec));

%% ==================== FIGURE ==================================
fh = figure('Position',[30 30 1320 760],'Visible','off');
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    mA  = mean(cell2mat(arrayfun(@(k)R(k).A(:),  idx,'UniformOutput',false)),2,'omitnan');
    mB  = mean(cell2mat(arrayfun(@(k)R(k).B(:),  idx,'UniformOutput',false)),2,'omitnan');
    fA  = mean(cell2mat(arrayfun(@(k)R(k).fitA(:),idx,'UniformOutput',false)),2,'omitnan');
    fB  = mean(cell2mat(arrayfun(@(k)R(k).fitB(:),idx,'UniformOutput',false)),2,'omitnan');
    mAf = mean(cell2mat(arrayfun(@(k)R(k).Af(:), idx,'UniformOutput',false)),2,'omitnan');
    mBf = mean(cell2mat(arrayfun(@(k)R(k).Bf(:), idx,'UniformOutput',false)),2,'omitnan');

    ok = fvec>=FIT_RANGE(1) & fvec<=FIT_RANGE(2);

    % (1) raw + fitted aperiodic
    subplot(3,4,c); hold on
    plot(fvec(ok), mA(ok), 'Color',C1,'LineWidth',1.5);
    plot(fvec(ok), mB(ok), 'Color',C2,'LineWidth',1.5);
    plot(fvec(ok), fA(ok), '--','Color',CF,'LineWidth',1.2);
    plot(fvec(ok), fB(ok), ':','Color',CF,'LineWidth',1.4);
    set(gca,'XScale','log'); grid on; xlim(FIT_RANGE);
    title(sprintf('%s %s',cells{c,1},cells{c,2}),'FontSize',9);
    if c==1
        ylabel('power (dB)');
        legend({labA,labB,'fit A','fit B'},'Location','best','FontSize',6);
    end

    % (2) flattened spectra
    subplot(3,4,4+c); hold on
    plot(fvec(ok), mAf(ok), 'Color',C1,'LineWidth',1.5);
    plot(fvec(ok), mBf(ok), 'Color',C2,'LineWidth',1.5);
    plot(FIT_RANGE,[0 0],'k--','HandleVisibility','off');
    shade_(GAMMA,[0.95 0.90 0.55]); grid on; xlim(FIT_RANGE);
    if c==1; ylabel('flattened (dB)'); end
    title('observed minus fitted','FontSize',8);

    % (3) change, raw vs flattened
    subplot(3,4,8+c); hold on
    plot(fvec(ok), mB(ok)-mA(ok),   'Color',[0.5 0.1 0.1],'LineWidth',1.6);
    plot(fvec(ok), mBf(ok)-mAf(ok), 'Color',[0.1 0.4 0.2],'LineWidth',1.6);
    plot(FIT_RANGE,[0 0],'k--','HandleVisibility','off');
    shade_(GAMMA,[0.95 0.90 0.55]); grid on; xlim(FIT_RANGE);
    xlabel('Hz'); if c==1
        ylabel('change (dB)');
        legend({'raw','flattened'},'Location','best','FontSize',6);
    end
    title('change: raw vs flattened','FontSize',8);
end
sgt(sprintf(['Aperiodic decomposition, anodal electrode, %s phase. ' ...
    'A narrowband oscillation would survive flattening; a broadband shift does not.'], ...
    tern(PRIMARY_PHASE==3,'move',num2str(PRIMARY_PHASE))));
savefig_both(fh, fullfile(OUT_DIR,sprintf('fig_aperiodic_%s.png',CONTRAST)));

fprintf('\nWrote %s\n', OUT_DIR);
fprintf('Row 3 carries the claim: if the green trace sits near zero in the\n');
fprintf('shaded band while the red trace is displaced, the change is aperiodic.\n');

%% ==================== LOCAL FUNCTIONS =========================
function [flat, ap] = flatten_psd(f, psd, fit_range, line_noise)
f = f(:); psd = psd(:);
m = f>=fit_range(1) & f<=fit_range(2) & isfinite(psd) & f>0;
m = m & ~(f>=line_noise(1) & f<=line_noise(2));
ap = struct('slope',NaN,'intercept',NaN,'r2',NaN,'pred',nan(size(psd)));
if sum(m) < 5; flat = nan(size(psd)); return; end
X = [ones(sum(m),1), log10(f(m))];
b = X \ psd(m);
ap.intercept=b(1); ap.slope=b(2);
res = psd(m) - X*b;
ap.r2 = 1 - sum(res.^2)/sum((psd(m)-mean(psd(m))).^2);
pred = nan(size(psd)); v = f>0;
pred(v) = b(1) + b(2)*log10(f(v));
ap.pred = pred;
flat = psd - pred;
end

function shade_(rng,col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)],[yl(1) yl(1) yl(2) yl(2)],col, ...
    'FaceAlpha',0.28,'EdgeColor','none','HandleVisibility','off');
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt,'FontSize',10);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function savefig_both(fh, pngpath)
print(fh, pngpath, '-dpng','-r150');
[d,nn,~] = fileparts(pngpath);
try
    print(fh, fullfile(d,[nn '.svg']), '-dsvg');
catch
end
close(fh);
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
