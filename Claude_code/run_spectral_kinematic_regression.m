%% run_spectral_kinematic_regression.m
%
% PURPOSE
%   Regress ES->LS kinematic change on ES->LS spectral band change, per
%   design cell. Tests whether the DIRECTION of the 25-45 Hz change tracks
%   the direction of behavioural change.
%
% BANDS
%   band2545 : 25-45 Hz  -- the empirically observed band from the PSD grids
%   beta     : 13-30 Hz  -- canonical, for comparison with prior analyses
%   gamma    : 30-50 Hz  -- canonical, for comparison with prior analyses
%   control  : 70-100 Hz -- artifact reference. If a kinematic correlation
%                           appears HERE too, it is not physiological:
%                           scalp EEG cannot resolve neural signal at these
%                           frequencies, so a control-band correlation
%                           indicates a shared nuisance driver.
%
% ORIENTATION
%   Both sides are LS - ES, matching run_es_ls_psd_contrast.m. Positive
%   spectral = power higher at late stim. Positive kinematic = metric
%   higher at late stim.
%
% STATISTICAL HEALTH WARNING
%   n = 5 per cell. 13 kinematic metrics x 4 bands = 52 tests per cell.
%   At alpha = .05 roughly 2-3 "significant" results per cell are expected
%   by chance alone. With n=5, r must exceed ~0.878 to reach p<.05, and a
%   single point can produce that. Treat every result here as
%   hypothesis-generating. The sham and HC cells are included precisely so
%   you can see how many spurious hits arise where no effect should exist
%   -- that is the calibration, not the p-values.
%
% INPUTS
%   subjectData.mat        (spectral, computed fresh so band edges are exact)
%   kinematics_long.csv    (from extract_kinematics.m)
%
% OUTPUT
%   console tables
%   spectral_kinematic_regression.csv
%   fig_scatter_<cell>_<band>.png   (top hits only)
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
CSV_PATH = fullfile(pwd,'kinematics_long.csv');
OUT_DIR  = fullfile(pwd,'spec_kin_regression_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

PRIMARY_PHASE = 3;   % move
TRIAL_ES = 2; TRIAL_LS = 3;

bands = { 'band2545',[25 45]; 'beta',[13 30]; 'gamma',[30 50]; 'control',[70 100] };

SCATTER_R_MIN = 0.80;   % only plot the stronger associations

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

%% ==================== SPECTRAL SIDE =============================
if ~isfile(MAT_PATH); error('Not found: %s',MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};

p1 = sd(1).power;
chanlabels = cell(1,numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');    chanlabels{c}=p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label'); chanlabels{c}=p1.chans(c).label;
    else;                                chanlabels{c}=sprintf('ch%d',c); end
end
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals<0) > 0.01;

spec = containers.Map();   % sid -> struct of band deltas (anode channel)
meta = containers.Map();   % sid -> {group, cond, anode}
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    si = sd(mi).sessioninfo;
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond='active'; end
    grp = 'HC';
    if isstruct(si)&&isfield(si,'dx')&&~isempty(si.dx)&& ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp='CS'; end
    sl = upper(strtrim(char(string(si.stimlat))));
    anode = tern(strcmp(sl,'L'),'C3','C4');
    ci = find(strcmpi(chanlabels,anode),1);
    if isempty(ci); warning('%s: %s missing',sid,anode); continue; end

    f = squeeze(sd(mi).power.freq(1,:,ci));
    pES = mean(get_spec(sd,mi,ci,PRIMARY_PHASE,TRIAL_ES,IS_DB),2,'omitnan');
    pLS = mean(get_spec(sd,mi,ci,PRIMARY_PHASE,TRIAL_LS,IS_DB),2,'omitnan');
    d = pLS - pES;

    st = struct();
    for b = 1:size(bands,1)
        m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
        st.(bands{b,1}) = mean(d(m),'omitnan');
    end
    spec(sid) = st;
    meta(sid) = {grp,cond,anode};
end

