%% plot_drift_figure_v05.m
%
% PURPOSE
%   Produce the figure supporting the claim that the dominant
%   stimulation-related signal is low-frequency drift.
%
%   The ES-LS contrast cannot show this: current flows in both periods, so
%   it shows how drift CHANGES during stimulation, not that drift appears
%   WITH stimulation. The demonstrating comparison is baseline (no current)
%   versus during stimulation, with sham as the control that separates
%   current from the mere presence of the apparatus on the scalp.
%
% OUTPUTS
%   fig_drift_psd.png/.svg      PSD by block, log-log, per group, drift shaded
%   fig_drift_bands.png/.svg    band power by block, drift vs other bands
%   fig_drift_subjects.png/.svg per-subject drift-band trajectory
%   drift_values.csv
%   console: drift increase from baseline, by group and band
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR  = fullfile(pwd,'drift_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

PRIMARY_PHASE = 3;            % move
blockLabels = {'BL','ES','LS','Post'};

% Drift first; the others are for contrast, to show the effect is
% concentrated at low frequency rather than broadband.
bands = { 'drift', [1 4]; 'theta',[4 8]; 'alpha',[8 13]; ...
          'beta',  [13 30]; 'gamma',[30 50] };

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};
cells = {'CS','active';'CS','sham';'HC','active';'HC','sham'};
colr  = [0.15 0.15 0.15; 0.85 0.30 0.10; 0.90 0.60 0.10; 0.20 0.45 0.75];  % BL ES LS Post

%% ============================ LOAD ==============================
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
fprintf('Units: %s\n', tern(IS_DB,'already dB','linear -> 10*log10'));

%% ==================== EXTRACT ==================================
R = struct(); n = 0;
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
    if isempty(ci); continue; end

    n = n+1;
    R(n).sid=sid; R(n).grp=grp; R(n).cond=cond; R(n).anode=anode;
    R(n).f = squeeze(sd(mi).power.freq(1,:,ci));
    R(n).psd = nan(numel(R(n).f),4);
    for b = 1:4
        raw = squeeze(sd(mi).power.data(:,:,ci,PRIMARY_PHASE,b));
        if ~IS_DB; raw = 10*log10(raw); end
        R(n).psd(:,b) = mean(raw,2,'omitnan');
    end
end
R = R(1:n);
fprintf('Processed %d subjects.\n\n', n);
f = R(1).f;

%% ==================== CONSOLE: drift vs other bands =============
fprintf('===== POWER CHANGE FROM BASELINE (dB), anodal electrode =====\n');
fprintf('If drift dominates, the drift row is much larger than the rest,\n');
fprintf('and larger in active than sham.\n\n');
rows = {};
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    fprintf('--- %s %s (n=%d) ---\n', cells{c,1},cells{c,2},numel(idx));
    fprintf('%-8s %10s %10s %10s\n','band','ES-BL','LS-BL','Post-BL');
    for b = 1:size(bands,1)
        m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
        v = nan(numel(idx),4);
        for k = 1:numel(idx)
            v(k,:) = mean(R(idx(k)).psd(m,:),1,'omitnan');
        end
        d = [mean(v(:,2)-v(:,1)), mean(v(:,3)-v(:,1)), mean(v(:,4)-v(:,1))];
        fprintf('%-8s %+10.3f %+10.3f %+10.3f\n', bands{b,1}, d(1), d(2), d(3));
        for k = 1:numel(idx)
            rows(end+1,:) = {R(idx(k)).sid, cells{c,1}, cells{c,2}, bands{b,1}, ...
                v(k,1), v(k,2), v(k,3), v(k,4), v(k,2)-v(k,1), v(k,3)-v(k,1)}; %#ok<AGROW>
        end
    end
    fprintf('\n');
end
writetable(cell2table(rows,'VariableNames', ...
    {'SubjectID','Group','Condition','Band','BL','ES','LS','Post','ES_minus_BL','LS_minus_BL'}), ...
    fullfile(OUT_DIR,'drift_values.csv'));

%% ==================== FIG 1: PSD by block ======================
fh = figure('Position',[50 50 1200 620],'Visible','off');

% Group means computed first so a common y-axis can be applied to every
% panel. Without this, each group is autoscaled and the large drift-band
% elevation in the actively stimulated groups is not visually comparable
% against the sham groups.
MM = cell(size(cells,1),1);
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    M = nan(numel(f),4);
    for b = 1:4
        A = cell2mat(arrayfun(@(k) R(k).psd(:,b), idx, 'UniformOutput',false));
        M(:,b) = mean(A,2,'omitnan');
    end
    MM{c} = M;
end
allv = cell2mat(cellfun(@(M) M(:), MM(~cellfun(@isempty,MM)), 'UniformOutput',false));
allv = allv(isfinite(allv));
pad  = 0.05*range(allv);
YL   = [min(allv)-pad, max(allv)+pad];

for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    M = MM{c};
    % linear-frequency view
    subplot(2,4,c); hold on
    for b = 1:4; plot(f, M(:,b), 'Color', colr(b,:), 'LineWidth',1.6); end
    ylim(YL); shade(bands{1,2},[0.95 0.85 0.85]);
    grid on; xlim([0 max(f)]);
    title(sprintf('%s %s (n=%d)',cells{c,1},cells{c,2},numel(idx)),'FontSize',9);
    if c==1
        ylabel('power (dB)'); legend(blockLabels,'Location','best','FontSize',7);
    end

    % log-frequency view: makes the low-frequency end readable
    subplot(2,4,4+c); hold on
    for b = 1:4
        plot(f(f>0), M(f>0,b), 'Color', colr(b,:), 'LineWidth',1.6);
    end
    set(gca,'XScale','log'); ylim(YL); shade(bands{1,2},[0.95 0.85 0.85]);
    grid on; xlim([max(min(f),0.5) max(f)]);
    xlabel('Hz (log)');
    if c==1; ylabel('power (dB)'); end
