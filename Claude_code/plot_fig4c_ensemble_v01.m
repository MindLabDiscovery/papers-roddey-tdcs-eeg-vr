%% plot_fig4c_ensemble.m
%
% PURPOSE
%   Replot Figure 4C using the CORRECTED ensemble estimator, comparing
%   CS active and HC active with pre-stim / LS-ES / post-stim on the x-axis.
%
% INPUT
%   coh_comparison_cells.csv, written by recompute_coherence_comparison.m.
%   Uses absimag_ensemble (corrected). absimag_pertrial (degenerate) is
%   plotted alongside only as a dashed reference, so the difference between
%   the published and corrected estimators is visible in one figure.
%
% X-AXIS NOTE
%   The requested axis mixes two kinds of quantity: BL and Post are
%   absolute coherence, LS-ES is a difference. A difference is centred on
%   zero while absolute values are not, so they are NOT on a common scale
%   and the middle point should not be read as "coherence at mid-stim".
%   FIG 1 therefore plots the requested 3-point axis with the LS-ES point
%   on its own right-hand axis, and FIG 2 plots the plain BL/ES/LS/Post
%   absolute series, which is directly comparable across all four levels
%   and is what the original 4C showed. Use FIG 2 for the manuscript
%   unless the difference framing is specifically wanted.
%
% OUTPUT
%   fig4c_ensemble_3point.png     requested axis
%   fig4c_ensemble_absolute.png   BL/ES/LS/Post absolute
%   fig4c_ensemble_values.csv     the plotted numbers
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
COH_PATH = fullfile(pwd,'coh_comparison_cells.csv');
OUT_DIR  = fullfile(pwd,'fig4c_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

SHOW_CELLS  = {'CS','Stim';'HC','Stim'};    % as requested
CLEAN_ONLY  = false;                        % true = clean cells only
phaseNames  = {'Hold','Prep','Move'};
blockLabels = {'BL','ES','LS','Post'};

colr = [0.80 0.15 0.15;    % CS
        0.15 0.35 0.75];   % HC

%% ============================ LOAD ==============================
if ~isfile(COH_PATH)
    error('%s not found. Run recompute_coherence_comparison.m first.', COH_PATH);
end
C = readtable(COH_PATH,'Delimiter',',');
for v = {'subject','group','condition','block','phase','cell_status'}
    C.(v{1}) = cellstr(string(C.(v{1})));
end
C.sid = cell(height(C),1);
for i = 1:height(C)
    tok = regexp(C.subject{i},'(\d{4})$','tokens','once');
    C.sid{i} = tern(isempty(tok), C.subject{i}, tern(isempty(tok),'',''));
    if ~isempty(tok); C.sid{i} = tok{1}; end
end
if CLEAN_ONLY
    n0 = height(C);
    C = C(strcmp(C.cell_status,'clean'),:);
    fprintf('CLEAN_ONLY: %d -> %d rows\n', n0, height(C));
end
fprintf('Loaded %d rows.\n\n', height(C));

%% ==================== ASSEMBLE ================================
% val{cellIdx}(subject, phase, block) for each estimator
est = {'absimag_ensemble','absimag_pertrial'};
estName = {'ensemble (corrected)','per-trial (degenerate)'};
V = cell(size(SHOW_CELLS,1), numel(est));
ids = cell(size(SHOW_CELLS,1),1);

for c = 1:size(SHOW_CELLS,1)
    m = strcmp(C.group,SHOW_CELLS{c,1}) & strcmp(C.condition,SHOW_CELLS{c,2});
    s = unique(C.sid(m),'stable');
    ids{c} = s;
    for e = 1:numel(est)
        A = nan(numel(s),3,4);
        for i = 1:numel(s)
            for ph = 1:3
                for b = 1:4
                    k = find(m & strcmp(C.sid,s{i}) & strcmp(C.phase,phaseNames{ph}) & ...
                             strcmp(C.block,blockLabels{b}),1);
                    if ~isempty(k); A(i,ph,b) = C.(est{e})(k); end
                end
            end
        end
        V{c,e} = A;
    end
    fprintf('%s %s: n=%d (%s)\n', SHOW_CELLS{c,1},SHOW_CELLS{c,2},numel(s),strjoin(s',', '));
end

%% ==================== FIG 1: requested 3-point axis ============
fh = figure('Position',[60 60 1150 400],'Visible','off');
for ph = 1:3
    subplot(1,3,ph); hold on;
    yyaxis left; ax = gca; ax.YColor = [0 0 0];
    hL = [];
    for c = 1:size(SHOW_CELLS,1)
        A = V{c,1};
        bl = A(:,ph,1); po = A(:,ph,4);
        mu = [mean(bl,'omitnan'), NaN, mean(po,'omitnan')];
        se = [sem(bl), NaN, sem(po)];
        h = errorbar([1 2 3], mu, se, '-o','Color',colr(c,:),'LineWidth',1.8, ...
            'MarkerFaceColor',colr(c,:),'MarkerSize',7);
        hL(end+1) = h; %#ok<AGROW>
    end
    ylabel('coherence (BL, Post)');

    yyaxis right; ax = gca; ax.YColor = [0.35 0.35 0.35];
    for c = 1:size(SHOW_CELLS,1)
        A = V{c,1};
        d = A(:,ph,3) - A(:,ph,2);            % LS - ES
        errorbar(2, mean(d,'omitnan'), sem(d), 's','Color',colr(c,:), ...
            'LineWidth',1.8,'MarkerFaceColor','w','MarkerSize',9);
    end
    plot([0.5 3.5],[0 0],'k:','HandleVisibility','off');
    ylabel('LS - ES (difference)');

    set(gca,'XTick',1:3,'XTickLabel',{'pre','LS-ES','post'});
    xlim([0.6 3.4]); grid on; title(phaseNames{ph});
    if ph==1
        legend(hL, cellfun(@(a,b)[a ' ' b],SHOW_CELLS(:,1),SHOW_CELLS(:,2), ...
            'UniformOutput',false),'Location','best','FontSize',8);
    end
end
sgtitle_compat('Figure 4C, corrected ensemble estimator (mean \pm SEM)');
print(fh,fullfile(OUT_DIR,'fig4c_ensemble_3point.png'),'-dpng','-r150'); close(fh);

%% ==================== FIG 2: absolute BL/ES/LS/Post ============
fh = figure('Position',[60 60 1150 640],'Visible','off');
for ph = 1:3
    % corrected
    subplot(2,3,ph); hold on;
    for c = 1:size(SHOW_CELLS,1)
        A = V{c,1};
        mu = squeeze(mean(A(:,ph,:),1,'omitnan'))';
        se = arrayfun(@(b) sem(A(:,ph,b)), 1:4);
        for i = 1:size(A,1)
            plot(1:4, squeeze(A(i,ph,:)), '-', 'Color',[colr(c,:) 0.25], ...
                'HandleVisibility','off');
        end
        errorbar(1:4, mu, se, '-o','Color',colr(c,:),'LineWidth',2, ...
            'MarkerFaceColor',colr(c,:),'MarkerSize',7);
    end
    set(gca,'XTick',1:4,'XTickLabel',blockLabels); xlim([0.7 4.3]); grid on;
    title(sprintf('%s  -  ensemble (corrected)',phaseNames{ph}));
    if ph==1; ylabel('imaginary coherence'); legend(cellfun(@(a,b)[a ' ' b], ...
        SHOW_CELLS(:,1),SHOW_CELLS(:,2),'UniformOutput',false), ...
        'Location','best','FontSize',8); end

    % degenerate, for contrast
    subplot(2,3,3+ph); hold on;
    for c = 1:size(SHOW_CELLS,1)
        A = V{c,2};
        mu = squeeze(mean(A(:,ph,:),1,'omitnan'))';
        se = arrayfun(@(b) sem(A(:,ph,b)), 1:4);
        errorbar(1:4, mu, se, '--s','Color',colr(c,:),'LineWidth',1.5, ...
            'MarkerFaceColor','w','MarkerSize',6);
    end
    plot([0.7 4.3],[2/pi 2/pi],'k:','LineWidth',1.2);
    text(4.25,2/pi,'  2/\pi','FontSize',8,'HorizontalAlignment','right');
    set(gca,'XTick',1:4,'XTickLabel',blockLabels); xlim([0.7 4.3]); grid on;
    title(sprintf('%s  -  per-trial (degenerate)',phaseNames{ph}));
    if ph==1; ylabel('|sin(\Delta\phi)|'); end
end
sgtitle_compat('Figure 4C: corrected vs published estimator');
print(fh,fullfile(OUT_DIR,'fig4c_ensemble_absolute.png'),'-dpng','-r150'); close(fh);

%% ==================== VALUES ==================================
rows = {};
for c = 1:size(SHOW_CELLS,1)
    for e = 1:numel(est)
        A = V{c,e};
        for ph = 1:3
            for b = 1:4
                rows(end+1,:) = {SHOW_CELLS{c,1},SHOW_CELLS{c,2},estName{e}, ...
                    phaseNames{ph},blockLabels{b},sum(isfinite(A(:,ph,b))), ...
                    mean(A(:,ph,b),'omitnan'), sem(A(:,ph,b))}; %#ok<AGROW>
            end
            d = A(:,ph,3)-A(:,ph,2);
            rows(end+1,:) = {SHOW_CELLS{c,1},SHOW_CELLS{c,2},estName{e}, ...
                phaseNames{ph},'LS-ES',sum(isfinite(d)),mean(d,'omitnan'),sem(d)}; %#ok<AGROW>
        end
    end
end
writetable(cell2table(rows,'VariableNames', ...
    {'Group','Condition','Estimator','Phase','Block','n','mean','sem'}), ...
    fullfile(OUT_DIR,'fig4c_ensemble_values.csv'));

fprintf('\nWrote %s\n', OUT_DIR);
fprintf('fig4c_ensemble_absolute.png is the one to use for the manuscript.\n');

%% ==================== LOCAL FUNCTIONS =========================
function s = sem(x)
x = x(isfinite(x));
if numel(x) < 2; s = 0; else; s = std(x)/sqrt(numel(x)); end
end

function sgtitle_compat(txt)
% sgtitle is R2018b+, but absent in some builds; fall back to annotation.
if exist('sgtitle','file')
    sgtitle(txt);
else
    annotation('textbox',[0 0.94 1 0.06],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function out = tern(c,a,b)
if c; out=a; else; out=b; end
end