%% ==================== KINEMATIC SIDE ============================
if ~isfile(CSV_PATH); error('Not found: %s',CSV_PATH); end
T = readtable(CSV_PATH,'Delimiter',',');
if ~iscell(T.SubjectID)
    T.SubjectID = arrayfun(@(x)sprintf('%04d',x),T.SubjectID,'UniformOutput',false);
end
T.Block  = cellstr(string(T.Block));
T.Metric = cellstr(string(T.Metric));
metrics  = unique(T.Metric,'stable');

kin = containers.Map();   % sid -> [1 x nMetric] LS-ES
ksub = unique(T.SubjectID);
for i = 1:numel(ksub)
    sid = ksub{i};
    v = nan(1,numel(metrics));
    for m = 1:numel(metrics)
        es = T.Value(strcmp(T.SubjectID,sid)&strcmp(T.Metric,metrics{m})&strcmp(T.Block,'ES'));
        ls = T.Value(strcmp(T.SubjectID,sid)&strcmp(T.Metric,metrics{m})&strcmp(T.Block,'LS'));
        v(m) = mean(ls,'omitnan') - mean(es,'omitnan');
    end
    kin(sid) = v;
end

%% ==================== REGRESSIONS ===============================
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
rows = {};

for c = 1:size(cells,1)
    ids = {};
    for i = 1:numel(roster)
        sid = roster{i};
        if ~isKey(meta,sid) || ~isKey(kin,sid); continue; end
        mm = meta(sid);
        if strcmp(mm{1},cells{c,1}) && strcmp(mm{2},cells{c,2}); ids{end+1}=sid; end %#ok<AGROW>
    end
    if numel(ids) < 3; continue; end

    fprintf('\n===================================================================\n');
    fprintf('  %s %s   (n=%d: %s)\n', cells{c,1},cells{c,2},numel(ids),strjoin(ids,', '));
    fprintf('===================================================================\n');

    for b = 1:size(bands,1)
        bn = bands{b,1};
        x = zeros(numel(ids),1);
        for k=1:numel(ids); st = spec(ids{k}); x(k) = st.(bn); end

        fprintf('\n  --- %s (%g-%g Hz) ---\n', bn, bands{b,2}(1), bands{b,2}(2));
        fprintf('  %-22s %8s %8s %8s %10s\n','kinematic metric','r','R2','slope','p');
        hits = {};
        for m = 1:numel(metrics)
            y = zeros(numel(ids),1);
            for k=1:numel(ids); v = kin(ids{k}); y(k)=v(m); end
            ok = isfinite(x)&isfinite(y);
            if sum(ok) < 3; continue; end
            [r,p,slope] = lin_reg(x(ok),y(ok));
            flag = '';
            if abs(r) >= SCATTER_R_MIN; flag = ' *'; end
            fprintf('  %-22s %+8.3f %8.3f %+8.3f %10.4f%s\n', ...
                metrics{m}, r, r^2, slope, p, flag);
            rows(end+1,:) = {cells{c,1},cells{c,2},bn,metrics{m},numel(ids),r,r^2,slope,p}; %#ok<AGROW>
            if abs(r) >= SCATTER_R_MIN
                hits{end+1} = {metrics{m}, x(ok), y(ok), ids(ok), r, p}; %#ok<AGROW>
            end
        end

        % scatter plots for strong associations
        for h = 1:numel(hits)
            H = hits{h};
            fh = figure('Position',[100 100 420 380],'Visible','off');
            plot(H{2},H{3},'ko','MarkerFaceColor',[0.2 0.4 0.8],'MarkerSize',8); hold on;
            pf = polyfit(H{2},H{3},1);
            xx = linspace(min(H{2}),max(H{2}),10);
            plot(xx,polyval(pf,xx),'r-','LineWidth',1.3);
            for q=1:numel(H{4})
                text(H{2}(q),H{3}(q),['  ' H{4}{q}],'FontSize',8);
            end
            grid on;
            xlabel(sprintf('%s LS-ES (dB)',bn));
            ylabel(sprintf('%s LS-ES',H{1}));
            title(sprintf('%s %s: r=%+.3f p=%.4f (n=%d)', ...
                cells{c,1},cells{c,2},H{5},H{6},numel(H{2})),'FontSize',9);
            print(fh,fullfile(OUT_DIR,sprintf('fig_scatter_%s_%s_%s_%s.png', ...
                cells{c,1},cells{c,2},bn,H{1})),'-dpng','-r150');
            close(fh);
        end
    end