end
sgt('PSD at the anodal electrode by block; drift band (1-4 Hz) shaded; common y-axis');
savefig_both(fh, fullfile(OUT_DIR,'fig_drift_psd.png'));

%% ==================== FIG 2: band change from baseline =========
fh = figure('Position',[50 50 1150 400],'Visible','off');

% Common y-axis across groups: the drift increase is an order of magnitude
% larger in healthy controls than in chronic stroke, and autoscaling each
% panel would conceal that difference.
DD = cell(size(cells,1),1);
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    D = nan(size(bands,1),3);
    for b = 1:size(bands,1)
        m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
        v = nan(numel(idx),4);
        for k = 1:numel(idx); v(k,:) = mean(R(idx(k)).psd(m,:),1,'omitnan'); end
        D(b,:) = [mean(v(:,2)-v(:,1)), mean(v(:,3)-v(:,1)), mean(v(:,4)-v(:,1))];
    end
    DD{c} = D;
end
allD = cell2mat(cellfun(@(D) D(:), DD(~cellfun(@isempty,DD)), 'UniformOutput',false));
allD = allD(isfinite(allD));
padD = 0.10*range(allD);
YLD  = [min(allD)-padD, max(allD)+padD];

for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    D = DD{c};
    subplot(1,4,c);
    bar(D); grid on; ylim(YLD);
    hold on; plot([0.4 size(bands,1)+0.6],[0 0],'k-','LineWidth',0.8,'HandleVisibility','off');
    set(gca,'XTickLabel',bands(:,1),'XTickLabelRotation',45);
    title(sprintf('%s %s',cells{c,1},cells{c,2}),'FontSize',9);
    if c==1
        ylabel('change from baseline (dB)');
        legend({'ES-BL','LS-BL','Post-BL'},'Location','best','FontSize',7);
    end
end
sgt('Change from baseline by band: drift versus the rest of the spectrum; common y-axis');
savefig_both(fh, fullfile(OUT_DIR,'fig_drift_bands.png'));

%% ==================== FIG 3: per-subject drift =================
m = f>=bands{1,2}(1) & f<=bands{1,2}(2);
fh = figure('Position',[50 50 1150 340],'Visible','off');

% Common y-axis, computed from all participants in all groups.
VV = cell(size(cells,1),1);
for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    V = nan(numel(idx),4);
    for k = 1:numel(idx); V(k,:) = mean(R(idx(k)).psd(m,:),1,'omitnan'); end
    VV{c} = V;
end
allV = cell2mat(cellfun(@(V) V(:), VV(~cellfun(@isempty,VV)), 'UniformOutput',false));
allV = allV(isfinite(allV));
padV = 0.06*range(allV);
YLV  = [min(allV)-padV, max(allV)+padV];

for c = 1:size(cells,1)
    idx = find(strcmp({R.grp},cells{c,1}) & strcmp({R.cond},cells{c,2}));
    if isempty(idx); continue; end
    subplot(1,4,c); hold on
    V = VV{c};
    for k = 1:size(V,1)
        plot(1:4, V(k,:), '-o','Color',[0.65 0.65 0.65],'MarkerSize',3);
    end
    plot(1:4, mean(V,1,'omitnan'), '-o','Color',[0.8 0 0],'LineWidth',2, ...
        'MarkerFaceColor',[0.8 0 0]);
    ylim(YLV);
    set(gca,'XTick',1:4,'XTickLabel',blockLabels); xlim([0.7 4.3]); grid on;
    title(sprintf('%s %s',cells{c,1},cells{c,2}),'FontSize',9);
    if c==1; ylabel('drift-band power (dB)'); end
end
sgt('Drift-band (1-4 Hz) power per subject across blocks; common y-axis');
savefig_both(fh, fullfile(OUT_DIR,'fig_drift_subjects.png'));

fprintf('Wrote %s\n', OUT_DIR);
fprintf(['\nREAD: the claim is supported if drift rises from BL to ES/LS in the\n' ...
         'ACTIVE groups and does not in sham, and if that rise is larger than\n' ...
         'the change in any other band. If sham rises comparably, the signal is\n' ...
         'the apparatus rather than the current, which is a different claim.\n']);

%% ==================== LOCAL FUNCTIONS =========================
function savefig_both(fh, pngpath)
% Write PNG (quick viewing) and SVG (vector, for the manuscript).
% SVG keeps text as text and lines as paths, so the figure stays sharp at
% any size and can be edited in Illustrator or Inkscape.
print(fh, pngpath, '-dpng','-r150');
[d,n,~] = fileparts(pngpath);
svgpath = fullfile(d,[n '.svg']);
try
    print(fh, svgpath, '-dsvg','-painters');
    fprintf('  wrote %s and %s\n', pngpath, svgpath);
catch ME
    fprintf('  wrote %s (SVG failed: %s)\n', pngpath, ME.message);
end
close(fh);
end

function shade(rng,col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)],[yl(1) yl(1) yl(2) yl(2)],col, ...
    'FaceAlpha',0.35,'EdgeColor','none','HandleVisibility','off');
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt);
else
    annotation('textbox',[0 0.94 1 0.06],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