end

%% ==================== SUMMARY ===================================
Tr = cell2table(rows,'VariableNames', ...
    {'Group','Condition','Band','Metric','n','r','R2','slope','p'});
writetable(Tr, fullfile(OUT_DIR,'spectral_kinematic_regression.csv'));

fprintf('\n\n===== HIT COUNTS (p < .05), by cell and band =====\n');
fprintf('Compare active cells against sham/HC. Similar counts everywhere\n');
fprintf('means you are looking at noise, not signal.\n\n');
fprintf('%-14s %-12s %8s %8s %14s\n','cell','band','n tests','n p<.05','expected~');
for c = 1:size(cells,1)
    for b = 1:size(bands,1)
        m = strcmp(Tr.Group,cells{c,1})&strcmp(Tr.Condition,cells{c,2})& ...
            strcmp(Tr.Band,bands{b,1});
        nt = sum(m); nh = sum(m & Tr.p<0.05);
        if nt==0; continue; end
        fprintf('%-14s %-12s %8d %8d %14.1f\n', ...
            [cells{c,1} ' ' cells{c,2}], bands{b,1}, nt, nh, 0.05*nt);
    end
end

fprintf('\n===== CONTROL-BAND CHECK =====\n');
mc = strcmp(Tr.Band,'control') & Tr.p<0.05;
if any(mc)
    fprintf('Control band (70-100 Hz) produced %d hits at p<.05:\n', sum(mc));
    sub = Tr(mc,:);
    for i=1:height(sub)
        fprintf('  %s %s / %-20s r=%+.3f p=%.4f\n', sub.Group{i},sub.Condition{i}, ...
            sub.Metric{i},sub.r(i),sub.p(i));
    end
    fprintf(['A hit here cannot be physiological -- scalp EEG has no neural\n' ...
             'signal at 70-100 Hz. Any band2545 hit on the SAME metric in the\n' ...
             'SAME cell should be regarded as sharing that nuisance driver.\n']);
else
    fprintf('No control-band hits at p<.05. Mildly reassuring.\n');
end

fprintf('\nWrote %s\n',OUT_DIR);
fprintf(['\nREAD THE HIT COUNTS BEFORE THE INDIVIDUAL p-VALUES. With 13 metrics\n' ...
         'and n=5, isolated p<.05 results are the expected output of noise.\n' ...
         'What would be meaningful: band2545 hits concentrated in CS active,\n' ...
         'absent from sham and control band, on kinematically related metrics.\n']);

%% ==================== LOCAL FUNCTIONS ==========================
function sg = get_spec(sd,sidx,ch,phase,trial,is_db)
raw = squeeze(sd(sidx).power.data(:,:,ch,phase,trial));
if is_db; sg = raw; else; sg = 10*log10(raw); end
end

function [r,p,slope] = lin_reg(x,y)
n = numel(x);
xc = x-mean(x); yc = y-mean(y);
den = sqrt(sum(xc.^2)*sum(yc.^2));
if den==0; r=NaN; p=NaN; slope=NaN; return; end
r = sum(xc.*yc)/den;
slope = sum(xc.*yc)/sum(xc.^2);
if n>2 && abs(r)<1
    t = r*sqrt((n-2)/(1-r^2));
    if exist('tcdf','file')==2
        p = 2*(1-tcdf(abs(t),n-2));
    else
        p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));   % normal approx fallback
    end
elseif abs(r)>=1
    p = 0;
else
    p = NaN;
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
